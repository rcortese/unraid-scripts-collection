#!/bin/bash
set -e

###################################################
## User filled variables
##

# vm name as listed by virsh (same as on Unraid VM tab)
declare -r vm_name="Windows 10"

# list of devices to bind
declare -r -a devices_list=( "Logitech mouse" "K78 Keyboard" )

# timeout
declare -r -i timeout=60

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

  if virsh list | grep -q "$vm_name"; then
    return 0
  else
    return 1
  fi
}

# Bind device to vm
# $1 - device idVendor
# $2 - device idProduct
bind_device() {

  local -r idVendor="$1"; shift
  local -r idProduct="$1"; shift

  if [ "$debug_mode" = true ]; then
    echo "--- no action taken, debug mode only ---"
  else
    # virsh attach-device $vm_name --file usb_device.xml --current
  fi
}

# Main funcion...
# The magic starts here
main() {

  local -i time_elapsed=0
  until $time_elapsed -gt $timeout
  do
    if vm_is_active "$vm_name"; then
      echo "$vm_name active!"
      echo "binding devices..."
      for i in "${!devices_list[@]}"
      do
        echo "binding ${devices_list[i]} to $vm_name"
        # TODO:
        bind_device "id" "id"
      done
      # virsh bind usb device
      ((time_elapsed++)) # just in case
      break
    else
      echo "$vm_name not active yet..."
      sleep 1 && ((time_elapsed++))
    fi
  done

  sleep 1

  if ! vm_is_active "$vm_name"; then
    echo "Error: $vm_name not active!"
    exit 1
  # elif device not bound
    # echo device not bound
    # exit 1
  else
    echo "Success: devices have been bound to $vm_to_start!"
    exit 0
  fi
}

main
