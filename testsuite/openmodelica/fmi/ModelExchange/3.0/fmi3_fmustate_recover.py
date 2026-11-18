"""After an error, fmi3SetFMUState with a stored state continues the simulation
(FMI 3.0.2, 2.2.4 and 2.3.1).
usage: fmi3_fmustate_recover.py <fmu> <output_txt>
"""
import sys
from ctypes import POINTER, byref, c_double, c_size_t, cast, create_string_buffer
from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Model, fmi3Byte, fmi3FMUState

NAMES = ["fmi3OK", "fmi3Warning", "fmi3Discard", "fmi3Error", "fmi3Fatal"]


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
f = FMU3Model(guid=md.instantiationToken, unzipDirectory=extract(fmu),
              modelIdentifier=md.modelExchange.modelIdentifier, instanceName="i")
f.instantiate()
f.enterInitializationMode(startTime=0.0)
f.exitInitializationMode()
s = f.getFMUState()
f.enterContinuousTimeMode()
f.setTime(0.5)
f.setContinuousStates((c_double * 1)(0.25), 1)

lines = []


def check(name, call, *args):
    lines.append("%s: %s" % (name, status(call, *args)))


check("fmi3EnterInitializationMode in Continuous-Time Mode", f.fmi3EnterInitializationMode, f.component, False, 0.0, 0.0, False, 0.0)
other = fmi3FMUState()
check("fmi3GetFMUState", f.fmi3GetFMUState, f.component, byref(other))
n = c_size_t()
check("fmi3SerializedFMUStateSize", f.fmi3SerializedFMUStateSize, f.component, s, byref(n))
buf = create_string_buffer(n.value)
check("fmi3SerializeFMUState", f.fmi3SerializeFMUState, f.component, s, cast(buf, POINTER(fmi3Byte)), n.value)
copy = fmi3FMUState()
check("fmi3DeserializeFMUState", f.fmi3DeserializeFMUState, f.component, cast(buf, POINTER(fmi3Byte)), n.value, byref(copy))
check("fmi3FreeFMUState", f.fmi3FreeFMUState, f.component, byref(other))
check("fmi3SetFMUState", f.fmi3SetFMUState, f.component, copy)
check("fmi3EnterContinuousTimeMode", f.fmi3EnterContinuousTimeMode, f.component)
lines.append("x = %g" % f.getFloat64([x])[0])

with open(sys.argv[2], "w") as out:
    out.write("\n".join(lines) + "\n")
f.freeInstance()
