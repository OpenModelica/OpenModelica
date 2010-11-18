#!/bin/sh 
RESULT=`./translate-if-needed.sh`
if [ "${RESULT}" == "GOOD" ]
then 
    echo RML files are older than .mo, no translation needed!
    exit 0
else
cd ..
RML_FILES=`ls *.rml` 
#${OMDEV}/tools/mingw/bin/dos2unix.exe -q $RML_FILES
echo "Generating .rdb files for RML->MO translation..."
for file in $RML_FILES
do
  echo "Generating rdb for $file ..." 
  ${OMDEV}/tools/rml/bin/rml -frdb-only $file  
done
fi
