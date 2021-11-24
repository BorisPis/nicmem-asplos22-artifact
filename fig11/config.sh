if [ -z "$if1" ]; then
	echo "if1 not configured $if1"
	exit -1
fi

echo killing t-rex
ssh $loader1 "sudo pkill t-rex-64"
echo killed t-rex

sudo ethtool -A $if1 rx off tx off

sudo modprobe -v mlx5_ib

echo 60000 | sudo tee /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
echo "The available huge pages on node0:"
cat /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages

#-----------------------------------------
sudo sysctl -w vm.overcommit_memory=1
sudo sysctl -w kernel.shmmax=12884901888
sudo sysctl -w kernel.shmall=12884901888
sudo umount /mnt/huge
sudo umount /mnt/huge
sudo mount -t hugetlbfs nodev -o pagesize=2M /mnt/huge
#-----------------------------------------

echo killing netbench_client
ssh $loader1 "sudo pkill netbench_client"
echo killed netbench_client

echo -1 | sudo tee /proc/sys/kernel/sched_rt_runtime_us
