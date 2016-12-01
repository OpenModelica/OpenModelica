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
#include "util/omc_error.h"
#include "omc_math.h"

#ifdef WITH_SUNDIALS

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

  /* ### tolerances ### */
  double fnormtol;        /* function tolerance */
  double scsteptol;       /* step tolerance */

  /* ### work arrays ### */
  N_Vector initialGuess;
  N_Vector xScale;
  N_Vector fScale;
  N_Vector fRes;
  N_Vector fx;
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
static int nlsDenseJac(long int N, N_Vector x, N_Vector fx, DlsMat Jac, void *userData, N_Vector tmp1, N_Vector tmp2);

int checkReturnFlag(int flag)
{
  int retVal;
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

int nlsKinsolAllocate(int size, NONLINEAR_SYSTEM_DATA *nlsData, int linearSolverMethod)
{
  int i, flag, printLevel;

  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA*) malloc(sizeof(NLS_KINSOL_DATA));

  /* allocate system data */
  nlsData->solverData = (void*)kinsolData;

  kinsolData->size = size;
  kinsolData->linearSolverMethod = linearSolverMethod;
  kinsolData->solved = 0;

  kinsolData->fnormtol  = sqrt(newtonFTol);     /* function tolerance */
  kinsolData->scsteptol = sqrt(newtonXTol);     /* step tolerance */

  kinsolData->initialGuess = N_VNew_Serial(size);
  kinsolData->xScale = N_VNew_Serial(size);
  kinsolData->fScale = N_VNew_Serial(size);
  kinsolData->fRes = N_VNew_Serial(size);

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
  if (kinsolData->linearSolverMethod == 3)
  {
    if(nlsData->isPatternAvailable)
    {
      kinsolData->nnz = nlsData->sparsePattern.numberOfNoneZeros;
      flag = KINKLU(kinsolData->kinsolMemory, size, kinsolData->nnz);
      if (checkReturnFlag(flag)){
        errorStreamPrint(LOG_STDOUT, 0, "##KINSOL## Something goes wrong while initialize KINSOL solver!");
      }
      flag = KINSlsSetSparseJacFn(kinsolData->kinsolMemory, nlsSparseJac);
      if (checkReturnFlag(flag)){
        errorStreamPrint(LOG_STDOUT, 0, "##KINSOL## Something goes wrong while initialize KINSOL Sparse Solver!");
      }
    }
    else
    {
      flag = KINDense(kinsolData->kinsolMemory, size);
      if (checkReturnFlag(flag)){
        errorStreamPrint(LOG_STDOUT, 0, "##KINSOL## Something goes wrong while initialize KINSOL solver!");
      }
    }
  }
  else if (kinsolData->linearSolverMethod == 1)
  {
    flag = KINDense(kinsolData->kinsolMemory, size);
    if (checkReturnFlag(flag)){
      errorStreamPrint(LOG_STDOUT, 0, "##KINSOL## Something goes wrong while initialize KINSOL solver!");
    }
  }
  else if (kinsolData->linearSolverMethod == 2)
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
  if (ACTIVE_STREAM(LOG_NLS))
    printLevel = 1;
  else if (ACTIVE_STREAM(LOG_NLS_V))
    printLevel = 3;
  else
    printLevel = 0;
  KINSetPrintLevel(kinsolData->kinsolMemory, printLevel);

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
      DENSE_ELEM(Jac, j, i) = (fRes[j] - fx[j]) * delta_hh;
    }
    x[i] = xsave;
  }

  /* debug */
  if (ACTIVE_STREAM(LOG_NLS_JAC)){
    infoStreamPrint(LOG_NLS_JAC, 0, "##KINSOL## omc dense matrix.");
    PrintMat(Jac);
  }
  return 0;
}

/* Element function for sparse matrix set */
static void setJacElementKluSparse(int row, int col, double value, int nth, SlsMat spJac)
{
  if (col > 0){
    if (spJac->colptrs[col] == 0){
      spJac->colptrs[col] = nth;
    }
  }
  spJac->rowvals[nth] = row;
  spJac->data[nth] = value;
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

  SPARSE_PATTERN* sparsePattern = &(nlsData->sparsePattern);

  const double delta_h = sqrt(DBL_EPSILON*2e1);

  long int i,j,ii;
  int nth = 0;

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
          setJacElementKluSparse(j, ii, (fRes[j] - fx[j]) * delta_hh[ii], nth, Jac);
          nth++;
        };
        x[ii] = xsave[ii];
      }
    }
  }
  /* finish matrix colptrs */
  Jac->colptrs[kinsolData->size] = kinsolData->nnz;

  /* debug */
  if (ACTIVE_STREAM(LOG_NLS_JAC)){
    infoStreamPrint(LOG_NLS_JAC, 0, "##KINSOL## Sparse Matrix.");
    PrintSparseMat(Jac);
  }
  return 0;
}

static
void nlsKinsolErrorPrint(int errorCode, const char *module, const char *function, char *msg, void *userData)
{
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA*) userData;
  DATA* data = kinsolData->userData.data;
  int sysNumber = kinsolData->userData.sysNumber;
  long eqSystemNumber = data->simulationInfo->nonlinearSystemData[sysNumber].equationIndex;

  if (ACTIVE_STREAM(LOG_NLS))
  {
    warningStreamPrint(LOG_NLS, 1, "kinsol failed for %d", modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).id);
    warningStreamPrint(LOG_NLS, 0, "[module] %s | [function] %s | [error_code] %d", module, function, errorCode);
    warningStreamPrint(LOG_NLS, 0, "%s", msg);

    messageClose(LOG_NLS);
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
  /* Use nominal value or the actual working point for scaling */
  switch (mode)
  {
    case SCALING_NOMINALSTART:
      for (i=0;i<nlsData->size;i++){
        xScaling[i] = fmax(nlsData->nominal[i],fabs(xStart[i]));
      }
      break;
    case SCALING_ONES:
      _omc_fillVector(_omc_createVector(nlsData->size,xScaling), 1.);
      break;
  }
}

static
int nlsKinsolConfigPrint(NLS_KINSOL_DATA *kinsolData, NONLINEAR_SYSTEM_DATA *nlsData)
{
  int retValue;
  double fNorm;
  double *xStart = NV_DATA_S(kinsolData->initialGuess);
  double *xScaling = NV_DATA_S(kinsolData->xScale);
  DATA* data = kinsolData->userData.data;
  int eqSystemNumber = nlsData->equationIndex;

  infoStreamPrint(LOG_NLS_V, 1, "Kinsol Configuration");
  _omc_printVectorWithEquationInfo(_omc_createVector(kinsolData->size, xStart),
      "Initial guess values", LOG_NLS_V, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber));

  _omc_printVectorWithEquationInfo(_omc_createVector(kinsolData->size, xScaling),
      "xScaling", LOG_NLS_V, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber));

  infoStreamPrint(LOG_NLS_V, 0, "KINSOL F tolerance: %g", (*(KINMem)kinsolData->kinsolMemory).kin_fnormtol);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL minimal step size %g", (*(KINMem)kinsolData->kinsolMemory).kin_scsteptol);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL max iterations %d", 20*kinsolData->size);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL strategy %d", kinsolData->kinsolStrategy);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL current retry %d", kinsolData->retries);

  messageClose(LOG_NLS_V);

  return retValue;
}

static
int nlsKinsolErrorHandler(int errorCode, DATA *data, NONLINEAR_SYSTEM_DATA *nlsData, NLS_KINSOL_DATA *kinsolData)
{
  int retValue, i, retValue2=0;
  double fNorm;
  double *xStart = NV_DATA_S(kinsolData->initialGuess);
  double *xScaling = NV_DATA_S(kinsolData->xScale);

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
    errorStreamPrint(LOG_NLS, 0, "kinsol has a serious memory issue ERROR %d\n", errorCode);
    return errorCode;
    break;
  /* just retry with new initial guess */
  case KIN_MXNEWT_5X_EXCEEDED:
    warningStreamPrint(LOG_NLS, 0, "initial guess was too far away from the solution. Try again.\n");
    return 1;
    break;
  /* just retry without line search */
  case KIN_LINESEARCH_NONCONV:
    warningStreamPrint(LOG_NLS, 0, "kinsols line search did not convergence. Try without.\n");
    kinsolData->kinsolStrategy = KIN_NONE;
    return 1;
  /* maybe happened because of an out-dated factorization, so just retry  */
  case KIN_LSETUP_FAIL:
  case KIN_LSOLVE_FAIL:
    warningStreamPrint(LOG_NLS, 0, "kinsols matrix need new factorization. Try again.\n");
    KINKLUReInit(kinsolData->kinsolMemory, kinsolData->size, kinsolData->nnz, 2);
    return 1;
  case KIN_MAXITER_REACHED:
  case KIN_REPTD_SYSFUNC_ERR:
    warningStreamPrint(LOG_NLS, 0, "kinsols runs into issues retry with differnt configuration.\n");
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
    warningStreamPrint(LOG_NLS, 0, "Move forward with a less accurate solution.");
    KINSetFuncNormTol(kinsolData->kinsolMemory, FTOL_WITH_LESS_ACCURANCY);
    KINSetScaledStepTol(kinsolData->kinsolMemory, FTOL_WITH_LESS_ACCURANCY);
    retValue2 = 1;
  }
  else
  {
    warningStreamPrint(LOG_NLS, 0, "Current status of fx = %f", fNorm);
  }

  /* reconfigure kinsol for an other try */
  if (retValue == 1 && !retValue2)
  {
    switch(kinsolData->retries)
    {
    case 0:
      /* try without x scaling  */
      nlsKinsolXScaling(data, kinsolData, nlsData, SCALING_ONES);
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
      nlsKinsolResetInitial(data, kinsolData, nlsData, INITIAL_EXTRAPOLATION);
      KINSetMaxSetupCalls(kinsolData->kinsolMemory, 1);
      kinsolData->kinsolStrategy = KIN_LINESEARCH;
      break;
    case 4:
      /* try with exact newton to with out x scaling values */
      nlsKinsolXScaling(data, kinsolData, nlsData, SCALING_ONES);
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

  /* reset configuration settings */
  nlsKinsolConfigSetup(kinsolData);

  infoStreamPrint(LOG_NLS, 0, "------------------------------------------------------");
  infoStreamPrintWithEquationIndexes(LOG_NLS, 1, indexes, "Start solving non-linear system >>%ld<< using Kinsol solver at time %g", eqSystemNumber, data->localData[0]->timeValue);

  nlsKinsolResetInitial(data, kinsolData, nlsData, INITIAL_EXTRAPOLATION);

  /* set x scaling */
  nlsKinsolXScaling(data, kinsolData, nlsData, SCALING_NOMINALSTART);

  /* set f scaling */
  _omc_fillVector(_omc_createVector(nlsData->size, fScaling), 1.);

  /*  */
  do{
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
    fNormValue = N_VWL2Norm(kinsolData->fRes, kinsolData->fRes);
    infoStreamPrint(LOG_NLS, 0, "scaled Euclidean norm of F(u) = %e", fNormValue);
    if (FTOL_WITH_LESS_ACCURANCY<fNormValue)
    {
      warningStreamPrint(LOG_NLS, 0, "False positive solution. FNorm is too small.");
      success = 0;
    }
    else /* solved system for reuse linear solver information */
    {
      kinsolData->solved = 1;
    }
    /* copy solution */
    memcpy(nlsData->nlsx, xStart, nlsData->size*(sizeof(double)));
    /* dump solution */
    if(ACTIVE_STREAM(LOG_NLS))
    {
      infoStreamPrintWithEquationIndexes(LOG_NLS, 1, indexes, "solution for NLS %ld at t=%g", eqSystemNumber, kinsolData->userData.data->localData[0]->timeValue);
      for(i=0; i<nlsData->size; ++i)
      {
        infoStreamPrintWithEquationIndexes(LOG_NLS, 0, indexes, "[%d] %s = %g", i+1, modelInfoGetEquation(&kinsolData->userData.data->modelData->modelDataXml,eqSystemNumber).vars[i], nlsData->nlsx[i]);
      }
      messageClose(LOG_NLS);
    }
  }

  messageClose(LOG_NLS);

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
