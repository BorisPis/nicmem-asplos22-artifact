#!/bin/bash
./rdma-core/build/bin/ibv_dm_copy -d mlx5_1 -s 131072 -n 100 -r >& memcpy_reverse.csv
