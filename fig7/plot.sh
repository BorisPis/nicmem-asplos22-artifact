TBASE=$NMBASE/fig7
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
RBASE=$TBASE/Results

name=$RBASE/setup.csv
fname=$RBASE/filter.csv
$TBASE/parse.py $RBASE && $TBASE/filter.py $name > $fname
result=$RBASE/result

export THRESHOLD_MEM=30
export THRESHOLD_CPU=1815
export XCOL=CYCLES

case "$XCOL" in
  MEM)
    echo "[+] XCOL is MEM"
    #export TITLE="cycles per packet (#)"
    export XRANGE="set xrange [0:60]; set xtics format \"%g\" autofreq;"
    export XFUNC="mem"
    export XCOLN="4"
    export XLABEL="memory bandwidth (GB/s)"
    ;;
  CYCLES)
    echo "[+] XCOL is CYCLES"
    #export TITLE="cycles per packet (#)"
    export XRANGE="set xrange [0:5]; set xtics format \"%g\" autofreq;"
    export XFUNC="cycles"
    export XCOLN="30"
    export XLABEL="cycles per packet (K)"
    ;;
  *)
    echo "Unsupported XCOL $XCOL" && die -1
esac


# BIGLAT
echo \# `head -n1 $fname`                                                                                                                   > $result.lowc.highm.nic.csv
echo \# `head -n1 $fname`                                                                                                                   > $result.lowc.highm.nic-inline.csv
echo \# `head -n1 $fname`                                                                                                                   > $result.lowc.highm.host.csv
echo \# `head -n1 $fname`                                                                                                                   > $result.lowc.highm.base.csv
grep nic $fname | grep -v inline | awk -F "\"*,\"*" '$30<ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4>ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.lowc.highm.nic.csv
grep nic-inline $fname           | awk -F "\"*,\"*" '$30<ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4>ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.lowc.highm.nic-inline.csv
grep host $fname                 | awk -F "\"*,\"*" '$30<ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4>ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.lowc.highm.host.csv
grep base $fname                 | awk -F "\"*,\"*" '$30<ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4>ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.lowc.highm.base.csv
echo \# `head -n1 $fname`                                                                                                                    > $result.lowc.lowm.nic.csv
echo \# `head -n1 $fname`                                                                                                                    > $result.lowc.lowm.nic-inline.csv
echo \# `head -n1 $fname`                                                                                                                    > $result.lowc.lowm.host.csv
echo \# `head -n1 $fname`                                                                                                                    > $result.lowc.lowm.base.csv
grep nic $fname  | grep -v inline | awk -F "\"*,\"*" '$30<ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4<=ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.lowc.lowm.nic.csv
grep nic-inline $fname            | awk -F "\"*,\"*" '$30<ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4<=ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.lowc.lowm.nic-inline.csv
grep host $fname                  | awk -F "\"*,\"*" '$30<ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4<=ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.lowc.lowm.host.csv
grep base $fname                  | awk -F "\"*,\"*" '$30<ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4<=ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.lowc.lowm.base.csv

# SMLLAT
echo \# `head -n1 $fname`                                                                                                                    > $result.highc.highm.nic.csv
echo \# `head -n1 $fname`                                                                                                                    > $result.highc.highm.nic-inline.csv
echo \# `head -n1 $fname`                                                                                                                    > $result.highc.highm.host.csv
echo \# `head -n1 $fname`                                                                                                                    > $result.highc.highm.base.csv
grep nic $fname  | grep -v inline | awk -F "\"*,\"*" '$30>=ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4>ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.highc.highm.nic.csv
grep nic-inline $fname            | awk -F "\"*,\"*" '$30>=ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4>ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.highc.highm.nic-inline.csv
grep host $fname                  | awk -F "\"*,\"*" '$30>=ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4>ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.highc.highm.host.csv
grep base $fname                  | awk -F "\"*,\"*" '$30>=ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4>ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.highc.highm.base.csv
echo \# `head -n1 $fname`                                                                                                                     > $result.highc.lowm.nic.csv
echo \# `head -n1 $fname`                                                                                                                     > $result.highc.lowm.nic-inline.csv
echo \# `head -n1 $fname`                                                                                                                     > $result.highc.lowm.host.csv
echo \# `head -n1 $fname`                                                                                                                     > $result.highc.lowm.base.csv
grep nic $fname  | grep -v inline | awk -F "\"*,\"*" '$30>=ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4<=ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.highc.lowm.nic.csv
grep nic-inline $fname            | awk -F "\"*,\"*" '$30>=ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4<=ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.highc.lowm.nic-inline.csv
grep host $fname                  | awk -F "\"*,\"*" '$30>=ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4<=ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.highc.lowm.host.csv
grep base $fname                  | awk -F "\"*,\"*" '$30>=ENVIRON["THRESHOLD_CPU"]' | awk -F "\"*,\"*" '$4<=ENVIRON["THRESHOLD_MEM"]' | sort -t, -k$XCOLN -n >> $result.highc.lowm.base.csv

$TBASE/mk-labels.pl > $RBASE/labels.txt
gnuplot $TBASE/scatter2.gp
