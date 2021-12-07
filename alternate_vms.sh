#!/bin/bash

# Fill with the names of VMs to alternate between
VM0_NAME="Pop_OS"
VM1_NAME="Windows 10"

# Switches between two vms
# $1 - name of vm to shutdown
# $2 - name of vm to start
switch_vm() {
  virsh shutdown "$1"
  sleep 30
  virsh start "$2"
}

if virsh list | grep -q "$VM0_NAME"; then
  switch_vm "$VM0_NAME" "$VM1_NAME"
elif virsh list | grep -q "$VM1_NAME"; then
  switch_vm "$VM1_NAME" "$VM0_NAME"
fi
