#!/bin/bash

TBASE=$NMBASE/fig8
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
RBASE=$TBASE/Results

$TBASE/parse.py $RBASE/nat
$TBASE/parse.py $RBASE/lb

$TBASE/filter.py $RBASE/nat/setup.csv > $RBASE/nat/filter.csv 
$TBASE/filter.py $RBASE/lb/setup.csv  > $RBASE/lb/filter.csv 

# MEMTYPE
echo \# `head -n1 $RBASE/lb/filter.csv`                         > $RBASE/lb/result.lat.nic.csv
echo \# `head -n1 $RBASE/lb/filter.csv`                         > $RBASE/lb/result.lat.nic-inline.csv
echo \# `head -n1 $RBASE/lb/filter.csv`                         > $RBASE/lb/result.lat.host.csv
echo \# `head -n1 $RBASE/lb/filter.csv`                         > $RBASE/lb/result.lat.base.csv

echo \# `head -n1 $RBASE/nat/filter.csv`                         > $RBASE/nat/result.lat.nic.csv
echo \# `head -n1 $RBASE/nat/filter.csv`                         > $RBASE/nat/result.lat.nic-inline.csv
echo \# `head -n1 $RBASE/nat/filter.csv`                         > $RBASE/nat/result.lat.host.csv
echo \# `head -n1 $RBASE/nat/filter.csv`                         > $RBASE/nat/result.lat.base.csv

grep nic $RBASE/lb/filter.csv      | grep    inline | sort -t, -k13 -n >> $RBASE/lb/result.lat.nic-inline.csv
grep nic $RBASE/lb/filter.csv      | grep -v inline | sort -t, -k13 -n >> $RBASE/lb/result.lat.nic.csv
grep host $RBASE/lb/filter.csv     |                  sort -t, -k13 -n >> $RBASE/lb/result.lat.host.csv
grep base $RBASE/lb/filter.csv     |                  sort -t, -k13 -n >> $RBASE/lb/result.lat.base.csv

grep nic $RBASE/nat/filter.csv      | grep    inline | sort -t, -k13 -n >> $RBASE/nat/result.lat.nic-inline.csv
grep nic $RBASE/nat/filter.csv      | grep -v inline | sort -t, -k13 -n >> $RBASE/nat/result.lat.nic.csv
grep host $RBASE/nat/filter.csv     |                  sort -t, -k13 -n >> $RBASE/nat/result.lat.host.csv
grep base $RBASE/nat/filter.csv     |                  sort -t, -k13 -n >> $RBASE/nat/result.lat.base.csv

gnuplot fclick.gp
