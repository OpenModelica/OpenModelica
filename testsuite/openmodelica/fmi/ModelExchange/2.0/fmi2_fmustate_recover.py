"""After an error, fmi2SetFMUstate with a stored state continues the simulation
(FMI 2.0.5, 2.1.3).
usage: fmi2_fmustate_recover.py <fmu> <output_txt>
"""
import sys
from ctypes import POINTER, byref, c_double, c_size_t, cast, create_string_buffer
from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Model, fmi2Byte, fmi2FMUstate

NAMES = ["fmi2OK", "fmi2Warning", "fmi2Discard", "fmi2Error", "fmi2Fatal"]


def status(call, *args):
    try:
        call(*args)
        return NAMES[0]
    except Exception as e:
        s = getattr(e, "status", None)
        return NAMES[s] if isinstance(s, int) and 0 <= s < 5 else type(e).__name__


fmu = sys.argv[1]
md = read_model_description(fmu)
x = next(v.valueReference for v in md.modelVariables if v.name == "x")
f = FMU2Model(guid=md.guid, unzipDirectory=extract(fmu),
              modelIdentifier=md.modelExchange.modelIdentifier, instanceName="i")
f.instantiate()
f.setupExperiment(startTime=0.0)
f.enterInitializationMode()
f.exitInitializationMode()
s = f.getFMUstate()
f.enterContinuousTimeMode()
f.setTime(0.5)
f.setContinuousStates((c_double * 1)(0.25), 1)

lines = []


def check(name, call, *args):
    lines.append("%s: %s" % (name, status(call, *args)))


check("fmi2EnterInitializationMode in Continuous-Time Mode", f.fmi2EnterInitializationMode, f.component)
other = fmi2FMUstate()
check("fmi2GetFMUstate", f.fmi2GetFMUstate, f.component, byref(other))
n = c_size_t()
check("fmi2SerializedFMUstateSize", f.fmi2SerializedFMUstateSize, f.component, s, byref(n))
buf = create_string_buffer(n.value)
check("fmi2SerializeFMUstate", f.fmi2SerializeFMUstate, f.component, s, cast(buf, POINTER(fmi2Byte)), n.value)
copy = fmi2FMUstate()
check("fmi2DeSerializeFMUstate", f.fmi2DeSerializeFMUstate, f.component, cast(buf, POINTER(fmi2Byte)), n.value, byref(copy))
check("fmi2FreeFMUstate", f.fmi2FreeFMUstate, f.component, byref(other))
check("fmi2SetFMUstate", f.fmi2SetFMUstate, f.component, copy)
check("fmi2EnterContinuousTimeMode", f.fmi2EnterContinuousTimeMode, f.component)
lines.append("x = %g" % f.getReal([x])[0])

with open(sys.argv[2], "w") as out:
    out.write("\n".join(lines) + "\n")
f.freeInstance()
