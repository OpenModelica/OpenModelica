#include "adopcs_stubs.h"

#include <string> //debug
#include <iostream> //debug

extern "C" {

void print_message(const char *message)
{
  //std::cout << message << std::endl;
}


/* Dummy functions to be registered to the server. These functions are not mandatory for simple operation. */

int addasGetLeafIdType(const int aCount, const char **apLeaf, const char* apPath, int apPathLen, AddaDataType aTypes[], int aSize[]) { print_message("addasGetLeafIdType"); return 0; }
int addasCurrentPosition(char **apPosition) { print_message("addasCurrentPosition"); return 0; }
int addasRootName(char **apRootName) { print_message("addasRootName"); return 0; }

int addasQueryAvailableProperties(const char *apItemId, int *apCount,
                  int **apIds, char ***apDescriptions, AddaDataType **apTypes, int** apSizes) { print_message("addasQueryAvailableProperties"); return 0; }

int addasGetItemProperties(const char *apItemId, const int apCount,
               const int *apIds, AddaValue aData[], int aResults[]) { print_message("addasGetItemProperties"); return 0; }


int addasLookupItemIds(const char *apItemId, const int apCount,
             const int *apIds, char ***apItemIds, int aResults[]) { print_message("addasLookupItemIds"); return 0; }


int adopcsQueryAvailableSimulationItemIDs(int* aCount, int** aSimulationProperties,
                          char*** aSimulationItemIDs, char*** aDescriptions,
                          AddaDataType** aDataTypes, int** aSizes) { print_message("adopcsQueryAvailableSimulationItemIDs"); return 0; }


int adopcsQueryAvailableRecordingItemIDs(int* aCount, int** aRecordingProperties,
                          char*** aRecordingItemIDs, char*** aDescriptions,
                          AddaDataType** aDataTypes, int** aSizes) { print_message("adopcsQueryAvailableRecordingItemIDs"); return 0; }
/*
  Starts to record simulation events
*/
int adopcsRecordingStart(void) { print_message("adopcsRecordingStart"); return 0; }


/*
  Stops recording simulation events.

*/
int adopcsRecordingStop(void) { print_message("adopcsRecordingStop"); return 0; }


/*
  Winds to the requested time.
  The actual point where the wind ended is returned in revised time.

*/
int adopcsWind(const double aRequestedTime, double *aRevisedTime) { print_message("adopcsWind"); return 0; }


/*
  Returns the begin and end times for the recording.
*/
int adopcsGetRecordingRange(double *aBeginTime, double *aEndTime) { print_message("adopcsGetRecordingRange"); return 0; }


/*
  Starts replaying from the current location
*/
int adopcsReplay(void) { print_message("adopcsReplay"); return 0; }


/*
  Returns the malfunctions (and descriptions for them) configured to the simulation model.
  NOTE MEMORY
*/
int adopcsListMalfunctions(int *aCount, char ***aNames, char ***aDescriptions) { print_message("adopcsListMalfunctions"); return 0; }


/*
  Returns the state of the given malfunction

*/
int adopcsGetMalfunctionState(const char *aName, AdopcsState *aState) { print_message("adopcsGetMalfunctionState"); return 0; }
/*
  Sets the state of the given malfunction.

*/
int adopcsSetMalfunctionState(const char *aName, const AdopcsState aState) { print_message("adopcsSetMalfunctionState"); return 0; }

/*
  Returns a list of available condition attributes, descriptions and datatypes.
  NOTE MEMORY
*/
int adopcsQueryAvailableConditionProperties(int *aCount, char ***aNames, char ***aDescriptions,
                      AddaDataType **aDataTypes, int **aSizes) { print_message("adopcsQueryAvailableConditionProperties"); return 0; }

/*
  Returns the data (including all the attributes) related to the given condition
  NOTE MEMORY

*/
int adopcsGetConditions(const char *aName, AdopcsCondition *aCondition) { print_message("adopcsGetConditions"); return 0; }

/*
  Sets the data related to the given condition

*/
int adopcsSetConditions(const char *aName, const AdopcsCondition aCondition) { print_message("adopcsSetConditions"); return 0; }





int adopcsExecuteSimulatorCommand(const char* aCommand, char** output) { print_message("adopcsExecuteSimulatorCommand"); return 0; }

int adopcsLoad(char* aFileName) { print_message("adopcsLoad"); return 0; }
int adopcsSave(char* aFileName) { print_message("adopcsSave"); return 0; }
int adopcsGetCurrentConfigurationFile(char** aFileName) { print_message("adopcsGetCurrentConfigurationFile"); return 0; }
int adopcsIsDirty(int* aDirty) { print_message("adopcsIsDirty"); return 0; }

}
