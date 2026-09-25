#!/usr/bin/env bash
# Runs the coverage part of the Jenkins pipeline on this machine, in the same
# Docker image, so that it can be tried and debugged without waiting for CI.
#
# Mirrors .CI/common.groovy - keep the two in sync. Per compiler:
#   sync     copies this checkout (uncommitted changes to tracked files
#            included, untracked files not) into a workspace of its own and
#            cleans it like standardSetup()
#   build    the instrumented build and install tree (buildGccOMC(),
#            buildClangOMC())
#   test     runs omc from that install tree at another agent's path, with
#            the counters redirected by GCOV_PREFIX (withCoverageCounters())
#   collect  a fresh configure at the build's path, holding only the *.gcno,
#            the generated sources and the counters, then coverage-collect
#            (collectCoverage())
# and then, for all compilers together,
#   merge    renders every tracefile in <work>/report/coverage-tracefiles/
#            into one report (coverageReportStage()). Tracefiles put there by
#            hand are merged too, e.g. the ones Jenkins archives in
#            coverage-tracefiles-archive/ (gunzip them first).
#   summary  line coverage per directory of each of those tracefiles
#
# Every step works on what the previous one left in <work>, so each can be
# rerun on its own: 'collect merge summary' after changing the coverage
# targets, 'build test collect merge summary' to rebuild incrementally. Only
# 'sync' copies the checkout again, and it throws away what the build
# generated in the source tree, so the next build redoes most of the compiler.
#
# The paths are the ones of PR-16907/2: gcc built at /var/lib/jenkins2/...,
# clang at /var/lib/jenkins/..., and the tests ran on yet another agent.

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [options] [step...]

Steps: sync build test collect merge summary, or all (the default).

Options:
  -c, --compilers LIST  comma-separated, gcc and/or clang (default: gcc,clang)
  -w, --work DIR        where the workspaces go
                        (default: \$OM_COVERAGE_WORK or <checkout>/../om-coverage-local)
  -j, --jobs N          parallel build jobs (default: nproc)
  -t, --test CMD        what 'test' runs instead of the default smoke test: a
                        bash command, run in the root of the build workspace
                        with omc at build/bin/omc, e.g.
                          'cd testsuite/openmodelica/interactive-API && ../../rtest -v saveTotalModel.mos'
      --ccache          build through ccache (\$HOME/.cache/om-coverage-ccache);
                        Jenkins uses sccache, which is not in the image
      --fresh           'build' starts from an empty build_cmake and build/
      --no-pull         do not pull the image first (Jenkins always does)
  -h, --help            this text
EOF
}

SRC=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
WORK=${OM_COVERAGE_WORK:-$(dirname "$SRC")/om-coverage-local}
IMAGE=docker.openmodelica.org/build-deps:ubuntu-22.04
COMPILERS=gcc,clang
JOBS=$(nproc)
TEST_CMD=
CCACHE=0
FRESH=0
PULL=1
STEPS=()

while [ $# -gt 0 ]; do
  case $1 in
    -c|--compilers) COMPILERS=$2; shift 2 ;;
    -w|--work)      WORK=$2; shift 2 ;;
    -j|--jobs)      JOBS=$2; shift 2 ;;
    -t|--test)      TEST_CMD=$2; shift 2 ;;
    --ccache)       CCACHE=1; shift ;;
    --fresh)        FRESH=1; shift ;;
    --no-pull)      PULL=0; shift ;;
    -h|--help)      usage; exit 0 ;;
    all)            STEPS+=(sync build test collect merge summary); shift ;;
    sync|build|test|collect|merge|summary) STEPS+=("$1"); shift ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done
[ ${#STEPS[@]} -gt 0 ] || STEPS=(sync build test collect merge summary)
IFS=, read -r -a COMPILER_LIST <<< "$COMPILERS"
for c in "${COMPILER_LIST[@]}"; do
  case $c in gcc|clang) ;; *) echo "Unknown compiler: $c" >&2; exit 2 ;; esac
done
for tool in docker git rsync tar python3; do
  command -v "$tool" > /dev/null || { echo "$tool is needed but not found" >&2; exit 1; }
done
mkdir -p "$WORK"
WORK=$(cd "$WORK" && pwd)
REPORT=$WORK/report

# Where each build ran, as the *.gcno record it, and where the tests ran.
build_root() {
  case $1 in
    gcc)   echo /var/lib/jenkins2/ws/OpenModelica ;;
    clang) echo /var/lib/jenkins/ws/OpenModelica ;;
  esac
}
TEST_ROOT=/var/lib/jenkins3/ws/OpenModelica

compiler_flags() {
  [ "$1" = clang ] && echo "-DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++" || true
}

step() { printf '\n=== %s\n' "$*"; }

# in_docker <host dir> <path to mount it at> <script> [docker args...]
# Runs script with bash -e in the image, in the mounted directory, as the
# calling user (Jenkins' docker.inside does the same with its own uid).
in_docker() {
  local dir=$1 mnt=$2 script=$3
  shift 3
  docker run --rm -u "$(id -u):$(id -g)" \
    -v "$dir:$mnt" -w "$mnt" -e HOME="$mnt/.home" "$@" \
    "$IMAGE" bash -ec "mkdir -p \"\$HOME\"; $script"
}

# Leave these alone when syncing: they are what the steps produce.
SYNC_KEEP=(/build_cmake/ /build/ /.home/ /gcda-out/ /fmu-coverage/
           /counters/ /coverage-tracefiles/ /.coverage-local/)

sync_tree() {
  local dst=$1 args=() p
  for p in "${SYNC_KEEP[@]}"; do args+=(--exclude="$p"); done
  mkdir -p "$dst"
  rsync -a --delete "${args[@]}" "$SRC/" "$dst/"
  args=()
  for p in "${SYNC_KEEP[@]}"; do args+=(-e "$p"); done
  # standardSetup(); -e keeps what the steps produced.
  git -C "$dst" clean -ffdxq "${args[@]}"
  git -C "$dst" submodule foreach --quiet --recursive git clean -ffdxq
}

do_sync() {
  local c
  for c in "${COMPILER_LIST[@]}"; do
    step "sync $c: $SRC -> $WORK/build-$c"
    sync_tree "$WORK/build-$c"
  done
  step "sync report: $SRC -> $REPORT"
  sync_tree "$REPORT"
}

do_build() {
  local c=$1 ws=$WORK/build-$c root cache_args=() docker_args=()
  root=$(build_root "$c")
  step "build $c in $ws, at $root"
  [ -d "$ws/.git" ] || { echo "No workspace; run 'sync' first" >&2; exit 1; }
  if [ $FRESH = 1 ]; then rm -rf "$ws/build_cmake" "$ws/build"; fi
  if [ $CCACHE = 1 ]; then
    mkdir -p "$HOME/.cache/om-coverage-ccache"
    cache_args=(-DOM_COMPILER_CACHE=ccache)
    docker_args=(-v "$HOME/.cache/om-coverage-ccache:/ccache" -e CCACHE_DIR=/ccache)
  else
    cache_args=(-DOM_COMPILER_CACHE=none)
  fi
  # buildOMC(): only the gcc build also builds testsuite-depends; the clang
  # one strips its libraries before they are stashed.
  in_docker "$ws" "$root" "
    cmake --version | head -1
    cmake -S . -B build_cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=build \
          -DOM_ENABLE_COVERAGE=ON $(compiler_flags "$c") ${cache_args[*]}
    cmake --build build_cmake --parallel $JOBS --target install
    if [ $c = gcc ]; then
      cmake --build build_cmake --parallel $JOBS --target testsuite-depends
    fi
    build/bin/omc --version
    if [ $c = clang ]; then
      find build/lib/*/omc/ -name '*.so' -exec strip {} ';'
    fi
  " "${docker_args[@]}"
}

# Simulates, which runs the compiler front to back and the C runtime, and
# exports an FMU, which covers the FMU export sources.
DEFAULT_TEST='
mkdir -p .coverage-local/test && cd .coverage-local/test && rm -rf ./*
cat > smoke.mos <<"EOF"
loadString("
model CoverageSmoke
  Real x(start = 1, fixed = true);
  Real y;
equation
  der(x) = -x;
  y = sin(time) * x;
end CoverageSmoke;
"); getErrorString();
res := simulate(CoverageSmoke, stopTime = 1); getErrorString();
res.resultFile;
buildModelFMU(CoverageSmoke, version = "2.0", fmuType = "me_cs"); getErrorString();
EOF
../../build/bin/omc smoke.mos
'

do_test() {
  local c=$1 ws=$WORK/build-$c
  step "test $c: $ws at $TEST_ROOT, counters to $ws/gcda-out"
  [ -x "$ws/build/bin/omc" ] || { echo "No install tree; run 'build' first" >&2; exit 1; }
  rm -rf "$ws/gcda-out" "$ws/fmu-coverage"
  in_docker "$ws" "$TEST_ROOT" "
    ${TEST_CMD:-$DEFAULT_TEST}
  " -e GCOV_PREFIX="$TEST_ROOT/gcda-out" \
    -e OMC_COVERAGE_FMU_DIR="$TEST_ROOT/fmu-coverage" \
    -e OMCOMPILERGENERATEDSOURCES="$TEST_ROOT/build_cmake/OMCompiler/Compiler/generated-mo"
  # withCoverageCounters(): GCOV_PREFIX redirected the FMUs' counters too, so
  # move them back next to their notes.
  if [ -d "$ws/gcda-out$TEST_ROOT/fmu-coverage" ]; then
    mkdir -p "$ws/fmu-coverage"
    cp -a "$ws/gcda-out$TEST_ROOT/fmu-coverage/." "$ws/fmu-coverage/"
    rm -rf "$ws/gcda-out$TEST_ROOT/fmu-coverage"
  fi
  echo "$(find "$ws/gcda-out" -name '*.gcda' 2>/dev/null | wc -l) counter files," \
       "$(find "$ws/gcda-out" -path '*OpenModelicaCompiler.dir*' -name '*.gcda' 2>/dev/null | wc -l) of them the compiler's," \
       "and $(find "$ws/fmu-coverage" -name '*.gcda' 2>/dev/null | wc -l) of FMUs"
}

do_collect() {
  local c=$1 ws=$WORK/build-$c root
  root=$(build_root "$c")
  step "collect $c in $REPORT, at $root"
  [ -d "$REPORT/.git" ] || { echo "No report workspace; run 'sync' first" >&2; exit 1; }
  [ -d "$ws/gcda-out" ] || { echo "No counters for $c; run 'test' first" >&2; exit 1; }

  # What the stashes carry: coverage-<c>-gcno, coverage-<c>-sources and
  # coverage-counters-<name>.
  rm -rf "$REPORT/build_cmake" "$REPORT/counters"
  (cd "$ws" && find build_cmake -name '*.gcno' -print0 | tar --null -T - -cf -) | tar -C "$REPORT" -xf -
  (cd "$ws" && { find build_cmake/OMCompiler/Compiler/generated-mo -name '*.mo' -print0
                 printf '%s\0' OMCompiler/Compiler/Script/OpenModelicaScriptingAPI.mo \
                                OMCompiler/Compiler/Util/Autoconf.mo
                 find build_cmake/OMCompiler/Compiler/c_files -name '*.c' -print0
               } | tar --null -T - -cf -) | tar -C "$REPORT" -xf -
  mkdir -p "$REPORT/counters"
  (cd "$ws" && { find gcda-out -name '*.gcda' -print0
                 [ -d fmu-coverage ] && find fmu-coverage \( -name '*.gcno' -o -name '*.gcda' \) -print0
               } | tar --null -T - -cf -) | tar -C "$REPORT/counters" -xf -
  mkdir -p "$REPORT/coverage-tracefiles"
  echo "$root" > "$REPORT/.coverage-local-root"

  in_docker "$REPORT" "$root" "
    cmake -S . -B build_cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DOM_USE_CCACHE=OFF \
          -DCMAKE_INSTALL_PREFIX=build -DOM_ENABLE_COVERAGE=ON $(compiler_flags "$c") \
          '-DOM_COVERAGE_TRACEFILES=$root/coverage-tracefiles/*.json' \
          '-DOM_COVERAGE_TITLE=OpenModelica Code Coverage Report (local)' > /dev/null
    find build_cmake -name '*.gcda' -delete
    rm -rf build_cmake/coverage-fmu
    if [ -d 'counters/gcda-out$root/build_cmake' ]; then
      cp -a 'counters/gcda-out$root/build_cmake/.' build_cmake/
    else
      echo 'No counters under counters/gcda-out$root/build_cmake' >&2
    fi
    if [ -d counters/fmu-coverage ]; then
      mkdir -p build_cmake/coverage-fmu
      cp -a counters/fmu-coverage/. build_cmake/coverage-fmu/
    fi
    cmake --build build_cmake --target coverage-collect
    cp build_cmake/coverage/coverage.json coverage-tracefiles/local-$c-coverage.json
    cp build_cmake/coverage/templates.json coverage-tracefiles/local-$c-templates.json
  "
}

do_merge() {
  local root c=${COMPILER_LIST[-1]}
  # The build_cmake the last collect configured, if any.
  root=$(cat "$REPORT/.coverage-local-root" 2>/dev/null || build_root "$c")
  [ "$root" = "$(build_root clang)" ] && c=clang || c=gcc
  step "merge $REPORT/coverage-tracefiles/*.json, at $root"
  ls "$REPORT"/coverage-tracefiles/*.json > /dev/null
  in_docker "$REPORT" "$root" "
    cmake -S . -B build_cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DOM_USE_CCACHE=OFF \
          -DCMAKE_INSTALL_PREFIX=build -DOM_ENABLE_COVERAGE=ON $(compiler_flags "$c") \
          '-DOM_COVERAGE_TRACEFILES=$root/coverage-tracefiles/*.json' \
          '-DOM_COVERAGE_TITLE=OpenModelica Code Coverage Report (local)' > /dev/null
    cmake --build build_cmake --target coverage-html
  "
  echo "Report: $REPORT/build_cmake/coverage/index.html"
}

do_summary() {
  step "summary of $REPORT/coverage-tracefiles/*.json"
  python3 - "$REPORT"/coverage-tracefiles/*.json <<'EOF'
import collections, json, os, sys

def group(path):
    parts = path.split("/")
    if parts[0] == "build_cmake":
        return "build_cmake/.../generated-mo"
    if parts[:2] == ["OMCompiler", "Compiler"]:
        return "/".join(parts[:3])
    return "/".join(parts[:3]) if parts[0] == "OMCompiler" else parts[0] + "/" + parts[1]

for name in sys.argv[1:]:
    with open(name) as f:
        files = json.load(f).get("files", [])
    groups = collections.defaultdict(lambda: [0, 0])
    main_mo = None
    for entry in files:
        lines = entry["lines"]
        hit = sum(1 for l in lines if l["count"] > 0)
        g = groups[group(entry["file"])]
        g[0] += hit
        g[1] += len(lines)
        if entry["file"] == "OMCompiler/Compiler/Main/Main.mo":
            main_mo = (hit, len(lines))
    hit = sum(g[0] for g in groups.values())
    total = sum(g[1] for g in groups.values())
    print(f"\n{os.path.basename(name)}: {len(files)} files, "
          f"{hit}/{total} lines ({100 * hit / max(total, 1):.1f}%), "
          f"Main.mo: {'%d/%d lines' % main_mo if main_mo else 'missing'}")
    for key, (h, t) in sorted(groups.items(), key=lambda kv: -kv[1][1]):
        print(f"  {key:45s} {h:7d}/{t:7d} {100 * h / max(t, 1):5.1f}%")
EOF
}

needs_docker=0
for s in "${STEPS[@]}"; do
  case $s in build|test|collect|merge) needs_docker=1 ;; esac
done
if [ $needs_docker = 1 ] && [ $PULL = 1 ]; then
  step "pull $IMAGE"
  docker pull -q "$IMAGE"
fi

for s in "${STEPS[@]}"; do
  case $s in
    sync)    do_sync ;;
    merge)   do_merge ;;
    summary) do_summary ;;
    *)       for c in "${COMPILER_LIST[@]}"; do "do_$s" "$c"; done ;;
  esac
done
