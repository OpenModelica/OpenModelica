"""Set tunable parameters of an FMU while it runs (#17652).

usage: fmi_tunable_parameters.py <fmu> <output_txt>
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
STOP, CHANGE = 20000.0, 1000.0


def say(line):
    out.write(line + "\n")

for v in md.modelVariables:
    if v.name in ("R_set", "R", "C", "k", "q", "s"):
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
    try:
        (f.setFloat64 if v3 else f.setReal)([vr[name]], [value])
        return "ok"
    except Exception:
        return "error"


def getr(f, name):
    return (f.getFloat64 if v3 else f.getReal)([vr[name]])[0]


def cs(change=None):
    f = instantiate(FMU3Slave if v3 else FMU2Slave, md.coSimulation)
    init(f)
    t, h, status = 0.0, 100.0, "-"
    while t < STOP:
        if change and t == CHANGE:
            status = setr(f, *change)
        f.doStep(t, h)
        t += h
    say("CS set %s=%g: %s, T=%.2f R=%g" % (change + (status, getr(f, "T"), getr(f, "R"))))
    f.terminate()
    f.freeInstance()


def me(change):
    f = instantiate(FMU3Model if v3 else FMU2Model, md.modelExchange)
    init(f)

    def event_iteration():
        while (f.updateDiscreteStates() if v3 else f.newDiscreteStates())[0]:
            pass

    event_iteration()
    f.enterContinuousTimeMode()
    status_ct = setr(f, *change)
    n = md.numberOfContinuousStates
    x, dx = np.zeros(n), np.zeros(n)
    px, pdx = x.ctypes.data_as(POINTER(c_double)), dx.ctypes.data_as(POINTER(c_double))
    t, h, status = 0.0, 5.0, "-"
    while t < STOP:
        if t == CHANGE:
            f.enterEventMode()
            status = setr(f, *change)
            event_iteration()
            f.enterContinuousTimeMode()
        f.getContinuousStates(px, n)
        (f.getContinuousStateDerivatives if v3 else f.getDerivatives)(pdx, n)
        t += h
        f.setTime(t)
        x[:] = x + h * dx
        f.setContinuousStates(px, n)
        f.completedIntegratorStep()
    say("ME set %s=%g in continuous-time mode: %s, in event mode: %s, T=%.2f R=%g"
          % (change + (status_ct, status, getr(f, "T"), getr(f, "R"))))
    f.terminate()
    f.freeInstance()


def nominal():
    f = instantiate(FMU3Model, md.modelExchange)
    init(f)
    while f.updateDiscreteStates()[0]:
        pass
    f.enterContinuousTimeMode()
    f.enterEventMode()
    setr(f, "T_nom", 100.0)
    changed = f.updateDiscreteStates()[2]
    n = md.numberOfContinuousStates
    nominals = np.zeros(n)
    f.getNominalsOfContinuousStates(nominals.ctypes.data_as(POINTER(c_double)), n)
    say("T_nom=100: nominals changed: %s, nominal(T)=%g" % (bool(changed), nominals[0]))
    f.terminate()
    f.freeInstance()


def fmu_state():
    a = instantiate(FMU3Slave if v3 else FMU2Slave, md.coSimulation)
    init(a)
    a.doStep(0.0, 100.0)
    state = a.getFMUState() if v3 else a.getFMUstate()
    setr(a, "R_set", 0.5)
    a.doStep(100.0, 100.0)
    (a.setFMUState if v3 else a.setFMUstate)(state)
    say("rolled back: R_set=%g R=%g" % (getr(a, "R_set"), getr(a, "R")))
    b = instantiate(FMU3Slave if v3 else FMU2Slave, md.coSimulation)
    setr(b, "R_set", 0.25)
    init(b)
    (b.setFMUState if v3 else b.setFMUstate)(state)
    say("set before init: R_set=%g R=%g" % (getr(b, "R_set"), getr(b, "R")))
    for f in (a, b):
        f.terminate()
        f.freeInstance()


cs(("R_set", 0.5))
cs(("R", 1.0))
cs(("k", 1.0))
me(("R_set", 0.5))
if v3:
    nominal()
fmu_state()
out.close()
