fontsize=18
set terminal postscript eps color enhanced fontsize;
set output 'scatter.eps'
set datafile separator ","

#-------------------------------------------------------------------------------
# multiplot
#-------------------------------------------------------------------------------
xsiz=.14
xoff=.095
xoff2=.01
xnum=4
xall=xoff+xnum*xsiz+xoff2

ysiz=.23
yoff=.18
yoff2=.006
ynum=2
yall=yoff+ynum*ysiz+yoff2

print "# dimensions:", xall, yall

set size xall,yall
set multiplot
set size xsiz,ysiz

#-------------------------------------------------------------------------------
# axes
#-------------------------------------------------------------------------------
set grid lc "gray"
set xtics 1
set logscale y 4
unset key

#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set tmargin 1.5
set bmargin 0.5
set lmargin 1.6
set rmargin .1

#-------------------------------------------------------------------------------
# style
#-------------------------------------------------------------------------------

# for the scatter points
set style data points
i=1; set style line i lt i pt i lw 2
i=2; set style line i lt i pt i lw 2

# for the arrow
i=3; set style line i lt i pt i 
set style arrow i filled heads size char .6,25 lt i lw 2

# macro for plotting the labels
#lblstyl = "u 3:4:7 w labels not off 1.5,-.4 font ',14' textcolor 'gray30'"; 
lblstyl = "u 3:4:7 w labels not off 4.8,-0.2 font ',14' textcolor 'gray30'"; 


#-------------------------------------------------------------------------------
# labels + key
#-------------------------------------------------------------------------------
set label 1 'cycles/packet (x1000)' \
  at screen xoff+xnum*.5*xsiz,0 center offset 0,3

#-------------------------------------------------------------------------------
# functions, constants
#-------------------------------------------------------------------------------
   rx(rx) = (197.9 - ((rx) / 1000000000.0)) # Gbps
 lat(lat) = (lat) # latency in us
 cyc(cyc) = (cyc/1000.0) # cycles
   cutoff = cyc(1814);

#-------------------------------------------------------------------------------
# file names:
#     memloc = nic|host|base
#      membw = highm|lowm
#        cpu = highc|lowc
#-------------------------------------------------------------------------------
_fnam(memloc,cpu,membw) = sprintf("Results/result.%s.%s.%s.csv",cpu,membw,memloc)
fnam(memloc,membw) = sprintf("< cat %s %s", \
  _fnam(memloc,"lowc" ,membw), \
  _fnam(memloc,"highc",membw))

#-------------------------------------------------------------------------------
# arrays 
#-------------------------------------------------------------------------------
array arMemLoc[xnum] = ["base",  "host" ,  "nic", "nic-inline"]
array arMemTit[xnum] = ["host",  "split",  "nmNFV-", "nmNFV"]
array arLtr[xnum]    = ["a"   ,  "b"    ,  "c"  , "d"         ]

array arMetric_[2]   = ["loss"    , "latency"               ];
array arMetric[2]    = ["missing\nthpt [Gb/s]", \
                        "lat [{/Symbol m}s]"];
array arMetricCol[2] = [19        , 16                      ];
array arYlo[2]       = [.5        , 8                       ];
array arYhi[2]       = [128       , 4096                    ];

#-------------------------------------------------------------------------------
# arrows data (1=x, 2=y, 3=xdelta, 4=ydelta)
#-------------------------------------------------------------------------------
print "# content for arrows.txt:"
do for [row=1:2] {
  print sprintf("%.3f,%.3f,%.3f,%.3f", \
  	cutoff, arYlo[row], 0, arYhi[row]-arYlo[row])
}

#-------------------------------------------------------------------------------
# plot
#-------------------------------------------------------------------------------
do for [row=1:2] {
  do for [col=1:4] {

    # origin
    i=col-1; j=2-row;
    set origin (xoff+i*(xsiz)),(yoff+j*ysiz)

    # title
    mloc = arMemLoc[col];
    mtit = arMemTit[col];
    ltr  = arLtr[col];
    if( row==1 && col!=4) {
      set title sprintf("(%s) %s", ltr, mtit) offset -.5,-.5
    } else {
      if ( row==1 && col==4) {
        set title sprintf("(%s) %s", ltr, mtit) offset -.3,-.5
      }
      else         { unset title }
    }
    set ytics out nomirror;
    set xtics out nomirror;

    # x
    set xrange [ 1 : 3.5 ];
    # y 
    set yrange [ arYlo[row] : arYhi[row] ];
    if( col==1 ) { set label 2 arMetric[row] rot at graph 0, .5 off -7 center; }
    else         { unset label 2; }
    if( col==1 ) {
      if (row==2) {
        set ytics ("16" 16, "64" 64, "256" 256, "1K" 1024, "4K" 4096) out nomirror
      } else {
        set ytics ("1" 1, "4" 4, "16" 16, "64" 64) out nomirror
        #set ytics autofreq;
      }
      set ytics format "%g";
    }
    else {
      if (row==1) {
        #set ytics format "";
        set ytics ("" 1, "" 4, "" 16, "" 64) out nomirror
      } else {
        set ytics ("" 16, "" 64, "" 256, "" 1024, "" 4096) out nomirror
      }
    }
    
    # x
    if( row==1 ) { set xtics format ""; }
    else         { set xtics format "%g";   }

    # key
    if( col==1 && row ==2 ) {
      set key at screen -0.01, 0.002 Left left bottom reverse samplen 1.5 invert
    } else {
      unset key
    }

    #set arrow 1 from first cutoff,arYlo[row] to cutoff,arYhi[row] \
    #  filled heads lt 3 lw 2 size char .8,25
    
    c = arMetricCol[row];
    m = arMetric_[row];
    y(m) = (row==1) ? rx(m) : lat(m);

    if( mloc eq 'nic-inline' ) { # no high mem...
      plot \
        'arrows.txt' index (row-1) u 1:2:3:4 w vec t 'cutoff cycles'    as 3,\
        fnam(mloc,'lowm' ) u (cyc($30)):(y(column(c))) t 'low mem bw'  ls 1,\
	sprintf("< grep %s Results/labels.txt| grep %s | head -n 2",mloc,m) @lblstyl
    } else {
      plot \
        'arrows.txt' index (row-1) u 1:2:3:4 w vec t 'cutoff cycles'    as 3,\
        fnam(mloc,'highm') u (cyc($30)):(y(column(c))) t 'high mem bw' ls 2,\
        fnam(mloc,'lowm' ) u (cyc($30)):(y(column(c))) t 'low mem bw'  ls 1,\
	sprintf("< grep %s Results/labels.txt| grep %s | head -n 2",mloc,m) @lblstyl
    }

    unset label 1;
    unset arrow 1
  }
}
