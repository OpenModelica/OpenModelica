#!/bin/sh
# Inputs:
# $1: basename of the cite-file 
# $2: basename of the bib-file
# $3: target encoding
# $4: path to where the files are stored (relative on the server) 
bibtex2html -r -d --note supervisor --note examiner -charset utf8 -citefile $1.cite -nf pdf pdf -nodoc -noheader -nofooter $2.bib || exit 1
iconv -f utf8 -t $3 $2.html > $1.bibinc || exit 1
sed -i "s/href=\"$2/href=\"$4$2/" $1.bibinc || exit 1
