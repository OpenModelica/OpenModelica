#!/bin/bash -e
# script to generate trend.html with library coverage: https://test.openmodelica.org/libraries/trend.html
# $1 path to where the libraries coverages is, /var/www/libraries
# $2 the generated file name (trend.html)
# $3 the detailed generated file name (trend-detailed.html)

WWW=$1
TREND_FILE=$2
TREND_FILE_DETAILED=$3

cd "$WWW"
OUT=a.html
SDATE=`date +"%Y-%m-%d %R week %V"`
echo "<html><head><title>OpenModelica - Library Coverage Trend Overview</title><body>" > $OUT
echo "<center>" >> $OUT
echo "<h2>OpenModelica Library Coverage Overview ran each night by <a href="/hudson/view/Library%20Testing/">Hudson</a></h2><br/><b>$SDATE</b>" >> $OUT
echo "<hr />" >> $OUT
for f in history/*/*-trend.svg; do
  # Filter out entries <10 days old. New entries will appear the day after this run!
  if test `find "$f" \( ! -mmin +14400 \)`; then
    IMG=$f
    HTML=`echo $IMG | sed -e 's,^history/\(.*\)/.*-trend.svg,\1/BuildModelRecursive.html,'`
    NAME=`echo $IMG | sed -e 's,^history/\(.*\)/.*-trend.svg,\1,'`
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
SDATE=`date +"%Y-%m-%d %R week %V"`
echo "<html><head><title>OpenModelica - Detailed Library Coverage Trend Overview</title><body>" > $OUT
echo "<center>" >> $OUT
echo "<h2>OpenModelica Detailed Library Coverage Overview ran each night by <a href="/hudson/view/Library%20Testing/">Hudson</a></h2><br/><b>$SDATE</b>" >> $OUT
echo "<hr />" >> $OUT
for f in history/*/*-trend-detailed.svg; do
  # Filter out entries <10 days old. New entries will appear the day after this run!
  if test `find "$f" \( ! -mmin +14400 \)`; then
    IMG=$f
    HTML=`echo $IMG | sed -e 's,^history/\(.*\)/.*-trend-detailed.svg,\1/BuildModelRecursive.html,'`
    NAME=`echo $IMG | sed -e 's,^history/\(.*\)/.*-trend-detailed.svg,\1,'`
    echo "<h3>$NAME<h3>" >> $OUT
    echo "<p><a href=\"$HTML\"><img src=\"$IMG\" width="80%" /></a></p>" >> $OUT
    echo "<hr />" >> $OUT
  fi
done
echo "<p>Please contact the <a href="https://www.openmodelica.org/">OpenModelica Team</a> if you have any questions." >> $OUT
echo "</center>" >> $OUT
echo "</body></html>" >> $OUT
mv $OUT $TREND_FILE_DETAILED
