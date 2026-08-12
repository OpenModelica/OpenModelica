#!/usr/bin/env bash

set -euo pipefail # bash "strict mode"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

usage() {
  cat <<EOF
Usage: $0 --omc=/full/path/to/omc [--workdir=/path/to/workdir] [--simCodeTarget=C|Cpp] [--help]

Options:
  --omc           Full path to the omc executable. REQUIRED.
  --workdir       Working directory where to perform the sanity test. Default: current directory
  --simCodeTarget Sim code target to use: C or Cpp, default: C
  --clean         true or false. If true, remove temp files. Default: true
  -h, --help      Show this help and exit
EOF
}

# Defaults
OMC=""
WORKDIR="$(pwd)"
SIM_CODE_TARGET="C"
CLEAN="true"

# Parse args (supports --opt value and --opt=value)
while [ "$#" -gt 0 ]; do
  case "$1" in
    --omc=*) OMC="${1#*=}"; shift;;
    --omc) [ -n "${2:-}" ] || { echo "Error: --omc requires a value"; exit 1; }; OMC="$2"; shift 2;;
    --workdir=*) WORKDIR="${1#*=}"; shift;;
    --workdir) [ -n "${2:-}" ] || { echo "Error: --workdir requires a value"; exit 1; }; WORKDIR="$2"; shift 2;;
    --simCodeTarget=*) SIM_CODE_TARGET="${1#*=}"; shift;;
    --simCodeTarget) [ -n "${2:-}" ] || { echo "Error: --simCodeTarget requires a value"; exit 1; }; SIM_CODE_TARGET="$2"; shift 2;;
    --clean=*) CLEAN="${1#*=}"; shift;;
    --clean) [ -n "${2:-}" ] || { echo "Error: --clean requires a value"; exit 1; }; CLEAN="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown argument: $1"; usage; exit 1;;
  esac
done

# Normalize clean
case "$(printf '%s' "$CLEAN" | tr '[:upper:]' '[:lower:]')" in
  true|1|yes) CLEAN="true";;
  *) CLEAN="false";;
esac

# Normalize simCode target (accepts C or Cpp only)
lc_sim="$(printf '%s' "$SIM_CODE_TARGET" | tr '[:upper:]' '[:lower:]')"
case "$lc_sim" in
  c) SIM_CODE_TARGET="C";;
  cpp) SIM_CODE_TARGET="Cpp";;
  *) echo "Error: --simCodeTarget must be C or Cpp (got: $SIM_CODE_TARGET)"; usage; exit 1;;
esac

# Normalize omc
if [ -z "$OMC" ]; then
  echo "Error: --omc is required."
  usage
  exit 1
fi
if [ ! -x "$OMC" ]; then
  echo "Error: omc executable not found or not executable: $OMC"
  exit 1
fi
OMC="$(realpath "$OMC")"

echo "Using omc: $OMC ($("$OMC" --version))"
echo "Working directory: $WORKDIR"
echo "simCodeTarget: $SIM_CODE_TARGET"

mkdir -p "$WORKDIR/.sanity-check/$SIM_CODE_TARGET"
pushd "$WORKDIR/.sanity-check/$SIM_CODE_TARGET" >/dev/null
cp "$SCRIPT_DIR/testSanity.mos" .

# Check that a source FMU declares the sources it ships, and ships the ones it declares.
#
# An FMU that carries C sources has to say which they are, or an importer that wants
# to build it has nothing to go on; and a file it names has to be there. Where the
# list lives depends on the FMI version:
#
#   FMI 1.0/2.0  SourceFiles/File in modelDescription.xml
#   FMI 3.0      SourceFile in sources/buildDescription.xml - FMI 3.0 dropped
#                SourceFiles from modelDescription.xml, and the schema rejects it
#                there (the interface type element takes only Annotations)
#
# The list of runtime sources behind all of this comes from RuntimeSources.mo, which
# the CMake and the autotools build generate separately, so the check lives here and
# runs on every build rather than in the testsuite, which only runs against one.
check_fmu_sources() {
  local fmu="$1"
  python3 - "$fmu" <<'PYEOF'
import sys, zipfile, re
fmu = sys.argv[1]
with zipfile.ZipFile(fmu) as z:
    names = set(z.namelist())
    md = z.read('modelDescription.xml').decode('utf-8', 'replace')
    build = (z.read('sources/buildDescription.xml').decode('utf-8', 'replace')
             if 'sources/buildDescription.xml' in names else '')
    mk = (z.read('sources/Makefile.in').decode('utf-8', 'replace')
          if 'sources/Makefile.in' in names else '')

version = (re.search(r'fmiVersion="([^"]+)"', md) or [None, ''])[1]
if version.startswith('3'):
    where, listed = 'sources/buildDescription.xml', re.findall(r'<SourceFile\s+name="([^"]+)"', build)
    if 'SourceFiles' in md:
        sys.exit("Error: %s has SourceFiles in modelDescription.xml, which FMI 3.0 "
                 "does not allow; sources belong in sources/buildDescription.xml" % fmu)
else:
    where, listed = 'modelDescription.xml', re.findall(r'<File\s+name="([^"]+)"', md)

shipped = [n[len('sources/'):] for n in names
           if n.startswith('sources/') and n.endswith(('.c', '.cpp'))]
if shipped and not listed:
    sys.exit("Error: %s ships %d source files but declares none in %s"
             % (fmu, len(shipped), where))
missing = [f for f in listed if 'sources/' + f not in names]
if missing:
    sys.exit("Error: %s declares %d source file(s) in %s that it does not ship: %s"
             % (fmu, len(missing), where, ", ".join(missing[:5])))

# Every object the makefile wants has to be one the makefile can build. Turning a
# source name into an object name by replacing ".c" used to mangle ".cpp" into
# ".opp", which no rule matches, and the FMU only failed once built from sources.
runtimefiles = re.search(r'^RUNTIMEFILES=(.*)$', mk, re.M)
if runtimefiles:
    bad = [o for o in runtimefiles.group(1).split()
           if not o.startswith('$') and not o.endswith('.o')]
    if bad:
        sys.exit("Error: %s has object files the makefile has no rule for: %s"
                 % (fmu, ", ".join(bad[:5])))

print("%s (FMI %s): %d source files declared in %s, all present"
      % (fmu, version, len(listed), where))
PYEOF
}

# Run sanity MOS script with sim Code target
if [ "$SIM_CODE_TARGET" = "Cpp" ]; then
  set -x # echo on
  "$OMC" --simCodeTarget=Cpp testSanity.mos
  ./M
  set +x # echo off
  test -f OMCppM.cpp || { echo "Error: Expected file OMCppM.cpp not found"; exit 1; }
  test -f M.fmu || { echo "Error: Expected file M.fmu (FMI 2.0) not found"; exit 1; }
  test -f M_fmi3.fmu || { echo "Error: Expected file M_fmi3.fmu (FMI 3.0) not found"; exit 1; }
  check_fmu_sources M.fmu
  check_fmu_sources M_fmi3.fmu
else
  set -x # echo on
  "$OMC" --linearizationDumpLanguage=matlab testSanity.mos
  ./M
  ./M -l=1.0
  set +x # echo off
  test -f linearized_model.m || { echo "Error: Expected file linearized_model.m not found"; exit 1; }
  test -f M.fmu || { echo "Error: Expected file M.fmu (FMI 2.0) not found"; exit 1; }
  test -f M_fmi3.fmu || { echo "Error: Expected file M_fmi3.fmu (FMI 3.0) not found"; exit 1; }
  check_fmu_sources M.fmu
  check_fmu_sources M_fmi3.fmu
fi

# Clean
popd >/dev/null
if [ "$CLEAN" = "true" ]; then
  rm -rf "$WORKDIR/.sanity-check/"
fi

echo "Sanity check ($SIM_CODE_TARGET) passed successfully."
