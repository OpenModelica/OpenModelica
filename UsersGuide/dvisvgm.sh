#!/bin/bash

OUTF=`echo $2 | sed 's/[.]png/.svg/'`
exec dvisvgm "$1" "$OUTF" -n "${12}"
