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

struct list_node {
    int data;
    struct list_node *next;
};

struct list_list {
    struct list_node *first;
    struct list_node *last;
};

List* list_init()
{
    return (List*)calloc(1,sizeof(List));
}

void list_deinit(List *list)
{
    if (list) 
    {
        free(list);
    }
}

void list_push_front(List *list, int data)
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

void list_push_back(List *list, int data)
{
    List_Node *new_node = 0;
    assert(list);
    new_node = (List_Node*) malloc(sizeof(List_Node));
    new_node->data = data;
    new_node->next = 0;
    if (list->last!=NULL) {
        list->last->next = new_node;
    } 
    if (list->first == NULL) {
        list->first = list->last;
    }
    list->last = new_node;
}

int list_empty(List *list)
{
    assert(list);
    return list->first==0?1:0;
}

int list_front(List *list)
{
    assert(list);
    assert(list->first);
    return list->first->data;
}

int list_last(List *list)
{
    assert(list);
    assert(list->last);
    return list->last->data;
}

void list_pop_front(List *list)
{
    if (list != NULL) {
        if (list->first != NULL) {
            List_Node *node = list->first->next;
            free(list->first);
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

List_Node *list_first(List *list)
{
    assert(list);
    return list->first;
}

List_Node *list_next(List_Node *node)
{
    assert(node);
    if (node==0) {
        return 0;
    }
    return node->next;
}

int list_node_data(List_Node *node)
{
    assert(node);
    return node->data;
}
