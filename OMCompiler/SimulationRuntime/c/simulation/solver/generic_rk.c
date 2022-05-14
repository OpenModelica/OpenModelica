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
void sortErrorIndices(DATA_GENERIC_RK* rk_data);

// singlerate step function
int expl_diag_impl_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
int full_implicit_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);

// Residuum and Jacobian functions for diagonal implicit (DIRK) and implicit (IRK) Runge-Kutta methods.
void residual_DIRK(void **dataIn, const double *xloc, double *res, const int *iflag);
int jacobian_DIRK_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian);

void residual_IRK(void **dataIn, const double *xloc, double *res, const int *iflag);
int jacobian_IRK_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian);

void initializeStaticNLSData(void* nlsDataVoid, threadData_t *threadData, void* rk_data_void);

void allocateDataGenericRK_MR(DATA* data, threadData_t* threadData, DATA_GENERIC_RK* rk_data);

// step size control function
double IController(double* err_values, double err_order);
double PIController(double* err_values, double err_order);

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
  DATA_GENERIC_RK* rk_data;
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
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*) data->simulationInfo->backupSolverData;

  /* Get Sparsity of ODE Jacobian */
  ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  SPARSE_PATTERN* sparsePattern_ODE = jacobian->sparsePattern;

  int sizeRows = jacobian->sizeRows;
  int sizeCols = jacobian->sizeCols;
  int nStages  = rk_data->tableau->nStages;
  int nStates  = rk_data->nStates;
  double* A    = rk_data->tableau->A;

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
 * @param rk_data                     Runge-Kutta method.
 * @return NONLINEAR_SYSTEM_DATA*     Pointer to initialized non-linear system data.
 */
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA(DATA* data, threadData_t* threadData, DATA_GENERIC_RK* rk_data) {
  assertStreamPrint(threadData, rk_data->type != RK_TYPE_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  // TODO AHeu: Free solverData again
  struct dataSolver *solverData = (struct dataSolver*) calloc(1,sizeof(struct dataSolver));

  ANALYTIC_JACOBIAN* jacobian = NULL;

  NONLINEAR_SYSTEM_DATA* nlsData = (NONLINEAR_SYSTEM_DATA*) calloc(1, sizeof(NONLINEAR_SYSTEM_DATA));
  assertStreamPrint(threadData, nlsData != NULL,"Out of memory");

  analyticalJacobianColumn_func_ptr analyticalJacobianColumn;

  nlsData->size = rk_data->nlSystemSize;
  nlsData->equationIndex = -1;

  nlsData->homotopySupport = FALSE;
  nlsData->initHomotopy = FALSE;
  nlsData->mixedSystem = FALSE;

  nlsData->min = NULL;
  nlsData->max = NULL;
  nlsData->nominal = NULL;

  switch (rk_data->type)
  {
  case RK_TYPE_DIRK:
    nlsData->residualFunc = residual_DIRK;
    nlsData->analyticalJacobianColumn = jacobian_DIRK_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_DIRK;
    nlsData->getIterationVars = NULL;

    rk_data->symJacAvailable = TRUE;
    break;
  case RK_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_IRK;
    nlsData->analyticalJacobianColumn = jacobian_IRK_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_IRK;
    nlsData->getIterationVars = NULL;

    rk_data->symJacAvailable = TRUE;
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Residual function for NLS type %i not yet implemented.", rk_data->type);
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
  rk_data->jacobian = initAnalyticJacobian(rk_data->nlSystemSize, rk_data->nlSystemSize, rk_data->nlSystemSize, NULL, nlsData->sparsePattern);
  nlsData->initialAnalyticalJacobian = NULL;
  nlsData->jacobianIndex = -1;

  /* Initialize NLS method */
  switch (rk_data->nlsSolverMethod) {
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
    if (rk_data->symJacAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsData->nlsLinearSolver);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    if (rk_data->symJacAvailable) {
      resetKinsolMemory(solverData->ordinaryData, nlsData->sparsePattern->numberOfNonZeros, nlsData->analyticalJacobianColumn);
    } else {
      resetKinsolMemory(solverData->ordinaryData, nlsData->size*nlsData->size, NULL);
      int flag = KINSetJacFn(((NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory, NULL);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
    }
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Memory allocation for NLS method %s not yet implemented.", RK_NLS_METHOD_NAME[rk_data->nlsSolverMethod]);
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
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*) malloc(sizeof(DATA_GENERIC_RK));

  // Set backup in simulationInfo
  data->simulationInfo->backupSolverData = (void*) rk_data;

  solverInfo->solverData = (void*) rk_data;

  rk_data->nStates = data->modelData->nStates;

  ANALYTIC_JACOBIAN* jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;

  rk_data->RK_method = getRK_Method(FLAG_RK);
  rk_data->tableau = initButcherTableau(rk_data->RK_method);
  if (rk_data->tableau == NULL){
    errorStreamPrint(LOG_STDOUT, 0, "allocateDataGenericRK: Failed to initialize butcher tableau for Runge-Kutta method %s", RK_SINGLERATE_METHOD_NAME[rk_data->RK_method]);
    return -1;
  }

  // Get size of non-linear system
  analyseButcherTableau(rk_data->tableau, rk_data->nStates, &rk_data->nlSystemSize, &rk_data->type);

  switch (rk_data->type)
  {
  case RK_TYPE_EXPLICIT:
    rk_data->isExplicit = TRUE;
    rk_data->step_fun = &(expl_diag_impl_RK);
    break;
  case RK_TYPE_DIRK:
    rk_data->isExplicit = FALSE;
    rk_data->step_fun = &(expl_diag_impl_RK);
    break;
  case RK_TYPE_IMPLICIT:
    rk_data->isExplicit = FALSE;
    rk_data->step_fun = &(full_implicit_RK);
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "allocateDataGenericRK: Unknown Runge-Kutta type %i", rk_data->type);
    return -1;
  }
  // adapt decision for testing of the fully implicit implementation
  if (rk_data->RK_method == RK_ESDIRK2_test || rk_data->RK_method == RK_ESDIRK3_test) {
    rk_data->nlSystemSize = rk_data->tableau->nStages*rk_data->nStates;
    rk_data->step_fun = &(full_implicit_RK);
    rk_data->type = RK_TYPE_IMPLICIT;
  }

  const char* flag_StepSize_ctrl = omc_flagValue[FLAG_RK_STEPSIZE_CTRL];

  if (flag_StepSize_ctrl != NULL) {
    rk_data->stepSize_control = &(PIController);
    infoStreamPrint(LOG_SOLVER, 0, "Stepsize control using PIController");
  } else
  {
    rk_data->stepSize_control = &(IController);
    infoStreamPrint(LOG_SOLVER, 0, "Stepsize control using IController");
  }

  /* Allocate internal memory */
  rk_data->isFirstStep = TRUE;
  rk_data->y = malloc(sizeof(double)*rk_data->nStates);
  rk_data->yOld = malloc(sizeof(double)*rk_data->nStates);
  rk_data->yLeft = malloc(sizeof(double)*rk_data->nStates);
  rk_data->yt = malloc(sizeof(double)*rk_data->nStates);
  rk_data->f = malloc(sizeof(double)*rk_data->nStates);
  rk_data->k = malloc(sizeof(double)*rk_data->nStates*rk_data->tableau->nStages);
  for (int i=0; i<rk_data->nStates*rk_data->tableau->nStages; i++)
    rk_data->k[i] = 0;
  rk_data->res_const = malloc(sizeof(double)*rk_data->nStates);
  rk_data->errest = malloc(sizeof(double)*rk_data->nStates);
  rk_data->errtol = malloc(sizeof(double)*rk_data->nStates);
  rk_data->err = malloc(sizeof(double)*rk_data->nStates);
  if (!rk_data->isExplicit) {
    rk_data->Jf = malloc(sizeof(double)*rk_data->nStates*rk_data->nStates);
    for (int i=0; i<rk_data->nStates*rk_data->nStates; i++)
      rk_data->Jf[i] = 0;
  } else {
    rk_data->Jf = NULL;
  }

  printButcherTableau(rk_data->tableau);

  /* initialize statistic counter */
  // TODO AHeu: Use calloc instead?
  rk_data->stepsDone = 0;
  rk_data->evalFunctionODE = 0;
  rk_data->evalJacobians = 0;
  rk_data->errorTestFailures = 0;
  rk_data->convergenceFailures = 0;

  rk_data->err_new = -1;

  /* initialize analytic Jacobian, if available and needed */
  if (!rk_data->isExplicit) {
    jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    // TODO: Do we need to initialize the Jacobian or is it already initialized?
    if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian)) {
      rk_data->symJacAvailable = FALSE;
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to numeric Jacobians.");
    } else {
      rk_data->symJacAvailable = TRUE;
      // TODO AHeu: Is there a reason we get the jacobian again? Did data->callback->initialAnalyticJacobianA change the pointer?
      // ANALYTIC_JACOBIAN* jac = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
      infoStreamPrint(LOG_SOLVER, 1, "Initialized colored Jacobian:");
      infoStreamPrint(LOG_SOLVER, 0, "columns: %d rows: %d", jacobian->sizeCols, jacobian->sizeRows);
      infoStreamPrint(LOG_SOLVER, 0, "NNZ:  %d colors: %d", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
      messageClose(LOG_SOLVER);
    }

  /* Allocate memory for the nonlinear solver */
    rk_data->nlsSolverMethod = getRK_NLS_Method();
    rk_data->nlsData = initRK_NLS_DATA(data, threadData, rk_data);
    if (!rk_data->nlsData) {
      return -1;
    }
  }
  else
  {
    rk_data->symJacAvailable = FALSE;
    rk_data->nlsSolverMethod = RK_NLS_UNKNOWN;  // TODO AHeu: Add a no-solver option?
    rk_data->nlsData = NULL;
    rk_data->jacobian = NULL;
  }

  if (solverInfo->solverMethod == S_GENERIC_RK_MR)
  {
    rk_data->multi_rate = 1;
    const char* flag_value = omc_flagValue[FLAG_RK_MR_PAR];
    if (flag_value != NULL) {
      rk_data->percentage = atof(omc_flagValue[FLAG_RK_MR_PAR]);
    } else
    {
      rk_data->percentage = 0.3;
    }
  } else
  {
    rk_data->multi_rate = 0;
    rk_data->percentage = 1;
  }

  rk_data->fastStates = malloc(sizeof(int)*rk_data->nStates);
  rk_data->slowStates = malloc(sizeof(int)*rk_data->nStates);
  rk_data->sortedStates = malloc(sizeof(int)*rk_data->nStates);

  rk_data->nFastStates = 0;
  rk_data->nSlowStates = rk_data->nStates;
  for (int i=0; i<rk_data->nStates; i++)
  {
    rk_data->slowStates[i] = i;
    rk_data->sortedStates[i] = i;
  }

  if (solverInfo->solverMethod == S_GENERIC_RK_MR) {
    allocateDataGenericRK_MR(data, threadData, rk_data);
  } else {
    rk_data->dataRKmr = NULL;
  }

  return 0;
}

/**
 * @brief Free generic RK data.
 *
 * @param rk_data    Pointer to generik Runge-Kutta data struct.
 */
void freeDataGenericRK(DATA_GENERIC_RK* rk_data) {
  /* Free non-linear system data */
  if(rk_data->nlsData != NULL) {
    struct dataSolver* dataSolver = rk_data->nlsData->solverData;
    switch (rk_data->nlsSolverMethod)
    {
    case RK_NLS_NEWTON:
      freeNewtonData(dataSolver->ordinaryData);
      break;
    case RK_NLS_KINSOL:
      //kinsolData = (NLS_KINSOL_DATA*) rk_data->nlsData->solverData;
      nlsKinsolFree(dataSolver->ordinaryData);
      break;
    default:
      warningStreamPrint(LOG_SOLVER, 0, "Not handled RK_NLS_METHOD in freeDataGenericRK. Are we leaking memroy?");
      break;
    }
    free(dataSolver);
    free(rk_data->nlsData);
  }
  /* Free Jacobian */
  freeAnalyticJacobian(rk_data->jacobian);

  /* Free Butcher tableau */
  freeButcherTableau(rk_data->tableau);

  if (rk_data->multi_rate == 1) {
    freeDataGenericRK_MR(rk_data->dataRKmr);
  }
  /* Free multi-rate data */
  free(rk_data->err);
  free(rk_data->fastStates);
  free(rk_data->slowStates);

  /* Free remaining arrays */
  free(rk_data->y);
  free(rk_data->yOld);
  free(rk_data->yLeft);
  free(rk_data->yt);
  free(rk_data->f);
  free(rk_data->Jf);
  free(rk_data->k);
  free(rk_data->res_const);
  free(rk_data->errest);
  free(rk_data->errtol);

  free(rk_data);
  rk_data = NULL;

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

// /**
//  * @brief Calculate numeric Jacobian of functionODE with respect to the states.
//  *
//  * @param data          Runtime data struct.
//  * @param threadData    Thread data for error handling.
//  * @param rk_data       Runge-Kutta method.
//  * @return int          Return 0 on success.
//  */
// int wrapper_Jf_numeric_genericRK(DATA* data, threadData_t *threadData, DATA_GENERIC_RK* rk_data)
// {
//   int i,j,l;
//   int nStates = data->modelData->nStates;
//   double timeValue;

//   SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
//   modelica_real *states = sData->realVars;
//   modelica_real *stateDerivatives = &sData->realVars[nStates];

//   timeValue = sData->timeValue;

//   // Only implemented for non-linear solver Newton
//   assertStreamPrint(threadData, rk_data->nlsSolverMethod == RK_NLS_NEWTON, "wrapper_Jf_numeric_genericRK only implemented for Newton solver");
//   DATA_NEWTON* solverData = (DATA_NEWTON*)rk_data->nlsData;

//   double delta_h = sqrt(solverData->epsfcn);
//   double delta_hh;
//   double xsave;

//   /* profiling */
//   rt_tick(SIM_TIMER_JACOBIAN);

//   /* statisitcs */
//   rk_data->evalJacobians++;

//   /* Evaluate symbolic Jacobian */
//   // TODO: Use a generic numeric Jacobian evaluation
//   memcpy(rk_data->f, stateDerivatives, nStates * sizeof(double));
//   for(i = 0; i < nStates; i++)
//   {
//     delta_hh = fmax(delta_h * fmax(fabs(states[i]), fabs(rk_data->f[i])), delta_h);
//     delta_hh = ((rk_data->f[i] >= 0) ? delta_hh : -delta_hh);
//     delta_hh = states[i] + delta_hh - states[i];
//     xsave = states[i];
//     states[i] += delta_hh;
//     delta_hh = 1. / delta_hh;

//     wrapper_f_genericRK(data, threadData, &(rk_data->evalFunctionODE), stateDerivatives);
//     // this should not count on function evaluation, since
//     // it belongs to jacobian evaluation
//     rk_data->evalFunctionODE--;

//     /* BB: Is this necessary for the statistics? */
//     solverData->nfev++;

//     for(j = 0; j < nStates; j++)
//     {
//       l = i * nStates + j;
//       rk_data->Jf[l] = (stateDerivatives[j] - rk_data->f[j]) * delta_hh;
//     }
//     states[i] = xsave;
//   }

//   /* profiling */
//   rt_accumulate(SIM_TIMER_JACOBIAN);

//   return 0;
// }

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
  DATA_GENERIC_RK *rk_data = (DATA_GENERIC_RK *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int nStates = data->modelData->nStates;
  int diagIdx = rk_data->act_stage * rk_data->tableau->nStages + rk_data->act_stage;

  // Evaluate right hand side of ODE
  sData->timeValue = rk_data->time + rk_data->tableau->c[rk_data->act_stage] * rk_data->stepSize;
  memcpy(sData->realVars, xloc, nStates*sizeof(double));
  wrapper_f_genericRK(data, threadData, &(rk_data->evalFunctionODE), fODE);

  // Evaluate residual
  for (int i=0; i<nStates; i++) {
    res[i] = rk_data->res_const[i] - xloc[i] + rk_data->stepSize * rk_data->tableau->A[diagIdx] * fODE[i];
  }
  // printVector_genericRK("sData->realVars", sData->realVars, rk_data->nStates, sData->timeValue);
  // printVector_genericRK("fODE           ", fODE, rk_data->nStates, sData->timeValue);
  // printVector_genericRK("res_const      ", rk_data->res_const, rk_data->nStates, sData->timeValue);
  // printVector_genericRK("res            ", res, rk_data->nStates, sData->timeValue);

  return;
}

/**
 * @brief Evaluate column of DIRK Jacobian.
 *
 * @param inData            Void pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param genericRKData     Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_DIRK_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA* data = (DATA*) inData;
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*) data->simulationInfo->backupSolverData;

  int i,j,l;
  int nStates = data->modelData->nStates;
  int diagIdx = rk_data->act_stage * rk_data->tableau->nStages + rk_data->act_stage;

  /* Evaluate column of Jacobian ODE */
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  memcpy(jacobian_ODE->seedVars, jacobian->seedVars, sizeof(modelica_real)*jacobian->sizeCols);
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  for (i = 0; i < jacobian->sizeCols; i++) {
    jacobian->resultVars[i] = rk_data->stepSize * rk_data->tableau->A[diagIdx] * jacobian_ODE->resultVars[i];
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
  DATA_GENERIC_RK *rk_data = (DATA_GENERIC_RK *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;

  int i;
  int k,l;
  int nStages = rk_data->tableau->nStages;
  int nStates = data->modelData->nStates;

  for (k=0; k<nStages; k++)
  {
    /* Evaluate ODE and compute res for each stage */
    sData->timeValue = rk_data->time + rk_data->tableau->c[k] * rk_data->stepSize;
    memcpy(sData->realVars, &xloc[k*nStates], nStates*sizeof(double));
    wrapper_f_genericRK(data, threadData, &(rk_data->evalFunctionODE), fODE);
    memcpy(&rk_data->k[k*nStates], fODE, nStates*sizeof(double));
  }

  // Calculate residuum for the full implicit RK method based on stages and A matrix
  for (l=0; l<nStages; l++)
  {
    for (i=0; i<nStates; i++)
    {
      res[l * nStates + i] = rk_data->yOld[i] - xloc[l * nStates + i];
      for (k=0; k<nStages; k++)
      {
        res[l * nStates + i] += rk_data->stepSize * rk_data->tableau->A[l * nStages + k] * (rk_data->k + k*nStates)[i];
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
 * @param genericRKData     Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_IRK_column(void *inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA* data = (DATA*) inData;
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*) data->simulationInfo->backupSolverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  const double* xloc = rk_data->nlsData->nlsx;

  int i,j,k,l,idx;
  int nStages = rk_data->tableau->nStages;
  int nStates = data->modelData->nStates;
  int diagIdx = rk_data->act_stage * rk_data->tableau->nStages + rk_data->act_stage;

  /* Evaluate column of Jacobian ODE */
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  // and find out which stage is active; different stages have different colors
  // reset jacobian_ODE->seedVars
  for (i=0; i<jacobian_ODE->sizeCols; i++)
    jacobian_ODE->seedVars[i] = 0;
  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  for (i=0, k=0; i<jacobian->sizeCols; i++)
  {
    if (jacobian->seedVars[i])
    {
      k = i;
      jacobian_ODE->seedVars[i%jacobian_ODE->sizeCols] = 1;
    }
  }
  // Determine active stage
  k = k/jacobian_ODE->sizeCols;

  // update timeValue and unknown vector
  sData->timeValue = rk_data->time + rk_data->tableau->c[k] * rk_data->stepSize;
  // BB ToDo: ist xloc das gleiche wie rk_data->nlsData->nlsx
  memcpy(sData->realVars, &(xloc[k*nStates]), nStates*sizeof(double));
  // call jacobian_ODE with the mapped seedVars
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array for corresponding jacobian->seedVars*/
  for (l=0; l<nStages; l++)
  {
    for (i=0; i<nStates; i++)
    {
      jacobian->resultVars[l * nStates + i] = rk_data->stepSize * rk_data->tableau->A[l * nStages + k]  * jacobian_ODE->resultVars[i];
      /* -1 on diagonal elements */
      if (jacobian->seedVars[l * nStates + i] == 1) {
        jacobian->resultVars[l * nStates + i] -= 1;
      }
    }
  }

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
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*)solverInfo->solverData;

  int stateIdx, k, l;
  int stage;
  int nStates = data->modelData->nStates;
  int nStages = rk_data->tableau->nStages;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;
  modelica_boolean solved = FALSE;

  sData->timeValue = rk_data->time;
  solverInfo->currentTime = sData->timeValue;

  /* Runge-Kutta step */
  for (stage = 0; stage < nStages; stage++)
  {
    /* Set constant parts or residual input
     * res = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..stage-1)) */
    k = stage * nStages;    // Index of A[stage,0]
    for (stateIdx = 0; stateIdx < nStates; stateIdx++)
    {
      // BB ToDo: check the formula with respect to rk_data->k[]
      rk_data->res_const[stateIdx] = rk_data->yOld[stateIdx];
      for (l = 0; l < stage; l++)
      {
        rk_data->res_const[stateIdx] += rk_data->stepSize * rk_data->tableau->A[k + l] * rk_data->k[l * nStates + stateIdx];
      }
    }

    /* Compute intermediate step k
     * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
    k = stage * nStages + stage;    // Index of A[stage,stage]
    if (rk_data->tableau->A[k] == 0)
    {
      // fODE = f(tOld + c2*h,x); x ~ yOld + gam*h*(k1+k2)
      // set correct time value and states of simulation system
      sData->timeValue = rk_data->time + rk_data->tableau->c[stage]*rk_data->stepSize;
      memcpy(sData->realVars, rk_data->res_const, nStates*sizeof(double));
      rk_data->act_stage = stage;
      wrapper_f_genericRK(data, threadData, &(rk_data->evalFunctionODE), fODE);
    }
    else
    {
      rk_data->act_stage = stage;
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = rk_data->nlsData;
      // Set start vector, BB ToDo: Ommit extrapolation after event!!!
      for (int i=0; i<rk_data->nStates; i++)
        nlsData->nlsx[i] = rk_data->yOld[i] + rk_data->tableau->c[stage] * rk_data->stepSize * (rk_data->k + (nStages-1)*nStates)[i];
      //memcpy(nlsData->nlsx, rk_data->yOld, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
      solved = solveNLS(data, threadData, nlsData, -1);
      if (!solved) {
        errorStreamPrint(LOG_STDOUT, 0, "expl_diag_impl_RK: Failed to solve NLS in expl_diag_impl_RK in stage %d", stage);
        return -1;
      }
    }
    // copy last calculation of fODE, which should coincide with k[i]
    memcpy(rk_data->k + stage * nStates, fODE, nStates*sizeof(double));
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
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*)solverInfo->solverData;

  NONLINEAR_SYSTEM_DATA* nlsData = rk_data->nlsData;

  int i, j, k, l;
  int stage;
  int nStates = data->modelData->nStates;
  int nStages = rk_data->tableau->nStages;

  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;
  modelica_boolean solved = FALSE;


  /* Set start values for non-linear solver */
  for (stage=0; stage<rk_data->tableau->nStages; stage++) {
    // BB ToDo: Ommit extrapolation after event!!!
    for (int i=0; i<rk_data->nStates; i++)
      nlsData->nlsx[stage*nStates +i] = rk_data->yOld[i] + rk_data->tableau->c[stage] * rk_data->stepSize * (rk_data->k + (nStages-1)*nStates)[i];

    // memcpy(&nlsData->nlsx[stage*nStates], rk_data->yOld, nStates*sizeof(double));
    memcpy(&nlsData->nlsxOld[stage*nStates], &nlsData->nlsx[stage*nStates], nStates*sizeof(double));
    memcpy(&nlsData->nlsxExtrapolation[stage*nStates], &nlsData->nlsx[stage*nStates], nStates*sizeof(double));
  }

  solved = solveNLS(data, threadData, rk_data->nlsData, -1);
  if (!solved) {
    errorStreamPrint(LOG_STDOUT, 0, "full_implicit_RK: Failed to solve NLS in full_implicit_RK");
    return -1;
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
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*)solverInfo->solverData;
  const int nStates = data->modelData->nStates;
  modelica_real* fODE = &sData->realVars[nStates];

  double sc, d, d0 = 0.0, d1 = 0.0, d2 = 0.0, h0, h1, delta_ti, infNorm, sum = 0;
  // TODO AHeu: We have flags for absolute and relative solver tolerances
  // Use data->simulationInfo->tolerance?
  double Atol = 1e-6;
  double Rtol = 1e-3;

  int i,j;

  /* store Startime of the simulation */
  rk_data->time = sDataOld->timeValue;
  if (rk_data->multi_rate)
      rk_data->dataRKmr->time = rk_data->time;
    rk_data->timeLeft = rk_data->time;
    rk_data->timeRight = rk_data->time;
  /* set correct flags in order to calculate initial step size */
  rk_data->isFirstStep = FALSE;
  solverInfo->didEventStep = 0;

 /* reset statistics because it is accumulated in solver_main.c */
  rk_data->stepsDone = 0;
  rk_data->evalFunctionODE = 0;
  rk_data->evalJacobians = 0;
  rk_data->errorTestFailures = 0;
  rk_data->convergenceFailures = 0;

  /* calculate starting step size 1st Version */
  /* BB: What is the difference between sData and sDataOld at this time instance?
         Is this important for the restart after an event?
         And should this also been copied to userdata->old (see above?)
  */
  /* initialize start values of the integrator and calculate ODE function*/
  //printVector_genericRK("sData->realVars: ", sData->realVars, data->modelData->nStates, sData->timeValue);
  //printVector_genericRK("sDataOld->realVars: ", sDataOld->realVars, data->modelData->nStates, sDataOld->timeValue);
  memcpy(rk_data->yOld, sData->realVars, data->modelData->nStates*sizeof(double));
  wrapper_f_genericRK(data, threadData, &(rk_data->evalFunctionODE), fODE);
  /* store values of the state derivatives at initial or event time */
  memcpy(rk_data->f, fODE, data->modelData->nStates*sizeof(double));

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
    sData->realVars[i] = rk_data->yOld[i] + fODE[i] * h0;
  }
  sData->timeValue += h0;

  wrapper_f_genericRK(data, threadData, &(rk_data->evalFunctionODE), fODE);

  for (i=0; i<data->modelData->nStates; i++)
  {
    sc = Atol + fabs(rk_data->yOld[i])*Rtol;
    d2 += ((fODE[i]-rk_data->f[i])*(fODE[i]-rk_data->f[i])/(sc*sc));
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

  rk_data->stepSize = 0.5*fmin(100*h0,h1);
  rk_data->lastStepSize = rk_data->stepSize;

  infoStreamPrint(LOG_SOLVER, 0, "initial step size = %e at time %g", rk_data->stepSize, rk_data->time);
}


/**
 * @brief simple step size control (see Hairer, etc.)
 *
 * @param genericRKData
 * @return double
 */
double IController(double* err_values, double err_order)
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
 * @param genericRKData
 * @return double
 */
double PIController(double* err_values, double err_order)
{
  double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.5;
  double beta1=-5./8./err_order, beta2=-3./8./err_order;

  return fmin(facmax, fmax(facmin, fac*pow(err_values[0], beta1)*pow(err_values[1], beta2)));

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
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*)solverInfo->solverData;

  double err, err_values[2];
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
  if (solverInfo->didEventStep == 1 || rk_data->isFirstStep)
  {
    genericRK_first_step(data, threadData, solverInfo);

    // side effect:
    //    sData->realVars, userdata->yOld, and userdata->f are consistent
    //    userdata->time and userdata->stepSize are defined
  }

  // Check if multirate step is necessary, otherwise the correct values are already stored in sData
  if (rk_data->multi_rate)
    if (rk_data->nFastStates > 0 && rk_data->dataRKmr->time < rk_data->time)
      if (genericRK_MR_step(data, threadData, solverInfo, targetTime))
              return 0;


  /* Main integration loop */
  while (rk_data->time < targetTime)
  {
    do
    {
      // printVector_genericRK("yOld: ", rk_data->yOld, nStates, rk_data->time);
      // printVector_genericRK("y:    ", rk_data->y, nStates, rk_data->time);
      /* store yOld in yLeft for interpolation purposes, if necessary
      * BB: Check condition
      */
      memcpy(rk_data->yLeft, rk_data->yOld, data->modelData->nStates*sizeof(double));
      rk_data->timeLeft = rk_data->time;

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
      rk_step_info = rk_data->step_fun(data, threadData, solverInfo);
      if (rk_step_info != 0) {
        errorStreamPrint(LOG_STDOUT, 0, "genericRK_step: Failed to calculate step at time = %5g.", rk_data->time);
        errorStreamPrint(LOG_STDOUT, 0, "Try half of the step size!");
        rk_data->stepSize = rk_data->stepSize/2.;
        continue;
        //return -1;
      }

      // Apply RK-scheme for determining the approximation at (time + stepsize)
      // y       = yold+h*sum(b[i]*k[i], i=1..stages);
      // yt      = yold+h*sum(bt[i]*k[i], i=1..stages);
      // Furthermore, calculate corresponding values for error estimator and step size control
      for (i=0; i<nStates; i++)
      {
        rk_data->y[i]  = rk_data->yOld[i];
        rk_data->yt[i] = rk_data->yOld[i];
        for (l=0; l<rk_data->tableau->nStages; l++)
        {
          rk_data->y[i]  += rk_data->stepSize * rk_data->tableau->b[l]  * (rk_data->k + l * nStates)[i];
          rk_data->yt[i] += rk_data->stepSize * rk_data->tableau->bt[l] * (rk_data->k + l * nStates)[i];
        }
        // BB ToDo: Investigate error estimator with respect for global accuracy
        // userdata->errtol[i] = Rtol*(fabs(userdata->y[i]) + fabs(userdata->stepSize*fODE[i])) + Atol*1e-3;
        rk_data->errtol[i] = Rtol*fmax(fabs(rk_data->y[i]),fabs(rk_data->yt[i])) + Atol;
        rk_data->errest[i] = fabs(rk_data->y[i] - rk_data->yt[i]);
      }

      /*** calculate error (infinity norm!)***/
      err = 0;
      for (i=0; i<data->modelData->nStates; i++)
      {
         rk_data->err[i] = rk_data->errest[i]/rk_data->errtol[i];
         err = fmax(err, rk_data->err[i]);
      }

      // printVector_genericRK("Error before sorting:", rk_data->err, rk_data->nStates, rk_data->time);
      // printIntVector_genericRK("Indices before sorting:", rk_data->sortedStates, rk_data->nStates, rk_data->time);
      // printIntVector_genericRK("Indices after sorting:", rk_data->sortedStates, rk_data->nStates, rk_data->time);
      // printVector_genericRK_MR("Error after sorting:", rk_data->err, rk_data->nStates, rk_data->time,  rk_data->nStates, rk_data->sortedStates);

      if (rk_data->multi_rate && rk_data->percentage > 0)
      {
        sortErrorIndices(rk_data);
        //Find fast and slow states based on
        rk_data->nFastStates = 0;
        rk_data->nSlowStates = 0;
        rk_data->err_slow = 0;
        rk_data->err_fast = 0;
        for (i=0; i<rk_data->nStates; i++)
        {
          ii = rk_data->sortedStates[i];
          if (i < rk_data->nStates * rk_data->percentage || rk_data->err[ii]>=1)
          {
            rk_data->fastStates[rk_data->nFastStates] = ii;
            rk_data->nFastStates++;
            rk_data->err_fast = fmax(rk_data->err_fast, rk_data->err[ii]);
          }
          else
          {
            rk_data->slowStates[rk_data->nSlowStates] = ii;
            rk_data->nSlowStates++;
            rk_data->err_slow = fmax(rk_data->err_slow, rk_data->err[ii]);
          }
        }
        err = rk_data->err_slow;
      }

      // Monitor error propagation for better step size control (PIController)
      if (rk_data->err_new == -1) rk_data->err_new = err;
      rk_data->err_old = rk_data->err_new;
      rk_data->err_new = err;

      err_values[0] = rk_data->err_new;
      err_values[1] = rk_data->err_old;

      // Store performed stepSize for adjusting the time and interpolation purposes
      // rk_data->stepSize_old = rk_data->lastStepSize;
      rk_data->lastStepSize = rk_data->stepSize;
      rk_data->timeRight    = rk_data->time + rk_data->stepSize;

      // Call the step size control
      rk_data->stepSize *= rk_data->stepSize_control(err_values, rk_data->tableau->error_order);
      // printVector_genericRK("y     ", rk_data->y, rk_data->nStates, sData->timeValue);
      // printVector_genericRK("yt    ", rk_data->yt, rk_data->nStates, sData->timeValue);
      // printVector_genericRK("errest", rk_data->errest, rk_data->nStates, sData->timeValue);
      // printVector_genericRK("errtol", rk_data->errtol, rk_data->nStates, sData->timeValue);
      // printVector_genericRK("err   ", rk_data->err, rk_data->nStates, sData->timeValue);


      //printf("nSlowStates = %d, nFastStates = %d, Check = %d\n",
      //    rk_data->nSlowStates, rk_data->nFastStates,
      //    rk_data->nFastStates + rk_data->nSlowStates - rk_data->nStates);
      if (rk_data->multi_rate)
      {
        // printf("nSlowStates = %d, nFastStates = %d, Check = %d\n",
        //     rk_data->nSlowStates, rk_data->nFastStates,
        //     rk_data->nFastStates + rk_data->nSlowStates - rk_data->nStates);
        if (rk_data->nFastStates>0)
        {
          if (genericRK_MR_step(data, threadData, solverInfo, targetTime))
            return 0;
          // rk_data->lastStepSize = rk_data->dataRKmr->lastStepSize;
          // rk_data->stepSize = rk_data->dataRKmr->stepSize;
          //  copyVector_genericRK_MR(rkData->y, rkData->dataRKmr->y, rkData->nFastStates, rkData->fastStates);
          //  copyVector_genericRK_MR(rkData->yt, rkData->dataRKmr->yt, rkData->nFastStates, rkData->fastStates);
          //  copyVector_genericRK_MR(rkData->err, rkData->dataRKmr->err, rkData->nFastStates, rkData->fastStates);
          //  printVector_genericRK_MR_fs("y ", rkData->y, n, rkData->time, rkData->nFastStates, rkData->fastStates);
          //  printVector_genericRK_MR_fs("yt ", rkData->yt, n, rkData->time, rkData->nFastStates, rkData->fastStates);
          /*** calculate error (infinity norm!)***/
          // err = 0;
          // for (i=0; i<data->modelData->nStates; i++)
          // {
          //   err = fmax(err, rk_data->err[i]);
          // }
          //printVector_genericRK("Error: ", rkData->err, rkData->nStates, rkData->time);
          err = rk_data->err_fast;
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
        rk_data->errorTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "reject step from %10g to %10g, error %10g, new stepsize %10g",
                        rk_data->time, rk_data->time + rk_data->lastStepSize, err, rk_data->stepSize);
      }
      else
      {
        // BB ToDo: maybe better to set userdata->stepSize to zero, if err<1 (last step!!!)
        rk_data->stepSize = fmin(rk_data->stepSize, stopTime - (rk_data->time + rk_data->lastStepSize));
      }

    } while  (err>1);
    rk_data->stepsDone += 1;

    if (!rk_data->multi_rate || !rk_data->percentage)
    {
      eventTime = checkForEvents(data, threadData, solverInfo, rk_data->time, rk_data->yOld, rk_data->time + rk_data->lastStepSize, rk_data->y);
      if (eventTime > 0)
      {
        // sData->realVars are the "numerical" values on the right hand side of the event
        memcpy(rk_data->yOld, sData->realVars, rk_data->nStates * sizeof(double));

//        rk_data->lastStepSize = eventTime-rk_data->time;
        rk_data->time = eventTime;

        solverInfo->currentTime = eventTime;
        sData->timeValue = eventTime;

        // printVector_genericRK("y:    ", rk_data->y, nStates, rk_data->time);
        if(ACTIVE_STREAM(LOG_SOLVER))
        {
          // printIntVector_genericRK("fast states:", rk_data->fastStates, rk_data->nFastStates, solverInfo->currentTime);
          // printVector_genericRK("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
          messageClose(LOG_SOLVER);
        }
        return 0;
      }
    }
    /* update time with performed stepSize */
    rk_data->time += rk_data->lastStepSize;

    // printVector_genericRK("yOld", rk_data->yOld, rk_data->nStates, rk_data->time - rk_data->lastStepSize);
    // printVector_genericRK("y   ", rk_data->y, rk_data->nStates, rk_data->time);
    /* step is accepted and yOld needs to be updated */
    memcpy(rk_data->yOld, rk_data->y, data->modelData->nStates*sizeof(double));
    infoStreamPrint(LOG_SOLVER, 0, "accept step from %10g to %10g, error %10g, new stepsize %10g",
                    rk_data->time- rk_data->lastStepSize, rk_data->time, err, rk_data->stepSize);
    rk_data->time = rk_data->time;

    /* emit step, if integratorSteps is selected */
    if (solverInfo->integratorSteps)
    {
      sData->timeValue = rk_data->time;
      solverInfo->currentTime = sData->timeValue;
      memcpy(sData->realVars, rk_data->y, data->modelData->nStates*sizeof(double));
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
    if (rk_data->multi_rate)
      // interpolating fast states if multirate method is used
      linear_interpolation_MR(rk_data->dataRKmr->time-rk_data->dataRKmr->lastStepSize, rk_data->dataRKmr->yt,
                              rk_data->dataRKmr->time, rk_data->dataRKmr->y,
                              sData->timeValue, sData->realVars,
                              rk_data->nFastStates, rk_data->fastStates);

    // interpolating slow states if multirate method is used, otherwise all states are slow states
    linear_interpolation_MR(rk_data->timeLeft, rk_data->yLeft,
                            rk_data->timeRight, rk_data->y,
                            sData->timeValue, sData->realVars,
                            rk_data->nSlowStates, rk_data->slowStates);
    if(ACTIVE_STREAM(LOG_SOLVER))
    {
      // printIntVector_genericRK("fast states:", rk_data->fastStates, rk_data->nFastStates, solverInfo->currentTime);
      // printVector_genericRK("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
      messageClose(LOG_SOLVER);
    }
  }else{
    // Integrator emits result on the simulation grid
    solverInfo->currentTime = rk_data->time;
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
    infoStreamPrint(LOG_SOLVER_V, 0, "current integration time value: %0.4g", rk_data->time);
    infoStreamPrint(LOG_SOLVER_V, 0, "step size h to be attempted on next step: %0.4g", rk_data->stepSize);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of steps taken so far: %d", rk_data->stepsDone);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calls of functionODE() : %d", rk_data->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calculation of jacobian : %d", rk_data->evalJacobians);
    infoStreamPrint(LOG_SOLVER_V, 0, "error test failure : %d", rk_data->errorTestFailures);
    infoStreamPrint(LOG_SOLVER_V, 0, "convergence failure : %d", rk_data->convergenceFailures);
    messageClose(LOG_SOLVER_V);
  }

  /* write statistics to the solverInfo data structure */
  solverInfo->solverStatsTmp[0] = rk_data->stepsDone;
  solverInfo->solverStatsTmp[1] = rk_data->evalFunctionODE;
  solverInfo->solverStatsTmp[2] = rk_data->evalJacobians;
  solverInfo->solverStatsTmp[3] = rk_data->errorTestFailures;
  solverInfo->solverStatsTmp[4] = rk_data->convergenceFailures;

  infoStreamPrint(LOG_SOLVER_V, 0, "finished genericRK step.");
  messageClose(LOG_SOLVER);
  return 0;
}

void sortErrorIndices(DATA_GENERIC_RK* rk_data)
{
  int i, j, temp;

  for (i = 0;  i < rk_data->nStates - 1; i++)
  {
    for (j = 0; j < rk_data->nStates - i - 1; j++)
    {
      if (rk_data->err[rk_data->sortedStates[j]] < rk_data->err[rk_data->sortedStates[j+1]])
      {
        temp = rk_data->sortedStates[j];
        rk_data->sortedStates[j] = rk_data->sortedStates[j+1];
        rk_data->sortedStates[j+1] = temp;
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
