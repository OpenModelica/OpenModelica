"""Simulate the FMU to <stop> s in steps of 0.1 s with all log categories on, and
write where it stopped and the messages the logger got in category
logStatusError.

usage: FmuEquationAssertLog.py <fmu> <stop> <output_txt>
"""
import sys
from ctypes import byref

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Slave, defaultCallbacks, fmi2CallbackFunctions, fmi2CallbackLoggerTYPE
from fmpy.logging import addLoggerProxy


def main(fmu, stop, output):
    md = read_model_description(fmu)
    s = FMU2Slave(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    errors = []

    def logger(env, instance, status, category, message):
        if category == b"logStatusError":
            errors.append("status %d: %s" % (status, message.decode()))

    callbacks = fmi2CallbackFunctions()
    callbacks.logger = fmi2CallbackLoggerTYPE(logger)
    callbacks.allocateMemory = defaultCallbacks.allocateMemory
    callbacks.freeMemory = defaultCallbacks.freeMemory
    addLoggerProxy(byref(callbacks))
    s.instantiate(callbacks=callbacks, loggingOn=True)
    s.setupExperiment(startTime=0.0)
    t = 0.0
    try:
        s.enterInitializationMode()
        s.exitInitializationMode()
        while t < stop - 1e-9:
            s.doStep(currentCommunicationPoint=t, communicationStepSize=0.1)
            t += 0.1
    except Exception:
        pass
    with open(output, "w") as f:
        f.write("stopped at t = %g\n" % t)
        f.writelines(m + "\n" for m in errors)


if __name__ == "__main__":
    main(sys.argv[1], float(sys.argv[2]), sys.argv[3])
