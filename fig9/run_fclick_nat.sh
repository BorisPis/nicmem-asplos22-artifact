#!/bin/bash

cd `dirname $0`

[ -z "$NMBASE" ] && echo "Missing environment variable. Please run 'source scripts/env.h' from the root directory" && exit -1
[ -z "$REPEAT" ] && REPEAT=1

export TBASE=$NMBASE/fig9
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
export RBASE=$TBASE/Results
Test=fclick_natlb

sudo -E rm -rf $RBASE # clean up Results

export IF1PCI=0000:3b:00.0
export IF2PCI=0000:5e:00.0 
export CORESS=( 7 )
export DDIO=( 0 2 3 4 5 6 7 8 9 10 11 ) # can't set 1 DDIO ways
export MEMTYPES=( nic-inline nic host base )
export PKT_SIZES=( 1500 )
export LOAD=200
export perf_cpus=2,4,6,8,10,12,14,16,18,20,22,24,26,28
export collect_perf=yes
export NATLB=( 1 0 )

for natlb in ${NATLB[@]};
do
  export IS_NAT=$natlb
  if [ "$natlb" == "1" ]; then
    export RBASE=$TBASE/Results/nat
  else
    export RBASE=$TBASE/Results/lb
  fi
  for memt in ${MEMTYPES[@]};
  do
    export MEMTYPE=$memt
    for size in ${PKT_SIZES[@]};
    do
      export PKT_SIZE=$size
      for cores in ${CORESS[@]};
      do
        export CORES=$cores
        for ddio in ${DDIO[@]};
        do
          export DDIO_WAYS=$ddio
          export OUT_FILE=$RBASE/$Test-$memt-$size-$cores-$ddio
          mkdir -p $RBASE
          export repeat=$REPEAT
          mkdir -p $OUT_FILE
          echo "running $Test cores type $memt pkt_size $size cores $cores ddio $ddio"
          ./run_test.sh $Test
        done
      done
    done
  done
done
