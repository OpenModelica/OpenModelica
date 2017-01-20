#!/bin/bash -x

WINE32=`which fmuCheck.win32.exe`
WINE64=`which fmuCheck.win64.exe`
DARWIN64=`which fmuCheck.darwin64`

if test ! -f "$WINE32"; then
 echo Did not find fmuCheck.win32.exe on the PATH "$PATH"
 exit 1
fi
if test ! -f "$WINE64"; then
  echo Did not find fmuCheck.win64.exe on the PATH "$PATH"
  exit 1
fi
if test ! -f "$DARWIN64"; then
  echo Did not find fmuCheck.darwin64 on the PATH "$PATH"
  exit 1
fi

"./$1" || exit 1

VERSION=`../../../build/bin/omc --version | grep -o "v[0-9]\+[.][0-9]\+[.][0-9]\+"`
echo "$VERSION"
for a in linux32 linux64 win32 win64 darwin64; do
for t in me cs; do
  if test "$t" = "me"; then
    d="ModelExchange"
  else
    d="CoSimulation"
  fi
  DIR="./Test_FMUs/FMI_2.0/$d/$a/OpenModelica/$VERSION/$1"
  mkdir -p "$DIR"
  case $a in
  linux32)
    CMD=fmuCheck.linux32
    ;;
  linux64)
    CMD=fmuCheck.linux64
    ;;
  win32)
    CMD="wine $WINE32"
    ;;
  win64)
    CMD="WINEARCH=win64 WINEPREFIX=~/.wine64 wine $WINE64"
    ;;
  darwin64)
    CMD="dyld64 $DARWIN64"
    ;;
  *)
    echo Unknown arch $a
    exit 1
    ;;
  esac
  CMD=`echo $CMD -c , -f -n 2000 -d -k $t -e "$DIR/$1_cc.log" -o "$DIR/$1_cc.csv" "$DIR/$1.fmu"`
  cp "$1.fmu" "$DIR/" || exit 1
  cp "$1_ref.opt" "$DIR/" || exit 1
  echo CMD > "$DIR/$1_cc.bat" || exit 1
  cp "$DIR/$1_cc.bat" "$DIR/$1_cc.sh" || exit 1
  bash -c "$CMD" || exit 1

  cp "$DIR/$1_cc.csv" "$1-$a-$t.csv" || exit 1
  cp "$1_res.csv" "$DIR/$1_ref.csv" || exit 1
  cp "ReadMe.txt" "$DIR/"
done
done
for a in c-code arm-linux-gnueabi; do
for t in me cs; do
  if test "$t" = "me"; then
    d="ModelExchange"
  else
    d="CoSimulation"
  fi
  DIR="./Test_FMUs/FMI_2.0/$d/$a/OpenModelica/$VERSION/$1"
  mkdir -p "$DIR"
  CMD=`echo fmuCheck.$a -c , -f -n 2000 -d -k $t -e "$DIR/$1_cc.log" -o "$DIR/$1_cc.csv" "$DIR/$1.fmu"`
  cp "$1.fmu" "$DIR/" || exit 1
  fmuCheck.linux64 -c , -f -n 2000 -d -k xml -e "$DIR/$1_cc.log" "$DIR/$1.fmu"
  cp "$1_ref.opt" "$DIR/" || exit 1
  cp "$1_res.csv" "$DIR/$1_ref.csv" || exit 1
  cp "$1_res.csv" "$DIR/$1_cc.csv" || exit 1
  cp "ReadMe.txt" "$DIR/" || exit 1
  echo "$CMD" > "$DIR/$1_cc.bat" || exit 1
done
done


# Need to find a working version of dyld32 to test this
#dyld32 $(DARWIN32) -f -n 2000 -d -k me -o darwin32-me.csv FmuExportCrossCompile.fmu
#dyld32 $(DARWIN32) -f -n 2000 -d -k cs -o darwin32-cs.csv FmuExportCrossCompile.fmu
