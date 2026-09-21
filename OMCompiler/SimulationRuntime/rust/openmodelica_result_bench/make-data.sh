#!/bin/sh
# Simulate the models the benchmark reads and leave the result files in one
# directory, outside any working tree.
#
#     ./make-data.sh [directory] [model ...]
#
# With no model names it makes all of them. Each model leaves a `<name>_res.mat`
# and the `<name>_init.xml` beside it: the benchmark needs both, because a
# `.mat` records no units and no types and the other three formats would then
# have no metadata to be compared on.
#
# omc comes from $OMC, or the first one on the path.

set -e

OUT=${1:-/projects/result-bench-data}
[ $# -gt 0 ] && shift
OMC=${OMC:-omc}

command -v "$OMC" >/dev/null || { echo "no omc: set \$OMC" >&2; exit 1; }
mkdir -p "$OUT"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# name|library|version|stopTime|intervals - the three shapes the report needs:
# small, wide and short, narrow and tall.
MODELS='
BouncingBall||||
Modelica.Mechanics.MultiBody.Examples.Systems.RobotR3.FullRobot|Modelica|4.1.0||
Buildings.ThermalZones.Detailed.Validation.LBNL_71T.RoomB.ElectroChromicWindow|Buildings|12.1.1||
'

want() {
    [ $# -eq 0 ] && return 0
    case " $WANTED " in *" $1 "*) return 0;; esac
    return 1
}
WANTED=$*

# BouncingBall is written out rather than loaded, so the small case does not
# depend on a library being installed.
cat > "$WORK/BouncingBall.mo" <<'MO'
model BouncingBall
  parameter Real e = 0.7 "coefficient of restitution";
  parameter Real g = 9.81 "gravity acceleration";
  Real h(start = 1, fixed = true) "height of ball";
  Real v(fixed = true) "velocity of ball";
  Boolean flying(start = true) "true, if ball is flying";
  Boolean impact;
  Real v_new(fixed = true);
  Integer foo;
equation
  impact = h <= 0.0;
  foo = if impact then 1 else 2;
  der(v) = if flying then -g else 0;
  der(h) = v;
  when {h <= 0.0 and v <= 0.0, impact} then
    v_new = if edge(impact) then -e * pre(v) else 0;
    flying = v_new > 0;
    reinit(v, v_new);
  end when;
end BouncingBall;
MO

for entry in $MODELS; do
    name=$(echo "$entry" | cut -d'|' -f1)
    library=$(echo "$entry" | cut -d'|' -f2)
    version=$(echo "$entry" | cut -d'|' -f3)
    stop=$(echo "$entry" | cut -d'|' -f4)
    intervals=$(echo "$entry" | cut -d'|' -f5)
    want "$name" || continue

    script="$WORK/$name.mos"
    : > "$script"
    if [ -n "$library" ]; then
        # Only fetch the library if it is not there: the library directory is
        # shared with other sessions and adding to it changes what they load.
        cat >> "$script" <<EOF
if not loadModel($library, {"$version"}) then
  if not installPackage($library, "$version") then
    print("cannot install $library $version\n"); exit(1);
  end if;
  loadModel($library, {"$version"});
end if;
EOF
    else
        echo 'loadFile("BouncingBall.mo"); getErrorString();' >> "$script"
    fi
    flags=""
    [ -n "$stop" ] && flags="$flags, stopTime=$stop"
    [ -n "$intervals" ] && flags="$flags, numberOfIntervals=$intervals"
    # `simulate(...)` prints its record; a script variable cannot be indexed
    # into (`r.resultFile` is not in scope), so the outcome is read off the
    # files it left rather than out of the record.
    cat >> "$script" <<EOF
simulate($name$flags);
getErrorString();
EOF

    echo "simulating $name"
    (cd "$WORK" && "$OMC" "$script") || { echo "$name failed" >&2; exit 1; }
    for suffix in _res.mat _init.xml; do
        [ -f "$WORK/$name$suffix" ] || { echo "$name$suffix not produced" >&2; exit 1; }
        mv "$WORK/$name$suffix" "$OUT/"
    done
done

echo
ls -la "$OUT"
