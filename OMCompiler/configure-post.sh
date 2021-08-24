#!/bin/sh
# Input is the configure command, e.g. '--with-omniORB'
CMD=`echo $@ | tr -d \" | tr -d \' | sed s/\\\\//\\\\\\\\\\\\//g`
sed -i.bak "s/@CONFIGURE_ARGS@/$CMD/" omc_config.unix.h && rm -f omc_config.unix.h.bak
