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
#include "method_kinsol.h"
#include "simulation_data.h"
#include "util/omc_error.h"

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

    INIT_DATA *initData = (INIT_DATA*) user_data;

    double* lb = initData->min;
    double* ub = initData->max;
    long i;

    setZScaled(initData, zdata);
    leastSquareWithLambda(initData, 1.0);

    for(i=0; i<initData->nVars; ++i)
    {
      fdata[i] = initData->initialResiduals[i];
      fdata[initData->nVars+2*i+0] = zdata[initData->nVars+2*i+0] - zdata[i] + lb[i];
      fdata[initData->nVars+2*i+1] = zdata[initData->nVars+2*i+1] - zdata[i] + ub[i];
    }

    return 0;
  }

  void kinsol_errorHandler(int error_code, const char* module, const char* function, char* msg, void* user_data)
  {
    if(ACTIVE_STREAM(LOG_INIT))
    {
      warningStreamPrint(LOG_INIT, 0, "[module] %s | [function] %s | [error_code] %d", module, function, error_code);
      warningStreamPrint(LOG_INIT, 0, "%s", msg);
    }
  }

  /*! \fn int kinsol_initialization(INIT_DATA *initData)
   *
   *  \param [ref] [initData]
   *
   *  \author lochel
   */
  int kinsol_initialization(INIT_DATA *initData)
  {
    long i;
    double fnormtol  = 1.e-12;     /* function tolerance */
    double scsteptol = 1.e-12;     /* step tolerance */

    long int nni = 0, nfe = 0, nje = 0, nfeD = 0;

    N_Vector z = NULL;
    N_Vector sVars = NULL;
    N_Vector sEqns = NULL;
    N_Vector c = NULL;

    int glstr = KIN_NONE;   /* globalization strategy applied to the Newton method. It must be one of KIN_NONE or KIN_LINESEARCH */
    long int mset = 1;      /* maximum number of nonlinear iterations without a call to the preconditioner setup function. Pass 0 to indicate the default [10]. */
    void *kmem = NULL;
    int error_code = -1;

    assertStreamPrint(initData->simData->modelData.nInitResiduals == initData->nVars, "The number of initial equations are not consistent with the number of unfixed variables. Select a different initialization.");

    do /* Try it first with KIN_NONE. If that fails, try it with KIN_LINESEARCH. */
    {
      if(mset == 1 && glstr == KIN_NONE)
        infoStreamPrint(LOG_INIT, 0, "using exact Newton");
      else if(mset == 1)
        infoStreamPrint(LOG_INIT, 0, "using exact Newton with line search");
      else if(glstr == KIN_NONE)
        infoStreamPrint(LOG_INIT, 0, "using modified Newton");
      else
        infoStreamPrint(LOG_INIT, 0, "using modified Newton with line search");

      infoStreamPrint(LOG_INIT, 0, "mset               = %10ld", mset);
      infoStreamPrint(LOG_INIT, 0, "function tolerance = %10.6g", fnormtol);
      infoStreamPrint(LOG_INIT, 0, "step tolerance     = %10.6g", scsteptol);

      z = N_VNew_Serial(3*initData->nVars);
      assertStreamPrint(0 != z, "out of memory");

      sVars = N_VNew_Serial(3*initData->nVars);
      assertStreamPrint(0 != sVars, "out of memory");

      sEqns = N_VNew_Serial(3*initData->nVars);
      assertStreamPrint(0 != sEqns, "out of memory");

      c = N_VNew_Serial(3*initData->nVars);
      assertStreamPrint(0 != c, "out of memory");

      /* initial guess */
      for(i=0; i<initData->nVars; ++i)
      {
        NV_Ith_S(z, i) = initData->start[i];
        NV_Ith_S(z, initData->nInitResiduals+2*i+0) = NV_Ith_S(z, i) - initData->min[i];
        NV_Ith_S(z, initData->nInitResiduals+2*i+1) = NV_Ith_S(z, i) - initData->max[i];
      }

      for(i=0; i<initData->nVars; ++i)
      {
        NV_Ith_S(sVars, i) = initData->nominal ? 1.0 / initData->nominal[i] : 1.0;
        NV_Ith_S(sVars, initData->nInitResiduals+2*i+0) = NV_Ith_S(sVars, i);
        NV_Ith_S(sVars, initData->nInitResiduals+2*i+1) = NV_Ith_S(sVars, i);

        NV_Ith_S(sEqns, i) = initData->residualScalingCoefficients ? 1.0 / initData->residualScalingCoefficients[i] : 1.0;
        NV_Ith_S(sEqns, initData->nInitResiduals+2*i+0) = NV_Ith_S(sEqns, i);
        NV_Ith_S(sEqns, initData->nInitResiduals+2*i+1) = NV_Ith_S(sEqns, i);
      }

      for(i=0; i<initData->nVars; ++i)
      {
        NV_Ith_S(c, i) =  0.0;        /* no constraint on z[i] */
        NV_Ith_S(c, initData->nInitResiduals+2*i+0) = 1.0;
        NV_Ith_S(c, initData->nInitResiduals+2*i+1) = -1.0;
      }

      kmem = KINCreate();
      assertStreamPrint(0 != kmem, "out of memory");

      KINSetErrHandlerFn(kmem, kinsol_errorHandler, NULL);
      KINSetUserData(kmem, initData);
      KINSetConstraints(kmem, c);
      KINSetFuncNormTol(kmem, fnormtol);
      KINSetScaledStepTol(kmem, scsteptol);
      KINInit(kmem, kinsol_residuals, z);

      /* Call KINDense to specify the linear solver */
      KINDense(kmem, 3*initData->nVars);

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
      for(i=0; i<initData->nVars; ++i)
        initData->vars[i] = NV_Ith_S(z, i);

      infoStreamPrint(LOG_INIT, 0, "final kinsol statistics");
      infoStreamPrint(LOG_INIT, 0, "KINGetNumNonlinSolvIters = %5ld", nni);
      infoStreamPrint(LOG_INIT, 0, "KINGetNumFuncEvals       = %5ld", nfe);
      infoStreamPrint(LOG_INIT, 0, "KINDlsGetNumJacEvals     = %5ld", nje);
      infoStreamPrint(LOG_INIT, 0, "KINDlsGetNumFuncEvals    = %5ld", nfeD);

      /* Free memory */
      N_VDestroy_Serial(z);
      N_VDestroy_Serial(sVars);
      N_VDestroy_Serial(sEqns);
      N_VDestroy_Serial(c);
      KINFree(&kmem);

      if(error_code < 0)
        glstr++;  /* try next globalization strategy */
    }while(error_code < 0 && glstr <= KIN_LINESEARCH);

    if(error_code < 0)
    {
      infoStreamPrint(LOG_STDOUT, 0, "kinsol failed. see last warning. use [-lv LOG_INIT] for more output.");
      return error_code;
    }

    return reportResidualValue(initData);
  }
#else
  int kinsol_initialization(INIT_DATA *initData)
  {
  DATA *data = initData->simData;
    throwStreamPrint(data->simulationInfo.errorHandler.globalJumpBuffer, "no sundials/kinsol support activated");
  }
#endif
