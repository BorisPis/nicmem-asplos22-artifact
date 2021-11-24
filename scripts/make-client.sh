#!/bin/bash

if [ ! "$NMBASE" ]
then
  echo "Please run 'source scripts/env.sh' from the root directory"
  exit -1
fi

TREX=$NMBASE/trex
MICA=$NMBASE/micac

git submodule init
git submodule update

# compile dpdk assuming all dependencies were met 
if [ -z "$(ls -A $TREX/linux_dpdk/build_dpdk/linux_dpdk/_t-rex-64)" ]; then
  echo -ne 'Compilig trex...'
  cd $TREX/linux_dpdk
  ./b configure >& /dev/null
  ./b build >& /dev/null
  cd - >& /dev/null
  # verify it worked
  if [ -z "$(ls -A $TREX/linux_dpdk/build_dpdk/linux_dpdk/_t-rex-64)" ]; then
    echo "Trex compilation failed at $TREX. Please verify rdma-core version is v23"
    exit -1
  else
    echo Done
  fi
else
  echo 'Trex already exists... Skipping' # avoid overriding fastclick
fi

# compile mica assuming all dependencies were met 
echo -ne 'Compilig mica...'
cd $MICA
./configure_client.sh >& mica.log 
cd build
make -j netbench_client >> mica.log 2>&1
make -j netbench_client_latency >> mica.log 2>&1
cd ../.. >& /dev/null

if [ -z "$(ls -A $MICA/build/src/netbench_client)" ]; then
  echo "mica compilation failed at $MICA"
  exit -1
else
  echo Done
fi
