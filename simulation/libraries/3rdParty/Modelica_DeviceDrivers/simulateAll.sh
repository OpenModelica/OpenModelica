#!/bin/bash
OMC="${OPENMODELICAHOME}/bin/omc +locale=C +running-testsuite=dummy.out +d=hpcom +n=2"
#OMC="${OPENMODELICAHOME}/bin/omc +locale=C +running-testsuite=dummy.out"
echo $OMC
COUNTER=0
for f in *.mos; do
	echo $f
	$OMC $f > $f.txt 2>&1
	ERRORLEVEL=$?

	if [ $ERRORLEVEL -ne 0 ]; then
 		echo "- translation failed"
	else
 		if [ -f ${f}_res.mat ]; then
 			echo "- simulation failed"
 		else
 			echo "- OK"
 		fi
 	fi
	#COUNTER=$((COUNTER+1))
        #if [ $COUNTER -gt 5 ]; then
        #        break
        #fi
done

python sortResults.py > results.txt
