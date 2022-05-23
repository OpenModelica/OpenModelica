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

/*! \file gm.c
 *  Implementation of a generic (implicit and explicit) Runge Kutta solver, which works for any
 *  order and stage based on a provided Butcher tableau. Utilizes the sparsity pattern of the ODE
 *  together with the KINSOL (KLU) solver
 *
 *  \author bbachmann
 */

#include <time.h>

#include "gbode.h"
#include "gbodef.h"

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
#include "epsilon.h"

//auxiliary vector functions
void linear_interpolation_gb(double a, double* fa, double b, double* fb, double t, double *f, int n);
void hermite_interpolation(double ta, double* fa, double* dfa, double tb, double* fb, double* dfb, double t, double* f, int n);
void printVector_gb(char name[], double* a, int n, double time);
void printIntVector_gb(char name[], int* a, int n, double time);
void printMatrix_gb(char name[], double* a, int n, double time);
void copyVector_gbf(double* a, double* b, int nIndx, int* indx);
double getErrorThreshold(DATA_GBODE* gbData);

// singlerate step function
int expl_diag_impl_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
int full_implicit_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
int full_implicit_MS(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);

// Residuum and Jacobian functions for diagonal implicit (DIRK) and implicit (IRK) Runge-Kutta methods.
void residual_MS(void **dataIn, const double *xloc, double *res, const int *iflag);
void residual_DIRK(void **dataIn, const double *xloc, double *res, const int *iflag);
int jacobian_SR_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian);

void residual_IRK(void **dataIn, const double *xloc, double *res, const int *iflag);
int jacobian_IRK_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian);

void initializeStaticNLSData_DIRK(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsPattern);

void allocateDataGbodef(DATA* data, threadData_t* threadData, DATA_GBODE* gbData);

// step size control function
double IController(double* err_values, double* stepSize_values, double err_order);
double PIController(double* err_values, double* stepSize_values, double err_order);

int checkForStateEvent(DATA* data, LIST *eventList);
double findRoot(DATA* data, threadData_t* threadData, LIST* eventList, double time_left, double* values_left, double time_right, double* values_right);

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
    eventTime = findRoot(data, threadData, solverInfo->eventLst, timeLeft, leftValues, timeRight, rightValues);
    infoStreamPrint(LOG_SOLVER, 0, "gbode detected an event at time: %20.16g", eventTime);
  }

  // re-store the pre values of the zeroCrossings for comparison
  memcpy(data->simulationInfo->zeroCrossings, data->simulationInfo->zeroCrossingsPre, data->modelData->nZeroCrossings * sizeof(modelica_real));

  return eventTime;
}

struct RK_USER_DATA {
  DATA* data;
  threadData_t* threadData;
  DATA_GBODE* gbData;
};

struct dataSolver
{
  void* ordinaryData;
  void* initHomotopyData;
};

/**
 * @brief Get Runge-Kutta method from simulation flag FLAG_SR.
 *
 * Defaults to RK_DOPRI45 if flag is not set.
 * Returns RK_UNKNOWN if flag is not known.
 *
 * @return enum GM_SINGLERATE_METHOD    Runge-Kutta method.
 */
enum GM_SINGLERATE_METHOD getGM_method(enum _FLAG FLAG_SR_METHOD) {
  enum GM_SINGLERATE_METHOD method;
  const char* flag_value;
  flag_value = omc_flagValue[FLAG_SR_METHOD];
  char* GM_method_string;

  if (flag_value != NULL) {
    GM_method_string = GC_strdup(flag_value);
    for (method=RK_UNKNOWN; method<RK_MAX; method++) {
      if (strcmp(GM_method_string, GM_SINGLERATE_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode method: %s", GM_SINGLERATE_METHOD_NAME[method]);
        return method;
      }
    }
    errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow gbode method %s.", GM_method_string);
    errorStreamPrint(LOG_STDOUT, 0, "Choose gbode method: %s [from command line]", GM_method_string);
    return RK_UNKNOWN;
  } else {
    if (FLAG_SR_METHOD == FLAG_MR) {
      return getGM_method(FLAG_SR);
    } else {

      infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode method: adams [default]");
      return MS_ADAMS_MOULTON;
    }
  }
}

/**
 * @brief Get non-linear solver method for Runge-Kutta from flag FLAG_SR_NLS.
 *
 * Defaults to Newton if flag is not set.
 * Returns RK_UNKNOWN if flag is not known.
 *
 * @return enum GM_NLS_METHOD   NLS method.
 */
enum GM_NLS_METHOD getGM_NLS_METHOD(enum _FLAG FLAG_NLS_METHOD) {
  enum GM_NLS_METHOD method;
  const char* flag_value;
  flag_value = omc_flagValue[FLAG_NLS_METHOD];
  char* GM_NLS_METHOD_string;

  if (flag_value != NULL) {
    GM_NLS_METHOD_string = GC_strdup(flag_value);
    for (method=RK_NLS_UNKNOWN; method<RK_NLS_MAX; method++) {
      if (strcmp(GM_NLS_METHOD_string, GM_NLS_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode NLS method: %s", GM_NLS_METHOD_NAME[method]);
        return method;
      }
    }
    errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow non-linear solver method %s for gbode.", GM_NLS_METHOD_string);
    errorStreamPrint(LOG_STDOUT, 0, "Choose gbode NLS method: %s [from command line]", GM_NLS_METHOD_string);
    return RK_NLS_UNKNOWN;
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "Chosen gbode NLS method: newton [default]");
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
                        LOG_MULTIRATE_V,
                        "sparsePattern");
  printSparseStructure(sparsePatternT,
                        sizeRows,
                        sizeCols,
                        LOG_MULTIRATE_V,
                        "sparsePatternT");
}

/**
 * @brief Prints sparse structure.
 *
 * Use to print e.g. sparse Jacobian matrix.
 * Only prints if stream is active and sparse pattern is non NULL and of size > 0.
 *
 * @param sparsePattern   Matrix to print.
 * @param sizeRows        Number of rows of matrix.
 * @param sizeCols        Number of columns of matrix.
 * @param stream          Steam to print to.
 * @param name            Name of matrix.
 */
void printSparseJacobianLocal(ANALYTIC_JACOBIAN* jacobian, const char* name)
{
  /* Variables */
  unsigned int row, col, i, j;
  infoStreamPrint(LOG_STDOUT, 0, "Sparse structure of %s [size: %ux%u]", name, jacobian->sizeRows, jacobian->sizeCols);
  infoStreamPrint(LOG_STDOUT, 0, "%u non-zero elements", jacobian->sparsePattern->numberOfNonZeros);

  infoStreamPrint(LOG_STDOUT, 0, "Values of the transposed matrix (rows: states)");

  printf("\n");
  i=0;
  for(row=0; row < jacobian->sizeRows; row++)
  {
    j=0;
    for(col=0; i < jacobian->sparsePattern->leadindex[row+1]; col++)
    {
      if(jacobian->sparsePattern->index[i] == col)
      {
        printf("%20.16g ", jacobian->resultVars[col]);
        ++i;
      }
      else
      {
        printf("%20.16g ", 0.0);
      }
    }
    printf("\n");
  }
  printf("\n");
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
  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;

  /* Get Sparsity of ODE Jacobian */
  ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  SPARSE_PATTERN* sparsePattern_ODE = jacobian->sparsePattern;

  int sizeRows = jacobian->sizeRows;
  int sizeCols = jacobian->sizeCols;
  int nStages  = gbData->tableau->nStages;
  int nStates  = gbData->nStates;
  double* A    = gbData->tableau->A;

  printSparseStructure(sparsePattern_ODE,
                      sizeRows,
                      sizeCols,
                      LOG_MULTIRATE_V,
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
      if (!diagElemNonZero) {
        coo_col[i] = col + k*nStates;
        coo_row[i] = col + k*nStates;
        i++;
        diagElemNonZero = TRUE;
      }
    }
  }

  numberOfNonZeros = i;

  if (ACTIVE_STREAM(LOG_MULTIRATE_V)){
    printIntVector_gb("rows", coo_row, numberOfNonZeros, 0.0);
    printIntVector_gb("cols", coo_col, numberOfNonZeros, 0.0);
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
  //   printIntVector_gb("colorCols: ", &sparsePattern_IRK->colorCols[k*nStates], sizeCols, 0);

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
void initializeStaticNLSData_DIRK(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsPattern) {
  for(int i=0; i<nonlinsys->size; i++) {
    // Get the nominal values of the states
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = DBL_MIN;
    nonlinsys->max[i]     = DBL_MAX;
  }

  /* Initialize sparsity pattern */
  if (initSparsPattern) {
    nonlinsys->sparsePattern = initializeSparsePattern_DIRK(data, nonlinsys);
    nonlinsys->isPatternAvailable = TRUE;
  }
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
void initializeStaticNLSData_MS(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsPattern) {
  for(int i=0; i<nonlinsys->size; i++) {
    // Get the nominal values of the states
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = DBL_MIN;
    nonlinsys->max[i]     = DBL_MAX;
  }

  /* Initialize sparsity pattern */
  if( initSparsPattern) {
    nonlinsys->sparsePattern = initializeSparsePattern_DIRK(data, nonlinsys); // BB ToDo: is this correct
    nonlinsys->isPatternAvailable = TRUE;
  }
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
void initializeStaticNLSData_IRK(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsPattern) {
  for(int i=0; i<nonlinsys->size; i++) {
    // Get the nominal values of the states, the non-linear system has size stages*nStates
    int ii = nonlinsys->size % data->modelData->nStates;
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[ii].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = DBL_MIN;
    nonlinsys->max[i]     = DBL_MAX;
  }

  /* Initialize sparsity pattern */
  if (initSparsPattern) {
    nonlinsys->sparsePattern = initializeSparsePattern_IRK(data, nonlinsys);
    nonlinsys->isPatternAvailable = TRUE;
  }
  return;
}

/**
 * @brief Allocate and initialize non-linear system data for Runge-Kutta method.
 *
 * Runge-Kutta method has to be implicit or diagonal implicit.
 *
 * @param data                        Runtime data struct.
 * @param threadData                  Thread data for error handling.
 * @param gbData                     Runge-Kutta method.
 * @return NONLINEAR_SYSTEM_DATA*     Pointer to initialized non-linear system data.
 */
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA(DATA* data, threadData_t* threadData, DATA_GBODE* gbData) {
  assertStreamPrint(threadData, gbData->type != GM_TYPE_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  // TODO AHeu: Free solverData again
  struct dataSolver *solverData = (struct dataSolver*) calloc(1,sizeof(struct dataSolver));

  ANALYTIC_JACOBIAN* jacobian = NULL;

  NONLINEAR_SYSTEM_DATA* nlsData = (NONLINEAR_SYSTEM_DATA*) calloc(1, sizeof(NONLINEAR_SYSTEM_DATA));
  assertStreamPrint(threadData, nlsData != NULL,"Out of memory");

  analyticalJacobianColumn_func_ptr analyticalJacobianColumn;

  nlsData->size = gbData->nlSystemSize;
  nlsData->equationIndex = -1;

  nlsData->homotopySupport = FALSE;
  nlsData->initHomotopy = FALSE;
  nlsData->mixedSystem = FALSE;

  nlsData->min = NULL;
  nlsData->max = NULL;
  nlsData->nominal = NULL;

  switch (gbData->type)
  {
  case GM_TYPE_DIRK:
    nlsData->residualFunc = residual_DIRK;
    nlsData->analyticalJacobianColumn = jacobian_SR_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_DIRK;
    nlsData->getIterationVars = NULL;

    gbData->symJacAvailable = TRUE;
    break;
  case GM_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_IRK;
    nlsData->analyticalJacobianColumn = jacobian_IRK_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_IRK;
    nlsData->getIterationVars = NULL;

    gbData->symJacAvailable = TRUE;
    break;
  case MS_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_MS;
    nlsData->analyticalJacobianColumn = jacobian_SR_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_MS;
    nlsData->getIterationVars = NULL;

    gbData->symJacAvailable = TRUE;
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Residual function for NLS type %i not yet implemented.", gbData->type);
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
  nlsData->initializeStaticNLSData(data, threadData, nlsData, TRUE);

  // TODO: Set callback to initialize Jacobian
  //       Write said function...
  // TODO: Free memory
  gbData->jacobian = initAnalyticJacobian(gbData->nlSystemSize, gbData->nlSystemSize, gbData->nlSystemSize, NULL, nlsData->sparsePattern);
  nlsData->initialAnalyticalJacobian = NULL;
  nlsData->jacobianIndex = -1;

  /* Initialize NLS method */
  switch (gbData->nlsSolverMethod) {
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
    if (gbData->symJacAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsData->nlsLinearSolver);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    if (gbData->symJacAvailable) {
      resetKinsolMemory(solverData->ordinaryData, nlsData);
    } else {
      resetKinsolMemory(solverData->ordinaryData, nlsData);
      int flag = KINSetJacFn(((NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory, NULL);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
    }
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Memory allocation for NLS method %s not yet implemented.", GM_NLS_METHOD_NAME[gbData->nlsSolverMethod]);
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
int allocateDataGbode(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo) {
  DATA_GBODE* gbData = (DATA_GBODE*) malloc(sizeof(DATA_GBODE));

  // Set backup in simulationInfo
  data->simulationInfo->backupSolverData = (void*) gbData;

  solverInfo->solverData = (void*) gbData;

  gbData->nStates = data->modelData->nStates;

  ANALYTIC_JACOBIAN* jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;

  gbData->GM_method = getGM_method(FLAG_SR);
  gbData->tableau = initButcherTableau(gbData->GM_method, FLAG_SR_ERR);
  if (gbData->tableau == NULL){
    errorStreamPrint(LOG_STDOUT, 0, "allocateDataGm: Failed to initialize gbode tableau for method %s", GM_SINGLERATE_METHOD_NAME[gbData->GM_method]);
    return -1;
  }

  // Get size of non-linear system
  analyseButcherTableau(gbData->tableau, gbData->nStates, &gbData->nlSystemSize, &gbData->type);

  switch (gbData->type)
  {
  case GM_TYPE_EXPLICIT:
    gbData->isExplicit = TRUE;
    gbData->step_fun = &(expl_diag_impl_RK);
    break;
  case GM_TYPE_DIRK:
    gbData->isExplicit = FALSE;
    gbData->step_fun = &(expl_diag_impl_RK);
    break;
  case GM_TYPE_IMPLICIT:
    gbData->isExplicit = FALSE;
    gbData->step_fun = &(full_implicit_RK);
    break;
  case MS_TYPE_IMPLICIT:
    gbData->isExplicit = FALSE;
    gbData->step_fun = &(full_implicit_MS);
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "allocateDataGbode: Unknown type %i", gbData->type);
    return -1;
  }
  // adapt decision for testing of the fully implicit implementation
  if (gbData->GM_method == RK_ESDIRK2_test || gbData->GM_method == RK_ESDIRK3_test) {
    gbData->nlSystemSize = gbData->tableau->nStages*gbData->nStates;
    gbData->step_fun = &(full_implicit_RK);
    gbData->type = GM_TYPE_IMPLICIT;
  }
  if (gbData->GM_method == MS_ADAMS_MOULTON) {
    gbData->nlSystemSize = gbData->nStates;
    gbData->step_fun = &(full_implicit_MS);
    gbData->type = MS_TYPE_IMPLICIT;
    gbData->isExplicit = FALSE;
  }

  // test of multistep method

  const char* flag_StepSize_ctrl = omc_flagValue[FLAG_SR_CTRL];

  if (flag_StepSize_ctrl != NULL) {
    gbData->stepSize_control = &(PIController);
    infoStreamPrint(LOG_SOLVER, 0, "Stepsize control using PIController");
  } else
  {
    gbData->stepSize_control = &(IController);
    infoStreamPrint(LOG_SOLVER, 0, "Stepsize control using IController");
  }

  /* Allocate internal memory */
  gbData->isFirstStep = TRUE;
  gbData->y = malloc(sizeof(double)*gbData->nStates);
  gbData->yOld = malloc(sizeof(double)*gbData->nStates);
  gbData->yLeft = malloc(sizeof(double)*gbData->nStates);
  gbData->yRight = malloc(sizeof(double)*gbData->nStates);
  gbData->yt = malloc(sizeof(double)*gbData->nStates);
  gbData->f = malloc(sizeof(double)*gbData->nStates);
  gbData->k = malloc(sizeof(double)*gbData->nStates*gbData->tableau->nStages);
  gbData->x = malloc(sizeof(double)*gbData->nStates*gbData->tableau->nStages);
  gbData->res_const = malloc(sizeof(double)*gbData->nStates);
  gbData->errest = malloc(sizeof(double)*gbData->nStates);
  gbData->errtol = malloc(sizeof(double)*gbData->nStates);
  gbData->err = malloc(sizeof(double)*gbData->nStates);
  gbData->ringBufferSize = 5;
  gbData->errValues = malloc(sizeof(double)* gbData->ringBufferSize);
  gbData->stepSizeValues = malloc(sizeof(double)* gbData->ringBufferSize);
  if (!gbData->isExplicit) {
    gbData->Jf = malloc(sizeof(double)*gbData->nStates*gbData->nStates);
    for (int i=0; i<gbData->nStates*gbData->nStates; i++)
      gbData->Jf[i] = 0;
  } else {
    gbData->Jf = NULL;
  }

  printButcherTableau(gbData->tableau);

  /* initialize statistic counter */
  // TODO AHeu: Use calloc instead?
  gbData->stepsDone = 0;
  gbData->evalFunctionODE = 0;
  gbData->evalJacobians = 0;
  gbData->errorTestFailures = 0;
  gbData->convergenceFailures = 0;

  /* initialize analytic Jacobian, if available and needed */
  if (!gbData->isExplicit) {
    jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    // TODO: Do we need to initialize the Jacobian or is it already initialized?
    if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian)) {
      gbData->symJacAvailable = FALSE;
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to numeric Jacobians.");
    } else {
      gbData->symJacAvailable = TRUE;
      // TODO AHeu: Is there a reason we get the jacobian again? Did data->callback->initialAnalyticJacobianA change the pointer?
      // ANALYTIC_JACOBIAN* jac = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
      infoStreamPrint(LOG_SOLVER, 1, "Initialized colored Jacobian:");
      infoStreamPrint(LOG_SOLVER, 0, "columns: %d rows: %d", jacobian->sizeCols, jacobian->sizeRows);
      infoStreamPrint(LOG_SOLVER, 0, "NNZ:  %d colors: %d", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
      messageClose(LOG_SOLVER);
    }

  /* Allocate memory for the nonlinear solver */
    gbData->nlsSolverMethod = getGM_NLS_METHOD(FLAG_SR_NLS);
    gbData->nlsData = initRK_NLS_DATA(data, threadData, gbData);
    if (!gbData->nlsData) {
      return -1;
    } else {
      infoStreamPrint(LOG_SOLVER, 1, "Nominal values of  the states:");
      for (int i =0; i<gbData->nStates; i++)
      {
        infoStreamPrint(LOG_SOLVER, 0, "%s = %g", data->modelData->realVarsData[i].info.name, gbData->nlsData->nominal[i]);
      }
      messageClose(LOG_SOLVER);
    }
  }
  else
  {
    gbData->symJacAvailable = FALSE;
    gbData->nlsSolverMethod = RK_NLS_UNKNOWN;  // TODO AHeu: Add a no-solver option?
    gbData->nlsData = NULL;
    gbData->jacobian = NULL;
  }

  const char* flag_value = omc_flagValue[FLAG_MR_PAR];
  if (flag_value != NULL)
    gbData->percentage = atof(omc_flagValue[FLAG_MR_PAR]);
  else
    gbData->percentage = 0;
  if (gbData->percentage > 0) {
    gbData->multi_rate = 1;
  } else {
    gbData->multi_rate = 0;
  }

  gbData->fastStates = malloc(sizeof(int)*gbData->nStates);
  gbData->slowStates = malloc(sizeof(int)*gbData->nStates);
  gbData->sortedStates = malloc(sizeof(int)*gbData->nStates);

  gbData->nFastStates = 0;
  gbData->nSlowStates = gbData->nStates;
  for (int i=0; i<gbData->nStates; i++)
  {
    gbData->slowStates[i] = i;
    gbData->sortedStates[i] = i;
  }

  if (gbData->multi_rate) {
    allocateDataGbodef(data, threadData, gbData);
  } else {
    gbData->gbfData = NULL;
  }

  //gbData->interpolation = 2; // GM_HERMITE
  gbData->interpolation = 1; // GM_LINEAR

  return 0;
}

/**
 * @brief Free generic RK data.
 *
 * @param gbData    Pointer to generik Runge-Kutta data struct.
 */
void freeDataGbode(DATA_GBODE* gbData) {
  /* Free non-linear system data */
  if(gbData->nlsData != NULL) {
    struct dataSolver* dataSolver = gbData->nlsData->solverData;
    switch (gbData->nlsSolverMethod)
    {
    case RK_NLS_NEWTON:
      freeNewtonData(dataSolver->ordinaryData);
      break;
    case RK_NLS_KINSOL:
      //kinsolData = (NLS_KINSOL_DATA*) gbData->nlsData->solverData;
      nlsKinsolFree(dataSolver->ordinaryData);
      break;
    default:
      warningStreamPrint(LOG_SOLVER, 0, "Not handled GM_NLS_METHOD in freeDataGbode. Are we leaking memroy?");
      break;
    }
    free(dataSolver);
    free(gbData->nlsData);
  }
  /* Free Jacobian */
  freeAnalyticJacobian(gbData->jacobian);

  /* Free Butcher tableau */
  freeButcherTableau(gbData->tableau);

  if (gbData->multi_rate == 1) {
    freeDataGbf(gbData->gbfData);
  }
  /* Free multi-rate data */
  free(gbData->err);
  free(gbData->errValues);
  free(gbData->stepSizeValues);
  free(gbData->fastStates);
  free(gbData->slowStates);

  /* Free remaining arrays */
  free(gbData->y);
  free(gbData->yOld);
  free(gbData->yLeft);
  free(gbData->yRight);
  free(gbData->yt);
  free(gbData->f);
  free(gbData->Jf);
  free(gbData->k);
  free(gbData->x);
  free(gbData->res_const);
  free(gbData->errest);
  free(gbData->errtol);

  free(gbData);
  gbData = NULL;

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
int wrapper_f_gm(DATA* data, threadData_t *threadData, void* evalFunctionODE, modelica_real* fODE)
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
  DATA_GBODE *gbData = (DATA_GBODE *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i;
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;
  int stage_   = gbData->act_stage;

  // Evaluate right hand side of ODE
  memcpy(sData->realVars, xloc, nStates*sizeof(double));
  wrapper_f_gm(data, threadData, &(gbData->evalFunctionODE), fODE);

  // Evaluate residual
  for (i=0; i<nStates; i++) {
    res[i] = gbData->res_const[i] - xloc[i] * gbData->tableau->c[nStages-1] +
                                      fODE[i] * gbData->tableau->b[nStages-1] * gbData->stepSize;
  }

  return;
}

/**
 * @brief Evaluate column of DIRK Jacobian.
 *
 * @param inData            Void pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gbData     Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_SR_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA* data = (DATA*) inData;
  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;

  int i;
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;
  int stage = gbData->act_stage;

  /* Evaluate column of Jacobian ODE */
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  memcpy(jacobian_ODE->seedVars, jacobian->seedVars, sizeof(modelica_real)*jacobian->sizeCols);
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  for (i = 0; i < jacobian->sizeCols; i++) {
    if (gbData->type == MS_TYPE_IMPLICIT) {
      jacobian->resultVars[i] = gbData->tableau->b[nStages-1] * gbData->stepSize * jacobian_ODE->resultVars[i];
    } else {
      jacobian->resultVars[i] = gbData->stepSize * gbData->tableau->A[stage * nStages + stage] * jacobian_ODE->resultVars[i];
    }
    /* -1 on diagonal elements */
    if (jacobian->seedVars[i] == 1) {
      jacobian->resultVars[i] -= 1;
    }
  }

  // printVector_gb("jacobian_ODE colums", jacobian_ODE->resultVars, nStates, gbData->time);
  // printVector_gb("jacobian colums", jacobian->resultVars, nStates, gbData->time);
  // printIntVector_gb("sparsity pattern colors", jacobian->sparsePattern->colorCols, nStates, gbData->time);

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
  DATA_GBODE *gbData = (DATA_GBODE *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i;
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;
  int stage_   = gbData->act_stage;

  // Evaluate right hand side of ODE
  memcpy(sData->realVars, xloc, nStates*sizeof(double));
  wrapper_f_gm(data, threadData, &(gbData->evalFunctionODE), fODE);

  // Evaluate residual
  for (i=0; i<nStates; i++) {
    res[i] = gbData->res_const[i] - xloc[i] + gbData->stepSize * gbData->tableau->A[stage_ * nStages + stage_] * fODE[i];
  }

  return;
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
  DATA_GBODE *gbData = (DATA_GBODE *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;

  int i;
  int nStages = gbData->tableau->nStages;
  int nStates = data->modelData->nStates;
  int stage, stage_;

  // stage_ == 0, was already handle for predictor step
  for (stage_=1; stage_<nStages; stage_++)
  {
    /* Evaluate ODE and compute res for each stage_ */
    sData->timeValue = gbData->time + gbData->tableau->c[stage_] * gbData->stepSize;
    memcpy(sData->realVars, &xloc[stage_*nStates], nStates*sizeof(double));
    wrapper_f_gm(data, threadData, &(gbData->evalFunctionODE), fODE);
    memcpy(&gbData->k[stage_*nStates], fODE, nStates*sizeof(double));
  }

  // Calculate residuum for the full implicit RK method based on stages and A matrix
  for (stage=0; stage<nStages; stage++)
  {
    for (i=0; i<nStates; i++)
    {
      res[stage * nStates + i] = gbData->yOld[i] - xloc[stage * nStates + i];
      for (stage_=0; stage_<nStages; stage_++)
      {
        res[stage * nStates + i] += gbData->stepSize * gbData->tableau->A[stage * nStages + stage_] * (gbData->k + stage_*nStates)[i];
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
 * @param gbData     Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_IRK_column(void *inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA* data = (DATA*) inData;
  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  const double* xloc = gbData->nlsData->nlsx;

  int i;
  int stage, stage_;
  int nStages = gbData->tableau->nStages;
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
  sData->timeValue = gbData->time + gbData->tableau->c[stage_] * gbData->stepSize;
  // BB ToDo: ist xloc das gleiche wie gbData->nlsData->nlsx
  memcpy(sData->realVars, &(xloc[stage_*nStates]), nStates*sizeof(double));
  // call jacobian_ODE with the mapped seedVars
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array for corresponding jacobian->seedVars*/
  for (stage=0; stage<nStages; stage++)
  {
    for (i=0; i<nStates; i++)
    {
      jacobian->resultVars[stage * nStates + i] = gbData->stepSize * gbData->tableau->A[stage * nStages + stage_]  * jacobian_ODE->resultVars[i];
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
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;

  int i;
  int stage, stage_;
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;
  modelica_boolean solved = FALSE;

  // printVector_gb("k:  ", gbData->k + 0 * nStates, nStates, gbData->time);
  // printVector_gb("k:  ", gbData->k + 1 * nStates, nStates, gbData->time);
  // printVector_gb("x:  ", gbData->x + 0 * nStates, nStates, gbData->time);
  // printVector_gb("x:  ", gbData->x + 1 * nStates, nStates, gbData->time);

  /* Predictor Schritt */
  for (i = 0; i < nStates; i++)
  {
    // BB ToDo: check the formula with respect to gbData->k[]
    gbData->yt[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gbData->yt[i] += -gbData->x[stage_ * nStates + i] * gbData->tableau->c[stage_] +
                          gbData->k[stage_ * nStates + i] * gbData->tableau->bt[stage_] *  gbData->stepSize;
    }
    gbData->yt[i] += gbData->k[stage_ * nStates + i] * gbData->tableau->bt[stage_] * gbData->stepSize;
    gbData->yt[i] /= gbData->tableau->c[stage_];
  }


  /* Constant part of the multistep method */
  for (i = 0; i < nStates; i++)
  {
    // BB ToDo: check the formula with respect to gbData->k[]
    gbData->res_const[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gbData->res_const[i] += -gbData->x[stage_ * nStates + i] * gbData->tableau->c[stage_] +
                                 gbData->k[stage_ * nStates + i] * gbData->tableau->b[stage_] *  gbData->stepSize;
    }
  }
  // printVector_gb("res_const:  ", gbData->res_const, nStates, gbData->time);

  /* Compute intermediate step k, explicit if diagonal element is zero, implicit otherwise
    * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
  // here, it yields:   stage == stage_, and stage * nStages + stage_ is index of the diagonal element

  // set simulation time with respect to the current stage
  sData->timeValue = gbData->time + gbData->stepSize;

  // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
  NONLINEAR_SYSTEM_DATA* nlsData = gbData->nlsData;
  // Set start vector, BB ToDo: Ommit extrapolation after event!!!

  memcpy(nlsData->nlsx, gbData->yt, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
  gbData->multi_rate_phase = 0;

  if (ACTIVE_STREAM(LOG_MULTIRATE_V)) {
    clock_t start, end;
    double cpu_time_used;

    start = clock();
    solved = solveNLS(data, threadData, nlsData, -1);
    end = clock();
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

    infoStreamPrint(LOG_STATS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
  } else {
    solved = solveNLS(data, threadData, nlsData, -1);
  }

  if (!solved) {
    errorStreamPrint(LOG_STDOUT, 0, "gbode error: Failed to solve NLS in full_implicit_MS");
    return -1;
  }

  memcpy(gbData->k + stage_ * nStates, fODE, nStates*sizeof(double));

  /* Corrector Schritt */
  for (i = 0; i < nStates; i++)
  {
    // BB ToDo: check the formula with respect to gbData->k[]
    gbData->y[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gbData->y[i] += -gbData->x[stage_ * nStates + i] * gbData->tableau->c[stage_] +
                         gbData->k[stage_ * nStates + i] * gbData->tableau->b[stage_] *  gbData->stepSize;
    }
    gbData->y[i] += gbData->k[stage_ * nStates + i] * gbData->tableau->b[stage_] * gbData->stepSize;
    gbData->y[i] /= gbData->tableau->c[stage_];
  }
  // copy last calculation of fODE, which should coincide with k[i], here, it yields stage == stage_
  memcpy(gbData->x + stage_ * nStates, gbData->y, nStates*sizeof(double));

  // printVector_gb("yt: ", gbData->yt, nStates, gbData->time);
  // printVector_gb("y:  ", gbData->y, nStates, gbData->time);

  // printVector_gb("k:  ", gbData->k + 0 * nStates, nStates, gbData->time);
  // printVector_gb("k:  ", gbData->k + 1 * nStates, nStates, gbData->time);


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
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;

  int i;
  int stage, stage_;
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;
  modelica_boolean solved = FALSE;

  // First try for better starting values, only necessary after restart
  // BB ToDo: Or maybe necessary for RK methods, where b is not equal to the last row of A
  sData->timeValue = gbData->time;
  memcpy(sData->realVars, gbData->yOld, nStates*sizeof(double));
  wrapper_f_gm(data, threadData, &(gbData->evalFunctionODE), fODE);
  memcpy(gbData->k, fODE, nStates*sizeof(double));

  /* Runge-Kutta step */
  for (stage = 0; stage < nStages; stage++)
  {
    gbData->act_stage = stage;
    /* Set constant parts or residual input
     * res = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..stage-1)) */

    for (i = 0; i < nStates; i++)
    {
      // BB ToDo: check the formula with respect to gbData->k[]
      gbData->res_const[i] = gbData->yOld[i];
      for (stage_ = 0; stage_ < stage; stage_++)
      {
        gbData->res_const[i] += gbData->stepSize * gbData->tableau->A[stage * nStages + stage_] * gbData->k[stage_ * nStates + i];
      }
    }

    /* Compute intermediate step k, explicit if diagonal element is zero, implicit otherwise
     * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
    // here, it yields:   stage == stage_, and stage * nStages + stage_ is index of the diagonal element

    // set simulation time with respect to the current stage
    sData->timeValue = gbData->time + gbData->tableau->c[stage_]*gbData->stepSize;


    if (gbData->tableau->A[stage * nStages + stage_] == 0)
    {
      if (stage>0) {
        memcpy(sData->realVars, gbData->res_const, nStates*sizeof(double));
        wrapper_f_gm(data, threadData, &(gbData->evalFunctionODE), fODE);
      }
      memcpy(gbData->x + stage_ * nStates, gbData->res_const, nStates*sizeof(double));
    }
    else
    {
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = gbData->nlsData;
      // Set start vector, BB ToDo: Ommit extrapolation after event!!!
      for (i=0; i<nStates; i++) {
          nlsData->nlsx[i] = gbData->yOld[i] + gbData->tableau->c[stage_] * gbData->stepSize * gbData->k[i];
      }
      //memcpy(nlsData->nlsx, gbData->yOld, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
      gbData->multi_rate_phase = 0;

      if (ACTIVE_STREAM(LOG_MULTIRATE_V)) {
        clock_t start, end;
        double cpu_time_used;

        start = clock();
        solved = solveNLS(data, threadData, nlsData, -1);
        end = clock();
        cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

        infoStreamPrint(LOG_STATS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
      } else {
        solved = solveNLS(data, threadData, nlsData, -1);
      }

      if (!solved) {
        errorStreamPrint(LOG_STDOUT, 0, "gbode error: Failed to solve NLS in expl_diag_impl_RK in stage %d", stage_);
        return -1;
      }
    }
    // copy last calculation of fODE, which should coincide with k[i], here, it yields stage == stage_
    memcpy(gbData->k + stage_ * nStates, fODE, nStates*sizeof(double));
  }

  // Apply RK-scheme for determining the approximations at (gbData->time + gbData->stepSize)
  // y       = yold+h*sum(b[stage_]  * k[stage_], stage_=1..nStages);
  // yt      = yold+h*sum(bt[stage_] * k[stage_], stage_=1..nStages);
  for (i=0; i<nStates; i++)
  {
    gbData->y[i]  = gbData->yOld[i];
    gbData->yt[i] = gbData->yOld[i];
    for (stage_=0; stage_<nStages; stage_++)
    {
      gbData->y[i]  += gbData->stepSize * gbData->tableau->b[stage_]  * (gbData->k + stage_ * nStates)[i];
      gbData->yt[i] += gbData->stepSize * gbData->tableau->bt[stage_] * (gbData->k + stage_ * nStates)[i];
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
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;

  NONLINEAR_SYSTEM_DATA* nlsData = gbData->nlsData;

  int i;
  int stage_;
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;

  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;
  modelica_boolean solved = FALSE;

  // First try for better starting values, only necessary after restart
  // BB ToDo: Or maybe necessary for RK methods, where b is not equal to the last row of A
  memcpy(sData->realVars, gbData->yOld, nStates*sizeof(double));
  wrapper_f_gm(data, threadData, &(gbData->evalFunctionODE), fODE);
  memcpy(gbData->k, fODE, nStates*sizeof(double));

  /* Set start values for non-linear solver */
  for (stage_=0; stage_<nStages; stage_++) {
    // BB ToDo: Ommit extrapolation after event!!!
    for (i=0; i<nStates; i++)
      nlsData->nlsx[stage_*nStates +i] = gbData->yOld[i] + gbData->tableau->c[stage_] * gbData->stepSize * gbData->k[i];

    // memcpy(&nlsData->nlsx[stage_*nStates], gbData->yOld, nStates*sizeof(double));
    memcpy(&nlsData->nlsxOld[stage_*nStates], &nlsData->nlsx[stage_*nStates], nStates*sizeof(double));
    memcpy(&nlsData->nlsxExtrapolation[stage_*nStates], &nlsData->nlsx[stage_*nStates], nStates*sizeof(double));
  }
  gbData->multi_rate_phase = 0;

  if (ACTIVE_STREAM(LOG_MULTIRATE_V)) {
    clock_t start, end;
    double cpu_time_used;

    start = clock();
    solved = solveNLS(data, threadData, nlsData, -1);
    end = clock();
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

    infoStreamPrint(LOG_STATS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
  } else {
    solved = solveNLS(data, threadData, nlsData, -1);
  }

  if (!solved) {
    errorStreamPrint(LOG_STDOUT, 0, "gbode error: Failed to solve NLS in full_implicit_RK");
    return -1;
  }

  // Apply RK-scheme for determining the approximations at (gbData->time + gbData->stepSize)
  // y       = yold+h*sum(b[stage_]  * k[stage_], stage_=1..nStages);
  // yt      = yold+h*sum(bt[stage_] * k[stage_], stage_=1..nStages);
  for (i=0; i<nStates; i++)
  {
    gbData->y[i]  = gbData->yOld[i];
    gbData->yt[i] = gbData->yOld[i];
    for (stage_=0; stage_<nStages; stage_++)
    {
      gbData->y[i]  += gbData->stepSize * gbData->tableau->b[stage_]  * (gbData->k + stage_ * nStates)[i];
      gbData->yt[i] += gbData->stepSize * gbData->tableau->bt[stage_] * (gbData->k + stage_ * nStates)[i];
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
void gm_first_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;
  modelica_real* fODE = &sData->realVars[nStates];

  double sc, d, d0 = 0.0, d1 = 0.0, d2 = 0.0, h0, h1, delta_ti, infNorm, sum = 0;
  // TODO AHeu: We have flags for absolute and relative solver tolerances
  // Use data->simulationInfo->tolerance?
  double Atol = 1e-6;
  double Rtol = 1e-3;

  int i,j;

  /* store Startime of the simulation */
  gbData->time = sDataOld->timeValue;
  if (gbData->multi_rate)
      gbData->gbfData->time = gbData->time;

  gbData->timeLeft = gbData->time;
  gbData->timeRight = gbData->time;
  /* set correct flags in order to calculate initial step size */
  gbData->isFirstStep = FALSE;
  gbData->didEventStep = TRUE;
  if (gbData->multi_rate)
    gbData->gbfData->didEventStep = TRUE;
  solverInfo->didEventStep = FALSE;

  for (int i=0; i<gbData->ringBufferSize; i++) {
    gbData->errValues[i] = 0;
    gbData->stepSizeValues[i] = 0;
  }

 /* reset statistics because it is accumulated in solver_main.c */
  gbData->stepsDone = 0;
  gbData->evalFunctionODE = 0;
  gbData->evalJacobians = 0;
  gbData->errorTestFailures = 0;
  gbData->convergenceFailures = 0;

  gbData->multi_rate_phase = 0;


  /* calculate starting step size 1st Version */
  /* BB: What is the difference between sData and sDataOld at this time instance?
         Is this important for the restart after an event?
         And should this also been copied to userdata->old (see above?)
  */
  /* initialize start values of the integrator and calculate ODE function*/
  //printVector_gb("sData->realVars: ", sData->realVars, data->modelData->nStates, sData->timeValue);
  //printVector_gb("sDataOld->realVars: ", sDataOld->realVars, data->modelData->nStates, sDataOld->timeValue);

  memcpy(gbData->yOld, sData->realVars, data->modelData->nStates*sizeof(double));
  memcpy(gbData->x, sData->realVars, data->modelData->nStates*sizeof(double));
  wrapper_f_gm(data, threadData, &(gbData->evalFunctionODE), fODE);
  /* store values of the state derivatives at initial or event time */
  memcpy(gbData->f, fODE, data->modelData->nStates*sizeof(double));
  memcpy(gbData->k, fODE, nStates*sizeof(double));

  // if (gbData->type == MS_TYPE_IMPLICIT) {
  //     memcpy(gbData->x + (nStages-2) * nStates, gbData->yOld, nStates*sizeof(double));
  // }

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
    sData->realVars[i] = gbData->yOld[i] + fODE[i] * h0;
  }
  sData->timeValue += h0;

  wrapper_f_gm(data, threadData, &(gbData->evalFunctionODE), fODE);

  for (i=0; i<data->modelData->nStates; i++)
  {
    sc = Atol + fabs(gbData->yOld[i])*Rtol;
    d2 += ((fODE[i]-gbData->f[i])*(fODE[i]-gbData->f[i])/(sc*sc));
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

  gbData->stepSize = 0.5*fmin(100*h0,h1);
  gbData->lastStepSize = gbData->stepSize;

  infoStreamPrint(LOG_MULTIRATE, 0, "initial step size = %e at time %g", gbData->stepSize, gbData->time);
}


/**
 * @brief simple step size control (see Hairer, etc.)
 *
 * @param gbData
 * @return double
 */
double IController(double* err_values, double* stepSize_values, double err_order)
{
  double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.5;
  double beta = 1./err_order;

  if (err_values[0]>0) {
    return fmin(facmax, fmax(facmin, fac*pow(1./err_values[0], beta)));
  } else {
    return facmax;
  }
}

/**
 * @brief PI controller for step size control (see Hairer)
 *
 * @param gbData
 * @return double
 */
double PIController(double* err_values, double* stepSize_values, double err_order)
{
  double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.5;
  double beta  = 1./err_order;
  double beta1 = 1./err_order;
  double beta2 = 1./err_order;

  double estimate;

  if (err_values[0] < DBL_EPSILON)
    return facmax;

  if (err_values[1] < DBL_EPSILON)
    estimate = pow(1./err_values[0], beta);
  else
    estimate = stepSize_values[0]/stepSize_values[1]*pow(.5/err_values[0], beta1)*pow(err_values[1]/err_values[0], beta2);

  return fmin(facmax, fmax(facmin, fac*estimate));

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
int gbode_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1]; // BB: Is this the ring buffer???
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;

  double err, err_threshold;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;
  int i, ii, l;
  int nStates = (int) data->modelData->nStates;
  int rk_step_info;

  double targetTime;
  double eventTime;
  double stopTime = data->simulationInfo->stopTime;

  solverInfo->solverRootFinding = 1;

  infoStreamPrint(LOG_SOLVER, 0, "gbode solver started:");

  if(ACTIVE_STREAM(LOG_MULTIRATE_V))
  {
    printVector_gb("yIni:", sData->realVars, gbData->nStates, sDataOld->timeValue);
  }
  // TODO AHeu: Copy-paste code used in dassl,c, ida.c, irksco.c and here. Make it a function!
  // Also instead of solverInfo->integratorSteps we should set and use solverInfo->solverNoEquidistantGrid
  /* Calculate steps until targetTime is reached */
  if (solverInfo->integratorSteps) // 1 => emit result at integrator step points; 0 => equidistant grid
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
    targetTime = solverInfo->currentTime + solverInfo->currentStepSize;
    // targetTime = sDataOld->timeValue + solverInfo->currentStepSize;
  }

  // (Re-)initialize after events or at first call of gbode_step
  if (solverInfo->didEventStep == 1 || gbData->isFirstStep)
  {
    gm_first_step(data, threadData, solverInfo);

    // side effect:
    //    sData->realVars, userdata->yOld, and userdata->f are consistent
    //    userdata->time and userdata->stepSize are defined
  }

  // Check if multirate step is necessary, otherwise the correct values are already stored in sData
  if (gbData->multi_rate)
    if (gbData->nFastStates > 0 && gbData->gbfData->time < gbData->time)
      if (gbodef_step(data, threadData, solverInfo, targetTime))
              return 0;


  /* Main integration loop */
  while (gbData->time < targetTime)
  {
    do
    {
      // printVector_gb("yOld: ", gbData->yOld, nStates, gbData->time);
      // printVector_gb("y:    ", gbData->y, nStates, gbData->time);
      /* store yOld in yLeft for interpolation purposes, if necessary
      * BB: Check condition
      */
      memcpy(gbData->yLeft, gbData->yOld, data->modelData->nStates*sizeof(double));
      gbData->timeLeft = gbData->time;

      if(ACTIVE_STREAM(LOG_MULTIRATE))
      {
        printVector_gb("gb->yOld: ", gbData->yOld, gbData->nStates, gbData->time);
      }

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
      // calculate one step of the integrator
      if (gbData->percentage!=1 || !gbData->stepsDone) {
        rk_step_info = gbData->step_fun(data, threadData, solverInfo);
      }

      // error handling: try half of the step size!
      if (rk_step_info != 0) {
        errorStreamPrint(LOG_STDOUT, 0, "gbode_step: Failed to calculate step at time = %5g.", gbData->time);
        errorStreamPrint(LOG_STDOUT, 0, "Try half of the step size!");
        gbData->stepSize = gbData->stepSize/2.;
        continue;
        //return -1;
      }

      // calculate corresponding values for error estimator and step size control
      // BB ToDo: Investigate error estimator with respect for global accuracy
      // userdata->errtol[i] = Rtol*(fabs(userdata->y[i]) + fabs(userdata->stepSize*fODE[i])) + Atol*1e-3;
      for (i=0; i<nStates; i++)
      {
        gbData->errtol[i] = Rtol*fmax(fabs(gbData->y[i]),fabs(gbData->yt[i])) + Atol;
        gbData->errest[i] = fabs(gbData->y[i] - gbData->yt[i]);
      }

      /*** calculate error (infinity norm!)***/
      err = 0;
      for (i=0; i<nStates; i++)
      {
         gbData->err[i] = gbData->errest[i]/gbData->errtol[i];
         err = fmax(err, gbData->err[i]);
      }
      err = gbData->tableau->fac * err;

      // printVector_gb("Error before sorting:", gbData->err, gbData->nStates, gbData->time);
      // printIntVector_gb("Indices before sorting:", gbData->sortedStates, gbData->nStates, gbData->time);
      // printIntVector_gb("Indices after sorting:", gbData->sortedStates, gbData->nStates, gbData->time);
      // printVector_gbf("Error after sorting:", gbData->err, gbData->nStates, gbData->time,  gbData->nStates, gbData->sortedStates);

      if (gbData->multi_rate)
      {
        // BB ToDo: Gives problems, if the orderig of the fast states change during simulation
        int *sortedStates;
        if(ACTIVE_STREAM(LOG_MULTIRATE_V))
        {
          sortedStates = (int*) malloc(sizeof(int)*nStates);
          memcpy(sortedStates, gbData->sortedStates, sizeof(int)*nStates);
        }
        err_threshold = getErrorThreshold(gbData);
        if(ACTIVE_STREAM(LOG_MULTIRATE_V))
        {
          for (int k=0; k<nStates; k++)
            if (sortedStates[k] - gbData->sortedStates[k]) {
              printIntVector_gb("sortedStates before:", sortedStates, nStates, gbData->time);
              printIntVector_gb("sortedStates after:", gbData->sortedStates, nStates, gbData->time);
              break;
            }
            free(sortedStates);
        }
        //Find fast and slow states based on
        gbData->nFastStates = 0;
        gbData->nSlowStates = 0;
        gbData->err_slow = 0;
        gbData->err_fast = 0;
        for (i=0; i<gbData->nStates; i++)
        {
          if (gbData->err[i]>=err_threshold || gbData->percentage==1)
          {
            gbData->fastStates[gbData->nFastStates] = i;
            gbData->nFastStates++;
            gbData->err_fast = fmax(gbData->err_fast, gbData->err[i]);
          }
          else
          {
            gbData->slowStates[gbData->nSlowStates] = i;
            gbData->nSlowStates++;
            gbData->err_slow = fmax(gbData->err_slow, gbData->err[i]);
          }
        }
        err = gbData->err_slow;
      }

      gbData->errValues[0]      =  err;
      gbData->stepSizeValues[0] = gbData->stepSize;

      // see Hairer book II, Seite 124 ....
      // step_values[0] =
      // step_values[1] =

      // Store performed stepSize for adjusting the time and interpolation purposes
      // gbData->stepSize_old = gbData->lastStepSize;
      gbData->lastStepSize = gbData->stepSize;

      // store right hand values for interpolation in the inner integration
      gbData->timeRight    = gbData->time + gbData->stepSize;
      memcpy(gbData->yRight, gbData->y, nStates * sizeof(double));

      // Call the step size control
      gbData->stepSize *= gbData->stepSize_control(gbData->errValues, gbData->stepSizeValues, gbData->tableau->error_order);

      if (gbData->multi_rate)
      {
        if (gbData->nFastStates>0  && gbData->err_fast >= 0)
        {
          if (gbodef_step(data, threadData, solverInfo, targetTime))
            return 0;
          err = gbData->err_fast;
        }
      }
      if (err>1)
      {
        gbData->errorTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "reject step from %10g to %10g, error %10g, new stepsize %10g",
                        gbData->time, gbData->time + gbData->lastStepSize, err, gbData->stepSize);
      }
      else
      {
        // BB ToDo: check if this is appropriate
        gbData->stepSize = fmin(gbData->stepSize, stopTime - (gbData->time + gbData->lastStepSize));
      }

    } while  (err>1);
    gbData->stepsDone += 1;

    // Rotate ring buffer
    for (i=0; i<(gbData->ringBufferSize-1); i++) {
      gbData->errValues[i+1] = gbData->errValues[i];
      gbData->stepSizeValues[i+1] = gbData->stepSizeValues[i];
    }

    if (gbData->type == MS_TYPE_IMPLICIT) {
      for (int stage_=0; stage_< (gbData->tableau->nStages-1); stage_++) {
        memcpy(gbData->k + stage_ * nStates, gbData->k + (stage_+1) * nStates, nStates*sizeof(double));
        memcpy(gbData->x + stage_ * nStates, gbData->x + (stage_+1) * nStates, nStates*sizeof(double));
      }
    }


    if (!gbData->multi_rate || !gbData->percentage)
    {
      eventTime = checkForEvents(data, threadData, solverInfo, gbData->time, gbData->yOld, gbData->time + gbData->lastStepSize, gbData->y);
      if (eventTime > 0)
      {
        solverInfo->currentTime = eventTime;
        sData->timeValue = eventTime;

        // sData->realVars are the "numerical" values on the right hand side of the event
        gbData->time = eventTime;
        memcpy(gbData->yOld, sData->realVars, gbData->nStates * sizeof(double));
        // printVector_gb("y:    ", gbData->y, nStates, gbData->time);
        if(ACTIVE_STREAM(LOG_MULTIRATE))
        {
          printIntVector_gb("fast states:", gbData->fastStates, gbData->nFastStates, solverInfo->currentTime);
          printVector_gb("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
          messageClose(LOG_MULTIRATE);
        }
        if (!gbData->multi_rate || (gbData->multi_rate && !gbData->percentage))
        {
            /* write statistics to the solverInfo data structure */
          solverInfo->solverStatsTmp[0] = gbData->stepsDone;
          solverInfo->solverStatsTmp[1] = gbData->evalFunctionODE;
          solverInfo->solverStatsTmp[2] = gbData->evalJacobians;
          solverInfo->solverStatsTmp[3] = gbData->errorTestFailures;
          solverInfo->solverStatsTmp[4] = gbData->convergenceFailures;
        }

        return 0;
      }
    }
    /* update time with performed stepSize */
    gbData->time += gbData->lastStepSize;

    if(ACTIVE_STREAM(LOG_MULTIRATE))
    {
      printVector_gb("gb->y:    ", gbData->y, gbData->nStates, gbData->time);
    }


    // printVector_gb("yOld", gbData->yOld, gbData->nStates, gbData->time - gbData->lastStepSize);
    // printVector_gb("y   ", gbData->y, gbData->nStates, gbData->time);
    /* step is accepted and yOld needs to be updated */
    memcpy(gbData->yOld, gbData->y, data->modelData->nStates*sizeof(double));
    infoStreamPrint(LOG_SOLVER, 0, "accept step from %10g to %10g, error %10g, new stepsize %10g",
                    gbData->time- gbData->lastStepSize, gbData->time, err, gbData->stepSize);

    /* emit step, if integratorSteps is selected */
    if (solverInfo->integratorSteps  && !gbData->multi_rate)
    {
      sData->timeValue = gbData->time;
      solverInfo->currentTime = sData->timeValue;
      memcpy(sData->realVars, gbData->y, data->modelData->nStates*sizeof(double));
      /*
       * to emit consistent value we need to update the whole
       * continuous system with algebraic variables.
       */
      data->callback->updateContinuousSystem(data, threadData);
      sim_result.emit(&sim_result, data, threadData);
    }
    if ((stopTime - gbData->time) < DASSL_STEP_EPS){
      gbData->time = stopTime;
      break;
    }
  } // end of while-loop (gbData->time < targetTime)

  if(ACTIVE_STREAM(LOG_MULTIRATE_V))
  {
    printf("\n");
  }

  if (!solverInfo->integratorSteps)
  {
    /* Integrator does large steps and needs to interpolate results with respect to the output grid */
    sData->timeValue = sDataOld->timeValue + solverInfo->currentStepSize;
    solverInfo->currentTime = sData->timeValue;
    if (gbData->multi_rate) {
      // interpolating fast states if multirate method is used
      linear_interpolation_gbf(gbData->gbfData->time-gbData->gbfData->lastStepSize, gbData->gbfData->yt,
                              gbData->gbfData->time, gbData->gbfData->y,
                              sData->timeValue, sData->realVars,
                              gbData->nFastStates, gbData->fastStates);

    }

    // interpolating slow states if multirate method is used, otherwise all states are slow states
    linear_interpolation_gbf(gbData->timeLeft, gbData->yLeft,
                          gbData->timeRight, gbData->y,
                          sData->timeValue, sData->realVars,
                          gbData->nSlowStates, gbData->slowStates);
    if(ACTIVE_STREAM(LOG_MULTIRATE))
    {
      printIntVector_gb("fast states:", gbData->fastStates, gbData->nFastStates, solverInfo->currentTime);
      printVector_gb("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
      messageClose(LOG_MULTIRATE);
    }
  }else{
    // Integrator emits result on the simulation grid
    sData->timeValue = gbData->time;
    solverInfo->currentTime = gbData->time;
  }

  /* if a state event occurs than no sample event does need to be activated  */
  if (data->simulationInfo->sampleActivated && solverInfo->currentTime < data->simulationInfo->nextSampleEvent)
  {
    data->simulationInfo->sampleActivated = 0;
  }

  /* Solver statistics */
  if(ACTIVE_STREAM(LOG_SOLVER_V))
  {
    infoStreamPrint(LOG_SOLVER_V, 1, "gm call statistics: ");
    infoStreamPrint(LOG_SOLVER_V, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_SOLVER_V, 0, "current integration time value: %0.4g", gbData->time);
    infoStreamPrint(LOG_SOLVER_V, 0, "step size h to be attempted on next step: %0.4g", gbData->stepSize);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of steps taken so far: %d", gbData->stepsDone);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calls of functionODE() : %d", gbData->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calculation of jacobian : %d", gbData->evalJacobians);
    infoStreamPrint(LOG_SOLVER_V, 0, "error test failure : %d", gbData->errorTestFailures);
    infoStreamPrint(LOG_SOLVER_V, 0, "convergence failure : %d", gbData->convergenceFailures);
    messageClose(LOG_SOLVER_V);
  }

  if (!gbData->multi_rate || (gbData->multi_rate && !gbData->percentage))
  {
      /* write statistics to the solverInfo data structure */
    solverInfo->solverStatsTmp[0] = gbData->stepsDone;
    solverInfo->solverStatsTmp[1] = gbData->evalFunctionODE;
    solverInfo->solverStatsTmp[2] = gbData->evalJacobians;
    solverInfo->solverStatsTmp[3] = gbData->errorTestFailures;
    solverInfo->solverStatsTmp[4] = gbData->convergenceFailures;
  }

  infoStreamPrint(LOG_SOLVER, 0, "finished gm step.");
  messageClose(LOG_SOLVER);
  return 0;
}

#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))

double getErrorThreshold(DATA_GBODE* gbData)
{
  int i, j, temp;

  for (i = 0;  i < gbData->nStates - 1; i++)
  {
    for (j = 0; j < gbData->nStates - i - 1; j++)
    {
      if (gbData->err[gbData->sortedStates[j]] < gbData->err[gbData->sortedStates[j+1]])
      {
        temp = gbData->sortedStates[j];
        gbData->sortedStates[j] = gbData->sortedStates[j+1];
        gbData->sortedStates[j+1] = temp;
      }
    }
  }
  i = MIN(MAX(ceil((gbData->nStates - 1) * gbData->percentage), 0), gbData->nStates - 1);

  // BB ToDo: check, if 0.1 is ok, or should be parameterized
  return fmax(gbData->err[i], 0.1);
}

// TODO AHeu: For sure there is already a linear interpolation function somewhere
//auxiliary vector functions for better code structure
void linear_interpolation_gb(double ta, double* fa, double tb, double* fb, double t, double* f, int n)
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

//auxiliary vector functions for better code structure
void hermite_interpolation(double ta, double* fa, double* dfa, double tb, double* fb, double* dfb, double t, double* f, int n)
{
  double tt, h00, h01, h10, h11;
  int i;

  tt = (t-ta)/(tb-ta);
  h00 = (1+2*tt)*(1-tt)*(1-tt);
  h10 = (tb-ta)*tt*(1-tt)*(1-tt);
  h01 = (3-2*tt)*tt*tt;
  h11 = (tb-ta)*(tt-1)*tt*tt;

  for (i=0; i<n; i++)
  {
    f[i] = h00*fa[i]+h10*dfa[i]+h01*fb[i]+h11*dfb[i];
  }
}

void printVector_gb(char name[], double* a, int n, double time)
{
  printf("%s\t(time = %14.8g):", name, time);
  for (int i=0;i<n;i++)
    printf("%16.12g ", a[i]);
  printf("\n");
}

void printIntVector_gb(char name[], int* a, int n, double time)
{
  printf("%s\t(time = %g): \n", name, time);
  for (int i=0;i<n;i++)
    printf("%d ", a[i]);
  printf("\n");
}

void copyVector_gbf(double* a, double* b, int nIndx, int* indx)
{
  for (int i=0;i<nIndx;i++)
    a[indx[i]] = b[indx[i]];
}


void printMatrix_gb(char name[], double* a, int n, double time)
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
