#!/bin/bash
./rdma-core/build/bin/ibv_dm_copy -d mlx5_1 -j -k -s 131072 -n 1 -r >& memcpy_memic_reverse.csv
