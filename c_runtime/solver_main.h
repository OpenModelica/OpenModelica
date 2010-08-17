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
 * File: solver_main.h
 *
 * Description: This file is a C header file for the main solver function.
 * It contains integration method for simulation.
 *
 */

#ifndef _SOLVER_MAIN_H
#define _SOLVER_MAIN_H
#define DDASRT ddasrt_

#include "fortran_types.h"

extern "C" {
  void  DDASRT(
	       int (*res) (double *t, double *y, double *yprime, double *delta, fortran_integer *ires, double *rpar, fortran_integer* ipar),
	       fortran_integer *neq,
	       double *t,
	       double *y,
	       double *yprime,
	       double *tout,
	       fortran_integer *info,
	       double *rtol,
	       double *atol,
	       fortran_integer *idid,
	       double *rwork,
	       fortran_integer *lrw,
	       fortran_integer *iwork,
	       fortran_integer *liw,
	       double *rpar,
	       fortran_integer *ipar,
	       int (*jac) (double *t, double *y, double *yprime, double *delta, double *cj, double *rpar, fortran_integer* ipar),
	       int (*g) (fortran_integer *neqm, double *t, double *y, fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar),
	       fortran_integer *ng,
	       fortran_integer *jroot
	       );

	       double dlamch_(char*,int);
} // extern "C"

int solver_main( int argc, char** argv,double &start,  double &stop, double &step, long &outputSteps,
                double &tolerance,int flag);


#endif
