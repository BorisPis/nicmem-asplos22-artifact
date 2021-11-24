#!/bin/bash

if [ ! "$NMBASE" ]
then
  echo "Please run 'source scripts/env.sh' from the root directory"
  exit -1
fi

FASTCLICK=$NMBASE/fastclick/userlevel/click
TREX=$NMBASE/trex/linux_dpdk/build_dpdk/linux_dpdk/_t-rex-64
PCM=$NMBASE/tools/pcm
PCMM=$NMBASE/tools/pcm/pcm-memory.x
PERF=perf

if [ "$EUID" -ne 0 ]
then echo "Please run this as root"
  exit -1
fi

if [[ ! -a $FASTCLICK ]]; then
  echo "No fastclick binary available at $FASTCLICK. Checking if it is a client"
  if [[ ! -a $TREX ]]; then
    echo "No trex binary available at $TREX."
    echo "Not a client and not a server. Abort!"
    exit -1
  else
    echo "Trex is availble"
    echo "Preparing a client..."
    # Need setcap for all files being run
    sudo setcap 'cap_sys_rawio+pe cap_net_raw+pe cap_net_admin+pe cap_ipc_lock+pe' $TREX
    sudo chown root $TREX
    sudo chmod u+s $TREX
  fi
else
  echo "Fastclick is availble"
  echo "Preparing a server..."

  # Need setcap for all files being run
  sudo setcap 'cap_sys_rawio+pe cap_net_raw+pe cap_net_admin+pe cap_ipc_lock+pe' $FASTCLICK
  sudo chown root $FASTCLICK
  sudo chmod u+s $FASTCLICK

  if [[ -a $PCMM ]]; then
    sudo chown root $PCM/*.x
    sudo chmod u+s $PCM/*.x
  else
    echo "Missing pcm on server. Abort!"
    exit -1
  fi
fi

# # Need hugepage permissions
# sudo chown -R 777 /dev/hugepages/
# 
# # Need cpu permissions for ddio
# sudo chown -R 777 /dev/cpu/

echo 64 | sudo tee /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages >& /dev/null
#echo 8192 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

echo "Root has prepared all files for non-root users!"

exit 0
