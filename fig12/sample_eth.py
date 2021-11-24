#!/usr/bin/python
from subprocess import Popen, PIPE
from sys import argv, exit
from time import sleep

def comp_ethtool(iface):
    output = Popen("ethtool -S %s" % iface, shell = True, stdout = PIPE).stdout.read()
    lines = output.split('\n')
    stat = []
    for l in lines:
        elements = l.split(':')
        if len(elements) != 2:
            continue
        try:
            stat.append((elements[0], int(elements[1])))
        except:
            pass
    #print 'stat:', stat
    return stat

def bytes2gbps(n):
    return float(n) * 8 / 1000 / 1000 / 1000

def main():
    iface = argv[2]
    sstat = comp_ethtool(iface)
    t = int(argv[1])
    sleep(t)
    estat = comp_ethtool(iface)
    stat_zip = zip(sstat, estat)
    for (t1,n1), (t2,n2) in stat_zip:
        assert t1 == t2, "different text %s vs. %s" % (t1, t2)
        if n1 != n2:
            value = abs(n2 - n1) / float(t)
            if 'bytes' in t1:
                print "%s_%s: %.2f" % (iface, t1.lstrip().replace('bytes', 'bw'), bytes2gbps(value))
                #value = bytes2gbps(value)
            print "%s_%s: %d" % (iface, t1.lstrip(), value)

if __name__ == '__main__':
    if len(argv) != 3:
        exit('Usage: %s <sleep-time> <netdev>' % argv[0])
    main()


