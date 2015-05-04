#!/bin/bash
# Creates statistic of all tearing methods in one file
start_model=1
end_model=18
path_to_stats=/home/ptaeuber/workspace/stats

echo -e "Tearing Results: (saved in $path_to_stats/tvarStat2.log)" | tee -a $path_to_stats/tvarStat2.log
date >> $path_to_stats/tvarStat2.log
omc ++v >> $path_to_stats/tvarStat2.log
echo >> $path_to_stats/tvarStat2.log
for i in `seq $start_model $end_model`
do
    echo Tearing$i.mo | tee -a $path_to_stats/tvarStat2.log
	echo omcTearing: >> $path_to_stats/tvarStat2.log
    omc Tearing$i-omc.mos | grep -A 1 "torn linear" >> $path_to_stats/tvarStat2.log
	echo cellier: >> $path_to_stats/tvarStat2.log
    omc Tearing$i-cel.mos | grep -A 1 "torn linear" >> $path_to_stats/tvarStat2.log
	echo -e "\n" >> $path_to_stats/tvarStat2.log
done