/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2021, Open Source Modelica Consortium (OSMC),
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

/*! \file doubleEndedList.c
 *
 * Description: This file contains a simple double ended linked list.
 */

#include "doubleEndedList.h"
#include "omc_error.h"

#include <stdlib.h>
#include <string.h>


/**
 * @brief A single node element of a double ended list.
 *
 * Knows previous and next node and has some data.
 */
struct DOUBLE_ENDED_LIST_NODE {
  void* data;                      /**< Item data */
  DOUBLE_ENDED_LIST_NODE* prev;    /**< Pointer to previous node in list */
  DOUBLE_ENDED_LIST_NODE* next;    /**< Pointer to next node in list */
};


/**
 * @brief Double ended list.
 *
 * Has pointers to first and last element and can be iterated over forward and backward.
 *
 */
struct DOUBLE_ENDED_LIST {
  DOUBLE_ENDED_LIST_NODE* first;   /**< Pointer to first element of list */
  DOUBLE_ENDED_LIST_NODE* last;    /**< Pointer to last element of list */
  unsigned int itemSize;           /**< Size of item data */
  unsigned int length;             /**< Number of elements in list */
};


// ############################################################################
//
// Section for allocating and freeing double ended list
//
// ############################################################################


/**
 * @brief Create new empty double ended list.
 *
 * @param itemSize              Size of item data.
 * @return DOUBLE_ENDED_LIST*   Pointer to new created double ended list.
 */
DOUBLE_ENDED_LIST* allocDoubleEndedList(unsigned int itemSize) {
  DOUBLE_ENDED_LIST* list = (DOUBLE_ENDED_LIST*) malloc(sizeof(DOUBLE_ENDED_LIST));
  list->first = NULL;
  list->last = NULL;
  list->itemSize = itemSize;
  list->length = 0;

  return list;
}


/**
 * @brief Free double ended list.
 *
 * Frees list items as well.
 *
 * @param list    Pointer to list to be freed.
 */
void freeDoubleEndedList(DOUBLE_ENDED_LIST *list) {
  if(list) {
    clearDoubleEndedList(list);
    free(list);
  }
}


/**
 * @brief Free double ended list node.
 *
 * Assumes that all memory inside node->data is allready freed by user of double ended list.
 *
 * @param node    Pointer to list node.
 */
void freeNodeDoubleEndedList(DOUBLE_ENDED_LIST_NODE *node) {
  free(node->data);
  free(node);
}



// ############################################################################
//
// Section for adding nodes
//
// ############################################################################


/**
 * @brief Create a double ended list node.
 *
 * Will copy provided data into node->data.
 *
 * @param data                        Date copied into node data.
 * @param itemSize                    Size of data.
 * @return DOUBLE_ENDED_LIST_NODE*    New created node.
 */
DOUBLE_ENDED_LIST_NODE* createNodeDoubleEndedList(const void* data, unsigned int itemSize) {
  /* Variables */
  DOUBLE_ENDED_LIST_NODE* newNode;

  /* Allocate memory */
  newNode = (DOUBLE_ENDED_LIST_NODE*) malloc(sizeof(DOUBLE_ENDED_LIST_NODE));
  assertStreamPrint(NULL, 0 != newNode, "createNodeDoubleEndedList: Out of memory");

  newNode->data = (void*) malloc(itemSize);
  assertStreamPrint(NULL, 0 != newNode, "createNodeDoubleEndedList: Out of memory");

  /* Set node data */
  memcpy(newNode->data, data, itemSize);
  newNode->prev = NULL;
  newNode->next = NULL;
  return newNode;
}


/**
 * @brief Create new node from data and insert at front of list.
 *
 * Will copy data.
 *
 * @param list    Pointer to double ended list.
 * @param data    Pointer to data to be coppied into new node.
 */
void pushFrontDoubleEndedList(DOUBLE_ENDED_LIST* list, const void* data) {
  /* Error checking */
  assertStreamPrint(NULL, 0 != list, "pushFrontDoubleEndedList: invalid list-pointer");

  /* Create new node */
  DOUBLE_ENDED_LIST_NODE* newFirstNode = createNodeDoubleEndedList(data, list->itemSize);

  /* Add node at front */
  if (list->length==0) {
    list->first = newFirstNode;
    list->last = newFirstNode;
  } else {
    list->first->prev = newFirstNode;
    newFirstNode->next = list->first;
    list->first = newFirstNode;
  }

  list->length+= 1;
}


/**
 * @brief Create new node from data and insert at back of list.
 *
 * @param list    Pointer to double ended list.
 * @param data    Pointer to data to be coppied into new node.
 */
void pushBackDoubleEndedList(DOUBLE_ENDED_LIST* list, const void* data) {
  /* Error checking */
  assertStreamPrint(NULL, 0 != list, "pushBackDoubleEndedList: invalid list-pointer");

  /* Create new node */
  DOUBLE_ENDED_LIST_NODE* newLastNode = createNodeDoubleEndedList(data, list->itemSize);

  /* Append node at back */
  if (list->length==0) {
    list->first = newLastNode;
    list->last = newLastNode;
  } else {
    list->last->next = newLastNode;
    newLastNode->prev = list->last;
    list->last = newLastNode;
  }

  list->length+= 1;
}


/**
 * @brief Insert list element after given node.
 *
 * @param list        Pointer to double ended list.
 * @param prevNode    Previous node for new created node.
 * @param data        Pointer to data to be coppied into new node.
 */
void insertDoubleEndedList(DOUBLE_ENDED_LIST *list, DOUBLE_ENDED_LIST_NODE* prevNode, const void *data) {
  /* Error checking */
  assertStreamPrint(NULL, 0 != list, "insertDoubleEndedList: invalid list-pointer");
  assertStreamPrint(NULL, 0 != prevNode, "insertDoubleEndedList: invalid previous-node-pointer");

  /* Create new node */
  DOUBLE_ENDED_LIST_NODE* newNode = createNodeDoubleEndedList(data, list->itemSize);

  newNode->prev = prevNode;
  newNode->next = prevNode->next;
  prevNode->next = newNode;

  /* Update end of list */
  if(list->last == prevNode)
    list->last = newNode;

  list->length+= 1;
}


// ############################################################################
//
// Section for removing nodes
//
// ############################################################################


/**
 * @brief Remove single node from list.
 *
 * @param list    Double ended list.
 * @param node    Node to be deleted from list.
 */
void removeNodeDoubleEndedList(DOUBLE_ENDED_LIST* list, DOUBLE_ENDED_LIST_NODE *node) {
  if (node != NULL) {
    /* Update previous node */
    if (node->prev) {
      if (node->next) {
        node->prev->next = node->next;  /* Set next of previous node to be the node after deleted one */
      } else {
        node->prev->next = NULL;
        if (node->next == NULL) { /* Previous node is now last node */
          list->last = node->prev;
        }
      }
    }
    /* Update next node */
    if (node->next) {
      if (node->prev) {
        node->next->prev = node->prev;  /* Set previous of next node to be the node before deleted one */
      } else {
        node->next->prev = NULL;
        if (node->prev == NULL) { /* Next node is now first node */
          list->first = node->next;
        }
      }
    }

    /* Free node */
    freeNodeDoubleEndedList(node);
    list->length -= 1;
    if (list->length == 0) {
      list->first = NULL;
      list->last = NULL;
    }
  }
}


/**
 * @brief Removes first node from list.
 *
 * @param list    Double ended list.
 */
void removeFirstDoubleEndedList(DOUBLE_ENDED_LIST *list) {
  if(list != NULL) {
    if(list->first != NULL) {
      removeNodeDoubleEndedList(list, list->first);
    }
  }
}


/**
 * @brief Removes last node from list.
 *
 * @param list    Double ended list.
 */
void removeLastDoubleEndedList (DOUBLE_ENDED_LIST *list) {
  if(list != NULL) {
    removeNodeDoubleEndedList(list, list->last);
  }
}


/**
 * @brief Remove all items from double ended list.
 *
 * @param list    Pointer to double ended list.
 */
void clearDoubleEndedList(DOUBLE_ENDED_LIST *list) {
  DOUBLE_ENDED_LIST_NODE *delNode;

  if(list == NULL) {
    return;
  }

  delNode = list->first;
  while(delNode) {
    DOUBLE_ENDED_LIST_NODE *tmpNode = delNode->next;
    freeNodeDoubleEndedList(delNode);
    delNode = tmpNode;
  }

  list->length = 0;
  list->first = NULL;
  list->last = NULL;
}


/**
 * @brief Remove all items from double ended list in front of given node.
 *
 * Given node will not be removed and will be the first node in the list.
 *
 * @param list            Pointer to double ended list.
 * @param newFrontNode    Pointer to node which will be the first node.
 */
void clearBeforeNodeDoubleEndedList(DOUBLE_ENDED_LIST *list, DOUBLE_ENDED_LIST_NODE* newFrontNode) {
  DOUBLE_ENDED_LIST_NODE *delNode;

  assertStreamPrint(NULL, 0 != list, "clearBeforeNodeDoubleEndedList: invalid list-pointer");
  assertStreamPrint(NULL, 0 != list->length, "clearBeforeNodeDoubleEndedList: empty list");

  delNode = newFrontNode->prev;
  while(delNode) {
    DOUBLE_ENDED_LIST_NODE *tmpNode = delNode->prev;
    freeNodeDoubleEndedList(delNode);
    list->length -= 1;
    delNode = tmpNode;
  }

  /* Update end of list */
  newFrontNode->prev = NULL;
  list->first = newFrontNode;
}


/**
 * @brief Remove all items from double ended list after given node.
 *
 * Given node will not be removed and will be the last node in the list.
 *
 * @param list        Pointer to double ended list.
 * @param newEndNode  Pointer to node which will be the new last node.
 */
void clearAfterNodeDoubleEndedList(DOUBLE_ENDED_LIST *list, DOUBLE_ENDED_LIST_NODE* newEndNode) {
  DOUBLE_ENDED_LIST_NODE *delNode;

  assertStreamPrint(NULL, 0 != list, "clearAfterNodeDoubleEndedList: invalid list-pointer");
  assertStreamPrint(NULL, 0 != list->length, "clearAfterNodeDoubleEndedList: empty list");

  delNode = newEndNode->next;
  while(delNode) {
    DOUBLE_ENDED_LIST_NODE *tmpNode = delNode->next;
    freeNodeDoubleEndedList(delNode);
    list->length -= 1;
    delNode = tmpNode;
  }

  /* Update end of list */
  newEndNode->next = NULL;
  list->last = newEndNode;
}


// ############################################################################
//
// Section for getting nodes
//
// ############################################################################


/**
 * @brief Get the first node of double ended list.
 *
 * @param list                        Double ended list.
 * @return DOUBLE_ENDED_LIST_NODE*    Pointer to first node element of list.
 */
DOUBLE_ENDED_LIST_NODE* getFirstNodeDoubleEndedList(DOUBLE_ENDED_LIST *list) {
  return list->first;
}


/**
 * @brief Get the last node of double ended list.
 *
 * @param list                        Double ended list
 * @return DOUBLE_ENDED_LIST_NODE*    Pointer to last node element of list.
 */
DOUBLE_ENDED_LIST_NODE* getLastNodeDoubleEndedList(DOUBLE_ENDED_LIST *list) {
  return list->last;
}


/**
 * @brief Get the previous node of current node.
 *
 * @param currentNode                 Current node of double ended list.
 * @return DOUBLE_ENDED_LIST_NODE*    Pointer to previous node element.
 */
DOUBLE_ENDED_LIST_NODE* getPreviousNodeDoubleEndedList(DOUBLE_ENDED_LIST_NODE *currentNode) {
  return currentNode->prev;
}


/**
 * @brief Get the next node of current node.
 *
 * @param currentNode                 Current node of double ended list.
 * @return DOUBLE_ENDED_LIST_NODE*    Pointer to next node element.
 */
DOUBLE_ENDED_LIST_NODE* getNextNodeDoubleEndedList(DOUBLE_ENDED_LIST_NODE *currentNode) {
  return currentNode->next;
}


// ############################################################################
//
// Section for getting data from nodes
//
// ############################################################################


/**
 * @brief Return pointer to data of first node.
 *
 * @param list        Double ended list.
 * @return void*      Pointer to data of first list element.
 */
void* firstDataDoubleEndedList(DOUBLE_ENDED_LIST *list) {
  assertStreamPrint(NULL, 0 != list, "firstDataDoubleEndedList: invalid list-pointer");
  assertStreamPrint(NULL, 0 != list->first, "firstDataDoubleEndedList: empty list");
  return list->first->data;
}


/**
 * @brief Return pointer to data of last node.
 *
 * @param list        Double ended list.
 * @return void*      Pointer to data of last list element.
 */
void* lastDataDoubleEndedList(DOUBLE_ENDED_LIST *list) {
  assertStreamPrint(NULL, 0 != list, "lastDataDoubleEndedList: invalid list-pointer");
  assertStreamPrint(NULL, 0 != list->last, "lastDataDoubleEndedList: empty list");
  return list->last->data;
}


/**
 * @brief Return pointer to data of given node.
 *
 * @param node        Node element.
 * @return void*      Pointer to data of node.
 */
void* dataDoubleEndedList(DOUBLE_ENDED_LIST_NODE *node) {
  assertStreamPrint(NULL, 0 != node, "dataDoubleEndedList: invalid node-pointer");
  return node->data;
}


// ############################################################################
//
// Section for small helper functions
//
// ############################################################################


/**
 * @brief Returns length of double ended lists.
 *
 * @param list    Double ended list.
 * @return int    Length of list.
 */
int doubleEndedListLen(DOUBLE_ENDED_LIST *list) {
  assertStreamPrint(NULL, 0 != list, "doubleEndedListLen: invalid list-pointer");
  return list->length;
}


/**
 * @brief Print a double ended list with provided print function.
 *
 * @param list              List to print.
 * @param stream            Stream of type LOG_STREAM.
 * @param printDataFunc     Function to print address of node and list->data to stream.
 */
void doubleEndedListPrint(DOUBLE_ENDED_LIST *list, int stream, void (*printDataFunc)(void*,int,void*)) {
  int i;
  DOUBLE_ENDED_LIST_NODE* tmpNode;

  if (useStream[stream]) {
    infoStreamPrint(stream, 1, "Printing double ended list:");
    infoStreamPrint(stream, 0, "list length: %i, size of each item data: %i (bytes)", list->length, list->itemSize);
    infoStreamPrint(stream, 0, "Pointer to first: %p", list->first);
    infoStreamPrint(stream, 0, "Pointer to last: %p", list->last);

    tmpNode = list->first;
    while(tmpNode != NULL) {
      printDataFunc(tmpNode->data, stream, (void*) tmpNode);
      tmpNode = tmpNode->next;
    }

    messageClose(stream);
  }
}
