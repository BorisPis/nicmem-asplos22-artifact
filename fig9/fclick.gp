fontsize=18
xticfont=18
set terminal postscript eps color enhanced fontsize;
set output 'fclick.eps'

set datafile separator ","

#-------------------------------------------------------------------------------
# multiplot
#-------------------------------------------------------------------------------
xsiz=.21
xoff=.06
xoff2=.02
xnum=6
xall=xoff+xnum*xsiz+xoff2

ysiz=.20
yoff=.13
yoff2=.08
ynum=2
yall=yoff+ynum*ysiz+yoff2
print xall, yall

set size xall,yall
set multiplot
set size xsiz,ysiz

#-------------------------------------------------------------------------------
# axes
#-------------------------------------------------------------------------------
#set logscale x 2
set grid front
set xtics  font ",".xticfont nomirror \
  scale .7 offset -.6,.2 rotate by -50 \
  ("0" 0, "2" 2, "4" 4, "6" 6, "8" 8, "10" 10) # (0, 2, 4, 6, 8, 10, 12, 14)
#set xrange [-20:220];
#set xtics format "%g" rotate 90 font ",".xticfont 20
set xrange [-0.5:11.5] # [0:14.9];
set yrange [0:*];

#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set tmargin 0.8
set bmargin 0.4
set lmargin 2.5
set rmargin 1

#-------------------------------------------------------------------------------
# style
#-------------------------------------------------------------------------------
set border back;   # place borders below data
set grid y lc "gray";
set grid x lc "black";
set style data linesp 

# set boxwidth .75 relative
# set style fill solid .9 border -1
# set style histogram rowstacked
# set style data histograms
#set style data filledcurve x1

# lc overwrites lt; ps/pt are meaningless for bars
w=2; p=1.5;
t=4; set style line t lt  1 lw w pt 5 ps p lc rgb 'blue';
t=5; set style line t lt  1 lw w pt 2 ps p lc rgb 'red';
t=6; set style line t lt  1 lw w pt 3 ps p lc rgb 'green';
t=7; set style line t lt  1 lw w pt 4 ps p lc rgb 'purple'; 

#-------------------------------------------------------------------------------
# labels + key
#-------------------------------------------------------------------------------
set label 2 at screen (xoff+xsiz*xnum/2), screen .06 center \
    "DDIO ways (#)"
    #"cores (#)"

set key at screen 0.02, screen 0.003 Left left bottom \
   samplen 2 spacing .95 reverse maxrows 1 invert width 10


#-------------------------------------------------------------------------------
# uppercase/lowercase functions (general purpose)
#-------------------------------------------------------------------------------

# Index lookup table strings
UCases="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
LCases="abcdefghijklmnopqrstuvwxyz"

# Convert a single character
toupperchr(c)=substr( UCases.c, strstrt(LCases.c, c), strstrt(LCases.c, c) )
tolowerchr(c)=substr( LCases.c, strstrt(UCases.c, c), strstrt(UCases.c, c) )

# Convert whole strings
toupper(s) = s eq ""  ?  ""  :  toupperchr(s[1:1]).toupper(s[2:*])
tolower(s) = s eq ""  ?  ""  :  tolowerchr(s[1:1]).tolower(s[2:*])

#-------------------------------------------------------------------------------
# data functions
#-------------------------------------------------------------------------------

idlP (rx,tx,idle,lookup,all) = (idle / all) * 100.0 # P = percent
cacheHits (refs,miss) = (1 - (miss / refs)) * 100.0 # P = percent

computeC (rx,tx,idle,lookup,all,time) = (lookup / time) / 1000000.0 # Millions

netbw (tx,rx) = (rx+tx)

cores (l) = (l*2);
ddio  (l) = (l);
rxd   (l) = (l);
size  (l) = (l);

trexRx (rx) = (rx) / 1000000000.0 # Gbps
trexLat (lat) = (lat) # us
nicLat (lat) = (lat) # us
pcieUti(pci) = (pci) # us

# # c = commutative
# c_idl    (all,cpy,crc,iops,cpu) = \
#   idl    (all,cpy,crc,iops,cpu)
#   
# c_otr    (all,cpy,crc,iops,cpu) = \
#   c_idl  (all,cpy,crc,iops,cpu) + \
#   otr    (all,cpy,crc,iops,cpu)
# 
# c_cpy    (all,cpy,crc,iops,cpu) = \
#   c_otr  (all,cpy,crc,iops,cpu) + \
#   cpy    (all,cpy,crc,iops,cpu)
# 
# c_crc    (all,cpy,crc,iops,cpu) = \
#   c_cpy  (all,cpy,crc,iops,cpu) + \
#   crc    (all,cpy,crc,iops,cpu)

labstr(str) = sprintf("%.0f%%", str);
xt(iod) = iod < 1000 ? sprintf("%.0f",iod) : sprintf("%.0fK",iod/1024.0);

hit_rate(hit,mss) = hit / (hit+mss) * 100.0


#-------------------------------------------------------------------------------
# arrays -- one entry per plot
#-------------------------------------------------------------------------------
array arLtr[xnum * ynum]    = ["a"    , "b"     , "c", "d"  , "e"   , "f" ]
array arTitle[xnum * ynum]  = ["latency\n[{/Symbol m}s]", \
                              "throughput\n[Gbps]", \
                               "PCIe out\nload [%]", \
			       "memory\nbw [GB/s]", "cache\nhit rate [%]", \
			       "PCIe\nhit rate [%]", \
];

arr_yhi    =  "5000 205 110 65 110 110"
#arr_yhi    =  "5000   205 110 65   110  110 "
arr_y1tic  =  "  4  20  20 20  20  20"
#arr_y1tic  =  "   4    40  20 20    20   20 "
arr_ybo    =  "   8 140   0  0   0   0"
#arr_ybo    =  "   8     0   0 0      0    0 "
arr_ylog   =  "   1     0   0 0      0    0 "


#-------------------------------------------------------------------------------
# plot
#-------------------------------------------------------------------------------
do for [z=1:12] {

    i=(z-1) % xnum; j=(z-1) / xnum;
    k = i + 1;
    set origin (xoff+i*xsiz),(yoff+j*ysiz)

    if (j == 1) { workload = "Results/nat"; wname="NAT" }
    else {        workload = "Results/lb" ; wname="LB" }

    if (k == 1) { set ylabel wname offset 1.4,0; }
    else        { unset ylabel; }
    
    yhi        = word(arr_yhi, k);
    ybo        = word(arr_ybo, k);
    y1t        = word(arr_y1tic, k);
    ylg        = word(arr_ylog, k);

    if( ylg > 0 ) { set logscale y 2;  }
    else          { unset logscale y;  }
    if( yhi > 0 )         { set yrange [ybo:yhi] } 
    else {if( ybo > 0 )   { set yrange [ybo:*]   }
    else                  { set yrange [0:*]     }}
    if( y1t > 0 ) { set ytics  y1t     }
    set ytics format "%g" offset 0.8,0;
    set ytics nomirror;

    ltr  = arLtr[k];
    tit  = arTitle[k]
    if (j == 1) {
	    set title sprintf("(%s) %s", ltr, tit) offset 0,-.5;
    } else {
            unset title;
    }

    # the x-axis is offered load in Gb/s
    if (k == 1) {
# latency
	    plot sprintf("%s/result.ddio.nic.csv", workload) \
	       u (ddio($22)):(trexLat($16)) ls 4 t 'nmNFV-', \
                 sprintf("%s/result.ddio.nic-inline.csv", workload) \
	       u (ddio($22)):(trexLat($16)) ls 5 t 'nmNFV', \
		 sprintf("%s/result.ddio.host.csv", workload) \
	       u (ddio($22)):(trexLat($16)) ls 6 t 'split', \
		 sprintf("%s/result.ddio.base.csv", workload) \
	       u (ddio($22)):(trexLat($16)) ls 7 t 'host'
    }
    if (k == 2) {
# handled load
	    plot sprintf("%s/result.ddio.nic.csv", workload) \
	       u (ddio($22)):(trexRx($19)) ls 4 t 'nmNFV-', \
     sprintf("%s/result.ddio.nic-inline.csv", workload) \
	       u (ddio($22)):(trexRx($19)) ls 5 t 'nmNFV', \
		 sprintf("%s/result.ddio.host.csv", workload) \
	       u (ddio($22)):(trexRx($19)) ls 6 t 'split', \
		 sprintf("%s/result.ddio.base.csv", workload) \
	       u (ddio($22)):(trexRx($19)) ls 7 t 'host'
    }
    if (k == 3) {
# PCIe hit rate
	    plot sprintf("%s/result.ddio.nic.csv", workload) \
	       u (ddio($22)):(pcieUti($27)) ls 4 t 'nmNFV-', \
                sprintf("%s/result.ddio.nic-inline.csv", workload) \
	       u (ddio($22)):(pcieUti($27)) ls 5 t 'nmNFV', \
		 sprintf("%s/result.ddio.host.csv", workload) \
	       u (ddio($22)):(pcieUti($27)) ls 6 t 'split', \
		 sprintf("%s/result.ddio.base.csv", workload) \
	       u (ddio($22)):(pcieUti($27)) ls 7 t 'host'
    }
    if (k == 4) {
# memory bandwidth
	    plot sprintf("%s/result.ddio.nic.csv", workload) \
	       u (ddio($22)):4 ls 4 t 'nmNFV-', \
                 sprintf("%s/result.ddio.nic-inline.csv", workload) \
	       u (ddio($22)):4 ls 5 t 'nmNFV', \
		 sprintf("%s/result.ddio.host.csv", workload) \
	       u (ddio($22)):4 ls 6 t 'split', \
		 sprintf("%s/result.ddio.base.csv", workload) \
	       u (ddio($22)):4 ls 7 t 'host' 
    }
    if (k == 5) {
 # cache hit rate
 	    plot sprintf("%s/result.ddio.nic.csv", workload) \
 	       u (ddio($22)):(cacheHits($23,$24)) ls 4 t 'nmNFV-', \
                 sprintf("%s/result.ddio.nic-inline.csv", workload) \
 	       u (ddio($22)):(cacheHits($23,$24)) ls 5 t 'nmNFV', \
 		 sprintf("%s/result.ddio.host.csv", workload) \
 	       u (ddio($22)):(cacheHits($23,$24)) ls 6 t 'split', \
 		 sprintf("%s/result.ddio.base.csv", workload) \
 	       u (ddio($22)):(cacheHits($23,$24)) ls 7 t 'host'
     }
    if (k == 6) {
# PCIe hit rate
	    plot sprintf("%s/result.ddio.nic.csv", workload) \
	       u (ddio($22)):(hit_rate($5,$6)) ls 4 t 'nmNFV-', \
                sprintf("%s/result.ddio.nic-inline.csv", workload) \
	       u (ddio($22)):(hit_rate($5,$6)) ls 5 t 'nmNFV', \
		 sprintf("%s/result.ddio.host.csv", workload) \
	       u (ddio($22)):(hit_rate($5,$6)) ls 6 t 'split', \
		 sprintf("%s/result.ddio.base.csv", workload) \
	       u (ddio($22)):(hit_rate($5,$6)) ls 7 t 'host'
    }

    if (k == 6) {
	    set xtics  font ",".xticfont nomirror \
		    scale .7 offset -.6,.2 rotate by -50 \
		    ("" 0, "" 2, "" 4, "" 6, "" 8, "" 10) # (0, 2, 4, 6, 8, 10, 12, 14)
    }

    set ytics autofreq
    set yrange [*:*]
    unset label 1
    unset label 2
    unset label 3
    unset label 4
    unset label 5
    unset label 6
    unset label 7
    unset key
    unset title
}
