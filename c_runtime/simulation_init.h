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
 * File: simulation_input.h
 */

#include <string>
#include <cstdlib>

#ifndef _SIMULATION_INIT_H
#define _SIMULATION_INIT_H

int initialize(const std::string*method);

#ifndef NEWUOA
#define NEWUOA newuoa_
#endif

#ifdef __cplusplus
extern "C" {
	void  NEWUOA(
	long *nz,
	long *NPT,
	double *z,
	double *RHOBEG,
	double *RHOEND,
	long *IPRINT,
	long *MAXFUN,
	double *W,
	void (*leastSquare) (long *nz, double *z, double *funcValue)
	);
} // extern C
#endif

#ifndef NELMEAD
#define NELMEAD nelmead_
#endif

#ifdef __cplusplus
extern "C" {
	void  NELMEAD(
	   double *z,
	   double *STEP,
	   long *nz,
	   double *funcValue,
	   long *MAXF,
	   long *IPRINT,
	   double *STOPCR,
	   long *NLOOP,
	   long *IQUAD,
	   double *SIMP,
	   double *VAR,
	   void (*leastSquare) (long *nz, double *z, double *funcValue),
	   long *IFAULT);
} // extern "C"
#endif

#endif
