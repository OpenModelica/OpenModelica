#!/bin/sh -x
rm -f *.md *.html
test -z "$1" && echo "You need to specify output directory (e.g. /media/ida-home/www-pub/ )" && exit

for type in conference-papers master-theses journal-papers phd-and-licentiate-theses; do
  ./bib2html.sh $type openmodelica utf8 /research/ || exit 1
done

bibtex2html -a -nodoc -noheader -nofooter -charset utf8 openmodelica.bib || exit 1

sed -i "s,href=\"openmodelica_bib.html,href=\"/research/openmodelica_bib," openmodelica.html
sed -i -e "s,href=\"openmodelica.html,href=\"/research/openmodelica," -e "s,<h1>.*</h1>,," openmodelica_bib.html

cat openmodelica_bib.title openmodelica_bib.html > openmodelica_bib.md
cat openmodelica.title openmodelica.html > openmodelica.md
rm openmodelica.html openmodelica_bib.html
mv *.md $1
