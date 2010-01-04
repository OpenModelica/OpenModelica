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

double TOL=0;

/* The main function for the explicit euler solver */
int euler_main( int argc, char** argv,double &start,  double &stop, double &step, long &outputSteps,
		double &tolerance,int flag)
{

	//double sim_time;
	int dideventstep = 0;
	double laststep = 0;
	globalData->oldTime = start;
	
	if (tolerance!=0) TOL = tolerance;
	//to get debug output with more precision 
	if (sim_verbose) cout.precision(13);


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

	// Calculate initial values from (fixed) start attributes
	// TODO: Check the intialisation
	
	globalData->init=1;
	initial_function();
	saveall();
	emit();
	
	if (initialize(init_method)) {
		throw TerminateSimulationException(globalData->timeValue,
				string("Error in initialization. Storing results and exiting.\n"));
	}
	saveall();
	if(emit()) { printf("Error, not enough space to save data"); return -1; }

	/*
	//Calculate initial derivatives
	if(functionODE()) {
		throw TerminateSimulationException(globalData->timeValue,string("Error calculating initial derivatives\n"));
	}
	//Calculate initial output values
	if(functionDAE_output() || functionDAE_output2()) {
		throw TerminateSimulationException(globalData->timeValue,
			string("Error calculating initial derivatives\n"));
	}
	cout << "Calculated function_ODE and functionsDAE_output (at time "<< globalData->timeValue << ")." << endl;
	*/
	function_updateDepend();
	saveall();
	if(emit()) { printf("Error, not enough space to save data"); return -1; }
	
	//Enable all Events
	for (int i = 0; i < globalData->nZeroCrossing; i++) {
	   zeroCrossingEnabled[i] = 1;
	}
	
	// check for Event at Initial
	if (sim_verbose) { cout << "Checking events at initialization (at time "<< globalData->timeValue << ")." << endl; }
	if (CheckForNewEvent(NOINTERVAL)){
		saveall();
		if(emit()) { printf("Error, not enough space to save data"); return -1; }
	}	
	globalData->init=0;
	
	
	if (sim_verbose)  {
		cout << "Performed initial value calutation." << endl;
		cout << "Start numerical solver from "<< globalData->timeValue << " to "<< stop << endl; 
	}

	while( globalData->timeValue <= stop){
	//for(globalData->timeValue=start; globalData->timeValue<= stop; globalData->timeValue+=step,pt++) {
	
		//TODO: calc new step size here
		if (dideventstep == 1){
			globalData->timeValue += (step-globalData->timeValue+laststep);
			dideventstep = 0;
		}else{
			globalData->timeValue+=step;
		}
		// do one integration step
		if (flag == 1) euler_ex_step(&step,functionODE);
		else if (flag == 2) rungekutta_step(&step,functionODE);
		else euler_ex_step(&step,functionODE);
		
		functionDAE_output();

		//Check for Events
		if (sim_verbose) { cout << "Checking for new events (at time "<< globalData->timeValue << ")." << endl; }
		if (CheckForNewEvent(INTERVAL) == 2){
			dideventstep = 1;
			if (sim_verbose) cout << "Go to Event time h_e" << endl;
		}else{
			laststep = globalData->timeValue;
			if (sim_verbose) cout << "Did Odinary step" << endl;
		}
			
		
		if (sim_verbose) { cout << "Check for new events done." << endl; }
		
		// Emit this timestep
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

