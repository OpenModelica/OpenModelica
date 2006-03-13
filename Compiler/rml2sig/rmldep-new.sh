#!/bin/sh
#
# rmldep: Generates a new signature if the old is different.
# BEDNARSKI Andrzej
# Last update: 11 June, 2003
# Changed by Adrian Pop, adrpo@ida.liu.se, 2006-02-02
#

date
mydir="`dirname $0`"

if [ ! "$#" -eq 1 ]; then
  echo "Usage: $0 <file>.(mo|rml)";
  exit;
fi

tmp_file="$1.$$"
if [ "mo" = "${OMC_BUILD_FROM}" ]; then
 sig_file="`basename "$1" ".mo"`.sig"
else
 sig_file="`basename "$1" ".rml"`.sig"
fi

if [ ! -f $sig_file ]; then
  echo "Sig file does not exist...";
  rml -fdump-interface $1 > $sig_file;
else 
  echo "Generates tmp sig."
  rml -fdump-interface $1 > $tmp_file
  echo "Diffing"
  diff $tmp_file $sig_file > /dev/null
  if [ $? -eq 0 ]; then
    echo "Interface is the same"
    rm $tmp_file
  else
    echo "Interface has changed"
    \mv $tmp_file $sig_file
  fi
fi
date
