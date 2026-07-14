/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/*! File jacobian_util.h
 */

#ifndef OMC_JACOBIAN_UTIL_H
#define OMC_JACOBIAN_UTIL_H

#include "../simulation_data.h"

#ifdef __cplusplus
extern "C" {
#endif

void initJacobian(JACOBIAN* jacobian, unsigned int sizeCols, unsigned int sizeRows, unsigned int sizeTmpVars, EVAL_DAG* dag, jacobianColumn_func_ptr evalColumn, jacobianColumn_func_ptr constantEqns, SPARSE_PATTERN* sparsePattern);
JACOBIAN* copyJacobian(JACOBIAN* source);
void freeJacobian(JACOBIAN* jac);
void freeJacobianCopy(JACOBIAN* jac);

typedef void (*jacobianSetDenseElementFunc)(modelica_real* jac, int row, int column, int nRows, int nCols, modelica_real value);

/**
 * @brief Generic element setter for a Jacobian matrix.
 *
 * Jac(row, column) = value.
 *
 * @param row     Row index.
 * @param column  Column index.
 * @param nth     Sparsity pattern position (CSC index).
 * @param value   Value to set.
 * @param Jac     Opaque pointer to the matrix data structure.
 * @param nRows   Number of rows.
 */
typedef void (*setJacElementFunc)(int row, int column, int nth, double value, void* Jac, int nRows);

/**
 * @brief Cleanup callback invoked after each color during Jacobian evaluation.
 *
 * Used to reset result and tmp vars between colors when needed (e.g. row-wise eval).
 * Pass NULL or evalJacobianCleanupNoop when no cleanup is required.
 *
 * @param jac  Jacobian being evaluated.
 */
typedef void (*jacobianCleanup_func_ptr)(JACOBIAN* jac);

/** No-op cleanup: does nothing. Use for column-wise (forward) evaluation. */
void evalJacobianCleanupNoop(JACOBIAN* jac);

/**
 * @brief Row-eval cleanup: zeros resultVars and tmpVars after each color.
 *
 * Required for row-wise (adjoint) evaluation to prevent accumulation across colors.
 */
void evalJacobianCleanupRowEval(JACOBIAN* jac);

/**
 * @brief setJacElementFunc-compatible setter: writes jac[nth] = value (sparse CSC raw buffer).
 */
void setJacElementRawSparse(int row, int col, int nth, double value, void* jac, int nRows);

/**
 * @brief setJacElementFunc-compatible setter: writes jac[col*nRows+row] = value (dense column-major raw buffer).
 */
void setJacElementRawDenseColumnMajor(int row, int col, int nth, double value, void* jac, int nRows);

/**
 * @brief setJacElementFunc-compatible setter for row-eval dense column-major output.
 *
 * Used in row-wise (adjoint) evaluation where setElement is called as
 * setElement(currentIndex=col, j=row, nth, value, jac, nRows).
 * Writes jac[col * nRows + row] = value.  nth is unused.
 */
void setJacElementRawDenseColumnMajorRowEval(int col, int row, int nth, double value, void* jac, int nRows);

/**
 * @brief setJacElementFunc-compatible setter: writes jac[row*nCols+col] = value (dense row-major raw buffer).
 */
void setJacElementRawDenseRowMajor(int row, int col, int nth, double value, void* jac, int nCols);

/**
 * @brief Evaluate one color of a Jacobian using a generic element setter.
 *
 * This is the shared single-color kernel used by both the serial evalJacobianColored
 * and the parallel evalJacobianColoredParallel.  Callers pre-compute the derived
 * quantities (isRowEval, activeDim, nRows) to avoid redundant work inside the parallel
 * region.
 *
 * evalFunc is passed explicitly so that callers with thread-local Jacobians that do not
 * have evalColumn set (e.g. those allocated by allocateThreadLocalJacobians) can supply
 * the correct function pointer from data->callback directly.
 *
 * @param jacobian    Jacobian to evaluate (seedVars/resultVars must be thread-local).
 * @param parentJac   Parent Jacobian; pass NULL in the parallel path.
 * @param sp          Sparse pattern (CSC for column eval, CSR for row eval).
 * @param color       0-based color index to process.
 * @param activeDim   jacobian->sizeRows (row eval) or jacobian->sizeCols (column eval).
 * @param nRows       (int)jacobian->sizeRows, passed through to the setter.
 * @param matrixA     Opaque output matrix; forwarded to setElement.
 * @param setElement  Orientation-aware setter called as setElement(currentIndex, j, nth, value, matrixA, nRows),
 *                    where j is the active (seeded) index and currentIndex is the passive index.
 *                    For column eval pass setJacElementRawDenseColumnMajor (receives row, col).
 *                    For row eval pass setJacElementRawDenseColumnMajorRowEval (receives col, row).
 *                    For sparse either direction works with setJacElementRawSparse.
 * @param evalFunc    Function that evaluates the Jacobian for the current seed vector.
 * @param cleanupFunc Called after scatter to reset intermediate state; NULL is a no-op.
 */
void evalJacobianOneColor(DATA* data, threadData_t* threadData,
                           JACOBIAN* jacobian, JACOBIAN* parentJac,
                           const SPARSE_PATTERN* sp, int color,
                           unsigned int activeDim, int nRows,
                           void* matrixA, setJacElementFunc setElement,
                           jacobianColumn_func_ptr evalFunc,
                           jacobianCleanup_func_ptr cleanupFunc);

/**
 * @brief Evaluate colored Jacobian, storing results via a generic setter.
 *
 * This is the unified core evaluation function.  All other evalJacobian* variants
 * are thin wrappers that select an appropriate setJacElementFunc and delegate here.
 *
 * Supports both column-wise (forward, jacobian->isRowEval == FALSE) and row-wise
 * (adjoint, jacobian->isRowEval == TRUE) evaluation based on the jacobian's isRowEval flag.
 * The sparsity pattern and seed/result indexing are chosen accordingly.
 *
 * @param matrixA     Opaque pointer to output matrix; passed through to setElement.
 * @param setElement  Setter called for each nonzero: (row, col, nz_index, value, matrixA, nRows).
 * @param cleanupFunc Called after each color to reset intermediate state.  Pass NULL or
 *                    evalJacobianCleanupNoop for column-wise eval; pass
 *                    evalJacobianCleanupRowEval for row-wise eval to avoid accumulation.
 */
void evalJacobianColored(DATA* data, threadData_t *threadData, JACOBIAN* jacobian, JACOBIAN* parentJacobian,
                         void* matrixA, setJacElementFunc setElement,
                         jacobianCleanup_func_ptr cleanupFunc);

/**
 * @brief Evaluate colored Jacobian into a raw modelica_real* buffer.
 *
 * Convenience wrapper over evalJacobianColored.
 * isDense=TRUE  → column-major dense output; buffer is zero-initialised first.
 * isDense=FALSE → sparse CSC output; values written at their CSC position (jac[nz]).
 */
void evalJacobian(DATA* data, threadData_t *threadData, JACOBIAN* jacobian, JACOBIAN* parentJacobian, modelica_real* jac, modelica_boolean isDense);
void evalJacobianExtended(DATA* data, threadData_t* threadData,
                   JACOBIAN_METHOD method,
                   JACOBIAN* jacobian, JACOBIAN* parentJacobian, JACOBIAN* t_jac,
                   void* outputMatrix, JACOBIAN_OUTPUT_FORMAT format,
                   setJacElementFunc setFwd, setJacElementFunc setAdj);

void initBidirectionalRecovery(JACOBIAN* fwd);
void evalJacobianBidirectional(DATA* data, threadData_t *threadData, JACOBIAN* fwd, JACOBIAN* parentJacobian, modelica_real* jac, modelica_boolean isDense);

SPARSE_PATTERN* allocSparsePattern(unsigned int n_leadIndex, unsigned int nnz, unsigned int maxColors);
void freeSparsePattern(SPARSE_PATTERN *spp);
FILE * openSparsePatternFile(DATA* data, threadData_t *threadData, const char* filename);
void readSparsePatternColor(threadData_t* threadData, FILE * pFile, unsigned int* colorCols, unsigned int color, unsigned int length, unsigned int maxIndex);
JACOBIAN_METHOD setJacobianMethod(threadData_t* threadData, JACOBIAN_AVAILABILITY availability);

void freeNonlinearPattern(NONLINEAR_PATTERN *nlp);

unsigned int* getNonlinearPatternCol(NONLINEAR_PATTERN *nlp, int var_idx);
unsigned int* getNonlinearPatternRow(NONLINEAR_PATTERN *nlp, int eqn_idx);

#ifdef __cplusplus
}
#endif

#endif
