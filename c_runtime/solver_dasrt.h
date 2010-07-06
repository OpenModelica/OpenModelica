/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link�ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
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
 * from Link�ping University, either from the above address,
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
 * File: simulation_runtime.h
 *
 * Description: This file is a C++ header file for the simulation runtime.
 * It contains solver functions and other simulation runtime specific functions
 *
 */

#ifndef _SOLVER_DASRT_H
#define _SOLVER_DASRT_H

#include "fortran_types.h"

int dassl_main(int argc, char**argv,double &start,  double &stop, double &step, long &outputSteps,
                double &tolerance);

#ifndef DDASRT
#define DDASRT ddasrt_
#endif

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



#endif
