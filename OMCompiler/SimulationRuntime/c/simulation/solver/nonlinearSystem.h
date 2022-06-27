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

/*! \file nonlinearSystem.h
 */


#ifndef _NONLINEARSYSTEM_H_
#define _NONLINEARSYSTEM_H_

#include "../../simulation_data.h"
#include "../../util/omc_error.h"
#include "../../util/simulation_options.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef VOID
#undef VOID
#endif

typedef void* NLS_SOLVER_DATA;

typedef struct NLS_USERDATA {
  DATA *data;
  threadData_t *threadData;

  int sysNumber;                        /* System index, for print messages only */
  NONLINEAR_SYSTEM_DATA* nlsData;       /* Pointer to nonlinear system data */
  ANALYTIC_JACOBIAN* analyticJacobian;  /* Pointer to analytic Jacobian */

  void* solverData;                     /* Optional pointer to ODE solver data.
                                         * Used in NLS solving of ODE integrator step. */
} NLS_USERDATA;

/**
 * @brief Store primary and secondary solvers in single NLS_USERDATA->solverData
 */
struct dataSolver
{
  void* ordinaryData;
  void* initHomotopyData;
};

void cleanUpOldValueListAfterEvent(DATA *data, double time);
int initializeNonlinearSystems(DATA *data, threadData_t *threadData);
int updateStaticDataOfNonlinearSystems(DATA *data, threadData_t *threadData);
void freeNonlinearSystems(DATA *data, threadData_t *threadData);
void printNonLinearSystemSolvingStatistics(NONLINEAR_SYSTEM_DATA* nonlinsys, enum LOG_STREAM stream);
NLS_SOLVER_STATUS solveNLS(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys);
int solve_nonlinear_system(DATA *data, threadData_t *threadData, int sysNumber);
int check_nonlinear_solutions(DATA *data, int printFailingSystems);
int print_csvLineIterStats(void* csvData, int size, int num,
                           int iteration, double* x, double* f, double error_f,
                           double error_fs, double delta_x, double delta_xs,
                           double lambda);
void initializeNonlinearSystemData(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA *nonlinsys, int sysNum, modelica_boolean* isSparseNls, modelica_boolean* isBigNls);

NLS_USERDATA* initNlsUserData(DATA* data, threadData_t* threadData, int sysNumber, NONLINEAR_SYSTEM_DATA* nlsData, ANALYTIC_JACOBIAN* analyticJacobian);
void freeNlsUserData(NLS_USERDATA* userData);

NLS_USERDATA* initNlsUserData(DATA* data, threadData_t* threadData, int sysNumber, NONLINEAR_SYSTEM_DATA* nlsData, ANALYTIC_JACOBIAN* analyticJacobian);
void freeNlsUserData(NLS_USERDATA* userData);

extern void debugMatrixPermutedDouble(int logName, char* matrixName, double* matrix, int n, int m, int* indRow, int* indCol);
extern void debugMatrixDouble(int logName, char* matrixName, double* matrix, int n, int m);
extern void debugVectorDouble(int logName, char* vectorName, double* vector, int n);
extern void debugVectorBool(int logName, char* vectorName, modelica_boolean* vector, int n);
extern void debugVectorInt(int logName, char* vectorName, int* vector, int n);

static inline void debugString(int logName, char* message)
{
  if(ACTIVE_STREAM(logName))
  {
    infoStreamPrint(logName, 1, "%s", message);
    messageClose(logName);
  }
}

static inline void debugInt(int logName, char* message, int value)
{
  if(ACTIVE_STREAM(logName))
  {
    infoStreamPrint(logName, 1, "%s %d", message, value);
    messageClose(logName);
  }
}

static inline void debugDouble(int logName, char* message, double value)
{
  if(ACTIVE_STREAM(logName))
  {
    infoStreamPrint(logName, 1, "%s %18.10e", message, value);
    messageClose(logName);
  }
}

#ifdef __cplusplus
}
#endif

#endif
