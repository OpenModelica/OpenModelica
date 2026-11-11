"""fmi2FreeFMUstate with a NULL pointer, C+Rust FMU.
usage: fmi2_fmustate_free_null_c_rust.py <fmu>
"""
import sys
from ctypes import byref
from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Model, fmi2FMUstate

NAMES = ["fmi2OK", "fmi2Warning", "fmi2Discard", "fmi2Error", "fmi2Fatal"]


def status(call, *args):
    try:
        call(*args)
        return NAMES[0]
    except Exception as e:
        s = getattr(e, "status", None)
        return NAMES[s] if isinstance(s, int) and 0 <= s < 5 else type(e).__name__


md = read_model_description(sys.argv[1])
f = FMU2Model(guid=md.guid, unzipDirectory=extract(sys.argv[1]),
              modelIdentifier=md.modelExchange.modelIdentifier, instanceName="i")
f.instantiate()
f.setupExperiment(startTime=0.0)
f.enterInitializationMode()
f.exitInitializationMode()
s = f.getFMUstate()
print("fmi2FreeFMUstate(c, NULL):", status(f.fmi2FreeFMUstate, f.component, None))
print("fmi2FreeFMUstate(c, &NULL):", status(f.fmi2FreeFMUstate, f.component, byref(fmi2FMUstate())))
print("fmi2FreeFMUstate(c, &s):", status(f.fmi2FreeFMUstate, f.component, byref(s)))
f.terminate()
f.freeInstance()
