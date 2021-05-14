/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#include "kinsolSolver.h"

#include "nonlinearSystem.h"
#include "omc_config.h"
#include "omc_math.h"
#include "simulation/options.h"
#include "simulation/simulation_info_json.h"
#include "util/omc_error.h"

#ifdef WITH_SUNDIALS

#include "events.h"
#include "model_help.h"
#include "openmodelica.h"
#include "openmodelica_func.h"
#include "util/read_matlab4.h"
#include "util/varinfo.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Function prototypes */
static int nlsKinsolResiduals(N_Vector x, N_Vector f, void *userData);
static int nlsSparseJac(N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                        void *userData, N_Vector tmp1, N_Vector tmp2);
int nlsSparseSymJac(N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                    void *userData, N_Vector tmp1, N_Vector tmp2);
static int nlsDenseJac(long int N, N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                       void *userData, N_Vector tmp1, N_Vector tmp2);
static void nlsKinsolJacSumSparse(SUNMatrix A);
static void nlsKinsolJacSumDense(SUNMatrix A);

/**
 * @brief Set KINSOL configuration.
 *
 * @param kinsolData    Kinsol data with configuration settings.
 */
static void nlsKinsolConfigSetup(NLS_KINSOL_DATA *kinsolData) {
  /* Variables */
  int flag;

  /* configuration */
  flag = KINSetFuncNormTol(
      kinsolData->kinsolMemory,
      kinsolData->fnormtol); /* Set function-norm stopping tolerance */
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetFuncNormTol");

  flag = KINSetScaledStepTol(
      kinsolData->kinsolMemory,
      kinsolData->scsteptol); /* Set scaled-step stopping tolerance */
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetScaledStepTol");

  flag = KINSetNumMaxIters(
      kinsolData->kinsolMemory,
      100 * kinsolData->size); /* Set max. number of nonlinear iterations */
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetNumMaxIters");

  kinsolData->kinsolStrategy =
      KIN_LINESEARCH; /* Newton with globalization strategy to solve nonlinear
                         systems */

  /* configuration for exact Newton */ /* TODO: Remove this? */
  /*
  KINSetMaxSetupCalls(kinsolData->kinsolMemory, 1);
  KINSetMaxSubSetupCalls(kinsolData->kinsolMemory, 1);
  */

  flag =
      KINSetNoInitSetup(kinsolData->kinsolMemory,
                        SUNFALSE); /* TODO: This is the default value. Is there
                                      a point in calling this function? */
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetNoInitSetup");

  kinsolData->retries = 0;
  kinsolData->countResCalls = 0;
}

/**
 * @brief (Re-) Initialize KINSOL data.
 *
 * Initialize KINSOL data. If the KINSOL memory block was alreay initialized
 * free it first and then reinitialize.
 *
 * @param kinsolData    KINSOL data.
 * @param nlsData       Nonliner system Data.
 */
static void resetKinsolMemory(NLS_KINSOL_DATA *kinsolData,
                              NONLINEAR_SYSTEM_DATA *nlsData) {
  int flag;
  int printLevel;
  int size = kinsolData->size;

  /* Free KINSOL memory block */
  if (kinsolData->kinsolMemory) {
    KINFree((void *)&kinsolData->kinsolMemory);
  }

  /* Create KINSOL memory block */
  kinsolData->kinsolMemory = KINCreate();
  if (kinsolData->kinsolMemory == NULL) {
    errorStreamPrint(LOG_STDOUT, 0,
                     "##KINSOL## In function KINCreate: An error occured.");
  }

  /* Set error handler and print level */
  if (ACTIVE_STREAM(LOG_NLS_V)) {
    printLevel = 3;
  } else if (ACTIVE_STREAM(LOG_NLS)) {
    printLevel = 1;
  } else {
    printLevel = 0;
  }
  flag = KINSetPrintLevel(kinsolData->kinsolMemory, printLevel);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetPrintLevel");

  kinsolData->userData.sysNumber = -1;
  flag = KINSetErrHandlerFn(kinsolData->kinsolMemory, kinsolErrorHandlerFunction, kinsolData);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetErrHandlerFn");

  flag = KINSetInfoHandlerFn(kinsolData->kinsolMemory, kinsolInfoHandlerFunction, NULL);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetInfoHandlerFn");

  /* Set user data given to KINSOL */
  flag = KINSetUserData(kinsolData->kinsolMemory, (void *)&(kinsolData->userData));
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetUserData");

  /* Initialize KINSOL object */
  flag = KINInit(kinsolData->kinsolMemory, nlsKinsolResiduals,
                 kinsolData->initialGuess);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINInit");

  /* Create matrix object */
  if (kinsolData->linearSolverMethod == NLS_LS_DEFAULT) {
    kinsolData->J = SUNDenseMatrix(size, size);
  } else if (kinsolData->linearSolverMethod == NLS_LS_KLU) {
    kinsolData->nnz = nlsData->sparsePattern->numberOfNoneZeros;
    kinsolData->J = SUNSparseMatrix(size, size, kinsolData->nnz, CSC_MAT);
  } else {
    kinsolData->J = NULL;
  }

  /* Create linear solver object */
  if (kinsolData->linearSolverMethod == NLS_LS_DEFAULT ||
      kinsolData->linearSolverMethod == NLS_LS_TOTALPIVOT) {
    kinsolData->linSol = SUNLinSol_Dense(kinsolData->y, kinsolData->J);
    if (kinsolData->linSol == NULL) {
      errorStreamPrint(
          LOG_STDOUT, 0,
          "##KINSOL## In function SUNLinSol_Dense: Input incompatible.");
    }
  } else if (kinsolData->linearSolverMethod == NLS_LS_LAPACK) {
    kinsolData->linSol = SUNLinSol_LapackDense(kinsolData->y, kinsolData->J);
    if (kinsolData->linSol == NULL) {
      errorStreamPrint(
          LOG_STDOUT, 0,
          "##KINSOL## In function SUNLinSol_LapackDense: Input incompatible.");
    }
  } else if (kinsolData->linearSolverMethod == NLS_LS_KLU) {
    kinsolData->linSol = SUNLinSol_KLU(kinsolData->y, kinsolData->J);
    if (kinsolData->linSol == NULL) {
      errorStreamPrint(
          LOG_STDOUT, 0,
          "##KINSOL## In function SUNLinSol_KLU: Input incompatible.");
    }
  } else {
    errorStreamPrint(LOG_STDOUT, 0, "##KINSOL## Unknown linear solver method.");
  }

  /* Set linear solver */
  flag = KINSetLinearSolver(kinsolData->kinsolMemory, kinsolData->linSol,
                            kinsolData->J);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetLinearSolver");

  /* Set Jacobian for linear solver */
  if (kinsolData->linearSolverMethod == NLS_LS_KLU) {
    if (nlsData->analyticalJacobianColumn != NULL) {
      flag = KINSetJacFn(kinsolData->kinsolMemory,
                         nlsSparseSymJac); /* Use symbolic Jacobian */
    } else {
      flag = KINSetJacFn(kinsolData->kinsolMemory,
                         nlsSparseJac); /* Use numeric Jacobian */
    }
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
  }

  /* Configuration */
  nlsKinsolConfigSetup(kinsolData);
}

/**
 * @brief Allocate memory for kinsol solver data and initialize KINSOL solver
 *
 * @param size                  Size of non-linear problem.
 * @param nlsData
 * @param linearSolverMethod    Type of linear solver method.
 * @return int
 */
int nlsKinsolAllocate(int size, NONLINEAR_SYSTEM_DATA *nlsData,
                      enum NLS_LS linearSolverMethod) {
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA *)malloc(sizeof(NLS_KINSOL_DATA));

  /* Allocate system data */
  nlsData->solverData = (void *)kinsolData;

  kinsolData->size = size;
  kinsolData->linearSolverMethod = linearSolverMethod;
  kinsolData->solved = 0;

  kinsolData->fnormtol = newtonFTol;  /* function tolerance */
  kinsolData->scsteptol = newtonXTol; /* step tolerance */

  kinsolData->maxstepfactor = maxStepFactor; /* step tolerance */
  kinsolData->nominalJac = 0; /* calculate for scaling the scaled matrix */

  kinsolData->initialGuess = N_VNew_Serial(size);
  kinsolData->xScale = N_VNew_Serial(size);
  kinsolData->fScale = N_VNew_Serial(size);
  kinsolData->fRes = N_VNew_Serial(size);
  kinsolData->fTmp = N_VNew_Serial(size);

  kinsolData->y = N_VNew_Serial(size);

  kinsolData->kinsolMemory = NULL;

  resetKinsolMemory(kinsolData, nlsData);

  return 0;
}

/**
 * @brief Deallocates memory for KINSOL solver.
 *
 * Free memory that was allocated with `nlsKinsolAllocate`.
 *
 * @param solverData
 * @return int
 */
int nlsKinsolFree(void **solverData) {
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA *)*solverData;

  KINFree((void *)&kinsolData->kinsolMemory);

  N_VDestroy_Serial(kinsolData->initialGuess);   /* TODO: Or was N_VDestroy_Serial correct? It won't free internal data */
  N_VDestroy_Serial(kinsolData->xScale);
  N_VDestroy_Serial(kinsolData->fScale);
  N_VDestroy_Serial(kinsolData->fRes);
  N_VDestroy_Serial(kinsolData->fTmp);

  /* Free linear solver data */
  SUNLinSolFree(kinsolData->linSol);
  SUNMatDestroy(kinsolData->J);
  N_VDestroy_Serial(kinsolData->y);

  free(kinsolData);

  return 0;
}

/**
 * @brief System function for non-linear problem.
 *
 * @param x           The current value of the variable vector.
 * @param f           Output vector.
 * @param userData    Pointer to user data.
 * @return int
 */
static int nlsKinsolResiduals(N_Vector x, N_Vector f, void *userData) {
  double *xdata = NV_DATA_S(x);
  double *fdata = NV_DATA_S(f);

  NLS_KINSOL_USERDATA *kinsolUserData = (NLS_KINSOL_USERDATA *)userData;
  DATA *data = kinsolUserData->data;
  threadData_t *threadData = kinsolUserData->threadData;
  int sysNumber = kinsolUserData->sysNumber;
  void *dataAndThreadData[2] = {data, threadData};
  NONLINEAR_SYSTEM_DATA *nlsData =
      &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA *)nlsData->solverData;
  long eqSystemNumber = nlsData->equationIndex;
  int iflag = 1 /* recoverable error */;

  /* Update statistics */
  kinsolData->countResCalls++;

#ifndef OMC_EMCC
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /* call residual function */
  data->simulationInfo->nonlinearSystemData[sysNumber].residualFunc(
      dataAndThreadData, xdata, fdata, (const int *)&iflag);
  iflag = 0 /* success */;

#ifndef OMC_EMCC
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  return iflag;
}

/*
 *  function calculates a jacobian matrix
 */
static int nlsDenseJac(long int N, N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                       void *userData, N_Vector tmp1, N_Vector tmp2) {
  NLS_KINSOL_USERDATA *kinsolUserData = (NLS_KINSOL_USERDATA *)userData;
  DATA *data = kinsolUserData->data;
  threadData_t *threadData = kinsolUserData->threadData;
  int sysNumber = kinsolUserData->sysNumber;
  NONLINEAR_SYSTEM_DATA *nlsData =
      &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA *)nlsData->solverData;

  /* prepare variables */
  double *x = N_VGetArrayPointer(vecX);
  double *fx = N_VGetArrayPointer(vecFX);
  double *xScaling = NV_DATA_S(kinsolData->xScale);
  double *fRes = NV_DATA_S(kinsolData->fRes);
  double xsave, xscale, sign;
  double delta_hh;
  const double delta_h = sqrt(DBL_EPSILON * 2e1);

  long int i, j;

  /* performance measurement */
  rt_ext_tp_tick(&nlsData->jacobianTimeClock);

  /* Use forward difference quotient to approximate Jacobian */
  for (i = 0; i < N; i++) {
    xsave = x[i];
    delta_hh = delta_h * (fabs(xsave) + 1.0);
    if ((xsave + delta_hh >= nlsData->max[i])) {
      delta_hh *= -1.0;
    }
    x[i] += delta_hh;

    /* Evaluate Jacobian function */
    nlsKinsolResiduals(vecX, kinsolData->fRes, userData);

    /* Calculate scaled difference quotient */
    delta_hh = 1.0 / delta_hh;

    for (j = 0; j < N; j++) {
      if (kinsolData->nominalJac) {
        SM_ELEMENT_D(Jac, j, i) = (fRes[j] - fx[j]) * delta_hh / xScaling[i];
      } else {
        SM_ELEMENT_D(Jac, j, i) =
            (fRes[j] - fx[j]) * delta_hh; /* TODO: Or now Jac(i,j) ??? */
      }
    }
    x[i] = xsave;
  }

  /* debug */
  if (ACTIVE_STREAM(LOG_NLS_JAC)) {
    infoStreamPrint(LOG_NLS_JAC, 1, "##KINSOL## Dense matrix.");
    SUNDenseMatrix_Print(Jac, stdout); /* TODO: Print in LOG_NLS_JAC */
    nlsKinsolJacSumDense(Jac);
    messageClose(LOG_NLS_JAC);
  }

  /* performance measurement and statistics */
  nlsData->jacobianTime += rt_ext_tp_tock(&(nlsData->jacobianTimeClock));
  nlsData->numberOfJEval++;

  return 0;
}

/**
 * @brief Set element of jacobian saved in CSC SUNMatrix.
 *
 * @param row
 * @param col
 * @param value
 * @param nth
 * @param A
 */
static void setJacElementKluSparse(int row, int col, double value, int nth,
                                   SUNMatrix A) {
  /* TODO: Remove this check for performance reasons? */
  if (SM_SPARSETYPE_S(A) != CSC_MAT) {
    errorStreamPrint(LOG_STDOUT, 0,
                     "In function setJacElementKluSparse: Wrong sparse format "
                     "of SUNMatrix A.");
  }

  if (col > 0 && SM_INDEXPTRS_S(A)[col] == 0) {
    SM_INDEXPTRS_S(A)[col] = nth;
  }
  SM_INDEXVALS_S(A)[nth] = row;
  SM_DATA_S(A)[nth] = value;
}

/**
 * @brief Finish sparse matrix by fixing colprts.
 *
 * Last value of indexptrs should always be nnz.
 * Search for empty rows which would mean the matrix is singular.
 *
 * @param A   CSC matrix
 */
static void finishSparseColPtr(SUNMatrix A, int nnz) {
  int i;

  /* TODO: Remove this check for performance reasons? */
  if (SM_SPARSETYPE_S(A) != CSC_MAT) {
    errorStreamPrint(
        LOG_STDOUT, 0,
        "In function finishSparseColPtr: Wrong sparse format of SUNMatrix A.");
  }

  /* Set last value of indexptrs to nnz */
  SM_INDEXPTRS_S(A)[SM_COLUMNS_S(A)] = nnz;

  /* Check for empty rows */
  for (i = 1; i < SM_COLUMNS_S(A) + 1; ++i) {
    if (SM_INDEXPTRS_S(A)[i] == SM_INDEXPTRS_S(A)[i - 1]) {
      warningStreamPrint(LOG_STDOUT, 0,
                         "##KINSOL## Jacobian row %d singular. See LOG_NLS for "
                         "more information.",
                         i);
      SM_INDEXPTRS_S(A)[i] = SM_INDEXPTRS_S(A)[i - 1];
    }
  }
}

/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences with coloring
 *  into a sparse SlsMat matrix
 */
static int nlsSparseJac(N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                        void *userData, N_Vector tmp1, N_Vector tmp2) {
  /* Variables */
  NLS_KINSOL_USERDATA *kinsolUserData;
  DATA *data;
  threadData_t *threadData;
  NONLINEAR_SYSTEM_DATA *nlsData;
  NLS_KINSOL_DATA *kinsolData;
  SPARSE_PATTERN *sparsePattern;
  int sysNumber;

  double *x;
  double *fx;
  double *xsave;
  double *delta_hh;
  double *xScaling;
  double *fRes;

  const double delta_h = sqrt(DBL_EPSILON * 2e1);

  long int i, j, ii;
  int nth;

  /* Access userData and nonlinear system data */
  kinsolUserData = (NLS_KINSOL_USERDATA *)userData;
  data = kinsolUserData->data;
  threadData = kinsolUserData->threadData;
  sysNumber = kinsolUserData->sysNumber;
  nlsData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  kinsolData = (NLS_KINSOL_DATA *)nlsData->solverData;
  sparsePattern = nlsData->sparsePattern;

  /* Access N_Vector variables */
  x = N_VGetArrayPointer(vecX);
  fx = N_VGetArrayPointer(vecFX);
  xsave = N_VGetArrayPointer(tmp1);
  delta_hh = N_VGetArrayPointer(tmp2);
  xScaling = NV_DATA_S(kinsolData->xScale);
  fRes = NV_DATA_S(kinsolData->fRes);

  nth = 0;

  /* performance measurement */
  rt_ext_tp_tick(&nlsData->jacobianTimeClock);

  /* reset matrix */
  SUNMatZero(Jac);

  /* Approximate Jacobian */
  for (i = 0; i < sparsePattern->maxColors; i++) {
    for (ii = 0; ii < kinsolData->size; ii++) {
      if (sparsePattern->colorCols[ii] - 1 == i) {
        xsave[ii] = x[ii];
        delta_hh[ii] = delta_h * (fabs(xsave[ii]) + 1.0);
        if ((xsave[ii] + delta_hh[ii] >= nlsData->max[ii])) {
          delta_hh[ii] *= -1;
        }
        x[ii] += delta_hh[ii];

        /* Calculate scaled difference quotient */
        delta_hh[ii] = 1. / delta_hh[ii];
      }
    }
    /* Evaluate residual function */
    nlsKinsolResiduals(vecX, kinsolData->fRes, userData);

    /* Save column in Jac and unset seed variables */
    for (ii = 0; ii < kinsolData->size; ii++) {
      if (sparsePattern->colorCols[ii] - 1 == i) {
        nth = sparsePattern->leadindex[ii];
        while (nth < sparsePattern->leadindex[ii + 1]) {
          j = sparsePattern->index[nth];
          if (kinsolData->nominalJac) {
            setJacElementKluSparse(
                j, ii, (fRes[j] - fx[j]) * delta_hh[ii] / xScaling[ii], nth,
                Jac);
          } else {
            setJacElementKluSparse(j, ii, (fRes[j] - fx[j]) * delta_hh[ii], nth,
                                   Jac);
          }
          nth++;
        }
        x[ii] = xsave[ii];
      }
    }
  }
  /* Finish sparse matrix */
  finishSparseColPtr(Jac, sparsePattern->numberOfNoneZeros);

  /* Debug print */
  if (ACTIVE_STREAM(LOG_NLS_JAC)) {
    infoStreamPrint(LOG_NLS_JAC, 1, "##KINSOL## Sparse Matrix.");
    SUNSparseMatrix_Print(Jac, stdout);
    nlsKinsolJacSumSparse(Jac);
    messageClose(LOG_NLS_JAC);
  }
  if (ACTIVE_STREAM(LOG_DEBUG)) {
    sundialsPrintSparseMatrix(Jac, "A", LOG_JAC);
  }

  /* performance measurement and statistics */
  nlsData->jacobianTime += rt_ext_tp_tock(&(nlsData->jacobianTimeClock));
  nlsData->numberOfJEval++;

  return 0;
}

/**
 * @brief Computes symbolic Jacobian matrix Jac(vecX)
 *
 * @param vecX
 * @param vecFX
 * @param Jac
 * @param userData
 * @param tmp1
 * @param tmp2
 * @return int
 */
int nlsSparseSymJac(N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                    void *userData, N_Vector tmp1, N_Vector tmp2) {
  /* Variables */
  NLS_KINSOL_USERDATA *kinsolUserData;
  DATA *data;
  threadData_t *threadData;
  NONLINEAR_SYSTEM_DATA *nlsData;
  NLS_KINSOL_DATA *kinsolData;
  SPARSE_PATTERN *sparsePattern;
  ANALYTIC_JACOBIAN *analyticJacobian;
  int sysNumber;

  double *x;
  double *fx;
  double *xScaling;

  long int i, j, ii;
  int nth;

  /* Access userData and nonlinear system data */
  kinsolUserData = (NLS_KINSOL_USERDATA *)userData;
  data = kinsolUserData->data;
  threadData = kinsolUserData->threadData;
  sysNumber = kinsolUserData->sysNumber;
  nlsData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  kinsolData = (NLS_KINSOL_DATA *)nlsData->solverData;
  sparsePattern = nlsData->sparsePattern;
  analyticJacobian =
      &data->simulationInfo->analyticJacobians[nlsData->jacobianIndex];

  /* Access N_Vector variables */
  x = N_VGetArrayPointer(vecX);
  fx = N_VGetArrayPointer(vecFX);
  xScaling = NV_DATA_S(kinsolData->xScale);

  nth = 0;

  /* performance measurement */
  rt_ext_tp_tick(&nlsData->jacobianTimeClock);

  /* reset matrix */
  SUNMatZero(Jac);

  /* Evaluate constant equations of Jacobian */
  if (analyticJacobian->constantEqns != NULL) {
    analyticJacobian->constantEqns(data, threadData, analyticJacobian, NULL);
  }

  /* Evaluate Jacobian */
  for (i = 0; i < sparsePattern->maxColors; i++) {
    /* Set seed variables */
    for (ii = 0; ii < kinsolData->size; ii++) {
      if (sparsePattern->colorCols[ii] - 1 == i) {
        analyticJacobian->seedVars[ii] = 1.0;
      }
    }
    /* Evaluate Jacobian column */
    ((nlsData->analyticalJacobianColumn))(data, threadData, analyticJacobian,
                                          NULL);

    /* Save column in Jac and unset seed variables */
    for (ii = 0; ii < kinsolData->size; ii++) {
      if (sparsePattern->colorCols[ii] - 1 == i) {
        nth = sparsePattern->leadindex[ii];
        while (nth < sparsePattern->leadindex[ii + 1]) {
          j = sparsePattern->index[nth];
          if (kinsolData->nominalJac) {
            setJacElementKluSparse(
                j, ii, analyticJacobian->resultVars[j] / xScaling[ii], nth,
                Jac);
          } else {
            setJacElementKluSparse(j, ii, analyticJacobian->resultVars[j], nth,
                                   Jac);
          }
          nth++;
        }
        analyticJacobian->seedVars[ii] = 0;
      }
    }
  }

  /* Finish sparse matrix and do a cheap check for singularity */
  finishSparseColPtr(Jac, sparsePattern->numberOfNoneZeros);

  /* Debug print */
  if (ACTIVE_STREAM(LOG_NLS_JAC)) {
    infoStreamPrint(LOG_NLS_JAC, 1, "##KINSOL## Sparse Matrix.");
    SUNSparseMatrix_Print(Jac, stdout); /* TODO: Print in LOG_NLS_JAC */
    nlsKinsolJacSumSparse(Jac);
    messageClose(LOG_NLS_JAC);
  }

  /* performance measurement and statistics */
  nlsData->jacobianTime += rt_ext_tp_tock(&(nlsData->jacobianTimeClock));
  nlsData->numberOfJEval++;

  return 0;
}

/**
 * @brief Check for zero columns of matrix and print absolute sums.
 *
 * Compute absoute sum for each column and print the result.
 * Report a warning if it is zero, since the matrix is singular in that case.
 *
 * @param A       Dense matrix stored columnwice
 */
static void nlsKinsolJacSumDense(SUNMatrix A) {
  /* Variables */
  int i, j;
  double sum;

  for (i = 0; i < SM_ROWS_D(A); ++i) {
    sum = 0.0;
    for (j = 0; j < SM_COLUMNS_D(A); ++j) {
      sum += fabs(SM_ELEMENT_D(A, j, i));
    }

    if (sum == 0.0) { /* TODO: Don't check for equality(!), maybe use DBL_EPSILON */
      warningStreamPrint(LOG_NLS_V, 0,
                         "Column %d of Jacobian is zero. Jacobian is singular.",
                         i);
    } else {
      infoStreamPrint(LOG_NLS_JAC, 0, "Column %d of Jacobian absolute sum = %g",
                      i, sum);
    }
  }
}

/**
 * @brief Check for zero columns of matrix and print absolute sums.
 *
 * Compute absoute sum for each column and print the result.
 * Report a warning if it is zero, since the matrix is singular in that case.
 *
 * @param A       CSC matrix
 */
static void nlsKinsolJacSumSparse(SUNMatrix A) {
  /* Variables */
  int i, j;
  double sum;

  /* Check format of A */
  if (SM_SPARSETYPE_S(A) != CSC_MAT) {
    errorStreamPrint(LOG_STDOUT, 0,
                     "In function nlsKinsolJacSumSparse: Wrong sparse format "
                     "of SUNMatrix A.");
  }

  /* Check sums of each column of A */
  for (i = 0; i < SM_COLUMNS_S(A); ++i) {
    sum = 0.0;
    for (j = SM_INDEXPTRS_S(A)[i]; j < SM_INDEXPTRS_S(A)[i + 1]; ++j) {
      sum += fabs(SM_DATA_S(A)[j]);
    }

    if (sum == 0.0) { /* TODO: Don't check for equality(!), maybe use DBL_EPSILON */
      warningStreamPrint(LOG_NLS_V, 0,
                         "Column %d of Jacobian is zero. Jacobian is singular.",
                         i);
    } else {
      infoStreamPrint(LOG_NLS_JAC, 0, "Column %d of Jacobian absolute sum = %g",
                      i, sum);
    }
  }
}

/**
 * @brief Set maximum scaled length of Newton step.
 *
 * Will be set to the weighted Euclidean l_2 norm of xScale with maxstepfactor
 * as weights. maxStep = sqrt(sum_{1=0}^{n-1} (xScale[i]*maxstepfactor)^2)
 *
 * @param kinsolData
 * @param maxstepfactor
 */
static void nlsKinsolSetMaxNewtonStep(NLS_KINSOL_DATA *kinsolData,
                                      double maxstepfactor) {
  /* Variables */
  int flag;

  N_VConst(maxstepfactor, kinsolData->fTmp);
  kinsolData->mxnstepin = N_VWL2Norm(kinsolData->xScale, kinsolData->fTmp);

  /* Set maximum step size */
  flag = KINSetMaxNewtonStep(kinsolData->kinsolMemory, kinsolData->mxnstepin);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetMaxNewtonStep");
}

/**
 * @brief Set initial guess for KINSOL
 *
 * Depending on mode extrapolate start value or use old value for
 * initialization.
 *
 * @param data
 * @param kinsolData
 * @param nlsData
 * @param mode          Has to be `INITIAL_EXTRAPOLATION` for extrapolation or
 * `INITIAL_OLDVALUES` for using old values.
 */
static void nlsKinsolResetInitial(DATA *data, NLS_KINSOL_DATA *kinsolData,
                                  NONLINEAR_SYSTEM_DATA *nlsData,
                                  initialMode mode) {
  double *xStart = NV_DATA_S(kinsolData->initialGuess);

  /* Set x vector */
  switch (mode) {
  case INITIAL_EXTRAPOLATION:
    if (data->simulationInfo->discreteCall) {
      memcpy(xStart, nlsData->nlsx, nlsData->size * (sizeof(double)));
    } else {
      memcpy(xStart, nlsData->nlsxExtrapolation,
             nlsData->size * (sizeof(double)));
    }
    break;
  case INITIAL_OLDVALUES:
    memcpy(xStart, nlsData->nlsxOld, nlsData->size * (sizeof(double)));
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0,
                     "Function nlsKinsolResetInitial: Unknown mode %d.",
                     (int)mode);
  }
}

/**
 * @brief Scale x vector.
 *
 * Scale with 1.0 for mode `SCALING_ONES`.
 * Scale with 1/fmax(nominal,|xStart|) for mode `SCALING_NOMINALSTART`.
 *
 * @param data
 * @param kinsolData
 * @param nlsData
 * @param mode          Mode for scaling. Use `SCALING_NOMINALSTART` for nominal
 *                      scaling and `SCALING_ONES` for no scalign. Will be
 * overwritten by simulation flag `FLAG_NO_SCALING`.
 */
static void nlsKinsolXScaling(DATA *data, NLS_KINSOL_DATA *kinsolData,
                              NONLINEAR_SYSTEM_DATA *nlsData,
                              scalingMode mode) {
  double *xStart = NV_DATA_S(kinsolData->initialGuess);
  double *xScaling = NV_DATA_S(kinsolData->xScale);
  int i;

  /* if noScaling flag is used overwrite mode */
  if (omc_flag[FLAG_NO_SCALING]) {
    mode = SCALING_ONES;
  }

  /* Use nominal value or the actual working point for scaling */
  switch (mode) {
  case SCALING_NOMINALSTART:
    for (i = 0; i < nlsData->size; i++) {
      xScaling[i] = 1.0 / fmax(nlsData->nominal[i], fabs(xStart[i]));
    }
    break;
  case SCALING_ONES:
    for (i = 0; i < nlsData->size; i++) {
      xScaling[i] = 1.0;
    }
    break;
  case SCALING_JACOBIAN:
    errorStreamPrint(
        LOG_STDOUT, 0,
        "Function nlsKinsolXScaling: Invalid mode SCALING_JACOBIAN.");
  default:
    errorStreamPrint(LOG_STDOUT, 0,
                     "Function nlsKinsolXScaling: Unknown mode %d.", (int)mode);
  }
}

/**
 * @brief Scale f(x) vector.
 *
 * @param data
 * @param kinsolData
 * @param nlsData
 * @param mode
 */
static void nlsKinsolFScaling(DATA *data, NLS_KINSOL_DATA *kinsolData,
                              NONLINEAR_SYSTEM_DATA *nlsData,
                              scalingMode mode) {
  double *fScaling = NV_DATA_S(kinsolData->fScale);
  N_Vector x = kinsolData->initialGuess;
  SUNMatrix spJac;
  SUNMatrix denseJac;
  N_Vector tmp1, tmp2;

  int i, j;

  /* If noScaling flag is used overwrite mode */
  if (omc_flag[FLAG_NO_SCALING]) {
    mode = SCALING_ONES;
  }

  /* Use nominal value or the actual working point for scaling */
  switch (mode) {
  case SCALING_JACOBIAN:
    tmp1 = N_VNew_Serial(kinsolData->size);
    tmp2 = N_VNew_Serial(kinsolData->size);

    /* Enable scaled jacobian evaluation */
    kinsolData->nominalJac = 1;

    /* Update x for the matrix */
    nlsKinsolResiduals(x, kinsolData->fTmp, &kinsolData->userData);

    /* Calculate the scaled Jacobian */
    if (nlsData->isPatternAvailable &&
        kinsolData->linearSolverMethod == NLS_LS_KLU) {
      spJac = SUNSparseMatrix(kinsolData->size, kinsolData->size,
                              kinsolData->nnz, CSC_MAT);
      if (nlsData->analyticalJacobianColumn != NULL) {
        nlsSparseSymJac(x, kinsolData->fTmp, spJac, &kinsolData->userData, tmp1,
                        tmp2);
      } else {
        nlsSparseJac(x, kinsolData->fTmp, spJac, &kinsolData->userData, tmp1,
                     tmp2);
      }
    } else {
      denseJac = SUNDenseMatrix(kinsolData->size, kinsolData->size);
      nlsDenseJac(nlsData->size, x, kinsolData->fTmp, denseJac,
                  &kinsolData->userData, tmp1, tmp2);
      spJac = SUNSparseFromDenseMatrix(denseJac, DBL_MIN, CSC_MAT);
      if (spJac == NULL) {
        errorStreamPrint(
            LOG_STDOUT, 0,
            "##KINSOL## In function SUNSparseFromDenseMatrix: Requirements are "
            "violated, or matrix storage request cannot be satisfied.");
      }
      SUNMatDestroy(denseJac);
    }

    /* Disable scaled Jacobian evaluation */
    kinsolData->nominalJac = 0;

    for (i = 0; i < nlsData->size; i++) {
      fScaling[i] = 1e-12;
    }
    for (i = 0; i < SM_NNZ_S(spJac); ++i) {
      if (fScaling[SM_INDEXVALS_S(spJac)[i]] < fabs(SM_DATA_S(spJac)[i])) {
        fScaling[SM_INDEXVALS_S(spJac)[i]] = fabs(SM_DATA_S(spJac)[i]);
      }
    }
    /* inverse fScale */
    N_VInv(kinsolData->fScale, kinsolData->fScale);

    /* Free memory */
    SUNMatDestroy(spJac);
    N_VDestroy_Serial(tmp1);
    N_VDestroy_Serial(tmp2);
    break;
  case SCALING_ONES:
    for (i = 0; i < nlsData->size; i++) {
      fScaling[i] = 1.0;
    }
    break;
  case SCALING_NOMINALSTART:
    errorStreamPrint(
        LOG_STDOUT, 0,
        "Function nlsKinsolFScaling: Invalid mode SCALING_NOMINALSTART.");
  default:
    errorStreamPrint(LOG_STDOUT, 0,
                     "Function nlsKinsolFScaling: Unknown mode %d.", (int)mode);
  }
}

/**
 * @brief Print KINSOL configuration.
 *
 * Only prints if stream `LOG_NLS_V` is active.
 *
 * @param kinsolData
 * @param nlsData
 */
static void nlsKinsolConfigPrint(NLS_KINSOL_DATA *kinsolData,
                                 NONLINEAR_SYSTEM_DATA *nlsData) {
  int retValue;
  double fNorm;
  DATA *data = kinsolData->userData.data;
  int eqSystemNumber = nlsData->equationIndex;
  _omc_vector vecStart, vecXScaling, vecFScaling;

  if (!useStream[LOG_NLS_V]) {
    return;
  }

  _omc_initVector(&vecStart, kinsolData->size,
                  NV_DATA_S(kinsolData->initialGuess));
  _omc_initVector(&vecXScaling, kinsolData->size,
                  NV_DATA_S(kinsolData->xScale));
  _omc_initVector(&vecFScaling, kinsolData->size,
                  NV_DATA_S(kinsolData->fScale));

  infoStreamPrint(LOG_NLS_V, 1, "Kinsol Configuration");
  _omc_printVectorWithEquationInfo(
      &vecStart, "Initial guess values", LOG_NLS_V,
      modelInfoGetEquation(&data->modelData->modelDataXml, eqSystemNumber));

  _omc_printVectorWithEquationInfo(
      &vecXScaling, "xScaling", LOG_NLS_V,
      modelInfoGetEquation(&data->modelData->modelDataXml, eqSystemNumber));

  _omc_printVector(&vecFScaling, "fScaling", LOG_NLS_V);

  infoStreamPrint(LOG_NLS_V, 0, "KINSOL F tolerance: %g", kinsolData->fnormtol);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL minimal step size %g",
                  kinsolData->scsteptol);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL max iterations %d",
                  20 * kinsolData->size);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL strategy %d",
                  kinsolData->kinsolStrategy);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL current retry %d", kinsolData->retries);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL max step %g", kinsolData->mxnstepin);
  infoStreamPrint(LOG_NLS_V, 0, "KINSOL linear solver %d",
                  kinsolData->linearSolverMethod);

  messageClose(LOG_NLS_V);
}

/**
 * @brief Try to handle errors of KINSol().
 *
 * @param errorCode
 * @param data
 * @param nlsData
 * @param kinsolData
 * @return int
 */
static int nlsKinsolErrorHandler(int errorCode, DATA *data,
                                 NONLINEAR_SYSTEM_DATA *nlsData,
                                 NLS_KINSOL_DATA *kinsolData) {
  int retValue;
  int i;
  int retValue2 = 0;
  int flag;
  double fNorm;
  double *xStart = NV_DATA_S(kinsolData->initialGuess);
  double *xScaling = NV_DATA_S(kinsolData->xScale);
  long outL;

  flag = KINSetNoInitSetup(kinsolData->kinsolMemory, SUNFALSE);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetNoInitSetup");

  switch (errorCode) {
  case KIN_MEM_NULL:
  case KIN_ILL_INPUT:
  case KIN_NO_MALLOC:
    errorStreamPrint(LOG_NLS_V, 0,
                     "Kinsol has a serious memory issue ERROR %d\n", errorCode);
    return errorCode;
    break;
  /* Just retry with new initial guess */
  case KIN_MXNEWT_5X_EXCEEDED:
    warningStreamPrint(
        LOG_NLS_V, 0,
        "Newton step exceed the maximum step size several times. Try again "
        "after increasing maximum step size.\n");
    kinsolData->maxstepfactor *= 1e5;
    nlsKinsolSetMaxNewtonStep(kinsolData, kinsolData->maxstepfactor);
    return 1;
    break;
  /* Just retry without line search */
  case KIN_LINESEARCH_NONCONV:
    warningStreamPrint(
        LOG_NLS_V, 0,
        "kinsols line search did not convergence. Try without.\n");
    kinsolData->kinsolStrategy = KIN_NONE;
    kinsolData->retries--;
    return 1;
    break;
  /* Maybe happened because of an out-dated factorization, so just retry */
  case KIN_LSOLVE_FAIL:
    warningStreamPrint(LOG_NLS_V, 0,
                       "kinsols matrix need new factorization. Try again.\n");
    if (nlsData->isPatternAvailable) {
      /* Complete symbolic and numeric factorizations */
      flag = SUNLinSol_KLUReInit(kinsolData->linSol, kinsolData->J,
                                 kinsolData->nnz, SUNKLU_REINIT_PARTIAL);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_SUNLS_FLAG, "SUNLinSol_KLUReInit");
    }
    return 1;
    break;
  case KIN_MAXITER_REACHED:
  case KIN_REPTD_SYSFUNC_ERR:
    warningStreamPrint(
        LOG_NLS_V, 0,
        "kinsols runs into issues retry with different configuration.\n");
    retValue = 1;
    break;
  case KIN_LSETUP_FAIL:
    /* In case something goes wrong with the symbolic jacobian try the numerical */
    if (kinsolData->linearSolverMethod == NLS_LS_KLU &&
        nlsData->isPatternAvailable &&
        nlsData->analyticalJacobianColumn != NULL) {
      warningStreamPrint(LOG_NLS_V, 0,
                         "The kinls setup routine (lsetup) encountered an error. "
                         "Retry with numerical Jacobian.\n");
      flag = KINSetJacFn(kinsolData->kinsolMemory, nlsSparseJac);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
    }
    if (flag < 0) {
      return flag;
    } else {
      retValue = 1;
    }
    break;
  case KIN_LINESEARCH_BCFAIL:
    KINGetNumBetaCondFails(kinsolData->kinsolMemory, &outL);
    warningStreamPrint(
        LOG_NLS_V, 0,
        "kinsols runs into issues with beta-condition fails: %ld\n", outL);
    retValue = 1;
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0,
                     "kinsol has a serious solving issue ERROR %d\n",
                     errorCode);
    return errorCode;
    break;
  }

  /* check if the current solution is sufficient anyway */
  KINGetFuncNorm(kinsolData->kinsolMemory, &fNorm);
  if (fNorm < FTOL_WITH_LESS_ACCURANCY) {
    warningStreamPrint(LOG_NLS_V, 0,
                       "Move forward with a less accurate solution.");
    KINSetFuncNormTol(kinsolData->kinsolMemory, FTOL_WITH_LESS_ACCURANCY);
    KINSetScaledStepTol(kinsolData->kinsolMemory, FTOL_WITH_LESS_ACCURANCY);
    retValue2 = 1;
  } else {
    warningStreamPrint(LOG_NLS_V, 0, "Current status of fx = %f", fNorm);
  }

  /* reconfigure kinsol for another try */
  if (retValue == 1 && !retValue2) {
    switch (kinsolData->retries) {
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

  return retValue + retValue2;
}

int nlsKinsolSolve(DATA *data, threadData_t *threadData, int sysNumber) {
  NONLINEAR_SYSTEM_DATA *nlsData =
      &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA *)nlsData->solverData;
  long eqSystemNumber = nlsData->equationIndex;
  int indexes[2] = {1, eqSystemNumber};

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

  infoStreamPrintWithEquationIndexes(LOG_NLS_V, 1, indexes,
                                     "Start Kinsol solver at time %g",
                                     data->localData[0]->timeValue);

  /* Solve nonlinear system with KINSol() */
  kinsolData->retries = 0;
  do {
    nlsKinsolResetInitial(data, kinsolData, nlsData, INITIAL_EXTRAPOLATION);

    /* Set x scaling */
    nlsKinsolXScaling(data, kinsolData, nlsData, SCALING_NOMINALSTART);

    /* Set f scaling */
    nlsKinsolFScaling(data, kinsolData, nlsData, SCALING_JACOBIAN);

    /* Set maximum step size */
    nlsKinsolSetMaxNewtonStep(kinsolData, kinsolData->maxstepfactor);

    /* Dump configuration */
    nlsKinsolConfigPrint(kinsolData, nlsData);

    flag = KINSol(
        kinsolData->kinsolMemory,   /* KINSol memory block */
        kinsolData->initialGuess,   /* initial guess on input; solution vector */
        kinsolData->kinsolStrategy, /* global strategy choice */
        kinsolData->xScale,         /* scaling vector, for the variable cc */
        kinsolData->fScale);        /* scaling vector for function values fval */

    if (flag < 0) {
      warningStreamPrint(LOG_NLS, 0, "KINSol finished with errorCode %d.", flag);
    } else {
      infoStreamPrint(LOG_NLS_V, 0, "KINSol finished with errorCode %d.", flag);
    }
    /* Try to handle recoverable errors */
    if (flag < 0) {
      retry = nlsKinsolErrorHandler(flag, data, nlsData, kinsolData);
    }

    /* solution found */
    if ((flag == KIN_SUCCESS) || (flag == KIN_INITIAL_GUESS_OK) ||
        (flag == KIN_STEP_LT_STPTOL)) {
      success = 1;
    }
    kinsolData->retries++;

    /* write statistics */
    KINGetNumNonlinSolvIters(kinsolData->kinsolMemory, &nFEval);
    nlsData->numberOfIterations += nFEval;
    nlsData->numberOfFEval += kinsolData->countResCalls;

    infoStreamPrint(
        LOG_NLS_V, 0, "Next try? success = %d, retry = %d, retries = %d = %s\n",
        success, retry, kinsolData->retries,
        !success && !(retry < 1) && kinsolData->retries < RETRY_MAX ? "true"
                                                                    : "false");
  } while (!success && !(retry < 0) && kinsolData->retries < RETRY_MAX);

  /* Solution found */
  if (success) {
    /* Check if solution really solves the residuals */
    nlsKinsolResiduals(kinsolData->initialGuess, kinsolData->fRes,
                       &kinsolData->userData);
    if (!omc_flag[FLAG_NO_SCALING]) {
      N_VProd(kinsolData->fRes, kinsolData->fScale, kinsolData->fRes);
    }
    fNormValue = N_VWL2Norm(kinsolData->fRes, kinsolData->fRes);

    infoStreamPrint(LOG_NLS_V, 0, "%sEuclidean norm of F(u) = %e",
                    (omc_flag[FLAG_NO_SCALING]) ? "" : "scaled ", fNormValue);
    if (FTOL_WITH_LESS_ACCURANCY < fNormValue) {
      warningStreamPrint(LOG_NLS_V, 0,
                         "False positive solution. FNorm is not small enough.");
      success = 0;
    } else { /* solved system for reuse linear solver information */
      kinsolData->solved = 1;
    }
    /* copy solution */
    memcpy(nlsData->nlsx, xStart, nlsData->size * (sizeof(double)));
  }

  messageClose(LOG_NLS_V);

  return success;
}

#else /* WITH_SUNDIALS */

int nlsKinsolAllocate(int size, NONLINEAR_SYSTEM_DATA *nlsData,
                      int linearSolverMethod) {

  throwStreamPrint(NULL, "No sundials/kinsol support activated.");
  return 0;
}

int nlsKinsolFree(void **solverData) {

  throwStreamPrint(NULL, "No sundials/kinsol support activated.");
  return 0;
}

int nlsKinsolSolve(DATA *data, threadData_t *threadData, int sysNumber) {

  throwStreamPrint(threadData, "No sundials/kinsol support activated.");
  return 0;
}

#endif /* WITH_SUNDIALS */
