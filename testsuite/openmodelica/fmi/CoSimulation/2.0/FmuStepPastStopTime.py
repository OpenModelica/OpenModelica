"""Step as the master example of the FMI 2.0 specification does, t += h while
t < stopTime, then one step more, and write the status of each step and the
messages the logger got in category logStatusError.

usage: FmuStepPastStopTime.py <fmu> <output_txt>
"""
import sys
from ctypes import byref

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Slave, defaultCallbacks, fmi2CallbackFunctions, fmi2CallbackLoggerTYPE
from fmpy.logging import addLoggerProxy


def main(fmu, output):
    md = read_model_description(fmu)
    s = FMU2Slave(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    lines = []

    def logger(env, instance, status, category, message):
        if category == b"logStatusError":
            lines.append("status %d: %s" % (status, message.decode()))

    callbacks = fmi2CallbackFunctions()
    callbacks.logger = fmi2CallbackLoggerTYPE(logger)
    callbacks.allocateMemory = defaultCallbacks.allocateMemory
    callbacks.freeMemory = defaultCallbacks.freeMemory
    addLoggerProxy(byref(callbacks))
    s.instantiate(callbacks=callbacks, loggingOn=True)
    s.setupExperiment(startTime=0.0, stopTime=0.3)
    s.enterInitializationMode()
    s.exitInitializationMode()
    def step(t, h):
        try:
            s.doStep(currentCommunicationPoint=t, communicationStepSize=h)
            lines.append("doStep(%r, %r): OK" % (t, h))
        except Exception as e:
            lines.append("doStep(%r, %r): %s" % (t, h, e))

    t, h = 0.0, 0.1
    while t < 0.3:
        step(t, h)
        t += h
    step(t, h)
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
