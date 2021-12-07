#!/bin/bash
set -e

###################################################
## User filled variables

# Fill with the names of VMs to alternate between
# If a VM is listed as active, the next one will be started (or first if last)
declare -r -a vms_to_alternate=( "Pop_OS" "Windows 10" )
declare -r debug_mode=true


###################################################
## Functions

# Switches between two vms
# $1 - name of vm to shutdown
# $2 - name of vm to start
switch_vm() {

  local -r vm_to_shutdown="$1"; shift
  local -r vm_to_start="$1"; shift

  echo "Requesting shutdown of VM: ${vm_to_shutdown}"
  if [ "$debug_mode" = true ]; then
    echo "no action taken, debug mode only..."
  else
    virsh shutdown "${vm_to_shutdown}"
    sleep 30
  fi
  echo "Requesting start of VM: ${vm_to_start}"
  if [ "$debug_mode" = true ]; then
    echo "no action taken, debug mode only..."
  else
    virsh start "${vm_to_start}"
  fi
}


main() {

  # vm_to_start defaults to first one
  local vm_to_start="${vms_to_alternate[0]}"
  # vm_to_shutdown defaults to a display message
  local vm_to_shutdown="NO_ACTIVE_VM_FOUND"

  echo "searching for an active VM on the following list:
  "
  local -r active_vms_list=$(virsh list)
  echo "${active_vms_list}
  "
  for i in "${!vms_to_alternate[@]}"
  do
    # if vm is listed as active
    if echo "${active_vms_list}" | grep -q "${vms_to_alternate[i]}"; then
      echo "${vms_to_alternate[i]} found active!"
      # set it to shutdown
      vm_to_shutdown="${vms_to_alternate[i]}"
      # and the next one to start (if not last)
      if ! [ -z "${vms_to_alternate[i+1]}" ]; then
        vm_to_start="${vms_to_alternate[i+1]}"
      fi
      echo "next on list: ${vm_to_start}"
    fi
  done

  switch_vm "${vm_to_shutdown}" "${vm_to_start}"
  exit 0
}

main
