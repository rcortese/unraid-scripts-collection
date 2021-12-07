#!/bin/bash

# Fill with the names of VMs to alternate between
VM0_NAME="Pop_OS"
VM1_NAME="Windows 10"

# Switches between two vms
# $1 - name of vm to shutdown
# $2 - name of vm to start
switch_vm() {
  local -r vm_to_shutdown="$1"; shift
  local -r vm_to_start="$1"; shift
  virsh shutdown "$vm_to_shutdown"
  sleep 30
  virsh start "$vm_to_start"
}

if virsh list | grep -q "$VM0_NAME"; then
  switch_vm "$VM0_NAME" "$VM1_NAME"
else
  switch_vm "$VM1_NAME" "$VM0_NAME"
fi
