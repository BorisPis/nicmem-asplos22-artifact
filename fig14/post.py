#!/usr/bin/python
import sys

def get_other(lines, size):
    for l in lines:
        _size, _rate = l.split(',')
        if int(_size) == int(size):
            return float(_rate)

class Exp:
    def __init__(self, l1, l2):
        elements1 = l1.split(',')
        elements2 = l2.split(',')
        self.size = int(elements1[0])
        assert int(elements1[0]) == int(elements2[0]), elements1 + elements2
        self.host_rate = float(elements1[1])
        self.nic_rate = float(elements2[1])

HEADER = '{:>10} {:>5s} {:>5s}'
FORMAT = '{:>10} {:>5.2f} {:>5.2f}'

def process(host, nic):
    exps = []
    host_data = open(host, 'r').read()
    host_lines = host_data.split('\n')[1:-1]
    nic_data = open(nic, 'r').read()
    nic_lines = nic_data.split('\n')[1:-1]
    HEADER.format('size', 'host', 'nic')
    for i in xrange(len(host_lines)):
        exp = Exp(host_lines[i], nic_lines[i])
        print FORMAT.format(exp.size, exp.host_rate, exp.nic_rate)

if __name__ == '__main__':
        if len(sys.argv) < 3:
            print 'Usage: %s <host-memcpy> <nic-memcpy>'
            sys.exit(1)
        process(sys.argv[1], sys.argv[2])
