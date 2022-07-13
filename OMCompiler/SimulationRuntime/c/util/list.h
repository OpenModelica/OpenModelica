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

/*! \file list.h
 *
 * Description: This file is a C header file for the simulation runtime.
 * It contains a simple linked list
 */

#ifndef _LIST_H_
#define _LIST_H_

#ifdef __cplusplus
extern "C" {
#endif

  /* type-free list */
  struct LIST_NODE;
  typedef struct LIST_NODE LIST_NODE;

  struct LIST;
  typedef struct LIST LIST;

  LIST *allocList(unsigned int itemSize);
  void freeList(LIST *list);

  void listPushFront(LIST *list, const void *data);
  void listPushFrontNodeNoCopy(LIST *list, LIST_NODE *node);
  void listPushBack(LIST *list, const void *data);
  void listInsert(LIST *list, LIST_NODE* prevNode, const void *data);

  int listLen(LIST *list);

  void *listFirstData(LIST *list);
  void *listLastData(LIST *list);

  LIST_NODE *listPopFrontNode(LIST *list);
  void listRemoveFront(LIST *list);

  void listClear(LIST *list);
  void freeNode(LIST_NODE *node);

  LIST_NODE *listFirstNode(LIST *list);
  LIST_NODE *listNextNode(LIST_NODE *node);

  void *listNodeData(LIST_NODE *node);
  void updateNodeData(LIST *list, LIST_NODE *node, const void *data);
  LIST_NODE* updateNodeNext(LIST *list, LIST_NODE *node, LIST_NODE *newNext);
  void updatelistFirst(LIST* list, LIST_NODE *node);
  void updatelistLength(LIST* list, unsigned int newLength);
  void printList(LIST* list, int stream, void (*printDataFunc)(void*,int,void*));

#ifdef __cplusplus
}
#endif

#endif
