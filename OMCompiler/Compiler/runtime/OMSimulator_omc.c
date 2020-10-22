/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


#include <stdio.h>
#include <stdbool.h>
#include "settingsimpl.h"
#include "meta/meta_modelica.h"
#include "ModelicaUtilities.h"
#include "omc_config.h"

#if defined WIN32
  #include <windows.h>
  static HINSTANCE OMSimulatorDLL = NULL;
  #define AddressOf GetProcAddress
  #define freeDLL FreeLibrary
#else
  #include <dlfcn.h>
  static void * OMSimulatorDLL = NULL;
  #define AddressOf dlsym
  #define freeDLL dlclose
#endif

typedef char* (*fnptr_oms_getVersion)();
static fnptr_oms_getVersion oms_getVersion = NULL;

typedef int (*fnptr_oms_addBus)(const char*);
static fnptr_oms_addBus oms_addBus = NULL;

typedef int (*fnptr_oms_addConnection)(const char*,const char*);
static fnptr_oms_addConnection oms_addConnection = NULL;

typedef int (*fnptr_oms_addConnector)(const char*,int,int);
static fnptr_oms_addConnector oms_addConnector = NULL;

typedef int (*fnptr_oms_addConnectorToBus)(const char*,const char*);
static fnptr_oms_addConnectorToBus oms_addConnectorToBus = NULL;

typedef int (*fnptr_oms_addConnectorToTLMBus)(const char*,const char*,const char*);
static fnptr_oms_addConnectorToTLMBus oms_addConnectorToTLMBus = NULL;

typedef int (*fnptr_oms_addDynamicValueIndicator)(const char*,const char*,const char*,double);
static fnptr_oms_addDynamicValueIndicator oms_addDynamicValueIndicator = NULL;

typedef int (*fnptr_oms_addEventIndicator)(const char*);
static fnptr_oms_addEventIndicator oms_addEventIndicator = NULL;

typedef int (*fnptr_oms_addExternalModel)(const char*,const char*,const char*);
static fnptr_oms_addExternalModel oms_addExternalModel = NULL;

typedef int (*fnptr_oms_addSignalsToResults)(const char*,const char*);
static fnptr_oms_addSignalsToResults oms_addSignalsToResults = NULL;

typedef int (*fnptr_oms_addStaticValueIndicator)(const char*,double,double,double);
static fnptr_oms_addStaticValueIndicator oms_addStaticValueIndicator = NULL;

typedef int (*fnptr_oms_addSubModel)(const char*,const char*);
static fnptr_oms_addSubModel oms_addSubModel = NULL;

typedef int (*fnptr_oms_addSystem)(const char*,int);
static fnptr_oms_addSystem oms_addSystem = NULL;

typedef int (*fnptr_oms_addTimeIndicator)(const char*);
static fnptr_oms_addTimeIndicator oms_addTimeIndicator = NULL;

typedef int (*fnptr_oms_addTLMBus)(const char*,int,const int,const int);
static fnptr_oms_addTLMBus oms_addTLMBus = NULL;

typedef int (*fnptr_oms_addTLMConnection)(const char*,const char*,double,double,double,double);
static fnptr_oms_addTLMConnection oms_addTLMConnection = NULL;

typedef int (*fnptr_oms_cancelSimulation_asynchronous)(const char*);
static fnptr_oms_cancelSimulation_asynchronous oms_cancelSimulation_asynchronous = NULL;

typedef int (*fnptr_oms_compareSimulationResults)(const char*,const char*,const char*,double,double);
static fnptr_oms_compareSimulationResults oms_compareSimulationResults = NULL;

typedef int (*fnptr_oms_copySystem)(const char*,const char*);
static fnptr_oms_copySystem oms_copySystem = NULL;

typedef int (*fnptr_oms_delete)(const char*);
static fnptr_oms_delete oms_delete = NULL;

typedef int (*fnptr_oms_deleteConnection)(const char*,const char*);
static fnptr_oms_deleteConnection oms_deleteConnection = NULL;

typedef int (*fnptr_oms_deleteConnectorFromBus)(const char*,const char*);
static fnptr_oms_deleteConnectorFromBus oms_deleteConnectorFromBus = NULL;

typedef int (*fnptr_oms_deleteConnectorFromTLMBus)(const char*,const char*);
static fnptr_oms_deleteConnectorFromTLMBus oms_deleteConnectorFromTLMBus = NULL;

typedef int (*fnptr_oms_export)(const char*,const char*);
static fnptr_oms_export oms_export = NULL;

typedef int (*fnptr_oms_exportDependencyGraphs)(const char*,const char*,const char*,const char*);
static fnptr_oms_exportDependencyGraphs oms_exportDependencyGraphs = NULL;

typedef int (*fnptr_oms_exportSnapshot)(const char*,char**);
static fnptr_oms_exportSnapshot oms_exportSnapshot = NULL;

typedef int (*fnptr_oms_extractFMIKind)(const char*,int*);
static fnptr_oms_extractFMIKind oms_extractFMIKind = NULL;

typedef int (*fnptr_oms_getBoolean)(const char*,bool*);
static fnptr_oms_getBoolean oms_getBoolean = NULL;

typedef int (*fnptr_oms_getFixedStepSize)(const char*,double*);
static fnptr_oms_getFixedStepSize oms_getFixedStepSize = NULL;

typedef int (*fnptr_oms_getInteger)(const char*,int*);
static fnptr_oms_getInteger oms_getInteger = NULL;

typedef int (*fnptr_oms_getModelState)(const char*,int*);
static fnptr_oms_getModelState oms_getModelState = NULL;

typedef int (*fnptr_oms_getReal)(const char*,double*);
static fnptr_oms_getReal oms_getReal = NULL;

typedef int (*fnptr_oms_getSolver)(const char*,int*);
static fnptr_oms_getSolver oms_getSolver = NULL;

typedef int (*fnptr_oms_getStartTime)(const char*,double*);
static fnptr_oms_getStartTime oms_getStartTime = NULL;

typedef int (*fnptr_oms_getStopTime)(const char*,double*);
static fnptr_oms_getStopTime oms_getStopTime = NULL;

typedef int (*fnptr_oms_getSubModelPath)(const char*,char**);
static fnptr_oms_getSubModelPath oms_getSubModelPath = NULL;

typedef int (*fnptr_oms_getSystemType)(const char*,int*);
static fnptr_oms_getSystemType oms_getSystemType = NULL;

typedef int (*fnptr_oms_getTolerance)(const char*,double*,double*);
static fnptr_oms_getTolerance oms_getTolerance = NULL;

typedef int (*fnptr_oms_getVariableStepSize)(const char*,double*,double*,double*);
static fnptr_oms_getVariableStepSize oms_getVariableStepSize = NULL;

typedef int (*fnptr_oms_faultInjection)(const char*,int,double);
static fnptr_oms_faultInjection oms_faultInjection = NULL;

typedef int (*fnptr_oms_importFile)(const char*,char**);
static fnptr_oms_importFile oms_importFile = NULL;

typedef int (*fnptr_oms_importSnapshot)(const char*,const char*);
static fnptr_oms_importSnapshot oms_importSnapshot = NULL;

typedef int (*fnptr_oms_initialize)(const char*);
static fnptr_oms_initialize oms_initialize = NULL;

typedef int (*fnptr_oms_instantiate)(const char*);
static fnptr_oms_instantiate oms_instantiate = NULL;

typedef int (*fnptr_oms_list)(const char*,char**);
static fnptr_oms_list oms_list = NULL;

typedef int (*fnptr_oms_listUnconnectedConnectors)(const char*,char**);
static fnptr_oms_listUnconnectedConnectors oms_listUnconnectedConnectors = NULL;

typedef int (*fnptr_oms_loadSnapshot)(const char*,const char*);
static fnptr_oms_loadSnapshot oms_loadSnapshot = NULL;

typedef int (*fnptr_oms_newModel)(const char*);
static fnptr_oms_newModel oms_newModel = NULL;

typedef int (*fnptr_oms_parseModelName)(const char*,char**);
static fnptr_oms_parseModelName oms_parseModelName = NULL;

typedef int (*fnptr_oms_removeSignalsFromResults)(const char*,const char*);
static fnptr_oms_removeSignalsFromResults oms_removeSignalsFromResults = NULL;

typedef int (*fnptr_oms_rename)(const char*,const char*);
static fnptr_oms_rename oms_rename = NULL;

typedef int (*fnptr_oms_reset)(const char*);
static fnptr_oms_reset oms_reset = NULL;

typedef int (*fnptr_oms_RunFile)(const char*);
static fnptr_oms_RunFile oms_RunFile = NULL;

typedef int (*fnptr_oms_setBoolean)(const char*,bool);
static fnptr_oms_setBoolean oms_setBoolean = NULL;

typedef int (*fnptr_oms_setCommandLineOption)(const char*);
static fnptr_oms_setCommandLineOption oms_setCommandLineOption = NULL;

typedef int (*fnptr_oms_setFixedStepSize)(const char*,double);
static fnptr_oms_setFixedStepSize oms_setFixedStepSize = NULL;

typedef int (*fnptr_oms_setInteger)(const char*,int);
static fnptr_oms_setInteger oms_setInteger = NULL;

typedef int (*fnptr_oms_setLogFile)(const char*);
static fnptr_oms_setLogFile oms_setLogFile = NULL;

typedef int (*fnptr_oms_setLoggingInterval)(const char*,double);
static fnptr_oms_setLoggingInterval oms_setLoggingInterval = NULL;

typedef int (*fnptr_oms_setLoggingLevel)(int);
static fnptr_oms_setLoggingLevel oms_setLoggingLevel = NULL;

typedef int (*fnptr_oms_setReal)(const char*,double);
static fnptr_oms_setReal oms_setReal = NULL;

typedef int (*fnptr_oms_setRealInputDerivative)(const char*,double);
static fnptr_oms_setRealInputDerivative oms_setRealInputDerivative = NULL;

typedef int (*fnptr_oms_setResultFile)(const char*,const char*,int);
static fnptr_oms_setResultFile oms_setResultFile = NULL;

typedef int (*fnptr_oms_setSignalFilter)(const char*,const char*);
static fnptr_oms_setSignalFilter oms_setSignalFilter = NULL;

typedef int (*fnptr_oms_setSolver)(const char*,int);
static fnptr_oms_setSolver oms_setSolver = NULL;

typedef int (*fnptr_oms_setStartTime)(const char*,double);
static fnptr_oms_setStartTime oms_setStartTime = NULL;

typedef int (*fnptr_oms_setStopTime)(const char*,double);
static fnptr_oms_setStopTime oms_setStopTime = NULL;

typedef int (*fnptr_oms_setTempDirectory)(const char*);
static fnptr_oms_setTempDirectory oms_setTempDirectory = NULL;

typedef int (*fnptr_oms_setTLMPositionAndOrientation)(const char*,double,double,double,double,double,double,double,double,double,double,double,double);
static fnptr_oms_setTLMPositionAndOrientation oms_setTLMPositionAndOrientation = NULL;

typedef int (*fnptr_oms_setTLMSocketData)(const char*,const char*,int,int);
static fnptr_oms_setTLMSocketData oms_setTLMSocketData = NULL;

typedef int (*fnptr_oms_setTolerance)(const char*,double,double);
static fnptr_oms_setTolerance oms_setTolerance = NULL;

typedef int (*fnptr_oms_setVariableStepSize)(const char*,double,double,double);
static fnptr_oms_setVariableStepSize oms_setVariableStepSize = NULL;

typedef int (*fnptr_oms_setWorkingDirectory)(const char*);
static fnptr_oms_setWorkingDirectory oms_setWorkingDirectory = NULL;

typedef int (*fnptr_oms_simulate)(const char*);
static fnptr_oms_simulate oms_simulate = NULL;

typedef int (*fnptr_oms_stepUntil)(const char*,double);
static fnptr_oms_stepUntil oms_stepUntil = NULL;

typedef int (*fnptr_oms_terminate)(const char*);
static fnptr_oms_terminate oms_terminate = NULL;


void resolveFunctionNames()
{
  oms_getVersion = (fnptr_oms_getVersion)AddressOf(OMSimulatorDLL, "oms_getVersion");
  oms_addBus = (fnptr_oms_addBus)AddressOf(OMSimulatorDLL, "oms_addBus");
  oms_addConnection = (fnptr_oms_addConnection)AddressOf(OMSimulatorDLL, "oms_addConnection");
  oms_addConnector = (fnptr_oms_addConnector)AddressOf(OMSimulatorDLL, "oms_addConnector");
  oms_addConnectorToBus = (fnptr_oms_addConnectorToBus)AddressOf(OMSimulatorDLL, "oms_addConnectorToBus");
  oms_addConnectorToTLMBus = (fnptr_oms_addConnectorToTLMBus)AddressOf(OMSimulatorDLL, "oms_addConnectorToTLMBus");
  oms_addDynamicValueIndicator = (fnptr_oms_addDynamicValueIndicator)AddressOf(OMSimulatorDLL, "oms_addDynamicValueIndicator");
  oms_addEventIndicator = (fnptr_oms_addEventIndicator)AddressOf(OMSimulatorDLL, "oms_addEventIndicator");
  oms_addExternalModel = (fnptr_oms_addExternalModel)AddressOf(OMSimulatorDLL, "oms_addExternalModel");
  oms_addSignalsToResults = (fnptr_oms_addSignalsToResults)AddressOf(OMSimulatorDLL, "oms_addSignalsToResults");
  oms_addStaticValueIndicator = (fnptr_oms_addStaticValueIndicator)AddressOf(OMSimulatorDLL, "oms_addStaticValueIndicator");
  oms_addSubModel = (fnptr_oms_addSubModel)AddressOf(OMSimulatorDLL, "oms_addSubModel");
  oms_addSystem = (fnptr_oms_addSystem)AddressOf(OMSimulatorDLL, "oms_addSystem");
  oms_addTimeIndicator = (fnptr_oms_addTimeIndicator)AddressOf(OMSimulatorDLL, "oms_addTimeIndicator");
  oms_addTLMBus = (fnptr_oms_addTLMBus)AddressOf(OMSimulatorDLL, "oms_addTLMBus");
  oms_addTLMConnection = (fnptr_oms_addTLMConnection)AddressOf(OMSimulatorDLL, "oms_addTLMConnection");
  oms_cancelSimulation_asynchronous = (fnptr_oms_cancelSimulation_asynchronous)AddressOf(OMSimulatorDLL, "oms_cancelSimulation_asynchronous");
  oms_compareSimulationResults = (fnptr_oms_compareSimulationResults)AddressOf(OMSimulatorDLL, "oms_compareSimulationResults");
  oms_copySystem = (fnptr_oms_copySystem)AddressOf(OMSimulatorDLL, "oms_copySystem");
  oms_delete = (fnptr_oms_delete)AddressOf(OMSimulatorDLL, "oms_delete");
  oms_deleteConnection = (fnptr_oms_deleteConnection)AddressOf(OMSimulatorDLL, "oms_deleteConnection");
  oms_deleteConnectorFromBus = (fnptr_oms_deleteConnectorFromBus)AddressOf(OMSimulatorDLL, "oms_deleteConnectorFromBus");
  oms_deleteConnectorFromTLMBus = (fnptr_oms_deleteConnectorFromTLMBus)AddressOf(OMSimulatorDLL, "oms_deleteConnectorFromTLMBus");
  oms_export = (fnptr_oms_export)AddressOf(OMSimulatorDLL, "oms_export");
  oms_exportDependencyGraphs = (fnptr_oms_exportDependencyGraphs)AddressOf(OMSimulatorDLL, "oms_exportDependencyGraphs");
  oms_exportSnapshot = (fnptr_oms_exportSnapshot)AddressOf(OMSimulatorDLL, "oms_exportSnapshot");
  oms_extractFMIKind = (fnptr_oms_extractFMIKind)AddressOf(OMSimulatorDLL, "oms_extractFMIKind");
  oms_getBoolean = (fnptr_oms_getBoolean)AddressOf(OMSimulatorDLL, "oms_getBoolean");
  oms_getFixedStepSize = (fnptr_oms_getFixedStepSize)AddressOf(OMSimulatorDLL, "oms_getFixedStepSize");
  oms_getInteger = (fnptr_oms_getInteger)AddressOf(OMSimulatorDLL, "oms_getInteger");
  oms_getModelState = (fnptr_oms_getModelState)AddressOf(OMSimulatorDLL, "oms_getModelState");
  oms_getReal = (fnptr_oms_getReal)AddressOf(OMSimulatorDLL, "oms_getReal");
  oms_getSolver = (fnptr_oms_getSolver)AddressOf(OMSimulatorDLL, "oms_getSolver");
  oms_getStartTime = (fnptr_oms_getStartTime)AddressOf(OMSimulatorDLL, "oms_getStartTime");
  oms_getStopTime = (fnptr_oms_getStopTime)AddressOf(OMSimulatorDLL, "oms_getStopTime");
  oms_getSubModelPath = (fnptr_oms_getSubModelPath)AddressOf(OMSimulatorDLL, "oms_getSubModelPath");
  oms_getSystemType = (fnptr_oms_getSystemType)AddressOf(OMSimulatorDLL, "oms_getSystemType");
  oms_getTolerance = (fnptr_oms_getTolerance)AddressOf(OMSimulatorDLL, "oms_getTolerance");
  oms_getVariableStepSize = (fnptr_oms_getVariableStepSize)AddressOf(OMSimulatorDLL, "oms_getVariableStepSize");
  oms_faultInjection = (fnptr_oms_faultInjection)AddressOf(OMSimulatorDLL, "oms_faultInjection");
  oms_importFile = (fnptr_oms_importFile)AddressOf(OMSimulatorDLL, "oms_importFile");
  oms_importSnapshot = (fnptr_oms_importSnapshot)AddressOf(OMSimulatorDLL, "oms_importSnapshot");
  oms_initialize = (fnptr_oms_initialize)AddressOf(OMSimulatorDLL, "oms_initialize");
  oms_instantiate = (fnptr_oms_instantiate)AddressOf(OMSimulatorDLL, "oms_instantiate");
  oms_list = (fnptr_oms_list)AddressOf(OMSimulatorDLL, "oms_list");
  oms_listUnconnectedConnectors = (fnptr_oms_listUnconnectedConnectors)AddressOf(OMSimulatorDLL, "oms_listUnconnectedConnectors");
  oms_loadSnapshot = (fnptr_oms_loadSnapshot)AddressOf(OMSimulatorDLL, "oms_loadSnapshot");
  oms_newModel = (fnptr_oms_newModel)AddressOf(OMSimulatorDLL, "oms_newModel");
  oms_parseModelName = (fnptr_oms_parseModelName)AddressOf(OMSimulatorDLL, "oms_parseModelName");
  oms_removeSignalsFromResults = (fnptr_oms_removeSignalsFromResults)AddressOf(OMSimulatorDLL, "oms_removeSignalsFromResults");
  oms_rename = (fnptr_oms_rename)AddressOf(OMSimulatorDLL, "oms_rename");
  oms_reset = (fnptr_oms_reset)AddressOf(OMSimulatorDLL, "oms_reset");
  oms_RunFile = (fnptr_oms_RunFile)AddressOf(OMSimulatorDLL, "oms_RunFile");
  oms_setBoolean = (fnptr_oms_setBoolean)AddressOf(OMSimulatorDLL, "oms_setBoolean");
  oms_setCommandLineOption = (fnptr_oms_setCommandLineOption)AddressOf(OMSimulatorDLL, "oms_setCommandLineOption");
  oms_setFixedStepSize = (fnptr_oms_setFixedStepSize)AddressOf(OMSimulatorDLL, "oms_setFixedStepSize");
  oms_setInteger = (fnptr_oms_setInteger)AddressOf(OMSimulatorDLL, "oms_setInteger");
  oms_setLogFile = (fnptr_oms_setLogFile)AddressOf(OMSimulatorDLL, "oms_setLogFile");
  oms_setLoggingInterval = (fnptr_oms_setLoggingInterval)AddressOf(OMSimulatorDLL, "oms_setLoggingInterval");
  oms_setLoggingLevel = (fnptr_oms_setLoggingLevel)AddressOf(OMSimulatorDLL, "oms_setLoggingLevel");
  oms_setReal = (fnptr_oms_setReal)AddressOf(OMSimulatorDLL, "oms_setReal");
  oms_setRealInputDerivative = (fnptr_oms_setRealInputDerivative)AddressOf(OMSimulatorDLL, "oms_setRealInputDerivative");
  oms_setResultFile = (fnptr_oms_setResultFile)AddressOf(OMSimulatorDLL, "oms_setResultFile");
  oms_setSignalFilter = (fnptr_oms_setSignalFilter)AddressOf(OMSimulatorDLL, "oms_setSignalFilter");
  oms_setSolver = (fnptr_oms_setSolver)AddressOf(OMSimulatorDLL, "oms_setSolver");
  oms_setStartTime = (fnptr_oms_setStartTime)AddressOf(OMSimulatorDLL, "oms_setStartTime");
  oms_setStopTime = (fnptr_oms_setStopTime)AddressOf(OMSimulatorDLL, "oms_setStopTime");
  oms_setTempDirectory = (fnptr_oms_setTempDirectory)AddressOf(OMSimulatorDLL, "oms_setTempDirectory");
  oms_setTLMPositionAndOrientation = (fnptr_oms_setTLMPositionAndOrientation)AddressOf(OMSimulatorDLL, "oms_setTLMPositionAndOrientation");
  oms_setTLMSocketData = (fnptr_oms_setTLMSocketData)AddressOf(OMSimulatorDLL, "oms_setTLMSocketData");
  oms_setTolerance = (fnptr_oms_setTolerance)AddressOf(OMSimulatorDLL, "oms_setTolerance");
  oms_setVariableStepSize = (fnptr_oms_setVariableStepSize)AddressOf(OMSimulatorDLL, "oms_setVariableStepSize");
  oms_setWorkingDirectory = (fnptr_oms_setWorkingDirectory)AddressOf(OMSimulatorDLL, "oms_setWorkingDirectory");
  oms_simulate = (fnptr_oms_simulate)AddressOf(OMSimulatorDLL, "oms_simulate");
  oms_stepUntil = (fnptr_oms_stepUntil)AddressOf(OMSimulatorDLL, "oms_stepUntil");
  oms_terminate = (fnptr_oms_terminate)AddressOf(OMSimulatorDLL, "oms_terminate");
}

extern const int OMSimulator_loadDLL()
{
  // check for OMSimulatorDLL instance for the first time this function called and load the library
  if(!OMSimulatorDLL)
  {
    const char *path = SettingsImpl__getInstallationDirectoryPath();
    const char* fullFileName;
    #if defined WIN32
      GC_asprintf(&fullFileName, "%s%s%s%s",path,"/bin/","libOMSimulator",CONFIG_DLL_EXT);
      OMSimulatorDLL = LoadLibrary(fullFileName);
    #else
      GC_asprintf(&fullFileName, "%s%s%s%s%s%s",path,"/lib/",CONFIG_TRIPLE,"/omc/","libOMSimulator",CONFIG_DLL_EXT);
      OMSimulatorDLL = dlopen(fullFileName,RTLD_LAZY);
    #endif
    if(!OMSimulatorDLL)
    {
      printf("Could not load the dynamic library %s Exiting the program\n",fullFileName);
      exit(0);
    }
    // resolve function signatures one time during initialization
    resolveFunctionNames();
  }
  return 0;
}

extern const int OMSimulator_unloadDLL()
{
  if(!OMSimulatorDLL)
  {
    printf("OMSimulator instance is not found, Please load the OMSimulator instance using loadOMSimulator()\n");
    exit(0);
  }
  freeDLL(OMSimulatorDLL);
  return 0;
}

extern const char* OMSimulator_oms_getVersion()
{
  if(!oms_getVersion)
  {
    printf("could not locate the function oms_getVersion\n");
    exit(0);
  }
  char *res=oms_getVersion();
  return strcpy(ModelicaAllocateString(strlen(res)), res);
}

extern const int OMSimulator_oms_addBus(const char* cref)
{
  if(!oms_addBus)
  {
    printf("could not locate the function oms_addBus\n");
    exit(0);
  }
  int status = oms_addBus(cref);
  return status;
}

extern const int OMSimulator_oms_addConnection(const char* crefA, const char* crefB)
{
  if(!oms_addConnection)
  {
    printf("could not locate the function oms_addConnection\n");
    exit(0);
  }
  int status = oms_addConnection(crefA,crefB);
  return status;
}

extern const int OMSimulator_oms_addConnector(const char* cref, int causality, int type)
{
  if(!oms_addConnector)
  {
    printf("could not locate the function oms_addConnector\n");
    exit(0);
  }
  int status = oms_addConnector(cref,causality,type);
  return status;
}

extern const int OMSimulator_oms_addConnectorToBus(const char* busCref, const char* connectorCref)
{
  if(!oms_addConnectorToBus)
  {
    printf("could not locate the function oms_addConnectorToBus\n");
    exit(0);
  }
  int status = oms_addConnectorToBus(busCref,connectorCref);
  return status;
}

extern const int OMSimulator_oms_addConnectorToTLMBus(const char* busCref, const char* connectorCref, const char* type)
{
  if(!oms_addConnectorToTLMBus)
  {
    printf("could not locate the function oms_addConnectorToTLMBus\n");
    exit(0);
  }
  int status = oms_addConnectorToTLMBus(busCref,connectorCref,type);
  return status;
}

extern const int OMSimulator_oms_addDynamicValueIndicator(const char* signal, const char* lower, const char* upper, double stepSize)
{
  if(!oms_addDynamicValueIndicator)
  {
    printf("could not locate the function oms_addDynamicValueIndicator\n");
    exit(0);
  }
  int status = oms_addDynamicValueIndicator(signal,lower,upper,stepSize);
  return status;
}

extern const int OMSimulator_oms_addEventIndicator(const char* signal)
{
  if(!oms_addEventIndicator)
  {
    printf("could not locate the function oms_addEventIndicator\n");
    exit(0);
  }
  int status = oms_addEventIndicator(signal);
  return status;
}

extern const int OMSimulator_oms_addExternalModel(const char* cref, const char* path, const char* startscript)
{
  if(!oms_addExternalModel)
  {
    printf("could not locate the function oms_addExternalModel\n");
    exit(0);
  }
  int status = oms_addExternalModel(cref,path,startscript);
  return status;
}

extern const int OMSimulator_oms_addSignalsToResults(const char* cref, const char* regex)
{
  if(!oms_addSignalsToResults)
  {
    printf("could not locate the function oms_addSignalsToResults\n");
    exit(0);
  }
  int status = oms_addSignalsToResults(cref,regex);
  return status;
}

extern const int OMSimulator_oms_addStaticValueIndicator(const char* signal, double lower, double upper, double stepSize)
{
  if(!oms_addStaticValueIndicator)
  {
    printf("could not locate the function oms_addStaticValueIndicator\n");
    exit(0);
  }
  int status = oms_addStaticValueIndicator(signal,lower,upper,stepSize);
  return status;
}

extern const int OMSimulator_oms_addSubModel(const char* cref, const char* fmuPath)
{
  if(!oms_addSubModel)
  {
    printf("could not locate the function oms_addSubModel\n");
    exit(0);
  }
  int status = oms_addSubModel(cref,fmuPath);
  return status;
}

extern const int OMSimulator_oms_addSystem(const char* cref, int type)
{
  if(!oms_addSystem)
  {
    printf("could not locate the function oms_addSystem\n");
    exit(0);
  }
  int status = oms_addSystem(cref,type);
  return status;
}

extern const int OMSimulator_oms_addTimeIndicator(const char* signal)
{
  if(!oms_addTimeIndicator)
  {
    printf("could not locate the function oms_addTimeIndicator\n");
    exit(0);
  }
  int status = oms_addTimeIndicator(signal);
  return status;
}

extern const int OMSimulator_oms_addTLMBus(const char* cref, int domain, const int dimensions, const int interpolation)
{
  if(!oms_addTLMBus)
  {
    printf("could not locate the function oms_addTLMBus\n");
    exit(0);
  }
  int status = oms_addTLMBus(cref,domain,dimensions,interpolation);
  return status;
}

extern const int OMSimulator_oms_addTLMConnection(const char* crefA, const char* crefB, double delay, double alpha, double linearimpedance, double angularimpedance)
{
  if(!oms_addTLMConnection)
  {
    printf("could not locate the function oms_addTLMConnection\n");
    exit(0);
  }
  int status = oms_addTLMConnection(crefA,crefB,delay,alpha,linearimpedance,angularimpedance);
  return status;
}

extern const int OMSimulator_oms_cancelSimulation_asynchronous(const char* cref)
{
  if(!oms_cancelSimulation_asynchronous)
  {
    printf("could not locate the function oms_cancelSimulation_asynchronous\n");
    exit(0);
  }
  int status = oms_cancelSimulation_asynchronous(cref);
  return status;
}

extern const int OMSimulator_oms_compareSimulationResults(const char* filenameA, const char* filenameB, const char* var, double relTol, double absTol)
{
  if(!oms_compareSimulationResults)
  {
    printf("could not locate the function oms_compareSimulationResults\n");
    exit(0);
  }
  int status = oms_compareSimulationResults(filenameA,filenameB,var,relTol,absTol);
  return status;
}

extern const int OMSimulator_oms_copySystem(const char* source, const char* target)
{
  if(!oms_copySystem)
  {
    printf("could not locate the function oms_copySystem\n");
    exit(0);
  }
  int status = oms_copySystem(source,target);
  return status;
}

extern const int OMSimulator_oms_delete(const char* cref)
{
  if(!oms_delete)
  {
    printf("could not locate the function oms_delete\n");
    exit(0);
  }
  int status = oms_delete(cref);
  return status;
}

extern const int OMSimulator_oms_deleteConnection(const char* crefA, const char* crefB)
{
  if(!oms_deleteConnection)
  {
    printf("could not locate the function oms_deleteConnection\n");
    exit(0);
  }
  int status = oms_deleteConnection(crefA,crefB);
  return status;
}

extern const int OMSimulator_oms_deleteConnectorFromBus(const char* busCref, const char* connectorCref)
{
  if(!oms_deleteConnectorFromBus)
  {
    printf("could not locate the function oms_deleteConnectorFromBus\n");
    exit(0);
  }
  int status = oms_deleteConnectorFromBus(busCref,connectorCref);
  return status;
}

extern const int OMSimulator_oms_deleteConnectorFromTLMBus(const char* busCref, const char* connectorCref)
{
  if(!oms_deleteConnectorFromTLMBus)
  {
    printf("could not locate the function oms_deleteConnectorFromTLMBus\n");
    exit(0);
  }
  int status = oms_deleteConnectorFromTLMBus(busCref,connectorCref);
  return status;
}

extern const int OMSimulator_oms_export(const char* cref, const char* filename)
{
  if(!oms_export)
  {
    printf("could not locate the function oms_export\n");
    exit(0);
  }
  int status = oms_export(cref,filename);
  return status;
}

extern const int OMSimulator_oms_exportDependencyGraphs(const char* cref, const char* initialization, const char* event, const char* simulation)
{
  if(!oms_exportDependencyGraphs)
  {
    printf("could not locate the function oms_exportDependencyGraphs\n");
    exit(0);
  }
  int status = oms_exportDependencyGraphs(cref,initialization,event,simulation);
  return status;
}

extern const int OMSimulator_oms_exportSnapshot(const char* cref, char** contents)
{
  if(!oms_exportSnapshot)
  {
    printf("could not locate the function oms_exportSnapshot\n");
    exit(0);
  }
  int status = oms_exportSnapshot(cref,contents);
  return status;
}

extern const int OMSimulator_oms_extractFMIKind(const char* filename, int* kind)
{
  if(!oms_extractFMIKind)
  {
    printf("could not locate the function oms_extractFMIKind\n");
    exit(0);
  }
  int status = oms_extractFMIKind(filename,kind);
  return status;
}

extern const int OMSimulator_oms_getBoolean(const char* cref, bool* value)
{
  if(!oms_getBoolean)
  {
    printf("could not locate the function oms_getBoolean\n");
    exit(0);
  }
  int status = oms_getBoolean(cref,value);
  return status;
}

extern const int OMSimulator_oms_getFixedStepSize(const char* cref, double* stepSize)
{
  if(!oms_getFixedStepSize)
  {
    printf("could not locate the function oms_getFixedStepSize\n");
    exit(0);
  }
  int status = oms_getFixedStepSize(cref,stepSize);
  return status;
}

extern const int OMSimulator_oms_getInteger(const char* cref, int* value)
{
  if(!oms_getInteger)
  {
    printf("could not locate the function oms_getInteger\n");
    exit(0);
  }
  int status = oms_getInteger(cref,value);
  return status;
}

extern const int OMSimulator_oms_getModelState(const char* cref, int* modelState)
{
  if(!oms_getModelState)
  {
    printf("could not locate the function oms_getModelState\n");
    exit(0);
  }
  int status = oms_getModelState(cref,modelState);
  return status;
}

extern const int OMSimulator_oms_getReal(const char* cref, double* value)
{
  if(!oms_getReal)
  {
    printf("could not locate the function oms_getReal\n");
    exit(0);
  }
  int status = oms_getReal(cref,value);
  return status;
}

extern const int OMSimulator_oms_getSolver(const char* cref, int* solver)
{
  if(!oms_getSolver)
  {
    printf("could not locate the function oms_getSolver\n");
    exit(0);
  }
  int status = oms_getSolver(cref,solver);
  return status;
}

extern const int OMSimulator_oms_getStartTime(const char* cref, double* startTime)
{
  if(!oms_getStartTime)
  {
    printf("could not locate the function oms_getStartTime\n");
    exit(0);
  }
  int status = oms_getStartTime(cref,startTime);
  return status;
}

extern const int OMSimulator_oms_getStopTime(const char* cref, double* stopTime)
{
  if(!oms_getStopTime)
  {
    printf("could not locate the function oms_getStopTime\n");
    exit(0);
  }
  int status = oms_getStopTime(cref,stopTime);
  return status;
}

extern const int OMSimulator_oms_getSubModelPath(const char* cref, char** path)
{
  if(!oms_getSubModelPath)
  {
    printf("could not locate the function oms_getSubModelPath\n");
    exit(0);
  }
  int status = oms_getSubModelPath(cref,path);
  return status;
}

extern const int OMSimulator_oms_getSystemType(const char* cref, int* type)
{
  if(!oms_getSystemType)
  {
    printf("could not locate the function oms_getSystemType\n");
    exit(0);
  }
  int status = oms_getSystemType(cref,type);
  return status;
}

extern const int OMSimulator_oms_getTolerance(const char* cref, double* absoluteTolerance, double* relativeTolerance)
{
  if(!oms_getTolerance)
  {
    printf("could not locate the function oms_getTolerance\n");
    exit(0);
  }
  int status = oms_getTolerance(cref,absoluteTolerance,relativeTolerance);
  return status;
}

extern const int OMSimulator_oms_getVariableStepSize(const char* cref, double* initialStepSize, double* minimumStepSize, double* maximumStepSize)
{
  if(!oms_getVariableStepSize)
  {
    printf("could not locate the function oms_getVariableStepSize\n");
    exit(0);
  }
  int status = oms_getVariableStepSize(cref,initialStepSize,minimumStepSize,maximumStepSize);
  return status;
}

extern const int OMSimulator_oms_faultInjection(const char* signal, int faultType, double faultValue)
{
  if(!oms_faultInjection)
  {
    printf("could not locate the function oms_faultInjection\n");
    exit(0);
  }
  int status = oms_faultInjection(signal,faultType,faultValue);
  return status;
}

extern const int OMSimulator_oms_importFile(const char* filename, char** cref)
{
  if(!oms_importFile)
  {
    printf("could not locate the function oms_importFile\n");
    exit(0);
  }
  int status = oms_importFile(filename,cref);
  return status;
}

extern const int OMSimulator_oms_importSnapshot(const char* cref, const char* snapshot)
{
  if(!oms_importSnapshot)
  {
    printf("could not locate the function oms_importSnapshot\n");
    exit(0);
  }
  int status = oms_importSnapshot(cref,snapshot);
  return status;
}

extern const int OMSimulator_oms_initialize(const char* cref)
{
  if(!oms_initialize)
  {
    printf("could not locate the function oms_initialize\n");
    exit(0);
  }
  int status = oms_initialize(cref);
  return status;
}

extern const int OMSimulator_oms_instantiate(const char* cref)
{
  if(!oms_instantiate)
  {
    printf("could not locate the function oms_instantiate\n");
    exit(0);
  }
  int status = oms_instantiate(cref);
  return status;
}

extern const int OMSimulator_oms_list(const char* cref, char** contents)
{
  if(!oms_list)
  {
    printf("could not locate the function oms_list\n");
    exit(0);
  }
  int status = oms_list(cref,contents);
  return status;
}

extern const int OMSimulator_oms_listUnconnectedConnectors(const char* cref, char** contents)
{
  if(!oms_listUnconnectedConnectors)
  {
    printf("could not locate the function oms_listUnconnectedConnectors\n");
    exit(0);
  }
  int status = oms_listUnconnectedConnectors(cref,contents);
  return status;
}

extern const int OMSimulator_oms_loadSnapshot(const char* cref, const char* snapshot)
{
  if(!oms_loadSnapshot)
  {
    printf("could not locate the function oms_loadSnapshot\n");
    exit(0);
  }
  int status = oms_loadSnapshot(cref,snapshot);
  return status;
}

extern const int OMSimulator_oms_newModel(const char* cref)
{
  if(!oms_newModel)
  {
    printf("could not locate the function oms_newModel\n");
    exit(0);
  }
  int status = oms_newModel(cref);
  return status;
}

extern const int OMSimulator_oms_parseModelName(const char* contents, char** cref)
{
  if(!oms_parseModelName)
  {
    printf("could not locate the function oms_parseModelName\n");
    exit(0);
  }
  int status = oms_parseModelName(contents,cref);
  return status;
}

extern const int OMSimulator_oms_removeSignalsFromResults(const char* cref, const char* regex)
{
  if(!oms_removeSignalsFromResults)
  {
    printf("could not locate the function oms_removeSignalsFromResults\n");
    exit(0);
  }
  int status = oms_removeSignalsFromResults(cref,regex);
  return status;
}

extern const int OMSimulator_oms_rename(const char* cref, const char* newCref)
{
  if(!oms_rename)
  {
    printf("could not locate the function oms_rename\n");
    exit(0);
  }
  int status = oms_rename(cref,newCref);
  return status;
}

extern const int OMSimulator_oms_reset(const char* cref)
{
  if(!oms_reset)
  {
    printf("could not locate the function oms_reset\n");
    exit(0);
  }
  int status = oms_reset(cref);
  return status;
}

extern const int OMSimulator_oms_RunFile(const char* filename)
{
  if(!oms_RunFile)
  {
    printf("could not locate the function oms_RunFile\n");
    exit(0);
  }
  int status = oms_RunFile(filename);
  return status;
}

extern const int OMSimulator_oms_setBoolean(const char* cref, bool value)
{
  if(!oms_setBoolean)
  {
    printf("could not locate the function oms_setBoolean\n");
    exit(0);
  }
  int status = oms_setBoolean(cref,value);
  return status;
}

extern const int OMSimulator_oms_setCommandLineOption(const char* cmd)
{
  if(!oms_setCommandLineOption)
  {
    printf("could not locate the function oms_setCommandLineOption\n");
    exit(0);
  }
  int status = oms_setCommandLineOption(cmd);
  return status;
}

extern const int OMSimulator_oms_setFixedStepSize(const char* cref, double stepSize)
{
  if(!oms_setFixedStepSize)
  {
    printf("could not locate the function oms_setFixedStepSize\n");
    exit(0);
  }
  int status = oms_setFixedStepSize(cref,stepSize);
  return status;
}

extern const int OMSimulator_oms_setInteger(const char* cref, int value)
{
  if(!oms_setInteger)
  {
    printf("could not locate the function oms_setInteger\n");
    exit(0);
  }
  int status = oms_setInteger(cref,value);
  return status;
}

extern const int OMSimulator_oms_setLogFile(const char* filename)
{
  if(!oms_setLogFile)
  {
    printf("could not locate the function oms_setLogFile\n");
    exit(0);
  }
  int status = oms_setLogFile(filename);
  return status;
}

extern const int OMSimulator_oms_setLoggingInterval(const char* cref, double loggingInterval)
{
  if(!oms_setLoggingInterval)
  {
    printf("could not locate the function oms_setLoggingInterval\n");
    exit(0);
  }
  int status = oms_setLoggingInterval(cref,loggingInterval);
  return status;
}

extern const int OMSimulator_oms_setLoggingLevel(int logLevel)
{
  if(!oms_setLoggingLevel)
  {
    printf("could not locate the function oms_setLoggingLevel\n");
    exit(0);
  }
  int status = oms_setLoggingLevel(logLevel);
  return status;
}

extern const int OMSimulator_oms_setReal(const char* cref, double value)
{
  if(!oms_setReal)
  {
    printf("could not locate the function oms_setReal\n");
    exit(0);
  }
  int status = oms_setReal(cref,value);
  return status;
}

extern const int OMSimulator_oms_setRealInputDerivative(const char* cref, double value)
{
  if(!oms_setRealInputDerivative)
  {
    printf("could not locate the function oms_setRealInputDerivative\n");
    exit(0);
  }
  int status = oms_setRealInputDerivative(cref,value);
  return status;
}

extern const int OMSimulator_oms_setResultFile(const char* cref, const char* filename, int bufferSize)
{
  if(!oms_setResultFile)
  {
    printf("could not locate the function oms_setResultFile\n");
    exit(0);
  }
  int status = oms_setResultFile(cref,filename,bufferSize);
  return status;
}

extern const int OMSimulator_oms_setSignalFilter(const char* cref, const char* regex)
{
  if(!oms_setSignalFilter)
  {
    printf("could not locate the function oms_setSignalFilter\n");
    exit(0);
  }
  int status = oms_setSignalFilter(cref,regex);
  return status;
}

extern const int OMSimulator_oms_setSolver(const char* cref, int solver)
{
  if(!oms_setSolver)
  {
    printf("could not locate the function oms_setSolver\n");
    exit(0);
  }
  int status = oms_setSolver(cref,solver);
  return status;
}

extern const int OMSimulator_oms_setStartTime(const char* cref, double startTime)
{
  if(!oms_setStartTime)
  {
    printf("could not locate the function oms_setStartTime\n");
    exit(0);
  }
  int status = oms_setStartTime(cref,startTime);
  return status;
}

extern const int OMSimulator_oms_setStopTime(const char* cref, double stopTime)
{
  if(!oms_setStopTime)
  {
    printf("could not locate the function oms_setStopTime\n");
    exit(0);
  }
  int status = oms_setStopTime(cref,stopTime);
  return status;
}

extern const int OMSimulator_oms_setTempDirectory(const char* newTempDir)
{
  if(!oms_setTempDirectory)
  {
    printf("could not locate the function oms_setTempDirectory\n");
    exit(0);
  }
  int status = oms_setTempDirectory(newTempDir);
  return status;
}

extern const int OMSimulator_oms_setTLMPositionAndOrientation(const char* cref, double x1, double x2, double x3, double A11, double A12, double A13, double A21, double A22, double A23, double A31, double A32, double A33)
{
  if(!oms_setTLMPositionAndOrientation)
  {
    printf("could not locate the function oms_setTLMPositionAndOrientation\n");
    exit(0);
  }
  int status = oms_setTLMPositionAndOrientation(cref,x1,x2,x3,A11,A12,A13,A21,A22,A23,A31,A32,A33);
  return status;
}

extern const int OMSimulator_oms_setTLMSocketData(const char* cref, const char* address, int managerPort, int monitorPort)
{
  if(!oms_setTLMSocketData)
  {
    printf("could not locate the function oms_setTLMSocketData\n");
    exit(0);
  }
  int status = oms_setTLMSocketData(cref,address,managerPort,monitorPort);
  return status;
}

extern const int OMSimulator_oms_setTolerance(const char* cref, double absoluteTolerance, double relativeTolerance)
{
  if(!oms_setTolerance)
  {
    printf("could not locate the function oms_setTolerance\n");
    exit(0);
  }
  int status = oms_setTolerance(cref,absoluteTolerance,relativeTolerance);
  return status;
}

extern const int OMSimulator_oms_setVariableStepSize(const char* cref, double initialStepSize, double minimumStepSize, double maximumStepSize)
{
  if(!oms_setVariableStepSize)
  {
    printf("could not locate the function oms_setVariableStepSize\n");
    exit(0);
  }
  int status = oms_setVariableStepSize(cref,initialStepSize,minimumStepSize,maximumStepSize);
  return status;
}

extern const int OMSimulator_oms_setWorkingDirectory(const char* newWorkingDir)
{
  if(!oms_setWorkingDirectory)
  {
    printf("could not locate the function oms_setWorkingDirectory\n");
    exit(0);
  }
  int status = oms_setWorkingDirectory(newWorkingDir);
  return status;
}

extern const int OMSimulator_oms_simulate(const char* cref)
{
  if(!oms_simulate)
  {
    printf("could not locate the function oms_simulate\n");
    exit(0);
  }
  int status = oms_simulate(cref);
  return status;
}

extern const int OMSimulator_oms_stepUntil(const char* cref, double stopTime)
{
  if(!oms_stepUntil)
  {
    printf("could not locate the function oms_stepUntil\n");
    exit(0);
  }
  int status = oms_stepUntil(cref,stopTime);
  return status;
}

extern const int OMSimulator_oms_terminate(const char* cref)
{
  if(!oms_terminate)
  {
    printf("could not locate the function oms_terminate\n");
    exit(0);
  }
  int status = oms_terminate(cref);
  return status;
}

