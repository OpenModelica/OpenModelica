#!/bin/bash -e
# Script to generate detailed test reports in a given directory, with history in another

if test ! "$#" = 7 -a ! "$#" = 6; then
  echo "Usage: $0 omhome workdir libraries_dir libdirname library_name library_version [path/to/referenceFiles]"
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

TESTMODELS="$OMHOME/share/doc/omc/testmodels/"
HISTORY="$WWW/history"

"$OMHOME/bin/omc" ++v

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR" "$WWW/$LIB_DIR" "$HISTORY"
cd "$WORKDIR"

sed "s/^libraryVersion:=\"default\";/libraryVersion:=\"$LIB_VERSION\";/" "$TESTMODELS/BuildModelRecursive.mos" | sed "s/library:=.*/library:=\$TypeName($LIB_NAME);/" | sed "s,referenceFiles:=.*,referenceFiles:=\"$REF_FILES\";," > BuildModelRecursive.mos
"$OMHOME/bin/omc" +g=MetaModelica BuildModelRecursive.mos

shopt -s nullglob
cp BuildModelRecursive.tar.gz "$WWW/$LIB_DIR/"
rm -rf "$WWW/$LIB_DIR/files"
tar -C "$WWW/$LIB_DIR/" -xzf BuildModelRecursive.tar.gz
cp BuildModelRecursive.html "$HISTORY"/`date +${LIB_DIR}-%Y-%m-%d.html`
bash -e "$TESTMODELS/PlotLibraryTrend.sh" "$HISTORY" "$LIB_NAME"
