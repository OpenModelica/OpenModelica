"""Log categories of a C FMU with FMI 2.0 (#11500): fmi2SetDebugLogging enables
only the named categories, all of them without names or with logAll.

usage: fmi2_log_categories.py <fmu> <output_txt>
"""
import sys
from ctypes import byref

import fmpy.fmi2 as fmi2
from fmpy import extract, read_model_description

fmu = sys.argv[1]
out = open(sys.argv[2], "w")
md = read_model_description(fmu)
unzipdir = extract(fmu)
log = []


def logger(env, instance, status, category, message):
    log.append((category.decode() if category else "NULL", message.decode()))


callbacks = fmi2.fmi2CallbackFunctions()
callbacks.logger = fmi2.fmi2CallbackLoggerTYPE(logger)
callbacks.allocateMemory = fmi2.defaultCallbacks.allocateMemory
callbacks.freeMemory = fmi2.defaultCallbacks.freeMemory
fmi2.addLoggerProxy(byref(callbacks))


def run(title, loggingOn, calls, check):
    f = fmi2.FMU2Slave(guid=md.guid, unzipDirectory=unzipdir, modelIdentifier=md.coSimulation.modelIdentifier,
                       instanceName="i")
    f.instantiate(loggingOn=loggingOn, callbacks=callbacks)
    del log[:]
    for on, categories in calls:
        f.setDebugLogging(on, categories)
    f.setupExperiment(startTime=0.0)
    f.enterInitializationMode()
    f.exitInitializationMode()
    for i in range(10):
        f.doStep(0.1 * i, 0.1)
    f.terminate()
    f.freeInstance()
    logged = {c for c, _ in log}
    out.write(title + ":" + "".join(" %s=%s" % (c, c in logged) for c in check) + "\n")
    for c, m in log:
        if c in ("LOG_STDOUT", "logStatusWarning"):
            out.write("  %s: %s\n" % (c, m))


check = ["LOG_STDOUT", "LOG_SOLVER", "logEvents"]
run("logging off", False, [], check)
run("no names", True, [(False, []), (True, [])], check)
run("LOG_STDOUT, then logEvents", True, [(True, ["LOG_STDOUT"]), (True, ["logEvents"])], check)
run("logAll", True, [(False, []), (True, ["logAll"])], check)
run("unknown category", True, [(True, ["logStatusWarning", "noSuchCategory"])], check)
