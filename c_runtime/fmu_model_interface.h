
#include <stdio.h>
#include <string.h>
#include <assert.h>

#include "fmiModelFunctions.h"


/*saving states, this will be used later in checkstate function to check 
   current state of a model. */
typedef enum {
    modelInstantiated = 1<<0,
    modelInitialized  = 1<<1,
    modelTerminated   = 1<<2,
    modelError        = 1<<3
} State;

/*This structure will contain data necessary for a model intance. I will
 add more values here. */
typedef struct {
    fmiReal    *realVar;
    fmiInteger *intVar;
    fmiBoolean *boolVar;
    fmiString  *strVar;
    fmiString instanceName;
    State state;
} ModelInstance;