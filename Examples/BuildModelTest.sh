#!/bin/bash

if test "$1" = "--plot-only"; then
  PLOTONLY="Yes"
  shift
fi
PUB="$1"
TRUNK="$2"
OMC=$TRUNK/build/bin/omc
shift;shift
if test ! -d "$PUB" -o ! -f "$OMC"; then
  echo "Usage: $0 [--plot-only] output/dir trunk/dir [SHORTNAME,NAME,VERSION]"
  exit 1
fi
OLD="$PUB/MSL_old"
mkdir -p "$OLD"

# Build the mos-files
if test -z "$PLOTONLY"; then
for lib in "$@"; do
SHORTNAME=`echo $lib | cut -d, -f1`
NAME=`echo $lib | cut -d, -f2`
VERSION=`echo $lib | cut -d, -f3`
if test -z "$VERSION"; then
  VERSION="default"
fi
mkdir -p "$PUB/$SHORTNAME"

sed "s/^libraryVersion:=\"default\";/libraryVersion:=\"$VERSION\";/" "$TRUNK/Examples/BuildModelRecursive.mos" | sed "s/library:=.*/library:=\$TypeName($NAME);/" > "$SHORTNAME.mos"

rm -f *.err BuildModelRecursive.html
if $OMC -g=MetaModelica "$SHORTNAME.mos" > log 2>&1; then
  rm -f "$PUB/$SHORTNAME/"*.err "$PUB/$SHORTNAME/"*.sim
  if ! cp BuildModelRecursive.html "$OLD/$SHORTNAME-`date +%Y-%m-%d`.html"; then
    echo "Failed to install $OLD/$SHORTNAME-`date +%Y-%m-%d`.html"
    exit 1
  fi
  for f in *.err *.sim BuildModelRecursive.html; do test -f "$f" && mv "$f" "$PUB/$SHORTNAME/"; done
else
  cat log
  echo "Subject: BuildModelTest $NAME $VERSION Failed"
  exit 1
fi
done
fi # --plot-only

for lib in "$@"; do
SECTION=`echo $lib | cut -d, -f1`
echo "$SECTION"
FIRST_DATE=`grep -H "Simulation Results:" "$OLD/${SECTION}"*.html | head -n1 | cut -d: -f1 | grep -o "20[0-9-]*"`
LAST_DATE=`grep -H "Simulation Results:" "$OLD/${SECTION}"*.html | tail -n1 | cut -d: -f1 | grep -o "20[0-9-]*"`
if test "$FIRST_DATE" = "$LAST_DATE"; then
  FIRST_DATE="1970-01-01"
fi
GOAL=`grep -H "Simulation Results:" "$OLD/${SECTION}"*.html | tail -n1 | grep -o "[0-9][0-9]*/[0-9][0-9]*" | sed s,.*/,,`
CURS=`grep -H "Simulation Results:" "$OLD/${SECTION}"*.html | tail -n1 | grep -o "[0-9][0-9]*/[0-9][0-9]*" | sed s,/.*,,`
CURC=`grep -H "BuildModel Results:" "$OLD/${SECTION}"*.html | tail -n1 | grep -o "[0-9][0-9]*/[0-9][0-9]*" | sed s,/.*,,`
cat > $PUB/MSL_old/${SECTION}-trend.gnuplot <<EOF
set term svg
set datafile separator ","
set xlabel "Date $FIRST_DATE - $LAST_DATE"
set ylabel "Models"
set xdata time
set timefmt "%Y-%m-%d"
#set xrange ["2012-10-17":"2012-11-22"]
set format x "%m-%d"
set xrange ["$FIRST_DATE":"$LAST_DATE"]
# set yrange [0:$(( (($GOAL+9)/10)*10 ))]
set yrange [0:]
# set ytics 10
# set xtics rotate by -13 font "Helvetica,8"
set title '$SECTION Coverage'
set output "${SECTION}-trend.svg"
goal(x) = $GOAL
currentC(x) = $CURC
currentS(x) = $CURS
set key right bottom Left title 'Legend'
set style line 1 linecolor rgb "red"   pt 1 ps 1
set style line 2 linecolor rgb "green" pt 1 ps 1
set style line 3 linecolor rgb "blue"  pt 1 ps 1
plot "${SECTION}-trend.csv" using 1:2 title 'Target: $GOAL'   with lines ls 1, \
     "${SECTION}-trend.csv" using 1:3 title 'Compile: $CURC'  with lines ls 2, \
     "${SECTION}-trend.csv" using 1:4 title 'Simulate: $CURS' with lines ls 3
EOF
rm -f $OLD/${SECTION}-trend.csv
for f in `grep -H "Simulation Results:" "$OLD/${SECTION}"*.html | cut -d: -f1` ; do
  DATE=`echo "$f" | grep -o "20[0-9-]*"`
  BUILD=`grep "BuildModel Results:" "$f" | cut -d: -f2 | cut -d/ -f1 | tr -d \ `
  SIM=`grep "Simulation Results:" "$f" | cut -d: -f2`
  SIMSUC=`echo "$SIM" | cut -d/ -f1`
  TOT=`echo "$SIM" | cut -d/ -f2 | cut -d" " -f1`
  REV=`grep -o "[(]r[0-9]*" "$f" | tr -d "("`
  #`cut -d / -f1 $f`
  echo "$DATE,$TOT,$BUILD,$SIMSUC" >> "$OLD/${SECTION}-trend.csv"
  echo -n "$DATE $REV"
  echo -n " - total $TOT"
  if test "$TOT" = "0"; then
    echo echo -n " - build $BUILD" "(0%)";
    echo " - sim $SIMSUC" "(0%)"
  else
    echo -n " - build $BUILD" "($((100 * $BUILD / $TOT))%)"
    echo " - sim $SIMSUC" "($((100 * $SIMSUC / $TOT))%)"
  fi
done
(cd $OLD; gnuplot ${SECTION}-trend.gnuplot)
CUR=`ls "$OLD/${SECTION}"*.html | tail -n1`
YDAY=`ls "$OLD/${SECTION}"*.html | tail -n2 | head -n1`
WEEK=`ls "$OLD/${SECTION}"*.html | tail -n7 | head -n1`
MONTH=`ls "$OLD/${SECTION}"*.html | tail -n28 | head -n1`
"$TRUNK"/Examples/BuildModelRecursiveDiff.sh "$YDAY" "$CUR" > "$PUB/MSL_old/${SECTION}-diff-yday.txt"
"$TRUNK"/Examples/BuildModelRecursiveDiff.sh "$WEEK" "$CUR" > "$PUB/MSL_old/${SECTION}-diff-week.txt"
"$TRUNK"/Examples/BuildModelRecursiveDiff.sh "$MONTH" "$CUR" > "$PUB/MSL_old/${SECTION}-diff-month.txt"
done > "$PUB/MSL_old/history.txt"

(echo "<html><head><title>Coverage trend overview</title><body>";
for lib in "$@"; do
  SHORTNAME=`echo $lib | cut -d, -f1`
  rsvg-convert --format=png -o "$OLD/$SHORTNAME-trend.png" "$OLD/$SHORTNAME-trend.svg"
  echo "<p><a href="$SHORTNAME/BuildModelRecursive.html"><img src=\"MSL_old/$SHORTNAME-trend.svg\" /></a></p>"
done;
echo "</body></html>") > "$PUB/trend.html"
