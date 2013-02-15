/*
 * OpenModelica Interactive (Ver 0.75)
 * Last Modification: 23. May 2011
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: Parham.Vasaiely@eads.com
 *
 * File description: omi_ResultManager.cpp
 * While a simulation is running the `Calculation' thread produces simulation results for every time step,
 * and the `Transfer' thread sends the single results to a client.
 * There is a need for synchronization and organisation of simulation results.
 * However, the application cannot store all results because this would cause the system to run out of memory.
 * This scenario is the typical `producer and consumer problem with restricted buffer',
 * which is well known in IT science.
 * The `ResultManager' assumes responsibility for organizing simulation result data and
 * synchronizing access to these data.
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

#include <iomanip>
#include <stdio.h>
#include <iostream>
#include <math.h>
#include "omi_ResultManager.h"

using namespace std;

#define MAX_SSD 200 //Maximum number of Simulation Step Data elements
#define MAX_SRDF 20 //Maximum number of Simulation Result Data elements for Forwarding

double EPSILON = 0.0001;
int debugResultManager = 0; //Set the debug level higher zero to print out messages which describes the program flow to the console [0= debug off, 1= min-debug, 2= max-debug]
/*
 * This element signalizes that the simulation runs for the first time.
 * It is important to store data into the "simulationStartSSD"
 */
bool firstRun = true; //TODO [20110522] firstRun zurück setzten für stop

/*
 * After a simulation reset a (all) calculation thread must start from new
 * but in some cases the calculation thread is waiting to add a result into SSD.
 * In this case the first time which should be added to the SDD is 0 or 2.220446049250313e-13
 */
double VALID_TIME_AFTER_RESET = 2.220446049250313e-13;
bool simulationReset = false; //Set true after an reset to signal that the simulation has been stopped.

double VALID_TIME_AFTER_CHANGETIME = 0;
bool simulationChangetime = false; //Set true after an reset to signal that the simulation has been stopped.
/*
 * This SimStepData element represents the state at the initial state,
 * it is necessary to be saved because of the method reInitAll in control
 */
SimStepData simulationStartSSD;
//Points on the simulation step data at the initial state
SimStepData* p_simulationStartSSD;

//***** SimStepData buffer *****
SimStepData ssdArray[MAX_SSD] = {{0}};

SimStepData* p_ssdArray_NextFreeSlot = 0; //Points on the next free slot

/* p_ssdArray_LastSlot points on the last array slot, if the set
 * method reached this address the pointer has to point to the first slot of the array
 */
SimStepData* p_ssdArray_LastSlot = 0;

//***** SimStepData for forwading buffer (SimulationResultDataForwarding)*****

/*
 * This array contains pointers from the type SimStepData, which points on elements
 * in the ssdArray, so there is much less redundancy
 *
 * Note: All pointers which points an this array have to be pointers of pointers
 */
SimStepData* srdfArrayOfPointer[MAX_SRDF] = { 0 };

SimStepData** pp_srdfArray_FirstQueueElement = 0;//Points on the smallest time step pointer
SimStepData** pp_srdfArray_NextFreeSlot = 0; //Points on the next free slot from SRDF Array to insert an element
SimStepData** pp_srdfArray_LastSlot = 0; //Points on the lsat slot of the srdfArrayOfPointer

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

//static void reInitSSD_A(void);
//static bool deinitializeAll(void);
//SSD Organisation
static void addDataToSSD(SimStepData*);
static void pointNextFreeSSDSlot(void);
//SRDF Organisation
static void pointNextFreeSRDFSlot(void);
static void pointNextUsedSRDFSlot(void);
static void pushSRDF(void);
static void popSRDF(SimStepData*);

//Math help methods
static bool compareDouble(double, double);
//print methods for testing
static void printSSD(void);
static void printSRDF(void);

/*****************************************************************
 * Organisation and Management of SSD, SRDF, SimDataNames...
 * e.g. Parameters, Variables, Simulation Setup...
 * Initialization for simulation data
 *****************************************************************/
bool initializeSSD_AND_SRDF(long nStates, long nAlgebraic, long nParameters)
{
  bool retValue = true;
  //simDataNames_SimulationResult will be initialize from the SimulationControl

  p_ssdArray_NextFreeSlot = ssdArray;

  { //initialize the SSDArray with NullSSDs
    for (int i = 0; i < MAX_SSD; i++) {
      SimStepData nullSSD; //this SimStepData element represents a null element in the SSD Array
      nullSSD.forTimeStep = -1; //if the forTimeStep is -1 the element is null
      double *statesTMP1 = new double[nStates];
      double *statesDerivativesTMP1 = new double[nStates];
      double *algebraicsTMP1 = new double[nAlgebraic];
      double *parametersTMP1 = new double[nParameters];
      //TODO [201105222] pv: optimization try putting new array directly into the ssdArraySlot instead of creating an nullSDD first
      nullSSD.states = statesTMP1;
      nullSSD.statesDerivatives = statesDerivativesTMP1;
      nullSSD.algebraics = algebraicsTMP1;
      nullSSD.parameters = parametersTMP1;

      ssdArray[i] = nullSSD;
    }
  }

  { //initialize the SSD for the first simulation run (e.g. at time 0)
    p_simulationStartSSD = &simulationStartSSD;
    double *statesTMP2 = new double[nStates];
    double *statesDerivativesTMP2 = new double[nStates];
    double *algebraicsTMP2 = new double[nAlgebraic];
    double *parametersTMP2 = new double[nParameters];
    p_simulationStartSSD->states = statesTMP2;
    p_simulationStartSSD->statesDerivatives = statesDerivativesTMP2;
    p_simulationStartSSD->algebraics = algebraicsTMP2;
    p_simulationStartSSD->parameters = parametersTMP2;
  }
  //p_ssdArray_NextFreeSlot = ssdArray; //Done from resetSSDArrayWithNull...
  p_ssdArray_LastSlot = &ssdArray[MAX_SSD - 1];

  pp_srdfArray_FirstQueueElement = srdfArrayOfPointer;
  pp_srdfArray_NextFreeSlot = srdfArrayOfPointer;
  pp_srdfArray_LastSlot = &srdfArrayOfPointer[MAX_SRDF - 1];

  p_simdatanumbers = &simdatanumbers;
  p_simdatanumbers->nStates = nStates;
  p_simdatanumbers->nAlgebraic = nAlgebraic;
  p_simdatanumbers->nParameters = nParameters;

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
  p_simDataNames_SimulationResult->stateDerivativesNames = stateDerivativesNamesTMP;
  p_simDataNames_SimulationResult->algebraicsNames = algebraicsNamesTMP;
  p_simDataNames_SimulationResult->parametersNames = parametersNames1TMP;
  //****
  string *variablesNamesTMP = new string[nStates + nAlgebraic];
  string *parametersNames2TMP = new string[nParameters];
  p_simDataNamesFilterForTransfer->variablesNames = variablesNamesTMP;
  p_simDataNamesFilterForTransfer->parametersNames = parametersNames2TMP;
  //****
  p_sdnMutex = &sdnMutex;

  return retValue;
}

/*
 * Call this function after shutdown to free all allocated memory
 * TODO [20110523] pv: TBD
 */
bool deInitializeSSD_AND_SRDF(void)
{
  for (int i = 0; i < MAX_SSD; i++) {
    delete [] ssdArray[i].states;
    delete [] ssdArray[i].statesDerivatives;
    delete [] ssdArray[i].algebraics;
    delete [] ssdArray[i].parameters;
  }
  return true;
}

/*****************************************************************
 * Getter and Setter from the Interface ResultManager.h
 *****************************************************************/

P_SimDataNumbers getSimDataNumbers(void)
{
  return p_simdatanumbers;
}

/**
 * Reads the SimStepData from a Calculation thread and adds it to the intern SSD buffer and the SRDF buffer.
 * parameter: pointer from type SimStepData, it points on a data struct in a Calculation thread
 */
bool setResultData(SimStepData* p_SimStepData_from_Calculation)
{
  bool retValue = true;

  /*
   * This part is necessary for the producer &consumer problem with districted buffer
   * The any entity which want to use the array must pas this part
   */
  // Try to enter the ghSemaphore_NumberFreeSlots gate.
  ghSemaphore_NumberFreeSlots.Wait();

  ssdMutex.Lock();
  /********************************************************************
   * Entity has pas the synchronization section and can work on the SSD buffer
   * Restrictions: if the simulation has been reseted the first time value must be VALID_TIME_AFTER_RESET
   * otherwise the result won't be added to the system
   */

  //block used by normal running simulation
  if(!simulationReset && !simulationChangetime){
    addDataToSSD(p_SimStepData_from_Calculation);
    if (debugResultManager > 0) {
      cout << "add time: " << p_SimStepData_from_Calculation->forTimeStep   << endl; fflush(stdout);
    }
  }else{//block used once after simulation has been reseted or more if the next time to add into the ssd is not VALID_TIME_AFTER_RESET
    if(simulationReset){
      if(p_SimStepData_from_Calculation->forTimeStep == VALID_TIME_AFTER_RESET || p_SimStepData_from_Calculation->forTimeStep == 0){
          addDataToSSD(p_SimStepData_from_Calculation);
          //cout << "add after reset time: " << p_SimStepData_from_Calculation->forTimeStep   << endl; fflush(stdout);
          simulationReset = false;
      }
      else{
        //cout << "no chance for reset ;) time: " << p_SimStepData_from_Calculation->forTimeStep << endl; fflush(stdout);
      }
    } else{
      if(simulationChangetime){

        if(compareDouble(p_SimStepData_from_Calculation->forTimeStep, VALID_TIME_AFTER_CHANGETIME)){
          //cout << "add after change time: " << p_SimStepData_from_Calculation->forTimeStep   << endl; fflush(stdout);
            addDataToSSD(p_SimStepData_from_Calculation);
            simulationChangetime = false;
        } else{
          //cout << "no chance for change ;) time: " << p_SimStepData_from_Calculation->forTimeStep << endl; fflush(stdout);
        }
      }
    }
  }

  //Work on SSD and SRDF buffer ended **********************************

  // Release the mutex
  if (!ssdMutex.Unlock()) {
    //printf("ReleaseMutex ssdMutex error: %d\n", GetLastError());
    return false;
  }
  //if(debugResultManager) { cout << "set released mutex" << endl; fflush(stdout); }
  // Release the semaphore ghSemaphore_NumberUsedSlots
  ghSemaphore_NumberUsedSlots.Post();

  return retValue;
}

/**
 * Fills the SimStepData from a Transfer thread with the first simulation result from the SRD queue
 * This method won't filter the data, all existing and available parameter, algebraic and states will be saved.
 * parameter: pointer from type SimStepData, it points on a data struct in a Transfer thread
 */
bool getResultData(SimStepData* p_SimResDataForw_from_Transfer) {
  bool retValue = true;

  /*
   * This part is necessary for the producer &consumer problem with districted buffer
   * An entity which want to use the array must pas this part
   */
  ghSemaphore_NumberUsedSlots.Wait();
  ssdMutex.Lock();

  /********************************************************************
   * Entity has pas the synchronization station and can work on the SSD buffer
   */
  if ((*pp_srdfArray_FirstQueueElement)->forTimeStep != -1) {
    popSRDF(p_SimResDataForw_from_Transfer);
  } else{
    //cout << "no chance ;) for time: " << (*pp_srdfArray_FirstQueueElement)->forTimeStep << endl; fflush(stdout);
  }


  // Release the mutex
  ssdMutex.Unlock();
  ghSemaphore_NumberFreeSlots.Post();

  return retValue;
}

/**
 * The SSD array is divided by the NextFreeSlot pointer in two parts.
 * e.g. Part A is the higher leveled part containing the highest SimStepData and Part B containing the lowest SimStepData.
 * -------------------
 * |8|9|10|11|4|5|6|7|
 * -------------------
 *  A        |      B
 * the NextFreeSlot pointer points on the element with at the time "4", so we need two different searching algorithms
 * for each part.
 *
 * Return: If the searched step time is not stored in the ssd, the method returns a pointer which points an nullSSD
 * otherwise it points on the searched element
 */
SimStepData* getResultDataForTime(double stepSize, double timeStep) {

  if (debugResultManager > 1) {
    cout
        << "ResultManager:\tFunct.: getResultDataForTime\tMessage: All SSD Array elements START" << endl; fflush( stdout);
    for (int i = 0; i < MAX_SSD; i++) {
      cout << ssdArray[i].forTimeStep << endl; fflush(stdout);
    }
    cout
        << "ResultManager:\tFunct.: getResultDataForTime\tMessage: All SSD Array elements END"  << endl; fflush(stdout);
  }

  if (debugResultManager > 1) {
    cout
        << "ResultManager:\tFunct.: getResultDataForTime\tMessage: ADD of p_ssdArray_NextFreeSlot: "
        << p_ssdArray_NextFreeSlot << endl;  fflush( stdout);
    cout
        << "ResultManager:\tFunct.: getResultDataForTime\tMessage: p_ssdArray_NextFreeSlot: "
        << p_ssdArray_NextFreeSlot->forTimeStep << endl; fflush(stdout);
    cout
        << "ResultManager:\tFunct.: getResultDataForTime\tMessage: p_ssdArray_NextFreeSlot-1: "
        << (p_ssdArray_NextFreeSlot - 1)->forTimeStep << endl; fflush(stdout);
    cout
        << "ResultManager:\tFunct.: getResultDataForTime\tMessage: timeStep: "
        << timeStep << endl;
    fflush(stdout);
  }

  SimStepData* temp;

  //check if the searched time step is available in simulationstepdata (ssd)
  if (timeStep == p_ssdArray_NextFreeSlot->forTimeStep || (timeStep
      > p_ssdArray_NextFreeSlot->forTimeStep && timeStep
      <= (p_ssdArray_NextFreeSlot - 1)->forTimeStep)) {

    SimStepData* firstSSD_Element = ssdArray;

    //If this query returns true we have to search in Part B, because the time step is smaller than the lowest ssd in Part A
    if (timeStep < firstSSD_Element->forTimeStep) {
      temp = static_cast<int> (((timeStep
          - p_ssdArray_NextFreeSlot->forTimeStep) / stepSize)
          + 0.0001) + p_ssdArray_NextFreeSlot; //+0.0001 is needed because of type cast and vision from int and double
      if (debugResultManager > 1) {
        cout
            << "ResultManager:\tFunct.: getResultDataForTime\tMessage: getResultDataForTime search in Part B temp->forTimeStep: "
            << temp->forTimeStep << endl;
        fflush( stdout);
      }
      return temp;
    } else {
      temp
          = static_cast<int> (((timeStep
              - firstSSD_Element->forTimeStep) / stepSize)
              + 0.0001) //+0.0001 is important while casting from double to integer
              + firstSSD_Element;
      if (debugResultManager > 1) {
        cout
            << "ResultManager:\tFunct.: getResultDataForTime\tMessage: getResultDataForTime search in Part A temp->forTimeStep: "
            << temp->forTimeStep << endl;
        fflush( stdout);
      }
      return temp;
    }
  } else {
    SimStepData nullSSD; //this SimStepData element represents a null element in the SSD Array
    nullSSD.forTimeStep = -1; //if the forTimeStep is -1 the element is null
    /*double *statesTMP1 = new double[1];
    double *statesDerivativesTMP1 = new double[1];
    double *algebraicsTMP1 = new double[1];
    double *parametersTMP1 = new double[1];
    nullSSD.states = statesTMP1;
    nullSSD.statesDerivatives = statesDerivativesTMP1;
    nullSSD.algebraics = algebraicsTMP1;
    nullSSD.parameters = parametersTMP1;*/
    temp = &nullSSD;
    if (debugResultManager > 1) {
      cout
          << "ResultManager:\tFunct.: getResultDataForTime\tMessage: Error time not in SSD"
          << endl;
      fflush( stdout);
    }
  }
  return temp;
}

/*
 * Retuns the simulation state data at the initial state
 */
SimStepData* getResultDataFirstStart(void)
{
  return p_simulationStartSSD;
}

/*
 * use this method after a change time or value operation from control
 * to signal a changed time to the simulation
 */
void setSimulationTimeReversed(double validTime){
  VALID_TIME_AFTER_CHANGETIME = validTime;
  if (debugResultManager > 0) {
    cout << "ResultManager:\tFunct.: setSimulationTimeReversed\tData: VALID_TIME_AFTER_CHANGETIME: "  << VALID_TIME_AFTER_CHANGETIME << endl; fflush( stdout);
  }
  simulationChangetime = true;
}

/*****************************************************************
 * Help Methods
 *****************************************************************/

/**
 * After changing simulation parameters or starting the simulation from beginning,
 * the organization of the SRDF array must start again from the beginning.
 * because old simulation data mustn't send to the GUI.
 */
void resetSRDFAfterChangetime(void)
{
  if (debugResultManager > 1) {
    cout << "ResultManager:\tFunct.: resetSRDFAfterChangetime\tMessage: START"  << endl; fflush( stdout);
  }
  pp_srdfArray_FirstQueueElement = srdfArrayOfPointer;
  pp_srdfArray_NextFreeSlot = srdfArrayOfPointer;

  while (ghSemaphore_NumberUsedSlots.TryWait()) {
    ghSemaphore_NumberFreeSlots.Post();
  }

  if (debugResultManager > 1) {
    printSRDF();
    cout << "ResultManager:\tFunct.: resetSRDFAfterChangetime\tMessage: END"  << endl; fflush( stdout);
  }
}

/**
 * If the simulation has to start again from the beginning
 * The SSD array has to reset with nullSSD elements
 */
void resetSSDArrayWithNullSSD(long nStates, long nAlgebraic, long nParameters)
{
  p_ssdArray_NextFreeSlot = ssdArray;
  simulationReset = true;
  for (int i = 0; i < MAX_SSD; i++) {

    delete [] ssdArray[i].states;
    delete [] ssdArray[i].statesDerivatives;
    delete [] ssdArray[i].algebraics;
    delete [] ssdArray[i].parameters;

    SimStepData nullSSD; //this SimStepData element represents a null element in the SSD Array
    nullSSD.forTimeStep = -1; //if the forTimeStep is -1 the element is null
    double *statesTMP1 = new double[nStates];
    double *statesDerivativesTMP1 = new double[nStates];
    double *algebraicsTMP1 = new double[nAlgebraic];
    double *parametersTMP1 = new double[nParameters];
    //TODO [201105222] optimization try putting new array directly into the ssdArraySlot instead of creating an nullSDD first
    nullSSD.states = statesTMP1;
    nullSSD.statesDerivatives = statesDerivativesTMP1;
    nullSSD.algebraics = algebraicsTMP1;
    nullSSD.parameters = parametersTMP1;

    ssdArray[i] = nullSSD;
    // if(debugResultManager) { cout << ssdArray[i].forTimeStep << endl; fflush(stdout); }
  }
  if (debugResultManager > 0) {
    cout << "ResultManager:\tFunct.: resetSSDArrayWithNullSSD" << endl;  fflush( stdout);
    printSSD();
  }
}

void lockMutexSSD(void)
{
  ssdMutex.Lock();
}

void releaseMutexSSD(void)
{
  ssdMutex.Unlock();
}

/*
 * Returns the minimum time stored in the SSDArray
 */
double getMinTime_inSSD(void)
{
  return p_ssdArray_NextFreeSlot->forTimeStep;
}

/*
 * Returns the maximum time stored in the SSDArray
 */
double getMaxTime_inSSD(void)
{
  return (p_ssdArray_NextFreeSlot - 1)->forTimeStep;
}
/*****************************************************************
 * Organization of SSD and SRDF
 *****************************************************************/

/**
 * Adds result data to the SSD Array and tries to add a pointer on it into the SRDF Array
 */
static void addDataToSSD(SimStepData* p_SimStepData_from_Calculation)
{

  p_ssdArray_NextFreeSlot->forTimeStep = p_SimStepData_from_Calculation->forTimeStep; //is the lastEmittedTime or timeValue of this step
  if (firstRun)
    p_simulationStartSSD->forTimeStep = p_SimStepData_from_Calculation->forTimeStep;

  for (int i = 0; i < p_simdatanumbers->nStates; i++) {
    p_ssdArray_NextFreeSlot->states[i] = p_SimStepData_from_Calculation->states[i];
    p_ssdArray_NextFreeSlot->statesDerivatives[i]= p_SimStepData_from_Calculation->statesDerivatives[i];

    //Save the first simulation data
    if (firstRun)
      p_simulationStartSSD->states[i]  = p_SimStepData_from_Calculation->states[i];
    if (firstRun)
      p_simulationStartSSD->statesDerivatives[i] = p_SimStepData_from_Calculation->statesDerivatives[i];
  }
  if (debugResultManager > 1) {
    cout << "ResultManager:\tFunct.: addDataToSSD\tData 2: time = " << (p_ssdArray_NextFreeSlot)->forTimeStep << " tank1.h = " << (p_ssdArray_NextFreeSlot)->states[0] << endl; fflush( stdout);
    printSSD();
  }
  for (int i = 0; i < p_simdatanumbers->nAlgebraic; i++) {
    p_ssdArray_NextFreeSlot->algebraics[i] = p_SimStepData_from_Calculation->algebraics[i];
    if (firstRun)
      p_simulationStartSSD->algebraics[i]  = p_SimStepData_from_Calculation->algebraics[i];
  }

  for (int i = 0; i < p_simdatanumbers->nParameters; i++) {
    p_ssdArray_NextFreeSlot->parameters[i] = p_SimStepData_from_Calculation->parameters[i];
    if (firstRun)
      p_simulationStartSSD->parameters[i]  = p_SimStepData_from_Calculation->parameters[i];
  }

  firstRun = false; //simulationStartSSD should only initialize once

  //If a simulation result is pushed into SSD it also have to push into the SRDF buffer
  pushSRDF();
  pointNextFreeSSDSlot();
}

/**
 * This method points the p_ssdArrayFreeSlot pointer to the next free slot from the SSD array
 * If the last slot is reached it will point p_ssdArrayFreeSlot to the first element from the SSD array
 * otherwise to the next higher index
 */
static void pointNextFreeSSDSlot(void)
{
  //cout << "pointNextFreeSSDSlot: p_ssdArray_NextFreeSlot " << p_ssdArray_NextFreeSlot->forTimeStep << endl; fflush(stdout);
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
static void pointNextFreeSRDFSlot(void)
{
  if (pp_srdfArray_NextFreeSlot != pp_srdfArray_LastSlot) {
    pp_srdfArray_NextFreeSlot++;
  } else {
    pp_srdfArray_NextFreeSlot = srdfArrayOfPointer;
  }
}

static void pointNextUsedSRDFSlot(void)
{
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
static void pushSRDF(void)
{
  *pp_srdfArray_NextFreeSlot = &(*p_ssdArray_NextFreeSlot);

  if (debugResultManager > 1) {
    cout << "ResultManager:\tFunct.: pushSRDF\tData 1: time = " << (*pp_srdfArray_NextFreeSlot)->forTimeStep << " tank1.h = " << (*pp_srdfArray_NextFreeSlot)->states[0] << endl; fflush( stdout);
    cout << "ResultManager:\tFunct.: pushSRDF\tData 2: time = " << (*pp_srdfArray_FirstQueueElement)->forTimeStep << " tank1.h = " << (*pp_srdfArray_FirstQueueElement)->states[0] << endl; fflush( stdout);
    printSRDF();
  }
  pointNextFreeSRDFSlot();
}

/*
 * Pops a simulation step data for a transfer thread
 */
static void popSRDF(SimStepData* p_SimResDataForw_from_Transfer)
{
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

  if (debugResultManager > 1) {
    cout << "ResultManager:\tFunct.: popSRDF\tData: time = "
        << (*pp_srdfArray_FirstQueueElement)->forTimeStep
        << " tank1.h = "
        << (*pp_srdfArray_FirstQueueElement)->states[0] << endl;
    fflush( stdout);
  }

  pointNextUsedSRDFSlot();
}

/*****************************************************************
 * Math help methods
 *****************************************************************/

static bool compareDouble(double a, double b)
{
    return fabs(a - b) < EPSILON;
}

/*****************************************************************
 * Print methods
 *****************************************************************/

static void printSSD(void)
{

  cout << "ResultManager:\tFunct.: printSSD****************" << endl;
  fflush( stdout);
  for (int i = 0; i < MAX_SSD; i++) {

    if (ssdArray[i].forTimeStep != -1) {
      cout << "ResultManager:\tFunct.: printSSD\tData: SSD[" << i
          << "]: time= " << ssdArray[i].forTimeStep
          << " tank1.h = " << ssdArray[i].states[0]
          << endl;
      fflush(stdout);
    }
  }
}

static void printSRDF(void)
{
  cout << "ResultManager:\tFunct.: printSRDF****************" << endl;
  fflush( stdout);
  for (int i = 0; i < MAX_SRDF; i++) {
    if (srdfArrayOfPointer[i] != 0) {
      if ((*srdfArrayOfPointer[i]).forTimeStep != -1) {
        cout << "ResultManager:\tFunct.: printSRDF\tData: SRDF[" << i
            << "]: time = " << (*srdfArrayOfPointer[i]).forTimeStep
            << " tank1.h = " << (*srdfArrayOfPointer[i]).states[0]
            << endl;
        fflush(stdout);
      }
    } else {
      cout << "ResultManager:\tFunct.: printSRDF\tData: SRDF[" << i
          << "]: " << srdfArrayOfPointer[i] << endl;
      fflush(stdout);
    }

  }
}
