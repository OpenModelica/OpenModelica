#!/usr/bin/env bash
#
# Check that the .deb packages a build produced upgrade an existing OpenModelica
# installation, in a throwaway container.
#
# The packages of the CMake build replace the ones the Autoconf packaging produced, and the
# two layouts do not have the same set of packages: nine of the old ones (the libomc/omc-common
# library split) have no counterpart here, and four of the new ones (simrt, simrtcpp, omsens,
# omoptim) did not exist before. Whether an installed system crosses that gap is decided
# entirely by control fields -- Provides/Replaces/Conflicts and the inter-package Depends --
# which nothing in the build itself exercises. So: install the published nightly, drop this
# build's packages in as a local apt repository, and upgrade.
#
# The old packages install under /usr and the new ones under /usr/local, so there is no file
# overlap between them at all. Conflicts, not Replaces, is what removes the old ones.
#
# Usage:
#   cmake/packaging/test-deb-upgrade.sh [deb-dir]
#
#   deb-dir   Directory holding the .deb files to test. Defaults to the _packages directory
#             of the build tree this script is run from (build_cmake/_packages).
#
# Environment:
#   OM_CODENAME  Ubuntu/Debian release to test on, and the apt suite to install from.
#                Must be one of the suites under https://build.openmodelica.org/apt/dists/.
#                Default: resolute
#   OM_CHANNEL   Which published packages the container starts out with: nightly, stable
#                or release. Default: nightly
#   OM_MODE      upgrade (the default) or full-upgrade. See the note printed with the result:
#                apt-get upgrade is by definition not allowed to remove a package, so it
#                cannot act on a Conflicts, while full-upgrade can.
#   OM_KEEP      Set to 1 to keep the container after the run for poking around.
#
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SOURCE_DIR=$(cd -- "${SCRIPT_DIR}/../.." && pwd)

DEB_DIR=${1:-${SOURCE_DIR}/build_cmake/_packages}
CODENAME=${OM_CODENAME:-resolute}
CHANNEL=${OM_CHANNEL:-nightly}
MODE=${OM_MODE:-upgrade}
KEEP=${OM_KEEP:-0}

case "${MODE}" in
  upgrade|full-upgrade) ;;
  *) echo "OM_MODE must be 'upgrade' or 'full-upgrade', not '${MODE}'" >&2; exit 2 ;;
esac

DEB_DIR=$(cd -- "${DEB_DIR}" && pwd) || { echo "No such directory: ${1:-}" >&2; exit 2; }
if ! compgen -G "${DEB_DIR}/*.deb" > /dev/null; then
  echo "No .deb files in ${DEB_DIR}." >&2
  echo "Build them first:  cpack -G DEB --config <build dir>/CPackConfig.cmake" >&2
  exit 2
fi

IMAGE="om-upgrade-base:${CODENAME}-${CHANNEL}"
WORK=$(mktemp -d)
trap 'rm -rf "${WORK}"' EXIT

echo "=== Packages under test ============================================================"
for f in "${DEB_DIR}"/*.deb; do
  printf '  %-22s %s\n' "$(dpkg-deb -f "$f" Package)" "$(dpkg-deb -f "$f" Version)"
done

## The starting point: a machine with the published packages installed ############################
# Built once and then cached by Docker, because it is the slow part -- OMEdit pulls in most of
# Qt 6. Delete the image to force it to be rebuilt against a newer nightly.
#
# Every package of the old layout is installed, but its *recommends* are not: a plain
# `apt-get install openmodelica` also pulls in TeX Live, gnuplot and a terminal emulator, none
# of which has anything to do with the upgrade under test, and which between them roughly
# double the size of the image.
#
# What each package is marked as matters more than it looks, because apt treats the two
# completely differently: it will remove an automatically installed package to satisfy a
# Conflicts, and it will not remove a manually installed one -- it keeps the conflicting
# upgrade back instead. So the marks here have to be the ones a real machine would have.
#
#   libomccpp   a Recommends of omc, so apt would have installed it by itself -> auto.
#   omlibrary   nothing in the old layout depends on or recommends it (the metapackage does
#               not list it), so a machine that has it has it because someone asked -> manual.
#   libomc-dev, libomplot-dev
#               likewise nothing pulls these in; they are there because someone wanted the
#               headers -> manual. They are the interesting case, and the one that fails:
#               the new omc conflicts with libomc-dev and the new omplot with libomplot-dev,
#               and apt will not remove either to make room.
cat > "${WORK}/Dockerfile" <<EOF
FROM ubuntu:${CODENAME}
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -qy --no-install-recommends ca-certificates curl gnupg dpkg-dev && \
    curl -fsSL https://build.openmodelica.org/apt/openmodelica.asc \
      | gpg --dearmor -o /usr/share/keyrings/openmodelica-keyring.gpg && \
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/openmodelica-keyring.gpg] https://build.openmodelica.org/apt ${CODENAME} ${CHANNEL}' \
      > /etc/apt/sources.list.d/openmodelica.list && \
    apt-get update && \
    apt-get install -qy --no-install-recommends \
        openmodelica omlibrary libomccpp libomc-dev libomplot-dev && \
    apt-mark auto libomccpp > /dev/null && \
    rm -rf /var/lib/apt/lists/*
EOF

if docker image inspect "${IMAGE}" > /dev/null 2>&1; then
  echo
  echo "=== Base image ${IMAGE} already present (delete it to refresh) ==="
else
  echo
  echo "=== Building base image ${IMAGE} (installs the published ${CHANNEL}; this is slow) ==="
  docker build --progress=plain -t "${IMAGE}" "${WORK}"
fi

## The test itself, run inside the container ######################################################
cat > "${WORK}/run-test.sh" <<'INNER'
#!/bin/bash
set -u
export DEBIAN_FRONTEND=noninteractive
MODE=$1

# Every package name either layout uses, so a package is not missed by listing only one set.
OM_PKGS="drcontrol drmodelica libomc libomc-dev libomccpp libomcsimulation libomplot
libomplot-dev libomsensplugin libomsimulator omc-common omc omedit omlibrary omnotebook
omplot omshell-terminal omshell omsimulator openmodelica simrt simrtcpp omsens omoptim"

# The nine packages of the old layout that nothing in the new one is named after. These are
# what has to disappear; everything else is upgraded in place under the same name.
OLD_ONLY="libomc libomc-dev libomccpp libomcsimulation libomplot libomplot-dev
libomsensplugin libomsimulator omc-common"

om_state() {
  for p in $OM_PKGS; do
    s=$(dpkg-query -W -f='${Version}\t${Status}' "$p" 2>/dev/null) || continue
    case "$s" in *"install ok installed"*) ;; *) continue ;; esac
    m=$(apt-mark showmanual "$p" 2>/dev/null | grep -qx "$p" && echo manual || echo auto)
    printf '  %-20s %-34s %s\n' "$p" "${s%%	*}" "$m"
  done
}

echo
echo "=== 1. Before: the published packages this machine already has ====================="
om_state

echo
echo "=== 2. Offer this build's packages as a local apt repository ======================="
# /debs is mounted read-only, so the index goes next to a copy rather than beside the
# originals. apt reads a file: repository straight out of the directory; no server needed.
mkdir -p /localrepo
cp /debs/*.deb /localrepo/
cd /localrepo
dpkg-scanpackages . /dev/null > Packages 2>/dev/null
gzip -9cf Packages > Packages.gz
echo "deb [trusted=yes] file:/localrepo ./" > /etc/apt/sources.list.d/om-local.list
apt-get update -qq
echo "  $(grep -c '^Package:' Packages) packages offered from /localrepo"

echo
echo "=== 3. apt-get $MODE ==============================================================="
apt-get "$MODE" -y 2>&1 | tail -n 45

echo
echo "=== 4. After apt-get $MODE ========================================================="
om_state

echo
echo "=== 5. apt-get autoremove =========================================================="
apt-get autoremove -y 2>&1 | tail -n 25

echo
echo "=== 6. After autoremove ============================================================"
om_state

echo
echo "=== 7. Result ======================================================================"
rc=0

left=""
for p in $OLD_ONLY; do
  dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed" && left="$left $p"
done
if [ -n "$left" ]; then
  echo "  FAIL  packages of the old layout still installed:$left"
  rc=1
else
  echo "  ok    every superseded package of the old layout is gone"
fi

# Nothing may be left half-configured, and no dependency may be unsatisfied.
if dpkg -C 2>&1 | grep -q .; then
  echo "  FAIL  dpkg reports broken packages:"; dpkg -C 2>&1 | sed 's/^/        /'
  rc=1
else
  echo "  ok    no broken or half-configured packages"
fi

# Whatever is still installed must be at this build's version, not the published one.
stale=$(for p in $OM_PKGS; do
          v=$(dpkg-query -W -f='${Version}' "$p" 2>/dev/null) || continue
          dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed" || continue
          [ "$v" = "$NEWVER" ] || echo "$p($v)"
        done | tr '\n' ' ')
if [ -n "$stale" ]; then
  echo "  FAIL  not upgraded to $NEWVER: $stale"
  rc=1
else
  echo "  ok    every installed OpenModelica package is at $NEWVER"
fi

if command -v omc > /dev/null; then
  echo "  ok    omc on PATH at $(command -v omc): $(omc --version 2>&1 | head -1)"
else
  echo "  FAIL  omc is not on PATH"
  rc=1
fi

echo
[ $rc -eq 0 ] && echo "  PASS" || echo "  FAIL"
exit $rc
INNER
chmod +x "${WORK}/run-test.sh"

# The version every package is expected to end up at, taken from the packages themselves.
NEWVER=$(dpkg-deb -f "$(ls -1 "${DEB_DIR}"/*.deb | head -1)" Version)

echo
echo "=== Running the upgrade (apt-get ${MODE}) on ${CODENAME}/${CHANNEL} ==="
RM_FLAG=(--rm)
[ "${KEEP}" = "1" ] && RM_FLAG=()

set +e
docker run "${RM_FLAG[@]}" \
  -e NEWVER="${NEWVER}" \
  -v "${DEB_DIR}":/debs:ro \
  -v "${WORK}/run-test.sh":/run-test.sh:ro \
  "${IMAGE}" bash /run-test.sh "${MODE}"
rc=$?
set -e

echo
if [ ${rc} -ne 0 ] && [ "${MODE}" = "upgrade" ]; then
  cat <<'NOTE'
Note: `apt-get upgrade` is documented never to remove an installed package. A package of this
build that Conflicts with one of the old layout therefore cannot be acted on, and apt holds it
back instead. That is apt working as specified, not a defect in the packages -- but it does
mean plain `apt-get upgrade` is not enough to cross this layout change. Re-run with
OM_MODE=full-upgrade to see what a user who runs `apt full-upgrade` (or `apt-get dist-upgrade`)
gets.
NOTE
fi

exit ${rc}
