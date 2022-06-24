/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-CurrentYear, Linköping University,
* Department of Computer and Information Science,
* SE-58183 Linköping, Sweden.
*
* All rights reserved.
*
* THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
* AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
* ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
* ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
*
* The OpenModelica software and the Open Source Modelica
* Consortium (OSMC) Public License (OSMC-PL) are obtained
* from Linköping University, either from the above address,
* from the URLs: http://www.ida.liu.se/projects/OpenModelica or
* http://www.openmodelica.org, and in the OpenModelica distribution.
* GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
*
* This program is distributed WITHOUT ANY WARRANTY; without
* even the implied warranty of  MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
* IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
* OF OSMC-PL.
*
* See the full OSMC Public License conditions for more details.
*
*/

/*! \file nonlinearValuesList.h
 * Description: This is the C header file for a valueList.
 *
 */

#ifndef _OMC_VALUE_LIST_H
#define _OMC_VALUE_LIST_H

#include "../../util/list.h"

typedef struct VALUES_LIST
{
  LIST* valueList;
} VALUES_LIST;

typedef struct VALUE
{
  double time;
  unsigned int size;
  double *values;
} VALUE;


VALUES_LIST *allocValueList(const unsigned int numberOfLists);
void freeValueList(VALUES_LIST *valueList, unsigned int numberOfLists);

VALUE* createValueElement(unsigned int size, double time, double* values);
void freeValue(VALUE* elem);
void cleanValueList(VALUES_LIST *valueListm, LIST_NODE* next);
void cleanValueListbyTime(VALUES_LIST *valueList, double time);
void removeListNodes(LIST* list, LIST_NODE *node);

void addListElement(VALUES_LIST* valueList, VALUE* elem);
void getValues(VALUES_LIST* valueList, double time, double* values, double* oldOutput);

void printValueElement(VALUE* elem);
void printValuesListTimes(VALUES_LIST* list);



#endif


