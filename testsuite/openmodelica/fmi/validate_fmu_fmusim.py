#!/usr/bin/env python3
"""Validate (and optionally simulate) an FMU with the Reference-FMUs fmusim CLI.

This helper complements simulate_fmu_fmpy.py: FMPy checks that an exported FMU
*simulates* like OpenModelica's own run, while fmusim additionally checks the
modelDescription.xml against the consistency rules of the FMI specification
that the XML schema alone does not express -- most importantly that
<ModelStructure> lists exactly the right Output, ContinuousStateDerivative and
InitialUnknown variables. Those rules are what an importer relies on, so a
schema-valid FMU can still be rejected in practice.

fmusim is a separate tool (https://github.com/modelica/fmusim) that ships
prebuilt binaries; it is located through the FMUSIM environment variable or on
PATH. It is not bundled with OpenModelica.

Usage:
    validate_fmu_fmusim.py <fmu>
    validate_fmu_fmusim.py <fmu> --simulate <output_csv> --stop-time <t>
                                 [--variable <name> ...]
                                 [--reference-file <reference_csv>]

With --simulate the FMU is also run and the trajectories are written to
<output_csv>, so a .mos test can compare them against the OpenModelica
reference with diffSimulationResults(). Passing --reference-file instead lets
fmusim do the comparison itself.

Exits non-zero when fmusim is missing or reports a problem, so a test fails
loudly rather than silently skipping the validation -- the same policy as
simulate_fmu_fmpy.py. Pass --skip-if-missing to turn a missing fmusim into a
skip (exit 0); the test suite does not use it, it is there for ad-hoc local runs
on a machine without fmusim.
"""
import os
import shutil
import subprocess
import sys


def find_fmusim():
    """The fmusim executable from $FMUSIM or PATH, or None."""
    fmusim = os.environ.get("FMUSIM")
    if fmusim:
        return fmusim if os.path.isfile(fmusim) else None
    return shutil.which("fmusim")


def run(argv):
    """Run fmusim, echoing its output. True when it succeeded."""
    proc = subprocess.run(argv, capture_output=True, text=True)
    sys.stdout.write(proc.stdout)
    sys.stderr.write(proc.stderr)
    # fmusim reports validation problems on stdout and still exits 0 in some
    # versions, so treat any reported error as a failure as well.
    return proc.returncode == 0 and "error:" not in (proc.stdout + proc.stderr)


def main(argv):
    if len(argv) < 2:
        sys.stderr.write(__doc__)
        return 2

    fmu = argv[1]
    args = argv[2:]

    simulate_csv = None
    stop_time = None
    reference_file = None
    variables = []
    skip_if_missing = False

    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--skip-if-missing":
            skip_if_missing = True
        elif arg == "--simulate":
            i += 1
            simulate_csv = args[i]
        elif arg == "--stop-time":
            i += 1
            stop_time = args[i]
        elif arg == "--reference-file":
            i += 1
            reference_file = args[i]
        elif arg == "--variable":
            i += 1
            variables.append(args[i])
        else:
            sys.stderr.write("unknown argument: %s\n" % arg)
            return 2
        i += 1

    fmusim = find_fmusim()
    if fmusim is None:
        if skip_if_missing:
            print("fmusim not found: skipped")
            return 0
        sys.stderr.write(
            "fmusim not found. Install it from "
            "https://github.com/modelica/fmusim/releases and put it on PATH, "
            "or point the FMUSIM environment variable at the executable.\n")
        return 1

    if not run([fmusim, "validate", fmu]):
        sys.stderr.write("fmusim validate failed for %s\n" % fmu)
        return 1

    if simulate_csv is not None:
        argv = [fmusim, "simulate", fmu, "--output-file", simulate_csv]
        if stop_time is not None:
            argv += ["--stop-time", stop_time, "--set-stop-time"]
        if reference_file is not None:
            argv += ["--reference-file", reference_file]
        for variable in variables:
            argv += ["--output-variable", variable]
        if not run(argv):
            sys.stderr.write("fmusim simulate failed for %s\n" % fmu)
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
