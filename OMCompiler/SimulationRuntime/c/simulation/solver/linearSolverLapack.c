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

/*! \file nonlinear_solver.c
 */

#include <math.h>
#include <stdlib.h>
#include <string.h> /* memcpy */

#include "../../simulation_data.h"
#include "../simulation_info_json.h"
#include "../jacobian_util.h"
#include "../../util/omc_error.h"
#include "../../util/parallel_helper.h"
#include "omc_math.h"
#include "../../util/varinfo.h"
#include "model_help.h"

#include "linearSystem.h"
#include "linearSolverLapack.h"

#ifdef USE_PARJAC
  #include <omp.h>
#endif

extern int dgesv_(int *n, int *nrhs, double *a, int *lda,
                  int *ipiv, double *b, int *ldb, int *info);

extern int dgetrs_(char* tran, int *n, int *nrhs, double *a, int *lda,
                  int *ipiv, double *b, int *ldb, int *info);
/*! \fn allocate memory for linear system solver lapack
 *
 */
int allocateLapackData(int size, void** voiddata)
{
  DATA_LAPACK* data = (DATA_LAPACK*) calloc(1, sizeof(DATA_LAPACK));

  data->ipiv = (int*) calloc(size, sizeof(int));
  assertStreamPrint(NULL, 0 != data->ipiv, "Could not allocate data for linear solver lapack.");
  data->nrhs = 1;
  data->info = 0;
  data->work = _omc_allocateVectorData(size);

  data->x = _omc_createVector(size, NULL);
  data->b = _omc_createVector(size, NULL);
  data->A = _omc_createMatrix(size, size, NULL);

  *voiddata = (void*)data;
  return 0;
}

/*! \fn free memory of lapack
 *
 */
int freeLapackData(void **voiddata)
{
  DATA_LAPACK* data = (DATA_LAPACK*) *voiddata;

  free(data->ipiv);
  _omc_deallocateVectorData(data->work);

  _omc_destroyVector(data->x);
  _omc_destroyVector(data->b);
  _omc_destroyMatrix(data->A);

  free(data);
  voiddata[0] = NULL;

  return 0;
}

/*! \fn getAnalyticalJacobian
 *
 *  function calculates analytical jacobian
 *
 *  \param [ref] [data]
 *  \param [out] [jac]
 *
 *  \author wbraun
 *
 */
void getAnalyticalJacobianLapack(DATA* data, threadData_t *threadData, LINEAR_SYSTEM_DATA* systemData, double* jac)
{
  int k;
  JACOBIAN* jacobian = systemData->parDynamicData[omc_get_thread_num()].jacobian;
  JACOBIAN* parentJacobian = systemData->parDynamicData[omc_get_thread_num()].parentJacobian;

  /* call generic dense Jacobian */
  evalJacobianDense(data, threadData, jacobian, parentJacobian, jac);

  for (k = 0; k < (jacobian->sizeRows) * (jacobian->sizeCols); k++)
    jac[k] = -jac[k];
}

/*! \fn wrapper_fvec_lapack for the residual function
 *
 */
static int wrapper_fvec_lapack(_omc_vector* x, _omc_vector* f, int* iflag, RESIDUAL_USERDATA* resUserData, int sysNumber)
{
  resUserData->data->simulationInfo->linearSystemData[sysNumber].residualFunc(resUserData, x->data, f->data, iflag);
  return 0;
}

/*! \fn solve linear system with lapack method
 *
 *  \param [in]  [data]
 *               [sysNumber] index of the corresponding linear system
 *
 *  \author wbraun
 */
int solveLapack(DATA *data, threadData_t *threadData, int sysNumber, double* aux_x)
{
  RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=NULL};
  int i, iflag = 1;
  LINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->linearSystemData[sysNumber]);

  DATA_LAPACK* solverData = (DATA_LAPACK*) systemData->parDynamicData[omc_get_thread_num()].solverData[0];
  int success = 1;

  /* We are given the number of the linear system.
   * We want to look it up among all equations. */
  int eqSystemNumber = systemData->equationIndex;
  int indexes[2] = {1,eqSystemNumber};
  _omc_scalar residualNorm = 0;
  double tmpJacEvalTime;
  int reuseMatrixJac = (data->simulationInfo->currentContext == CONTEXT_SYM_JACOBIAN && data->simulationInfo->currentJacobianEval > 0);

  infoStreamPrintWithEquationIndexes(OMC_LOG_LS, omc_dummyFileInfo, 0, indexes,
    "Start solving Linear System %d (size %d) at time %g with Lapack Solver",
    eqSystemNumber, (int) systemData->size, data->localData[0]->timeValue);

  /* set data */
  _omc_setVectorData(solverData->x, aux_x);
  _omc_setVectorData(solverData->b, systemData->parDynamicData[omc_get_thread_num()].b);
  _omc_setMatrixData(solverData->A, systemData->parDynamicData[omc_get_thread_num()].A);

  // ToDo: Make time variables thread safe as this can be called in a parallel region
  rt_ext_tp_tick(&(solverData->timeClock));
  if (0 == systemData->method) {

    if (!reuseMatrixJac) {
      /* reset matrix A */
      memset(systemData->parDynamicData[omc_get_thread_num()].A, 0, (systemData->size)*(systemData->size)*sizeof(double));
      /* update matrix A */
      systemData->setA(data, threadData, systemData);
    }

    /* update vector b (rhs) */
    systemData->setb(data, threadData, systemData);
  } else {
    if (!reuseMatrixJac) {
      /* calculate jacobian -> matrix A*/
      if(systemData->jacobianIndex != -1) {
        getAnalyticalJacobianLapack(data, threadData, systemData, solverData->A->data);
      } else {
        assertStreamPrint(threadData, 1, "jacobian function pointer is invalid" );
      }
    }
    /* calculate vector b (rhs) */
    _omc_copyVector(solverData->work, solverData->x);

    wrapper_fvec_lapack(solverData->work, solverData->b, &iflag, &resUserData, sysNumber);
  }
  tmpJacEvalTime = rt_ext_tp_tock(&(solverData->timeClock));
  systemData->jacobianTime += tmpJacEvalTime;
  infoStreamPrint(OMC_LOG_LS_V, 0, "###  %f  time to set Matrix A and vector b.", tmpJacEvalTime);

  /* Log A*x=b */
  if(OMC_ACTIVE_STREAM(OMC_LOG_LS_V)){
    _omc_printVector(solverData->x, "Vector old x", OMC_LOG_LS_V);
    _omc_printMatrix(solverData->A, "Matrix A", OMC_LOG_LS_V);
    _omc_printVector(solverData->b, "Vector b", OMC_LOG_LS_V);
  }

  rt_ext_tp_tick(&(solverData->timeClock));

  /* if reuseMatrixJac use also previous factorization */
  if (!reuseMatrixJac)
  {
    /* Solve system */
    dgesv_((int*) &systemData->size,
           (int*) &solverData->nrhs,
           solverData->A->data,
           (int*) &systemData->size,
           solverData->ipiv,
           solverData->b->data,
           (int*) &systemData->size,
           &solverData->info);

  } /* further Jacobian evaluations */
  else
  {
    char trans = 'N';
    /* Solve system */
    dgetrs_(&trans,
            (int*) &systemData->size,
            (int*) &solverData->nrhs,
            solverData->A->data,
            (int*) &systemData->size,
            solverData->ipiv,
            solverData->b->data,
            (int*) &systemData->size,
            &solverData->info);
  }


  infoStreamPrint(OMC_LOG_LS_V, 0, "Solve System: %f", rt_ext_tp_tock(&(solverData->timeClock)));

  if(solverData->info < 0)
  {
    warningStreamPrint(OMC_LOG_LS, 0, "Error solving linear system of equations (no. %d) at time %f. Argument %d illegal.", (int)systemData->equationIndex, data->localData[0]->timeValue, (int)solverData->info);
    success = 0;
  }
  else if(solverData->info > 0)
  {
    warningStreamPrintWithLimit(OMC_LOG_LS, 0, ++(systemData->numberOfFailures) /* Update counter */, data->simulationInfo->maxWarnDisplays,
                                "Failed to solve linear system of equations (no. %d) at time %f, system is singular for U[%d, %d].",
                                (int)systemData->equationIndex, data->localData[0]->timeValue, (int)solverData->info+1, (int)solverData->info+1);

    success = 0;

    /* debug output */
    if (OMC_ACTIVE_STREAM(OMC_LOG_LS)){
      _omc_printMatrix(solverData->A, "Matrix U", OMC_LOG_LS);

      _omc_printVector(solverData->b, "Output vector x", OMC_LOG_LS);
    }
  }

  if (1 == success){

    if (1 == systemData->method){
      /* take the solution */
      solverData->x = _omc_addVectorVector(solverData->x, solverData->work, solverData->b); // x = xold(work) + xnew(b)

      /* update inner equations */
      wrapper_fvec_lapack(solverData->x, solverData->work, &iflag, &resUserData, sysNumber);
      residualNorm = _omc_euclideanVectorNorm(solverData->work);

      if ((isnan(residualNorm)) || (residualNorm>1e-4)){
        warningStreamPrintWithLimit(OMC_LOG_LS, 0, ++(systemData->numberOfFailures) /* Update counter */, data->simulationInfo->maxWarnDisplays,
                                    "Failed to solve linear system of equations (no. %d) at time %f. Residual norm is %.15g.",
                                    (int)systemData->equationIndex, data->localData[0]->timeValue, residualNorm);
        success = 0;
      }
    } else {
      /* take the solution */
      _omc_copyVector(solverData->x, solverData->b);
    }

    if (OMC_ACTIVE_STREAM(OMC_LOG_LS_V)){
        if (1 == systemData->method) {
          infoStreamPrint(OMC_LOG_LS_V, 1, "Residual Norm %.15g of solution x:", residualNorm);
        } else {
          infoStreamPrint(OMC_LOG_LS_V, 1, "Solution x:");
        }
      infoStreamPrint(OMC_LOG_LS_V, 0, "System %d numVars %d.", eqSystemNumber, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).numVar);

      for(i = 0; i < systemData->size; ++i) {
        infoStreamPrint(OMC_LOG_LS_V, 0, "[%d] %s = %.15g", i+1, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i], aux_x[i]);
      }

      messageClose(OMC_LOG_LS_V);
    }
  }

  return success;
}
