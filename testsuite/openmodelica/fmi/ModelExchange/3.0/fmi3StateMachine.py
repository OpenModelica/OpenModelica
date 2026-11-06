# Drives the FMI 3.0 C API of <me_cs.fmu>, <se.fmu> and <events.fmu>: every call below, on a fresh
# instance, in every state the FMU can reach. The ALLOWED table comes from the
# "Allowed Function Calls" lists of FMI 3.0.2, sections 2.3, 3.2, 4.2 and 5.2. Each
# call with variables passes none of them, as the state is all that is under test.
# A call that is legal in the spec but refused, or the reverse, prints MISMATCH.
# <events.fmu> has an event indicator and a parameter p, for the per-variable checks
# at the end. The output does not depend on the runtime behind the FMU.
import ctypes as C, glob, os, re, sys, zipfile

LOG = C.CFUNCTYPE(None, C.c_void_p, C.c_int, C.c_char_p, C.c_char_p)
log = LOG(lambda env, status, category, message: None)
P = C.c_void_p
REFS = [P, P, C.c_size_t, P, C.c_size_t]


class Fmu:
    def __init__(self, name):
        folder = name + "_unzipped"
        zipfile.ZipFile(name + ".fmu").extractall(folder)
        md = open(os.path.join(folder, "modelDescription.xml")).read()
        self.token = re.search(r'instantiationToken="([^"]*)"', md).group(1).encode()
        clock = re.search(r'<Clock name="[^"]*" valueReference="(\d+)"', md)
        self.clock = int(clock.group(1)) if clock else 0
        self.structural = 'causality="structuralParameter"' in md
        self.vr = {name: int(vr) for name, vr in re.findall(r'name="([^"]*)" valueReference="(\d+)"', md)}
        self.resources = os.path.abspath(os.path.join(folder, "resources")).encode()
        self.lib = C.CDLL(os.path.abspath(glob.glob(os.path.join(folder, "binaries", "*", "*"))[0]))
        lib = self.lib
        for f in ("InstantiateModelExchange", "InstantiateCoSimulation", "InstantiateScheduledExecution"):
            getattr(lib, "fmi3" + f).restype = P
        lib.fmi3InstantiateModelExchange.argtypes = [C.c_char_p, C.c_char_p, C.c_char_p, C.c_bool, C.c_bool, P, LOG]
        lib.fmi3InstantiateCoSimulation.argtypes = [C.c_char_p, C.c_char_p, C.c_char_p, C.c_bool, C.c_bool, C.c_bool,
                                                    C.c_bool, P, C.c_size_t, P, LOG, P]
        lib.fmi3InstantiateScheduledExecution.argtypes = [C.c_char_p, C.c_char_p, C.c_char_p, C.c_bool, C.c_bool, P,
                                                          LOG, P, P]
        lib.fmi3EnterInitializationMode.argtypes = [P, C.c_bool, C.c_double, C.c_double, C.c_bool, C.c_double]
        lib.fmi3FreeInstance.restype = None
        for f in ("FreeInstance", "ExitInitializationMode", "EnterStepMode", "Terminate", "EnterContinuousTimeMode",
                  "EnterConfigurationMode", "UpdateDiscreteStates"):
            getattr(lib, "fmi3" + f).argtypes = [P] if f != "UpdateDiscreteStates" else [P] * 7

    def me(self):
        return self.lib.fmi3InstantiateModelExchange(b"i", self.token, self.resources, False, False, None, log)

    def cs(self, event_mode=False):
        return self.lib.fmi3InstantiateCoSimulation(b"i", self.token, self.resources, False, False, event_mode, False,
                                                    None, 0, None, log, None)

    def se(self):
        return self.lib.fmi3InstantiateScheduledExecution(b"i", self.token, self.resources, False, False, None, log,
                                                          None, None)


me_cs, se, events = Fmu(sys.argv[1]), Fmu(sys.argv[2]), Fmu(sys.argv[3])


def path(fmu, make, *steps):
    def reach():
        i = make()
        assert i, "no instance"
        for name, *args in steps:
            status = getattr(fmu.lib, "fmi3" + name)(i, *args)
            assert status == 0, name
        return i, fmu
    return reach


INIT = ("EnterInitializationMode", False, 0.0, 0.0, False, 0.0)
EXIT = ("ExitInitializationMode",)
TERM = ("Terminate",)
CT = ("EnterContinuousTimeMode",)
STATES = {
    "ME.Instantiated": path(me_cs, me_cs.me),
    "ME.Configuration": path(me_cs, me_cs.me, ("EnterConfigurationMode",)),
    "ME.Initialization": path(me_cs, me_cs.me, INIT),
    "ME.Event": path(me_cs, me_cs.me, INIT, EXIT),
    "ME.ContinuousTime": path(me_cs, me_cs.me, INIT, EXIT, CT),
    "ME.Terminated": path(me_cs, me_cs.me, INIT, EXIT, TERM),
    "CS.Instantiated": path(me_cs, me_cs.cs),
    "CS.Configuration": path(me_cs, me_cs.cs, ("EnterConfigurationMode",)),
    "CS.Initialization": path(me_cs, me_cs.cs, INIT),
    "CS.Step": path(me_cs, me_cs.cs, INIT, EXIT),
    "CS.Terminated": path(me_cs, me_cs.cs, INIT, EXIT, TERM),
    "CSE.Initialization": path(me_cs, lambda: me_cs.cs(True), INIT),
    "CSE.Event": path(me_cs, lambda: me_cs.cs(True), INIT, EXIT),
    "CSE.Step": path(me_cs, lambda: me_cs.cs(True), INIT, EXIT, ("EnterStepMode",)),
    "CSE.Terminated": path(me_cs, lambda: me_cs.cs(True), INIT, EXIT, TERM),
    "SE.Instantiated": path(se, se.se),
    "SE.Configuration": path(se, se.se, ("EnterConfigurationMode",)),
    "SE.Initialization": path(se, se.se, INIT),
    "SE.ClockActivation": path(se, se.se, INIT, EXIT),
    "SE.Terminated": path(se, se.se, INIT, EXIT, TERM),
}


# Configuration Mode is only open on an FMU with a structural parameter.
for state in [s for s in STATES if s.endswith(".Configuration")]:
    if not (se if state.startswith("SE") else me_cs).structural:
        del STATES[state]


def states(*names):
    return set(names)


INSTANTIATED = states("ME.Instantiated", "CS.Instantiated", "SE.Instantiated")
CONFIGURATION = states("ME.Configuration", "CS.Configuration", "SE.Configuration")
INITIALIZATION = states("ME.Initialization", "CS.Initialization", "CSE.Initialization", "SE.Initialization")
EVENT = states("ME.Event", "CSE.Event")
RUNNING = EVENT | states("ME.ContinuousTime", "CS.Step", "CSE.Step", "SE.ClockActivation")
TERMINATED = states("ME.Terminated", "CS.Terminated", "CSE.Terminated", "SE.Terminated")
ME_INSPECT = states("ME.Initialization", "ME.Event", "ME.ContinuousTime", "ME.Terminated")

GET = INITIALIZATION | RUNNING | TERMINATED
# Configuration Mode takes structural parameters, so a call with no variable is legal there.
SET_REAL = INSTANTIATED | CONFIGURATION | INITIALIZATION | RUNNING
SET_OTHER = SET_REAL - states("ME.ContinuousTime")
EMPTY = (None, 0, None, 0)
x = C.c_double()
n = C.c_size_t()
b = C.c_bool()
NO_REFS = (None, 0, None)

ALLOWED = {
    "GetFloat64": (GET, EMPTY), "GetInt32": (GET, EMPTY), "GetInt64": (GET, EMPTY), "GetBoolean": (GET, EMPTY),
    "GetString": (GET, EMPTY),
    "GetBinary": (GET, (None, 0, None, None, 0)),
    "SetFloat64": (SET_REAL, EMPTY), "SetInt32": (SET_OTHER, EMPTY), "SetInt64": (SET_OTHER, EMPTY),
    "SetBoolean": (SET_OTHER, EMPTY), "SetString": (SET_OTHER, EMPTY),
    "SetBinary": (SET_OTHER, (None, 0, None, None, 0)),
    "GetFloat32": (GET, EMPTY), "GetInt8": (GET, EMPTY), "GetUInt8": (GET, EMPTY), "GetInt16": (GET, EMPTY),
    "GetUInt16": (GET, EMPTY), "GetUInt32": (GET, EMPTY), "GetUInt64": (GET, EMPTY),
    "SetFloat32": (SET_REAL, EMPTY), "SetInt8": (SET_OTHER, EMPTY), "SetUInt8": (SET_OTHER, EMPTY),
    "SetInt16": (SET_OTHER, EMPTY), "SetUInt16": (SET_OTHER, EMPTY), "SetUInt32": (SET_OTHER, EMPTY),
    "SetUInt64": (SET_OTHER, EMPTY),
    "GetClock": (EVENT, NO_REFS), "SetClock": (EVENT, NO_REFS),
    "GetIntervalDecimal": (INITIALIZATION | EVENT | states("SE.ClockActivation"), (None, 0, None, None)),
    "GetIntervalFraction": (INITIALIZATION | EVENT | states("SE.ClockActivation"), (None, 0, None, None, None)),
    "GetShiftDecimal": (INITIALIZATION, NO_REFS), "GetShiftFraction": (INITIALIZATION, (None, 0, None, None)),
    "SetIntervalDecimal": (INITIALIZATION, NO_REFS), "SetIntervalFraction": (INITIALIZATION, (None, 0, None, None)),
    "SetShiftDecimal": (INITIALIZATION, NO_REFS), "SetShiftFraction": (INITIALIZATION, (None, 0, None, None)),
    "GetDirectionalDerivative": (GET, (None, 0, None, 0, None, 0, None, 0)),
    "GetOutputDerivatives": (states("CS.Step", "CSE.Step", "CS.Terminated", "CSE.Terminated"), (None, 0, None, None, 0)),
    "GetContinuousStates": (ME_INSPECT, (C.byref(x), 1)),
    "GetContinuousStateDerivatives": (ME_INSPECT, (C.byref(x), 1)),
    "GetNominalsOfContinuousStates": (ME_INSPECT, (C.byref(x), 1)),
    "GetEventIndicators": (ME_INSPECT, (None, 0)),
    "GetNumberOfContinuousStates": (states("ME.Instantiated", "ME.Event"), (C.byref(n),)),
    "GetNumberOfEventIndicators": (states("ME.Instantiated", "ME.Event"), (C.byref(n),)),
    "SetTime": (states("ME.ContinuousTime"), (C.c_double(0.0),)),
    "SetContinuousStates": (states("ME.ContinuousTime"), (C.byref(C.c_double(1.0)), C.c_size_t(1))),
    "CompletedIntegratorStep": (states("ME.ContinuousTime"), (C.c_bool(True), C.byref(b), C.byref(b))),
    "EnterContinuousTimeMode": (states("ME.Event"), ()),
    "EvaluateDiscreteStates": (EVENT, ()),
    "UpdateDiscreteStates": (EVENT, (None,) * 6),
    "EnterEventMode": (states("ME.ContinuousTime", "CSE.Step"), ()),
    "EnterStepMode": (states("CSE.Event"), ()),
    "DoStep": (states("CS.Step", "CSE.Step"), (C.c_double(0.0), C.c_double(0.1), C.c_bool(True), None, None, None, None)),
    "ActivateModelPartition": (states("SE.ClockActivation"), None),
    "EnterInitializationMode": (INSTANTIATED, INIT[1:]),
    "ExitInitializationMode": (INITIALIZATION, ()),
    "EnterConfigurationMode": (INSTANTIATED, ()),
    "ExitConfigurationMode": (CONFIGURATION, ()),
    "Terminate": (RUNNING, ()),
}
ANY_STATE = {"SetDebugLogging": (False, 0, None), "Reset": ()}

mismatches = 0
for call, (allowed, args) in ALLOWED.items():
    allowed = allowed & set(STATES)
    if call == "EnterConfigurationMode":
        allowed = {s for s in allowed if (se if s.startswith("SE") else me_cs).structural}
    legal = set()
    for state, reach in STATES.items():
        i, fmu = reach()
        fn = getattr(fmu.lib, "fmi3" + call)
        if args is None:
            status = fn(P(i), C.c_uint32(fmu.clock), C.c_double(0.0))
        else:
            status = fn(P(i), *[C.c_double(a) if isinstance(a, float) else
                                C.c_bool(a) if isinstance(a, bool) else
                                C.c_size_t(a) if isinstance(a, int) else a for a in args])
        if status == 0:
            legal.add(state)
        fmu.lib.fmi3FreeInstance(i)
    if legal != allowed:
        mismatches += 1
        print("MISMATCH %s: accepted, not allowed: %s; refused, allowed: %s"
              % (call, sorted(legal - allowed), sorted(allowed - legal)))
    print("%s: %d states" % (call, len(legal)))
for call, args in ANY_STATE.items():
    refused = []
    for state, reach in STATES.items():
        i, fmu = reach()
        fn = getattr(fmu.lib, "fmi3" + call)
        status = fn(P(i), *[C.c_bool(a) if isinstance(a, bool) else C.c_size_t(a) if isinstance(a, int) else a for a in args])
        if status != 0:
            refused.append(state)
        fmu.lib.fmi3FreeInstance(i)
    print("%s: refused in %s" % (call, refused or "no state"))
print("%d mismatches" % mismatches)

# An illegal call moves the instance to the error state: only reading and freeing are left.
i, fmu = STATES["CS.Instantiated"]()
print("illegal EnterEventMode: %d, then EnterInitializationMode: %d, then GetFloat64: %d"
      % (fmu.lib.fmi3EnterEventMode(P(i)), fmu.lib.fmi3EnterInitializationMode(i, False, 0.0, 0.0, False, 0.0),
         fmu.lib.fmi3GetFloat64(P(i), None, C.c_size_t(0), None, C.c_size_t(0))))
fmu.lib.fmi3FreeInstance(i)

i, fmu = STATES["ME.Instantiated"]()
print("illegal GetAdjointDerivative: %d, then EnterInitializationMode: %d"
      % (fmu.lib.fmi3GetAdjointDerivative(P(i), None, C.c_size_t(0), None, C.c_size_t(0), None, C.c_size_t(0), None,
                                          C.c_size_t(0)),
         fmu.lib.fmi3EnterInitializationMode(i, False, 0.0, 0.0, False, 0.0)))
fmu.lib.fmi3FreeInstance(i)


def get_zc(i):
    vr, value = C.c_uint32(events.vr["__zc_0"]), C.c_double()
    return events.lib.fmi3GetFloat64(P(i), C.byref(vr), C.c_size_t(1), C.byref(value), C.c_size_t(1))


# An event indicator is an ordinary variable, whatever the interface: every state with
# fmi3GetFloat64 can read it. Co-Simulation reads it again after a step over its event.
DOSTEP = ("DoStep", C.c_double(0.0), C.c_double(1.0), C.c_bool(True), None, None, None, None)
cs_event = lambda: events.cs(True)
ZC = {
    "ME.Initialization": path(events, events.me, INIT),
    "ME.Event": path(events, events.me, INIT, EXIT),
    "ME.ContinuousTime": path(events, events.me, INIT, EXIT, CT),
    "ME.Terminated": path(events, events.me, INIT, EXIT, TERM),
    "CS.Initialization": path(events, events.cs, INIT),
    "CS.Step": path(events, events.cs, INIT, EXIT),
    "CS.Step, after DoStep": path(events, events.cs, INIT, EXIT, DOSTEP),
    "CS.Terminated": path(events, events.cs, INIT, EXIT, TERM),
    "CSE.Event": path(events, cs_event, INIT, EXIT),
    "CSE.Step": path(events, cs_event, INIT, EXIT, ("EnterStepMode",)),
    "CSE.Step, after DoStep": path(events, cs_event, INIT, EXIT, ("EnterStepMode",), DOSTEP),
}
for state, reach in ZC.items():
    i, fmu = reach()
    print("%s: GetFloat64 of __zc_0: %d" % (state, get_zc(i)))
    fmu.lib.fmi3FreeInstance(i)

# Configuration Mode refuses a variable that is not a structural parameter, into the error state.
for name, make in (("ME", events.me), ("CS", events.cs)):
    i = make()
    events.lib.fmi3EnterConfigurationMode(i)
    vr, value = C.c_uint32(events.vr["p"]), C.c_double(2.0)
    print("%s: SetFloat64 of p in Configuration Mode: %d, then ExitConfigurationMode: %d"
          % (name, events.lib.fmi3SetFloat64(P(i), C.byref(vr), C.c_size_t(1), C.byref(value), C.c_size_t(1)),
             events.lib.fmi3ExitConfigurationMode(P(i))))
    events.lib.fmi3FreeInstance(i)
