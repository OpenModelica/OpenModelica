#!/bin/bash
my_dir="`cd $0; pwd`"
path_to_stats=/home/ptaeuber/workspace/stats
path_to_msl=/home/ptaeuber/workspace/trunk/testsuite/simulation/libraries/msl32

echo -e "Tearing Statistic - MSL: (saved in $path_to_stats/tvarStat_msl.log)" | tee -a $path_to_stats/tvarStat_msl.log
date >> $path_to_stats/tvarStat_msl.log
omc ++v >> $path_to_stats/tvarStat_msl.log
echo >> $path_to_stats/tvarStat_msl.log
cd $path_to_msl

while read line
 do
   echo $line | tee -a $path_to_stats/tvarStat_msl.log
   echo omcTearing: >> $path_to_stats/tvarStat_msl.log
   omc $line +tearingMethod=omcTearing +d=backenddaeinfo | grep 'torn\|time' >> $path_to_stats/tvarStat_msl.log
   echo cellier: >> $path_to_stats/tvarStat_msl.log
   omc $line +tearingMethod=cellier2 +d=backenddaeinfo | grep 'torn\|time' >> $path_to_stats/tvarStat_msl.log
   echo $'\n' >> $path_to_stats/tvarStat_msl.log
done < $my_dir/msl32-models.txt
cd $my_dir
