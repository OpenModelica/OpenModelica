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
  RML=$1
  FNAME=$2
  if [ ! "$#" -eq 2 ]; then
    echo "Usage: $0 /path/to/rml <file>.mo)";
    exit;
  fi
else
  RML=${OMDEV}/tools/rml/bin/rml
  FNAME=$1
  if [ ! "$#" -eq 1 ]; then
    echo "Usage: $0 <file>.mo)";
    exit;
  fi
fi

tmp_file="$FNAME.$$"
sig_file="`basename "$FNAME" ".mo"`.sig"

if [ ! -f $sig_file ]; then
  TMPMSG="Sig file: $sig_file does not exist...";
  ${RML} -fdump-interface $FNAME > $sig_file;
else 
  #echo "Generates tmp sig."
  ${RML} -fdump-interface $FNAME > $tmp_file
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
