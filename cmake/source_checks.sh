#!/bin/bash
# cmake/source_checks.sh
#
# Source hygiene checks that used to live as targets in the top-level Makefile.in
# of the removed autotools build. Driven by the CMake targets defined in
# cmake/omc_source_checks.cmake.
#
# Usage: source_checks.sh <check> <source_dir>
#   <check> is one of:
#     bom-error                   fail if any source file starts with a UTF-8 BOM
#     utf8-error                  fail if any source file is not valid UTF-8
#     thumbsdb-error              fail if a Windows Thumbs.db file is checked in
#     trailing-whitespace-error   fail on trailing whitespace in sources
#     tab-error                   fail on hard tabs in sources
#     fix-whitespace              rewrite sources: tabs -> 2 spaces, trim trailing
#
# Exit code: 0 on success, 1 on failure.

set -u

CHECK="${1:-}"
SOURCE_DIR="${2:-}"

if [[ -z "$CHECK" || -z "$SOURCE_DIR" ]]; then
  echo "Usage: $0 <check> <source_dir>"
  exit 1
fi

cd "$SOURCE_DIR" || exit 1

# The directories that are checked. Only these are checked (rather than the whole
# repository) because 3rdParty sources and the bulk of the testsuite are not ours.
SOURCE_DIRS=(
  OMEdit
  OMShell/OMShell
  OMNotebook/OMNotebook
  OMOptim/OMOptim
  OMPlot/OMPlot
  OMCompiler/Compiler
  OMCompiler/SimulationRuntime
  testsuite/flattening/libraries/3rdParty/PlanarMechanics
  testsuite/flattening/libraries/3rdParty/siemens
  testsuite/flattening/libraries/3rdParty/SiemensPower
  testsuite/flattening/libraries/3rdParty/ThermoSysPro
  testsuite/openmodelica/modelicaML
  testsuite/AVM
  testsuite/simulation
)

# Drop the ones that are not checked out (optional submodules).
EXISTING_DIRS=()
for d in "${SOURCE_DIRS[@]}"; do
  test -d "$d" && EXISTING_DIRS+=("$d")
done

if [ ${#EXISTING_DIRS[@]} -eq 0 ]; then
  echo "None of the checked source directories exist; nothing to do."
  exit 0
fi

# All C/C++/Modelica/Susan sources below the checked directories.
find_sources() {
  find "${EXISTING_DIRS[@]}" -regextype posix-egrep -regex '.*\.(cpp|c|h|mo|tpl)$' -type f
}

case "$CHECK" in
  bom-error)
    failed=0
    while IFS= read -r f; do
      # od keeps the comparison textual, so files with null bytes are fine.
      if [ "$(od -An -N3 -tx1 < "$f" | tr -d ' \n')" = "efbbbf" ]; then
        echo "$f contains a UTF-8 BOM"
        failed=1
      fi
    done < <(find "${EXISTING_DIRS[@]}" -type f)
    exit $failed
    ;;

  utf8-error)
    failed=0
    while IFS= read -r f; do
      if ! iconv -f UTF-8 -t UTF-8 "$f" -o /dev/null 2>/dev/null; then
        echo -n "$f: "
        iconv -f UTF-8 -t UTF-8 "$f" -o /dev/null 2>&1 | head -n1
        failed=1
      fi
      # Also detect some valid UTF-8 that was obviously mangled by an editor:
      # "Linköping" spelled with a broken separator.
      if grep -q 'Link[^A-Za-z0-9_,.;&-]*ping' "$f" && ! grep -q 'Linköping' "$f"; then
        echo "$f: Failed Linköping test"
        failed=1
      fi
    done < <(find_sources)
    exit $failed
    ;;

  thumbsdb-error)
    if find . -name "Thumbs.db" | grep Thumbs.db; then
      exit 1
    fi
    exit 0
    ;;

  trailing-whitespace-error)
    if find_sources \
        | grep -Ev '/GenTest/|/antlr-3\.2/|qjson-0\.8\.1|ParadisEO-2\.0\.1|OMPlot/qwt' \
        | xargs -r grep -l ' $' ; then
      exit 1
    fi
    exit 0
    ;;

  tab-error)
    if find_sources \
        | grep -Ev '/GenTest/|/antlr-3\.2/|Parser/MetaModelica_|Parser/ParModelica_|Parser/Modelica_3_|Parser/ModelicaParser' \
        | xargs -r grep -lP '\t' ; then
      exit 1
    fi
    exit 0
    ;;

  fix-whitespace)
    find_sources | xargs -r sed -i -e 's/\t/  /g' -e 's/ *$//'
    exit 0
    ;;

  *)
    echo "Unknown check: $CHECK"
    exit 1
    ;;
esac
