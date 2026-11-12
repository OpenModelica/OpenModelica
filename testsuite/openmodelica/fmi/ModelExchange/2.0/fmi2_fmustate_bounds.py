"""FMI 2.0 FMU state calls with a wrong size, a damaged byte vector and NULL
arguments, and fmi2SetFMUstate after the error. Each check runs in its own
process, so a crash shows as a line.
usage: fmi2_fmustate_bounds.py <fmu> <output_txt>
"""
import struct
import subprocess
import sys
from ctypes import POINTER, byref, c_size_t, cast, create_string_buffer, sizeof
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


def deserialize(f, data):
    buf = create_string_buffer(data, len(data))
    return status(f.fmi2DeSerializeFMUstate, f.component, cast(buf, POINTER(fmi2Byte)), len(data), byref(fmi2FMUstate()))


def deserialize_changed(change):
    f = model()
    return deserialize(f, change(serialized(f)[1]))


def deserialize_and_set():
    f = model()
    _, data = serialized(f)
    buf = create_string_buffer(data, len(data))
    s = fmi2FMUstate()
    r = status(f.fmi2DeSerializeFMUstate, f.component, cast(buf, POINTER(fmi2Byte)), len(data), byref(s))
    return r + ", fmi2SetFMUstate: " + status(f.fmi2SetFMUstate, f.component, s)


def long_delay_buffer(data):
    """Set the length of the delay() buffer, the first history word, past the end."""
    w = sizeof(c_size_t)
    for n in range(1, len(data) // 8):
        k = len(data) - 8 * n - w
        if int.from_bytes(data[k:k + w], sys.byteorder) == n:
            return data[:k + w] + struct.pack("=d", 1e9) + data[k + w + 8:]
    raise ValueError("no history words in the state")


def recover(fail):
    """After the error, free one state and continue from another."""
    f = model()
    s, data = serialized(f)
    other = f.getFMUstate()
    return ", ".join([fail(f, s, data), status(f.fmi2FreeFMUstate, f.component, byref(other)),
                      status(f.fmi2SetFMUstate, f.component, s), status(f.fmi2EnterContinuousTimeMode, f.component)])


def with_state(call):
    f = model()
    s, data = serialized(f)
    buf = create_string_buffer(data, len(data))
    return status(*call(f, s, cast(buf, POINTER(fmi2Byte)), len(data)))


CHECKS = [
    ("serialize, size half of the state", lambda: serialize_into(len(serialized(model())[1]) // 2)),
    ("serialize, size 0", lambda: serialize_into(0)),
    ("serialize, size one byte too many", lambda: serialize_into(len(serialized(model())[1]) + 1)),
    ("deserialize, exact size, then set", deserialize_and_set),
    ("deserialize, one byte short", lambda: deserialize_changed(lambda d: d[:-1])),
    ("deserialize, one byte too many", lambda: deserialize_changed(lambda d: d + b"\x00")),
    ("deserialize, all bytes 0xFF", lambda: deserialize_changed(lambda d: b"\xff" * len(d))),
    ("deserialize, delay() buffer longer than the state", lambda: deserialize_changed(long_delay_buffer)),
    ("serialize with a wrong size, then fmi2FreeFMUstate, fmi2SetFMUstate, fmi2EnterContinuousTimeMode",
     lambda: recover(lambda f, s, d: status(f.fmi2SerializeFMUstate, f.component, s,
                                            cast(create_string_buffer(len(d)), POINTER(fmi2Byte)), len(d) // 2))),
    ("deserialize a damaged state, then fmi2FreeFMUstate, fmi2SetFMUstate, fmi2EnterContinuousTimeMode",
     lambda: recover(lambda f, s, d: deserialize(f, b"\xff" * len(d)))),
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

if child:
    try:
        import resource
        resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    except ImportError:
        pass
    print(CHECKS[int(sys.argv[4])][1]())
    sys.exit(0)

with open(sys.argv[2], "w") as out:
    for k in range(len(CHECKS)):
        p = subprocess.run([sys.executable, sys.argv[0], fmu, "--child", unzipdir, str(k)],
                           stdout=subprocess.PIPE, text=True)
        if p.returncode == 0:
            text = p.stdout.strip().splitlines()[-1]
        else:
            text = "crashed (exit code %d)" % p.returncode
        out.write("%s: %s\n" % (CHECKS[k][0], text))
