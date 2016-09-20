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
#include <kinsol/kinsol_dense.h>
#include <nvector/nvector_serial.h>
#include <sundials/sundials_types.h>
#include <sundials/sundials_math.h>

typedef struct NLS_KINSOL_DATA
{
  double fnormtol;        /* function tolerance */
  double scsteptol;       /* step tolerance */

  double *res;            /* residuals */

  DATA *data;
  threadData_t *threadData;
  NONLINEAR_SYSTEM_DATA *nlsData; /* closing the circle - not so nice */
}NLS_KINSOL_DATA;

int nls_kinsol_allocate(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA *nlsData)
{
  int i;
  int size = nlsData->size;
  int eqSystemNumber = nlsData->equationIndex;
  NLS_KINSOL_DATA *kinsolData;

  if (useStream[LOG_NLS]) {
    infoStreamPrint(LOG_NLS, 1, "allocate memory for %d", modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).id);
    messageClose(LOG_NLS);
  }

  /* allocate system data */
  nlsData->solverData = malloc(sizeof(NLS_KINSOL_DATA));
  kinsolData = (NLS_KINSOL_DATA*) nlsData->solverData;
  assertStreamPrint(threadData, 0 != kinsolData, "out of memory");

  kinsolData->fnormtol  = 1.e-12;     /* function tolerance */
  kinsolData->scsteptol = 1.e-12;     /* step tolerance */

  kinsolData->res = (double*) malloc(size*sizeof(double));

  kinsolData->data = data;
  kinsolData->threadData = threadData;
  kinsolData->nlsData = nlsData;

  return 0;
}

int nls_kinsol_free(NONLINEAR_SYSTEM_DATA *nlsData)
{
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA*) nlsData->solverData;

  free(kinsolData->res);

  free(kinsolData);
  nlsData->solverData = NULL;
  return 0;
}

 /*! \fn kinsol_residuals
 *
 *  \param [in]  [z]
 *  \param [out] [f]
 *  \param [ref] [user_data]
 *
 *  \author lochel
 */
static int nls_kinsol_residuals(N_Vector z, N_Vector f, void *user_data)
{
  double *zdata = NV_DATA_S(z);
  double *fdata = NV_DATA_S(f);

  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA*) user_data;
  void *dataAndThreadData[2] = {kinsolData->data, kinsolData->threadData};

  double* lb = kinsolData->nlsData->min;
  double* ub = kinsolData->nlsData->max;
  long i;

  /* call residual function */
  kinsolData->nlsData->residualFunc(dataAndThreadData, zdata,  kinsolData->res, 0);

  for(i=0; i<kinsolData->nlsData->size; ++i)
  {
    fdata[i] = kinsolData->res[i];
    fdata[kinsolData->nlsData->size+2*i+0] = zdata[kinsolData->nlsData->size+2*i+0] - zdata[i] + lb[i];
    fdata[kinsolData->nlsData->size+2*i+1] = zdata[kinsolData->nlsData->size+2*i+1] - zdata[i] + ub[i];
  }

  return 0;
}

void nls_kinsol_errorHandler(int error_code, const char *module, const char *function, char *msg, void *user_data)
{
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA*) user_data;
  int eqSystemNumber = kinsolData->nlsData->equationIndex;

  if(ACTIVE_STREAM(LOG_NLS))
  {
    warningStreamPrint(LOG_NLS, 1, "kinsol failed for %d", modelInfoGetEquation(&kinsolData->data->modelData->modelDataXml,eqSystemNumber).id);
    warningStreamPrint(LOG_NLS, 0, "[module] %s | [function] %s | [error_code] %d", module, function, error_code);
    warningStreamPrint(LOG_NLS, 0, "%s", msg);

    messageClose(LOG_NLS);
  }
}

int nonlinearSolve_kinsol(DATA *data, threadData_t *threadData, int sysNumber)
{
  NONLINEAR_SYSTEM_DATA *nlsData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA*)nlsData->solverData;
  int eqSystemNumber = kinsolData->nlsData->equationIndex;
  int indexes[2] = {1,eqSystemNumber};

  long i;
  double fnormtol  = 1.e-12;     /* function tolerance */
  double scsteptol = 1.e-12;     /* step tolerance */
  int size = kinsolData->nlsData->size;

  long int nni = 0, nfe = 0, nje = 0, nfeD = 0;

  N_Vector z = NULL;
  N_Vector sVars = NULL;
  N_Vector sEqns = NULL;
  N_Vector c = NULL;

  int glstr = KIN_NONE;         /* globalization strategy applied to the Newton method. It must be one of KIN_NONE or KIN_LINESEARCH */
  long int mset = 1;            /* maximum number of nonlinear iterations without a call to the preconditioner setup function. Pass 0 to indicate the default [10]. */
  void *kmem = NULL;
  int error_code = -1;

  infoStreamPrintWithEquationIndexes(LOG_NLS_V, 1, indexes, "Start solving non-linear system >>%d<< using Kinsol solver at time %g", eqSystemNumber, data->localData[0]->timeValue);

  z = N_VNew_Serial(3*size);
  assertStreamPrint(threadData, 0 != z, "out of memory");

  sVars = N_VNew_Serial(3*size);
  assertStreamPrint(threadData, 0 != sVars, "out of memory");

  sEqns = N_VNew_Serial(3*size);
  assertStreamPrint(threadData, 0 != sEqns, "out of memory");

  c = N_VNew_Serial(3*size);
  assertStreamPrint(threadData, 0 != c, "out of memory");

  /* initial guess */
  for(i=0; i<size; ++i)
  {
    NV_Ith_S(z, i) = kinsolData->nlsData->nlsxExtrapolation[i];
    NV_Ith_S(z, size+2*i+0) = NV_Ith_S(z, i) - kinsolData->nlsData->min[i];
    NV_Ith_S(z, size+2*i+1) = NV_Ith_S(z, i) - kinsolData->nlsData->max[i];
  }

  for(i=0; i<size; ++i)
  {
    NV_Ith_S(sVars, i) = kinsolData->nlsData->nominal[i];
    NV_Ith_S(sVars, size+2*i+0) = NV_Ith_S(sVars, i);
    NV_Ith_S(sVars, size+2*i+1) = NV_Ith_S(sVars, i);

    NV_Ith_S(sEqns, i) = 1.0;
    NV_Ith_S(sEqns, size+2*i+0) = NV_Ith_S(sEqns, i);
    NV_Ith_S(sEqns, size+2*i+1) = NV_Ith_S(sEqns, i);
  }

  for(i=0; i<size; ++i)
  {
    NV_Ith_S(c, i) =  0.0;        /* no constraint on z[i] */
    NV_Ith_S(c, size+2*i+0) = 1.0;
    NV_Ith_S(c, size+2*i+1) = -1.0;
  }

  kmem = KINCreate();
  assertStreamPrint(threadData, 0 != kmem, "out of memory");

  KINSetErrHandlerFn(kmem, nls_kinsol_errorHandler, kinsolData);
  KINSetUserData(kmem, kinsolData);
  KINSetConstraints(kmem, c);
  KINSetFuncNormTol(kmem, fnormtol);
  KINSetScaledStepTol(kmem, scsteptol);
  KINInit(kmem, nls_kinsol_residuals, z);

  /* Call KINDense to specify the linear solver */
  KINDense(kmem, 3*size);

  KINSetMaxSetupCalls(kmem, mset);
  /*KINSetNumMaxIters(kmem, 2000);*/

  error_code = KINSol(kmem,           /* KINSol memory block */
                      z,              /* initial guess on input; solution vector */
                      glstr,          /* global stragegy choice */
                      sVars,          /* scaling vector, for the variable cc */
                      sEqns);         /* scaling vector for function values fval */

  KINGetNumNonlinSolvIters(kmem, &nni);
  KINGetNumFuncEvals(kmem, &nfe);
  KINDlsGetNumJacEvals(kmem, &nje);
  KINDlsGetNumFuncEvals(kmem, &nfeD);

  /* solution */
  infoStreamPrintWithEquationIndexes(LOG_NLS, 1, indexes, "solution for NLS %d at t=%g", eqSystemNumber, kinsolData->data->localData[0]->timeValue);
  for(i=0; i<size; ++i)
  {
    kinsolData->nlsData->nlsx[i] = NV_Ith_S(z, i);
    infoStreamPrintWithEquationIndexes(LOG_NLS, 0, indexes, "[%ld] %s = %g", i+1, modelInfoGetEquation(&kinsolData->data->modelData->modelDataXml,eqSystemNumber).vars[i],  kinsolData->nlsData->nlsx[i]);
  }

  infoStreamPrint(LOG_NLS, 0, "KINGetNumNonlinSolvIters = %5ld", nni);
  infoStreamPrint(LOG_NLS, 0, "KINGetNumFuncEvals       = %5ld", nfe);
  infoStreamPrint(LOG_NLS, 0, "KINDlsGetNumJacEvals     = %5ld", nje);
  infoStreamPrint(LOG_NLS, 0, "KINDlsGetNumFuncEvals    = %5ld", nfeD);
  messageClose(LOG_NLS);

  /* free memory */
  N_VDestroy_Serial(z);
  N_VDestroy_Serial(sVars);
  N_VDestroy_Serial(sEqns);
  N_VDestroy_Serial(c);
  KINFree(&kmem);

  if(ACTIVE_STREAM(LOG_NLS))
  {
    if(error_code == KIN_LINESEARCH_NONCONV)
    {
      warningStreamPrint(LOG_NLS, 0, "kinsol failed. The linesearch algorithm was unable to find an iterate sufficiently distinct from the current iterate.");
      return 0;
    }
    else if(error_code == KIN_MAXITER_REACHED)
    {
      warningStreamPrint(LOG_NLS, 0, "kinsol failed. The maximum number of nonlinear iterations has been reached.");
      return 0;
    }
    else if(error_code < 0)
    {
      warningStreamPrint(LOG_NLS, 0, "kinsol failed [error_code=%d]", error_code);
      return 0;
    }
  }
  else if(error_code < 0)
  {
    warningStreamPrint(LOG_STDOUT, 0, "kinsol failed. Use [-lv LOG_NLS] for more output.");
    return 0;
  }

  return 1;
}

#else

int nls_kinsol_allocate(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA *nlsData)
{
  throwStreamPrint(threadData,"no sundials/kinsol support activated");
  return 0;
}

int nls_kinsol_free(NONLINEAR_SYSTEM_DATA *nlsData)
{
  throwStreamPrint(NULL,"no sundials/kinsol support activated");
  return 0;
}

int nonlinearSolve_kinsol(DATA *data, threadData_t *threadData, int sysNumber)
{
  throwStreamPrint(threadData,"no sundials/kinsol support activated");
  return 0;
}

#endif
