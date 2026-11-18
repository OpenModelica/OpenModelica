"""Run an FMI 2.0 Model Exchange FMU with a logger that formats the message
with printf, as FMI 2.0 allows. The model has two asserts whose texts
contain "%s". Write the status of fmi2GetDerivatives and the formatted
warning and error messages.

usage: fmi2LogFormatCpp.py <fmu> <output_txt>
"""
import sys
from ctypes import byref

from fmpy import extract, read_model_description
from fmpy.fmi2 import (FMU2Model, calloc, free, fmi2CallbackFunctions,
                       fmi2CallbackLoggerTYPE, fmi2CallbackAllocateMemoryTYPE,
                       fmi2CallbackFreeMemoryTYPE, fmi2Real)
from fmpy.logging import addLoggerProxy

messages = []


def logger(env, instanceName, status, category, message):
    # status 1 = fmi2Warning, 3 = fmi2Error
    if status in (1, 3):
        messages.append("status %d: %s" % (status, message.decode(errors="backslashreplace")))


def main(fmu, output):
    md = read_model_description(fmu)
    m = FMU2Model(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.modelExchange.modelIdentifier)
    callbacks = fmi2CallbackFunctions()
    callbacks.logger = fmi2CallbackLoggerTYPE(logger)
    callbacks.allocateMemory = fmi2CallbackAllocateMemoryTYPE(calloc)
    callbacks.freeMemory = fmi2CallbackFreeMemoryTYPE(free)
    # the FMPy proxy formats message with vsnprintf and the variadic arguments
    addLoggerProxy(byref(callbacks))
    m.instantiate(callbacks=callbacks, loggingOn=True)
    m.setupExperiment(startTime=0.0)
    m.enterInitializationMode()
    m.exitInitializationMode()
    lines = []
    x, dx = (fmi2Real * 1)(), (fmi2Real * 1)()
    for xv in (0.6, 0.9):
        del messages[:]
        x[0] = xv
        m.setTime(xv)
        m.setContinuousStates(x, 1)
        status = m.dll.fmi2GetDerivatives(m.component, dx, 1)
        lines.append("x = %g: fmi2GetDerivatives status %d" % (xv, status))
        lines += messages
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
