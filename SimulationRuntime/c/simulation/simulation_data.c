/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "simulation_data.h"
#include <stdlib.h>
#include <malloc.h>

const size_t SIZERINGBUFFER = 3;

void initializeDataStruc(_X_DATA *data)
{
  SIMULATION_DATA *tmpSimData = 0;
  size_t i = 0;
  /* RingBuffer */
  data->simulationData = 0;
  allocRingBuffer(data->simulationData, SIZERINGBUFFER, sizeof(SIMULATION_DATA));
  if (!data->simulationData)
  {
    THROW("Your memory is not strong enough for our Ringbuffer!");
  }

  /* prepair RingBuffer */
  for(i=0; i<SIZERINGBUFFER; i++)
  {
    tmpSimData = ((SIMULATION_DATA*)getRingData(data->simulationData, (int)SIZERINGBUFFER));

    tmpSimData->realVars = (modelica_real*)calloc(data->modelData.nVariablesReal, sizeof(modelica_real));
    tmpSimData->integerVars = (modelica_integer*)calloc(data->modelData.nVariablesInteger, sizeof(modelica_integer));
    tmpSimData->booleanVars = (modelica_boolean*)calloc(data->modelData.nVariablesBoolean, sizeof(modelica_boolean));
    tmpSimData->stringVars = (modelica_string*)calloc(data->modelData.nVariablesString, sizeof(modelica_string));

    tmpSimData->realVarsPre = (modelica_real*)calloc(data->modelData.nVariablesReal, sizeof(modelica_real));
    tmpSimData->integerVarsPre = (modelica_integer*)calloc(data->modelData.nVariablesInteger, sizeof(modelica_integer));
    tmpSimData->booleanVarsPre = (modelica_boolean*)calloc(data->modelData.nVariablesBoolean, sizeof(modelica_boolean));
    tmpSimData->stringVarsPre = (modelica_string*)calloc(data->modelData.nVariablesString, sizeof(modelica_string));
  }
}