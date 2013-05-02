/*
 * OpenModelica Interactive (Ver 0.75)
 * Last Modification: 23. May 2011
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: Parham.Vasaiely@eads.com
 *
 * File description: omi_Control.cpp
 * The `Control' module is the interface between OMI and a GUI.
 * It is implemented as a single thread to support parallel tasks and independent reactivity.
 * As the main controlling and communication instance at simulation initialisation phase and
 * while simulation is running it manages simulation properties and also behaviour.
 * A client can permanently send operations as messages to the `Control' unit,
 * it can react at any time to feedback from the `Calculation' or `Transfer' threads and
 * it also sends messages to a client, for example error or status messages.
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

#include "socket.h"
#include "omi_ServiceInterface.h"
#include "omi_Control.h"
#include "omi_Calculation.h"
#include "omi_Transfer.h"

using namespace std;

//#pragma comment(lib, "ws2_32.lib")

#define NUMBER_CONSUMER 1
#define NUMBER_PRODUCER 1

#define DEFAULT_CLIENT_PORT 10500
#define DEFAULT_SERVER_PORT 10501

const int control_default_client_port = 10500;
const int control_default_server_port = 10501;
const int transfer_default_server_port = 10502;
const string control_default_client_ip = "127.0.0.1"; //localhost ip for control client
const string control_default_server_ip = "127.0.0.1"; //localhost ip for control server
const string transfer_default_server_ip = "127.0.0.1"; //localhost ip for transfer server

string control_client_ip = "";
int control_client_port = 0;
int control_server_port = 0;

int debugLevelControl = 0; //Set the debug level higher zero to print out messages which describes the program flow to the console [0= debug off, 1= min-debug, 2= max-debug]
bool shutDownSignal = false;
bool error = false;
string messageForClient;
string status;

long nStates, nAlgebraic, nParameters;
bool initDone = false; //True if initialization is done
bool clientDone = false; //True if client ip and port was configured
bool transferDone = false; //True if transfer ip and port was configured

SimulationStatus::type simulationStatus = SimulationStatus::STOPPED;
Mutex mutexSimulationStatus_;
Mutex* mutexSimulationStatus = &mutexSimulationStatus_;
Semaphore waitForResume_(0, NUMBER_PRODUCER + NUMBER_CONSUMER);
Semaphore* waitForResume = &waitForResume_;

Thread producerThreads[NUMBER_PRODUCER];
Thread consumerThreads[NUMBER_CONSUMER];
Thread threadClient;

Semaphore semaphoreMessagesToClient(0, 1);

//General initialization for control thread
static void initialize(void);
static void createProducerAndConsumer(void);
static void createControlClient(void);
static void connectToControlServer(Socket*);
//Organisation and Management of simulation data
static void reInitAll(void);
static void changeSimulationTime(double);
static void changeParameterValues(double, string);
static void setFilterForTransfer(string);
//Controlling for simulation
static void startSimulation(void);
static void stopSimulation(void);
static void pauseSimulation(void);
static void endSimulation(void);
static void shutDown(void);
//Network
//int sendMessageToClient(SOCKET*, string);
static void parseMessageFromClient(string);

static void createMessage(string);
THREAD_RET_TYPE threadClientControl(THREAD_PARAM_TYPE);

//Common help methods
static string parseIP(string);
static int parsePort(string);
static void setValuesFrom_A_SSD(SimStepData*, char, string);
static void parseState(SimStepData*, string);
static void parseAlgebraic(SimStepData*, string);
static void parseParameter(SimStepData*, string);
static void parseNameTypes(string);
static void parseNames(SimDataNamesFilter*, char, string);
static void addNameTo_A_SimDataNames(SimDataNamesFilter*, char, string);

/*****************************************************************
 * Setups for the whole simulation environment
 *****************************************************************/

/**
 * Initializes all needed variables for the control thread
 * initializes the DataNames structure
 */
static void initialize(void)
{
       nStates = get_NStates();
       nAlgebraic = get_NAlgebraic();
       nParameters = get_NParameters();

       initializeSSD_AND_SRDF(nStates, nAlgebraic, nParameters);
       status = "stop";

       if (debugLevelControl > 0)
       {
              cout << "Control:\tMessage: Store the DataNames Start" << endl; fflush(stdout);
       }
       fillSimDataNames_AND_SimDataNamesFilter_WithValuesFromGlobalData(
                     p_simDataNames_SimulationResult, p_simDataNamesFilterForTransfer);

       if (debugLevelControl  > 0)
       {
              cout << "Control:\tMessage: Store the DataNames End" << endl; fflush(stdout);
       }
//TODO initDone is obsolete
       initDone = true;
       if (debugLevelControl  > 0)
       {
              cout << "Control:\tMessage: Initialize done..." << endl; fflush(stdout);
       }
}//End Initialize

/**
 * Creates all producers and consumers
 * The settransferclienturl#ip#port#end operation have to be called first
 */
static void createProducerAndConsumer(void)
{
       std::cout << "Creating producers and consumers!" << std::endl; fflush(stdout);
       if (transferDone)
       {
              for(int i = 0; i < NUMBER_PRODUCER; ++i)
              {
                     producerThreads[i].Create(threadSimulationCalculation);
              }

              for(int i = 0; i < NUMBER_CONSUMER; ++i)
              {
                     consumerThreads[i].Create(threadClientTransfer);
              }

              if (debugLevelControl  > 0)
              {
                     cout << "Control:\tMessage: Create producer and consumer done..." << endl; fflush(stdout);
              }
       }
       else
       {
              //Set Transfer IP & PORT
       }
}

/**
 * Creates the control client thread
 * the setcontrolclienturl#ip#port#end operation have to be called first
 */
static void createControlClient(void)
{
       if (clientDone) {

              /*
               * Creates client thread to communicate with GUI
               */
              threadClient.Create(threadClientControl);
              if (debugLevelControl > 0)
              {
                     cout << "Control:\tMessage: Create client done..." << endl; fflush(stdout);
              }
       }
}

/**
 * Sets the IP and Port of the control network client to user specific values
 * To use Default IP (localhost - 127.0.0.1) send an empty string as ip parameter ("")
 * Note: Call this function before starting simulation
 */
void setControlClientIPandPort(string ip, int port){
       if (debugLevelControl > 0)
       {
              cout << "Control:\tMessage: Control-Client IP and Port: " << ip << ":" << port << endl; fflush(stdout);
       }
       control_client_ip = ip;
       control_client_port = port;
}

/**
 *  Note: Call this function before starting simulation
 */
void resetControlClientIPandPortToDefault(){
       control_client_ip = "";
       control_client_port = 0;
}

/**
 * Sets only the Port of the control network server to user specific value
 * The IP (localhost - 127.0.0.1) mustn't change
 * Note: Call this function before starting simulation
 */
void setControlServerPort(int port){
       control_server_port = port;
}

/**
 *  Note: Call this function before starting simulation
 */
void resetControlServerPortToDefault(){
       control_client_port = 0;
}

/**
 * This function establishes the connection to a client's control server
 * respective user specific network configurations
 */
static void connectToControlServer(Socket* p_sock)
{
       if (control_client_ip != string(""))
       {
              if (control_client_port != 0)
              {
                     if (debugLevelControl > 0)
                     {
                            cout << "Control:\tMessage: Connect to server with user specific ip and port, ip = " << control_client_ip << ", port = " << control_client_port << endl; fflush(stdout);
                     }
                     // Connect to server with user specific ip and port
                     (*p_sock).connect(control_client_ip, control_client_port);
              }
              else
              {
                     if (debugLevelControl > 0)
                     {
                            cout << "Control:\tMessage: Connect to server with user specific ip and default port (10500)"       << endl; fflush(stdout);
                     }
                     // Connect to server with user specific ip and default port
                     (*p_sock).connect(control_client_ip, control_default_client_port);
              }
       }
       else
       {
              if (control_client_port != 0)
              {
                     if (debugLevelControl > 0)
                     {
                            cout << "Control:\tMessage: Connect to server on default IP(localhost) but user specific port" << endl; fflush(stdout);
                     }
                     // Connect to server on default IP(localhost) but user specific port
                     (*p_sock).connect(control_default_client_ip, control_client_port);
              }
              else
              {
                     if (debugLevelControl > 0)
                     {
                            cout << "Control:\tMessage: Connect to server on default IP(localhost) and default port (10500)" << endl; fflush(stdout);
                     }
                     // Connect to server on default IP(localhost) and default port (10502)
                     (*p_sock).connect(control_default_client_ip, control_default_client_port);
              }
       }
}

/*****************************************************************
 * Organisation and Management of simulation data
 * e.g. Parameters, Variables, Simulation Setup...
 * Initialization for simulation data
 *****************************************************************/

/**
 * Re-initializes the whole simulation runtime so the simulation can start from beginning
 */
static void reInitAll(void)
{
   SimStepData* p_ssdAtSimulationTime = getResultDataFirstStart();
   if (debugLevelControl > 0)
   {
      cout << "Control:\tFunct.: reInitAll\tData: p_ssdAtChangedSimulationTime->forTimeStep: " << p_ssdAtSimulationTime->forTimeStep << endl; fflush(stdout);
   }
   setGlobalSimulationValuesFromSimulationStepData(p_ssdAtSimulationTime);
   resetSRDFAfterChangetime(); //Resets the SRDF Array and the producer and consumer semaphores
   resetSSDArrayWithNullSSD(nStates, nAlgebraic, nParameters); //overrides all SSD Slots with nullSSD elements
   if (debugLevelControl > 0)
   {
      cout << "Control:\tFunct.: reInitAll\tData: globalData->lastEmittedTime: " << get_lastEmittedTime() << endl; fflush(stdout);
      cout << "Control:\tFunct.: reInitAll\tData: globalData->timeValue: " << get_timeValue() << endl; fflush(stdout);
   }

}

/**
 * Changes values for parameters for a specified simulationTime
 * The parameter variable contains all names and new values as one string, separated with symbols
 */
static void changeParameterValues(double changedSimulationTime, string parameter)
{
   if (debugLevelControl > 0)
   {
      cout << "Control:\tFunct.: changeParameterValues\tData: time: " << changedSimulationTime << " parameter: " << parameter << endl; fflush(stdout);
   }

   //If the parameter changed while simulation is running, the simulation must go on after changing parameter in global data
   string preStatus = status;
   if (status.compare("start") == 0)
      pauseSimulation();

   SimStepData* p_ssdAtChangedSimulationTime = getResultDataForTime(get_stepSize(), changedSimulationTime);
   if (debugLevelControl > 0)
   {
      cout << "Control:\tFunct.: changeParameterValues\tData: p_ssdAtChangedSimulationTime->forTimeStep: " << p_ssdAtChangedSimulationTime->forTimeStep << endl; fflush(stdout);
   }

   if (p_ssdAtChangedSimulationTime->forTimeStep != -1)
   {
    parseParameter(p_ssdAtChangedSimulationTime, parameter);
    if (debugLevelControl > 0)
    {
       cout << "Control:\tFunct.: parseParameter " << endl; fflush(stdout);
    }
    setGlobalSimulationValuesFromSimulationStepData(p_ssdAtChangedSimulationTime);

    //resetSRDFAfterChangetime(); //Resets the SRDF Array and the producer and consumer semaphores
    //setSimulationTimeReversed(get_stepSize() + changedSimulationTime);
    if (debugLevelControl > 0)
    {
       cout << "Control:\tFunct.: changeParameterValues\tData:globalData->lastEmittedTime: " << get_lastEmittedTime() << endl; fflush(stdout);
       cout << "Control:\tFunct.: changeParameterValues\tData:globalData->timeValue: " << get_timeValue() << endl; fflush(stdout);
    }
   }
   else
   {
     createMessage("Error: Time is not stored anymore");
   }
   //If the parameter changed while simulation is running, the simulation must go on after changing parameter in global data
   if (preStatus.compare("start") == 0)
      startSimulation();
}

/**
 * Changes the simulation time to a previously timestep
 * All values which are stored for this time step will be reused
 */
static void changeSimulationTime(double changedSimulationTime)
{

   double stepSize = get_stepSize();

   //If the parameter changed while simulation is running, the simulation must go on after changing parameter in global data
   string preStatus = status;

   if (status.compare("start") == 0)
      pauseSimulation();

   SimStepData* p_ssdAtChangedSimulationTime = getResultDataForTime(stepSize, changedSimulationTime);

   if (p_ssdAtChangedSimulationTime->forTimeStep >= stepSize)
   {
    setGlobalSimulationValuesFromSimulationStepData(p_ssdAtChangedSimulationTime);
    resetSRDFAfterChangetime(); //Resets the SRDF Array and the producer and consumer semaphores
    //cout << "Control:\tFunct.: changeSimulationTime\tData: get_stepSize() " << stepSize << endl; fflush(stdout);
    setSimulationTimeReversed(stepSize + changedSimulationTime);
   }
   else
   {
    createMessage("Error: Time is not stored anymore");
   }

   //If the parameter changed while simulation is running, the simulation must go on after changing parameter in global data
   if (preStatus.compare("start") == 0)
      startSimulation();
}

/*
 * void changeSimulationTime(double changedSimulationTime) {
   if (debugLevelControl > 0)
   {
      cout << "Control:\tFunct.: changeSimulationTime\tData: time: " << changedSimulationTime << endl; fflush(stdout);
   }

   double stepSize = get_stepSize();

   //If the parameter changed while simulation is running, the simulation must go on after changing parameter in global data
   string preStatus = status;

   if (debugLevelControl > 0)
   {
      cout << "Control:\tFunct.: changeSimulationTime\tData: preStatus: " << preStatus << endl; fflush(stdout);
   }

   if (status.compare("start") == 0)
      pauseSimulation();

   if (debugLevelControl > 0)
   {
      cout << "Control:\tFunct.: changeSimulationTime\tData: preStatus: " << preStatus << endl; fflush(stdout);
   }

   SimStepData* p_ssdAtChangedSimulationTime = getResultDataForTime(stepSize,
         changedSimulationTime);
   if (debugLevelControl > 0)
   {
      cout << "Control:\tFunct.: changeSimulationTime\tData: p_ssdAtChangedSimulationTime->forTimeStep: " << p_ssdAtChangedSimulationTime->forTimeStep << endl; fflush(stdout);
   }

   if (p_ssdAtChangedSimulationTime->forTimeStep >= stepSize)
   {
      setGlobalSimulationValuesFromSimulationStepData(p_ssdAtChangedSimulationTime);
      resetSRDFAfterChangetime(); //Resets the SRDF Array and the producer and consumer semaphores
      cout << "Control:\tFunct.: changeSimulationTime\tData: get_stepSize() " << stepSize << endl; fflush(stdout);
      setSimulationTimeReversed(stepSize + changedSimulationTime);
      if (debugLevelControl > 0)
      {
         cout << "Control:\tFunct.: changeSimulationTime\tData: globalData->lastEmittedTime: " << get_lastEmittedTime() << endl; fflush(stdout);
         cout << "Control:\tFunct.: changeSimulationTime\tData: globalData->timeValue: " << get_timeValue() << endl; fflush(stdout);
      }
   }
   else
   {
      createMessage("Error: Time is not stored anymore");
   }

   //If the parameter changed while simulation is running, the simulation must go on after changing parameter in global data
   if (preStatus.compare("start") == 0)
      startSimulation();
}
 */

/**
 * This method defines the mask for filter transfer
 * variable#parameter
 * If one type doesn't care the space between ## has to be empty
 */
static void setFilterForTransfer(string filterstring)
{
   if (debugLevelControl > 0)
   {
     cout << "Control:\tFunct.: setFilterForTransfer\tData: filterstring: " << filterstring << endl; fflush(stdout);
   }

   parseNameTypes(filterstring);
}

/*****************************************************************
 * Controlling of simulation runtime
 *****************************************************************/

/**
 * Starts all producers and consumers, afterwards the simulation is running
 */
static void startSimulation(void)
{
  if (status.compare("start") != 0) {
    mutexSimulationStatus->Lock();
    simulationStatus = SimulationStatus::RUNNING;
    waitForResume->Post(NUMBER_PRODUCER + NUMBER_CONSUMER);
    mutexSimulationStatus->Unlock();

    status = "start";
    if (debugLevelControl > 0)
      cout << "Control:\tFunct.: startSimulation\tMessage: start done" << endl; fflush( stdout);
  } else {
    if (debugLevelControl > 0)
      cout << "Control:\tFunct.: startSimulation\tMessage: already started" << endl; fflush( stdout);
  }
}

/**
 * interrupts the simulation but the actual state will be save
 */
static void pauseSimulation(void)
{
  if (status.compare("start") == 0) {
    /*Try lock the mutex is necessary, because the producer and consumer threads are working on the
     * global data which is protected by a mutex
     * A lock in pause ensures that the threads finished their job before they will be interrupted
     */

    // Is this necessary anymore?
    lockMutexSSD();

    denied_work_on_GD();

    mutexSimulationStatus->Lock();
    simulationStatus = SimulationStatus::PAUSED;
    mutexSimulationStatus->Unlock();

    allow_work_on_GD();

    releaseMutexSSD();

    status = "pause";
    if (debugLevelControl > 0)
      cout << "Control:\tFunct.: pauseSimulation\tMessage: pause done" << endl; fflush( stdout);
  } else {
    if (debugLevelControl > 0)
      cout << "Control:\tFunct.: pauseSimulation\tMessage: already paused or stopped" << endl; fflush( stdout);
  }
  if (debugLevelControl > 0)
    cout << "Control:\tFunct.: pauseSimulation\t[" << getMinTime_inSSD() << " - " << getMaxTime_inSSD() << "]" << endl; fflush( stdout);
}

/**
 * Interrupts the simulation and reset all simulation data to initial state
 */
static void stopSimulation(void)
{
  if (status.compare("stop") != 0)
  {
    pauseSimulation();

    // Is this necessary anymore: pv yes, because the ssdArray must be synchronized
    lockMutexSSD();
    denied_work_on_GD();

    reInitAll();

    mutexSimulationStatus->Lock();
    simulationStatus = SimulationStatus::STOPPED;
    mutexSimulationStatus->Unlock();

    allow_work_on_GD();
    releaseMutexSSD();

    status = "stop";

    if (debugLevelControl > 0)
      cout << "Control:\tFunct.: stopSimulation\tMessage: stop done" << endl; fflush(stdout);
  }
  else
  {
    if (debugLevelControl > 0)
      cout << "Control:\tFunct.: stopSimulation\tMessage: already stopped" << endl; fflush(stdout);
  }
}

static void endSimulation(void)
{
  mutexSimulationStatus->Lock();
  simulationStatus = SimulationStatus::SHUTDOWN;
  mutexSimulationStatus->Unlock();
  shutDown();
}

/*****************************************************************
 * Standard methods for controlling of simulation runtime
 *****************************************************************/

/**
 * Sets the shutdown signal on true, in order to signal simulation shutdown
 * to all running control threads
 *
 */
static void shutDown(void)
{
  shutDownSignal = true;
}

/*****************************************************************
 * Network Communication between the simulation runtime as server and gui,script file,... as client
 * gobalError management, future network configuration
 *****************************************************************/
/*
int sendMessageToClient(SOCKET* p_ConnectSocket, string message)
{
  int iResult;
  iResult = send(*p_ConnectSocket, message.data(), message.size(), 0);

  if (iResult == SOCKET_ERROR)
  {
    printf("send failed: %d\n", WSAGetLastError());
    closesocket(*p_ConnectSocket);
    WSACleanup();
    return 1;
  }

  return iResult;
}*/

/**
 * Parses a message from a client and calls the needed operation
 * If the message is correct it will be replied with an done message afterwards,
 * otherwise it will be replied with an error message.
 * See OM Documentation for a list of all available operations (Chapter 5.4.2 Operation Messages)
 */
static void parseMessageFromClient(string message)
{
       // IMPORTANT: The Control Server should be able to reply with an error message while the Control Client is not initialized e.g. if an user sends an malformed operation

       /*SYSTEMTIME systime;
        GetSystemTime(&systime);
        cout << systime.wSecond << systime.wMilliseconds << endl; fflush(stdout);
        cout << operation << endl; fflush(stdout); */

       //"start","pause","stop","shutdown","init","setfilter","changetime","changevalue",
       //string::npos is the maximum value for size_t
       string::size_type checkForSharpSymbol = message.find_last_of("#");
       if (checkForSharpSymbol != string::npos) {
              string end = message.substr(checkForSharpSymbol + 1);

              if (end.compare("end") == 0) {
                     //Operation send via message
                     string operation;
                     //Sequence number send via message
                     string seqNumber;
                     //Attributes send via message
                     string attributes;

                     //op#seq#attr
                     string opANDseqANDattr;

                     opANDseqANDattr = message.substr(0, checkForSharpSymbol);
                     string::size_type checkForSharpSymbolAfterOperation =
                                   opANDseqANDattr.find_first_of("#");

                     if (checkForSharpSymbolAfterOperation != string::npos) {
                            operation = opANDseqANDattr.substr(0,
                                          checkForSharpSymbolAfterOperation);

                            //seq#attr
                            string seqANDattr;
                            seqANDattr = opANDseqANDattr.substr(
                                          checkForSharpSymbolAfterOperation + 1);

                            string::size_type checkForSharpSymbolAfterSeqNumber =
                                          seqANDattr.find_first_of("#");
                            if (checkForSharpSymbolAfterSeqNumber != string::npos) { //Used with operations which needs seq and attribute
                                   seqNumber = seqANDattr.substr(0,
                                                 checkForSharpSymbolAfterSeqNumber);
                                   attributes = seqANDattr.substr(
                                                 checkForSharpSymbolAfterSeqNumber + 1);
                                   //Used with operations which doesn't need attributes e.g. start, stop, pause,...
                            } else if ((operation.compare("start") == 0)
                                          || (operation.compare("pause") == 0)
                                          || (operation.compare("stop") == 0)
                                          || (operation.compare("shutdown") == 0)) {
                                   seqNumber = seqANDattr;
                            } else {
                                   createMessage(
                                                 "Error: Missing '#' symbol to separate sequence number from attribute");
                                   return;
                            }
                     } else {
                            createMessage(
                                          "Error: Missing '#' symbol to separate operation from sequence number");
                            return;
                     }
                     /*
                      * To optimize the reaction on a user interaction, most used operations should
                      * be at beginning of the if else queries
                      */
                     if (debugLevelControl > 0) {
                            cout << "Control:\tMessage: Operation: " << operation << endl;
                            fflush( stdout);
                     }

                     if (operation.compare("setcontrolclienturl") == 0) {
                            string ip = parseIP(attributes);

                            if (debugLevelControl > 0) {
                                   cout << "Control:\tMessage: control client ip: " << ip << endl;
                                   fflush( stdout);
                            }

                            int port = parsePort(attributes);
                            if (debugLevelControl > 0) {
                                   cout << " port: " << port << endl;
                                   fflush( stdout);
                            }
                            setControlClientIPandPort(ip, port);
                            clientDone = true;
                            createControlClient();
                     } else if (operation.compare("settransferclienturl") == 0) {
                            string ip = parseIP(attributes);

                            if (debugLevelControl > 0) {
                                   cout << "Control:\tMessage: transfer client ip: " << ip << endl;
                                   fflush( stdout);
                            }

                            int port = parsePort(attributes);

                            if (debugLevelControl > 0) {
                                   cout << " port: " << port << endl;
                                   fflush( stdout);
                            }

                            setTransferIPandPort(ip, port);
                            transferDone = true;
                            createProducerAndConsumer();
                     } else {

                            /*
                             * If the default network settings should be used the clientDone and transferDone variables are false
                             */
                            {
                                   if (!clientDone) {
                                          setControlClientIPandPort(control_default_client_ip,
                                                        control_default_client_port);
                                          clientDone = true;
                                          createControlClient();
                                   }
                                   if (!transferDone) {
                                          setTransferIPandPort(transfer_default_server_ip,
                                                        transfer_default_server_port);
                                          transferDone = true;
                                          createProducerAndConsumer();
                                   }
                            }

                            //This block parses the commonly used messages from a client
                            {
                                   if (operation.compare("changevalue") == 0) {
                                          string::size_type endOfTime = attributes.find_first_of(
                                                        "#");
                                          if (endOfTime != string::npos) {
                                                 string time = attributes.substr(0, endOfTime);
                                                 string parameter = attributes.substr(endOfTime + 1);

                                                 //Check if time is a valid double value
                                                 char* rest = 0;
                                                 double d = strtod(time.c_str(), &rest);
                                                 if (*rest == 0)
                                                        changeParameterValues(d, parameter);
                                                 else {
                                                        createMessage(
                                                                      "Error: The time value is not a valid double value");
                                                        return;
                                                 }
                                          } else {
                                                 createMessage(
                                                               "Error: Missing '#' symbol to separate time from parameter");
                                                 return;
                                          }
                                   } else if (operation.compare("changetime") == 0) {
                                          string time = attributes;
                                          //Check if time is a valid double value
                                          char* rest = 0;
                                          double d = strtod(time.c_str(), &rest);
                                          if (*rest == 0)
                                                 changeSimulationTime(d);
                                          else {
                                                 createMessage(
                                                               "Error: The time value is not a valid double value");
                                                 return;
                                          }
                                   } else if (operation.compare("pause") == 0) {
                                          pauseSimulation();
                                   } else if (operation.compare("start") == 0) {
                                          startSimulation();
                                   } else if (operation.compare("stop") == 0) {
                                          stopSimulation();
                                   } else if (operation.compare("shutdown") == 0) {
                                          endSimulation();
                                   } else if (operation.compare("setfilter") == 0) {
                                          string parameter = attributes;
                                          setFilterForTransfer(parameter);
                                   } else {
                                          createMessage(
                                                        "Error: Unknown operation [please view documentation]");
                                          return;
                                   }
                            }
                     }
              //Send done message if the message was correct and the operation has been executed
              ostringstream formatter;
              formatter << "done#" << seqNumber << "#end";
              createMessage(formatter.str());
              } else {
                     createMessage(
                                   "Error: Missing 'end' string at the end of the message");
                     return;
              }
       } else {
              createMessage("Error: Missing '#' symbol to separate tokens from end");
              return;
       }
}

/*****************************************************************
 * Global Error handling
 *****************************************************************/

static void createMessage(string newmessageForClient)
{
  messageForClient = newmessageForClient;
  semaphoreMessagesToClient.Post();
}

/*****************************************************************
 * Common help methods
 *****************************************************************/

/**
 * This functions parses a string like "ip#port"
 * and returns the ip value of it as an string
 */
static string parseIP(string ip_port)
{
       string::size_type checkForSharpSymbol = ip_port.find_first_of("#");
       if (checkForSharpSymbol != string::npos) {
              string ip = ip_port.substr(0, checkForSharpSymbol);
              return ip;
       } else {
              createMessage("Error: Missing '#' symbol to separate ip from parameter");
              return "";
       }
}

/**
 * This functions parses a string like "ip#port"
 * and returns the port value of it as an int
 */
static int parsePort(string ip_port)
{
       string::size_type checkForSharpSymbol = ip_port.find_first_of("#");
       if (checkForSharpSymbol != string::npos) {
              string port = ip_port.substr(checkForSharpSymbol + 1);
              std::istringstream stream(port);
              int portvalue;
              stream >> portvalue;
              return portvalue;

       } else {
              createMessage(
                            "Error: Missing '#' symbol to separate port from parameter");
              return 0;
       }
}

/**
 * Recursive method to parse all names and values from the string state and set the values to the to the p_SSD parameter
 */
static void parseState(SimStepData* p_SSD, string state)
{
       string::size_type checkForDoublePoint = state.find_first_of(":");
       if (checkForDoublePoint != string::npos) {
              string statenameANDstatevalue = state.substr(0, checkForDoublePoint);
              state = state.substr(checkForDoublePoint + 1);
              setValuesFrom_A_SSD(p_SSD, 's', statenameANDstatevalue);
              parseState(p_SSD, state);
       } else {
              setValuesFrom_A_SSD(p_SSD, 's', state);
       }
}

/**
 * Recursive method to parse all  names and values from the string algebraic and set the values to the to the p_SSD parameter
 */
static void parseAlgebraic(SimStepData* p_SSD, string algebraic)
{
       string::size_type checkForDoublePoint = algebraic.find_first_of(":");
       if (checkForDoublePoint != string::npos) {
              string algnameANDalgvalue = algebraic.substr(0, checkForDoublePoint);
              algebraic = algebraic.substr(checkForDoublePoint + 1);
              setValuesFrom_A_SSD(p_SSD, 'a', algnameANDalgvalue);
              parseAlgebraic(p_SSD, algebraic);
       } else {
              setValuesFrom_A_SSD(p_SSD, 'a', algebraic);
       }
}

/**
 * Recursive method to parse all names and values from the string parameter and set the values to the to the p_SSD parameter
 */
static void parseParameter(SimStepData* p_SSD, string parameter)
{
       string::size_type checkForDoublePoint = parameter.find_first_of(":");
       if (checkForDoublePoint != string::npos) {
              string parnameANDparvalue = parameter.substr(0, checkForDoublePoint);
              parameter = parameter.substr(checkForDoublePoint + 1);
              setValuesFrom_A_SSD(p_SSD, 'p', parnameANDparvalue);
              parseParameter(p_SSD, parameter);
       } else {
              setValuesFrom_A_SSD(p_SSD, 'p', parameter);
       }
}

/*
 ********** Creating Filtermask
 */

/**
 * This method is used to set the filter mask depends on a filter string from the user/gui
 */
static void parseNameTypes(string filterstring)
{
       if (debugLevelControl > 0)
       {
              cout << "Control:\tFunct.: parseNameTypes\tData: filter string: " << filterstring << endl; fflush(stdout);
       }
       string::size_type checkForSharp;
       /*
        * Filter for variables (state and algebraic)
        */
       checkForSharp = filterstring.find_first_of("#");
       if (checkForSharp != string::npos) {
              string variablesNames = filterstring.substr(0, checkForSharp);
              filterstring = filterstring.substr(checkForSharp + 1);
              if (variablesNames.compare("") != 0) //If false, there is no filter for this type
                     parseNames(p_simDataNamesFilterForTransfer, 'v', variablesNames);
       }

       /*
        * Filter for parameter
        */
       string parametersNames = filterstring;
       if (parametersNames.compare("") != 0) //If false, there is no filter for this type
              parseNames(p_simDataNamesFilterForTransfer, 'p', parametersNames);
}

/**
 * parses all names from a type (state, algebraic,...)
 */
static void parseNames(SimDataNamesFilter* p_SDN, char type, string names)
{
       //if(debugLevelControl) { cout << "Type: "<< type << " Name: " << names << endl; fflush(stdout); }
       string::size_type checkForDoublePoint = names.find_first_of(":");
       if (checkForDoublePoint != string::npos) {
              string name = names.substr(0, checkForDoublePoint);//single name
              names = names.substr(checkForDoublePoint + 1); //rest of string with more names
              addNameTo_A_SimDataNames(p_SDN, type, name);
              parseNames(p_SDN, type, names);
       } else {
              addNameTo_A_SimDataNames(p_SDN, type, names);
       }
}

/**
 * Adds a name to a simdatanames structure
 * this is used to set the filter for transfer
 */
static void addNameTo_A_SimDataNames(SimDataNamesFilter* p_SDN, char type, string name)
{
       if (debugLevelControl > 1)
       {
              cout << "Type: " << type << " Name: " << name << endl; fflush(stdout);
       }

       switch (type) {
       case 'v':
              //Check if the variable is an state or an algebraic and what index does it have
       {
              bool found = false;
              int indexInFilterArr = 0;
              for (int var = 0; var < nStates; var++, indexInFilterArr++) {
                     if (debugLevelControl > 1)
                     {
                            cout << "STATENAME: " << p_simDataNames_SimulationResult->statesNames[var] << endl; fflush(stdout);
                     }

                     if (p_simDataNames_SimulationResult->statesNames[var] == name
                                   && p_SDN->variablesNames[indexInFilterArr] == string("")) {
                            p_SDN->variablesNames[indexInFilterArr] = name;
                            found = true;
                            if (debugLevelControl > 1)
                            {
                                   cout << "VARFILTERNAME: " << name << endl; fflush(stdout);
                            }
                            break;
                     }
              }

              if (!found) {
                     if (debugLevelControl > 1)
                     {
                            cout << "is not state" << endl; fflush(stdout);
                     }
                     for (int var = 0; var < (nStates + nAlgebraic); var++, indexInFilterArr++) {
                            if (debugLevelControl > 1)
                            {
                                   cout << "ALGNAME: " << p_simDataNames_SimulationResult->algebraicsNames[var] << endl; fflush(stdout);
                            }
                            if (p_simDataNames_SimulationResult->algebraicsNames[var]
                                          == name && p_SDN->variablesNames[indexInFilterArr]
                                          == string("")) {
                                   p_SDN->variablesNames[indexInFilterArr] = name;
                                   if (debugLevelControl > 1)
                                   {
                                          cout << "VARFILTERNAME: " << name << endl; fflush(stdout);
                                   }
                                   break;
                            }
                     }
              }
       }
              break;

       case 'p':
              for (int var = 0; var < nParameters; var++) {
                     if (p_SDN->parametersNames[var] == string("")) {
                            p_SDN->parametersNames[var] = name;
                            if (debugLevelControl > 1)
                            {
                                   cout << "PARFILTERNAME: " << name << endl; fflush(stdout);
                            }
                            break;
                     }
              }
              break;

       default:
              if (debugLevelControl > 0)
              {
                     cout << "Incorrect Type" << endl; fflush(stdout);
              }
              break;
       }
}
/*
 ********** END Creating Filtermask
 */

/**
 * set a value for a state, algebraic, parameter... from global data
 * the string looks like this "name=value"
 * type is for variable type
 * state: s
 * algebraic: a
 * parameter: p
 * ...
 */
static void setValuesFrom_A_SSD(SimStepData* p_SSD, char type, string nameANDvalue)
{
       bool findElement = false;

       string::size_type checkForEquals = nameANDvalue.find_first_of("=");
       if (checkForEquals != string::npos) {
              string name = nameANDvalue.substr(0, checkForEquals);
              string valueString = nameANDvalue.substr(checkForEquals + 1);

              //Check if time is a valid double value
              char* rest = 0;
              double valueDouble = strtod(valueString.c_str(), &rest);
              if (*rest == 0) {

                     switch (type) {
                     case 's':
                            for (int var = 0; var < nStates; var++) {
                                   if (p_simDataNames_SimulationResult->statesNames[var]
                                                 == string(name)) {
                                          findElement = true;
                                          p_SSD->states[var] = valueDouble;
                                          break;
                                   }
                            }
                            break;

                     case 'a':
                            for (int var = 0; var < nAlgebraic; var++) {
                                   if (p_simDataNames_SimulationResult->algebraicsNames[var]
                                                 == string(name)) {
                                          findElement = true;
                                          p_SSD->algebraics[var] = valueDouble;
                                          break;
                                   }
                            }
                            break;

                     case 'p':
                            for (int var = 0; var < nParameters; var++) {
                                   if (p_simDataNames_SimulationResult->parametersNames[var]
                                                 == string(name)) {
                                          findElement = true;
                                          p_SSD->parameters[var] = valueDouble;
                                          break;
                                   }
                            }
                            break;

                     default:
                            if (debugLevelControl > 0)
                            {
                                   cout << "Incorrect Type" << endl; fflush(stdout);
                            }
                            break;
                     }
              } else {
                     createMessage("Error: The value is not a valid double value");
              }

              if (!findElement)
                     createMessage("Error: Parameter " + name + " not found");
       } else {
              createMessage("Error: Missing '=' between name and value");
       }
}

/*****************************************************************
 * ServerControl and ClientControl Threads
 *****************************************************************/

/**
 * Initial Thread which provides a communication server.
 * Waits for requests from a client
 */
THREAD_RET_TYPE threadServerControl(THREAD_PARAM_TYPE lpParam) {
       Socket sock1;
       sock1.create();
       if (control_server_port != 0) {
              sock1.bind(control_server_port);
       } else {
              sock1.bind(control_default_server_port);
       }

       sock1.listen();
       Socket sock2;
       sock1.accept(sock2);

       initialize();

       while (!shutDownSignal && !error) {
              string operation;
              delay(1000);
              sock2.recv(operation);
              if (operation.compare("") != 0) {
                     if (debugLevelControl > 0)
                     {
                            cout << "Client Message: "; fflush(stdout);
                            cout << operation << endl; fflush(stdout);
                     }
                     parseMessageFromClient(operation);
              }
       }
       sock2.close();
       sock1.close();

       return (THREAD_RET_TYPE_NO_API)error;
}

/**
 * Client Control Thread which communicates with a server do send status or error messages
 */
THREAD_RET_TYPE threadClientControl(THREAD_PARAM_TYPE lpParam) {
       Socket sock;
       sock.create();

       connectToControlServer(&sock);

       //Waits for a message to the client
       while (!shutDownSignal) {
              semaphoreMessagesToClient.Wait();

              bool status = sock.send(messageForClient);
              if (status)
              {
                     cout << "Message send: " << messageForClient << endl; fflush(stdout);
              }
              else
              {
                     cout << "Fail to send" << endl; fflush(stdout);
              }
       }
       sock.close();

       return 0;
}
