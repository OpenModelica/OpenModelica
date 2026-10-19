#!/bin/sh
#
# Check style 50/72

if test `head -1 "$1" | wc -L` -gt 50; then
  echo "Too long commit summary (max 50 characters)" >&2
  exit 1
elif test `sed -n 2p "$1" | wc -L` != 0; then
  echo "Commit does not have an empty second line" >&2
  exit 1
elif test `grep -v '^#' < "$1" | wc -L` -gt 72; then
  echo "Commit has too long commit lines (max 72 characters per line)" >&2
  exit 1
fi
