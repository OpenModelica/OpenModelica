#!/bin/bash
#
# Regenerate src/sim_metadata.rs from the OpenModelica C runtime tables.
#
# Compiles gen-sim-tables.c against the C runtime (which defines the tables),
# runs it, and writes the Rust mirror. Run when the upstream SimulationRuntime
# tables (FLAG_*, *_METHOD_*, OMC_LOG_STREAM_*) change. See gen-sim-tables.c.
#
set -euo pipefail

GEN="$(cd "$(dirname "$0")" && pwd)"
OUT="$GEN/../src/sim_metadata.rs"
OMBUILDDIR="${OMBUILDDIR:-/projects/OpenModelica/build}"
HOST_SHORT="${HOST_SHORT:-$(gcc -dumpmachine)}"
INC="$OMBUILDDIR/include/omc/c"
LIB="$OMBUILDDIR/lib/$HOST_SHORT/omc"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cc "$GEN/gen-sim-tables.c" -I"$INC" -I"$INC/util" \
   -L"$LIB" -lOpenModelicaRuntimeC -lomcgc \
   -Wl,-rpath,"$LIB" -o "$tmp/gen-sim-tables"
"$tmp/gen-sim-tables" > "$OUT"

echo "wrote $OUT ($(grep -c 'no_mangle' "$OUT") exported symbols)"
