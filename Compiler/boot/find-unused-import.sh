#!/bin/bash

for f in ../*/*.mo; do
  case $f in
    *Template*)
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
  for i in `grep -o "import \+[A-Za-z0-9_]\+ *;" "$f" | cut -d" " -f2 | cut -d";" -f1`; do
    if ! grep -q "$i[.]" "$f"; then
      echo "Unused import $i in $f"
      sed -i "/^[a-z]* *import \+$i *;/d" "$f"
    fi
  done
done
