"""Set a tunable parameter that is a divisor to zero and to another value (#4871).

usage: fmi_tunable_divisor.py <fmu> <output_txt>
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
    if v.name in ("tau", "c"):
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


def call(fn, *args):
    try:
        fn(*args)
        return "ok"
    except Exception:
        return "error"


def setr(f, name, value):
    return call(f.setFloat64 if v3 else f.setReal, [vr[name]], [value])


def getr(f, name):
    return (f.getFloat64 if v3 else f.getReal)([vr[name]])[0]


def cs(tau):
    f = instantiate(FMU3Slave if v3 else FMU2Slave, md.coSimulation)
    init(f)
    f.doStep(0.0, 1.0)
    status = setr(f, "tau", tau)
    step = call(f.doStep, 1.0, 1.0)
    say("CS set tau=%g: %s, doStep: %s" % (tau, status, step))
    if step == "ok":
        say("CS x(2)=%.4f c=%g" % (getr(f, "x"), getr(f, "c")))
    f.terminate()
    f.freeInstance()


def me(tau):
    f = instantiate(FMU3Model if v3 else FMU2Model, md.modelExchange)
    init(f)
    update = f.updateDiscreteStates if v3 else f.newDiscreteStates
    update()
    f.enterContinuousTimeMode()
    f.enterEventMode()
    status = setr(f, "tau", tau)
    events = call(update)
    say("ME set tau=%g in event mode: %s, event update: %s" % (tau, status, events))
    if events == "ok":
        n = md.numberOfContinuousStates
        dx = np.zeros(n)
        f.enterContinuousTimeMode()
        (f.getContinuousStateDerivatives if v3 else f.getDerivatives)(dx.ctypes.data_as(POINTER(c_double)), n)
        say("ME der(x)=%.4f" % dx[0])
    f.terminate()
    f.freeInstance()


cs(0.0)
cs(2.0)
me(0.0)
me(4.0)
out.close()
