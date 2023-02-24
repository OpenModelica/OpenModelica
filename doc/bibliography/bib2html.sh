#!/bin/sh
# Inputs:
# $1: basename of the cite-file
# $2: basename of the bib-file
# $3: target encoding
# $4: path to where the files are stored (relative on the server)
rm -f $1.md
cp $1.title $1.md
for year in `grep -o '[0-9][0-9][0-9][0-9]' $1.cite | sort -ru`; do
  grep $year $1.cite > $1.cite.$year
  bibtex2html -r -d --note supervisor --note examiner -charset utf8 -citefile $1.cite.$year -nf pdf pdf -nodoc -noheader -nofooter $2.bib || exit 1
  iconv -f utf8 -t $3 $2.html > $1.md.tmp || exit 1
  sed -i "s,href=\"$2_bib.html,href=\"$4$2_bib," $1.md.tmp || exit 1
  echo "<h3>$year</h3>" >> $1.md
  cat $1.md.tmp >> $1.md
  rm $1.cite.$year
done

cp $1.md $1.html
