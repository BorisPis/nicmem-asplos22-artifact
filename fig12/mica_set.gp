fontsize=18
xticfont=18
smallfontsize=14
set terminal postscript eps color enhanced fontsize;
set output 'mica_set.eps'

legend_inside = 0;

set datafile separator ","

#-------------------------------------------------------------------------------
# multiplot
#-------------------------------------------------------------------------------
xsiz= .30
xoff= .065
xnum= 2
xall= xoff+xnum*xsiz

ysiz= .33
yoff= legend_inside ? .12 : .16
ynum= 1
yall = yoff+ynum*ysiz
print xall, yall

set size xall,yall
set multiplot
set size xsiz,ysiz

#-------------------------------------------------------------------------------
# axes
#-------------------------------------------------------------------------------
#set logscale x 2
set grid front
#set xtics  font ",".xticfont norotate nomirror offset 0.0,0.3\
#set xtics format "%g" rotate 90 font ",".xticfont 20
set xrange [-15:115];
set yrange[0:13.5];
set xtics out nomirror rotate by -40 offset -0.4,.2 format "%g";
#set yrange [0:805];
set ytics out nomirror ("0" 0, "2" 2, "4" 4, "6" 6, "8" 8, "10" 10, "12" 12) offset .5,0;
set border back;   # place borders below data
set grid y lc "gray";

#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
#set border 1+2+8;
set tmargin 1.5
set bmargin 1.0
set lmargin 3.5
set rmargin .5

#-------------------------------------------------------------------------------
# style
#-------------------------------------------------------------------------------

set style data linesp 

w=3; p=1.5;
t=1; set style line t lt  t lw w pt t ps p lc rgb 'purple'; 
t=2; set style line t lt  t lw w pt t ps p lc rgb 'purple'; 
t=4; set style line t lt  t lw w pt t ps p lc rgb 'blue';
t=5; set style line t lt  t lw w pt t ps p lc rgb 'blue';
t=6; set style line t lt  t lw w pt t ps p lc rgb 'blue';
t=7; set style line t lt  t lw w pt t ps p lc rgb 'blue';
t=8; set style line t lt  t lw w pt t ps p lc rgb 'blue';

#-------------------------------------------------------------------------------
# labels + key
#-------------------------------------------------------------------------------
set label 1 at screen (xoff+xsiz*xnum/2), screen .1 center \
    "set ratio [%]"
#set title "MICA performance" offset screen xsiz, screen ysiz-.02

if( legend_inside ) {
    set key at screen xoff+.1, screen ysiz-.12 Left left bottom \
       samplen 2 spacing .95 reverse maxcols 1 maxrows 7 invert;
}  else {
    set key at screen 0, screen 0.01 Left left bottom \
       samplen 1 spacing .95 reverse maxcols 1 maxrows 2 width 10.5;
       # samplen 1 spacing .95 reverse maxcols 1 maxrows 2 width 12.5;
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
GetRatio(rate) = (100.0 - rate * 100.0)

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
do for [k=1:2] {
  i=(k-1) % xnum; j=(k-1) / xnum;
  set origin (xoff+i*xsiz),(yoff+j*ysiz)
  if (k == 1) {
    set ylabel "Throughput\n[MRPS]" offset .1,0
  } else {
    unset ylabel
  }
  
  lb(y1,y2) = labstr(y2,y1);
  ns = word(nic_sizes, k)
  #print ns
  yv(y1,y2) = Thpt(y2);
  if ((ns+0) < 1000) {
      set title ns . " KiB hot area" offset 0,-.8;
  } else {
      set title sprintf("%d", (ns / 1024)) . "MiB hot area" offset 0, -.8;
  }

  w=20

  plot sprintf("Results/result.lat.nic.4.%s.1.100.csv", ns) \
     u (GetRatio($17)):(yv($6,$5)) ls 1 t 'nmKVS-allhit', \
       sprintf("Results/result.lat.nic.4.%s.1.0.csv", ns) \
     u (GetRatio($17)):(yv($6,$5)) ls 2 t 'nmKVS-nohit', \
       sprintf("Results/result.lat.base.4.%s.1.100.csv", ns) \
     u (GetRatio($17)):(yv($6,$5)) ls 3 t 'hostmem-allhit', \
       sprintf("Results/result.lat.base.4.%s.1.0.csv", ns) \
     u (GetRatio($17)):(yv($6,$5)) ls 4 t 'hostmem-nohit', \
       sprintf("Results/result.lat.all.%s.1.0.csv", ns) \
     u (GetRatio($17)):(Thpt($5)):(lb($5,$25)) not w labels offset .0,-1.1 rotate by -30 textcolor 'grey40', \
       sprintf("Results/result.lat.all.%s.1.100.csv", ns) \
     u (GetRatio($17)):(Thpt($25)):(lb($5,$25)) not w labels offset .0,1.1 rotate by 30 textcolor 'grey40'

}
