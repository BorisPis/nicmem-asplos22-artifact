fontsize=18
set terminal postscript eps color fontsize
set output 'memcpy_reverse.eps'
set size 0.6,0.45
ylabfontsiz = fontsize*.8; 

#set grid y;
set yrange [0:35]
set xrange [500:2000000000]
set xtics nomirror
set ytics nomirror
set logscale x 10
set format x "%0.s%c"

#-------------------------------------------------------------------------------
# multiplot
#-------------------------------------------------------------------------------
xsiz=.675
xoff=.03
xnum=1
xall=xoff+xnum*xsiz

ysiz=.5
yoff=.06
ynum=1
yall=yoff+ynum*ysiz

set size xall,yall
set multiplot
set size xsiz,ysiz

#-------------------------------------------------------------------------------
# labels
#-------------------------------------------------------------------------------
set ylabel "rate\n[bytes/cycles]" offset .5,0
set xlabel "dest buffer size [bytes]" offset .5,0
set title "memcpy from buffer of 128KiB" offset 0,-.5  
#
#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set bmargin 3.5;
set lmargin 8

labstr(str) = sprintf("{/=%.1f %.1f}",ylabfontsiz, str);
diff(a,b) = (a/b);

set key top right
set style data linesp

w=5; s=2;
set style line 1 lt 1 lw w ps s
set style line 2 lt 2 lw w ps s

yhi=5

plot 'result_reverse.csv' \
   u 1:2 t "host memcpy" ls 1, \
'' u 1:3 t "NIC memcpy"  ls 2 ,\
'' u 1:($2+yhi):(labstr(diff($2,$3))) every 2 ls 3 not w labels offset 0.5,0 rotate by 45
