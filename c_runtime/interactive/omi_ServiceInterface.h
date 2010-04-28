/*
 * OpenModelica Interactive (Ver 0.7)
 * Last Modification: 17. January 2010
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: vasaie_p@informatik.haw-hamburg.de
 *
 * File description: omi_ServiceInterface.h
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

#include <string>
#include <limits>
#include <list>
#include <math.h>
#include <iomanip>
#include <stdio.h>
#include <iostream>
#include <cstdlib>
#include <sstream>

#include "thread.h"
#include "omi_ResultManager.h"

using namespace std;

//#ifndef _MY_SERVICEINTERFACE_H
#define _MY_SERVICEINTERFACE_H

int initServiceInterfaceData(int, char**);

//************ Global Data Value Request and Manipulation ************

//****** Number of properties ******
long get_NStates(void);
long get_NAlgebraic(void);
long get_NParameters(void);
long get_NInputVars(void);
long get_NOutputVars(void);
//****** END Number of properties ******

//****** Value, Name Request and Manipulation ******
void set_StateValue(int, double);
double get_StateValue(int);
string get_StateName(int);

//****** StateDerivative Value, Name Request and Manipulation ******
void set_StateDerivativesValue(int, double);
double get_StateDerivativesValue(int);
string get_StateDerivativesName(int);

//****** Algebraic Value, Name Request and Manipulation ******
void set_AlgebraicValue(int, double);
double get_AlgebraicValue(int);
string get_AlgebraicName(int);

//****** Parameter Value, Name Request and Manipulation ******
void set_ParameterValue(int, double);
double get_ParameterValue(int);
string get_ParameterName(int);

//****** InputVariable Value, Name Request and Manipulation ******
void set_InputVarValue(int, double);
double get_InputVarValue(int);
string get_InputVarName(int);

//****** OutputVariable Value, Name Request and Manipulation ******
void set_OutputVarValue(int, double);
double get_OutputVarValue(int);
string get_OutputVarName(int);

//****** END Value, Name Request and Manipulation ******

double get_timeValue(void);
void set_lastEmittedTime(double);
double get_lastEmittedTime(void);

void set_stepSize(double);
double get_stepSize(void);

void set_forceEmit(int);
int get_forceEmit(void);

void setGlobalSimulationValuesFromSimulationStepData(SimStepData*);
void fillSimulationStepDataWithValuesFromGlobalData(SimStepData*);
void fillSimDataNames_AND_SimDataNamesFilter_WithValuesFromGlobalData(
		SimDataNames*, SimDataNamesFilter*);

//************ END Global Data Value Request and Manipulation ************

/*
 * Calls the "read_input(...)" function from "simulation_input.cpp" and stores the simulation start data into
 * a set of variables from "omi_Calculation.cpp"
 */
void getSimulationStartData(double*, long*, double*, string*);

int callSolverFromOM(string, double, double, double, long, double);

bool denied_work_on_GD();
bool allow_work_on_GD();

Thread* createControlThread();

//************ Network Configuration Settings ************
void setIPAndPortOfControlClient(string, int);
void setPortOfControlServer(int);
void setIPandPortOfTransferClient(string, int);
//************ END Network Configuration Settings ************

void printGlobalData(void);
