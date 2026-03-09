#ifndef Example__H
#define Example__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#include "simulation/simulation_runtime.h"
#ifdef __cplusplus
extern "C" {
#endif


void genericCall_0(DATA *data, threadData_t *threadData, const int equationIndexes[2], modelica_integer _omcQ_24i1);
#include "Example_model.h"


#ifdef __cplusplus
}
#endif
#endif
