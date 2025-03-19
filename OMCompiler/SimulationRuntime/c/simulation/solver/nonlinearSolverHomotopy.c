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

#if !defined(OMC_NUM_LINEAR_SYSYTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0

#if defined(__AVR__)
#warning "AVR CPUs are not suitable for non-linear solvers"
#endif

/*! \file nonlinearSolverHomotopy.c
*  \author bbachmann
*/

#include <math.h>
#include <stdlib.h>
#include <string.h> /* memcpy */

#include "../options.h"
#include "../simulation_info_json.h"
#include "../jacobian_util.h"
#include "../../util/omc_error.h"
#include "../../util/omc_file.h"
#include "../../util/varinfo.h"
#include "model_help.h"
#include "../../meta/meta_modelica.h"
#if !defined(OMC_MINIMAL_RUNTIME)
#include "../../util/write_csv.h"
#endif

#include "nonlinearSystem.h"
#include "nonlinearSolverHomotopy.h"
#include "nonlinearSolverHybrd.h"

#ifdef __cplusplus
extern "C" {
#endif

extern int dgesv_(int *n, int *nrhs, doublereal *a, int *lda, int *ipiv, doublereal *b, int *ldb, int *info);

#ifdef __cplusplus
}
#endif

/*! \typedef DATA_HOMOTOPY
 * define memory structure for nonlinear system solver
 *  \author bbachmann
 */
typedef struct DATA_HOMOTOPY
{
  modelica_boolean initialized;

  size_t n; /* dimension; n == size */
  size_t m; /* dimension: m == size+1 */

  double xtol_sqrd; /* tolerance for updating solution vector */
  double ftol_sqrd; /* tolerance for accepting accuracy */

  double error_f_sqrd;

  double* resScaling; /* residual scaling */
  double* fvecScaled; /* function values scaled */
  double* hvecScaled; /* function values scaled */
  double* dxScaled;   /* scaled solution vector */

  double* minValue; /* min-attribute of variable, only pointer */
  double* maxValue; /* max-attribute of variable, only pointer */
  double* xScaling; /* nominal-attrbute [x.nominal,lambda.nominal] with lambda.nominal=1.0 */

  /* used in wrapper_*/
  double* f1;
  double* f2;
  /* used for steepest descent method */
  double* gradFx;

  /* return value, if success info == 1 */
  int info;
  int numberOfIterations; /* over the whole simulation time */
  int numberOfFunctionEvaluations; /* over the whole simulation time */
  int maxNumberOfIterations; /* number of Newton steps */

  /* strict tearing set or casual tearing set */
  int casualTearingSet;

  /* newton algorithm*/
  double* x;
  double* x0;
  double* xStart;
  double* x1;
  double* finit;
  double* fx0;
  double* fJac;           /* n times n Jacobian matrix with additional scaling row at the end */
  double* fJacx0;

  /* debug arrays */
  double* debug_fJac;
  double* debug_dx;

  /* homotopy parameters */
  int initHomotopy; /* homotopy method used for the initialization with lambda from the homotopy()-operator */
  double startDirection;
  double  tau;
  double* y0;
  double* y1;
  double* y2;
  double* yt;
  double* dy0;
  double* dy1;
  double* dy2;
  double* hvec;
  double* hJac;
  double* hJac2;
  double* hJacInit;
  double* ones;

  /* linear system */
  int* indRow;
  int* indCol;

  int (*f)         (struct DATA_HOMOTOPY*, double*, double*);
  int (*f_con)     (struct DATA_HOMOTOPY*, double*, double*);
  int (*fJac_f)    (struct DATA_HOMOTOPY* solverData, double* x, double* fJac);
  int (*h_function)(struct DATA_HOMOTOPY*, double*, double*);
  int (*hJac_dh)   (struct DATA_HOMOTOPY*, double*, double*);

  NLS_USERDATA* userData;
  int eqSystemNumber;
  double timeValue;
  int mixedSystem;

  DATA_HYBRD* dataHybrid;

} DATA_HOMOTOPY;

/**
 * @brief Allocate memory for non-linear homotopy solver.
 *
 * @param size              Size of non-linear system.
 * @param userData          Pointer to set NLS user data.
 * @return DATA_HOMOTOPY*   Pointer to allocated KINSOL data.
 */
DATA_HOMOTOPY* allocateHomotopyData(size_t size, NLS_USERDATA* userData)
{
  DATA_HOMOTOPY* homotopyData = (DATA_HOMOTOPY*) malloc(sizeof(DATA_HOMOTOPY));
  assertStreamPrint(NULL, NULL != homotopyData, "allocationHomotopyData() failed!");

  homotopyData->initialized = FALSE;
  homotopyData->n = size;
  homotopyData->m = size + 1;
  homotopyData->xtol_sqrd = newtonXTol*newtonXTol;
  homotopyData->ftol_sqrd = newtonFTol*newtonFTol;

  homotopyData->error_f_sqrd = 0;

  homotopyData->maxNumberOfIterations = size*100;
  homotopyData->numberOfIterations = 0;
  homotopyData->numberOfFunctionEvaluations = 0;

  homotopyData->resScaling = (double*) calloc(size,sizeof(double));
  homotopyData->fvecScaled = (double*) calloc(size,sizeof(double));
  homotopyData->hvecScaled = (double*) calloc(size,sizeof(double));
  homotopyData->dxScaled = (double*) calloc(size,sizeof(double));

  homotopyData->xScaling = (double*) calloc((size+1),sizeof(double));

  homotopyData->f1 = (double*) calloc(size,sizeof(double));
  homotopyData->f2 = (double*) calloc(size,sizeof(double));
  homotopyData->gradFx = (double*) calloc(size,sizeof(double));

  /* damped newton */
  homotopyData->x = (double*) calloc((size+1),sizeof(double));
  homotopyData->x0 = (double*) calloc((size+1),sizeof(double));
  homotopyData->xStart = (double*) calloc(size,sizeof(double));
  homotopyData->x1 = (double*) calloc((size+1),sizeof(double));
  homotopyData->finit = (double*) calloc(size,sizeof(double));
  homotopyData->fx0 = (double*) calloc(size,sizeof(double));
  homotopyData->fJac = (double*) calloc((size*(size+1)),sizeof(double));
  homotopyData->fJacx0 = (double*) calloc((size*(size+1)),sizeof(double));

  /* debug arrays */
  homotopyData->debug_dx = (double*) calloc(size,sizeof(double));
  homotopyData->debug_fJac = (double*) calloc((size*(size+1)),sizeof(double));

   /* homotopy */
  homotopyData->y0 = (double*) calloc((size+1),sizeof(double));
  homotopyData->y1 = (double*) calloc((size+1),sizeof(double));
  homotopyData->y2 = (double*) calloc((size+1),sizeof(double));
  homotopyData->yt = (double*) calloc((size+1),sizeof(double));
  homotopyData->dy0 = (double*) calloc((size+1),sizeof(double));
  homotopyData->dy1 = (double*) calloc((size+homBacktraceStrategy),sizeof(double));
  homotopyData->dy2 = (double*) calloc((size+1),sizeof(double));
  homotopyData->hvec = (double*) calloc(size,sizeof(double));
  homotopyData->hJac = (double*) calloc(size*(size+1),sizeof(double));
  homotopyData->hJac2 = (double*) calloc((size+1)*(size+2),sizeof(double));
  homotopyData->hJacInit = (double*) calloc(size*(size+1),sizeof(double));
  homotopyData->ones = (double*) calloc(size+1,sizeof(double));

  /* linear system */
  homotopyData->indRow = (int*) calloc(size+homBacktraceStrategy-1,sizeof(int));
  homotopyData->indCol = (int*) calloc(size+homBacktraceStrategy,sizeof(int));

  homotopyData->userData = userData;

  homotopyData->dataHybrid = allocateHybrdData(size, userData);

  return homotopyData;
}

/**
 * @brief Free homotopy data.
 *
 * @param homotopyData  Pointer to homotopy data.
 */
void freeHomotopyData(DATA_HOMOTOPY* homotopyData)
{
  free(homotopyData->resScaling);
  free(homotopyData->fvecScaled);
  free(homotopyData->hvecScaled);
  free(homotopyData->x);
  free(homotopyData->debug_dx);
  free(homotopyData->finit);
  free(homotopyData->f1);
  free(homotopyData->f2);
  free(homotopyData->gradFx);
  free(homotopyData->fJac);
  free(homotopyData->fJacx0);
  free(homotopyData->debug_fJac);

  /* damped newton */
  free(homotopyData->x0);
  free(homotopyData->xStart);
  free(homotopyData->x1);
  free(homotopyData->dxScaled);

  /* homotopy */
  free(homotopyData->fx0);
  free(homotopyData->hvec);
  free(homotopyData->hJac);
  free(homotopyData->hJac2);
  free(homotopyData->hJacInit);
  free(homotopyData->y0);
  free(homotopyData->y1);
  free(homotopyData->y2);
  free(homotopyData->yt);
  free(homotopyData->dy0);
  free(homotopyData->dy1);
  free(homotopyData->dy2);
  free(homotopyData->xScaling);
  free(homotopyData->ones);

  /* linear system */
  free(homotopyData->indRow);
  free(homotopyData->indCol);

  /* Don't free userData here, it's done in freeHybrdData */
  freeHybrdData(homotopyData->dataHybrid);

  free(homotopyData);
  return;
}

/* Prototypes for debug functions
 *  \author bbachmann
 */
void printUnknowns(int logName, DATA_HOMOTOPY *solverData)
{
  long i;
  int eqSystemNumber = solverData->eqSystemNumber;
  DATA *data = solverData->userData->data;

  if (!OMC_ACTIVE_STREAM(logName)) return;
  infoStreamPrint(logName, 1, "nls status");
  infoStreamPrint(logName, 1, "variables");
  messageClose(logName);

  for(i=0; i<solverData->n; i++)
    infoStreamPrint(logName, 0, "[%2ld] %30s  = %16.8g\t\t nom = %16.8g\t\t min = %16.8g\t\t max = %16.8g", i+1,
                    modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i],
                    solverData->x[i], solverData->xScaling[i], solverData->minValue[i], solverData->maxValue[i]);
  messageClose(logName);
}

void printNewtonStep(int logName, DATA_HOMOTOPY *solverData)
{
  long i;
  int eqSystemNumber = solverData->eqSystemNumber;
  DATA *data = solverData->userData->data;

  if (!OMC_ACTIVE_STREAM(logName)) return;
  infoStreamPrint(logName, 1, "newton step");
  infoStreamPrint(logName, 1, "variables");
  messageClose(logName);

  for(i=0; i<solverData->n; i++)
    infoStreamPrint(logName, 0, "[%2ld] %30s  = %16.8g\t\t step = %16.8g\t\t old = %16.8g", i+1,
                    modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i],
                    solverData->x1[i], solverData->dy0[i], solverData->x[i]);
  messageClose(logName);
}

void printHomotopyUnknowns(int logName, DATA_HOMOTOPY *solverData)
{
  long i;
  int eqSystemNumber = solverData->eqSystemNumber;
  DATA *data = solverData->userData->data;

  if (!OMC_ACTIVE_STREAM(logName)) return;
  infoStreamPrint(logName, 1, "homotopy status");
  infoStreamPrint(logName, 1, "variables");
  messageClose(logName);

  for(i=0; i<solverData->n; i++)
    infoStreamPrint(logName, 0, "[%2ld] %30s  = %16.8g\t\t nom = %16.8g\t\t min = %16.8g\t\t max = %16.8g", i+1,
                    modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i],
                    solverData->y0[i], solverData->xScaling[i], solverData->minValue[i], solverData->maxValue[i]);
  if (solverData->initHomotopy) {
    infoStreamPrint(logName, 0, "[%2ld] %30s  = %16.8g\t\t nom = %16.8g\t\t min = %16.8g\t\t max = %16.8g", i+1,
                    modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i],
                    solverData->y0[i], solverData->xScaling[i], solverData->minValue[i], solverData->maxValue[i]);
  }
  else {
    infoStreamPrint(logName, 0, "[%2ld] %30s  = %16.8g\t\t nom = %16.8g", i+1,
                    "LAMBDA",
                    solverData->y0[solverData->n], solverData->xScaling[solverData->n]);
  }
  messageClose(logName);
}

void printHomotopyPredictorStep(int logName, DATA_HOMOTOPY *solverData)
{
  long i;
  int eqSystemNumber = solverData->eqSystemNumber;
  DATA *data = solverData->userData->data;

  if (!OMC_ACTIVE_STREAM(logName)) return;
  infoStreamPrint(logName, 1, "predictor status");
  infoStreamPrint(logName, 1, "variables");
  messageClose(logName);

  for(i=0; i<solverData->n; i++)
    infoStreamPrint(logName, 0, "[%2ld] %30s  = %16.8g\t\t dy = %16.8g\t\t old = %16.8g\t\t tau = %16.8g", i+1,
                    modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i],
                    solverData->yt[i], solverData->dy0[i], solverData->y0[i], solverData->tau);
  if (solverData->initHomotopy) {
    infoStreamPrint(logName, 0, "[%2ld] %30s  = %16.8g\t\t dy = %16.8g\t\t old = %16.8g\t\t tau = %16.8g", i+1,
                    modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i],
                    solverData->yt[i], solverData->dy0[i], solverData->y0[i], solverData->tau);
  } else {
    infoStreamPrint(logName, 0, "[%2ld] %30s  = %16.8g\t\t dy = %16.8g\t\t old = %16.8g\t\t tau = %16.8g", i+1,
                    "LAMBDA",
                    solverData->yt[solverData->n], solverData->dy0[i], solverData->y0[i], solverData->tau);
  }
  messageClose(logName);
}

void printHomotopyCorrectorStep(int logName, DATA_HOMOTOPY *solverData)
{
  long i;
  int eqSystemNumber = solverData->eqSystemNumber;
  DATA *data = solverData->userData->data;

  if (!OMC_ACTIVE_STREAM(logName)) return;
  infoStreamPrint(logName, 1, "corrector status");
  infoStreamPrint(logName, 1, "variables");
  messageClose(logName);

  for(i=0; i<solverData->n; i++)
    infoStreamPrint(logName, 0, "[%2ld] %30s  = %16.8g\t\t dy = %16.8g\t\t old = %16.8g\t\t tau = %16.8g", i+1,
                    modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i],
                    solverData->y1[i], solverData->dy1[i], solverData->yt[i], solverData->tau);
  if (solverData->initHomotopy) {
    infoStreamPrint(logName, 0, "[%2ld] %30s  = %16.8g\t\t dy = %16.8g\t\t old = %16.8g\t\t tau = %16.8g", i+1,
                    modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i],
                    solverData->y1[i], solverData->dy1[i], solverData->yt[i], solverData->tau);
  } else {
    infoStreamPrint(logName, 0, "[%2ld] %30s  = %16.8g\t\t dy = %16.8g\t\t old = %16.8g\t\t tau = %16.8g", i+1,
                    "LAMBDA",
                    solverData->y1[solverData->n], solverData->dy1[i], solverData->yt[i], solverData->tau);
  }
  messageClose(logName);
}

void debugMatrixPermutedDouble(int logName, char* matrixName, double* matrix, int n, int m, int* indRow, int* indCol)
{
  if(OMC_ACTIVE_STREAM(logName))
  {
    int i, j;
    int sparsity = 0;
    char *buffer = (char*)malloc(sizeof(char)*m*20);

    infoStreamPrint(logName, 1, "%s [%dx%d-dim]", matrixName, n, m);
    for(i=0; i<n;i++)
    {
      buffer[0] = 0;
      for(j=0; j<m; j++)
      {
        if (sparsity)
        {
          if (fabs(matrix[indRow[i] + indCol[j]*(m-1)])<1e-12)
            sprintf(buffer, "%s 0", buffer);
          else
            sprintf(buffer, "%s *", buffer);
        }
        else
        {
          sprintf(buffer, "%s %16.8g", buffer, matrix[indRow[i] + indCol[j]*(m-1)]);
        }
      }
      infoStreamPrint(logName, 0, "%s", buffer);
    }
    messageClose(logName);
    free(buffer);
  }
}

void debugMatrixDouble(int logName, char* matrixName, double* matrix, int n, int m)
{
  if(OMC_ACTIVE_STREAM(logName))
  {
    int i, j;
    int sparsity = 0;
    char *buffer = (char*)malloc(sizeof(char)*m*20);

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
          sprintf(buffer, "%s %16.8g", buffer, matrix[i + j*(m-1)]);
        }
      }
      infoStreamPrint(logName, 0, "%s", buffer);
    }
    messageClose(logName);
    free(buffer);
  }
}

void debugVectorDouble(int logName, char* vectorName, double* vector, int n)
{
  if(OMC_ACTIVE_STREAM(logName))
  {
    int i;
    char *buffer = (char*)malloc(sizeof(char)*n*20);

    infoStreamPrint(logName, 1, "%s [%d-dim]", vectorName, n);
    buffer[0] = 0;
    if (vector[0]<-1e+300)
      sprintf(buffer, "%s-INF", buffer);
    else if (vector[0]>1e+300)
      sprintf(buffer, "%s+INF", buffer);
    else
      sprintf(buffer, "%s%16.8g", buffer, vector[0]);
    for(i=1; i<n;i++)
    {
      if (vector[i]<-1e+300)
        sprintf(buffer, "%s -INF", buffer);
      else if (vector[i]>1e+300)
        sprintf(buffer, "%s +INF", buffer);
      else
        sprintf(buffer, "%s %16.8g", buffer, vector[i]);
    }
    infoStreamPrint(logName, 0, "%s", buffer);
    messageClose(logName);
    free(buffer);
  }
}

void debugVectorBool(int logName, char* vectorName, modelica_boolean* vector, int n)
{
   if(OMC_ACTIVE_STREAM(logName))
  {
    int i;
    char *buffer = (char*)malloc(sizeof(char)*n*20);

    infoStreamPrint(logName, 1, "%s [%d-dim]", vectorName, n);
    buffer[0] = 0;
    if (vector[0]<-1e+300)
      sprintf(buffer, "%s-INF", buffer);
    else if (vector[0]>1e+300)
      sprintf(buffer, "%s+INF", buffer);
    else
      sprintf(buffer, "%s%d", buffer, vector[0]);
    for(i=1; i<n;i++)
    {
      if (vector[i]<-1e+300)
        sprintf(buffer, "%s -INF", buffer);
      else if (vector[i]>1e+300)
        sprintf(buffer, "%s +INF", buffer);
      else
        sprintf(buffer, "%s %d", buffer, vector[i]);
    }
    infoStreamPrint(logName, 0, "%s", buffer);
    messageClose(logName);
    free(buffer);
  }
}

void debugVectorInt(int logName, char* vectorName, int* vector, int n)
{
  if(OMC_ACTIVE_STREAM(logName))
  {
    int i;
    char *buffer = (char*)malloc(sizeof(char)*n*20);

    infoStreamPrint(logName, 1, "%s [%d-dim]", vectorName, n);
    buffer[0] = 0;
    if (vector[0]<-1e+300)
      sprintf(buffer, "%s-INF", buffer);
    else if (vector[0]>1e+300)
      sprintf(buffer, "%s+INF", buffer);
    else
      sprintf(buffer, "%s%d", buffer, vector[0]);
    for(i=1; i<n;i++)
    {
      if (vector[i]<-1e+300)
        sprintf(buffer, "%s -INF", buffer);
      else if (vector[i]>1e+300)
        sprintf(buffer, "%s +INF", buffer);
      else
        sprintf(buffer, "%s %d", buffer, vector[i]);
    }
    infoStreamPrint(logName, 0, "%s", buffer);
    messageClose(logName);
    free(buffer);
  }
}


/* Prototypes for linear algebra functions
 *  \author bbachmann
 */

double vec2Norm(int n, double *x)
{
  int i;
  double norm=0.0;
  for (i=0;i<n;i++)
    norm+=x[i]*x[i];
  return sqrt(norm);
}

double vec2NormSqrd(int n, double *x)
{
  int i;
  double norm=0.0;
  for (i=0;i<n;i++)
    norm+=x[i]*x[i];
  return norm;
}

double vecMaxNorm(int n, double *x)
{
  int i;
  double norm=fabs(x[0]);
  for (i=1;i<n;i++)
    if (fabs(x[i])>norm)
       norm=fabs(x[i]);
  return norm;
}

void vecAdd(int n, double *a, double *b, double *c)
{
  int i;
  for (i=0;i<n;i++)
    c[i] = a[i] + b[i];
}

void vecAddScal(int n, double *a, double *b, double s, double *c)
{
  int i;
  for (i=0;i<n;i++)
    c[i] = a[i] + s*b[i];
}

void vecScalarMult(int n, double *a, double s, double *b)
{
  int i;
  for (i=0;i<n;i++)
    b[i] = s*a[i];
}

void vecLinearComb(int n, double *a, double r, double *b, double s, double *c)
{
  int i;
  for (i=0;i<n;i++)
    c[i] = r*a[i] + s*b[i];
}

void vecCopy(int n, double *a, double *b)
{
  memcpy(b, a, n*(sizeof(double)));
}

void vecCopyBool(int n, modelica_boolean *a, modelica_boolean *b)
{
  memcpy(b, a, n*(sizeof(modelica_boolean)));
}

void vecAddInv(int n, double *a, double *b)
{
  int i;
  for (i=0;i<n;i++)
    b[i] = -a[i];
}

void vecDiff(int n, double *a, double *b, double *c)
{
  int i;
  for (i=0;i<n;i++)
    c[i] = a[i] - b[i];
}

int isNotEqualVectorInt(int n, modelica_boolean *a, modelica_boolean *b)
{
  int i, isNotEqual = 0;
  for (i=0;i<n;i++)
    isNotEqual += abs(a[i] - b[i]);
  return isNotEqual;
}

void vecMultScaling(int n, double *a, double *b, double *c)
{
  int i;
  for (i=0;i<n;i++)
    c[i] = (fabs(b[i])>0 ? a[i]*fabs(b[i]):a[i]);
}

void vecDivScaling(int n, double *a, double *b, double *c)
{
  int i;
  for (i=0;i<n;i++)
    c[i] = (fabs(b[i])>0 ? a[i]/fabs(b[i]):a[i]);
}

void vecNormalize(int n, double *a, double *b)
{
  int i;
  double norm = vec2Norm(n,a);
  for (i=0;i<n;i++)
    b[i] = (norm>0 ? a[i]/norm:a[i]);
}

void vecConst(int n, double value, double *a)
{
  int i;
  for (i=0;i<n;i++)
    a[i] = value;
}

double vecScalarProd(int n, double *a, double *b)
{
  int i;
  double prod;

  for (i=0,prod=0;i<n;i++)
    prod = prod + a[i]*b[i];

  return prod;
}

/* Matrix has dimension [n x m], vector [m] */
void matVecMult(int n, int m, double *A, double *b, double *c)
{
  int i, j;
  for (i=0;i<n;i++)
    c[i] = 0.0;
  for (j=0;j<m;j++) {
    for (i=0;i<n;i++)
      c[i] += A[i+j*(m-1)]*b[j];
  }
}

/* Matrix has dimension [n x m], vector [m] */
void matVecMultAbs(int n, int m, double *A, double *b, double *c)
{
  int i, j;
  for (i=0;i<n;i++)
    c[i] = 0.0;
  for (j=0;j<m;j++) {
    for (i=0;i<n;i++)
      c[i] += fabs(A[i+j*(m-1)]*b[j]);
  }
}

/* Matrix has dimension [n x (n+1)] */
void matVecMultBB(int n, double *A, double *b, double *c)
{
  int i, j;
  for (i=0;i<n;i++)
    c[i] = 0.0;
  for (j=0;j<n;j++) {
    for (i=0;i<n;i++)
      c[i] += A[i+j*n]*b[j];
  }
}

/* Matrix has dimension [n x (n+1)] */
void matVecMultAbsBB(int n, double *A, double *b, double *c)
{
  int i, j;
  for (i=0;i<n;i++)
    c[i] = 0.0;
  for (j=0;j<n;j++) {
    for (i=0;i<n;i++)
      c[i] += fabs(A[i+j*n]*b[j]);
  }
}

/* Matrix has dimension [n x (n+1)] */
void matAddBB(int n, double* A, double* B, double* C)
{
  int i, j;
  for (j=0;j<n+1;j++) {
    for (i=0;i<n;i++)
      C[i + j*n] = A[i + j*n] + B[i + j*n];
  }
}

/* Matrix has dimension [n x (n+1)] */
void matDiffBB(int n, double* A, double* B, double* C)
{
  int i, j;
  for (j=0;j<n;j++) {
    for (i=0;i<n;i++)
      C[i + j*n] = A[i + j*n] - B[i + j*n];
  }
}

/* Matrix has dimension [n x m] */
void scaleMatrixRows(int n, int m, double *A)
{
  const double delta = 0; /* This might be changed to sqrt(DBL_EPSILON) */
  int i, j;
  double* rowsMax = (double*) calloc(n,sizeof(double));

  for (i=0;i<n;i++)
    rowsMax[i] = 0;

  /* find maximum of each row */
  for (j=0;j<n;j++) {
    for (i=0;i<n;i++) {
      if (fabs(A[i+j*(m-1)]) > rowsMax[i]) {
         rowsMax[i] = fabs(A[i+j*(m-1)]);
      }
    }
  }

  /* remove zero normailzation */
  for (i=0;i<n;i++) {
    if (rowsMax[i] <= delta)
      rowsMax[i] = 1.0;
  }

  /* scale matrix */
  for (j=0;j<m;j++) {
    for (i=0;i<n;i++)
      A[i+j*(m-1)] /= rowsMax[i];
  }

  free(rowsMax);
}

/* Build the newton matrix for the corrector step with orthogonal backtrace strategy */
void orthogonalBacktraceMatrix(DATA_HOMOTOPY* solverData, double* hJac, double* hvec, double* v, double* hJac2, int n, int m)
{
  int i, j;
  for (j=0; j<m; j++) {
    for (i=0; i<n; i++) {
      hJac2[i + j*m] = hJac[i + j*(m-1)];
    }
    hJac2[n + j*m] = v[j];
  }
  for (i=0; i<n; i++) {
    hJac2[i + m*m] = hvec[i];
  }
  hJac2[n + m*m] = 0;
}

void swapPointer(double* *p1, double* *p2)
{
  double* help;
  help = *p1;
  *p1 = *p2;
  *p2 = help;
}

/*! \fn getAnalyticalJacobian
 *
 *  function calculates analytical jacobian
 *
 *  \param [ref] [data]
 *  \param [out] [jac]
 *
 *  \author wbraun
 *          bbachmann: introduce scaling factor
 *
 */
int getAnalyticalJacobianHomotopy(DATA_HOMOTOPY* solverData, double* jac)
{
  int i,j,k,l,ii;
  DATA* data = solverData->userData->data;
  threadData_t *threadData = solverData->userData->threadData;
  JACOBIAN* jacobian = solverData->userData->analyticJacobian;

  evalJacobian(data, threadData, jacobian, NULL, jac);

  /* apply scaling to each column */
  for (j = 0; j < jacobian->sizeCols; j++) {
    for (ii = jacobian->sparsePattern->leadindex[j]; ii < jacobian->sparsePattern->leadindex[j+1]; ii++) {
      l = jacobian->sparsePattern->index[ii];
      k = j*jacobian->sizeRows + l;
      jac[k] *= solverData->xScaling[j];
    }
  }

  return 0;
}

/*! \fn getNumericalJacobianHomotopy
 *
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 *  \author bbachmann
 *
*/
static int getNumericalJacobianHomotopy(DATA_HOMOTOPY* solverData, double *x, double *fJac)
{
  const double delta_h = sqrt(DBL_EPSILON*2e1);
  double delta_hh;
  double xsave;
  int i,j,l;
  int N;
  double* f1;
  int (*f) (struct DATA_HOMOTOPY*, double*, double*);

  if (solverData->initHomotopy) {
    N = solverData->n + 1;  /* also calculate the lambda column */
    f1 = solverData->hvec;  /* homotopy function values solverData->hvec must be set outside this function based on x */
    f = solverData->h_function;
  } else {
    N = solverData->n;      /* calculate jacobian without the lambda column */
    f1 = solverData->f1;    /* normal function values solverData->f1 must be set outside this function based on x */
    f = solverData->casualTearingSet ? solverData->f_con : solverData->f;
  }

  for(i = 0; i < N; i++) {
    xsave = x[i];
    delta_hh = delta_h * (fabs(xsave) + 1.0);
    if ((xsave + delta_hh >= solverData->maxValue[i]))
      delta_hh *= -1;
    x[i] += delta_hh;
    /* Calculate scaled difference quotient */
    delta_hh = 1. / delta_hh * solverData->xScaling[i];
    f(solverData, x, solverData->f2);

    for(j = 0; j < solverData->n; j++) {
      l = i * solverData->n + j;
      fJac[l] = (solverData->f2[j] - f1[j]) * delta_hh;
    }
    x[i] = xsave;
  }
  return 0;
}

/*! \fn wrapper_fvec for the residual Function
 *   tensolve calls for the subroutine fcn(n, x, fvec, iflag, data)
 *
 *  \author bbachmann
 *
 */
static int wrapper_fvec(DATA_HOMOTOPY* solverData, double* x, double* f)
{
  DATA* data = solverData->userData->data;
  threadData_t* threadData = solverData->userData->threadData;
  NONLINEAR_SYSTEM_DATA* nlsData = solverData->userData->nlsData;
  RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=NULL};
  int iflag = 0;

  /* TODO: change input to residualFunc from data to systemData */
  nlsData->residualFunc(&resUserData, x, f, &iflag);
  solverData->numberOfFunctionEvaluations++;

  return 0;
}

/*! \fn wrapper_fvec_constraints for the residual Function
 *   tensolve calls for the subroutine fcn(n, x, fvec, iflag, data)
 *
 *  \author ptaeuber
 *
 */
int wrapper_fvec_constraints(DATA_HOMOTOPY* solverData, double* x, double* f)
{
  DATA* data = solverData->userData->data;
  threadData_t* threadData = solverData->userData->threadData;
  NONLINEAR_SYSTEM_DATA* nlsData = solverData->userData->nlsData;
  RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=NULL};
  int iflag = 0;
  int retVal;

  /* TODO: change input to residualFunc from data to systemData */
  retVal = nlsData->residualFuncConstraints(&resUserData, x, f, &iflag);
  solverData->numberOfFunctionEvaluations++;

  return retVal;
}

/*! \fn wrapper_fvec_der for the residual Function
 *   tensolve calls for the subroutine fcn(n, x, fvec, iflag, data)
 *
 *  \author bbachmann
 *
 */
static int wrapper_fvec_der(DATA_HOMOTOPY* solverData, double* x, double* fJac)
{
  NONLINEAR_SYSTEM_DATA* nlsData = solverData->userData->nlsData;

  /* performance measurement */
  rt_ext_tp_tick(&nlsData->jacobianTimeClock);

  /* calculate jacobian */
  if(nlsData->jacobianIndex != -1)
  {
    /* !!!!!!!!!!! Be sure that actual x is used !!!!!!!!!!! */
    getAnalyticalJacobianHomotopy(solverData, fJac);
  }
  else
  {
    getNumericalJacobianHomotopy(solverData, x, fJac);
  }

  if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_JAC_TEST))
  {
    int n = solverData->n;
    /* debugMatrixDouble(OMC_LOG_NLS_JAC_TEST,"analytical jacobian:",fJac, n, n+1); */
    getNumericalJacobianHomotopy(solverData, x, solverData->debug_fJac);
    /* debugMatrixDouble(OMC_LOG_NLS_JAC_TEST,"numerical jacobian:",solverData->debug_fJac, n, n+1); */
    matDiffBB(n, fJac, solverData->debug_fJac, solverData->debug_fJac);
    /* debugMatrixDouble(OMC_LOG_NLS_JAC_TEST,"Difference of jacobians:",solverData->debug_fJac, n, n+1); */
    debugDouble(OMC_LOG_NLS_JAC_TEST,"error between analytical and numerical jacobian = ", vecMaxNorm(n*n, solverData->debug_fJac));
    vecDivScaling(n*(n+1), solverData->debug_fJac , fJac, solverData->debug_fJac);
    debugDouble(OMC_LOG_NLS_JAC_TEST,"relative error between analytical and numerical jacobian = ", vecMaxNorm(n*n, solverData->debug_fJac));
    messageClose(OMC_LOG_NLS_JAC_TEST);
  }
  /* performance measurement and statistics */
  nlsData->jacobianTime += rt_ext_tp_tock(&(nlsData->jacobianTimeClock));
  nlsData->numberOfJEval++;

  return 0;
}

/*! \fn wrapper_fvec_homotopy_newton for the residual Function
 *
 *  \author bbachmann
 *
 */
static int wrapper_fvec_homotopy_newton(DATA_HOMOTOPY* solverData, double* x, double* h)
{
  int i;
  int n = solverData->n;

  /*  Newton homotopy */
  wrapper_fvec(solverData, x, solverData->f1);
  vecAddScal(solverData->n, solverData->f1, solverData->fx0, - (1-x[n]), h);

  return 0;
}

/*! \fn wrapper_fvec_homotopy_newton_der for the residual Function
 *
 *  \author bbachmann
 *
 */
static int wrapper_fvec_homotopy_newton_der(DATA_HOMOTOPY* solverData, double* x, double* hJac)
{
  int i, j;
  int n = solverData->n;

  /* Newton homotopy */
  wrapper_fvec_der(solverData, x, hJac);

  /* add f(x0) as the last column of the Jacobian*/
  vecCopy(n, solverData->fx0, hJac + n*n);

  return 0;
}

/*! \fn wrapper_fvec_homotopy_fixpoint for the residual Function
 *
 *  \author bbachmann
 *
 */
static int wrapper_fvec_homotopy_fixpoint(DATA_HOMOTOPY* solverData, double* x, double* h)
{
  int i;
  int n = solverData->n;

  /* Fixpoint homotopy */
  wrapper_fvec(solverData, x, solverData->f1);
  for (i=0; i<n; i++){
    h[i] = x[n]*solverData->f1[i] + (1-x[n]) * (x[i]-solverData->x0[i]);
  }

  return 0;
}

/*! \fn wrapper_fvec_homotopy_fixpoint_der for the residual Function
 *
 *  \author bbachmann
 *
 */
static int wrapper_fvec_homotopy_fixpoint_der(DATA_HOMOTOPY* solverData, double* x, double* hJac)
{
  int i, j;
  int n = solverData->n;

  /* Fixpoint homotopy */
  wrapper_fvec_der(solverData, x, hJac);
  for (i=0; i<n; i++){
    for (j=0; j<n; j++) {
      hJac[i+ j * n] = x[n]*hJac[i+ j * n];
    }
    hJac[i+ i * n] = hJac[i+ i * n] + (1-x[n]);
    hJac[i+ n * n] = solverData->f1[i]-(x[i] - solverData->x0[i]);
  }
  return 0;
}

/*! \fn getIndicesOfPivotElement for calculating pivot element
 *
 *  \author bbachmann
 *
 */
 void getIndicesOfPivotElement(int *n, int *m, int *l, double* A, int *indRow, int *indCol, int *pRow, int *pCol, double *absMax)
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


/*! \fn solveSystemWithTotalPivotSearch for solution of overdetermined linear system
 *  used for the homotopy solver, for calculating the direction
 *  used for the newton solver, for calculating the Newton step
 *
 *  \author bbachmann
 *
 */
int solveSystemWithTotalPivotSearch(DATA *data, int n, double* x, double* A, int* indRow, int* indCol, int *pos, int *rank, int casualTearingSet)
{
   int i, k, j, m=n+1, nPivot=n;
   int pCol, pRow;
   double hValue;
   double hInt;
   double absMax, detJac;
   int returnValue = 0;

   debugMatrixDouble(OMC_LOG_NLS_JAC,"Linear System Matrix [Jac res]:",A, n, m);
   debugVectorDouble(OMC_LOG_NLS_JAC,"vector b:", A+n*n, n);

   /* assume full rank of matrix [n x (n+1)] */
   *rank = n;

   for (i=0; i<n; i++) {
      indRow[i] = i;
   }
   for (i=0; i<m; i++) {
      indCol[i] = i;
   }
   if (*pos>=0) {
     indCol[n] = *pos;
     indCol[*pos] = n;
   } else {
     nPivot = n+1;
   }

   for (i = 0; i < n; i++) {
    getIndicesOfPivotElement(&n, &nPivot, &i, A, indRow, indCol, &pRow, &pCol, &absMax);
    if (absMax<DBL_EPSILON) {
      *rank = i;
      if (data->simulationInfo->initial) {
        warningStreamPrint(OMC_LOG_NLS_V, 1, "Homotopy solver total pivot: Matrix (nearly) singular at initialization.");
      } else {
        warningStreamPrint(OMC_LOG_NLS_V, 1, "Homotopy solver total pivot: Matrix (nearly) singular at time %f.", data->localData[0]->timeValue);
      }
      warningStreamPrint(OMC_LOG_NLS_V, 0, "Continuing anyway. For more information please use -lv %s.", OMC_LOG_STREAM_NAME[OMC_LOG_NLS_V]);
      messageCloseWarning(OMC_LOG_NLS_V);
      debugInt(OMC_LOG_NLS_V,"rank = ", *rank);
      debugInt(OMC_LOG_NLS_V,"position = ", *pos);
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

  for (detJac=1.0,k=0; k<n; k++) detJac *= A[indRow[k] + indCol[k]*n];

  debugMatrixPermutedDouble(OMC_LOG_NLS_JAC,"Linear System Matrix [Jac res] after decomposition",A, n, m, indRow, indCol);
  debugDouble(OMC_LOG_NLS_JAC,"Determinant = ", detJac);
  if (isnan(detJac)){
    warningStreamPrint(OMC_LOG_NLS_V, 0, "Jacobian determinant is NaN.");
    return -1;
  }
  else if (fabs(detJac) < 1e-9 && casualTearingSet)
  {
    debugString(OMC_LOG_DT, "The determinant of the casual tearing set is vanishing, let's fail if this is not the solution...");
    returnValue = 1;
  }

  /* Solve even singular matrices !!! */
  for (i=n-1;i>=0; i--) {
    if (i>=*rank) {
      /* this criteria should be evaluated and may be improved in future */
      if (fabs(A[indRow[i] + indCol[n]*n])>1e-6) {
        warningStreamPrint(OMC_LOG_NLS_V, 0, "under-determined linear system not solvable!");
        return -1;
      } else {
        x[indCol[i]] = 0.0;
      }
    } else {
      x[indCol[i]] = -A[indRow[i] + indCol[n]*n];
      for (j=n-1; j>i; j--) {
        x[indCol[i]] = x[indCol[i]] - A[indRow[i] + indCol[j]*n]*x[indCol[j]];
      }
      x[indCol[i]]=x[indCol[i]]/A[indRow[i] + indCol[i]*n];
    }
  }
  x[indCol[n]]=1.0;
  debugVectorInt(OMC_LOG_NLS_V,"indRow:", indRow, n);
  debugVectorInt(OMC_LOG_NLS_V,"indCol:", indCol, n+1);
  debugVectorDouble(OMC_LOG_NLS_V,"vector x (solution):", x, n+1);

  /* Return position of largest value (1.0) */
  if (*pos<0) {
    *pos=indCol[n];
    debugInt(OMC_LOG_NLS_V,"position of largest value = ", *pos);
  }

  return returnValue;
}


/*! \fn linearSolverWrapper
 */
int linearSolverWrapper(DATA *data, int n, double* x, double* A, int* indRow, int* indCol, int *pos, int *rank, int method, int casualTearingSet)
{
  /* First try to use lapack and if it fails then
   * use solveSystemWithTotalPivotSearch */
  int returnValue = -1;
  int solverinfo;
  int nrhs = 1;
  int lda = n;
  int k;
  double detJac;

  debugMatrixDouble(OMC_LOG_NLS_JAC,"Linear System Matrix [Jac res]:", A, n, n+1);
  debugVectorDouble(OMC_LOG_NLS_JAC,"vector b:", x, n);

  switch(method){
    case NLS_LS_TOTALPIVOT:

      solverinfo = solveSystemWithTotalPivotSearch(data, n, x, A, indRow, indCol, pos, rank, casualTearingSet);
      /* in case of failing */
      if (solverinfo == -1)
      {
        /* debug information */
        debugString(OMC_LOG_NLS_V, "Linear total pivot solver failed!!!");
        debugString(OMC_LOG_NLS_V, "******************************************************");
      }
      else if (solverinfo == 1)
      {
        returnValue = 1;
      }
      else
      {
        returnValue = 0;
      }
      break;
    case NLS_LS_LAPACK:
      /* Solve system with lapack */
      dgesv_((int*) &n,
          (int*) &nrhs,
          A,
          (int*) &lda,
          indRow,
          x,
          (int*) &n,
          &solverinfo);

      for (detJac=1.0, k=0; k<n; k++) detJac *= A[k + k*n];

      debugMatrixDouble(OMC_LOG_NLS_JAC,"Linear system matrix [Jac res] after decomposition:", A, n, n+1);
      debugDouble(OMC_LOG_NLS_JAC,"Determinant = ", detJac);

      /* in case of failing */
      if (solverinfo != 0)
      {
        /* debug information */
        debugString(OMC_LOG_NLS_V, "Linear lapack solver failed!!!");
        debugString(OMC_LOG_NLS_V, "******************************************************");
      }
      else if (fabs(detJac) < 1e-9 && casualTearingSet)
      {
        debugString(OMC_LOG_DT, "The determinant of the casual tearing set is vanishing, let's fail if this is not the solution...");
        returnValue = 1;
      }
      else
      {
        vecScalarMult(n, x, -1, x);
        returnValue = 0;
      }
      break;
    default:
      throwStreamPrint(0, "Non-Linear solver try to run with a unknown linear solver (%d).", method);
  }

  /* Debugging error of linear system */
  if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_JAC))
  {
    double* res = (double*) calloc(n,sizeof(double));
    debugVectorDouble(OMC_LOG_NLS_JAC,"solution:", x, n);
    matVecMult(n, n, A, x, res);
    debugVectorDouble(OMC_LOG_NLS_JAC,"test solution:", res, n);
    debugDouble(OMC_LOG_NLS_JAC,"error of linear system = ", vec2Norm(n, res));
    free(res);
    messageClose(OMC_LOG_NLS_JAC);
  }

  return returnValue;
}


/*! \fn solve system with damped Newton-Raphson
 *
 *  \author bbachmann
 *
 */
static int newtonAlgorithm(DATA_HOMOTOPY* solverData, double* x)
{
  int numberOfIterations = 0 ,i, j, n=solverData->n, m=solverData->m;
  int  pos = solverData->n, rank;
  double error_f_sqrd, error_f1_sqrd, error_f2_sqrd, error_f_sqrd_scaled, error_f1_sqrd_scaled;
  double delta_x_sqrd, delta_x_sqrd_scaled, grad_f, grad_f_scaled;
  int numberOfSmallSteps = 0;
  double error_f_old = 1e100;
  int countNegativeSteps = 0;
  double lambda;
  double lambda1, lambda2;
  double lambdaMin = 1e-4;
  double a2, a3, rhs1, rhs2, D;
  double alpha = 1e-1;
  int firstrun;
  int constraintViolated;
  int solverinfo = 0;
  int lastWasGood = 0; /* boolean, keeps track of previous x */

  int assert = 1;
  DATA* data = solverData->userData->data;
  threadData_t *threadData = solverData->userData->threadData;
  NONLINEAR_SYSTEM_DATA* nlsData = solverData->userData->nlsData;
  int linearSolverMethod = data->simulationInfo->nlsLinearSolver;

  /* debug information */
  debugString(OMC_LOG_NLS_V, "******************************************************");
  debugInt(OMC_LOG_NLS_V, "NEWTON SOLVER STARTED! equation number: ",solverData->eqSystemNumber);
  debugInt(OMC_LOG_NLS_V, "maximum number of function evaluation: ", solverData->maxNumberOfIterations);
  printUnknowns(OMC_LOG_NLS_V, solverData);

  /* set default solver message */
  solverData->info = 0;

  /* calculated error of function values */
  error_f_sqrd = vec2NormSqrd(solverData->n, solverData->f1);
  vecDivScaling(solverData->n, solverData->f1, solverData->resScaling, solverData->fvecScaled);
  error_f_sqrd_scaled = vec2NormSqrd(solverData->n, solverData->fvecScaled);

  while(1)
  {
    numberOfIterations++;
    /* debug information */
    debugInt(OMC_LOG_NLS_V, "Iteration:", numberOfIterations);

    /* solve jacobian and function value (both stored in hJac, last column is fvec), side effects: jacobian matrix is changed */
    if (numberOfIterations>1)
      solverinfo = linearSolverWrapper(data, solverData->n, solverData->dy0, solverData->fJac, solverData->indRow, solverData->indCol, &pos, &rank, linearSolverMethod, solverData->casualTearingSet);

    if (solverinfo == -1)
    {
      /* report solver abortion */
      solverData->info=-1;
      /* debug information */
      debugString(OMC_LOG_NLS_V, "NEWTON SOLVER DID ---NOT--- CONVERGE TO A SOLUTION!!!");
      debugString(OMC_LOG_NLS_V, "******************************************************");
      assert = 0;
      break;
    }
    else
    {
      /* Scaling back to original variables */
      vecMultScaling(solverData->m, solverData->dy0, solverData->xScaling, solverData->dy0);
      /* try full Newton step */
      vecAdd(solverData->n, x, solverData->dy0, solverData->x1);
      printNewtonStep(OMC_LOG_NLS_V, solverData);

      /* Damping strategy, performance is very sensitive on the value of lambda */
      lambda1 = 1.0;
      assert = 1;
      firstrun = 1;
      while (assert && (lambda1 > lambdaMin))
      {
        if (!firstrun){
          lambda1 *= 0.655;
          vecAddScal(solverData->n, x, solverData->dy0, lambda1, solverData->x1);
          assert = 1;
        }
#ifndef OMC_EMCC
    MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
        if (solverData->casualTearingSet){
          constraintViolated = solverData->f_con(solverData, solverData->x1, solverData->f1);
          if (constraintViolated){
            lambda1 = lambdaMin-1;
            break;
          }
        }
        else
          solverData->f(solverData, solverData->x1, solverData->f1);

        assert = 0;
#ifndef OMC_EMCC
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
        firstrun = 0;
        if (assert) {
          debugDouble(OMC_LOG_NLS_V, "Assert of Newton step: lambda1 =", lambda1);
        }
      }

      if (lambda1 < lambdaMin)
      {
        debugDouble(OMC_LOG_NLS_V, "UPS! MUST HANDLE A PROBLEM (Newton method), time : ", solverData->timeValue);
        solverData->info = -1;
        break;
      }

      /* Damping (see Numerical Recipes) */
      /* calculate gradient of quadratic function for damping strategy */
      grad_f = -2.0*error_f_sqrd;
      grad_f_scaled = -2.0*error_f_sqrd_scaled;
      error_f1_sqrd = vec2NormSqrd(solverData->n, solverData->f1);
      vecDivScaling(solverData->n, solverData->f1, solverData->resScaling, solverData->f2);
      error_f1_sqrd_scaled = vec2NormSqrd(solverData->n, solverData->f2);
      debugDouble(OMC_LOG_NLS_V, "Need to damp, grad_f = ", grad_f);
      debugDouble(OMC_LOG_NLS_V, "Need to damp, error_f = ", sqrt(error_f_sqrd));
      debugDouble(OMC_LOG_NLS_V, "Need to damp this!! lambda1 = ", lambda1);
      debugDouble(OMC_LOG_NLS_V, "Need to damp, error_f1 = ", sqrt(error_f1_sqrd));
      debugDouble(OMC_LOG_NLS_V, "Need to damp, forced error = ", error_f_sqrd + alpha*lambda1*grad_f);
      if ((error_f1_sqrd > error_f_sqrd + alpha*lambda1*grad_f)
        && (error_f1_sqrd_scaled > error_f_sqrd_scaled + alpha*lambda1*grad_f_scaled)
        && (error_f_sqrd > 1e-12) && (error_f_sqrd_scaled > 1e-12))
      {
        lambda2 = fmax(-lambda1*lambda1*grad_f/(2*(error_f1_sqrd-error_f_sqrd-lambda1*grad_f)),lambdaMin);
        debugDouble(OMC_LOG_NLS_V, "Need to damp this!! lambda2 = ", lambda2);
        vecAddScal(solverData->n, x, solverData->dy0, lambda2, solverData->x1);
        assert= 1;
#ifndef OMC_EMCC
        MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
        if (solverData->casualTearingSet){
          constraintViolated = solverData->f_con(solverData, solverData->x1, solverData->f1);
          if (constraintViolated){
            solverData->info = -1;
            break;
          }
        }
        else
          solverData->f(solverData, solverData->x1, solverData->f1);

        error_f2_sqrd = vec2NormSqrd(solverData->n, solverData->f1);
        debugDouble(OMC_LOG_NLS_V, "Need to damp, error_f2 = ", sqrt(error_f2_sqrd));
        assert = 0;
#ifndef OMC_EMCC
        MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
        if (assert)
        {
          debugDouble(OMC_LOG_NLS_V, "UPS! MUST HANDLE A PROBLEM (Newton method), time : ", solverData->timeValue);
          solverData->info = -1;
          break;
        }
        if ((error_f1_sqrd > error_f_sqrd + alpha*lambda2*grad_f) && (error_f_sqrd > 1e-12) && (error_f_sqrd_scaled > 1e-12))
        {
          rhs1 = error_f1_sqrd - grad_f*lambda1 - error_f_sqrd;
          rhs2 = error_f2_sqrd - grad_f*lambda2 - error_f_sqrd;
          a3 = (rhs1/(lambda1*lambda1) - rhs2/(lambda2*lambda2))/(lambda1 - lambda2);
          a2 = (-lambda2*rhs1/(lambda1*lambda1) + lambda1*rhs2/(lambda2*lambda2))/(lambda1 - lambda2);
          if (a3==0.0)
            lambda = -grad_f/(2.0*a2);
          else
          {
            D = a2*a2 - 3.0*a3*grad_f;
            if (D <= 0.0)
              lambda = 0.5*lambda1;
            else
              if (a2 <= 0.0)
                lambda = (-a2+sqrt(D))/(3.0*a3);
              else
                lambda = -grad_f/(a2+sqrt(D));
          }
          lambda = fmax(lambda, lambdaMin);
          debugDouble(OMC_LOG_NLS_V, "Need to damp this!! lambda = ", lambda);
          vecAddScal(solverData->n, x, solverData->dy0, lambda, solverData->x1);
          assert= 1;
#ifndef OMC_EMCC
          MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
          if (solverData->casualTearingSet){
            constraintViolated = solverData->f_con(solverData, solverData->x1, solverData->f1);
            if (constraintViolated){
              solverData->info = -1;
              break;
            }
          }
          else
            solverData->f(solverData, solverData->x1, solverData->f1);

          error_f1_sqrd = vec2NormSqrd(solverData->n, solverData->f1);
          debugDouble(OMC_LOG_NLS_V, "Need to damp, error_f1 = ", sqrt(error_f1_sqrd));
          assert = 0;
#ifndef OMC_EMCC
          MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
          if (assert)
          {
            debugDouble(OMC_LOG_NLS_V, "UPS! MUST HANDLE A PROBLEM (Newton method), time : ", solverData->timeValue);
            solverData->info = -1;
            break;
          }
        }
      }else{
        lambda = lambda1;
      }
    }

    /* Calculate different error measurements */
    vecDivScaling(solverData->n, solverData->f1, solverData->resScaling, solverData->fvecScaled);
    debugVectorDouble(OMC_LOG_NLS_V, "function values:",solverData->f1, n);
    debugVectorDouble(OMC_LOG_NLS_V, "scaled function values:",solverData->fvecScaled, n);

    /* update delta_x_sqrd, error_f_sqrd */
    vecDivScaling(solverData->n, solverData->dy0, solverData->xScaling, solverData->dxScaled);
    delta_x_sqrd        = vec2NormSqrd(solverData->n, solverData->dy0);
    delta_x_sqrd_scaled = vec2NormSqrd(solverData->n, solverData->dxScaled);

    error_f_old = error_f_sqrd;
    error_f_sqrd        = vec2NormSqrd(solverData->n, solverData->f1);
    error_f_sqrd_scaled = vec2NormSqrd(solverData->n, solverData->fvecScaled);

    countNegativeSteps += (error_f_sqrd > 10*error_f_old);
    lastWasGood = error_f_sqrd >= error_f_old;


    /* debug information */
    if (omc_useStream[OMC_LOG_NLS_V]) {
      debugString(OMC_LOG_NLS_V, "error measurements:");
      debugDouble(OMC_LOG_NLS_V, "delta_x        =", sqrt(delta_x_sqrd));
      debugDouble(OMC_LOG_NLS_V, "delta_x_scaled =", sqrt(delta_x_sqrd_scaled));
      debugDouble(OMC_LOG_NLS_V, "newtonXTol          =", sqrt(solverData->xtol_sqrd));
      debugDouble(OMC_LOG_NLS_V, "error_f        =", sqrt(error_f_sqrd));
      debugDouble(OMC_LOG_NLS_V, "error_f_scaled =", sqrt(error_f_sqrd_scaled));
      debugDouble(OMC_LOG_NLS_V, "newtonFTol          =", sqrt(solverData->ftol_sqrd));
    }

#if !defined(OMC_MINIMAL_RUNTIME)
    if (data->simulationInfo->nlsCsvInfomation){
      print_csvLineIterStats(((struct csvStats*) nlsData->csvData)->iterStats,
                             nlsData->size,
                             nlsData->numberOfCall+1,
                             numberOfIterations,
                             solverData->x,
                             solverData->f1,
                             delta_x_sqrd,
                             delta_x_sqrd_scaled,
                             error_f_sqrd,
                             error_f_sqrd_scaled,
                             lambda
      );
    }
#endif
    if (countNegativeSteps > 20)
    {
      debugInt(OMC_LOG_NLS_V, "UPS! Something happened, NegativeSteps = ", countNegativeSteps);
      solverData->info = -1;
      break;
    }

    /* solution found */
    if (((error_f_sqrd < solverData->ftol_sqrd) || (error_f_sqrd_scaled < solverData->ftol_sqrd)) && ((delta_x_sqrd_scaled < solverData->xtol_sqrd) || (delta_x_sqrd < solverData->xtol_sqrd)))
    {
      solverData->info = 1;

      /* reject new x if old x is as good, for stability (see issue #6419) */
      if (lastWasGood)
      {
        debugString(OMC_LOG_NLS_V, "Note: newton solver rejected last x because previous was as good");
      }
      else
      {
        vecCopy(solverData->n, solverData->x1, x);
      }

      /* update statistics */
      solverData->numberOfIterations += numberOfIterations;
      solverData->error_f_sqrd = error_f_sqrd;

      break;
    }
    else if (solverinfo == 1){
      solverData->info = -1;
      debugString(OMC_LOG_DT, "It is not the solution.");
      break;
    }

    /* check if maximum iteration is reached */
    if (numberOfIterations > solverData->maxNumberOfIterations)
    {
      solverData->info = -1;
      if (data->simulationInfo->initial) {
        warningStreamPrint(OMC_LOG_NLS_V, 0, "Homotopy solver Newton iteration: Maximum number of iterations reached at initialization, but no root found.");
      } else {
        warningStreamPrint(OMC_LOG_NLS_V, 0, "Homotopy solver Newton iteration: Maximum number of iterations reached at time %f, but no root found.", data->localData[0]->timeValue);
      }
      /* debug information */
      debugString(OMC_LOG_NLS_V, "NEWTON SOLVER DID ---NOT--- CONVERGE TO A SOLUTION!!!");
      debugString(OMC_LOG_NLS_V, "******************************************************");

      /* update statistics */
      solverData->numberOfIterations += numberOfIterations;
      break;
    }

    numberOfSmallSteps += (delta_x_sqrd < solverData->xtol_sqrd*1e4) ||  (delta_x_sqrd_scaled < solverData->xtol_sqrd*1e4);
    /* check changes in unknown vector */
    if ((delta_x_sqrd < solverData->xtol_sqrd) ||  (delta_x_sqrd_scaled < solverData->xtol_sqrd) || (numberOfSmallSteps > 20))
    {
      if ((error_f_sqrd < solverData->ftol_sqrd*1e6) || (error_f_sqrd_scaled < solverData->ftol_sqrd*1e6))
      {
        solverData->info = 1;

        /* debug information */
        debugString(OMC_LOG_NLS_V, "NEWTON SOLVER DID CONVERGE TO A SOLUTION WITH LESS ACCURACY!!!");
        printUnknowns(OMC_LOG_NLS_V, solverData);
        debugString(OMC_LOG_NLS_V, "******************************************************");
        solverData->error_f_sqrd = 0;

      } else
      {
        solverData->info = -1;
        debugString(OMC_LOG_NLS_V, "Warning: newton solver gets stuck!!!");
        /* debug information */
        debugString(OMC_LOG_NLS_V, "NEWTON SOLVER DID ---NOT--- CONVERGE TO A SOLUTION!!!");
        debugString(OMC_LOG_NLS_V, "******************************************************");
      }
      /* update statistics */
      solverData->numberOfIterations += numberOfIterations;
      break;
    }
    assert = 1;
#ifndef OMC_EMCC
    MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
    /* updating x */
    vecCopy(solverData->n, solverData->x1, x);

    /* calculate jacobian and function values (both stored in fJac, last column is fvec) */
    solverData->fJac_f(solverData, x, solverData->fJac);
    assert = 0;
#ifndef OMC_EMCC
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
    if (assert)
    {
      /* report solver abortion */
      solverData->info=-1;
      debugString(OMC_LOG_NLS_V,"UPS! assert when calculating Jacobian!!!");
      break;
    }
    vecCopy(n, solverData->f1, solverData->fJac + n*n);
    /* calculate scaling factor of residuals */
    matVecMultAbsBB(solverData->n, solverData->fJac, solverData->ones, solverData->resScaling);
    debugVectorDouble(OMC_LOG_NLS_JAC, "residuum scaling:", solverData->resScaling, solverData->n);
    scaleMatrixRows(solverData->n, solverData->m, solverData->fJac);
    vecCopy(n, solverData->fJac + n*n, solverData->dy0);
  }
  return 0;
}

/*! \fn solve system with homotopy method
 *
 *  \author bbachmann
 */
static int homotopyAlgorithm(DATA_HOMOTOPY* solverData, double *x)
{
  int i, j;
  double error_h, error_h_scaled, delta_x;
  double vecScalarProduct;

  int pos, rank;
  int iter = 0;
  int maxiter = homMaxNewtonSteps;
  int maxTries = homMaxTries;
  int numSteps = 0;
  int stepAccept = 0;
  int correctorStrategy = homBacktraceStrategy; /* 1: go back to the path by fixing one coordinate, 2: go back to the path in an orthogonal direction to the tangent vector */
  double bend = 0;
  double tau = homTauStart, tauMax = homTauMax, tauMin = homTauMin, hEps = homHEps, adaptBend = homAdaptBend;
  double tauDecreasingFactor = homTauDecreasingFactor, tauDecreasingFactorPredictor = homTauDecreasingFactorPredictor;
  double tauIncreasingFactor = homTauIncreasingFactor, tauIncreasingThreshold = homTauIncreasingThreshold;
  double preTau;
  int m = solverData->m;
  int n = solverData->n;
  int initialStep = 1;
  int maxLambdaSteps = homMaxLambdaSteps ? homMaxLambdaSteps : solverData->maxNumberOfIterations;

  int assert = 1;
  DATA* data = solverData->userData->data;
  threadData_t *threadData = solverData->userData->threadData;
  int sysNumber = solverData->userData->sysNumber;

  // TODO: Make this print a function!
  FILE *pFile = NULL;
  char buffer[4096];

#if !defined(OMC_NO_FILESYSTEM)
    const char sep[] = ",";
    if(solverData->initHomotopy && OMC_ACTIVE_STREAM(OMC_LOG_INIT_HOMOTOPY))
    {
      if (omc_flag[FLAG_OUTPUT_PATH]) { /* Add output path to file name */
        sprintf(buffer, "%s/%s_nonlinsys%d_adaptive_%s_homotopy_%s.csv", omc_flagValue[FLAG_OUTPUT_PATH], data->modelData->modelFilePrefix, sysNumber, data->callback->useHomotopy == 2 ? "global" : "local", solverData->startDirection > 0 ? "pos" : "neg");
      }
      else
      {
        sprintf(buffer, "%s_nonlinsys%d_adaptive_%s_homotopy_%s.csv", data->modelData->modelFilePrefix, sysNumber, data->callback->useHomotopy == 2 ? "global" : "local", solverData->startDirection > 0 ? "pos" : "neg");
      }
      infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 0, "The homotopy path will be exported to %s.", buffer);
      pFile = omc_fopen(buffer, "wt");
      fprintf(pFile, "\"sep=%s\"\n%s", sep, "\"lambda\"");
      for(i=0; i<n; ++i)
        fprintf(pFile, "%s\"%s\"", sep, modelInfoGetEquation(&data->modelData->modelDataXml,solverData->eqSystemNumber).vars[i]);
      fprintf(pFile, "\n");
      fprintf(pFile, "0.0");
      for(i=0; i<n; ++i)
        fprintf(pFile, "%s%.16g", sep, x[i]);
      fprintf(pFile, "\n");
    }
#endif

  /* Initialize vector dy2 using chosen startDirection */
  /* set start vector, lambda = 0.0 */
  vecCopy(solverData->n, x, solverData->y0);
  solverData->y0[solverData->n] = 0.0;

  vecConst(solverData->n, 0.0, solverData->dy2);
  solverData->dy2[solverData->n]= solverData->startDirection;
  printHomotopyUnknowns(OMC_LOG_NLS_V, solverData);
  assert = 1;
#ifndef OMC_EMCC
    MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
    solverData->h_function(solverData, solverData->y0, solverData->hvec);
    assert = 0;
#ifndef OMC_EMCC
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
  /* start iteration; stop, if lambda = solverData->y0[solverData->n] == 1 */
  while (solverData->y0[solverData->n]<1)
  {
    if (solverData->initHomotopy)
      infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 0, "homotopy parameter lambda = %g", solverData->y0[solverData->n]);
    else
      infoStreamPrint(OMC_LOG_NLS_HOMOTOPY, 0, "homotopy parameter lambda = %g", solverData->y0[solverData->n]);
    /* Break loop, iff algorithm gets stuck or lambda accelerates to the wrong direction */
    if (iter>=maxTries)
    {
      if (solverData->initHomotopy) {
        if (preTau == tau)
          warningStreamPrint(OMC_LOG_ASSERT, 0, "Homotopy algorithm did not converge.\nNo solution for current step size tau found and tau cannot be decreased any further.\nYou can set the minimum step size tau with:\n\t-homTauMin=<value>\nYou can also try to allow more newton steps in the corrector step with:\n\t-homMaxNewtonSteps=<value>\nor change the tolerance for the solution with:\n\t-homHEps=<value>\nYou can also try to use another backtrace stategy in the corrector step with:\n\t-homBacktraceStrategy=<fix|orthogonal>\nYou can use -lv=LOG_INIT_HOMOTOPY,LOG_NLS_HOMOTOPY to get more information.");
        else
          warningStreamPrint(OMC_LOG_ASSERT, 0, "Homotopy algorithm did not converge.\nThe maximum number of tries for one lambda is reached (%d).\nYou can change the number of tries with:\n\t-homMaxTries=<value>\nYou can also try to allow more newton steps in the corrector step with:\n\t-homMaxNewtonSteps=<value>\nor change the tolerance for the solution with:\n\t-homHEps=<value>\nYou can also try to use another backtrace stategy in the corrector step with:\n\t-homBacktraceStrategy=<fix|orthogonal>\nYou can use -lv=LOG_INIT_HOMOTOPY,LOG_NLS_HOMOTOPY to get more information.", iter);
      }
      else
        debugInt(OMC_LOG_NLS_HOMOTOPY, "Homotopy algorithm did not converge: iter = ", iter);
      debugString(OMC_LOG_NLS_HOMOTOPY, "======================================================");
      return -1;
    }
    if (solverData->y0[solverData->n]<(-1))
    {
      if (solverData->initHomotopy)
        warningStreamPrint(OMC_LOG_ASSERT, 0, "Homotopy algorithm did not converge.\nlambda is smaller than -1: lambda=%g\nYou can use -lv=LOG_INIT_HOMOTOPY,LOG_NLS_HOMOTOPY to get more information.", solverData->y0[solverData->n]);
      else
        debugDouble(OMC_LOG_NLS_HOMOTOPY, "Homotopy algorithm did not converge: lambda = ", solverData->y0[solverData->n]);
      debugString(OMC_LOG_NLS_HOMOTOPY, "======================================================");
      return -1;
    }
    if (numSteps >= maxLambdaSteps)
    {
      if (solverData->initHomotopy)
        warningStreamPrint(OMC_LOG_ASSERT, 0, "Homotopy algorithm did not converge.\nThe maximum number of lambda steps is reached (%d).\nYou can change the maximum number of lambda steps with:\n\t-homMaxLambdaSteps=<value>\nYou can also try to influence the step size tau with the following flags:\n\t-homTauDecFac=<value>\n\t-homTauDecFacPredictor=<value>\n\t-homTauIncFac=<value>\n\t-homTauIncThreshold=<value>\n\t-homTauMax=<value>\n\t-homTauMin=<value>\n\t-homTauStart=<value>\nor you can also set the threshold for accepting the current bending with:\n\t-homAdaptBend=<value>\nYou can also try to use another backtrace stategy in the corrector step with:\n\t-homBacktraceStrategy=<fix|orthogonal>\nYou can use -lv=LOG_INIT_HOMOTOPY,LOG_NLS_HOMOTOPY to get more information.", maxLambdaSteps);
      else
        debugInt(OMC_LOG_NLS_HOMOTOPY, "Homotopy algorithm did not converge: numSteps = ", numSteps);
      debugString(OMC_LOG_NLS_HOMOTOPY, "======================================================");
      return -1;
    }

    stepAccept = 0;

    /****************************************************************************
     * Predictor step: Calculation of tangent vector!                           *
     ****************************************************************************/
    /* If a step succeeded, calculate the homotopy function and corresponding jacobian */
    if (iter==0)
    {
    /* Handle asserts of function calls, mainly necessary for fluid stuff */
      assert = 1;
#ifndef OMC_EMCC
    MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
      solverData->hJac_dh(solverData, solverData->y0, solverData->hJac);
      debugMatrixDouble(OMC_LOG_NLS_JAC,"Jacobian hJac:",solverData->hJac, solverData->n, solverData->n+1);
      scaleMatrixRows(solverData->n, solverData->m, solverData->hJac);
      debugMatrixDouble(OMC_LOG_NLS_JAC,"Jacobian hJac after scaling:",solverData->hJac, solverData->n, solverData->n+1);
      assert = 0;
      pos = -1; /* stable solution algorithm for solving a generalized over-determined linear system */
#ifndef OMC_EMCC
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

      if (assert || (solveSystemWithTotalPivotSearch(data, solverData->n, solverData->dy0, solverData->hJac, solverData->indRow, solverData->indCol, &pos, &rank, solverData->casualTearingSet) == -1))
      {
        /* report solver abortion */
        solverData->info=-1;
        /* debug information */
        if (assert) {
          if (solverData->initHomotopy)
            warningStreamPrint(OMC_LOG_ASSERT, 0, "Homotopy algorithm did not converge.\nIt was not possible to calculate the jacobian.\nYou can use -lv=LOG_INIT_HOMOTOPY,LOG_NLS_HOMOTOPY to get more information.");
          else {
            debugString(OMC_LOG_NLS_HOMOTOPY, "Assert, when calculating Jacobian!");
            debugString(OMC_LOG_NLS_HOMOTOPY, "Homotopy algorithm did not converge");
          }
        } else {
          if (solverData->initHomotopy)
            warningStreamPrint(OMC_LOG_ASSERT, 0, "Homotopy algorithm did not converge.\nThe system is singular and not solvable.\nYou can use -lv=LOG_INIT_HOMOTOPY,LOG_NLS_HOMOTOPY to get more information.");
          else {
            debugString(OMC_LOG_NLS_HOMOTOPY, "System singular and not solvable!");
            debugString(OMC_LOG_NLS_HOMOTOPY, "Homotopy algorithm did not converge");
          }
        }
        debugString(OMC_LOG_NLS_HOMOTOPY, "======================================================");
        /* update statistics */
        return -1;
      }
      /* Scaling back to original variables */
      vecMultScaling(solverData->m, solverData->dy0, solverData->xScaling, solverData->dy0);
      debugVectorDouble(OMC_LOG_NLS_HOMOTOPY, "tangent vector with original scaling:", solverData->dy0, solverData->m);
      debugDouble(OMC_LOG_NLS_HOMOTOPY,"length of tangent vector with original scaling: ", vec2Norm(solverData->m, solverData->dy0));
      // vecNormalize(solverData->m, solverData->dy0, solverData->dy0);
      // debugVectorDouble(OMC_LOG_NLS_HOMOTOPY, "normalized tangent vector:", solverData->dy0, solverData->m);
      // debugDouble(OMC_LOG_NLS_HOMOTOPY,"length of normalized tangent vector: ", vec2Norm(solverData->m, solverData->dy0));

      /* Correct search direction, depending on the last direction (angle < 90 degree) */
      vecScalarProduct = vecScalarProd(solverData->m,solverData->dy0,solverData->dy2);
      debugDouble(OMC_LOG_NLS_HOMOTOPY,"scalar product ", vecScalarProduct);
      if (vecScalarProduct<0 || ((fabs(vecScalarProduct)<DBL_EPSILON) && (solverData->startDirection == -1) && initialStep))
      {
        debugInt(OMC_LOG_NLS_HOMOTOPY,"initialStep = ", initialStep);
        debugInt(OMC_LOG_NLS_HOMOTOPY,"solverData->startDirection = ", solverData->startDirection);
        debugVectorDouble(OMC_LOG_NLS_HOMOTOPY,"step:",solverData->dy0, m);
        vecAddInv(solverData->m, solverData->dy0, solverData->dy0);
        debugVectorDouble(OMC_LOG_NLS_HOMOTOPY,"corrected step:",solverData->dy0, m);
      }
      /* adapt tau, if lambda + tau*delta_lambda > 1 */
      if (fabs(solverData->dy0[solverData->n])>1e-8)
      {
        tau = fmin(tau,(1-solverData->y0[solverData->n])/fabs(solverData->dy0[solverData->n]));
      }
    }

    assert = 1;
    do {
      /* do update and store approximated vector in yt */
      vecAddScal(solverData->m, solverData->y0, solverData->dy0, tau,  solverData->y1);

      /* update function value */
#ifndef OMC_EMCC
      MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
      debugVectorDouble(OMC_LOG_NLS_HOMOTOPY,"y1 (predictor step):",solverData->y1, m);
      solverData->h_function(solverData, solverData->y1, solverData->hvec);
      debugVectorDouble(OMC_LOG_NLS_HOMOTOPY,"hvec (predictor step):",solverData->hvec, n);
      assert = 0;
#ifndef OMC_EMCC
      MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
      if (assert){
        debugString(OMC_LOG_NLS_HOMOTOPY, "Assert, when calculating function value!");
        debugString(OMC_LOG_NLS_HOMOTOPY, "--- decreasing step size tau in predictor step!");
        debugDouble(OMC_LOG_NLS_HOMOTOPY, "old tau =", tau);
        tau = tau/tauDecreasingFactorPredictor;
        debugDouble(OMC_LOG_NLS_HOMOTOPY, "new tau =", tau);
      }
    } while (assert && (tau > tauMin));

    if (assert)
    {
        /* report solver abortion */
        solverData->info=-1;
        /* debug information */
        if (solverData->initHomotopy)
            warningStreamPrint(OMC_LOG_ASSERT, 0, "Homotopy algorithm did not converge.\nThe step size tau cannot be decreased anymore and current tau=%g already failed.\nYou can influence the calculation of tau with the following flags:\n\t-homTauDecFac=<value>\n\t-homTauDecFacPredictor=<value>\n\t-homTauIncFac=<value>\n\t-homTauIncThreshold=<value>\n\t-homTauMax=<value>\n\t-homTauMin=<value>\n\t-homTauStart=<value>\nYou can also set the threshold for accepting the current bending with:\n\t-homAdaptBend=<value>\nYou can use -lv=LOG_INIT_HOMOTOPY,LOG_NLS_HOMOTOPY to get more information.", tau);
        else {
          debugString(OMC_LOG_NLS_HOMOTOPY, "Assert, because tau cannot be decreased anymore and current tau already failed!");
          debugString(OMC_LOG_NLS_HOMOTOPY, "Homotopy algorithm did not converge");
        }
        debugString(OMC_LOG_NLS_HOMOTOPY, "======================================================");
        /* update statistics */
        return -1;
    }
    vecCopy(solverData->m, solverData->y1, solverData->y2);
    vecCopy(solverData->m, solverData->y1, solverData->yt);
    vecCopy(solverData->n, solverData->hvec, solverData->hvecScaled);

    solverData->tau = tau;
    printHomotopyPredictorStep(OMC_LOG_NLS_HOMOTOPY, solverData);

    /****************************************************************************
     * Corrector step: Newton iteration!                                        *
     ****************************************************************************/
    debugString(OMC_LOG_NLS_HOMOTOPY, "Newton iteration for corrector step begins!");

    /* If this is the last step, use backtrace strategy with one fixed coordinate and fix lambda */
    if (solverData->yt[solverData->n] == 1)
    {
      debugString(OMC_LOG_NLS_HOMOTOPY, "Force '-homBacktraceStrategy=fix' and fix lambda, because this is the last step!");
      debugDouble(OMC_LOG_NLS_HOMOTOPY, "Set tolerance homHEps to newtonFTol =", newtonFTol);
      correctorStrategy = 1;
      pos = solverData->n;
      hEps = newtonFTol;
    }

    if (correctorStrategy==1)
      debugString(OMC_LOG_NLS_HOMOTOPY, "Using backtrace strategy with one fixed coordinate! To change this use: '-homBacktraceStrategy=orthogonal'");
    else
      debugString(OMC_LOG_NLS_HOMOTOPY, "Using backtrace strategy orthogonal to the tangent vector! To change this use: '-homBacktraceStrategy=fix'");


    for(j=0;j<maxiter;j++)
    {
      debugInt(OMC_LOG_NLS_HOMOTOPY, "Iteration: ", j+1);
      if (vec2Norm(solverData->n, solverData->hvec)<hEps || vec2Norm(solverData->n, solverData->hvecScaled)<hEps)
      {
        debugString(OMC_LOG_NLS_HOMOTOPY, "step accepted!");
        stepAccept = 1;
        break;
      }
      assert = 1;
#ifndef OMC_EMCC
    MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
      /* calculate homotopy jacobian */
      solverData->hJac_dh(solverData, solverData->y1, solverData->hJac);
      debugMatrixDouble(OMC_LOG_NLS_JAC,"Jacobian hJac:",solverData->hJac, solverData->n, solverData->n+1);

      if (correctorStrategy==2)
      {
        /* calculate the newton matrix hJac2 for the orthogonal backtrace strategy */
        orthogonalBacktraceMatrix(solverData, solverData->hJac, solverData->hvec, solverData->dy0, solverData->hJac2, solverData->n, solverData->m);
        debugMatrixDouble(OMC_LOG_NLS_JAC,"Enhanced Jacobian hJac2 (orthogonal backtrace strategy):",solverData->hJac2, solverData->n+1, solverData->m+1);
      }

      assert = 0;
#ifndef OMC_EMCC
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
      if (assert)
      {
        debugString(OMC_LOG_NLS_HOMOTOPY, "step NOT accepted, because hJac_dh could not be calculated!");
        stepAccept = 0;
        break;
      }
      matVecMultAbs(solverData->n, solverData->m, solverData->hJac, solverData->ones, solverData->resScaling);
      debugVectorDouble(OMC_LOG_NLS_HOMOTOPY, "residuum scaling of function h:", solverData->resScaling, solverData->n);

      if (correctorStrategy==1) // fix one coordinate
      {
        /* copy vector h to column "pos" of the jacobian */
        debugVectorDouble(OMC_LOG_NLS_HOMOTOPY, "copy vector hvec to column 'pos' of the jacobian:", solverData->hvec, solverData->n);
        vecCopy(solverData->n, solverData->hvec, solverData->hJac + pos*solverData->n);
        scaleMatrixRows(solverData->n, solverData->m, solverData->hJac);
        if (solveSystemWithTotalPivotSearch(data, solverData->n, solverData->dy1, solverData->hJac, solverData->indRow, solverData->indCol, &pos, &rank, solverData->casualTearingSet) == -1)
        {
          debugString(OMC_LOG_NLS_HOMOTOPY, "step NOT accepted, because solveSystemWithTotalPivotSearch failed!");
          stepAccept = 0;
          break;
        }
        solverData->dy1[pos] = 0.0;
      }
      else // go back in orthogonal direction to tangent vector
      {
        scaleMatrixRows(solverData->n+1, solverData->m+1, solverData->hJac2);
        pos = solverData->n+1;
        if (solveSystemWithTotalPivotSearch(data, solverData->n+1, solverData->dy1, solverData->hJac2, solverData->indRow, solverData->indCol, &pos, &rank, solverData->casualTearingSet) == -1)
        {
          debugString(OMC_LOG_NLS_HOMOTOPY, "step NOT accepted, because solveSystemWithTotalPivotSearch failed!");
          stepAccept = 0;
          break;
        }
      }

      /* Scaling back to original variables */
      vecMultScaling(solverData->m, solverData->dy1, solverData->xScaling, solverData->dy1);
      debugVectorDouble(OMC_LOG_NLS_HOMOTOPY, "solution (original scaling):", solverData->dy1, solverData->m);

      vecAdd(solverData->m, solverData->y1, solverData->dy1, solverData->y2);
      vecCopy(solverData->m, solverData->y2, solverData->y1);
      debugVectorDouble(OMC_LOG_NLS_HOMOTOPY, "new y in newton:", solverData->y1, solverData->m);
      assert = 1;
#ifndef OMC_EMCC
    MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
      /* calculate homotopy function */
      solverData->h_function(solverData, solverData->y1, solverData->hvec);
      assert = 0;
#ifndef OMC_EMCC
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
      if (assert)
      {
        debugString(OMC_LOG_NLS_HOMOTOPY, "step NOT accepted, because h_function could not be calculated!");
        stepAccept = 0;
        break;
      }
      /* Calculate different error measurements */
      vecDivScaling(solverData->n, solverData->hvec, solverData->resScaling, solverData->hvecScaled);

      delta_x        = vec2Norm(solverData->m, solverData->dy1);
      error_h        = vec2Norm(solverData->n, solverData->hvec);
      error_h_scaled = vec2Norm(solverData->n, solverData->hvecScaled);


      /* debug information */
      debugVectorDouble(OMC_LOG_NLS_HOMOTOPY,"function values:",solverData->hvec, n);
      debugVectorDouble(OMC_LOG_NLS_HOMOTOPY,"scaled function values:",solverData->hvecScaled, n);

      debugString(OMC_LOG_NLS_HOMOTOPY, "error measurements:");
      debugDouble(OMC_LOG_NLS_HOMOTOPY, "delta_x        =", delta_x);
      debugDouble(OMC_LOG_NLS_HOMOTOPY, "error_h        =", error_h);
      debugDouble(OMC_LOG_NLS_HOMOTOPY, "error_h_scaled =", error_h_scaled);
      debugDouble(OMC_LOG_NLS_HOMOTOPY, "hEps           =", hEps);

    }
    debugString(OMC_LOG_NLS_HOMOTOPY, "Newton iteration for corrector step finished!");

    if (!assert)
    {
      vecDiff(solverData->m, solverData->y1, solverData->yt, solverData->dy1);
      vecDiff(solverData->m, solverData->yt, solverData->y0, solverData->dy2);
      printHomotopyCorrectorStep(OMC_LOG_NLS_HOMOTOPY, solverData);
      bend = vec2Norm(solverData->m,solverData->dy1)/vec2Norm(solverData->m,solverData->dy2);

      debugDouble(OMC_LOG_NLS_HOMOTOPY, "vector length of predictor step =", vec2Norm(solverData->m,solverData->dy2));
      debugDouble(OMC_LOG_NLS_HOMOTOPY, "vector length of corrector step =", vec2Norm(solverData->m,solverData->dy1));
      debugDouble(OMC_LOG_NLS_HOMOTOPY, "bend  =", bend);
      debugDouble(OMC_LOG_NLS_HOMOTOPY, "adaptBend  =", adaptBend);
    }
    if ((bend > adaptBend) || !stepAccept)
    {
      if (bend<DBL_EPSILON)
      {
        /* debug information */
        if (solverData->initHomotopy)
          warningStreamPrint(OMC_LOG_ASSERT, 0, "Homotopy algorithm did not converge.\nThe value specifying the bending of the homotopy curve is smaller than DBL_EPSILON (increment zero).\nYou can use -lv=LOG_INIT_HOMOTOPY,LOG_NLS_HOMOTOPY to get more information.");
        else
          debugString(OMC_LOG_NLS_HOMOTOPY, "\nINCREMENT ZERO: Homotopy algorithm did not converge\n");
        debugString(OMC_LOG_NLS_HOMOTOPY, "======================================================");
        /* update statistics */
        return -1;
      }
      debugString(OMC_LOG_NLS_HOMOTOPY, "The relation between the vector length of corrector step and predictor step is too big:");
      debugDouble(OMC_LOG_NLS_HOMOTOPY, "bend/adaptBend  =", bend/adaptBend);
      debugString(OMC_LOG_NLS_HOMOTOPY, "--- decreasing step size tau in corrector step!");
      preTau = tau;
      debugDouble(OMC_LOG_NLS_HOMOTOPY, "old tau =", preTau);
      tau = fmax(tauMin,tau/tauDecreasingFactor);
      debugDouble(OMC_LOG_NLS_HOMOTOPY, "new tau =", tau);
      if (tau==preTau)
        iter = maxTries;
      else
        iter++;
    } else
    {
      initialStep = 0;
      iter = 0;
      numSteps++;
      if (bend < adaptBend/tauIncreasingThreshold)
      {
        debugString(OMC_LOG_NLS_HOMOTOPY, "--- increasing step size tau in corrector step!");
        debugDouble(OMC_LOG_NLS_HOMOTOPY, "old tau =", tau);
        tau = fmin(tauMax, tau*tauIncreasingFactor);
        debugDouble(OMC_LOG_NLS_HOMOTOPY, "new tau =", tau);
      }
      vecCopy(solverData->m, solverData->y1, solverData->y0);
      vecCopy(solverData->m, solverData->dy0, solverData->dy2);
      debugString(OMC_LOG_NLS_HOMOTOPY, "Successfull homotopy step!\n======================================================");
      printHomotopyUnknowns(OMC_LOG_NLS_HOMOTOPY, solverData);

#if !defined(OMC_NO_FILESYSTEM)
      if(solverData->initHomotopy && OMC_ACTIVE_STREAM(OMC_LOG_INIT_HOMOTOPY))
      {
        fprintf(pFile, "%.16g", solverData->y0[n]);
        for(i=0; i<n; ++i)
          fprintf(pFile, "%s%.16g", sep, solverData->y0[i]);
        fprintf(pFile, "\n");
      }
#endif
    }
  }
  if (solverData->initHomotopy)
      infoStreamPrint(OMC_LOG_INIT_HOMOTOPY, 0, "homotopy parameter lambda = %g", solverData->y0[solverData->n]);
  else
      infoStreamPrint(OMC_LOG_NLS_HOMOTOPY, 0, "homotopy parameter lambda = %g", solverData->y0[solverData->n]);
  /* copy solution back to vector x */
  vecCopy(solverData->n, solverData->y1, x);

  debugString(OMC_LOG_NLS_HOMOTOPY, "HOMOTOPY ALGORITHM SUCCEEDED");
  if (solverData->initHomotopy) {
    data->simulationInfo->homotopySteps += numSteps;
    debugInt(OMC_LOG_INIT_HOMOTOPY, "Total number of lambda steps for this homotopy loop:", numSteps);
  }
  debugString(OMC_LOG_NLS_HOMOTOPY, "======================================================");
  solverData->info = 1;

#if !defined(OMC_NO_FILESYSTEM)
  if(solverData->initHomotopy && OMC_ACTIVE_STREAM(OMC_LOG_INIT_HOMOTOPY))
    fclose(pFile);
#endif

  return 0;
}

/**
 * @brief Solve non-linear system with damped Newton method, combined with homotopy approach.
 *
 * @param data                Pointer to data struct.
 * @param threadData          Pointer to thread data.
 * @param nlsData             Non-linear system data.
* @return NLS_SOLVER_STATUS   Return NLS_SOLVED on success and NLS_FAILED otherwise.
 */
NLS_SOLVER_STATUS solveHomotopy(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nlsData)
{
  DATA_HOMOTOPY* homotopyData = (DATA_HOMOTOPY*)(nlsData->solverData);
  DATA_HYBRD* solverDataHybrid;

  /*
   * Get non-linear equation system
   */
  int eqSystemNumber = nlsData->equationIndex;
  int mixedSystem = nlsData->mixedSystem;

  int i, j;
  NLS_SOLVER_STATUS success = NLS_FAILED;
  double error_f_sqrd, error_f1_sqrd;

  int assert = 1;
  int giveUp = 0;
  int alreadyTested = 0;
  int pos;
  int rank;
  int tries = 0;
  int runHomotopy = 0;
  int skipNewton = 0;
  homotopyData->casualTearingSet = nlsData->strictTearingFunctionCall != NULL;
  int constraintViolated;
  homotopyData->initHomotopy = nlsData->initHomotopy;

  modelica_boolean* relationsPreBackup;
  relationsPreBackup = (modelica_boolean*) malloc(data->modelData->nRelations*sizeof(modelica_boolean));

  homotopyData->f = wrapper_fvec;
  homotopyData->f_con = wrapper_fvec_constraints;
  homotopyData->fJac_f = wrapper_fvec_der;

  homotopyData->eqSystemNumber = nlsData->equationIndex;
  homotopyData->mixedSystem = mixedSystem;
  homotopyData->timeValue = data->localData[0]->timeValue;
  homotopyData->minValue = nlsData->min;
  homotopyData->maxValue = nlsData->max;
  homotopyData->info = 0;

  vecConst(homotopyData->m,1.0,homotopyData->ones);

  if (!homotopyData->initHomotopy) {
    int indexes[2] = {1,eqSystemNumber};
    infoStreamPrintWithEquationIndexes(OMC_LOG_NLS_V, omc_dummyFileInfo, 1, indexes,
      "Start solving Non-Linear System %d (size %d) at time %g with Mixed (Newton/Homotopy) Solver",
      eqSystemNumber, (int) nlsData->size, data->localData[0]->timeValue);
  } else {
    debugString(OMC_LOG_NLS_V, "------------------------------------------------------");
    debugString(OMC_LOG_NLS_V, "SOLVING HOMOTOPY INITIALIZATION PROBLEM WITH THE HOMOTOPY SOLVER");
    debugInt(OMC_LOG_NLS_V, "EQUATION NUMBER:", eqSystemNumber);
    debugDouble(OMC_LOG_NLS_V, "TIME:", homotopyData->timeValue);
  }

  /* set x vector */
  if(data->simulationInfo->discreteCall)
  {
    vecCopy(homotopyData->n, nlsData->nlsx, homotopyData->xStart);
    debugVectorDouble(OMC_LOG_NLS_V,"System values", homotopyData->xStart, homotopyData->n);
  } else
  {
    vecCopy(homotopyData->n, nlsData->nlsxExtrapolation, homotopyData->xStart);
    debugVectorDouble(OMC_LOG_NLS_V,"System extrapolation", homotopyData->xStart, homotopyData->n);
  }
  vecCopy(homotopyData->n, homotopyData->xStart, homotopyData->x0);
  // Initialize lambda variable
  if (homotopyData->userData->nlsData->homotopySupport && !homotopyData->initHomotopy && homotopyData->userData->nlsData->size > homotopyData->n) {
    homotopyData->x0[homotopyData->n] = 1.0;
    homotopyData->x[homotopyData->n] = 1.0;
    homotopyData->x1[homotopyData->n] = 1.0;
  } else {
    homotopyData->x0[homotopyData->n] = 0.0;
    homotopyData->x[homotopyData->n] = 0.0;
    homotopyData->x1[homotopyData->n] = 0.0;
  }
  /* Use actual working point for scaling */
  for (i=0;i<homotopyData->n;i++){
    homotopyData->xScaling[i] = fmax(nlsData->nominal[i],fabs(homotopyData->x0[i]));
  }
  homotopyData->xScaling[homotopyData->n] = 1.0;

  debugVectorDouble(OMC_LOG_NLS_V,"Nominal values", nlsData->nominal, homotopyData->n);
  debugVectorDouble(OMC_LOG_NLS_V,"Scaling values", homotopyData->xScaling, homotopyData->m);


  if (!homotopyData->initHomotopy) {
    /* Handle asserts of function calls, mainly necessary for fluid stuff */
    assert = 1;
    giveUp = 1;
    while (tries<=2)
    {
      debugVectorDouble(OMC_LOG_NLS_V,"x0", homotopyData->x0, homotopyData->n);
      /* evaluate with discontinuities */
      if(data->simulationInfo->discreteCall)
      {
        data->simulationInfo->solveContinuous = 0;
      }
      /* evaluate with discontinuities */
#ifndef OMC_EMCC
      MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
      if (mixedSystem)
        memcpy(relationsPreBackup, data->simulationInfo->relations, sizeof(modelica_boolean)*data->modelData->nRelations);

      if (homotopyData->casualTearingSet){
        constraintViolated = homotopyData->f_con(homotopyData, homotopyData->x0, homotopyData->f1);
        if (constraintViolated){
          giveUp = 1;
          break;
        }
      }
      else
        homotopyData->f(homotopyData, homotopyData->x0, homotopyData->f1);

      /* Try to get out of here!!! */
      error_f_sqrd        = vec2NormSqrd(homotopyData->n, homotopyData->f1);

      homotopyData->fJac_f(homotopyData, homotopyData->x0, homotopyData->fJac);
      vecCopy(homotopyData->n, homotopyData->f1, homotopyData->fJac + homotopyData->n*homotopyData->n);
      vecCopy(homotopyData->n*homotopyData->m, homotopyData->fJac, homotopyData->fJacx0);
      if (mixedSystem)
        memcpy(relationsPreBackup, data->simulationInfo->relations, sizeof(modelica_boolean)*data->modelData->nRelations);
      /* calculate scaling factor of residuals */
      matVecMultAbsBB(homotopyData->n, homotopyData->fJac, homotopyData->ones, homotopyData->resScaling);
      debugVectorDouble(OMC_LOG_NLS_JAC, "residuum scaling:", homotopyData->resScaling, homotopyData->n);
      scaleMatrixRows(homotopyData->n, homotopyData->m, homotopyData->fJac);

      pos = homotopyData->n;
      assert = (solveSystemWithTotalPivotSearch(data, homotopyData->n, homotopyData->dy0, homotopyData->fJac, homotopyData->indRow, homotopyData->indCol, &pos, &rank, homotopyData->casualTearingSet) == -1);
      if (!assert)
        debugString(OMC_LOG_NLS_V, "regular initial point!!!");
      giveUp = 0;
#ifndef OMC_EMCC
      MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
      if (assert && homotopyData->casualTearingSet)
      {
        giveUp = 1;
        break;
      }
      if (assert)
      {
        tries += 1;
      }
      else
        break;
      /* break symmetry, when varying start values */
      /* try to find regular initial point, if necessary */
      if (tries == 1)
      {
        debugString(OMC_LOG_NLS_V, "assert handling:\t vary initial guess by +1%.");
        for(i = 0; i < homotopyData->n; i++)
          homotopyData->x0[i] = homotopyData->xStart[i] + homotopyData->xScaling[i]*i/homotopyData->n*0.01;
      }
      if (tries == 2)
      {
        debugString(OMC_LOG_NLS_V,"assert handling:\t vary initial guess by +10%.");
        for(i = 0; i < homotopyData->n; i++)
          homotopyData->x0[i] = homotopyData->xStart[i] + homotopyData->xScaling[i]*i/homotopyData->n*0.1;
      }
    }
    data->simulationInfo->solveContinuous = 1;
    vecCopy(homotopyData->n, homotopyData->x0, homotopyData->x);
    vecCopy(homotopyData->n, homotopyData->f1, homotopyData->fx0);
  }

  /* start solving loop */
  while(!giveUp && success != NLS_SOLVED)
  {
    giveUp = 1;

    if (!skipNewton && !homotopyData->initHomotopy){

      /* set x vector */
      if(data->simulationInfo->discreteCall){
        memcpy(nlsData->nlsx, homotopyData->x, homotopyData->n*(sizeof(double)));
      }
      else{
        memcpy(nlsData->nlsxExtrapolation, homotopyData->x, homotopyData->n*(sizeof(double)));
      }

      newtonAlgorithm(homotopyData, homotopyData->x);

      // If this is the casual tearing set (only exists for dynamic tearing), break after first try
      if (homotopyData->info == -1 && homotopyData->casualTearingSet){
        infoStreamPrint(OMC_LOG_NLS_V, 0, "### No Solution for the casual tearing set at the first try! ###");
        break;
      }

      if (homotopyData->info == -1){
        solverDataHybrid = (DATA_HYBRD*)(homotopyData->dataHybrid);
        nlsData->solverData = solverDataHybrid;

        homotopyData->info = solveHybrd(data, threadData, nlsData);

        memcpy(homotopyData->x, nlsData->nlsx, homotopyData->n*(sizeof(double)));
        nlsData->solverData = homotopyData;
      }
    }

    /* solution found */
    if(homotopyData->info == 1)
    {
      success = NLS_SOLVED;
      /* This case may be switched off, because of event chattering!!!*/
      if(mixedSystem && data->simulationInfo->discreteCall && (alreadyTested<1))
      {
        debugVectorBool(OMC_LOG_NLS_V,"Relations Pre vector", data->simulationInfo->relationsPre, data->modelData->nRelations);
        debugVectorBool(OMC_LOG_NLS_V,"Relations Backup vector", relationsPreBackup, data->modelData->nRelations);
        data->simulationInfo->solveContinuous = 0;

        if (homotopyData->casualTearingSet){
          constraintViolated = homotopyData->f_con(homotopyData, homotopyData->x, homotopyData->f1);
          if (constraintViolated){
            success = NLS_FAILED;
            break;
          }
        }
        else
          homotopyData->f(homotopyData, homotopyData->x, homotopyData->f1);

        debugVectorBool(OMC_LOG_NLS_V,"Relations vector", data->simulationInfo->relations, data->modelData->nRelations);
        if (isNotEqualVectorInt(data->modelData->nRelations, data->simulationInfo->relations, relationsPreBackup)>0)
        {
          /* re-run the solution process, since relations in the system have changed */
          success = NLS_FAILED;
          giveUp = 0;
          runHomotopy = 0;
          alreadyTested = 1;
          vecCopy(homotopyData->n, homotopyData->x0, homotopyData->x);
          vecCopy(homotopyData->n, homotopyData->fx0, homotopyData->f1);
          vecCopy(homotopyData->n*homotopyData->m, homotopyData->fJacx0, homotopyData->fJac);

          /* calculate scaling factor of residuals */
          matVecMultAbsBB(homotopyData->n, homotopyData->fJac, homotopyData->ones, homotopyData->resScaling);
          scaleMatrixRows(homotopyData->n, homotopyData->m, homotopyData->fJac);

          pos = homotopyData->n;
          solveSystemWithTotalPivotSearch(data, homotopyData->n, homotopyData->dy0, homotopyData->fJac,   homotopyData->indRow, homotopyData->indCol, &pos, &rank, homotopyData->casualTearingSet);
          debugDouble(OMC_LOG_NLS_V,"solve mixed system at time : ", homotopyData->timeValue);
          continue;
        }
      }
      if (success == NLS_SOLVED)
      {
        /* take the solution */
        vecCopy(homotopyData->n, homotopyData->x, nlsData->nlsx);
        /* reset continous flag */
        data->simulationInfo->solveContinuous = 0;
        break;
      }
    }
    if (success != NLS_SOLVED && runHomotopy>=3) break;
    /* Start homotopy search for new start values */
    vecCopy(homotopyData->n, homotopyData->x0, homotopyData->x);
    runHomotopy++;
    /* debug output */
    debugString(OMC_LOG_NLS_HOMOTOPY, "======================================================");

    if (homotopyData->initHomotopy) {
      if (runHomotopy == 1) {
        homotopyData->h_function = wrapper_fvec;
        homotopyData->hJac_dh = wrapper_fvec_der;
        homotopyData->startDirection = omc_flag[FLAG_HOMOTOPY_NEG_START_DIR] ? -1.0 : 1.0;
        debugInt(OMC_LOG_INIT_HOMOTOPY, "Homotopy run: ", runHomotopy);
        debugDouble(OMC_LOG_INIT_HOMOTOPY,"startDirection = ", homotopyData->startDirection);
      }

      if (runHomotopy == 2) {
        homotopyData->h_function = wrapper_fvec;
        homotopyData->hJac_dh = wrapper_fvec_der;
        homotopyData->startDirection = omc_flag[FLAG_HOMOTOPY_NEG_START_DIR] ? 1.0 : -1.0;
        infoStreamPrint(OMC_LOG_ASSERT, 0, "The homotopy algorithm is started again with opposing start direction.");
        debugInt(OMC_LOG_INIT_HOMOTOPY, "Homotopy run: ", runHomotopy);
        debugDouble(OMC_LOG_INIT_HOMOTOPY,"Try again with startDirection = ", homotopyData->startDirection);
      }

      if (runHomotopy == 3) {
        success = NLS_FAILED;
        break;
      }
    }
    else {
      debugInt(OMC_LOG_NLS_HOMOTOPY, "Homotopy run: ", runHomotopy);
      if (runHomotopy == 1)
      {
        /* store x0 and calculate f(x0) -> newton homotopy, fJac(x0) -> taylor, affin homotopy */
        homotopyData->h_function = wrapper_fvec_homotopy_newton;
        homotopyData->hJac_dh = wrapper_fvec_homotopy_newton_der;
        homotopyData->startDirection = 1.0;
        debugDouble(OMC_LOG_NLS_HOMOTOPY,"STARTING NEWTON HOMOTOPY METHOD; startDirection = ", homotopyData->startDirection);
      }
      if (runHomotopy == 2)
      {
        /* store x0 and calculate f(x0) -> newton homotopy, fJac(x0) -> taylor, affin homotopy */
        homotopyData->h_function = wrapper_fvec_homotopy_newton;
        homotopyData->hJac_dh = wrapper_fvec_homotopy_newton_der;
        homotopyData->startDirection = -1.0;
        debugDouble(OMC_LOG_NLS_HOMOTOPY,"STARTING NEWTON HOMOTOPY METHOD; startDirection = ", homotopyData->startDirection);
      }
      if (runHomotopy == 3)
      {
        homotopyData->h_function = wrapper_fvec_homotopy_fixpoint;
        homotopyData->hJac_dh = wrapper_fvec_homotopy_fixpoint_der;
        homotopyData->startDirection = 1.0;
        debugDouble(OMC_LOG_NLS_HOMOTOPY,"STARTING FIXPOINT HOMOTOPY METHOD = ", homotopyData->startDirection);
      }
    }

    homotopyAlgorithm(homotopyData, homotopyData->x);

    if (homotopyData->info<1)
    {
      skipNewton = 1;
      giveUp = runHomotopy>=3;

    } else if (homotopyData->initHomotopy && homotopyData->info==1) {
      /* take the solution */
      vecCopy(homotopyData->n, homotopyData->x, nlsData->nlsx);
      debugVectorDouble(OMC_LOG_NLS_V,"Solution", homotopyData->x, homotopyData->n);
      success = NLS_SOLVED;
    }

    else {
      assert = 1;
#ifndef OMC_EMCC
      MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
      if (homotopyData->casualTearingSet){
        constraintViolated = homotopyData->f_con(homotopyData, homotopyData->x, homotopyData->f1);
        if (constraintViolated){
          success = NLS_FAILED;
          break;
        }
      }
      else
        homotopyData->f(homotopyData, homotopyData->x, homotopyData->f1);

      homotopyData->fJac_f(homotopyData, homotopyData->x, homotopyData->fJac);
      vecCopy(homotopyData->n, homotopyData->f1, homotopyData->fJac + homotopyData->n*homotopyData->n);
      /* calculate scaling factor of residuals */
      matVecMultAbsBB(homotopyData->n, homotopyData->fJac, homotopyData->ones, homotopyData->resScaling);
      debugVectorDouble(OMC_LOG_NLS_JAC, "residuum scaling:", homotopyData->resScaling, homotopyData->n);
      scaleMatrixRows(homotopyData->n, homotopyData->m, homotopyData->fJac);

      pos = homotopyData->n;
      assert = (solveSystemWithTotalPivotSearch(data, homotopyData->n, homotopyData->dy0, homotopyData->fJac,   homotopyData->indRow, homotopyData->indCol, &pos, &rank, homotopyData->casualTearingSet) == -1);
      if (!assert)
        debugString(OMC_LOG_NLS_V, "regular initial point!!!");
#ifndef OMC_EMCC
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
 #endif
      if (assert)
      {
        giveUp = 1;
      } else
      {
        giveUp = 0;
        skipNewton = 0;
      }
    }
  }
  if (success != NLS_SOLVED)
  {
    debugString(OMC_LOG_NLS_V,"Homotopy solver did not converge!");
  }
  free(relationsPreBackup);

  messageClose(OMC_LOG_NLS_V);

  /* write statistics */
  nlsData->numberOfFEval = homotopyData->numberOfFunctionEvaluations;
  nlsData->numberOfIterations = homotopyData->numberOfIterations;

  return success;
}

/**
 * @brief Return pointer to Jacobian.
 *
 * @param nlsData     Non-linear system data.
 * @return double*    Jacobian in row-major format.
 */
double* getHomotopyJacobian(NONLINEAR_SYSTEM_DATA* nlsData) {
  DATA_HOMOTOPY* homotopyData = (DATA_HOMOTOPY*)(nlsData->solverData);
  return homotopyData->fJac;
}

#endif
