#!/bin/bash

DIR=/tmp/make-package-sh-$$/

sh createbuilders.sh win32
make -C latex
cp ../../../../Compiler/Template/Tpl.mo ../10_pamtrans/ || exit 1

mkdir -p "$DIR"

svn export .. "$DIR/MetaModelica"
(cd ../documentation/; for f in *.ppt *.odp *.url; do
  echo "$f"
  rm "$DIR/MetaModelica/documentation/$f"
  cp "../documentation/`echo $f | sed 's/ppt$/pdf/'`" "$DIR/MetaModelica/documentation/" || exit 1
done)
# cp ../../../../doc/OpenModelicaMetaProgramming.pdf "$DIR/MetaModelica/documentation/" || exit 1
wget "http://liu.diva-portal.org/smash/get/diva2:403940/FULLTEXT01" -O \
  "$DIR/MetaModelica/documentation/MetaModelica1.0.pdf" || exit 1
wget "http://liu.diva-portal.org/smash/get/diva2:418188/FULLTEXT01" -O \
  "$DIR/MetaModelica/documentation/MetaModelica2.0.pdf" || exit 1
TXT="Only some features of MM 2.0 are in OpenModelica.txt"
cp latex/main.pdf "$DIR/MetaModelica/documentation/CourseExercises_ExcerptFromBook.pdfs"
echo "$TXT" > "$DIR/MetaModelica/documentation/$TXT"

find "$DIR" -name SOLUTION*.mo* -delete

FILE=MetaModelicaDevelopersCourse-`date +%Y-%m-%d`.tar.gz
(cd "$DIR"; tar czf "$FILE" ./MetaModelica)
cp "$DIR/$FILE" ./

rm -rf "$DIR"
echo Success! Created "$FILE"
