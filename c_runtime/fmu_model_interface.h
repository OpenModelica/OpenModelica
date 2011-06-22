#ifndef __FMU_MODEL_INTERFACE_H__
#define __FMU_MODEL_INTERFACE_H__
/******************************************************************************
 *fmuTemplate.h
 ******************************************************************************/
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "fmiModelFunctions.h"
#include "simulation_runtime.h"
//#include "simulation_init.h"

// macros used to define variables
#define  r(vr) comp->r[vr]
#define  i(vr) comp->i[vr]
#define  b(vr) comp->b[vr]
#define  s(vr) comp->s[vr]
#define pos(z) comp->isPositive[z]
#define copy(vr, value) setString(comp, vr, value)

#define not_modelError (modelInstantiated|modelInitialized|modelTerminated)

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
    fmiReal *time;
    fmiString instanceName;
    fmiString GUID;
    fmiCallbackFunctions functions;
    fmiBoolean loggingOn;
    fmiEventInfo eventInfo;
    fmiBoolean outputsvalid;
    ModelState state;
} ModelInstance;

fmiStatus setString(fmiComponent comp, fmiValueReference vr, fmiString value){
    return fmiSetString(comp, &vr, 1, &value);
}

// relation functions used in zero crossing detection
fmiReal
FmiLess(fmiReal a, fmiReal b);
fmiReal
FmiLessEq(fmiReal a, fmiReal b);
fmiReal
FmiGreater(fmiReal a, fmiReal b);
fmiReal
FmiGreaterEq(fmiReal a, fmiReal b);
#define FMIZEROCROSSING(ind,exp) { \
  eventIndicators[ind] = exp; \
}

#endif
