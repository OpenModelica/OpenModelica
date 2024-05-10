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

/*! \file doubleEndedList.h
 *
 * Description: This file is a C header file for the simulation runtime.
 * It contains a simple double ended list.
 */

#ifndef _DOUBLEENDEDLIST_H_
#define _DOUBLEENDEDLIST_H_

#ifdef __cplusplus
extern "C" {
#endif

  struct DOUBLE_ENDED_LIST_NODE;
  typedef struct DOUBLE_ENDED_LIST_NODE DOUBLE_ENDED_LIST_NODE;
  struct DOUBLE_ENDED_LIST;
  typedef struct DOUBLE_ENDED_LIST DOUBLE_ENDED_LIST;

  /* Section for allocating and freeing double ended list */
  DOUBLE_ENDED_LIST* allocDoubleEndedList(unsigned int itemSize);
  void freeDoubleEndedList(DOUBLE_ENDED_LIST *list);
  void freeNodeDoubleEndedList(DOUBLE_ENDED_LIST_NODE *node);

  /* Section for adding nodes */
  DOUBLE_ENDED_LIST_NODE* createNodeDoubleEndedList(const void* data, unsigned int itemSize);
  void pushFrontDoubleEndedList(DOUBLE_ENDED_LIST* list, const void* data);
  void pushBackDoubleEndedList(DOUBLE_ENDED_LIST* list, const void* data);
  void insertDoubleEndedList(DOUBLE_ENDED_LIST *list, DOUBLE_ENDED_LIST_NODE* prevNode, const void *data);

  /* Section for removing nodes */
  void removeNodeDoubleEndedList(DOUBLE_ENDED_LIST* list, DOUBLE_ENDED_LIST_NODE *node);
  void removeFirstDoubleEndedList(DOUBLE_ENDED_LIST *list);
  void removeLastDoubleEndedList (DOUBLE_ENDED_LIST *list);
  void clearDoubleEndedList(DOUBLE_ENDED_LIST *list);
  void clearBeforeNodeDoubleEndedList(DOUBLE_ENDED_LIST *list, DOUBLE_ENDED_LIST_NODE* newFrontNode);
  void clearAfterNodeDoubleEndedList(DOUBLE_ENDED_LIST *list, DOUBLE_ENDED_LIST_NODE* startNode);

  /* Section for getting nodes */
  DOUBLE_ENDED_LIST_NODE* getFirstNodeDoubleEndedList(DOUBLE_ENDED_LIST *list);
  DOUBLE_ENDED_LIST_NODE* getLastNodeDoubleEndedList(DOUBLE_ENDED_LIST *list) ;
  DOUBLE_ENDED_LIST_NODE* getPreviousNodeDoubleEndedList(DOUBLE_ENDED_LIST_NODE *currentNode);
  DOUBLE_ENDED_LIST_NODE* getNextNodeDoubleEndedList(DOUBLE_ENDED_LIST_NODE *currentNode);

  /* Section for getting data from nodes */
  void* firstDataDoubleEndedList(DOUBLE_ENDED_LIST *list);
  void* lastDataDoubleEndedList(DOUBLE_ENDED_LIST *list);
  void* dataDoubleEndedList(DOUBLE_ENDED_LIST_NODE *node);

  /* Section for small helper functions */
  int doubleEndedListLen(DOUBLE_ENDED_LIST *list);
  void doubleEndedListPrint(DOUBLE_ENDED_LIST *list, int stream, void (*printDataFunc)(void*,int,void*));

#ifdef __cplusplus
}
#endif

#endif
