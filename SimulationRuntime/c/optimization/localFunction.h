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

/*
 * Developed by:
 * FH-Bielefeld
 * Developer: Vitalij Ruge
 * Contact: vitalij.ruge@fh-bielefeld.de
 */

#ifndef LOCALFUNCTION_H_
#define LOCALFUNCTION_H_

#include "interfaceOptimization.h"
#include "ipoptODEstruct.h"


#ifdef WITH_IPOPT


#ifdef __cplusplus
extern "C"
{
#endif
Bool evalfF(Index n, double * x, Bool new_x, Number *objValue, void * useData);
Bool evalfDiffF(Index n, double * x, Bool new_x, Number *gradF, void * useData);
Bool goal_func_mayer(double* vn, double *obj_value, IPOPT_DATA_ *iData);
Bool goal_func_lagrange(double* vn, double *obj_value, int k, IPOPT_DATA_ *iData);

Bool evalfG(Index n, double * x, Bool new_x, int m, Number *g, void * useData);
Bool evalfDiffG(Index n, double * x, Bool new_x,
       Index m, Index njac, Index *iRow, Index *iCol, Number* values, void * useData);

Bool ipopt_h(int n, double *x, Bool new_x, double obj_factor, int m, double *lambda, Bool new_lambda,
         int nele_hess, int *iRow, int *jCol, double *values, void* user_data);

#ifdef __cplusplus
}
#endif


/*sym JAC*/
int diff_symColoredObject(IPOPT_DATA_ *iData, long double *gradF, int this_it);
int diff_symColoredODE(double *v, int k, IPOPT_DATA_ *iData, long double **J);

/*model*/
int functionODE_(double * x, double *u, int k, double * dotx, IPOPT_DATA_ *iData);
int refreshSimData(double *x, double *u, int k, IPOPT_DATA_ *iData);

/*allocate*/
int loadDAEmodel(DATA* data, IPOPT_DATA_ *iData);

/*initial guess*/
int initial_guess_ipopt(IPOPT_DATA_ *iData,SOLVER_INFO* solverInfo);

/*DEBUGE*/
int ipoptDebuge(IPOPT_DATA_ *iData, double *x);

#endif /*WITH_IPOPT*/

/*ADOL-C*/
/* extern int functionODE_ADOLC(DATA*);*/ /* jacobian(0, data->modelData.nStates, data->modelData.nStates + data->modelData.nInputVars, indvars, jac_states); */

#endif /* LOCALFUNCTION_H_ */
