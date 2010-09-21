/*
 * OpenModelica Interactive (Ver 0.7)
 * Last Modification: 3. October 2009
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: vasaie_p@informatik.haw-hamburg.de
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
	double forTimeStep; //is the lastEmittedTime of this step
	double *states;//[4];
	double *statesDerivatives;//[4]; //xd DERIVATIVES
	double *algebraics;//[17];
	double *parameters;//[17];
} SimStepData;

typedef struct sdNames{
	string *statesNames;//[4];
	string *stateDerivativesNames;//[4];
	string *algebraicsNames;//[17];
	string *parametersNames;//[17];
} SimDataNames;

typedef struct sdNamesForTransfer{
	string *variablesNames;//[21]; //statesNames + algebraicsNames
	string *parametersNames;//[17]; //parametersNames
} SimDataNamesFilter;

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
bool deInitializeSSD_AND_SRDF(long, long, long);
bool getResultData(SimStepData*);
bool setResultData(SimStepData*);
SimStepData* getResultDataForTime(double, double);
SimStepData* getResultDataFirstStart();

void resetSRDFAfterChangetime(void);//Resets the SRDF Array and the producer and consumer semaphores, so the Transfer wont send old results after changing the time
void resetSSDArrayWithNullSSD(void);
void lockMutexSSD(void);
void releaseMutexSSD(void);
double getMinTime_inSSD(void);
double getMaxTime_inSSD(void);
