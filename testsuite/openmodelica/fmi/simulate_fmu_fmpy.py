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

from fmpy import simulate_fmu
from fmpy.util import write_csv


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

    result = simulate_fmu(fmu, stop_time=stop_time, output=variables)
    write_csv(output_csv, result)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
