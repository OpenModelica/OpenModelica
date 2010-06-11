/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Link?pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link?ping, Sweden.
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
 * from Link?pings University, either from the above address,
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
using namespace std;

//********************* for dasrt_step*********************
#define MAXORD 5

//provides a dummy Jacobian to be used with DASSL
int dummyJacobianMINE(double *t, double *y, double *yprime, double *pd, fortran_integer *cj, double *rpar, fortran_integer* ipar)
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

//*********************end of dasrt_step**********************************

void euler_ex_step (double* step, int (*f)() );
void rungekutta_step (double* step, int (*f)());
void dasrt_step (double* step, int (*f)());

int euler_in_use;

/* The main function for a solver with synchronous event handling*/
int solver_main(int argc, char** argv, double &start,  double &stop, double &step, long &outputSteps,
		       double &tolerance, int flag)
{

	//Workaround for Relation in simulation_events
	euler_in_use = 1;

	//double sim_time;
	int dideventstep = 0;
	double laststep = 0;
	double current_stepsize = step;
	double offset = 0;
	globalData->oldTime = start;

	const string *init_method = getFlagValue("im",argc,argv);

	long numpoints = long((stop-start)/step)+2;

	// allocate data for storing results.
	if (initializeResult(5*numpoints,globalData->nStates,globalData->nAlgebraic,globalData->nParameters)) {
		cout << "Internal error, allocating result data structures"  << endl;
		return -1;
	}
	if (initializeEventData()) {
		cout << "Internal error, allocating event data structures" << endl;
		return -1;
	}

	if (sim_verbose) { cout << "Allocated simulation data storage" << endl; }

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
	if(sim_verbose) { emit(); }
	// Calculate stable discrete state
	// and initial ZeroCrossings
	function_updateDepend();
	if(sim_verbose) { emit(); }
	while(checkForDiscreteChanges()) {
		if (sim_verbose) cout << "Discrete Var Changed!" << endl;
		saveall();
		function_updateDepend();
	}
	saveall();
	if(sim_verbose) { emit(); }

	// Do a tiny step to initialize ZeroCrossing that are fulfilled
    // And then go back and start at t_0
	globalData->timeValue += calcTiny(globalData->timeValue);
	double* backupstats_new = new double[globalData->nStates];
	backupstats_new = globalData->states;
	if (flag == 1) euler_ex_step(&current_stepsize,functionODE);
	else if (flag == 2) rungekutta_step(&current_stepsize,functionODE);
	else if (flag == 3) dasrt_step(&current_stepsize,functionODE);
	else euler_ex_step(&current_stepsize,functionODE);
	functionDAE_output();
	if(sim_verbose) { emit(); }
	InitialZeroCrossings();

	globalData->timeValue = start;
	globalData->states = backupstats_new;
	delete [] backupstats_new;

	function_updateDepend();
	if(sim_verbose) { emit(); }
	while(checkForDiscreteChanges()) {
		if (sim_verbose) cout << "Discrete Var Changed!" << endl;
		saveall();
		function_updateDepend();
	}
	saveall();
	emit();

	globalData->init=0;
	
	// Put initial values to delayed expression buffers
	function_storeDelayed();

	
	if (sim_verbose)  {
		cout << "Performed initial value calutation." << endl;
		cout << "Start numerical solver from "<< globalData->timeValue << " to "<< stop << endl; 
	}

	while( globalData->timeValue < stop){

		/*
		 * Calculate new step size after an event
		 */
		if (dideventstep == 1){
			offset = globalData->timeValue-laststep;
			dideventstep = 0;
			if (globalData->timeValue == globalData->oldTime)
				globalData->timeValue += step - offset;
		}else{
			offset = 0;
			globalData->timeValue += step;
		}
		current_stepsize = step-offset;

		/* do one integration step
		 *
		 * one step means:
		 * determine all states by Integration-Method
		 * update continuous part with
		 * functionODE() and functionDAE_output();
		 *
		 */

		if (flag == 1) euler_ex_step(&current_stepsize,functionODE);
		else if (flag == 2) rungekutta_step(&current_stepsize,functionODE);
		else if (flag == 3) dasrt_step(&current_stepsize,functionODE);
		else euler_ex_step(&current_stepsize,functionODE);
		functionDAE_output();

		// functionDAE_output2() contains all discrete Values
		// should executed for noEvent() operator, but then
		// avoid all relation that are in function_updateDepend
		//functionDAE_output2();
		
		function_storeDelayed();

		//Check for Events
		if (CheckForNewEvent(INTERVAL) == 2){
			dideventstep = 1;
		}else{
			laststep = globalData->timeValue;
		}
		
		// Emit this time step
		// TODO: check if time step equal to output point
		emit();

	}

	deinitializeEventData();

	string* result_file =(string*)getFlagValue("r",argc,argv);
	string result_file_cstr;
	if (!result_file) {
		result_file_cstr = string(globalData->modelName)+string("_res.plt");
	} else {
		result_file_cstr = *result_file;
	}

  // In interactive mode there is no need to write results to file.
  if (isInteractiveSimulation()) {    
    deallocResult();
  } else {
    if (deinitializeResult(result_file_cstr.c_str())) {
      return -1;
    }
  }
	return 0;
}

void euler_ex_step (double* step, int (*f)())
{	
	for(int i=0; i < globalData->nStates; i++) {
		globalData->states[i] = globalData->states[i] + globalData->statesDerivatives[i] * (*step);
	}
	f();
}

void rungekutta_step (double* step, int (*f)())
{	
	int s=4,i,j,l;
	double b[4] = {1.0/6.0,1.0/3.0,1.0/3.0,1.0/6.0};
	double c[4] = {0,0.5,0.5,1};
	double a[][4] = { {0,0,0,0}, {0.5,0,0,0}, {0,0.5,0,0}, {0,0,1,0}};
	double sum=0;
	double* backupstats = new double[globalData->nStates];

	for(i=0; i < globalData->nStates; i++) {
		backupstats[i] = globalData->states[i];
	}
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
}
/*
 * brute force approach for DASSL with correct event handling
 *   - For now most feature of DASSL are not in use.
 *   + The feature will be introduced successively.
 */
void dasrt_step (double* step, int (*f)())
{
	//double uround = dlamch_("P",1);
	double tout;
	fortran_integer info[15];
	double rtol = 1.0e-5;
	double atol = 1.0e-5;
	fortran_integer idid = 0;
	fortran_integer ipar = 0;

	// work arrays for dassl
	fortran_integer liw = 20+globalData->nStates;
	fortran_integer lrw = 52+(MAXORD+4)*globalData->nStates+globalData->nStates*globalData->nStates+3*globalData->nZeroCrossing;
	double *rwork = new double[lrw];
	fortran_integer *iwork = new fortran_integer[liw];
	fortran_integer NG_var=0;	//->siehe ddasrt.c ZEILE 250
	fortran_integer jroot=0;    // without event handling
	//fortran_integer *jroot = new fortran_integer[globalData->nZeroCrossing];

	// Used when calculating residual for its side effects. (alg. var calc)
	double *dummy_delta = new double[globalData->nStates];

	int i;
	for(i=0; i<15; i++)
	    info[i] = 0;
    for(i=0; i<liw; i++)
    	iwork[i] = 0;
    for(i=0; i<lrw; i++)
    	rwork[i] = 0.0;
    for(i=0; i<globalData->nHelpVars; i++)
    	globalData->helpVars[i] = 0;

    try
    {
    	do
    	{
    		// Calculate time steps until tout is reached.
    		info[0]=0;
    		globalData->timeValue -=  *step;
    		tout = globalData->timeValue + *step;
			DDASRT(functionDAE_res, &globalData->nStates, &globalData->timeValue, globalData->states,
					globalData->statesDerivatives, &tout,
					info, &rtol, &atol,
					&idid, rwork, &lrw, iwork, &liw, globalData->algebraics,
					&ipar, dummyJacobianMINE, dummy_zeroCrossing,
					&NG_var, &jroot);

			if (idid < 0)
					{
					  fflush(stderr); fflush(stdout);
					  if (idid == -1)
						info[0] = 1; // try again
					  if(!continue_MINE(&idid,&atol,&rtol))
						throw TerminateSimulationException(globalData->timeValue);
					}
					info[0]=1;
					 // Since residual function calculates
					functionDAE_res(&globalData->timeValue,globalData->states,globalData->statesDerivatives,dummy_delta,0,0,0);
					// alg vars too.
					//acceptedStep=1;
					functionDAE_output();  // discrete variables are separated so that they can be emitted before and after the event.
					function_storeDelayed();
					//acceptedStep=0;
		}
		while (&step >= 0 && idid == 1 && globalData->timeValue < tout);
    }
    catch(TerminateSimulationException &e)
    {
        cout << e.getMessage() << endl;
    }

	//Free dassl specific work arrays.
	  delete [] iwork;
	  delete [] rwork;
	  //delete [] jroot;		//only for active event handling
	  delete [] dummy_delta;
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
    /* 1-4 are means success */
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



