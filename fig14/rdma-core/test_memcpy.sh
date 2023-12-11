#!/bin/bash
./build/bin/ibv_dm_copy -d mlx5_1 -s 131072 >& memcpy.csv
