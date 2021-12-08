# Unraid Scripts Collection

My own personal collection of scripts for Unraid. Can be directly executed via ssh on an Unraid server or through the User Scripts plugin.

(currently on Unraid v6.9.2)

## [alternate_vms](scripts/alternate_vms.sh)

Shuts down an active vm from a hardcoded list and starts up the next one on the list. Can be used from within VM if ran in background. Intended to be used for VMs sharing common resources (such as a GPU). Please fill the variables at the beginning of the script accordingly.

Based on a [tutorial video by SpaceInvader One](https://www.youtube.com/watch?v=QoVJ0460cro).
