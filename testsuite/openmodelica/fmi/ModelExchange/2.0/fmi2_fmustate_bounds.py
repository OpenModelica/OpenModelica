"""FMI 2.0 FMU state calls with a short buffer, a damaged byte vector and NULL
arguments. Each check runs in its own process, so a crash shows as a line.
usage: fmi2_fmustate_bounds.py <fmu> <output_txt> [null]
With "null", only the NULL argument checks run.
"""
import resource
import subprocess
import sys
from ctypes import POINTER, byref, c_size_t, cast, create_string_buffer
from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Model, fmi2Byte, fmi2FMUstate

NAMES = ["fmi2OK", "fmi2Warning", "fmi2Discard", "fmi2Error", "fmi2Fatal"]

fmu = sys.argv[1]
md = read_model_description(fmu)
child = sys.argv[2] == "--child"
unzipdir = sys.argv[3] if child else extract(fmu)


def status(call, *args):
    try:
        call(*args)
        return NAMES[0]
    except Exception as e:
        s = getattr(e, "status", None)
        return NAMES[s] if isinstance(s, int) and 0 <= s < 5 else type(e).__name__


def model():
    f = FMU2Model(guid=md.guid, unzipDirectory=unzipdir,
                  modelIdentifier=md.modelExchange.modelIdentifier, instanceName="i")
    f.instantiate()
    f.setupExperiment(startTime=0.0)
    f.enterInitializationMode()
    f.exitInitializationMode()
    return f


def serialized(f):
    s = f.getFMUstate()
    n = c_size_t()
    f.fmi2SerializedFMUstateSize(f.component, s, byref(n))
    buf = create_string_buffer(n.value)
    f.fmi2SerializeFMUstate(f.component, s, cast(buf, POINTER(fmi2Byte)), n.value)
    return s, buf.raw


def serialize_into(size):
    """Serialize into a bigger buffer, but say it has `size` bytes."""
    f = model()
    s, data = serialized(f)
    buf = create_string_buffer(b"\xaa" * (len(data) + 16))
    r = status(f.fmi2SerializeFMUstate, f.component, s, cast(buf, POINTER(fmi2Byte)), size)
    past = buf.raw[size:len(data) + 16] != b"\xaa" * (len(data) + 16 - size)
    return r + (", bytes written past size" if past else "")


def deserialize(change):
    f = model()
    _, data = serialized(f)
    data = change(data)
    buf = create_string_buffer(data, len(data))
    s = fmi2FMUstate()
    return status(f.fmi2DeSerializeFMUstate, f.component, cast(buf, POINTER(fmi2Byte)), len(data), byref(s))


def deserialize_and_set():
    f = model()
    _, data = serialized(f)
    buf = create_string_buffer(data, len(data))
    s = fmi2FMUstate()
    r = status(f.fmi2DeSerializeFMUstate, f.component, cast(buf, POINTER(fmi2Byte)), len(data), byref(s))
    return r + ", fmi2SetFMUstate: " + status(f.fmi2SetFMUstate, f.component, s)


def with_state(call):
    f = model()
    s, data = serialized(f)
    buf = create_string_buffer(data, len(data))
    return status(*call(f, s, cast(buf, POINTER(fmi2Byte)), len(data)))


SIZE_CHECKS = [
    ("serialize, size half of the state", lambda: serialize_into(len(serialized(model())[1]) // 2)),
    ("serialize, size 0", lambda: serialize_into(0)),
    ("deserialize, exact size, then set", deserialize_and_set),
    ("deserialize, one byte short", lambda: deserialize(lambda d: d[:-1])),
    ("deserialize, one byte too many", lambda: deserialize(lambda d: d + b"\x00")),
    ("deserialize, all bytes 0xFF", lambda: deserialize(lambda d: b"\xff" * len(d))),
]
NULL_CHECKS = [
    ("fmi2FreeFMUstate(c, NULL)", lambda: with_state(lambda f, s, b, n: (f.fmi2FreeFMUstate, f.component, None))),
    ("fmi2FreeFMUstate(c, &NULL)", lambda: with_state(lambda f, s, b, n: (f.fmi2FreeFMUstate, f.component, byref(fmi2FMUstate())))),
    ("fmi2GetFMUstate(c, NULL)", lambda: with_state(lambda f, s, b, n: (f.fmi2GetFMUstate, f.component, None))),
    ("fmi2SetFMUstate(c, NULL)", lambda: with_state(lambda f, s, b, n: (f.fmi2SetFMUstate, f.component, None))),
    ("fmi2SerializedFMUstateSize(c, NULL, &size)", lambda: with_state(lambda f, s, b, n: (f.fmi2SerializedFMUstateSize, f.component, None, byref(c_size_t())))),
    ("fmi2SerializedFMUstateSize(c, s, NULL)", lambda: with_state(lambda f, s, b, n: (f.fmi2SerializedFMUstateSize, f.component, s, None))),
    ("fmi2SerializeFMUstate(c, NULL, buffer, size)", lambda: with_state(lambda f, s, b, n: (f.fmi2SerializeFMUstate, f.component, None, b, n))),
    ("fmi2SerializeFMUstate(c, s, NULL, size)", lambda: with_state(lambda f, s, b, n: (f.fmi2SerializeFMUstate, f.component, s, None, n))),
    ("fmi2DeSerializeFMUstate(c, NULL, size, &s)", lambda: with_state(lambda f, s, b, n: (f.fmi2DeSerializeFMUstate, f.component, None, n, byref(fmi2FMUstate())))),
    ("fmi2DeSerializeFMUstate(c, buffer, size, NULL)", lambda: with_state(lambda f, s, b, n: (f.fmi2DeSerializeFMUstate, f.component, b, n, None))),
]


CHECKS = SIZE_CHECKS + NULL_CHECKS

if child:
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    print(CHECKS[int(sys.argv[4])][1]())
    sys.exit(0)

first = len(SIZE_CHECKS) if len(sys.argv) > 3 and sys.argv[3] == "null" else 0
with open(sys.argv[2], "w") as out:
    for k in range(first, len(CHECKS)):
        p = subprocess.run([sys.executable, "-I", sys.argv[0], fmu, "--child", unzipdir, str(k)],
                           stdout=subprocess.PIPE, text=True)
        if p.returncode == 0:
            text = p.stdout.strip().splitlines()[-1]
        else:
            text = "crashed (signal %d)" % -p.returncode
        out.write("%s: %s\n" % (CHECKS[k][0], text))
