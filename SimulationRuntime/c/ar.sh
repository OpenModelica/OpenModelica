#!/bin/sh

ld -r -o "$@"
mv $1 $1.o
ar -ru $1 $1.o
rm $1.o
