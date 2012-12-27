#!/bin/sh
TMPNAME=/tmp/openmodelica.org-bibgen
rm -rf $TMPNAME
mkdir -p $TMPNAME
sh generate.sh $TMPNAME || exit 1
for f in $TMPNAME/*; do
  echo "" >> $f
  echo "<!-- This code was automatically generated from the OpenModelica trunk --!>" >> $f
done
scp $TMPNAME/* openmodelica.org:/var/www/joomla/bibliography
