#!/bin/bash

if [ "$EUID" -ne 0 ]
then echo "Please run as root"
  exit
fi

mst start
RET=$?

if [[ $RET -ne 0 ]]; then
  echo "Failed to start mst.. please install mst from Mellanox Firmware Tools (MFT):"
  echo "https://www.mellanox.com/products/adapter-software/firmware-tools"
  exit $RET
fi

if [ -z "$(ls -A /dev/mst)" ]; then
  echo "No NVIDIA devices available. Please verify that running 'sudo mst start' works"
  exit -1
fi

for F in /dev/mst/*; do
  if mlxconfig -d /dev/mst/mt4119_pciconf0 q | grep -q MEMIC;
  then
    echo "$F is OK"
  else
    echo "$F does not support nicmem!"
    exit -1
  fi
done

exit 0
