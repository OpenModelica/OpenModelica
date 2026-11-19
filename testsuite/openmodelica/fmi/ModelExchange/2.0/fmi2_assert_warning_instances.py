"""Two instances of one FMI 2.0 Model Exchange FMU in one process. A
function of the model has an assert with AssertionLevel.warning. Write which
instance got the warning when each instance violates it, when an instance
violates it again, and after fmi2Reset.
usage: fmi2_assert_warning_instances.py <fmu> <output_txt>
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
    if b"x is above 0.5" in message:
        received.append(instanceName.decode())


callbacks = fmi2CallbackFunctions()
callbacks.logger = fmi2CallbackLoggerTYPE(logger)
callbacks.allocateMemory = fmi2CallbackAllocateMemoryTYPE(calloc)
callbacks.freeMemory = fmi2CallbackFreeMemoryTYPE(free)
# the FMPy proxy formats message with vsnprintf and the variadic arguments
addLoggerProxy(byref(callbacks))


def initialize(m):
    m.setupExperiment(startTime=0.0)
    m.enterInitializationMode()
    m.exitInitializationMode()
    m.enterEventMode()
    m.newDiscreteStates()
    m.enterContinuousTimeMode()


def main(fmu, output):
    md = read_model_description(fmu)
    unzipdir = extract(fmu)
    vr_y = [v.valueReference for v in md.modelVariables if v.name == "y"]
    inst = {}
    for name in ("a", "b"):
        m = FMU2Model(guid=md.guid, unzipDirectory=unzipdir, instanceName=name,
                      modelIdentifier=md.modelExchange.modelIdentifier)
        m.instantiate(callbacks=callbacks, loggingOn=True)
        initialize(m)
        inst[name] = m
    out = open(output, "w")
    x = (fmi2Real * 1)()
    x[0] = 0.6

    def violate(name, what):
        del received[:]
        m = inst[name]
        m.setTime(0.6)
        m.setContinuousStates(x, 1)
        m.getReal(vr_y)
        # write each line at once: a crash must not hide the lines before it
        out.write("%s: warning received for %s\n" % (what, ", ".join(received) or "none"))
        out.flush()

    violate("a", "a")
    violate("b", "b")
    violate("a", "a again")
    inst["a"].reset()
    initialize(inst["a"])
    violate("a", "a after fmi2Reset")
    for m in inst.values():
        m.freeInstance()
    out.close()


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
