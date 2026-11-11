"""Solver messages of a C FMU (#11500): a warning that a simulation shows in
LOG_STDOUT, but which is about a singular linear system, goes to
logSingularLinearSystems, and not to logStatusWarning.

usage: fmi3_log_solver_warning.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Slave

fmu = sys.argv[1]
out = open(sys.argv[2], "w")
md = read_model_description(fmu)
unzipdir = extract(fmu)
log = []
# The messages about the singular system that every runtime gives.
SHOWN = ("Failed to solve linear system", "The default linear solver fails")


def logMessage(env, status, category, message):
    log.append((category.decode() if category else "NULL", status, message.decode()))


def run(categories):
    f = FMU3Slave(guid=md.guid, unzipDirectory=unzipdir, modelIdentifier=md.coSimulation.modelIdentifier, instanceName="i")
    f.instantiate(loggingOn=True, logMessage=logMessage)
    f.setDebugLogging(False, [])
    f.setDebugLogging(True, categories)
    del log[:]
    f.enterInitializationMode()
    f.exitInitializationMode()
    for i in range(10):
        f.doStep(0.1 * i, 0.1)
    f.terminate()
    f.freeInstance()
    out.write(" ".join(categories) + ":\n")
    for p in SHOWN:
        for c, s, m in log:
            if m.startswith(p):
                out.write("  %s, status %d: %s\n" % (c, s, m.splitlines()[0]))
                break


run(["logStatusWarning", "logStatusError"])
run(["logSingularLinearSystems"])
