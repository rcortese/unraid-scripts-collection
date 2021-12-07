#!/bin/bash

VM0_NAME="Pop_OS"
VM1_NAME="Windows 10"

if virsh list | grep -q "$VM0_NAME"; then
  sleep 30
  virsh start $VM1_NAME
elif virsh list | grep -q "$VM1_NAME"; then
  sleep 30
  virsh start $VM0_NAME
fi
