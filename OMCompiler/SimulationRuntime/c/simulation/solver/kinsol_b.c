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

// this a quick copy / rewrite of the Kinsol NLS interface
// it is only meant for experimental builds in order to test scalings

/*! \file kinsol_B.c
 */


#include "kinsol_b.h"

#include "nonlinearSystem.h"
#include "omc_config.h"
#include "omc_math.h"
#include "../options.h"
#include "../simulation_info_json.h"
#include "../jacobian_util.h"
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
static int B_nlsKinsolResiduals(N_Vector x, N_Vector f, void* userData);
static int B_nlsSparseJac(N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                        void* userData, N_Vector tmp1, N_Vector tmp2);
static int B_nlsSparseSymJac(N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                    void* userData, N_Vector tmp1, N_Vector tmp2);
static int B_nlsDenseJac(long int N, N_Vector vecX, N_Vector vecFX,
                       SUNMatrix Jac, NLS_USERDATA *kinsolUserData,
                       N_Vector tmp1, N_Vector tmp2);
static void B_nlsKinsolJacSumSparse(SUNMatrix A);
static void B_nlsKinsolJacSumDense(SUNMatrix A);

static void B_print_jac(NONLINEAR_SYSTEM_DATA* nlsData, SUNMatrix J, const char* name) {
  int i, j, size, nz, nnz, col, row;

  SPARSE_PATTERN *sp = nlsData->sparsePattern;
  size = nlsData->size;
  if (SUNMatGetID(J) == SUNMATRIX_DENSE) {
    for (col = 0; col < size; col++) {
        for (row = 0; row < size; row++) {
        infoStreamPrint(OMC_LOG_STDOUT, 0, "%s(row = %d, col = %d) = %.3e", name, row, col, SM_ELEMENT_D(J, row, col));
        }
    }
  }
  else if (SUNMatGetID(J) == SUNMATRIX_SPARSE && SM_SPARSETYPE_S(J) == CSC_MAT) {
    for (col = 0; col < size; col++) {
      for (nz = sp->leadindex[col]; nz < sp->leadindex[col + 1]; nz++) {
        row = sp->index[nz];
        infoStreamPrint(OMC_LOG_STDOUT, 0, "%s(row = %d, col = %d) = %.3e", name, row, col, SM_DATA_S(J)[nz]);
      }
    }
  }
}

// debug print
static void B_print_X(B_NLS_KINSOL_DATA* kinsolData, N_Vector x, const char* name) {
  int i, j, size, nz, nnz, col, row;
  realtype *values;

  size = kinsolData->size;
  values = N_VGetArrayPointer(x);
  for (i = 0; i < size; i++) {
      infoStreamPrint(OMC_LOG_STDOUT, 0, "%s(%d) = %.3e", name, i, values[i]);
  }
}

static void nlsKinsolInplaceScaleJac(NONLINEAR_SYSTEM_DATA *nlsData, B_NLS_KINSOL_DATA *kinsolData, SUNMatrix Jac) {
  /* scaling pointers */
  int i, j, size, nz, nnz, col, row;
  SPARSE_PATTERN *sp = nlsData->sparsePattern;

  double *x_scaling = N_VGetArrayPointer(kinsolData->xScale);
  double *f_scaling = N_VGetArrayPointer(kinsolData->fScale);

  size = kinsolData->size;
  nnz = kinsolData->nnz;

  if (SUNMatGetID(Jac) == SUNMATRIX_DENSE) {
    for (col = 0; col < size; col++) {
        for (row = 0; row < size; row++) {
           SM_ELEMENT_D(Jac, row, col) *= f_scaling[row] / x_scaling[col];
        }
    }
  }
  else if (SUNMatGetID(Jac) == SUNMATRIX_SPARSE && SM_SPARSETYPE_S(Jac) == CSC_MAT) {
    for (col = 0; col < size; col++) {
      for (nz = sp->leadindex[col]; nz < sp->leadindex[col + 1]; nz++) {
        row = sp->index[nz];
        SM_DATA_S(Jac)[nz] *= f_scaling[row] / x_scaling[col];
      }
    }
  }
  else {
    errorStreamPrint(OMC_LOG_STDOUT, 0, "kinsol-experimental: Matrix not supported in nlsKinsolInplaceScaleJac.");
  }
}

static void nlsKinsolInplaceUnscaleJac(NONLINEAR_SYSTEM_DATA *nlsData, B_NLS_KINSOL_DATA *kinsolData, SUNMatrix Jac) {
  /* scaling pointers */
  int i, j, size, nz, nnz, col, row;
  SPARSE_PATTERN *sp = nlsData->sparsePattern;

  double *x_scaling = N_VGetArrayPointer(kinsolData->xScale);
  double *f_scaling = N_VGetArrayPointer(kinsolData->fScale);

  size = kinsolData->size;
  nnz = kinsolData->nnz;

  if (SUNMatGetID(Jac) == SUNMATRIX_DENSE) {
    for (col = 0; col < size; col++) {
        for (row = 0; row < size; row++) {
           SM_ELEMENT_D(Jac, row, col) *=  x_scaling[col] / f_scaling[row];
        }
    }
  }
  else if (SUNMatGetID(Jac) == SUNMATRIX_SPARSE && SM_SPARSETYPE_S(Jac) == CSC_MAT) {
    for (col = 0; col < size; col++) {
      for (nz = sp->leadindex[col]; nz < sp->leadindex[col + 1]; nz++) {
        row = sp->index[nz];
        SM_DATA_S(Jac)[nz] *= x_scaling[col] / f_scaling[row];
      }
    }
  }
  else {
    errorStreamPrint(OMC_LOG_STDOUT, 0, "kinsol-experimental: Matrix not supported in nlsKinsolInplaceScaleJac.");
  }
}

static void nlsKinsolInplaceScaleX(B_NLS_KINSOL_DATA *kinsolData, N_Vector x) {
  int i, size = kinsolData->size;
  double *x_data = N_VGetArrayPointer(x);
  double *x_scaling = N_VGetArrayPointer(kinsolData->xScale);

  for (i = 0; i < size; i++) {
    x_data[i] *= x_scaling[i];
  }
}

static void nlsKinsolInplaceScaleF(B_NLS_KINSOL_DATA *kinsolData, N_Vector f) {
  int i, size = kinsolData->size;
  double *f_data = N_VGetArrayPointer(f);
  double *f_scaling = N_VGetArrayPointer(kinsolData->fScale);

  for (i = 0; i < size; i++) {
    f_data[i] *= f_scaling[i];
  }
}

static void nlsKinsolInplaceUnscaleX(B_NLS_KINSOL_DATA *kinsolData, N_Vector x) {
  int i, size = kinsolData->size;
  double *x_data = N_VGetArrayPointer(x);
  double *x_scaling = N_VGetArrayPointer(kinsolData->xScale);

  for (i = 0; i < size; i++) {
    x_data[i] /= x_scaling[i];
  }
}

/**
 * @brief Set KINSOL configuration.
 *
 * @param kinsolData    Kinsol data with configuration settings.
 */
static void B_nlsKinsolConfigSetup(B_NLS_KINSOL_DATA *kinsolData) {
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
 * @brief Error handler function given to KINSOL.
 *
 * @param errorCode   Error code from KINSOL
 * @param module      Name of the KINSOL module reporting the error.
 * @param function    Name of the function in which the error occurred.
 * @param msg         Error Message.
 * @param userData    Pointer to user data given with KINSetUserData.
 */
static void B_kinsolErrorHandlerFunction(int errorCode, const char* module,
                                const char *function, char* msg,
                                void* userData) {
  /* Variables */
  B_NLS_KINSOL_DATA* kinsolData;
  DATA* data;
  NONLINEAR_SYSTEM_DATA* nlsData;
  long eqSystemNumber;

  if (userData != NULL) {
    kinsolData = (B_NLS_KINSOL_DATA *)userData;
    data = kinsolData->userData->data;
    nlsData = kinsolData->userData->nlsData;
    if (nlsData) {
      eqSystemNumber = nlsData->equationIndex;
    } else {
      eqSystemNumber = -1;
    }
  }

  if (OMC_ACTIVE_STREAM(OMC_LOG_NLS)) {
    if (userData != NULL && eqSystemNumber > 0) {
      warningStreamPrint(
          OMC_LOG_NLS, 1, "kinsol failed for system %d",
          modelInfoGetEquation(&data->modelData->modelDataXml, eqSystemNumber).id);
    } else {
      warningStreamPrint(
          OMC_LOG_NLS, 1, "kinsol failed");
    }

    warningStreamPrint(OMC_LOG_NLS, 0,
                       "[module] %s | [function] %s | [error_code] %d", module,
                       function, errorCode);
    if (msg) {
      warningStreamPrint(OMC_LOG_NLS, 0, "%s", msg);
    }

    messageClose(OMC_LOG_NLS);
  }
}

/**
 * @brief Info handler function given to KINSOL.
 *
 * Will only print information when stream OMC_LOG_NLS_V is active.
 *
 * @param module      Name of the KINSOL module reporting the information.
 * @param function    Name of the function reporting the information.
 * @param msg         Message.
 * @param user_data   Pointer to user data given with KINSetInfoHandlerFn.
 */
static void B_kinsolInfoHandlerFunction(const char *module, const char *function,
                               char *msg, void *user_data) {
  (void)(user_data);  /* Disables compiler warning */

  if (OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)) {
    warningStreamPrint(OMC_LOG_NLS_V, 1, "[module] %s | [function] %s:", module, function);
    if (msg) {
      warningStreamPrint(OMC_LOG_NLS_V, 0, "%s", msg);
    }

    messageClose(OMC_LOG_NLS_V);
  }
}

/**
 * @brief Initialize KINSOL data.
 *
 * Allocate memory for KINSOL data and Jacobian.
 *
 * @param kinsolData          KINSOL data.
 */
static void initKinsolMemory(B_NLS_KINSOL_DATA *kinsolData) {
  int flag;
  int printLevel;
  int size = kinsolData->size;
  NONLINEAR_SYSTEM_DATA *nlsData = kinsolData->userData->nlsData;
  SPARSE_PATTERN* sparsePattern = nlsData->sparsePattern;

  /* Free KINSOL memory block */
  if (kinsolData->kinsolMemory != NULL || kinsolData->J != NULL || kinsolData->scaledJ != NULL) {
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "experimental-kinsol: Already allocated kinsol memory. Loosing memory!");
  }

  /* Create KINSOL memory block */
  kinsolData->kinsolMemory = KINCreate();
  if (kinsolData->kinsolMemory == NULL) {
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "experimental-kinsol: In function KINCreate: An error occurred.");
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
  infoStreamPrint(OMC_LOG_NLS, 0, "experimental-kinsol: log level %i", printLevel);
  flag = KINSetPrintLevel(kinsolData->kinsolMemory, printLevel);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetPrintLevel");

  flag = KINSetErrHandlerFn(kinsolData->kinsolMemory, B_kinsolErrorHandlerFunction, kinsolData);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetErrHandlerFn");

  flag = KINSetInfoHandlerFn(kinsolData->kinsolMemory, B_kinsolInfoHandlerFunction, NULL);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetInfoHandlerFn");

  flag = KINSetUserData(kinsolData->kinsolMemory, (void*)kinsolData->userData);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetUserData");

  /* Initialize KINSOL object */
  flag = KINInit(kinsolData->kinsolMemory, B_nlsKinsolResiduals,
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
      throwStreamPrint(NULL, "experimental-kinsol: In function SUNLinSol_Dense: Input incompatible.");
    }
  } else if (kinsolData->linearSolverMethod == NLS_LS_LAPACK) {
    kinsolData->linSol = SUNLinSol_LapackDense(kinsolData->y, kinsolData->J);
    if (kinsolData->linSol == NULL) {
      throwStreamPrint(NULL, "experimental-kinsol: In function SUNLinSol_LapackDense: Input incompatible.");
    }
  } else if (kinsolData->linearSolverMethod == NLS_LS_KLU) {
    kinsolData->linSol = SUNLinSol_KLU(kinsolData->y, kinsolData->J);
    if (kinsolData->linSol == NULL) {
      throwStreamPrint(NULL, "experimental-kinsol: In function SUNLinSol_KLU: Input incompatible.");
    }
  } else {
    throwStreamPrint(NULL, "experimental-kinsol: Unknown linear solver method.");
  }
  /* Log used solver */
  infoStreamPrint(OMC_LOG_NLS, 0, "experimental-kinsol: Using linear solver method %s", NLS_LS_METHOD_NAME[kinsolData->linearSolverMethod]);

  /* Set linear solver */
  flag = KINSetLinearSolver(kinsolData->kinsolMemory, kinsolData->linSol,
                            kinsolData->J);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetLinearSolver");

  /* Set Jacobian for non-linear solver */
  if (kinsolData->linearSolverMethod == NLS_LS_KLU) {
    if (nlsData->analyticalJacobianColumn != NULL && sparsePattern != NULL) {
      flag = KINSetJacFn(kinsolData->kinsolMemory, B_nlsSparseSymJac); /* Use symbolic Jacobian with sparsity pattern*/
    } else if (sparsePattern != NULL) {
      flag = KINSetJacFn(kinsolData->kinsolMemory, B_nlsSparseJac); /* Use numeric Jacobian with sparsity pattern */
    } else {
      throwStreamPrint(NULL, "experimental-kinsol: In function initKinsolMemory: Sparse linear solver KLU needs sparse Jacobian, but no sparsity pattern is available. Use a dense non-linear solver instead of KINSOL.");
    }
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
  }

/* Configuration */
B_nlsKinsolConfigSetup(kinsolData);
}

/**
 * @brief Allocate memory for kinsol solver data and initialize KINSOL solver.
 *
 * @param size                  Size of non-linear problem.
 * @param userData              Pointer to set NLS user data.
 * @param attemptRetry          True if KINSOL should retry with different settings after solution failed.
 * @param isPatternAvailable    True if sparsity pattern of Jacobian is available. Allocate work vectors for KLU in that case.
 * @return B_NLS_KINSOL_DATA*     Pointer to allocated KINSOL data.
 */
B_NLS_KINSOL_DATA* B_nlsKinsolAllocate(int size, NLS_USERDATA* userData, modelica_boolean attemptRetry, modelica_boolean isPatternAvailable) {
  /* Allocate system data */
  B_NLS_KINSOL_DATA *kinsolData = (B_NLS_KINSOL_DATA *)calloc(1, sizeof(B_NLS_KINSOL_DATA));
  int i;
  double *ones_x, *ones_f;

  kinsolData->size = size;
  kinsolData->linearSolverMethod = userData->nlsData->nlsLinearSolver;
  kinsolData->solved = NLS_FAILED;

  kinsolData->fnormtol = newtonFTol;  /* function tolerance */
  kinsolData->scsteptol = newtonXTol; /* step tolerance */

  kinsolData->maxstepfactor = maxStepFactor; /* step tolerance */
  kinsolData->useScaling = FALSE; /* calculate for scaling the scaled matrix */
  kinsolData->attemptRetry = attemptRetry;

  kinsolData->initialGuess = N_VNew_Serial(size);
  kinsolData->xScale = N_VNew_Serial(size);
  kinsolData->fScale = N_VNew_Serial(size);
  kinsolData->ONES_xScale = N_VNew_Serial(size);
  kinsolData->ONES_fScale = N_VNew_Serial(size);
  ones_x = N_VGetArrayPointer(kinsolData->ONES_xScale);
  ones_f = N_VGetArrayPointer(kinsolData->ONES_fScale);

  for (i = 0; i < size; i++) {
    ones_x[i] = 1.0;
    ones_f[i] = 1.0;
  }

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
void B_nlsKinsolFree(B_NLS_KINSOL_DATA* kinsolData) {
  KINFree((void *)&kinsolData->kinsolMemory);

  N_VDestroy_Serial(kinsolData->initialGuess);
  N_VDestroy_Serial(kinsolData->xScale);
  N_VDestroy_Serial(kinsolData->fScale);
  N_VDestroy_Serial(kinsolData->ONES_xScale);
  N_VDestroy_Serial(kinsolData->ONES_fScale);
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
static int B_nlsKinsolResiduals(N_Vector x, N_Vector f, void* userData) {

  double *xdata = NV_DATA_S(x);
  double *fdata = NV_DATA_S(f);

  NLS_USERDATA* kinsolUserData = (NLS_USERDATA*)userData;
  DATA* data = kinsolUserData->data;
  threadData_t* threadData = kinsolUserData->threadData;
  NONLINEAR_SYSTEM_DATA* nlsData = kinsolUserData->nlsData;
  B_NLS_KINSOL_DATA* kinsolData = (B_NLS_KINSOL_DATA*)nlsData->solverData;
  RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=kinsolUserData->solverData};
  int iflag = 1 /* recoverable error */;

  /* Update statistics */
  kinsolData->countResCalls++;

#ifndef OMC_EMCC
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  if (kinsolData->useScaling) {
    nlsKinsolInplaceUnscaleX(kinsolData, x);
  }

  /* call residual function */
  nlsData->residualFunc(&resUserData, xdata, fdata, (const int *)&iflag);

  if (kinsolData->useScaling) {
    nlsKinsolInplaceScaleX(kinsolData, x);
    nlsKinsolInplaceScaleF(kinsolData, f);
  };

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
static int B_nlsDenseJac(long int N,
                       N_Vector vecX,
                       N_Vector vecFX,
                       SUNMatrix Jac,
                       NLS_USERDATA *kinsolUserData,
                       N_Vector tmp1,
                       N_Vector tmp2) {
  DATA *data = kinsolUserData->data;
  threadData_t *threadData = kinsolUserData->threadData;
  NONLINEAR_SYSTEM_DATA *nlsData = kinsolUserData->nlsData;
  B_NLS_KINSOL_DATA *kinsolData = (B_NLS_KINSOL_DATA *)nlsData->solverData;

  if (SUNMatGetID(Jac) != SUNMATRIX_DENSE) {
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "experimental-kinsol: B_nlsDenseJac illegal input Jac. Matrix is not dense!");
    return -1;
  }

  /* prepare variables */
  double *x = N_VGetArrayPointer(vecX);
  double *fx = N_VGetArrayPointer(vecFX);
  double *fRes = NV_DATA_S(kinsolData->fRes);
  double xsave, xscale, sign;
  double delta_hh;
  const double delta_h = sqrt(DBL_EPSILON * 2e1);

  long int col, row;

  modelica_boolean stored_nominal_jac = kinsolData->useScaling;
  if (kinsolData->useScaling) {
    nlsKinsolInplaceUnscaleX(kinsolData, vecX);
    kinsolData->useScaling = FALSE;
  }

  SUNMatZero_Dense(Jac);
  B_nlsKinsolResiduals(vecX, vecFX, kinsolUserData);

  /* performance measurement */
  rt_ext_tp_tick(&nlsData->jacobianTimeClock);

  /* Use forward difference quotient to approximate Jacobian */
  for (col = 0; col < N; col++) {
    xsave = x[col];
    delta_hh = delta_h * (fabs(xsave) + 1.0);
    if ((xsave + delta_hh >= nlsData->max[col])) {
      delta_hh *= -1.0;
    }
    x[col] += delta_hh;

    /* Evaluate Jacobian function */
    B_nlsKinsolResiduals(vecX, kinsolData->fRes, kinsolUserData);

    /* Calculate scaled difference quotient */
    delta_hh = 1.0 / delta_hh;

    for (row = 0; row < N; row++) {
      SM_ELEMENT_D(Jac, row, col) = (fRes[row] - fx[row]) * delta_hh;
    }
    x[col] = xsave;
  }

  kinsolData->useScaling = stored_nominal_jac;
  if (kinsolData->useScaling) {
    nlsKinsolInplaceScaleX(kinsolData, vecX);
    nlsKinsolInplaceScaleJac(nlsData, kinsolData, Jac);
  };

  /* debug */
  if (OMC_ACTIVE_STREAM(OMC_LOG_NLS_JAC)) {
    infoStreamPrint(OMC_LOG_NLS_JAC, 1, "experimental-kinsol: Dense matrix (scaled = %s).", kinsolData->useScaling ? "true" : "false");
    SUNDenseMatrix_Print(Jac, stdout); /* TODO: Print in OMC_LOG_NLS_JAC */
    B_nlsKinsolJacSumDense(Jac);
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
                     "experimental-kinsol: In function finishSparseColPtr: Wrong sparse format of SUNMatrix A.");
  }

  /* Set last value of indexptrs to nnz */
  SM_INDEXPTRS_S(A)[SM_COLUMNS_S(A)] = nnz;

  /* Check for empty rows */
  for (i = 1; i < SM_COLUMNS_S(A) + 1; ++i) {
    if (SM_INDEXPTRS_S(A)[i] == SM_INDEXPTRS_S(A)[i - 1]) {
      warningStreamPrint(OMC_LOG_STDOUT, 0,
                         "experimental-kinsol: Jacobian row %d singular. See OMC_LOG_NLS for "
                         "more information.",
                         i);
      SM_INDEXPTRS_S(A)[i] = SM_INDEXPTRS_S(A)[i - 1];
    }
  }
}

/**
 * @brief Perform derivative test comparing symbolic and numerical Jacobians for KINSOL
 *
 * Compares the symbolic Jacobian (sparse CSC format) with a numerically approximated
 * dense Jacobian, checking for numerical and structural anomalies. The numerical
 * Jacobian is computed using finite differences via B_nlsDenseJac.
 *
 * @param data              Runtime data structure
 * @param nlsData           Nonlinear system data
 * @param kinsolData        KINSOL solver data structure
 * @param Jsym              Symbolic Jacobian in sparse CSC format
 * @param tol               Tolerance, all relative errors above tol are considered anomalies
 * @param newJac            TRUE if called from jacobian evaluation, FALSE if called from solver entry point
 *
 * @return int              1 derivative test failed and no error
 *                          0 derivative test successful and no error
 *                         -1 internal error
 */
static int nlsKinsolDenseDerivativeTest(DATA *data, NONLINEAR_SYSTEM_DATA *nlsData, B_NLS_KINSOL_DATA *kinsolData,
                                        SUNMatrix Jsym, SolverCaller caller)
{
  int row, col, nz, errorCount, numericalErrorCount, structuralErrorCount;
  const int size = nlsData->size;
  int ret = 0;

  modelica_real symValue, numValue, absError, relError;
  modelica_real maxError = 0.0;

  modelica_boolean errorFound;

  sunindextype nnz = SUNSparseMatrix_NNZ(Jsym);
  sunindextype columns = SUNSparseMatrix_Columns(Jsym);
  sunindextype rows = SUNSparseMatrix_Rows(Jsym);

  sunindextype *colPointers = SM_INDEXPTRS_S(Jsym);
  sunindextype *rowIndices = SM_INDEXVALS_S(Jsym);
  realtype *symValues = SM_DATA_S(Jsym);

  // allocate temporary memory for dense finite-diff matrix
  N_Vector vecX = N_VNew_Serial(size);
  N_Vector vecFX = N_VNew_Serial(size);
  N_Vector tmp1 = N_VNew_Serial(size);
  N_Vector tmp2 = N_VNew_Serial(size);
  SUNMatrix Jnum = SUNDenseMatrix(size, size);

  // set tolerances
  modelica_real Atol = omc_flag[FLAG_NLS_JAC_TEST_ATOL] ? atof(omc_flagValue[FLAG_NLS_JAC_TEST_ATOL]) : 100 * DBL_EPSILON;
  modelica_real Rtol = omc_flag[FLAG_NLS_JAC_TEST_RTOL] ? atof(omc_flagValue[FLAG_NLS_JAC_TEST_RTOL]) : 1e-4;

  if (kinsolData->useScaling) {
    errorFound = FALSE;
  }

  // copy current x into new vector, compute f(x) and corresponding dense finite-diff Jacobian
  SUNMatZero(Jnum);
  N_VScale(1.0, kinsolData->initialGuess, vecX);
  B_nlsKinsolResiduals(vecX, vecFX, kinsolData->userData);
  if (B_nlsDenseJac(size, vecX, vecFX, Jnum, kinsolData->userData, tmp1, tmp2) != 0)
  {
    errorStreamPrint(OMC_LOG_STDOUT, 0, "Numerical Jacobian computation failed in nlsKinsolDenseDerivativeTest");
    ret = -1;
    SUNMatDestroy(Jnum);
    N_VDestroy_Serial(vecX);
    N_VDestroy_Serial(vecFX);
    N_VDestroy_Serial(tmp1);
    N_VDestroy_Serial(tmp2);
    return ret;
  }

  infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 1, "%s: Derivative test (atol=%.5e, rtol=%.5e, scaled = %s, Caller: %s):",
                  SolverCaller_callerString(caller), Atol, Rtol, kinsolData->useScaling ? "true" : "false", SolverCaller_toString(caller));
  infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 1, "Matrix Info");
  infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 0, "NLS index = %ld", nlsData->equationIndex);
  infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 0, "Columns   = %li", columns);
  infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 0, "Rows      = %li", rows);
  infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 0, "NNZ       = %li", nnz);
  infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 0, "Curr Time = %-11.5e", data->localData[0]->timeValue);

  messageClose(OMC_LOG_NLS_DERIVATIVE_TEST);

  infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 1, "Anomalies");

  nz = 0;
  errorCount = 0;
  numericalErrorCount = 0;
  structuralErrorCount = 0;

  for (col = 0; col < size; col++)
  {
    errorFound = FALSE;

    for (row = 0; row < size; row++)
    {
      numValue = SM_ELEMENT_D(Jnum, row, col);

      if (colPointers[col] <= nz && nz < colPointers[col+1] && rowIndices[nz] == row)
      {
        // structural non-zero -> compare values
        symValue = symValues[nz++];
        absError = fabs(symValue - numValue);
        relError = (absError < Atol) ? 0.0 : absError / fmax(fabs(numValue), fabs(symValue));

        if (relError > maxError)
        {
            maxError = relError;
        }

        if (relError > Rtol)
        {
          // tolerance exceeded -> numerical error
          if (!errorFound)
          {
            infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 1, "Column / Variable: %i, Name: %s",
            col + 1, modelInfoGetEquation(&data->modelData->modelDataXml, nlsData->equationIndex).vars[col]);
            infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 0, "%-12s %-6s %-6s %-15s  %-15s  %-8s",
                            "Type", "Col", "Row", "Symbolic", "Numerical", "RelError");
            errorFound = TRUE;
          }
          infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 0, "%-12s %-6d %-6d %+15.8e  %+15.8e  %+13.8e",
                          "Numerical", col + 1, row + 1, symValue, numValue, relError);
          numericalErrorCount++;
        }
      }
      else if (fabs(numValue) > Atol)
      {
        // structural error with tolerance exceeded -> non-zero in numerical Jacobian but zero in symbolic
        if (!errorFound)
        {
          infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 1, "Column / Variable: %i, Name: %s",
                          col + 1, modelInfoGetEquation(&data->modelData->modelDataXml, nlsData->equationIndex).vars[col]);
          infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 0, "%-12s %-6s %-6s %-15s  %-15s  %-8s",
                          "Type", "Col", "Row", "Symbolic", "Numerical", "RelError");
          errorFound = TRUE;
        }
        infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 0, "%-12s %-6d %-6d %+15.8e  %+15.8e  %+13.8e",
                        "Structural", col + 1, row + 1, 0.0, numValue, 1.0);
        structuralErrorCount++;
      }
    }

    if (errorFound)
    {
      messageClose(OMC_LOG_NLS_DERIVATIVE_TEST);
    }
  }
  messageClose(OMC_LOG_NLS_DERIVATIVE_TEST);

  infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 1, "Summary");
  infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 0, "Numerical errors:  %d (value mismatch w.r.t. reference)", numericalErrorCount);
  infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 0, "Structural errors: %d (non-zero not in sparsity pattern)", structuralErrorCount);
  infoStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 0, "Max relative error: %.3e", maxError);

  if (numericalErrorCount + structuralErrorCount > 0)
  {
    warningStreamPrint(OMC_LOG_NLS_DERIVATIVE_TEST, 0, "Derivative test failed (%d numerical, %d structural errors)",
                       numericalErrorCount, structuralErrorCount);
    ret = 1;
  }
  messageClose(OMC_LOG_NLS_DERIVATIVE_TEST);

  SUNMatDestroy(Jnum);
  N_VDestroy_Serial(vecX);
  N_VDestroy_Serial(vecFX);
  N_VDestroy_Serial(tmp1);
  N_VDestroy_Serial(tmp2);

  messageClose(OMC_LOG_NLS_DERIVATIVE_TEST);

  return ret;
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
static int B_nlsSparseSymJac(N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                    void *userData, N_Vector tmp1, N_Vector tmp2) {
  /* Variables */
  NLS_USERDATA* kinsolUserData = (NLS_USERDATA *)userData;;
  DATA* data = kinsolUserData->data;
  threadData_t* threadData = kinsolUserData->threadData;
  NONLINEAR_SYSTEM_DATA* nlsData = kinsolUserData->nlsData;
  B_NLS_KINSOL_DATA* kinsolData = (B_NLS_KINSOL_DATA *)nlsData->solverData;
  JACOBIAN* jacobian = kinsolUserData->analyticJacobian;
  assertStreamPrint(threadData, NULL != jacobian, "jacobian is NULL");
  const SPARSE_PATTERN* sp = jacobian->sparsePattern;
  assertStreamPrint(threadData, NULL != sp, "sp is NULL");
  long int column, nz;

  if (SUNMatGetID(Jac) != SUNMATRIX_SPARSE || SM_SPARSETYPE_S(Jac) == CSR_MAT) {
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "experimental-kinsol: B_nlsSparseSymJac illegal input Jac. Matrix is not sparse!");
    return -1;
  }

  /* performance measurement */
  rt_ext_tp_tick(&nlsData->jacobianTimeClock);

  if (kinsolData->useScaling) {
    nlsKinsolInplaceUnscaleX(kinsolData, vecX);
  }

  /* call generic sparse Jacobian with CSC buffer "SM_DATA_S(Jac)" */
  evalJacobian(data, threadData, jacobian, NULL, SM_DATA_S(Jac), FALSE);
  setSundialsSparsePattern(jacobian, Jac);

  /* Finish sparse matrix and do a cheap check for singularity */
  finishSparseColPtr(Jac, sp->numberOfNonZeros);

  if (kinsolData->useScaling) {
    nlsKinsolInplaceScaleX(kinsolData, vecX);
    nlsKinsolInplaceScaleJac(nlsData, kinsolData, Jac);
  };

  /* Debug print */
  if (OMC_ACTIVE_STREAM(OMC_LOG_NLS_JAC)) {
    infoStreamPrint(OMC_LOG_NLS_JAC, 1, "experimental-kinsol: Sparse Matrix.");
    SUNSparseMatrix_Print(Jac, stdout); /* TODO: Print in OMC_LOG_NLS_JAC */
    B_nlsKinsolJacSumSparse(Jac);
    messageClose(OMC_LOG_NLS_JAC);
  }

  if (omc_useStream[OMC_LOG_NLS_DERIVATIVE_TEST])
  {
    nlsKinsolDenseDerivativeTest(data, nlsData, kinsolData, Jac, KINSOL_B_JAC_EVAL);
  }

  if (omc_useStream[OMC_LOG_NLS_JAC_SUMS])
  {
    nlsJacobianRowColSums(data, nlsData, Jac, KINSOL_B_JAC_EVAL /* called at evaluation */, kinsolData->useScaling /* scaled */);
  }

  /* performance measurement and statistics */
  nlsData->jacobianTime += rt_ext_tp_tock(&(nlsData->jacobianTimeClock));
  nlsData->numberOfJEval++;

  return 0;
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
static int B_nlsSparseJac(N_Vector vecX, N_Vector vecFX, SUNMatrix Jac,
                        void *userData, N_Vector tmp1, N_Vector tmp2) {
  /* Variables */
  NLS_USERDATA *kinsolUserData;
  DATA *data;
  threadData_t *threadData;
  NONLINEAR_SYSTEM_DATA *nlsData;
  B_NLS_KINSOL_DATA *kinsolData;
  SPARSE_PATTERN *sparsePattern;

  if (SUNMatGetID(Jac) != SUNMATRIX_SPARSE || SM_SPARSETYPE_S(Jac) == CSR_MAT) {
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "experimental-kinsol: B_nlsSparseJac illegal input Jac. Matrix is not sparse!");
    return -1;
  }

  double *x;
  double *fx;
  double *xsave;
  double *delta_hh;
  double *xScaling;
  double *fRes;

  const double delta_h = sqrt(DBL_EPSILON * 2e1);

  modelica_real result;
  long int i, j, ii;
  int nth;

  modelica_boolean stored_nominal_jac;

  /* Access userData and nonlinear system data */
  kinsolUserData = (NLS_USERDATA *)userData;
  data = kinsolUserData->data;
  threadData = kinsolUserData->threadData;
  nlsData = kinsolUserData->nlsData;
  kinsolData = (B_NLS_KINSOL_DATA *)nlsData->solverData;
  sparsePattern = nlsData->sparsePattern;

  /* Access N_Vector variables */
  x = N_VGetArrayPointer(vecX);
  fx = N_VGetArrayPointer(vecFX);
  xsave = N_VGetArrayPointer(tmp1);
  delta_hh = N_VGetArrayPointer(tmp2);
  fRes = N_VGetArrayPointer(kinsolData->fRes);

  nth = 0;

  /* performance measurement */
  rt_ext_tp_tick(&nlsData->jacobianTimeClock);

  /* reset matrix */
  SUNMatZero(Jac);

  stored_nominal_jac = kinsolData->useScaling;
  if (kinsolData->useScaling) {
    nlsKinsolInplaceUnscaleX(kinsolData, vecX);
    kinsolData->useScaling = FALSE;
  }

  B_nlsKinsolResiduals(vecX, vecFX, userData);

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
    B_nlsKinsolResiduals(vecX, kinsolData->fRes, userData);

    /* Save column in Jac and unset seed variables */
    for (ii = 0; ii < kinsolData->size; ii++) {
      if (sparsePattern->colorCols[ii] - 1 == i) {
        nth = sparsePattern->leadindex[ii];
        while (nth < sparsePattern->leadindex[ii + 1]) {
          j = sparsePattern->index[nth];

          // TODO: investigate NaN values stemming from residual functions
          // Hypothesis: lambda = 0 system forces variables to be 0, while for lambda = eps, we divide by them?!
          result = (fRes[j] - fx[j]) * delta_hh[ii];

          // (IN)SANITY CHECK
          if (isnan(result) || isinf(result)) {
            warningStreamPrint(OMC_LOG_STDOUT, 0,
                "WARNING: NaN (%d) or Inf (%d) detected at col %ld row %ld: fRes=%g, fx=%g, delta_hh=%g, x=%g, xsave=%g\n"
                "ACTION: setting Jacobian entry := 0.0 and trying to recover...",
                isnan(result), isinf(result), ii, j, fRes[j], fx[j], delta_hh[ii], x[ii], xsave[ii]);
            result = 0.0;
          }
          setJacElementSundialsSparse(j, ii, nth, result, Jac, SM_CONTENT_S(Jac)->M);
          nth++;
        }
        x[ii] = xsave[ii];
      }
    }
  }
  /* Finish sparse matrix */
  finishSparseColPtr(Jac, sparsePattern->numberOfNonZeros);

  kinsolData->useScaling = stored_nominal_jac;
  if (kinsolData->useScaling) {
    nlsKinsolInplaceScaleX(kinsolData, vecX);
    nlsKinsolInplaceScaleF(kinsolData, vecFX);
    nlsKinsolInplaceScaleJac(nlsData, kinsolData, Jac);
  };

  /* Debug print */
  if (OMC_ACTIVE_STREAM(OMC_LOG_NLS_JAC)) {
    infoStreamPrint(OMC_LOG_NLS_JAC, 1, "experimental-kinsol: Sparse Matrix.");
    SUNSparseMatrix_Print(Jac, stdout);
    B_nlsKinsolJacSumSparse(Jac);
    messageClose(OMC_LOG_NLS_JAC);
  }

  if (OMC_ACTIVE_STREAM(OMC_LOG_DEBUG)) {
    sundialsPrintSparseMatrix(Jac, "A", OMC_LOG_JAC);
  }

  if (omc_useStream[OMC_LOG_NLS_DERIVATIVE_TEST])
  {
    nlsKinsolDenseDerivativeTest(data, nlsData, kinsolData, Jac, KINSOL_B_JAC_EVAL);
  }

  if (omc_useStream[OMC_LOG_NLS_JAC_SUMS])
  {
    nlsJacobianRowColSums(data, nlsData, Jac, KINSOL_B_JAC_EVAL /* called at evaluation */, kinsolData->useScaling /* scaled */);
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
static void B_nlsKinsolJacSumDense(SUNMatrix A) {
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
                         "experimental-kinsol: Column %d of Jacobian is zero. Jacobian is singular.",
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
static void B_nlsKinsolJacSumSparse(SUNMatrix A) {
  /* Variables */
  int i, j;
  double sum;

  /* Check format of A */
  if (SM_SPARSETYPE_S(A) != CSC_MAT) {
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "experimental-kinsol: In function B_nlsKinsolJacSumSparse: Wrong sparse format "
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
                         "experimental-kinsol: Column %d of Jacobian is zero. Jacobian is singular.",
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
static void B_nlsKinsolSetMaxNewtonStep(B_NLS_KINSOL_DATA *kinsolData,
                                      double maxstepfactor) {
  /* Variables */
  int flag;

  N_VConst(maxstepfactor, kinsolData->fTmp);
  kinsolData->mxnstepin = N_VWL2Norm(kinsolData->xScale, kinsolData->fTmp); // TODO: ?

  /* Set maximum step size */
  flag = KINSetMaxNewtonStep(kinsolData->kinsolMemory, kinsolData->mxnstepin);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetMaxNewtonStep");
}

/**
 * @brief Set initial guess for KINSOL and unscale previous Jacobian
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
static void B_nlsKinsolResetInitialUnscaled(DATA *data, B_NLS_KINSOL_DATA *kinsolData,
                                  NONLINEAR_SYSTEM_DATA *nlsData,
                                  B_initialMode mode) {
  double *xStart = NV_DATA_S(kinsolData->initialGuess);

  /* Set x vector */
  switch (mode) {
  case B_INITIAL_EXTRAPOLATION:
    if (data->simulationInfo->discreteCall) {
      memcpy(xStart, nlsData->nlsx, nlsData->size * (sizeof(double)));
    } else {
      memcpy(xStart, nlsData->nlsxExtrapolation,
             nlsData->size * (sizeof(double)));
    }
    break;
  case B_INITIAL_OLDVALUES:
    memcpy(xStart, nlsData->nlsxOld, nlsData->size * (sizeof(double)));
    break;
  default:
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "experimental-kinsol: Function B_nlsKinsolResetInitialUnscaled: Unknown mode %d.",
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
static void B_nlsKinsolXScaling(DATA *data, B_NLS_KINSOL_DATA *kinsolData,
                              NONLINEAR_SYSTEM_DATA *nlsData,
                              B_scalingMode mode) {
  double *xStart = NV_DATA_S(kinsolData->initialGuess);
  double *xScaling = NV_DATA_S(kinsolData->xScale);
  int i;

  /* if noScaling flag is used overwrite mode */
  if (omc_flag[FLAG_NO_SCALING]) {
    mode = B_SCALING_ONES;
  }

  /* Use nominal value or the actual working point for scaling */
  switch (mode) {
  case B_SCALING_NOMINALSTART:
    for (i = 0; i < nlsData->size; i++) {
      xScaling[i] = 1.0 / fmax(nlsData->nominal[i], fabs(xStart[i]));
    }
    break;
  case B_SCALING_ONES:
    for (i = 0; i < nlsData->size; i++) {
      xScaling[i] = 1.0;
    }
    break;
  case B_SCALING_JACOBIAN:
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "experimental-kinsol: Function B_nlsKinsolXScaling: Invalid mode SCALING_JACOBIAN.");
  default:
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "experimental-kinsol: Function B_nlsKinsolXScaling: Unknown mode %d.", (int)mode);
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
static void B_nlsKinsolFScaling(DATA *data, B_NLS_KINSOL_DATA *kinsolData,
                              NONLINEAR_SYSTEM_DATA *nlsData,
                              B_scalingMode mode) {
  double *fScaling = NV_DATA_S(kinsolData->fScale);
  N_Vector x = kinsolData->initialGuess;

  int i, j;
  int ret;

  /* If noScaling flag is used overwrite mode */
  if (omc_flag[FLAG_NO_SCALING]) {
    mode = B_SCALING_ONES;
  }

  /* Disable scaled jacobian evaluation */
  kinsolData->useScaling = FALSE;

  /* Use nominal value or the actual working point for scaling */
  switch (mode) {
  case B_SCALING_JACOBIAN:

    /* Calculate the scaled Jacobian */
    if (nlsData->isPatternAvailable && kinsolData->linearSolverMethod == NLS_LS_KLU) {
      if (kinsolData->solved != NLS_SOLVED) {
        if (nlsData->analyticalJacobianColumn != NULL) {
          /* Calculate the sparse Jacobian symbolically  */
          B_nlsSparseSymJac(x, kinsolData->fTmp, kinsolData->J, kinsolData->userData, NULL, NULL);
        } else {
          /* Update f(x) for the numerical jacobian matrix */
          B_nlsKinsolResiduals(x, kinsolData->fTmp, kinsolData->userData);
          B_nlsSparseJac(x, kinsolData->fTmp, kinsolData->J, kinsolData->userData, kinsolData->tmp1, kinsolData->tmp2);
        }
      }
      /* Scale the current Jacobian */
      SUNMatCopy_Sparse(kinsolData->J, kinsolData->scaledJ);  /* Copy J into scaledJ */
      ret = _omc_SUNSparseMatrixVecScaling(kinsolData->scaledJ, kinsolData->xScale);
      if (ret != 0) {
        errorStreamPrint(OMC_LOG_STDOUT, 0, "experimental-kinsol: _omc_SUNSparseMatrixVecScaling failed.");
      }
    } else {
      /* Update f(x) for the numerical jacobian matrix */
      B_nlsKinsolResiduals(x, kinsolData->fTmp, kinsolData->userData);
      B_nlsDenseJac(nlsData->size, x, kinsolData->fTmp, kinsolData->J,
                  kinsolData->userData, NULL, NULL);
    }

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
                       "KINSOL: Function B_nlsKinsolFScaling: Unknown matrix type.");
    }

    /* inverse fScale */
    N_VInv(kinsolData->fScale, kinsolData->fScale);

    break;
  case B_SCALING_ONES:
    for (i = 0; i < nlsData->size; i++) {
      fScaling[i] = 1.0;
    }
    break;
  case B_SCALING_NOMINALSTART:
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "experimental-kinsol: Function B_nlsKinsolFScaling: Invalid mode SCALING_NOMINALSTART.");
  default:
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "experimental-kinsol: Function B_nlsKinsolFScaling: Unknown mode %d.", (int)mode);
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
static void B_nlsKinsolConfigPrint(B_NLS_KINSOL_DATA *kinsolData,
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

  if (eqSystemNumber>0) {
    _omc_printVectorWithEquationInfo(
      &vecStart, "Initial guess values", OMC_LOG_NLS_V,
      modelInfoGetEquation(&data->modelData->modelDataXml, eqSystemNumber));

    _omc_printVectorWithEquationInfo(
      &vecXScaling, "xScaling", OMC_LOG_NLS_V,
      modelInfoGetEquation(&data->modelData->modelDataXml, eqSystemNumber));
  }

  _omc_printVector(&vecFScaling, "fScaling", OMC_LOG_NLS_V);

  infoStreamPrint(OMC_LOG_NLS_V, 0, "experimental-kinsol F tolerance: %g", kinsolData->fnormtol);
  infoStreamPrint(OMC_LOG_NLS_V, 0, "experimental-kinsol minimal step size %g",
                  kinsolData->scsteptol);
  infoStreamPrint(OMC_LOG_NLS_V, 0, "experimental-kinsol max iterations %d",
                  20 * kinsolData->size);
  infoStreamPrint(OMC_LOG_NLS_V, 0, "experimental-kinsol strategy %d",
                  kinsolData->kinsolStrategy);
  infoStreamPrint(OMC_LOG_NLS_V, 0, "experimental-kinsol current retry %d", kinsolData->retries);
  infoStreamPrint(OMC_LOG_NLS_V, 0, "experimental-kinsol max step %g", kinsolData->mxnstepin);
  infoStreamPrint(OMC_LOG_NLS_V, 0, "experimental-kinsol linear solver %d",
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
                                              B_NLS_KINSOL_DATA *kinsolData) {
  int flag;
  double fNorm;
  double *xStart = NV_DATA_S(kinsolData->initialGuess);
  long outL;

  flag = KINSetNoInitSetup(kinsolData->kinsolMemory, SUNFALSE);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetNoInitSetup");

  switch (errorCode) {
  case KIN_MEM_NULL:
    throwStreamPrint(NULL, "experimental-kinsol: Memory NULL ERROR %d\n", errorCode);
    return FALSE;
    break;
  case KIN_ILL_INPUT:
    throwStreamPrint(NULL, "experimental-kinsol: Ill input ERROR %d\n", errorCode);
    return FALSE;
    break;
  case KIN_NO_MALLOC:
    throwStreamPrint(NULL, "experimental-kinsol: Memory issue ERROR %d\n", errorCode);
    return FALSE;
    break;
  /* Just retry with new initial guess */
  case KIN_MXNEWT_5X_EXCEEDED:
    warningStreamPrint(
        OMC_LOG_NLS_V, 0,
        "Newton step exceed the maximum step size several times. Try again "
        "after increasing maximum step size.\n");
    kinsolData->maxstepfactor *= 1e5;
    B_nlsKinsolSetMaxNewtonStep(kinsolData, kinsolData->maxstepfactor);
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
                       "experimental-kinsol: Matrix need new factorization. Try again.\n");
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
                       "experimental-kinsol: Runs into issues retry with different configuration.\n");
    break;
  case KIN_LINIT_FAIL:
    errorStreamPrint(OMC_LOG_STDOUT, 0,
                     "experimental-kinsol: The linear solver's initialization function failed.\n");
    return errorCode;
  case KIN_LSETUP_FAIL:
    /* In case something goes wrong with the symbolic jacobian try the numerical */
    warningStreamPrint(OMC_LOG_NLS_V, 0,
                       "experimental-kinsol: The kinls setup routine (lsetup) encountered an error. "
                       "Retry with numerical Jacobian.\n");
    if (kinsolData->linearSolverMethod == NLS_LS_KLU) {
      if (nlsData->isPatternAvailable && nlsData->analyticalJacobianColumn != NULL) {
        flag = KINSetJacFn(kinsolData->kinsolMemory, B_nlsSparseJac);
        checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
        if (flag < 0) {
          return FALSE;
        }
      } else {
        errorStreamPrint(OMC_LOG_STDOUT, 0, "experimental-kinsol: Trying to switch to numeric Jacobian for sparse solver KLU, but no sparsity pattern is available.");
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

  // TODO: configure the retry strategies properly!!
  // currently this is does not make sense with the new scaling

  /* check if the current solution is sufficient anyway */
  KINGetFuncNorm(kinsolData->kinsolMemory, &fNorm);
  if (fNorm < B_FTOL_WITH_LESS_ACCURACY) {
    warningStreamPrint(OMC_LOG_NLS_V, 0, "experimental-kinsol: Move forward with a less accurate solution.");
    KINSetFuncNormTol(kinsolData->kinsolMemory, B_FTOL_WITH_LESS_ACCURACY);
    KINSetScaledStepTol(kinsolData->kinsolMemory, B_FTOL_WITH_LESS_ACCURACY);
    kinsolData->resetTol = TRUE;
    return TRUE;
  } else {
    warningStreamPrint(OMC_LOG_NLS_V, 0, "experimental-kinsol: Current status of fx = %f", fNorm);
  }

  /* reconfigure kinsol for another try */
  switch (kinsolData->retries) {
  case 0:
    /* try without scaling  */
    B_nlsKinsolXScaling(data, kinsolData, nlsData, B_SCALING_ONES);
    B_nlsKinsolFScaling(data, kinsolData, nlsData, B_SCALING_ONES);
    break;
  case 1:
    /* try without line-search and oldValues */
    B_nlsKinsolResetInitialUnscaled(data, kinsolData, nlsData, B_INITIAL_OLDVALUES);
    kinsolData->kinsolStrategy = KIN_LINESEARCH;
    break;
  case 2:
    /* try without line-search and oldValues */
    B_nlsKinsolResetInitialUnscaled(data, kinsolData, nlsData, B_INITIAL_EXTRAPOLATION);
    kinsolData->kinsolStrategy = KIN_NONE;
    break;
  case 3:
    /* try with exact newton  */
    B_nlsKinsolXScaling(data, kinsolData, nlsData, B_SCALING_NOMINALSTART);
    B_nlsKinsolFScaling(data, kinsolData, nlsData, B_SCALING_JACOBIAN);
    B_nlsKinsolResetInitialUnscaled(data, kinsolData, nlsData, B_INITIAL_EXTRAPOLATION);
    KINSetMaxSetupCalls(kinsolData->kinsolMemory, 1);
    kinsolData->kinsolStrategy = KIN_LINESEARCH;
    break;
  case 4:
    /* try with exact newton to with out x scaling values */
    B_nlsKinsolXScaling(data, kinsolData, nlsData, B_SCALING_ONES);
    B_nlsKinsolFScaling(data, kinsolData, nlsData, B_SCALING_ONES);
    B_nlsKinsolResetInitialUnscaled(data, kinsolData, nlsData, B_INITIAL_OLDVALUES);
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
NLS_SOLVER_STATUS B_nlsKinsolSolve(DATA* data, threadData_t* threadData, NONLINEAR_SYSTEM_DATA* nlsData) {

  B_NLS_KINSOL_DATA *kinsolData = (B_NLS_KINSOL_DATA *)nlsData->solverData;
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
    // FIXME: This entire interface needs a complete redesign from the ground up.
    // With the new scaling logic, everything becomes tangled and the control flow increasingly unclear.

    kinsolData->useScaling = FALSE;

    // set x := unscaled x (solution of prev / initial guess)
    B_nlsKinsolResetInitialUnscaled(data, kinsolData, nlsData, B_INITIAL_EXTRAPOLATION);

    // create new x scaling based on x and x_nominal
    B_nlsKinsolXScaling(data, kinsolData, nlsData, B_SCALING_NOMINALSTART);

    // create new f scaling based on Jacobian in memory (from prev solve) or if none compute new scaling
    B_nlsKinsolFScaling(data, kinsolData, nlsData, B_SCALING_JACOBIAN);

    /* Set maximum step size */
    B_nlsKinsolSetMaxNewtonStep(kinsolData, kinsolData->maxstepfactor);

    /* Dump configuration */
    B_nlsKinsolConfigPrint(kinsolData, nlsData);

    kinsolData->useScaling = TRUE;
    nlsKinsolInplaceScaleX(kinsolData, kinsolData->initialGuess);
    nlsKinsolInplaceScaleJac(nlsData, kinsolData, kinsolData->J);

    /* TODO: This should be another flag, e.g. LOG_NLS_JAC_UPDATE and not OMC_LOG_NLS_DERIVATIVE_TEST
          only in some cases this derivative test makes sense, since the scaled Jacobian is outdated frequently!
          in many cases, we use an outdated jacobian here, such that errors explode and it detects wrong Jacobian mismatches
          that are due to the dense Jacobian evaluated at the new point x_new.

    if (omc_useStream[OMC_LOG_NLS_DERIVATIVE_TEST])
    {
      nlsKinsolDenseDerivativeTest(data, nlsData, kinsolData, kinsolData->J, KINSOL_B_ENTRY_POINT);
    }
    */

    if (omc_useStream[OMC_LOG_NLS_JAC_SUMS])
    {
      nlsJacobianRowColSums(data, nlsData, kinsolData->J, KINSOL_B_ENTRY_POINT /* called at entry point */, kinsolData->useScaling /* scaled */);
    }

    if (omc_useStream[OMC_LOG_NLS_SVD])
    {
      svd_compute(data, nlsData, SM_DATA_S(kinsolData->J), kinsolData->useScaling, KINSOL_B_ENTRY_POINT /* called at entry point */);
    }

    flag = KINSol(
        kinsolData->kinsolMemory,   /* KINSol memory block */
        kinsolData->initialGuess,   /* initial guess on input; solution vector */
        kinsolData->kinsolStrategy, /* global strategy choice */
        kinsolData->ONES_xScale,    /* (1, ..., 1)^T */
        kinsolData->ONES_fScale);   /* (1, ..., 1)^T */

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
                    !success && !retry && kinsolData->retries < B_RETRY_MAX ? "true" : "false");
  } while (!success && retry && kinsolData->retries < B_RETRY_MAX);

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
    if (kinsolData->useScaling) {
      nlsKinsolInplaceUnscaleX(kinsolData, kinsolData->initialGuess);

      /* repeated solve; we must unscale the previous Jacobian, since we will compute the new fScalings
         in the next step from the Jacobian that is already in memory */
      nlsKinsolInplaceUnscaleJac(nlsData, kinsolData, kinsolData->J);
      kinsolData->useScaling = FALSE;
    }
    memcpy(nlsData->nlsx, xStart, nlsData->size * (sizeof(double)));
  }

  messageClose(OMC_LOG_NLS_V);

  return kinsolData->solved;
}

#else /* WITH_SUNDIALS */

void* B_nlsKinsolAllocate(int size, void* userData, int attemptRetry, modelica_boolean isPatternAvailable) {

  throwStreamPrint(NULL, "No sundials/kinsol support activated.");
  return 0;
}

int B_nlsKinsolFree(void* kinsolData) {

  throwStreamPrint(NULL, "No sundials/kinsol support activated.");
  return 0;
}

int B_nlsKinsolSolve(void *data, threadData_t *threadData, void* nlsData) {

  throwStreamPrint(threadData, "No sundials/kinsol support activated.");
  return 0;
}

#endif /* WITH_SUNDIALS */
