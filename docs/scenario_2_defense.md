# Persistence: Scenario 2 Defense

## Backstory

### Name: __Blue__

* Still overworked
* Still can only do the bare minimum
* Uses the defaults when configuring systems
* Usually gets blamed for stability or security issues

### Motivations

* A week after the first incident, __Blue__ gets paged at 3am because “website is slow again”.
* __Blue__, puzzled, takes another look.
* __Blue__ decides to dust-off the résumé “just in case”.

## Defense

__Blue__ is paged again with the same message as last time. What is going on? Could this be the same problem again?

### Identifying the Issue

Let's run some basic checks again to see if we can find random workloads:

```console
kubectl get pods --all-namespaces
```

There does not appear to be any unusual workloads running on our cluster.

Just to be sure, let's check our cluster's resource consumption:

```console
kubectl top node
```

and

```console
kubectl top pod --all-namespaces
```

So far, everything looks normal. What gives?

Remembering that `falco` was deployed for runtime visibility and monitoring last time, we seem to be getting alerts from StackDriver filters.

In a new <a href="https://console.cloud.google.com/logs/viewer" target="_blank">StackDriver window</a>, let's run the query:

```console
resource.type="container"
resource.labels.container_name:"falco"
jsonPayload.rule="Launch Privileged Container" OR jsonPayload.rule="Terminal shell in container"
```

We're looking for `container` logs from `falco` where triggered rules are privileged containers or interactive shells.

Huh. This is definitely odd. What is this privileged `alpine` container?

In a new <a href="https://console.cloud.google.com/logs/viewer" target="_blank">StackDriver window</a>, let's correlate this with kubernetes cluster logs:

```console
resource.type=k8s_cluster
protoPayload.request.spec.containers.image="alpine"
```

So, we see a few things:

1. References to `dev` namespace and serviceaccount `system:serviceaccount:dev:default`
1. A pod named `r00t` got created
1. The pod command is `nsenter --mount=/proc/1/ns/mnt -- /bin/bash`
1. The `securityContext` is `privileged: true`
1. The `hostPID` is set to `true`

This is not looking good. Can we see any activity in this container?

In a new <a href="https://console.cloud.google.com/logs/viewer" target="_blank">StackDriver window</a>, let's search for this `r00t` container logs:

```console
resource.type="container"
resource.labels.pod_id:r00t
```

Wow. We are seeing some commands executed from the container.

But wait, looks like they're directly on the node.

They tried to create a pod, but failed. So, they created a Service and an Endpoint.

- Inspecting the attacker's commands, we see they were running kubectl using a kube-system default service token and created a service and endpoints.

- In cloud shell, kubectl get service & endpoints in cloud shell to verify & delete them:

```console
kubectl get svc --all-namespaces
kubectl get ep --all-namespaces
```

```console
kubectl -n kube-system delete svc/istio-mgmt
```

- But, how did this happen?!?!?!

- In SD, we found traces of serviceaccount tokens in `dev` namespace. So, we decide to investigate pods in that namespace:

```console
kubectl -n dev get pods
kubectl -n dev logs $(kubectl -n dev get pods -oname | grep dashboard)
```

```console
kubectl -n dev logs $(kubectl -n dev get pods -oname | grep dashboard) -c dashboard
```

- Nothing

```console
kubectl -n dev logs $(kubectl -n dev get pods -oname | grep dashboard) -c authproxy
```

- Looks like webshell activity in authproxy logs.

- Recalling an Open-Policy-Agent talk at KubeCon San Diego 2019, I heard that OPA/Gatekeeper can be deployed as an admission controller.

- Explain Admission Controllers. Insert diagram.

- Let's block privileged containers and unapproved images:

```console
kubectl apply -f <GITHUB URL TO manifests/gatekeeper>
```

- Tries to kubectl run privileged container and sees it's blocked.

- Blue contacts boss and says "Houston, we have a problem".
