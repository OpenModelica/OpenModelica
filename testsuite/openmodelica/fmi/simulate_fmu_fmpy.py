#!/usr/bin/env python3
"""Simulate an FMU with FMPy and write the trajectories to a CSV file.

This helper is used by the FMI 3.0 export tests to validate that an FMU
exported by OpenModelica, when simulated by an *independent* FMI importer
(FMPy), reproduces the results of OpenModelica's own (non-FMU) simulation.
The resulting CSV is compared against the OpenModelica reference results with
diffSimulationResults() from the .mos test.

FMPy is a required dependency of the FMI test suite; if it cannot be imported
or the simulation fails, the script exits with a non-zero status so the test
fails loudly instead of silently skipping the validation.

Usage:
    simulate_fmu_fmpy.py <fmu> <output_csv> <stop_time> <var> [<var> ...]

The variable names are the ones to record (and later compare against the
OpenModelica reference); they must be passed explicitly because FMPy's default
recorder only captures output variables, not continuous states such as 'x'.
"""
import sys

import numpy as np
from fmpy import read_model_description, simulate_fmu
from fmpy.util import write_csv


def flatten_arrays(result, dims):
    """One column per scalar element of an FMI 3.0 array variable, named as
    OpenModelica names the element (row major, 1-based: x[2], A[1,3]), so
    that arrays and scalarized variables compare alike."""
    names, columns = [], []
    for name in result.dtype.names:
        col = result[name]
        if name in dims and col.ndim == 2:
            for k in range(col.shape[1]):
                index = ",".join(str(i + 1) for i in np.unravel_index(k, dims[name]))
                names.append("%s[%s]" % (name, index))
                columns.append(col[:, k])
        else:
            names.append(name)
            columns.append(col)
    return np.rec.fromarrays(columns, names=names)


def main(argv):
    if len(argv) < 5:
        sys.stderr.write(
            "usage: simulate_fmu_fmpy.py <fmu> <output_csv> <stop_time> "
            "<var> [<var> ...]\n")
        return 2

    fmu = argv[1]
    output_csv = argv[2]
    stop_time = float(argv[3])
    variables = argv[4:]

    # An element of an array variable is recorded through the array.
    dims = {}
    for v in read_model_description(fmu).modelVariables:
        if getattr(v, "dimensions", None):
            dims[v.name] = [int(d.start) for d in v.dimensions]
    outputs = []
    for name in variables:
        base = name.split("[")[0]
        recorded = base if base in dims else name
        if recorded not in outputs:
            outputs.append(recorded)

    result = flatten_arrays(simulate_fmu(fmu, stop_time=stop_time, output=outputs), dims)
    write_csv(output_csv, result)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
