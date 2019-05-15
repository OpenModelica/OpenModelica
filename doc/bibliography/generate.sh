#!/bin/sh
rm -f *.bibinc *.html ../*.bibinc ../marsj_bib.html
test -z "$1" && echo "You need to specify output directory (e.g. /media/ida-home/www-pub/ )" && exit

for type in papers msc journals phd; do
  ./bib2html.sh $type openmodelica utf8 bibliography\\/ || exit 1
done

bibtex2html -a -charset utf8 openmodelica.bib || exit 1

mv *.bibinc openmodelica_bib.html openmodelica.html $1
