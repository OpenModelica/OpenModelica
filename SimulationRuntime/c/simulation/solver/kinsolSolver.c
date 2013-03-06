/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*! \file kinsolSolver.c
 */

#include "../../../../Compiler/runtime/config.h"
#include "nonlinearSystem.h"
#include "kinsolSolver.h"
#include "simulation_info_xml.h"
#include "omc_error.h"

#ifdef WITH_SUNDIALS

  #include <math.h>
  #include <stdlib.h>
  #include <string.h> /* memcpy */

  #include "varinfo.h"
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

  typedef struct NLS_KINSOL_DATA
  {
    double fnormtol;        /* function tolerance */
    double scsteptol;       /* step tolerance */

    double *res;            /* residuals */

    DATA *data;
    NONLINEAR_SYSTEM_DATA *nlsData; /* closing the circle - not so nice */
  }NLS_KINSOL_DATA;

  int nls_kinsol_allocate(DATA *data, NONLINEAR_SYSTEM_DATA *nlsData)
  {
    int i;
    int size = nlsData->size;
    int eqSystemNumber = nlsData->equationIndex;
    NLS_KINSOL_DATA *kinsolData;

    INFO1(LOG_NLS, "allocate memory for %s", modelInfoXmlGetEquation(&data->modelData.modelDataXml,eqSystemNumber).name);
    INDENT(LOG_NLS);
    for(i=0; i<size; ++i)
      INFO2(LOG_NLS, "[%d] %s", i+1, modelInfoXmlGetEquation(&data->modelData.modelDataXml,eqSystemNumber).vars[i]->name);
    RELEASE(LOG_NLS);

    /* allocate system data */
    nlsData->solverData = malloc(sizeof(NLS_KINSOL_DATA));
    kinsolData = (NLS_KINSOL_DATA*) nlsData->solverData;
    ASSERT(kinsolData, "out of memory");

    kinsolData->fnormtol  = 1.e-12;     /* function tolerance */
    kinsolData->scsteptol = 1.e-12;     /* step tolerance */

    kinsolData->res = (double*) malloc(size*sizeof(double));

    kinsolData->data = data;
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

    double* lb = kinsolData->nlsData->min;
    double* ub = kinsolData->nlsData->max;
    long i;

    /* call residual function */
    kinsolData->nlsData->residualFunc(kinsolData->data, zdata,  kinsolData->res, 0);

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
      WARNING1(LOG_NLS, "kinsol failed for %s", modelInfoXmlGetEquation(&kinsolData->data->modelData.modelDataXml,eqSystemNumber).name);
      INDENT(LOG_NLS);

      WARNING3(LOG_NLS, "[module] %s | [function] %s | [error_code] %d", module, function, error_code);
      WARNING1(LOG_NLS, "%s", msg);

      RELEASE(LOG_NLS);
    }
  }

  int nonlinearSolve_kinsol(DATA *data, int sysNumber)
  {
    NONLINEAR_SYSTEM_DATA *nlsData = &(data->simulationInfo.nonlinearSystemData[sysNumber]);
    NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA*)nlsData->solverData;
    int eqSystemNumber = kinsolData->nlsData->equationIndex;

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

    z = N_VNew_Serial(3*size);
    ASSERT(z, "out of memory");

    sVars = N_VNew_Serial(3*size);
    ASSERT(sVars, "out of memory");

    sEqns = N_VNew_Serial(3*size);
    ASSERT(sEqns, "out of memory");

    c = N_VNew_Serial(3*size);
    ASSERT(c, "out of memory");

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
    ASSERT(kmem, "out of memory");

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
    INFO2(LOG_NLS, "solution for %s at t=%g", modelInfoXmlGetEquation(&kinsolData->data->modelData.modelDataXml,eqSystemNumber).name, kinsolData->data->localData[0]->timeValue);
    INDENT(LOG_NLS);
    for(i=0; i<size; ++i)
    {
      kinsolData->nlsData->nlsx[i] = NV_Ith_S(z, i);
      INFO3(LOG_NLS, "[%ld] %s = %g", i+1, modelInfoXmlGetEquation(&kinsolData->data->modelData.modelDataXml,eqSystemNumber).vars[i]->name,  kinsolData->nlsData->nlsx[i]);
    }

    INFO1(LOG_NLS, "KINGetNumNonlinSolvIters = %5ld", nni);
    INFO1(LOG_NLS, "KINGetNumFuncEvals       = %5ld", nfe);
    INFO1(LOG_NLS, "KINDlsGetNumJacEvals     = %5ld", nje);
    INFO1(LOG_NLS, "KINDlsGetNumFuncEvals    = %5ld", nfeD);
    RELEASE(LOG_NLS);

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
        WARNING(LOG_NLS, "kinsol failed. The linesearch algorithm was unable to find an iterate sufficiently distinct from the current iterate.");
        return 0;
      }
      else if(error_code == KIN_MAXITER_REACHED)
      {
        WARNING(LOG_NLS, "kinsol failed. The maximum number of nonlinear iterations has been reached.");
        return 0;
      }
      else if(error_code < 0)
      {
        WARNING1(LOG_NLS, "kinsol failed [error_code=%d]", error_code);
        return 0;
      }
    }
    else if(error_code < 0)
    {
      WARNING(LOG_STDOUT, "kinsol failed. Use [-lv LOG_NLS] for more output.");
      return 0;
    }

    return 1;
  }

#else

  int nls_kinsol_allocate(DATA *data, NONLINEAR_SYSTEM_DATA *nlsData)
  {
    THROW("no sundials/kinsol support activated");
    return 0;
  }

  int nls_kinsol_free(NONLINEAR_SYSTEM_DATA *nlsData)
  {
    THROW("no sundials/kinsol support activated");
    return 0;
  }

  int nonlinearSolve_kinsol(DATA *data, int sysNumber)
  {
    THROW("no sundials/kinsol support activated");
    return 0;
  }

#endif
