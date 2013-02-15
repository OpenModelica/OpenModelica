/*
 * OpenModelica Interactive (Ver 0.75)
 * Last Modification: 23. May 2011
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: Parham.Vasaiely@eads.com
 *
 * File description: omi_Calculation.cpp
 * The "Calculation" thread is synonymous to a producer which uses the "OM Solving Service"
 * to get results for a specific time step and to inform the "ResultManager"
 * about the new simulation results. It uses parameters to calculate the interval between single calculation steps
 * in a loop, until the simulation is interrupted by the "Control" or because of an occurred error.
 * If a single solving step is very complex and takes a long time to be solved,
 * it is possible to create more than one producer to start the next simulation step during the data storing time.
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

#include "omi_ServiceInterface.h"
#include "omi_Control.h"
#include "omi_Calculation.h"

using namespace std;

static bool debugCalculation = false; //Set true to print out comments which describes the program flow to the console

static bool calculationInterrupted = false;

static SimStepData simStepData_from_Calculation; //Simulation Step Data structure used by a calculation thread to store simulation result data for a specific time step data
static SimStepData* p_SimStepData_from_Calculation = 0;

static int calculate(void);
static void createSSDEntry(string);
static void printSSDCalculation(long, long, long);

/**
 * Calculates all simulation steps in a loop until the calculation is interrupted
 */
static int calculate(void)
{
  int retVal = -1;
  double start = 0.0;
  double stop = 1.0;
  double stepSize = 1;
  long outputSteps = 1; //unnecessary for interactive simulation
  double tolerance = 1e-4;
  string method;
  string outputFormat;


  intializeSolverStartData(&stepSize, &outputSteps, &tolerance, &method, &outputFormat);
  //TODO  20100217 pv catch correct stepSize value for calculation loop
  if (debugCalculation) {
    cout << "Calculation:\tFunct.: calculate\tData 1: start: " << start
        << " stop: " << stop << " stepSize: " << stepSize
        << " outputSteps: " << outputSteps << " method: " << method
        << " outputFormat: " << outputFormat;
    fflush( stdout);
  }

  set_timeValue(start);
  set_forceEmit(0);


  while (!calculationInterrupted) { //TODO 20100210 pv Interrupt is not implemented yet

    mutexSimulationStatus->Lock(); // Lock to see the simulation status.
    if (simulationStatus == SimulationStatus::STOPPED) {
      // If the simulation should stop, unlock and break out of the loop.
      mutexSimulationStatus->Unlock();
    }

    if (simulationStatus == SimulationStatus::SHUTDOWN) {
      // If the simulation should stop, unlock and break out of the loop.
      mutexSimulationStatus->Unlock();
      break;
    }

    if (simulationStatus == SimulationStatus::RUNNING) {
      // If the simulation should continue, increase the semaphore.
      waitForResume->Post();
    }
    // Unlock and see if we need to wait for resume or not.
    mutexSimulationStatus->Unlock();
    waitForResume->Wait(); //wait and reduce semaphore

    //TODO 20100210 pv testing rungekutter...
    start = get_timeValue();
    stop = get_timeValue() + stepSize;
    if (debugCalculation) {
      cout << "Calculation:\tFunct.: calculate\tData 2: p_SimStepData_from_Calculation->forTimeStep: " << p_SimStepData_from_Calculation->forTimeStep  << " ------" << endl;  fflush( stdout);
      cout << "Calculation:\tFunct.: calculate\tData 3: start " << start << " stop: " << stop << endl; fflush(stdout);
    }

    retVal =  performSolverStepFromOM(start, stop, stepSize);

    if (retVal != 0) {
      cout << "Calculation:\tFunct.: calculate\tMessage: omi_Calculation: error occurred while calculating" << endl; fflush( stdout);
      return 1;
    }

    set_stepSize(stepSize);
    createSSDEntry(method);
    calculationInterrupted = false;

    setResultData(p_SimStepData_from_Calculation); //ssd(tn) as parameter
  }

  deintializeSolverStartData();
  //if (debugCalculation)
  cout
      << "Calculation:\tFunct.: calculate\tMessage: Calculation end: calculationInterrupted -> "
      << calculationInterrupted << endl;
  fflush( stdout);
  //return retVal; //TODO 20100210 pv Implement the return value correctly
  return 0;
}

/**
 * Asks the ServiceInterface for the last simulation results to put into the simulation step data structure
 */
static void createSSDEntry(string method)
{
  fillSimulationStepDataWithValuesFromGlobalData(method, p_SimStepData_from_Calculation);

  p_sdnMutex->Lock();

  p_sdnMutex->Unlock();
  if (debugCalculation)
  {
    //printSSDCalculation(nStates, nAlgebraic, nParameters);
    cout
        << "Calculation:\tFunct.: createSSDEntry\tData: p_SimStepData_from_Calculation->forTimeStep: "
        << p_SimStepData_from_Calculation->forTimeStep
        << " --------------------" << endl;
    fflush( stdout);
  }
}

/**
 * Only for debugging
 * Prints out the actual calculated Simulation Step Data structure
 */
static void printSSDCalculation(long nStates, long nAlgebraic, long nParameters)
{
  cout
      << "Calculation:\tFunct.: printSSDCalculation\tMessage: OutPutSSD-CALCULATION***********"
      << endl;
  fflush( stdout);
  cout
      << "Calculation:\tFunct.: printSSDCalculation\tData: p_SimStepData_from_Calculation->forTimeStep: "
      << p_SimStepData_from_Calculation->forTimeStep
      << " --------------------" << endl;
  fflush(stdout);

  cout << "Calculation:\tFunct.: printSSDCalculation\tMessage: Parmeters--- "
      << endl;
  fflush(stdout);
  for (int t = 0; t < nParameters; t++)
  {
    cout << t << ": "
        << p_simDataNames_SimulationResult->parametersNames[t] << ": "
        << p_SimStepData_from_Calculation->parameters[t] << endl;
    fflush(stdout);
  }

  if (nAlgebraic > 0) {
    cout
        << "Calculation:\tFunct.: printSSDCalculation\tMessage: Algebraics---"
        << endl;
    fflush(stdout);
    for (int t = 0; t < nAlgebraic; t++) {
      cout << t << ": "
          << p_simDataNames_SimulationResult->algebraicsNames[t]
          << ": " << p_SimStepData_from_Calculation->algebraics[t]
          << endl;
      fflush(stdout);
    }
  }

  if (nStates > 0) {
    cout << "Calculation:\tFunct.: printSSDCalculation\tMessage: States---"
        << endl;
    fflush(stdout);
    for (int t = 0; t < nStates; t++) {
      cout << t << ": "
          << p_simDataNames_SimulationResult->statesNames[t] << ": "
          << p_SimStepData_from_Calculation->states[t] << endl;
      fflush(stdout);
      cout << t << ": "
          << p_simDataNames_SimulationResult->stateDerivativesNames[t]
          << ": "
          << p_SimStepData_from_Calculation->statesDerivatives[t]
          << endl;
      fflush(stdout);
    }
  }
}

/**
 * Main thread method initializes all data
 */
THREAD_RET_TYPE threadSimulationCalculation(THREAD_PARAM_TYPE lpParam)
{
  int retValue = -1; //Not used yet

  if (debugCalculation) {
    cout << "Calculation:\tMessage: Calculation Thread Start*****" << endl;
    fflush( stdout);
  }

  p_sdnMutex->Lock();
  long nStates = p_simdatanumbers->nStates;
  long nAlgebraic = p_simdatanumbers->nAlgebraic;
  long nParameters = p_simdatanumbers->nParameters;
  p_sdnMutex->Unlock();

  p_SimStepData_from_Calculation = &simStepData_from_Calculation;

  double *statesTMP2 = new double[nStates];
  double *statesDerivativesTMP2 = new double[nStates];
  double *algebraicsTMP2 = new double[nAlgebraic];
  double *parametersTMP2 = new double[nParameters];
  p_SimStepData_from_Calculation->states = statesTMP2;
  p_SimStepData_from_Calculation->statesDerivatives = statesDerivativesTMP2;
  p_SimStepData_from_Calculation->algebraics = algebraicsTMP2;
  p_SimStepData_from_Calculation->parameters = parametersTMP2;



  retValue = calculate();

  if (debugCalculation) {
    cout << "Calculation:\tMessage: Calculation Thread End*****" << endl;
    fflush( stdout);
  }

  return (THREAD_RET_TYPE_NO_API) retValue;
}
