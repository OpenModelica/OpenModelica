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

/*! \file kinsolSolver.c
 */

#include "omc_config.h"
#include "nonlinearSystem.h"
#include "kinsolSolver.h"
#include "simulation/simulation_info_json.h"
#include "simulation/options.h"
#include "util/omc_error.h"
#include "omc_math.h"

#ifdef WITH_SUNDIALS

/* adrpo: on mingw link with static sundials */
#if defined(__MINGW32__)
#define LINK_SUNDIALS_STATIC
#endif

#include <math.h>
#include <stdlib.h>
#include <string.h> /* memcpy */

#include "util/varinfo.h"
#include "openmodelica.h"
#include "openmodelica_func.h"
#include "model_help.h"
#include "util/read_matlab4.h"
#include "events.h"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <kinsol/kinsol.h>
#include <kinsol/kinsol_impl.h>
#include <kinsol/kinsol_dense.h>
#include <kinsol/kinsol_lapack.h>
#include <kinsol/kinsol_direct.h>
#include <kinsol/kinsol_klu.h>
#include <sundials/sundials_nvector.h>
#include <nvector/nvector_serial.h>
#include <sundials/sundials_types.h>
#include <sundials/sundials_math.h>


/* constants */
#define RETRY_MAX 5
#define FTOL_WITH_LESS_ACCURANCY 1.e-6

/* readability */
#define INITIAL_EXTRAPOLATION 0
#define INITIAL_OLDVALUES     1

#define SCALING_NOMINALSTART  1
#define SCALING_ONES          2
#define SCALING_JACOBIAN      3



typedef struct NLS_KINSOL_USERDATA
{
  DATA* data;
  threadData_t* threadData;

  int sysNumber;
}NLS_KINSOL_USERDATA;

typedef struct NLS_KINSOL_DATA
{
  /* ### configuration  ### */
  int linearSolverMethod;     /* specifies the method to solve the underlying linear problem */
  int nonLinearSystemNumber;
  int kinsolStrategy;
  int retries;
  int solved;                 /* if the system is once solved reuse linear matrix information */
  int nominalJac;

  /* ### tolerances ### */
  double fnormtol;        /* function tolerance */
  double scsteptol;       /* step tolerance */
  double maxstepfactor;   /* maximum newton step factor mxnewtstep = maxstepfactor * norm2(xScaling) */

  /* ### work arrays ### */
  N_Vector initialGuess;
  N_Vector xScale;
  N_Vector fScale;
  N_Vector fRes;
  N_Vector fTmp;

  int iflag;
  long countResCalls;        /* case of sparse function not avaiable */

  /* ### kinsol internal data */
  void* kinsolMemory;
  NLS_KINSOL_USERDATA userData;

  /* settings */
  int size;
  int nnz;

}NLS_KINSOL_DATA;

static int nlsKinsolResiduals(N_Vector z, N_Vector f, void *userData);
static void nlsKinsolErrorPrint(int error_code, const char *module, const char *function, char *msg, void *userData);
static void nlsKinsolInfoPrint(const char *module, const char *function, char *msg, void *userData);
static int nlsSparseJac(N_Vector x, N_Vector fx, SlsMat Jac, void *userData, N_Vector tmp1, N_Vector tmp2);
static int nlsSparseSymJac(N_Vector x, N_Vector fx, SlsMat Jac, void *userData, N_Vector tmp1, N_Vector tmp2);
static int nlsDenseJac(long int N, N_Vector x, N_Vector fx, DlsMat Jac, void *userData, N_Vector tmp1, N_Vector tmp2);
static void nlsKinsolJacSumSparse(SlsMat mat);
static void nlsKinsolJacSumDense(DlsMat mat);



int checkReturnFlag(int flag)
{
  int retVal = flag;
  switch(flag)
  {
  case KIN_SUCCESS:
    retVal = 0;
    break;
  case KIN_MEM_NULL:
  case KIN_MEM_FAIL:
  case KIN_ILL_INPUT:
    retVal = -1;
    break;
  }
  return retVal;
}

static
void nlsKinsolConfigSetup(NLS_KINSOL_DATA *kinsolData)
{
  /* configuration */
  KINSetFuncNormTol(kinsolData->kinsolMemory, kinsolData->fnormtol);
  KINSetScaledStepTol(kinsolData->kinsolMemory, kinsolData->scsteptol);
  KINSetNumMaxIters(kinsolData->kinsolMemory, 100*kinsolData->size);
  kinsolData->kinsolStrategy = KIN_LINESEARCH;
  /* configuration for exact Newton */
  /*
  KINSetMaxSetupCalls(kinsolData->kinsolMemory, 1);
  KINSetMaxSubSetupCalls(kinsolData->kinsolMemory, 1);
  */

  KINSetNoInitSetup(kinsolData->kinsolMemory, FALSE);

  kinsolData->retries = 0;
  kinsolData->countResCalls = 0;
}

static void resetKinsolMemory(NLS_KINSOL_DATA *kinsolData, NONLINEAR_SYSTEM_DATA *nlsData)
{
  int flag, size = kinsolData->size, printLevel;
  if (kinsolData->kinsolMemory) {
    KINFree((void*)&kinsolData->kinsolMemory);
  }
  kinsolData->kinsolMemory = KINCreate();
  /* setup user defined functions */
  KINSetErrHandlerFn(kinsolData->kinsolMemory, nlsKinsolErrorPrint, kinsolData);
  KINSetInfoHandlerFn(kinsolData->kinsolMemory, nlsKinsolInfoPrint, kinsolData);
  KINSetUserData(kinsolData->kinsolMemory, (void*)&(kinsolData->userData));
  flag = KINInit(kinsolData->kinsolMemory, nlsKinsolResiduals, kinsolData->initialGuess);
  if (checkReturnFlag(flag)){
    errorStreamPrint(LOG_STDOUT, 0, "##KINSOL## Something goes wrong while initialize KINSOL solver!");
  }
  /* Specify linear solver and/or corresponding jacobian function*/
  if (kinsolData->linearSolverMethod == NLS_LS_KLU)
  {
    if(nlsData->isPatternAvailable)
    {
      kinsolData->nnz = nlsData->sparsePattern->numberOfNoneZeros;
      flag = KINKLU(kinsolData->kinsolMemory, size, kinsolData->nnz);
      if (checkReturnFlag(flag)){
        errorStreamPrint(LOG_STDOUT, 0, "##KINSOL## Something goes wrong while initialize KINSOL solver!");
      }
      if (nlsData->analyticalJacobianColumn != NULL){
        flag = KINSlsSetSparseJacFn(kinsolData->kinsolMemory, nlsSparseSymJac);
      }
      else {
        flag = KINSlsSetSparseJacFn(kinsolData->kinsolMemory, nlsSparseJac);
      }
      if (checkReturnFlag(flag)){
        errorStreamPrint(LOG_STDOUT, 0, "##KINSOL## Something goes wrong while initialize KINSOL Sparse Solver!");
      }
    } else {
      flag = KINDense(kinsolData->kinsolMemory, size);
      if (checkReturnFlag(flag)){
        errorStreamPrint(LOG_STDOUT, 0, "##KINSOL## Something goes wrong while initialize KINSOL solver!");
      }
    }
  }
  else if (kinsolData->linearSolverMethod == NLS_LS_TOTALPIVOT)
  {
    flag = KINDense(kinsolData->kinsolMemory, size);
    if (checkReturnFlag(flag)){
      errorStreamPrint(LOG_STDOUT, 0, "##KINSOL## Something goes wrong while initialize KINSOL solver!");
    }
  }
  else if (kinsolData->linearSolverMethod == NLS_LS_LAPACK)
  {
    flag = KINDense(kinsolData->kinsolMemory, size);
    if (checkReturnFlag(flag)){
      errorStreamPrint(LOG_STDOUT, 0, "##KINSOL## Something goes wrong while initialize KINSOL solver!");
    }
    flag = KINDlsSetDenseJacFn(kinsolData->kinsolMemory, nlsDenseJac);
    if (checkReturnFlag(flag)){
      errorStreamPrint(LOG_STDOUT, 0, "##KINSOL## Something goes wrong while initialize KINSOL Sparse Solver!");
    }
  }

  /* configuration */
  nlsKinsolConfigSetup(kinsolData);

  /* debug print level of kinsol */
  if (ACTIVE_STREAM(LOG_NLS_V)) {
    printLevel = 3;
  } else if (ACTIVE_STREAM(LOG_NLS)) {
    printLevel = 1;
  } else {
    printLevel = 0;
  }
  KINSetPrintLevel(kinsolData->kinsolMemory, printLevel);
}

int nlsKinsolAllocate(int size, NONLINEAR_SYSTEM_DATA *nlsData, int linearSolverMethod)
{
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA*) malloc(sizeof(NLS_KINSOL_DATA));

  /* allocate system data */
  nlsData->solverData = (void*)kinsolData;

  kinsolData->size = size;
  kinsolData->linearSolverMethod = linearSolverMethod;
  kinsolData->solved = 0;

  kinsolData->fnormtol  = newtonFTol;     /* function tolerance */
  kinsolData->scsteptol = newtonXTol;     /* step tolerance */

  kinsolData->maxstepfactor = maxStepFactor;     /* step tolerance */
  kinsolData->nominalJac = 0;             /* calculate for scaling the scaled matrix */

  kinsolData->initialGuess = N_VNew_Serial(size);
  kinsolData->xScale = N_VNew_Serial(size);
  kinsolData->fScale = N_VNew_Serial(size);
  kinsolData->fRes = N_VNew_Serial(size);
  kinsolData->fTmp = N_VNew_Serial(size);

  kinsolData->kinsolMemory = NULL;

  resetKinsolMemory(kinsolData, nlsData);

  return 0;
}

int nlsKinsolFree(void** solverData)
{
  NLS_KINSOL_DATA* kinsolData = (NLS_KINSOL_DATA*) *solverData;

  KINFree((void*)&kinsolData->kinsolMemory);

  N_VDestroy_Serial(kinsolData->initialGuess);
  N_VDestroy_Serial(kinsolData->xScale);
  N_VDestroy_Serial(kinsolData->fScale);
  N_VDestroy_Serial(kinsolData->fRes);
  N_VDestroy_Serial(kinsolData->fTmp);
  free(kinsolData);

  return 0;
}

 /*! \fn nlsKinsolResiduals
 *
 *  \param [in]  [x]
 *  \param [out] [f]
 *  \param [ref] [user_data]
 *
 */
static int nlsKinsolResiduals(N_Vector x, N_Vector f, void *userData)
{
  double *xdata = NV_DATA_S(x);
  double *fdata = NV_DATA_S(f);

  NLS_KINSOL_USERDATA *kinsolUserData = (NLS_KINSOL_USERDATA*) userData;
  DATA* data = kinsolUserData->data;
  threadData_t *threadData = kinsolUserData->threadData;
  int sysNumber = kinsolUserData->sysNumber;
  void *dataAndThreadData[2] = {data, threadData};
  NONLINEAR_SYSTEM_DATA *nlsData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  NLS_KINSOL_DATA* kinsolData = (NLS_KINSOL_DATA*) nlsData->solverData;
  long eqSystemNumber = nlsData->equationIndex;
  int iflag = 1;

  kinsolData->countResCalls++;

#ifndef OMC_EMCC
    MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /* call residual function */
  data->simulationInfo->nonlinearSystemData[sysNumber].residualFunc(dataAndThreadData, xdata,  fdata, (const int*) &iflag);
  iflag = 0;

#ifndef OMC_EMCC
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  return iflag;
}

/*
 *  function calculates a jacobian matrix
 */
static
int nlsDenseJac(long int N, N_Vector vecX, N_Vector vecFX, DlsMat Jac, void *userData, N_Vector tmp1, N_Vector tmp2)
{
  NLS_KINSOL_USERDATA *kinsolUserData = (NLS_KINSOL_USERDATA*) userData;
  DATA* data = kinsolUserData->data;
  threadData_t *threadData = kinsolUserData->threadData;
  int sysNumber = kinsolUserData->sysNumber;
  NONLINEAR_SYSTEM_DATA *nlsData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  NLS_KINSOL_DATA* kinsolData = (NLS_KINSOL_DATA*) nlsData->solverData;

  /* prepare variables */
  double *x = N_VGetArrayPointer(vecX);
  double *fx = N_VGetArrayPointer(vecFX);
  double *xScaling = NV_DATA_S(kinsolData->xScale);
  double *fRes = NV_DATA_S(kinsolData->fRes);
  double xsave, xscale, sign;
  double delta_hh;
  const double delta_h = sqrt(DBL_EPSILON*2e1);

  long int i,j;

  /* performance measurement */
  rt_ext_tp_tick(&nlsData->jacobianTimeClock);

  for(i = 0; i < N; i++)
  {
    xsave = x[i];
    delta_hh = delta_h * (fabs(xsave) + 1.0);
    if ((xsave + delta_hh >=  nlsData->max[i]))
      delta_hh *= -1;
    x[i] += delta_hh;

    /* Calculate difference quotient */
    nlsKinsolResiduals(vecX, kinsolData->fRes, userData);

    /* Calculate scaled difference quotient */
    delta_hh = 1. / delta_hh;

    for(j = 0; j < N; j++)
    {
      if (kinsolData->nominalJac){
        DENSE_ELEM(Jac, j, i) = (fRes[j] - fx[j]) * delta_hh  / xScaling[i];
      }else{
        DENSE_ELEM(Jac, j, i) = (fRes[j] - fx[j]) * delta_hh;
      }

    }
    x[i] = xsave;
  }

  /* debug */
  if (ACTIVE_STREAM(LOG_NLS_JAC)){
    infoStreamPrint(LOG_NLS_JAC, 1, "##KINSOL## omc dense matrix.");
    PrintSparseMat(SlsConvertDls(Jac));
    nlsKinsolJacSumDense(Jac);
    messageClose(LOG_NLS_JAC);
  }

  /* performance measurement and statistics */
  nlsData->jacobianTime += rt_ext_tp_tock(&(nlsData->jacobianTimeClock));
  nlsData->numberOfJEval++;

  return 0;
}

/* Element function for sparse matrix set */
static void setJacElementKluSparse(int row, int col, double value, int nth, void* spJac)
{
  SlsMat mat = (SlsMat)spJac;
  if (col > 0 && mat->colptrs[col] == 0){
      mat->colptrs[col] = nth;
  }
  mat->rowvals[nth] = row;
  mat->data[nth] = value;
}

/* finish sparse matrix, by fixing colprts */
static void finishSparseColPtr(SlsMat mat)
{
  int i;
  /* finish matrix colptrs */
  mat->colptrs[mat->N] = mat->NNZ;
  for(i=1; i<mat->N+1; ++i){
    if (mat->colptrs[i] == 0){
      warningStreamPrint(LOG_STDOUT, 0, "##KINSOL## Jacobian row %d singular. See LOG_NLS for more information.", i);
      mat->colptrs[i] = mat->colptrs[i-1];
    }
  }
}

/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences with coloring
 *  into a sparse SlsMat matrix
 */
static
int nlsSparseJac(N_Vector vecX, N_Vector vecFX, SlsMat Jac, void *userData, N_Vector tmp1, N_Vector tmp2)
{
  NLS_KINSOL_USERDATA *kinsolUserData = (NLS_KINSOL_USERDATA*) userData;
  DATA* data = kinsolUserData->data;
  threadData_t *threadData = kinsolUserData->threadData;
  int sysNumber = kinsolUserData->sysNumber;
  NONLINEAR_SYSTEM_DATA *nlsData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  NLS_KINSOL_DATA* kinsolData = (NLS_KINSOL_DATA*) nlsData->solverData;

  /* prepare variables */
  double *x = N_VGetArrayPointer(vecX);
  double *fx = N_VGetArrayPointer(vecFX);
  double *xsave = N_VGetArrayPointer(tmp1);
  double *delta_hh = N_VGetArrayPointer(tmp2);
  double *xScaling = NV_DATA_S(kinsolData->xScale);
  double *fRes = NV_DATA_S(kinsolData->fRes);

  SPARSE_PATTERN* sparsePattern = nlsData->sparsePattern;

  const double delta_h = sqrt(DBL_EPSILON*2e1);

  long int i,j,ii;
  int nth = 0;

  /* performance measurement */
  rt_ext_tp_tick(&nlsData->jacobianTimeClock);

  /* reset matrix */
  SlsSetToZero(Jac);

  for(i = 0; i < sparsePattern->maxColors; i++)
  {
    for(ii=0; ii < kinsolData->size; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        xsave[ii] = x[ii];
        delta_hh[ii] = delta_h * (fabs(xsave[ii]) + 1.0);
        if ((xsave[ii] + delta_hh[ii] >=  nlsData->max[ii]))
          delta_hh[ii] *= -1;
        x[ii] += delta_hh[ii];

        /* Calculate scaled difference quotient */
        delta_hh[ii] = 1. / delta_hh[ii];
      }
    }
    nlsKinsolResiduals(vecX, kinsolData->fRes, userData);

    for(ii = 0; ii < kinsolData->size; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        nth = sparsePattern->leadindex[ii];
        while(nth < sparsePattern->leadindex[ii+1])
        {
          j  =  sparsePattern->index[nth];
          if (kinsolData->nominalJac){
            setJacElementKluSparse(j, ii, (fRes[j] - fx[j]) * delta_hh[ii] / xScaling[ii], nth, Jac);
          }else{
            setJacElementKluSparse(j, ii, (fRes[j] - fx[j]) * delta_hh[ii], nth, Jac);
          }
          nth++;
        };
        x[ii] = xsave[ii];
      }
    }
  }
  /* finish sparse matrix */
  finishSparseColPtr(Jac);

  /* debug */
  if (ACTIVE_STREAM(LOG_NLS_JAC)){
    infoStreamPrint(LOG_NLS_JAC, 1, "##KINSOL## Sparse Matrix.");
    PrintSparseMat(Jac);
    nlsKinsolJacSumSparse(Jac);
    messageClose(LOG_NLS_JAC);
  }

  /* performance measurement and statistics */
  nlsData->jacobianTime += rt_ext_tp_tock(&(nlsData->jacobianTimeClock));
  nlsData->numberOfJEval++;

  return 0;
}

/*! \fn nlsSparseSymJac
 *
 *  function calculates symbolic jacobian
 *
 *  \param [ref] [data]
 *  \param [in]  [sysNumber]

 */
static
int nlsSparseSymJac(N_Vector vecX, N_Vector vecFX, SlsMat Jac, void *userData, N_Vector tmp1, N_Vector tmp2)
{
  NLS_KINSOL_USERDATA *kinsolUserData = (NLS_KINSOL_USERDATA*) userData;
  DATA* data = kinsolUserData->data;
  threadData_t *threadData = kinsolUserData->threadData;
  int sysNumber = kinsolUserData->sysNumber;
  NONLINEAR_SYSTEM_DATA *nlsData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  NLS_KINSOL_DATA* kinsolData = (NLS_KINSOL_DATA*) nlsData->solverData;

  /* prepare variables */
  double *x = N_VGetArrayPointer(vecX);
  double *fx = N_VGetArrayPointer(vecFX);
  double *xScaling = NV_DATA_S(kinsolData->xScale);

  SPARSE_PATTERN* sparsePattern = nlsData->sparsePattern;
  ANALYTIC_JACOBIAN* analyticJacobian = &data->simulationInfo->analyticJacobians[nlsData->jacobianIndex];

  long int i,j,ii;
  int nth = 0;
  int nnz = sparsePattern->numberOfNoneZeros;

  /* performance measurement */
  rt_ext_tp_tick(&nlsData->jacobianTimeClock);

  /* reset matrix */
  SlsSetToZero(Jac);

  if (analyticJacobian->constantEqns != NULL) {
    analyticJacobian->constantEqns(data, threadData, analyticJacobian, NULL);
  }

  for(i = 0; i < sparsePattern->maxColors; i++)
  {
    for(ii=0; ii < kinsolData->size; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        analyticJacobian->seedVars[ii] = 1.0;
      }
    }
    ((nlsData->analyticalJacobianColumn))(data, threadData, analyticJacobian, NULL);

    for(ii = 0; ii < kinsolData->size; ii++)
    {
      if(sparsePattern->colorCols[ii]-1 == i)
      {
        nth = sparsePattern->leadindex[ii];
        while(nth < sparsePattern->leadindex[ii+1])
        {
          j  =  sparsePattern->index[nth];
          if (kinsolData->nominalJac){
            setJacElementKluSparse(j, ii, analyticJacobian->resultVars[j] / xScaling[ii] , nth, Jac);
          }else{
            setJacElementKluSparse(j, ii, analyticJacobian->resultVars[j], nth, Jac);
          }
          nth++;
        };
        analyticJacobian->seedVars[ii] = 0;
      }
    }
  }
  /* finish sparse matrix */
  finishSparseColPtr(Jac);

  /* debug */
  if (ACTIVE_STREAM(LOG_NLS_JAC)){
    infoStreamPrint(LOG_NLS_JAC, 1, "##KINSOL## Sparse Matrix.");
    PrintSparseMat(Jac);
    nlsKinsolJacSumSparse(Jac);
    messageClose(LOG_NLS_JAC);
  }

  /* performance measurement and statistics */
  nlsData->jacobianTime += rt_ext_tp_tock(&(nlsData->jacobianTimeClock));
  nlsData->numberOfJEval++;

  return 0;
}

static
void nlsKinsolJacSumDense(DlsMat mat)
{
  int i,j;
  double sum;

  for(i=0; i<mat->M; ++i){
    sum = 0.0;
    for(j=0; j<mat->N;++j){
      sum += fabs(DENSE_ELEM(mat,j,i));
    }

    if (sum == 0.0){
      warningStreamPrint(LOG_NLS_V, 0, "sum of col %d of jacobian is zero!", i);
    }else{
      infoStreamPrint(LOG_NLS_JAC, 0, "col %d jac sum = %g", i, sum);
    }

  }
}

static
void nlsKinsolJacSumSparse(SlsMat mat)
{
  int i,j;
  double sum;

  for(i=0; i<mat->N; ++i){
    sum = 0.0;
    for(j=mat->colptrs[i]; j<mat->colptrs[i+1];++j){
      sum += fabs(mat->data[j]);
    }

    if (sum == 0.0){
      warningStreamPrint(LOG_NLS_V, 0, "sum of col %d of jacobian is zero!", i);
    }else{
      infoStreamPrint(LOG_NLS_JAC, 0, "col %d jac sum = %g", i, sum);
    }

  }
}


static
void nlsKinsolErrorPrint(int errorCode, const char *module, const char *function, char *msg, void *userData)
{
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA*) userData;
  DATA* data = kinsolData->userData.data;
  int sysNumber = kinsolData->userData.sysNumber;
  long eqSystemNumber = data->simulationInfo->nonlinearSystemData[sysNumber].equationIndex;

  if (ACTIVE_STREAM(LOG_NLS_V))
  {
    warningStreamPrint(LOG_NLS_V, 1, "kinsol failed for %d", modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).id);
    warningStreamPrint(LOG_NLS_V, 0, "[module] %s | [function] %s | [error_code] %d", module, function, errorCode);
    warningStreamPrint(LOG_NLS_V, 0, "%s", msg);

    messageClose(LOG_NLS_V);
  }
}

static
void nlsKinsolInfoPrint(const char *module, const char *function, char *msg, void *user_data)
{
  if (ACTIVE_STREAM(LOG_NLS_V))
  {
    warningStreamPrint(LOG_NLS_V, 1, "%s %s:", module, function);
    warningStreamPrint(LOG_NLS_V, 0, "%s", msg);

    messageClose(LOG_NLS_V);
  }
}

static
void nlsKinsolSetMaxNewtonStep(NLS_KINSOL_DATA *kinsolData, double maxstepfactor)
{
  /* set maximum step size */
  N_VConst(maxstepfactor, kinsolData->fTmp);
  KINSetMaxNewtonStep(kinsolData->kinsolMemory, N_VWL2Norm(kinsolData->xScale, kinsolData->fTmp));

}

static
void nlsKinsolResetInitial(DATA* data, NLS_KINSOL_DATA *kinsolData, NONLINEAR_SYSTEM_DATA* nlsData, int mode)
{
  double *xStart = NV_DATA_S(kinsolData->initialGuess);
  /* set x vector */
  switch (mode)
  {
    case INITIAL_EXTRAPOLATION:
      if(data->simulationInfo->discreteCall) {
        memcpy(xStart, nlsData->nlsx, nlsData->size*(sizeof(double)));
      } else {
        memcpy(xStart, nlsData->nlsxExtrapolation, nlsData->size*(sizeof(double)));
      }
      break;
    case INITIAL_OLDVALUES:
      memcpy(xStart, nlsData->nlsxOld, nlsData->size*(sizeof(double)));
      break;
  }
}

static
void nlsKinsolXScaling(DATA* data, NLS_KINSOL_DATA *kinsolData, NONLINEAR_SYSTEM_DATA* nlsData, int mode)
{
  double *xStart = NV_DATA_S(kinsolData->initialGuess);
  double *xScaling = NV_DATA_S(kinsolData->xScale);
  int i;

  /* if noScaling flag is used overwrite mode */
  if (omc_flag[FLAG_NO_SCALING])
  {
    mode = SCALING_ONES;
  }

  /* Use nominal value or the actual working point for scaling */
  switch (mode)
  {
    case SCALING_NOMINALSTART:
      for (i=0;i<nlsData->size;i++){
        xScaling[i] = 1.0/fmax(nlsData->nominal[i],fabs(xStart[i]));
      }
      break;
    case SCALING_ONES:
      for (i=0;i<nlsData->size;i++){
        xScaling[i] = 1.0;
      }
      break;
  }
}

static
void nlsKinsolFScaling(DATA* data, NLS_KINSOL_DATA *kinsolData, NONLINEAR_SYSTEM_DATA* nlsData, int mode)
{
  double *fScaling = NV_DATA_S(kinsolData->fScale);
  N_Vector x = kinsolData->initialGuess;
  int i,j;
  SlsMat spJac;

  /* if noScaling flag is used overwrite mode */
  if (omc_flag[FLAG_NO_SCALING])
  {
    mode = SCALING_ONES;
  }

  /* Use nominal value or the actual working point for scaling */
  switch (mode)
  {
    case SCALING_JACOBIAN:
    {
      N_Vector tmp1 = N_VNew_Serial(kinsolData->size);
      N_Vector tmp2 = N_VNew_Serial(kinsolData->size);

      /* enable scaled jacobian */
      kinsolData->nominalJac = 1;

      /* update x for the matrix */
      nlsKinsolResiduals(x, kinsolData->fTmp, &kinsolData->userData);

      /* calculate the right jacobian */
      if(nlsData->isPatternAvailable && kinsolData->linearSolverMethod == NLS_LS_KLU)
      {
        spJac = NewSparseMat(kinsolData->size,kinsolData->size,kinsolData->nnz);
        if (nlsData->analyticalJacobianColumn != NULL){
          nlsSparseSymJac(x, kinsolData->fTmp, spJac, &kinsolData->userData, tmp1, tmp2);
        } else {
          nlsSparseJac(x, kinsolData->fTmp, spJac, &kinsolData->userData, tmp1, tmp2);
        }
      }
      else
      {
        DlsMat denseJac = NewDenseMat(kinsolData->size,kinsolData->size);
        nlsDenseJac(nlsData->size, x, kinsolData->fTmp, denseJac, &kinsolData->userData, tmp1, tmp2);
        spJac = SlsConvertDls(denseJac);
      }
      /* disable scaled jacobian */
      kinsolData->nominalJac = 0;

      for (i=0;i<nlsData->size;i++){
        fScaling[i] = 1e-12;
      }
      for(i=0; i<spJac->NNZ; ++i){
        if (fScaling[spJac->rowvals[i]] < fabs(spJac->data[i])){
          fScaling[spJac->rowvals[i]] = fabs(spJac->data[i]);
        }
      }
      N_VInv(kinsolData->fScale, kinsolData->fScale);

      DestroySparseMat(spJac);
      N_VDestroy_Serial(tmp1);
      N_VDestroy_Serial(tmp2);
      break;
    }
    case SCALING_ONES:
      for (i=0;i<nlsData->size;i++){
        fScaling[i] = 1.0;
      }
      break;
  }
}

static
void nlsKinsolConfigPrint(NLS_KINSOL_DATA *kinsolData, NONLINEAR_SYSTEM_DATA *nlsData)
{
  int retValue;
  double fNorm;
  DATA* data = kinsolData->userData.data;
  int eqSystemNumber = nlsData->equationIndex;
  _omc_vector vecStart, vecXScaling, vecFScaling;

  if (!useStream[LOG_NLS_V]) {
    return;
  }

  _omc_initVector(&vecStart, kinsolData->size, NV_DATA_S(kinsolData->initialGuess));
  _omc_initVector(&vecXScaling, kinsolData->size, NV_DATA_S(kinsolData->xScale));
  _omc_initVector(&vecFScaling, kinsolData->size, NV_DATA_S(kinsolData->fScale));

  infoStreamPrint(LOG_NLS_V, 1, "Kinsol Configuration");
  _omc_printVectorWithEquationInfo(&vecStart,
      "Initial guess values", LOG_NLS_V, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber));

  _omc_printVectorWithEquationInfo(&vecXScaling,
      "xScaling", LOG_NLS_V, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber));

  _omc_printVector(&vecFScaling, "fScaling", LOG_NLS_V);

  infoStreamPrint(LOG_NLS_V, 0, "KINSOL F tolerance: %g", (*(KINMem)kinsolData->kinsolMemory).kin_fnormtol);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL minimal step size %g", (*(KINMem)kinsolData->kinsolMemory).kin_scsteptol);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL max iterations %d", 20*kinsolData->size);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL strategy %d", kinsolData->kinsolStrategy);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL current retry %d", kinsolData->retries);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL max step %g", (*(KINMem)kinsolData->kinsolMemory).kin_mxnstepin);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL linear solver %d", kinsolData->linearSolverMethod);

  messageClose(LOG_NLS_V);
}

static
int nlsKinsolErrorHandler(int errorCode, DATA *data, NONLINEAR_SYSTEM_DATA *nlsData, NLS_KINSOL_DATA *kinsolData)
{
  int retValue, i, retValue2=0, flag;
  double fNorm;
  double *xStart = NV_DATA_S(kinsolData->initialGuess);
  double *xScaling = NV_DATA_S(kinsolData->xScale);
  long outL;

  /* check what kind of error
   *   retValue < 0 -> a non recoverable issue
   *   retValue == 1 -> try with other settings
   */
  KINSetNoInitSetup(kinsolData->kinsolMemory, FALSE);

  switch(errorCode)
  {
  case KIN_MEM_NULL:
  case KIN_ILL_INPUT:
  case KIN_NO_MALLOC:
    errorStreamPrint(LOG_NLS_V, 0, "kinsol has a serious memory issue ERROR %d\n", errorCode);
    return errorCode;
    break;
  /* just retry with new initial guess */
  case KIN_MXNEWT_5X_EXCEEDED:
    warningStreamPrint(LOG_NLS_V, 0, "Newton step exceed the maximum step size several times. Try again after increasing maximum step size.\n");
    kinsolData->maxstepfactor *= 1e5;
    nlsKinsolSetMaxNewtonStep(kinsolData, kinsolData->maxstepfactor);
    return 1;
    break;
  /* just retry without line search */
  case KIN_LINESEARCH_NONCONV:
    warningStreamPrint(LOG_NLS_V, 0, "kinsols line search did not convergence. Try without.\n");
    kinsolData->kinsolStrategy = KIN_NONE;
    kinsolData->retries--;
    return 1;
  /* maybe happened because of an out-dated factorization, so just retry  */
  case KIN_LSOLVE_FAIL:
    warningStreamPrint(LOG_NLS_V, 0, "kinsols matrix need new factorization. Try again.\n");
    if (nlsData->isPatternAvailable){
      KINKLUReInit(kinsolData->kinsolMemory, kinsolData->size, kinsolData->nnz, 2);
    }
    return 1;
  case KIN_MAXITER_REACHED:
  case KIN_REPTD_SYSFUNC_ERR:
    warningStreamPrint(LOG_NLS_V, 0, "kinsols runs into issues retry with different configuration.\n");
    retValue = 1;
    break;
  case KIN_LSETUP_FAIL:
    /* in case of something goes wrong with the symbolic jacobian try the numerical */
    if ( kinsolData->linearSolverMethod == NLS_LS_KLU && nlsData->isPatternAvailable && nlsData->analyticalJacobianColumn != NULL){
      flag = KINSlsSetSparseJacFn(kinsolData->kinsolMemory, nlsSparseJac);
    }
    if (checkReturnFlag(flag)){
      errorStreamPrint(LOG_STDOUT, 0, "##KINSOL## Something goes wrong while initialize KINSOL Sparse Solver!");
      return flag;
    }
    else
    {
      retValue = 1;
    }
    break;
  case KIN_LINESEARCH_BCFAIL:
    KINGetNumBetaCondFails(kinsolData->kinsolMemory, &outL);
    warningStreamPrint(LOG_NLS_V, 0, "kinsols runs into issues with beta-condition fails: %ld\n", outL);
    retValue = 1;
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "kinsol has a serious solving issue ERROR %d\n", errorCode);
    return errorCode;
    break;
  }

  /* check if the current solution is sufficient anyway */
  KINGetFuncNorm(kinsolData->kinsolMemory, &fNorm);
  if (fNorm<FTOL_WITH_LESS_ACCURANCY)
  {
    warningStreamPrint(LOG_NLS_V, 0, "Move forward with a less accurate solution.");
    KINSetFuncNormTol(kinsolData->kinsolMemory, FTOL_WITH_LESS_ACCURANCY);
    KINSetScaledStepTol(kinsolData->kinsolMemory, FTOL_WITH_LESS_ACCURANCY);
    retValue2 = 1;
  }
  else
  {
    warningStreamPrint(LOG_NLS_V, 0, "Current status of fx = %f", fNorm);
  }

  /* reconfigure kinsol for an other try */
  if (retValue == 1 && !retValue2)
  {
    switch(kinsolData->retries)
    {
    case 0:
      /* try without scaling  */
      nlsKinsolXScaling(data, kinsolData, nlsData, SCALING_ONES);
      nlsKinsolFScaling(data, kinsolData, nlsData, SCALING_ONES);
      break;
    case 1:
      /* try without line-search and oldValues */
      nlsKinsolResetInitial(data, kinsolData, nlsData, INITIAL_OLDVALUES);
      kinsolData->kinsolStrategy = KIN_LINESEARCH;
      break;
    case 2:
      /* try without line-search and oldValues */
      nlsKinsolResetInitial(data, kinsolData, nlsData, INITIAL_EXTRAPOLATION);
      kinsolData->kinsolStrategy = KIN_NONE;
      break;
    case 3:
      /* try with exact newton  */
      nlsKinsolXScaling(data, kinsolData, nlsData, SCALING_NOMINALSTART);
      nlsKinsolFScaling(data, kinsolData, nlsData, SCALING_JACOBIAN);
      nlsKinsolResetInitial(data, kinsolData, nlsData, INITIAL_EXTRAPOLATION);
      KINSetMaxSetupCalls(kinsolData->kinsolMemory, 1);
      kinsolData->kinsolStrategy = KIN_LINESEARCH;
      break;
    case 4:
      /* try with exact newton to with out x scaling values */
      nlsKinsolXScaling(data, kinsolData, nlsData, SCALING_ONES);
      nlsKinsolFScaling(data, kinsolData, nlsData, SCALING_ONES);
      nlsKinsolResetInitial(data, kinsolData, nlsData, INITIAL_OLDVALUES);
      KINSetMaxSetupCalls(kinsolData->kinsolMemory, 1);
      kinsolData->kinsolStrategy = KIN_LINESEARCH;
      break;
    default:
      retValue = 0;
      break;
    }
  }

  return retValue+retValue2;
}

int nlsKinsolSolve(DATA *data, threadData_t *threadData, int sysNumber)
{
  NONLINEAR_SYSTEM_DATA *nlsData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA*)nlsData->solverData;
  long eqSystemNumber = nlsData->equationIndex;
  int indexes[2] = {1,eqSystemNumber};

  int flag, i;
  long nFEval;
  int success = 0;
  int retry = 0;
  double *xStart = NV_DATA_S(kinsolData->initialGuess);
  double *xScaling = NV_DATA_S(kinsolData->xScale);
  double *fScaling = NV_DATA_S(kinsolData->fScale);
  double fNormValue;

  /* set user data */
  kinsolData->userData.data = data;
  kinsolData->userData.threadData = threadData;
  kinsolData->userData.sysNumber = sysNumber;

  infoStreamPrintWithEquationIndexes(LOG_NLS_V, 1, indexes, "Start Kinsol solver at time %g", data->localData[0]->timeValue);

  /*  */
  do{
    {
      /* It seems if we don't free KINSol on every iteration, it leaks memory.
       * But if we reset KINSol, it takes an enormous amount of time...
       */
      if (0) { /* Save time; leak memory */
        resetKinsolMemory(kinsolData, nlsData);
      } else {
        /* reset configuration settings */
        nlsKinsolConfigSetup(kinsolData);
      }
    }

    nlsKinsolResetInitial(data, kinsolData, nlsData, INITIAL_EXTRAPOLATION);

    /* set x scaling */
    nlsKinsolXScaling(data, kinsolData, nlsData, SCALING_NOMINALSTART);

    /* set f scaling */
    nlsKinsolFScaling(data, kinsolData, nlsData, SCALING_JACOBIAN);

    /* set maximum step size */
    nlsKinsolSetMaxNewtonStep(kinsolData, kinsolData->maxstepfactor);

    /* dump configuration */
    nlsKinsolConfigPrint(kinsolData, nlsData);

    flag = KINSol(kinsolData->kinsolMemory,           /* KINSol memory block */
                  kinsolData->initialGuess,           /* initial guess on input; solution vector */
                  kinsolData->kinsolStrategy,         /* global strategy choice */
                  kinsolData->xScale,                 /* scaling vector, for the variable cc */
                  kinsolData->fScale);                /* scaling vector for function values fval */

    infoStreamPrint(LOG_NLS_V, 0, "KINSol finished with errorCode %d.", flag);
    /* check for errors */
    if(flag < 0)
    {
      retry = nlsKinsolErrorHandler(flag, data, nlsData, kinsolData);
    }

    /* solution found */
    if ((flag == KIN_SUCCESS) || (flag == KIN_INITIAL_GUESS_OK) || (flag ==  KIN_STEP_LT_STPTOL))
    {
      success = 1;
    }
    kinsolData->retries++;

    /* write statistics */
    KINGetNumNonlinSolvIters(kinsolData->kinsolMemory, &nFEval);
    nlsData->numberOfIterations += nFEval;
    nlsData->numberOfFEval += kinsolData->countResCalls;

    infoStreamPrint(LOG_NLS_V, 0, "Next try? success = %d, retry = %d, retries = %d = %s\n", success, retry, kinsolData->retries,!success && !(retry<1) && kinsolData->retries<RETRY_MAX ? "true" : "false" );
  }while(!success && !(retry<0) && kinsolData->retries < RETRY_MAX);

  /* solution found */
  if (success)
  {
    /* check if solution really solves the residuals */
    nlsKinsolResiduals(kinsolData->initialGuess, kinsolData->fRes, &kinsolData->userData);
    if (!omc_flag[FLAG_NO_SCALING]){
      N_VProd(kinsolData->fRes, kinsolData->fScale, kinsolData->fRes);
    }
    fNormValue = N_VWL2Norm(kinsolData->fRes, kinsolData->fRes);

    infoStreamPrint(LOG_NLS_V, 0, "%sEuclidean norm of F(u) = %e", (omc_flag[FLAG_NO_SCALING])?"":"scaled ", fNormValue);
    if (FTOL_WITH_LESS_ACCURANCY<fNormValue)
    {
      warningStreamPrint(LOG_NLS_V, 0, "False positive solution. FNorm is not small enough.");
      success = 0;
    }
    else /* solved system for reuse linear solver information */
    {
      kinsolData->solved = 1;
    }
    /* copy solution */
    memcpy(nlsData->nlsx, xStart, nlsData->size*(sizeof(double)));
  }

  messageClose(LOG_NLS_V);

  return success;
}

#else

int nlsKinsolAllocate(int size, NONLINEAR_SYSTEM_DATA *nlsData, int linearSolverMethod)
{
  throwStreamPrint(NULL,"no sundials/kinsol support activated");
  return 0;
}

int nlsKinsolFree(void** solverData)
{
  throwStreamPrint(NULL,"no sundials/kinsol support activated");
  return 0;
}

int nlsKinsolSolve(DATA *data, threadData_t *threadData, int sysNumber)
{
  throwStreamPrint(threadData,"no sundials/kinsol support activated");
  return 0;
}

#endif
