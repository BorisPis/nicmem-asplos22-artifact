## The Benefits of General-Purpose on-NIC Memory Artifact 

This repository contains scripts for ASPLOS'22 artifact evaluation of the **The
Benefits of General-Purpose on-NIC Memory** paper by Boris Pismenny, Liran
Liss, Adam Morrison, and Dan Tsafrir.

### Evaluation instructions ###

Should evaluators choose to to compile and install our code, we provide
instructions for this at the end.  However, as nicmem requires hardware,
kernel, and system software, we have set up an environment for the evaluators
on our machines.

#### Accessing the evaluation environment
Our system works closely with real hardware and reproduction of our results
requires two machines connected back-to-back with two NVIDIA ConnectX-5
devices; 100GbE each and 200GbE in total on each machine.  Additionally, our
scripts assume that all NICs are connected to a NUMA node `#0` which hosts
cores `0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30`.  Furthermore, our scripts
rely on hardcoded MAC and IP address.  Different configuration will require
updating our scripts accordingly.  This is why we provide evaluators with
credentials to access our setup for reproducing our results. 

Please contact authors for inromation on how to access this setup remotely.
We will provide username/password on-demand.

### Directory structure ###

* `fig7` Scripts to reproduce figure 7 in the paper: cd fig8; ./run_fclick_wp.sh; ./plot.sh, see scatter.eps.
* `fig8` Scripts to reproduce figure 8 in the paper: cd fig8; ./run_fclick_nat.sh; ./plot.sh, see fclick.eps.
* `fig9` Scripts to reproduce figure 9 in the paper: cd fig9; ./run_fclick_nat.sh; ./plot.sh, see fclick.eps.
* `fig11` Scripts to reproduce figure 11 in the paper: cd fig11; ./run_mica_get.sh; ./plot.sh, see mica_get.eps.
* `fig12` Scripts to reproduce figure 12 in the paper: cd fig12; ./run_mica_set.sh; ./plot.sh, see mica_set.eps.
* `dpdk` DPDK sources modified to support nicmem.
* `micas` MICA server modified to support new DPDK and nicmem.
* `micac` MICA client modified to support new DPDK and to test our server.
* `fastclick` FastClick sources modified to support nicmem.
* `trex` T-Rex load generation tool used only by the load generator.
* `scripts` Miscellaneous scripts for artifact evaluation.

### Instructions for evaluation testing ###

To simplify artifact testing, we pre-configured a server with two kernels with
require huge pages support:
* `Linux 5.4.0dpdk 1G hugepages` is used to test Fastclick (figures 7--9).
* `Linux 5.4.0dpdk 2M hugepages` is used to test MICA (figures 11--12).

To boot into the `Linux 5.4.0dpdk 1G hugepages` kernel run:
```
sudo grub-reboot "Linux 5.4.0dpdk 1G hugepages"
sudo reboot
```

To boot into the `Linux 5.4.0dpdk 2M hugepages` kernel run:
```
sudo grub-reboot "Linux 5.4.0dpdk 2M hugepages"
sudo reboot
```

When the kernel is loaded, check what hugepage size is configured in the
currently running kernel to verify the operations completed successfully:
```
./scripts/kernel-params-check.sh
```

Connect to both load generator (e.g., danger40) and server (e.g., danger39)
machines. Place the base directory in the same path on both machines. Run all
tests for the server machine which is the machine under test.

On both machines, import useful environment variables:
```
source ./scripts/env.sh
```

Now, on the server run the following to obtain all submodules and compile the
environment:
```
./scripts/make-server.sh
```

And on the client run:
```
./scripts/make-client.sh
```

### Running benchmarks ###

In the figX subdirectories, we provide instructions for reporducing the
corresponding key figures in our paper in eps format. Use the gv eps viewer to
view the resulting figure files.

All benchmarks should be executed from the server machine.

> To reduce reproduction time, we set the experiments to run once (instead of
> 10 times). You can change that by modifying the `REPEAT` parameter in the
> test scripts.
> Running fig7 once takes ~480min; 10 repeatitions will require 4800min=80hrs.
>
> Running fig8 once takes ~90min; 10 repeatitions will require 900min=15hrs.
>
> Running fig9 once takes ~125min; 10 repeatitions will require 1250min=21hrs.
> 
> Running fig11 once takes ~36min; 10 repeatitions will require 360min=6hrs.
> 
> Running fig12 once takes ~72min; 10 repeatitions will require 720min=12hrs.
> 

<!--
### Hardware dependencies ###

The experiments require two machines connected back-to-back with two NVIDIA
ConnectX-5 devices on each machine. To test whether nicmem is enabled on a
machine run:
```
./scripts/test_machine.sh
```

In our tests, we used two Connect-X5, part-number MCX555A-ECA_Ax_Bx, PSID
MT_0000000010, and FW version 16.32.0415
-->

### Software dependencies ###

All dependencies have been fullfiled on our test machines. Please follow this
section's instructions only if installing from scratch!

The code is tested on Ubuntu Ubuntu 18.04.5 LTS. To build our code, you will
need all dependencies for supporting
[DPDK](https://doc.dpdk.org/guides/linux_gsg/index.html) with [NVIDIA
devices](https://doc.dpdk.org/guides/nics/mlx5.html#linux-prerequisites). We
direct readers to follow the instructions on the respective project websites.

<!--
These dependencies include at least:
* Recent Linux kernel (we used 5.4) with support for Mellanox Infiniband drivers: 
  * CONFIG_MLX5_INFINIBAND=m
  * CONFIG_INFINIBAND=y
  * CONFIG_INFINIBAND_USER_VERBS=y
* Recent rdma-core library (we used 33.0) 
* DPDK version (20.08)
* python pip3 install meson ninja python3-pyelftools
* apt install build-essential
-->

DPDK also requires hugepages and isolated Linux CPUs. For example, we used the following
Linux kernel boot parameters for fastclick experiments on our setup:
```
default_hugepagesz=1G hugepagesz=1G hugepages=64 isolcpus=2,4,6,8,10,12,14,16,18,20,22,24,26,28
```
MICA experiments use the same parameters with 2M hugepages.

We rely on pcm for measuring CPU metrics (cache and PCIe hit ratios and memory
bandwidth). To measure NIC PCIe load, we use Mellanox NEO-host.
