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

#include "simulation_input.h"
#include "simulation_init.h"
#include "simulation_events.h"
#include "simulation_result.h"
#include "simulation_runtime.h"
#include "options.h"
#include <string>
#include <iostream>
using namespace std;


void euler_ex_step (double* step, int (*f)() );
void rungekutta_step (double* step, int (*f)());

int euler_in_use;

/* The main function for the explicit euler solver */
int euler_main( int argc, char** argv,double &start,  double &stop, double &step, long &outputSteps,
		double &tolerance,int flag)
{

	//Workaround for Ralation in simulation_events
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

	// Calculate initial values from initial_function()
	// saveall() value as pre values
	globalData->init=1;
	initial_function();
	saveall();
	emit();
	
	// Calculate initial values from (fixed) start attributes
	if (initialize(init_method)) {
		throw TerminateSimulationException(globalData->timeValue,
				string("Error in initialization. Storing results and exiting.\n"));
	}

	// Calculate stable discrete state
	// and initial ZeroCrossings
	saveall();
	function_updateDepend();
	if(sim_verbose) { emit(); }
	InitialZeroCrossings();
	while(checkForDiscreteChanges()) {
		if (sim_verbose) cout << "Discrete Var Changed!" << endl;
		saveall();
		function_updateDepend();
	}
	if(sim_verbose) {emit();}

	// Put initial values to delayed expression buffers
	function_storeDelayed();
	// check for Event at Initial
	if (sim_verbose) { cout << "Checking events at initialization (at time "<< globalData->timeValue << ")." << endl; }
	if (CheckForNewEvent(NOINTERVAL)){
		if(sim_verbose) { emit(); }
	}
	saveall();
	globalData->init=0;
	
	
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
	if (deinitializeResult(result_file_cstr.c_str())) {
		return -1;
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
	double* k1 = new double[globalData->nStates];
	double* k2 = new double[globalData->nStates];
	double* k3 = new double[globalData->nStates];
	double* k4 = new double[globalData->nStates];
	double* backupstats = new double[globalData->nStates];
	
	for(int i=0; i < globalData->nStates; i++) {
		backupstats[i] = globalData->states[i];
		k1[i] = globalData->statesDerivatives[i];
		globalData->states[i] = backupstats[i] + 0.5 *(*step) * k1[i];
	}
	globalData->timeValue = globalData->timeValue - 0.5 *(*step);
	f();
	for(int i=0; i < globalData->nStates; i++) {
		k2[i] = globalData->statesDerivatives[i];
		globalData->states[i] = backupstats[i] + 0.5 *(*step) * k2[i];
	}
	f();
	for(int i=0; i < globalData->nStates; i++) {
		k3[i] = globalData->statesDerivatives[i];
	}	
	globalData->timeValue = globalData->timeValue + 0.5 * (*step);
	for(int i=0; i < globalData->nStates; i++) {
		globalData->states[i] = backupstats[i] + (*step) * k3[i];
	}
	f();
	for(int i=0; i < globalData->nStates; i++) {
		k4[i] = globalData->statesDerivatives[i];
		globalData->states[i] = backupstats[i] + (*step) * ( (1.0/6.0) * (k1[i] + 2 * k2[i] + 2* k3[i] + k4[i]));
	}
	f();
}

