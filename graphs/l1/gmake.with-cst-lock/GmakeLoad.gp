set terminal pdfcairo
set output "GmakeLoad.pdf"
set title 'GmakeLoad'
set xlabel 'cores'
set ylabel 'builds/hour'
set yrange [0:*]
set y2label 'CPU time (secs/build)'
set y2tics 
set ytics nomirror
plot 'GmakeLoad.dat' index 0 title '' with lines linecolor 1,\
  'GmakeLoad.dat' index 1 axis x1y2 title ' user' with linespoints linecolor 2 pointtype 6,\
  'GmakeLoad.dat' index 2 axis x1y2 title ' sys' with linespoints linecolor 3 pointtype 8,\
  'GmakeLoad.dat' index 3 axis x1y2 title ' idle' with linespoints linecolor 4 pointtype 2
