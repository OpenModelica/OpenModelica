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
#include "../../util/omc_error.h"
#include "../../util/varinfo.h"
#include "model_help.h"

#include "linearSystem.h"
#include "linearSolverTotalPivot.h"


void debugMatrixDoubleLS(int logName, char* matrixName, double* matrix, int n, int m)
{
  if(ACTIVE_STREAM(logName))
  {
    int i, j;
    int sparsity = 0;
    char *buffer = (char*)malloc(sizeof(char)*m*18);

    infoStreamPrint(logName, 1, "%s [%dx%d-dim]", matrixName, n, m);
    for(i=0; i<n;i++)
    {
      buffer[0] = 0;
      for(j=0; j<m; j++)
      {
        if (sparsity)
        {
          if (fabs(matrix[i + j*(m-1)])<1e-12)
            sprintf(buffer, "%s 0", buffer);
          else
            sprintf(buffer, "%s *", buffer);
        }
        else
        {
          sprintf(buffer, "%s%12.4g ", buffer, matrix[i + j*(m-1)]);
        }
      }
      infoStreamPrint(logName, 0, "%s", buffer);
    }
    messageClose(logName);
    free(buffer);
  }
}

void debugVectorDoubleLS(int logName, char* vectorName, double* vector, int n)
{
   if(ACTIVE_STREAM(logName))
  {
    int i;
    char *buffer = (char*)malloc(sizeof(char)*n*22);

    infoStreamPrint(logName, 1, "%s [%d-dim]", vectorName, n);
    buffer[0] = 0;
    for(i=0; i<n;i++)
    {
      if (vector[i]<-1e+300)
        sprintf(buffer, "%s -INF ", buffer);
      else if (vector[i]>1e+300)
        sprintf(buffer, "%s +INF ", buffer);
      else
        sprintf(buffer, "%s%16.8g ", buffer, vector[i]);
    }
    infoStreamPrint(logName, 0, "%s", buffer);
    free(buffer);
    messageClose(logName);
  }
}

void debugStringLS(int logName, char* message)
{
  if(ACTIVE_STREAM(logName))
  {
    infoStreamPrint(logName, 1, "%s", message);
    messageClose(logName);
  }
}

void debugIntLS(int logName, char* message, int value)
{
  if(ACTIVE_STREAM(logName))
  {
    infoStreamPrint(logName, 1, "%s %d", message, value);
    messageClose(logName);
  }
}
void vecMultScalingLS(int n, double *a, double *b, double *c)
{
  int i;
  for (i=0;i<n;i++)
    c[i] = a[i]*fabs(b[i]);
}

void vecAddScalLS(int n, double *a, double *b, double s, double *c)
{
  int i;
  for (i=0;i<n;i++)
    c[i] = a[i] + s*b[i];
}

void vecAddLS(int n, double *a, double *b, double *c)
{
  int i;
  for (i=0;i<n;i++)
    c[i] = a[i] + b[i];
}

void vecCopyLS(int n, double *a, double *b)
{
  memcpy(b, a, n*(sizeof(double)));
}

void vecConstLS(int n, double value, double *a)
{
  int i;
  for (i=0;i<n;i++)
    a[i] = value;
}

void vecScalarMultLS(int n, double *a, double s, double *b)
{
  int i;
  for (i=0;i<n;i++)
    b[i] = s*a[i];
}

void getIndicesOfPivotElementLS(int *n, int *m, int *l, double* A, int *indRow, int *indCol, int *pRow, int *pCol, double *absMax)
{
  int i, j;

  *absMax = fabs(A[indRow[*l] + indCol[*l]* *n]);
  *pCol = *l;
  *pRow = *l;
  for (i = *l; i < *n; i++) {
   for (j = *l; j < *m; j++) {
      if (fabs(A[indRow[i] + indCol[j]* *n]) > *absMax) {
        *absMax = fabs(A[indRow[i] + indCol[j]* *n]);
        *pCol = j;
        *pRow = i;
      }
    }
  }
}

/*! \ linear solver for A*x = b based on a total pivot search
 *  \ input matrix Ab: first n columns are matrix A
 *                     last column is -b
 *    output x: solution dim n+1, last column is 1 for solvable systems!
 *           rank: rank of matrix Ab
 *           det: determinant of matrix A
 *
 *  \author bbachmann
 */

int solveSystemWithTotalPivotSearchLS(int n, double* x, double* A, int* indRow, int* indCol, int *rank)
{
   int i, k, j, l, m=n+1, nrsh=1, singular=0;
   int pCol, pRow;
   double hValue;
   double hInt;
   double absMax;
   int r,s;
   int permutation = 1;

   /* assume full rank of matrix [n x (n+1)] */
   *rank = n;

   for (i=0; i<n; i++) {
      indRow[i] = i;
   }
   for (i=0; i<m; i++) {
      indCol[i] = i;
   }

   for (i = 0; i < n; i++) {
    getIndicesOfPivotElementLS(&n, &n, &i, A, indRow, indCol, &pRow, &pCol, &absMax);
    /* this criteria should be evaluated and may be improved in future */
    if (absMax<DBL_EPSILON) {
      *rank = i;
      warningStreamPrint(LOG_LS, 0, "Matrix singular!");
      debugIntLS(LOG_LS,"rank = ", *rank);
      break;
    }
    /* swap row indices */
    if (pRow!=i) {
      hInt = indRow[i];
      indRow[i] = indRow[pRow];
      indRow[pRow] = hInt;
    }
    /* swap column indices */
    if (pCol!=i) {
      hInt = indCol[i];
      indCol[i] = indCol[pCol];
      indCol[pCol] = hInt;
    }

    /* Gauss elimination of row indRow[i] */
    for (k=i+1; k<n; k++) {
      hValue = -A[indRow[k] + indCol[i]*n]/A[indRow[i] + indCol[i]*n];
      for (j=i+1; j<m; j++) {
        A[indRow[k] + indCol[j]*n] = A[indRow[k] + indCol[j]*n] + hValue*A[indRow[i] + indCol[j]*n];
      }
      A[indRow[k] + indCol[i]*n] = 0;
    }
  }

  debugMatrixDoubleLS(LOG_LS_V,"LGS: matrix Ab manipulated",A, n, n+1);
  /* solve even singular matrix !!! */
  for (i=n-1;i>=0; i--) {
    if (i>=*rank) {
      /* this criteria should be evaluated and may be improved in future */
      if (fabs(A[indRow[i] + n*n])>1e-12) {
        warningStreamPrint(LOG_LS, 0, "under-determined linear system not solvable!");
        return -1;
      } else {
        x[indCol[i]] = 0.0;
      }
    } else {
      x[indCol[i]] = -A[indRow[i] + n*n];
      for (j=n-1; j>i; j--) {
        x[indCol[i]] = x[indCol[i]] - A[indRow[i] + indCol[j]*n]*x[indCol[j]];
      }
      x[indCol[i]]=x[indCol[i]]/A[indRow[i] + indCol[i]*n];
    }
  }
  x[n]=1.0;
  debugVectorDoubleLS(LOG_LS_V,"LGS: solution vector x",x, n+1);

  return 0;
}

/*! \fn allocate memory for linear system solver totalpivot
 *
 *  \author bbachmann
 */
int allocateTotalPivotData(int size, void** voiddata)
{
  DATA_TOTALPIVOT* data = (DATA_TOTALPIVOT*) malloc(sizeof(DATA_TOTALPIVOT));

  /* memory for linear system */
  data->Ab = (double*) calloc((size*(size+1)),sizeof(double));
  data->b = (double*) malloc(size*sizeof(double));
  data->x = (double*) calloc(size+1,sizeof(double));

  /* used for pivot strategy */
  data->indRow =(int*) calloc(size,sizeof(int));
  data->indCol =(int*) calloc(size+1,sizeof(int));

  voiddata[1] = (void*)data;
  return 0;
}

/*! \fn free memory for nonlinear solver totalpivot
 *
 *  \author bbachmann
 */
int freeTotalPivotData(void** voiddata)
{
  DATA_TOTALPIVOT* data = (DATA_TOTALPIVOT*) voiddata[1];

  /* memory for linear system */
  free(data->Ab);
  free(data->b);
  free(data->x);

   /* used for pivot strategy */
  free(data->indRow);
  free(data->indCol);

  free(voiddata[1]);
  voiddata[1] = 0;

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
int getAnalyticalJacobianTotalPivot(DATA* data, threadData_t *threadData, double* jac, int sysNumber)
{
  int i,j,k,l,ii,currentSys = sysNumber;
  LINEAR_SYSTEM_DATA* systemData = &(((DATA*)data)->simulationInfo->linearSystemData[currentSys]);

  const int index = systemData->jacobianIndex;
  ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[systemData->jacobianIndex]);

  memset(jac, 0, (systemData->size)*(systemData->size)*sizeof(double));

  for(i=0; i < jacobian->sparsePattern.maxColors; i++)
  {
    /* activate seed variable for the corresponding color */
    for(ii=0; ii < jacobian->sizeCols; ii++)
      if(jacobian->sparsePattern.colorCols[ii]-1 == i)
        jacobian->seedVars[ii] = 1;

    ((systemData->analyticalJacobianColumn))(data, threadData, jacobian, systemData->parentJacobian);

    for(j = 0; j < jacobian->sizeCols; j++)
    {
      if(jacobian->seedVars[j] == 1)
      {
        ii = jacobian->sparsePattern.leadindex[j];
        while(ii < jacobian->sparsePattern.leadindex[j+1]) {
          l  = jacobian->sparsePattern.index[ii];
          k  = j*jacobian->sizeRows + l;
          jac[k] = jacobian->resultVars[l];
          ii++;
        }
      }
      /* de-activate seed variable for the corresponding color */
      if(jacobian->sparsePattern.colorCols[j]-1 == i) {
        jacobian->seedVars[j] = 0;
      }
    }

  }
  return 0;
}

/*! \fn wrapper_fvec_hybrd for the residual Function
 *      calls for the subroutine fcn(n, x, fvec, iflag, data)
 *
 *
 */
static int wrapper_fvec_totalpivot(double* x, double* f, void** data, int sysNumber)
{
  int currentSys = sysNumber;
  int iflag = 0;
  /* NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)data)->simulationInfo->nonlinearSystemData[currentSys]); */
  /* DATA_NEWTON* solverData = (DATA_NEWTON*)(systemData->solverData); */

  (*((DATA*)data[0])->simulationInfo->linearSystemData[currentSys].residualFunc)(data, x, f, &iflag);
  return 0;
}

/*! \fn solve linear system with totalpivot method
 *
 *  \param [in]  [data]
 *                [sysNumber] index of the corresponing non-linear system
 *
 *  \author bbachmann
 */
int solveTotalPivot(DATA *data, threadData_t *threadData, int sysNumber, double* aux_x)
{
  void *dataAndThreadData[2] = {data, threadData};
  int i, j;
  LINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->linearSystemData[sysNumber]);
  DATA_TOTALPIVOT* solverData = (DATA_TOTALPIVOT*) systemData->solverData[1];
  int n = systemData->size, status;
  double fdeps = 1e-8;
  double xTol = 1e-8;
  int eqSystemNumber = systemData->equationIndex;
  int indexes[2] = {1,eqSystemNumber};
  int rank;

  /* We are given the number of the linear system.
   * We want to look it up among all equations. */
  /* int eqSystemNumber = systemData->equationIndex; */
  int success = 1;
  double tmpJacEvalTime;

  infoStreamPrintWithEquationIndexes(LOG_LS, 0, indexes, "Start solving Linear System %d (size %d) at time %g with Total Pivot Solver",
         eqSystemNumber, (int) systemData->size,
         data->localData[0]->timeValue);

  debugVectorDoubleLS(LOG_LS_V,"SCALING",systemData->nominal,n);
  debugVectorDoubleLS(LOG_LS_V,"Old VALUES",aux_x,n);

  rt_ext_tp_tick(&(solverData->timeClock));
  if (0 == systemData->method){

    /* reset matrix A */
    vecConstLS(n*n, 0.0, systemData->A);
    /* update matrix A -> first n columns of matrix Ab*/
    systemData->setA(data, threadData, systemData);
    vecCopyLS(n*n, systemData->A, solverData->Ab);

    /* update vector b (rhs) -> -b is last column of matrix Ab*/
    rt_ext_tp_tick(&(solverData->timeClock));
    systemData->setb(data, threadData, systemData);
    vecScalarMultLS(n, systemData->b, -1.0, solverData->Ab + n*n);

  } else {

    /* calculate jacobian -> first n columns of matrix Ab*/
    if(systemData->jacobianIndex != -1){
      getAnalyticalJacobianTotalPivot(data, threadData, solverData->Ab, sysNumber);
    } else {
      assertStreamPrint(threadData, 1, "jacobian function pointer is invalid" );
    }
    /* calculate vector b (rhs) -> -b is last column of matrix Ab */
    wrapper_fvec_totalpivot(aux_x, solverData->Ab + n*n, dataAndThreadData, sysNumber);
  }
  tmpJacEvalTime = rt_ext_tp_tock(&(solverData->timeClock));
  systemData->jacobianTime += tmpJacEvalTime;
  infoStreamPrint(LOG_LS_V, 0, "###  %f  time to set Matrix A and vector b.", tmpJacEvalTime);
  debugMatrixDoubleLS(LOG_LS_V,"LGS: matrix Ab",solverData->Ab, n, n+1);

  rt_ext_tp_tick(&(solverData->timeClock));
  status = solveSystemWithTotalPivotSearchLS(n, solverData->x, solverData->Ab, solverData->indRow, solverData->indCol, &rank);
  infoStreamPrint(LOG_LS_V, 0, "Solve System: %f", rt_ext_tp_tock(&(solverData->timeClock)));

  if (status != 0)
  {
    warningStreamPrint(LOG_STDOUT, 0, "Error solving linear system of equations (no. %d) at time %f.", (int)systemData->equationIndex, data->localData[0]->timeValue);
    success = 0;
  } else {

    debugVectorDoubleLS(LOG_LS_V, "SOLUTION:", solverData->x, n+1);
    if (1 == systemData->method){
      /* add the solution to old solution vector*/
      vecAddLS(n, aux_x, solverData->x, aux_x);
      wrapper_fvec_totalpivot(aux_x, solverData->b, dataAndThreadData, sysNumber);
    } else {
       /* take the solution */
       vecCopyLS(n, solverData->x, aux_x);
    }

    if (ACTIVE_STREAM(LOG_LS_V)){
      infoStreamPrint(LOG_LS_V, 1, "Solution x:");
      infoStreamPrint(LOG_LS_V, 0, "System %d numVars %d.", eqSystemNumber, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).numVar);
      for(i=0; i<systemData->size; ++i)
      {
        infoStreamPrint(LOG_LS_V, 0, "[%d] %s = %g", i+1, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i], aux_x[i]);
      }
      messageClose(LOG_LS_V);
    }
  }
  return success;
}
