#!/bin/sh -x

ld -r -o "$@" || exit 1
mv $1 $1.o || exit 1
ar -ru $1 $1.o || exit 1
rm $1.o || exit 1
