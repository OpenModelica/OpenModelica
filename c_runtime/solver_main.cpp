/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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

#include "solver_main.h"
#include "simulation_input.h"
#include "simulation_init.h"
#include "simulation_events.h"
#include "simulation_result.h"
#include "simulation_runtime.h"
#include "options.h"
#include <math.h>
#include <string>
#include <iostream>
#include <iomanip>
#include <algorithm>
#include <cstdarg>
using namespace std;

// Internal definitions; do not expose
int inline_step (double* step, int (*f)() );
int euler_ex_step (double* step, int (*f)() );
int rungekutta_step (double* step, int (*f)());
int dasrt_step (double* step, double &start, double &stop, bool &trigger, int (*f)());

#define MAXORD 5

//provides a dummy Jacobian to be used with DASSL
int dummyJacobianMINE(double *t, double *y, double *yprime, double *pd, double *cj, double *rpar, fortran_integer* ipar)
{
	return 0;
}

int dummy_zeroCrossing(fortran_integer *neqm, double *t, double *y, fortran_integer *ng, double *gout, double *rpar, fortran_integer* ipar)
{
	return 0;
}
bool continue_MINE(fortran_integer* idid, double* atol, double *rtol);

/* \brief
* calculates a tiny step
*
* A tiny step is taken at initialization to check events. The tiny step is calculated as
* 200*uround*max(abs(T0),abs(T1)) = 200*uround*abs(T1), when simulating from T0 to T1, and uround is the machine precision.
*/
double calcTiny(double tout)
{
  double uround = dlamch_("P",1);
  if (tout == 0.0) {
    return 1000.0*uround;
  } else {
    return 1000.0*uround*fabs(tout);
  }
}

fortran_integer info[15];
double reltol = 1.0e-5;
double abstol = 1.0e-5;
fortran_integer idid = 0;
fortran_integer ipar = 0;

// work arrays for DASSL
fortran_integer liw;
fortran_integer lrw;
double *rwork;
fortran_integer *iwork;
fortran_integer NG_var=0;	//->see ddasrt.c LINE 250 (number of constraint functions)
fortran_integer *jroot;

// work array for inline implementation
double **inline_work_states;

// Used when calculating residual for its side effects. (alg. var calc)
double *dummy_delta;

int euler_in_use;

int solver_main_step(int flag, double* step, double &start, double &stop, bool &reset, int (*f)()) {
  switch (flag) {
	case 2:
    return rungekutta_step(&globalData->current_stepsize,functionODE);
  case 3:
    return dasrt_step(&globalData->current_stepsize,start,stop,reset,functionODE);
  case 4:
    return inline_step(&globalData->current_stepsize,functionODE_inline);
  case 1:
  default:
    return euler_ex_step(&globalData->current_stepsize,functionODE);
  }
}	

/* The main function for a solver with synchronous event handling
flag 1=explicit euler
     2=rungekutta
     3=dassl
     4=inline
*/
int solver_main(int argc, char** argv, double &start,  double &stop, double &step, long &outputSteps,
		       double &tolerance, int flag)
{
	acceptedStep = 1; // euler only takes accepted steps

	//Workaround for Relation in simulation_events
	euler_in_use = 1;

	//Flags for event handling
	int dideventstep = 0;
	bool reset = false;


	double laststep = 0;
	double offset = 0;
	globalData->oldTime = start;

	double uround = dlamch_("P",1);

	const string *init_method = getFlagValue("im",argc,argv);

	int retValIntration;

  // Enable inlining solvers
  if (flag == 4) {
    inline_work_states = (double**) malloc(inline_work_states_ndims*sizeof(double*));
    for (int i=0; i<inline_work_states_ndims; i++)
      inline_work_states[i] = (double*) malloc(globalData->nStates*sizeof(double));
  }

	if (initializeEventData()) {
		cout << "Internal error, allocating event data structures" << endl;
		return -1;
	}

	if(bound_parameters()) {
		printf("Error calculating bound parameters\n");
		return -1;
	}
	if (sim_verbose) { cout << "Calculated bound parameters" << endl; }

	//Enable all Events
	for (int i = 0; i < globalData->nZeroCrossing; i++) {
		zeroCrossingEnabled[i] = 1;
	}

	// Calculate initial values from initial_function()
	// saveall() value as pre values
	globalData->init=1;
	initial_function();
	
	// Calculate initial values from (fixed) start attributes
	if (initialize(init_method)) {
		throw TerminateSimulationException(globalData->timeValue,
				string("Error in initialization. Storing results and exiting.\n"));
	}
	saveall();
	if(sim_verbose) { sim_result->emit(); }
	// Calculate stable discrete state
	// and initial ZeroCrossings
	function_updateDepend();
	if(sim_verbose) { sim_result->emit(); }
	while(checkForDiscreteChanges()) {
		if (sim_verbose) cout << "Discrete Var Changed!" << endl;
		saveall();
		function_updateDepend();
	}
	saveall();
	if(sim_verbose) { sim_result->emit(); }

	// Do a tiny step to initialize ZeroCrossing that are fulfilled
    // And then go back and start at t_0
	globalData->current_stepsize = calcTiny(globalData->timeValue);
	double* backupstats_new = new double[globalData->nStates];
  std::copy(globalData->states, globalData->states + globalData->nStates, backupstats_new);
  
  solver_main_step(flag,&globalData->current_stepsize,start,stop,reset,functionODE);
	functionDAE_output();
	if(sim_verbose) { sim_result->emit(); }
	InitialZeroCrossings();

	globalData->timeValue = start;
  globalData->current_stepsize = step;
  std::copy(backupstats_new, backupstats_new + globalData->nStates, globalData->states);
	delete [] backupstats_new;
	reset = true;

	function_updateDepend();
	if(sim_verbose) { sim_result->emit(); }
	while(checkForDiscreteChanges()) {
		if (sim_verbose) cout << "Discrete Var Changed!" << endl;
		saveall();
		function_updateDepend();
	}
	saveall();
	sim_result->emit();

	globalData->init=0;
	
	// Put initial values to delayed expression buffers
	function_storeDelayed();

	
	if (sim_verbose)  {
		cout << "Performed initial value calculation." << endl;
		cout << "Start numerical solver from "<< globalData->timeValue << " to "<< stop << endl; 
	}

  try {
	while( globalData->timeValue < stop){

		/*
		 * Calculate new step size after an event
		 */
		if (dideventstep == 1){
			offset = globalData->timeValue-laststep;
			dideventstep = 0;
			if (offset+10*uround > step)
				offset = 0;
		}else{
			offset = 0;
		}
		globalData->current_stepsize = step-offset;

		/* do one integration step
		 *
		 * one step means:
		 * determine all states by Integration-Method
		 * update continuous part with
		 * functionODE() and functionDAE_output();
		 *
		 */

    retValIntration = solver_main_step(flag,&globalData->current_stepsize,start,stop,reset,functionODE);

		functionDAE_output();

		// functionDAE_output2() contains all discrete Values
		// should executed for noEvent() operator, but then
		// avoid all relation that are in function_updateDepend
		//functionDAE_output2();
		
		function_storeDelayed();

		if (reset)
			reset = false;

		//Check for Events
		if (CheckForNewEvent(INTERVAL) == 2){
			reset = true;
			dideventstep = 1;
		}else{
			laststep = globalData->timeValue;
		}
		
		// Emit this time step
		sim_result->emit();

		if (retValIntration){
			throw TerminateSimulationException(globalData->timeValue,
					string("Error in Simulation. Solver exit with error.\n"));
		}


	}
  } catch (TerminateSimulationException &e) {
    cout << e.getMessage() << endl;
    if (modelTermination) { // terminated from assert, etc.
      cout << "Simulation terminated at time " << globalData->timeValue << endl;
      return -1;
    }
  }

	deinitializeEventData();

	return 0;
}

int inline_step(double* step, int (*f)())
{	
  double* tmp;
  f();
  std::swap(globalData->states,inline_work_states[0]);
	return 0;
}

int euler_ex_step (double* step, int (*f)())
{	
	globalData->timeValue += *step;
	for(int i=0; i < globalData->nStates; i++)	{
		globalData->states[i] = globalData->states[i] + globalData->statesDerivatives[i] * (*step);
	}
	f();
	return 0;
}

int rungekutta_step (double* step, int (*f)())
{	
	globalData->timeValue += *step;
	const int s=4;
  int i,j,l;
	const double b[4] = {1.0/6.0,1.0/3.0,1.0/3.0,1.0/6.0};
	const double c[4] = {0,0.5,0.5,1};
	const double a[][4] = { {0,0,0,0}, {0.5,0,0,0}, {0,0.5,0,0}, {0,0,1,0}};
	double sum=0;
	double* backupstats = new double[globalData->nStates];

	std::copy(globalData->states, globalData->states + globalData->nStates, backupstats);
	
	double** k;

	k = new double*[s];
	for(i=0;i<s;i++){
		k[i] = new double[globalData->nStates];
		for(j=0;j<globalData->nStates;j++){
			k[i][j] = 0;
		}
	}

	for(j=0;j<s;j++){

		globalData->timeValue = globalData->oldTime + c[j]  * (*step);
		for(int i=0; i < globalData->nStates; i++) {
			sum=0;
			for(l=0; l < s; l++) {
				sum = sum + a[j][l] * k[l][i];
			}
			globalData->states[i] = backupstats[i] + (*step) * sum;
		}
		f();
		for(int i=0; i < globalData->nStates; i++) {
			k[j][i] = globalData->statesDerivatives[i];
		}
	}

	for(i=0 ; i < globalData->nStates; i++) {
		sum = 0;
		for(l=0; l < s; l++) {
			sum = sum + b[l] * k[l][i];
		}
		globalData->states[i] = backupstats[i] + (*step) * sum;
	}
	f();
	return 0;
}
/*
 * DASSL with synchronous treating of when equation
 *   - without integrated ZeroCrossing method.
 *   + ZeroCrossing are handled outside DASSL.
 *   + if no event occurs outside DASSL perform a warm-start
 */
int dasrt_step (double* step, double &start, double &stop, bool &trigger, int (*f)())
{
	double tout;
	int i;
	extern fortran_integer info[15];
	extern double reltol;
	extern double abstol;
	extern fortran_integer idid;
	extern fortran_integer ipar;
	extern fortran_integer liw;
	extern fortran_integer lrw;
	extern double *rwork;
	extern fortran_integer *iwork;
	extern fortran_integer NG_var;	//->see ddasrt.c LINE 250 (number of constraint functions)
	extern fortran_integer *jroot;
	extern double *dummy_delta;

	if(globalData->timeValue == start){
		if (sim_verbose){
			cout << "**Calling DDASRT the first time..." << endl;
		}
		// work arrays for DASSL
		liw = 20+globalData->nStates;
		lrw = 52+(MAXORD+4)*globalData->nStates+globalData->nStates*globalData->nStates+3*globalData->nZeroCrossing;
		rwork = new double[lrw];
		iwork = new fortran_integer[liw];
		jroot = new fortran_integer[globalData->nZeroCrossing];
		// Used when calculating residual for its side effects. (alg. var calc)
		dummy_delta = new double[globalData->nStates];

		for(i=0; i<15; i++)
			info[i] = 0;
		for(i=0; i<liw; i++)
			iwork[i] = 0;
		for(i=0; i<lrw; i++)
			rwork[i] = 0.0;
		for(i=0; i<globalData->nHelpVars; i++)
			globalData->helpVars[i] = 0;
		/*********************************************************************/
		//info[2] = 1;		//intermediate-output mode
		/*********************************************************************/
		//info[3] = 1;		//go not past TSTOP
		//rwork[0] = stop;	//TSTOP
		/*********************************************************************/
		//info[6] = 1;		//prohibit code to decide max. stepsize on its own
		//rwork[1] = *step;	//define max. stepsize
		/*********************************************************************/
	}

	if (trigger){
		if (sim_verbose){
			cout << "Event-management forced reset of DDASRT... " << endl;
		}
		info[0]=0;	// obtain reset
	}

	// Calculate time steps until TOUT is reached (DASSL calculates beyond TOUT unless info[6] is set to 1!)
    try{
    	do{
    		tout = globalData->timeValue + *step;

    		if (sim_verbose){
				cout << "**Calling DDASRT from " << globalData->timeValue << " to " << tout << "..." << endl;
			}

			DDASRT(functionDAE_res, &globalData->nStates, &globalData->timeValue, globalData->states,
					globalData->statesDerivatives, &tout,
					info, &reltol, &abstol,
					&idid, rwork, &lrw, iwork, &liw, globalData->algebraics,
					&ipar, dummyJacobianMINE, dummy_zeroCrossing,
					&NG_var, jroot);
/*
			if (sim_verbose){
				cout << " value of idid: " << idid << endl;
				cout << " step size H to be attempted on next step: " << rwork[2] << endl;
				cout << " current value of independent variable: " << rwork[3] << endl;
				cout << " stepsize used on last successful step : " << rwork[6] << endl;
				cout << " number of steps taken so far: " << iwork[10] << endl << endl;
			}
*/
			if (idid < 0){
			  fflush(stderr); fflush(stdout);
			  if (idid == -1){
					if (sim_verbose){
						cout << "DDASRT will try again..." << endl;
					}
					info[0] = 1; // try again
			  }
			  if(!continue_MINE(&idid,&abstol,&reltol))
				throw TerminateSimulationException(globalData->timeValue);
			}

			// Since residual function calculates alg vars too.
			functionDAE_res(&globalData->timeValue,globalData->states,globalData->statesDerivatives,dummy_delta,0,0,0);
		}
		while(idid==-1 && globalData->timeValue <= stop);
    }
    catch(TerminateSimulationException &e){
        cout << e.getMessage() << endl;
    	//free DASSL specific work arrays.
		delete [] iwork;
		delete [] rwork;
		delete [] jroot;
		delete [] dummy_delta;
        return 1;

    }

    if(tout > stop){
    	if (sim_verbose){
			cout << "**Deleting work arrays after last DDASRT call..." << endl;
		}
    	//free DASSL specific work arrays.
		delete [] iwork;
		delete [] rwork;
		delete [] jroot;
		delete [] dummy_delta;
    }
    return 0;
}

bool continue_MINE(fortran_integer* idid, double* atol, double *rtol)
{
  static int atolZeroIterations=0;
  bool retValue = true;
  switch(*idid ){
  case 1:
  case 2:
  case 3:
  case 4:
    /* 1-4 means success */
    break;
  case -1:
    std::cerr << "DDASRT: A large amount of work has been expended.(About 500 steps). Trying to continue ..." << std::endl;
    retValue = true; /* adrpo: try to continue */
    break;
  case -2:
    std::cerr << "DDASRT: The error tolerances are too stringent." << std::endl;
    retValue = false;
    break;
  case -3:
    if (atolZeroIterations > 10) {
      std::cerr << "DDASRT: The local error test cannot be satisfied because you specified a zero component in ATOL and the corresponding computed solution component is zero. Thus, a pure relative error test is impossible for this component." << std::endl;
      retValue = false;
      atolZeroIterations++;
    } else {
      *atol = 1e-6;
      retValue = true;
    }
    break;
  case -6:
    std::cerr << "DDASRT: DDASSL had repeated error test failures on the last attempted step." << std::endl;
    retValue = false;
    break;
  case -7:
    std::cerr << "DDASRT: The corrector could not converge." << std::endl;
    retValue = false;
    break;
  case -8:
    std::cerr << "DDASRT: The matrix of partial derivatives is singular." << std::endl;
    retValue = false;
    break;
  case -9:
    std::cerr << "DDASRT: The corrector could not converge. There were repeated error test failures in this step." << std::endl;
    retValue = false;
    break;
  case -10:
    std::cerr << "DDASRT: The corrector could not converge because IRES was equal to minus one." << std::endl;
    retValue = false;
    break;
  case -11:
    std::cerr << "DDASRT: IRES equal to -2 was encountered and control is being returned to the calling program." << std::endl;
    retValue = false;
    break;
  case -12:
    std::cerr << "DDASRT: DDASSL failed to compute the initial YPRIME." << std::endl;
    retValue = false;
    break;
  case -33:
    std::cerr << "DDASRT: The code has encountered trouble from which it cannot recover. " << std::endl;
    retValue = false;
    break;
  }
  return retValue;
}



