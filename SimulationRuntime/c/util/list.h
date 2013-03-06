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

  void listPushFront(LIST *list, void *data);
  void listPushBack(LIST *list, void *data);

  int listLen(LIST *list);

  void *listFirstData(LIST *list);
  void *listLastData(LIST *list);

  void listPopFront(LIST *list);

  void listClear(LIST *list);

  LIST_NODE *listFirstNode(LIST *list);
  LIST_NODE *listNextNode(LIST_NODE *node);

  void *listNodeData(LIST_NODE *node);

#ifdef __cplusplus
}
#endif

#endif
