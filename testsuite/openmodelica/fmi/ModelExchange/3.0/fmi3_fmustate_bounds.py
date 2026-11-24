"""FMI 3.0 FMU state calls with a wrong size, a damaged byte vector and NULL
arguments, and fmi3SetFMUState after the error. Each check runs in its own
process, so a crash shows as a line.
usage: fmi3_fmustate_bounds.py <fmu> <output_txt>
"""
import struct
import subprocess
import sys
from ctypes import POINTER, byref, c_size_t, cast, create_string_buffer, sizeof
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


def set_deserialized(f, data):
    """fmi3Error if fmi3DeserializeFMUState or the fmi3SetFMUState after it refuses data."""
    buf = create_string_buffer(data, len(data))
    s = fmi3FMUState()
    r = status(f.fmi3DeserializeFMUState, f.component, cast(buf, POINTER(fmi3Byte)), len(data), byref(s))
    return r if r != NAMES[0] else status(f.fmi3SetFMUState, f.component, s)


def deserialize_changed(change):
    f = model()
    return set_deserialized(f, change(serialized(f)[1]))


def deserialize_and_set():
    f = model()
    _, data = serialized(f)
    buf = create_string_buffer(data, len(data))
    s = fmi3FMUState()
    r = status(f.fmi3DeserializeFMUState, f.component, cast(buf, POINTER(fmi3Byte)), len(data), byref(s))
    return r + ", fmi3SetFMUState: " + status(f.fmi3SetFMUState, f.component, s)


def long_delay_buffer(data):
    """Set the length of the delay() buffer past the end of the state."""
    # C+Rust and wasm: mode, SimData, the String variables (none here), the
    # delay() words (has, start, count, length, ...), the schedule, then the
    # lengths of the last two parts and of SimData.
    n_opaque, n_schedule, flat = struct.unpack("<3Q", data[-24:])
    if 4 + flat + n_opaque + n_schedule + 24 == len(data):
        k = 4 + flat + 24
        return data[:k] + struct.pack("<d", 1e9) + data[k + 8:]
    # C: the history words come last, after their number.
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
    other = f.getFMUState()
    return ", ".join([fail(f, s, data), status(f.fmi3FreeFMUState, f.component, byref(other)),
                      status(f.fmi3SetFMUState, f.component, s), status(f.fmi3EnterContinuousTimeMode, f.component)])


def with_state(call):
    f = model()
    s, data = serialized(f)
    buf = create_string_buffer(data, len(data))
    return status(*call(f, s, cast(buf, POINTER(fmi3Byte)), len(data)))


CHECKS = [
    ("serialize, size half of the state", lambda: serialize_into(len(serialized(model())[1]) // 2)),
    ("serialize, size 0", lambda: serialize_into(0)),
    ("serialize, size one byte too many", lambda: serialize_into(len(serialized(model())[1]) + 1)),
    ("deserialize, exact size, then set", deserialize_and_set),
    ("deserialize and set, one byte short", lambda: deserialize_changed(lambda d: d[:-1])),
    ("deserialize and set, one byte too many", lambda: deserialize_changed(lambda d: d + b"\x00")),
    ("deserialize and set, all bytes 0xFF", lambda: deserialize_changed(lambda d: b"\xff" * len(d))),
    ("deserialize and set, delay() buffer longer than the state", lambda: deserialize_changed(long_delay_buffer)),
    ("serialize with a wrong size, then fmi3FreeFMUState, fmi3SetFMUState, fmi3EnterContinuousTimeMode",
     lambda: recover(lambda f, s, d: status(f.fmi3SerializeFMUState, f.component, s,
                                            cast(create_string_buffer(len(d)), POINTER(fmi3Byte)), len(d) // 2))),
    ("deserialize and set a damaged state, then fmi3FreeFMUState, fmi3SetFMUState, fmi3EnterContinuousTimeMode",
     lambda: recover(lambda f, s, d: set_deserialized(f, b"\xff" * len(d)))),
    ("fmi3FreeFMUState(c, NULL)", lambda: with_state(lambda f, s, b, n: (f.fmi3FreeFMUState, f.component, None))),
    ("fmi3FreeFMUState(c, &NULL)", lambda: with_state(lambda f, s, b, n: (f.fmi3FreeFMUState, f.component, byref(fmi3FMUState())))),
    ("fmi3GetFMUState(c, NULL)", lambda: with_state(lambda f, s, b, n: (f.fmi3GetFMUState, f.component, None))),
    ("fmi3SetFMUState(c, NULL)", lambda: with_state(lambda f, s, b, n: (f.fmi3SetFMUState, f.component, None))),
    ("fmi3SerializedFMUStateSize(c, NULL, &size)", lambda: with_state(lambda f, s, b, n: (f.fmi3SerializedFMUStateSize, f.component, None, byref(c_size_t())))),
    ("fmi3SerializedFMUStateSize(c, s, NULL)", lambda: with_state(lambda f, s, b, n: (f.fmi3SerializedFMUStateSize, f.component, s, None))),
    ("fmi3SerializeFMUState(c, NULL, buffer, size)", lambda: with_state(lambda f, s, b, n: (f.fmi3SerializeFMUState, f.component, None, b, n))),
    ("fmi3SerializeFMUState(c, s, NULL, size)", lambda: with_state(lambda f, s, b, n: (f.fmi3SerializeFMUState, f.component, s, None, n))),
    ("fmi3DeserializeFMUState(c, NULL, size, &s)", lambda: with_state(lambda f, s, b, n: (f.fmi3DeserializeFMUState, f.component, None, n, byref(fmi3FMUState())))),
    ("fmi3DeserializeFMUState(c, buffer, size, NULL)", lambda: with_state(lambda f, s, b, n: (f.fmi3DeserializeFMUState, f.component, b, n, None))),
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
