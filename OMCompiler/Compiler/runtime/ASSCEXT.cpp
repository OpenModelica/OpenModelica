/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * file:        ASSCEXT.cpp
 * description: The ASSCEXT.cpp file is the external implementation of
 *              MetaModelica package: Compiler/ASSC.mo.
 *              This is used for the analytical to structural singularity conversion
 *              (ASSC) algorithm which is used for alias elimination and before index
 *              reduction.
 */

#include <iostream>
#include <fstream>
#include <map>
#include <set>
#include <string>
#include <vector>
#include <cassert>
#include "../../SimulationRuntime/c/util/list.h"

using namespace std;

#ifdef __cplusplus
extern "C" {
#endif

static int nv;
static int ne;
static int nnz;
static int* col_ptrs=NULL; // del
static int* col_ids=NULL; // del
static int* col_val=NULL; // del

LIST** rows = NULL;
static int* mapping=NULL;

typedef struct{
  int index;
  int value;
} ASSC_ELEMENT;

void* allocAsscElement(const void* data)
{
  void* new_element = malloc(sizeof(ASSC_ELEMENT));
  assertStreamPrint(NULL, new_element != NULL, "ASSC_ELEMENT out of memory.");
  return new_element;
};

void copyAsscElement(void* dest, const void* src)
{
  memcpy(dest, src, sizeof(ASSC_ELEMENT));
};

void printAsscElement(void* data)
{
  ASSC_ELEMENT* elem = (ASSC_ELEMENT*) data;
  printf("(%d: %d) ", (int) elem->index, (int) elem->value);
}

/* find element in list --> to compute M_{k,j}
input list
input index
output value

while list->next
  if next->index == index
    return next-> value
  elseif next->index > index
    return 0

return 0
*/
int findAsscElement(LIST* list, int ind) {
  printf("find \n");
  LIST_NODE* tmpNode;
  ASSC_ELEMENT* tmpElem;
  ASSC_ELEMENT* nextElem;
  tmpNode = listFirstNode(list);
  tmpElem = (ASSC_ELEMENT*) listNodeData(tmpNode);
  printAsscElement(tmpElem);
  printf("\n");
  if(tmpElem->index == ind){ // maybe not relevant
    return tmpElem->value;
  }
  else {
    while (listNextNode(tmpNode)) {
      nextElem = (ASSC_ELEMENT*) listNodeData(listNextNode(tmpNode));
      printAsscElement(nextElem);
      printf("\n");
      if (nextElem->index == ind) {
        printf("end find \n");
        return nextElem->value;
      }
      else if(nextElem->index > ind){
        printf("end find \n");
        return 0;
      }
      tmpNode = listNextNode(tmpNode);
    }
  }
  printf("end find \n");
  return 0;
}
// utility function first data (check if exists)
/*
  if rows[i]->first
        elem = (ASSC_ELEMENT*) listFirstData(rows[i]);
*/

void bareiss()
{
  ASSC_ELEMENT* prev_pivot;
  LIST_NODE* pivot_node;
  ASSC_ELEMENT* pivot;
  ASSC_ELEMENT* new_pivot;
  LIST_NODE* prev_update_node;
  LIST_NODE* prev_pivot_node;
  ASSC_ELEMENT* elem;
  ASSC_ELEMENT* new_elem;
  LIST_NODE* next_elem_pivot_row_node;
  ASSC_ELEMENT* next_elem_pivot_row;
  LIST_NODE* next_elem_update_row_node;
  ASSC_ELEMENT* next_elem_update_row;
  int n = min(ne,nv);
  int no_prev_pivot;
  int pivot_ind;
  int val;
  int new_val;
  printf("mapping ");
  for (int i = 0; i < n; i++) {
      mapping[i] = i;
      printf("%d ", mapping[i]);
  }
  printf("\n");
  for(int k = 0; k < n-1; k++) {
    if(k == 0){
      //no_prev_pivot = 1;
      prev_pivot = (ASSC_ELEMENT*) allocAsscElement(NULL);
      prev_pivot->index = -1;
      prev_pivot->value = 1;
      printf("no_prev_pivot ");
      printAsscElement(prev_pivot);
      printf("\n");
    }else{
      prev_pivot = (ASSC_ELEMENT*) listFirstData(rows[mapping[k-1]]); // M_{k-1,k-1}
      printf("prev_pivot ");
      printAsscElement(prev_pivot);
      printf("\n");
    }
    pivot_node = listFirstNode(rows[mapping[k]]);
    pivot = (ASSC_ELEMENT*) listFirstData(rows[mapping[k]]); // M_{k,k}
    printf("pivot ");
    printAsscElement(pivot);
    printf("\n");
    // check if element is nonzero == check if index is k
    // if is zero -> traverse rows down until nonzero is found (if none is found -> singular -> skip this)
    if(pivot->index != k){
      printf("ZERO, k = %d, index = %d \n", k, pivot->index);
      for(int k_new = k+1; k_new < n; k_new++){
        printf("k_new %d \n",k_new);
        new_pivot = (ASSC_ELEMENT*) listFirstData(rows[mapping[k_new]]); // M_{k_new,k_new}
        printf("new pivot ");
        printAsscElement(new_pivot);
        printf("\n");
        if(new_pivot->index == k){
          pivot = new_pivot;
          pivot_ind = k_new;
          break;
        }
      }
      if(pivot->index != k){ // none is found
        printf("SINGULAR\n");
      }else{
        // adjust mapping
        mapping[k] = pivot_ind;
        mapping[pivot_ind] = k;
        printf("mapping ");
        for (int i = 0; i < n; i++) {
          printf("%d ", mapping[i]);
        }
        printf("\n");
      }
    }

    for(int i = k+1; i < n; i++){
        elem = (ASSC_ELEMENT*) listFirstData(rows[mapping[i]]);
        printf("first elem rows[i], i = %d, ",i);
        printAsscElement(elem);
        printf("\n");
        if(elem->index == k){
          LIST_NODE* m_ik_node = listPopFrontNode(rows[mapping[i]]); // M_{i,k}
          ASSC_ELEMENT* m_ik_elem = (ASSC_ELEMENT*) listNodeData(m_ik_node);
          printf("m_ik elem ");
          printAsscElement(m_ik_elem);
          printf("\n");
          // traverse rows[k] and rows[i] simultaneously

          // next_elem_pivot_row <- rows[k].next
          // next_elem_update_row <- rows[i].next
          next_elem_pivot_row_node = listNextNode(pivot_node);
          next_elem_pivot_row = (ASSC_ELEMENT*) listNodeData(next_elem_pivot_row_node);
          next_elem_update_row_node = listNextNode(m_ik_node);
          next_elem_update_row = (ASSC_ELEMENT*) listNodeData(next_elem_update_row_node);
          prev_update_node = NULL;
          printf("next pivot elem ");
          printAsscElement(next_elem_pivot_row);
          printf("\n");
          printf("next update elem ");
          printAsscElement(next_elem_update_row);
          printf("\n");
          while (next_elem_pivot_row){
            // case 0: k.index == i.index == n -> break
            if(next_elem_pivot_row->index == n && next_elem_update_row->index == n){
              printf("case 0\n");
              break;
            }
            // case 1: k.index == i.index
            else if(next_elem_pivot_row->index == next_elem_update_row->index){
              printf("case 1\n");
              new_val = (next_elem_update_row->value * pivot->value - m_ik_elem->value * next_elem_pivot_row->value) / prev_pivot->value;
              printf("new val %d \n", new_val);
              next_elem_update_row->value = new_val; // remove if 0
              // both next
              // i.next
              if(listNextNode(next_elem_update_row_node)){
                prev_update_node = next_elem_update_row_node;
                printf("prev update node ");
                printAsscElement((ASSC_ELEMENT*) listNodeData(prev_update_node));
                printf("\n");
                next_elem_update_row_node = listNextNode(next_elem_update_row_node);
                next_elem_update_row = (ASSC_ELEMENT*) listNodeData(next_elem_update_row_node);
                printf("next update elem ");
                printAsscElement(next_elem_update_row);
                printf("\n");
              }else{ // case 2+
                printf("no i.next\n");
                prev_update_node = next_elem_update_row_node;
                printf("prev update node ");
                printAsscElement((ASSC_ELEMENT*) listNodeData(prev_update_node));
                printf("\n");
                next_elem_update_row = (ASSC_ELEMENT*) allocAsscElement(NULL);
                next_elem_update_row->index = n;
                next_elem_update_row->value = 0;
                printf("next update elem ");
                printAsscElement(next_elem_update_row);
                printf("\n");
              }
              // k.next
              if(listNextNode(next_elem_pivot_row_node)){
                prev_pivot_node = next_elem_pivot_row_node;
                printf("prev pivot node ");
                printAsscElement((ASSC_ELEMENT*) listNodeData(prev_pivot_node));
                printf("\n");
                next_elem_pivot_row_node = listNextNode(next_elem_pivot_row_node);
                next_elem_pivot_row = (ASSC_ELEMENT*) listNodeData(next_elem_pivot_row_node);
                printf("next pivot elem ");
                printAsscElement(next_elem_pivot_row);
                printf("\n");
              }else{ // case 3+
                printf("no k.next\n");
                prev_pivot_node = next_elem_pivot_row_node;
                printf("prev pivot node ");
                printAsscElement((ASSC_ELEMENT*) listNodeData(prev_pivot_node));
                printf("\n");
                next_elem_pivot_row = (ASSC_ELEMENT*) allocAsscElement(NULL);
                next_elem_pivot_row->index = n;
                next_elem_pivot_row->value = 0;
                printf("next pivot elem ");
                printAsscElement(next_elem_pivot_row);
                printf("\n");
              }
            }
            // case 2: k.index > i.index
            else if(next_elem_pivot_row->index > next_elem_update_row->index){
              printf("case 2\n");
              new_val = (next_elem_update_row->value * pivot->value) / prev_pivot->value;
              printf("new val %d \n", new_val);
              next_elem_update_row->value = new_val; // remove if 0
              // i.next
              if(listNextNode(next_elem_update_row_node)){
                prev_update_node = next_elem_update_row_node;
                printf("prev update node ");
                printAsscElement((ASSC_ELEMENT*) listNodeData(prev_update_node));
                printf("\n");
                next_elem_update_row_node = listNextNode(next_elem_update_row_node);
                next_elem_update_row = (ASSC_ELEMENT*) listNodeData(next_elem_update_row_node);
                printf("next update elem ");
                printAsscElement(next_elem_update_row);
                printf("\n");
              }else{ // case 2+
                printf("no i.next\n");
                prev_update_node = next_elem_update_row_node;
                printf("prev update node ");
                printAsscElement((ASSC_ELEMENT*) listNodeData(prev_update_node));
                printf("\n");
                next_elem_update_row = (ASSC_ELEMENT*) allocAsscElement(NULL);
                next_elem_update_row->index = n;
                next_elem_update_row->value = 0;
                printf("next update elem ");
                printAsscElement(next_elem_update_row);
                printf("\n");
              }
            }
            // case 3: k.index < i.index
            else if(next_elem_pivot_row->index < next_elem_update_row->index){
              printf("case 3\n");
              new_val = (-m_ik_elem->value * next_elem_pivot_row->value) / prev_pivot->value;
              printf("new val %d \n", new_val);
              // insert (i,j)
              new_elem = (ASSC_ELEMENT*) allocAsscElement(NULL);
              new_elem->index = next_elem_pivot_row->index;
              new_elem->value = new_val;
              printf("new_elem ");
              printAsscElement(new_elem);
              printf("\n");
              printf("first elem before listPushBack ");
              printAsscElement((ASSC_ELEMENT*) listFirstData(rows[mapping[i]]));
              printf("\n");
              if(prev_update_node){
                listInsert(rows[mapping[i]], prev_update_node, new_elem); //################################## insert before next elem still missing!!!
              }else{
                listPushFront(rows[mapping[i]], new_elem);
              };
              //listPushBack(rows[mapping[i]], new_elem);
              printf("first elem after listPushBack ");
              printAsscElement((ASSC_ELEMENT*) listFirstData(rows[mapping[i]]));
              printf("\n");
              // k.next
              if(listNextNode(next_elem_pivot_row_node)){
                prev_pivot_node = next_elem_pivot_row_node;
                printf("prev pivot node ");
                printAsscElement((ASSC_ELEMENT*) listNodeData(prev_pivot_node));
                printf("\n");
                next_elem_pivot_row_node = listNextNode(next_elem_pivot_row_node);
                next_elem_pivot_row = (ASSC_ELEMENT*) listNodeData(next_elem_pivot_row_node);
                printf("next pivot elem ");
                printAsscElement(next_elem_pivot_row);
                printf("\n");
              }else{ // case 3+
                printf("no k.next\n");
                prev_pivot_node = next_elem_pivot_row_node;
                printf("prev pivot node ");
                printAsscElement((ASSC_ELEMENT*) listNodeData(prev_pivot_node));
                printf("\n");
                next_elem_pivot_row = (ASSC_ELEMENT*) allocAsscElement(NULL);
                next_elem_pivot_row->index = n;
                next_elem_pivot_row->value = 0;
                printf("next pivot elem ");
                printAsscElement(next_elem_pivot_row);
                printf("\n");
              }
            }
            //next_elem_pivot_row_node = listNextNode(next_elem_pivot_row_node);
            //next_elem_pivot_row = (ASSC_ELEMENT*) listNodeData(next_elem_pivot_row_node);
          }
          /*
          for(int j = k+1; j < n; j++){
            elem = (ASSC_ELEMENT*) listFirstData(rows[mapping[i]]); // M_{i,j}
            printf("next elem rows[i] ");
            printAsscElement(elem);
            printf("\n");
            if(j < elem->index){
              int no_elem = 0;
              printf("no elem %d \n",no_elem);
              val = findAsscElement(rows[mapping[k]],j); // M_{k,j}
              printf("found val %d \n", val);
              new_val = (no_elem * pivot->value - m_ik_elem->value * val) / prev_pivot->value;
              printf("new val %d \n", new_val);
            }else{
              val = findAsscElement(rows[mapping[k]],j); // M_{k,j}
              printf("found val %d \n", val);
              new_val = (elem->value * pivot->value - m_ik_elem->value * val) / prev_pivot->value;
              printf("new val %d \n", new_val);
              elem->value = new_val; // remove if 0
              printf("new elem ");
              printAsscElement(elem);
              printf("\n");
            }*/
          }
        }
    }
    printf("\nmapping ");
    for (int i = 0; i < n; i++) {
      printf("%d ", mapping[i]);
    }
    printf("\n");
  }

  /*
  mapping = 0,1,2,3,4,5, |size rows|

  at row 2 is a zero -> search -> find nonzero at 4

  mapping = 0,1,4,3,2,5,

  rows[i] -> rows[mapping[i]]

  1 0 1      1 0 1   swap  1 0 1
  2 0 1  ->  0 0 -1  ->    0 1 0
  0 1 1      0 1 0         0 0 -1

  0 2 0 3
  1 1 0 0
  0 2 0 2
  0 1 1 0

  */



  /*

  Input: M — an n-square matrix
  assuming its leading principal minors [M]k,k are all non-zero.

  FUTURE
  0. permutate that leading principal minors are non zero


  For k from 1 to n−1: || n is NV
      compute M_{k-1,k-1} (if k==1 then 1) and M_{k,k} // have to be first elements in corresponding row
      For i from k+1 to n: > traverses col_ptrs || n is NE
          compute M_{i,k}
          if M_{i,k} != 0:
              For j from k+1 to n: || traverse

                  Set M_{i,j}={M_{i,j}M_{k,k}-M_{i,k}M_{k,j}} / {M_{k-1,k-1}}
              Set Mi,k = 0
  Output: The matrix is modified in-place,
  each Mk,k entry contains the leading minor [M]k,k,
  entry Mn,n contains the determinant of the original M.


  */


#ifdef __cplusplus
}
#endif

