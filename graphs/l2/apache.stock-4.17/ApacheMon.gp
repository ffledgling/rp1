set terminal pdfcairo
set output "ApacheMon.pdf"
set title 'ApacheMon'
set xlabel 'cores'
set ylabel 'requests/sec'
set yrange [0:*]
set y2label 'CPU time (secs/request)'
set y2tics 
set ytics nomirror
plot 'ApacheMon.dat' index 0 title '' with lines linecolor 1,\
  'ApacheMon.dat' index 1 axis x1y2 title ' user' with linespoints linecolor 2 pointtype 6,\
  'ApacheMon.dat' index 2 axis x1y2 title ' sys' with linespoints linecolor 3 pointtype 8,\
  'ApacheMon.dat' index 3 axis x1y2 title ' idle' with linespoints linecolor 4 pointtype 2
