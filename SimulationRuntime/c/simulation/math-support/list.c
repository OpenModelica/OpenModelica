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

/* File: list.c
 *
 * Description: This file is a C header file for the simulation runtime.
 * It contains a simple linked list
 */

#include "list.h"
#include <stdlib.h>
#include <assert.h>

void list_push_front(int data, List *list)
{
    List_Node *new_node = 0;
    assert(list);
    new_node = (List_Node*) malloc(sizeof(List_Node));
    new_node->data = data;
    new_node->next = list->first;
    list->first = new_node;
    if (list->last == NULL) {
        list->last = list->first;
    }
}

void list_push_back(int data, List *list)
{
    List_Node *new_node = 0;
    assert(list==0?0:1);
    new_node = (List_Node*) malloc(sizeof(List_Node));
    new_node->data = data;
    new_node->next = 0;
    if (list->last!=NULL) {
        list->last->next = new_node;
    } 
    list->last = new_node;
    if (list->first == NULL) {
        list->first = list->last;
    }
}

int list_empty(List list)
{
    return list.first==0?1:0;
}

int list_front(List list)
{
    assert(list.first);
    return list.first->data;
}

int list_last(List list)
{
    assert(list.last);
    return list.last->data;
}

void list_pop_front(List *list)
{
    if (list != NULL) {
        if (list->first != NULL) {
            List_Node *node = list->first->next;
             free(list);
             list->first = node;
             if (list->first == 0) {
                 list->last = list->first;
             }
        }
    } 
}

void list_clear(List *list)
{
    if (list == NULL) { 
        return;
    }
    while(list->first != NULL) {
        list_pop_front(list);
    }
}

List_Node* list_next(List_Node* node)
{
    if (node==0) {
        return 0;
    }
    return node->next;
}