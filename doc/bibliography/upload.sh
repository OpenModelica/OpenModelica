#!/bin/sh
TMPNAME=/tmp/openmodelica.org-bibgen
rm -rf $TMPNAME
mkdir -p $TMPNAME
sh generate.sh $TMPNAME || exit 1
for f in $TMPNAME/*; do
  echo "<!-- This code was automatically generated from the repository at https://github.com/OpenModelica/OpenModelica-doc/ --!>" > $f.tmp
  echo "" >> $f.tmp
  cat $f >> $f.tmp
  echo "" >> $f.tmp
  echo "<!-- This code was automatically generated from the repository at https://github.com/OpenModelica/OpenModelica-doc/ --!>" >> $f.tmp
  mv $f.tmp $f
done
scp $TMPNAME/* openmodelica.org:/var/www/joomla/bibliography
