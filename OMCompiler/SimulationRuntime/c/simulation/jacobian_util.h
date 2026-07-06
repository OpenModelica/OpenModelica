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
 * @brief setJacElementFunc-compatible setter: writes jac[nth] = value (sparse CSC raw buffer).
 */
void setJacElementRawSparse(int row, int col, int nth, double value, void* jac, int nRows);

/**
 * @brief setJacElementFunc-compatible setter: writes jac[col*nRows+row] = value (dense column-major raw buffer).
 */
void setJacElementRawDenseColumnMajor(int row, int col, int nth, double value, void* jac, int nRows);

/**
 * @brief setJacElementFunc-compatible setter: writes jac[row*nCols+col] = value (dense row-major raw buffer).
 */
void setJacElementRawDenseRowMajor(int row, int col, int nth, double value, void* jac, int nCols);

/**
 * @brief Evaluate colored Jacobian, storing results via a generic setter.
 *
 * This is the unified core evaluation function.  All other evalJacobian* variants
 * are thin wrappers that select an appropriate setJacElementFunc and delegate here.
 *
 * @param matrixA     Opaque pointer to output matrix; passed through to setElement.
 * @param setElement  Setter called for each nonzero: (row, col, nz_index, value, matrixA, nRows).
 */
void evalJacobianColored(DATA* data, threadData_t *threadData, JACOBIAN* jacobian, JACOBIAN* parentJacobian,
                         void* matrixA, setJacElementFunc setElement);

/**
 * @brief Evaluate colored Jacobian into a raw modelica_real* buffer.
 *
 * Convenience wrapper over evalJacobianColored.
 * isDense=TRUE  → column-major dense output; buffer is zero-initialised first.
 * isDense=FALSE → sparse CSC output; values written at their CSC position (jac[nz]).
 */
void evalJacobian(DATA* data, threadData_t *threadData, JACOBIAN* jacobian, JACOBIAN* parentJacobian, modelica_real* jac, modelica_boolean isDense);

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
