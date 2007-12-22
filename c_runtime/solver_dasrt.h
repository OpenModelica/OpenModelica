/* 
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science, 
 * SE-58183 Linköping, Sweden. 
 * 
 * All rights reserved.
 * 
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC 
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF 
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC 
 * PUBLIC LICENSE. 
 * 
 * The OpenModelica software and the Open Source Modelica 
 * Consortium (OSMC) Public License (OSMC-PL) are obtained 
 * from Linköpings University, either from the above address, 
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 * 
 * This program is distributed  WITHOUT ANY WARRANTY; without 
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

int dassl_main(int argc, char**argv,double &start,  double &stop, double &step, long &outputSteps,
                double &tolerance);

#ifndef DDASRT
#define DDASRT ddasrt_
#endif

extern "C" {
  void  DDASRT(
	       int (*res) (double *t, double *y, double *yprime, double *delta, long *ires, double *rpar, long* ipar), 
	       long *neq, 
	       double *t,
	       double *y,
	       double *yprime, 
	       double *tout, 
	       long *info,
	       double *rtol, 
	       double *atol, 
	       long *idid, 
	       double *rwork,
	       long *lrw, 
	       long *iwork, 
	       long *liw, 
	       double *rpar, 
	       long *ipar, 
	       int (*jac) (double *t, double *y, double *yprime, double *delta, long *ires, double *rpar, long* ipar),
	       int (*g) (long *neqm, double *t, double *y, long *ng, double *gout, double *rpar, long* ipar),
	       long *ng,
	       long *jroot
	       );
	       
	       double dlamch_(char*,int);
} // extern "C"



#endif
