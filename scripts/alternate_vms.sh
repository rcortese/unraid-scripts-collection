#!/bin/bash
set -e

###################################################
## User filled variables
##


# names of VMs to alternate between (may be more than 2)
# if a VM is listed as active, the next one will be started. If no VM is active, the first one will be started
declare -r -a vms_to_alternate=( "Pop_OS" "Windows 10" )

# time to wait for a graceful shutdown to be considered success
declare -r graceful_shutdown_timeout=30

# should termination be forced if graceful reaches a timeout?
declare -r force_shutdown_if_timeout=true

# no action, only logs if set to true
declare -r debug_mode=true


##
## IMPORTANT: FILL THE VARIABLES ABOVE ACCORDINGLY
###################################################


###################################################
## Functions

# Returns true (0) if vm is listed as active
# $1 - name of vm to search for
vm_is_active() {

  local -r vm_name="$1"

  if virsh list | grep -q "${vm_name}"; then
    return 0
  else
    return 1
  fi
}

# Halts execution until vm is no longer listed or timeout is exceeded
# $1 - name of vm to await for shutdown
# $2 - timeout (in seconds) - optional
# $3 - termination type (for logging only) - optional
await_vm_termination() {
  local -r vm_name="$1"; shift
  local -ri timeout="$1"; shift
  local termination_type="${1:-shutdown}"

  local -i time_elapsed=1 # setting it to 0 makes it not a number apparently (went with workaround =1 here and -gt and +1 below)
  # until vm name no longer listed by virsh
  until ! vm_is_active "${vm_name}"
  do
    local timeout_warning=""
    if ! [ -z "${timeout}" ]; then
      timeout_warning="(timeout in $((timeout+1-time_elapsed))s)"
    fi
    echo "Waiting for ${termination_type} of ${vm_name} ${timeout_warning}"
    # wait
    sleep 1 && ((time_elapsed++))
    # break if timeout exceeded
    if [ ${time_elapsed} -gt ${timeout} ]; then
      echo "Timeout reached!"
      break
    fi
  done
}

# Requests graceful shutdown of vm.
# $1 - name of vm to shutdown
shutdown_vm() {

  local -r vm_name="$1"

  echo "Gracefully shutting down VM: ${vm_name}"
  if [ "$debug_mode" = true ]; then
    echo "no action taken, debug mode only..."
  else
    virsh shutdown "${vm_name}"
  fi
}

# Forcefully shuts down vm.
# $1 - name of vm to shutdown
force_shutdown_vm() {

  local -r vm_name="$1"

  echo "Forcefully shutting down VM: ${vm_name}"
  if [ "${debug_mode}" = true ]; then
    echo "no action taken, debug mode only..."
  else
    virsh destroy "${vm_name}"
  fi
}

# Starts vm passed as argument
# $1 - name of vm to start
start_vm() {

  local -r vm_name="$1"

  echo "Starting VM: ${vm_name}"
  if [ "${debug_mode}" = true ]; then
    echo "no action taken, debug mode only..."
  else
    virsh start "${vm_name}"
  fi
}

# Alternates between two vms
# $1 - name of vm to shutdown
# $2 - name of vm to start
alternate_vms() {

  local -r vm_to_shutdown="$1"; shift
  local -r vm_to_start="$1"

  if [ -z "${vm_to_shutdown}" ]; then
    echo "No vm on the list was reported active..."
  else
    shutdown_vm "${vm_to_shutdown}"
    await_vm_termination "${vm_to_shutdown}" "${graceful_shutdown_timeout}" "graceful shutdown"

    if vm_is_active "${vm_to_shutdown}"; then
      if [ "$force_shutdown_if_timeout" = true ]; then
        force_shutdown_vm "${vm_to_shutdown}"
        await_vm_termination "${vm_to_shutdown}" 10 "forced shutdown"
      fi
    fi
  fi

  start_vm ${vm_to_start}
}

# Main funcion...
# The magic starts here
main() {

  # vm_to_start defaults to first one
  local vm_to_start="${vms_to_alternate[0]}"
  local vm_to_shutdown

  echo "Searching for active VMs:
  "
  echo "$(virsh list)
  "
  for i in "${!vms_to_alternate[@]}"
  do
    if vm_is_active "${vms_to_alternate[i]}"; then
      echo "${vms_to_alternate[i]} VM reported active!"
      # set active vm for shutdown
      vm_to_shutdown="${vms_to_alternate[i]}"
      # set next listed vm for startup
      if ! [ -z "${vms_to_alternate[i+1]}" ]; then
        vm_to_start="${vms_to_alternate[i+1]}"
      fi
      echo "next on list: ${vm_to_start}"
    fi
  done

  alternate_vms "${vm_to_shutdown}" "${vm_to_start}"
  sleep 10
  if ! vm_is_active "${vm_to_start}"; then
    echo "ERROR: vm ${vm_to_start} seems to not have been started!"
    exit 1
  else
    echo "SUCCESS: vm ${vm_to_start} seems to have been started successfully!"
    exit 0
  fi
}

main
