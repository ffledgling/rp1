set terminal pdfcairo
set output "GmakeLoad.pdf"
set title 'GmakeLoad'
set xlabel 'cores'
set ylabel 'builds/hour'
set yrange [0:*]
set y2label 'CPU time (secs/build)'
set y2tics 
set ytics nomirror
plot 'GmakeLoad.dat' index 0 title '20180505-104800/benchmark-gmake' with lines linecolor 1,\
  'GmakeLoad.dat' index 1 axis x1y2 title '20180505-104800/benchmark-gmake user' with linespoints linecolor 2 pointtype 6,\
  'GmakeLoad.dat' index 2 axis x1y2 title '20180505-104800/benchmark-gmake sys' with linespoints linecolor 3 pointtype 8,\
  'GmakeLoad.dat' index 3 axis x1y2 title '20180505-104800/benchmark-gmake idle' with linespoints linecolor 4 pointtype 2,\
  'GmakeLoad.dat' index 4 title 'benchmark-gmake' with lines linecolor 1,\
  'GmakeLoad.dat' index 5 axis x1y2 title 'benchmark-gmake user' with linespoints linecolor 2 pointtype 6,\
  'GmakeLoad.dat' index 6 axis x1y2 title 'benchmark-gmake sys' with linespoints linecolor 3 pointtype 8,\
  'GmakeLoad.dat' index 7 axis x1y2 title 'benchmark-gmake idle' with linespoints linecolor 4 pointtype 2
