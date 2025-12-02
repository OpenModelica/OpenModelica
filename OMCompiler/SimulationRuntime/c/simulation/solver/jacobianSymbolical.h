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

 /*! \file jacobianSymbolical.h
 */

#ifndef OMC_JACOBIAN_SYMBOLICAL_H
#define OMC_JACOBIAN_SYMBOLICAL_H

#include "../../simulation_data.h"
#include "util/parallel_helper.h"

/**
 * @brief Set element of Jacobian matrix.
 *
 * Jac(row, column) = val.
 *
 * @param row       Row of matrix element.
 * @param column    Column of matrix element.
 * @param nth       Sparsity pattern lead index.
 * @param value     Value to set in position (i,j).
 * @param Jac       Pointer to data structure storing matrix.
 * @param nRows     Number of rows of Jacobian matrix, unused.
 */
typedef void (*setJacElementFunc)(int row, int column, int nth, double value, void* Jac, int nRows);

void allocateThreadLocalJacobians(DATA* data, JACOBIAN** jacColumns);

void genericColoredSymbolicJacobianEvaluation(int rows, int columns, SPARSE_PATTERN* spp,
                                              void* matrixA, JACOBIAN* jacColumns,
                                              DATA* data,
                                              threadData_t* threadData,
                                              setJacElementFunc setJacElement);

void freeAnalyticalJacobian(JACOBIAN** jacColumns);

#endif
