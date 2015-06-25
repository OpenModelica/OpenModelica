#!/bin/bash

for f in "$@"; do
  sed 's,\(_images/math/.*[.]\)png,\1svg,' "$f" > fix-math.tmp
  while ! cmp --quiet "$f" fix-math.tmp; do
    mv fix-math.tmp "$f"
    sed 's,\(_images/math/.*[.]\)png,\1svg,g' "$f" > fix-math.tmp
  done
  rm -f fix-math.tmp
done
