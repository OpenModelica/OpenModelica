#!/usr/bin/env bash
#
# This file is part of OpenModelica.
#
# Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
# c/o Linköpings universitet, Department of Computer and Information Science,
# SE-58183 Linköping, Sweden. All rights reserved.
#
# THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
# THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
# SPDX-License-Identifier: OSMC-PL-1.8 OR AGPL-3.0-or-later
#
# End-to-end ParModelica auto clustering-optimization demo.
#
# It walks the whole optimization loop and dumps a GraphML (and an SVG) of the
# clustering at every stage, so you can see how the clustering changes — both the
# optimizations performed inside the executable and the metaheuristic optimization
# performed in Julia:
#
#   Modelica  --omc --parmodauto-->  executable
#   executable  --parmodExportTaskGraph / --parmodDumpStages-->  task-graph + per-stage clustering JSON
#   JSON  --parmod_optimize_clustering.jl (MetaheuristicsAlgorithms.jl)-->  optimized clustering JSON
#   optimized JSON  --parmodImportClustering-->  executable re-runs the simulation
#
# At the end it computes the differences:
#   * graph HEIGHT (critical path): executable clustering vs. Julia-optimized clustering,
#   * simulation RESULT: default run vs. optimized-clustering run (must match — same model),
#   * wall-clock time of the two runs.
#
# Every clustering JSON is rendered to GraphML with parmod_graph_to_graphml.py and to
# SVG with parmod_graph_plot.jl, named <NN>_<stage>.{graphml,svg}.
#
# Usage:
#   parmod_optimize_demo.sh [MODEL] [OUTDIR]
#     MODEL   Modelica model to simulate (default: Modelica.Fluid.Examples.BranchingDynamicPipes)
#     OUTDIR  output directory          (default: ./parmod_demo_out)
#
#   parmod_optimize_demo.sh --clean [OUTDIR]
#     Remove everything in OUTDIR that this demo can regenerate (build files, task
#     graphs, GraphML/SVG, results, logs) and exit. README.md is kept.
#
# Environment overrides:
#   OMC, JULIA, PYTHON   interpreters to use (default: omc / julia / python3 from PATH)
#   MODELFILE            a .mo file to loadFile instead of loadModel(Modelica); use this
#                        for a small self-contained model with legible task graphs
#   CORES                number of hardware lanes for the optimizer (default: nproc)
#   ALGO                 metaheuristic algorithm (default: GWO)
#   ITERS, POP, SEED     optimizer settings (default: 300 / 30 / 1)
#   STOPTIME             override the model stopTime to keep the demo quick (optional)

set -uo pipefail

# ---- arguments -------------------------------------------------------------
CLEAN=0
POS=()
for a in "$@"; do
  case "$a" in
    --clean) CLEAN=1 ;;
    *)       POS+=("$a") ;;
  esac
done
PREFIX="m"
if [ "$CLEAN" = 1 ]; then
  MODEL=""
  OUTDIR="${POS[0]:-$PWD/parmod_demo_out}"
else
  MODEL="${POS[0]:-Modelica.Fluid.Examples.BranchingDynamicPipes}"
  OUTDIR="${POS[1]:-$PWD/parmod_demo_out}"
fi

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMC="${OMC:-omc}"
JULIA="${JULIA:-julia}"
PYTHON="${PYTHON:-python3}"
CORES="${CORES:-$(nproc 2>/dev/null || echo 4)}"
ALGO="${ALGO:-GWO}"
ITERS="${ITERS:-300}"
POP="${POP:-30}"
SEED="${SEED:-1}"

GRAPHML="$SCRIPTS_DIR/parmod_graph_to_graphml.py"
PLOT="$SCRIPTS_DIR/parmod_graph_plot.jl"
OPTIMIZE="$SCRIPTS_DIR/parmod_optimize_clustering.jl"

say()  { printf '\n\033[1;36m== %s\033[0m\n' "$*"; }
note() { printf '   %s\n' "$*"; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# Remove everything in a directory that this demo can regenerate: the omc build
# files (the executable and its m_* sources/objects/metadata) and every produced
# task graph / clustering / GraphML / SVG / result / log. Hand-written files such
# as README.md (and anything not matching the patterns) are left untouched.
clean_outdir() {
  local d="$1"
  [ -d "$d" ] || { note "nothing to clean: $d does not exist"; return; }
  ( cd "$d" 2>/dev/null && rm -f \
      "$PREFIX" "$PREFIX".* "${PREFIX}"_* \
      ./*.json ./*.graphml ./*.svg ./*.mat ./*.mos ./*.log ./*.bin 2>/dev/null )
  note "cleaned regenerable artifacts in $d (kept README.md and any non-generated files)"
}

# --clean: wipe regenerable artifacts and exit (no toolchain needed).
if [ "$CLEAN" = 1 ]; then
  say "Cleaning regenerable demo artifacts"
  clean_outdir "$OUTDIR"
  exit 0
fi

command -v "$OMC"    >/dev/null 2>&1 || die "omc not found (set OMC=...)"
[ -f "$OPTIMIZE" ]   || die "optimizer not found at $OPTIMIZE"

mkdir -p "$OUTDIR" || die "cannot create $OUTDIR"
cd "$OUTDIR"        || die "cannot enter $OUTDIR"
clean_outdir "$PWD"  # start each run from a clean directory

# Render one clustering JSON to GraphML (python: task view colored by cluster + the
# contracted cluster view) and to SVG (julia GraphPlot). $1=json $2=label
render() {
  local json="$1" label="$2"
  [ -f "$json" ] || { note "skip render: $json missing"; return; }
  if "$PYTHON" "$GRAPHML" --mode tasks    -o "${label}.tasks.graphml"    "$json" >/dev/null 2>&1 \
  && "$PYTHON" "$GRAPHML" --mode clusters -o "${label}.clusters.graphml" "$json" >/dev/null 2>&1; then
    note "GraphML  -> ${label}.tasks.graphml , ${label}.clusters.graphml"
  else
    note "GraphML render failed for $json (python available?)"
  fi
  "$JULIA" "$PLOT" --mode tasks -o "${label}.svg" "$json" >/dev/null 2>&1 \
      && note "SVG      -> ${label}.svg" \
      || note "SVG render skipped for $json (julia GraphPlot deps?)"
}

# --------------------------------------------------------------------------
say "1/7  Modelica -> executable   ($MODEL, omc --parmodauto)"
# --------------------------------------------------------------------------
if [ -n "${MODELFILE:-}" ]; then
  [ -f "$MODELFILE" ] || die "MODELFILE '$MODELFILE' not found"
  LOADCMD="loadFile(\"$(cd "$(dirname "$MODELFILE")" && pwd)/$(basename "$MODELFILE")\");"
  note "loading model from $MODELFILE"
else
  LOADCMD="loadModel(Modelica);"
  note "loading the Modelica Standard Library"
fi
cat > build.mos <<EOF
setCommandLineOptions("--parmodauto"); getErrorString();
$LOADCMD getErrorString();
buildModel($MODEL, fileNamePrefix="$PREFIX"); getErrorString();
EOF
"$OMC" build.mos || die "omc build failed"
[ -x "./$PREFIX" ] || die "executable ./$PREFIX was not produced (see omc output above)"
note "built ./$PREFIX"

SIMFLAGS=""
[ -n "${STOPTIME:-}" ] && SIMFLAGS="-override=stopTime=$STOPTIME"

# --------------------------------------------------------------------------
say "2/7  executable -> task graph + per-stage clustering (executable-side optimizations)"
# --------------------------------------------------------------------------
# -parmodDumpStages writes one snapshot before and after every clustering optimization
# the executable performs; -parmodExportTaskGraph writes the final task graph + clustering.
/usr/bin/env bash -c "time ./$PREFIX -parmodExportTaskGraph=taskgraph.json -parmodDumpStages=stage $SIMFLAGS" \
    > default_run.log 2>&1 || die "default parmodauto run failed (see default_run.log)"
cp -f "${PREFIX}_res.mat" default_res.mat 2>/dev/null
[ -f taskgraph.json ] || die "taskgraph.json was not exported"
note "exported taskgraph.json and stage snapshots:"
ls -1 stage.*.json 2>/dev/null | sed 's/^/     /'

# --------------------------------------------------------------------------
say "3/7  GraphML/SVG of the executable-side clustering (before & after each optimization)"
# --------------------------------------------------------------------------
i=0
for f in $(ls -1 stage.*.json 2>/dev/null | sort); do
  base="$(basename "$f" .json)"          # e.g. stage.01.cluster_merge_common
  render "$f" "exe_$(printf '%02d' "$i")_${base#stage.}"
  i=$((i+1))
done
render taskgraph.json "exe_final_clustering"

# --------------------------------------------------------------------------
say "4/7  task graph -> Julia metaheuristic optimization ($ALGO)"
# --------------------------------------------------------------------------
"$JULIA" "$OPTIMIZE" --algorithm "$ALGO" --cores "$CORES" --iters "$ITERS" \
    --pop "$POP" --seed "$SEED" -o optimized.json taskgraph.json \
    | tee optimize.log
[ -f optimized.json ] || die "optimizer did not produce optimized.json"

# --------------------------------------------------------------------------
say "5/7  GraphML/SVG of the Julia optimization (before = exported, after = optimized)"
# --------------------------------------------------------------------------
render taskgraph.json "julia_before_optimization"
render optimized.json "julia_after_optimization"

# --------------------------------------------------------------------------
say "6/7  optimized clustering -> executable (re-run via -parmodImportClustering)"
# --------------------------------------------------------------------------
/usr/bin/env bash -c "time ./$PREFIX -parmodImportClustering=optimized.json $SIMFLAGS" \
    > optimized_run.log 2>&1 || die "optimized-clustering run failed (see optimized_run.log)"
cp -f "${PREFIX}_res.mat" optimized_res.mat 2>/dev/null
note "re-ran the simulation with the optimized clustering"

# --------------------------------------------------------------------------
say "7/7  Differences"
# --------------------------------------------------------------------------
# (a) graph height, parsed from the optimizer log
note "Graph height (critical path):"
grep -E "Reference height|Imported clustering height|Optimized clustering|Speedup|Improvement" optimize.log | sed 's/^/     /'

# (b) simulation result difference: default clustering vs optimized clustering
cat > diff.mos <<EOF
(ok, vars) := OpenModelica.Scripting.diffSimulationResults(
  actualFile="optimized_res.mat", expectedFile="default_res.mat",
  diffPrefix="resdiff", relTol=1e-6, relTolDiffMinMax=1e-4, rangeDelta=0.002);
"match=" + String(ok);
vars;
getErrorString();
EOF
note "Simulation result difference (default vs optimized clustering):"
if "$OMC" diff.mos > resdiff.log 2>&1; then
  if grep -q "match=true" resdiff.log; then
    note "  results MATCH — optimized clustering reproduces the simulation exactly"
  else
    note "  results DIFFER — see resdiff.log and resdiff* files:"
    grep -vE '^"*"$' resdiff.log | sed 's/^/       /' | head -20
  fi
else
  note "  diffSimulationResults could not run; see resdiff.log"
fi

# (c) wall-clock time of the two runs
note "Wall-clock time:"
printf '     default clustering : %s\n' "$(grep -E '^real' default_run.log   | tail -1 | awk '{print $2}')"
printf '     optimized clustering: %s\n' "$(grep -E '^real' optimized_run.log | tail -1 | awk '{print $2}')"

say "Done. Artifacts in $OUTDIR"
ls -1 *.graphml *.svg 2>/dev/null | sed 's/^/   /'
