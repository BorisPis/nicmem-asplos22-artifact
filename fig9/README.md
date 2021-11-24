### To reproduce run
./run_fclick_nat.sh # produces ./Results directory
./plot.sh # produces fclick.eps (figure 9)

### NAT/LB performance varying DDIO ways
Run fastclick NAT/LB and compare nmNFV- and nmNFV+ with baseline and split
while varying the number of DDIO ways.

### Description of scripts in this directory
To reproduce our results, you need to run only the first two files: 
* run_fclick_nat.sh     -- run the benchmark while varying DDIO ways and memory type.
* plot.sh	        -- process the data in Results.
                           This calls fclick.gp to generate the figure (fclick.eps)

The rest of the files are called from the above scripts.
Test execution scripts:
* run_test.sh	        -- run the benchmark once with specific parameters
                           while recording performance.
* test.sh	        -- run the benchmark once with specific parameters
* nat.x.[2|1].npf       -- fclick script template for NAT
* lb.x.[2|1].npf        -- fclick script template for LB
* config.sh             -- initialize t-rex on the workload generator
* collect_membw.sh      -- collect all stats during an experiment
* sample_eth.py         -- record ethtool stats

Plotting scripts:
* fclick.gp	        -- gnuplot script that generates the figure.
		           You should not need to call it manually
* parse.py              -- parse data in Results into csv (generates setup.csv)
* perf_util.py          -- helpers to process results in parse.py
* filter.py             -- extract secific data columns from results csv (generates filter.csv)
 
* README.md             -- this file

### Output files
* fclick.eps	-- The figure in the paper
