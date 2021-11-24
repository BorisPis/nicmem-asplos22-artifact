#!/bin/bash

TBASE=$NMBASE/fig9
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
RBASE=$TBASE/Results

$TBASE/parse.py $RBASE/nat
$TBASE/parse.py $RBASE/lb

$TBASE/filter.py $RBASE/nat/setup.csv > $RBASE/nat/filter.csv 
$TBASE/filter.py $RBASE/lb/setup.csv  > $RBASE/lb/filter.csv 

# MEMTYPE
echo \# `head -n1 $RBASE/lb/filter.csv`                         > $RBASE/lb/result.ddio.nic.csv
echo \# `head -n1 $RBASE/lb/filter.csv`                         > $RBASE/lb/result.ddio.nic-inline.csv
echo \# `head -n1 $RBASE/lb/filter.csv`                         > $RBASE/lb/result.ddio.host.csv
echo \# `head -n1 $RBASE/lb/filter.csv`                         > $RBASE/lb/result.ddio.base.csv

echo \# `head -n1 $RBASE/nat/filter.csv`                         > $RBASE/nat/result.ddio.nic.csv
echo \# `head -n1 $RBASE/nat/filter.csv`                         > $RBASE/nat/result.ddio.nic-inline.csv
echo \# `head -n1 $RBASE/nat/filter.csv`                         > $RBASE/nat/result.ddio.host.csv
echo \# `head -n1 $RBASE/nat/filter.csv`                         > $RBASE/nat/result.ddio.base.csv

grep nic $RBASE/lb/filter.csv      | grep    inline | sort -t, -k22 -n >> $RBASE/lb/result.ddio.nic-inline.csv
grep nic $RBASE/lb/filter.csv      | grep -v inline | sort -t, -k22 -n >> $RBASE/lb/result.ddio.nic.csv
grep host $RBASE/lb/filter.csv     |                  sort -t, -k22 -n >> $RBASE/lb/result.ddio.host.csv
grep base $RBASE/lb/filter.csv     |                  sort -t, -k22 -n >> $RBASE/lb/result.ddio.base.csv

grep nic $RBASE/nat/filter.csv      | grep    inline | sort -t, -k22 -n >> $RBASE/nat/result.ddio.nic-inline.csv
grep nic $RBASE/nat/filter.csv      | grep -v inline | sort -t, -k22 -n >> $RBASE/nat/result.ddio.nic.csv
grep host $RBASE/nat/filter.csv     |                  sort -t, -k22 -n >> $RBASE/nat/result.ddio.host.csv
grep base $RBASE/nat/filter.csv     |                  sort -t, -k22 -n >> $RBASE/nat/result.ddio.base.csv

gnuplot fclick.gp
