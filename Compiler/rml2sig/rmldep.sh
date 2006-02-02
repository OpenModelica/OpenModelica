#!/bin/sh
#
# rmldep: Generates a new signature if the old is different.
# BEDNARSKI Andrzej
# Last update: 11 June, 2003
#

mydir="`dirname $0`"

if [ ! "$#" -eq 1 ]; then
  echo "Usage: $0 <file>.rml";
  exit;
fi

tmp_file="$1.$$"
sig_file="`basename "$1" ".rml"`.sig"

if [ ! -f $sig_file ]; then
   # echo "Sig file does not exist...";
  $mydir/rml2sig $1 > $sig_file;
else 
  # echo "Generates tmp sig."
  $mydir/rml2sig $1 > $tmp_file
  # echo "Diffing"
  diff $tmp_file $sig_file > /dev/null
  if [ $? -eq 0 ]; then
    # echo "Same files"
    rm $tmp_file
  else
    # echo "Interface changed"
    \mv $tmp_file $sig_file
  fi
fi

