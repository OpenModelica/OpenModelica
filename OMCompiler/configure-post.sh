#!/bin/sh
# Input is the configure command, e.g. '--with-omniORB'
CMD=`echo $@ | tr -d \" | tr -d \' | sed s/\\\\//\\\\\\\\\\\\//g`
sed -i.bak "s/@CONFIGURE_ARGS@/$CMD/" Compiler/runtime/config.unix.h && rm -f Compiler/runtime/config.unix.h.bak
