/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2019, Open Source Modelica Consortium (OSMC),
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

/*! File jac_util.c
 */

#include "jacobian_util.h"
#include "../simulation/options.h"

/**
 * @brief Initialize analytic jacobian.
 *
 * Jacobian has to be allocatd already.
 *
 * @param jacobian                  Jacobian to initialized.
 * @param sizeCols                  Number of columns of Jacobian
 * @param sizeRows                  Number of rows of Jacobian
 * @param sizeTmpVars               Size of tmp vars array.
 * @param constantEqns              Function pointer for constant equations of Jacobian.
 *                                  NULL if not available.
 * @param sparsePattern             Pointer to sparsity pattern of Jacobian.
 */
void initAnalyticJacobian(ANALYTIC_JACOBIAN* jacobian, unsigned int sizeCols, unsigned int sizeRows, unsigned int sizeTmpVars, int (*constantEqns)(void* data, threadData_t *threadData, void* thisJacobian, void* parentJacobian), SPARSE_PATTERN* sparsePattern) {
  jacobian->sizeCols = sizeCols;
  jacobian->sizeRows = sizeRows;
  jacobian->sizeTmpVars = sizeTmpVars;
  jacobian->seedVars = (modelica_real*) calloc(sizeCols, sizeof(modelica_real));
  jacobian->resultVars = (modelica_real*) calloc(sizeRows, sizeof(modelica_real));
  jacobian->tmpVars = (modelica_real*) calloc(sizeTmpVars, sizeof(modelica_real));
  jacobian->constantEqns = constantEqns;
  jacobian->sparsePattern = sparsePattern;
  jacobian->availability = JACOBIAN_UNKNOWN;
  jacobian->dae_cj = 0;
}

/**
 * @brief Copy analytic Jacobian.
 *
 * Sparsity pattern is not copied, only the pointer to it.
 *
 * @param source                  Jacobian that should be copied.
 * @return ANALYTIC_JACOBIAN*     Copy of source.
 */
ANALYTIC_JACOBIAN* copyAnalyticJacobian(ANALYTIC_JACOBIAN* source) {
  ANALYTIC_JACOBIAN* jacobian = (ANALYTIC_JACOBIAN*) malloc(sizeof(ANALYTIC_JACOBIAN));
  initAnalyticJacobian(jacobian,
                       source->sizeCols,
                       source->sizeRows,
                       source->sizeTmpVars,
                       source->constantEqns,
                       source->sparsePattern);

  return jacobian;
}

/**
 * @brief Free memory of analytic Jacobian.
 *
 * Also frees sparse pattern.
 *
 * @param jac   Pointer to Jacobian.
 */
void freeAnalyticJacobian(ANALYTIC_JACOBIAN *jac) {
  if (jac == NULL) {
    return;
  }
  free(jac->seedVars); jac->seedVars = NULL;
  free(jac->tmpVars); jac->tmpVars = NULL;
  free(jac->resultVars); jac->resultVars = NULL;
  freeSparsePattern(jac->sparsePattern);
  free(jac->sparsePattern); jac->sparsePattern = NULL;
}

/**
 * @brief Allocate memory for sparsity pattern.
 *
 * @param n_leadIndex         Number of rows or columns of Matrix.
 *                            Depending on compression type CSR (-->rows) or CSC (-->columns).
 * @param numberOfNonZeros    Numbe rof non-zero elements in Matrix.
 * @param maxColors           Maximum number of colors of Matrix.
 * @return SPARSE_PATTERN*    Pointer ot allocated sparsity pattern of Matrix.
 */
SPARSE_PATTERN* allocSparsePattern(unsigned int n_leadIndex, unsigned int numberOfNonZeros, unsigned int maxColors) {
  SPARSE_PATTERN* sparsePattern = (SPARSE_PATTERN*) malloc(sizeof(SPARSE_PATTERN));
  sparsePattern->leadindex = (unsigned int*) malloc((n_leadIndex+1)*sizeof(unsigned int));
  sparsePattern->index = (unsigned int*) malloc(numberOfNonZeros*sizeof(unsigned int));
  sparsePattern->sizeofIndex = numberOfNonZeros;
  sparsePattern->numberOfNonZeros = numberOfNonZeros;
  sparsePattern->colorCols = (unsigned int*) malloc(n_leadIndex*sizeof(unsigned int));
  sparsePattern->maxColors = maxColors;

  return sparsePattern;
}

/**
 * @brief Free sparsity pattern
 *
 * @param spp   Pointer to sparsity pattern
 */
void freeSparsePattern(SPARSE_PATTERN *spp) {
  if (spp != NULL) {
    free(spp->index); spp->index = NULL;
    free(spp->colorCols); spp->colorCols = NULL;
    free(spp->leadindex); spp->leadindex = NULL;
  }
}

/**
 * @brief Set Jacobian method from user flag and available Jacobian.
 *
 * @param threadData              Used for error handling.
 * @param availability            Is the Jacobian available, only the sparsity pattern available or nothing available.
 * @param flagValue               Flag value of FLAG_JACOBIAN. Can be NULL.
 * @return enum JACOBIAN_METHOD   Returns jacobian method that is availble.
 */
enum JACOBIAN_METHOD setJacobianMethod(threadData_t* threadData, JACOBIAN_AVAILABILITY availability, const char* flagValue){
  enum JACOBIAN_METHOD jacobianMethod = JAC_UNKNOWN;
  assertStreamPrint(threadData, availability != JACOBIAN_UNKNOWN, "Jacobian availablity status is unknown.");

  /* if FLAG_JACOBIAN is set, choose jacobian calculation method */
  if (flagValue) {
    for (int method=1; method < JAC_MAX; method++) {
      if (!strcmp(flagValue, JACOBIAN_METHOD[method])) {
        jacobianMethod = (enum JACOBIAN_METHOD) method;
        break;
      }
    }
    // Error case
    if(jacobianMethod == JAC_UNKNOWN){
      errorStreamPrint(LOG_STDOUT, 0, "Unknown value `%s` for flag `-jacobian`", flagValue);
      infoStreamPrint(LOG_STDOUT, 1, "Available options are");
      for (int method=1; method < JAC_MAX; method++) {
        infoStreamPrint(LOG_STDOUT, 0, "%s", JACOBIAN_METHOD[method]);
      }
      messageClose(LOG_STDOUT);
      omc_throw(threadData);
    }
  }

  /* Check if method is available */
  switch (availability)
  {
  case JACOBIAN_NOT_AVAILABLE:
    if (jacobianMethod != INTERNALNUMJAC && jacobianMethod != JAC_UNKNOWN) {
      warningStreamPrint(LOG_STDOUT, 0, "Jacobian not available, switching to internal numerical Jacobian.");
    }
    jacobianMethod = INTERNALNUMJAC;
    break;
  case JACOBIAN_ONLY_SPARSITY:
    if (jacobianMethod == COLOREDSYMJAC) {
      warningStreamPrint(LOG_STDOUT, 0, "Symbolic Jacobian not available, only sparsity pattern. Switching to colored numerical Jacobian.");
      jacobianMethod = COLOREDNUMJAC;
    } else if(jacobianMethod == SYMJAC) {
      warningStreamPrint(LOG_STDOUT, 0, "Symbolic Jacobian not available, only sparsity pattern. Switching to numerical Jacobian.");
      jacobianMethod = NUMJAC;
    } else if(jacobianMethod == JAC_UNKNOWN) {
      jacobianMethod = COLOREDNUMJAC;
    }
    break;
  case JACOBIAN_AVAILABLE:
    if (jacobianMethod == JAC_UNKNOWN) {
      jacobianMethod = COLOREDSYMJAC;
    }
    break;
  default:
    throwStreamPrint(threadData, "Unhandled case in setJacobianMethod");
    break;
  }

  /* Log Jacobian method */
  switch (jacobianMethod)
  {
  case INTERNALNUMJAC:
    infoStreamPrint(LOG_JAC, 0, "Using Jacobian method: Internal numerical Jacobian.");
    break;
  case NUMJAC:
    infoStreamPrint(LOG_JAC, 0, "Using Jacobian method: Numerical Jacobian.");
    break;
  case COLOREDNUMJAC:
    infoStreamPrint(LOG_JAC, 0, "Using Jacobian method: Colored numerical Jacobian.");
    break;
  case SYMJAC:
    infoStreamPrint(LOG_JAC, 0, "Using Jacobian method: Symbolical Jacobian.");
    break;
  case COLOREDSYMJAC:
    infoStreamPrint(LOG_JAC, 0, "Using Jacobian method: Colored symbolical Jacobian.");
    break;
  default:
    throwStreamPrint(threadData, "Unhandled case in setJacobianMethod");
    break;
  }
  return jacobianMethod;
}
