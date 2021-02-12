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

/*! \file linearSolverUmfpack.c
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
#include "linearSolverUmfpack.h"

void printMatrixCSC(int* Ap, int* Ai, double* Ax, int n);
void printMatrixCSR(int* Ap, int* Ai, double* Ax, int n);
int solveSingularSystem(LINEAR_SYSTEM_DATA* systemData, double* aux_x);

/*! \fn allocate memory for linear system solver UmfPack
 *
 */
int
allocateUmfPackData(int n_row, int n_col, int nz, void** voiddata)
{
  DATA_UMFPACK* data = (DATA_UMFPACK*) malloc(sizeof(DATA_UMFPACK));
  assertStreamPrint(NULL, 0 != data, "Could not allocate data for linear solver UmfPack.");

  data->symbolic = NULL;
  data->numeric = NULL;

  data->n_col = n_col;
  data->n_row = n_row;
  data->nnz = nz;


  data->Ap = (int*) calloc((n_row+1),sizeof(int));

  data->Ai = (int*) calloc(nz,sizeof(int));
  data->Ax = (double*) calloc(nz,sizeof(double));
  data->work = (double*) calloc(n_col,sizeof(double));

  data->Wi = (int*) malloc(n_row * sizeof(int));
  data->W = (double*) malloc(5*n_row * sizeof(double));

  data->numberSolving=0;
  umfpack_di_defaults(data->control);

  data->control[UMFPACK_PIVOT_TOLERANCE] = 0.1;
  data->control[UMFPACK_IRSTEP] = 2;
  data->control[UMFPACK_SCALE] = 1;
  data->control[UMFPACK_STRATEGY] = 5;



  *voiddata = (void*)data;

  return 0;
}


/*! \fn free memory for linear system solver UmfPack
 *
 */
int
freeUmfPackData(void **voiddata)
{
  TRACE_PUSH

  DATA_UMFPACK* data = (DATA_UMFPACK*) *voiddata;

  free(data->Ap);
  free(data->Ai);
  free(data->Ax);
  free(data->work);

  free(data->Wi);
  free(data->W);

  if(data->symbolic)
    umfpack_di_free_symbolic (&data->symbolic);
  if(data->numeric)
    umfpack_di_free_numeric (&data->numeric);

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
int getAnalyticalJacobianUmfPack(DATA* data, threadData_t *threadData, int sysNumber)
{
  int i,ii,j,k,l;
  LINEAR_SYSTEM_DATA* systemData = &(((DATA*)data)->simulationInfo->linearSystemData[sysNumber]);

  const int index = systemData->jacobianIndex;
  ANALYTIC_JACOBIAN* jacobian = systemData->parDynamicData[omc_get_thread_num()].jacobian;
  ANALYTIC_JACOBIAN* parentJacobian = systemData->parDynamicData[omc_get_thread_num()].parentJacobian;

  int nth = 0;
  int nnz = jacobian->sparsePattern->numberOfNoneZeros;

  for(i=0; i < jacobian->sizeRows; i++)
  {
    jacobian->seedVars[i] = 1;

    ((systemData->analyticalJacobianColumn))(data, threadData, jacobian, parentJacobian);

    for(j = 0; j < jacobian->sizeCols; j++)
    {
      if(jacobian->seedVars[j] == 1)
      {
        ii = jacobian->sparsePattern->leadindex[j];
        while(ii < jacobian->sparsePattern->leadindex[j+1])
        {
          l  = jacobian->sparsePattern->index[ii];
          /* infoStreamPrint(LOG_LS_V, 0, "set on Matrix A (%d, %d)(%d) = %f", i, l, nth, -jacobian->resultVars[l]); */
          systemData->setAElement(i, l, -jacobian->resultVars[l], nth, (void*) systemData, threadData);
          nth++;
          ii++;
        };
      }
    };

    /* de-activate seed variable for the corresponding color */
    jacobian->seedVars[i] = 0;
  }

  return 0;
}

/*! \fn wrapper_fvec_umfpack for the residual function
 *
 */
static int wrapper_fvec_umfpack(double* x, double* f, void** data, int sysNumber)
{
  int iflag = 0;

  (*((DATA*)data[0])->simulationInfo->linearSystemData[sysNumber].residualFunc)(data, x, f, &iflag);
  return 0;
}

/*! \fn solve linear system with UmfPack method
 *
 *  \param  [in]  [data]
 *                [sysNumber] index of the corresponding linear system
 *
 *
 * author: kbalzereit, wbraun
 */
int
solveUmfPack(DATA *data, threadData_t *threadData, int sysNumber, double* aux_x)
{
  void *dataAndThreadData[2] = {data, threadData};
  LINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->linearSystemData[sysNumber]);
  DATA_UMFPACK* solverData = (DATA_UMFPACK*)systemData->parDynamicData[omc_get_thread_num()].solverData[0];
  _omc_scalar residualNorm = 0;

  int i, j, status = UMFPACK_OK, success = 0, ni=0, n = systemData->size, eqSystemNumber = systemData->equationIndex, indexes[2] = {1,eqSystemNumber};
  int casualTearingSet = systemData->strictTearingFunctionCall != NULL;
  double tmpJacEvalTime;
  int reuseMatrixJac = (data->simulationInfo->currentContext == CONTEXT_SYM_JACOBIAN && data->simulationInfo->currentJacobianEval > 0);

  infoStreamPrintWithEquationIndexes(LOG_LS, 0, indexes, "Start solving Linear System %d (size %d) at time %g with UMFPACK Solver",
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
        getAnalyticalJacobianUmfPack(data, threadData, sysNumber);
      } else {
        assertStreamPrint(threadData, 1, "jacobian function pointer is invalid" );
      }
      solverData->Ap[solverData->n_row] = solverData->nnz;
    }

    /* calculate vector b (rhs) */
    memcpy(solverData->work, aux_x, sizeof(double)*solverData->n_row);
    wrapper_fvec_umfpack(solverData->work, systemData->parDynamicData[omc_get_thread_num()].b, dataAndThreadData, sysNumber);
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

    for (i=0; i<solverData->n_row; i++) {
      // ToDo Rework stream prints like this one to work in parallel regions
      infoStreamPrint(LOG_LS_V, 0, "b[%d] = %e", i, systemData->parDynamicData[omc_get_thread_num()].b[i]);
    }
  }
  rt_ext_tp_tick(&(solverData->timeClock));

  /* symbolic pre-ordering of A to reduce fill-in of L and U */
  if (0 == solverData->numberSolving) {
    status = umfpack_di_symbolic(solverData->n_col, solverData->n_row, solverData->Ap, solverData->Ai, solverData->Ax, &(solverData->symbolic), solverData->control, solverData->info);
  }

  /* compute the LU factorization of A */
  /* if reuseMatrixJac use also previous factorization */
  if (!reuseMatrixJac)
  {
    if (0 == status){
      umfpack_di_free_numeric(&(solverData->numeric));
      status = umfpack_di_numeric(solverData->Ap, solverData->Ai, solverData->Ax, solverData->symbolic, &(solverData->numeric), solverData->control, solverData->info);
    }
  }

  if (0 == status){
    if (1 == systemData->method){
      status = umfpack_di_wsolve(UMFPACK_A, solverData->Ap, solverData->Ai, solverData->Ax, aux_x, systemData->parDynamicData[omc_get_thread_num()].b, solverData->numeric, solverData->control, solverData->info, solverData->Wi, solverData->W);
    } else {
      status = umfpack_di_wsolve(UMFPACK_Aat, solverData->Ap, solverData->Ai, solverData->Ax, aux_x, systemData->parDynamicData[omc_get_thread_num()].b, solverData->numeric, solverData->control, solverData->info, solverData->Wi, solverData->W);
    }
  }

  if (status == UMFPACK_OK){
    success = 1;
  }
  else if ((status == UMFPACK_WARNING_singular_matrix) && (casualTearingSet==0))
  {
    if (!solveSingularSystem(systemData, aux_x))
    {
      success = 1;
    }
  }
  infoStreamPrint(LOG_LS_V, 0, "Solve System: %f", rt_ext_tp_tock(&(solverData->timeClock)));

  /* print solution */
  if (1 == success){
    if (1 == systemData->method){
      /* take the solution */
      for(i = 0; i < solverData->n_row; ++i)
        aux_x[i] += solverData->work[i];

      /* update inner equations */
      wrapper_fvec_umfpack(aux_x, solverData->work, dataAndThreadData, sysNumber);
      residualNorm = _omc_gen_euclideanVectorNorm(solverData->work, solverData->n_row);

      if ((isnan(residualNorm)) || (residualNorm>1e-4)){
        warningStreamPrint(LOG_LS, 0,
            "Failed to solve linear system of equations (no. %d) at time %f. Residual norm is %.15g.",
            (int)systemData->equationIndex, data->localData[0]->timeValue, residualNorm);
        success = 0;
      }
    } else {
      /* the solution is automatically in x */
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

/*! \fn solve a singular linear system with UmfPack methods
 *
 *  \param  [in/out]  [systemData]
 *
 *
 *  solve even singular system
 *  (note that due to initialization A is given in its transposed form A^T)
 *
 *  A * x = b
 *  <=> P * R * A * Q * Q * x = P * R * b       |   P * R * A * Q = L * U
 *  <=> L * U * Q * x = P * R * b
 *
 *  note that P and Q are orthogonal permutation matrices, so P^(-1) = P^T and Q^(-1) = Q^T
 *
 *   (1) L * y = P * R * b  <=>  P^T * L * y = R * b     (L is always regular so this can be solved by umfpack)
 *
 *   (2) U * z = y      (U is singular, this cannot be solved by umfpack)
 *
 *   (3) Q * x = z  <=>  x = Q^T * z
 *
 *
 * author: kbalzereit, wbraun
 */
int solveSingularSystem(LINEAR_SYSTEM_DATA* systemData, double* aux_x)
{
  DATA_UMFPACK* solverData = (DATA_UMFPACK*) systemData->parDynamicData[omc_get_thread_num()].solverData[0];
  double *Ux, *Rs, r_ii, *b, sum, *y, *z;
  int *Up, *Ui, *Q, do_recip, rank = 0, current_rank, current_unz, i, j, k, l,
      success = 0, status, stop = 0;

  int unz = solverData->info[UMFPACK_UNZ];

  Up = (int*) malloc((solverData->n_row + 1) * sizeof(int));
  Ui = (int*) malloc(unz * sizeof(int));
  Ux = (double*) malloc(unz * sizeof(double));

  Q = (int*) malloc(solverData->n_col * sizeof(int));
  Rs = (double*) malloc(solverData->n_row * sizeof(double));

  b = (double*) malloc(solverData->n_col * sizeof(double));
  y = (double*) malloc(solverData->n_col * sizeof(double));
  z = (double*) malloc(solverData->n_col * sizeof(double));

  infoStreamPrint(LOG_LS_V, 0, "Solve singular system");

  status = umfpack_di_get_numeric((int*) NULL, (int*) NULL, (double*) NULL, Up,
      Ui, Ux, (int*) NULL, Q, (double*) NULL, &do_recip, Rs,
      solverData->numeric);

  switch (status)
  {
  case UMFPACK_WARNING_singular_matrix:
  case UMFPACK_ERROR_out_of_memory:
  case UMFPACK_ERROR_argument_missing:
  case UMFPACK_ERROR_invalid_system:
  case UMFPACK_ERROR_invalid_Numeric_object:
    infoStreamPrint(LOG_LS_V, 0, "error: %d", status);
  }

  /* calculate R*b */
  if (do_recip == 0)
  {
    for (i = 0; i < solverData->n_row; i++)
    {
      b[i] = systemData->parDynamicData[omc_get_thread_num()].b[i] / Rs[i];
    }
  }
  else
  {
    for (i = 0; i < solverData->n_row; i++) {
      b[i] = systemData->parDynamicData[omc_get_thread_num()].b[i] * Rs[i];
    }
  }

  /* solve L * y = P * R * b  <=>  P^T * L * y = R * b */
  status = umfpack_di_wsolve(UMFPACK_Pt_L, solverData->Ap, solverData->Ai,
      solverData->Ax, y, b, solverData->numeric, solverData->control,
      solverData->info, solverData->Wi, solverData->W);

  switch (status)
  {
  case UMFPACK_WARNING_singular_matrix:
  case UMFPACK_ERROR_out_of_memory:
  case UMFPACK_ERROR_argument_missing:
  case UMFPACK_ERROR_invalid_system:
  case UMFPACK_ERROR_invalid_Numeric_object:
    infoStreamPrint(LOG_LS_V, 0, "error: %d", status);
  }

  /* rank is at most as high as the maximum in Ui */
  for (i = 0; i < unz; i++)
  {
    if (rank < Ui[i])
      rank = Ui[i];
  }

  /* if rank is already smaller than n set last component of result zero */
  for (i = rank + 1; i < solverData->n_col; i++)
  {
    if (y[i] < 1e-12)
    {
      z[i] = 0.0;
    }
    else
    {
      infoStreamPrint(LOG_LS_V, 0, "error: system is not solvable*");
      /* free all used memory */
      free(Up);
      free(Ui);
      free(Ux);

      free(Q);
      free(Rs);

      free(b);
      free(y);
      free(z);
      return -1;
    }
  }

  current_rank = rank;
  current_unz = unz;

  while ((stop == 0) && (current_rank > 1))
  {
    /* check if last two rows of U are the same */
    if ((Ux[current_unz] == Ux[current_unz - 1])
        && (Ui[current_unz] == Ui[current_unz - 1])
        && (Up[current_rank] - Up[current_rank - 1] > 1))
    {
      /* if diagonal entry on second to last row is nonzero, remaining matrix is regular */
      if (Ui[Up[current_rank] - 1] == current_rank - 1)
      {
        stop = 1;
      }
      /* last two rows are the same -> under-determined system, calculate one value and set the other one zero */
      else
      {
        z[current_rank] = y[current_rank] / Ux[current_unz];

        /* reduce system */
        for (i = Up[current_rank]; i < current_unz; i++)
        {
          y[Ui[i]] -= z[current_rank] * Ux[i];
        }

        current_unz = Up[current_rank] - 1;
        current_rank--;

        /* now last row has only zero entries */
        if (y[current_rank] < 1e-12)
        {
          z[current_rank] = 0.0;
        }
        else
        {
          infoStreamPrint(LOG_LS_V, 0, "error: system is not solvable");
          /* free all used memory */
          free(Up);
          free(Ui);
          free(Ux);

          free(Q);
          free(Rs);

          free(b);
          free(y);
          free(z);
          return -1;
        }

        current_rank--;
      }
    }
    else
    {
      stop = 1;
    }
  }

  /* remaining system is regular so solve system by back substitution */
  z[current_rank] = Ux[current_unz] * y[current_rank];

  for (i = current_rank - 1; i >= 0; i--)
  {
    /* get diagonal element r_ii, j shows where the element is in vector Ux, Ui */
    j = Up[i];
    while (Ui[j] != i)
    {
      j++;
    }
    r_ii = Ux[j];
    sum = 0.0;
    for (k = i + 1; k < current_rank; k++)
    {
      for (l = Up[k]; l < Up[k + 1]; l++)
      {
        if (Ui[l] == Ui[i])
        {
          sum += Ux[i] * z[k];
        }
      }
    }
    z[i] = (y[i] - sum) / r_ii;
  }

  /* x = Q^T * z */
  for (i = 0; i < solverData->n_col; i++)
  {
    aux_x[Q[i]] = z[i];
  }

  /* free all used memory */
  free(Up);
  free(Ui);
  free(Ux);

  free(Q);
  free(Rs);

  free(b);
  free(y);
  free(z);

  return success;
}

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
  for (l=0; l<n; l++)
  {
    infoStreamPrint(LOG_LS_V, 0, "%s", buffer[l]);
    free(buffer[l]);
  }
  free(buffer);
}

void printMatrixCSR(int* Ap, int* Ai, double* Ax, int n)
{
  int i, j, k;
  char *buffer = (char*)malloc(sizeof(char)*n*20);
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
