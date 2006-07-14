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
#ifdef _MSC_VER
#  define NEWUOA NEWUOA
#else
#  define NEWUOA newuoa_
#endif
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

#ifdef _MSC_VER
#  define NELMEAD NELMEAD
#else
#  define NELMEAD nelmead_
#endif

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

#ifdef _MSC_VER
#  define DDASRT DDASRT
#else
#  define DDASRT ddasrt_
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
} // extern "C"

inline void read_commented_value( ifstream &f, double *res);
inline void read_commented_value( ifstream &f, int *res);

void read_input(int argc, char **argv,
		double* x,double*xd,double*y,
		double *p, int nx,int ny, int np,
		double *start, double *stop,
		double *step);

/* extern double* h; */
/* extern double* x; */
/* extern double* xd; */
/* extern double* dummy_delta; */
/* extern double* y; */
/* extern double* p; */
/* extern long* jroot; */
/* extern long liw; */
/* extern long lrw; */
/* extern double* rwork; */
/* extern long* iwork; */
/* extern long nhelp,nx,ny,np,ng,nr; */
/* extern char *model_name; */
/* extern char** varnames; */
/* extern int init; */


typedef enum {
/*   These are flags for the generated 
     initializeDataStruc(DATA_INIT_FLAGS) function */

  NO_INIT_OF_VECTORS        = 0x00000000,
  STATES                  	= 0x00000001,
  STATESDERIVATIVES      	= 0x00000002,
  HELPVARS                	= 0x00000004,
  ALGEBRAICS              	= 0x00000008,
  PARAMETERS              	= 0x00000010,
  INITIALRESIDUALS        	= 0x00000020,
  INPUTVARS               	= 0x00000040,
  OUTPUTVARS              	= 0x00000080,
  INITFIXED               	= 0x00000100,
  EXTERNALVARS			  	= 0x00000200,

  /*in initializeDataStruc these are not allocated with malloc!*/
  MODELNAME               	= 0x00000400, 
  STATESNAMES             	= 0x00000800,
  STATESDERIVATIVESNAMES  	= 0x00001000,
  ALGEBRAICSNAMES         	= 0x00002000,
  PARAMETERSNAMES         	= 0x00004000,
  INPUTNAMES              	= 0x00008000,
  OUTPUTNAMES             	= 0x00010000,

  /*in initializeDataStruc these are not allocated with malloc!*/
  STATESCOMMENTS            = 0x00020000,
  STATESDERIVATIVESCOMMENTS = 0x00040000,
  ALGEBRAICSCOMMENTS        = 0x00080000,
  PARAMETERSCOMMENTS        = 0x00100000,
  INPUTCOMMENTS             = 0x00200000,
  OUTPUTCOMMENTS            = 0x00400000,

  ALL                       = 0xFFFFFFFF
} DATA_FLAGS;

typedef struct sim_DATA_STRING {
  char** algebraics; //y ALGVARS
  char** parameters; //p; PARAMETERS
  char** inputVars; //in_y INPUTVARS
  char** outputVars; //out_y OUTPUTVARS

  long nAlgebraic,nParameters;
  long nInputVars,nOutputVars;
} DATA_STRING;


typedef struct sim_DATA {
  /* this is the data structure for saving important data for this simulation. */
  /* Each generated function have a DATA* parameter wich contain the data. */
  /* A object for the data can be created using */
  /* initializeDataStruc(DATA_FLAGS) function*/
  double* states; //x STATES
  double* statesDerivatives; //xd DERIVATIVES
  double* algebraics; //y ALGVARS
  double* parameters; //p; PARAMETERS
  double* inputVars; //in_y INPUTVARS
  double* outputVars; //out_y OUTPUTVARS
  double* helpVars;
  double* initialResiduals;
  char* initFixed;
  void** extObjs; // External objects	
  /* nStatesDerivatives == states */
  long nStates,nAlgebraic,nParameters;
  long nInputVars,nOutputVars;
  long nZeroCrossing/*NG*/;
  long nInitialResiduals/*NR*/;
  long nHelpVars/* NHELP */;
  //extern char init_fixed[];
    DATA_STRING stringVariables;


  char*  modelName;
  char** statesNames;
  char** stateDerivativesNames;
  char** algebraicsNames;
  char** parametersNames;
  char** inputNames;
  char** outputNames;
  char** statesComments;
  char** stateDerivativesComments;
  char** algebraicsComments;
  char** parametersComments;
  char** inputComments;
  char** outputComments;

  double timeValue; //the time for the simulation
  //used in some generated function
  // this is not changed by initializeDataStruc
} DATA;


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
 * This flag should be the same for second argument in deInitializeDataStruc
 * to avoid memory leak.
 */
DATA* initializeDataStruc(DATA_FLAGS flags);

/* this frees the memory that is allocated in the data-structure.
 * The second argument must have the same value as the argument in initializeDataStruc
 */ 
void deInitializeDataStruc(DATA* data, DATA_FLAGS flags);
/* this is used to set the localData in the generated code
 * that is used in the diferrent generated functions 
 * 
 */ 
void setLocalData(DATA* data);


/*used in DDASRT fortran function*/
int 
function_zeroCrossing(long *neqm, double *t, double *x, long *ng, double *gout, double *rpar, long* ipar);

int
handleZeroCrossing(long index);

// function for calculating ouput values 
/*used in DDASRT fortran function*/
int 
functionDAE_output();

// function for calculating state values on residual form
/*used in DDASRT fortran function*/
int
functionDAE_res(double *t, double *x, double *xprime, double *delta, long int *ires, double *rpar, long int* ipar);

int
function_when(int i);

int
function_updateDependents();

// function for calculating states on explicit ODE form
/*used in functionDAE_res function*/
int functionODE();

// function for calculate initial values from initial equations
// and fixed start attibutes
int initial_function(); 

int checkForDiscreteVarChanges();

// function for calculating bound parameters that depend on other
// parameters, e.g. parameter Real n=1/m;
int bound_parameters(); 

// function for calculate residual values for the initial equations
// and fixed start attibutes
int initial_residual();

int initialize(const std::string*method);

// Adds a result to the simulation result data.
void add_result(double *data, long *actual_points); 

// stores the result on file.
void store_result(const char * filename, double*data,
		  long numpoints);

// euler numerical solver
void euler ( DATA * data,
             double* step,
	     int (*f)() // time
	     );
 
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

#define MODELICA_ASSERT(cond,msg) do { if (!(cond)) { printf(msg); \
exit(-1);} } while(0)
#define initial() init

#endif
