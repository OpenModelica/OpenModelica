# Drives <name>.fmu through its FMI 3.0 C API to check the calling sequences of
# Configuration Mode, and prints each call's status. No .mos can call a native FMU.
# Without a structural parameter the FMU must refuse to enter it; with one, the
# sequences below run on each interface the FMU has, and Configuration Mode sets
# the structural parameter but no other variable.
import ctypes as C, glob, os, re, sys, zipfile

name = sys.argv[1]
folder = name + "_unzipped"
zipfile.ZipFile(name + ".fmu").extractall(folder)
md = open(os.path.join(folder, "modelDescription.xml")).read()
token = re.search(r'instantiationToken="([^"]*)"', md).group(1).encode()
x_vr = int(re.search(r'<Float64 name="x" valueReference="(\d+)"', md).group(1))
structural = re.search(r'<Boolean name="([^"]*)" valueReference="(\d+)" causality="structuralParameter"', md)
interfaces = [k for k in ("ModelExchange", "CoSimulation") if re.search(r"<%s\b" % k, md)]
resources = os.path.abspath(os.path.join(folder, "resources")).encode()
fmu = C.CDLL(os.path.abspath(glob.glob(os.path.join(folder, "binaries", "*", "*"))[0]))

LOG = C.CFUNCTYPE(None, C.c_void_p, C.c_int, C.c_char_p, C.c_char_p)
log = LOG(lambda env, status, category, message: None)
inst_ptr = C.c_void_p
fmu.fmi3InstantiateModelExchange.restype = inst_ptr
fmu.fmi3InstantiateModelExchange.argtypes = [C.c_char_p, C.c_char_p, C.c_char_p, C.c_bool, C.c_bool, C.c_void_p, LOG]
fmu.fmi3InstantiateCoSimulation.restype = inst_ptr
fmu.fmi3InstantiateCoSimulation.argtypes = [C.c_char_p, C.c_char_p, C.c_char_p, C.c_bool, C.c_bool, C.c_bool, C.c_bool,
                                            C.c_void_p, C.c_size_t, C.c_void_p, LOG, C.c_void_p]
fmu.fmi3EnterInitializationMode.argtypes = [inst_ptr, C.c_bool, C.c_double, C.c_double, C.c_bool, C.c_double]
fmu.fmi3GetFloat64.argtypes = [inst_ptr, C.POINTER(C.c_uint32), C.c_size_t, C.POINTER(C.c_double), C.c_size_t]
fmu.fmi3SetFloat64.argtypes = [inst_ptr, C.POINTER(C.c_uint32), C.c_size_t, C.POINTER(C.c_double), C.c_size_t]
fmu.fmi3DoStep.argtypes = [inst_ptr, C.c_double, C.c_double, C.c_bool, C.c_void_p, C.c_void_p, C.c_void_p, C.c_void_p]
fmu.fmi3SetBoolean.argtypes = [inst_ptr, C.POINTER(C.c_uint32), C.c_size_t, C.POINTER(C.c_bool), C.c_size_t]
fmu.fmi3SetDebugLogging.argtypes = [inst_ptr, C.c_bool, C.c_size_t, C.c_void_p]
fmu.fmi3FreeInstance.restype = None
for f in ("EnterConfigurationMode", "ExitConfigurationMode", "ExitInitializationMode", "EnterEventMode",
          "EnterContinuousTimeMode", "EnterStepMode", "Terminate", "Reset", "FreeInstance"):
    getattr(fmu, "fmi3" + f).argtypes = [inst_ptr]

STATUS = {0: "OK", 1: "Warning", 2: "Discard", 3: "Error", 4: "Fatal"}

def me():
    return fmu.fmi3InstantiateModelExchange(b"i", token, resources, False, False, None, log)

def cs():
    return fmu.fmi3InstantiateCoSimulation(b"i", token, resources, False, False, False, False, None, 0, None, log, None)

def call(what, *args):
    print("  %s: %s" % (what, STATUS[getattr(fmu, "fmi3" + what)(*args)]))

def enter_init(i):
    call("EnterInitializationMode", i, False, 0.0, 0.0, False, 0.0)

def get_x(i):
    vr, v = C.c_uint32(x_vr), C.c_double()
    status = fmu.fmi3GetFloat64(i, C.byref(vr), 1, C.byref(v), 1)
    print("  GetFloat64 x: %s%s" % (STATUS[status], " = %.4f" % v.value if status == 0 else ""))

def set_x(i):
    vr, v = C.c_uint32(x_vr), C.c_double(2.0)
    print("  SetFloat64 x: %s" % STATUS[fmu.fmi3SetFloat64(i, C.byref(vr), 1, C.byref(v), 1)])

def set_structural(i):
    vr, v = C.c_uint32(int(structural.group(2))), C.c_bool(False)
    print("  SetBoolean %s: %s" % (structural.group(1), STATUS[fmu.fmi3SetBoolean(i, C.byref(vr), 1, C.byref(v), 1)]))

for kind, new in (("Model Exchange", me), ("Co-Simulation", cs)):
    if kind.replace(" ", "").replace("-", "") not in interfaces:
        continue
    print(kind + ":")

    if not structural:
        print(" no structural parameter: refused, into the error state")
        i = new()
        call("EnterConfigurationMode", i)
        enter_init(i)
        fmu.fmi3FreeInstance(i)
        continue

    print(" the sequence a Configuration Mode opens, on to a simulation")
    i = new()
    call("EnterConfigurationMode", i)
    set_structural(i)
    call("ExitConfigurationMode", i)
    enter_init(i)
    call("ExitInitializationMode", i)
    get_x(i)
    if new is cs:
        call("DoStep", i, 0.0, 0.1, False, None, None, None, None)
        get_x(i)
    call("Terminate", i)
    fmu.fmi3FreeInstance(i)

    print(" twice, and the instance can still be freed")
    i = new()
    call("EnterConfigurationMode", i)
    call("EnterConfigurationMode", i)
    fmu.fmi3FreeInstance(i)

    print(" Exit without Enter")
    i = new()
    call("ExitConfigurationMode", i)
    fmu.fmi3FreeInstance(i)

    print(" Enter after initialization: there is no Reconfiguration Mode")
    i = new()
    enter_init(i)
    call("EnterConfigurationMode", i)
    fmu.fmi3FreeInstance(i)
    i = new()
    enter_init(i)
    call("ExitInitializationMode", i)
    call("EnterConfigurationMode", i)
    fmu.fmi3FreeInstance(i)

    print(" what Configuration Mode refuses, a fresh instance each")
    for refused in (enter_init, get_x, set_x,
                    lambda i: call("Terminate", i),
                    lambda i: call("EnterEventMode", i),
                    lambda i: call("EnterStepMode", i),
                    lambda i: call("DoStep", i, 0.0, 0.1, False, None, None, None, None)):
        i = new()
        fmu.fmi3EnterConfigurationMode(i)
        refused(i)
        fmu.fmi3FreeInstance(i)

    print(" what it allows: debug logging, and Reset back to Instantiated")
    i = new()
    call("EnterConfigurationMode", i)
    call("SetDebugLogging", i, False, 0, None)
    call("Reset", i)
    enter_init(i)
    call("ExitInitializationMode", i)
    get_x(i)
    fmu.fmi3FreeInstance(i)

    print(" freed while in it")
    i = new()
    call("EnterConfigurationMode", i)
    fmu.fmi3FreeInstance(i)
    print("  done")
