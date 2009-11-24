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


void euler (DATA * data,
		double* step,
		int (*f)() // time
);

double TOL=0;

/* The main function for the explicit euler solver */
int euler_main( int argc, char** argv,double &start,  double &stop, double &step, long &outputSteps,
		double &tolerance)
{

	//double sim_time;
	
	//double tol = 1e-05
	globalData->timeValue = start;
	
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
	globalData->init=1;
	initial_function();
	if (initialize(init_method)) {
		throw TerminateSimulationException(globalData->timeValue,
				string("Error in initialization. Storing results and exiting.\n"));
	}
	
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


	//function_updateDependents();
	saveall();
	if(emit()) { printf("Error, not enough space to save data"); return -1; }
	
	//Enable all Events
	for (int i = 0; i < globalData->nZeroCrossing; i++) {
	   zeroCrossingEnabled[i] = 1;
	}
	
	// check for Event at Initial
	if (sim_verbose) { cout << "Checking events at initialization (at time "<< globalData->timeValue << ")." << endl; }
	if (CheckForNewEvent(NOINTERVAL))
		if(emit()) { printf("Error, not enough space to save data"); return -1; }	

	globalData->init=0;
	
	
	if (sim_verbose)  {
		cout << "Performed initial value calutation." << endl;
		cout << "Start numerical solver \"Euler\" from "<< globalData->timeValue << " to "<< stop << endl; 
	}

	while( globalData->timeValue <= stop){
	//for(globalData->timeValue=start; globalData->timeValue<= stop; globalData->timeValue+=step,pt++) {
	
		//TODO: calc new step size here
		
		globalData->timeValue+=step;
		
		// do one integration step
		euler(globalData,&step,functionODE);
		
		functionDAE_output();
		//functionDAE_output2();

		//Check for Events
		//if (sim_verbose) { cout << "Checking for new events (at time "<< globalData->timeValue << ")." << endl; }
		CheckForNewEvent(INTERVAL);
		//if (sim_verbose) { cout << "Check for new events done." << endl; }
		
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


void euler (DATA * data,
		double* step,
		int (*f)() // time
)
{
	setLocalData(data);	
	for(int i=0; i < data->nStates; i++) {
		data->states[i]=data->states[i]+data->statesDerivatives[i]*(*step); // Based on that, calculate state variables.
	}
	f(); // calculate equations
}
