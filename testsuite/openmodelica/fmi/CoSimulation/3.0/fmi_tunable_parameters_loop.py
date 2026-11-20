"""Set a tunable parameter that feeds loops of parameters only (#1869).

usage: fmi_tunable_parameters_loop.py <fmu> <output_txt>
"""
import sys
from ctypes import POINTER, c_double

import numpy as np
from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Model, FMU2Slave
from fmpy.fmi3 import FMU3Model, FMU3Slave

fmu = sys.argv[1]
out = open(sys.argv[2], "w")
md = read_model_description(fmu)
unzipdir = extract(fmu)
v3 = md.fmiVersion.startswith("3")
vr = {v.name: v.valueReference for v in md.modelVariables}


def say(line):
    out.write(line + "\n")


for v in md.modelVariables:
    if v.name == "k":
        say("%s: %s %s" % (v.name, v.causality, v.variability))


def instantiate(cls, ident):
    f = cls(guid=md.guid, unzipDirectory=unzipdir, modelIdentifier=ident.modelIdentifier, instanceName="i")
    f.instantiate()
    if not v3:
        f.setupExperiment(startTime=0)
    return f


def init(f):
    if v3:
        f.enterInitializationMode(startTime=0)
    else:
        f.enterInitializationMode()
    f.exitInitializationMode()


def setr(f, name, value):
    (f.setFloat64 if v3 else f.setReal)([vr[name]], [value])


def get(f, fmt, *names):
    return " ".join(("%s=" + fmt) % (n, (f.getFloat64 if v3 else f.getReal)([vr[n]])[0]) for n in names)


def cs():
    f = instantiate(FMU3Slave if v3 else FMU2Slave, md.coSimulation)
    init(f)
    t, h = 0.0, 0.5
    while t < 10.0:
        if t == 5.0:
            say("CS k=1: " + get(f, "%.6f", "z", "w"))
            setr(f, "k", 2.0)
            say("CS set k=2: " + get(f, "%.6f", "z", "w"))
        f.doStep(t, h)
        t += h
    say("CS end: " + get(f, "%.6f", "z", "w") + " " + get(f, "%.4f", "T"))
    f.terminate()
    f.freeInstance()


def me():
    f = instantiate(FMU3Model if v3 else FMU2Model, md.modelExchange)
    init(f)

    def event_iteration():
        while (f.updateDiscreteStates() if v3 else f.newDiscreteStates())[0]:
            pass

    event_iteration()
    f.enterContinuousTimeMode()
    n = md.numberOfContinuousStates
    x, dx = np.zeros(n), np.zeros(n)
    px, pdx = x.ctypes.data_as(POINTER(c_double)), dx.ctypes.data_as(POINTER(c_double))
    h = 0.01
    for i in range(1000):
        if i == 500:
            f.enterEventMode()
            setr(f, "k", 2.0)
            event_iteration()
            say("ME set k=2 in event mode: " + get(f, "%.6f", "z", "w"))
            f.enterContinuousTimeMode()
        f.getContinuousStates(px, n)
        (f.getContinuousStateDerivatives if v3 else f.getDerivatives)(pdx, n)
        f.setTime((i + 1) * h)
        x[:] = x + h * dx
        f.setContinuousStates(px, n)
        f.completedIntegratorStep()
    say("ME end: " + get(f, "%.6f", "z", "w") + " " + get(f, "%.4f", "T"))
    f.terminate()
    f.freeInstance()


cs()
me()
out.close()
