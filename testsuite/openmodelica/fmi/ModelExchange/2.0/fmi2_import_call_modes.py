"""Build CallModes2.fmu, a small hand-written FMI 2.0 Model Exchange FMU.

usage: fmi2_import_call_modes.py
(the C compiler is $OMC_NATIVE_CC, which rtest sets; default cc)

Model: der(x) = -1, x(0) = 1, output y = x, one event indicator z = x - 0.5.
At the event at x = 0.5 the FMU sets x back to 1 and increments the output n.

The FMU checks the FMI 2.0 call table (FMI 2.0.5, section 3.2.3) like the
Reference FMUs do: a call in a state where the table does not allow it returns
fmi2Error and logs "Illegal call sequence". fmi2SetTime and
fmi2SetContinuousStates are allowed only in Continuous-Time Mode (the FMU has
a state, so it is not a pure discrete-time FMU). OpenModelica FMUs accept
these calls in all states, so they cannot test the importer.
"""
import os
import platform
import shlex
import subprocess
import zipfile

NAME = "CallModes2"

C_SOURCE = r"""
#include <stdlib.h>
#include <stddef.h>

typedef void* fmi2Component;
typedef void* fmi2ComponentEnvironment;
typedef void* fmi2FMUstate;
typedef unsigned int fmi2ValueReference;
typedef double fmi2Real;
typedef int fmi2Integer;
typedef int fmi2Boolean;
typedef const char* fmi2String;
typedef char fmi2Byte;
typedef enum { fmi2OK, fmi2Warning, fmi2Discard, fmi2Error, fmi2Fatal, fmi2Pending } fmi2Status;
typedef enum { fmi2ModelExchange, fmi2CoSimulation } fmi2Type;
typedef struct {
  void (*logger)(fmi2ComponentEnvironment, fmi2String, fmi2Status, fmi2String, fmi2String, ...);
  void* (*allocateMemory)(size_t, size_t);
  void (*freeMemory)(void*);
  void (*stepFinished)(fmi2ComponentEnvironment, fmi2Status);
  fmi2ComponentEnvironment componentEnvironment;
} fmi2CallbackFunctions;
typedef struct {
  fmi2Boolean newDiscreteStatesNeeded;
  fmi2Boolean terminateSimulation;
  fmi2Boolean nominalsOfContinuousStatesChanged;
  fmi2Boolean valuesOfContinuousStatesChanged;
  fmi2Boolean nextEventTimeDefined;
  fmi2Real nextEventTime;
} fmi2EventInfo;

#if defined(_WIN32)
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default")))
#endif

enum { INSTANTIATED = 1, INIT = 2, EVENT = 4, CONT = 8, TERMINATED = 16 };

typedef struct {
  const fmi2CallbackFunctions* cb;
  int state;
  double time, x;
  int n;
} Inst;

/* the call table: return fmi2Error if the call is not allowed in this state */
#define ALLOWED(f, states) \
  do { \
    if (!(c->state & (states))) { \
      c->cb->logger(c->cb->componentEnvironment, "CallModes2", fmi2Error, "logStatusError", \
                    f ": Illegal call sequence."); \
      return fmi2Error; \
    } \
  } while (0)

EXPORT const char* fmi2GetTypesPlatform(void) { return "default"; }
EXPORT const char* fmi2GetVersion(void) { return "2.0"; }
EXPORT fmi2Status fmi2SetDebugLogging(fmi2Component c, fmi2Boolean on, size_t n, const fmi2String cat[]) { return fmi2OK; }
EXPORT fmi2Component fmi2Instantiate(fmi2String name, fmi2Type type, fmi2String guid, fmi2String res,
                                     const fmi2CallbackFunctions* functions, fmi2Boolean visible, fmi2Boolean loggingOn) {
  Inst* c;
  if (type != fmi2ModelExchange) return NULL;
  c = calloc(1, sizeof(Inst));
  c->cb = functions;
  c->state = INSTANTIATED;
  c->x = 1.0;
  return c;
}
EXPORT void fmi2FreeInstance(fmi2Component c) { free(c); }
EXPORT fmi2Status fmi2SetupExperiment(fmi2Component cc, fmi2Boolean tolDef, fmi2Real tol, fmi2Real start,
                                      fmi2Boolean stopDef, fmi2Real stop) {
  Inst* c = cc;
  ALLOWED("fmi2SetupExperiment", INSTANTIATED);
  c->time = start;
  return fmi2OK;
}
EXPORT fmi2Status fmi2EnterInitializationMode(fmi2Component cc) {
  Inst* c = cc;
  ALLOWED("fmi2EnterInitializationMode", INSTANTIATED);
  c->state = INIT;
  return fmi2OK;
}
EXPORT fmi2Status fmi2ExitInitializationMode(fmi2Component cc) {
  Inst* c = cc;
  ALLOWED("fmi2ExitInitializationMode", INIT);
  c->state = EVENT;
  return fmi2OK;
}
EXPORT fmi2Status fmi2Terminate(fmi2Component cc) {
  Inst* c = cc;
  ALLOWED("fmi2Terminate", EVENT | CONT);
  c->state = TERMINATED;
  return fmi2OK;
}
EXPORT fmi2Status fmi2Reset(fmi2Component c) { return fmi2Error; }
EXPORT fmi2Status fmi2GetReal(fmi2Component cc, const fmi2ValueReference vr[], size_t nvr, fmi2Real v[]) {
  Inst* c = cc; size_t i;
  for (i = 0; i < nvr; i++) {
    if (vr[i] == 0 || vr[i] == 2) v[i] = c->x; else if (vr[i] == 1) v[i] = -1.0; else return fmi2Error;
  }
  return fmi2OK;
}
EXPORT fmi2Status fmi2GetInteger(fmi2Component cc, const fmi2ValueReference vr[], size_t nvr, fmi2Integer v[]) {
  Inst* c = cc; size_t i;
  for (i = 0; i < nvr; i++) {
    if (vr[i] == 3) v[i] = c->n; else return fmi2Error;
  }
  return fmi2OK;
}
EXPORT fmi2Status fmi2GetBoolean(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Boolean v[]) { return nvr ? fmi2Error : fmi2OK; }
EXPORT fmi2Status fmi2GetString(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2String v[]) { return nvr ? fmi2Error : fmi2OK; }
EXPORT fmi2Status fmi2SetReal(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Real v[]) { return nvr ? fmi2Error : fmi2OK; }
EXPORT fmi2Status fmi2SetInteger(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Integer v[]) { return nvr ? fmi2Error : fmi2OK; }
EXPORT fmi2Status fmi2SetBoolean(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Boolean v[]) { return nvr ? fmi2Error : fmi2OK; }
EXPORT fmi2Status fmi2SetString(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2String v[]) { return nvr ? fmi2Error : fmi2OK; }
EXPORT fmi2Status fmi2GetFMUstate(fmi2Component c, fmi2FMUstate* s) { return fmi2Error; }
EXPORT fmi2Status fmi2SetFMUstate(fmi2Component c, fmi2FMUstate s) { return fmi2Error; }
EXPORT fmi2Status fmi2FreeFMUstate(fmi2Component c, fmi2FMUstate* s) { return fmi2Error; }
EXPORT fmi2Status fmi2SerializedFMUstateSize(fmi2Component c, fmi2FMUstate s, size_t* n) { return fmi2Error; }
EXPORT fmi2Status fmi2SerializeFMUstate(fmi2Component c, fmi2FMUstate s, fmi2Byte b[], size_t n) { return fmi2Error; }
EXPORT fmi2Status fmi2DeSerializeFMUstate(fmi2Component c, const fmi2Byte b[], size_t n, fmi2FMUstate* s) { return fmi2Error; }
EXPORT fmi2Status fmi2GetDirectionalDerivative(fmi2Component c, const fmi2ValueReference u[], size_t nu,
    const fmi2ValueReference z[], size_t nz, const fmi2Real du[], fmi2Real dz[]) { return fmi2Error; }
EXPORT fmi2Status fmi2EnterEventMode(fmi2Component cc) {
  Inst* c = cc;
  ALLOWED("fmi2EnterEventMode", EVENT | CONT);
  c->state = EVENT;
  return fmi2OK;
}
EXPORT fmi2Status fmi2NewDiscreteStates(fmi2Component cc, fmi2EventInfo* ei) {
  Inst* c = cc;
  ALLOWED("fmi2NewDiscreteStates", EVENT);
  ei->newDiscreteStatesNeeded = 0;
  ei->terminateSimulation = 0;
  ei->nominalsOfContinuousStatesChanged = 0;
  ei->valuesOfContinuousStatesChanged = 0;
  ei->nextEventTimeDefined = 0;
  ei->nextEventTime = 0.0;
  if (c->x <= 0.5 + 1e-6) {
    c->x = 1.0;
    c->n++;
    ei->valuesOfContinuousStatesChanged = 1;
  }
  return fmi2OK;
}
EXPORT fmi2Status fmi2EnterContinuousTimeMode(fmi2Component cc) {
  Inst* c = cc;
  ALLOWED("fmi2EnterContinuousTimeMode", EVENT);
  c->state = CONT;
  return fmi2OK;
}
EXPORT fmi2Status fmi2CompletedIntegratorStep(fmi2Component cc, fmi2Boolean noSet, fmi2Boolean* enterEventMode,
                                              fmi2Boolean* terminate) {
  Inst* c = cc;
  ALLOWED("fmi2CompletedIntegratorStep", CONT);
  *enterEventMode = 0;
  *terminate = 0;
  return fmi2OK;
}
EXPORT fmi2Status fmi2SetTime(fmi2Component cc, fmi2Real t) {
  Inst* c = cc;
  ALLOWED("fmi2SetTime", CONT);
  c->time = t;
  return fmi2OK;
}
EXPORT fmi2Status fmi2SetContinuousStates(fmi2Component cc, const fmi2Real x[], size_t nx) {
  Inst* c = cc;
  ALLOWED("fmi2SetContinuousStates", CONT);
  c->x = x[0];
  return fmi2OK;
}
EXPORT fmi2Status fmi2GetDerivatives(fmi2Component cc, fmi2Real dx[], size_t nx) {
  Inst* c = cc;
  ALLOWED("fmi2GetDerivatives", INIT | EVENT | CONT | TERMINATED);
  dx[0] = -1.0;
  return fmi2OK;
}
EXPORT fmi2Status fmi2GetEventIndicators(fmi2Component cc, fmi2Real z[], size_t nz) {
  Inst* c = cc;
  ALLOWED("fmi2GetEventIndicators", INIT | EVENT | CONT | TERMINATED);
  z[0] = c->x - 0.5;
  return fmi2OK;
}
EXPORT fmi2Status fmi2GetContinuousStates(fmi2Component cc, fmi2Real x[], size_t nx) {
  Inst* c = cc;
  ALLOWED("fmi2GetContinuousStates", INIT | EVENT | CONT | TERMINATED);
  x[0] = c->x;
  return fmi2OK;
}
EXPORT fmi2Status fmi2GetNominalsOfContinuousStates(fmi2Component c, fmi2Real n[], size_t nx) { n[0] = 1.0; return fmi2OK; }
"""

MODEL_DESCRIPTION = """<?xml version="1.0" encoding="UTF-8"?>
<fmiModelDescription fmiVersion="2.0" modelName="CallModes2"
  guid="{8c2e4a61-3f5d-4b7a-9e1c-6d0b2f4a8e17}" numberOfEventIndicators="1">
  <ModelExchange modelIdentifier="CallModes2"/>
  <DefaultExperiment startTime="0" stopTime="1.2" tolerance="1e-6"/>
  <ModelVariables>
    <ScalarVariable name="x" valueReference="0" causality="local" variability="continuous" initial="exact"><Real start="1"/></ScalarVariable>
    <ScalarVariable name="der(x)" valueReference="1" causality="local" variability="continuous"><Real derivative="1"/></ScalarVariable>
    <ScalarVariable name="y" valueReference="2" causality="output" variability="continuous"><Real/></ScalarVariable>
    <ScalarVariable name="n" valueReference="3" causality="output" variability="discrete"><Integer/></ScalarVariable>
  </ModelVariables>
  <ModelStructure>
    <Outputs>
      <Unknown index="3" dependencies="1"/>
      <Unknown index="4" dependencies=""/>
    </Outputs>
    <Derivatives>
      <Unknown index="2" dependencies=""/>
    </Derivatives>
    <InitialUnknowns>
      <Unknown index="2" dependencies=""/>
      <Unknown index="3" dependencies=""/>
      <Unknown index="4" dependencies=""/>
    </InitialUnknowns>
  </ModelStructure>
</fmiModelDescription>
"""


def main():
    system = platform.system()
    if system == "Windows":
        folder, suffix = "win64", ".dll"
    elif system == "Darwin":
        folder, suffix = "darwin64", ".dylib"
    else:
        folder, suffix = "linux64", ".so"
    src = NAME + ".c"
    lib = NAME + suffix
    with open(src, "w") as f:
        f.write(C_SOURCE)
    cc = shlex.split(os.environ.get("OMC_NATIVE_CC", "cc"))
    subprocess.check_call(cc + ["-shared", "-fPIC", "-o", lib, src])
    with zipfile.ZipFile(NAME + ".fmu", "w") as z:
        z.writestr("modelDescription.xml", MODEL_DESCRIPTION)
        z.write(lib, "binaries/%s/%s" % (folder, lib))


if __name__ == "__main__":
    main()
