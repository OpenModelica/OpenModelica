/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

/*! \file list.c
 *
 * Description: This file is a C header file for the simulation runtime.
 * It contains a simple linked list
 */

#include "list.h"
#include "omc_error.h"

#include <stdlib.h>
#include <string.h>

/* Private function prototypes */
modelica_boolean listIsIn(LIST *list, LIST_NODE *node);

struct LIST_NODE
{
  void *data;         /* Data of list element.
                       * Use allocListNodeFunc, freeListNodeFunc and copyListNodeDataFunc for alloc, free and copy. */
  LIST_NODE *next;    /* Pointer to next list element. */
};

struct LIST
{
  LIST_NODE *first;                             /* Pointer to first list element */
  LIST_NODE *last;                              /* Pointer to last list element */
  unsigned int length;                          /* Number if list elements */
  allocListNodeDataFunc_t* allocListNodeData;   /* Function to allocate memory for LIST_NODE data. */
  freeListNodeDataFunc_t* freeListNodeData;     /* Function to free memory of LIST_NODE data. */
  copyListNodeDataFunc_t* copyListNodeData;     /* Function to copy memory of LIST_NODE data. */
};

/**
 * @brief Allocates memory for a new empty list
 *
 * @param itemSize    Size of data
 * @return list       Pointer to list
 */

/**
 * @brief Allocates memory for a new empty list
 *
 * @param allocListNodeData   Function to allocate memory for new list elements data.
 * @param freeListNodeData    Function to free memory for list elements data.
 * @param copyListNodeData    Function to copy list elements data.
 * @return LIST*              New empty list.
 */
LIST *allocList(allocListNodeDataFunc_t* allocListNodeData, freeListNodeDataFunc_t* freeListNodeData, copyListNodeDataFunc_t* copyListNodeData)
{
  LIST *list = (LIST*)malloc(sizeof(LIST));
  assertStreamPrint(NULL, 0 != list, "out of memory");

  list->first = NULL;
  list->last = NULL;
  list->allocListNodeData = allocListNodeData;
  list->freeListNodeData = freeListNodeData;
  list->copyListNodeData = copyListNodeData;
  list->length = 0;

  return list;
}

/**
 * @brief Frees list and everything inside it
 *
 * @param list    Pointer to list
 */
void freeList(LIST *list)
{
  if(list)
  {
    listClear(list);
    free(list);
  }
}

/**
 * @brief Frees node and data inside node
 *
 * @param node    Pointer to node
 */
void freeNode(LIST *list, LIST_NODE *node)
{
  list->freeListNodeData(node->data);
  free(node);
}

/**
 * @brief Copies data into new tmpNode and pushes tmpNode to the front of list
 *
 * @param list    Pointer to list
 * @param data    Pointer to data (copied)
 */
void listPushFront(LIST *list, const void *data)
{
  LIST_NODE *tmpNode = NULL;
  assertStreamPrint(NULL, 0 != list, "invalid list-pointer");

  tmpNode = (LIST_NODE*)malloc(sizeof(LIST_NODE));
  assertStreamPrint(NULL, 0 != tmpNode, "out of memory");

  tmpNode->data = list->allocListNodeData(data);
  assertStreamPrint(NULL, 0 != tmpNode->data, "out of memory");

  list->copyListNodeData(tmpNode->data, data);
  tmpNode->next = list->first;
  ++(list->length);

  list->first = tmpNode;
  if(!list->last)
    list->last = list->first;
}

/**
 * @brief Pushes node to the front of list
 *
 * @param list    Pointer to list
 * @param node    Pointer to node (not copied)
 */
void listPushFrontNodeNoCopy(LIST *list, LIST_NODE *node)
{
  assertStreamPrint(NULL, 0 != list, "invalid list-pointer");
  assertStreamPrint(NULL, 0 != node, "invalid list-node");

  node->next = list->first;
  ++(list->length);
  list->first = node;
  if(!list->last)
    list->last = list->first;
}

/**
 * @brief Copies data into new tmpNode and pushes tmpNode to the back of list
 *
 * @param list    Pointer to list
 * @param data    Pointer to data (copied)
 */
void listPushBack(LIST *list, const void *data)
{
  LIST_NODE *tmpNode = NULL;
  assertStreamPrint(NULL, 0 != list, "invalid list-pointer");

  tmpNode = (LIST_NODE*)malloc(sizeof(LIST_NODE));
  assertStreamPrint(NULL, 0 != tmpNode, "out of memory");

  tmpNode->data = list->allocListNodeData(data);
  assertStreamPrint(NULL, 0 != tmpNode->data, "out of memory");

  list->copyListNodeData(tmpNode->data, data);
  tmpNode->next = NULL;
  ++(list->length);

  if(list->last)
    list->last->next = tmpNode;

  list->last = tmpNode;

  if(!list->first)
    list->first = list->last;
}

/**
 * @brief Copies data into new node and inserts it into list after prevNode
 *
 * @param list       Pointer to list
 * @param prevNode   Pointer to previous node
 * @param data       Pointer to data (copied)
 */
void listInsert(LIST *list, LIST_NODE* prevNode, const void *data)
{
  LIST_NODE *tmpNode = (LIST_NODE*)malloc(sizeof(LIST_NODE));
  assertStreamPrint(NULL, 0 != tmpNode, "out of memory");

  tmpNode->data = list->allocListNodeData(data);
  assertStreamPrint(NULL, 0 != tmpNode->data, "out of memory");
  list->copyListNodeData(tmpNode->data, data);

  tmpNode->next = prevNode->next;
  prevNode->next = tmpNode;

  ++(list->length);
  if(list->last == prevNode)
    list->last = tmpNode;
}

/**
 * @brief Returns the length of list
 *
 * @param list    Pointer to list
 * @return        length of list
 */
int listLen(LIST *list)
{
  assertStreamPrint(NULL, 0 != list, "invalid list-pointer");
  return list->length;
}

/**
 * @brief Returns data of first node in list
 *
 * @param list    Pointer to list
 * @return        Pointer to data of first node in list
 */
void *listFirstData(LIST *list)
{
  assertStreamPrint(NULL, 0 != list, "invalid list-pointer");
  assertStreamPrint(NULL, 0 != list->first, "empty list");
  return list->first->data;
}

/**
 * @brief Returns data of last node in list
 *
 * @param list    Pointer to list
 * @return        Pointer to data of last node in list
 */
void *listLastData(LIST *list)
{
  assertStreamPrint(NULL, 0 != list, "invalid list-pointer");
  assertStreamPrint(NULL, 0 != list->last, "empty list");
  return list->last->data;
}

/**
 * @brief Returns first node and pops node from list
 *
 * @param list    Pointer to list
 * @return node   Pointer to node (must be freed by caller)
 */
LIST_NODE *listPopFrontNode(LIST *list)
{
  assertStreamPrint(NULL, 0 != list, "invalid list-pointer");
  assertStreamPrint(NULL, 0 != list->first, "empty list");

  LIST_NODE *node = list->first;
  list->first = node->next;
  //node->next = NULL;
  --(list->length);
  if(!list->first)
    list->last = list->first;
  return node;
}

/**
 * @brief Removes and frees first node from list
 *
 * @param list    Pointer to list
 */
void listRemoveFront(LIST *list)
{
  assertStreamPrint(NULL, 0 != list, "invalid list-pointer");
  if(list->first)
  {
    LIST_NODE *tmpNode = list->first->next;
    freeNode(list, list->first);

    list->first = tmpNode;
    --(list->length);
    if(!list->first)
      list->last = list->first;
  }
}

/**
 * @brief Frees all nodes and their data in list
 *
 * @param list    Pointer to list
 */
void listClear(LIST *list)
{
  LIST_NODE *delNode;

  if(!list)
    return;

  delNode = list->first;
  while(delNode)
  {
    LIST_NODE *tmpNode = delNode->next;
    freeNode(list, delNode);
    delNode = tmpNode;
  }

  list->length = 0;
  list->first = NULL;
  list->last = NULL;
}

/**
 * @brief Remove all nodes after startNode from list.
 *
 * Checks if startNode is part of list.
 *
 * @param list        List to remove elements from.
 * @param startNode   Node to remove after. startNode won't be removed.
 */
void listClearAfterNode(LIST *list, LIST_NODE *startNode) {
  assertStreamPrint(NULL, 0 != list, "invalid list-pointer");
  assertStreamPrint(NULL, 0 != startNode, "invalid list-node");

  assertStreamPrint(NULL, listIsIn(list, startNode), "listClearAfterNode: start node not in list!");

  LIST_NODE* delNode = startNode->next;
  while (delNode) {
    LIST_NODE* nextNode = delNode->next;
    freeNode(list, delNode);
    list->length--;
    delNode = nextNode;
  }
  startNode->next = NULL;
  list->last = startNode;
}

/**
 * @brief Returns first node of list
 *
 * @param list    Pointer to list
 * @return        Pointer to first node (NULL if list is empty)
 */
LIST_NODE *listFirstNode(LIST *list)
{
  assertStreamPrint(NULL, 0 != list, "invalid list-pointer");
  return list->first;
}

/**
 * @brief Returns next node after node (used for iterating over list)
 *
 * @param node    Pointer to node
 * @return        Pointer to next node (NULL if end of list is reached)
 */
LIST_NODE *listNextNode(LIST_NODE *node)
{
  assertStreamPrint(NULL, 0 != node, "invalid list-node");
  return node->next;
}

/**
 * @brief Test if node is in list
 *
 * @param list                  Pointer to List.
 * @param node                  Node to test if in list.
 * @return modelica_boolean     True if node is in list, false otherwise.
 */
modelica_boolean listIsIn(LIST *list, LIST_NODE *node) {
  assertStreamPrint(NULL, 0 != list, "invalid list-pointer");
  assertStreamPrint(NULL, 0 != node, "invalid list-node");

  modelica_boolean isIn = FALSE;
  LIST_NODE* tmpNode = list->first;
  while (tmpNode) {
    if (node == tmpNode) {
      return TRUE;
    }
    tmpNode = tmpNode->next;
  }

  return FALSE;
}

/**
 * @brief Returns node data.
 *
 * @param node    Pointer to node
 * @return        Pointer to data
 */
void *listNodeData(LIST_NODE *node)
{
  assertStreamPrint(NULL, 0 != node, "invalid list-node");
  assertStreamPrint(NULL, 0 != node->data, "invalid list-data");
  return node->data;
}

/**
 * @brief Update content of node->data with data.
 *
 * Uses provided copyListNodeData function.
 *
 * @param list    List containing node.
 * @param node    Node to update.
 * @param data    Data to copy into node data.
 */
void updateNodeData(LIST *list, LIST_NODE *node, const void *data)
{
  assertStreamPrint(NULL, 0 != list, "invalid list-pointer");
  assertStreamPrint(NULL, 0 != node, "invalid list-node");
  assertStreamPrint(NULL, 0 != node->data, "invalid list-data");
  list->copyListNodeData(node->data, data);
  return;
}

/**
 * @brief Print list
 *
 * @param list            Pointer to list.
 * @param stream          Stream to print to.
 * @param printDataFunc   Function to print address of buffer element and its data to stream.
 */
void printList(LIST* list, int stream, void (*printDataFunc)(void*,int,void*))
{
  LIST_NODE* listElem;

  if (useStream[stream]) {
    infoStreamPrint(stream, 1, "Printing list:");
    infoStreamPrint(stream, 0, "length: %d", list->length);

    listElem = list->first;
    for (int i=0; i<list->length; i++) {
      assertStreamPrint(NULL, listElem != NULL, "list element is NULL");
      printDataFunc(listElem->data, stream, (void*) listElem->data);
      listElem = listElem->next;
    }

    messageClose(stream);
  }
}
