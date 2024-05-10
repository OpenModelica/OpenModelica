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

/*! \file spatialDistribution.h
 */

#include "../../simulation_data.h"
#include "../../util/doubleEndedList.h"

#ifdef __cplusplus
  extern "C" {
#endif

SPATIAL_DISTRIBUTION_DATA* allocSpatialDistribution(unsigned int nSpatialDistributions);
void freeSpatialDistribution(SPATIAL_DISTRIBUTION_DATA* spatialDistributionData, unsigned int nSpatialDistributions);
void initSpatialDistribution(DATA* data, threadData_t* threadData, unsigned int index, real_array* initialPoints, real_array* initialValues, unsigned int length);
void storeSpatialDistribution(DATA* data, threadData_t *threadData, unsigned int index, double in0, double in1, double posX, int isPositiveVelocity) ;
double spatialDistribution(DATA* data, threadData_t *threadData, unsigned int index, double in0, double in1, double posX, int isPositiveVelocity, double* out1);
double spatialDistributionZeroCrossing (DATA* data, threadData_t *threadData, unsigned int index, unsigned int relationIndex, double posX, int isPositiveVelocity);

void printTransportedQuantity(void* data, int stream, void* nodePointer);

#ifdef __cplusplus
  }
#endif
