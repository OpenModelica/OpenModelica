#!/bin/sh
#
# Check style 52/70

if test `head -1 "$1" | wc -L` -gt 50; then
  echo "Too long commit summary (leave an empty line after the first if it is not part of the summary)" >&2
  exit 1
elif test `head -2 | tail -n +2 "$1" | wc -L` != 0; then
  echo "Commit does not have an empty second line" >&2
  exit 1
elif test `wc -L < "$1"` -gt 72; then
  echo "Commit has too long commit lines (max 72 characters per line)" >&2
  exit 1
fi
