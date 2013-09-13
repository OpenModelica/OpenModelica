/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
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

#ifdef __cplusplus
extern "C"
{
#endif

#ifdef WITH_IPOPT

Bool evalfF(Index n, double * x, Bool new_x, Number *objValue, void * useData);
Bool evalfDiffF(Index n, double * x, Bool new_x, Number *gradF, void * useData);
Bool goal_func_mayer(double* vn, double *obj_value, IPOPT_DATA_ *iData);
Bool goal_func_lagrange(double* vn, double *obj_value, double t, IPOPT_DATA_ *iData);

Bool evalfG(Index n, double * x, Bool new_x, int m, Number *g, void * useData);
Bool evalfDiffG(Index n, double * x, Bool new_x,
       Index m, Index njac, Index *iRow, Index *iCol, Number* values, void * useData);

Bool ipopt_h(int n, double *x, Bool new_x, double obj_factor, int m, double *lambda, Bool new_lambda,
         int nele_hess, int *iRow, int *jCol, double *values, void* user_data);

#ifdef __cplusplus
}
#endif


/*JAC*/
int diff_functionODE(double *v, double t, IPOPT_DATA_ *iData, double **J);
int diff_functionODE0(double *v, double t, IPOPT_DATA_ *iData);
int diff_numColoredODE(double *v, double t, IPOPT_DATA_ *iData, double **J);
int diff_symColoredODE(double *v, double t, IPOPT_DATA_ *iData, double **J);
int ddiff(double *v, double t, IPOPT_DATA_ *iData);

/*model*/
int functionODE_(double * x, double *u, double t, double * dotx, IPOPT_DATA_ *iData);
int refreshSimData(double *x, double *u, double t, IPOPT_DATA_ *iData);

extern int mayer(DATA* data, modelica_real* res);
extern int lagrange(DATA* data, modelica_real* res);
extern int pathConstraints(DATA* data, modelica_real* res, int* N);

/*allocate*/
int loadDAEmodel(DATA* data, IPOPT_DATA_ *iData);
int get_moidel_info(DATA *data, IPOPT_DATA_ *iData);
int freeIpoptData(IPOPT_DATA_ *iData);

/*initial guess*/
int initial_guess_ipopt(IPOPT_DATA_ *iData,SOLVER_INFO* solverInfo);

/*DEBUGE*/
int ipoptDebuge(IPOPT_DATA_ *iData, double *x);

/*initial*/
int move_grid(IPOPT_DATA_ *iData);

#endif /*WITH_IPOPT*/

/*ADOL-C*/
/* extern int functionODE_ADOLC(DATA*);*/ /* jacobian(0, data->modelData.nStates, data->modelData.nStates + data->modelData.nInputVars, indvars, jac_states); */

#endif /* LOCALFUNCTION_H_ */
