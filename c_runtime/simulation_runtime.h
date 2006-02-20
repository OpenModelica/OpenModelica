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

/* File: simulation_runtime.h
 *
 * Description: This file is a C++ header file for the simulation runtime.
 * It contains solver functions and other simulation runtime specific functions
 */

#ifndef _SIMULATION_RUNTIME_H
#define _SIMULATION_RUNTIME_H


#include <fstream>
#include <iostream>

using namespace std;

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
} // extern "C"

inline void read_commented_value( ifstream &f, double *res);
inline void read_commented_value( ifstream &f, int *res);

void read_input(int argc, char **argv,
		double* x,double*xd,double*y,
		double *p, int nx,int ny, int np,
		double *start, double *stop,
		double *step);

extern double* h;
extern double* x;
extern double* xd;
extern double* dummy_delta;
extern double* y;
extern double* p;
extern long* jroot;
extern long liw;
extern long lrw;
extern double* rwork;
extern long* iwork;
extern long nhelp,nx,ny,np,ng;
extern char *model_name;
extern char** varnames;
extern int init;

int 
function_zeroCrossing(long *neqm, double *t, double *x, long *ng, double *gout, double *rpar, long* ipar);

int
handleZeroCrossing(long index, double* t);

// function for calculating ouput values 
int 
functionDAE_output(double *t, double *x, double *xprimne, double *y, double* p);

// function for calculating state values on residual form
int
functionDAE_res(double *t, double *x, double *xprime, double *delta, long int *ires, double *rpar, long int* ipar);

int
function_when(int i, double *t);

int
function_updateDependents(double *t);

// function for calculating states on explicit ODE form
int functionODE(double *x, double *xd, double *y, double *p, 
		 int nx, int ny, int np, double *t);

// function for calculate initial values from initial equations
// and fixed start attibutes
int initial_function(double*x, double *xd, double*y, double*p,
		    int nx, int ny, int np); 

// Adds a result to the simulation result data.
void add_result(double *data, double time,double *x, double *ndx, double *y,
		long nx, long ny, long *actual_points);

// stores the result on file.
void store_result(const char * filename, double*data,
		  long numpoints, long nx, long ny);

// euler numerical solver
void euler ( double *x, double *xd, double *y, double *p, double *data,
	     int nx, int ny, int np, double *time, double *step,
	     int (*f)(double*,// x
		       double*,// xd
		       double*,// y
		       double*,// p
		       int,int,int, //nx,ny,np
		       double *));
void saveall();
void save(double & var);
double pre(double & var);
bool edge(double& var);

double Sample(double t, double start ,double interval);
double sample(double start ,double interval);

void CheckForNewEvents(double *t);
void StartEventIteration(double *t);
void StateEventHandler(long jroot[], double *t);

void AddEvent(long);

extern long* zeroCrossingEnabled;

double Less(double a,double b);
double LessEq(double a,double b);
double Greater(double a,double b);
double GreaterEq(double a,double b);
#define ZEROCROSSING(ind,exp) gout[ind] = (zeroCrossingEnabled[ind])?double(zeroCrossingEnabled[ind])*exp:1.0
#define noEvent(arg) arg

#define MODELICA_ASSERT(cond,msg) do { if ((cond)) { printf(msg); \
exit(-1);} } while(0)
#define initial() init

#endif
