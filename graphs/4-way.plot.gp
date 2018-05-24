#!/usr/bin/env gnuplot

######################################################################
# http://youinfinitesnake.blogspot.com/2011/02/attractive-scientific-plots-with.html
set terminal pdfcairo enhanced dashed size 7in,4.2in font "Gill Sans,9" linewidth 4 rounded fontscale 1.0 

# Line style for axes
set style line 80 lt rgb "#808080"

# Line style for grid
set style line 81 lt 0  # dashed
set style line 81 lt rgb "#808080"  # grey

set grid back linestyle 81
set border 3 back linestyle 80 # Remove border on top and right.  These
             # borders are useless and make it harder
             # to see plotted lines near the border.
    # Also, put it in grey; no need for so much emphasis on a border.
set xtics nomirror
set ytics nomirror

#set log x
#set mxtics 10    # Makes logscale look good.

# Line styles: try to pick pleasing colors, rather
# than strictly primary colors or hard-to-see colors
# like gnuplot's default yellow.  Make the lines thick
# so they're easy to see in small plots in papers.
# Take hints from http://colorbrewer2.org/#type=diverging&scheme=PRGn&n=5
set style line 1 lt rgb "#A00000" lw 2 pt 1
set style line 2 lt rgb "#00A000" lw 2 pt 6
set style line 3 lt rgb "#5060D0" lw 2 pt 2
set style line 4 lt rgb "#F25900" lw 2 pt 9

# Dashed versions of 1 and 2
set style line 5 lt rgb "#A00000" lw 2 pt 1
set style line 6 lt rgb "#00A000" lw 2 pt 6
######################################################################

# set terminal pdf
set output '4-way.plot.pdf'

# Add timestamp to the plot, so we have some semblance of sanity
set timestamp "%d/%m/%y %H:%M" top font "Gill Sans, 6"
show timestamp

set title 'Apache'
set xlabel 'cores'
set ylabel 'requests/sec'
set yrange [0:*]
set ytics nomirror
set key left top
plot \
        'l2/apache.stock/ApacheMon.dat' index 0 title 'nVM' with lp linecolor 1,\
        'l1/apache.stock/ApacheMon.dat' index 0 title 'VM' with lp linecolor 2,\
        'l2/apache.stock-4.17/ApacheMon.dat' index 0 title 'nVM-v4.17rc6' with lp linecolor 1 dt 5,\
        'l1/apache.stock-4.17/ApacheMon.dat' index 0 title 'VM-v4.17rc6' with lp linecolor 2 dt 6
	#'l2/apache.stock-4.17/ApacheMon.dat' index 0 title 'nVM-v4.17rc6' with lp linecolor 1 dt 2,\
	#'l1/apache.stock-4.17/ApacheMon.dat' index 0 title 'VM-v4.17rc6' with lp linecolor 2 dt 2


set title 'Gmake'
set xlabel 'cores'
set ylabel 'builds/hour'
set yrange [0:*]
set ytics nomirror
set key left top
plot \
        'l2/gmake.stock/GmakeLoad.dat' index 0 title 'nVM' with lp linecolor 1,\
        'l1/gmake.stock/GmakeLoad.dat' index 0 title 'VM' with lp linecolor 2,\
        'l2/gmake.stock-4.17/GmakeLoad.dat' index 0 title 'nVM-v4.17rc6' with lp linecolor 5,\
        'l1/gmake.stock-4.17/GmakeLoad.dat' index 0 title 'VM-v4.17rc6' with lp linecolor 6


set title 'Exim'
set xlabel 'cores'
set ylabel 'messages/sec'
set yrange [0:*]
set ytics nomirror
set key left top
plot \
        'l2/exim.stock/EximLoad.dat' index 0 title 'nVM' with lp linecolor 1,\
        'l1/exim.stock/EximLoad.dat' index 0 title 'VM' with lp linecolor 2,\
        'l2/exim.stock-4.17/EximLoad.dat' index 0 title 'nVM-v4.17rc6' with lp linecolor 5,\
        'l1/exim.stock-4.17/EximLoad.dat' index 0 title 'VM-v4.17rc6' with lp linecolor 6

## set title 'Metis'
## set xlabel 'cores'
## set ylabel 'jobs/hour'
## set yrange [0:*]
## set ytics nomirror
## set key left top
## plot \
##         'l2/metis.stock/MetisLoad.dat' index 0 title 'nVM' with lp linecolor 1,\
##         'l1/metis.stock/MetisLoad.dat' index 0 title 'VM' with lp linecolor 2,\
##         'l2/metis.stock-4.17/MetisLoad.dat' index 0 title 'nVM-v4.17rc6' with lp linecolor 5,\
##         'l1/metis.stock-4.17/MetisLoad.dat' index 0 title 'VM-v4.17rc6' with lp linecolor 6


set title 'Psearchy'
set xlabel 'cores'
set ylabel 'jobs/hour'
set yrange [0:*]
set ytics nomirror
set key left top
plot \
        'l2/psearchy.stock/PsearchyLoad.dat' index 0 title 'nVM' with lp linecolor 1,\
        'l1/psearchy.stock/PsearchyLoad.dat' index 0 title 'VM' with lp linecolor 2,\
        'l2/psearchy.stock-4.17/PsearchyLoad.dat' index 0 title 'nVM-v4.17rc6' with lp linecolor 5,\
        'l1/psearchy.stock-4.17/PsearchyLoad.dat' index 0 title 'VM-v4.17rc6' with lp linecolor 6


### set title 'Pbzip'
### set xlabel 'cores'
### set ylabel 'jobs/hour'
### set yrange [0:*]
### set ytics nomirror
### set key left top
### plot \
###         'nested/pbzip/pbzip.dat' index 0 title 'nVM' with lp linecolor 1, \
###         'vm/pbzip/pbzip.dat' index 0 title 'VM' with lp linecolor 2
