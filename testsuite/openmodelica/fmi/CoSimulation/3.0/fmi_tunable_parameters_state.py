"""Tunable parameters with an external object, FMU states and arrays (#17652).

usage: fmi_tunable_parameters_state.py <fmu> <output_txt>
"""
import sys
from ctypes import POINTER, c_double

import numpy as np
from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Model, FMU3Slave

fmu = sys.argv[1]
out = open(sys.argv[2], "w")
md = read_model_description(fmu)
unzipdir = extract(fmu)
vr = {v.name: v.valueReference for v in md.modelVariables}


def say(line):
    out.write(line + "\n")


for v in md.modelVariables:
    if v.name in ("k", "k2", "T_nom", "q", "r", "p"):
        say("%s: %s %s" % (v.name, v.causality, v.variability))


def instantiate(cls, ident):
    f = cls(guid=md.guid, unzipDirectory=unzipdir, modelIdentifier=ident.modelIdentifier, instanceName="i")
    f.instantiate()
    return f


def get(f, *names):
    return " ".join("%s=%g" % (n, f.getFloat64([vr[n]])[0]) for n in names)


def cs():
    f = instantiate(FMU3Slave, md.coSimulation)
    f.setFloat64([vr["k"]], [3.0])
    f.enterInitializationMode(startTime=0)
    f.exitInitializationMode()
    f.doStep(0.0, 0.1)
    s1 = f.getFMUState()
    f.setFloat64([vr["k"]], [7.0])
    f.doStep(0.1, 0.1)
    say("tuned: " + get(f, "k", "k2", "y", "ra"))
    f.setFMUState(s1)
    say("rolled back past a set before init: " + get(f, "k", "k2"))
    f.setFloat64([vr["k"]], [5.0])
    s2 = f.getFMUState()
    f.doStep(0.1, 0.1)
    f.setFMUState(s2)
    say("state saved after a set: " + get(f, "k", "k2"))
    f.doStep(0.1, 0.1)
    say("step after it: " + get(f, "y"))
    f.terminate()
    f.freeInstance()


def me():
    f = instantiate(FMU3Model, md.modelExchange)
    f.enterInitializationMode(startTime=0)
    f.exitInitializationMode()
    while f.updateDiscreteStates()[0]:
        pass
    n = md.numberOfContinuousStates
    nominals = np.zeros(n)
    pn = nominals.ctypes.data_as(POINTER(c_double))
    s = f.getFMUState()
    f.setFloat64([vr["T_nom"]], [100.0])
    f.updateDiscreteStates()
    f.getNominalsOfContinuousStates(pn, n)
    say("T_nom=100: nominal(x)=%g" % nominals[0])
    f.setFMUState(s)
    f.getNominalsOfContinuousStates(pn, n)
    say("restored: %s nominal(x)=%g" % (get(f, "T_nom"), nominals[0]))
    f.terminate()
    f.freeInstance()


cs()
me()
out.close()
