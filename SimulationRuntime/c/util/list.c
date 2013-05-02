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

/*! \file list.c
 *
 * Description: This file is a C header file for the simulation runtime.
 * It contains a simple linked list
 */

#include "list.h"
#include "omc_error.h"

#include <memory.h>
#include <stdlib.h>

struct LIST_NODE
{
  void *data;
  LIST_NODE *next;
};

struct LIST
{
  LIST_NODE *first;
  LIST_NODE *last;
  unsigned int itemSize;
  unsigned int length;
};

LIST *allocList(unsigned int itemSize)
{
  LIST *list = (LIST*)malloc(sizeof(LIST));
  ASSERT(list, "out of memory");

  list->first = NULL;
  list->last = NULL;
  list->itemSize = itemSize;
  list->length = 0;

  return list;
}

void freeList(LIST *list)
{
  if(list)
  {
    listClear(list);
    free(list);
  }
}

void listPushFront(LIST *list, void *data)
{
  LIST_NODE *tmpNode = NULL;
  ASSERT(list, "invalid list-pointer");

  tmpNode = (LIST_NODE*)malloc(sizeof(LIST_NODE));
  ASSERT(tmpNode, "out of memory");

  tmpNode->data = malloc(list->itemSize);
  ASSERT(tmpNode->data, "out of memory");

  memcpy(tmpNode->data, data, list->itemSize);
  tmpNode->next = list->first;
  ++(list->length);

  list->first = tmpNode;
  if(!list->last)
    list->last = list->first;
}

void listPushBack(LIST *list, void *data)
{
  LIST_NODE *tmpNode = NULL;
  ASSERT(list, "invalid list-pointer");

  tmpNode = (LIST_NODE*)malloc(sizeof(LIST_NODE));
  ASSERT(tmpNode, "out of memory");

  tmpNode->data = malloc(list->itemSize);
  ASSERT(tmpNode->data, "out of memory");

  memcpy(tmpNode->data, data, list->itemSize);
  tmpNode->next = NULL;
  ++(list->length);

  if(list->last)
    list->last->next = tmpNode;

  list->last = tmpNode;

  if(!list->first)
    list->first = list->last;
}

int listLen(LIST *list)
{
  ASSERT(list, "invalid list-pointer");
  return list->length;
}

void *listFirstData(LIST *list)
{
  ASSERT(list, "invalid list-pointer");
  ASSERT(list->first, "empty list");
  return list->first->data;
}

void *listLastData(LIST *list)
{
  ASSERT(list, "invalid list-pointer");
  ASSERT(list->last, "empty list");
  return list->last->data;
}

void listPopFront(LIST *list)
{
  if(list)
  {
    if(list->first)
    {
      LIST_NODE *tmpNode = list->first->next;
      free(list->first->data);
      free(list->first);

      list->first = tmpNode;
      --(list->length);
      if(!list->first)
        list->last = list->first;
    }
  }
}

void listClear(LIST *list)
{
  LIST_NODE *delNode;

  if(!list)
    return;

  delNode = list->first;
  while(delNode)
  {
    LIST_NODE *tmpNode = delNode->next;
    free(delNode->data);
    free(delNode);
    delNode = tmpNode;
  }

  list->length = 0;
  list->first = NULL;
  list->last = NULL;
}

LIST_NODE *listFirstNode(LIST *list)
{
  ASSERT(list, "invalid list-pointer");
  ASSERT(list->first, "invalid fist list-pointer");
  return list->first;
}

LIST_NODE *listNextNode(LIST_NODE *node)
{
  ASSERT(node, "invalid list-node");
  if(node)
    return node->next;
  return NULL;
}

void *listNodeData(LIST_NODE *node)
{
  ASSERT(node, "invalid list-node");
  ASSERT(node->data, "invalid data node");
  return node->data;
}
