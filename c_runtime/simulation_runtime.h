/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with OpenModelica; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

#ifndef _SIMULATION_RUNTIME_H
#define _SIMULATION_RUNTIME_H

using namespace std;
#include <fstream>
#include <iostream>

#define DDASRT ddasrt_

extern "C" {
  void ddasrt_(
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
}

inline void read_commented_value( ifstream &f, double *res);
inline void read_commented_value( ifstream &f, int *res);

void read_input(int argc, char **argv,
		double* x,double*xd,double*y,
		double *p, int nx,int ny, int np,
		double *start, double *stop,
		double *step);
extern double x[];
extern double xd[];
extern double dummy_delta[];
extern double y[];
extern double p[];
extern long liw;
extern long lrw;
extern double rwork[];
extern long iwork[];
extern long nx,ny,np;
extern char *model_name;
extern char *varnames[];

// function for calculating ouput values 
int 
functionDAE_output(double *t, double *x, double *xprimne, double *y, double* p);

// function for calculating state values on residual form
int
functionDAE_res(double *t, double *x, double *xprime, double *delta, long int *ires, double *rpar, long int* ipar);

void functionODE(double *x, double *xd, double *y, double *p, 
		 int nx, int ny, int np, double *t);

void add_result(double *data, double time,double *nx, double *ndx, double *y,
		long nx, long ny, long *actual_points);

void store_result(const char * filename, double*data,
		  long numpoints, long nx, long ny);

void euler ( double *x, double *xd, double *y, double *p, double *data,
	     int nx, int ny, int np, double *time, double *step,
	     void (*f)(double*,// x
		       double*,// xd
		       double*,// y
		       double*,// p
		       int,int,int, //nx,ny,np
		       double *));

#endif
