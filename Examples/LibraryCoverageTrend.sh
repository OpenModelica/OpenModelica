#!/bin/bash -e
# script to generate trend.html with library coverage: https://test.openmodelica.org/libraries/trend.html
# $1 path to CountClassUses.py, /var/lib/hudson/jobs/OpenModelica_TEST_ALL_LIBRARIES/workspace/OpenModelica/Examples/CountClassUses.py
# $2 path to where the libraries coverages is, /var/www/libraries
# $3 the generated file name (trend.html)
# $4 the detailed generated file name (trend-detailed.html)

PY=$1
WWW=$2
TREND_FILE=$3
TREND_FILE_DETAILED=$4

cd "$WWW"
OUT=a.html
SDATE=`date +"%Y-%m-%d %R week %U"`
echo "<html><head><title>OpenModelica - Library Coverage Trend Overview</title><body>" > $OUT
echo "<center>" >> $OUT
echo "<h2>OpenModelica Library Coverage Overview ran each night by <a href="/hudson/view/Library%20Testing/">Hudson</a></h2><br/><b>$SDATE</b>" >> $OUT
echo "<hr />" >> $OUT
for f in history/*-trend.svg; do
  # Filter out entries <10 days old. New entries will appear the day after this run!
  if test `find "$f" \( ! -mmin +14400 \)`; then
    IMG=$f
    HTML=`echo $IMG | sed -e 's,^history/\(.*\)-trend.svg,\1/BuildModelRecursive.html,'`
    NAME=`echo $IMG | sed -e 's,^history/\(.*\)-trend.svg,\1,'`
    echo "<h3>$NAME<h3>" >> $OUT
    echo "<p><a href=\"$HTML\"><img src=\"$IMG\" width="80%" /></a></p>" >> $OUT
    echo "<hr />" >> $OUT
  fi
done
echo "<p>Please contact the <a href="https://www.openmodelica.org/">OpenModelica Team</a> if you have any questions." >> $OUT
echo "</center>" >> $OUT
echo "</body></html>" >> $OUT
mv $OUT $TREND_FILE

cd "$WWW"
OUT=b.html
SDATE=`date +"%Y-%m-%d %R week %U"`
echo "<html><head><title>OpenModelica - Detailed Library Coverage Trend Overview</title><body>" > $OUT
echo "<center>" >> $OUT
echo "<h2>OpenModelica Detailed Library Coverage Overview ran each night by <a href="/hudson/view/Library%20Testing/">Hudson</a></h2><br/><b>$SDATE</b>" >> $OUT
echo "<hr />" >> $OUT
for f in history/*-trend-detailed.svg; do
  # Filter out entries <10 days old. New entries will appear the day after this run!
  if test `find "$f" \( ! -mmin +14400 \)`; then
    IMG=$f
    HTML=`echo $IMG | sed -e 's,^history/\(.*\)-trend-detailed.svg,\1/BuildModelRecursive.html,'`
    NAME=`echo $IMG | sed -e 's,^history/\(.*\)-trend-detailed.svg,\1,'`
    echo "<h3>$NAME<h3>" >> $OUT
    echo "<p><a href=\"$HTML\"><img src=\"$IMG\" width="80%" /></a></p>" >> $OUT
    echo "<hr />" >> $OUT
  fi
done
echo "<p>Please contact the <a href="https://www.openmodelica.org/">OpenModelica Team</a> if you have any questions." >> $OUT
echo "</center>" >> $OUT
echo "</body></html>" >> $OUT
mv $OUT $TREND_FILE_DETAILED

(cd "$WWW" && "$PY" MSL_3.2.1 ModelicaTest_3.2.1 > "$WWW/MSL_3.2.1/Coverage.txt")
(cd "$WWW" && "$PY" MSL_trunk ModelicaTest_trunk > "$WWW/MSL_trunk/Coverage.txt")
for lib in ModelicaTest_3.2.1 ModelicaTest_trunk Annex60 BioChem Buildings OpenHydraulics Physiolibrary PlanarMechanics PowerSystems SiemensPower SystemDynamics ThermoPower ThermoSysPro; do
  (cd "$WWW" && "$PY" $lib > "$WWW/$lib/Coverage.txt")
done