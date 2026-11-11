"""FMI 3.0 FMU state serialization with a short buffer and a damaged byte
vector. Each check runs in its own process, so a crash shows as a line.
usage: fmi3_fmustate_bounds.py <fmu> <output_txt>
"""
import resource
import subprocess
import sys
from ctypes import POINTER, byref, c_size_t, cast, create_string_buffer
from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Model, fmi3Byte, fmi3FMUState

NAMES = ["fmi3OK", "fmi3Warning", "fmi3Discard", "fmi3Error", "fmi3Fatal"]

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
    f = FMU3Model(guid=md.instantiationToken, unzipDirectory=unzipdir,
                  modelIdentifier=md.modelExchange.modelIdentifier, instanceName="i")
    f.instantiate()
    f.enterInitializationMode(startTime=0.0)
    f.exitInitializationMode()
    return f


def serialized(f):
    s = f.getFMUState()
    n = c_size_t()
    f.fmi3SerializedFMUStateSize(f.component, s, byref(n))
    buf = create_string_buffer(n.value)
    f.fmi3SerializeFMUState(f.component, s, cast(buf, POINTER(fmi3Byte)), n.value)
    return s, buf.raw


def serialize_into(size):
    """Serialize into a bigger buffer, but say it has `size` bytes."""
    f = model()
    s, data = serialized(f)
    buf = create_string_buffer(b"\xaa" * (len(data) + 16))
    r = status(f.fmi3SerializeFMUState, f.component, s, cast(buf, POINTER(fmi3Byte)), size)
    past = buf.raw[size:len(data) + 16] != b"\xaa" * (len(data) + 16 - size)
    return r + (", bytes written past size" if past else "")


def deserialize(change):
    f = model()
    _, data = serialized(f)
    data = change(data)
    buf = create_string_buffer(data, len(data))
    s = fmi3FMUState()
    return status(f.fmi3DeserializeFMUState, f.component, cast(buf, POINTER(fmi3Byte)), len(data), byref(s))


def deserialize_and_set():
    f = model()
    _, data = serialized(f)
    buf = create_string_buffer(data, len(data))
    s = fmi3FMUState()
    r = status(f.fmi3DeserializeFMUState, f.component, cast(buf, POINTER(fmi3Byte)), len(data), byref(s))
    return r + ", fmi3SetFMUState: " + status(f.fmi3SetFMUState, f.component, s)


CHECKS = [
    ("serialize, size half of the state", lambda: serialize_into(len(serialized(model())[1]) // 2)),
    ("serialize, size 0", lambda: serialize_into(0)),
    ("deserialize, exact size, then set", deserialize_and_set),
    ("deserialize, one byte short", lambda: deserialize(lambda d: d[:-1])),
    ("deserialize, one byte too many", lambda: deserialize(lambda d: d + b"\x00")),
    ("deserialize, all bytes 0xFF", lambda: deserialize(lambda d: b"\xff" * len(d))),
]

if child:
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    print(CHECKS[int(sys.argv[4])][1]())
    sys.exit(0)

with open(sys.argv[2], "w") as out:
    for k in range(len(CHECKS)):
        p = subprocess.run([sys.executable, "-I", sys.argv[0], fmu, "--child", unzipdir, str(k)],
                           stdout=subprocess.PIPE, text=True)
        if p.returncode == 0:
            text = p.stdout.strip().splitlines()[-1]
        else:
            text = "crashed (signal %d)" % -p.returncode
        out.write("%s: %s\n" % (CHECKS[k][0], text))
