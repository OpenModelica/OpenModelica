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

/*! File jacobian_util.h
 */

#ifndef OMC_JACOBIAN_UTIL_H
#define OMC_JACOBIAN_UTIL_H

#include "../simulation_data.h"

#ifdef __cplusplus
extern "C" {
#endif

void initAnalyticJacobian(ANALYTIC_JACOBIAN* jacobian, unsigned int sizeCols, unsigned int sizeRows, unsigned int sizeTmpVars, int (*constantEqns)(void* data, threadData_t *threadData, void* thisJacobian, void* parentJacobian), SPARSE_PATTERN* sparsePattern);
ANALYTIC_JACOBIAN* copyAnalyticJacobian(ANALYTIC_JACOBIAN* source);
void freeAnalyticJacobian(ANALYTIC_JACOBIAN* jac);

SPARSE_PATTERN* allocSparsePattern(unsigned int n_leadIndex, unsigned int numberOfNonZeros, unsigned int maxColors);
void freeSparsePattern(SPARSE_PATTERN *spp);
enum JACOBIAN_METHOD setJacobianMethod(threadData_t* threadData, JACOBIAN_AVAILABILITY availability, const char* flagValue);


#ifdef __cplusplus
}
#endif

#endif
