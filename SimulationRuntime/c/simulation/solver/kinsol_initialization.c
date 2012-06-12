/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*! \file kinsol_initialization.c
 */

#include "../../../../Compiler/runtime/config.h"
#include "kinsol_initialization.h"
#include "simulation_data.h"
#include "omc_error.h"

#ifdef WITH_SUNDIALS
  #include "openmodelica.h"
  #include "openmodelica_func.h"
  #include "model_help.h"
  #include "read_matlab4.h"
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

  typedef struct KINSOL_DATA
  {
    INIT_DATA* initData;
    DATA* data;
    int useScaling;
  }KINSOL_DATA;

  /*! \fn kinsol_residuals
   *
   *  \param [in]  [z]
   *  \param [out] [f]
   *  \param [ref] [user_data]
   *
   *  \author lochel
   */
  static int kinsol_residuals(N_Vector z, N_Vector f, void* user_data)
  {
    double* zdata = NV_DATA_S(z);
    double* fdata = NV_DATA_S(f);

    KINSOL_DATA* kdata = (KINSOL_DATA*) user_data;
    DATA* data = kdata->data;
    INIT_DATA* initData = kdata->initData;

    double* lb = initData->min;
    double* ub = initData->max;
    double* nominal = initData->nominal;
    long i;

    if(kdata->useScaling==0)
      setZ(initData, zdata);/*memcpy(initData->z, zdata, initData->nz*sizeof(double));*/
    else
      setZScaled(initData, zdata);

    if(kdata->useScaling==0)
      initData->nominal = NULL;
    leastSquareWithLambda(data, initData, 1.0);
    if(kdata->useScaling==0)
      initData->nominal = nominal;

    for(i=0; i<initData->nz; ++i)
    {
      fdata[i] = globalInitialResiduals[i];
      fdata[initData->nz+2*i+0] = zdata[initData->nz+2*i+0] - zdata[i] + lb[i];
      fdata[initData->nz+2*i+1] = zdata[initData->nz+2*i+1] - zdata[i] + ub[i];
    }

    return 0;
  }

  void kinsol_errorHandler(int error_code, const char* module, const char* function, char* msg, void* user_data)
  {
    if(DEBUG_FLAG(LOG_INIT))
    {
      WARNING3("[module] %s | [function] %s | [error_code] %d", module, function, error_code);
      WARNING_AL1("%s", msg);
    }
  }

  /*! \fn kinsol_initialization
   *
   *  \param [ref] [data]
   *  \param [in]  [initData]
   *  \param [ref] [initialResiduals]
   *
   *  \author lochel
   */
  int kinsol_initialization(DATA* data, INIT_DATA* initData, int useScaling)
  {
    long i, indz;
    KINSOL_DATA* kdata = NULL;
    double fnormtol  = 1.e-9;     /* function tolerance */
    double scsteptol = 1.e-9;     /* step tolerance */

    long int nni, nfe, nje, nfeD;

    N_Vector z = NULL;
    N_Vector sVars = NULL;
    N_Vector sEqns = NULL;
    N_Vector c = NULL;

    int glstr = KIN_NONE;   /* globalization strategy applied to the Newton method. It must be one of KIN_NONE or KIN_LINESEARCH */
    long int mset = 1;      /* maximum number of nonlinear iterations without a call to the preconditioner setup function. Pass 0 to indicate the default [10]. */
    void *kmem = NULL;
    int error_code = -1;

    ASSERT(data->modelData.nInitResiduals == initData->nz, "The number of initial equations are not consistent with the number of unfixed variables. Select a different initialization.");

    do /* Try it first with KIN_NONE. If that fails, try it with KIN_LINESEARCH. */
    {
      if(mset == 1 && glstr == KIN_NONE)
        DEBUG_INFO(LOG_INIT, "using exact Newton");
      else if(mset == 1)
        DEBUG_INFO(LOG_INIT, "using exact Newton with line search");
      else if(glstr == KIN_NONE)
        DEBUG_INFO(LOG_INIT, "using modified Newton");
      else
        DEBUG_INFO(LOG_INIT, "using modified Newton with line search");

      DEBUG_INFO_AL1(LOG_INIT, "| mset               = %10ld", mset);
      DEBUG_INFO_AL1(LOG_INIT, "| function tolerance = %10.6g", fnormtol);
      DEBUG_INFO_AL1(LOG_INIT, "| step tolerance     = %10.6g", scsteptol);

      kdata = (KINSOL_DATA*)malloc(sizeof(KINSOL_DATA));
      ASSERT(kdata, "out of memory");

      kdata->initData = initData;
      kdata->data = data;

      z = N_VNew_Serial(3*initData->nz);
      ASSERT(z, "out of memory");

      sVars = N_VNew_Serial(3*initData->nz);
      ASSERT(sVars, "out of memory");

      sEqns = N_VNew_Serial(3*initData->nz);
      ASSERT(sEqns, "out of memory");

      c = N_VNew_Serial(3*initData->nz);
      ASSERT(c, "out of memory");

      /* initial guess */
      for(i=0; i<initData->nz; ++i)
      {
        NV_Ith_S(z, i) = initData->start[i];
        NV_Ith_S(z, initData->nInitResiduals+2*i+0) = NV_Ith_S(z, i) - initData->min[i];
        NV_Ith_S(z, initData->nInitResiduals+2*i+1) = NV_Ith_S(z, i) - initData->max[i];
      }

      kdata->useScaling=useScaling;
      if(useScaling)
      {
        computeInitialResidualScalingCoefficients(data, initData);
        for(i=0; i<initData->nz; ++i)
        {
          NV_Ith_S(sVars, i) = 1.0 / (initData->nominal[i] == 0.0 ? 1.0 : initData->nominal[i]);
          NV_Ith_S(sVars, initData->nInitResiduals+2*i+0) = NV_Ith_S(sVars, i);
          NV_Ith_S(sVars, initData->nInitResiduals+2*i+1) = NV_Ith_S(sVars, i);

          NV_Ith_S(sEqns, i) = 1.0 / (initData->residualScalingCoefficients[i] == 0.0 ? 1.0 : initData->residualScalingCoefficients[i]);
          NV_Ith_S(sEqns, initData->nInitResiduals+2*i+0) = NV_Ith_S(sEqns, i);
          NV_Ith_S(sEqns, initData->nInitResiduals+2*i+1) = NV_Ith_S(sEqns, i);
        }
      }
      else
      {
        N_VConst_Serial(1.0, sVars);        /* no scaling */
        N_VConst_Serial(1.0, sEqns);        /* no scaling */
      }

      for(i=0; i<initData->nz; ++i)
      {
        NV_Ith_S(c, i) =  0.0;        /* no constraint on z[i] */
        NV_Ith_S(c, initData->nInitResiduals+2*i+0) = 1.0;
        NV_Ith_S(c, initData->nInitResiduals+2*i+1) = -1.0;
      }

      kmem = KINCreate();
      ASSERT(kmem, "out of memory");

      KINSetErrHandlerFn(kmem, kinsol_errorHandler, NULL);
      KINSetUserData(kmem, kdata);
      KINSetConstraints(kmem, c);
      KINSetFuncNormTol(kmem, fnormtol);
      KINSetScaledStepTol(kmem, scsteptol);
      KINInit(kmem, kinsol_residuals, z);

      /* Call KINDense to specify the linear solver */
      KINDense(kmem, 3*initData->nz);

      KINSetMaxSetupCalls(kmem, mset);
      /*KINSetNumMaxIters(kmem, 2000);*/

      globalInitialResiduals = initData->initialResiduals;

      error_code = KINSol(kmem,           /* KINSol memory block */
             z,              /* initial guess on input; solution vector */
             glstr,          /* global stragegy choice */
             sVars,          /* scaling vector, for the variable cc */
             sEqns);         /* scaling vector for function values fval */

      globalInitialResiduals = NULL;

      KINGetNumNonlinSolvIters(kmem, &nni);
      KINGetNumFuncEvals(kmem, &nfe);
      KINDlsGetNumJacEvals(kmem, &nje);
      KINDlsGetNumFuncEvals(kmem, &nfeD);

      DEBUG_INFO(LOG_INIT, "final kinsol statistics");
      DEBUG_INFO_AL1(LOG_INIT, "| KINGetNumNonlinSolvIters = %5ld", nni);
      DEBUG_INFO_AL1(LOG_INIT, "| KINGetNumFuncEvals       = %5ld", nfe);
      DEBUG_INFO_AL1(LOG_INIT, "| KINDlsGetNumJacEvals     = %5ld", nje);
      DEBUG_INFO_AL1(LOG_INIT, "| KINDlsGetNumFuncEvals    = %5ld", nfeD);

      /* Free memory */
      N_VDestroy_Serial(z);
      N_VDestroy_Serial(sVars);
      N_VDestroy_Serial(sEqns);
      N_VDestroy_Serial(c);
      KINFree(&kmem);
      free(kdata);

      if(error_code < 0)
        glstr++;  /* try next globalization strategy */
    }while(error_code < 0 && glstr <= KIN_LINESEARCH);

    /* debug output */
    indz = 0;
    DEBUG_INFO(LOG_INIT, "solution");
    for(i=0; i<data->modelData.nStates; ++i)
      if(data->modelData.realVarsData[i].attribute.fixed==0)
        DEBUG_INFO_AL2(LOG_INIT, "| %s = %g", initData->name[indz++], data->localData[0]->realVars[i]);

    for(i=0; i<data->modelData.nParametersReal; ++i)
      if(data->modelData.realParameterData[i].attribute.fixed == 0)
        DEBUG_INFO_AL2(LOG_INIT, "| %s = %g", initData->name[indz++], data->simulationInfo.realParameter[i]);

    if(error_code < 0)
      THROW("kinsol failed. see last warning. use [-lv LOG_INIT] for more output.");

    return 0;
  }
#else
  int kinsol_initialization(DATA* data, INIT_DATA* initData, int useScaling)
  {
    THROW("no sundials/kinsol support activated");
  }
#endif
