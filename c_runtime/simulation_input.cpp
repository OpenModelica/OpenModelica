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

#include "simulation_input.h"
#include "simulation_runtime.h"
#include "options.h"

#include <fstream>
#include <iomanip>

using namespace std;

void read_commented_value( ifstream &f, double *res);
void read_commented_value( ifstream &f, int *res);
void read_commented_value(ifstream &f, string *str);
void read_commented_value(ifstream &f, char **str);


/* \brief
 *  Reads initial values from a text file.
 *  
 *  The textfile should be given as argument to the main function using 
 *  the -f file flag.
 */
 void read_input(int argc, char **argv,
 				DATA *simData, 
                double *start, double *stop,
                double *stepSize, long *outputSteps,
                double *tolerance, string* method)
{

  string *filename=(string*)getFlagValue("f",argc,argv);
  if (filename == NULL) { 
    filename = new string(string(simData->modelName)+"_init.txt");  // model_name defined in generated code for model.
  }

  ifstream file(filename->c_str());
  if (!file) { 
    cerr << "Error, can not read file " << filename 
	 << " as indata to simulation." << endl; 
    exit(-1);
  }
  //  cerr << "opened file" << endl;
  read_commented_value(file,start);
  if (sim_verbose) { cout << "read start = " << *start << " from init file." << endl; }
  read_commented_value(file,stop);
  if (sim_verbose) { cout << "read stop = " << *stop << " from init file." << endl; }
  read_commented_value(file,stepSize);
  if (sim_verbose) { cout << "read stepSize = " << *stepSize << " from init file." << endl; }
  if (stepSize < 0) { // stepSize < 0 => Automatic number of outputs 
  	*outputSteps = -1;
  } else {
  	// Calculate outputSteps from stepSize, start and stop
    *outputSteps = (long)(int(*stop-*start) /(*stepSize));
  }
  read_commented_value(file,tolerance);
  if (sim_verbose) { cout << "read tolerance = " << *tolerance << " from init file." << endl; }
  read_commented_value(file,method);
  if (sim_verbose) { cout << "read method = " << *method << " from init file." << endl; }
  int nxchk,nychk,npchk;
  int nystrchk,npstrchk;
  read_commented_value(file,&nxchk);
  read_commented_value(file,&nychk);
  read_commented_value(file,&npchk);
  read_commented_value(file,&npstrchk);
  read_commented_value(file,&nystrchk);
  	  
  if (nxchk != simData->nStates || nychk != simData->nAlgebraic || npchk != simData->nParameters 
  		|| npstrchk != simData->stringVariables.nParameters || nystrchk != simData->stringVariables.nAlgebraic ) {
    cerr << "Error, input data file does not match model." << endl;
    cerr << "nx in initfile: " << nxchk << " from model code :" << simData->nStates << endl;
    cerr << "ny in initfile: " << nychk << " from model code :" << simData->nAlgebraic << endl;
    cerr << "np in initfile: " << npchk << " from model code :" << simData->nParameters << endl;
	cerr << "npstr in initfile: " << npstrchk << " from model code: " << simData->stringVariables.nParameters << endl;
	cerr << "nystr in initfile: " << nystrchk << " from model code: " << simData->stringVariables.nAlgebraic <<  endl;    
    exit(-1);
  }
  for(int i = 0; i < simData->nStates; i++) { // Read x initial values  	
    read_commented_value(file,&simData->states[i]);
    if (sim_verbose) {
    cout << "read " << getName(&simData->states[i]) << " = " 
    	<< simData->states[i] << " from init file." << endl;
    }
  }
 for(int i = 0; i < simData->nStates; i++) { // Read der(x) initial values
    read_commented_value(file,&simData->statesDerivatives[i]);
    if (sim_verbose) {
    cout << "read " << getName(&simData->statesDerivatives[i]) << " = " 
    	<< simData->statesDerivatives[i] << " from init file." << endl;
    }
  }
 for(int i = 0; i < simData->nAlgebraic; i++) { // Read y initial values
    read_commented_value(file,&simData->algebraics[i]);
    if (sim_verbose) {
    cout << "read " << getName(&simData->algebraics[i]) << " = " 
    	<< simData->algebraics[i] << " from init file." << endl;
    }
  }
 for(int i = 0; i < simData->nParameters; i++) { // Read parameter values
    read_commented_value(file,&simData->parameters[i]);
    if (sim_verbose) {
    cout << "read" << getName(&simData->parameters[i]) << " = " 
    << simData->parameters[i] << " from init file." << endl;
    }
  }
  for(int i=0; i < simData->stringVariables.nParameters; i++) { // Read string parameter values
    read_commented_value(file,&simData->stringVariables.parameters[i]);
    if (sim_verbose) {
    cout << "read" <<simData->stringVariables.parameters[i] << " from init file." << endl;
    }
  }
  for(int i=0; i < simData->stringVariables.nAlgebraic; i++) { // Read string parameter values
    read_commented_value(file,&simData->stringVariables.algebraics[i]);
    if (sim_verbose) {
    cout << "read" <<simData->stringVariables.algebraics[i] << " from init file." << endl;
    }
  }
 file.close();
 if (sim_verbose) {
 	cout << "Read parameter data from file " << *filename << endl;
 }
}
inline void read_commented_value(ifstream &f, string *str)
{
	
	string line;
	char c[160];
  	f.getline(c,160);
  	line = c;
  	int pos;
	if (line.find("\"") != line.npos) {	
		pos = line.rfind("\""); // find end of string
		*str = string(line.substr(1,pos-1));	// Remove " at beginning and end
	}
}

inline void read_commented_value(ifstream &f, char **str)
{
	if (str == NULL) {
		cerr << "error read_commented_value, no data allocated for storing string" << endl;
		return;
	} 
	string line;
	read_commented_value(f,&line);
	*str = new char[line.length()+1];
	int i;
	for (i=0;i<(int)line.length();i++) {
		(*str)[i] = line.c_str()[i];	
	}
	(*str)[i]='\0';
	
	if (!str) {
		cerr << "Error reading string value from init file" << endl;
	}
}

inline void read_commented_value( ifstream &f, double *res)
{
  string line;
//  f >> *res;   
  char c[160];
  f.getline(c,160);
  line = c;

  if (line.find("true") != line.npos) {
	  *res = 1.0;
  }
  else if (line.find("false") != line.npos) {
	  *res = 0.0;
  }
  else {
    *res = atof(c);
  }
}

inline void read_commented_value( ifstream &f, int *res)
{
  f >> *res; 
  char c[160];
  f.getline(c,160);
}



