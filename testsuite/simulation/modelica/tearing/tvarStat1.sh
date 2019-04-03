#!/bin/bash
# Creates statistic of all tearing methods in seperated files
start_model=1
end_model=18
path_to_stats=/home/ptaeuber/workspace/stats

if [ $# -eq 1 ]
 then
  case "$1" in
        omcTearing) 
		echo -e "omcTearing Results: (saved in $path_to_stats/tvarStat1_omc.log)" | tee -a $path_to_stats/tvarStat1_omc.log
        date >> $path_to_stats/tvarStat1_omc.log
        omc ++v >> $path_to_stats/tvarStat1_omc.log
        echo >> $path_to_stats/tvarStat1_omc.log
        for i in `seq $start_model $end_model`
        do
            echo Tearing$i-omc.mos | tee -a $path_to_stats/tvarStat1_omc.log
            omc Tearing$i-omc.mos | grep -A 1 "torn linear" >> $path_to_stats/tvarStat1_omc.log
        	echo $'\n' >> $path_to_stats/tvarStat1_omc.log
        done
            ;;
        cellier)
		echo -e "Cellier Results: (saved in $path_to_stats/tvarStat1_cel.log)" | tee -a $path_to_stats/tvarStat1_cel.log
        date >> $path_to_stats/tvarStat1_cel.log
        omc ++v >> $path_to_stats/tvarStat1_cel.log
        echo >> $path_to_stats/tvarStat1_cel.log
        for i in `seq $start_model $end_model`
        do
            echo Tearing$i-cel.mos | tee -a $path_to_stats/tvarStat1_cel.log
            omc Tearing$i-cel.mos | grep -A 1 "torn linear" >> $path_to_stats/tvarStat1_cel.log
        	echo $'\n' >> $path_to_stats/tvarStat1_cel.log
        done
            ;;
        *) 
		echo "Error! Wrong argument. Allowed arguments: omcTearing, cellier" 
            ;;
  esac
elif [ $# -eq 0 ]
 then
   echo -e "omcTearing Results: (saved in $path_to_stats/tvarStat1_omc.log)" | tee -a $path_to_stats/tvarStat1_omc.log
   date >> $path_to_stats/tvarStat1_omc.log
   omc ++v >> $path_to_stats/tvarStat1_omc.log
   echo >> $path_to_stats/tvarStat1_omc.log
   for i in `seq $start_model $end_model`
   do
       echo Tearing$i-omc.mos | tee -a $path_to_stats/tvarStat1_omc.log
       omc Tearing$i-omc.mos | grep -A 1 "torn linear" >> $path_to_stats/tvarStat1_omc.log
   	   echo $'\n' >> $path_to_stats/tvarStat1_omc.log
   done
   
   echo $'\n'
   echo -e "Cellier Results: (saved in $path_to_stats/tvarStat1_cel.log)" | tee -a $path_to_stats/tvarStat1_cel.log
   date >> $path_to_stats/tvarStat1_cel.log
   omc ++v >> $path_to_stats/tvarStat1_cel.log
   echo >> $path_to_stats/tvarStat1_cel.log
   for i in `seq $start_model $end_model`
   do
       echo Tearing$i-cel.mos | tee -a $path_to_stats/tvarStat1_cel.log
       omc Tearing$i-cel.mos | grep -A 1 "torn linear" >> $path_to_stats/tvarStat1_cel.log
   	   echo $'\n' >> $path_to_stats/tvarStat1_cel.log
   done
   echo $'\n'
else
  echo Error! Wrong number of arguments. Pass either one argument for special method or no argument for all methods.
fi
