#!/bin/bash

basedir=`dirname \`realpath $0\``
DPDK_BASE=$NMBASE/dpdk/build
FCLICK_BASE=$NMBASE/fastclick/
TREX_BASE=$NMBASE/trex-core/scripts

# output directory
[ -z "$OUT_FILE" ] && OUT_FILE=/tmp

# click params
[ -z "$IF1PCI" ] && IF1PCI=0000:3b:00.0 # PCIe BDF for $if1 on dante732

# click params
[ -z "$MEMTYPE" ] && MEMTYPE="base"

[ -z "$TIME" ] && TIME=20
[ -z "$WARMUP" ] && WARMUP=0
[ -z "$PKT_SIZE" ] && PKT_SIZE=1500
[ -z "$CORES" ] && CORES=1

# trex params
[ -z "$LOAD" ] && LOAD=200
[ -z "$IS_NAT" ] && IS_NAT=1

## generic fastclick script parameters (see [nat|lb].$PORTS.npf)
[ -z $CAPACITY ] && echo Missing CAPACITY setting to 20000000 && export CAPACITY=10000000 
[ -z $CPUS1 ] && echo Missing CPUS1 setting to CORES=$CORES &&   export CPUS1=$CORES
[ -z $CPUS2 ] && echo Missing CPUS2 setting to CORES=$CORES &&   export CPUS2=$CORES
[ -z $RXDESC ] && echo Missing RXDESC setting to 1024 &&         export RXDESC=1024
[ -z $DDIO_WAYS ] && echo Missing DDIO_WAYS setting to 2 &&      export DDIO_WAYS=2
[ -z $HDS_QUEUES ] && echo Missing HDS_QUEUES setting to -1 &&    export HDS_QUEUES=-1

[ -z "$MLXINLINE" ] && MLXINLINE="0"
[ -z "$MLXCOMPRESS" ] && MLXCOMPRESS="0"
[ -z "$MLXMPRQ" ] && MLXMPRQ="0"

if [ $MEMTYPE == "host" ]; then
	echo "[+] host split memory"
	_MEMTYPE="--dpdk-split"
elif [ $MEMTYPE == "base" ]; then
	echo "[+] host baseline memory"
	_MEMTYPE=""
elif [ $MEMTYPE == "nic" ]; then
	echo "[+] nic memory"
	_MEMTYPE="--dpdk-nicmem --dpdk-split"
elif [ $MEMTYPE == "nic-inline" ]; then
	echo "[+] nic memory"
	_MEMTYPE="--dpdk-nicmem --dpdk-split"
        MLXINLINE="1"
else
	echo "[-] unknown memtype $MEMTYPE"
	exit -1
fi

if [ $MLXINLINE == "0" ]; then
  echo '[-] not using inline'
  MLXFLAGS="" # MLXFLAGS="txq_inline_min=64"
else
  echo '[+] inlining 64 bytes'
  MLXFLAGS="txq_inline_min=64"
fi

# try to use many cores
CORE_MASK="0xfffffffc"

(( "$TIME" <= "10" )) && echo "TIME ($TIME) must be greater than 10" && exit -1

IF1PCI_FLAGS=,$MLXFLAGS,rxq_cqe_comp_en=0,mprq_en=0
# single/dual port
if [ -z "${IF2PCI+x}" ]; then
	echo "[+] single port" $IF1PCI
	PORTS_MASK=1
	PORTS=1
	IF2PCI_PREFIX=""
        IF2PCI_FLAGS=""
else
	echo "[+] dual port" $IF1PCI " " $IF2PCI
	PORTS_MASK=3 # PORTS_MASK is a mask 3=0x11 (two ports)
	PORTS=2
	IF2PCI_PREFIX="-w "
        IF2PCI_FLAGS=,$MLXFLAGS,rxq_cqe_comp_en=0,mprq_en=0
fi

#-------------------------------------------------
# kill previous instances
sudo pkill -f $FCLICK_BASE/bin/click
sleep 3 # time for the process to die

#-------------------------------------------------

# run new click instance using GENERIC values
export STARTUP=$[$WARMUP+10]
export FCLICK_TIME=$[$TIME-$WARMUP-10]
if [ "$IS_NAT" == "1" ]; then
  envsubst '${FCLICK_TIME} ${STARTUP} ${CAPACITY} ${CPUS1} ${CPUS2} ${RXDESC} ${DDIO_WAYS} ${HDS_QUEUES}' < nat.x.$PORTS.npf > nat.envsubst.$PORTS.npf 
  echo $FCLICK_BASE/bin/click $_MEMTYPE --dpdk -c $CORE_MASK -w $IF1PCI,$IF1PCI_FLAGS $IF2PCI_PREFIX $IF2PCI$IF2PCI_FLAGS  -- nat.envsubst.$PORTS.npf 
  sudo -E $FCLICK_BASE/bin/click $_MEMTYPE --dpdk -c $CORE_MASK -w $IF1PCI,$IF1PCI_FLAGS $IF2PCI_PREFIX $IF2PCI$IF2PCI_FLAGS  -- nat.envsubst.$PORTS.npf |& tee -a $OUT_FILE/fclick_nat.txt &
else
  envsubst '${FCLICK_TIME} ${STARTUP} ${CAPACITY} ${CPUS1} ${CPUS2} ${RXDESC} ${DDIO_WAYS} ${HDS_QUEUES}' < lb.x.$PORTS.npf > lb.envsubst.$PORTS.npf 
  echo $FCLICK_BASE/bin/click $_MEMTYPE --dpdk -c $CORE_MASK -w $IF1PCI,$IF1PCI_FLAGS $IF2PCI_PREFIX $IF2PCI$IF2PCI_FLAGS  -- lb.envsubst.$PORTS.npf 
  sudo -E $FCLICK_BASE/bin/click $_MEMTYPE --dpdk -c $CORE_MASK -w $IF1PCI,$IF1PCI_FLAGS $IF2PCI_PREFIX $IF2PCI$IF2PCI_FLAGS  -- lb.envsubst.$PORTS.npf |& tee -a $OUT_FILE/fclick_nat.txt &
fi

sleep 10

# trex warmup
if [ $WARMUP == "0" ]; then
	echo "Skipping warmup"
else
	echo python trex/stl_imix.py -s $loader1 -p trex/imix_lat.py -d $WARMUP -m $LOAD% -l $PKT_SIZE --ports $PORS
	python trex/stl_imix.py -s $loader1 -p trex/imix_lat.py -d $WARMUP -m $LOAD% -l $PKT_SIZE --ports $PORTS_MASK
fi

# run trex load-generator
echo python trex/stl_imix.py -s $loader1 -p trex/imix_lat.py -d $FCLICK_TIME -m $LOAD% -l $PKT_SIZE --ports $PORTS_MASK
python trex/stl_imix.py -s $loader1 -p trex/imix_lat.py -d $FCLICK_TIME -m $LOAD% -l $PKT_SIZE --ports $PORTS_MASK |& tee -a $OUT_FILE/trex.txt

# kill this instances
sudo pkill -f $FCLICK_BASE/bin/click
#-------------------------------------------------

env > $OUT_FILE/env.txt
