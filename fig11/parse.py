#!/usr/bin/python
from sys import argv,exit
from os.path import isdir, basename, dirname
from glob import glob
from perf_util import read_cpu, read_net, read_memory, read_perf_stat,\
                      read_env, read_pcie, read_l3fwd, read_trex, read_neo,\
                      read_fclick_wp, read_dpdk_ping_client,\
                      read_dpdk_ping_server, read_ibvping_client,\
                      read_trex_ndr, read_mica_lat, read_mica_server

# input csv is a two dimensional array
def pretty_csv(csv):
    out = ""
    csvt = [[] for i in range(len(csv[0]))]
    for j in range(len(csv[0])):
        #print 'col expected len:', len(csv[0])
        for i in range(len(csv)):
            #print 'col actual len:', len(csv[i])
            csvt[j].append(csv[i][j])

    #print (csvt)
    csv_widths = [ max(map(lambda x : len(str(x)), csvt[i])) + 1 for i in range(len(csvt)) ]
    #print ('widths', csv_widths)
    for i in range(len(csv)):
        l = ""
        for j in range(len(csv[0])):
            format_str = "%%%ds, " % csv_widths[j]
            l += format_str % csv[i][j]
        l += "\n"
        out += l
    return out

def hash2csv(name, res):
    cols = []
    # join all keys in a single list of unique keys
    for t in res.keys():
        cols.extend(res[t].keys())
    cols = list(set(cols))
    csv = [['name', 'test'] + cols]
    for k in res.keys():
        csv.append([name, k])
        for c in cols:
            try:
                csv[-1].append(res[k][c])
            except:
                csv[-1].append(0)

    return pretty_csv(csv)

#def hash2csv(name, res):
#    cols = []
#    # join all keys in a single list of unique keys
#    [cols.extend(res[t].keys()) for t in res.keys()]
#    cols = list(set(cols))
#    print '[+] Columns:', cols
#    l = 'name,test,'
#    for k in cols:
#        l += k + ','
#    csv = l+'\n'
#    for test in res.keys():
#        l = '%s,%s,' % (name, test)
#        for c in cols:
#            try:
#                l += '%s,' % res[test][c]
#            except:
#                l += '0,'
#        csv += l+'\n'
#    return csv

parsers = {
'eth.txt' : read_net,
'if1.eth.txt' : read_net,
'if2.eth.txt' : read_net,
'if3.eth.txt' : read_net,
'if4.eth.txt' : read_net,
'cpu.txt' : read_cpu,
'memory.txt' : read_memory,
'pcie.txt' : read_pcie,
'perf_stat.txt' : read_perf_stat,
'env.txt' : read_env,
'l3fwd.txt' : read_l3fwd,
'trex.txt' : read_trex,
'trex_ndr.txt' : read_trex_ndr,
#'if1.neo.txt' : read_neo,
'if2.neo.txt' : read_neo,
'fclick_wp.txt' : read_fclick_wp,
'dpdk-ping-client.txt' : read_dpdk_ping_client,
'dpdk-ping-server.txt' : read_dpdk_ping_server,
'ibvping-client.txt' : read_ibvping_client,
'output_latency.0' : read_mica_lat,
'mica_server.txt' : read_mica_server,
}

def parse(d):
    res = {}
    files = glob(d + '/*')
    #print 'files', files
    for f in files:
        #fname = f.split('/')[-1]
        fname = basename(f)
        #if not f.endswith('.txt') and not f.endswith('.terse') and not f.endswith('.out'):
        #    print '[-] Skipping parsing non-txt/terse/out file %s' % fname
        #    continue
        if fname not in parsers.keys():
            print '[-] Skipping parsing unknown file %s' % fname
            continue
        print '[+] Parsing file %s' % fname
        res.update(parsers[fname](f))
    return res

def parse_base(d):
    dirs = glob(d + '/*')
    res = {}
    for name in dirs:
        dname = basename(name)
        if not isdir(name):
            print '[-] Skipping non-directory in base: %s' % dname
            continue
        print '[+] Parsing directory %s' % dname
        res[dname] = parse(name)
    return res

if __name__ == '__main__':
    # argv[1] is a directory containing subdirectories with test results
    if len(argv) < 2:
        print 'Usage: %s <base-directory>' % argv[0]
        exit(1)
    d = argv[1]
    res = parse_base(d)
    csv = hash2csv(basename(d), res)
    open(d + '/setup.csv', 'wb').write(csv)
    print '[+] Saved CSV in %s' % (d + '/setup.csv')
