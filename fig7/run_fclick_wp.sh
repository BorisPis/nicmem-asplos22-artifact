#!/bin/bash

cd `dirname $0`

[ -z "$NMBASE" ] && echo "Missing environment variable. Please run 'source scripts/env.h' from the root directory" && exit -1
[ -z "$REPEAT" ] && REPEAT=1

export TBASE=$NMBASE/fig7
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
export RBASE=$TBASE/Results
Test=fclick_wp

# Total runtime lower limit:
# repeat * core * rxdesc * ddio * memtype * pktsize * load * memsize * cpun * memn * write
#    1   *  1   *   1    *  4   *  4      *  1      *   1  *    6    *  1   *  5   *  1 =  480

sudo -E rm -rf $RBASE # some files belong to root

export IF1PCI=0000:3b:00.0
export IF2PCI=0000:5e:00.0 
export CORESS=( 7 )
export RXDESCS=( 256 512 1024 2048 )
export DDIO=( 0 2 8 11 )
export MEMTYPES=( nic-inline nic host base )
export PKT_SIZES=( 1500 )
export LOADS=( 200 )
# WorkPackage params
export WP_MEMSIZES=(1 2 4 8 16 32)
export WP_CPUS=( 1 )
export WP_MEMNS=( 2 4 6 8 10 )
export perf_cpus=2,4,6,8,10,12,14,16,18,20,22,24,26,28
export collect_perf=yes
export WP_WRITE=0 # read or write to memory

for memt in ${MEMTYPES[@]};
do
  export MEMTYPE=$memt
  for size in ${PKT_SIZES[@]};
  do
    export PKT_SIZE=$size
    for cores in ${CORESS[@]};
    do
      export CORES=$cores
      for rxdesc in ${RXDESCS[@]};
      do
        export RXDESC=$rxdesc
        for ddio in ${DDIO[@]};
        do
          export DDIO_WAYS=$ddio
          for memn in ${WP_MEMNS[@]};
          do
            export WP_MEMN=$memn
            for cpun in ${WP_CPUS[@]};
            do
              export WP_CPU=$cpun
              for memsize in ${WP_MEMSIZES[@]};
              do 
                export WP_MEMSIZE=$memsize
                for load in ${LOADS[@]};
                do
                  export LOAD=$load
                  export OUT_FILE=$RBASE/$Test-$memt-$size-$cores-$rxdesc-$ddio-$memn-$cpun-$memsize-$load
                  export repeat=$REPEAT
                  mkdir -p $OUT_FILE
                  echo "running $Test type $memt pkt_size $size cores $cores rxdesc $rxdesc ddio $ddio memn $memn cpun $cpun memsize $memsize load $load"
                  ./run_test.sh $Test
                done
              done
            done
          done
        done
      done
    done
  done
done
