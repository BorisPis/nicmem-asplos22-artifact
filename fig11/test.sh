#~/bin/bash

LD_LIB="LD_LIBRARY_PATH=/usr/local/lib/x86_64-linux-gnu" #dpdk's install path
basedir=`dirname \`realpath $0\``
basedir=`dirname \`realpath $0\``
MICAS_BASE=$NMBASE/micas/build
MICAC_BASE=$NMBASE/micac/build

# output directory
[ -z "$OUT_FILE" ] && OUT_FILE=/tmp
[ -z "$TIME" ] && TIME=30

# mica params
[ -z "$REQUEST_RATE" ] && REQUEST_RATE=0 #3500000
[ -z "$THREADS" ] && THREADS=4
[ -z "$PREPOPULATION_FILE" ] && PREPOPULATION_FILE=conf_prepopulate.x 
[ -z "$MACHINE_FILE" ] && MACHINE_FILE=conf_machines.x.$THREADS
[ -z "$MACHINE_FILE_CLIENT" ] && MACHINE_FILE_CLIENT=conf_machines_client.x.$THREADS
[ -z "$WORKLOAD_FILE" ] && WORKLOAD_FILE=workload.x.$THREADS
[ -z "$KEYS" ] &&     export KEYS=838860
[ -z "$KEY_SIZE" ] && export KEY_SIZE=128
[ -z "$VAL_SIZE" ] && export VAL_SIZE=1024
[ -z "$SKEW" ] && export SKEW=0.0
[ -z "$GET_RATIO" ] && export GET_RATIO=1.0
[ -z "$MEMTYPE" ] && MEMTYPE="base"
[ -z "$MAX_NICMEM_KEY" ] && export MAX_NICMEM_KEY=100 # percentages
[ -z "$NIC_RATIO" ] && export NIC_RATIO=999 # if greater than 100% than ignored
[ -z "$FORCE_SET_NIC" ] && export FORCE_SET_NIC=0 # force sets to go to nic memory 

_MAX_NICMEM_KEY=$[ $KEYS * $MAX_NICMEM_KEY / 100 ]
[ ! -z "$MAX_NICMEM_KEY_OVERRIDE" ] && export _MAX_NICMEM_KEY=$MAX_NICMEM_KEY_OVERRIDE # percentages
echo "setting max NIC key $_MAX_NICMEM_KEY" 
#--------------------------------------------------

(( "$TIME" < "30" )) && echo "TIME ($TIME) must be greater than 30" && exit -1
#-------------------------------------------------
export PUT_RATIO=`python -c "print 1.0 - $GET_RATIO"`
# create prepopulation file
envsubst '${KEYS} ${KEY_SIZE} ${VAL_SIZE}' < $PREPOPULATION_FILE > $PREPOPULATION_FILE.tmp
envsubst '${KEYS} ${KEY_SIZE} ${VAL_SIZE} ${GET_RATIO} ${PUT_RATIO} ${SKEW}' < $WORKLOAD_FILE > $WORKLOAD_FILE.tmp
envsubst '${KEYS} ' < $MACHINE_FILE > $MACHINE_FILE.tmp
envsubst '${KEYS} ' < $MACHINE_FILE_CLIENT > $MACHINE_FILE_CLIENT.tmp
#--------------------------------------------------

# translate memtype to parameters
[ -z "$MLXINLINE" ] && MLXINLINE="0"
if [ $MEMTYPE == "host" ]; then
	echo "[+] host split memory"
	_SPLIT=1
	_NICMEM=0
elif [ $MEMTYPE == "base" ]; then
	echo "[+] host baseline memory"
	_SPLIT=0
	_NICMEM=0
elif [ $MEMTYPE == "nic" ]; then
	echo "[+] nic memory"
	_SPLIT=1
	_NICMEM=1
elif [ $MEMTYPE == "nic-inline" ]; then
	echo "[+] nic memory"
        MLXINLINE=1
	_SPLIT=1
	_NICMEM=1
else
	echo "[-] unknown memtype $MEMTYPE"
	exit -1
fi

if [ $MLXINLINE == "0" ]; then
  echo '[-] not using inline'
  MLXFLAGS="" # MLXFLAGS="txq_inline_min=64"
else
  echo '[+] inlining 72 bytes'
  MLXFLAGS="txq_inline_min=72"
fi
#--------------------------------------------------

# kill previous instances
sudo pkill -f netbench_server
sleep 3 # time for the process to die

# # kill the load generator
echo ssh $loader1 sudo pkill --signal SIGINT netbench_client
ssh $loader1 sudo pkill --signal SIGINT netbench_client
#-------------------------------------------------

# prepare loader files
TMP_DATE=`date +"%y_%m_%d_%H.%M.%S"`
echo "[+] preparing loader files at /tmp/$TMP_DATE"
ssh $loader1 mkdir /tmp/$TMP_DATE
scp $MACHINE_FILE_CLIENT.tmp $loader1:/tmp/$TMP_DATE
scp $WORKLOAD_FILE.tmp $loader1:/tmp/$TMP_DATE
#-------------------------------------------------

# run new mica instance using GENERIC values
echo sudo -E $LD_LIB $MICAS_BASE/src/netbench_server_latency $MACHINE_FILE.tmp server 0 0 $PREPOPULATION_FILE.tmp $REQUEST_RATE $_SPLIT $_NICMEM $MLXINLINE $_MAX_NICMEM_KEY
sudo -E $LD_LIB $MICAS_BASE/src/netbench_server_latency $MACHINE_FILE.tmp server 0 0 $PREPOPULATION_FILE.tmp $REQUEST_RATE $_SPLIT $_NICMEM $MLXINLINE $_MAX_NICMEM_KEY | tee -a $OUT_FILE/mica_server.txt &
# it takes 20 seconds to boot 1 mica therad 
sleep 20
#--------------------------------------------------

#sudo ./src/netbench_client_latency my_conf_machines_1_EREW_0.5 client0 0 0 w_conf_workload_2_uniform_1.00_0.00_0.00_1
echo "ssh $loader1 \"cd /tmp/$TMP_DATE; sudo -E $MICAC_BASE/src/netbench_client_latency $MACHINE_FILE_CLIENT.tmp client0 0 0 $REQUEST_RATE $NIC_RATIO $_MAX_NICMEM_KEY $FORCE_SET_NIC $WORKLOAD_FILE.tmp\""
ssh $loader1 "cd /tmp/$TMP_DATE; sudo -E $MICAC_BASE/src/netbench_client_latency $MACHINE_FILE_CLIENT.tmp client0 0 0 $REQUEST_RATE $NIC_RATIO $_MAX_NICMEM_KEY $FORCE_SET_NIC $WORKLOAD_FILE.tmp" | tee -a $OUT_FILE/mica.txt &
sleep $[ $TIME - 20 ]
#--------------------------------------------------

# get latency stats
for i in `seq 0 $[ $THREADS - 1]`; do
  scp $loader1:/tmp/$TMP_DATE/output_latency.$i.tmp /tmp/output_latency.$i
  cat /tmp/output_latency.$i >> $OUT_FILE/output_latency.$i
done
#--------------------------------------------------

# kill all
ssh $loader1 sudo pkill netbench_client
sudo pkill netbench_server
#-------------------------------------------------

env > $OUT_FILE/env.txt
