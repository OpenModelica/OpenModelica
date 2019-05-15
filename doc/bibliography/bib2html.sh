#!/bin/sh
# Inputs:
# $1: basename of the cite-file
# $2: basename of the bib-file
# $3: target encoding
# $4: path to where the files are stored (relative on the server)
rm -f $1.bibinc
for year in `grep -o '[0-9][0-9][0-9][0-9]' $1.cite | sort -ru`; do
  grep $year $1.cite > $1.cite.$year
  bibtex2html -r -d --note supervisor --note examiner -charset utf8 -citefile $1.cite.$year -nf pdf pdf -nodoc -noheader -nofooter $2.bib || exit 1
  iconv -f utf8 -t $3 $2.html > $1.bibinc.tmp || exit 1
  sed -i "s/href=\"$2/href=\"$4$2/" $1.bibinc.tmp || exit 1
  echo "<h3>$year</h3>" >> $1.bibinc
  cat $1.bibinc.tmp >> $1.bibinc
  rm $1.cite.$year
done

cp $1.bibinc $1.html
