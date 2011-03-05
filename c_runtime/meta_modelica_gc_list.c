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

#include "modelica.h"


/* make an empty list */
mmc_List list_create(void)
{
  return NULL;
}

/* return nonzero if the list is empty */
int list_empty(mmc_List list)
{
  return list == NULL;
}

/* number of elements */
int list_length(mmc_List list)
{
  struct mmc_ListElement *curPtr;
  int count = 0;

  curPtr = list;

  while(curPtr != NULL)
  {
     curPtr = curPtr->next;
     count++;
  }
  return count;
}

/* deleting a node from list depending upon the data in the node */
int list_delete(mmc_List* list, mmc_GC_free_slot slot)
{
  struct mmc_ListElement *prevPtr = NULL, *curPtr = NULL;

  curPtr = *list;

  while(curPtr != NULL)
  {
     if(curPtr->el.start == slot.start)
     {
        if(curPtr == *list)
        {
           *list = curPtr->next;
           free(curPtr);
           return 0;
        }
        else
        {
           prevPtr->next = curPtr->next;
           free(curPtr);
           return 0;
        }
     }
     else
     {
        prevPtr = curPtr;
        curPtr = curPtr->next;
     }
  }
  /* not found */
  return 1;
}

/* deleting a node from list depending on the location */
int list_delete_nth(mmc_List* list, int loc)
{
  struct mmc_ListElement *prevPtr = NULL, *curPtr = NULL;
  int i;

  curPtr = *list;

  if(loc > (list_length(*list)) || loc <= 0)
  {
      printf("\nDeletion of mmc_ListElement at given location is not possible\n ");
  }
  else
  {
      /* if the location is starting of the list */
      if (loc == 1)
      {
          *list = curPtr->next;
          free(curPtr);
          return 0;
      }
      else
      {
          for(i = 1;i < loc; i++)
          {
              prevPtr = curPtr;
              curPtr = curPtr->next;
          }

          prevPtr->next = curPtr->next;
          free(curPtr);
      }
  }
  return 1;
}

/* delete the entire list */
int list_clear(mmc_List* list)
{
  struct mmc_ListElement *prevPtr, *curPtr;

  curPtr = *list;

  while(curPtr != NULL)
  {
        if(curPtr == *list)
        {
           *list = curPtr->next;
           free(curPtr);
           return 0;
        }
        else
        {
           prevPtr->next = curPtr->next;
           free(curPtr);
           return 0;
        }
        curPtr = curPtr->next;
  }

  *list = NULL;

  return 1;
}

/* adding a mmc_GC_free_slot at the end of the list */
int list_add(mmc_List* list, mmc_GC_free_slot slot)
{
  struct mmc_ListElement *temp1, *temp2;

  temp1 = (struct mmc_ListElement *)malloc(sizeof(struct mmc_ListElement));

  assert(temp1 != 0);

  temp1->el = slot;

  /* copying the *list location into another node */
  temp2 = *list;

  if(*list == NULL)
  {
     /* if list is empty we create first mmc_ListElement. */
     *list = temp1;
     (*list)->next = NULL;
  }
  else
  {
     /* traverse down to end of the list */
     while(temp2->next != NULL)
     temp2 = temp2->next;

     /* append at the end of the list */
     temp1->next = NULL;
     temp2->next = temp1;
  }

  return 0;
}

/* adding a mmc_GC_free_slot at the end of the list */
int list_cons(mmc_List* list, mmc_GC_free_slot slot)
{
  struct mmc_ListElement *temp;

  temp = (struct mmc_ListElement *)malloc(sizeof(struct mmc_ListElement));

  assert(temp != 0);

  temp->el = slot;

  if (*list == NULL)
  {
     /* list is empty */
     *list = temp;
     (*list)->next = NULL;
  }
  else
  {
     temp->next = *list;
     *list = temp;
  }

  return 0;
}


/* displaying list contents */
void list_dump(mmc_List* list)
{
  struct mmc_ListElement *curPtr = NULL;
  curPtr = *list;

  if(curPtr == NULL)
  {
     printf("\nList is Empty");
  }
  else
  {
      fprintf(stderr, "\nElements in the List: ");
      /* traverse the entire linked list */
      while(curPtr != NULL)
      {
          fprintf(stderr, "p[%p], size[%ld]\n", curPtr->el.start, curPtr->el.size);
          curPtr = curPtr->next;
      }
      fprintf(stderr, "\n");
      fflush(NULL);
  }
}

/* reversing a list */
int list_reverse(mmc_List* list)
{
  struct mmc_ListElement *prevPtr = NULL, *curPtr = NULL, *temp = NULL;

  curPtr = *list;
  prevPtr = NULL;

  while(curPtr != NULL)
  {
     temp = prevPtr;
     prevPtr = curPtr;

     curPtr = curPtr->next;
     prevPtr->next = temp;
  }

  *list = prevPtr;

  return 0;
}

/* clone a list in reverse! */
mmc_List list_clone(mmc_List list)
{
  mmc_List lst = NULL, curPtr = list;

  /* if empty return empty */
  if (!curPtr)
    return lst;

    while(curPtr != NULL)
    {
      list_cons(&lst, curPtr->el);
      curPtr = curPtr->next;
    }

    return lst;
}

