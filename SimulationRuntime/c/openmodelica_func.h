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

/* File: modelica.h
 * Description: This is the C header file for the C code generated from
 * Modelica. It includes e.g. the C object representation of the builtin types
 * and arrays, etc.
 */

#ifndef OPENMODELICAFUNC_H_
#define OPENMODELICAFUNC_H_

#include "simulation_data.h"

#include "memory_pool.h"
#include "index_spec.h"
#include "boolean_array.h"
#include "integer_array.h"
#include "real_array.h"
#include "string_array.h"
#include "modelica_string.h"
#include "matrix.h"
#include "division.h"
#include "utility.h"

#include "model_help.h"
#include "delay.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * this is used for initialize the DATA structure that is used in
 * all the generated functions.
 * The parameter controls what vectors should be initilized in
 * in the structure. Usually you can use the "ALL" flag which
 * initilizes all the vectors. This is needed for example in those ocasions
 * when another process have allocated the needed vectors.
 * Make sure that you call this function first because it sets the non-initialize
 * pointer to 0.
 *
 * This flag should be the same for second argument in callExternalObjectDestructors
 * to avoid memory leak.
 */
/* DATA* initializeDataStruc(); */ /*create in model code */
void initializeDataStruc_X_2(DATA *data);

/* Function for calling external object constructors */
void
callExternalObjectConstructors(DATA *data);
/* Function for calling external object deconstructors */
void
callExternalObjectDestructors(DATA *_data);

/* function for calculating ouput values */
/*used in DDASRT fortran function*/
int functionODE(DATA *data);          /* functionODE with respect to start-values */
int functionAlgebraics(DATA *data);   /* functionAlgebraics with respect to start-values */
int functionAliasEquations(DATA *data);


/*   function for calculating all equation sorting order
  uses in EventHandle  */
int
functionDAE(DATA *data, int *needToIterate);


/* functions for input and output */
int input_function(DATA*);
int output_function(DATA*);

/* function for storing value histories of delayed expressions
 * called from functionDAE_output()
 */
int
function_storeDelayed(DATA *data);

/* function for calculating states on explicit ODE form */
/*used in functionDAE_res function*/
int functionODE_inline(DATA *data, double stepsize);

/*! \fn updateBoundStartValues
 *
 *  This function updates all bound start-values. This are all start-values
 *  which are not constant.
 *  obsolete: initial_function
 *
 *  \param [ref] [data]
 */
int updateBoundStartValues(DATA *data);

/* function for calculate residual values for the initial equations and fixed start attibutes */
int initial_residual(DATA *data, double lambda, double* initialResiduals);

/*! \fn updateBoundParameters
 *
 *  This function calculates bound parameters that depend on other parameters,
 *  e.g. parameter Real n=1/m;
 *  obsolete: bound_parameters
 *
 *  \param [ref] [data]
 */
int updateBoundParameters(DATA *data);

/* function for checking for asserts and terminate */
int checkForAsserts(DATA *data);

/* functions for event handling */
int function_onlyZeroCrossings(DATA *data, double* gout, double* t);
int function_updateSample(DATA *data);
int checkForDiscreteChanges(DATA *data);

/* function for initializing time instants when sample() is activated */
void function_sampleInit(DATA *data);
void function_initMemoryState();

/* function for calculation Jacobian */
/*#ifdef D_OMC_JACOBIAN*/
int initialAnalyticJacobianA(DATA* data);
int initialAnalyticJacobianB(DATA* data);
int initialAnalyticJacobianC(DATA* data);
int initialAnalyticJacobianD(DATA* data);
int functionJacA(DATA* data, double* jac);
int functionJacB(DATA* data, double* jac);
int functionJacC(DATA* data, double* jac);
int functionJacD(DATA* data, double* jac);
/*#endif*/

extern const char *linear_model_frame; /* printf format-string with holes for 6 strings */

#ifdef __cplusplus
}
#endif

#endif
