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

#include "simulation_data.h"
#include "openmodelica_func.h"
#include "simulation_runtime.h"
#include "simulation_input_xml.h"
#include "solver_main.h"
#include "options.h"
#include "omi_ServiceInterface.h"
#include "omi_Control.h"
#include "omi_Transfer.h"

//Global Data Mutex
static Mutex gdMutex;

int argcTEMP = 0; //From main parameter argc
char** argvTEMP = 0; //From main parameter argv
double global_stepSize = 0.0;

// Global Data structure
DATA* globalData;
SOLVER_INFO* solverInfo;

/**
 * Initializes the service interface data
 * e.g. the used globalDataMutex
 * and the arguments of the simulation_runtime main function
 */
int initServiceInterfaceData(int argc, char**argv, void* inData)
{
  //The arguments should be available globally, also in other classes
  argcTEMP = argc;
  argvTEMP = argv;
  globalData = (DATA*) inData;

  return true;
}

void* getGlobalData(void)
{
  return globalData;
}

/*****************************************************************
 * Communication direction from OMI --> OM              *
 *****************************************************************/

//************ Global Data Value Request and Manipulation ************

//****** Number of properties******

//NOTE: nStates is similar to nStateDerivatives
long get_NStates(void)
{
  gdMutex.Lock();

  long temp_val = globalData->modelData.nStates;

  gdMutex.Unlock();
  return temp_val;
}

long get_NAlgebraic(void)
{
  gdMutex.Lock();

  long temp_val = globalData->modelData.nVariablesReal-2*globalData->modelData.nStates;

  gdMutex.Unlock();

  return temp_val;
}

long get_NParameters(void)
{
  gdMutex.Lock();

  long temp_val = globalData->modelData.nParametersReal;

  gdMutex.Unlock();

  return temp_val;
}

long get_NInputVars(void)
{
  gdMutex.Lock();

  long temp_val = globalData->modelData.nInputVars;

  gdMutex.Unlock();

  return temp_val;
}

long get_NOutputVars(void)
{
  gdMutex.Lock();

  long temp_val = globalData->modelData.nOutputVars;

  gdMutex.Unlock();

  return temp_val;
}

//****** END Number of properties******

//****** State Value, Name Request and Manipulation ******

void set_StateValue(int index, double value)
{
  gdMutex.Lock();

  globalData->localData[0]->realVars[index] = value;

  gdMutex.Unlock();
}

double get_StateValue(int index)
{
  gdMutex.Lock();

  double temp_val =  globalData->localData[0]->realVars[index];

  gdMutex.Unlock();

  return temp_val;
}

string get_StateName(int index)
{
  gdMutex.Lock();

  string temp_val =  globalData->modelData.realVarsData[index].info.name;

  gdMutex.Unlock();

  return temp_val;
}

//****** StateDerivative Value, Name Request and Manipulation ******
void set_StateDerivativesValue(int index, double value)
{
  gdMutex.Lock();

  long nStates = globalData->modelData.nStates;

  globalData->localData[0]->realVars[nStates + index] = value;

  gdMutex.Unlock();
}

double get_StateDerivativesValue(int index)
{
  gdMutex.Lock();

  long nStates = globalData->modelData.nStates;

  double temp_val =  globalData->localData[0]->realVars[nStates + index];

  gdMutex.Unlock();

  return temp_val;
}

string get_StateDerivativesName(int index)
{
  gdMutex.Lock();

  long nStates = globalData->modelData.nStates;

  string temp_val =  globalData->modelData.realVarsData[nStates + index].info.name;

  gdMutex.Unlock();

  return temp_val;
}

//****** Algebraic Value, Name Request and Manipulation ******
// Currently only Real Variables are supported!
// TODO: extend for other types (e.g. integer, boolean,...)
void set_AlgebraicValue(int index, double value)
{
  gdMutex.Lock();

  long nStates = globalData->modelData.nStates;

  globalData->localData[0]->realVars[2*nStates + index] = value;

  gdMutex.Unlock();
}

double get_AlgebraicValue(int index)
{
  gdMutex.Lock();

  long nStates = globalData->modelData.nStates;

  double temp_val =  globalData->localData[0]->realVars[2*nStates + index];

  gdMutex.Unlock();

  return temp_val;
}

string get_AlgebraicName(int index)
{
  gdMutex.Lock();

  long nStates = globalData->modelData.nStates;

  string temp_val =  globalData->modelData.realVarsData[nStates + index].info.name;

  gdMutex.Unlock();

  return temp_val;
}

//****** Parameter Value, Name Request and Manipulation ******
// Currently only Real Variables are supported!
// TODO: extend for other types (e.g. integer, boolean,...)
void set_ParameterValue(int index, double value)
{
  gdMutex.Lock();

  globalData->simulationInfo.realParameter[index] = value;

  gdMutex.Unlock();
}

double get_ParameterValue(int index)
{
  gdMutex.Lock();

  double temp_val =  globalData->simulationInfo.realParameter[index];

  gdMutex.Unlock();

  return temp_val;
}

string get_ParameterName(int index)
{
  gdMutex.Lock();

  string temp_val =  globalData->modelData.realParameterData[index].info.name;

  gdMutex.Unlock();

  return temp_val;
}

//****** InputVariable Value, Name Request and Manipulation ******
void set_InputVarValue(int index, double value)
{
  gdMutex.Lock();

  globalData->simulationInfo.inputVars[index] = value;

  gdMutex.Unlock();
}

double get_InputVarValue(int index)
{
  gdMutex.Lock();

  double temp_val =  globalData->simulationInfo.inputVars[index];

  gdMutex.Unlock();

  return temp_val;
}

string get_InputVarName(int index)
{
  gdMutex.Lock();

  // TODO: find name for input values */
  string temp_val =  "";

  gdMutex.Unlock();

  return temp_val;
}

//****** OutputVariable Value, Name Request and Manipulation ******
void set_OutputVarValue(int index, double value)
{
  gdMutex.Lock();

  globalData->simulationInfo.outputVars[index] = value;

  gdMutex.Unlock();

}

double get_OutputVarValue(int index)
{
  gdMutex.Lock();

  double temp_val =  globalData->simulationInfo.outputVars[index];

  gdMutex.Unlock();

  return temp_val;
}

string get_OutputVarName(int index)
{
  gdMutex.Lock();

  // TODO: find name for input values */
  string temp_val =  "";

  gdMutex.Unlock();

  return temp_val;
}
//****** END Value, Name Request and Manipulation ******


//****** Simulation Status Request and Manipulation ******

double get_timeValue(void)
{
  gdMutex.Lock();

  double temp_let = globalData->localData[0]->timeValue;

  gdMutex.Unlock();

  return temp_let;
}

void set_timeValue(double new_timeValue)
{
   gdMutex.Lock();

   globalData->localData[0]->timeValue = new_timeValue;

   gdMutex.Unlock();
}

void set_lastEmittedTime(double new_lastEmittedTime)
{
  gdMutex.Lock();

  // What's the propose of that???
  // One can't change things that were happen already!!!
  cout << "set_lastEmittedTime not implemented!" << endl;

  gdMutex.Unlock();
}


double get_lastEmittedTime(void)
{
  gdMutex.Lock();

  double temp_let = globalData->localData[0]->timeValue - solverInfo->currentStepSize;

  gdMutex.Unlock();

  return temp_let;
}

void set_stepSize(double new_globalStepSize)
{
  gdMutex.Lock();

  globalData->simulationInfo.stepSize = new_globalStepSize;

  gdMutex.Unlock();
}

double get_stepSize(void)
{
  gdMutex.Lock();

  double temp_let =  globalData->simulationInfo.stepSize ;

  gdMutex.Unlock();

  return temp_let;
}

// TODO: update forceEmit functions
//       when the purpose is clear.
void set_forceEmit(int new_forceEmit)
{
  gdMutex.Lock();

  //globalData->forceEmit = new_forceEmit;

  gdMutex.Unlock();
}
int get_forceEmit(void){
  gdMutex.Lock();

  //int fe = globalData->forceEmit;

  gdMutex.Unlock();

  return 0;
}
//****** END Simulation Status Request and Manipulation ******

//****** Request and Manipulate Data from GlobalData via SimulationStepData

void setGlobalSimulationValuesFromSimulationStepData(SimStepData* p_SimStepData)
{
  gdMutex.Lock();

  /*
   * With the currect implementation it's not possible
   * to change the time.
   */
  //globalData->localData[0]->timeValue = p_SimStepData->forTimeStep;

  long nStates = globalData->modelData.nStates;
  long nParameters = globalData->modelData.nParametersReal;

  /* For now permit only parameter and states changes, since
   * changes of stateDerivates and algebraic variables are
   * anyway not possible, they are calculated!
   */
  for (int i = 0; i < nStates; i++) {
    globalData->localData[0]->realVars[i] = p_SimStepData->states[i];
  }
  for (int i = 0; i < nParameters; i++) {
    globalData->simulationInfo.realParameter[i] = p_SimStepData->parameters[i];
  }
  gdMutex.Unlock();
}

void fillSimulationStepDataWithValuesFromGlobalData(string method, SimStepData* p_SimStepData)
{
  gdMutex.Lock();

  long nStates = globalData->modelData.nStates;
  long nAlgebraic = globalData->modelData.nVariablesReal-2*globalData->modelData.nStates;
  long nParameters = globalData->modelData.nParametersReal;

  p_SimStepData->forTimeStep = globalData->localData[0]->timeValue; //is the lastEmittedTime of this step

  for (int i = 0; i < nStates; i++)
  {
    p_SimStepData->states[i] = globalData->localData[0]->realVars[i];
    p_SimStepData->statesDerivatives[i] = globalData->localData[0]->realVars[nStates + i];
  }
  for (int i = 0; i < nAlgebraic; i++)
  {
    p_SimStepData->algebraics[i] = globalData->localData[0]->realVars[2*nStates + i];
  }
  for (int i = 0; i < nParameters; i++)
  {
    p_SimStepData->parameters[i] = globalData->simulationInfo.realParameter[i];
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
    SimDataNames* p_simDataNames, SimDataNamesFilter* p_simDataNamesFilter)
{
  gdMutex.Lock();

  long nStates = globalData->modelData.nStates;
  long nAlgebraic = globalData->modelData.nVariablesReal-2*globalData->modelData.nStates;
  long nParameters = globalData->modelData.nParametersReal;

  int variablesNamesPos = 0;
  for (int i = 0; i < nStates; i++)
  {
    p_simDataNames->statesNames[i] = globalData->modelData.realVarsData[i].info.name;
    p_simDataNamesFilter->variablesNames[variablesNamesPos] = "";
    p_simDataNames->stateDerivativesNames[i]
        = globalData->modelData.realVarsData[nStates + i].info.name;
    variablesNamesPos++;
  }
  for (int i = 0; i < nAlgebraic; i++)
  {
    p_simDataNames->algebraicsNames[i] = globalData->modelData.realVarsData[2*nStates + i].info.name;
    p_simDataNamesFilter->variablesNames[variablesNamesPos] = "";
    variablesNamesPos++;
  }
  for (int i = 0; i < nParameters; i++)
  {
    p_simDataNames->parametersNames[i] = globalData->modelData.realParameterData[i].info.name;
    p_simDataNamesFilter->parametersNames[i] = "";
  }
  gdMutex.Unlock();
}

//****** END OPTIMIZATION ******

/*
 * Calls the "read_input_xml(...)" function from "simulation_input.cpp" and stores the simulation start data into
 * a set of variables from "omi_Calculation.cpp"
 */
int intializeSolverStartData(double *stepSize, long *outputSteps,
    double *tolerance, string* method, string* outputFormat)
{

  gdMutex.Lock();

  int retVal = -1;

  SIMULATION_INFO* simInfo = &globalData->simulationInfo;

  string result_file_cstr = string(globalData->modelData.modelFilePrefix) + string("_res.") + simInfo->outputFormat;

  retVal = initializeResultData(globalData, result_file_cstr, 0);

  solverInfo = (SOLVER_INFO*) malloc(sizeof(SOLVER_INFO));


  if(simInfo->solverMethod == std::string("rungekutta"))
  {
    solverInfo->solverMethod = 2;
  }
  else if(simInfo->solverMethod == std::string("dassl"))
  {
    solverInfo->solverMethod = 3;
  }
  /* as fallback and default euler solver is used */
  else
  {
    solverInfo->solverMethod = 1;
  }

  *stepSize = simInfo->stepSize;
  *outputSteps = simInfo->stepSize;
  *tolerance = simInfo->tolerance;
  *method = simInfo->solverMethod;


  /* allocate SolverInfo memory */
  if (!retVal)
    retVal = initializeSolverData(globalData, solverInfo);

  /* initialize all parts of the model */
  if (!retVal)
    retVal = initializeModel(globalData, "", "", "", 0.0, 0);


  gdMutex.Unlock();

  return retVal;
}


/*
 * Calls the "read_input_xml(...)" function from "simulation_input.cpp" and stores the simulation start data into
 * a set of variables from "omi_Calculation.cpp"
 */
void deintializeSolverStartData(void)
{

  gdMutex.Lock();

  /* terminate the simulation */
  finishSimulation(globalData, solverInfo, "");

  /* free SolverInfo memory */
  freeSolverData(globalData, solverInfo);


  gdMutex.Unlock();
}
//************ END Global Data Value Request and Manipulation ************

/*
 * Calls the solver which is selected in the parameter string "method"
 */
int performSolverStepFromOM(double start, double stop, double stepSize)
{
  int retVal = -1;
  gdMutex.Lock();


  SIMULATION_INFO* simInfo = &globalData->simulationInfo;
  simInfo->stepSize = stepSize;
  simInfo->startTime = start;
  simInfo->stopTime = stop;

  /* starts the simulation main loop */
  retVal = globalData->callback->performSimulation(globalData, solverInfo);

  gdMutex.Unlock();
  return retVal;
}

/**
 * Bans working on Global Data, this is important for interrupting calculation and transfer threads
 * Otherwise one of the consumer or producer threads are still working on the GD and no changes could realized
 * while the simulation is paused or an error occurred...
 */
bool denied_work_on_GD(void)
{
  gdMutex.Lock();
  return true;
}

bool allow_work_on_GD(void)
{
  gdMutex.Unlock();

  return true;
}

/*****************************************************************
 * Communication direction from OM --> OMI              *
 *****************************************************************/

/**
 * Creates the Simulation Control Thread
 */
Thread* createControlThread(void)
{
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
void setIPAndPortOfControlClient(string ip, int port)
{
  setControlClientIPandPort(ip, port);
}

/**
 * Sets only the Port of the control network server to user specific value
 * The IP (localhost - 127.0.0.1) mustn't change
 * Note: Call this function before starting simulation
 */
void setPortOfControlServer(int port)
{
  setControlServerPort(port);
}

/*
 * Note: Call this function before starting simulation
 */
void setIPandPortOfTransferClient(string ip, int port)
{
  setTransferIPandPort(ip, port);
}

//TODO 20100217 pv Implement Reset of IP and Port.. necessary??

//************ END Network Configuration Settings ************

/*****************************************************************
 * Used from both subsystems              *
 *****************************************************************/


/**
 * Prints out the actual global data stored in the simulation_runtime.cpp
 * Only for debugging
 */
void printGlobalData(void)
{
  gdMutex.Lock();

  cout << "OutPutGlobalData***********" << endl; fflush(stdout);
  cout << "lastEmittedTime: " << globalData->localData[1]->timeValue << " --------------------" << endl; fflush(stdout);
  cout << "timeValue: " << globalData->localData[0]->timeValue  << " --------------------" << endl; fflush(stdout);

  long nStates = globalData->modelData.nStates;
  long nAlgebraic = globalData->modelData.nVariablesReal-2*globalData->modelData.nStates;
  long nParameters = globalData->modelData.nParametersReal;

  if (nStates > 0)
  {
    cout << "---States---" << endl; fflush(stdout);
    for (int t = 0; t < nStates; t++)
    {
      cout << t << ": " << get_StateName(t) << ": " << get_StateValue(t) << endl; fflush(stdout);
    }
  }

  if (nAlgebraic > 0)
  {
    cout << "---Algebraics---" << endl; fflush(stdout);
    for (int t = 0; t < nAlgebraic; t++)
    {
      cout << t << ": " << get_AlgebraicName(t) << ": " << get_AlgebraicValue(t) << endl; fflush(stdout);
    }
  }

  if (nParameters > 0)
  {
    cout << "---Parmeters--- " << endl; fflush(stdout);
    for (int t = 0; t < nParameters; t++)
    {
      cout << t << ": " << get_ParameterName(t) << ": "  << get_ParameterValue(t) << endl; fflush(stdout);
    }
  }
  /* /
  if (globalData->nInputVars > 0)
  {
    cout << "---InputVars--- " << endl; fflush(stdout);
    for (int t = 0; t < globalData->nInputVars; t++)
    {
      cout << t << ": " << globalData->inputNames[t].name << ": " << globalData->inputVars[t] << endl; fflush(stdout);
    }
  }

  if (globalData->nOutputVars > 0)
  {
    cout << "---OutputVars--- " << endl; fflush(stdout);
    for (int t = 0; t < globalData->nOutputVars; t++)
    {
      cout << t << ": " << globalData->outputNames[t].name << ": " << globalData->outputVars[t] << endl; fflush(stdout);
    }
  }
  */

  gdMutex.Unlock();
}
