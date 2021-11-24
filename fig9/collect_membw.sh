#!/bin/bash

pcm=$NMBASE/tools/pcm/
time=5
base=`dirname $0`

echo "<$OUT_FILE>"
function collect_net_cpu {
  echo if1 enp59s0
  $base/sample_eth.py $[$time*4] enp59s0 | tee -a $OUT_FILE/eth.txt | tee -a $OUT_FILE/if1.eth.txt &
  echo " out collect cpu" >&2
}

function collect_net2 {
  echo " in collect net2" >&2
  echo if2 enp94s0
  $base/sample_eth.py $[$time*4] enp94s0 | tee -a $OUT_FILE/if2.eth.txt &
  echo " out collect net2" >&2
}

function collect_net3 {
  echo " in collect net3" >&2
  echo if3 $if3
  $base/sample_eth.py $[$time*4] $if3 | tee -a $OUT_FILE/if3.eth.txt &
  echo " out collect net3" >&2
}

function collect_net4 {
  echo " in collect net4" >&2
  echo if4 $if4
  $base/sample_eth.py $[$time*4] $if4 | tee -a $OUT_FILE/if4.eth.txt &
  echo " out collect net4" >&2
}

function collect_mem_bw {
  echo " in collect mem bw" >&2
  sudo -E $pcm/pcm-memory.x 1 -- sleep $[$time*2] | tee -a $OUT_FILE/memory.txt
  echo " out collect mem bw" >&2
}

function collect_pcm {
  echo " in collect pcm" >&2
  sudo -E $pcm/pcm-pcie.x -e -B 1 -- sleep $time | tee -a $OUT_FILE/pcie.txt
  #$pcm/pcm.x 1 -- sleep $time| tee -a $OUT_FILE/pcm.txt 
  echo " out collect pcm" >&2
}

function collect_perf {
  echo " in collect perf" >&2
  echo CPU list: $perf_cpus
  echo perf stat -a -C $perf_cpus -e duration_time,task-clock,cycles,instructions,cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses -x, -o $OUT_FILE/perf_stat.txt --append sleep $[$time*4]
  sudo -E perf stat -a -C $perf_cpus -e duration_time,task-clock,cycles,instructions,cache-references,cache-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses -x, -o $OUT_FILE/perf_stat.txt --append sleep $[$time*4] &
  echo " out collect perf" >&2
}

function collect_neo1 {
    echo " in collect neo-host1" >&2
    echo if1 enp59s0 0000:5e:00.0
    sudo -E timeout -s 2 $[$time*4] python /opt/neohost/sdk/get_device_performance_counters.py --mode=shell --dev-uid=0000:5e:00.0 --run-loop | tee -a $OUT_FILE/if1.neo.txt &
    echo " out collect neo-host1" >&2
}

function collect_neo2 {
    echo " in collect neo-host2" >&2
    echo if2 enp94s0 0000:3b:00.0
    sudo -E timeout -s 2 $[$time*4] python /opt/neohost/sdk/get_device_performance_counters.py --mode=shell --dev-uid=0000:3b:00.0 --run-loop | tee -a $OUT_FILE/if2.neo.txt &
    echo " out collect neo-host2" >&2
}

[ "$collect_net_cpu" != "no" ] && collect_net_cpu
[ "$collect_net2" == "yes" ] && collect_net2
[ "$collect_net3" == "yes" ] && collect_net3
[ "$collect_net4" == "yes" ] && collect_net4
[ "$collect_perf" == "yes" ] && collect_perf
[ "$collect_mem_bw" != "no" ] && collect_mem_bw
[ "$collect_pcm" != "no" ] && collect_pcm
[ "$collect_neo1" != "no" ] && collect_neo1
[ "$collect_neo2" != "no" ] && collect_neo2

echo "Data collected"
