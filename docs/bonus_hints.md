# Bonus Hints

## Bonus 1 Challenge Hint:

On the host, look at `/home/kubernetes/.bash_history` bash shell history.

## Bonus 2 Challenge Hint:

Review the leftover Helm chart deploy history `configmap` in the `kube-system` `namespace`. Base64 decode and `gunzip` the contents of the `configmap` data, and examine the contents of the container image referenced in the `deployment` manifest.
