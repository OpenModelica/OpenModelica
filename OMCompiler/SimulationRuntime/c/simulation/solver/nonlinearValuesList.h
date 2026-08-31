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

/*! \file nonlinearValuesList.h
 * Description: This is the C header file for a valueList.
 *
 */

#ifndef _OMC_VALUE_LIST_H
#define _OMC_VALUE_LIST_H

#include "../../util/list.h"

typedef struct VALUES_LIST {
  LIST* valueList;
} VALUES_LIST;

typedef struct VALUE {
  double time;            /* Time value */
  unsigned int size;      /* Length of array values */
  double *values;         /* Array with values */
} VALUE;

VALUES_LIST* allocValueList(unsigned int numberOfList, unsigned int valueSize);
void freeValueList(VALUES_LIST* valueList, unsigned int numberOfLists);

VALUE* createValueElement(unsigned int size, double time, double* values);
void freeValue(VALUE* elem);
void cleanValueList(LIST* valueList, LIST_NODE *startNode);
void cleanValueListbyTime(LIST *valueList, double time);
void removeListNodes(LIST* list, LIST_NODE *node);

void addListElement(LIST* valueList, VALUE* elem);
void getValues(LIST* valueList, double time, double* values, double* oldOutput);

void printValueElement(VALUE* elem);
void printValuesListTimes(LIST* list);

#endif
