#!/bin/sh
#
# rmldep: Generates a new signature if the old is different.
# BEDNARSKI Andrzej
# Last update: 11 June, 2003
# Changed by Adrian Pop, adrpo@ida.liu.se, 2006-02-02
#

TMPSTART=`date +"%s"`
TMPMSG=""
mydir="`dirname $0`"

if [ -z "${OMDEV}" ]; then
  RML=rml
else
  RML=${OMDEV}/tools/rml/bin/rml
fi

if [ ! "$#" -eq 1 ]; then
  echo "Usage: $0 <file>.mo)";
  exit;
fi

tmp_file="$1.$$"
sig_file="`basename "$1" ".mo"`.sig"

if [ ! -f $sig_file ]; then
  TMPMSG="Sig file: $sig_file does not exist...";
  ${RML} -fdump-interface $1 > $sig_file;
else 
  #echo "Generates tmp sig."
  ${RML} -fdump-interface $1 > $tmp_file
  #echo "Diffing"
  diff $tmp_file $sig_file > /dev/null
  if [ $? -eq 0 ]; then
    TMPMSG="Interface is the same"
    rm $tmp_file
  else
    TMPMSG="Interface has changed"
    \mv $tmp_file $sig_file
  fi
fi
TMPEND=`date +"%s"`
echo [`expr $TMPEND - $TMPSTART` second\(s\) \-\> $TMPMSG] 
