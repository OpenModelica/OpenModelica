#ifndef FMUWRAPPER_H
#define FMUWRAPPER_H
#endif

#include "fmiModelFunctions.h"
#include "xmlparser.h"
#define COMBINENAME(a,b) a##_##b

/* handling platform dependency */
#if defined(__MINGW32__) || defined(_MSC_VER)
#include <windows.h>
#define getFunctionPointerFromDLL  GetProcAddress
#define FreeLibraryFromHandle !FreeLibrary
#define LoadLibraryFromDLL LoadLibrary

#else
#include <dlfcn.h>
#define LoadLibraryFromDLL(X) dlopen(X, RTLD_LOCAL | RTLD_NOW)
#define getFunctionPointerFromDLL dlsym
#define FreeLibraryFromHandle dlclose
#define GetLastError(X)

#endif


#ifdef __cplusplus
extern "C"{
#endif

/* typedef of function pointers to FMI interface functions */
typedef const char* (*fGetModelTypesPlatform)();
typedef const char* (*fGetVersion)();
typedef fmiComponent (*fInstantiateModel)(fmiString instanceName, fmiString GUID,
                                        fmiCallbackFunctions functions, fmiBoolean loggingOn);
typedef void      (*fFreeModelInstance)  (fmiComponent c);
typedef fmiStatus (*fSetDebugLogging)    (fmiComponent c, fmiBoolean loggingOn);
typedef fmiStatus (*fSetTime)            (fmiComponent c, fmiReal time);
typedef fmiStatus (*fSetContinuousStates)(fmiComponent c, const fmiReal x[], size_t nx);
typedef fmiStatus (*fCompletedIntegratorStep)(fmiComponent c, fmiBoolean* callEventUpdate);
typedef fmiStatus (*fSetReal)   (fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiReal    value[]);
typedef fmiStatus (*fSetInteger)(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger value[]);
typedef fmiStatus (*fSetBoolean)(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiBoolean value[]);
typedef fmiStatus (*fSetString) (fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiString  value[]);
typedef fmiStatus (*fInitialize)(fmiComponent c, fmiBoolean toleranceControlled,
                               fmiReal relativeTolerance, fmiEventInfo* eventInfo);
typedef fmiStatus (*fGetDerivatives)    (fmiComponent c, fmiReal derivatives[]    , size_t nx);
typedef fmiStatus (*fGetEventIndicators)(fmiComponent c, fmiReal eventIndicators[], size_t ni);
typedef fmiStatus (*fGetReal)   (fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiReal    value[]);
typedef fmiStatus (*fGetInteger)(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiInteger value[]);
typedef fmiStatus (*fGetBoolean)(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiBoolean value[]);
typedef fmiStatus (*fGetString) (fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiString  value[]);
typedef fmiStatus (*fEventUpdate)               (fmiComponent c, fmiBoolean intermediateResults, fmiEventInfo* eventInfo);
typedef fmiStatus (*fGetContinuousStates)       (fmiComponent c, fmiReal states[], size_t nx);
typedef fmiStatus (*fGetNominalContinuousStates)(fmiComponent c, fmiReal x_nominal[], size_t nx);
typedef fmiStatus (*fGetStateValueReferences)   (fmiComponent c, fmiValueReference vrx[], size_t nx);
typedef fmiStatus (*fTerminate)                 (fmiComponent c);

/* typedef of the data structure FMI containing loaded FMI functions */
typedef struct {
    void* modelDescription; /* ModelDescription* */
    void* dllHandle;
    fGetModelTypesPlatform getModelTypesPlatform;
    fGetVersion getVersion;
    fInstantiateModel instantiateModel;
    fFreeModelInstance freeModelInstance;
    fSetDebugLogging setDebugLogging;
    fSetTime setTime;
    fSetContinuousStates setContinuousStates;
    fCompletedIntegratorStep completedIntegratorStep;
    fSetReal setReal;
    fSetInteger setInteger;
    fSetBoolean setBoolean;
    fSetString setString;
    fInitialize initialize;
    fGetDerivatives getDerivatives;
    fGetEventIndicators getEventIndicators;
    fGetReal getReal;
    fGetInteger getInteger;
    fGetBoolean getBoolean;
    fGetString getString;
    fEventUpdate eventUpdate;
    fGetContinuousStates getContinuousStates;
    fGetNominalContinuousStates getNominalContinuousStates;
    fGetStateValueReferences getStateValueReferences;
    fTerminate terminate;
  int flagInit;
} FMI;

#ifdef _DEBUG_
typedef enum {
    modelInstantiated = 1<<0,
    modelInitialized  = 1<<1,
    modelTerminated   = 1<<2,
    modelError        = 1<<3
} ModelState;

typedef struct {
    fmiReal    *r;
    fmiInteger *i;
    fmiBoolean *b;
    fmiString  *s;
    fmiBoolean *isPositive;
    fmiReal time;
    fmiString instanceName;
    fmiString GUID;
    fmiCallbackFunctions functions;
    fmiBoolean loggingOn;
    ModelState state;
} ModelInstance;

#endif

void PrintModelStates(void* in_fmu, double in_time);
const char* fmiGetModelTypesPF(void* in_fmi);
const char* fmiGetVer(void* in_fmi);
void* getProAdr(FMI* fmi, const char* mid, const char* funName);
void* loadFMUDll(void* in_fmi, const char* pathFMUDll,const char* mid);
void freeFMUDll(void* dummy);
void fmiSetDebugLog(void* in_fmi, void* in_fmu, char log);
double fmiSetT(void* in_fmi, void* in_fmu, double in_t, double in_flowControl);
double fmiSetContStates(void* in_fmi, void* in_fmu, const double* in_x, int nx, double in_flowControl);
double fmiSetRealVR(void* in_fmi, void* in_fmu, const int* in_vr, const double* rv, int nvr, double in_flowControl);
double fmiSetIntegerVR(void* in_fmi, void* in_fmu, const int* in_vr, const int* iv, int nvr, double in_flowControl);
double fmiSetStringVR(void* in_fmi, void* in_fmu, const int* in_vr, const char** sv, int nvr, double in_flowControl);
double fmiSetBooleanVR(void* in_fmi, void* in_fmu, const int* in_vr, const int* in_bv, int nvr, double in_flowControl);
double fmiCompIntStep(void* in_fmi, void* in_fmu, void* in_stepEvt, double in_flowControl);
void fmiGetContStates(void* in_fmi, void* in_fmu, double* out_x, int nx);
void fmiGetNomContStates(void* in_fmi, void* in_fmu, double* x_nom, int nx);
void fmiGetStateVR(void* in_fmi, void* in_fmu, int* in_vrx, int nx);
void fmiGetDer(void* in_fmi, void* in_fmu, double* der_x, int nx, const double* x, double in_flowControl);
void fmiGetRealVR(void* in_fmi, void* in_fmu, const int* in_vr, double* rv, int nvr, double in_flowControl);
void fmiGetIntegerVR(void* in_fmi, void* in_fmu, const int* in_vr, int* iv, int nvr, double in_flowControl);
void fmiGetStringVR(void* in_fmi, void* in_fmu, const int* in_vr, const char** sv, int nvr, double in_flowControl);
void fmiGetBooleanVR(void* in_fmi, void* in_fmu, const int* in_vr, int* bv, int nvr, double in_flowControl);
void fmiGetTimeEvent(void * in_evtInfo, double in_time, double in_pretime, void * in_timeEvt, double* out_nextTime);
void fmiGetEventInd(void* in_fmi, void* in_fmu, double* z, int ni);
void fmuStateEventCheck(void* stateEvt, int ni, const double* z, const double* prez);
void fmiEvtUpdate(void* in_fmi, void* in_fmu,fmiBoolean inter_res, fmiEventInfo* in_evtInfo);
void fmuEventUpdate(void * in_fmufun, void * in_inst, void * in_evtInfo, void * timeEvt, void * stepEvt, void * stateEvt, void * interMediateRes);
void fmuLogger(void* in_fmu, const char* instanceName, fmiStatus status,const char* category, const char* message, ...);
void* fmiInstantiate(void* in_fmi, const char* instanceName,  const char* GUID, void* in_functions, int logFlag);
void fmiInit(void* in_fmi, void* in_fmu, int tolCont, double rTol, void* in_evtInfo);
void fmiTerminator(void* in_fmi, void* in_fmu);

void* instantiateFMIFun(const char* mid, const char* pathFMUDll);
void freeFMUFun(void* in_fmi);

void* fmuBooleanInst(int def_bool);
void freefmuBooleanInst(void* in_bool);

void fmiFreeModelInst(void* in_fmufun, void* in_fmu);
//void fmiFreeModelInst(void* in_fmu);

void* fmiCallbackFuns();
void fmiFreeCallbackFuns(void * functions);

void* fmuFreeAll(void* in_fmufun, void* in_inst, void* functions);

void* fmiEvtInfo();
void freefmiEvtInfo(void* in_evtInfo);
void fmiFreeDummy(void *);
void freeFMUDll(void* dummy);
void printVariables(const double * var, int n, const char* varName);
void printIntVariables(const int * var, int n, const char* varName);

/*
// void* fmiInstantiate(void* in_fmi, const char* instanceName,  const char* GUID, void* in_functions, int logFlag);
// void fmiSetT(void* in_fmi, void* in_fmu, double t);
// void fmiGetContStates(void *, void *, double *, int);
// void fmiGetDer(void* in_fmi, void* in_fmu, double* der_x, int nx, const double* x);
// void* instantiateFMIFun(const char* mid, const char* pathFMUDll);
// void fmiCompIntStep(void* in_fmi, void* in_fmu, void* in_stepEvt);
// void freeFMIfun(void* in_fmi);
// void printVariables(const double *, int, const char*);
// // void fmiFreeModelInst(void* in_fmi, void* in_fmu);
// void fmiFreeModelInst(void* in_fmu);
// void fmiGetTimeEvent(void *, double, double, void *, double*);
// void fmuStateEventCheck(void *, int, const double *, const double *);
// //signed char fmuStateEventCheck(void *, int, const double *, const double *);
// void fmuEventUpdate(void *, void *, void *, void *, void *, void *, void *, double, double*);
*/

#ifdef __cplusplus
} //extern "C"
#endif
