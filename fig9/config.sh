#!/bin/bash

echo 64 | sudo tee /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages >& /dev/null

sudo ethtool -A $if1 rx off tx off
sudo ethtool -A $if2 rx off tx off

sudo modprobe -v mlx5_ib

echo killing t-rex
ssh $loader1 "sudo pkill t-rex-64"
echo killed t-rex
ssh -n $loader1 "cd $NMBASE/trex/scripts;  sudo -E ./t-rex-64 -i --stl --no-ofed --cfg trex_cfg.yaml >& /dev/null" &
#ssh -n $loader1 "cd $NMBASE/trex/scripts;  ./t-rex-64 -i --stl --no-ofed --cfg trex_cfg.yaml"
echo starting t-rex

sleep 5
