#!/bin/bash
# Script to replace all "No viable alternative near token: equation" occurrences
# Runs iteratively until no more such errors remain

ITERATION=0

while true; do
    ERRORS=$(omc LoadCompilerSources.mos 2>&1 | grep "No viable alternative near token: equation")

    if [ -z "$ERRORS" ]; then
        echo "No more 'No viable alternative near token: equation' errors found."
        break
    fi

    ITERATION=$((ITERATION + 1))
    echo "=== Iteration $ITERATION ==="

    FIXED=0
    while IFS= read -r line; do
        # Extract file path and line number
        # Format: [/path/file.mo:LINE:COL-COL2:writable] Error: No viable alternative near token: equation
        FILEPATH=$(echo "$line" | sed -n 's|^\[\([^:]*\):\([0-9]*\):.*\].*Error: No viable alternative near token: equation|\1|p')
        LINENUM=$(echo "$line" | sed -n 's|^\[\([^:]*\):\([0-9]*\):.*\].*Error: No viable alternative near token: equation|\2|p')

        if [ -n "$FILEPATH" ] && [ -n "$LINENUM" ]; then
            RELPATH=${FILEPATH#$PWD/../../..}
            echo "  Fixing $RELPATH line $LINENUM"
            sed -i "${LINENUM}s/equation/algorithm/" "$RELPATH"
            FIXED=$((FIXED + 1))
        fi
    done <<< "$ERRORS"

    echo "  Fixed $FIXED occurrences in this iteration."

    # Safety: stop after 50 iterations to avoid infinite loops
    if [ $ITERATION -ge 50 ]; then
        echo "Safety limit reached (50 iterations)."
        break
    fi
done

echo "Done. Total iterations: $ITERATION"
