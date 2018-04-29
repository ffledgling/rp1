#!/bin/bash

vmip() {
  vmipaddr=$(virsh net-dhcp-leases default | grep "$1" | awk '{print $5}')
  vmipaddr=${vmipaddr%/*}
  echo $vmipaddr
}

vmls() {
  virsh list --all
}
