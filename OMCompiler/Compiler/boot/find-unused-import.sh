#!/bin/bash

EXIT=0
for f in "$@"; do
  case $f in
    *Template*TV.mo)
      SKIP=1
      ;;
    *susan_codegen*)
      SKIP=1
      ;;
    *)
      SKIP=
      ;;
  esac
  if test ! -z "$SKIP"; then
    continue
  fi
  CONTINUE=1
  while test "$CONTINUE" = "1"; do
    CONTINUE=0
    for i in `egrep "^ *(public|protected)? *import" "$f" | grep -o "import \+[A-Za-z0-9_]\+ *;" | cut -d" " -f2 | cut -d";" -f1`; do
      if ! grep "$i" "$f" | grep -q -v "import \+$i *[;]"; then
        echo "Unused import $i in $f"
        sed -i.bak "/^ *[a-z]* *import *$i *;/d" "$f"
        rm -f "$f.bak"
        CONTINUE=1
        EXIT=1
      fi
    done
  done
done
if test "NOERROR" = "1"; then
  exit
fi
exit "$EXIT"
