#!/bin/bash

TBASE=$NMBASE/fig12
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
RBASE=$TBASE/Results

$TBASE/parse.py $RBASE
name=$RBASE/setup.csv
fname=$RBASE/filter.csv
result=$RBASE/result

$TBASE/filter.py $name > $fname

#################################################################
# get/set
#################################################################
echo \# `head -n1 $fname`                         > $result.lat.nic.4.256.1.0.csv
echo \# `head -n1 $fname`                         > $result.lat.nic.4.256.1.100.csv
echo \# `head -n1 $fname`                         > $result.lat.base.4.256.1.0.csv
echo \# `head -n1 $fname`                         > $result.lat.base.4.256.1.100.csv
echo \# `head -n1 $fname`                         > $result.lat.nic.4.65536.1.0.csv
echo \# `head -n1 $fname`                         > $result.lat.nic.4.65536.1.100.csv
echo \# `head -n1 $fname`                         > $result.lat.base.4.65536.1.0.csv
echo \# `head -n1 $fname`                         > $result.lat.base.4.65536.1.100.csv

# Name encoding:
#   4            threads
#   256/65536    cache size
#   1/0          set is always from cache area
#   100/0        get is always from cache area

grep nic-4 $fname      | grep \\-256\\-0      | grep \\-1, | grep -v inline                 | sort -t, -k16,16 -n >> $result.lat.nic.4.256.1.0.csv
grep nic-4 $fname      | grep \\-256\\-100    | grep \\-1, | grep -v inline                 | sort -t, -k16,16 -n >> $result.lat.nic.4.256.1.100.csv
grep base-4 $fname     | grep \\-256\\-0      | grep \\-1, |                                  sort -t, -k16,16 -n >> $result.lat.base.4.256.1.0.csv
grep base-4 $fname     | grep \\-256\\-100    | grep \\-1, |                                  sort -t, -k16,16 -n >> $result.lat.base.4.256.1.100.csv
grep nic-4 $fname      | grep \\-65536\\-0    | grep \\-1, | grep -v inline                 | sort -t, -k16,16 -n >> $result.lat.nic.4.65536.1.0.csv
grep nic-4 $fname      | grep \\-65536\\-100  | grep \\-1, | grep -v inline                 | sort -t, -k16,16 -n >> $result.lat.nic.4.65536.1.100.csv
grep base-4 $fname     | grep \\-65536\\-0    | grep \\-1, |                                  sort -t, -k16,16 -n >> $result.lat.base.4.65536.1.0.csv
grep base-4 $fname     | grep \\-65536\\-100  | grep \\-1, |                                  sort -t, -k16,16 -n >> $result.lat.base.4.65536.1.100.csv

paste $result.lat.base.4.256.1.0.csv   $result.lat.nic.4.256.1.0.csv           > $result.lat.all.256.1.0.csv
paste $result.lat.base.4.256.1.100.csv   $result.lat.nic.4.256.1.100.csv       > $result.lat.all.256.1.100.csv
paste $result.lat.base.4.65536.1.0.csv   $result.lat.nic.4.65536.1.0.csv       > $result.lat.all.65536.1.0.csv
paste $result.lat.base.4.65536.1.100.csv   $result.lat.nic.4.65536.1.100.csv   > $result.lat.all.65536.1.100.csv
# 
gnuplot mica_set.gp
