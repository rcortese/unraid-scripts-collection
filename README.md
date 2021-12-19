# Unraid Scripts Collection

My own personal collection of scripts for Unraid Server. Can be run directly via ssh, console, or through the User Scripts plugin.

(currently only tested on Unraid v6.9.2)

## [cycle_vms.sh](scripts/cycle_vms.sh)

Cycles between a list of VMs. Intended to be used with resource sharing VMs (such as gaming/mining VMs that pass-through the same GPU).

* User must fill vm_names_list variable upon import

``` sh
# example (vm_names_list already declared in the headers, fill it with your setup)
declare -r -a vm_names_list=( "Pop_OS" "Windows 10" )
```

The script works as such (using virsh):

* Search for an active VM within the list
* If a VM is listed as active
  * Shuts it down
  * Checks periodically until it is no longer listed (or timeout)
* Starts next one on the list

 If started from inside a VM on the list, run it on the background otherwise the script is killed upon VM shut down.

Inspired by a [tutorial video by SpaceInvader One](https://www.youtube.com/watch?v=QoVJ0460cro).
