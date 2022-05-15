/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

/* BB: ToDo's
 *
 * 0) Update comments for better readability, delete stuff no longer necessary
 * 1) Check pointer, especially, if there is no memory leak!
 * 2) Check necessary function evaluation and counting of it (use userdata->f, userdata->fOld)
 * 3) Optimize evaluation of the Jacobian (e.g. in case it is constant)
 * 4) Introduce generic multirate-method, that might also be used for higher order
 *    ESDIRK and explicit RK methods
 * 5) Check accuracy and decide on the Left-limit of the implicit embedded RK method, if possible...
 *
*/

/*! \file genericRK.c
 *  Implementation of a generic (implicit and explicit) Runge Kutta solver, which works for any
 *  order and stage based on a provided Butcher tableau. Utilizes the sparsity pattern of the ODE
 *  together with the KINSOL (KLU) solver
 *
 *  \author bbachmann
 */

#include "generic_rk.h"

#include <float.h>
#include <math.h>
#include <string.h>

#include "external_input.h"
#include "jacobianSymbolical.h"
#include "kinsolSolver.h"
#include "model_help.h"
#include "newtonIteration.h"
#include "nonlinearSystem.h"
#include "simulation/options.h"
#include "simulation/results/simulation_result.h"
#include "util/jacobian_util.h"
#include "util/omc_error.h"
#include "util/simulation_options.h"
#include "util/varinfo.h"

//auxiliary vector functions
void linear_interpolation(double a, double* fa, double b, double* fb, double t, double *f, int n);
void printVector_genericRK(char name[], double* a, int n, double time);
void printIntVector_genericRK(char name[], int* a, int n, double time);
void printVector_genericRK_MR_fs(char name[], double* a, int n, double time, int nIndx, int* indx);
void printMatrix_genericRK(char name[], double* a, int n, double time);
void copyVector_genericRK_MR(double* a, double* b, int nIndx, int* indx);
void sortErrorIndices(DATA_GSRI* gsriData);

// singlerate step function
int expl_diag_impl_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
int full_implicit_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
int full_implicit_MS(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);

// Residuum and Jacobian functions for diagonal implicit (DIRK) and implicit (IRK) Runge-Kutta methods.
void residual_MS(void **dataIn, const double *xloc, double *res, const int *iflag);
int jacobian_MS_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian);

void residual_DIRK(void **dataIn, const double *xloc, double *res, const int *iflag);
int jacobian_DIRK_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian);

void residual_IRK(void **dataIn, const double *xloc, double *res, const int *iflag);
int jacobian_IRK_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian);

void initializeStaticNLSData(void* nlsDataVoid, threadData_t *threadData, void* gsriData_void);

void allocateDataGenericRK_MR(DATA* data, threadData_t* threadData, DATA_GSRI* gsriData);

// step size control function
double IController(double* err_values, double* stepSize_values, double err_order);
double PIController(double* err_values, double* stepSize_values, double err_order);

int checkForStateEvent(DATA* data, LIST *eventList);
double bisection(DATA* data, threadData_t *threadData, double* a, double* b, double* states_a, double* states_b, LIST *tmpEventList, LIST *eventList);

/*! \fn findRootLocal
 *
 *  \param [ref] [data]
 *  \param [ref] [threadData]
 *  \param [ref] [eventList]
 *  \return: first event of interval [oldTime, timeValue]
 *
 *  This function perform a root finding for interval = [oldTime, timeValue]
 */
double findRootLocal(DATA* data, threadData_t *threadData, LIST *eventList, double timeLeft, double* leftValues, double timeRight, double* rightValues)
{
  TRACE_PUSH

  double eventTime;
  long event_id;
  LIST_NODE* it;
  fortran_integer i=0;
  static LIST *tmpEventList = NULL;

  double *states_right = (double*) malloc(data->modelData->nStates * sizeof(double));
  double *states_left = (double*) malloc(data->modelData->nStates * sizeof(double));

  tmpEventList = allocList(sizeof(long));

  assert(states_right);
  assert(states_left);

  for(it=listFirstNode(eventList); it; it=listNextNode(it))
  {
    infoStreamPrint(LOG_ZEROCROSSINGS, 0, "search for current event. Events in list: %ld", *((long*)listNodeData(it)));
  }

  /* write states to work arrays */
  memcpy(states_left,  leftValues, data->modelData->nStates * sizeof(double));
  memcpy(states_right, rightValues, data->modelData->nStates * sizeof(double));

  /* Search for event time and event_id with bisection method */
  eventTime = bisection(data, threadData, &timeLeft, &timeRight, states_left, states_right, tmpEventList, eventList);

  if(listLen(tmpEventList) == 0)
  {
    double value = fabs(data->simulationInfo->zeroCrossings[*((long*) listFirstData(eventList))]);
    for(it = listFirstNode(eventList); it; it = listNextNode(it))
    {
      double fvalue = fabs(data->simulationInfo->zeroCrossings[*((long*) listNodeData(it))]);
      if(value > fvalue)
      {
        value = fvalue;
      }
    }
    infoStreamPrint(LOG_ZEROCROSSINGS, 0, "Minimum value: %e", value);
    for(it = listFirstNode(eventList); it; it = listNextNode(it))
    {
      if(value == fabs(data->simulationInfo->zeroCrossings[*((long*) listNodeData(it))]))
      {
        listPushBack(tmpEventList, listNodeData(it));
        infoStreamPrint(LOG_ZEROCROSSINGS, 0, "added tmp event : %ld", *((long*) listNodeData(it)));
      }
    }
  }

  listClear(eventList);

  if(ACTIVE_STREAM(LOG_EVENTS))
  {
    if(listLen(tmpEventList) > 0)
    {
      debugStreamPrint(LOG_EVENTS, 0, "found events: ");
    }
    else
    {
      debugStreamPrint(LOG_EVENTS, 0, "found event: ");
    }
  }
  while(listLen(tmpEventList) > 0)
  {
    event_id = *((long*)listFirstData(tmpEventList));
    listPopFront(tmpEventList);

    infoStreamPrint(LOG_ZEROCROSSINGS, 0, "Event id: %ld ", event_id);

    listPushFront(eventList, &event_id);
  }

  eventTime = timeRight;
  debugStreamPrint(LOG_EVENTS, 0, "time: %.10e", eventTime);

  data->localData[0]->timeValue = timeLeft;
  for(i=0; i < data->modelData->nStates; i++) {
    data->localData[0]->realVars[i] = states_left[i];
  }

  /* determined continuous system */
  data->callback->updateContinuousSystem(data, threadData);
  updateRelationsPre(data);
  /*sim_result_emit(data);*/

  data->localData[0]->timeValue = eventTime;
  for(i=0; i < data->modelData->nStates; i++)
  {
    data->localData[0]->realVars[i] = states_right[i];
  }

  free(states_left);
  free(states_right);
  freeList(tmpEventList);

  TRACE_POP
  return eventTime;
}

double checkForEvents(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double timeLeft, double* leftValues, double timeRight, double* rightValues)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  int eventHappend;
  double eventTime = -1;

  static LIST *tmpEventList = NULL;

  // store the pre values of the zeroCrossings for comparison
  memcpy(data->simulationInfo->zeroCrossingsPre, data->simulationInfo->zeroCrossings, data->modelData->nZeroCrossings * sizeof(modelica_real));

  // set simulation data to the current time
  sData->timeValue = timeRight;
  memcpy(sData->realVars, rightValues, data->modelData->nStates*sizeof(double));
  /*calculates Values dependents on new states*/
  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  /* eval needed equations*/
  data->callback->function_ZeroCrossingsEquations(data, threadData);
  data->callback->function_ZeroCrossings(data, threadData, data->simulationInfo->zeroCrossings);

  eventHappend = checkForStateEvent(data, solverInfo->eventLst);

  if (eventHappend) {
    eventTime = findRootLocal(data, threadData, solverInfo->eventLst, timeLeft, leftValues, timeRight, rightValues);
  }

  // re-store the pre values of the zeroCrossings for comparison
  memcpy(data->simulationInfo->zeroCrossings, data->simulationInfo->zeroCrossingsPre, data->modelData->nZeroCrossings * sizeof(modelica_real));

  return eventTime;
}

struct RK_USER_DATA {
  DATA* data;
  threadData_t* threadData;
  DATA_GSRI* gsriData;
};

struct dataSolver
{
  void* ordinaryData;
  void* initHomotopyData;
};

/**
 * @brief Get Runge-Kutta method from simulation flag FLAG_RK.
 *
 * Defaults to RK_DOPRI45 if flag is not set.
 * Returns RK_UNKNOWN if flag is not known.
 *
 * @return enum RK_SINGLERATE_METHOD    Runge-Kutta method.
 */
enum RK_SINGLERATE_METHOD getRK_Method(enum _FLAG FLAG_RK_METHOD) {
  enum RK_SINGLERATE_METHOD method;
  const char* flag_value;
  flag_value = omc_flagValue[FLAG_RK_METHOD];
  char* RK_method_string;

  if (flag_value != NULL) {
    RK_method_string = GC_strdup(flag_value);
    for (method=RK_UNKNOWN; method<RK_MAX; method++) {
      if (strcmp(RK_method_string, RK_SINGLERATE_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method: %s", RK_SINGLERATE_METHOD_NAME[method]);
        return method;
      }
    }
    errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow Runge-Kutta method %s.", RK_method_string);
    errorStreamPrint(LOG_STDOUT, 0, "Choose RK method: %s [from command line]", RK_method_string);
    return RK_UNKNOWN;
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method: esdirk3 [default]");
    return RK_ESDIRK3;
  }
}

/**
 * @brief Get non-linear solver method for Runge-Kutta from flag FLAG_RK_NLS.
 *
 * Defaults to Newton if flag is not set.
 * Returns RK_UNKNOWN if flag is not known.
 *
 * @return enum RK_NLS_METHOD   NLS method.
 */
enum RK_NLS_METHOD getRK_NLS_Method() {
  enum RK_NLS_METHOD method;
  const char* flag_value;
  flag_value = omc_flagValue[FLAG_RK_NLS];
  char* RK_NLS_method_string;

  if (flag_value != NULL) {
    RK_NLS_method_string = GC_strdup(flag_value);
    for (method=RK_NLS_UNKNOWN; method<RK_NLS_MAX; method++) {
      if (strcmp(RK_NLS_method_string, RK_NLS_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen RK NLS method: %s", RK_NLS_METHOD_NAME[method]);
        return method;
      }
    }
    errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow non-linear solver method %s for Runge-Kutta method.", RK_NLS_method_string);
    errorStreamPrint(LOG_STDOUT, 0, "Choose RK NLS method: %s [from command line]", RK_NLS_method_string);
    return RK_NLS_UNKNOWN;
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method: omc_newton [default]");
    return RK_NLS_NEWTON;
  }
}

void sparsePatternTranspose(int sizeRows, int sizeCols, SPARSE_PATTERN* sparsePattern, SPARSE_PATTERN* sparsePatternT)
{
  int leadindex[sizeCols];
  unsigned int i, j, loc;

  for (i=0; i < sizeCols; i++)
    leadindex[i] = 0;
  for (i=0; i < sparsePattern->numberOfNonZeros; i++)
    leadindex[sparsePattern->index[i]]++;
  sparsePatternT->leadindex[0] = 0;
  for(i=1;i<sizeCols+1;i++)
    sparsePatternT->leadindex[i] = sparsePatternT->leadindex[i-1] + leadindex[i-1];
  memcpy(leadindex, sparsePatternT->leadindex, sizeof(unsigned int)*sizeCols);
  for (i=0,j=0;i<sizeRows;i++)
  {
    for(; j < sparsePattern->leadindex[i+1];) {
      loc = leadindex[sparsePattern->index[j]];
      sparsePatternT->index[loc] = i;
      leadindex[sparsePattern->index[j]]++;
      j++;
    }
  }
  printSparseStructure(sparsePattern,
                        sizeRows,
                        sizeCols,
                        LOG_SOLVER_V,
                        "sparsePattern");
  printSparseStructure(sparsePatternT,
                        sizeRows,
                        sizeCols,
                        LOG_SOLVER_V,
                        "sparsePatternT");
}

void ColoringAlg(SPARSE_PATTERN* sparsePattern, int sizeRows, int sizeCols, int nStages)
{
  SPARSE_PATTERN* sparsePatternT;
  int row, col, nCols, leadIdx;
  int i, j, maxColors = 0;

  int length_column_indices = sizeCols+1;
  int length_index = sparsePattern->numberOfNonZeros;
  // initialize array to zeros

  int* tabu;
  tabu = (int*) malloc(sizeCols*sizeCols*sizeof(int));
  for (i=0; i<sizeCols; i++)
     for (j=0; j<sizeCols; j++)
        tabu[i*sizeCols + j]=0;

    // Allocate memory for new sparsity pattern
  sparsePatternT = (SPARSE_PATTERN*) malloc(sizeof(SPARSE_PATTERN));
  sparsePatternT->leadindex = (unsigned int*) malloc((length_column_indices)*sizeof(unsigned int));
  sparsePatternT->index = (unsigned int*) malloc(length_index*sizeof(unsigned int));
  sparsePatternT->sizeofIndex = length_index;
  sparsePatternT->numberOfNonZeros = length_index;

  sparsePatternTranspose(sizeRows, sizeCols, sparsePattern, sparsePatternT);

  int sizeCols_ODE = sizeCols/nStages;
  int act_stage;

  for (col=0; col<sizeCols; col++)
  {
    // Look for the next free color, based on the tabu list
    for (i=0; i<sizeCols ; i++)
    {
      if (tabu[col*sizeCols + i] == 0)
      {
        sparsePattern->colorCols[col] = i+1;
        maxColors = fmax(maxColors, i+1);

        // set tabu for columns that have entries in the same row!
        for (row=sparsePattern->leadindex[col]; row<sparsePattern->leadindex[col+1]; row++)
        {
          int rowIdx = sparsePattern->index[row];
          for (j=sparsePatternT->leadindex[rowIdx]; j<sparsePatternT->leadindex[rowIdx+1]; j++)
          {
            tabu[sparsePatternT->index[j]*sizeCols + i]=1;
          }
        }

        // each stage has different colors, due to the columnwise jacobian calculation
        // only important and utilized, if a fully implicit RK-method is used
        act_stage = col/sizeCols_ODE;
        for (j=(act_stage+1)*sizeCols_ODE; j<sizeCols; j++)
        {
          tabu[j*sizeCols + i]=1;
        }

        break;
      }
    }
  }
  sparsePattern->maxColors = maxColors;

  // free memory allocation for the transposed sprasity pattern
  free(sparsePatternT->leadindex);
  free(sparsePatternT->index);
  free(sparsePatternT);
  free(tabu);
}

/**
 * @brief Initialize sparsity pattern for non-linear system of diagonal implicit Runge-Kutta methods.
 *
 * Get sparsity pattern of ODE Jacobian and edit to be non-zero on diagonal elements.
 * Coloring of ODE Jacobian will be used, if it had non-zero elements on all diagonal entries.
 * Calculate coloring otherwise.
 *
 * @param data                Runtime data struct.
 * @param sysData             Non-linear system.
 * @return SPARSE_PATTERN*    Pointer to sparsity pattern of non-linear system.
 */
SPARSE_PATTERN* initializeSparsePattern_DIRK(DATA* data, NONLINEAR_SYSTEM_DATA* sysData)
{
  unsigned int i,j;
  unsigned int row, col;
  unsigned int missingZeros = 0;
  unsigned int nDiags = 0;
  unsigned int shift = 0;
  modelica_boolean diagElemNonZero;
  SPARSE_PATTERN* sparsePattern_DIRK;

  /* Get Sparsity of ODE Jacobian */
  ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  SPARSE_PATTERN* sparsePattern_ODE = jacobian->sparsePattern;

  int sizeRows = jacobian->sizeRows;
  int sizeCols = jacobian->sizeCols;

  /* Compute size of new sparsitiy pattern
   * Increase the size to contain non-zero elements on diagonal. */
  i = 0;
  for(row=0; row < sizeRows; row++) {
    for(; i < sparsePattern_ODE->leadindex[row+1];) {
      if(sparsePattern_ODE->index[i++] == row) {
        nDiags++;
      }
    }
  }
  int missingDiags = jacobian->sizeRows - nDiags;
  int length_column_indices = jacobian->sizeRows+1;
  int length_index = jacobian->sparsePattern->numberOfNonZeros + missingDiags;

  // Allocate memory for new sparsity pattern
  sparsePattern_DIRK = (SPARSE_PATTERN*) malloc(sizeof(SPARSE_PATTERN));
  sparsePattern_DIRK->leadindex = (unsigned int*) malloc((length_column_indices)*sizeof(unsigned int));
  sparsePattern_DIRK->index = (unsigned int*) malloc(length_index*sizeof(unsigned int));
  sparsePattern_DIRK->sizeofIndex = length_index;
  sparsePattern_DIRK->numberOfNonZeros = length_index;
  sparsePattern_DIRK->colorCols = (unsigned int*) malloc(jacobian->sizeCols*sizeof(unsigned int));
  sparsePattern_DIRK->maxColors = jacobian->sizeCols;

  /* Set diagonal elements of sparsitiy pattern to non-zero */
  i = 0;
  j = 0;
  sparsePattern_DIRK->leadindex[0] = sparsePattern_ODE->leadindex[0];
  for(row=0; row < sizeRows; row++) {
    diagElemNonZero = FALSE;
    int leadIdx = sparsePattern_ODE->leadindex[row+1];
    for(; j < leadIdx;) {
      if(sparsePattern_ODE->index[j] == row) {
        diagElemNonZero = TRUE;
        sparsePattern_DIRK->leadindex[row+1] = sparsePattern_ODE->leadindex[row+1] + shift;
      }
      if(sparsePattern_ODE->index[j] > row && !diagElemNonZero) {
        sparsePattern_DIRK->index[i] = row;
        shift++;
        sparsePattern_DIRK->leadindex[row+1] = sparsePattern_ODE->leadindex[row+1] + shift;
        i++;
        diagElemNonZero = TRUE;
      }
      sparsePattern_DIRK->index[i] = sparsePattern_ODE->index[j];
      i++;
      j++;
    }
    if (!diagElemNonZero) {
      sparsePattern_DIRK->index[i] = row;
      shift++;
      sparsePattern_DIRK->leadindex[row+1] = sparsePattern_ODE->leadindex[row+1] + shift;
      i++;
    }
  }

  if (missingDiags == 0) {
    // If missingDiags=0 we can re-use coloring (and everything else)
    sparsePattern_DIRK->maxColors = sparsePattern_ODE->maxColors;
    memcpy(sparsePattern_DIRK->colorCols, sparsePattern_ODE->colorCols, jacobian->sizeCols*sizeof(unsigned int));
  } else {
    // Calculate new coloring, because of additional nonZeroDiagonals
    ColoringAlg(sparsePattern_DIRK, sizeRows, sizeCols, 1);
  }

  return sparsePattern_DIRK;
}


/**
 * @brief Initialize sparsity pattern for non-linear system of full implicit Runge-Kutta methods.
 *
 * Get sparsity pattern of ODE Jacobian and map it on the different stages taking into account
 * the non-zero elements of the A matrix in the Butcher-tableau
 * Coloring will be calculated, whereby different stages will have different colors, due to the
 * column-wise calculation of the Jacobian
 *
 * @param data                Runtime data struct.
 * @param sysData             Non-linear system.
 * @return SPARSE_PATTERN*    Pointer to sparsity pattern of non-linear system.
 */
SPARSE_PATTERN* initializeSparsePattern_IRK(DATA* data, NONLINEAR_SYSTEM_DATA* sysData)
{
  unsigned int i,j,k,l;
  unsigned int row, col;
  unsigned int missingZeros = 0;
  unsigned int nDiags = 0, nDiags_A, nnz_A;
  unsigned int shift = 0;
  modelica_boolean diagElemNonZero;
  SPARSE_PATTERN* sparsePattern_IRK;
  DATA_GSRI* gsriData = (DATA_GSRI*) data->simulationInfo->backupSolverData;

  /* Get Sparsity of ODE Jacobian */
  ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  SPARSE_PATTERN* sparsePattern_ODE = jacobian->sparsePattern;

  int sizeRows = jacobian->sizeRows;
  int sizeCols = jacobian->sizeCols;
  int nStages  = gsriData->tableau->nStages;
  int nStates  = gsriData->nStates;
  double* A    = gsriData->tableau->A;

  printSparseStructure(sparsePattern_ODE,
                      sizeRows,
                      sizeCols,
                      LOG_SOLVER_V,
                      "sparsePatternODE");

  nnz_A = 0;
  nDiags_A = 0;
  for (i=0; i<nStages; i++) {
     if (A[i*nStages + i] != 0) nDiags_A++;
     for (j=0; j<nStages; j++) {
       if (A[i*nStages + j] != 0) nnz_A++;
     }
  }

  i = 0;
  for(col=0; col < sizeRows; col++) {
    for(; i < sparsePattern_ODE->leadindex[col+1];) {
      if(sparsePattern_ODE->index[i++] == col) {
        nDiags++;
      }
    }
  }
  int missingDiags = jacobian->sizeRows - nDiags;
  int numberOfNonZeros = nnz_A*sparsePattern_ODE->numberOfNonZeros + nDiags_A*missingDiags + (nStages-nDiags_A)*nStates;

  // first generated a coordinate format and transform this later to Column pressed format
  int coo_col[numberOfNonZeros];
  int coo_row[numberOfNonZeros];

  i = 0;
  for (k=0; k<nStages; k++)
  {
    for (col=0; col < nStates; col++)
    {
      diagElemNonZero = FALSE;
      for (l=0; l<nStages; l++)
      {
        for (j=sparsePattern_ODE->leadindex[col]; j<sparsePattern_ODE->leadindex[col+1]; j++)
        {
          if (((col + k*nStates) < (sparsePattern_ODE->index[j] + l*nStates)) && !diagElemNonZero)
          {
            coo_col[i] = col + k*nStates;
            coo_row[i] = col + k*nStates;
            i++;
            diagElemNonZero = TRUE;
          }
          // if the entry in A is non-zero, the sparsity pattern of the ODE-Jacobian will be inserted,
          // respectively
          if (A[l*nStages + k] != 0)
          {
            if ((col + k*nStates) == (sparsePattern_ODE->index[j] + l*nStates))
              diagElemNonZero = TRUE;
            coo_col[i] = col + k*nStates;
            coo_row[i] = sparsePattern_ODE->index[j] + l*nStates;
            i++;
          }
        }
      }
    }
  }

  int length_row_indices = jacobian->sizeCols*nStages+1;
  int length_index = numberOfNonZeros;

  // Allocate memory for new sparsity pattern
  sparsePattern_IRK = (SPARSE_PATTERN*) malloc(sizeof(SPARSE_PATTERN));
  sparsePattern_IRK->leadindex = (unsigned int*) malloc((length_row_indices)*sizeof(unsigned int));
  sparsePattern_IRK->index = (unsigned int*) malloc(length_index*sizeof(unsigned int));
  sparsePattern_IRK->sizeofIndex = length_index;
  sparsePattern_IRK->numberOfNonZeros = length_index;
  sparsePattern_IRK->maxColors = jacobian->sizeCols*nStages;
  sparsePattern_IRK->colorCols = (unsigned int*) malloc(sparsePattern_IRK->maxColors*sizeof(unsigned int));

  /* Set diagonal elements of sparsitiy pattern to non-zero */
  for (i=0; i<length_row_indices; i++)
    sparsePattern_IRK->leadindex[i] = 0;

  for (int i = 0; i < numberOfNonZeros; i++)
  {
    sparsePattern_IRK->index[i] = coo_row[i];
    sparsePattern_IRK->leadindex[coo_col[i] + 1]++;
  }
  for (int i = 0; i < sizeCols*nStages; i++)
  {
    sparsePattern_IRK->leadindex[i + 1] += sparsePattern_IRK->leadindex[i];
  }

  ColoringAlg(sparsePattern_IRK, sizeRows*nStages, sizeCols*nStages, nStages);

  // for (int k=0; k<nStages; k++)
  //   printIntVector_genericRK("colorCols: ", &sparsePattern_IRK->colorCols[k*nStates], sizeCols, 0);

  return sparsePattern_IRK;
}

/**
 * @brief Initialize static data of non-linear system for DIRK.
 *
 * Initialize for diagoanl implicit Runge-Kutta (DIRK) method.
 * Sets min, max, nominal values and sparsity pattern.
 *
 * @param data              Runtime data struct
 * @param threadData        Thread data for error handling
 * @param nonlinsys         Non-linear system data.
 */
void initializeStaticNLSData_DIRK(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys) {
  for(int i=0; i<nonlinsys->size; i++) {
    // Get the nominal values of the states
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = DBL_MIN;
    nonlinsys->max[i]     = DBL_MAX;
  }

  /* Initialize sparsity pattern */
  nonlinsys->sparsePattern = initializeSparsePattern_DIRK(data, nonlinsys);
  nonlinsys->isPatternAvailable = TRUE;
  return;
}

/**
 * @brief Initialize static data of non-linear system for DIRK.
 *
 * Initialize for diagoanl implicit Runge-Kutta (DIRK) method.
 * Sets min, max, nominal values and sparsity pattern.
 *
 * @param data              Runtime data struct
 * @param threadData        Thread data for error handling
 * @param nonlinsys         Non-linear system data.
 */
void initializeStaticNLSData_MS(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys) {
  for(int i=0; i<nonlinsys->size; i++) {
    // Get the nominal values of the states
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = DBL_MIN;
    nonlinsys->max[i]     = DBL_MAX;
  }

  /* Initialize sparsity pattern */
  nonlinsys->sparsePattern = initializeSparsePattern_DIRK(data, nonlinsys); // BB ToDo: is this correct
  nonlinsys->isPatternAvailable = TRUE;
  return;
}


/**
 * @brief Initialize static data of non-linear system for IRK.
 *
 * Initialize for implicit Runge-Kutta (IRK) method.
 * Sets min, max, nominal values and sparsity pattern.
 *
 * @param data              Runtime data struct
 * @param threadData        Thread data for error handling
 * @param nonlinsys         Non-linear system data.
 */
void initializeStaticNLSData_IRK(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys) {
  for(int i=0; i<nonlinsys->size; i++) {
    // Get the nominal values of the states, the non-linear system has size stages*nStates
    int ii = nonlinsys->size % data->modelData->nStates;
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[ii].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = DBL_MIN;
    nonlinsys->max[i]     = DBL_MAX;
  }

  /* Initialize sparsity pattern */
  nonlinsys->sparsePattern = initializeSparsePattern_IRK(data, nonlinsys);
  nonlinsys->isPatternAvailable = TRUE;
  return;
}

/**
 * @brief Allocate and initialize non-linear system data for Runge-Kutta method.
 *
 * Runge-Kutta method has to be implicit or diagonal implicit.
 *
 * @param data                        Runtime data struct.
 * @param threadData                  Thread data for error handling.
 * @param gsriData                     Runge-Kutta method.
 * @return NONLINEAR_SYSTEM_DATA*     Pointer to initialized non-linear system data.
 */
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA(DATA* data, threadData_t* threadData, DATA_GSRI* gsriData) {
  assertStreamPrint(threadData, gsriData->type != RK_TYPE_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  // TODO AHeu: Free solverData again
  struct dataSolver *solverData = (struct dataSolver*) calloc(1,sizeof(struct dataSolver));

  ANALYTIC_JACOBIAN* jacobian = NULL;

  NONLINEAR_SYSTEM_DATA* nlsData = (NONLINEAR_SYSTEM_DATA*) calloc(1, sizeof(NONLINEAR_SYSTEM_DATA));
  assertStreamPrint(threadData, nlsData != NULL,"Out of memory");

  analyticalJacobianColumn_func_ptr analyticalJacobianColumn;

  nlsData->size = gsriData->nlSystemSize;
  nlsData->equationIndex = -1;

  nlsData->homotopySupport = FALSE;
  nlsData->initHomotopy = FALSE;
  nlsData->mixedSystem = FALSE;

  nlsData->min = NULL;
  nlsData->max = NULL;
  nlsData->nominal = NULL;

  switch (gsriData->type)
  {
  case RK_TYPE_DIRK:
    nlsData->residualFunc = residual_DIRK;
    nlsData->analyticalJacobianColumn = jacobian_DIRK_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_DIRK;
    nlsData->getIterationVars = NULL;

    gsriData->symJacAvailable = TRUE;
    break;
  case RK_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_IRK;
    nlsData->analyticalJacobianColumn = jacobian_IRK_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_IRK;
    nlsData->getIterationVars = NULL;

    gsriData->symJacAvailable = TRUE;
    break;
  case MS_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_MS;
    nlsData->analyticalJacobianColumn = jacobian_MS_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_MS;
    nlsData->getIterationVars = NULL;

    gsriData->symJacAvailable = TRUE;
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Residual function for NLS type %i not yet implemented.", gsriData->type);
    break;
  }

  /* allocate system data */
  nlsData->nlsx = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->nlsxExtrapolation = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->nlsxOld = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->resValues = (double*) malloc(nlsData->size*sizeof(double));

  nlsData->lastTimeSolved = 0.0;

  nlsData->nominal = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->min = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->max = (double*) malloc(nlsData->size*sizeof(double));

  // TODO: Do we need to initialize the Jacobian or is it already initialized?
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  data->callback->initialAnalyticJacobianA(data, threadData, jacobian_ODE);
  nlsData->initializeStaticNLSData(data, threadData, nlsData);

  // TODO: Set callback to initialize Jacobian
  //       Write said function...
  // TODO: Free memory
  gsriData->jacobian = initAnalyticJacobian(gsriData->nlSystemSize, gsriData->nlSystemSize, gsriData->nlSystemSize, NULL, nlsData->sparsePattern);
  nlsData->initialAnalyticalJacobian = NULL;
  nlsData->jacobianIndex = -1;

  /* Initialize NLS method */
  switch (gsriData->nlsSolverMethod) {
  case RK_NLS_NEWTON:
    nlsData->nlsMethod = NLS_NEWTON;
    nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    nlsData->jacobianIndex = -1;
    solverData->ordinaryData =(void*) allocateNewtonData(nlsData->size);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case RK_NLS_KINSOL:
    nlsData->nlsMethod = NLS_KINSOL;
    if (gsriData->symJacAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsData->nlsLinearSolver);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    if (gsriData->symJacAvailable) {
      resetKinsolMemory(solverData->ordinaryData, nlsData->sparsePattern->numberOfNonZeros, nlsData->analyticalJacobianColumn);
    } else {
      resetKinsolMemory(solverData->ordinaryData, nlsData->size*nlsData->size, NULL);
      int flag = KINSetJacFn(((NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory, NULL);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
    }
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Memory allocation for NLS method %s not yet implemented.", RK_NLS_METHOD_NAME[gsriData->nlsSolverMethod]);
    return NULL;
    break;
  }

  return nlsData;
}

/**
 * @brief Function allocates memory needed for generic RK method.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Information about main solver.
 * @return int          Return 0 on success, -1 on failure.
 */
int allocateDataGenericRK(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo) {
  DATA_GSRI* gsriData = (DATA_GSRI*) malloc(sizeof(DATA_GSRI));

  // Set backup in simulationInfo
  data->simulationInfo->backupSolverData = (void*) gsriData;

  solverInfo->solverData = (void*) gsriData;

  gsriData->nStates = data->modelData->nStates;

  ANALYTIC_JACOBIAN* jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;

  gsriData->RK_method = getRK_Method(FLAG_RK);
  gsriData->tableau = initButcherTableau(gsriData->RK_method);
  if (gsriData->tableau == NULL){
    errorStreamPrint(LOG_STDOUT, 0, "allocateDataGenericRK: Failed to initialize butcher tableau for Runge-Kutta method %s", RK_SINGLERATE_METHOD_NAME[gsriData->RK_method]);
    return -1;
  }

  // Get size of non-linear system
  analyseButcherTableau(gsriData->tableau, gsriData->nStates, &gsriData->nlSystemSize, &gsriData->type);

  switch (gsriData->type)
  {
  case RK_TYPE_EXPLICIT:
    gsriData->isExplicit = TRUE;
    gsriData->step_fun = &(expl_diag_impl_RK);
    break;
  case RK_TYPE_DIRK:
    gsriData->isExplicit = FALSE;
    gsriData->step_fun = &(expl_diag_impl_RK);
    break;
  case RK_TYPE_IMPLICIT:
    gsriData->isExplicit = FALSE;
    gsriData->step_fun = &(full_implicit_RK);
    break;
  case MS_TYPE_IMPLICIT:
    gsriData->isExplicit = FALSE;
    gsriData->step_fun = &(full_implicit_MS);
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "allocateDataGenericRK: Unknown Runge-Kutta type %i", gsriData->type);
    return -1;
  }
  // adapt decision for testing of the fully implicit implementation
  if (gsriData->RK_method == RK_ESDIRK2_test || gsriData->RK_method == RK_ESDIRK3_test) {
    gsriData->nlSystemSize = gsriData->tableau->nStages*gsriData->nStates;
    gsriData->step_fun = &(full_implicit_RK);
    gsriData->type = RK_TYPE_IMPLICIT;
  }
  if (gsriData->RK_method == MS_ADAMS_MOULTON) {
    gsriData->nlSystemSize = gsriData->nStates;
    gsriData->step_fun = &(full_implicit_MS);
    gsriData->type = MS_TYPE_IMPLICIT;
    gsriData->isExplicit = FALSE;
  }

  // test of multistep method

  const char* flag_StepSize_ctrl = omc_flagValue[FLAG_RK_STEPSIZE_CTRL];

  if (flag_StepSize_ctrl != NULL) {
    gsriData->stepSize_control = &(PIController);
    infoStreamPrint(LOG_SOLVER, 0, "Stepsize control using PIController");
  } else
  {
    gsriData->stepSize_control = &(IController);
    infoStreamPrint(LOG_SOLVER, 0, "Stepsize control using IController");
  }

  /* Allocate internal memory */
  gsriData->isFirstStep = TRUE;
  gsriData->y = malloc(sizeof(double)*gsriData->nStates);
  gsriData->yOld = malloc(sizeof(double)*gsriData->nStates);
  gsriData->yLeft = malloc(sizeof(double)*gsriData->nStates);
  gsriData->yt = malloc(sizeof(double)*gsriData->nStates);
  gsriData->f = malloc(sizeof(double)*gsriData->nStates);
  gsriData->k = malloc(sizeof(double)*gsriData->nStates*gsriData->tableau->nStages);
  gsriData->x = malloc(sizeof(double)*gsriData->nStates*gsriData->tableau->nStages);
  gsriData->res_const = malloc(sizeof(double)*gsriData->nStates);
  gsriData->errest = malloc(sizeof(double)*gsriData->nStates);
  gsriData->errtol = malloc(sizeof(double)*gsriData->nStates);
  gsriData->err = malloc(sizeof(double)*gsriData->nStates);
  gsriData->ringBufferSize = 5;
  gsriData->errValues = malloc(sizeof(double)* gsriData->ringBufferSize);
  gsriData->stepSizeValues = malloc(sizeof(double)* gsriData->ringBufferSize);
  if (!gsriData->isExplicit) {
    gsriData->Jf = malloc(sizeof(double)*gsriData->nStates*gsriData->nStates);
    for (int i=0; i<gsriData->nStates*gsriData->nStates; i++)
      gsriData->Jf[i] = 0;
  } else {
    gsriData->Jf = NULL;
  }

  printButcherTableau(gsriData->tableau);

  /* initialize statistic counter */
  // TODO AHeu: Use calloc instead?
  gsriData->stepsDone = 0;
  gsriData->evalFunctionODE = 0;
  gsriData->evalJacobians = 0;
  gsriData->errorTestFailures = 0;
  gsriData->convergenceFailures = 0;

  /* initialize analytic Jacobian, if available and needed */
  if (!gsriData->isExplicit) {
    jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    // TODO: Do we need to initialize the Jacobian or is it already initialized?
    if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian)) {
      gsriData->symJacAvailable = FALSE;
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to numeric Jacobians.");
    } else {
      gsriData->symJacAvailable = TRUE;
      // TODO AHeu: Is there a reason we get the jacobian again? Did data->callback->initialAnalyticJacobianA change the pointer?
      // ANALYTIC_JACOBIAN* jac = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
      infoStreamPrint(LOG_SOLVER, 1, "Initialized colored Jacobian:");
      infoStreamPrint(LOG_SOLVER, 0, "columns: %d rows: %d", jacobian->sizeCols, jacobian->sizeRows);
      infoStreamPrint(LOG_SOLVER, 0, "NNZ:  %d colors: %d", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
      messageClose(LOG_SOLVER);
    }

  /* Allocate memory for the nonlinear solver */
    gsriData->nlsSolverMethod = getRK_NLS_Method();
    gsriData->nlsData = initRK_NLS_DATA(data, threadData, gsriData);
    if (!gsriData->nlsData) {
      return -1;
    }
  }
  else
  {
    gsriData->symJacAvailable = FALSE;
    gsriData->nlsSolverMethod = RK_NLS_UNKNOWN;  // TODO AHeu: Add a no-solver option?
    gsriData->nlsData = NULL;
    gsriData->jacobian = NULL;
  }

  if (solverInfo->solverMethod == S_GENERIC_RK_MR)
  {
    gsriData->multi_rate = 1;
    const char* flag_value = omc_flagValue[FLAG_RK_MR_PAR];
    if (flag_value != NULL) {
      gsriData->percentage = atof(omc_flagValue[FLAG_RK_MR_PAR]);
    } else
    {
      gsriData->percentage = 0.3;
    }
  } else
  {
    gsriData->multi_rate = 0;
    gsriData->percentage = 1;
  }

  gsriData->fastStates = malloc(sizeof(int)*gsriData->nStates);
  gsriData->slowStates = malloc(sizeof(int)*gsriData->nStates);
  gsriData->sortedStates = malloc(sizeof(int)*gsriData->nStates);

  gsriData->nFastStates = 0;
  gsriData->nSlowStates = gsriData->nStates;
  for (int i=0; i<gsriData->nStates; i++)
  {
    gsriData->slowStates[i] = i;
    gsriData->sortedStates[i] = i;
  }

  if (solverInfo->solverMethod == S_GENERIC_RK_MR) {
    allocateDataGenericRK_MR(data, threadData, gsriData);
  } else {
    gsriData->gmriData = NULL;
  }

  return 0;
}

/**
 * @brief Free generic RK data.
 *
 * @param gsriData    Pointer to generik Runge-Kutta data struct.
 */
void freeDataGenericRK(DATA_GSRI* gsriData) {
  /* Free non-linear system data */
  if(gsriData->nlsData != NULL) {
    struct dataSolver* dataSolver = gsriData->nlsData->solverData;
    switch (gsriData->nlsSolverMethod)
    {
    case RK_NLS_NEWTON:
      freeNewtonData(dataSolver->ordinaryData);
      break;
    case RK_NLS_KINSOL:
      //kinsolData = (NLS_KINSOL_DATA*) gsriData->nlsData->solverData;
      nlsKinsolFree(dataSolver->ordinaryData);
      break;
    default:
      warningStreamPrint(LOG_SOLVER, 0, "Not handled RK_NLS_METHOD in freeDataGenericRK. Are we leaking memroy?");
      break;
    }
    free(dataSolver);
    free(gsriData->nlsData);
  }
  /* Free Jacobian */
  freeAnalyticJacobian(gsriData->jacobian);

  /* Free Butcher tableau */
  freeButcherTableau(gsriData->tableau);

  if (gsriData->multi_rate == 1) {
    freeDataGenericRK_MR(gsriData->gmriData);
  }
  /* Free multi-rate data */
  free(gsriData->err);
  free(gsriData->errValues);
  free(gsriData->stepSizeValues);
  free(gsriData->fastStates);
  free(gsriData->slowStates);

  /* Free remaining arrays */
  free(gsriData->y);
  free(gsriData->yOld);
  free(gsriData->yLeft);
  free(gsriData->yt);
  free(gsriData->f);
  free(gsriData->Jf);
  free(gsriData->k);
  free(gsriData->x);
  free(gsriData->res_const);
  free(gsriData->errest);
  free(gsriData->errtol);

  free(gsriData);
  gsriData = NULL;

  return;
}

/**
 * @brief Calculate function values of function ODE f(t,y).
 *
 * Assuming the correct values for time value and states are set.
 *
 * @param data               Runtime data struct.
 * @param threadData         Thread data for error handling.
 * @param evalFunctionsODE   Counter for function calls.
 * @param fODE               Array of state derivatives.
 * @return int               Returns 0 on success.
 */
int wrapper_f_genericRK(DATA* data, threadData_t *threadData, void* evalFunctionODE, modelica_real* fODE)
{
  unsigned int* counter = (unsigned int*) evalFunctionODE;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  fODE = sData->realVars + data->modelData->nStates;

  (*counter)++;

  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  data->callback->functionODE(data, threadData);

  return 0;
}

/**
 * @brief Residual function for non-linear system of generic multistep methods.
 *
 * TODO: Describe what the residual means.
 *
 * @param dataIn  Userdata provided to non-linear system solver.
 * @param xloc    Input vector for non-linear system.
 * @param res     Residuum vector for given input xloc.
 * @param iflag   Unused.
 */
void residual_MS(void **dataIn, const double *xloc, double *res, const int *iflag)
{
  DATA *data = (DATA *)((void **)dataIn[0]);
  threadData_t *threadData = (threadData_t *)((void **)dataIn[1]);
  DATA_GSRI *gsriData = (DATA_GSRI *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i;
  int nStates = data->modelData->nStates;
  int nStages = gsriData->tableau->nStages;
  int stage_   = gsriData->act_stage;

  // Evaluate right hand side of ODE
  memcpy(sData->realVars, xloc, nStates*sizeof(double));
  wrapper_f_genericRK(data, threadData, &(gsriData->evalFunctionODE), fODE);

  // Evaluate residual
  for (i=0; i<nStates; i++) {
    res[i] = gsriData->res_const[i] - xloc[i] * gsriData->tableau->c[nStages-1] +
                                      fODE[i] * gsriData->tableau->b[nStages-1] * gsriData->stepSize;
  }

  return;
}

/**
 * @brief Evaluate column of DIRK Jacobian.
 *
 * @param inData            Void pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gsriData     Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_MS_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA* data = (DATA*) inData;
  DATA_GSRI* gsriData = (DATA_GSRI*) data->simulationInfo->backupSolverData;

  int i;
  int nStates = data->modelData->nStates;
  int nStages = gsriData->tableau->nStages;
  int stage = gsriData->act_stage;

  /* Evaluate column of Jacobian ODE */
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  memcpy(jacobian_ODE->seedVars, jacobian->seedVars, sizeof(modelica_real)*jacobian->sizeCols);
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  for (i = 0; i < jacobian->sizeCols; i++) {
    jacobian->resultVars[i] = gsriData->tableau->b[nStages-1] * gsriData->stepSize * jacobian_ODE->resultVars[i];
    /* -1 on diagonal elements */
    if (jacobian->seedVars[i] == 1) {
      jacobian->resultVars[i] -= gsriData->tableau->c[nStages-1];
    }
  }

  return 0;
}


/**
 * @brief Residual function for non-linear system for diagonal implicit Runge-Kutta methods.
 *
 * TODO: Describe what the residual means.
 *
 * @param dataIn  Userdata provided to non-linear system solver.
 * @param xloc    Input vector for non-linear system.
 * @param res     Residuum vector for given input xloc.
 * @param iflag   Unused.
 */
void residual_DIRK(void **dataIn, const double *xloc, double *res, const int *iflag)
{
  DATA *data = (DATA *)((void **)dataIn[0]);
  threadData_t *threadData = (threadData_t *)((void **)dataIn[1]);
  DATA_GSRI *gsriData = (DATA_GSRI *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i;
  int nStates = data->modelData->nStates;
  int nStages = gsriData->tableau->nStages;
  int stage_   = gsriData->act_stage;

  // Evaluate right hand side of ODE
  memcpy(sData->realVars, xloc, nStates*sizeof(double));
  wrapper_f_genericRK(data, threadData, &(gsriData->evalFunctionODE), fODE);

  // Evaluate residual
  for (i=0; i<nStates; i++) {
    res[i] = gsriData->res_const[i] - xloc[i] + gsriData->stepSize * gsriData->tableau->A[stage_ * nStages + stage_] * fODE[i];
  }

  return;
}

/**
 * @brief Evaluate column of DIRK Jacobian.
 *
 * @param inData            Void pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gsriData     Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_DIRK_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA* data = (DATA*) inData;
  DATA_GSRI* gsriData = (DATA_GSRI*) data->simulationInfo->backupSolverData;

  int i;
  int nStates = data->modelData->nStates;
  int nStages = gsriData->tableau->nStages;
  int stage = gsriData->act_stage;

  /* Evaluate column of Jacobian ODE */
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  memcpy(jacobian_ODE->seedVars, jacobian->seedVars, sizeof(modelica_real)*jacobian->sizeCols);
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  for (i = 0; i < jacobian->sizeCols; i++) {
    jacobian->resultVars[i] = gsriData->stepSize * gsriData->tableau->A[stage * nStages + stage] * jacobian_ODE->resultVars[i];
    /* -1 on diagonal elements */
    if (jacobian->seedVars[i] == 1) {
      jacobian->resultVars[i] -= 1;
    }
  }

  return 0;
}


/**
 * @brief Evaluate residual for non-linear system of implicit Runge-Kutta method.
 *
 * TODO: Describe how the residual is computed.
 *
 * @param dataIn  Userdata provided to non-linear system solver.
 * @param xloc    Input vector for non-linear system.
 * @param res     Residuum vector for given input xloc.
 * @param iflag   Unused.
 */
void residual_IRK(void **dataIn, const double *xloc, double *res, const int *iflag) {

  DATA *data = (DATA *)((void **)dataIn[0]);
  threadData_t *threadData = (threadData_t *)((void **)dataIn[1]);
  DATA_GSRI *gsriData = (DATA_GSRI *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;

  int i;
  int nStages = gsriData->tableau->nStages;
  int nStates = data->modelData->nStates;
  int stage, stage_;

  for (stage_=0; stage_<nStages; stage_++)
  {
    /* Evaluate ODE and compute res for each stage_ */
    sData->timeValue = gsriData->time + gsriData->tableau->c[stage_] * gsriData->stepSize;
    memcpy(sData->realVars, &xloc[stage_*nStates], nStates*sizeof(double));
    wrapper_f_genericRK(data, threadData, &(gsriData->evalFunctionODE), fODE);
    memcpy(&gsriData->k[stage_*nStates], fODE, nStates*sizeof(double));
  }

  // Calculate residuum for the full implicit RK method based on stages and A matrix
  for (stage=0; stage<nStages; stage++)
  {
    for (i=0; i<nStates; i++)
    {
      res[stage * nStates + i] = gsriData->yOld[i] - xloc[stage * nStates + i];
      for (stage_=0; stage_<nStages; stage_++)
      {
        res[stage * nStates + i] += gsriData->stepSize * gsriData->tableau->A[stage * nStages + stage_] * (gsriData->k + stage_*nStates)[i];
      }
    }
  }

  return;
}


/**
 * @brief Evaluate column of IRK Jacobian.
 *
 * @param inData            Void pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gsriData     Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_IRK_column(void *inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA* data = (DATA*) inData;
  DATA_GSRI* gsriData = (DATA_GSRI*) data->simulationInfo->backupSolverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  const double* xloc = gsriData->nlsData->nlsx;

  int i;
  int stage, stage_;
  int nStages = gsriData->tableau->nStages;
  int nStates = data->modelData->nStates;

  /* Evaluate column of Jacobian ODE */
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  // and find out which stage is active; different stages have different colors
  // reset jacobian_ODE->seedVars
  for (i=0; i<jacobian_ODE->sizeCols; i++)
    jacobian_ODE->seedVars[i] = 0;
  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  for (i=0, stage_=0; i<jacobian->sizeCols; i++)
  {
    if (jacobian->seedVars[i])
    {
      stage_ = i;
      jacobian_ODE->seedVars[i%jacobian_ODE->sizeCols] = 1;
    }
  }
  // Determine active stage
  stage_ = stage_/jacobian_ODE->sizeCols;

  // update timeValue and unknown vector based on the active column "stage_"
  sData->timeValue = gsriData->time + gsriData->tableau->c[stage_] * gsriData->stepSize;
  // BB ToDo: ist xloc das gleiche wie gsriData->nlsData->nlsx
  memcpy(sData->realVars, &(xloc[stage_*nStates]), nStates*sizeof(double));
  // call jacobian_ODE with the mapped seedVars
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array for corresponding jacobian->seedVars*/
  for (stage=0; stage<nStages; stage++)
  {
    for (i=0; i<nStates; i++)
    {
      jacobian->resultVars[stage * nStates + i] = gsriData->stepSize * gsriData->tableau->A[stage * nStages + stage_]  * jacobian_ODE->resultVars[i];
      /* -1 on diagonal elements */
      if (jacobian->seedVars[stage * nStates + i] == 1) {
        jacobian->resultVars[stage * nStates + i] -= 1;
      }
    }
  }

  return 0;
}

/**
 * @brief Generic multistep function.
 *
 * Internal non-linear equation system will be solved with non-linear solver specified during setup.
 * Results will be saved in y and embedded results saved in yt.
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Storing Runge-Kutta solver data.
 * @return int              Return 0 on success, -1 on failure.
 */
int full_implicit_MS(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GSRI* gsriData = (DATA_GSRI*)solverInfo->solverData;

  int i;
  int stage, stage_;
  int nStates = data->modelData->nStates;
  int nStages = gsriData->tableau->nStages;
  modelica_boolean solved = FALSE;

  // printVector_genericRK("k:  ", gsriData->k + (nStages-1) * nStates, nStates, gsriData->time);

  /* Predictor Schritt */
  for (i = 0; i < nStates; i++)
  {
    // BB ToDo: check the formula with respect to gsriData->k[]
    gsriData->yt[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gsriData->yt[i] += -gsriData->x[stage_ * nStates + i] * gsriData->tableau->c[stage_] +
                          gsriData->k[stage_ * nStates + i] * gsriData->tableau->bt[stage_] *  gsriData->stepSize;//gsriData->stepSizeValues[nStages-2-stage_];
    }
    gsriData->yt[i] += gsriData->k[stage_ * nStates + i] * gsriData->tableau->bt[stage_] * gsriData->stepSize;
    gsriData->yt[i] /= gsriData->tableau->c[stage_];
  }


  /* Constant part of the multistep method */
  for (i = 0; i < nStates; i++)
  {
    // BB ToDo: check the formula with respect to gsriData->k[]
    gsriData->res_const[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gsriData->res_const[i] += -gsriData->x[stage_ * nStates + i] * gsriData->tableau->c[stage_] +
                                 gsriData->k[stage_ * nStates + i] * gsriData->tableau->b[stage_] *  gsriData->stepSize;//gsriData->stepSizeValues[nStages-2-stage_];
    }
  }
  // printVector_genericRK("res_const:  ", gsriData->res_const, nStates, gsriData->time);

  /* Compute intermediate step k, explicit if diagonal element is zero, implicit otherwise
    * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
  // here, it yields:   stage == stage_, and stage * nStages + stage_ is index of the diagonal element

  // set simulation time with respect to the current stage
  sData->timeValue = gsriData->time + gsriData->stepSize;

  // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
  NONLINEAR_SYSTEM_DATA* nlsData = gsriData->nlsData;
  // Set start vector, BB ToDo: Ommit extrapolation after event!!!

  memcpy(nlsData->nlsx, gsriData->yt, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
  solved = solveNLS(data, threadData, nlsData, -1);
  if (!solved) {
    errorStreamPrint(LOG_STDOUT, 0, "full_implicit_MS: Failed to solve NLS in full_implicit_MS");
    return -1;
  }
  // copy last calculation of fODE, which should coincide with k[i], here, it yields stage == stage_
  memcpy(gsriData->k + stage_ * nStates, fODE, nStates*sizeof(double));
  memcpy(gsriData->x + stage_ * nStates, nlsData->nlsx, nStates*sizeof(double));
  memcpy(gsriData->y, nlsData->nlsx, nStates*sizeof(double));

  // printVector_genericRK("yt: ", gsriData->yt, nStates, gsriData->time);
  // printVector_genericRK("y:  ", gsriData->y, nStates, gsriData->time);

  return 0;
}

/**
 * @brief Generic diagonal implicit Runge-Kutta step function.
 *
 * Internal non-linear equation system will be solved with non-linear solver specified during setup.
 * Results will be saved in y and embedded results saved in yt.
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Storing Runge-Kutta solver data.
 * @return int              Return 0 on success, -1 on failure.
 */
int expl_diag_impl_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GSRI* gsriData = (DATA_GSRI*)solverInfo->solverData;

  int i;
  int stage, stage_;
  int nStates = data->modelData->nStates;
  int nStages = gsriData->tableau->nStages;
  modelica_boolean solved = FALSE;

  // First try for better starting values, only necessary after restart
  // BB ToDo: Or maybe necessary for RK methods, where b is not equal to the last row of A
  if (gsriData->didEventStep) {
    sData->timeValue = gsriData->time;
    memcpy(sData->realVars, gsriData->yOld, nStates*sizeof(double));
    wrapper_f_genericRK(data, threadData, &(gsriData->evalFunctionODE), fODE);
    memcpy(gsriData->k + (nStages-1) * nStates, fODE, nStates*sizeof(double));
    gsriData->didEventStep = FALSE;
  }

  /* Runge-Kutta step */
  for (stage = 0; stage < nStages; stage++)
  {
    gsriData->act_stage = stage;
    /* Set constant parts or residual input
     * res = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..stage-1)) */

    for (i = 0; i < nStates; i++)
    {
      // BB ToDo: check the formula with respect to gsriData->k[]
      gsriData->res_const[i] = gsriData->yOld[i];
      for (stage_ = 0; stage_ < stage; stage_++)
      {
        gsriData->res_const[i] += gsriData->stepSize * gsriData->tableau->A[stage * nStages + stage_] * gsriData->k[stage_ * nStates + i];
      }
    }

    /* Compute intermediate step k, explicit if diagonal element is zero, implicit otherwise
     * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
    // here, it yields:   stage == stage_, and stage * nStages + stage_ is index of the diagonal element

    // set simulation time with respect to the current stage
    sData->timeValue = gsriData->time + gsriData->tableau->c[stage_]*gsriData->stepSize;


    if (gsriData->tableau->A[stage * nStages + stage_] == 0)
    {
      memcpy(sData->realVars, gsriData->res_const, nStates*sizeof(double));
      wrapper_f_genericRK(data, threadData, &(gsriData->evalFunctionODE), fODE);
    }
    else
    {
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = gsriData->nlsData;
      // Set start vector, BB ToDo: Ommit extrapolation after event!!!

      for (i=0; i<nStates; i++)
        nlsData->nlsx[i] = gsriData->yOld[i] + gsriData->tableau->c[stage_] * gsriData->stepSize * (gsriData->k + (nStages-1)*nStates)[i];
      //memcpy(nlsData->nlsx, gsriData->yOld, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
      solved = solveNLS(data, threadData, nlsData, -1);
      if (!solved) {
        errorStreamPrint(LOG_STDOUT, 0, "expl_diag_impl_RK: Failed to solve NLS in expl_diag_impl_RK in stage %d", stage_);
        return -1;
      }
    }
    // copy last calculation of fODE, which should coincide with k[i], here, it yields stage == stage_
    memcpy(gsriData->k + stage_ * nStates, fODE, nStates*sizeof(double));
  }

  // Apply RK-scheme for determining the approximations at (gsriData->time + gsriData->stepSize)
  // y       = yold+h*sum(b[stage_]  * k[stage_], stage_=1..nStages);
  // yt      = yold+h*sum(bt[stage_] * k[stage_], stage_=1..nStages);
  for (i=0; i<nStates; i++)
  {
    gsriData->y[i]  = gsriData->yOld[i];
    gsriData->yt[i] = gsriData->yOld[i];
    for (stage_=0; stage_<nStages; stage_++)
    {
      gsriData->y[i]  += gsriData->stepSize * gsriData->tableau->b[stage_]  * (gsriData->k + stage_ * nStates)[i];
      gsriData->yt[i] += gsriData->stepSize * gsriData->tableau->bt[stage_] * (gsriData->k + stage_ * nStates)[i];
    }
  }

  return 0;
}

/**
 * @brief Single implicit Runge-Kutta step.
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Storing Runge-Kutta solver data.
 * @return int              Return 0 on success, -1 on failure.
 */
int full_implicit_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GSRI* gsriData = (DATA_GSRI*)solverInfo->solverData;

  NONLINEAR_SYSTEM_DATA* nlsData = gsriData->nlsData;

  int i;
  int stage_;
  int nStates = data->modelData->nStates;
  int nStages = gsriData->tableau->nStages;

  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;
  modelica_boolean solved = FALSE;

  // First try for better starting values, only necessary after restart
  // BB ToDo: Or maybe necessary for RK methods, where b is not equal to the last row of A
  if (gsriData->didEventStep) {
    memcpy(sData->realVars, gsriData->yOld, nStates*sizeof(double));
    wrapper_f_genericRK(data, threadData, &(gsriData->evalFunctionODE), fODE);
    memcpy(gsriData->k + (nStages-1) * nStates, fODE, nStates*sizeof(double));
    gsriData->didEventStep = FALSE;
  }

  /* Set start values for non-linear solver */
  for (stage_=0; stage_<nStages; stage_++) {
    // BB ToDo: Ommit extrapolation after event!!!
    for (i=0; i<nStates; i++)
      nlsData->nlsx[stage_*nStates +i] = gsriData->yOld[i] + gsriData->tableau->c[stage_] * gsriData->stepSize * (gsriData->k + (nStages-1)*nStates)[i];

    // memcpy(&nlsData->nlsx[stage_*nStates], gsriData->yOld, nStates*sizeof(double));
    memcpy(&nlsData->nlsxOld[stage_*nStates], &nlsData->nlsx[stage_*nStates], nStates*sizeof(double));
    memcpy(&nlsData->nlsxExtrapolation[stage_*nStates], &nlsData->nlsx[stage_*nStates], nStates*sizeof(double));
  }

  solved = solveNLS(data, threadData, gsriData->nlsData, -1);
  if (!solved) {
    errorStreamPrint(LOG_STDOUT, 0, "full_implicit_RK: Failed to solve NLS in full_implicit_RK");
    return -1;
  }

  // Apply RK-scheme for determining the approximations at (gsriData->time + gsriData->stepSize)
  // y       = yold+h*sum(b[stage_]  * k[stage_], stage_=1..nStages);
  // yt      = yold+h*sum(bt[stage_] * k[stage_], stage_=1..nStages);
  for (i=0; i<nStates; i++)
  {
    gsriData->y[i]  = gsriData->yOld[i];
    gsriData->yt[i] = gsriData->yOld[i];
    for (stage_=0; stage_<nStages; stage_++)
    {
      gsriData->y[i]  += gsriData->stepSize * gsriData->tableau->b[stage_]  * (gsriData->k + stage_ * nStates)[i];
      gsriData->yt[i] += gsriData->stepSize * gsriData->tableau->bt[stage_] * (gsriData->k + stage_ * nStates)[i];
    }
  }

  return 0;
}

/**
 * @brief Initialize values and calculate initial step size.
 *
 * Called at the beginning of simulation or after an event occurred.
 *
 * TODO BB: Lookup the reference in Hairers book
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Storing Runge-Kutta solver data.
 */
void genericRK_first_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_GSRI* gsriData = (DATA_GSRI*)solverInfo->solverData;
  int nStates = data->modelData->nStates;
  int nStages = gsriData->tableau->nStages;
  modelica_real* fODE = &sData->realVars[nStates];

  double sc, d, d0 = 0.0, d1 = 0.0, d2 = 0.0, h0, h1, delta_ti, infNorm, sum = 0;
  // TODO AHeu: We have flags for absolute and relative solver tolerances
  // Use data->simulationInfo->tolerance?
  double Atol = 1e-6;
  double Rtol = 1e-3;

  int i,j;

  /* store Startime of the simulation */
  gsriData->time = sDataOld->timeValue;
  if (gsriData->multi_rate)
      gsriData->gmriData->time = gsriData->time;
    gsriData->timeLeft = gsriData->time;
    gsriData->timeRight = gsriData->time;
  /* set correct flags in order to calculate initial step size */
  gsriData->isFirstStep = FALSE;
  gsriData->didEventStep = TRUE;
  solverInfo->didEventStep = FALSE;

  for (int i=0; i<gsriData->ringBufferSize; i++) {
    gsriData->errValues[i] = 0;
    gsriData->stepSizeValues[i] = 0;
  }

 /* reset statistics because it is accumulated in solver_main.c */
  gsriData->stepsDone = 0;
  gsriData->evalFunctionODE = 0;
  gsriData->evalJacobians = 0;
  gsriData->errorTestFailures = 0;
  gsriData->convergenceFailures = 0;

  /* calculate starting step size 1st Version */
  /* BB: What is the difference between sData and sDataOld at this time instance?
         Is this important for the restart after an event?
         And should this also been copied to userdata->old (see above?)
  */
  /* initialize start values of the integrator and calculate ODE function*/
  //printVector_genericRK("sData->realVars: ", sData->realVars, data->modelData->nStates, sData->timeValue);
  //printVector_genericRK("sDataOld->realVars: ", sDataOld->realVars, data->modelData->nStates, sDataOld->timeValue);
  memcpy(gsriData->yOld, sData->realVars, data->modelData->nStates*sizeof(double));
  wrapper_f_genericRK(data, threadData, &(gsriData->evalFunctionODE), fODE);
  /* store values of the state derivatives at initial or event time */
  memcpy(gsriData->f, fODE, data->modelData->nStates*sizeof(double));
  memcpy(gsriData->k + (nStages-2) * nStates, fODE, nStates*sizeof(double));

  if (gsriData->type == MS_TYPE_IMPLICIT) {
      memcpy(gsriData->x + (nStages-2) * nStates, gsriData->yOld, nStates*sizeof(double));
  }

  for (i=0; i<data->modelData->nStates; i++)
  {
    sc = Atol + fabs(sDataOld->realVars[i])*Rtol;
    d0 += ((sDataOld->realVars[i] * sDataOld->realVars[i])/(sc*sc));
    d1 += ((fODE[i] * fODE[i]) / (sc*sc));
  }
  d0 /= data->modelData->nStates;
  d1 /= data->modelData->nStates;

  d0 = sqrt(d0);
  d1 = sqrt(d1);

  /* calculate first guess of the initial step size */
  if (d0 < 1e-5 || d1 < 1e-5)
  {
    h0 = 1e-6;
  }
  else
  {
    h0 = 0.01 * d0/d1;
  }


  for (i=0; i<data->modelData->nStates; i++)
  {
    sData->realVars[i] = gsriData->yOld[i] + fODE[i] * h0;
  }
  sData->timeValue += h0;

  wrapper_f_genericRK(data, threadData, &(gsriData->evalFunctionODE), fODE);

  for (i=0; i<data->modelData->nStates; i++)
  {
    sc = Atol + fabs(gsriData->yOld[i])*Rtol;
    d2 += ((fODE[i]-gsriData->f[i])*(fODE[i]-gsriData->f[i])/(sc*sc));
  }

  d2 /= h0;
  d2 = sqrt(d2);


  d = fmax(d1,d2);

  if (d > 1e-15)
  {
    h1 = sqrt(0.01/d);
  }
  else
  {
    h1 = fmax(1e-6, h0*1e-3);
  }

  gsriData->stepSize = 0.5*fmin(100*h0,h1);
  gsriData->lastStepSize = gsriData->stepSize;

  infoStreamPrint(LOG_SOLVER, 0, "initial step size = %e at time %g", gsriData->stepSize, gsriData->time);
}


/**
 * @brief simple step size control (see Hairer, etc.)
 *
 * @param gsriData
 * @return double
 */
double IController(double* err_values, double* stepSize_values, double err_order)
{
  double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.5;
  double beta = -1./err_order;

  return fmin(facmax, fmax(facmin, fac*pow(err_values[0], beta)));

}

/**
 * @brief PI controller for step size control (see Hairer)
 *
 * @param gsriData
 * @return double
 */
double PIController(double* err_values, double* stepSize_values, double err_order)
{
  double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.5;
  double beta1=-1./err_order, beta2=-1./err_order;

  return fmin(facmax, fmax(facmin, fac*pow(err_values[0], beta1)*pow(err_values[1]/err_values[0], beta2)));

}

/**
 * @brief Generic Runge-Kutta step.
 *
 * Do one Runge-Kutta integration step.
 * has step-size control and event handling.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Storing Runge-Kutta solver data.
 * @return int          Return 0 on success, -1 on failure.
 */
int genericRK_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1]; // BB: Is this the ring buffer???
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GSRI* gsriData = (DATA_GSRI*)solverInfo->solverData;

  double err;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;
  int i, ii, l;
  int nStates = (int) data->modelData->nStates;
  int rk_step_info;

  double targetTime;
  double eventTime;
  double stopTime = data->simulationInfo->stopTime;

  solverInfo->solverRootFinding = 1;

  infoStreamPrint(LOG_SOLVER, 1, "generic Runge-Kutta method:");

  // TODO AHeu: Copy-paste code used in dassl,c, ida.c, irksco.c and here. Make it a function!
  // Also instead of solverInfo->integratorSteps we should set and use solverInfo->solverNoEquidistantGrid
  /* Calculate steps until targetTime is reached */
  if (solverInfo->integratorSteps) // 1 => stepSizeControl; 0 => equidistant grid
  {
    if (data->simulationInfo->nextSampleEvent < data->simulationInfo->stopTime)
    {
      targetTime = data->simulationInfo->nextSampleEvent;
    }
    else
    {
      targetTime = data->simulationInfo->stopTime;
    }
  }
  else
  {
    targetTime = sDataOld->timeValue + solverInfo->currentStepSize;
  }

  // (Re-)initialize after events or at first call of genericRK_step
  if (solverInfo->didEventStep == 1 || gsriData->isFirstStep)
  {
    genericRK_first_step(data, threadData, solverInfo);

    // side effect:
    //    sData->realVars, userdata->yOld, and userdata->f are consistent
    //    userdata->time and userdata->stepSize are defined
  }

  // Check if multirate step is necessary, otherwise the correct values are already stored in sData
  if (gsriData->multi_rate)
    if (gsriData->nFastStates > 0 && gsriData->gmriData->time < gsriData->time)
      if (genericRK_MR_step(data, threadData, solverInfo, targetTime))
              return 0;


  /* Main integration loop */
  while (gsriData->time < targetTime)
  {
    do
    {
      // printVector_genericRK("yOld: ", gsriData->yOld, nStates, gsriData->time);
      // printVector_genericRK("y:    ", gsriData->y, nStates, gsriData->time);
      /* store yOld in yLeft for interpolation purposes, if necessary
      * BB: Check condition
      */
      memcpy(gsriData->yLeft, gsriData->yOld, data->modelData->nStates*sizeof(double));
      gsriData->timeLeft = gsriData->time;

      /* calculate jacobian:
       *    once for the first iteration after initial or an event
       *    solverData->calculate_jacobian = 0
       *    always
       *    solverData->calculate_jacobian = 1
       *
       * BB: How does this actually work in combination with the Newton method?
       */
      // TODO AHeu: Not sure how to handle this one
      //if (rkData->stepsDone == 0)
      //  solverData->calculate_jacobian = 0;

      // calculate one step of the integrator
      rk_step_info = gsriData->step_fun(data, threadData, solverInfo);

      // error handling: try half of the step size!
      if (rk_step_info != 0) {
        errorStreamPrint(LOG_STDOUT, 0, "genericRK_step: Failed to calculate step at time = %5g.", gsriData->time);
        errorStreamPrint(LOG_STDOUT, 0, "Try half of the step size!");
        gsriData->stepSize = gsriData->stepSize/2.;
        continue;
        //return -1;
      }

      // calculate corresponding values for error estimator and step size control
      // BB ToDo: Investigate error estimator with respect for global accuracy
      // userdata->errtol[i] = Rtol*(fabs(userdata->y[i]) + fabs(userdata->stepSize*fODE[i])) + Atol*1e-3;
      for (i=0; i<nStates; i++)
      {
        gsriData->errtol[i] = Rtol*fmax(fabs(gsriData->y[i]),fabs(gsriData->yt[i])) + Atol;
        gsriData->errest[i] = fabs(gsriData->y[i] - gsriData->yt[i]);
      }

      /*** calculate error (infinity norm!)***/
      err = 0;
      for (i=0; i<nStates; i++)
      {
         gsriData->err[i] = gsriData->errest[i]/gsriData->errtol[i];
         err = fmax(err, gsriData->err[i]);
      }
      err = gsriData->tableau->fac * err;

      // printVector_genericRK("Error before sorting:", gsriData->err, gsriData->nStates, gsriData->time);
      // printIntVector_genericRK("Indices before sorting:", gsriData->sortedStates, gsriData->nStates, gsriData->time);
      // printIntVector_genericRK("Indices after sorting:", gsriData->sortedStates, gsriData->nStates, gsriData->time);
      // printVector_genericRK_MR("Error after sorting:", gsriData->err, gsriData->nStates, gsriData->time,  gsriData->nStates, gsriData->sortedStates);

      if (gsriData->multi_rate && gsriData->percentage > 0)
      {
        sortErrorIndices(gsriData);
        //Find fast and slow states based on
        gsriData->nFastStates = 0;
        gsriData->nSlowStates = 0;
        gsriData->err_slow = 0;
        gsriData->err_fast = 0;
        for (i=0; i<gsriData->nStates; i++)
        {
          ii = gsriData->sortedStates[i];
          if (i < gsriData->nStates * gsriData->percentage || gsriData->err[ii]>=1)
          {
            gsriData->fastStates[gsriData->nFastStates] = ii;
            gsriData->nFastStates++;
            gsriData->err_fast = fmax(gsriData->err_fast, gsriData->err[ii]);
          }
          else
          {
            gsriData->slowStates[gsriData->nSlowStates] = ii;
            gsriData->nSlowStates++;
            gsriData->err_slow = fmax(gsriData->err_slow, gsriData->err[ii]);
          }
        }
        err = gsriData->err_slow;
      }

      gsriData->errValues[0]      =  err;
      gsriData->stepSizeValues[0] = gsriData->stepSize;

      // see Hairer book II, Seite 124 ....
      // step_values[0] =
      // step_values[1] =

      // Store performed stepSize for adjusting the time and interpolation purposes
      // gsriData->stepSize_old = gsriData->lastStepSize;
      gsriData->lastStepSize = gsriData->stepSize;
      gsriData->timeRight    = gsriData->time + gsriData->stepSize;

      // Call the step size control
      gsriData->stepSize *= gsriData->stepSize_control(gsriData->errValues, gsriData->stepSizeValues, gsriData->tableau->error_order);
      // printVector_genericRK("y     ", gsriData->y, gsriData->nStates, sData->timeValue);
      // printVector_genericRK("yt    ", gsriData->yt, gsriData->nStates, sData->timeValue);
      // printVector_genericRK("errest", gsriData->errest, gsriData->nStates, sData->timeValue);
      // printVector_genericRK("errtol", gsriData->errtol, gsriData->nStates, sData->timeValue);
      // printVector_genericRK("err   ", gsriData->err, gsriData->nStates, sData->timeValue);


      //printf("nSlowStates = %d, nFastStates = %d, Check = %d\n",
      //    gsriData->nSlowStates, gsriData->nFastStates,
      //    gsriData->nFastStates + gsriData->nSlowStates - gsriData->nStates);
      if (gsriData->multi_rate)
      {
        // printf("nSlowStates = %d, nFastStates = %d, Check = %d\n",
        //     gsriData->nSlowStates, gsriData->nFastStates,
        //     gsriData->nFastStates + gsriData->nSlowStates - gsriData->nStates);
        if (gsriData->nFastStates>0)
        {
          if (genericRK_MR_step(data, threadData, solverInfo, targetTime))
            return 0;
          // gsriData->lastStepSize = gsriData->gmriData->lastStepSize;
          // gsriData->stepSize = gsriData->gmriData->stepSize;
          //  copyVector_genericRK_MR(rkData->y, rkData->gmriData->y, rkData->nFastStates, rkData->fastStates);
          //  copyVector_genericRK_MR(rkData->yt, rkData->gmriData->yt, rkData->nFastStates, rkData->fastStates);
          //  copyVector_genericRK_MR(rkData->err, rkData->gmriData->err, rkData->nFastStates, rkData->fastStates);
          //  printVector_genericRK_MR_fs("y ", rkData->y, n, rkData->time, rkData->nFastStates, rkData->fastStates);
          //  printVector_genericRK_MR_fs("yt ", rkData->yt, n, rkData->time, rkData->nFastStates, rkData->fastStates);
          /*** calculate error (infinity norm!)***/
          // err = 0;
          // for (i=0; i<data->modelData->nStates; i++)
          // {
          //   err = fmax(err, gsriData->err[i]);
          // }
          //printVector_genericRK("Error: ", rkData->err, rkData->nStates, rkData->time);
          err = gsriData->err_fast;
        }
      }

      // printf("Stepsize: old: %g, last: %g, act: %g\n", rkData->stepSize_old, rkData->lastStepSize, rkData->stepSize);
      // printf("Error:    old: %g, new: %g\n", rkData->err_old, rkData->err_new);


      //rkData->stepSize *= fmin(facmax, fmax(facmin, rkData->tableau->fac*pow(1.0/err, 1./rkData->tableau->error_order)));
      /*
       * step size control from Luca, etc.:
       * stepSize = seccoeff*sqrt(norm_errtol/fmax(norm_errest,errmin));
       * printf("Error:  %g, New stepSize: %g from %g to  %g\n", err, rkData->stepSize, rkData->time, rkData->time+stepSize);
       */
      if (err>1)
      {
        gsriData->errorTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "reject step from %10g to %10g, error %10g, new stepsize %10g",
                        gsriData->time, gsriData->time + gsriData->lastStepSize, err, gsriData->stepSize);
      }
      else
      {
        // BB ToDo: maybe better to set userdata->stepSize to zero, if err<1 (last step!!!)
        gsriData->stepSize = fmin(gsriData->stepSize, stopTime - (gsriData->time + gsriData->lastStepSize));
      }

    } while  (err>1);
    gsriData->stepsDone += 1;

    // Rotate ring buffer
    for (i=0; i<(gsriData->ringBufferSize-1); i++) {
      gsriData->errValues[i+1] = gsriData->errValues[i];
      gsriData->stepSizeValues[i+1] = gsriData->stepSizeValues[i];
    }

    if (gsriData->type == MS_TYPE_IMPLICIT) {
      for (int stage_=0; stage_< (gsriData->tableau->nStages-1); stage_++) {
        memcpy(gsriData->k + stage_ * nStates, gsriData->k + (stage_+1) * nStates, nStates*sizeof(double));
        memcpy(gsriData->x + stage_ * nStates, gsriData->x + (stage_+1) * nStates, nStates*sizeof(double));
      }
      // for (int stage_=0; stage_< (gsriData->tableau->nStages); stage_++) {
      //   printVector_genericRK("gsriData->k + stage_ * nStates    ", gsriData->k + stage_ * nStates, nStates, gsriData->time);
      // }
      // for (int stage_=0; stage_< (gsriData->tableau->nStages); stage_++) {
      //   printVector_genericRK("gsriData->x + stage_ * nStates    ", gsriData->x + stage_ * nStates, nStates, gsriData->time);
      // }
    }


    if (!gsriData->multi_rate || !gsriData->percentage)
    {
      eventTime = checkForEvents(data, threadData, solverInfo, gsriData->time, gsriData->yOld, gsriData->time + gsriData->lastStepSize, gsriData->y);
      if (eventTime > 0)
      {
        // sData->realVars are the "numerical" values on the right hand side of the event
        memcpy(gsriData->yOld, sData->realVars, gsriData->nStates * sizeof(double));

//        gsriData->lastStepSize = eventTime-gsriData->time;
        gsriData->time = eventTime;

        solverInfo->currentTime = eventTime;
        sData->timeValue = eventTime;

        // printVector_genericRK("y:    ", gsriData->y, nStates, gsriData->time);
        if(ACTIVE_STREAM(LOG_SOLVER))
        {
          // printIntVector_genericRK("fast states:", gsriData->fastStates, gsriData->nFastStates, solverInfo->currentTime);
          // printVector_genericRK("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
          messageClose(LOG_SOLVER);
        }
        return 0;
      }
    }
    /* update time with performed stepSize */
    gsriData->time += gsriData->lastStepSize;

    // printVector_genericRK("yOld", gsriData->yOld, gsriData->nStates, gsriData->time - gsriData->lastStepSize);
    // printVector_genericRK("y   ", gsriData->y, gsriData->nStates, gsriData->time);
    /* step is accepted and yOld needs to be updated */
    memcpy(gsriData->yOld, gsriData->y, data->modelData->nStates*sizeof(double));
    infoStreamPrint(LOG_SOLVER, 0, "accept step from %10g to %10g, error %10g, new stepsize %10g",
                    gsriData->time- gsriData->lastStepSize, gsriData->time, err, gsriData->stepSize);
    gsriData->time = gsriData->time;

    /* emit step, if integratorSteps is selected */
    if (solverInfo->integratorSteps)
    {
      sData->timeValue = gsriData->time;
      solverInfo->currentTime = sData->timeValue;
      memcpy(sData->realVars, gsriData->y, data->modelData->nStates*sizeof(double));
      /*
       * to emit consistent value we need to update the whole
       * continuous system with algebraic variables.
       */
      data->callback->updateContinuousSystem(data, threadData);
      sim_result.emit(&sim_result, data, threadData);
    }
  }

  if (!solverInfo->integratorSteps)
  {
    /* Integrator does large steps and needs to interpolate results with respect to the output grid */
    sData->timeValue = sDataOld->timeValue + solverInfo->currentStepSize;
    solverInfo->currentTime = sData->timeValue;
    if (gsriData->multi_rate)
      // interpolating fast states if multirate method is used
      linear_interpolation_MR(gsriData->gmriData->time-gsriData->gmriData->lastStepSize, gsriData->gmriData->yt,
                              gsriData->gmriData->time, gsriData->gmriData->y,
                              sData->timeValue, sData->realVars,
                              gsriData->nFastStates, gsriData->fastStates);

    // interpolating slow states if multirate method is used, otherwise all states are slow states
    linear_interpolation_MR(gsriData->timeLeft, gsriData->yLeft,
                            gsriData->timeRight, gsriData->y,
                            sData->timeValue, sData->realVars,
                            gsriData->nSlowStates, gsriData->slowStates);
    if(ACTIVE_STREAM(LOG_SOLVER))
    {
      // printIntVector_genericRK("fast states:", gsriData->fastStates, gsriData->nFastStates, solverInfo->currentTime);
      // printVector_genericRK("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
      messageClose(LOG_SOLVER);
    }
  }else{
    // Integrator emits result on the simulation grid
    solverInfo->currentTime = gsriData->time;
  }

  /* if a state event occurs than no sample event does need to be activated  */
  if (data->simulationInfo->sampleActivated && solverInfo->currentTime < data->simulationInfo->nextSampleEvent)
  {
    data->simulationInfo->sampleActivated = 0;
  }

  /* Solver statistics */
  if(ACTIVE_STREAM(LOG_SOLVER_V))
  {
    infoStreamPrint(LOG_SOLVER_V, 1, "genericRK call statistics: ");
    infoStreamPrint(LOG_SOLVER_V, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_SOLVER_V, 0, "current integration time value: %0.4g", gsriData->time);
    infoStreamPrint(LOG_SOLVER_V, 0, "step size h to be attempted on next step: %0.4g", gsriData->stepSize);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of steps taken so far: %d", gsriData->stepsDone);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calls of functionODE() : %d", gsriData->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calculation of jacobian : %d", gsriData->evalJacobians);
    infoStreamPrint(LOG_SOLVER_V, 0, "error test failure : %d", gsriData->errorTestFailures);
    infoStreamPrint(LOG_SOLVER_V, 0, "convergence failure : %d", gsriData->convergenceFailures);
    messageClose(LOG_SOLVER_V);
  }

  /* write statistics to the solverInfo data structure */
  solverInfo->solverStatsTmp[0] = gsriData->stepsDone;
  solverInfo->solverStatsTmp[1] = gsriData->evalFunctionODE;
  solverInfo->solverStatsTmp[2] = gsriData->evalJacobians;
  solverInfo->solverStatsTmp[3] = gsriData->errorTestFailures;
  solverInfo->solverStatsTmp[4] = gsriData->convergenceFailures;

  infoStreamPrint(LOG_SOLVER_V, 0, "finished genericRK step.");
  messageClose(LOG_SOLVER);
  return 0;
}

void sortErrorIndices(DATA_GSRI* gsriData)
{
  int i, j, temp;

  for (i = 0;  i < gsriData->nStates - 1; i++)
  {
    for (j = 0; j < gsriData->nStates - i - 1; j++)
    {
      if (gsriData->err[gsriData->sortedStates[j]] < gsriData->err[gsriData->sortedStates[j+1]])
      {
        temp = gsriData->sortedStates[j];
        gsriData->sortedStates[j] = gsriData->sortedStates[j+1];
        gsriData->sortedStates[j+1] = temp;
      }
    }
  }
}

// TODO AHeu: For sure there is already a linear interpolation function somewhere
//auxiliary vector functions for better code structure
void linear_interpolation(double ta, double* fa, double tb, double* fb, double t, double* f, int n)
{
  double lambda, h0, h1;

  lambda = (t-ta)/(tb-ta);
  h0 = 1-lambda;
  h1 = lambda;

  for (int i=0; i<n; i++)
  {
    f[i] = h0*fa[i] + h1*fb[i];
  }
}

void printVector_genericRK(char name[], double* a, int n, double time)
{
  printf("%s at time: %16.12g:", name, time);
  for (int i=0;i<n;i++)
    printf("%16.12g ", a[i]);
  printf("\n");
}

void printIntVector_genericRK(char name[], int* a, int n, double time)
{
  printf("\n%s at time: %g: \n", name, time);
  for (int i=0;i<n;i++)
    printf("%d ", a[i]);
  printf("\n");
}

void printVector_genericRK_MR_fs(char name[], double* a, int n, double time, int nIndx, int* indx)
{
  printf("\n%s at time: %g: \n", name, time);
  for (int i=0;i<nIndx;i++)
    printf("%6g ", a[indx[i]]);
  printf("\n");
}

void copyVector_genericRK_MR(double* a, double* b, int nIndx, int* indx)
{
  for (int i=0;i<nIndx;i++)
    a[indx[i]] = b[indx[i]];
}


void printMatrix_genericRK(char name[], double* a, int n, double time)
{
  printf("\n%s at time: %g: \n ", name, time);
  for (int i=0;i<n;i++)
  {
    for (int j=0;j<n;j++)
      printf("%6g ", a[i*n + j]);
    printf("\n");
  }
  printf("\n");
}
