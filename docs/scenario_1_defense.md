# Free Compute: Scenario 1 Defense

## Backstory

### Name: __Blue__

* Overworked
* Can only do the bare minimum
* Uses defaults when configuring systems
* Usually gets blamed for stability or security issues

### Motivations

* __Blue__ gets paged at 1am with an “urgent” problem: the developers say the “website is slow”
* __Blue__ reluctantly agrees to take a “quick look”
* __Blue__ wants desperately to get back to sleep. Zzz

## Defense

__Blue__ looks at the page with an unsurprising lack of details, and spends a few minutes getting the answer to exactly _which_ website they are referring to that is underperforming.  It's "the one running in Kubernetes", they said.  __Blue__ leverages their Cloud Shell terminal to begin the process of troubleshooting the issue.

### Identifying the Issue

The first step is to determine the name for the web application `deployment` in question.  From the terminal, __Blue__ runs the following to see a listing of all `pods` in all `namespaces`:

```console
kubectl get pods --all-namespaces
```

The `cluster` is relatively small in size, but it has a couple `deployments` that could be the site in question.  The development team mentions performance is an issue, so __Blue__ checks the current CPU and Memory usage with:

```console
kubectl top node
```

and

```console
kubectl top pod --all-namespaces
```

It appears that a suspcious `deployment` named `bitcoinero` is running, and its causing resource contention issues.  __Blue__ runs the following to see the `pod's` full configuration:

```console
kubectl get deployment -n prd bitcoinero -o yaml
```

It was created very recently, but there are no ports listening, so this looks unlikely to be part of the website.  Next, __Blue__ grabs a consolidated listing of all images running in the `cluster`:

```console
kubectl get pods --all-namespaces -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n' | sort -u
```

### Confirming the Foreign Workload

__Blue__ sends a message back to the developers asking for confirmation of the suspicious `bitcoinero` image, and they all agree they don't know who created the `deployment`. They also mention that someone accidentally deployed a `nodePort` for the production ops dashboard, and ask if __Blue__ can delete it for them. __Blue__ makes a mental note about the `nodePort` and then <a href="https://console.cloud.google.com/logs/viewer" target="_blank">opens a browser to the cluster log system</a>.

Once there, __Blue__ clicks on the small "down arrow" on the far right of the "Filter by label or text" search bar, selects "Convert to advanced filter", and puts the following query into the search filter area:

```console
resource.type="k8s_cluster"
protoPayload.authorizationInfo.permission="io.k8s.extensions.v1beta1.deployments.create"
```

![Stackdriver Log Filter of Default Service Account](img/sd-prd.png)

__Blue__ sees that the `default` Kubernetes `serviceaccount` was the creator of the `bitcoinero` `deployment`.

Back in the Cloud Shell terminal, __Blue__ runs the following to list the `pods` running with the `default` `serviceaccount` in the `prd` `namespace`:

```console
kubectl get pods -n prd -o jsonpath='{range .items[?(@.spec.serviceAccountName=="default")]}{.metadata.name}{" "}{.spec.serviceAccountName}{"\n"}{end}'
```

### Cleaning Up

Unsure of exactly _how_ a `pod` created another `pod`, __Blue__ decides that it's now 3am, and the commands are blurring together.  The website is still slow, so __Blue__ decides to find and delete the `deployment`:

```console
kubectl get deployments -n prd
```

```console
kubectl delete deployment bitcoinero -n prd
```

They also keep their promise, and delete the `nodePort`:
```console
kubectl get services -n prd
```

```console
kubectl delete service dashboard -n prd
```

### Installing Security Visibility

It's now very clear to __Blue__ that without additional information, it's difficult to determine exactly _who_ or _what_ created that `bitcoinero` deployment.  Was it code?  Was it a human?  __Blue__ suspects it was one of the engineers on the team, but there's not much they can do without proof.  Remembering that this `cluster` doesn't have any runtime behavior monitoring and detection software installed, __Blue__ decides to install <a href="https://falco.org" target="_blank">Sysdig's Falco</a> using an all-in-one manifest from a prominent blogger.

```console
kubectl apply -f https://raw.githubusercontent.com/securekubernetes/securekubernetes/master/manifests/security.yml
```

Just to make sure it's working, __Blue__ runs the following command to get the logs from the deployed `Falco` `pod(s)`:

```console
kubectl logs -n falco $(kubectl get pod -n falco -l app=falco -o=name) -f
```

### Ensuring Security Log Flow

Going back to the <a href="https://console.cloud.google.com/logs/viewer" target="_blank">logging system</a>, __Blue__ enters another log filter using the "advanced filter" with the following query to confirm it's receiving all the logs coming from the `Falco` `deployment`:

```console
resource.type="container"
resource.labels.namespace_id="falco"
resource.labels.container_name="falco"
severity!="ERROR"
textPayload=""
```

### Reviewing the Falco Rules:

Falco Kubernetes Rules:

```console
kubectl get configmaps -n falco falco-config -o json | jq -r '.data."falco_rules.yaml"' | grep rule:
```

Kubernetes Audit Rules (Not applicable on GKE):

```console
kubectl get configmaps -n falco falco-config -o json | jq -r '.data."k8s_audit_rules.yaml"' | grep rule:
```

### Giving the "All Clear"

Seeing what looks like a "happy" `cluster`, __Blue__ emails their boss that there was a workload using too many resources that wasn't actually needed, so it was deleted.  Also, they added some additional "security" just in case.
