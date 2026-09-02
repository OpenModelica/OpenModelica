# OMPlot

Plots result files and compares two of them the way `diffSimulationResults`
does, in the browser. Nothing is uploaded: the files are read by
`openmodelica_result_web.wasm`, a small module built from
`openmodelica_result_files` (the CSV/PLT readers, the MATLAB v4 reader and the
tube comparison omc itself uses) that needs no compiler. The charts are the
same `../plot.js` the simulator pages draw with.

## Query parameters

| parameter | |
| --- | --- |
| `result=<url>` and `reference=<url>` | fetch both and compare, `result` against `reference` |
| `var=<name>` | the variable to show first (defaults to the first differing one) |
| `relTol`, `relTolDiffMinMax`, `rangeDelta` | the tolerances, with `diffSimulationResults`'s defaults |
| `file=<url>` (repeatable) | just load files to plot |

A page such as an OpenModelicaLibraryTesting report can link straight to
`omplot/index.html?result=…&reference=…` and get the comparison of every
variable, with the tube plot per variable, without generating any HTML or CSV
of its own; the URLs must be fetchable from the page's origin (same host, or
CORS).

## Zoom

Drag a box on a chart: a mostly horizontal drag zooms the time axis, a mostly
vertical one the value axis. Ctrl/⌘ + wheel zooms time around the cursor.
Double-click or right-click resets. The error chart follows the time zoom of
the chart above it. This lives in `../plot.js`, so the simulator pages zoom the
same way.

## Files

Open `.mat`, `.csv` and `.plt` with the button or by dropping them on the page.
The save button writes the selected file back out as `.mat` or `.csv`, all
variables or the ticked ones, optionally resampled onto equidistant intervals —
which also converts a Modelica Association CSV reference to `.mat`.
