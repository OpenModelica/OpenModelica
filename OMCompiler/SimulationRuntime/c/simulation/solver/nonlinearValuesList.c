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

#include "epsilon.h"
#include "nonlinearValuesList.h"

#include "../../util/list.h"
#include "../../util/omc_error.h"

#include <stdlib.h>
#include <string.h>

#define UNUSED(x) (void)(x)

/* Forward extrapolate function definition */
double extrapolateValues(const double, const double, const double, const double, const double);
void* valueListAlloc(const void* data);
void valueListFree(void* data);
void valueListCopy(void* dest, const void* src);

/**
 * @brief Allocate value lists.
 *
 * @param numberOfList    Number of lists to allocate.
 * @param valueSize       Length of array double* values
 * @return VALUES_LIST*   Array of value lists.
 */
VALUES_LIST* allocValueList(unsigned int numberOfList, unsigned int valueSize)
{
  unsigned int i = 0;
  VALUES_LIST* valueList = (VALUES_LIST*) malloc(numberOfList*sizeof(VALUES_LIST));

  for(i=0; i<numberOfList; i++) {
    valueList[i].valueList = allocList(valueListAlloc, valueListFree, valueListCopy);
  }

  return valueList;
}

/**
 * @brief Free array of value lists.
 *
 * @param valueList       Array of value lists.
 * @param numberOfList    Length of array valueList.
 */
void freeValueList(VALUES_LIST* valueList, unsigned int numberOfList)
{
  unsigned int i = 0;

  for(i=0; i<numberOfList; i++) {
    freeList(valueList[i].valueList);
  }
  free(valueList);
}

/**
 * @brief Removes all nodes after startNode from valueList.
 *        If startNode = NULL then clear the whole list.
 *
 * @param valueList    Pointer to value list
 * @param startNode    Pointer to list node, following nodes will be deleted
 */
void cleanValueList(LIST* valueList, LIST_NODE *startNode)
{
  int len;
  if(startNode)
  {
    listClearAfterNode(valueList, startNode);
  }
  else listClear(valueList);
}

/**
 * @brief Removes all nodes except the one just before or at time.
 *
 * @param valueList    Pointer to value list
 * @param time         time
 */
void cleanValueListbyTime(LIST *valueList, double time)
{
  LIST_NODE *next, *it;
  VALUE* elem;

  printValuesListTimes(valueList);
  // need to get first node at each iteration since head is removed
  for(it = listFirstNode(valueList); it; it = listFirstNode(valueList))
  {
    assert(it != NULL);
    elem = (VALUE*)listNodeData(it);
    if (elem->time <= time)
    {
      cleanValueList(valueList, it);
      infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "New list length %d: ", listLen(valueList));
      printValuesListTimes(valueList);
      infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "Done!");
      break;
    }
    /* debug output */
    infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "cleanValueListbyTime %g check element: ", time);
    printValueElement(elem);

    listRemoveFront(valueList);
  }
}

/**
 * @brief Create new value element for value list.
 *
 * @param size      Length of values array.
 * @param time      Time
 * @param values    Array of values
 */
VALUE* createValueElement(unsigned int size, double time, double* values)
{
  VALUE* elem = calloc(1, sizeof(VALUE));
  elem->values = calloc(size, sizeof(double));
  elem->time = time;
  elem->size = size;

  memcpy(elem->values, values, size*sizeof(double));

  /* debug output */
  infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "Create Element");

  return elem;
}

/**
 * @brief Free value element allocated with createValueElement
 *
 * @param elem    Value element to free.
 */
void freeValue(VALUE* elem)
{
  free(elem->values);
  free(elem);
}

/**
 * @brief Adds copy of new element to list.
 *
 * @param valuesList    List
 * @param newElem       New element to add to list.
 */
void addListElement(LIST* valuesList, VALUE* newElem)
{
  LIST_NODE *node, *next;
  VALUE* elem;
  int replace = 0, i = 0;

  /* debug output */
  infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 1, "Adding element in a list of size %d", listLen(valuesList));
  printValueElement(newElem);

  /*  if it's empty, just push it in */
  if (listLen(valuesList) == 0)
  {
    infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "List is empty add new element.");
    listPushFront(valuesList, (void*) newElem);

    messageClose(OMC_LOG_NLS_EXTRAPOLATE);
    return;
  }

  /*  if the element at begin is earlier than current
   *  push the element just in front and if the end element
   *  is later than current push it just back.*/
  node = listFirstNode(valuesList);
  if ( fabs( ((VALUE*)listNodeData(node))->time - newElem->time ) > MINIMAL_STEP_SIZE )
  {
    infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "First Value list element is:");
    printValueElement(((VALUE*)listNodeData(node)));
    infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "so new element is added before.");
    listPushFront(valuesList, (void*) newElem);

    messageClose(OMC_LOG_NLS_EXTRAPOLATE);
    return;
  }

  infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "Search position of new element");
  /* search correct position */
  next = node;
  do
  {
    /*  if next node is empty */
    if (!next)
    {
      infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "Search finished last element reached");
      break;
    }

    elem = ((VALUE*)listNodeData(next));

    /* debug output */
    infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "Next node of list is element:");
    printValueElement(elem);


    if (fabs(elem->time - newElem->time)<=MINIMAL_STEP_SIZE)
    {
      replace = 1;
      break;
    }
    else if (elem->time < newElem->time)
    {
      break;
    }
    node = next;
    next = listNextNode(node);
    i++; /* count insert or replace place */
  }while(1);

  /* add element before currect node */
  if (!replace){
    infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "Insert element before last output element.");
    listInsert(valuesList, node, (void*) newElem);
  }
  else
  {
    infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "replace element.");
    updateNodeData(valuesList, next, (void*) newElem);
  }
  /*  clean list if too full */
  if (i < 3 && listLen(valuesList)>10)
  {
    while(i < 4)
    {
      next = listNextNode(next);
      i++;
    }
    cleanValueList(valuesList, next);
  }

  messageClose(OMC_LOG_NLS_EXTRAPOLATE);
  return;
}

/**
 * @brief Gets extrapolated values for time from value list.
 *
 * @param valuesList            Pointer to value list
 * @param time                  time
 * @param extrapolatedValues    values extrapolated (overwritten)
 * @param oldOutput             old values just before time
 */
void getValues(LIST* valuesList, double time, double* extrapolatedValues, double* oldOutput)
{
  LIST_NODE *it;
  LIST_NODE *old = NULL;
  LIST_NODE *old2 = NULL;
  VALUE *oldValues, *old2Values, *elem;

  infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 1, "Get values for time %g in a list of size %d", time, listLen(valuesList));

  /* find corresponding values */
  for(it = listFirstNode(valuesList); it; it = listNextNode(it))
  {
    elem = (VALUE*)listNodeData(it);
    infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "Searching current element:");
    printValueElement(elem);

    old = it;
    if(fabs(elem->time - time) <= MINIMAL_STEP_SIZE)
    {
      infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "take element with the same time.");
      break;
    }
    else if(elem->time < time)
    {
      old2 = listNextNode(old);
      infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "found element to use for extrapolation.");
      break;
    }
  }

  /* if the list is empty old never gets set */
  assertStreamPrint(NULL, NULL != old, "getValues failed, no elements!");

  if(it == NULL)
  {
    infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "reached end of list.");
  }

  /*  get next values */
  if (old2 == NULL)
  {
    oldValues = (VALUE*) listNodeData(old);
    memcpy(extrapolatedValues, oldValues->values, oldValues->size*sizeof(double));
    memcpy(oldOutput, oldValues->values, oldValues->size*sizeof(double));
    infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "take just old values.");
  }
  else
  {
    int i;
    oldValues = (VALUE*) listNodeData(old);
    old2Values = (VALUE*) listNodeData(old2);
    infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, "Use following elements for calculation:");
    printValueElement(oldValues);
    printValueElement(old2Values);
    for(i = 0; i < oldValues->size; ++i)
    {
      extrapolatedValues[i] = extrapolateValues(time, oldValues->values[i], oldValues->time, old2Values->values[i], old2Values->time);
    }
    memcpy(oldOutput, oldValues->values, oldValues->size*sizeof(double));
  }
  messageClose(OMC_LOG_NLS_EXTRAPOLATE);
  return;
}

void printValueElement(VALUE* elem)
{
  /* debug output */
  if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_EXTRAPOLATE))
  {
    int i;
    infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 1, "Element(size %d) at time %g ", elem->size, elem->time);
    for(i = 0; i < elem->size; i++) {
      infoStreamPrint(OMC_LOG_NLS_EXTRAPOLATE, 0, " oldValues[%d] = %g",i, elem->values[i]);
    }
    messageClose(OMC_LOG_NLS_EXTRAPOLATE);
  }
}

/**
 * @brief Print function for printValuesListTimes
 *
 * @param data      Data of node of type VALUE*
 * @param stream    Stream to output to.
 * @param unused    Unused
 */
static void printElemTimes(void* data, int stream, void* unused) {
  UNUSED(unused);
  VALUE* elem = (VALUE*) data;

  unsigned int i;
  for(i=0; i<elem->size; i++) {
    infoStreamPrint(stream, 0, "Element %d at time %g", i, elem->time);
  }
}

/**
 * @brief Print value times of value list.
 *
 * @param list    Value list.
 */
void printValuesListTimes(LIST* list) {
  printList(list, OMC_LOG_NLS_EXTRAPOLATE, printElemTimes);
}

/*! \fn extraPolateValues
 *   This function extrapolates linear values based on old values.
 *
 *  \param [in]  [time] desired time for extrapolation
 *  \param [in]  [old1] old value at time1
 *  \param [in]  [time1] time for the first value
 *  \param [in]  [old2] old value at time2
 *  \param [in]  [time2] time for the second value
 */
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

/**
 * @brief Allocate memory for valueList elements.
 *
 * @param data      value list element, containing size of array values
 *                  Has to be of type VALUE*;
 * @return void*    Allocated memory for LIST_NODE data.
 */
void* valueListAlloc(const void* data) {
  const VALUE* valueElem = (VALUE*) data;
  VALUE* newElem = malloc(sizeof(VALUE));
  assertStreamPrint(NULL, newElem != NULL, "valueListAlloc: Out of memory");
  newElem->values = malloc(valueElem->size*sizeof(double));
  assertStreamPrint(NULL, newElem->values != NULL, "valueListAlloc: Out of memory");
  return (void*) newElem;
}

/**
 * @brief Free memory allocated with valueListAlloc.
 *
 * @param data      Void pointer, representing index for new list element.
 */
void valueListFree(void* data) {
  VALUE* valueElem = (VALUE*) data;
  free(valueElem->values);
  free(valueElem);
}

/**
 * @brief Copy data of valueList elements.
 *
 * @param dest    Void pointer of destination data, representing VALUE.
 * @param src     Void pointer of source data, representing VALUE.
 */
void valueListCopy(void* dest, const void* src) {
  VALUE* destValue = (VALUE*) dest;
  VALUE* srcValue = (VALUE*) src;
  destValue->size = srcValue->size;
  destValue->time = srcValue->time;
  memcpy(destValue->values, srcValue->values, srcValue->size*sizeof(double));
}
