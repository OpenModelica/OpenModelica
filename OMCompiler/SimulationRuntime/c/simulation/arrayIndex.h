/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#include "../simulation_data.h"

void allocateArrayIndexMaps(MODEL_DATA *modelData, SIMULATION_INFO *simulationInfo, threadData_t *threadData);

void freeArrayIndexMaps(SIMULATION_INFO *simulationInfo);

size_t calculateLength(DIMENSION_INFO *dimensionInfo, STATIC_INTEGER_DATA *integerParameterData, long nParametersIntegerArray);

size_t multiDimArrayToLinearIndex(DIMENSION_INFO* dimension, size_t* array_index);

size_t* linearToMultiDimArrayIndex(DIMENSION_INFO* dimension, size_t linear_address);

void calculateAllScalarLength(MODEL_DATA* modelData);

size_t scalarArrayVariableSize(void *variableData, enum var_type type, size_t num_variables);

void computeVarIndices(SIMULATION_INFO *simulationInfo, MODEL_DATA *modelData);
