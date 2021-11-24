from trex_stl_lib.api import *

# 1514 byte packets
class STLImix(object):

    def __init__ (self):
        # default IP range
        self.ip_range = {'src': {'start': "16.1.1.1", 'end': "16.63.254.254"},
                         'dst': {'start': "48.1.1.1",  'end': "48.1.1.4"}}

        # default IMIX properties
        self.imix_table = [ {'size': 1514, 'pps': 1000,   'isg':0.2 } ]
        self.pg_id = 0

    def create_stream (self, size, pps, isg, vm ):
        # Create base packet and pad it to size
        base_pkt = Ether()/IP()/UDP()
        pad = max(0, size - len(base_pkt)) * 'x'

        pkt = STLPktBuilder(pkt = base_pkt/pad,
                            vm = vm)

        return STLStream(isg = isg,
                         packet = pkt,
                         mode = STLTXCont(pps = pps))

    def get_lat_streams (self, size, vm):
        base_pkt = Ether()/IP()/UDP()
        pad = max(0, size - len(base_pkt)) * 'x'

        pkt = STLPktBuilder(pkt = base_pkt/pad, vm = vm)

        return STLStream(packet = pkt,
                         mode = STLTXCont(pps = 1000),
                         flow_stats = STLFlowLatencyStats(pg_id = self.pg_id))

    def get_streams (self, direction = 0, pg_id = 7, **kwargs):
        self.pg_id = pg_id + kwargs['port_id']
        self.size = kwargs['size']
        if direction == 0:
            src = self.ip_range['src']
            dst = self.ip_range['dst']
        else:
            src = self.ip_range['dst']
            dst = self.ip_range['src']

        # construct the base packet for the profile
        vm = STLVM()

        # define two vars (src and dst)
        vm.var(name="src",min_value=src['start'],max_value=src['end'],size=4,op="inc")
        vm.var(name="dst",min_value=dst['start'],max_value=dst['end'],size=4,op="inc")

        # write them
        vm.write(fv_name="src",pkt_offset= "IP.src")
        vm.write(fv_name="dst",pkt_offset= "IP.dst")

        # fix checksum
        vm.fix_chksum()

        # create imix streams
        return [self.create_stream(self.size, x['pps'],x['isg'] , vm) for x in self.imix_table] +\
               [self.get_lat_streams(64, vm)]



# dynamic load - used for trex console or simulator
def register():
    return STLImix()
