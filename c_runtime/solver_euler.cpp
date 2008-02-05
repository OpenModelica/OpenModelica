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

#include "solver_dasrt.h"
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

/* The main function for the explicit euler solver */
int euler_main( int argc, char** argv,double &start,  double &stop, double &step, long &outputSteps,
                double &tolerance)
{
  
  double sim_time;

  if (argc == 2 && flagSet("?",argc,argv)) {
    cout << "usage: " << argv[0]  << " <-f initfile> <-r result file> -m solver:{dassl, euler}" << endl;
    exit(0);
  }            
  
  long numpoints = long((stop-start)/step)+2;
  
  // allocate data for storing results.
  
 if (initializeResult(5*numpoints,globalData->nStates,globalData->nAlgebraic,globalData->nParameters)) {
  	cout << "Internal error, allocating result data structures"  << endl;
    return -1;
  }

 if(bound_parameters()) {
   printf("Error calculating bound parameters\n");
   return -1;
 }
 if (sim_verbose) { cout << "Calculated bound parameters" << endl; }   
 
  // Calculate initial values from (fixed) start attributes 
  globalData->init=1;
  initial_function();
  globalData->init=0; 
  
  if (sim_verbose)  { 
  	cout << "Performed initial value calutation." << endl; 
  	cout << "Starting numerical solver at time "<< start << endl;
  }
  	
  int npts_per_result=int((stop-start)/(step*(numpoints-2)));
  int pt=0;
  for(sim_time=start; sim_time <= stop; sim_time+=step,pt++) {

   
    euler(globalData,&step,functionODE);


    /* Calculate the output variables */
    functionDAE_output();

    if (pt % npts_per_result == 0 || sim_time+step > stop) { // store result
      emit();
    }
  } 

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
  f(); // calculate equations
  for(int i=0; i < data->nStates; i++) {
    data->states[i]=data->states[i]+data->statesDerivatives[i]*(*step); // Based on that, calculate state variables.
  }
}
