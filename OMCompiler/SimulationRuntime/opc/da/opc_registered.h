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
