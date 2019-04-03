#!/bin/bash
# Creates statistic of given .mos-files in shell
for model in "$@"
do
    echo $model
    omc $model | grep -C 1 "torn linear"
	echo -e "\n"
done