/*
 * OpenModelica Interactive (Ver 0.7)
 * Last Modification: 17. January 2010
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiel y
 * Contact: vasaie_p@informatik.haw-hamburg.de
 *
 * File description: omi_ServiceInterface.cpp
 * An Interface is needed in order to support the modularization and information hiding
 * principles. The OM can be developed further, without respecting the OMI code.
 * The only restriction to developing OM and OMI is, to assure all functions in this interface will work
 * correctly and specified results won't change after further developing a component.
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

#include "omi_ServiceInterface.h"
#include "omi_Control.h"
#include "omi_Transfer.h"
#include "simulation_runtime.h"
#include "simulation_input.h"
#include "solver_dasrt.h"
#include "solver_euler.h"
#include "options.h"

//Global Data Mutex
Mutex gdMutex;

int argcTEMP = 0; //From main parameter argc
char** argvTEMP = 0; //From main parameter argv
double global_stepSize = 0.0;

/**
 * Initializes the service interface data
 * e.g. the used globalDataMutex
 * and the arguments of the simulation_runtime main function
 */
int initServiceInterfaceData(int argc, char**argv){
		//The arguments should be available globally, also in other classes
		argcTEMP = argc;
		argvTEMP = argv;

		return true;
}


/*****************************************************************
 * Communication direction from OMI --> OM 						 *
 *****************************************************************/

//************ Global Data Value Request and Manipulation ************

//****** Number of properties******

//NOTE: nStates is similar to nStateDerivatives
long get_NStates(void) {
	gdMutex.Lock();

	long temp_val = globalData->nStates;

	gdMutex.Unlock();

	return temp_val;
}

long get_NAlgebraic(void) {
	gdMutex.Lock();

	long temp_val = globalData->nAlgebraic;

	gdMutex.Unlock();

	return temp_val;
}

long get_NParameters(void) {
	gdMutex.Lock();

	long temp_val = globalData->nParameters;

	gdMutex.Unlock();

	return temp_val;
}

long get_NInputVars(void) {
	gdMutex.Lock();

	long temp_val = globalData->nInputVars;

	gdMutex.Unlock();

	return temp_val;
}

long get_NOutputVars(void) {
	gdMutex.Lock();

	long temp_val = globalData->nOutputVars;

	gdMutex.Unlock();

	return temp_val;
}

//****** END Number of properties******

//****** State Value, Name Request and Manipulation ******

void set_StateValue(int index, double value){
	gdMutex.Lock();

	globalData->states[index] = value;

	gdMutex.Unlock();
}

double get_StateValue(int index){
	gdMutex.Lock();

	double temp_val =  globalData->states[index];

	gdMutex.Unlock();

	return temp_val;
}

string get_StateName(int index){
	gdMutex.Lock();

	string temp_val =  globalData->statesNames[index];

	gdMutex.Unlock();

	return temp_val;
}

//****** StateDerivative Value, Name Request and Manipulation ******
void set_StateDerivativesValue(int index, double value){
	gdMutex.Lock();

	globalData->statesDerivatives[index] = value;

	gdMutex.Unlock();
}

double get_StateDerivativesValue(int index){
	gdMutex.Lock();

	double temp_val =  globalData->statesDerivatives[index];

	gdMutex.Unlock();

	return temp_val;
}

string get_StateDerivativesName(int index){
	gdMutex.Lock();

	string temp_val =  globalData->stateDerivativesNames[index];

	gdMutex.Unlock();

	return temp_val;
}

//****** Algebraic Value, Name Request and Manipulation ******
void set_AlgebraicValue(int index, double value){
	gdMutex.Lock();

	globalData->algebraics[index] = value;

	gdMutex.Unlock();
}

double get_AlgebraicValue(int index){
	gdMutex.Lock();

	double temp_val =  globalData->algebraics[index];

	gdMutex.Unlock();

	return temp_val;
}

string get_AlgebraicName(int index){
	gdMutex.Lock();

	string temp_val =  globalData->algebraicsNames[index];

	gdMutex.Unlock();

	return temp_val;
}

//****** Parameter Value, Name Request and Manipulation ******
void set_ParameterValue(int index, double value){
	gdMutex.Lock();

	globalData->parameters[index] = value;

	gdMutex.Unlock();
}

double get_ParameterValue(int index){
	gdMutex.Lock();

	double temp_val =  globalData->parameters[index];

	gdMutex.Unlock();

	return temp_val;
}

string get_ParameterName(int index){
	gdMutex.Lock();

	string temp_val =  globalData->parametersNames[index];

	gdMutex.Unlock();

	return temp_val;
}

//****** InputVariable Value, Name Request and Manipulation ******
void set_InputVarValue(int index, double value){
	gdMutex.Lock();

	globalData->inputVars[index] = value;

	gdMutex.Unlock();
}

double get_InputVarValue(int index){
	gdMutex.Lock();

	double temp_val =  globalData->inputVars[index];

	gdMutex.Unlock();

	return temp_val;
}

string get_InputVarName(int index){
	gdMutex.Lock();

	string temp_val =  globalData->inputNames[index];

	gdMutex.Unlock();

	return temp_val;
}

//****** OutputVariable Value, Name Request and Manipulation ******
void set_OutputVarValue(int index, double value){
	gdMutex.Lock();

	globalData->outputVars[index] = value;

	gdMutex.Unlock();

}

double get_OutputVarValue(int index){
	gdMutex.Lock();

	double temp_val =  globalData->outputVars[index];

	gdMutex.Unlock();

	return temp_val;
}

string get_OutputVarName(int index){
	gdMutex.Lock();

	string temp_val =  globalData->outputNames[index];

	gdMutex.Unlock();

	return temp_val;
}
//****** END Value, Name Request and Manipulation ******


//****** Simulation Status Request and Manipulation ******

double get_timeValue(void){
	gdMutex.Lock();

		double temp_let =  globalData->timeValue;

		gdMutex.Unlock();

		return temp_let;
}

void set_lastEmittedTime(double new_lastEmittedTime) {
	gdMutex.Lock();

	globalData->lastEmittedTime = new_lastEmittedTime;

	gdMutex.Unlock();
}


double get_lastEmittedTime(void) {
	gdMutex.Lock();

	double temp_let =  globalData->lastEmittedTime;

	gdMutex.Unlock();

	return temp_let;
}

void set_stepSize(double new_globalStepSize) {
	gdMutex.Lock();

	global_stepSize = new_globalStepSize;

	gdMutex.Unlock();
}

double get_stepSize(void) {
	gdMutex.Lock();

	double temp_let =  global_stepSize;

	gdMutex.Unlock();

	return temp_let;
}

void set_forceEmit(int new_forceEmit){
	gdMutex.Lock();

	globalData->forceEmit = new_forceEmit;

	gdMutex.Unlock();
}

int get_forceEmit(void){
	gdMutex.Lock();

	int fe = globalData->forceEmit;

	gdMutex.Unlock();

	return fe;
}
//****** END Simulation Status Request and Manipulation ******

//****** Request and Manipulate Data from GlobalData via SimulationStepData

void setGlobalSimulationValuesFromSimulationStepData(SimStepData* p_SimStepData){
	gdMutex.Lock();

	globalData->lastEmittedTime = p_SimStepData->forTimeStep; //is the lastEmittedTime of this step
	for (int i = 0; i < globalData->nStates; i++) {
		globalData->states[i] = p_SimStepData->states[i];
		globalData->statesDerivatives[i]
			= p_SimStepData->statesDerivatives[i];
	}
	for (int i = 0; i < globalData->nAlgebraic; i++) {
		globalData->algebraics[i] = p_SimStepData->algebraics[i];
	}
	for (int i = 0; i < globalData->nParameters; i++) {
		globalData->parameters[i] = p_SimStepData->parameters[i];
	}
	gdMutex.Unlock();
}

void fillSimulationStepDataWithValuesFromGlobalData(SimStepData* p_SimStepData) {

	gdMutex.Lock();

	p_SimStepData->forTimeStep = globalData->lastEmittedTime; //is the lastEmittedTime of this step
	for (int i = 0; i < globalData->nStates; i++) {
		p_SimStepData->states[i] = globalData->states[i];
		p_SimStepData->statesDerivatives[i]
				= globalData->statesDerivatives[i];
	}
	for (int i = 0; i < globalData->nAlgebraic; i++) {
		p_SimStepData->algebraics[i]
				= globalData->algebraics[i];
	}
	for (int i = 0; i < globalData->nParameters; i++) {
		p_SimStepData->parameters[i]
				= globalData->parameters[i];
	}

	gdMutex.Unlock();
}
//****** OPTIMIZATION ******

/* Because of Optimization while manipulating the whole global data structure
 * The mutex will only lock/unlock once
 * Kommentar: Normalerweise müsste für jede anfrage der Mutex gelocked werden und erneut frei gegeben
 * mit diesen methoden sorgen wir dafür, dass dies nur ein einziges mal geschiecht!
 */

void fillSimDataNames_AND_SimDataNamesFilter_WithValuesFromGlobalData(
		SimDataNames* p_simDataNames, SimDataNamesFilter* p_simDataNamesFilter) {
	gdMutex.Lock();

	int variablesNamesPos = 0;
	for (int i = 0; i < globalData->nStates; i++) {
		p_simDataNames->statesNames[i] = globalData->statesNames[i];
		p_simDataNamesFilter->variablesNames[variablesNamesPos] = "";
		p_simDataNames->stateDerivativesNames[i]
				= globalData->stateDerivativesNames[i];
		variablesNamesPos++;
	}
	for (int i = 0; i < globalData->nAlgebraic; i++) {
		p_simDataNames->algebraicsNames[i] = globalData->algebraicsNames[i];
		p_simDataNamesFilter->variablesNames[variablesNamesPos] = "";
		variablesNamesPos++;
	}
	for (int i = 0; i < globalData->nParameters; i++) {
		p_simDataNames->parametersNames[i] = globalData->parametersNames[i];
		p_simDataNamesFilter->parametersNames[i] = "";
	}
	gdMutex.Unlock();
}

//****** END OPTIMIZATION ******

/*
 * Calls the "read_input(...)" function from "simulation_input.cpp" and stores the simulation start data into
 * a set of variables from "omi_Calculation.cpp"
 */
void getSimulationStartData(double *stepSize, long *outputSteps,
		double *tolerance, string* method){

	double start = 0.0; //unnecessary for interactive simulation
	double stop = 1.0; //unnecessary for interactive simulation

	gdMutex.Lock();

	read_input(argcTEMP, argvTEMP, globalData, &start, &stop, stepSize,
			outputSteps, tolerance, method);

	gdMutex.Unlock();
}

//************ END Global Data Value Request and Manipulation ************

/*
 * Calls the solver which is selected in the parameter string "method"
 */
int callSolverFromOM(string method, double start, double stop, double stepSize,
		long outputSteps, double tolerance) {
	int retVal = -1;
	gdMutex.Lock();

	retVal = callSolver(argcTEMP, argvTEMP, method, start, stop, stepSize, outputSteps, tolerance);

	gdMutex.Unlock();
	return retVal;
}

/**
 * Bans working on Global Data, this is important for interrupting calculation and transfer threads
 * Otherwise one of the consumer or producer threads are still working on the GD and no changes could realized
 * while the simulation is paused or an error occurred...
 */
bool denied_work_on_GD(){
	gdMutex.Lock();
	return true;
}

bool allow_work_on_GD(){
	gdMutex.Unlock();

	return true;
}

/*****************************************************************
 * Communication direction from OM --> OMI 						 *
 *****************************************************************/

/**
 * Creates the Simulation Control Thread
 */
Thread* createControlThread(){
	//Create the Control Server Thread
	Thread *new_thread = new Thread();
	new_thread->Create(threadServerControl);
	return new_thread;
}

//************ Network Configuration Settings ************

/**
 * Sets the IP and Port of the control network client to user specific values
 * To use Default IP (localhost - 127.0.0.1) send an empty string as ip parameter ("")
 * Note: Call this function before starting simulation
 */
void setIPAndPortOfControlClient(string ip, int port) {
	setControlClientIPandPort(ip, port);
}

/**
 * Sets only the Port of the control network server to user specific value
 * The IP (localhost - 127.0.0.1) mustn't change
 * Note: Call this function before starting simulation
 */
void setPortOfControlServer(int port) {
	setControlServerPort(port);
}

/*
 * Note: Call this function before starting simulation
 */
void setIPandPortOfTransferClient(string ip, int port) {
	setTransferIPandPort(ip, port);
}

//TODO 20100217 pv Implement Reset of IP and Port.. necessary??

//************ END Network Configuration Settings ************

/*****************************************************************
 * Used from both subsystems 						 *
 *****************************************************************/


/**
 * Prints out the actual global data stored in the simulation_runtime.cpp
 * Only for debugging
 */
void printGlobalData(void) {
	gdMutex.Lock();

	cout << "OutPutGlobalData***********" << endl;
	cout << "lastEmittedTime: " << globalData->lastEmittedTime
			<< " --------------------" << endl;

	if (globalData->nStates > 0) {
		cout << "---States---" << endl;
		for (int t = 0; t < globalData->nStates; t++) {
			cout << t << ": " << globalData->statesNames[t] << ": "
					<< globalData->states[t] << endl;
		}
	}

	if (globalData->nAlgebraic > 0) {
		cout << "---Algebraics---" << endl;
		for (int t = 0; t < globalData->nAlgebraic; t++) {
			cout << t << ": " << globalData->algebraicsNames[t] << ": "
					<< globalData->algebraics[t] << endl;
		}
	}

	if (globalData->nParameters > 0) {
		cout << "---Parmeters--- " << endl;
		for (int t = 0; t < globalData->nParameters; t++) {
			cout << t << ": " << globalData->parametersNames[t] << ": "
					<< globalData->parameters[t] << endl;
		}
	}

	if (globalData->nInputVars > 0) {
		cout << "---InputVars--- " << endl;
		for (int t = 0; t < globalData->nInputVars; t++) {
			cout << t << ": " << globalData->inputNames[t] << ": "
					<< globalData->inputVars[t] << endl;
		}
	}

	if (globalData->nInputVars > 0) {
		cout << "---OutputVars--- " << endl;
		for (int t = 0; t < globalData->nOutputVars; t++) {
			cout << t << ": " << globalData->outputNames[t] << ": "
					<< globalData->outputVars[t] << endl;
		}
	}

	gdMutex.Unlock();
}
