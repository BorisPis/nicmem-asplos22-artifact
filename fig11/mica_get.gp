fontsize=18
xticfont=18
smallfontsize=14
set terminal postscript eps color enhanced fontsize;
set output 'mica_get.eps'

legend_inside = 0;

set datafile separator ","

#-------------------------------------------------------------------------------
# multiplot
#-------------------------------------------------------------------------------
xsiz= .30
xoff= .07
xnum= 2
xall= xoff+xnum*xsiz

ysiz= .20
yoff= legend_inside ? .13 : .15
yoff2=.03
ynum= 3
yall = yoff+ynum*ysiz+yoff2
print xall, yall

set size xall,yall
set multiplot
set size xsiz,ysiz

#-------------------------------------------------------------------------------
# axes
#-------------------------------------------------------------------------------
#set logscale x 2
set grid front
set xrange [-15:115];
set border back;   # place borders below data
set grid y lc "gray";

#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
#set border 1+2+8;
set tmargin 0.5
set bmargin 0.5
set lmargin 4.5
set rmargin .5

#-------------------------------------------------------------------------------
# style
#-------------------------------------------------------------------------------

set style data linesp 

w=3; p=1.5;
t=1; set style line 1 lt  1 lw w pt 1 ps p lc rgb 'purple'; 
t=4; set style line 4 lt  t lw w pt 2 ps p lc rgb 'blue';
t=5; set style line 5 lt  t lw w pt 3 ps p lc rgb 'blue';
t=6; set style line 6 lt  t lw w pt 4 ps p lc rgb 'blue';
t=7; set style line 7 lt  t lw w pt 5 ps p lc rgb 'blue';
t=8; set style line 8 lt  t lw w pt 6 ps p lc rgb 'blue';

#-------------------------------------------------------------------------------
# labels + key
#-------------------------------------------------------------------------------
set label 1 at screen (xoff+xsiz*xnum/2), screen .065 center \
    "Requests from hot area (%)"

if( legend_inside ) {
    set key at screen xoff+.1, screen ysiz-.12 Left left bottom \
       samplen 2 spacing .95 reverse maxcols 1 maxrows 7 invert;
}  else {
    set key at screen 0, screen 0 Left left bottom \
       samplen 2 spacing .95 reverse maxcols 1 maxrows 1 width 2;
}

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
Lat    (lat) = (lat) # us
Thpt   (thpt) = (thpt) # Gbps
ReqRate (rate,tid) = (rate * tid / 1000000.0)
NicRatio(rate) = (rate)

labstr(n,d)  = (d<=0.1 ? "" : ((n/d >= 2) \
  ? sprintf("{/=%.0f %.1fx}", smallfontsize, n/d) \
  : ((n/d >= 1.005 || n/d < .995) \
    ? sprintf("{/=%.0f %.0f%%}", smallfontsize, 100*n/d-100) \
    : sprintf("{/=%.0f %.1f%%}", smallfontsize, 100*n/d-100) ) ) )

#-------------------------------------------------------------------------------
# arrays -- one entry per plot
#-------------------------------------------------------------------------------
nic_sizes = "256 65536"

#-------------------------------------------------------------------------------
# plot
#-------------------------------------------------------------------------------
do for [row=1:3] {
  do for [col=1:2] {
    i=col-1; j=3-row;
    set origin (xoff+i*(xsiz)),(yoff+j*ysiz);

    if (row == 1 && col == 1) {
      set ylabel "Throughput\n[MRPS]" offset -1.5,0
    } else {
      if (row == 2 && col == 1) {
        set ylabel "Latency\n[{/Symbol m}s]" offset 0.4,0
      } else {
        if (row == 3 && col == 1) {
          set ylabel "99p Latency\n[{/Symbol m}s]" offset 1.5,0
        } else {
          unset ylabel
        }
      }
    }

    if (row == 3) {
      set xtics out nomirror rotate by -40 offset -0.4,.2 format "%g";
      set yrange[0:1050];
      set ytics out nomirror 200 offset 0.5,0;
      m_yoff = -0.9;
      m_rot = 30;
    } else {
      if (row == 2) {
        set yrange[0:850];
        set ytics out nomirror 200 offset 0.5,0;
        m_yoff = -0.9;
        m_rot = 30;
      } else {
        set xtics out nomirror format '';
        set yrange[0:15.1];
        #set ytics out nomirror ("0" 0, "2" 2, "4" 4, "6" 6, "8" 8, "10" 10, "12" 12) offset .5,0;
        set ytics out nomirror ("0" 0, "4" 4, "8" 8, "12" 12) offset .5,0;
        m_yoff = 0.9;
        m_rot = -30;
      }
    }

    lb(y1,y2) = labstr(y2,y1);
    ns = word(nic_sizes, col);
    yv(y1,y2,y3) = (row == 1) ? Thpt(y2) : ((row == 2) ? Lat(y1) : Lat(y3));

    if (row == 1) {
      if ((ns+0) < 1000) {
        set title ns . " KiB hot area" offset 0,-.8;
      } else {
        set title sprintf("%d", (ns / 1024)) . "MiB hot area" offset 0, -.8;
      }
    } else {
      unset title;
    }

    plot sprintf("Results/result.lat.nic.4.%s.csv", ns) \
      u (NicRatio($16)):(yv($6,$5,$8)) ls 4 t 'nmKVS hot area', \
         sprintf("Results/result.lat.base.4.%s.csv", ns) \
         u (NicRatio($16)):(yv($6,$5,$8)) ls 1 t 'hostmem hot area', \
         sprintf("Results/result.lat.all.%s.csv", ns) \
         u (NicRatio($16)):(yv($26,$25,$28)):(lb(yv($6,$5,$8),yv($26,$25,$28))) not w labels offset .0,m_yoff rotate by m_rot textcolor 'grey40'

    unset label 1;
    unset label 2;
    unset key;
  }
}
