#!/bin/bash -e
# Script to generate detailed test reports in a given directory, with history in another

if ! test "$#" = 6 -o "$#" = 7 -o "$#" = 8 -o "$#" = 9; then
  echo "Usage: $0 omhome workdir libraries_dir libdirname library_name library_version [path/to/referenceFiles] [mat] [.]"
  echo "Example: $0 /path/to/build/ OpenModelica/BuildModelTest/MSL_3.2.1 /var/www/libraries/ MSL_3.2.1 Modelica 3.2.1 /path/to/trunk/testsuite/simulation/libraries/msl32/ReferenceFiles"
  exit 1
fi

OMHOME="$1"
WORKDIR="$2"
WWW="$3"
LIB_DIR="$4"
LIB_NAME="$5"
LIB_VERSION="$6"
REF_FILES="$7"
if test -z "$8"; then
  REF_EXT="mat"
else
  REF_EXT="$8"
fi
if test -z "$9"; then
  REF_NAME_DELIMITER="."
else
  REF_NAME_DELIMITER="$9"
fi
TESTMODELS="$OMHOME/share/doc/omc/testmodels/"
HISTORY="$WWW/history/$LIB_DIR"

"$OMHOME/bin/omc" +version

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR" "$WWW/$LIB_DIR" "$HISTORY"
test ! -f "$LIB_DIR.mos" || cp "$LIB_DIR.mos" "$WORKDIR/CustomCommands.mos"
cd "$WORKDIR"

sed "s/^libraryVersion:=\"default\";/libraryVersion:=\"$LIB_VERSION\";/" "$TESTMODELS/BuildModelRecursive.mos" | \
sed "s/library:=.*/library:=\$TypeName($LIB_NAME);/" | \
sed "s,referenceFiles:=.*,referenceFiles:=\"$REF_FILES\";," | \
sed "s,referenceFileExtension:=.*,referenceFileExtension:=\"$REF_EXT\";," | \
sed "s,referenceFileNameDelimiter:=.*,referenceFileNameDelimiter:=\"$REF_NAME_DELIMITER\";," \
> BuildModelRecursive.mos
"$OMHOME/bin/omc" +g=MetaModelica BuildModelRecursive.mos

shopt -s nullglob
cp BuildModelRecursive.tar.gz "$WWW/$LIB_DIR/"
rm -rf "$WWW/$LIB_DIR/files"
tar -C "$WWW/$LIB_DIR/" -xzf BuildModelRecursive.tar.gz
cp BuildModelRecursive.html "$HISTORY"/`date +${LIB_DIR}-%Y-%m-%d.html`
bash -e "$TESTMODELS/PlotLibraryTrend.sh" "$HISTORY" "$LIB_DIR"
