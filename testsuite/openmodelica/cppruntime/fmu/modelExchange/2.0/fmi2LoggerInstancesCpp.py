"""Use two instances of an FMI 2.0 Model Exchange FMU in one process. Each
instance logs a model warning. Write which instance name the logger got
for each warning, also after the other instance is freed.

usage: fmi2LoggerInstancesCpp.py <fmu> <output_txt>
"""
import sys
from ctypes import byref

from fmpy import extract, read_model_description
from fmpy.fmi2 import (FMU2Model, calloc, free, fmi2CallbackFunctions,
                       fmi2CallbackLoggerTYPE, fmi2CallbackAllocateMemoryTYPE,
                       fmi2CallbackFreeMemoryTYPE, fmi2Real)
from fmpy.logging import addLoggerProxy

received = []


def logger(env, instanceName, status, category, message):
    if b"x is above" in message:
        received.append(instanceName.decode())


callbacks = fmi2CallbackFunctions()
callbacks.logger = fmi2CallbackLoggerTYPE(logger)
callbacks.allocateMemory = fmi2CallbackAllocateMemoryTYPE(calloc)
callbacks.freeMemory = fmi2CallbackFreeMemoryTYPE(free)
# the FMPy proxy formats message with vsnprintf and the variadic arguments
addLoggerProxy(byref(callbacks))


def main(fmu, output):
    md = read_model_description(fmu)
    unzipdir = extract(fmu)
    inst = {}
    for name in ("a", "b"):
        m = FMU2Model(guid=md.guid, unzipDirectory=unzipdir, instanceName=name,
                      modelIdentifier=md.modelExchange.modelIdentifier)
        m.instantiate(callbacks=callbacks, loggingOn=True)
        m.setupExperiment(startTime=0.0)
        m.enterInitializationMode()
        m.exitInitializationMode()
        inst[name] = m
    out = open(output, "w")
    x, dx = (fmi2Real * 1)(), (fmi2Real * 1)()

    def warn(name, what):
        del received[:]
        m = inst[name]
        x[0] = 0.6
        m.setContinuousStates(x, 1)
        m.getDerivatives(dx, 1)
        # write each line at once: a crash must not hide the lines before it
        out.write("%s: warning received for %s\n" % (what, ", ".join(received) or "none"))
        out.flush()

    warn("a", "a")
    warn("b", "b")
    inst["b"].freeInstance()
    warn("a", "a after b was freed")
    inst["a"].freeInstance()
    out.close()


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
