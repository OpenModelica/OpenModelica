#!/bin/sh
cd ..
RMLFILES=`ls *.rml` 
MOFILES=`ls *.mo`
if [ "$MOFILES" == "" ]
then 
    cd ./rml2mmo
    echo REDO
    exit 0
fi
for rml_file in $RMLFILES
do
    for mo_file in $MOFILES
    do
	#echo Testing if $rml_file is newer than $mo_file
	if [ "$rml_file" -nt "$mo_file" ]
	then 
	    cd ./rml2mmo
	    echo REDO
	    exit 0
	fi
    done
done
cd ./rml2mmo
echo GOOD
exit 0