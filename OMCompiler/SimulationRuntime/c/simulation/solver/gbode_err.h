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

#ifndef GBODE_ERR_H
#define GBODE_ERR_H

#include "gbode_main.h"

#ifdef __cplusplus
extern "C" {
#endif

struct GB_ERROR_CONTEXT
{
  DATA *data;
  threadData_t *threadData;
  DATA_GBODE *gbData;
  DATA_GBODEF *gbfData;
  modelica_boolean isFast;
};

#define GB_TOLERANCE_SCALING_SAFETY 0.2

int gbEstimateError(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator);

int gbEmbeddedErrorEstimator(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator);
int gbContractiveDefectErrorEstimator(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator);
int gbContractiveFilterErrorEstimator(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator);
int gbTwoStepErrorEstimator(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator);
int gbRichardsonErrorEstimator(GB_ERROR_CONTEXT *context, const GB_ERROR_ESTIMATOR *estimator);

double gbScaledErrorTolerance(double tol, int methodOrder, int estimatorOrder, modelica_boolean richardson);

#ifdef __cplusplus
}
#endif

#endif
