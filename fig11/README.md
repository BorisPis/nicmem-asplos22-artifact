### To reproduce run
./run_mica_get.sh # produces ./Results directory
./plot.sh # produces mica_get.eps (figure 11)

### MICA 100% get performance
Run MICA 100% get workload and compare nicmem with hostmem
while varying the number of items in a 256KB or 64MB hot area.

### Description of scripts in this directory
To reproduce our results, you need to run only the first two files: 
* run_mica_get.sh       -- run the benchmark.
* plot.sh	        -- process the data in Results.
                           This calls the perl scripts to generate the figure (mica_get.eps)

The rest of the files are called from the above scripts.
Test execution scripts:
* run_test.sh	          -- run the benchmark once with specific parameters
                             while recording performance.
* test.sh	          -- run the benchmark once with specific parameters
* conf_machines_client.x  -- mica client machine configurations
* conf_machines.x         -- mica server machine configurations
* conf_prepopulate.x      -- mica prepopulation configuration
* workload.x              -- mica workload configurations
* config.sh               -- initialize t-rex on the workload generator
* collect_membw.sh        -- collect all stats during an experiment
* sample_eth.py           -- record ethtool stats

Plotting scripts:
* mica_get.gp	          -- gnuplot script that generates the figure.
		             You should not need to call it manually
* parse.py                -- parse data in Results into csv (generates setup.csv)
* perf_util.py            -- helpers to process results in parse.py
* filter.py               -- extract secific data columns from results csv (generates filter.csv)
* README.md               -- this file

### Output files
* mica_get.eps	-- The figure in the paper
