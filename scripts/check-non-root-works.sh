#!/bin/bash

if [ ! "$NMBASE" ]
then
  echo "Please run 'source scripts/env.sh' from the root directory"
  exit -1
fi

FASTCLICK=$NMBASE/fastclick

if [[ ! -a $FASTCLICK/userlevel/click ]]; then
  echo "No fastclick binary available at $FASTCLICK. Make sure it was compiled."
  exit -1
fi

if [[ ! -u $FASTCLICK/userlevel/click ]]; then
# Need setcap for all files being run
  echo "Missing setuid on fastclick's binary"
  # echo "getcap $FASTCLICK/userlevel/click"
  # getcap $FASTCLICK/userlevel/click
  exit -1
fi

if [ ! -w /dev/hugepages ]; then
  echo "Missing rwx permissions on /dev/hugepages for DPDK"
  exit -1
fi

if [ ! -w /dev/cpu/ ]; then
  echo "Missing rwx permissions on /dev/cpu for DDIO tuning"
  exit -1
fi

echo "All is ready for non-root testing!"

exit 0

