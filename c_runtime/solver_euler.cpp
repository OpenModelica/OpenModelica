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


  string * result_file =(string*)getFlagValue("r",argc,argv);
  const char * result_file_cstr;
  if (!result_file) {
    result_file_cstr = string(string(globalData->modelName)+string("_res.plt")).c_str();
  } else {
    result_file_cstr = result_file->c_str();
  }
  if (deinitializeResult(result_file_cstr)) {
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
