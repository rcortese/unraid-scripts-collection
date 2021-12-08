#!/bin/bash
set -e

###################################################
## User filled variables

# Fill with the names of VMs to alternate between
# If a VM is listed as active, the next one will be started (or first if last)
declare -r -a vms_to_alternate=( "Pop_OS" "Windows 10" )
declare -r graceful_shutdown_timeout=30 # in seconds
declare -r force_shutdown_if_timeout=true # vm might be forcefully shutdown if set to true
declare -r debug_mode=true # no action, only logs if set to true


###################################################
## Functions

# Halts execution until vm is no longer listed or timeout is exceeded
# $1 - name of vm to await for shutdown
# $2 - timeout (in seconds) - optional
await_vm_termination() {

  local -r vm_to_wait_for="$1"; shift
  local -ri timeout="$1"; shift

  local -i time_elapsed=1 # setting it to 0 makes it not a number apparently (went with workaround =1 here and -gt and +1 below)
  # until vm name no longer listed by virsh
  until ! virsh list | grep -q "${vm_to_wait_for}"
  do
    local timeout_warning=""
    if ! [ -z "${timeout}" ]; then
      timeout_warning="(timeout in $((timeout+1-time_elapsed))s)"
    fi
    echo "Waiting for shutdown of ${vm_to_shutdown} ${timeout_warning}"
    # wait
    sleep 1 && ((time_elapsed++))
    # break if timeout exceeded
    if [ ${time_elapsed} -gt ${timeout} ]; then
      echo "Timeout reached!"
      return 1
    fi
  done
  return 0
}

# Requests graceful shutdown of vm.
# $1 - name of vm to shutdown
shutdown_vm() {

  local -r vm_to_shutdown="$1"; shift

  echo "Gracefully shutting down VM: ${vm_to_shutdown}"
  if [ "$debug_mode" = true ]; then
    echo "no action taken, debug mode only..."
  else
    virsh shutdown "${vm_to_shutdown}"
  fi
}

# Forcefully shuts down vm.
# $1 - name of vm to shutdown
force_shutdown_vm() {

  local -r vm_to_shutdown="$1"; shift

  echo "Forcefully shutting down VM: ${vm_to_shutdown}"
  if [ "${debug_mode}" = true ]; then
    echo "no action taken, debug mode only..."
  else
    virsh destroy "${vm_to_shutdown}"
  fi
}

# Starts vm passed as argument
# $1 - name of vm to start
start_vm() {

  local -r vm_to_start="$1"; shift

  echo "Starting VM: ${vm_to_start}"
  if [ "${debug_mode}" = true ]; then
    echo "no action taken, debug mode only..."
  else
    virsh start "${vm_to_start}"
  fi  

}

# Alternates between two vms
# $1 - name of vm to shutdown
# $2 - name of vm to start
alternate_vms() {

  local -r vm_to_shutdown="$1"; shift
  local -r vm_to_start="$1"; shift

  shutdown_vm "${vm_to_shutdown}"
  await_vm_termination "${vm_to_shutdown}" "${graceful_shutdown_timeout}"

  # if vm still exists after waiting for request
  if ! virsh list | grep -q "${vm_to_shutdown}"; then
    # if authorized in global vars
    if [ "$force_shutdown_if_timeout" = true ]; then
      # force shutdown
      force_shutdown_vm "${vm_to_shutdown}"
      await_vm_termination "${vm_to_shutdown}" 10
    fi
  fi
  start_vm ${vm_to_start}
}

# Main funcion...
# The magic starts here
main() {

  # vm_to_start defaults to first one
  local vm_to_start="${vms_to_alternate[0]}"
  # vm_to_shutdown defaults to a display message
  local vm_to_shutdown="NO_ACTIVE_VM_FOUND"

  echo "Searching for active VMs:
  "
  local -r active_vms_list=$(virsh list)
  echo "${active_vms_list}
  "
  for i in "${!vms_to_alternate[@]}"
  do
    # if vm is listed as active
    if echo "${active_vms_list}" | grep -q "${vms_to_alternate[i]}"; then
      echo "${vms_to_alternate[i]} VM reported active!"
      # set it to shutdown
      vm_to_shutdown="${vms_to_alternate[i]}"
      # and the next one to start (if not last)
      if ! [ -z "${vms_to_alternate[i+1]}" ]; then
        vm_to_start="${vms_to_alternate[i+1]}"
      fi
      echo "next on list: ${vm_to_start}"
    fi
  done

  alternate_vms "${vm_to_shutdown}" "${vm_to_start}"
  exit 0
}

main
