/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

/*! OptimizerLocalFunction.h
 */


#ifndef _OPTIMIZER_LOCAL_FUNCTION_H
#define _OPTIMIZER_LOCAL_FUNCTION_H

#include "OptimizerData.h"

int pickUpModelData(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
void allocate_der_struct(OptDataStructure *s, OptDataDim * dim, DATA* data, OptData *optData);
void initial_guess_optimizer(OptData *optData, SOLVER_INFO* solverInfo);

void res2file(OptData *optData, SOLVER_INFO* solverInfo,double * v);
void optData2ModelData(OptData *optData, double *vopt, const int index);

void diffSynColoredOptimizerSystem(OptData *optData, modelica_real **J, const int i, const int j, const int index);
void diffSynColoredOptimizerSystemF(OptData *optData, modelica_real **J);
void debugeJac(OptData * optData,Number* vopt);
void debugeSteps(OptData * optData, modelica_real*vopt, modelica_real * lambda);
void copy_initial_values(OptData * optData, DATA* data);
void setLocalVars(OptData * optData, DATA * data, const double * const vopt, const int i, const int j, const int shift);

/*ipopt*/

#ifdef __cplusplus
extern "C"
{
#endif

Bool evalfG(Index n, double * v, Bool new_x, int m, Number *g, void * useData);
Bool evalfDiffG(Index n, double * x, Bool new_x, Index m, Index njac, Index *iRow, Index *iCol, Number *values, void * useData);
Bool evalfF(Index n, double * v, Bool new_x, Number *objValue, void * useData);
Bool evalfDiffF(Index n, double * v, Bool new_x, Number *gradF, void * useData);
Bool ipopt_h(int n, double *v, Bool new_x, double obj_factor, int m, double *lambda, Bool new_lambda,
                    int nele_hess, int *iRow, int *iCol, double *values, void* useData);

#ifdef __cplusplus
}
#endif

#endif
