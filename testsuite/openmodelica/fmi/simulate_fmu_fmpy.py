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
    simulate_fmu_fmpy.py [--set-states] <fmu> <output_csv> <stop_time> <var> [<var> ...]

With --set-states, a Model Exchange FMU gets its continuous states set again
after each step, one by one with fmi2SetReal or fmi3SetFloat64, as FMI 2.0.1
and later and FMI 3.0.2 allow in Continuous-Time Mode. The states with
initial="exact" or "approx" are also set to their start values before the
initialization, as FMI allows in Instantiated Mode.

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


def set_states_again(model_description):
    """A step_finished callback that sets each continuous state to its value."""
    vrs = [d.variable.derivative.valueReference for d in model_description.derivatives]

    def step_finished(time, recorder):
        fmu = recorder.fmu
        if model_description.fmiVersion.startswith("3"):
            fmu.setFloat64(vrs, fmu.getFloat64(vrs))
        else:
            fmu.setReal(vrs, fmu.getReal(vrs))
        return True

    return step_finished


def start_states(model_description):
    """The start values of the scalar continuous states that may be set before
    the initialization."""
    values = {}
    for d in model_description.derivatives:
        v = d.variable.derivative
        if v.initial in ("exact", "approx") and v.start is not None and not getattr(v, "dimensions", None):
            values[v.name] = float(v.start)
    return values


def main(argv):
    set_states = len(argv) > 1 and argv[1] == "--set-states"
    if set_states:
        argv = argv[:1] + argv[2:]
    if len(argv) < 5:
        sys.stderr.write(
            "usage: simulate_fmu_fmpy.py [--set-states] <fmu> <output_csv> <stop_time> "
            "<var> [<var> ...]\n")
        return 2

    fmu = argv[1]
    output_csv = argv[2]
    stop_time = float(argv[3])
    variables = argv[4:]

    # An element of an array variable is recorded through the array.
    model_description = read_model_description(fmu)
    dims = {}
    for v in model_description.modelVariables:
        if getattr(v, "dimensions", None):
            dims[v.name] = [int(d.start) for d in v.dimensions]
    outputs = []
    for name in variables:
        base = name.split("[")[0]
        recorded = base if base in dims else name
        if recorded not in outputs:
            outputs.append(recorded)

    options = {}
    if set_states:
        options = dict(fmi_type="ModelExchange", step_finished=set_states_again(model_description),
                       start_values=start_states(model_description))
    result = flatten_arrays(simulate_fmu(fmu, stop_time=stop_time, output=outputs, **options), dims)
    write_csv(output_csv, result)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
