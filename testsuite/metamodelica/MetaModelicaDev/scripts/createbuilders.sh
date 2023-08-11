#!/bin/bash

case $1 in
  "windows" ) BUILDER=tool.launch.in.win32 ;;
  "win32" ) BUILDER=tool.launch.in.win32 ;;
  "win" ) BUILDER=tool.launch.in.win32 ;;
  "omdev" ) BUILDER=tool.launch.in.win32 ;;
  "osx" )     BUILDER=tool.launch.in.osx ;;
  "linux" )   BUILDER=tool.launch.in.linux ;;
  * ) echo "Usage: $0 omdev|windows|osx|linux"; exit 1 ;;
esac

MMDIRS="01_experiment 02a_exp1 02b_exp2 03_symbolicderivative 04_assignment 05a_assigntwotype 05b_modassigntwotype 06_advanced 08_pam 09_pamdecl 10_pamtrans 11_petrol"

for DIR in $MMDIRS; do
  sed s/%NAME%/$DIR/ project.in > ../$DIR/.project
  sed s/%TARGET%/Makefile/ $BUILDER | sed s/%ENABLED%/true/ > ../$DIR/.externalToolBuilders/OMC.launch
  # sed s/%TARGET%/Makefile.rml/ $BUILDER | sed s/%ENABLED%/false/ > ../$DIR/.externalToolBuilders/RML.launch
done

