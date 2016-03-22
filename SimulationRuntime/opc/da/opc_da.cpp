#include "opc_da.h"
#include "opc_event.h"
#include "opc_utility.h"
#include "adopcs_stubs.h"
#include "opc_registered.h"
#include "simulation/simulation_runtime.h"
#include "OPCregistry.h"

#include <map>
#include <vector>
#include <string>
#include <iostream>
#include <math.h>
#include <pthread.h>

#define FIRST_GROUP_INDEX 8000

static DATA *globalData;
static Event simulation_control_event;

static bool writeFlag = false; // True iff a writing operation has occurred
static std::vector<std::pair<int, Group> > groupVector;
static bool isStarted = false;
static bool isWaiting = false;
static bool isRunning = true;
static pthread_mutex_t mutex_write = PTHREAD_MUTEX_INITIALIZER; // To prevent from writing when simulation is running
static pthread_mutex_t mutex_command = PTHREAD_MUTEX_INITIALIZER; // To ensure that only one function that can change the state is called at a time
static pthread_mutex_t mutex_groups = PTHREAD_MUTEX_INITIALIZER; // To ensure that only one function that can change the groupVector is called at a time
static double p_tout;

static const char *apExeAndArguments;

// If multiple OpenModelica simulations are desired to run simultaneously, this string should be determined
// in a dynamic manner. Now all simulations create an OPC endpoint with the same ProgId.
// The name should in any case contain the substring "OpenModelica".
static const char* apVersionIndependentProgrammaticId = "OpenModelica.OPCDA";

static double p_step;

/* Return true iff a write operation has been performed in the last iteration */
static bool opc_da_write_performed() { return writeFlag; }

/* Return true iff simulation has been started, i.e. at least one iteration has been simulated */
static bool opc_da_is_started() { return isStarted; }

static int addaWrite(int aSize, AddaDataItem* apAddaItems[], void** apData)
{
  adopcsLogMessage((char*)"addaWrite", 1);
  pthread_mutex_lock(&mutex_write);
  pthread_mutex_lock(&mutex_command);
  for (int i = 0; i < aSize; ++i) {
    // Copy the values to the simulator and set the write flag
    memcpy(apAddaItems[i]->data, apData[i], sizeof(double));
    writeFlag = true;
  }
  pthread_mutex_unlock(&mutex_command);
  pthread_mutex_unlock(&mutex_write);
  return 0;
}

static int addaGetLeaves(int *apCount, char ***apLeaves, const char* apPath, int aPathLen)
{
  adopcsLogMessage((char*)"addaGetLeaves", 1);
  std::vector<std::string> leaves;
  char** temp;
  const char *tempPath;
  const char *empty_str = "";

  *apCount = 0; // The number of returned leaves

  tempPath = apPath;
  if (tempPath == NULL) {
    tempPath = empty_str;
  }

  pthread_mutex_lock(&mutex_command);

  MODEL_DATA *modelData = globalData->modelData;

  // Browse through states, their derivatives, algebraics, and parameters and collect all to leaves
  std::cout << "TODO: addaGetLeaves" << std::endl;
  /*extractLeaves(apCount, modelData->statesNames, modelData->nStates, tempPath, leaves);
  extractLeaves(apCount, modelData->stateDerivativesNames, modelData->nStates, tempPath, leaves);
  extractLeaves(apCount, modelData->algebraicsNames, modelData->nAlgebraic, tempPath, leaves);
  extractLeaves(apCount, modelData->parametersNames, modelData->nParameters, tempPath, leaves);*/

  // Copy the leaves into a C string array
  temp = (char**) malloc(*apCount * sizeof(char*));
  for(int i=0; i < *apCount; i++) {
    temp[i] = strdup((char*)(leaves[i].c_str()));
  }
  *apLeaves = temp;

  pthread_mutex_unlock(&mutex_command);

  return 0;
}

static int addaGetBranches(int *apCount, char ***apBranches, const char* apPath, int aPathLen)
{
  adopcsLogMessage((char*)"addaGetBranches", 1);
  std::vector<std::string> branches;
  char** temp;
  const char *tempPath;
  const char *empty_str = "";

  *apCount = 0; // The number of returned leaves

  tempPath = apPath;
  if (tempPath == NULL) {
    tempPath = empty_str;
  }

  pthread_mutex_lock(&mutex_command);

  // Browse through states, their derivatives, algebraics, and parameters and collect all to branches
  std::cout << "TODO: addaGetBranches" << std::endl;
  /*
  extractBranches(apCount, globalData->statesNames, globalData->nStates, tempPath, branches);
  extractBranches(apCount, globalData->stateDerivativesNames, globalData->nStates, tempPath, branches);
  extractBranches(apCount, globalData->algebraicsNames, globalData->nAlgebraic, tempPath, branches);
  extractBranches(apCount, globalData->parametersNames, globalData->nParameters, tempPath, branches);
  */

  // Copy the branches into a C string array
  temp = (char**) malloc(*apCount * sizeof(char*));
  for(int i=0; i < *apCount; i++) {
    temp[i] = strdup((char*)(branches[i].c_str()));
  }
  *apBranches = temp;

  pthread_mutex_unlock(&mutex_command);

  return 0;
}

static int addaAddGroup(AddaModuleId aModuleId, int* aGroupId)
{
  adopcsLogMessage((char*)"addaAddGroup", 1);
  // Create a new group index, a new group, and add the new group to the vector.
  static int nextIndex = FIRST_GROUP_INDEX;
  Group g;
  g.handle = nextIndex++;
  g.frequency = 0.0;
  g.lastOPCEmit = 0.0;
  g.aModuleId = aModuleId;
  *aGroupId = g.handle;

  pthread_mutex_lock(&mutex_groups);

  groupVector.push_back(std::pair<int, Group>(g.handle, g));

  pthread_mutex_unlock(&mutex_groups);

  return 0;
}

static int addaAddItems(int aSize, AddaDataItem aItemIds[])
{
  adopcsLogMessage((char*)"addaAddItems", 1);
  pthread_mutex_lock(&mutex_command);

  for (int i = 0; i < aSize; ++i){

    if (aItemIds[i].id == NULL) {
      continue;
    }

    //All items are of size 1, type double, and Ok.

    aItemIds[i].type = AddaDouble;

    aItemIds[i].size = 1;

    aItemIds[i].quality = AddaOk;

    std::cout << "TODO: addaAddItems" << std::endl;
    /*
    for (int j = 0; j < globalData->nStates; ++j) {
      if (!strcmp(aItemIds[i].id, globalData->statesNames[j])) {
        aItemIds[i].data = &globalData->states[j];
        aItemIds[i].frontItem = &globalData->states[j];
        break;
      }
      if (!strcmp(aItemIds[i].id, globalData->stateDerivativesNames[j])) {
        aItemIds[i].data = &globalData->statesDerivatives[j];
        aItemIds[i].frontItem = &globalData->statesDerivatives[j];
        break;
      }
    }
    for (int j = 0; j < globalData->nAlgebraic; ++j) {
      if (!strcmp(aItemIds[i].id, globalData->algebraicsNames[j])) {
        aItemIds[i].data = &globalData->algebraics[j];
        aItemIds[i].frontItem = &globalData->algebraics[j];
        break;
      }
    }
    for (int j = 0; j < globalData->nParameters; ++j) {
      if (!strcmp(aItemIds[i].id, globalData->parametersNames[j])) {
        aItemIds[i].data = &globalData->parameters[j];
        aItemIds[i].frontItem = &globalData->parameters[j];
        break;
      }
    }
    */

    /*
    If a match is found in itemIds, a data pointer is stored to the AddaDataItem.

    here: frontItem == data
    */
  }

  AddaDataItem** itemPtrTable = NULL;

  itemPtrTable = (AddaDataItem**) malloc(aSize * sizeof(AddaDataItem*));
  for(int i = 0; i < aSize; i++) {
    itemPtrTable[i] = &(aItemIds[i]);
  }

  adopcsConfigurationChanged(aSize, itemPtrTable); // Only a stub implemetation in OPC UA dll

  pthread_mutex_unlock(&mutex_command);

  return 0;
}

static int addaRun(double aTime)
{
  adopcsLogMessage((char*)"addaRun", 1);
  pthread_mutex_lock(&mutex_command);

  isStarted = true;
  isRunning = true;
  simulation_control_event.Release();

  pthread_mutex_unlock(&mutex_command);

  return 0;
}

static int addaStop()
{
  adopcsLogMessage((char*)"addaStop", 1);
  pthread_mutex_lock(&mutex_command);

  isRunning = false;

  pthread_mutex_unlock(&mutex_command);

  return 0;
}

static int addaStep() {
  adopcsLogMessage((char*)"addaStep", 1);
  pthread_mutex_lock(&mutex_command);

  isStarted = true;
  isRunning = false;
  simulation_control_event.Release();

  pthread_mutex_unlock(&mutex_command);
  return 0;
}

static int addaGetState(double* aTime, AdopcsSimulationState* aSimulationState)
{
  adopcsLogMessage((char*)"addaGetState", 1);
  aTime = &p_tout;

  pthread_mutex_lock(&mutex_command);

  // AdopcsRunning when the simulation really is proceeding, AdopcsStopped otherwise
  if (isStarted && !isWaiting)
    *aSimulationState = AdopcsRunning;
  else
    *aSimulationState = AdopcsStopped;

  pthread_mutex_unlock(&mutex_command);

  return 0;
}

// Functions utilized by the OPCKit:

static int adopcsLogMessage(char* aString, int aNro)
{
  //std::cout << "OPCKit: " << aString << std::endl;
  return 0;
}

static int addasGetLeafId(const char *apLeaf, const char* apPath, int apPathLen, char **apLeafId)
{
  adopcsLogMessage((char*)"addasGetLeafId", 1);

  // Doesn't check whether the given leaf exists in the first place

  // Combine the whole path
  std::string tempStr;
  if (apLeaf == NULL) {
    tempStr = apPath;
  }
  else {
    tempStr = std::string(apPath) + std::string(".") + std::string(apLeaf);
  }

  // If the path begins with a '.' (i.e. a variable on the root level), remove that '.'
  size_t found = tempStr.find(".");
  if (found == 0) {
    tempStr = tempStr.erase(0, 1);
  }

  // Move the possible "der(" back to the beginning of the string.
  found = tempStr.find("der(");
  if (found < tempStr.length()) {
    tempStr = tempStr.erase(found, 4);
    tempStr = "der(" + tempStr;
  }

  *apLeafId = strdup((char*)(tempStr.c_str()));

  return 0;
}

static char addasSeparation(void)
{
  adopcsLogMessage((char*)"addasSeparation", 1);
  return '.';
}

static int addasQueryDataChanged(int aGroupId)
{
  adopcsLogMessage((char*)"addasQueryDataChanged", 1);
  pthread_mutex_lock(&mutex_command);

  addasDataChanged(p_tout, aGroupId);

  pthread_mutex_unlock(&mutex_command);

  return 0;
}

static int addasCheckItemIds(int aNumberOfItems, AddaDataItem apItemIds[], int apExist[])
{
  adopcsLogMessage((char*)"addasCheckItemIds", 1);
  pthread_mutex_lock(&mutex_command);

  // Check whether the given item exists and fills the type and size fields.

  for (int i = 0; i < aNumberOfItems; ++i) {
    apExist[i] = 0;

    apItemIds[i].type = AddaDouble;

    apItemIds[i].size = 1;

    std::cout << "TODO: addasCheckItemIds" << std::endl;
    /*
    for (int j = 0; j < globalData->nStates; ++j) {
      if (!strcmp(apItemIds[i].id, globalData->statesNames[j])
          || !strcmp(apItemIds[i].id, globalData->stateDerivativesNames[j])) {
        apExist[i] = 1;
        break;
      }
    }
    for (int j = 0; j < globalData->nAlgebraic; ++j) {
      if (!strcmp(apItemIds[i].id, globalData->algebraicsNames[j])) {
        apExist[i] = 1;
        break;
      }
    }
    for (int j = 0; j < globalData->nParameters; ++j) {
      if (!strcmp(apItemIds[i].id, globalData->parametersNames[j])) {
        apExist[i] = 1;
        break;
      }
    }
    */
  }

  pthread_mutex_unlock(&mutex_command);

  return 0;
}

static int addasIsFlat(AddaBoolean *apFlat)
{
  adopcsLogMessage((char*)"addasIsFlat", 1);
  *apFlat = AddaFalse;
  return 0;
}

static int addasChangeFrequency(int aGroupId, double aFreq)
{
  adopcsLogMessage((char*)"addasChangeFrequency", 1);
  pthread_mutex_lock(&mutex_groups);

  for (std::vector<std::pair<int, Group> >::iterator it = groupVector.begin(), end = groupVector.end(); it != end; ++it){
    if (it->first == aGroupId) {
      if (aFreq < 0.0) {
        aFreq = 0.0;
        it->second.frequency = aFreq;
        pthread_mutex_unlock(&mutex_groups);
        return 2; // This isn't necessarily an error.
      }
      else {
        // Alter the given frequency so that it is a mutltiple of the step size
        double cycles = round(aFreq / p_step);
        aFreq = cycles * p_step;
        it->second.frequency = aFreq;
        pthread_mutex_unlock(&mutex_groups);
        return 0;
      }
    }
  }

  pthread_mutex_unlock(&mutex_groups);

  return 1; // The given group was not found.
}

static int addasGetFrequency(int aGroupId, double* aFreq)
{
  adopcsLogMessage((char*)"addasGetFrequency", 1);
  pthread_mutex_lock(&mutex_groups);

  for (std::vector<std::pair<int, Group> >::iterator it = groupVector.begin(), end = groupVector.end(); it != end; ++it){
    if (it->first == aGroupId) {
      *aFreq = it->second.frequency;
      pthread_mutex_unlock(&mutex_groups);
      return 0;
    }
  }
  pthread_mutex_unlock(&mutex_groups);
  return 1; // The given group was not found.
}

static int adopcsGetOPCProperties(int* aSynchronizationState, int* aSendAll, float* aTimeOut)
{
  adopcsLogMessage((char*)"adopcsGetOPCProperties", 1);
  *aSynchronizationState = 0;
  *aSendAll = 0;
  *aTimeOut = 5.0;
  return 0;
}

static int addasDelGroup(int aGroupId)
{
  adopcsLogMessage((char*)"addasDelGroup", 1);
  pthread_mutex_lock(&mutex_groups);

  for (std::vector<std::pair<int, Group> >::iterator it = groupVector.begin(), end = groupVector.end(); it != end; ++it){
    if (it->first == aGroupId) {
      groupVector.erase(it);
      pthread_mutex_unlock(&mutex_groups);
      return 0;
    }
  }

  pthread_mutex_unlock(&mutex_groups);

  return 1; // The given group was not found.
}

static int addasRemoveItems(int aSize, AddaDataItem aItemIds[])
{
  adopcsLogMessage((char*)"addasRemoveItems", 1);
  //pthread_mutex_lock(&mutex_command);

  // Since adding items has no effect on emitting items (it is used only to pass information from
  // simulation to the OPC (UA) server), there is no need to do anything here.

  //pthread_mutex_unlock(&mutex_command);

  return 0;
}

static int adopcsReadyToQuit(AddaModuleId aModuleId)
{
  adopcsLogMessage((char*)"adopcsReadyToQuit", 1);
  return 0;
}

static int adopcsOpenConnection(AddaModuleId aModuleId)
{
  adopcsLogMessage((char*)"adopcsOpenConnection", 1);
  return 0;
}

static int adopcsFree(void *aPointer)
{
  adopcsLogMessage((char*)"adopcsFree", 1);
  free(aPointer);
  return 0;
}

// Functions used by the simulator

extern "C" int omc_embedded_server_init(DATA *data, double tout, double step, const char *argv_0)
{
  globalData = data;

  // Initialize the COM interface and register a ProgID for the OPC server
  initCOM();
  registerOPCServer(argv_0, apVersionIndependentProgrammaticId);
  uninitCOM();

  int res = 0;
  p_step = step;

  p_tout = tout;

  // Register the function pointers to the OPC UA server
  res += addasRegWrite(addaWrite);
  res += addasRegGetLeaves(addaGetLeaves);
  res += addasRegGetBranches(addaGetBranches);
  res += addasRegAddItems(addaAddItems);
  res += addasRegAddGroup(addaAddGroup);
  res += addasRegRun(addaRun);
  res += addasRegStop(addaStop);
  res += adopcsRegStep(addaStep);
  res += adopcsRegGetState(addaGetState);
  res += adopcsRegLogMessage(&adopcsLogMessage);

  // Register the function pointers used by the OPC kit + the dummy function pointers
  res +=  adopcsRegCheckItemIds(&addasCheckItemIds);
  res +=  adopcsRegQueryDataChanged(&addasQueryDataChanged);
  res +=  adopcsRegDelGroup(&addasDelGroup);
  res +=  adopcsRegChangeFrequency(&addasChangeFrequency);
  res +=  adopcsRegGetFrequency(&addasGetFrequency);
  res +=  adopcsRegRemoveItems(&addasRemoveItems);

  res +=  adopcsRegGetLeafId(&addasGetLeafId);
  res +=  adopcsRegGetLeafIdType(&addasGetLeafIdType);
  res +=  adopcsRegRootName(&addasRootName);
  res +=  adopcsRegIsFlat(&addasIsFlat);

  res +=  adopcsRegQueryAvailableProperties(&addasQueryAvailableProperties);
  res +=  adopcsRegGetItemProperties(&addasGetItemProperties);
  res +=  adopcsRegLookupItemIds(&addasLookupItemIds);
  res +=  adopcsRegSeparation(&addasSeparation);

  res +=  adopcsRegQueryAvailableSimulationItemIDs(&adopcsQueryAvailableSimulationItemIDs);
  res +=  adopcsRegQueryAvailableRecordingItemIDs(&adopcsQueryAvailableRecordingItemIDs);

  res += adopcsRegRecordingStart(&adopcsRecordingStart);
  res += adopcsRegRecordingStop(&adopcsRecordingStop);
  res += adopcsRegWind(&adopcsWind);
  res += adopcsRegGetRecordingRange(&adopcsGetRecordingRange);
  res += adopcsRegReplay(&adopcsReplay);
  res += adopcsRegListMalfunctions(&adopcsListMalfunctions);
  res += adopcsRegGetMalfunctionState(&adopcsGetMalfunctionState);
  res += adopcsRegSetMalfunctionState(&adopcsSetMalfunctionState);
  res += adopcsRegQueryAvailableConditionProperties(&adopcsQueryAvailableConditionProperties);
  res += adopcsRegGetConditions(&adopcsGetConditions);
  res += adopcsRegSetConditions(&adopcsSetConditions);

  res += adopcsRegGetOPCProperties(&adopcsGetOPCProperties);
  res += adopcsRegExecuteSimulatorCommand(&adopcsExecuteSimulatorCommand);
  res += adopcsRegReadyToQuit(&adopcsReadyToQuit);
  res += adopcsRegOpenConnection(&adopcsOpenConnection);
  res += adopcsRegLoad(&adopcsLoad);
  res += adopcsRegSave(&adopcsSave);
  res += adopcsRegGetCurrentConfigurationFile(&adopcsGetCurrentConfigurationFile);
  res += adopcsRegIsDirty(&adopcsIsDirty);

  res += adopcsRegFree(&adopcsFree);

  // Start the OPC UA server
  std::string apOPCNameStr = std::string(apVersionIndependentProgrammaticId) + ".1";
  const char *apOPCName = apOPCNameStr.c_str();
  AddaModuleId aModuleId = COMDAKit;
  res += adopcsInit(apOPCName, aModuleId);

  opc_da_new_iteration(tout); // Fetch the initial values
  pthread_mutex_unlock(&mutex_write);

  // Wait until a start (or step) command is given
  simulation_control_event.Wait();

  if (opc_da_write_performed()) {
    std::cout << "TODO: Restart simulation" << std::endl;
  }

  return res;
}

extern "C" void omc_embedded_server_deinit()
{
  pthread_mutex_unlock(&mutex_write);
  // Do not cut the DA connection when the simulation is finished.
  // Why not? I guess so the client can still be connected and so on.
  // Would it not be better to wait until all clients have disconnected?
  std::cout << "Simulation finished, press enter to shut down the OPC DA server." << std::endl;
  getchar();
  adopcsExit();
  // Initialize the COM interface and unregister the ProgID from the registry
  initCOM();
  unregisterOPCServer(apVersionIndependentProgrammaticId);
  uninitCOM();
}

extern "C" void omc_embedded_server_update(double tout)
{
  // The state of the simulation can be altered only during opc_da_new_iteration(tout) call.
  fprintf(stderr, "opc_da_new_iteration %.8g\n", tout);
  pthread_mutex_lock(&mutex_groups);
  pthread_mutex_lock(&mutex_command);
  writeFlag = false;
  p_tout = tout;
  // Tell the OPC DA server that the data of each group has changed in simulator
  for (std::vector<std::pair<int, Group> >::iterator it = groupVector.begin(), end = groupVector.end(); it != end; ++it){
    // Check whether the frequency of the group has been reached
    // (a small offset to handle rounding errors)
    if (it->second.frequency < p_step
        || it->second.lastOPCEmit + it->second.frequency - (0.01 * p_step) <= tout) {
      it->second.lastOPCEmit = tout;
      pthread_mutex_unlock(&mutex_command);
      pthread_mutex_unlock(&mutex_write);
      addasDataChanged(tout, it->first);
      pthread_mutex_lock(&mutex_write);
      pthread_mutex_lock(&mutex_command);
    }
  }

  if (!isRunning) {
    pthread_mutex_unlock(&mutex_command);
    pthread_mutex_unlock(&mutex_write);
    pthread_mutex_unlock(&mutex_groups);

    isWaiting = true;
    simulation_control_event.Wait();
    isWaiting = false;

    pthread_mutex_lock(&mutex_groups);
    pthread_mutex_lock(&mutex_write);
    pthread_mutex_lock(&mutex_command);
  }

  pthread_mutex_unlock(&mutex_command);
  pthread_mutex_unlock(&mutex_groups);

  if (opc_da_write_performed()) {
  // If a write operation is performed, restart the simulation
  std::cout << "TODO: Restart simulation" << std::endl;
  }
}
