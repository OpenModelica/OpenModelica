
// array of value references of states
#if NUMBER_OF_REALS>0
fmiValueReference vrStates[NUMBER_OF_STATES] = STATES;
#endif


static fmiBoolean invalidNumber(ModelInstance* comp, const char* f, const char* arg, int n, int nExpected){
    if (n != nExpected) {
        comp->state = modelError;
        comp->functions.logger(comp, comp->instanceName, fmiError, "error",
                "%s: Invalid argument %s = %d. Expected %d.", f, arg, n, nExpected);
        return fmiTrue;
    }
    return fmiFalse;
}

static fmiBoolean invalidState(ModelInstance* comp, const char* f, int statesExpected){
    if (!comp)
        return fmiTrue;
    if (!(comp->state & statesExpected)) {
        comp->state = modelError;
        comp->functions.logger(comp, comp->instanceName, fmiError, "error",
                "%s: Illegal call sequence.", f);
        return fmiTrue;
    }
    return fmiFalse;
}

static fmiBoolean nullPointer(ModelInstance* comp, const char* f, const char* arg, const void* p){
    if (!p) {
        comp->state = modelError;
        comp->functions.logger(comp, comp->instanceName, fmiError, "error",
                "%s: Invalid argument %s = NULL.", f, arg);
        return fmiTrue;
    }
    return fmiFalse;
}

static fmiBoolean vrOutOfRange(ModelInstance* comp, const char* f, fmiValueReference vr, int end) {
    if (vr >= end) {
        comp->functions.logger(comp, comp->instanceName, fmiError, "error",
                "%s: Illegal value reference %u.", f, vr);
        comp->state = fmiError;
        return fmiTrue;
    }
    return fmiFalse;
}

// ---------------------------------------------------------------------------
// FMI functions: class methods not depending of a specific model instance
// ---------------------------------------------------------------------------

const char* fmiGetModelTypesPlatform() {
    return fmiModelTypesPlatform;
}

const char* fmiGetVersion() {
    return fmiVersion;
}

// ---------------------------------------------------------------------------
// FMI functions: creation and destruction of a model instance
// ---------------------------------------------------------------------------

fmiComponent fmiInstantiateModel(fmiString instanceName, fmiString GUID,
        fmiCallbackFunctions functions, fmiBoolean loggingOn) {
    ModelInstance* comp;
    if (!functions.logger)
        return NULL;
    if (!functions.allocateMemory || !functions.freeMemory){
        functions.logger(NULL, instanceName, fmiError, "error",
                "fmiInstantiateModel: Missing callback function.");
        return NULL;
    }
    if (!instanceName || strlen(instanceName)==0) {
        functions.logger(NULL, instanceName, fmiError, "error",
                "fmiInstantiateModel: Missing instance name.");
        return NULL;
    }
    if (strcmp(GUID, MODEL_GUID)) {
        functions.logger(NULL, instanceName, fmiError, "error",
                "fmiInstantiateModel: Wrong GUID %s. Expected %s.", GUID, MODEL_GUID);
        return NULL;
    }
    comp = (ModelInstance *)functions.allocateMemory(1, sizeof(ModelInstance));
    if (comp) {
        comp->r = calloc(NUMBER_OF_REALS,    sizeof(fmiReal));
        comp->i = calloc(NUMBER_OF_INTEGERS, sizeof(fmiInteger));
        comp->b = calloc(NUMBER_OF_BOOLEANS, sizeof(fmiBoolean));
        comp->s = calloc(NUMBER_OF_STRINGS,  sizeof(fmiString));
        comp->isPositive = calloc(NUMBER_OF_EVENT_INDICATORS, sizeof(fmiBoolean));
    }
    if (!comp || !comp->r || !comp->i || !comp->b || !comp->s || !comp->isPositive) {
        functions.logger(NULL, instanceName, fmiError, "error",
                "fmiInstantiateModel: Out of memory.");
        return NULL;
    }
    if (comp->loggingOn) comp->functions.logger(NULL, instanceName, fmiOK, "log",
            "fmiInstantiateModel: GUID=%s", GUID);
    comp->instanceName = instanceName;
    comp->GUID = GUID;
    comp->functions = functions;
    comp->loggingOn = loggingOn;
    comp->state = modelInstantiated;
    setStartValues(comp); // to be implemented by the includer of this file
    return comp;
}

fmiStatus fmiSetDebugLogging(fmiComponent c, fmiBoolean loggingOn) {
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiSetDebugLogging", not_modelError))
         return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiSetDebugLogging: loggingOn=%d", loggingOn);
    comp->loggingOn = loggingOn;
    return fmiOK;
}

void fmiFreeModelInstance(fmiComponent c) {
    ModelInstance* comp = (ModelInstance *)c;
    if (!comp) return;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiFreeModelInstance");
    if (comp->r) comp->functions.freeMemory(comp->r);
    if (comp->i) comp->functions.freeMemory(comp->i);
    if (comp->b) comp->functions.freeMemory(comp->b);
    if (comp->s) {
        int i;
        for (i=0; i<NUMBER_OF_STRINGS; i++){
            if (comp->s[i]) comp->functions.freeMemory(comp->s[i]);
        }
        comp->functions.freeMemory(comp->s);
    }
    comp->functions.freeMemory(comp);
}

// ---------------------------------------------------------------------------
// FMI functions: set variable values in the FMU
// ---------------------------------------------------------------------------

fmiStatus fmiSetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiReal value[]){
    int i;
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiSetReal", modelInstantiated|modelInitialized))
         return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiSetReal", "vr[]", vr))
         return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiSetReal", "value[]", value))
         return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiSetReal: nvr = %d", nvr);
    // no check wether setting the value is allowed in the current state
    for (i=0; i<nvr; i++) {
       if (vrOutOfRange(comp, "fmiSetReal", vr[i], NUMBER_OF_REALS))
           return fmiError;
       if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiSetReal: #r%d# = %.16g", vr[i], value[i]);
       comp->r[vr[i]] = value[i];
    }
    return fmiOK;
}

fmiStatus fmiSetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger value[]){
    int i;
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiSetInteger", modelInstantiated|modelInitialized))
         return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiSetInteger", "vr[]", vr))
         return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiSetInteger", "value[]", value))
         return fmiError;
    if (comp->loggingOn)
        comp->functions.logger(c, comp->instanceName, fmiOK, "log", "fmiSetInteger: nvr = %d",  nvr);
    for (i=0; i<nvr; i++) {
       if (vrOutOfRange(comp, "fmiSetInteger", vr[i], NUMBER_OF_INTEGERS))
           return fmiError;
       if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiSetInteger: #i%d# = %d", vr[i], value[i]);
        comp->i[vr[i]] = value[i];
    }
    return fmiOK;
}

fmiStatus fmiSetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiBoolean value[]){
    int i;
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiSetBoolean", modelInstantiated|modelInitialized))
         return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiSetBoolean", "vr[]", vr))
         return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiSetBoolean", "value[]", value))
         return fmiError;
    if (comp->loggingOn)
        comp->functions.logger(c, comp->instanceName, fmiOK, "log", "fmiSetBoolean: nvr = %d",  nvr);
    for (i=0; i<nvr; i++) {
        if (vrOutOfRange(comp, "fmiSetBoolean", vr[i], NUMBER_OF_BOOLEANS))
            return fmiError;
       if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiSetBoolean: #b%d# = %s", vr[i], value[i] ? "true" : "false");
        comp->b[vr[i]] = value[i];
    }
    return fmiOK;
}

fmiStatus fmiSetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiString value[]){
    int i, n;
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiSetString", modelInstantiated|modelInitialized))
         return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiSetString", "vr[]", vr))
         return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiSetString", "value[]", value))
         return fmiError;
    if (comp->loggingOn)
        comp->functions.logger(c, comp->instanceName, fmiOK, "log", "fmiSetString: nvr = %d",  nvr);
    for (i=0; i<nvr; i++) {
        char* string = comp->s[vr[i]];
        if (vrOutOfRange(comp, "fmiSetString", vr[i], NUMBER_OF_STRINGS))
            return fmiError;
        if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiSetString: #s%d# = '%s'", vr[i], value[i]);
        if (nullPointer(comp, "fmiSetString", "value[i]", value[i]))
            return fmiError;
        if (string==NULL || strlen(string) < strlen(value[i])) {
            if (string) comp->functions.freeMemory(string);
            comp->s[vr[i]] = comp->functions.allocateMemory(1+strlen(value[i]), sizeof(char));
            if (!comp->s[vr[i]]) {
                comp->state = modelError;
                comp->functions.logger(NULL, comp->instanceName, fmiError, "error", "fmiSetString: Out of memory.");
                return fmiError;
            }
        }
        strcpy(comp->s[vr[i]], value[i]);
    }
    return fmiOK;
}

fmiStatus fmiSetTime(fmiComponent c, fmiReal time) {
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiSetTime", modelInstantiated|modelInitialized))
         return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiSetTime: time=%.16g", time);
    comp->time = time;
    return fmiOK;
}

fmiStatus fmiSetContinuousStates(fmiComponent c, const fmiReal x[], size_t nx){
    ModelInstance* comp = (ModelInstance *)c;
    int i;
    if (invalidState(comp, "fmiSetContinuousStates", modelInitialized))
         return fmiError;
    if (invalidNumber(comp, "fmiSetContinuousStates", "nx", nx, NUMBER_OF_STATES))
        return fmiError;
    if (nullPointer(comp, "fmiSetContinuousStates", "x[]", x))
         return fmiError;
#if NUMBER_OF_REALS>0
    for (i=0; i<nx; i++) {
        fmiValueReference vr = vrStates[i];
        if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiSetContinuousStates: #r%d#=%.16g", vr, x[i]);
        assert(vr>=0 && vr<NUMBER_OF_REALS);
        comp->r[vr] = x[i];
    }
#endif
    return fmiOK;
}

// ---------------------------------------------------------------------------
// FMI functions: get variable values from the FMU
// ---------------------------------------------------------------------------

fmiStatus fmiGetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiReal value[]) {
    int i;
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiGetReal", not_modelError))
        return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiGetReal", "vr[]", vr))
         return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiGetReal", "value[]", value))
         return fmiError;
#if NUMBER_OF_REALS>0
    for (i=0; i<nvr; i++) {
        if (vrOutOfRange(comp, "fmiGetReal", vr[i], NUMBER_OF_REALS))
            return fmiError;
        value[i] = getReal(comp, vr[i]); // to be implemented by the includer of this file
        if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
                "fmiGetReal: #r%u# = %.16g", vr[i], value[i]);
    }
#endif
    return fmiOK;
}

fmiStatus fmiGetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiInteger value[]) {
    int i;
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiGetInteger", not_modelError))
        return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiGetInteger", "vr[]", vr))
         return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiGetInteger", "value[]", value))
         return fmiError;
    for (i=0; i<nvr; i++) {
        if (vrOutOfRange(comp, "fmiGetInteger", vr[i], NUMBER_OF_INTEGERS))
           return fmiError;
        value[i] = comp->i[vr[i]];
        if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
                "fmiGetInteger: #i%u# = %d", vr[i], value[i]);
    }
    return fmiOK;
}

fmiStatus fmiGetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiBoolean value[]) {
    int i;
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiGetBoolean", not_modelError))
        return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiGetBoolean", "vr[]", vr))
         return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiGetBoolean", "value[]", value))
         return fmiError;
    for (i=0; i<nvr; i++) {
        if (vrOutOfRange(comp, "fmiGetBoolean", vr[i], NUMBER_OF_BOOLEANS))
           return fmiError;
        value[i] = comp->b[vr[i]];
        if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
                "fmiGetBoolean: #b%u# = %s", vr[i], value[i]? "true" : "false");
    }
    return fmiOK;
}

fmiStatus fmiGetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiString  value[]) {
    int i;
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiGetString", not_modelError))
        return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiGetString", "vr[]", vr))
         return fmiError;
    if (nvr>0 && nullPointer(comp, "fmiGetString", "value[]", value))
         return fmiError;
    for (i=0; i<nvr; i++) {
        if (vrOutOfRange(comp, "fmiGetString", vr[i], NUMBER_OF_STRINGS))
           return fmiError;
        value[i] = comp->s[vr[i]];
        if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
                "fmiGetString: #s%u# = '%s'", vr[i], value[i]);
    }
    return fmiOK;
}

fmiStatus fmiGetStateValueReferences(fmiComponent c, fmiValueReference vrx[], size_t nx){
    int i;
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiGetStateValueReferences", not_modelError))
        return fmiError;
    if (invalidNumber(comp, "fmiGetStateValueReferences", "nx", nx, NUMBER_OF_STATES))
        return fmiError;
    if (nullPointer(comp, "fmiGetStateValueReferences", "vrx[]", vrx))
         return fmiError;
#if NUMBER_OF_REALS>0
    for (i=0; i<nx; i++) {
        vrx[i] = vrStates[i];
        if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiGetStateValueReferences: vrx[%d] = %d", i, vrx[i]);
    }
#endif
    return fmiOK;
}

fmiStatus fmiGetContinuousStates(fmiComponent c, fmiReal states[], size_t nx){
    int i;
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiGetContinuousStates", not_modelError))
        return fmiError;
    if (invalidNumber(comp, "fmiGetContinuousStates", "nx", nx, NUMBER_OF_STATES))
        return fmiError;
    if (nullPointer(comp, "fmiGetContinuousStates", "states[]", states))
         return fmiError;
#if NUMBER_OF_REALS>0
    for (i=0; i<nx; i++) {
        fmiValueReference vr = vrStates[i];
        states[i] = getReal(comp, vr); // to be implemented by the includer of this file
        if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiGetContinuousStates: #r%u# = %.16g", vr, states[i]);
    }
#endif
    return fmiOK;
}

fmiStatus fmiGetNominalContinuousStates(fmiComponent c, fmiReal x_nominal[], size_t nx){
    int i;
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiGetNominalContinuousStates", not_modelError))
        return fmiError;
    if (invalidNumber(comp, "fmiGetNominalContinuousStates", "nx", nx, NUMBER_OF_STATES))
        return fmiError;
    if (nullPointer(comp, "fmiGetNominalContinuousStates", "x_nominal[]", x_nominal))
         return fmiError;
    x_nominal[0] = 1;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetNominalContinuousStates: x_nominal[0..%d] = 1.0", nx-1);
    for (i=0; i<nx; i++)
        x_nominal[i] = 1;
    return fmiOK;
}

fmiStatus fmiGetDerivatives(fmiComponent c, fmiReal derivatives[], size_t nx) {
    int i;
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiGetDerivatives", not_modelError))
         return fmiError;
    if (invalidNumber(c, "fmiGetDerivatives", "nx", nx, NUMBER_OF_STATES))
        return fmiError;
    if (nullPointer(comp, "fmiGetDerivatives", "derivatives[]", derivatives))
         return fmiError;
#if NUMBER_OF_STATES>0
    for (i=0; i<nx; i++) {
        fmiValueReference vr = vrStates[i] + 1;
        derivatives[i] = getReal(comp, vr); // to be implemented by the includer of this file
        if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiGetDerivatives: #r%d# = %.16g", vr, derivatives[i]);
    }
#endif
    return fmiOK;
}

fmiStatus fmiGetEventIndicators(fmiComponent c, fmiReal eventIndicators[], size_t ni) {
    int i;
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiGetEventIndicators", not_modelError))
        return fmiError;
    if (invalidNumber(comp, "fmiGetEventIndicators", "ni", ni, NUMBER_OF_EVENT_INDICATORS))
        return fmiError;
#if NUMBER_OF_EVENT_INDICATORS>0
    for (i=0; i<ni; i++) {
        eventIndicators[i] = getEventIndicator(comp, i); // to be implemented by the includer of this file
        if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiGetEventIndicators: z%d = %.16g", i, eventIndicators[i]);
    }
#endif
    return fmiOK;
}

// ---------------------------------------------------------------------------
// FMI functions: initialization, event handling, stepping and termination
// ---------------------------------------------------------------------------

fmiStatus fmiInitialize(fmiComponent c, fmiBoolean toleranceControlled, fmiReal relativeTolerance,
    fmiEventInfo* eventInfo) {
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiInitialize", modelInstantiated))
         return fmiError;
    if (nullPointer(comp, "fmiInitialize", "eventInfo", eventInfo))
         return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiInitialize: toleranceControlled=%d relativeTolerance=%g",
        toleranceControlled, relativeTolerance);
    eventInfo->iterationConverged  = fmiTrue;
    eventInfo->stateValueReferencesChanged = fmiFalse;
    eventInfo->stateValuesChanged  = fmiFalse;
    eventInfo->terminateSimulation = fmiFalse;
    eventInfo->upcomingTimeEvent   = fmiFalse;
    initialize(comp, eventInfo); // to be implemented by the includer of this file
    comp->state = modelInitialized;
    return fmiOK;
}

fmiStatus fmiEventUpdate(fmiComponent c, fmiBoolean intermediateResults, fmiEventInfo* eventInfo) {
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiEventUpdate", modelInitialized))
        return fmiError;
    if (nullPointer(comp, "fmiEventUpdate", "eventInfo", eventInfo))
         return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiEventUpdate: intermediateResults = %d", intermediateResults);
    eventInfo->iterationConverged  = fmiTrue;
    eventInfo->stateValueReferencesChanged = fmiFalse;
    eventInfo->stateValuesChanged  = fmiFalse;
    eventInfo->terminateSimulation = fmiFalse;
    eventInfo->upcomingTimeEvent   = fmiFalse;
    eventUpdate(comp, eventInfo); // to be implemented by the includer of this file
    return fmiOK;
}

fmiStatus fmiCompletedIntegratorStep(fmiComponent c, fmiBoolean* callEventUpdate){
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiCompletedIntegratorStep", modelInitialized))
         return fmiError;
    if (nullPointer(comp, "fmiCompletedIntegratorStep", "callEventUpdate", callEventUpdate))
         return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiCompletedIntegratorStep");
    *callEventUpdate = fmiFalse;
    return fmiOK;
}

fmiStatus fmiTerminate(fmiComponent c){
    ModelInstance* comp = (ModelInstance *)c;
    if (invalidState(comp, "fmiTerminate", modelInitialized))
         return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiTerminate");
    comp->state = modelTerminated;
    return fmiOK;
}


