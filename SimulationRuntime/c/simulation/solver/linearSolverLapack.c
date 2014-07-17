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
#include "simulation_info_xml.h"
#include "omc_error.h"
#include "varinfo.h"
#include "model_help.h"

#include "linearSystem.h"
#include "linearSolverLapack.h"
#include "blaswrap.h"


extern int dgesv_(int *n, int *nrhs, double *a, int *lda,
                  int *ipiv, double *b, int *ldb, int *info);
extern double enorm_(int *n, double *x);

typedef struct DATA_LAPACK
{
  int *ipiv;  /* vector pivot values */
  int nrhs;   /* number of righthand sides*/
  int info;   /* output */
  double* work;
} DATA_LAPACK;

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
  data->work = (double*) malloc(size*sizeof(double));

  *voiddata = (void*)data;
  return 0;
}

/*! \fn free memory for nonlinear solver hybrd
 *
 */
int freeLapackData(void **voiddata)
{
  DATA_LAPACK* data = (DATA_LAPACK*) *voiddata;

  free(data->ipiv);
  free(data->work);

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
int getAnalyticalJacobianLapack(DATA* data, double* jac, int sysNumber)
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

    ((systemData->analyticalJacobianColumn))(data);

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
          jac[k] = data->simulationInfo.analyticJacobians[index].resultVars[l];
          ii++;
        };
      }
      /* de-activate seed variable for the corresponding color */
      if(data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[j]-1 == i)
        data->simulationInfo.analyticJacobians[index].seedVars[j] = 0;
    }

  }

  /* debug output */
  if(ACTIVE_STREAM(LOG_LS))
  {
    printf("Print analytical jac:\n");
    for(l=0;  l < data->simulationInfo.analyticJacobians[index].sizeCols;l++)
    {
      for(k=0;  k < data->simulationInfo.analyticJacobians[index].sizeRows;k++)
        printf("% .5e ",jac[l+k*data->simulationInfo.analyticJacobians[index].sizeRows]);
      printf("\n");
    }
  }

  return 0;
}

/*! \fn fdjac
 *
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 */
static int fdjacLinear(modelica_integer* n, int(*f)(double*, double*, int*, void*, int), double *x,
       double* fvec, double *fjac, double* eps, int* iflag, double* wa,
       void* userdata, int sysNumber)
{
  double delta_h = sqrt(*eps);
  double delta_hh;
  double delta_hhh;
  double xsave;

  int i,j,l;

  for(i = 0; i < *n; i++) {
    /* delta_h == 1, since linear case */
    delta_hh = 1;
    xsave = x[i];
    x[i] += delta_hh;
    delta_hh = 1. / delta_hh;
    f(x, wa, iflag, userdata, sysNumber);

    for(j = 0; j < *n; j++) {
      l = i * *n + j;
      fjac[l] = (wa[j] - fvec[j]) * delta_hh;
    }
    x[i] = xsave;
  }

  /* debug output */
  if(ACTIVE_STREAM(LOG_LS))
  {
    int l,k;
    printf("Print numerical jac:\n");
    for(l=0;  l < *n;l++)
    {
      for(k=0;  k < *n;k++)
        printf("% .5e ", fjac[l+k * *n]);
      printf("\n");
    }
  }

  return *iflag;
}

/*! \fn wrapper_fvec_hybrd for the residual Function
 *   tensolve calls for the subroutine fcn(n, x, fvec, iflag, data)
 *
 *
 */
static int wrapper_fvec_lapack(double* x, double* f, int* iflag, void* data, int sysNumber)
{
  int currentSys = sysNumber;
  /* NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)data)->simulationInfo.nonlinearSystemData[currentSys]); */
  /* DATA_NEWTON* solverData = (DATA_NEWTON*)(systemData->solverData); */

  (*((DATA*)data)->simulationInfo.linearSystemData[currentSys].residualFunc)(data, x, f, iflag);
  return 0;
}

/*! \fn solve linear system with lapack method
 *
 *  \param [in]  [data]
 *                [sysNumber] index of the corresponing non-linear system
 *
 *  \author wbraun
 */
int solveLapack(DATA *data, int sysNumber)
{
  int i, j, iflag = 1;
  LINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo.linearSystemData[sysNumber]);
  DATA_LAPACK* solverData = (DATA_LAPACK*)systemData->solverData;
  int n = systemData->size;
  double fdeps = 1e-8;
  double xTol = 1e-8;
  int eqSystemNumber = systemData->equationIndex;

  /* We are given the number of the linear system.
   * We want to look it up among all equations. */
  /* int eqSystemNumber = systemData->equationIndex; */
  int success = 1;

  if (0 == systemData->method){

    /* reset matrix A */
    memset(systemData->A, 0, (systemData->size)*(systemData->size)*sizeof(double));

    /* update matrix A */
    systemData->setA(data, systemData);
    /* update vector b (rhs) */
    systemData->setb(data, systemData);
  } else {
    /* calculate jacobian -> matrix A*/
    //wrapper_fvec_lapack(systemData->x, solverData->work, &iflag, data, sysNumber);
    if(systemData->jacobianIndex != -1){
      getAnalyticalJacobianLapack(data, systemData->A, sysNumber);
    } else {
      assertStreamPrint(data->threadData, 1, "jacobian function pointer is invalid" );
    }

    /* calculate vector b (rhs) */
     memset(solverData->work, 0, (systemData->size)*sizeof(double));
     wrapper_fvec_lapack(solverData->work, systemData->b, &iflag, data, sysNumber);
     for(i=0; i < n; ++i)
       systemData->b[i] = -systemData->b[i];
  }
  /* Log A*x=b */
  if(ACTIVE_STREAM(LOG_LS_V))
  {
    char buffer[16384];

    /* A matrix */
    infoStreamPrint(LOG_LS_V, 1, "A matrix [%dx%d]", n, n);
    printf("[ ");
    for(i=0; i<n; i++)
    {
      buffer[0] = 0;
      for(j=0; j<n; j++){
        if (j == n-1)
          sprintf(buffer, "%s%g ", buffer, systemData->A[i + j*n]);
        else
          sprintf(buffer, "%s%g, ", buffer, systemData->A[i + j*n]);
      }
      if (i == n-1)
        printf("%s", buffer);
      else
        printf("%s;", buffer);
    }
    printf(" ];\n");
    messageClose(LOG_LS_V);

    /* b vector */
    infoStreamPrint(LOG_LS_V, 1, "b vector [%d]", n);
    for(i=0; i<n; i++)
    {
      buffer[0] = 0;
      sprintf(buffer, "%s%20.12g ", buffer, systemData->b[i]);
      infoStreamPrint(LOG_LS_V, 0, "%s", buffer);
    }

    messageClose(LOG_LS_V);
  }

  /* Solve system */
  dgesv_((int*) &systemData->size,
         (int*) &solverData->nrhs,
         systemData->A,
         (int*) &systemData->size,
         solverData->ipiv,
         systemData->b,
         (int*) &systemData->size,
         &solverData->info);

  if(solverData->info < 0)
  {
    warningStreamPrint(LOG_STDOUT, 0, "Error solving linear system of equations (no. %d) at time %f. Argument %d illegal.", (int)systemData->equationIndex, data->localData[0]->timeValue, (int)solverData->info);
    success = 0;
  }
  else if(solverData->info > 0)
  {
    warningStreamPrint(LOG_STDOUT, 0,
        "Failed to solve linear system of equations (no. %d) at time %f, system is singular for U[%d, %d].",
        (int)systemData->equationIndex, data->localData[0]->timeValue, (int)solverData->info+1, (int)solverData->info+1);

    /* debug output */
    if (ACTIVE_STREAM(LOG_LS))
    {
      long int l = 0;
      long int k = 0;
      char buffer[4096];
      infoStreamPrint(LOG_LS, 0, "Matrix U:");
      for(l = 0; l < systemData->size; l++)
      {
        buffer[0] = 0;
        for(k = 0; k < systemData->size; k++)
          sprintf(buffer, "%s%10g ", buffer, systemData->A[l + k*systemData->size]);
        infoStreamPrint(LOG_LS, 0, "%s", buffer);
      }
      infoStreamPrint(LOG_LS, 0, "Solution x:");
      buffer[0] = 0;
      for(k = 0; k < systemData->size; k++)
        sprintf(buffer, "%s%10g ", buffer, systemData->b[k]);
      infoStreamPrint(LOG_LS, 0, "%s", buffer);
    }

    success = 0;
  }

  if (success == 1){

    /* take the solution */
    memcpy(systemData->x, systemData->b, systemData->size*(sizeof(double)));

    if (1 == systemData->method){
      wrapper_fvec_lapack(systemData->x, solverData->work, &iflag, data, sysNumber);
    }

    if (ACTIVE_STREAM(LOG_LS)){
      infoStreamPrint(LOG_LS, 1, "Solution x:");
      infoStreamPrint(LOG_LS, 0, "System %d numVars %d.", eqSystemNumber, modelInfoXmlGetEquation(&data->modelData.modelDataXml,eqSystemNumber).numVar);
      for(i=0; i<systemData->size; ++i)
      {
        infoStreamPrint(LOG_LS, 0, "[%d] %s = %g", i+1, modelInfoXmlGetEquation(&data->modelData.modelDataXml,eqSystemNumber).vars[i], systemData->x[i]);
      }
      messageClose(LOG_LS);
    }
  }


  return success;
}
