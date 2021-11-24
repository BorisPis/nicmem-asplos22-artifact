#!/usr/bin/python
import re
import os
import numpy as np
import ast

def reject_outliers(data, auto = True, bot = 0, top = -1):
    if auto:
        if len(data) > 8:
            bot = top = 1
        elif len(data) > 4:
            bot = top = 1
        else:
            return data
    if top == -1:
        return data

    return sorted(data)[bot:-top]

def align_std(x):
    return 0 if (x < 0.0001) else x

def _read_net_cpu(f):
    data = open(f, 'rb').read()
    #enp4s0f1_rx_packets: 1179901
    res = {}
    for l in data.split('\n'):
        if ':' not in l:
            continue
        try:
            k, v = l.split(': ')
            if k not in res.keys():
                res[k] = []
            res[k].append(float(v))
        except:
            print "[-] Skipping", l

    res_median = {}
    res_no_outliers = {}
    for k,v in res.items():
        d = np.array(res[k])
        res_no_outliers[k] = reject_outliers(d)
        try:
            res_median[k] = '%.2f' % float(np.average(res_no_outliers[k]))
            res_median[k+'_std'] = '%.2f' % align_std(float(np.std(res_no_outliers[k])))
        except:
            res_median[k] = '%.2f' % float(res[k])
            res_median[k+'_std'] = '%.2f' % max(max(res[k]), abs(min(res[k])))
        #print
        if len(res[k]) > len(res_no_outliers[k]) + 5:
                #assert False, (k, res_median[k], res_median[k+'_std'], len(res[k]), len(res_no_outliers[k]), res[k])
                print (k, res_median[k], res_median[k+'_std'], len(res[k]), len(res_no_outliers[k]), res[k])

    return res_median

def read_cpu(f):
    res = _read_net_cpu(f)
    return res

def read_net(f):
    res = _read_net_cpu(f)
    res['Total_tx_bw_phy'] = res['Total_rx_bw_phy'] = res['Total_tx_bw'] = res['Total_rx_bw'] = res['Total_tx_bytes'] = res['Total_rx_bytes'] = res['Total_tx_packets'] =  res['Total_rx_packets'] =  0
    for k,v in res.items():
        #print k
        if k.endswith('tx_bw'):
            #print k
            res['Total_tx_bw'] += float(v)
        elif k.endswith('rx_bw'):
            #print k
            res['Total_rx_bw'] += float(v)
        elif k.endswith('tx_bw_phy'):
            #print k
            res['Total_tx_bw_phy'] += float(v)
        elif k.endswith('rx_bw_phy'):
            #print k
            res['Total_rx_bw_phy'] += float(v)
        elif k.endswith('tx_bytes'):
            #print k
            res['Total_tx_bytes'] += float(v)
        elif k.endswith('rx_bytes'):
            #print k
            res['Total_rx_bytes'] += float(v)
        elif k.endswith('tx_packets'):
            #print k
            res['Total_tx_packets'] += float(v)
        elif k.endswith('rx_packets'):
            #print k
            res['Total_rx_packets'] += float(v)
    #print res['Total_tx_bw'], res['Total_rx_bw'], res['Total_tx_bytes'], res['Total_rx_bytes'], res['Total_tx_packets'], res['Total_rx_packets']
    return res

'''
 |---------------------------------------||---------------------------------------|
 |--             Socket  0             --||--             Socket  1             --|
 |---------------------------------------||---------------------------------------|
 |--     Memory Channel Monitoring     --||--     Memory Channel Monitoring     --|
 |---------------------------------------||---------------------------------------|
 |-- Mem Ch  0: Reads (MB/s):  2599.10 --||-- Mem Ch  0: Reads (MB/s):   449.15 --|
 |--            Writes(MB/s):   262.32 --||--            Writes(MB/s):    11.88 --|
 |-- Mem Ch  1: Reads (MB/s):  2602.05 --||-- Mem Ch  1: Reads (MB/s):   444.88 --|
 |--            Writes(MB/s):   258.62 --||--            Writes(MB/s):     7.96 --|
 |-- Mem Ch  2: Reads (MB/s):  2600.20 --||-- Mem Ch  2: Reads (MB/s):   448.79 --|
 |--            Writes(MB/s):   262.60 --||--            Writes(MB/s):    11.87 --|
 |-- Mem Ch  3: Reads (MB/s):  2598.12 --||-- Mem Ch  3: Reads (MB/s):   444.91 --|
 |--            Writes(MB/s):   258.53 --||--            Writes(MB/s):     7.96 --|
 |-- NODE 0 Mem Read (MB/s) : 10399.46 --||-- NODE 1 Mem Read (MB/s) :  1787.73 --|
 |-- NODE 0 Mem Write(MB/s) :  1042.07 --||-- NODE 1 Mem Write(MB/s) :    39.66 --|
 |-- NODE 0 P. Write (T/s): 4802627619 --||-- NODE 1 P. Write (T/s): 4802550306 --|
 |-- NODE 0 Memory (MB/s):    11441.53 --||-- NODE 1 Memory (MB/s):     1827.39 --|
 |---------------------------------------||---------------------------------------|
 |---------------------------------------||---------------------------------------|
 |--                 System Read Throughput(MB/s):      12187.19                --|
 |--                System Write Throughput(MB/s):       1081.73                --|
 |--               System Memory Throughput(MB/s):      13268.92                --|
 |---------------------------------------||---------------------------------------|

'''
def read_memory(f):
    data = open(f, 'rb').read()
    res = {}
    in_channel = -1
    #print f
    for l in data.split('\n'):
        #print l

        # parse Mem Ch Writes
        if in_channel >= 0:
            r = re.findall("\s+Writes\(MB/s\):\s+(\d+\.\d+)", l)
            #print l
            if r == []:
                continue
            if len(r) >= 2:
                res['socket_0_Ch_%d_Wr' % in_channel].append(r[0])
                res['socket_1_Ch_%d_Wr' % in_channel].append(r[1])
            else:
                pass
            in_channel = -1
            continue

        r = re.findall("Mem Ch  (\d): Reads \(MB/s\):\s+(\d+\.\d+)", l)
        if r != []:
            in_channel = int(r[0][0])
            if not ('socket_0_Ch_%d_Rd' % in_channel) in res.keys():
                res['socket_0_Ch_%d_Rd' % in_channel] = []
                res['socket_1_Ch_%d_Rd' % in_channel] = []
                res['socket_0_Ch_%d_Wr' % in_channel] = []
                res['socket_1_Ch_%d_Wr' % in_channel] = []
            try:
                res['socket_0_Ch_%d_Rd' % in_channel].append(r[0][1])
                res['socket_1_Ch_%d_Rd' % in_channel].append(r[1][1])
            except:
                break
            continue

        r = re.findall("NODE (\d) Mem Read \(MB/s\) :\s+(\d+\.\d+)", l)
        if r != []:
            if not 'node_0_Mem_Read' in res.keys():
                res['node_0_Mem_Read'] = []
                res['node_1_Mem_Read'] = []

            res['node_0_Mem_Read'].append(r[0][1])
            res['node_1_Mem_Read'].append(r[1][1])
            continue

        r = re.findall("NODE (\d) Mem Write\(MB/s\) :\s+(\d+\.\d+)", l)
        if r != []:
            if not 'node_0_Mem_Write' in res.keys():
                res['node_0_Mem_Write'] = []
                res['node_1_Mem_Write'] = []

            res['node_0_Mem_Write'].append(r[0][1])
            res['node_1_Mem_Write'].append(r[1][1])
            continue

        #|-- NODE 0 memory (MB/s):    11441.53 --||-- NODE 1 Memory (MB/s):     1827.39 --|
        r = re.findall("NODE (\d) Memory \(MB/s\):\s+(\d+\.\d+)", l)
        if r != []:
            if not 'node_0_Memory' in res.keys():
                res['node_0_Memory'] = []
                res['node_1_Memory'] = []

            res['node_0_Memory'].append(r[0][1])
            res['node_1_Memory'].append(r[1][1])
            continue

        #|--                 System Read Throughput(MB/s):      12187.19                --|
        r = re.findall("System Read Throughput\(MB/s\):\s+(\d+\.\d+)", l)
        if r != []:
            if not 'sys_Read' in res.keys():
                res['sys_Read'] = []
            res['sys_Read'].append(r[0])
            continue
        #|--                System Write Throughput(MB/s):       1081.73                --|
        r = re.findall("System Write Throughput\(MB/s\):\s+(\d+\.\d+)", l)
        if r != []:
            if not 'sys_Write' in res.keys():
                res['sys_Write'] = []
            res['sys_Write'].append(r[0])
            continue
        #|--               System Memory Throughput(MB/s):      13268.92                --|
        r = re.findall("System Memory Throughput\(MB/s\):\s+(\d+\.\d+)", l)
        if r != []:
            if not 'sys_Memory' in res.keys():
                res['sys_Memory'] = []
            res['sys_Memory'].append(r[0])
            continue

    for k,v in res.items():
        #assert filter(lambda x: float(x) > 100 * 1000, v) == [], "dict[%s] = %s MB/s" % (k,v)
        if filter(lambda x: float(x) > 100 * 1000, v) == []:
            res[k] = filter(lambda x: float(x) < 100 * 1000, v)

    res_out = {}
    #print '!!!! Samples: !!!!!', len(res['sys_Memory'])
    for k,v in res.items():
        #res_out[k] = sum(map(lambda x: float(x), v)) / len(v) / 1000.0
        res_out[k] = '%.2f' % (np.average(map(lambda x: float(x), v)) / 1000.0)

    return res_out

'''
Skt | PCIeRdCur |  RFO  |  CRd  |  DRd  |  ItoM  |  PRd  |  WiL  | PCIe Rd (B) | PCIe Wr (B)
 0    8316           0      43 K   207 K    612       0      36            16 M          39 K   (Total)
 0    8100          24      84      74 K      0       0     108          5323 K        1536     (Miss)
 0     216           0      43 K   132 K    612       0       0            11 M          39 K   (Hit)
 1       0           0    8436    2291 K      0       0       0           147 M           0     (Total)
 1       0           0    1092     113 K      0     372       0          7332 K           0     (Miss)
 1       0           0    7344    2178 K      0       0       0           139 M           0     (Hit)
----------------------------------------------------------------------------------------------------
 *    8316           0      51 K  2499 K    612       0      36           163 M          39 K   (Aggregate)
'''
def read_pcie(f):
    data = open(f, 'rb').read()
    data = data.replace (' G', '000000000')
    data = data.replace (' M', '000000')
    data = data.replace (' K', '000')
    res = {}
    #print f
    for l in data.split('\n'):
        # socket 0 miss
        r = re.findall("0\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+(\d+)\s+\(Miss\)", l)
        if r != []:
            if not 'sys_pcie_0_miss_rdb' in res.keys():
                res['sys_pcie_0_miss_rdb'] = []
            res['sys_pcie_0_miss_rdb'].append(r[0][0])
            if not 'sys_pcie_0_miss_wrb' in res.keys():
                res['sys_pcie_0_miss_wrb'] = []
            res['sys_pcie_0_miss_wrb'].append(r[0][1])
            continue
        # socket 0 hit
        r = re.findall("0\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+(\d+)\s+\(Hit\)", l)
        if r != []:
            if not 'sys_pcie_0_hit_rdb' in res.keys():
                res['sys_pcie_0_hit_rdb'] = []
            res['sys_pcie_0_hit_rdb'].append(r[0][0])
            if not 'sys_pcie_0_hit_wrb' in res.keys():
                res['sys_pcie_0_hit_wrb'] = []
            res['sys_pcie_0_hit_wrb'].append(r[0][1])
            continue
        # Aggregate
        r = re.findall("\*\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+(\d+)\s+\(Aggregate\)", l)
        if r != []:
            if not 'sys_pcie_agg_rdb' in res.keys():
                res['sys_pcie_agg_rdb'] = []
            res['sys_pcie_agg_rdb'].append(r[0][0])
            if not 'sys_pcie_agg_wrb' in res.keys():
                res['sys_pcie_agg_wrb'] = []
            res['sys_pcie_agg_wrb'].append(r[0][1])
            continue

    res_out = {}
    for k,v in res.items():
        #res_out[k] = sum(map(lambda x: float(x), v)) / len(v) / 1000.0
        res_out[k] = '%d' % (np.average(map(lambda x: float(x), v)))

    if 'sys_pcie_0_hit_rdb' in res.keys() and 'sys_pcie_0_hit_wrb' in res.keys():
        res_out['sys_pcie_0_hit_mem'] = '%d' % (float(res_out['sys_pcie_0_hit_wrb']) + float(res_out['sys_pcie_0_hit_rdb']))
    if 'sys_pcie_0_miss_rdb' in res.keys() and 'sys_pcie_0_miss_wrb' in res.keys():
        res_out['sys_pcie_0_miss_mem'] = '%d' % (float(res_out['sys_pcie_0_miss_wrb']) + float(res_out['sys_pcie_0_miss_rdb']))

    #print '!!!! Samples: !!!!!', res_out
    return res_out


def dict_append_or_create(d, k, v):
    if not k in d:
        d[k] = [v]
    else:
        d[k].append(v)

def read_perf_stat(f):
    #10043.27,msec,task-clock,10043270741,100.00,0.668,CPUs utilized
    #176024046091,,cycles,90917549301,100.00,,
    #175630864683,,instructions,90917547680,100.00,1.00,insn per cycle
    #19604465,,cache-misses,90917544918,100.00,,
    res = {}
    data = open(f, 'rb').read()
    lines = data.split('\n')
    for l in lines:
        if l.startswith('#') or len(l) < 5:
            continue
        #print l, len(l.split(','))
        val,_,name,_,_,_,_ = l.split(',')
        #res['perf_' + name] = val
        try:
            dict_append_or_create(res, 'perf_' + name, int(val))
        except:
            dict_append_or_create(res, 'perf_' + name, float(val))

    for k in res.keys():
        #print k, res[k]
        if res[k] != []:
            no_outliers = reject_outliers(res[k])
            if len(no_outliers) > len(res[k]) + 5:
                print (res[k], no_outliers)
            res[k + '_std'] = np.std(no_outliers)
            res[k]          = np.average(no_outliers)
        else:
            res[k + '_std'] = 0
            res[k]          = 0

    return res

def is_ascii(s):
    not_low = filter(lambda c : not (97 <= ord(c) <= 122), s)
    not_high = filter(lambda c : not (65 <= ord(c) <= 90), not_low)
    not_num = filter(lambda c : not (48 <= ord(c) <= 57), not_high)
    not_sign = filter(lambda c : not (ord(c) in [ord('-'), ord('_'), ord('+'), ord('.')]), not_num)
    #print 'not_sign', type(not_sign), not_sign
    return not_sign == ""

def read_env(f):
    res = {}
    data = open(f, 'rb').read()
    lines = data.split('\n')
    for l in lines:
        try:
            name, val = l.split('=')
        except:
            continue
        if name == '' or val == '' or not is_ascii(name) or not is_ascii(val):
            continue
        # print 'env name', name
        # print 'env val', val
        res[name] = val
    return res

'''
tx_cyc=24713349976
rx_cyc=26102800856
lookup_cyc=32128821656
idle_cyc=195448781
'''
def read_l3fwd(f):
    res = {}
    data = open(f, 'rb').read()
    lines = data.split('\n')
    for l in lines:
        # tx_cyc
        items = re.findall('\s+tx_cyc=(\d+)', l)
        if len(items) != 0:
            if not 'l3fwd_tx_cyc' in res.keys():
                res['l3fwd_tx_cyc'] = []
            res['l3fwd_tx_cyc'].append(int(items[0]))
        # rx_cyc
        items = re.findall('\s+rx_cyc=(\d+)', l)
        if len(items) != 0:
            if not 'l3fwd_rx_cyc' in res.keys():
                res['l3fwd_rx_cyc'] = []
            res['l3fwd_rx_cyc'].append(int(items[0]))
        # lookup_cyc
        items = re.findall('\s+lookup_cyc=(\d+)', l)
        if len(items) != 0:
            if not 'l3fwd_lookup_cyc' in res.keys():
                res['l3fwd_lookup_cyc'] = []
            res['l3fwd_lookup_cyc'].append(int(items[0]))
        # idle_cyc
        items = re.findall('\s+idle_cyc=(\d+)', l)
        if len(items) != 0:
            if not 'l3fwd_idle_cyc' in res.keys():
                res['l3fwd_idle_cyc'] = []
            res['l3fwd_idle_cyc'].append(int(items[0]))
        # total_cyc
        items = re.findall('\s+total_cyc=(\d+)', l)
        if len(items) != 0:
            if not 'l3fwd_total_cyc' in res.keys():
                res['l3fwd_total_cyc'] = []
            res['l3fwd_total_cyc'].append(int(items[0]))
        # sw drop pkts=4447358
        items = re.findall('\s+sw drop pkts=(\d+)', l)
        if len(items) != 0:
            if not 'l3fwd_sw_drops' in res.keys():
                res['l3fwd_sw_drops'] = []
            res['l3fwd_sw_drops'].append(int(items[0]))
        # txq occupied=123.12
        items = re.findall('\s+txq occupied=(\d+)', l)
        if len(items) != 0:
            if not 'l3fwd_txq_occupied' in res.keys():
                res['l3fwd_txq_occupied'] = []
            res['l3fwd_txq_occupied'].append(int(items[0]))

    try:
        res['l3fwd_rx_cyc'] = reject_outliers(res['l3fwd_rx_cyc'])
    except:
        pass

    try:
        res['l3fwd_tx_cyc'] = reject_outliers(res['l3fwd_tx_cyc'])
    except:
        pass

    try:
        res['l3fwd_lookup_cyc'] = reject_outliers(res['l3fwd_lookup_cyc'])
    except:
        pass

    try:
        # remove startup/teardown time
        res['l3fwd_idle_cyc'] = map(lambda x: max(x - (2.1 * (10**9)) * 0.5, 0),
                                    reject_outliers(res['l3fwd_idle_cyc']))
    except:
        pass
        #if np.average(res['l3fwd_idle_cyc']) <= (2.1 * (10**9)) * 3:
        #    res['l3fwd_idle_cyc'] = [0]
        #else:
        #    print np.average(res['l3fwd_idle_cyc']) / float(2.1 * (10**9))

    try:
        res['l3fwd_total_cyc'] = reject_outliers(res['l3fwd_total_cyc'])
    except:
        pass

    try:
        res['l3fwd_sw_drops'] = reject_outliers(res['l3fwd_sw_drops'])
    except:
        pass

    try:
        res['l3fwd_txq_occupied'] = reject_outliers(res['l3fwd_txq_occupied'])
    except:
        pass
    out = {}
    for k in res.keys():
        if res[k] != []:
            out[k] = np.average(res[k])
            out[k+'_std'] = np.std(res[k])
            #print 'l3fwd cycles', out, res
        else:
            out[k] = 0

    return out

'''
{'global': {...},
 'latency' : {...}
}
'''
def read_trex(f):
    res = {'trex_lat_avg' : [],
           'trex_lat_avg2' : [],
           'trex_lat_50th' : [],
           'trex_lat_90th' : [],
           'trex_lat_99th' : [],
           'trex_tx_bps' : [],
           'trex_rx_bps' : [],
           }
    data = open(f, 'rb').read()
    dicts_str = []
    while len(data) >= 10:
        first_bracket = data.find('{')
        data = data[first_bracket:]
        lines = data.split('\n')
        last_bracket = data.find('}}}')
        dicts_str.append(data[:last_bracket])
        data = data[last_bracket+1:]
    dicts = [ast.literal_eval(s + '}}}') for s in dicts_str]
    for d in dicts:
        # global analysis
        res['trex_tx_bps'].append(d['global']['tx_bps'])
        res['trex_rx_bps'].append(d['global']['rx_bps'])

        # latency analysis of all packet group IDs (pg_id)
        for _,lat in d['latency'].items():
            try:
                res['trex_lat_avg'].append(lat['latency']['average'])
                # TODO: support median, tail
                if lat['latency']['histogram'] != {}:
                    lat_hist = lat['latency']['histogram']
                elif lat['latency']['histogram1us'] != {}:
                    lat_hist = lat['latency']['histogram1us']
                elif lat['latency']['histogram100ns'] != {}:
                    lat_hist = lat['latency']['histogram100ns']
                else:
                    assert False, "No histogram in lat %s" % str(lat['latency'])

                total_measured = sum([v for v in lat_hist.values()])
                percentiles = []
                cur = 1
                cur_percentile = float(total_measured) * cur / 100.0
                cur_sum = 0
                # print sorted(lat_hist.items())
                for k,v in sorted(lat_hist.items()):
                    # print k,v,cur_percentile, total_measured, percentiles
                    while cur_percentile < v + cur_sum:
                        cur += 1
                        cur_percentile = float(total_measured) * cur / 100.0
                        percentiles.append(k)
                    cur_sum += v
                assert len(percentiles) == 99, len(percentiles)
                res['trex_lat_50th'].append(percentiles[50 - 1])
                res['trex_lat_90th'].append(percentiles[90 - 1])
                res['trex_lat_99th'].append(percentiles[99 - 1])
                res['trex_lat_avg2'].append(np.average(percentiles))
            except: # skip the global results
                pass

    res['trex_lat_50th'] = filter(lambda x : float(x) >= 1, res['trex_lat_50th'])
    res['trex_lat_90th'] = filter(lambda x : float(x) >= 1, res['trex_lat_90th'])
    res['trex_lat_99th'] = filter(lambda x : float(x) >= 1, res['trex_lat_99th'])
    res['trex_lat_avg']  = filter(lambda x : float(x) >= 1, res['trex_lat_avg'])
    res['trex_tx_bps']   = filter(lambda x : float(x) >= 1, res['trex_tx_bps'])
    res['trex_rx_bps']   = filter(lambda x : float(x) >= 1, res['trex_rx_bps'])

    res['trex_lat_50th'] = reject_outliers(res['trex_lat_50th'])
    res['trex_lat_90th'] = reject_outliers(res['trex_lat_90th'])
    res['trex_lat_99th'] = reject_outliers(res['trex_lat_99th'])
    res['trex_lat_avg'] = reject_outliers(res['trex_lat_avg'])
    res['trex_tx_bps'] = reject_outliers(res['trex_tx_bps'])
    res['trex_rx_bps'] = reject_outliers(res['trex_rx_bps'])

    out = {}
    for k in res.keys():
        if res[k] != []:
            out[k] = np.average(res[k])
            out[k+'_std'] = np.std(res[k])
        else:
            out[k] = 0

    return out

def read_trex_ndr(f):
    res = {}
    data = open(f, 'rb').read()
    lines = data.split('\n')
    for l in lines:
        # NDR(s) uni-directional            :5.36 Gbps
        items = re.findall('NDR\(s\) uni-directional\s+:(\d+\.\d+) Gbps', l)
        if len(items) == 0:
            # NDR(s) uni-directional            :127.03 Mbps
            items = re.findall('NDR\(s\) uni-directional\s+:(\d+\.\d+) Mbps', l)
        if len(items) != 0:
            if not 'trex_ndr' in res.keys():
                res['trex_ndr'] = []
            res['trex_ndr'].append(float(items[0]))

    res['trex_ndr'] = reject_outliers(res['trex_ndr'])
    out = {}
    for k in res.keys():
        if res[k] != []:
            out[k] = np.average(res[k])
            out[k+'_std'] = np.std(res[k])
            #print 'dpdk ping ', out, res
        else:
            out[k] = 0

    return out

def read_neo(f):
    res = {}
    data = open(f, 'rb').read()
    #remove color
    data = data.replace("\x1b", "")
    #data = data.replace("\x7c", "")
    data = re.sub("\[(\d+)m", "", data)
    #print data
    lines = data.split('\n')
    for l in lines:
        if l.startswith('=============='):
            continue
        if "Counter Name" in l:
            continue
        terms = l.split('||')
        #####################################
        ######### counter names #########
        #####################################
        #print terms
        if len(terms) < 3:
            continue
        key, val = terms[1:3]
        #print key,val
        if key.startswith('==========='):
            continue
        if key.startswith('-----------'):
            continue
        key = key.lower()
        key = key.rstrip()
        key = key.replace(' ', '_')
        key = key[1:]
        key = 'neo_' + key
        val = val[:val.find('[')]
        val = val.replace(',', '')
        if len(val.replace(' ', '')) == 0:
            continue
        val = val.replace("\x7c", "")
        try:
            val = float(val)
        except:
            print 'Fail', f, l
            print 'val:', len(val), val.encode('hex')
            print 'val:', val
            # raise
            continue
        if val.is_integer():
            val = int(val)
        #print key, val
        try:
            res[key].append(val)
        except:
            res[key] = [val]
        #####################################
        ######### neo host analysis #########
        #####################################
        # we ignore raw counters and focus on analysis for now
        if len(terms) < 5:
            continue
        key, val = terms[3:5]
        if key.startswith('==========='):
            continue
        if key.startswith('-----------'):
            continue
        key = key.lower()
        key = key.rstrip()
        key = key.replace(' ', '_')
        key = key[2:]
        key = 'neo_' + key
        val = val[:val.find('[')]
        val = val.replace(',', '')
        if len(val.replace(' ', '')) == 0:
            continue
        try:
            val = float(val)
        except:
            continue
        if val.is_integer():
            val = int(val)
        #print key, val
        try:
            res[key].append(val)
        except:
            res[key] = [val]

    out = {}
    for k,v in res.items():
        if 'utilization' in k: # remove faulty measurements of 0 utilization
            v = filter(lambda x : x > 1, v)
        out[k] = np.average(reject_outliers(v))

    return out

def to_bps(pkts, size = 1500, t = 20.0):
    return pkts * size * 8 / t

# RESULT-CYCLEPP1 141
# RESULT-CYCLEPP2 142
def read_fclick_wp(f):
    res = {'fclick_cycles' : [], 'fclick_cycles_pb' : [],
           'fclick_cycles_idle' : [], 'fclick_oob_bps' : [],
           'fclick_missed_bps' : [],
           'fclick_discards_bps' : []}
    data = open(f, 'rb').read()
    lines = data.split('\n')
    for l in lines:
        if l.startswith('rx_missed_errors'):
            l1 = l.split(' ')
            # assume it runs for 20sec * 2 for two NICs
            res['fclick_missed_bps'].append(to_bps(float(l1[2])) * 2)
        if l.startswith('rx_discards_phy'):
            l1 = l.split(' ')
            # assume it runs for 20sec * 2 for two NICs
            res['fclick_discards_bps'].append(to_bps(float(l1[2])) * 2)
        if l.startswith('rx_out_of_buffer'):
            l1 = l.split(' ')
            # assume it runs for 20sec * 2 for two NICs
            res['fclick_oob_bps'].append(to_bps(float(l1[2])) * 2)
        if l.startswith('RESULT-CYCLEPP'):
            l1 = l.split(' ')
            res['fclick_cycles'].append(int(l1[1]))
        if l.startswith('RESULT-CYCLEPB'):
            l1 = l.split(' ')
            res['fclick_cycles_pb'].append(int(l1[1]))
        if l.startswith('RESULT-CYCLE_IDLE'):
            l1 = l.split(' ')
            res['fclick_cycles_idle'].append(float(l1[1]))
    out = {}
    for k,v in res.items():
        out[k] = np.average(reject_outliers(v))
    out['fclick_total_drops'] = out['fclick_discards_bps'] + out['fclick_oob_bps'] + out['fclick_missed_bps']
    return out

def read_dpdk_ping_client(f):
    res = {}
    data = open(f, 'rb').read()
    lines = data.split('\n')
    for l in lines:
        # 1000000 iters in 3.12 seconds = 3.12 usec/iter
        items = re.findall('\d+ iters in \d+\.\d+ seconds = (\d+\.\d+) usec/iter', l)
        if len(items) != 0:
            if not 'dpdk_ping_rtt' in res.keys():
                res['dpdk_ping_rtt'] = []
            res['dpdk_ping_rtt'].append(float(items[0]))
        # average tsc: 524 cycles
        items = re.findall('average tsc: (\d+) cycles', l)
        if len(items) != 0:
            if not 'dpdk_ping_tsc' in res.keys():
                res['dpdk_ping_tsc'] = []
            res['dpdk_ping_tsc'].append(float(items[0]))
        # tx tsc: 131 cycles
        items = re.findall('tx tsc: (\d+) cycles', l)
        if len(items) != 0:
            if not 'dpdk_ping_tx_tsc' in res.keys():
                res['dpdk_ping_tx_tsc'] = []
            res['dpdk_ping_tx_tsc'].append(float(items[0]))
        # rx tsc: 131 cycles
        items = re.findall('rx tsc: (\d+) cycles', l)
        if len(items) != 0:
            if not 'dpdk_ping_rx_tsc' in res.keys():
                res['dpdk_ping_rx_tsc'] = []
            res['dpdk_ping_rx_tsc'].append(float(items[0]))

    res['dpdk_ping_rtt'] = reject_outliers(res['dpdk_ping_rtt'])
    res['dpdk_ping_tsc'] = reject_outliers(res['dpdk_ping_tsc'])
    res['dpdk_ping_tx_tsc'] = reject_outliers(res['dpdk_ping_tx_tsc'])
    res['dpdk_ping_rx_tsc'] = reject_outliers(res['dpdk_ping_rx_tsc'])
    out = {}
    for k in res.keys():
        if res[k] != []:
            out[k] = np.average(res[k])
            out[k+'_std'] = np.std(res[k])
            #print 'dpdk ping ', out, res
        else:
            out[k] = 0

    return out

def read_dpdk_ping_server(f):
    res = {}
    data = open(f, 'rb').read()
    lines = data.split('\n')
    for l in lines:
        # average tsc: 524 cycles
        items = re.findall('average tsc: (\d+) cycles', l)
        if len(items) != 0:
            if not 'dpdk_pong_tsc' in res.keys():
                res['dpdk_pong_tsc'] = []
            res['dpdk_pong_tsc'].append(float(items[0]))
        # tx tsc: 131 cycles
        items = re.findall('tx tsc: (\d+) cycles', l)
        if len(items) != 0:
            if not 'dpdk_pong_tx_tsc' in res.keys():
                res['dpdk_pong_tx_tsc'] = []
            res['dpdk_pong_tx_tsc'].append(float(items[0]))
        # rx tsc: 131 cycles
        items = re.findall('rx tsc: (\d+) cycles', l)
        if len(items) != 0:
            if not 'dpdk_pong_rx_tsc' in res.keys():
                res['dpdk_pong_rx_tsc'] = []
            res['dpdk_pong_rx_tsc'].append(float(items[0]))

    res['dpdk_pong_tsc'] = reject_outliers(res['dpdk_pong_tsc'])
    res['dpdk_pong_tx_tsc'] = reject_outliers(res['dpdk_pong_tx_tsc'])
    res['dpdk_pong_rx_tsc'] = reject_outliers(res['dpdk_pong_rx_tsc'])
    out = {}
    for k in res.keys():
        if res[k] != []:
            out[k] = np.average(res[k])
            out[k+'_std'] = np.std(res[k])
            #print 'dpdk ping ', out, res
        else:
            out[k] = 0

    return out

def read_ibvping_client(f):
    res = {}
    data = open(f, 'rb').read()
    lines = data.split('\n')
    for l in lines:
        # 1000000 iters in 3.94 seconds = 3.94 usec/iter
        items = re.findall('\d+ iters in \d+\.\d+ seconds = (\d+\.\d+) usec/iter', l)
        if len(items) != 0:
            if not 'ibvping_rtt' in res.keys():
                res['ibvping_rtt'] = []
            res['ibvping_rtt'].append(float(items[0]))

    res['ibvping_rtt'] = reject_outliers(res['ibvping_rtt'])
    out = {}
    for k in res.keys():
        if res[k] != []:
            out[k] = np.average(res[k])
            out[k+'_std'] = np.std(res[k])
            #print 'dpdk ping ', out, res
        else:
            out[k] = 0

    return out

def read_mica_lat(f):
    res = {'mica_avg' : []}
    histogram = {}
    data = open(f, 'rb').read()
    lines = data.split('\n')
    # read histogram
    for l in lines:
        #   0      0
        items = re.findall('\s*(\d+)\s+(\d+)', l)
        if len(items) != 0:
            # print len(items), items
            k = int(items[0][0])
            v = int(items[0][1])
            if k == 1920:
                print "Skipping key 1920 value %d" % v
                continue
            if k not in histogram.keys():
                histogram[k] = v
            else:
                histogram[k] += v

    # calculate avg, median, 90th, 99th
    num_items = sum([v for v in histogram.values()])
    total = sum([k*v for k,v in histogram.items()])
    avg = float(total) / num_items
    th99 = th90 = th50 = 0
    cdf = 0
    for k,v in histogram.items():
        cdf += v
        if th50 == 0 and cdf >= (num_items * 50.0 / 100.0 ):
            th50 = k
        if th90 == 0 and cdf >= (num_items * 90.0 / 100.0 ):
            th90 = k
        if th99 == 0 and cdf >= (num_items * 99.0 / 100.0 ):
            th99 = k

    out = {}
    out['mica_avg'] = '%.2f' % avg
    out['mica_50th'] = th50
    out['mica_90th'] = th90
    out['mica_99th'] = th99

    return out

def read_mica_server(f):
    res = {'mica_mops' : []}
    data = open(f, 'rb').read()
    lines = data.split('\n')
    # read histogram
    for l in lines:
        # current_ops:      11.57 Mops
        items = re.findall('current_ops:\s*(\d+\.\d+) Mops', l)
        if len(items) != 0:
            if float(items[0]) != 0.0:
                res['mica_mops'].append(float(items[0]))

    out = {}
    out['mica_mops'] = '%.2f' % np.average(reject_outliers(res['mica_mops']))

    return out

