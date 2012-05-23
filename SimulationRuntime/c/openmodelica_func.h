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

#ifdef __cplusplus
extern "C" {
#endif

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
extern void setupDataStruc2(DATA *data);

/* Function for calling external object constructors */
extern void callExternalObjectConstructors(DATA *data);
/* Function for calling external object deconstructors */
extern void callExternalObjectDestructors(DATA *_data);

/* functionODE contains those equations that are needed
 * to calculate the dynamic part of the system */
extern int functionODE(DATA *data);

/* functionAlgebraics contains all continuous equations that
 * are not part of the dynamic part of the system */
extern int functionAlgebraics(DATA *data);

/* function for calculating all equation sorting order
   uses in EventHandle  */
extern int functionDAE(DATA *data, int *needToIterate);

/* functions for input and output */
extern int input_function(DATA*);
extern int output_function(DATA*);

/* function for storing value histories of delayed expressions
 * called from functionDAE_output()
 */
extern int function_storeDelayed(DATA *data);

/* function for calculating states on explicit ODE form */
/*used in functionDAE_res function*/
extern int functionODE_inline(DATA *data, double stepsize);

/*! \fn updateBoundStartValues
 *
 *  This function updates all bound start-values. This are all start-values
 *  which are not constant.
 *  obsolete: initial_function
 *
 *  \param [ref] [data]
 */
extern int updateBoundStartValues(DATA *data);

/*! \fn initial_residual
 *
 * function for calculate residual values for the initial equations and initial algorithms
 *
 *  \param [in]  [data]
 *  \param [ref] [initialResiduals]
 */
extern int initial_residual(DATA *data, double* initialResiduals);

/*! \fn updateBoundParameters
 *
 *  This function calculates bound parameters that depend on other parameters,
 *  e.g. parameter Real n=1/m;
 *  obsolete: bound_parameters
 *
 *  \param [ref] [data]
 */
extern int updateBoundParameters(DATA *data);

/* function for checking for asserts and terminate */
extern int checkForAsserts(DATA *data);

/* functions for event handling */
extern int function_onlyZeroCrossings(DATA *data, double* gout, double* t);
extern int function_updateSample(DATA *data);
extern int checkForDiscreteChanges(DATA *data);

/* function for initializing time instants when sample() is activated */
extern void function_sampleInit(DATA *data);
extern void function_initMemoryState(void);

/* function for calculation Jacobian */
/*#ifdef D_OMC_JACOBIAN*/
extern int initialAnalyticJacobianA(DATA* data);
extern int initialAnalyticJacobianB(DATA* data);
extern int initialAnalyticJacobianC(DATA* data);
extern int initialAnalyticJacobianD(DATA* data);
extern int functionJacA(DATA* data, double* jac);
extern int functionJacB(DATA* data, double* jac);
extern int functionJacC(DATA* data, double* jac);
extern int functionJacD(DATA* data, double* jac);
/*#endif*/

extern const char *linear_model_frame; /* printf format-string with holes for 6 strings */

#ifdef __cplusplus
}
#endif

#endif
