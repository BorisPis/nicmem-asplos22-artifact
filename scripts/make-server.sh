#!/bin/bash

if [ ! "$NMBASE" ]
then
  echo "Please run 'source scripts/env.sh' from the root directory"
  exit -1
fi

RDMA=$NMBASE/rdma-core-server
FASTCLICK=$NMBASE/fastclick
DPDK=$NMBASE/dpdk
MICA=$NMBASE/micas
PCM=$NMBASE/tools/pcm

git submodule init
git submodule update

# compile rdma-core assuming all dependencies were met 
echo -ne 'Compilig rdma-core...'
cd $RDMA
./build.sh >& rdma.log
cmake . >> rdma.log 2>&1
make -j >& rdma.make.log
sudo -E make -j install >& rdma.make-install.log
cd - >& /dev/null

if [ -z "$(ls -A $RDMA/lib/libibverbs.so)" ]; then
  echo "rdma-core compilation failed at $RDMA"
  exit -1
else
  echo Done
fi

if [ -z "$(echo $PKG_CONFIG_PATH | grep rdma-core-server )" ]; then
  echo "PKG_CONFIG_PATH is missing rdma-core-server"
  exit -1
else
  echo Done
fi

# compile dpdk assuming all dependencies were met 
echo -ne 'Compilig dpdk...'
cd $DPDK
meson build >& dpdk.log
ninja -C build >> dpdk.log 2>&1
sudo ninja -C build install > dpdk-install.log 2>&1
cd - >& /dev/null

if [ -z "$(ls -A $DPDK/build)" ]; then
  echo "dpdk compilation failed at $DPDK"
  exit -1
else
  echo Done
fi

# compile fastclick only if missing -- it assumes dpdk is pre-installed
if [ -z "$(ls -A $FASTCLICK/userlevel/click)" ]; then
  echo -ne 'Compilig fastclick...'
  cd $FASTCLICK
  ./configure --enable-dpdk-pool --enable-dpdk --enable-intel-cpu --verbose --enable-select=poll CFLAGS="-O3" CXXFLAGS="-std=c++11 -O3" --disable-dynamic-linking --enable-poll --enable-bound-port-transfer --enable-local --enable-flow --disable-task-stats --disable-cpu-load --enable-dpdk-packet --disable-clone --disable-dpdk-softqueue --enable-research >& fastclick.log
  make -j >> fastclick.log 2>&1
  cd - >& /dev/null
else
  echo 'Fastclick already exists... Skipping' # avoid overriding fastclick
fi

if [ -z "$(ls -A $FASTCLICK/userlevel/click)" ]; then
  echo "Fastclick compilation failed at $FASTCLICK"
  exit -1
else
  echo Done
fi

# compile mica assuming all dependencies were met 
echo -ne 'Compilig mica...'
cd $MICA
./configure_server.sh >& mica.log 
cd build
make -j netbench_server >> mica.log 2>&1
make -j netbench_server_latency >> mica_lat.log 2>&1
cd ../.. >& /dev/null

if [ -z "$(ls -A $MICA/build/src/netbench_server)" ]; then
  echo "mica compilation failed at $MICA"
  exit -1
else
  echo Done
fi

# compile pcm
cd $PCM
make -j >& /dev/null
cd - >& /dev/null

if [ -z "$(ls -A $PCM/pcm-memory.x)" ]; then
  echo "pcm compilation failed at $DPDK"
  exit -1
else
  echo Done
fi

######################
# Prepare network
#####################
export mtu=1500
export ip1=10.1.4.100
export ip2=10.1.130.100
sudo -E ifconfig $if1 $ip1 netmask 255.255.255.0 mtu $mtu
sudo -E ifconfig $if2 $ip2 netmask 255.255.255.0 mtu $mtu
sudo -E ethtool -A $if1 rx off tx off
sudo -E ethtool -A $if2 rx off tx off

export dip1=10.1.4.38
export dip2=10.1.130.30
export dif1=enp59s0f1
export dif2=enp94s0f1

ssh $loader1 sudo -E ifconfig $dif1 $dip1 netmask 255.255.255.0 mtu $mtu
ssh $loader1 sudo -E ifconfig $dif2 $dip2 netmask 255.255.255.0 mtu $mtu
ssh $loader1 sudo -E ethtool -A $dif1 rx off tx off
ssh $loader1 sudo -E ethtool -A $dif2 rx off tx off
