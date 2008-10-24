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

/*
 * File: simulation_runtime.h
 *
 * Description: This file is a C++ header file for the simulation runtime.
 * It contains solver functions and other simulation runtime specific functions
 *
 */

#ifndef _SIMULATION_RUNTIME_H
#define _SIMULATION_RUNTIME_H

#include "simulation_events.h"

#include <stdlib.h>
#include <fstream>
#include <iostream>


using namespace std;

// To retrive the last two values of a variable.
double old(double*);
double old2(double*);

extern int sim_verbose; // control debug output during simulation.
extern int acceptedStep; // !=0 when accepted step is calculated, 0 otherwise.
extern int modelTermination; //// Becomes non-zero when user terminates simulation.

/* Flags for controlling logging to stdout */
extern const int LOG_EVENTS;
extern const int LOG_NONLIN_SYS;
extern const int LOG_DEBUG;

/* Flags for modelErrorCodes */
extern const int ERROR_NONLINSYS;
extern const int ERROR_LINSYS;

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

  // Old values used for extrapolation
  double* oldStates,*oldStates2;
  double* oldStatesDerivatives,*oldStatesDerivatives2;
  double* oldAlgebraics,*oldAlgebraics2;
  double oldTime,oldTime2;

  char* initFixed; // Fixed attribute for all variables and parameters
  int init; // =1 during initialization, 0 otherwise.
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
  double lastEmittedTime; // The last time value that has been emitted.
  int forceEmit; // when != 0 force emit, set e.g. by newTime for equidistant output signal.
} DATA;

/* Global data */
extern DATA *globalData;


extern long numpoints;
extern int modelErrorCode;

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

// defined in model code. Used to get name of variable by investigating its pointer in the state or alg vectors.
char* getName(double* ptr);

void storeExtrapolationData();

// function for calculating ouput values
/*used in DDASRT fortran function*/
int
functionDAE_output();

/* Function for calculating discrete variables, called when event has occured
to get new values of discrete varibles*/
int
functionDAE_output2();

// function for calculating state values on residual form
/*used in DDASRT fortran function*/
int
functionDAE_res(double *t, double *x, double *xprime, double *delta, long int *ires, double *rpar, long int* ipar);


int
function_updateDependents();

// function for calculating states on explicit ODE form
/*used in functionDAE_res function*/
int functionODE();

// function for calculate initial values from initial equations
// and fixed start attibutes
int initial_function();

// function for calculating bound parameters that depend on other
// parameters, e.g. parameter Real n=1/m;
int bound_parameters();

// function for calculate residual values for the initial equations
// and fixed start attibutes
int initial_residual();

double newTime(double t, double step,double stop);

#define MODELICA_ASSERT(cond,msg) do { if (!(cond)&& acceptedStep) { modelTermination=1; \
throw TerminateSimulationException(string(msg)); } } while(0)

#define MODELICA_TERMINATE(msg) do { modelTermination=1; \
throw TerminateSimulationException(string(msg)); } } while(0)

#define initial() localData->init

#include <string>

/* \brief This class is used for throwing an exception when simulation code should be terminated.
 * For instance, when a terminate call occurse or if an assert becomes active
 */

class TerminateSimulationException {
 public:
 	TerminateSimulationException(std::string msg) : currentTime(0.0), errorMessage(std::string(msg)) {} ;
	TerminateSimulationException(double time) : currentTime(time), errorMessage(std::string("")) {} ;
	TerminateSimulationException(double time, std::string msg) : currentTime(time), errorMessage(msg) {};
	TerminateSimulationException() : currentTime(0.0) {};
	~TerminateSimulationException() {};
	std::string getMessage() { return errorMessage; };
	double getTime() { return currentTime; };
	private :
	double currentTime;
	std::string errorMessage;
};

#endif
