#ifndef _STUBS_H
#define _STUBS_H

// Stub functions. These functions belong to the Adda interface but are not implemented.
// Their descriptions can be found in addas.h and adopcs.h

#include "addas.h"
#include "adopcs.h"

extern "C" {

static int addasRemoveItems(int aSize, AddaDataItem aItemIds[]);

int addasGetLeafIdType(const int aCount, const char **apLeaf, const char* apPath, int apPathLen, AddaDataType aTypes[], int aSize[]);
int addasCurrentPosition(char **apPosition);
int addasRootName(char **apRootName);


int addasQueryAvailableProperties(const char *apItemId, int *apCount,
								  int **apIds, char ***apDescriptions, AddaDataType **apTypes, int** apSizes);

int addasLookupItemIds(const char *apItemId, const int apCount,
					   const int *apIds, char ***apItemIds, int aResults[]);


int adopcsQueryAvailableSimulationItemIDs(int* aCount, int** aSimulationProperties,
												  char*** aSimulationItemIDs, char*** aDescriptions,
												  AddaDataType** aDataTypes, int** aSizes);


int adopcsQueryAvailableRecordingItemIDs(int* aCount, int** aRecordingProperties,
												  char*** aRecordingItemIDs, char*** aDescriptions,
												  AddaDataType** aDataTypes, int** aSizes);
/*
	Starts to record simulation events
*/
int adopcsRecordingStart(void);


/*
	Stops recording simulation events.

*/
int adopcsRecordingStop(void);


/*
	Winds to the requested time.
	The actual point where the wind ended is returned in revised time.

*/
int adopcsWind(const double aRequestedTime, double *aRevisedTime);


/*
	Returns the begin and end times for the recording.
*/
int adopcsGetRecordingRange(double *aBeginTime, double *aEndTime);


/*
	Starts replaying from the current location
*/
int adopcsReplay(void);


/*
	Returns the malfunctions (and descriptions for them) configured to the simulation model.
	NOTE MEMORY
*/
int adopcsListMalfunctions(int *aCount, char ***aNames, char ***aDescriptions);


/*
	Returns the state of the given malfunction

*/
int adopcsGetMalfunctionState(const char *aName, AdopcsState *aState);
/*
	Sets the state of the given malfunction.

*/
int adopcsSetMalfunctionState(const char *aName, const AdopcsState aState);

/*
	Returns a list of available condition attributes, descriptions and datatypes.
	NOTE MEMORY
*/
int adopcsQueryAvailableConditionProperties(int *aCount, char ***aNames, char ***aDescriptions,
											AddaDataType **aDataTypes, int **aSizes);

/*
	Returns the data (including all the attributes) related to the given condition
	NOTE MEMORY

*/
int adopcsGetConditions(const char *aName, AdopcsCondition *aCondition);

/*
	Sets the data related to the given condition

*/
int adopcsSetConditions(const char *aName, const AdopcsCondition aCondition);



int adopcsExecuteSimulatorCommand(const char* aCommand, char** output);

int adopcsLoad(char* aFileName);
int adopcsSave(char* aFileName);
int adopcsGetCurrentConfigurationFile(char** aFileName);
int adopcsIsDirty(int* aDirty);

}

#endif /* _STUBS_H */
