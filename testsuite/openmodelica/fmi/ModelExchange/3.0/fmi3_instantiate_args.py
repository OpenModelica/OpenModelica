"""Call fmi3InstantiateModelExchange and fmi3InstantiateCoSimulation with
logMessage = NULL and with resourcePath = NULL, and write the results.
usage: fmi3_instantiate_args.py <fmu> <output_txt>
"""
import ctypes
import os
import sys
from ctypes import c_bool, c_char_p, c_double, c_int, c_size_t, c_void_p
from fmpy import extract, read_model_description, platform_tuple, sharedLibraryExtension

NAMES = ["fmi3OK", "fmi3Warning", "fmi3Discard", "fmi3Error", "fmi3Fatal"]
LOG = ctypes.CFUNCTYPE(None, c_void_p, c_int, c_char_p, c_char_p)
messages = []
log = LOG(lambda env, status, category, message: messages.append("%s %s" % (NAMES[status], category.decode())))

def main(fmu, output):
    md = read_model_description(fmu)
    unzipdir = extract(fmu)
    lib = ctypes.CDLL(os.path.join(unzipdir, "binaries", platform_tuple,
                                   md.modelExchange.modelIdentifier + sharedLibraryExtension))
    token = md.instantiationToken.encode()
    resources = (os.path.join(unzipdir, "resources") + os.sep).encode()
    me = lib.fmi3InstantiateModelExchange
    me.argtypes = [c_char_p, c_char_p, c_char_p, c_bool, c_bool, c_void_p, LOG]
    me.restype = c_void_p
    cs = lib.fmi3InstantiateCoSimulation
    cs.argtypes = [c_char_p, c_char_p, c_char_p, c_bool, c_bool, c_bool, c_bool,
                   c_void_p, c_size_t, c_void_p, LOG, c_void_p]
    cs.restype = c_void_p
    lib.fmi3FreeInstance.argtypes = [c_void_p]
    lib.fmi3EnterInitializationMode.argtypes = [c_void_p, c_bool, c_double, c_double, c_bool, c_double]
    lib.fmi3ExitInitializationMode.argtypes = [c_void_p]
    calls = [
        ("fmi3InstantiateModelExchange", lambda res, cb: me(b"instance", token, res, False, True, None, cb)),
        ("fmi3InstantiateCoSimulation", lambda res, cb: cs(b"instance", token, res, False, True, False, False,
                                                           None, 0, None, cb, None)),
    ]
    with open(output, "w") as f:
        for name, call in calls:
            for label, res, cb in (("logMessage = NULL", resources, LOG()), ("resourcePath = NULL", None, log)):
                del messages[:]
                f.write("%s(%s): " % (name, label))
                f.flush()
                instance = call(res, cb)
                f.write("%s, log: %s\n" % ("instance" if instance else "NULL", messages))
                f.flush()
                if instance:
                    status = max(lib.fmi3EnterInitializationMode(instance, False, 0.0, 0.0, False, 0.0),
                                 lib.fmi3ExitInitializationMode(instance))
                    f.write("  initialization: %s\n" % NAMES[status])
                    lib.fmi3FreeInstance(instance)

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
