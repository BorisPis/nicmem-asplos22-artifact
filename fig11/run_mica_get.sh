#!/bin/bash

cd `dirname $0`

[ -z "$NMBASE" ] && echo "Missing environment variable. Please run 'source scripts/env.h' from the root directory" && exit -1
[ -z "$REPEAT" ] && REPEAT=1

TBASE=$NMBASE/fig11
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
RBASE=$TBASE/Results
Test=mica_get

echo "source $TBASE/config.sh"
source $TBASE/config.sh | tee $RBASE/test_raw.txt
export NOCONFIG=1

if [[ ! -a /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages ]]; then
  echo "[-] Missing 2MB hugepage mount. Aborting!"
  exit -1
fi

# Total runtime lower limit:
# 2 * 2 * 6 * 1.5 = 36min

export THREADSS=( 4 )
# export MEMTYPES=( nic-inline nic host base )
export MEMTYPES=( nic base )
export MAX_NICMEM_KEY_OVERRIDES=( 256 65536 )
export LOADS=( 16000000 ) # this gets divided according to number of threads below
export GET_RATIO=1.0
export NIC_RATIOS=( `seq 0 20 100` )
export SKEW=0.0
skew=$SKEW

export perf_cpus=0,2,4,6
export collect_perf=yes

for memt in ${MEMTYPES[@]};
do
  export MEMTYPE=$memt
  for threads in ${THREADSS[@]};
  do
    export THREADS=$threads
    for load in ${LOADS[@]};
    do
      export REQUEST_RATE=$[$load/$threads]
      echo "using request rate $REQUEST_RATE"
      for maxkey in ${MAX_NICMEM_KEY_OVERRIDES[@]};
      do
        export MAX_NICMEM_KEY_OVERRIDE=$maxkey
        for nicr in ${NIC_RATIOS[@]};
        do
          export NIC_RATIO=$nicr
          export OUT_FILE=$RBASE/$Test-$memt-$threads-$load-$skew-$maxkey-$nicr
          export repeat=$REPEAT
          mkdir -p $OUT_FILE
          echo "running $Test type $memt threads $threads load $load skew $skew maxkey $maxkey nicratio $nicr"
          ./run_test.sh $Test
        done
      done
    done
  done
done
