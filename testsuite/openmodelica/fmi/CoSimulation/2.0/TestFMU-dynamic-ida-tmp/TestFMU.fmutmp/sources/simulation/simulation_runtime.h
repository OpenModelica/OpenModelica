/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/*! \file simulation_runtime.h
 *
 *  This file is a C++ header file for the simulation runtime. It contains
 *  solver functions and other simulation runtime specific functions
 */

#ifndef _SIMULATION_RUNTIME_H
#define _SIMULATION_RUNTIME_H

#include "../openmodelica.h"

#include "../simulation_data.h"

#include "../util/rtclock.h"
#include "omc_simulation_util.h"
#include <stdlib.h>
#include <string.h>

#include "../linearization/linearize.h"
#include "../dataReconciliation/dataReconciliation.h"
#include "results/simulation_result.h"

#ifdef __cplusplus
extern "C" {
#endif /* cplusplus */

extern int initializeResultData(DATA* simData, threadData_t *threadData, int cpuTime);

extern int modelTermination;     /* Becomes non-zero when simulation terminates. */
extern int terminationTerminate; /* Becomes non-zero when user terminates simulation. */
extern int terminationAssert;    /* Becomes non-zero when model call assert simulation. */
extern int warningLevelAssert;   /* Becomes non-zero when model call assert with warning level. */
extern FILE_INFO TermInfo;       /* message for termination. */

extern char* TermMsg; /* message for termination. */

/* defined in model code. Used to get name of variable by investigating its pointer in the state or alg vectors. */
extern const char* getNameReal(double* ptr);
extern const char* getNameInt(modelica_integer* ptr);
extern const char* getNameBool(modelica_boolean* ptr);
extern const char* getNameString(const char** ptr);

extern double getSimulationStepSize();
extern void printSimulationStepSize(double in_stepSize, double time);

extern void communicateStatus(const char *phase, double completionPercent, double currentTime, double currentStepSize);
extern void communicateMsg(char id, unsigned int size, const char *data);

/**
 * @brief Parses the commandline (program options) and sets some
 * values. See initRuntimeAndSimulation for more info.
 * This allows generated simulation code to check-on/read options and flags before
 * it calls the main _main_SimulationRuntime function to do the simulation.
 *
 * @param argc
 * @param argv  This gets overwritten on Windows!!
 * @param data
 * @param threadData
 * @return int    Returns 0 on success. Returns 1 otherwise.
 *
 * Note: The function will overwrite argv to its wide character representation. Not sure
 * if this is a good idea. However, I am leaving it as it was for now.
 */
int _main_initRuntimeAndSimulation(int argc, char**argv, DATA *data, threadData_t *threadData);
/* the main function of the simulation runtime!
 * simulation runtime no longer has main, is defined by the generated model code which calls this function.
 */
extern int _main_SimulationRuntime(int argc, char**argv, DATA *data, threadData_t *threadData);

#if !defined(OMC_MINIMAL_RUNTIME)
const char* prettyPrintNanoSec(int64_t ns, int *v);
#endif

void setStreamPrintXML(int isXML);

#ifdef __cplusplus
}
#endif

/*
 * adrpo: weird msvc _C2 defined inside stdint.h via yvals.h interferes with some generated Modelica code
 */
#if defined(_MSC_VER)
#if defined(_C2)
#undef _C2
#endif
#endif

#endif
