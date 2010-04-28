/*
 * OpenModelica Interactive (Ver 0.7)
 * Last Modification: 16. January 2010
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: vasaie_p@informatik.haw-hamburg.de
 *
 * File description: omi_Control.cpp
 * The “Control” module is the interface between OMI and a GUI.
 * It is implemented as a single thread to support parallel tasks and independent reactivity.
 * As the main controlling and communication instance at simulation initialisation phase and
 * while simulation is running it manages simulation properties and also behaviour.
 * A client can permanently send operations as messages to the “Control” unit,
 * it can react at any time to feedback from the “Calculation” or “Transfer” threads and
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
const string control_default_client_ip = "127.0.0.1"; //localhost ip for control client
const string control_default_server_ip = "127.0.0.1"; //localhost ip for control client

string control_client_ip = "";
int control_client_port = 0;
int control_server_port = 0;

bool debugControl = false; //Set true to print out comments which describes the program flow to the console
bool shutDownSignal = false;
bool error = false;
string messageForClient;
string status;

long nStates, nAlgebraic, nParameters;
bool initDone = false; //True if initialization is done
bool clientDone = false; //True if client ip and port was configured
bool transferDone = false; //True if transfer ip and port was configured

SimulationStatus::type simulationStatus = SimulationStatus::PAUSED;
Mutex mutexSimulationStatus_;
Mutex* mutexSimulationStatus = &mutexSimulationStatus_;
Semaphore waitForResume_(0, NUMBER_PRODUCER + NUMBER_CONSUMER);
Semaphore* waitForResume = &waitForResume_;

Thread producerThreads[NUMBER_PRODUCER];
Thread consumerThreads[NUMBER_CONSUMER];
Thread threadClient;

Semaphore semaphoreMessagesToClient(0, 1);

//General initialization for control thread
void initialize();
void createProducerAndConsumer();
void createControlClient();
void connectToControlServer(Socket*);
//Organisation and Management of simulation data
void reInitAll(void);
void changeSimulationTime(double);
void changeParameterValues(double, string);
void setFilterForTransfer(string);
//Controlling for simulation
void startSimulation(void);
void stopSimulation(void);
void pauseSimulation(void);
void endSimulation(void);
void shutDown(void);
//Network
//int sendMessageToClient(SOCKET*, string);
void parseMessageFromClient(string);

void createMessage(string);
THREAD_RET_TYPE threadClientControl(THREAD_PARAM_TYPE);

//Common help methods
string parseIP(string);
int parsePort(string);
void setValuesFrom_A_SSD(SimStepData*, char, string);
void parseState(SimStepData*, string);
void parseAlgebraic(SimStepData*, string);
void parseParameter(SimStepData*, string);
void parseNameTypes(string);
void parseNames(SimDataNamesFilter*, char, string);
void addNameTo_A_SimDataNames(SimDataNamesFilter*, char, string);

/*****************************************************************
 * Setups for the whole simulation environment
 *****************************************************************/

/**
 * Initializes all needed variables for the control thread
 * initializes the DataNames structure
 */
void initialize() {

	nStates = get_NStates();
	nAlgebraic = get_NAlgebraic();
	nParameters = get_NParameters();

	initializeSSD_AND_SRDF(nStates, nAlgebraic, nParameters);
	status = "stop";

	if (debugControl)
		cout << "***** Store the DataNames *****" << endl;
	fillSimDataNames_AND_SimDataNamesFilter_WithValuesFromGlobalData(
			p_simDataNames_SimulationResult, p_simDataNamesFilterForTransfer);
	if (debugControl)
		cout << "***** End store the DataNames *****" << endl;

	initDone = true;
	if (debugControl)
		cout << "initialize done..." << endl;
}//End Initialize

/**
 * Creates all producers and consumers
 * The settransferclienturl#ip#port#end operation have to be called first
 */
void createProducerAndConsumer() {
	std::cout << "Creating producers and consumers!" << std::endl;
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
	
		if (debugControl)
			cout << "create producer and consumer done..." << endl;
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
void createControlClient() {
	if (clientDone) {

		/*
		 * Creates client thread to communicate with GUI
		 */
		threadClient.Create(threadClientControl);
		if (debugControl)
			cout << "create client done..." << endl;
	} else {
		//Set Client IP & PORT
	}
}

/**
 * Sets the IP and Port of the control network client to user specific values
 * To use Default IP (localhost - 127.0.0.1) send an empty string as ip parameter ("")
 * Note: Call this function before starting simulation
 */
void setControlClientIPandPort(string ip, int port){
	if (debugControl)
		cout << "Control Client IP and Port: " << ip << ":" << port << endl;
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
void connectToControlServer(Socket* p_sock) {

	if (control_client_ip != string("")) {
		if (control_client_port != 0) {
if (debugControl)
				cout << "Connect to server with user specific ip and port, ip = " << control_client_ip << ", port = " << control_client_port
						<< endl;
						// Connect to server with user specific ip and port
			(*p_sock).connect(control_client_ip,
					control_client_port);
		} else{
			if (debugControl)
				cout
						<< "Connect to server with user specific ip and default port (10500)"
						<< endl;
			// Connect to server with user specific ip and default port
			(*p_sock).connect(control_client_ip,
					control_default_client_port);
		}
	} else {
		if (control_client_port != 0) {
			if (debugControl)
				cout
						<< "Connect to server on default IP(localhost) but user specific port"
						<< endl;
			// Connect to server on default IP(localhost) but user specific port
			(*p_sock).connect(control_default_client_ip,
					control_client_port);
		} else {
			if (debugControl)
				cout
						<< "Connect to server on default IP(localhost) and default port (10500)"
						<< endl;
			// Connect to server on default IP(localhost) and default port (10502)
			(*p_sock).connect(control_default_client_ip,
					control_default_client_port);
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
void reInitAll() {
	SimStepData* p_ssdAtSimulationTime = getResultDataFirstStart();
	if (debugControl)
		cout << "p_ssdAtChangedSimulationTime->forTimeStep: "
				<< p_ssdAtSimulationTime->forTimeStep << endl;
	setGlobalSimulationValuesFromSimulationStepData(p_ssdAtSimulationTime);
	resetSRDFAfterChangetime(); //Resets the SRDF Array and the producer and consumer semaphores
	resetSSDArrayWithNullSSD(); //overrides all SSD Slots with nullSSD elements
	if (debugControl)
		cout << "globalData->lastEmittedTime: " << get_lastEmittedTime()
				<< endl;

	*p_forZero = true;
}

/**
 * Changes values for parameters for a specified simulationTime
 * The parameter variable contains all names and new values as one string, separated with symbols
 */
void changeParameterValues(double changedSimulationTime, string parameter) {

	if (debugControl)
		cout << "changeParameterValues --> time: " << changedSimulationTime
				<< " parameter: " << parameter << endl;

	//If the parameter changed while simulation is running, the simulation must go on after changing parameter in global data
	string preStatus = status;
	if (status.compare("start") == 0)
		pauseSimulation();

	SimStepData* p_ssdAtChangedSimulationTime = getResultDataForTime(get_stepSize(),
			changedSimulationTime);
	if (debugControl)
		cout << "p_ssdAtChangedSimulationTime->forTimeStep: "
				<< p_ssdAtChangedSimulationTime->forTimeStep << endl;

	if (p_ssdAtChangedSimulationTime->forTimeStep != -1) {

		parseParameter(p_ssdAtChangedSimulationTime, parameter);
		setGlobalSimulationValuesFromSimulationStepData(
				p_ssdAtChangedSimulationTime);
		resetSRDFAfterChangetime(); //Resets the SRDF Array and the producer and consumer semaphores
		if (debugControl)
			cout << "globalData->lastEmittedTime: " << get_lastEmittedTime()
					<< endl;
	} else {
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
void changeSimulationTime(double changedSimulationTime) {
	if (debugControl)
		cout << "time: " << changedSimulationTime << endl;

	double stepSize = get_stepSize();

	//If the parameter changed while simulation is running, the simulation must go on after changing parameter in global data
	string preStatus = status;
	if (debugControl)
		cout << "preStatus: " << preStatus << endl;
	if (status.compare("start") == 0)
		pauseSimulation();
	if (debugControl)
		cout << "preStatus: " << preStatus << endl;
	SimStepData* p_ssdAtChangedSimulationTime = getResultDataForTime(stepSize,
			changedSimulationTime);
	if (debugControl)
		cout << "p_ssdAtChangedSimulationTime->forTimeStep: "
				<< p_ssdAtChangedSimulationTime->forTimeStep << endl;

	if (p_ssdAtChangedSimulationTime->forTimeStep >= stepSize) {
		setGlobalSimulationValuesFromSimulationStepData(
				p_ssdAtChangedSimulationTime);
		resetSRDFAfterChangetime(); //Resets the SRDF Array and the producer and consumer semaphores
		if (debugControl)
			cout << "globalData->lastEmittedTime: " << get_lastEmittedTime()
					<< endl;
	} else {
		createMessage("Error: Time is not stored anymore");
	}

	//If the parameter changed while simulation is running, the simulation must go on after changing parameter in global data
	if (preStatus.compare("start") == 0)
		startSimulation();

}

/**
 * This method defines the mask for filter transfer
 * variable#parameter
 * If one type doesn't care the space between ## has to be empty
 */
void setFilterForTransfer(string filterstring) {
	if (debugControl)
		cout << "filterstring: " << filterstring << endl;
	parseNameTypes(filterstring);
}

/*****************************************************************
 * Controlling of simulation runtime
 *****************************************************************/

/**
 * Starts all producers and consumers, afterwards the simulation is running
 */
void startSimulation() {

	if (status.compare("start") != 0) {
		mutexSimulationStatus->Lock();
		simulationStatus = SimulationStatus::RUNNING;
		waitForResume->Post(NUMBER_PRODUCER + NUMBER_CONSUMER);
		mutexSimulationStatus->Unlock();

		status = "start";
		cout << "start done" << endl;
	} else {
		cout << "already started" << endl;
	}
}

/**
 * interrupts the simulation but the actual state will be save
 */
void pauseSimulation() {

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
		cout << "pause done" << endl;
	} else {
		cout << "already paused or stopped" << endl;
	}

	cout << "[" << getMinTime_inSSD() << " - " << getMaxTime_inSSD() << "]"
			<< endl;

}

/**
 * Interrupts the simulation and reset all simulation data the beginning
 */
void stopSimulation(void) {
	if (status.compare("stop") != 0) {
		pauseSimulation();

		reInitAll();

		status = "stop";
		cout << "stop done" << endl;
	} else {
		cout << "already stopped" << endl;
	}
}

void endSimulation() {
	mutexSimulationStatus->Lock();
	simulationStatus = SimulationStatus::STOPPED;
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
void shutDown(void) {

	shutDownSignal = true;
}

/*****************************************************************
 * Network Communication between the simulation runtime as server and gui,script file,... as client
 * gobalError management, future network configuration
 *****************************************************************/
/*
int sendMessageToClient(SOCKET* p_ConnectSocket, string message) {
	int iResult;
	iResult = send(*p_ConnectSocket, message.data(), message.size(), 0);

	if (iResult == SOCKET_ERROR) {
		printf("send failed: %d\n", WSAGetLastError());
		closesocket(*p_ConnectSocket);
		WSACleanup();
		return 1;
	}

	return iResult;
}*/

/**
 * Parses the message from the client and calls the needed operation
 */
void parseMessageFromClient(string message) {
	/*SYSTEMTIME systime;
	 GetSystemTime(&systime);
	 cout << systime.wSecond << systime.wMilliseconds << endl;
	 cout << operation << endl;*/

	//"start","pause","stop","shutdown","init","setfilter","changetime","changevalue", 
	//string::npos is the maximum value for size_t
	string::size_type checkForSharpSymbol = message.find_last_of("#");
	if (checkForSharpSymbol != string::npos) {
		string end = message.substr(checkForSharpSymbol + 1);

		if (end.compare("end") == 0) {
			string operationANDAttribute = message.substr(0,
					checkForSharpSymbol);
			string::size_type checkForSharpSymbolAfterOperation =
					operationANDAttribute.find_first_of("#");
			string operation;
			string attributes;
			if (checkForSharpSymbolAfterOperation != string::npos) {
				operation = operationANDAttribute.substr(0,
						checkForSharpSymbolAfterOperation);
				attributes = operationANDAttribute.substr(
						checkForSharpSymbolAfterOperation + 1);
			} else {
				operation = operationANDAttribute;
			}
			/*
			 * To optimize the reaction on a user interaction, most used operations should
			 * be at beginning of the if else queries
			 * TODO 20100218 initDone, clientDone & transferDone should be checked further so the user can get an error message
			 */
			if (debugControl)
				cout << "Operation: " << operation << endl;
			if (operation.compare("changevalue") == 0 && (initDone
					&& clientDone && transferDone)) {
				string::size_type endOfTime = attributes.find_first_of("#");
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
			} else if (operation.compare("changetime") == 0 && (initDone
					&& clientDone && transferDone)) {
				string time = attributes;
				//Check if time is a valid double value
				char* rest = 0;
				double d = strtod(time.c_str(), &rest);
				if (*rest == 0)
					changeSimulationTime(d);
				else{
					createMessage(
							"Error: The time value is not a valid double value");
					return;
				}
			} else if (operation.compare("pause") == 0 && (initDone
					&& clientDone && transferDone)) {
				pauseSimulation();
			} else if (operation.compare("start") == 0 && (initDone
					&& clientDone && transferDone)) {
				startSimulation();
			} else if (operation.compare("stop") == 0 && (initDone
					&& clientDone && transferDone)) {
				stopSimulation();
			} else if (operation.compare("shutdown") == 0 && (initDone
					&& clientDone && transferDone)) {
				endSimulation();
			} else if (operation.compare("setfilter") == 0 && (initDone)) {
				string parameter = attributes;
				setFilterForTransfer(parameter);
			} else if (operation.compare("setcontrolclienturl") == 0) {
				string ip = parseIP(attributes);
				if (debugControl)
					cout << ip << endl;
				int port = parsePort(attributes);
				if (debugControl)
					cout << port << endl;
				setControlClientIPandPort(ip, port);
				clientDone = true;
				createControlClient();
			} else if (operation.compare("settransferclienturl") == 0) {
				string ip = parseIP(attributes);
				int port = parsePort(attributes);
				setTransferIPandPort(ip, port);
				transferDone = true;
				createProducerAndConsumer();
			} else {
				createMessage(
						"Error: Unknown operation [accept: start, pause, stop, shutdown, changevalue, changetime, init]");
				return;
			}
		} else {
			createMessage(
					"Error: Missing 'end' string at the end of the message");
			return;
		}
	} else {
		createMessage("Error: Missing '#' symbol to separate tokens from end");
		return;
	}
	createMessage("done#end"); //TODO 20100217 pv Refactoring because of error handling, otherwise an incorrect also replies with an done#end
}

/*****************************************************************
 * Global Error handling
 *****************************************************************/

void createMessage(string newmessageForClient) {
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
string parseIP(string ip_port) {
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
int parsePort(string ip_port) {
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
void parseState(SimStepData* p_SSD, string state) {
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
void parseAlgebraic(SimStepData* p_SSD, string algebraic) {
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
void parseParameter(SimStepData* p_SSD, string parameter) {
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
void parseNameTypes(string filterstring) {
	if (debugControl)
		cout << filterstring << endl;
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
void parseNames(SimDataNamesFilter* p_SDN, char type, string names) {
	//if(debugControl)cout << "Type: "<< type << " Name: " << names << endl;
	string::size_type checkForDoublePoint = names.find_first_of(":");
	if (checkForDoublePoint != string::npos) {
		string name = names.substr(0, checkForDoublePoint);
		names = names.substr(checkForDoublePoint + 1);
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
void addNameTo_A_SimDataNames(SimDataNamesFilter* p_SDN, char type, string name) {
	if (debugControl)
		cout << "Type: " << type << " Name: " << name << endl;
	switch (type) {
	case 'v':
		//Check if the variable is an state or an algebraic and what index does it have
	{
		bool found = false;
		int indexInFilterArr = 0;
		for (int var = 0; var < nStates; var++, indexInFilterArr++) {
			if (debugControl)
				cout << "STATENAME: "
						<< p_simDataNames_SimulationResult->statesNames[var]
						<< endl;
			if (p_simDataNames_SimulationResult->statesNames[var] == name
					&& p_SDN->variablesNames[indexInFilterArr] == string("")) {
				p_SDN->variablesNames[indexInFilterArr] = name;
				found = true;
				if (debugControl)
					cout << "VARFILTERNAME: " << name << endl;
				break;
			}
		}

		if (!found) {
			if (debugControl)
				cout << "is not state" << endl;
			for (int var = 0; var < (nStates + nAlgebraic); var++, indexInFilterArr++) {
				if (debugControl)
					cout << "ALGNAME: "
							<< p_simDataNames_SimulationResult->algebraicsNames[var]
						<< endl;
				if (p_simDataNames_SimulationResult->algebraicsNames[var]
						== name && p_SDN->variablesNames[indexInFilterArr]
						== string("")) {
					p_SDN->variablesNames[indexInFilterArr] = name;
					if (debugControl)
						cout << "VARFILTERNAME: " << name << endl;
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
				if (debugControl)
					cout << "PARFILTERNAME: " << name << endl;
				break;
			}
		}
		break;

	default:
		if (debugControl)
			cout << "Incorrect Type" << endl;
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
void setValuesFrom_A_SSD(SimStepData* p_SSD, char type, string nameANDvalue) {
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
				if (debugControl)
					cout << "Incorrect Type" << endl;
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
			if (debugControl)
				cout << "Client Message: ";
			if (debugControl)
				cout << operation << endl;
			parseMessageFromClient(operation);
		}
	}
	sock2.close();
	sock1.close();
	
	return (THREAD_RET_TYPE)error;
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
			cout << "Message send: " << messageForClient << endl;
		else
			cout << "Fail to send" << endl;
	}
	sock.close();

	return 0;
}
