#!/bin/bash
./build/bin/ibv_dm_copy -d mlx5_1 -j -k -s 131072 >& memcpy_memic.csv
