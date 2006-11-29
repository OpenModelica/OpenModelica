/*
Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/* File: simulation_input.h
 *
 */

#include <string>

#ifndef _SIMULATION_INIT_H
#define _SIMULATION_INIT_H

int initialize(const std::string*method);

#ifdef _MSC_VER
#  define NEWUOA NEWUOA
#else
#  define NEWUOA newuoa_
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


#ifdef _MSC_VER
#  define NELMEAD NELMEAD
#else
#  define NELMEAD nelmead_
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
