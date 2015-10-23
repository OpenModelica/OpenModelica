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
 * Description: This is a C implementation of a value database
 *              based on a list. It's purpose is to be used by a
 *              a non-linear solver in OpenModelica in order to
 *              guess next value by extrapolation or interpolation.
 *              Assuming time passes forward.
 *
 */

#include "nonlinearValuesList.h"

#include "util/list.h"
#include "util/omc_error.h"

#include <stdlib.h>
#include <string.h>

/* Forward extrapolate function definition */
double extrapolateValues(const double, const double, const double, const double, const double);

VALUES_LIST* allocValueList(unsigned itemSize)
{
  VALUES_LIST* valueList = (VALUES_LIST*) malloc(sizeof(VALUES_LIST));

  valueList->valueList = allocList(itemSize);

  return valueList;
}

void freeValueList(VALUES_LIST *valueList)
{
  VALUE* elem;

  int i;
  for(i = 0; i < listLen(valueList->valueList); ++i)
  {
    elem = (VALUE*) listFirstData(valueList->valueList);
    //freeValue(elem);
    listPopFront(valueList->valueList);
  }
  freeList(valueList->valueList);
  free(valueList);
}

void cleanValueList(VALUES_LIST *valueList, LIST_NODE *startNode)
{
  LIST_NODE *next, *node;
  VALUE* elem;

  int i, j;
  next = listNextNode(startNode);
  /* clean list from next node */
  updateNodeNext(valueList->valueList, startNode, NULL);

  removeNodes(valueList->valueList, next);
}

VALUE* createValueElement(unsigned int size, double time, double* values)
{
  VALUE* elem = (VALUE*) malloc(sizeof(VALUE));
  elem->values = (double*) malloc(size*sizeof(double));
  elem->time = time;
  elem->size = size;

  memcpy(elem->values, values, size*sizeof(double));

  /* debug output */
  infoStreamPrint(LOG_NLS_EXTRAPOLATE, 1, "Create Element");
  printValueElement(elem);
  messageClose(LOG_NLS_EXTRAPOLATE);

  return elem;
}

void freeValue(VALUE* elem)
{
  free(elem->values);
  free(elem);
}

void addListElement(VALUES_LIST* valuesList, VALUE* newElem)
{
  LIST_NODE *node, *next;
  VALUE* elem;
  int replace = 0, i=0;

  /* debug output */
  infoStreamPrint(LOG_NLS_EXTRAPOLATE, 1, "Adding element in a list of size %d", listLen(valuesList->valueList));
  printValueElement(newElem);

  /*  if it's empty, just push in  */
  if (listLen(valuesList->valueList) == 0)
  {
    infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "List is empty add just.");
    listPushFront(valuesList->valueList, (void*) newElem);

    messageClose(LOG_NLS_EXTRAPOLATE);
    return;
  }

  /*  if the element at begin is earlier than current
   *  push the elemnt just in front and if the end element
   *  is later than current push it just back.*/
  node = listFirstNode(valuesList->valueList);
  if (((VALUE*)listNodeData(node))->time < newElem->time)
  {
    infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "First Value list element is:");
    printValueElement(((VALUE*)listNodeData(node)));
    infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "so new element is added before.");
    listPushFront(valuesList->valueList, (void*) newElem);

    messageClose(LOG_NLS_EXTRAPOLATE);
    return;
  }

  infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "Search position of new element");
  /* search correct position */
  next = node;
  do
  {
    /*  if next node is empty */
    if (!next)
    {
      infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "Search finished last element reached");
      break;
    }

    elem = ((VALUE*)listNodeData(next));

    /* debug output */
    infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "Next node of list is element:");
    printValueElement(elem);

    if (elem->time < newElem->time)
    {
      break;
    }
    if (elem->time == newElem->time)
    {
      replace = 1;
      break;
    }
    else if (elem->time > newElem->time)
    {
      node = next;
    }
    next = listNextNode(node);
    i++; /* count insert or replace place */
  }while(1);

  /* add element before currect node */
  if (!replace){
    infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "Insert element before last output element.");
    listInsert(valuesList->valueList, node, (void*) newElem);
  }
  else
  {
    infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "replace element.");
    updateNodeData(valuesList->valueList, node, (void*) newElem);
  }
  /*  clean lsit if too full */
  if (i < 3 && listLen(valuesList->valueList)>20)
  {
    while(i < 4)
    {
      next = listNextNode(next);
      i++;
    }
    cleanValueList(valuesList, next);
  }

  messageClose(LOG_NLS_EXTRAPOLATE);
  return;
}

void getValues(VALUES_LIST* valuesList, double time, double* newValues)
{
  LIST_NODE *begin, *next, *old, *old2;
  VALUE *oldValues, *old2Values, *elem;

  infoStreamPrint(LOG_NLS_EXTRAPOLATE, 1, "Get values for time %g in a list of size %d", time, listLen(valuesList->valueList));
  begin = listFirstNode(valuesList->valueList);

  assertStreamPrint(NULL, NULL != begin, "getValues failed, no elements");

  /* find corresponding values */
  do{
    elem = (VALUE*)listNodeData(begin);
    infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "Searching current element:");
    printValueElement(elem);

    if (elem->time == time)
    {
      old = begin;
      old2 = NULL;
      infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "take element with the same time.");
      break;
    }
    else if (elem->time < time)
    {
      old = begin;
      old2 = listNextNode(old);
      infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "found element to use for extrapolation.");
      break;
    }
   else
    {
      next = listNextNode(begin);
      if (!next){
        old = begin;
        old2 = next;
        infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "reached end of list.");
        break;
      }
      else
      {
        begin = next;
      }
    }
  }while(1);

  /*  get next values */
  if (old2 == NULL)
  {
    oldValues = (VALUE*) listNodeData(old);
    memcpy(newValues, oldValues->values, oldValues->size*sizeof(double));
    infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "take just old values.");
  }
  else
  {
    int i;
    oldValues = (VALUE*) listNodeData(old);
    old2Values = (VALUE*) listNodeData(old2);
    infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "Use following elements for calculation:");
    printValueElement(oldValues);
    printValueElement(old2Values);
    for(i = 0; i < oldValues->size; ++i)
    {
      newValues[i] = extrapolateValues(time, oldValues->values[i], oldValues->time, old2Values->values[i], old2Values->time);
    }
  }
  messageClose(LOG_NLS_EXTRAPOLATE);
  return;
}

void printValueElement(VALUE* elem)
{
  /* debug output */
  if(ACTIVE_STREAM(LOG_NLS_EXTRAPOLATE))
  {
    int i;
    infoStreamPrint(LOG_NLS_EXTRAPOLATE, 1, "Element(size %d) at time %g ", elem->size, elem->time);
    for(i = 0; i < elem->size; i++) {
      infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, " oldValues[%d] = %g",i, elem->values[i]);
    }
    messageClose(LOG_NLS_EXTRAPOLATE);
  }
}

void printValuesListTimes(VALUES_LIST* list)
{
  /* debug output */
  if(ACTIVE_STREAM(LOG_NLS_EXTRAPOLATE))
  {
    int i;
    LIST_NODE *next;
    VALUE *elem;

    infoStreamPrint(LOG_NLS_EXTRAPOLATE, 1, "Print all elements");
    if (listLen(list->valueList) == 0){
      infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "List is empty!");
      messageClose(LOG_NLS_EXTRAPOLATE);
      return;
    }
    next = listFirstNode(list->valueList);

    assertStreamPrint(NULL, NULL != next, "printValuesListTimes failed, no elements");

    /* go though the list */
    for(i = 0; i < listLen(list->valueList); i++) {
      elem = (VALUE*)listNodeData(next);
      infoStreamPrint(LOG_NLS_EXTRAPOLATE, 0, "Element %d at time %g", i, elem->time);
      next = listNextNode(next);
    }
    messageClose(LOG_NLS_EXTRAPOLATE);
  }
}

double extrapolateValues(const double time, const double old1, const double time1, const double old2, const double time2)
{
  double retValue;

  if (time1 == time2 || old1 == old2)
  {
    retValue = old1;
  }
  else
  {
    retValue = old2 + ((time - time2)/(time1 - time2)) * (old1-old2);
  }

  return retValue;
}
