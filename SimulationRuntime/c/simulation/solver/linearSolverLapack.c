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

#include "simulation_data.h"
#include "simulation/simulation_info_json.h"
#include "util/omc_error.h"
#include "omc_math.h"
#include "util/varinfo.h"
#include "model_help.h"

#include "linearSystem.h"
#include "linearSolverLapack.h"


extern int dgesv_(int *n, int *nrhs, double *a, int *lda,
                  int *ipiv, double *b, int *ldb, int *info);

/*! \fn allocate memory for linear system solver lapack
 *
 */
int allocateLapackData(int size, void** voiddata)
{
  DATA_LAPACK* data = (DATA_LAPACK*) malloc(sizeof(DATA_LAPACK));

  data->ipiv = (int*) malloc(size*sizeof(int));
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
int getAnalyticalJacobianLapack(DATA* data, threadData_t *threadData, double* jac, int sysNumber)
{
  int i,j,k,l,ii,currentSys = sysNumber;
  LINEAR_SYSTEM_DATA* systemData = &(((DATA*)data)->simulationInfo.linearSystemData[currentSys]);

  const int index = systemData->jacobianIndex;

  memset(jac, 0, (systemData->size)*(systemData->size)*sizeof(double));

  for(i=0; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors; i++)
  {
    /* activate seed variable for the corresponding color */
    for(ii=0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++)
      if(data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i)
        data->simulationInfo.analyticJacobians[index].seedVars[ii] = 1;

    ((systemData->analyticalJacobianColumn))(data, threadData);

    for(j = 0; j < data->simulationInfo.analyticJacobians[index].sizeCols; j++)
    {
      if(data->simulationInfo.analyticJacobians[index].seedVars[j] == 1)
      {
        if(j==0)
          ii = 0;
        else
          ii = data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex[j-1];
        while(ii < data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex[j])
        {
          l  = data->simulationInfo.analyticJacobians[index].sparsePattern.index[ii];
          k  = j*data->simulationInfo.analyticJacobians[index].sizeRows + l;
          jac[k] = -data->simulationInfo.analyticJacobians[index].resultVars[l];
          ii++;
        };
      }
      /* de-activate seed variable for the corresponding color */
      if(data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[j]-1 == i)
        data->simulationInfo.analyticJacobians[index].seedVars[j] = 0;
    }
  }

  return 0;
}

/*! \fn wrapper_fvec_lapack for the residual function
 *
 */
static int wrapper_fvec_lapack(_omc_vector* x, _omc_vector* f, int* iflag, void** data, int sysNumber)
{
  int currentSys = sysNumber;

  (*((DATA*)data[0])->simulationInfo.linearSystemData[currentSys].residualFunc)(data, x->data, f->data, iflag);
  return 0;
}

/*! \fn solve linear system with lapack method
 *
 *  \param [in]  [data]
 *               [sysNumber] index of the corresponding linear system
 *
 *  \author wbraun
 */
int solveLapack(DATA *data, threadData_t *threadData, int sysNumber)
{
  void *dataAndThreadData[2] = {data, threadData};
  int i, j, iflag = 1;
  LINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo.linearSystemData[sysNumber]);
  DATA_LAPACK* solverData = (DATA_LAPACK*)systemData->solverData;

  int success = 1;

  /* We are given the number of the linear system.
   * We want to look it up among all equations. */
  int eqSystemNumber = systemData->equationIndex;
  int indexes[2] = {1,eqSystemNumber};
  _omc_scalar residualNorm = 0;

  infoStreamPrintWithEquationIndexes(LOG_LS, 0, indexes, "Start solving Linear System %d (size %d) at time %g with Lapack Solver",
         eqSystemNumber, (int) systemData->size,
         data->localData[0]->timeValue);


  /* set data */
  _omc_setVectorData(solverData->x, systemData->x);
  _omc_setVectorData(solverData->b, systemData->b);
  _omc_setMatrixData(solverData->A, systemData->A);


  rt_ext_tp_tick(&(solverData->timeClock));
  if (0 == systemData->method) {

    /* reset matrix A */
    memset(systemData->A, 0, (systemData->size)*(systemData->size)*sizeof(double));

    /* update matrix A */
    systemData->setA(data, threadData, systemData);

    /* update vector b (rhs) */
    systemData->setb(data, threadData, systemData);
  } else {

    /* calculate jacobian -> matrix A*/
    if(systemData->jacobianIndex != -1){
      getAnalyticalJacobianLapack(data, threadData, solverData->A->data, sysNumber);
    } else {
      assertStreamPrint(threadData, 1, "jacobian function pointer is invalid" );
    }

    /* calculate vector b (rhs) */
    _omc_copyVector(solverData->work, solverData->x);
    wrapper_fvec_lapack(solverData->work, solverData->b, &iflag, dataAndThreadData, sysNumber);
  }
  infoStreamPrint(LOG_LS, 0, "###  %f  time to set Matrix A and vector b.", rt_ext_tp_tock(&(solverData->timeClock)));

  /* Log A*x=b */
  if(ACTIVE_STREAM(LOG_LS_V)){
    _omc_printVector(solverData->x, "Vector old x", LOG_LS_V);
    _omc_printMatrix(solverData->A, "Matrix A", LOG_LS_V);
    _omc_printVector(solverData->b, "Vector b", LOG_LS_V);
  }

  rt_ext_tp_tick(&(solverData->timeClock));

  /* Solve system */
  dgesv_((int*) &systemData->size,
         (int*) &solverData->nrhs,
         solverData->A->data,
         (int*) &systemData->size,
         solverData->ipiv,
         solverData->b->data,
         (int*) &systemData->size,
         &solverData->info);

  infoStreamPrint(LOG_LS, 0, "Solve System: %f", rt_ext_tp_tock(&(solverData->timeClock)));

  if(solverData->info < 0)
  {
    warningStreamPrint(LOG_LS, 0, "Error solving linear system of equations (no. %d) at time %f. Argument %d illegal.", (int)systemData->equationIndex, data->localData[0]->timeValue, (int)solverData->info);
    success = 0;
  }
  else if(solverData->info > 0)
  {
    warningStreamPrint(LOG_LS, 0,
        "Failed to solve linear system of equations (no. %d) at time %f, system is singular for U[%d, %d].",
        (int)systemData->equationIndex, data->localData[0]->timeValue, (int)solverData->info+1, (int)solverData->info+1);

    success = 0;

    /* debug output */
    if (ACTIVE_STREAM(LOG_LS)){
      _omc_printMatrix(solverData->A, "Matrix U", LOG_LS);

      _omc_printVector(solverData->b, "Output vector x", LOG_LS);
    }
  }

  if (1 == success){

    if (1 == systemData->method){
      /* take the solution */
      solverData->x = _omc_addVectorVector(solverData->x, solverData->work, solverData->b);

      /* update inner equations */
      wrapper_fvec_lapack(solverData->x, solverData->work, &iflag, dataAndThreadData, sysNumber);
      residualNorm = _omc_euclideanVectorNorm(solverData->work);
    } else {
      /* take the solution */
      _omc_copyVector(solverData->x, solverData->b);
    }

    if (ACTIVE_STREAM(LOG_LS_V)){
      infoStreamPrint(LOG_LS_V, 1, "Residual Norm %f of solution x:", residualNorm);
      infoStreamPrint(LOG_LS_V, 0, "System %d numVars %d.", eqSystemNumber, modelInfoGetEquation(&data->modelData.modelDataXml,eqSystemNumber).numVar);

      for(i = 0; i < systemData->size; ++i) {
        infoStreamPrint(LOG_LS_V, 0, "[%d] %s = %g", i+1, modelInfoGetEquation(&data->modelData.modelDataXml,eqSystemNumber).vars[i], systemData->x[i]);
      }

      messageClose(LOG_LS_V);
    }
  }

  return success;
}
