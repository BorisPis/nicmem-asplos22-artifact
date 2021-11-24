#Config collected info as well

[ ! -e "$TBASE" ] && echo "base directory is missing" && exit -1
[ -z "$OUT_FILE" ] && OUT_FILE=/tmp/

[  ! -e "$TBASE/test.sh" ] && echo "No File" && exit -1

[ -z "$NOCONFIG" ] && source $TBASE/config.sh >> $OUT_FILE/test_raw.txt
[ -z "$repeat" ] && repeat=1
[ -z "$DELAY" ] && DELAY=30

export TIME=60
export WARMUP=10

rm -rf $OUT_FILE/result.txt

echo "$date starting ($TBASE $repeat [$DELAY])"
for i in `seq 1 $repeat`; do
	date=`date +"%H:%M.%s:"`
	export OUT_FILE=$OUT_FILE
	echo "Sock: $SOCK_SIZE"
	$TBASE/test.sh >> $OUT_FILE/test_raw.txt &
	testid=$!
	echo "$date $TBASE/test.sh & $OUT_FILE"
	sleep $DELAY
	# collect_membw is at least 20sec
	sudo -E collect_net2=yes $TBASE/collect_membw.sh &>> $OUT_FILE/result.txt
	sleep $[$TIME-$DELAY]
	sleep 5 # write output
	echo "waiting on $testid"
	wait $testid
        if [ "$CONFIG_PER_TEST" ]; then
          $TBASE/config.sh
        fi
done
date=`date +"%H:%M.%s:"`
echo "$date Done ($TBASE)"
