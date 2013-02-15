/*
 * OpenModelica Interactive (Ver 0.75)
 * Last Modification: 23. May 2011
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: Parham.Vasaiely@eads.com
 *
 * File description: omi_ResultManager.h
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

#include <string>
#include "thread.h"
using namespace std;

//#ifndef _MY_SIMULATIONRESULT_H
#define _MY_SIMULATIONRESULT_H

typedef struct ssd{ //SimulationStepData struct
       double forTimeStep; //is the lastEmittedTime or timeValue of this step
       double *states;
       double *statesDerivatives; //xd DERIVATIVES
       double *algebraics;
       double *parameters;
} SimStepData;

//Property Names of model simulation data (state, algebraic, variables)
typedef struct sdNames{
       string *statesNames;
       string *stateDerivativesNames;
       string *algebraicsNames;
       string *parametersNames;
} SimDataNames;

//Model property names used to be transfered to a client
typedef struct sdNamesForTransfer{
       string *variablesNames; //statesNames + algebraicsNames
       string *parametersNames; //parametersNames
} SimDataNamesFilter;

//Number of property values
typedef struct nValues{
       long nStates;
       long nAlgebraic;
       long nParameters;
} SimDataNumbers, *P_SimDataNumbers;

extern SimDataNames* p_simDataNames_SimulationResult;
extern SimDataNamesFilter* p_simDataNamesFilterForTransfer;
extern P_SimDataNumbers p_simdatanumbers;

extern Mutex* p_sdnMutex;

bool initializeSSD_AND_SRDF(long, long, long);
bool deInitializeSSD_AND_SRDF(void);
bool getResultData(SimStepData*);
bool setResultData(SimStepData*);
SimStepData* getResultDataForTime(double, double);
SimStepData* getResultDataFirstStart(void);

//Resets the SRDF Array and the producer and consumer semaphores, so the Transfer wont send old results after changing the time
void resetSRDFAfterChangetime(void);
void resetSSDArrayWithNullSSD(long, long, long);
void lockMutexSSD(void);
void releaseMutexSSD(void);
/*
 * Returns the minimum time stored in the SSDArray
 */
double getMinTime_inSSD(void);
/*
 * Returns the maximum time stored in the SSDArray
 */
double getMaxTime_inSSD(void);
/*
 * use this method after a change time or value operation from control
 * to signal a changed time to the simulation
 */
void setSimulationTimeReversed(double);
