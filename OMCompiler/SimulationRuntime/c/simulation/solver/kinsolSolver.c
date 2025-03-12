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
#include "sundials_util.h"
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
static int nlsKinsolResiduals(N_Vector x, N_Vector f, void* userData);
static int nlsSparseJac(N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                        void* userData, N_Vector tmp1, N_Vector tmp2);
int nlsSparseSymJac(N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                    void* userData, N_Vector tmp1, N_Vector tmp2);
static int nlsDenseJac(long int N, N_Vector vecX, N_Vector vecFX,
                       SUNMatrix Jac, NLS_USERDATA *kinsolUserData,
                       N_Vector tmp1, N_Vector tmp2);
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
  flag = KINSetFuncNormTol(kinsolData->kinsolMemory,
                           kinsolData->fnormtol); /* Set function-norm stopping tolerance */
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetFuncNormTol");
  kinsolData->resetTol = FALSE;

  flag = KINSetScaledStepTol(kinsolData->kinsolMemory,
                             kinsolData->scsteptol); /* Set scaled-step stopping tolerance */
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetScaledStepTol");

  flag = KINSetNumMaxIters(kinsolData->kinsolMemory,
                           100 * kinsolData->size); /* Set max. number of nonlinear iterations */
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetNumMaxIters");

  kinsolData->kinsolStrategy = KIN_LINESEARCH; /* Newton with globalization strategy to solve nonlinear systems */

  flag = KINSetNoInitSetup(kinsolData->kinsolMemory, SUNFALSE); /* TODO: This is the default value. Is there a point in calling this function? */
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetNoInitSetup");

  kinsolData->retries = 0;
  kinsolData->countResCalls = 0;
}

/**
 * @brief Initialize KINSOL data.
 *
 * Allocate memory for KINSOL data and Jacobian.
 *
 * @param kinsolData          KINSOL data.
 */
void initKinsolMemory(NLS_KINSOL_DATA *kinsolData) {
  int flag;
  int printLevel;
  int size = kinsolData->size;
  NONLINEAR_SYSTEM_DATA *nlsData = kinsolData->userData->nlsData;
  SPARSE_PATTERN* sparsePattern = nlsData->sparsePattern;

  /* Free KINSOL memory block */
  if (kinsolData->kinsolMemory != NULL || kinsolData->J != NULL || kinsolData->scaledJ != NULL) {
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "KINSOL: Already allocated kinsol memory. Loosing memory!");
  }

  /* Create KINSOL memory block */
  kinsolData->kinsolMemory = KINCreate();
  if (kinsolData->kinsolMemory == NULL) {
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "KINSOL: In function KINCreate: An error occurred.");
  }

  /* Set error handler and print level */
  if (!nlsData->logActive) {
    printLevel = 0;
  } else if (OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)) {
    printLevel = 3;
  } else if (OMC_ACTIVE_STREAM(OMC_LOG_NLS)) {
    printLevel = 1;
  } else {
    printLevel = 0;
  }
  infoStreamPrint(OMC_LOG_NLS, 0, "KINSOL: log level %i", printLevel);
  flag = KINSetPrintLevel(kinsolData->kinsolMemory, printLevel);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetPrintLevel");

  flag = KINSetErrHandlerFn(kinsolData->kinsolMemory, kinsolErrorHandlerFunction, kinsolData);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetErrHandlerFn");

  flag = KINSetInfoHandlerFn(kinsolData->kinsolMemory, kinsolInfoHandlerFunction, NULL);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetInfoHandlerFn");

  flag = KINSetUserData(kinsolData->kinsolMemory, (void*)kinsolData->userData);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetUserData");

  /* Initialize KINSOL object */
  flag = KINInit(kinsolData->kinsolMemory, nlsKinsolResiduals,
                 kinsolData->initialGuess);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINInit");

  /* Create matrix object */
  if (kinsolData->linearSolverMethod == NLS_LS_DEFAULT ||
      kinsolData->linearSolverMethod == NLS_LS_LAPACK) {
    kinsolData->J = SUNDenseMatrix(size, size);
  } else if (kinsolData->linearSolverMethod == NLS_LS_KLU) {
    if (!sparsePattern) {
      kinsolData->nnz = size*size;
    } else {
      kinsolData->nnz = sparsePattern->numberOfNonZeros;
    }
    kinsolData->J = SUNSparseMatrix(size, size, kinsolData->nnz, CSC_MAT);
    kinsolData->scaledJ = SUNSparseMatrix(size, size, kinsolData->nnz, CSC_MAT);
  }

  /* Create linear solver object */
  if (kinsolData->linearSolverMethod == NLS_LS_DEFAULT ||
      kinsolData->linearSolverMethod == NLS_LS_TOTALPIVOT) {
    kinsolData->linSol = SUNLinSol_Dense(kinsolData->y, kinsolData->J);
    if (kinsolData->linSol == NULL) {
      throwStreamPrint(NULL, "KINSOL: In function SUNLinSol_Dense: Input incompatible.");
    }
  } else if (kinsolData->linearSolverMethod == NLS_LS_LAPACK) {
    kinsolData->linSol = SUNLinSol_LapackDense(kinsolData->y, kinsolData->J);
    if (kinsolData->linSol == NULL) {
      throwStreamPrint(NULL, "KINSOL: In function SUNLinSol_LapackDense: Input incompatible.");
    }
  } else if (kinsolData->linearSolverMethod == NLS_LS_KLU) {
    kinsolData->linSol = SUNLinSol_KLU(kinsolData->y, kinsolData->J);
    if (kinsolData->linSol == NULL) {
      throwStreamPrint(NULL, "KINSOL: In function SUNLinSol_KLU: Input incompatible.");
    }
  } else {
    throwStreamPrint(NULL, "KINSOL: Unknown linear solver method.");
  }
  /* Log used solver */
  infoStreamPrint(OMC_LOG_NLS, 0, "KINSOL: Using linear solver method %s", NLS_LS_METHOD_NAME[kinsolData->linearSolverMethod]);

  /* Set linear solver */
  flag = KINSetLinearSolver(kinsolData->kinsolMemory, kinsolData->linSol,
                            kinsolData->J);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetLinearSolver");

  /* Set Jacobian for non-linear solver */
  if (kinsolData->linearSolverMethod == NLS_LS_KLU) {
    if (nlsData->analyticalJacobianColumn != NULL && sparsePattern != NULL) {
      flag = KINSetJacFn(kinsolData->kinsolMemory, nlsSparseSymJac); /* Use symbolic Jacobian with sparsity pattern*/
    } else if (sparsePattern != NULL) {
      flag = KINSetJacFn(kinsolData->kinsolMemory, nlsSparseJac); /* Use numeric Jacobian with sparsity pattern */
    } else {
      throwStreamPrint(NULL, "KINSOL: In function initKinsolMemory: Sparse linear solver KLU needs sparse Jacobian, but no sparsity pattern is available. Use a dense non-linear solver instead of KINSOL.");
    }
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
  }

  /* Configuration */
  nlsKinsolConfigSetup(kinsolData);
}

/**
 * @brief Allocate memory for kinsol solver data and initialize KINSOL solver.
 *
 * @param size                  Size of non-linear problem.
 * @param userData              Pointer to set NLS user data.
 * @param attemptRetry          True if KINSOL should retry with different settings after solution failed.
 * @param isPatternAvailable    True if sparsity pattern of Jacobian is available. Allocate work vectors for KLU in that case.
 * @return NLS_KINSOL_DATA*     Pointer to allocated KINSOL data.
 */
NLS_KINSOL_DATA* nlsKinsolAllocate(int size, NLS_USERDATA* userData, modelica_boolean attemptRetry, modelica_boolean isPatternAvailable) {
  /* Allocate system data */
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA *)calloc(1, sizeof(NLS_KINSOL_DATA));

  kinsolData->size = size;
  kinsolData->linearSolverMethod = userData->nlsData->nlsLinearSolver;
  kinsolData->solved = NLS_FAILED;

  kinsolData->fnormtol = newtonFTol;  /* function tolerance */
  kinsolData->scsteptol = newtonXTol; /* step tolerance */

  kinsolData->maxstepfactor = maxStepFactor; /* step tolerance */
  kinsolData->nominalJac = 0; /* calculate for scaling the scaled matrix */
  kinsolData->attemptRetry = attemptRetry;

  kinsolData->initialGuess = N_VNew_Serial(size);
  kinsolData->xScale = N_VNew_Serial(size);
  kinsolData->fScale = N_VNew_Serial(size);
  kinsolData->fRes = N_VNew_Serial(size);
  kinsolData->fTmp = N_VNew_Serial(size);

  kinsolData->y = N_VNew_Serial(size);
  kinsolData->J = NULL;

  /* tmp1, tmp2 only needed for numeric Jacobian */
  if (userData->nlsData->analyticalJacobianColumn != NULL &&
      isPatternAvailable &&
      kinsolData->linearSolverMethod == NLS_LS_KLU)
  {
    kinsolData->tmp1 = NULL;
    kinsolData->tmp2 = NULL;
  } else {
    kinsolData->tmp1 = N_VNew_Serial(size);
    kinsolData->tmp2 = N_VNew_Serial(size);
  }
  /* Scaled Jacobian is allocated with J */
  kinsolData->scaledJ = NULL;

  kinsolData->kinsolMemory = NULL;
  kinsolData->userData = userData;

  initKinsolMemory(kinsolData);

  return kinsolData;
}

/**
 * @brief Deallocates memory for KINSOL solver.
 *
 * Free memory that was allocated with `nlsKinsolAllocate`.
 *
 * @param kinsolData    Pointer to KINSOL data.
 */
void nlsKinsolFree(NLS_KINSOL_DATA* kinsolData) {
  KINFree((void *)&kinsolData->kinsolMemory);

  N_VDestroy_Serial(kinsolData->initialGuess);
  N_VDestroy_Serial(kinsolData->xScale);
  N_VDestroy_Serial(kinsolData->fScale);
  N_VDestroy_Serial(kinsolData->fRes);
  N_VDestroy_Serial(kinsolData->fTmp);

  /* Free linear solver data */
  SUNLinSolFree(kinsolData->linSol);
  SUNMatDestroy(kinsolData->J);
  N_VDestroy_Serial(kinsolData->y);
  if (kinsolData->tmp1 != NULL) {
    N_VDestroy_Serial(kinsolData->tmp1);
    N_VDestroy_Serial(kinsolData->tmp2);
  }

  freeNlsUserData(kinsolData->userData);
  free(kinsolData);

  return;
}

/**
 * @brief Residual function for non-linear problem.
 *
 * @param x         The current value of the variable vector.
 * @param f         Output vector.
 * @param userData  Pointer to Kinsol user data.
 * @return int      Return 0 on success, return 1 on recoverable error.
 */
static int nlsKinsolResiduals(N_Vector x, N_Vector f, void* userData) {
  double *xdata = NV_DATA_S(x);
  double *fdata = NV_DATA_S(f);

  NLS_USERDATA* kinsolUserData = (NLS_USERDATA*)userData;
  DATA* data = kinsolUserData->data;
  threadData_t* threadData = kinsolUserData->threadData;
  NONLINEAR_SYSTEM_DATA* nlsData = kinsolUserData->nlsData;
  NLS_KINSOL_DATA* kinsolData = (NLS_KINSOL_DATA*)nlsData->solverData;
  RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=kinsolUserData->solverData};
  int iflag = 1 /* recoverable error */;

  /* Update statistics */
  kinsolData->countResCalls++;

#ifndef OMC_EMCC
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /* call residual function */
  nlsData->residualFunc(&resUserData, xdata, fdata, (const int *)&iflag);
  iflag = 0 /* success */;

#ifndef OMC_EMCC
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  return iflag;
}

/**
 * @brief Calculate dense Jacobian matrix.
 *
 * @param N               Size of vecX and vecFX.
 * @param vecX            Vector x.
 * @param vecFX           Residual vector f(x).
 * @param Jac             Dense Jacobian matrix J(x).
 * @param kinsolUserData  Pointer to Kinsol user data.
 * @param tmp1            Unused, only to match interface of KINLsJacFn
 * @param tmp2            Unused, only to match interface of KINLsJacFn
 * @return int            Return 0 on success, -1 on failure.
 */
static int nlsDenseJac(long int N,
                       N_Vector vecX,
                       N_Vector vecFX,
                       SUNMatrix Jac,
                       NLS_USERDATA *kinsolUserData,
                       N_Vector tmp1,
                       N_Vector tmp2) {
  DATA *data = kinsolUserData->data;
  threadData_t *threadData = kinsolUserData->threadData;
  NONLINEAR_SYSTEM_DATA *nlsData = kinsolUserData->nlsData;
  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA *)nlsData->solverData;

  if (SUNMatGetID(Jac) != SUNMATRIX_DENSE) {
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "KINSOL: nlsDenseJac illegal input Jac. Matrix is not dense!");
    return -1;
  }

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
    nlsKinsolResiduals(vecX, kinsolData->fRes, kinsolUserData);

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
  if (OMC_ACTIVE_STREAM(OMC_LOG_NLS_JAC)) {
    infoStreamPrint(OMC_LOG_NLS_JAC, 1, "KINSOL: Dense matrix.");
    SUNDenseMatrix_Print(Jac, stdout); /* TODO: Print in OMC_LOG_NLS_JAC */
    nlsKinsolJacSumDense(Jac);
    messageClose(OMC_LOG_NLS_JAC);
  }

  /* performance measurement and statistics */
  nlsData->jacobianTime += rt_ext_tp_tock(&(nlsData->jacobianTimeClock));
  nlsData->numberOfJEval++;

  return 0;
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
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "KINSOL: In function finishSparseColPtr: Wrong sparse format of SUNMatrix A.");
  }

  /* Set last value of indexptrs to nnz */
  SM_INDEXPTRS_S(A)[SM_COLUMNS_S(A)] = nnz;

  /* Check for empty rows */
  for (i = 1; i < SM_COLUMNS_S(A) + 1; ++i) {
    if (SM_INDEXPTRS_S(A)[i] == SM_INDEXPTRS_S(A)[i - 1]) {
      warningStreamPrint(OMC_LOG_STDOUT, 0,
                         "KINSOL: Jacobian row %d singular. See OMC_LOG_NLS for "
                         "more information.",
                         i);
      SM_INDEXPTRS_S(A)[i] = SM_INDEXPTRS_S(A)[i - 1];
    }
  }
}

/**
 * @brief Colored numeric Jacobian evaluation.
 *
 * Finite differences while using coloring of Jacobian.
 * Jacobian matrix format has to be compressed sparse columns (CSC).
 *
 * @param vecX      Input vector x.
 * @param vecFX     Vector for residual evaluation: f(x)
 * @param Jac       Jacobian to calculate: J(x)
 * @param userData  Pointer to user data, tpyecasted to `NLS_USERDATA`.
 * @param tmp1      Work vector.
 * @param tmp2      Work vector.
 * @return int      Return 0 on success.
 */
static int nlsSparseJac(N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                        void *userData, N_Vector tmp1, N_Vector tmp2) {
  /* Variables */
  NLS_USERDATA *kinsolUserData;
  DATA *data;
  threadData_t *threadData;
  NONLINEAR_SYSTEM_DATA *nlsData;
  NLS_KINSOL_DATA *kinsolData;
  SPARSE_PATTERN *sparsePattern;

  if (SUNMatGetID(Jac) != SUNMATRIX_SPARSE || SM_SPARSETYPE_S(Jac) == CSR_MAT) {
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "KINSOL: nlsSparseJac illegal input Jac. Matrix is not sparse!");
    return -1;
  }

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
  kinsolUserData = (NLS_USERDATA *)userData;
  data = kinsolUserData->data;
  threadData = kinsolUserData->threadData;
  nlsData = kinsolUserData->nlsData;
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
            setJacElementSundialsSparse(j, ii, nth, (fRes[j] - fx[j]) * delta_hh[ii] / xScaling[ii], Jac, SM_CONTENT_S(Jac)->M);
          } else {
            setJacElementSundialsSparse(j, ii, nth, (fRes[j] - fx[j]) * delta_hh[ii], Jac, SM_CONTENT_S(Jac)->M);
          }
          nth++;
        }
        x[ii] = xsave[ii];
      }
    }
  }
  /* Finish sparse matrix */
  finishSparseColPtr(Jac, sparsePattern->numberOfNonZeros);

  /* Debug print */
  if (OMC_ACTIVE_STREAM(OMC_LOG_NLS_JAC)) {
    infoStreamPrint(OMC_LOG_NLS_JAC, 1, "KINSOL: Sparse Matrix.");
    SUNSparseMatrix_Print(Jac, stdout);
    nlsKinsolJacSumSparse(Jac);
    messageClose(OMC_LOG_NLS_JAC);
  }
  if (OMC_ACTIVE_STREAM(OMC_LOG_DEBUG)) {
    sundialsPrintSparseMatrix(Jac, "A", OMC_LOG_JAC);
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
 * @param vecFX     just for interface compatibility, will not be used here
 * @param Jac       Allocated Jacobian, contains symbolic Jacobian on exit
 * @param userData  Void pointer to user data of type NLS_USERDATA*.
 * @param tmp1      Unused, only to match interface of KINLsJacFn
 * @param tmp2      Unused, only to match interface of KINLsJacFn
 * @return int
 */
int nlsSparseSymJac(N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                    void *userData, N_Vector tmp1, N_Vector tmp2) {
  /* Variables */
  NLS_USERDATA *kinsolUserData;
  DATA *data;
  threadData_t *threadData;
  NONLINEAR_SYSTEM_DATA *nlsData;
  NLS_KINSOL_DATA *kinsolData;
  SPARSE_PATTERN *sparsePattern;
  ANALYTIC_JACOBIAN *analyticJacobian;

  double *x;
  double *fx;
  double *xScaling;

  long int i, j, ii;
  int nth;

  if (SUNMatGetID(Jac) != SUNMATRIX_SPARSE || SM_SPARSETYPE_S(Jac) == CSR_MAT) {
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "KINSOL: nlsSparseJac illegal input Jac. Matrix is not sparse!");
    return -1;
  }

  /* Access userData and nonlinear system data */
  kinsolUserData = (NLS_USERDATA *)userData;
  data = kinsolUserData->data;
  threadData = kinsolUserData->threadData;
  nlsData = kinsolUserData->nlsData;
  analyticJacobian = kinsolUserData->analyticJacobian;
  kinsolData = (NLS_KINSOL_DATA *)nlsData->solverData;
  sparsePattern = nlsData->sparsePattern;

  /* Access N_Vector variables */
  x = N_VGetArrayPointer(vecX);
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
    nlsData->analyticalJacobianColumn(data, threadData, analyticJacobian, NULL);

    /* Save column in Jac and unset seed variables */
    for (ii = 0; ii < kinsolData->size; ii++) {
      if (sparsePattern->colorCols[ii] - 1 == i) {
        nth = sparsePattern->leadindex[ii];
        while (nth < sparsePattern->leadindex[ii + 1]) {
          j = sparsePattern->index[nth];
          if (kinsolData->nominalJac) {
            setJacElementSundialsSparse(j, ii, nth, analyticJacobian->resultVars[j] / xScaling[ii], Jac, SM_CONTENT_S(Jac)->M);
          } else {
            setJacElementSundialsSparse(j, ii, nth, analyticJacobian->resultVars[j], Jac, SM_CONTENT_S(Jac)->M);
          }
          nth++;
        }
        analyticJacobian->seedVars[ii] = 0;
      }
    }
  }

  /* Finish sparse matrix and do a cheap check for singularity */
  finishSparseColPtr(Jac, sparsePattern->numberOfNonZeros);

  /* Debug print */
  if (OMC_ACTIVE_STREAM(OMC_LOG_NLS_JAC)) {
    infoStreamPrint(OMC_LOG_NLS_JAC, 1, "KINSOL: Sparse Matrix.");
    SUNSparseMatrix_Print(Jac, stdout); /* TODO: Print in OMC_LOG_NLS_JAC */
    nlsKinsolJacSumSparse(Jac);
    messageClose(OMC_LOG_NLS_JAC);
  }

  /* performance measurement and statistics */
  nlsData->jacobianTime += rt_ext_tp_tock(&(nlsData->jacobianTimeClock));
  nlsData->numberOfJEval++;

  return 0;
}

/**
 * @brief Check for zero columns of matrix and print absolute sums.
 *
 * Compute absolute sum for each column and print the result.
 * Report a warning if it is zero, since the matrix is singular in that case.
 *
 * @param A       Dense matrix stored columnwise
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
      warningStreamPrint(OMC_LOG_NLS_V, 0,
                         "KINSOL: Column %d of Jacobian is zero. Jacobian is singular.",
                         i);
    } else {
      infoStreamPrint(OMC_LOG_NLS_JAC, 0, "Column %d of Jacobian absolute sum = %g",
                      i, sum);
    }
  }
}

/**
 * @brief Check for zero columns of matrix and print absolute sums.
 *
 * Compute absolute sum for each column and print the result.
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
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "KINSOL: In function nlsKinsolJacSumSparse: Wrong sparse format "
                     "of SUNMatrix A.");
  }

  /* Check sums of each column of A */
  for (i = 0; i < SM_COLUMNS_S(A); ++i) {
    sum = 0.0;
    for (j = SM_INDEXPTRS_S(A)[i]; j < SM_INDEXPTRS_S(A)[i + 1]; ++j) {
      sum += fabs(SM_DATA_S(A)[j]);
    }

    if (sum == 0.0) { /* TODO: Don't check for equality(!), maybe use DBL_EPSILON */
      warningStreamPrint(OMC_LOG_NLS_V, 0,
                         "KINSOL: Column %d of Jacobian is zero. Jacobian is singular.",
                         i);
    } else {
      infoStreamPrint(OMC_LOG_NLS_JAC, 0, "Column %d of Jacobian absolute sum = %g",
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
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "KINSOL: Function nlsKinsolResetInitial: Unknown mode %d.",
                     (int)mode);
  }
}

/**
 * @brief Scale x vector.
 *
 * Scale with 1.0 for mode `SCALING_ONES`.
 * Scale with 1/fmax(nominal,|xStart|) for mode `SCALING_NOMINALSTART`.
 *
 * @param data          unused
 * @param kinsolData
 * @param nlsData
 * @param mode          Mode for scaling. Use `SCALING_NOMINALSTART` for nominal
 *                      scaling and `SCALING_ONES` for no scaling. Will be
 *                      overwritten by simulation flag `FLAG_NO_SCALING`.
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
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "KINSOL: Function nlsKinsolXScaling: Invalid mode SCALING_JACOBIAN.");
  default:
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "KINSOL: Function nlsKinsolXScaling: Unknown mode %d.", (int)mode);
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

  int i, j;
  int ret;

  /* If noScaling flag is used overwrite mode */
  if (omc_flag[FLAG_NO_SCALING]) {
    mode = SCALING_ONES;
  }

  /* Use nominal value or the actual working point for scaling */
  switch (mode) {
  case SCALING_JACOBIAN:
    /* Enable scaled jacobian evaluation */
    kinsolData->nominalJac = 1;

    /* Calculate the scaled Jacobian */
    if (nlsData->isPatternAvailable && kinsolData->linearSolverMethod == NLS_LS_KLU) {
      if (kinsolData->solved != NLS_SOLVED) {
        kinsolData->nominalJac = 0;
        if (nlsData->analyticalJacobianColumn != NULL) {
          /* Calculate the sparse Jacobian symbolically  */
          nlsSparseSymJac(x, kinsolData->fTmp, kinsolData->J, kinsolData->userData, NULL, NULL);
        } else {
          /* Update f(x) for the numerical jacobian matrix */
          nlsKinsolResiduals(x, kinsolData->fTmp, kinsolData->userData);
          nlsSparseJac(x, kinsolData->fTmp, kinsolData->J, kinsolData->userData, kinsolData->tmp1, kinsolData->tmp2);
        }
      }
      /* Scale the current Jacobian */
      SUNMatCopy_Sparse(kinsolData->J, kinsolData->scaledJ);  /* Copy J into scaledJ */
      ret = _omc_SUNSparseMatrixVecScaling(kinsolData->scaledJ, kinsolData->xScale);
      if (ret != 0) {
        errorStreamPrint(OMC_LOG_STDOUT, 0, "KINSOL: _omc_SUNSparseMatrixVecScaling failed.");
      }
    } else {
      /* Update f(x) for the numerical jacobian matrix */
      nlsKinsolResiduals(x, kinsolData->fTmp, kinsolData->userData);
      nlsDenseJac(nlsData->size, x, kinsolData->fTmp, kinsolData->J,
                  kinsolData->userData, NULL, NULL);
    }

    /* Disable scaled Jacobian evaluation */
    kinsolData->nominalJac = 0;

    for (i = 0; i < nlsData->size; i++) {
      fScaling[i] = 1e-12;
    }

    switch (SUNMatGetID(kinsolData->J))
    {
    case SUNMATRIX_SPARSE:
      for (i = 0; i < SM_NNZ_S(kinsolData->scaledJ); ++i) {
        if (fScaling[SM_INDEXVALS_S(kinsolData->scaledJ)[i]] < fabs(SM_DATA_S(kinsolData->scaledJ)[i])) {
          fScaling[SM_INDEXVALS_S(kinsolData->scaledJ)[i]] = fabs(SM_DATA_S(kinsolData->scaledJ)[i]);
        }
      }
      break;
    case SUNMATRIX_DENSE:
      for (i = 0; i < nlsData->size; i++) {
        for (j = 0; j < nlsData->size; j++) {
          if (fScaling[i] < fabs(SM_ELEMENT_D(kinsolData->J, j, i))) {
            fScaling[i] = fabs(SM_ELEMENT_D(kinsolData->J, j, i));
          }
        }
      }
      break;
    default:
      errorStreamPrint(OMC_LOG_STDOUT, 0,
                       "KINSOL: Function nlsKinsolFScaling: Unknown matrix type.");
    }

    /* inverse fScale */
    N_VInv(kinsolData->fScale, kinsolData->fScale);

    break;
  case SCALING_ONES:
    for (i = 0; i < nlsData->size; i++) {
      fScaling[i] = 1.0;
    }
    break;
  case SCALING_NOMINALSTART:
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "KINSOL: Function nlsKinsolFScaling: Invalid mode SCALING_NOMINALSTART.");
  default:
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "KINSOL: Function nlsKinsolFScaling: Unknown mode %d.", (int)mode);
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
  DATA *data = kinsolData->userData->data;
  int eqSystemNumber = nlsData->equationIndex;
  _omc_vector vecStart, vecXScaling, vecFScaling;

  if (!omc_useStream[OMC_LOG_NLS_V]) {
    return;
  }

  _omc_initVector(&vecStart, kinsolData->size,
                  NV_DATA_S(kinsolData->initialGuess));
  _omc_initVector(&vecXScaling, kinsolData->size,
                  NV_DATA_S(kinsolData->xScale));
  _omc_initVector(&vecFScaling, kinsolData->size,
                  NV_DATA_S(kinsolData->fScale));

  _omc_printVectorWithEquationInfo(
      &vecStart, "Initial guess values", OMC_LOG_NLS_V,
      modelInfoGetEquation(&data->modelData->modelDataXml, eqSystemNumber));

  _omc_printVectorWithEquationInfo(
      &vecXScaling, "xScaling", OMC_LOG_NLS_V,
      modelInfoGetEquation(&data->modelData->modelDataXml, eqSystemNumber));

  _omc_printVector(&vecFScaling, "fScaling", OMC_LOG_NLS_V);

  infoStreamPrint(OMC_LOG_NLS_V, 0, "KINSOL F tolerance: %g", kinsolData->fnormtol);
  infoStreamPrint(OMC_LOG_NLS_V, 0, "KINSOL minimal step size %g",
                  kinsolData->scsteptol);
  infoStreamPrint(OMC_LOG_NLS_V, 0, "KINSOL max iterations %d",
                  20 * kinsolData->size);
  infoStreamPrint(OMC_LOG_NLS_V, 0, "KINSOL strategy %d",
                  kinsolData->kinsolStrategy);
  infoStreamPrint(OMC_LOG_NLS_V, 0, "KINSOL current retry %d", kinsolData->retries);
  infoStreamPrint(OMC_LOG_NLS_V, 0, "KINSOL max step %g", kinsolData->mxnstepin);
  infoStreamPrint(OMC_LOG_NLS_V, 0, "KINSOL linear solver %d",
                  kinsolData->linearSolverMethod);
}

/**
 * @brief Try to handle errors of KINSol().
 *
 * @param errorCode           Error code from KINSOL.
 * @param data                Pointer to data struct.
 * @param nlsData             Non-linear solver data.
 * @param kinsolData          Kinsol data.
 * @return modelica_boolean   Return true, if it is possible to retry KINSol().
 */
static modelica_boolean nlsKinsolErrorHandler(int errorCode, DATA *data,
                                              NONLINEAR_SYSTEM_DATA *nlsData,
                                              NLS_KINSOL_DATA *kinsolData) {
  int flag;
  double fNorm;
  double *xStart = NV_DATA_S(kinsolData->initialGuess);
  double *xScaling = NV_DATA_S(kinsolData->xScale);
  long outL;

  flag = KINSetNoInitSetup(kinsolData->kinsolMemory, SUNFALSE);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetNoInitSetup");

  switch (errorCode) {
  case KIN_MEM_NULL:
    throwStreamPrint(NULL, "KINSOL: Memory NULL ERROR %d\n", errorCode);
    return FALSE;
    break;
  case KIN_ILL_INPUT:
    throwStreamPrint(NULL, "KINSOL: Ill input ERROR %d\n", errorCode);
    return FALSE;
    break;
  case KIN_NO_MALLOC:
    throwStreamPrint(NULL, "KINSOL: Memory issue ERROR %d\n", errorCode);
    return FALSE;
    break;
  /* Just retry with new initial guess */
  case KIN_MXNEWT_5X_EXCEEDED:
    warningStreamPrint(
        OMC_LOG_NLS_V, 0,
        "Newton step exceed the maximum step size several times. Try again "
        "after increasing maximum step size.\n");
    kinsolData->maxstepfactor *= 1e5;
    nlsKinsolSetMaxNewtonStep(kinsolData, kinsolData->maxstepfactor);
    return TRUE;
    break;
  /* Just retry without line search */
  case KIN_LINESEARCH_NONCONV:
    warningStreamPrint(
        OMC_LOG_NLS_V, 0,
        "kinsols line search did not convergence. Try without.\n");
    kinsolData->kinsolStrategy = KIN_NONE;
    kinsolData->retries--;
    return TRUE;
    break;
  /* Maybe happened because of an out-dated factorization, so just retry */
  case KIN_LSOLVE_FAIL:
    warningStreamPrint(OMC_LOG_NLS_V, 0,
                       "KINSOL: Matrix need new factorization. Try again.\n");
    if (kinsolData->linearSolverMethod == NLS_LS_KLU &&
        nlsData->isPatternAvailable) {
      /* Complete symbolic and numeric factorizations */
      flag = SUNLinSol_KLUReInit(kinsolData->linSol, kinsolData->J,
                                 kinsolData->nnz, SUNKLU_REINIT_PARTIAL);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_SUNLS_FLAG, "SUNLinSol_KLUReInit");
      return TRUE;
    }
    break;
  case KIN_MAXITER_REACHED:
  case KIN_REPTD_SYSFUNC_ERR:
    warningStreamPrint(OMC_LOG_NLS_V, 0,
                       "KINSOL: Runs into issues retry with different configuration.\n");
    break;
  case KIN_LINIT_FAIL:
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "KINSOL: The linear solver's initialization function failed.\n");
    return errorCode;
  case KIN_LSETUP_FAIL:
    /* In case something goes wrong with the symbolic jacobian try the numerical */
    warningStreamPrint(OMC_LOG_NLS_V, 0,
                       "KINSOL: The kinls setup routine (lsetup) encountered an error. "
                       "Retry with numerical Jacobian.\n");
    if (kinsolData->linearSolverMethod == NLS_LS_KLU) {
      if (nlsData->isPatternAvailable && nlsData->analyticalJacobianColumn != NULL) {
        flag = KINSetJacFn(kinsolData->kinsolMemory, nlsSparseJac);
        checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
        if (flag < 0) {
          return FALSE;
        }
      } else {
        errorStreamPrint(OMC_LOG_STDOUT, 0, "KINSOL: Trying to switch to numeric Jacobian for sparse solver KLU, but no sparsity pattern is available.");
        return FALSE;
      }
    }
    break;
  case KIN_LINESEARCH_BCFAIL:
    KINGetNumBetaCondFails(kinsolData->kinsolMemory, &outL);
    warningStreamPrint(
        OMC_LOG_NLS_V, 0,
        "kinsols runs into issues with beta-condition fails: %ld\n", outL);
    break;
  default:
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "kinsol has a serious solving issue ERROR %d\n",
                     errorCode);
    return FALSE;
    break;
  }

  /* check if the current solution is sufficient anyway */
  KINGetFuncNorm(kinsolData->kinsolMemory, &fNorm);
  if (fNorm < FTOL_WITH_LESS_ACCURACY) {
    warningStreamPrint(OMC_LOG_NLS_V, 0, "KINSOL: Move forward with a less accurate solution.");
    KINSetFuncNormTol(kinsolData->kinsolMemory, FTOL_WITH_LESS_ACCURACY);
    KINSetScaledStepTol(kinsolData->kinsolMemory, FTOL_WITH_LESS_ACCURACY);
    kinsolData->resetTol = TRUE;
    return TRUE;
  } else {
    warningStreamPrint(OMC_LOG_NLS_V, 0, "KINSOL: Current status of fx = %f", fNorm);
  }

  /* reconfigure kinsol for another try */
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
    /* Too many retries */
    return FALSE;
    break;
  }

  return TRUE;
}

/**
 * @brief Solve non-linear system with KINSol
 *
 * @param data                Runtime data struct.
 * @param threadData          Thread data for error handling.
 * @param nlsData             Pointer to non-linear system data.
 * @return NLS_SOLVER_STATUS  Return NLS_SOLVED on success and NLS_FAILED otherwise.
 */
NLS_SOLVER_STATUS nlsKinsolSolve(DATA* data, threadData_t* threadData, NONLINEAR_SYSTEM_DATA* nlsData) {

  NLS_KINSOL_DATA *kinsolData = (NLS_KINSOL_DATA *)nlsData->solverData;
  int eqSystemNumber = nlsData->equationIndex;
  int indexes[2] = {1, eqSystemNumber};

  int flag;
  long nFEval;
  modelica_boolean success = FALSE;
  modelica_boolean retry = TRUE;
  NLS_SOLVER_STATUS solver_status;
  double *xStart = NV_DATA_S(kinsolData->initialGuess);
  double fNormValue;

  infoStreamPrintWithEquationIndexes(OMC_LOG_NLS_V, omc_dummyFileInfo, 1, indexes,
    "Start solving Non-Linear System %d (size %d) at time %g with Kinsol Solver",
    eqSystemNumber, (int) nlsData->size, data->localData[0]->timeValue);

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

    if (flag < 0 && kinsolData->attemptRetry) {
      warningStreamPrint(OMC_LOG_NLS, 0, "KINSol finished with errorCode %d.", flag);
    } else {
      infoStreamPrint(OMC_LOG_NLS_V, 0, "KINSol finished with errorCode %d.", flag);
    }
    /* Try to handle recoverable errors */
    retry = flag < 0 && kinsolData->attemptRetry && nlsKinsolErrorHandler(flag, data, nlsData, kinsolData);

    /* solution found */
    if ((flag == KIN_SUCCESS) || (flag == KIN_INITIAL_GUESS_OK) ||
        (flag == KIN_STEP_LT_STPTOL)) {
      success = TRUE;
    }
    kinsolData->retries++;

    /* write statistics */
    KINGetNumNonlinSolvIters(kinsolData->kinsolMemory, &nFEval);
    nlsData->numberOfIterations += nFEval;
    nlsData->numberOfFEval = kinsolData->countResCalls;

    infoStreamPrint(OMC_LOG_NLS_V, 0, "Next try? success = %d, retry = %d, retries = %d = %s\n",
                    success, retry, kinsolData->retries,
                    !success && !retry && kinsolData->retries < RETRY_MAX ? "true" : "false");
  } while (!success && retry && kinsolData->retries < RETRY_MAX);

  /* Check solution status */
  if (success && kinsolData->resetTol) {
    kinsolData->solved = NLS_SOLVED_LESS_ACCURACY;
  } else if (success) {
    kinsolData->solved = NLS_SOLVED;
  } else {
    kinsolData->solved = NLS_FAILED;
  }

  /* Reset solver tolerance */
  if (kinsolData->resetTol) {
    KINSetFuncNormTol(kinsolData->kinsolMemory, kinsolData->fnormtol);
    KINSetScaledStepTol(kinsolData->kinsolMemory,  kinsolData->scsteptol);
    kinsolData->resetTol = FALSE;
  }

  if (success) {
    memcpy(nlsData->nlsx, xStart, nlsData->size * (sizeof(double)));
  }

  messageClose(OMC_LOG_NLS_V);

  return kinsolData->solved;
}

#else /* WITH_SUNDIALS */

void* nlsKinsolAllocate(int size, void* userData, int attemptRetry, modelica_boolean isPatternAvailable) {

  throwStreamPrint(NULL, "No sundials/kinsol support activated.");
  return 0;
}

int nlsKinsolFree(void* kinsolData) {

  throwStreamPrint(NULL, "No sundials/kinsol support activated.");
  return 0;
}

int nlsKinsolSolve(void *data, threadData_t *threadData, void* nlsData) {

  throwStreamPrint(threadData, "No sundials/kinsol support activated.");
  return 0;
}

#endif /* WITH_SUNDIALS */
