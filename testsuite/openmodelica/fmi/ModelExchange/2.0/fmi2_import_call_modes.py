"""Build CallModes2.fmu, a small hand-written FMI 2.0 Model Exchange FMU.

usage: fmi2_import_call_modes.py <directory of fmi2Functions.h>
(the C compiler is $OMC_NATIVE_CC with $OMC_NATIVE_CFLAGS, which rtest sets;
default cc)

Model: der(x) = -x, x(t0) = 1, output y = x, one event indicator z = x - 0.5.
At the event at x = 0.5 the FMU sets x back to 1.

The FMU checks the FMI 2.0 calling sequence (FMI 2.0.5, sections 3.2.2 to
3.2.4) like the Reference FMUs do. A call that the sequence does not allow
returns fmi2Error and logs "Illegal call sequence":

- the call table of section 3.2.3, also for the getters. fmi2SetTime and
  fmi2SetContinuousStates are allowed only in Continuous-Time Mode (the FMU
  has a state, so it is not a pure discrete-time FMU);
- fmi2EnterContinuousTimeMode only after fmi2NewDiscreteStates returned
  newDiscreteStatesNeeded = fmi2False. At each event the FMU needs two passes;
- fmi2SetTime must not go back over the last fmi2CompletedIntegratorStep or
  fmi2EnterEventMode (section 3.2.2).

nextEventTimeDefined is always fmi2False, with nextEventTime = t0 + 0.3,
which the importer must ignore. The output nEvents counts the calls of
fmi2EnterEventMode.

OpenModelica FMUs accept these calls in all states, so they cannot test the
importer.
"""
import os
import platform
import shlex
import subprocess
import sys
import zipfile

NAME = "CallModes2"

C_SOURCE = r"""
#include <stdlib.h>
#include "fmi2Functions.h"

enum { INSTANTIATED = 1, INIT = 2, EVENT = 4, CONT = 8, TERMINATED = 16 };

typedef struct {
  const fmi2CallbackFunctions* cb;
  int state;
  int passes;    /* fmi2NewDiscreteStates calls still needed at this event */
  double time;
  double tMin;   /* time of the last fmi2CompletedIntegratorStep or fmi2EnterEventMode */
  double x;
  int nEvents;
} Inst;

static fmi2Status illegal(Inst* c, const char* f, const char* why)
{
  c->cb->logger(c->cb->componentEnvironment, "CallModes2", fmi2Error, "logStatusError",
                "%s: Illegal call sequence (%s).", f, why);
  return fmi2Error;
}

/* the call table: return fmi2Error if the call is not allowed in this state */
#define ALLOWED(f, states) \
  do { \
    if (!(c->state & (states))) return illegal(c, f, "state"); \
  } while (0)

const char* fmi2GetTypesPlatform(void) { return fmi2TypesPlatform; }
const char* fmi2GetVersion(void) { return fmi2Version; }
fmi2Status fmi2SetDebugLogging(fmi2Component c, fmi2Boolean on, size_t n, const fmi2String cat[]) { return fmi2OK; }
fmi2Component fmi2Instantiate(fmi2String name, fmi2Type type, fmi2String guid, fmi2String res,
                              const fmi2CallbackFunctions* functions, fmi2Boolean visible, fmi2Boolean loggingOn) {
  Inst* c;
  if (type != fmi2ModelExchange) return NULL;
  c = calloc(1, sizeof(Inst));
  c->cb = functions;
  c->state = INSTANTIATED;
  c->x = 1.0;
  return c;
}
void fmi2FreeInstance(fmi2Component c) { free(c); }
fmi2Status fmi2SetupExperiment(fmi2Component cc, fmi2Boolean tolDef, fmi2Real tol, fmi2Real start,
                               fmi2Boolean stopDef, fmi2Real stop) {
  Inst* c = cc;
  ALLOWED("fmi2SetupExperiment", INSTANTIATED);
  c->time = start;
  c->tMin = start;
  return fmi2OK;
}
fmi2Status fmi2EnterInitializationMode(fmi2Component cc) {
  Inst* c = cc;
  ALLOWED("fmi2EnterInitializationMode", INSTANTIATED);
  c->state = INIT;
  return fmi2OK;
}
fmi2Status fmi2ExitInitializationMode(fmi2Component cc) {
  Inst* c = cc;
  ALLOWED("fmi2ExitInitializationMode", INIT);
  c->state = EVENT;
  c->passes = 2;
  return fmi2OK;
}
fmi2Status fmi2Terminate(fmi2Component cc) {
  Inst* c = cc;
  ALLOWED("fmi2Terminate", EVENT | CONT);
  c->state = TERMINATED;
  return fmi2OK;
}
fmi2Status fmi2Reset(fmi2Component c) { return fmi2Error; }
fmi2Status fmi2GetReal(fmi2Component cc, const fmi2ValueReference vr[], size_t nvr, fmi2Real v[]) {
  Inst* c = cc; size_t i;
  ALLOWED("fmi2GetReal", INIT | EVENT | CONT | TERMINATED);
  for (i = 0; i < nvr; i++) {
    if (vr[i] == 0 || vr[i] == 2) v[i] = c->x; else if (vr[i] == 1) v[i] = -c->x; else return fmi2Error;
  }
  return fmi2OK;
}
fmi2Status fmi2GetInteger(fmi2Component cc, const fmi2ValueReference vr[], size_t nvr, fmi2Integer v[]) {
  Inst* c = cc; size_t i;
  ALLOWED("fmi2GetInteger", INIT | EVENT | CONT | TERMINATED);
  for (i = 0; i < nvr; i++) {
    if (vr[i] == 3) v[i] = c->nEvents; else return fmi2Error;
  }
  return fmi2OK;
}
fmi2Status fmi2GetBoolean(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Boolean v[]) { return nvr ? fmi2Error : fmi2OK; }
fmi2Status fmi2GetString(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2String v[]) { return nvr ? fmi2Error : fmi2OK; }
fmi2Status fmi2SetReal(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Real v[]) { return nvr ? fmi2Error : fmi2OK; }
fmi2Status fmi2SetInteger(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Integer v[]) { return nvr ? fmi2Error : fmi2OK; }
fmi2Status fmi2SetBoolean(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Boolean v[]) { return nvr ? fmi2Error : fmi2OK; }
fmi2Status fmi2SetString(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2String v[]) { return nvr ? fmi2Error : fmi2OK; }
fmi2Status fmi2EnterEventMode(fmi2Component cc) {
  Inst* c = cc;
  ALLOWED("fmi2EnterEventMode", EVENT | CONT);
  c->nEvents++;
  c->state = EVENT;
  c->passes = 2;
  c->tMin = c->time;
  return fmi2OK;
}
fmi2Status fmi2NewDiscreteStates(fmi2Component cc, fmi2EventInfo* ei) {
  Inst* c = cc;
  ALLOWED("fmi2NewDiscreteStates", EVENT);
  ei->terminateSimulation = fmi2False;
  ei->nominalsOfContinuousStatesChanged = fmi2False;
  ei->valuesOfContinuousStatesChanged = fmi2False;
  ei->nextEventTimeDefined = fmi2False;
  ei->nextEventTime = c->time + 0.3;
  /* the first pass resets x, the second pass only confirms */
  if (c->passes == 2 && c->x <= 0.5 + 1e-6) {
    c->x = 1.0;
    ei->valuesOfContinuousStatesChanged = fmi2True;
  }
  if (c->passes > 0) c->passes--;
  ei->newDiscreteStatesNeeded = c->passes > 0;
  return fmi2OK;
}
fmi2Status fmi2EnterContinuousTimeMode(fmi2Component cc) {
  Inst* c = cc;
  ALLOWED("fmi2EnterContinuousTimeMode", EVENT);
  if (c->passes > 0) return illegal(c, "fmi2EnterContinuousTimeMode", "newDiscreteStatesNeeded");
  c->state = CONT;
  return fmi2OK;
}
fmi2Status fmi2CompletedIntegratorStep(fmi2Component cc, fmi2Boolean noSet, fmi2Boolean* enterEventMode,
                                       fmi2Boolean* terminate) {
  Inst* c = cc;
  ALLOWED("fmi2CompletedIntegratorStep", CONT);
  c->tMin = c->time;
  *enterEventMode = fmi2False;
  *terminate = fmi2False;
  return fmi2OK;
}
fmi2Status fmi2SetTime(fmi2Component cc, fmi2Real t) {
  Inst* c = cc;
  ALLOWED("fmi2SetTime", CONT);
  if (t < c->tMin) return illegal(c, "fmi2SetTime", "time goes back");
  c->time = t;
  return fmi2OK;
}
fmi2Status fmi2SetContinuousStates(fmi2Component cc, const fmi2Real x[], size_t nx) {
  Inst* c = cc;
  ALLOWED("fmi2SetContinuousStates", CONT);
  c->x = x[0];
  return fmi2OK;
}
fmi2Status fmi2GetDerivatives(fmi2Component cc, fmi2Real dx[], size_t nx) {
  Inst* c = cc;
  ALLOWED("fmi2GetDerivatives", INIT | EVENT | CONT | TERMINATED);
  dx[0] = -c->x;
  return fmi2OK;
}
fmi2Status fmi2GetEventIndicators(fmi2Component cc, fmi2Real z[], size_t nz) {
  Inst* c = cc;
  ALLOWED("fmi2GetEventIndicators", INIT | EVENT | CONT | TERMINATED);
  z[0] = c->x - 0.5;
  return fmi2OK;
}
fmi2Status fmi2GetContinuousStates(fmi2Component cc, fmi2Real x[], size_t nx) {
  Inst* c = cc;
  ALLOWED("fmi2GetContinuousStates", INIT | EVENT | CONT | TERMINATED);
  x[0] = c->x;
  return fmi2OK;
}
fmi2Status fmi2GetNominalsOfContinuousStates(fmi2Component cc, fmi2Real n[], size_t nx) {
  Inst* c = cc;
  ALLOWED("fmi2GetNominalsOfContinuousStates", INSTANTIATED | EVENT | CONT | TERMINATED);
  n[0] = 1.0;
  return fmi2OK;
}
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
    <ScalarVariable name="nEvents" valueReference="3" causality="output" variability="discrete"><Integer/></ScalarVariable>
  </ModelVariables>
  <ModelStructure>
    <Outputs>
      <Unknown index="3" dependencies="1"/>
      <Unknown index="4" dependencies=""/>
    </Outputs>
    <Derivatives>
      <Unknown index="2" dependencies="1"/>
    </Derivatives>
    <InitialUnknowns>
      <Unknown index="2" dependencies=""/>
      <Unknown index="3" dependencies=""/>
      <Unknown index="4" dependencies=""/>
    </InitialUnknowns>
  </ModelStructure>
</fmiModelDescription>
"""


def compile_library(src, lib, include):
    cc = shlex.split(os.environ.get("OMC_NATIVE_CC", "cc"))
    cflags = shlex.split(os.environ.get("OMC_NATIVE_CFLAGS", ""))
    if os.path.basename(cc[-1]).lower() in ("cl", "cl.exe", "clang-cl", "clang-cl.exe"):
        cmd = cc + ["-nologo", "-LD"] + cflags + ["-I" + include, src, "-Fe" + lib]
    else:
        pic = [] if platform.system() == "Windows" else ["-fPIC"]
        cmd = cc + cflags + ["-shared"] + pic + ["-I" + include, "-o", lib, src]
    subprocess.check_call(cmd)


def main():
    include = sys.argv[1]
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
    compile_library(src, lib, include)
    with zipfile.ZipFile(NAME + ".fmu", "w") as z:
        z.writestr("modelDescription.xml", MODEL_DESCRIPTION)
        z.write(lib, "binaries/%s/%s" % (folder, lib))


if __name__ == "__main__":
    main()
