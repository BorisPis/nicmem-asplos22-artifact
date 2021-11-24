#!/bin/bash

TBASE=$NMBASE/fig11
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
RBASE=$TBASE/Results

$TBASE/parse.py $RBASE
name=$RBASE/setup.csv
fname=$RBASE/filter.csv
result=$RBASE/result

$TBASE/filter.py $name > $fname

#################################################################
# 100% get
#################################################################
echo \# `head -n1 $fname`                         > $result.lat.nic.4.256.csv
echo \# `head -n1 $fname`                         > $result.lat.base.4.256.csv
echo \# `head -n1 $fname`                         > $result.lat.nic.4.65536.csv
echo \# `head -n1 $fname`                         > $result.lat.base.4.65536.csv

echo \# `head -n1 $fname`                         > $result.lat.nic.1.256.csv
echo \# `head -n1 $fname`                         > $result.lat.base.1.256.csv
echo \# `head -n1 $fname`                         > $result.lat.nic.1.65536.csv
echo \# `head -n1 $fname`                         > $result.lat.base.1.65536.csv

# 4 threads
grep nic-4 $fname      | grep \\-256\\- | grep -v inline                 | sort -t, -k16,16 -n >> $result.lat.nic.4.256.csv
grep base-4 $fname     | grep \\-256\\- |                                  sort -t, -k16,16 -n >> $result.lat.base.4.256.csv
grep nic-4 $fname      | grep \\-65536\\- | grep -v inline                 | sort -t, -k16,16 -n >> $result.lat.nic.4.65536.csv
grep base-4 $fname     | grep \\-65536\\- |                                  sort -t, -k16,16 -n >> $result.lat.base.4.65536.csv
paste $result.lat.base.4.256.csv   $result.lat.nic.4.256.csv   > $result.lat.all.256.csv
paste $result.lat.base.4.65536.csv $result.lat.nic.4.65536.csv > $result.lat.all.65536.csv

gnuplot mica_get.gp
