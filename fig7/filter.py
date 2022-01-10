#!/usr/bin/python
from sys import argv,exit

def parse_csv(csv_data):
    res = {}
    lines = csv_data.split('\n')
    keys = filter(lambda x: len(x) > 0, lines[0].split(','))[2:]
    tests = [l.split(',')[1] for l in lines[:-1]][1:]
    #print 'Tests:', tests
    #print 'Keys:', keys
    for i in xrange(len(tests)):
        t = tests[i]
        res[t] = {}
        values = lines[i + 1].split(',')
        for j in xrange(len(keys)):
            k = keys[j].lstrip().rstrip()
            v = values[j + 2].lstrip().rstrip()
            if k != '':
                res[t][k] = v
    return res


def filter_csv(csv, keys):
    csv_data = open(csv, 'rb').read()
    res = parse_csv(csv_data)
    out = []
    line = ''
    # print the headers first
    l = 'test,bandwidth,cpu,' + ','.join(keys)
    out.append(l)
    for test in res.keys():
        l = test
        #print (res[test]['Total_rx_bw']), (res[test]['Total_tx_bw'])
        l += ',%.2f,' % (float(res[test]['Total_rx_bw']) + float(res[test]['Total_tx_bw']))
        #l += '%.2f,' % float(res[test]['cpu_total'])
        l += '%.2f,' % float(0)
        for k in keys:
            if not k in res[test].keys():
                l += '%s,' % 'Nan'
            else:
                l += '%s,' % res[test][k]
        out.append(l)
    print '\n'.join(out)

if __name__ == '__main__':
    # argv[1] is a directory containing subdirectories with test results
    if len(argv) < 2:
        print 'Usage: %s <csv> <filter-file>'
        exit(1)
    if len(argv) < 3:
        keys = 'sys_Memory sys_pcie_0_hit_mem sys_pcie_0_miss_mem RXDESC MEMTYPE CORES l3fwd_rx_cyc l3fwd_tx_cyc l3fwd_idle_cyc l3fwd_lookup_cyc l3fwd_total_cyc TIME trex_lat_avg2 LOAD trex_tx_bps trex_rx_bps trex_lat_99th neo_pcie_avg_latency DDIO_WAYS perf_cache-references perf_cache-misses PKT_SIZE WP_CPU WP_MEMN WP_MEMSIZE fclick_cycles fclick_cycles_pb fclick_cycles_idle neo_outbound_stalled_writes fclick_oob_bps fclick_discards_bps fclick_total_drops'.split()
    else:
        keys = open(argv[2], 'rb').read().split()
    res = filter_csv(argv[1], keys)
