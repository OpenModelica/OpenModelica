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

/*! \file initialization_data.h
 */

#ifndef _INITIALIZATION_DATA_H_
#define _INITIALIZATION_DATA_H_

#include "simulation_data.h"
#include "util/omc_error.h"

typedef struct INIT_DATA
{
  /* counts */
  long nVars;                                     /* nStates + nParameters + nDiscrete */
  long nStates;
  long nParameters;
  long nDiscreteReal;                             /* only of typ Real */
  long nInitResiduals;
  long nStartValueResiduals;

  /* vars */
  double *vars;                                   /* array of all unfixed variables, states first */
  double *start;
  double *min;
  double *max;
  double *nominal;                                /* can be zero; nominal[i] not */
  char **name;

  /* equations */
  double *initialResiduals;
  double *residualScalingCoefficients;            /* can be zero; residualScalingCoefficients[i] not */
  double *startValueResidualScalingCoefficients;  /* can be zero; startValueResidualScalingCoefficients[i] not */

  DATA *simData;                                  /* corresponding simulation-data struct */
}INIT_DATA;

#ifdef __cplusplus
#include <cstdlib>
extern "C"
{
#endif

  extern INIT_DATA *initializeInitData(DATA *simData);
  extern void freeInitData(INIT_DATA *initData);

  extern void computeInitialResidualScalingCoefficients(INIT_DATA *initData);

  extern void setZ(INIT_DATA *initData, double *vars);
  extern void setZScaled(INIT_DATA *initData,  double *scaledVars);

  extern void updateSimData(INIT_DATA *initData);

#ifdef __cplusplus
}
#endif

#endif
