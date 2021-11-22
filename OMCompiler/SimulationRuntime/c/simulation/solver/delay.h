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

/*! \file delay.h
 */

#ifndef _DELAY_H_
#define _DELAY_H_

#include "../../simulation_data.h"

typedef struct TIME_AND_VALUE
{
  double t; /* time; not named that due to macros */
  double value;
} TIME_AND_VALUE;

typedef struct EXPRESSION_DELAY_BUFFER
{
  long currentIndex;
  long maxExpressionBuffer;
  TIME_AND_VALUE *expressionDelayBuffer;
}EXPRESSION_DELAY_BUFFER;

#ifdef __cplusplus
  extern "C" {
#endif

  double delayImpl(DATA* data, threadData_t *threadData, int exprNumber, double exprValue, double t, double delayTime, double maxDelay);
  void storeDelayedExpression(DATA* data, threadData_t *threadData, int exprNumber, double exprValue, double delayTime, double delayMax);
  double delayZeroCrossing(DATA* data, threadData_t *threadData, unsigned int exprNumber, unsigned int relationIndex, double delayValue, double delayTime, double delayMax);

#ifdef __cplusplus
  }
#endif

#endif
