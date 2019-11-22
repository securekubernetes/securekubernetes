# Bonus Challenges

__Blue's__ boss has hired you to see if the cluster is completely "clean".  Use the next block of time to solve the following bonus challenges.  Once you know both answers, approach one of the co-presenters and _whisper_ the answers to both questions to earn the prestigious "expert" badge.

## Challenge 1

* Get a root shell on the `cluster` `node` again. Find out the image name that was last run directly with docker commands by the `kubernetes` user.

## Challenge 2

* Was this cluster compromised via another mechanism and __Blue__ didn't know about it?  (Yes!) Find the IP address of the attacker's system where the reverse shell was being sent.  Hint: Tiller was removed with `helm reset --force` and so it left some things behind in the `kube-system` `namespace`.
