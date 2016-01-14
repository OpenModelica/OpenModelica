#ifndef _REGISTERED_H
#define _REGISTERED_H

#include "addas.h"
#include "adopcs.h"

// Functions to be registered to the server.
// The descriptions of the functions can be found in addas.h and adopcs.h

extern "C" {

static int addaWrite(int aSize, AddaDataItem* apAddaItems[], void** apData);

static int addaGetLeaves(int *apCount, char ***apLeaves, const char* apPath, int aPathLen);

static int addaGetBranches(int *apCount, char ***apBranches, const char* apPath, int aPathLen);

static int addaAddItems(int aSize, AddaDataItem aItemIds[]);

static int addaAddGroup(AddaModuleId aModuleId, int* aGroupId);

static int addaRun(double aTime);

static int addaStop();

static int addaStep();

static int addaGetState(double* aTime, AdopcsSimulationState* aSimulationState);

static int adopcsLogMessage(char* aString, int aNro);

static int addasGetLeafId(const char *apLeaf, const char* apPath, int apPathLen, char **apLeafId);

static char addasSeparation(void);

static int addasCheckItemIds(int aNumberOfItems, AddaDataItem apItemIds[], int apExist[]);

static int addasQueryDataChanged(int aGroupId);

static int addasDelGroup(int aGroupId);

static int addasChangeFrequency(int aGroupId, double aFreq);

static int addasGetFrequency(int aGroupId, double* aFreq);

static int addasIsFlat(AddaBoolean *apFlat);

static int addasGetItemProperties(const char *apItemId, const int apCount,
						   const int *apIds, AddaValue aData[], int aResults[]);

static int adopcsReadyToQuit(AddaModuleId aModuleId);

static int adopcsOpenConnection(AddaModuleId aModuleId);

static int adopcsGetOPCProperties(int* aSynchronizationState, int* aSendAll, float* aTimeOut);

}

#endif /* _REGISTERED_H */
