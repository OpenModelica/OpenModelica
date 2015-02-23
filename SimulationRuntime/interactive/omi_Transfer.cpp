/*
 * OpenModelica Interactive (Ver 0.75)
 * Last Modification: 23. May 2011
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: Parham.Vasaiely@eads.com
 *
 * File description: omi_Transfer.cpp
 * Similar to a consumer, the `Transfer' thread tries to get simulation results from
 * the `ResultManager' and send them to the GUI immediately after starting a simulation.
 * If the  communication takes longer than a calculation step,
 * it is also possible to create more than one consumer.
 * The `Transfer' uses a property filter mask containing all property names whoes result values are important for the GUI.
 * The GUI must set this mask using the `setfilter' operation,
 * otherwise the transfer sends only the actual simulation time.
 * This is very useful for increasing the communication speed while sending results to the GUI.
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

#include <iomanip>
#include <iostream>
#include <sstream>
#include "socket.h"
#include "omi_Control.h"
//#include "omi_ResultManager.h"
#include "omi_Transfer.h"
#include "omi_ServiceInterface.h"

using namespace std;

//#pragma comment(lib, "ws2_32.lib")

static const int transfer_default_client_port = 10502;
static const string transfer_default_client_ip = "127.0.0.1"; //localhost ip for transfer client
static string transfer_client_ip = "";
static int transfer_client_port = 0;

static bool debugTransfer = false; //Set true to print out comments which describes the program flow to the console
static bool transferInterrupted = false;

static SimStepData simStepData_from_Transfer; //Simulation Step Data structure used by a Transfer thread to store simulation result data for a specific time step data
static SimStepData* p_SimResDataForw_from_Transfer = 0;

static Socket transfer_client_socket;
static struct sockaddr_in client;

static int sendMessageToClientGUI(long, long, long);
static string createResultMessageWithNames(long, long, long);
static string createResultMessageWithIndex(long, long, long);
static void connectToTransferServer(void);
static int printSSDTransfer(long, long, long);

/**
 * Generates a simulation result message containing all variables and parameters from the filter mask
 * and sends the string to a server via message parsing and tcp/ip
 */
static int sendMessageToClientGUI(long nStates, long nAlgebraic, long nParameters)
{
  bool retValue = true;

  string resultMessage = createResultMessageWithNames(nStates, nAlgebraic, nParameters);

  if (debugTransfer)
  {
    cout << resultMessage << endl; fflush(stdout);
  }

  /*
   * Sends the simulation result data string to a server
   */
  transfer_client_socket.send(resultMessage);

  return retValue;
}

/**
 * creates a result message containing variables and parameters, identifiable by full qualified names
 * e.g. result#var1=0.001:...#par1=9.9:...#end
 */
static string createResultMessageWithNames(long nStates, long nAlgebraic, long nParameters)
{
  ostringstream formatter;
  formatter << "result#" << p_SimResDataForw_from_Transfer->forTimeStep
            << "#";

  //string values;

  int var = 0;
  bool notFirstElement = false; //signal if the element is the first element in the formatter, if its so there is no need for a ":" at the beginning
  for (int i = 0; var < nStates; var++, i++)
  {
    if (debugTransfer)
    {
      cout << p_simDataNamesFilterForTransfer->variablesNames[var] << endl; fflush(stdout);
      cout << p_simDataNames_SimulationResult->statesNames[i] << endl; fflush(stdout);
    }

    if (p_simDataNamesFilterForTransfer->variablesNames[var] != string(""))
    {
      if (notFirstElement)
      {
        formatter << ":";
      }
      else
      {
        notFirstElement = true;
      }
      formatter << p_simDataNamesFilterForTransfer->variablesNames[var]
                << "=" << p_SimResDataForw_from_Transfer->states[i];
    }
  }

  for (int i = 0; var < (nStates + nAlgebraic); var++, i++)
  {
    if (debugTransfer)
    {
      cout << p_simDataNamesFilterForTransfer->variablesNames[var] << endl; fflush(stdout);
      cout << p_simDataNames_SimulationResult->algebraicsNames[i] << endl; fflush(stdout);
    }

    if (p_simDataNamesFilterForTransfer->variablesNames[var] != string(""))
    {
      if (notFirstElement)
      {
        formatter << ":";
      }
      else
      {
        notFirstElement = true;
      }
      formatter << p_simDataNamesFilterForTransfer->variablesNames[var]
                << "=" << p_SimResDataForw_from_Transfer->algebraics[i];
    }
  }
  formatter << "#";
  notFirstElement = false;
  for (int i = 0; i < nParameters; i++)
  {
    /*if (p_simDataNamesFilterForTransfer->parametersNames[i] != string("")) {
      if(notFirstElement)formatter << ":";
      else notFirstElement = true;
      formatter << p_simDataNamesFilterForTransfer->variablesNames[var] << "=" << p_SimResDataForw_from_Transfer->parameters[i];
    }*/
    if (p_simDataNamesFilterForTransfer->parametersNames[i] != string(""))
    {
      if (notFirstElement)
      {
        formatter << ":";
      }
      else
      {
        notFirstElement = true;
      }
      formatter << p_simDataNamesFilterForTransfer->parametersNames[i]
                << "=" << p_SimResDataForw_from_Transfer->parameters[i];
    }
  }
  formatter << "#end";

  return formatter.str();

  //formatter.clear();
}

/**
 * creates a result message containing variables and parameters, identifiable by a specified index instead of a full qualified name.
 * e.g. result#1=0.001:2=3:...#1=9.9:2=80:...#end
 * this will improve the network communication between runtime and a client gui
 * TODO 20100211 pv createResultMessageWithIndex not implemented yet
 */
static string createResultMessageWithIndex(long nStates, long nAlgebraic, long nParameters)
{
  return "";
}

/**
 * Sets the IP and Port of the transfer network client to user specific values
 * To use Default IP (localhost - 127.0.0.1) send an empty string as newIP parameter ("")
 * Note: Call this function before starting simulation
 */
void setTransferIPandPort(string ip, int port)
{
  if (debugTransfer)
  {
    cout << "Transfer IP and Port: " << ip << ":" << port << endl; fflush(stdout);
  }

  transfer_client_ip = ip;
  transfer_client_port = port;
//  connectToTransferServer(); //dynamic change during a running simulation possible with mutex... but necessary?
}

/**
 *  Note: Call this function before starting simulation
 */
void resetTransferIPandPortToDefault(void)
{
  transfer_client_ip = "";
  transfer_client_port = 0;
  //connectToTransferServer(); //dynamic change during a running simulation possible with mutex... but necessary?
}

string getTransferActIP(void)
{
  if(transfer_client_ip != string(""))
  {
    return transfer_client_ip;
  }
  else
  {
    return transfer_default_client_ip;
  }
}

int getTransferActPort(void)
{
  if(transfer_client_port != 0)
  {
    return transfer_client_port;
  }
  else
  {
    return transfer_default_client_port;
  }
}

/**
 * Establishes a connection to a server to transfer the result data to
 */
static void connectToTransferServer(void)
{
  transfer_client_socket.create();

  if (transfer_client_ip != string(""))
  {
    if (transfer_client_port != 0)
    {
      if (debugTransfer)
      {
        cout << "Connect to server with user specific ip and port" << endl; fflush(stdout);
      }
      // Connect to server with user specific ip and port
      transfer_client_socket.connect(transfer_client_ip, transfer_client_port);
    }
    else
    {
      if (debugTransfer)
      {
        cout << "Connect to server with user specific ip and default port (" << transfer_default_client_port << ")" << endl; fflush(stdout);
      }
      // Connect to server with user specific ip and default port
      transfer_client_socket.connect(transfer_client_ip, transfer_default_client_port);
    }
  }
  else
  {
    if (transfer_client_port != 0)
    {
      if (debugTransfer)
      {
        cout << "Connect to server on default IP(localhost) but user specific port" << endl; fflush(stdout);
      }
      // Connect to server on default IP(localhost) but user specific port
      transfer_client_socket.connect(transfer_default_client_ip, transfer_client_port);
    }
    else
    {
      if (debugTransfer)
      {
        cout << "Connect to server on default IP(localhost) and default port (" << transfer_default_client_port << ")" << endl; fflush(stdout);
      }
      // Connect to server on default IP(localhost) and default port (10502)
      transfer_client_socket.connect(transfer_default_client_ip, transfer_default_client_port);
    }
  }
}

/**
 * Only for debugging
 * Prints out the actual Simulation Step Data structure
 */
static int printSSDTransfer(long nStates, long nAlgebraic, long nParameters)
{
  cout << "printSSDTransfer***********" << endl; fflush(stdout);
  cout << "p_simDataNames_SimulationResult->lastEmittedTime: " << p_SimResDataForw_from_Transfer->forTimeStep << " --------------------" << endl; fflush(stdout);

  cout << "---Parmeters--- " << endl; fflush(stdout);
  for (int t = 0; t < nParameters; t++)
  {
    cout << t << ": " /*<< p_simDataNames_SimulationResult->parametersNames[t]*/<< ": " << p_SimResDataForw_from_Transfer->parameters[t] << endl; fflush(stdout);
  }

  if (nAlgebraic > 0)
  {
    cout << "---Algebraics---" << endl; fflush(stdout);
    for (int t = 0; t < nAlgebraic; t++)
    {
      cout << t << ": " /*<< p_simDataNames_SimulationResult->algebraicsNames[t]*/<< ": " << p_SimResDataForw_from_Transfer->algebraics[t] << endl; fflush(stdout);
    }
  }

  if (nStates > 0)
  {
    cout << "---States---" << endl; fflush(stdout);
    for (int t = 0; t < nStates; t++)
    {
      cout << t << ": " /*<< p_simDataNames_SimulationResult->statesNames[t]*/<< ": " << p_SimResDataForw_from_Transfer->states[t] << endl; fflush(stdout);
      cout << t << ": " /*<< p_simDataNames_SimulationResult->stateDerivativesNames[t]*/<< ": " << p_SimResDataForw_from_Transfer->statesDerivatives[t] << endl; fflush(stdout);
    }
  }

  return 0;
}

/**
 * This method tries to get the last calculated simulation result data in a loop
 */
static void doTransfer(long nStates, long nAlgebraic, long nParameters) {

  /* TODO: Fix pause and resume of thread! */
  while (!transferInterrupted)
  {
    mutexSimulationStatus->Lock(); // Lock to see the simulation status.
    if(simulationStatus == SimulationStatus::STOPPED)
    {
      // If the simulation should stop, do nothing for transfer...
      mutexSimulationStatus->Unlock();
    }

    if(simulationStatus == SimulationStatus::SHUTDOWN)
    {
      // If the simulation should shutdown, unlock and break out of the loop.
      mutexSimulationStatus->Unlock();
      break;
    }

    if(simulationStatus == SimulationStatus::RUNNING)
    {
      // If the simulation should continue, increase the semaphore.
      waitForResume->Post();
    }
    // Unlock and see if we need to wait for resume or not.
    mutexSimulationStatus->Unlock();
    waitForResume->Wait(); //wait and reduce semaphore

    getResultData(p_SimResDataForw_from_Transfer);

    if (debugTransfer)//TODO doTransfer
    {
      cout << "Transfer:\tFunct.: doTransfer\tData: time = " << p_SimResDataForw_from_Transfer->forTimeStep << " tank1.h = " << p_SimResDataForw_from_Transfer->states[0]  << endl; fflush(stdout);
    }

    //printSSDTransfer(nStates, nAlgebraic, nParameters);
    sendMessageToClientGUI(nStates, nAlgebraic, nParameters);
    delay((unsigned int)(get_stepSize() * 1000)); //TODO 20100427 pv The sending frequency should depend on the real time, **soft real time
   }
}

/**
 * Transfer Client Thread
 */
THREAD_RET_TYPE threadClientTransfer(THREAD_PARAM_TYPE lpParam)
{
  bool retValue = true; //Not used yet

  p_sdnMutex->Lock();

  long nStates = p_simdatanumbers->nStates;
  long nAlgebraic = p_simdatanumbers->nAlgebraic;
  long nParameters = p_simdatanumbers->nParameters;

  p_sdnMutex->Unlock();

  p_SimResDataForw_from_Transfer = &simStepData_from_Transfer;

  double *statesTMP2 = new double[nStates];
  double *statesDerivativesTMP2 = new double[nStates];
  double *algebraicsTMP2 = new double[nAlgebraic];
  double *parametersTMP2 = new double[nParameters];
  p_SimResDataForw_from_Transfer->states = statesTMP2;
  p_SimResDataForw_from_Transfer->statesDerivatives = statesDerivativesTMP2;
  p_SimResDataForw_from_Transfer->algebraics = algebraicsTMP2;
  p_SimResDataForw_from_Transfer->parameters = parametersTMP2;

  connectToTransferServer();
  doTransfer(nStates, nAlgebraic, nParameters);

  // cleanup
  transfer_client_socket.close();
  transfer_client_socket.cleanup();

  if (debugTransfer)
  {
    cout << "*****Transfer Thread End*****" << endl; fflush(stdout);
  }

  return (THREAD_RET_TYPE_NO_API)retValue;
}
