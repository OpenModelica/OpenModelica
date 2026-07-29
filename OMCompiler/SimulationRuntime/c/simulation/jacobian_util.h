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

#ifdef USE_PARJAC
void evalJacobianColoredParallel(DATA* data, threadData_t* threadData,
                                        JACOBIAN* jacColumns,
                                        SPARSE_PATTERN* spp,
                                        void* matrixA, setJacElementFunc setElement);
void allocateThreadLocalJacobians(JACOBIAN* source, JACOBIAN** jacColumns);
void freeAnalyticalJacobian(JACOBIAN** jacColumns);
#endif

typedef void (*jacobianSetDenseElementFunc)(modelica_real* jac, int row, int column, int nRows, int nCols, modelica_real value);
typedef void (*setJacElementFunc)(int row, int column, int nth, double value, void* Jac, int nRows);
typedef void (*jacobianCleanup_func_ptr)(JACOBIAN* jac);
void evalJacobianCleanupRowEval(JACOBIAN* jac);
void setJacElementRawSparse(int row, int col, int nth, double value, void* jac, int nRows);
void setJacElementRawDenseColumnMajor(int row, int col, int nth, double value, void* jac, int nRows);
void setJacElementRawDenseColumnMajorRowEval(int col, int row, int nth, double value, void* jac, int nRows);
void evalJacobianOneColor(DATA* data, threadData_t* threadData,
                           JACOBIAN* jacobian, JACOBIAN* parentJac,
                           const SPARSE_PATTERN* sp, int color,
                           unsigned int activeDim, int nRows,
                           void* matrixA, setJacElementFunc setElement,
                           jacobianColumn_func_ptr evalFunc,
                           jacobianCleanup_func_ptr cleanupFunc);
void evalJacobianColored(DATA* data, threadData_t *threadData, JACOBIAN* jacobian, JACOBIAN* parentJacobian,
                         void* matrixA, setJacElementFunc setElement,
                         jacobianCleanup_func_ptr cleanupFunc);
void evalJacobian(DATA* data, threadData_t *threadData, JACOBIAN* jacobian, JACOBIAN* parentJacobian, modelica_real* jac, modelica_boolean isDense);
void evalJacobianExtended(DATA* data, threadData_t* threadData,
                   JACOBIAN_METHOD method,
                   JACOBIAN* jacobian, JACOBIAN* parentJacobian, JACOBIAN* t_jac,
                   void* outputMatrix, JACOBIAN_OUTPUT_FORMAT format,
                   setJacElementFunc setFwd, setJacElementFunc setAdj);

void initBidirectionalRecovery(JACOBIAN* fwd);
void evalJacobianBidirectional(DATA* data, threadData_t *threadData,
                               JACOBIAN* fwd, JACOBIAN* parentJacobian,
                               void* matrixA, setJacElementFunc setElement,
                               jacobianCleanup_func_ptr cleanupFunc);

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
