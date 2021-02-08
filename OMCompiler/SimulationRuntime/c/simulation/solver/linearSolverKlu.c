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

/*! \file linearSolverKlu.c
 */

#include "omc_config.h"

#ifdef WITH_SUITESPARSE
#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "simulation_data.h"
#include "simulation/simulation_info_json.h"
#include "util/omc_error.h"
#include "util/parallel_helper.h"
#include "omc_math.h"
#include "util/varinfo.h"
#include "model_help.h"

#include "linearSystem.h"
#include "linearSolverKlu.h"

static void printMatrixCSC(int* Ap, int* Ai, double* Ax, int n);
static void printMatrixCSR(int* Ap, int* Ai, double* Ax, int n);

/*! \fn allocate memory for linear system solver Klu
 *
 */
int allocateKluData(int n_row, int n_col, int nz, void** voiddata)
{
  DATA_KLU* data = (DATA_KLU*) malloc(sizeof(DATA_KLU));
  assertStreamPrint(NULL, 0 != data, "Could not allocate data for linear solver Klu.");

  data->symbolic = NULL;
  data->numeric = NULL;

  data->n_col = n_col;
  data->n_row = n_row;
  data->nnz = nz;

  data->Ap = (int*) calloc((n_row+1),sizeof(int));
  data->Ai = (int*) calloc(nz,sizeof(int));
  data->Ax = (double*) calloc(nz,sizeof(double));
  data->work = (double*) calloc(n_col,sizeof(double));

  data->numberSolving = 0;
  klu_defaults(&(data->common));

  *voiddata = (void*)data;

  return 0;
}


/*! \fn free memory for linear system solver Klu
 *
 */
int freeKluData(void **voiddata)
{
  TRACE_PUSH

  DATA_KLU* data = (DATA_KLU*) *voiddata;

  free(data->Ap);
  free(data->Ai);
  free(data->Ax);
  free(data->work);


  if(data->symbolic)
    klu_free_symbolic(&data->symbolic, &data->common);
  if(data->numeric)
    klu_free_numeric(&data->numeric, &data->common);

  TRACE_POP
  return 0;
}

/*! \fn getAnalyticalJacobian
 *
 *  function calculates analytical jacobian
 *
 *  \param [ref] [data]
 *  \param [in]  [sysNumber]
 *
 *  \author wbraun
 *
 */
static int getAnalyticalJacobian(DATA* data, threadData_t *threadData,
                                 int sysNumber)
{
  int i,ii,j,k,l;

  LINEAR_SYSTEM_DATA* systemData = &(((DATA*)data)->simulationInfo->linearSystemData[sysNumber]);

  const int index = systemData->jacobianIndex;
  ANALYTIC_JACOBIAN* jacobian = systemData->parDynamicData[omc_get_thread_num()].jacobian;
  ANALYTIC_JACOBIAN* parentJacobian = systemData->parDynamicData[omc_get_thread_num()].parentJacobian;

  int nth = 0;
  int nnz = jacobian->sparsePattern->numberOfNoneZeros;

  if (jacobian->constantEqns != NULL) {
    jacobian->constantEqns(data, threadData, jacobian, parentJacobian);
  }

  for(i=0; i < jacobian->sparsePattern->maxColors; i++)
  {
    /* activate seed variable for the corresponding color */
    for(ii=0; ii < jacobian->sizeCols; ii++)
    {
      if(jacobian->sparsePattern->colorCols[ii]-1 == i)
      {
        jacobian->seedVars[ii] = 1;
      }
    }

    ((systemData->analyticalJacobianColumn))(data, threadData, jacobian, parentJacobian);

    for(j = 0; j < jacobian->sizeCols; j++)
    {
      if(jacobian->seedVars[j] == 1)
      {
        nth = jacobian->sparsePattern->leadindex[j];
        while(nth < jacobian->sparsePattern->leadindex[j+1])
        {
          l  = jacobian->sparsePattern->index[nth];
          systemData->setAElement(j, l, -jacobian->resultVars[l], nth, (void*) systemData, threadData);
          nth++;
        }
        /* de-activate seed variable for the corresponding color */
        jacobian->seedVars[j] = 0;
      }
    }
  }
  return 0;
}

/*! \fn residual_wrapper for the residual function
 *
 */
static int residual_wrapper(double* x, double* f, void** data, int sysNumber)
{
  int iflag = 0;

  (*((DATA*)data[0])->simulationInfo->linearSystemData[sysNumber].residualFunc)(data, x, f, &iflag);
  return 0;
}

/*! \fn solve linear system with Klu method
 *
 *  \param  [in]  [data]
 *                [sysNumber] index of the corresponding linear system
 *
 *
 * author: wbraun
 */
int solveKlu(DATA *data, threadData_t *threadData, int sysNumber, double* aux_x)
{
  void *dataAndThreadData[2] = {data, threadData};
  LINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->linearSystemData[sysNumber]);
  DATA_KLU* solverData = (DATA_KLU*)systemData->parDynamicData[omc_get_thread_num()].solverData[0];
  _omc_scalar residualNorm = 0;

  int i, j, status = 0, success = 0, n = systemData->size, eqSystemNumber = systemData->equationIndex, indexes[2] = {1,eqSystemNumber};
  double tmpJacEvalTime;
  int reuseMatrixJac = (data->simulationInfo->currentContext == CONTEXT_SYM_JACOBIAN && data->simulationInfo->currentJacobianEval > 0);

  infoStreamPrintWithEquationIndexes(LOG_LS, 0, indexes, "Start solving Linear System %d (size %d) at time %g with Klu Solver",
   eqSystemNumber, (int) systemData->size,
   data->localData[0]->timeValue);

  rt_ext_tp_tick(&(solverData->timeClock));
  if (0 == systemData->method)
  {
    if (!reuseMatrixJac){
      /* set A matrix */
      solverData->Ap[0] = 0;
      systemData->setA(data, threadData, systemData);
      solverData->Ap[solverData->n_row] = solverData->nnz;
    }

    /* set b vector */
    systemData->setb(data, threadData, systemData);
  } else {

    if (!reuseMatrixJac){
      solverData->Ap[0] = 0;
      /* calculate jacobian -> matrix A*/
      if(systemData->jacobianIndex != -1){
        getAnalyticalJacobian(data, threadData, sysNumber);
      } else {
        assertStreamPrint(threadData, 1, "jacobian function pointer is invalid" );
      }
      solverData->Ap[solverData->n_row] = solverData->nnz;
    }

    /* calculate vector b (rhs) */
    memcpy(solverData->work, aux_x, sizeof(double)*solverData->n_row);

  residual_wrapper(solverData->work, systemData->parDynamicData[omc_get_thread_num()].b, dataAndThreadData, sysNumber);
  }
  tmpJacEvalTime = rt_ext_tp_tock(&(solverData->timeClock));
  systemData->jacobianTime += tmpJacEvalTime;
  infoStreamPrint(LOG_LS_V, 0, "###  %f  time to set Matrix A and vector b.", tmpJacEvalTime);

  if (ACTIVE_STREAM(LOG_LS_V))
  {
    infoStreamPrint(LOG_LS_V, 1, "Old solution x:");
    for(i = 0; i < solverData->n_row; ++i)
      infoStreamPrint(LOG_LS_V, 0, "[%d] %s = %g", i+1, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i], aux_x[i]);
    messageClose(LOG_LS_V);

    infoStreamPrint(LOG_LS_V, 1, "Matrix A n_rows = %d", solverData->n_row);
    for (i=0; i<solverData->n_row; i++){
      infoStreamPrint(LOG_LS_V, 0, "%d. Ap => %d -> %d", i, solverData->Ap[i], solverData->Ap[i+1]);
      for (j=solverData->Ap[i]; j<solverData->Ap[i+1]; j++){
        infoStreamPrint(LOG_LS_V, 0, "A[%d,%d] = %f", i, solverData->Ai[j], solverData->Ax[j]);
      }
    }
    messageClose(LOG_LS_V);

    for (i=0; i<solverData->n_row; i++)
    {
      // ToDo Rework stream prints like this one to work in parallel regions
      infoStreamPrint(LOG_LS_V, 0, "b[%d] = %e", i, systemData->parDynamicData[omc_get_thread_num()].b[i]);
    }
  }
  rt_ext_tp_tick(&(solverData->timeClock));

  /* symbolic pre-ordering of A to reduce fill-in of L and U */
  if (0 == solverData->numberSolving)
  {
    infoStreamPrint(LOG_LS_V, 0, "Perform analyze settings:\n - ordering used: %d\n - current status: %d", solverData->common.ordering, solverData->common.status);
    solverData->symbolic = klu_analyze(solverData->n_col, solverData->Ap, solverData->Ai, &solverData->common);
  }

  /* if reuseMatrixJac use also previous factorization */
  if (!reuseMatrixJac)
  {
    /* compute the LU factorization of A */
    if (0 == solverData->common.status){
      if(solverData->numeric){
        /* Just refactor using the same pivots, but check that the refactor is still accurate */
        klu_refactor(solverData->Ap, solverData->Ai, solverData->Ax, solverData->symbolic, solverData->numeric, &solverData->common);
        klu_rgrowth(solverData->Ap, solverData->Ai, solverData->Ax, solverData->symbolic, solverData->numeric, &solverData->common);
        infoStreamPrint(LOG_LS_V, 0, "Klu rgrowth after refactor: %f", solverData->common.rgrowth);
        /* If rgrowth is small then do a whole factorization with new pivots (What should this tolerance be?) */
        if (solverData->common.rgrowth < 1e-3){
          klu_free_numeric(&solverData->numeric, &solverData->common);
          solverData->numeric = klu_factor(solverData->Ap, solverData->Ai, solverData->Ax, solverData->symbolic, &solverData->common);
          infoStreamPrint(LOG_LS_V, 0, "Klu new factorization performed.");
        }
      } else {
        solverData->numeric = klu_factor(solverData->Ap, solverData->Ai, solverData->Ax, solverData->symbolic, &solverData->common);
      }
    }
  }

  if (0 == solverData->common.status){
    if (1 == systemData->method){
      if (klu_solve(solverData->symbolic, solverData->numeric, solverData->n_col, 1, systemData->parDynamicData[omc_get_thread_num()].b, &solverData->common)){
        success = 1;
      }
    } else {
      if (klu_tsolve(solverData->symbolic, solverData->numeric, solverData->n_col, 1, systemData->parDynamicData[omc_get_thread_num()].b, &solverData->common)){
        success = 1;
      }
    }
  }

  infoStreamPrint(LOG_LS_V, 0, "Solve System: %f", rt_ext_tp_tock(&(solverData->timeClock)));

  /* print solution */
  if (1 == success){

    if (1 == systemData->method){
      /* take the solution */
      for(i = 0; i < solverData->n_row; ++i)
        aux_x[i] += systemData->parDynamicData[omc_get_thread_num()].b[i];

      /* update inner equations */
      residual_wrapper(aux_x, solverData->work, dataAndThreadData, sysNumber);
      residualNorm = _omc_gen_euclideanVectorNorm(solverData->work, solverData->n_row);

      if ((isnan(residualNorm)) || (residualNorm>1e-4)){
        warningStreamPrint(LOG_LS, 0,
            "Failed to solve linear system of equations (no. %d) at time %f. Residual norm is %.15g.",
            (int)systemData->equationIndex, data->localData[0]->timeValue, residualNorm);
        success = 0;
      }
    } else {
      /* the solution is automatically in x */
      memcpy(aux_x, systemData->parDynamicData[omc_get_thread_num()].b, sizeof(double)*systemData->size);
    }

    if (ACTIVE_STREAM(LOG_LS_V))
    {
      if (1 == systemData->method) {
        infoStreamPrint(LOG_LS_V, 1, "Residual Norm %.15g of solution x:", residualNorm);
      } else {
        infoStreamPrint(LOG_LS_V, 1, "Solution x:");
      }
      infoStreamPrint(LOG_LS_V, 0, "System %d numVars %d.", eqSystemNumber, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).numVar);

      for(i = 0; i < systemData->size; ++i)
        infoStreamPrint(LOG_LS_V, 0, "[%d] %s = %g", i+1, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i], aux_x[i]);

      messageClose(LOG_LS_V);
    }
  }
  else
  {
    warningStreamPrint(LOG_STDOUT, 0,
      "Failed to solve linear system of equations (no. %d) at time %f, system status %d.",
        (int)systemData->equationIndex, data->localData[0]->timeValue, status);
  }
  solverData->numberSolving += 1;

  return success;
}

static
void printMatrixCSC(int* Ap, int* Ai, double* Ax, int n)
{
  int i, j, k, l;

  char **buffer = (char**)malloc(sizeof(char*)*n);
  for (l=0; l<n; l++)
  {
    buffer[l] = (char*)malloc(sizeof(char)*n*20);
    buffer[l][0] = 0;
  }

  k = 0;
  for (i = 0; i < n; i++)
  {
    for (j = 0; j < n; j++)
    {
      if ((k < Ap[i + 1]) && (Ai[k] == j))
      {
        sprintf(buffer[j], "%s %5g ", buffer[j], Ax[k]);
        k++;
      }
      else
      {
        sprintf(buffer[j], "%s %5g ", buffer[j], 0.0);
      }
    }
  }
  for (l = 0; l < n; l++)
  {
    infoStreamPrint(LOG_LS_V, 0, "%s", buffer[l]);
    free(buffer[l]);
  }
  free(buffer);
}

static
void printMatrixCSR(int* Ap, int* Ai, double* Ax, int n)
{
  int i, j, k;
  char *buffer = (char*)malloc(sizeof(char)*n*15);
  k = 0;
  for (i = 0; i < n; i++)
  {
    buffer[0] = 0;
    for (j = 0; j < n; j++)
    {
      if ((k < Ap[i + 1]) && (Ai[k] == j))
      {
        sprintf(buffer, "%s %5.2g ", buffer, Ax[k]);
        k++;
      }
      else
      {
        sprintf(buffer, "%s %5.2g ", buffer, 0.0);
      }
    }
    infoStreamPrint(LOG_LS_V, 0, "%s", buffer);
  }
  free(buffer);
}

#endif
