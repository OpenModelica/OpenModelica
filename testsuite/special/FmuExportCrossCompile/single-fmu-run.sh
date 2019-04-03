#!/bin/bash -x

ARCH="$1"
VERSION="$2"
shift
shift

CMD="$@"

echo "$VERSION"

for fmu in *.fmu; do
fmu=`echo $fmu | sed 's/[.]fmu$//'`
for t in me cs; do
  if test "$t" = "me"; then
    d="ModelExchange"
  else
    d="CoSimulation"
  fi
  DIR="./Test_FMUs/FMI_2.0/$d/$ARCH/OpenModelica/$VERSION/$fmu"
  mkdir -p "$DIR"
  if test -z "$CMD"; then
    case $ARCH in
    c-code)
      CMD=fmuCheck.linux64
      ;;
    linux32)
      CMD=fmuCheck.linux32
      ;;
    linux64)
      CMD=fmuCheck.linux64
      ;;
    win32)
      WINE32=`which fmuCheck.win32.exe`
      CMD="wine $WINE32"
      ;;
    win64)
      WINE64=`which fmuCheck.win64.exe`
      CMD="WINEARCH=win64 WINEPREFIX=~/.wine64 wine $WINE64"
      ;;
    darwin64)
      if which dyld64; then
        CMD="dyld64 $DARWIN64"
      else
        CMD=fmuCheck.darwin64
      fi
      ;;
    *)
      echo Unknown arch $ARCH
      exit 1
      ;;
    esac
  fi
  CMD2=`echo $CMD -c , -f -n 2000 -d -k $t -e "$DIR/${fmu}_cc.log" -o "$DIR/${fmu}_cc.csv" "$DIR/${fmu}.fmu"`
  cp "${fmu}.fmu" "$DIR/" || exit 1
  cp "${fmu}_ref.opt" "$DIR/" || exit 1
  echo "$CMD2" > "$DIR/${fmu}_cc.bat" || exit 1
  cp "$DIR/${fmu}_cc.bat" "$DIR/${fmu}_cc.sh" || exit 1
  bash -c "$CMD2" || exit 1

  cp "$DIR/${fmu}_cc.csv" "${fmu}-$ARCH-$t.csv" || exit 1
  cp "${fmu}_res.csv" "$DIR/${fmu}_ref.csv" || exit 1
  cp "ReadMe.txt" "$DIR/"
done
done

# Need to find a working version of dyld32 to test this
#dyld32 $(DARWIN32) -f -n 2000 -d -k me -o darwin32-me.csv FmuExportCrossCompile.fmu
#dyld32 $(DARWIN32) -f -n 2000 -d -k cs -o darwin32-cs.csv FmuExportCrossCompile.fmu
