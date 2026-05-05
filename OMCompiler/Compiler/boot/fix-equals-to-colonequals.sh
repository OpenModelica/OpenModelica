#!/usr/bin/env bash
# Iteratively fix '=' to ':=' in algorithms, as reported by omc parser errors.
# Usage: ./fix-equals-to-colonequals.sh [--apply]
#
# Without --apply: shows what would be fixed per iteration.
# With --apply: runs omc, parses errors, fixes each file in-place, repeats.
#
# The omc parser stops at the first error per file, so this loop is needed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OMC="${OMC:-/usr/bin/omc}"
OMC_LOG="$(mktemp)"
trap 'rm -f "$OMC_LOG"' EXIT

apply=false
if [[ "${1:-}" == "--apply" ]]; then
    apply=true
fi

total_fixes=0
iteration=0

while true; do
    iteration=$((iteration + 1))
    if $apply; then
        echo "=== Iteration $iteration ==="
    else
        echo "=== DRY RUN — Iteration $iteration ==="
    fi
    echo "Running: $OMC LoadCompilerSources.mos"

    "$OMC" LoadCompilerSources.mos > "$OMC_LOG" 2>&1 || true

    # Count parse errors (not "File does not exist", not other errors)
    parse_errors=$(grep -c 'Error: Parse error: Algorithms can not contain equations' "$OMC_LOG" || true)

    if [ "$parse_errors" -eq 0 ]; then
        echo "No more '=' parse errors found."
        break
    fi

    if ! $apply; then
        echo "Would fix $parse_errors errors in this iteration."
        # Show first few for visibility
        grep 'Error: Parse error: Algorithms can not contain equations' "$OMC_LOG" | head -5
        echo "... (total: $parse_errors)"
        break
    fi

    # Run the Python fixer for this iteration
    python3 - "$OMC_LOG" <<'PYEOF'
import sys, os, re
from collections import defaultdict

log_path = sys.argv[1]

errors = []
with open(log_path) as f:
    for line in f:
        m = re.match(
            r'^\[([^\]]+)\] Error: Parse error: Algorithms can not contain equations',
            line.strip(),
        )
        if not m:
            continue
        loc = m.group(1)
        path_match = re.match(r'^(/.+\.mo):(\d+):(\d+)-\d+:\d+', loc)
        if not path_match:
            continue
        path = path_match.group(1)
        line_num = int(path_match.group(2)) - 1
        col = int(path_match.group(3)) - 1

        if not os.path.isfile(path):
            continue

        with open(path) as f:
            text = f.read()
        lines = text.split('\n')
        if line_num < len(lines) and col < len(lines[line_num]) and lines[line_num][col] == '=':
            errors.append((path, line_num, col))
        else:
            ln = lines[line_num] if line_num < len(lines) else '<missing>'
            ch = ln[col] if col < len(ln) else '<newline>'
            print(f"SKIP {path}:{line_num+1}:{col+1}: got '{ch}' not '='", file=sys.stderr)

if not errors:
    sys.exit(0)

by_file = defaultdict(list)
for path, line_num, col in errors:
    by_file[path].append((line_num, col))

for path in sorted(by_file):
    fixes = sorted(by_file[path], key=lambda x: x[1], reverse=True)  # rightmost first
    with open(path) as f:
        text = f.read()
    lines = list(text.split('\n'))
    for line_num, col in fixes:
        lines[line_num] = lines[line_num][:col] + ':=' + lines[line_num][col+1:]
    with open(path, 'w') as f:
        f.write('\n'.join(lines))
    print(f"FIXED  {path} ({len(fixes)} fix{'es' if len(fixes) > 1 else ''})")

print(f"Total in this pass: {len(errors)} fix{'es' if len(errors) > 1 else ''} across {len(by_file)} files.", file=sys.stderr)
PYEOF

    pass_fixes=$?
    if [ $pass_fixes -ne 0 ]; then
        echo "Python fixer exited with error $pass_fixes"
        break
    fi

    total_fixes=$((total_fixes + parse_errors))
    if [ $iteration -gt 5000 ]; then
        echo "Max iterations (5000) reached. Stopping."
        break
    fi
done

if $apply; then
    echo ""
    echo "Done. Total parse errors fixed: $total_fixes across $iteration iteration(s)."
    echo ""
    # Verify
    "$OMC" LoadCompilerSources.mos > /tmp/omc_verify.txt 2>&1
    remaining=$(grep -c 'Error: Parse error: Algorithms' /tmp/omc_verify.txt || true)
    if [ "$remaining" -eq 0 ]; then
        echo "SUCCESS: All '=' parse errors fixed!"
    else
        echo "Remaining parse errors: $remaining (may need additional iterations or are different errors)"
    fi
fi
