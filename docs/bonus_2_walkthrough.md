# Bonus Walkthroughs

## Challenge 2

Was this cluster compromised via another mechanism and __Blue__ didn't know about it?  (Yes!) Find the IP address of the attacker's system where the reverse shell was being sent.  Hint: Tiller was removed with `helm reset --force` and so it left some things behind in the `kube-system` `namespace`.

1. Search for leftover `configmaps`

    ```console
    kubectl get configmap --all-namespaces
    ```

1. Dig into the Helm Chart configmap

    ```console
    kubectl get configmap -n kube-system toned-elk.v1 -o json
    ```

    ```console
    kubectl get configmap -n kube-system toned-elk.v1 -o json | jq -r '.'
    ```

    ```console
    kubectl get configmap -n kube-system toned-elk.v1 -o json | jq -r '.data.release'
    ```

    ```console
    kubectl get configmap -n kube-system toned-elk.v1 -o json | jq -r '.data.release' | base64 -d
    ```

    ```console
    kubectl get configmap -n kube-system toned-elk.v1 -o json | jq -r '.data.release' | base64 -d | file -
    ```

    ```console
    kubectl get configmap -n kube-system toned-elk.v1 -o json | jq -r '.data.release' | base64 -d | gunzip -
    ```


1. Examine the image without running it

    ```console
    docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock docker.io/wagoodman/dive:latest docker.io/bradgeesaman/bd:latest
    ```

1. Make a tmp space to save the image

    ```console
    mkdir ~/bdtmp && cd ~/bdtmp
    ```

1. Save the image as a tarball

    ```console
    docker save docker.io/bradgeesaman/bd:latest -o bd.tar
    ```

    ```console
    ls -alh
    ```

1. View the image tarball contents

    ```console
    tar tvf bd.tar 
    ```

    ```console
    tar xvf bd.tar
    ```

1. Examine the manifest.json to find the layers

    ```console
    cat manifest.json | jq -r '.'
    ```

    ```console
    jq -r '.[].Config' manifest.json
    ```

    ```console
    cat $(jq -r '.[].Config' manifest.json) | jq -r '.'
    ```

    ```console
    cat $(jq -r '.[].Config' manifest.json) | jq -r '.history[] | select(."empty_layer"!=true)'
    ```

    ```console
    ls -alh
    ```

1. Obtain the last layer file name

    ```console
    cat manifest.json | jq -r '.'
    ```

    ```console
    jq -r '.[].Layers[]' manifest.json | tail -1
    ```

1. To get the answer, view the contents of the last image layer

    ```console
    tar xvf $(jq -r '.[].Layers[]' manifest.json | tail -1) -O
    ```

1. Cleanup

    ```console
    cd ..
    ```

    ```console
    rm -rf ~/bdtmp
    ```

