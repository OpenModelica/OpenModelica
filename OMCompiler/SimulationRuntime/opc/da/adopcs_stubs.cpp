/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

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
