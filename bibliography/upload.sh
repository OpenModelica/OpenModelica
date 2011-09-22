#!/bin/sh
TMPNAME=/tmp/openmodelica.org-bibgen
rm -rf $TMPNAME
mkdir -p $TMPNAME
sh generate.sh $TMPNAME
scp $TMPNAME/* openmodelica.org:/var/www/bibliography
