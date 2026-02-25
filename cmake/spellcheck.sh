#!/bin/bash
# cmake/spellcheck.sh
#
# Spellcheck gettext strings in Modelica compiler sources using aspell.
# Used by the 'spellcheck' CMake target (cmake/omc_spellcheck.cmake) and
# the 'spellcheck' Makefile target (Makefile.in).
#
# Usage: spellcheck.sh <source_dir> <aspell_executable>
# Exit code: 0 on success, 1 on spellcheck failure.

SOURCE_DIR="$1"
ASPELL="$2"

if [[ -z "$SOURCE_DIR" || -z "$ASPELL" ]]; then
  echo "Usage: $0 <source_dir> <aspell_executable>"
  exit 1
fi

git p=$(ls "$SOURCE_DIR"/OMCompiler/Compiler/*/*.mo | grep -v "Flags.*mo")

ASPELL_OUTPUT=$(grep -oE 'gettext[(]["]([^"]|([\\]["]))*["]' $MO_FILES \
    | sed "s/[\\%]./ /g" \
    | "$ASPELL" -p "$SOURCE_DIR/.openmodelica.aspell" --mode=ccpp --lang=en_US list \
    | sort -u \
    | sed 's/^/aspell: /')

if [[ -n "$ASPELL_OUTPUT" ]]; then
  echo "$ASPELL_OUTPUT"
  printf '\nSpellcheck failed! To fix, add the flagged word(s) to the personal word list:\n'
  printf '  %s/.openmodelica.aspell\n' "$SOURCE_DIR"
  exit 1
fi

echo "Spellcheck passed."
