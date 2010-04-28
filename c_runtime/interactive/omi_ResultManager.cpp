/*
 * OpenModelica Interactive (Ver 0.7)
 * Last Modification: 11. January 2010
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: vasaie_p@informatik.haw-hamburg.de
 *
 * File description: omi_ResultManager.cpp
 * While a simulation is running the “Calculation” thread produces simulation results for every time step,
 * and the “Transfer” thread sends the single results to a client.
 * There is a need for synchronization and organisation of simulation results.
 * However, the application cannot store all results because this would cause the system to run out of memory.
 * This scenario is the typical “producer and consumer problem with restricted buffer”,
 * which is well known in IT science.
 * The “ResultManager” assumes responsibility for organizing simulation result data and
 * synchronizing access to these data.
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

#include <iomanip>
#include <stdio.h>
#include <iostream>
#include "omi_ResultManager.h"

using namespace std;

#define MAX_SSD 200 //Maximum number of Simulation Step Data elements
#define MAX_SRDF 20 //Maximum number of Simulation Result Data for Forwarding
bool debugResultManager = false; //Set true to print out comments which describes the program flow to the console
bool firstRun = true; //This element signalizes that the simulation runs for the first time. It is important to store data into the "simulationStartSSD"

SimStepData nullSSD; //this SimStepData element represents a null element in the SSD Array
SimStepData simulationStartSSD; //this SimStepData element represents the state at the simulation start, it is necessary to save because of the method reInitAll in control
SimStepData* p_simulationStartSSD;
//***** SimStepData buffer *****
SimStepData ssdArray[MAX_SSD] = { 0 };

SimStepData* p_ssdArray_NextFreeSlot = 0; //Points on the next free slot
/* p_last_ssdArray_slot points on the last array slot, if the set
 * method reached this address the pointer have to point to the first slot of the array
 */
SimStepData* p_ssdArray_LastSlot = 0;

//***** SimStepData for forwading buffer (SimulationResultDataForwarding)*****

/*
 * This array contains pointers from the type SimStepData, which points on elements
 * in the ssdArray, so there is much less redundancy
 *
 * Note: All pointers which points an this array have to be pointers from pointers
 */
SimStepData* srdfArrayOfPointer[MAX_SRDF] = { 0 };

SimStepData** pp_srdfArray_FirstQueueElement = 0;//Points on the smallest time step pointer
SimStepData** pp_srdfArray_NextFreeSlot = 0; //Points on the next free slot from SRDF Array to insert an element
SimStepData** pp_srdfArray_LastSlot = 0;

//***** SimDataNames Contains all Variable, Algebraic and State names*****
SimDataNames simDataNames_SimulationResult;
SimDataNames* p_simDataNames_SimulationResult = 0;

SimDataNamesFilter simDataNamesFilterForTransfer;
SimDataNamesFilter* p_simDataNamesFilterForTransfer = 0;

SimDataNumbers simdatanumbers;
P_SimDataNumbers p_simdatanumbers = 0;
//***** Objects for synchronization
Mutex ssdMutex;

Semaphore ghSemaphore_NumberUsedSlots(0, MAX_SRDF);
Semaphore ghSemaphore_NumberFreeSlots(MAX_SRDF, MAX_SRDF);
//Mutex for simdatanumbers synchronization
Mutex sdnMutex;
Mutex* p_sdnMutex;

//void reInitSSD_A();
//bool deinitializeAll();
//SSD Organisation
void addDataToSSD(SimStepData*);
void pointNextFreeSSDSlot();
//SRDF Organisation
void pointNextFreeSRDFSlot();
void pointNextUsedSRDFSlot();
void pushSRDF();
void popSRDF(SimStepData*);

//print methods for testing
void printSSD();
void printSRDF();


/*****************************************************************
 * Organisation and Management of SSD, SRDF, SimDataNames...
 * e.g. Parameters, Variables, Simulation Setup...
 * Initialization for simulation data
 *****************************************************************/
bool initializeSSD_AND_SRDF(long nStates, long nAlgebraic, long nParameters) {
	bool retValue = true;
	//if(debugResultManager) cout << "initializeSSD_AND_SRDF" << endl;
	//simDataNames_SimulationResult will be initialize from the SimulationControl

	nullSSD.forTimeStep = -1; //if the forTimeStep is -1 the element is null

	double *statesTMP1 = new double[nStates];
	double *statesDerivativesTMP1 = new double[nStates];
	double *algebraicsTMP1 = new double[nAlgebraic];
	double *parametersTMP1 = new double[nParameters];
	nullSSD.states = statesTMP1;
	nullSSD.statesDerivatives = statesDerivativesTMP1;
	nullSSD.algebraics = algebraicsTMP1;
	nullSSD.parameters = parametersTMP1;
	resetSSDArrayWithNullSSD();

	p_simulationStartSSD = &simulationStartSSD;
	double *statesTMP2 = new double[nStates];
	double *statesDerivativesTMP2 = new double[nStates];
	double *algebraicsTMP2 = new double[nAlgebraic];
	double *parametersTMP2 = new double[nParameters];
	p_simulationStartSSD->states = statesTMP2;
	p_simulationStartSSD->statesDerivatives = statesDerivativesTMP2;
	p_simulationStartSSD->algebraics = algebraicsTMP2;
	p_simulationStartSSD->parameters = parametersTMP2;

	//p_ssdArray_NextFreeSlot = ssdArray; //Done from resetSSDArrayWithNull...
	p_ssdArray_LastSlot = &ssdArray[MAX_SSD - 1];

	pp_srdfArray_FirstQueueElement = srdfArrayOfPointer;
	pp_srdfArray_NextFreeSlot = srdfArrayOfPointer;
	pp_srdfArray_LastSlot = &srdfArrayOfPointer[MAX_SRDF - 1];

	p_simdatanumbers = &simdatanumbers;
	p_simdatanumbers->nStates = nStates;
	p_simdatanumbers->nAlgebraic = nAlgebraic;
	p_simdatanumbers->nParameters = nParameters;

	/*	int *dyn;
	 dyn = new int [2];
	 dyn[0]=4;
	 dyn[1]=2;
	 cout << dyn[0] + dyn[1]<< endl;
	 */

	p_simDataNames_SimulationResult = &simDataNames_SimulationResult;
	p_simDataNamesFilterForTransfer = &simDataNamesFilterForTransfer;

	/*
	 * Dynamic definition of struct data
	 */
	string *statesNamesTMP = new string[nStates];
	string *stateDerivativesNamesTMP = new string[nStates];
	string *algebraicsNamesTMP = new string[nAlgebraic];
	string *parametersNames1TMP = new string[nParameters];
	p_simDataNames_SimulationResult->statesNames = statesNamesTMP;
	p_simDataNames_SimulationResult->stateDerivativesNames
			= stateDerivativesNamesTMP;
	p_simDataNames_SimulationResult->algebraicsNames = algebraicsNamesTMP;
	p_simDataNames_SimulationResult->parametersNames = parametersNames1TMP;
	//****
	string *variablesNamesTMP = new string[nStates + nAlgebraic];
	string *parametersNames2TMP = new string[nParameters];
	p_simDataNamesFilterForTransfer->variablesNames = variablesNamesTMP;
	p_simDataNamesFilterForTransfer->parametersNames = parametersNames2TMP;
	//****
	p_sdnMutex = &sdnMutex;

	//if(debugResultManager) cout << "END initializeSSD_AND_SRDF" << endl;
	return retValue;
}

bool deInitializeSSD_AND_SRDF() {

	return true;
}

/*****************************************************************
* Getter and Setter from the Interface ResultManager.h
*****************************************************************/

P_SimDataNumbers getSimDataNumbers(void) {
	return p_simdatanumbers;
}

/**
 * Reads the SimStepData from a Calculation thread and adds it to the intern SSD buffer and the SRDF buffer.
 * parameter: pointer from type SimStepData, it points on a data struct in a Calculation thread
 */
bool setResultData(SimStepData* p_SimStepData_from_Calculation) {
	bool retValue = true;

	//cout << "p_ssdArray_NextFreeSlot: " << p_ssdArray_NextFreeSlot << endl;

	if (debugResultManager)
		cout << "RS1" << endl;
	/*
	 * This part is necessary for the producer &consumer problem with districted buffer
	 * The any entity which want to use the array must pas this part
	 */
	// Try to enter the ghSemaphore_NumberFreeSlots gate.
	ghSemaphore_NumberFreeSlots.Wait();
	ssdMutex.Lock();
	/********************************************************************
	 * Entity has pas the synchronization station and can work on the SSD buffer
	 */
	if (debugResultManager)
		cout << "RS2" << endl;
	addDataToSSD(p_SimStepData_from_Calculation);
	if (debugResultManager)
		cout << "RS3" << endl;
	//printSSD();
	//printSRDF();
	//Work on SSD and SRDF buffer ended **********************************

	// Release the mutex
	if (!ssdMutex.Unlock()) {
		//printf("ReleaseMutex ssdMutex error: %d\n", GetLastError());
		return false;
	}
	//if(debugResultManager) cout << "set released mutex" << endl;
	if (debugResultManager)
		cout << "RS4" << endl;
	// Release the semaphore ghSemaphore_NumberUsedSlots
	/*if (!ReleaseSemaphore(ghSemaphore_NumberFreeSlots, // handle to semaphore
	 0, // increase count by zero because this will done for the external variable
	 NULL)) // not interested in previous count
	 {
	 //printf("ReleaseSemaphore ghSemaphore_NumberUsedSlots error: %d\n", GetLastError());
	 return false;
	 }*/
	if (debugResultManager)
		cout << "RS5" << endl;
	ghSemaphore_NumberUsedSlots.Post();
	//if(debugResultManager) cout << "RS6" << endl;

	if (debugResultManager)
		cout << "RS Proof: " << p_SimStepData_from_Calculation->forTimeStep
				<< endl;
	return retValue;
}

/**
 * Fills the SimStepData from a Transfer thread with the first simulation result from the SRD queue
 * This method won't filter the data, all existing and available parameter, algebraic and states will be saved.
 * parameter: pointer from type SimStepData, it points on a data struct in a Transfer thread
 */
bool getResultData(SimStepData* p_SimResDataForw_from_Transfer){
	bool retValue = true;

	//cout << "getResultData" << endl;

	/*
	 * This part is necessary for the producer &consumer problem with districted buffer
	 * The any entity which want to use the array must pas this part
	 */
	if(debugResultManager) cout << "RG1" << endl;

	ghSemaphore_NumberUsedSlots.Wait();
	ssdMutex.Lock();

	/********************************************************************
	 * Entity has pas the synchronization station and can work on the SSD buffer
	 */
	if(debugResultManager) cout << "RG2" << endl;
	//if(debugResultManager) cout << "SimResDataForw_from_Transfer address: " << p_SimResDataForw_from_Transfer << endl;
	//if(debugResultManager) cout << "popSRDF" << endl;
	popSRDF(p_SimResDataForw_from_Transfer);
	if(debugResultManager) cout << "RG3" << endl;
	//********************************************************************

	// Release the mutex
	ssdMutex.Unlock();
	ghSemaphore_NumberFreeSlots.Post();

	if(debugResultManager) cout << "RG Proof: " << p_SimResDataForw_from_Transfer->forTimeStep << endl;
	return retValue;
}

/**
 * The SSD array is divided by the NextFreeSlot pointer in two parts.
 * e.g. Part A is the higher leveled part containing the highest SimStepData and Part B containing the lowest SimStepData.
 * -------------------
 * |8|9|10|11|4|5|6|7|
 * -------------------
 * 		A	 |	 B
 * the NextFreeSlot pointer points on the element with at the time "4", so we need two different searching algorithms
 * for each part.
 *
 * Return: If the searched step time is not stored in the ssd, the method returns a pointer which points an nullSSD
 * otherwise it points on the searched element
 */
SimStepData* getResultDataForTime(double stepSize, double timeStep) {

	if(debugResultManager) cout << "All SSD Array elements" << endl;
	for(int i=0;i < MAX_SSD;i++){
		if(debugResultManager) cout << ssdArray[i].forTimeStep << endl;
	}
	if(debugResultManager) cout << "END All SSD Array elements" << endl;


	SimStepData* temp;

	if (debugResultManager)
		cout << "ADD of p_ssdArray_NextFreeSlot: " << p_ssdArray_NextFreeSlot
				<< endl;
	if (debugResultManager)
		cout << "p_ssdArray_NextFreeSlot: "
				<< p_ssdArray_NextFreeSlot->forTimeStep << endl;
	if (debugResultManager)
		cout << "p_ssdArray_NextFreeSlot-1: "
				<< (p_ssdArray_NextFreeSlot - 1)->forTimeStep << endl;
	if (debugResultManager)
			cout << "timeStep: " << timeStep << endl;

	//check if the searched time step is available in simulationstepdata (ssd)
	if (timeStep == p_ssdArray_NextFreeSlot->forTimeStep ||  (timeStep > p_ssdArray_NextFreeSlot->forTimeStep && timeStep
			<= (p_ssdArray_NextFreeSlot - 1)->forTimeStep)) {

		SimStepData* firstSSD_Element = ssdArray;

		//If this query returns true we have to search in Part B, because the time step is smaller than the lowest ssd in Part A
		if (timeStep < firstSSD_Element->forTimeStep) {
			temp = static_cast<int> (((timeStep
					- p_ssdArray_NextFreeSlot->forTimeStep) / stepSize)
					+ 0.0001) + p_ssdArray_NextFreeSlot; //+0.0001 is needed because of type cast and vision from int and double
			if (debugResultManager)
				cout
						<< "getResultDataForTime search in Part B temp->forTimeStep: "
						<< temp->forTimeStep << endl;
			return temp;
		} else {
			temp = static_cast<int> (((timeStep
					- firstSSD_Element->forTimeStep) / stepSize) + 0.0001) //+0.0001 is important while casting from double to integer
					+ firstSSD_Element;
			if (debugResultManager)
				cout
						<< "getResultDataForTime search in Part A temp->forTimeStep: "
						<< temp->forTimeStep << endl;
			return temp;
		}
	} else {
		temp = &nullSSD;
		if (debugResultManager)
			cout << "error time not in ssd" << endl;
	}
	return temp;
}


SimStepData* getResultDataFirstStart(){
	return p_simulationStartSSD;
}
/*****************************************************************
* Help Methods
*****************************************************************/

/**
 * After changing simulation parameters or starting the simulation from beginning, the SRDF Organisation must start again from the beginning. Because old simulation data mustn't send to the GUI.
 */
void resetSRDFAfterChangetime() {
	if (debugResultManager)
		cout << "***resetSRDFAfterChangetime" << endl;

	pp_srdfArray_FirstQueueElement = srdfArrayOfPointer;
	pp_srdfArray_NextFreeSlot = srdfArrayOfPointer;

	while(ghSemaphore_NumberUsedSlots.TryWait())
	{
		ghSemaphore_NumberFreeSlots.Post();
	}

	if (debugResultManager)
		cout << "***resetSRDFAfterChangetime END" << endl;
}

/**
 * If the simulation has to start again from the beginning
 * The SSD array has to reset with nullSSD elements
 */
void resetSSDArrayWithNullSSD() {
	p_ssdArray_NextFreeSlot = ssdArray;
	for (int i = 0; i < MAX_SSD; i++) {
		ssdArray[i] = nullSSD;
		//if(debugResultManager) cout << ssdArray[i].forTimeStep << endl;
	}
}

void lockMutexSSD() {
	ssdMutex.Lock();
}

void releaseMutexSSD() {
	ssdMutex.Unlock();
}

double getMinTime_inSSD() {
	return p_ssdArray_NextFreeSlot->forTimeStep;
}

double getMaxTime_inSSD() {
	return (p_ssdArray_NextFreeSlot - 1)->forTimeStep;
}
/*****************************************************************
* Organisation of SSD
*****************************************************************/

/**
 * Adds result data to the SSD Array and tries to add a pointer on it into the SRDF Array
 */
void addDataToSSD(SimStepData* p_SimStepData_from_Calculation) {

	p_ssdArray_NextFreeSlot->forTimeStep
			= p_SimStepData_from_Calculation->forTimeStep; //is the lastEmittedTime of this step
	if (firstRun)
		p_simulationStartSSD->forTimeStep
				= p_SimStepData_from_Calculation->forTimeStep;

	for (int i = 0; i < p_simdatanumbers->nStates; i++) {
		p_ssdArray_NextFreeSlot->states[i]
				= p_SimStepData_from_Calculation->states[i];
		if (firstRun)
			p_simulationStartSSD->states[i]
					= p_SimStepData_from_Calculation->states[i];
		p_ssdArray_NextFreeSlot->statesDerivatives[i]
				= p_SimStepData_from_Calculation->statesDerivatives[i];
		if (firstRun)
			p_simulationStartSSD->statesDerivatives[i]
					= p_SimStepData_from_Calculation->statesDerivatives[i];
	}

	for (int i = 0; i < p_simdatanumbers->nAlgebraic; i++) {
		p_ssdArray_NextFreeSlot->algebraics[i]
				= p_SimStepData_from_Calculation->algebraics[i];
		if (firstRun)
			p_simulationStartSSD->algebraics[i]
					= p_SimStepData_from_Calculation->algebraics[i];
	}

	for (int i = 0; i < p_simdatanumbers->nParameters; i++) {
		p_ssdArray_NextFreeSlot->parameters[i]
				= p_SimStepData_from_Calculation->parameters[i];
		if (firstRun)
			p_simulationStartSSD->parameters[i]
					= p_SimStepData_from_Calculation->parameters[i];
	}

	firstRun = false;
	//If a simulation result pushed into SSD it also have to push into the SRDF buffer
	pushSRDF();
	pointNextFreeSSDSlot();
}

/**
 * This method points the p_ssdArrayFreeSlot pointer to the next free slot from the SSD array
 * If the last slot is reached it will point p_ssdArrayFreeSlot to the first element from the SSD array
 * otherwise to the next higher index
 */
void pointNextFreeSSDSlot() {
	//cout << "pointNextFreeSSDSlot: p_ssdArray_NextFreeSlot " << p_ssdArray_NextFreeSlot->forTimeStep << endl;
	if (p_ssdArray_NextFreeSlot != p_ssdArray_LastSlot) {

		p_ssdArray_NextFreeSlot++;
	} else {
		p_ssdArray_NextFreeSlot = ssdArray;
	}
}

/*
 * Organisation of SRDF
 ************************************************************
 */

/**
 * This method points the pp_srdfArray_NextFreeSlot pointer to the next free slot from the SRDF array
 * If the last slot is reached it will point pp_srdfArray_NextFreeSlot to the first element from the SRDF array
 * otherwise to the next higher index
 */
void pointNextFreeSRDFSlot() {
	if (pp_srdfArray_NextFreeSlot != pp_srdfArray_LastSlot) {
		pp_srdfArray_NextFreeSlot++;
	} else {
		pp_srdfArray_NextFreeSlot = srdfArrayOfPointer;
	}
}

void pointNextUsedSRDFSlot() {
	if (pp_srdfArray_FirstQueueElement != pp_srdfArray_LastSlot) {
		pp_srdfArray_FirstQueueElement++;
	} else {
		pp_srdfArray_FirstQueueElement = srdfArrayOfPointer;
	}
}

/**
 * The SRDF buffer adds the new simulation data to its next free slot
 * and calls the pointNextFreeSRDFSlot method
 */
void pushSRDF() {
	*pp_srdfArray_NextFreeSlot = &(*p_ssdArray_NextFreeSlot);
	//cout << "pushSRDF: pp_srdfArray_NextFreeSlot " <<(*pp_srdfArray_NextFreeSlot)->forTimeStep << endl;
	pointNextFreeSRDFSlot();
}

void popSRDF(SimStepData* p_SimResDataForw_from_Transfer) {

	p_SimResDataForw_from_Transfer->forTimeStep
			= (*pp_srdfArray_FirstQueueElement)->forTimeStep; //is the lastEmittedTime of this step

	for (int i = 0; i < p_simdatanumbers->nStates; i++) {
		p_SimResDataForw_from_Transfer->states[i]
				= (*pp_srdfArray_FirstQueueElement)->states[i];
		p_SimResDataForw_from_Transfer->statesDerivatives[i]
				= (*pp_srdfArray_FirstQueueElement)->statesDerivatives[i];
	}

	for (int i = 0; i < p_simdatanumbers->nAlgebraic; i++) {
		p_SimResDataForw_from_Transfer->algebraics[i]
				= (*pp_srdfArray_FirstQueueElement)->algebraics[i];
	}

	for (int i = 0; i < p_simdatanumbers->nParameters; i++) {
		p_SimResDataForw_from_Transfer->parameters[i]
				= (*pp_srdfArray_FirstQueueElement)->parameters[i];
	}
	pointNextUsedSRDFSlot();
}

/*****************************************************************
* Print methods
*****************************************************************/

void printSSD() {

	cout << "****************printSSD****************" << endl;
	for (int i = 0; i < MAX_SSD; i++) {

		if (ssdArray[i].forTimeStep != -1) {
			cout << i << ": " << ssdArray[i].forTimeStep << endl;
		}
	}
}

void printSRDF() {
	cout << "****************printSRDF****************" << endl;
	for (int i = 0; i < MAX_SRDF; i++) {
		if (srdfArrayOfPointer[i] != 0) {
			if ((*srdfArrayOfPointer[i]).forTimeStep != -1)
				cout << i << ": " << (*srdfArrayOfPointer[i]).forTimeStep
						<< endl;
		} else {
			cout << i << ": " << srdfArrayOfPointer[i] << endl;
		}

	}
}
