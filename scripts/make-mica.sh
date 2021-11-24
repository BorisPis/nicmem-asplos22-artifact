#!/bin/bash

MICA=$NMBASE/micas

# compile mica assuming all dependencies were met 
echo -ne 'Compilig mica...'
cd $MICA
./configure_server.sh >& mica.log 
cd build
make -j netbench_server >> mica.log 2>&1
cd ../.. >& /dev/null

if [ -z "$(ls -A $MICA/build/src/netbench_server)" ]; then
  echo "mica compilation failed at $MICA"
  exit -1
else
  echo Done
fi
