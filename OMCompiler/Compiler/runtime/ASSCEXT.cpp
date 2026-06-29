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
#include "ASSCEXT.h"
#include <stdio.h>
#include <stdbool.h>

bool DEBUG = false;
#define DEBUG_PRINT(...) \
    do { if (DEBUG) printf(__VA_ARGS__); } while (0)

using namespace std;

#ifdef __cplusplus
extern "C" {
#endif

static int nv;
static int ne;
static int nnz;

LIST** rows = NULL;
static int* mapping=NULL;
LIST* saves;
ASSC_OPERATION* save_operation;

void* allocAsscElement(const void* data)
{
  void* new_element = malloc(sizeof(ASSC_ELEMENT));
  assertStreamPrint(NULL, new_element != NULL, "ASSC_ELEMENT out of memory.");
  return new_element;
};

void* allocAsscOperation(const void* data)
{
  void* new_element = malloc(sizeof(ASSC_OPERATION));
  assertStreamPrint(NULL, new_element != NULL, "ASSC_OPERATION out of memory.");
  return new_element;
};

bool isEqualAsscElement(ASSC_ELEMENT e1, ASSC_ELEMENT e2){
  return(e1.index == e2.index && e1.value == e2.value);
};

bool isEqualAsscRow(LIST* l1, LIST* l2){
  bool b = true;

  LIST_NODE *ln_ptr1 = listFirstNode(l1);
  LIST_NODE *ln_ptr2 = listFirstNode(l2);
  while(ln_ptr1 && ln_ptr2){
    b = isEqualAsscElement(*(ASSC_ELEMENT *)listNodeData(ln_ptr1), *(ASSC_ELEMENT *)listNodeData(ln_ptr2));
    if(!b){
      return false;
    }
    ln_ptr1 = listNextNode(ln_ptr1);
    ln_ptr2 = listNextNode(ln_ptr2);
  }
  return !ln_ptr1 && !ln_ptr2;
};

bool isEqualAsscMatrix(LIST** m1, LIST** m2, int* mapping, int ne){
  bool b = true;
  for(int i=0; i<ne; i++){
    b = isEqualAsscRow(m1[mapping[i]], m2[i]);
    if(!b){
      return false;
    }
  }
  return true;
}

bool isEqualAsscMatrixDebug(LIST **mref, int *mappingref, int ne)
{
  return isEqualAsscMatrix(rows, mref, mappingref, ne);
}

void copyAsscElement(void* dest, const void* src)
{
  memcpy(dest, src, sizeof(ASSC_ELEMENT));
};

void copyAsscOperation(void* dest, const void* src)
{
  memcpy(dest, src, sizeof(ASSC_OPERATION));
};

void printAsscElement(void* data)
{
  if(data){
    ASSC_ELEMENT* elem = (ASSC_ELEMENT*) data;
    printf("(%d: %d) ", (int) elem->index, (int) elem->value);
  }else{
    printf("empty");
  }
}

void printAsscOperation(void* data)
{
  if(data){
    ASSC_OPERATION* elem = (ASSC_OPERATION*) data;
    switch (elem->mode) {
      case 0:
        printf("(mode %d: %d, %d, %d, %d) ",
              elem->mode,
              elem->u.m0.pivot_index,
              elem->u.m0.pivot_value,
              elem->u.m0.update_index,
              elem->u.m0.update_value);
        break;

      case 1:
        printf("(mode %d: %d, %d) ",
              elem->mode,
              elem->u.m1.index1,
              elem->u.m1.index2);
        break;

      case 2:
        printf("(mode %d: %d, %d) ",
              elem->mode,
              elem->u.m2.index,
              elem->u.m2.gcd_value);
        break;}
  }else{
    printf("empty");
  }
}

int findAsscElement(LIST* list, int ind) {
  LIST_NODE* tmpNode;
  ASSC_ELEMENT* tmpElem;
  ASSC_ELEMENT* nextElem;
  tmpNode = listFirstNode(list);
  tmpElem = (ASSC_ELEMENT*) listNodeData(tmpNode);
  if(tmpElem->index == ind){ // maybe not relevant
    return tmpElem->value;
  }
  else {
    while (listNextNode(tmpNode)) {
      nextElem = (ASSC_ELEMENT*) listNodeData(listNextNode(tmpNode));
      if (nextElem->index == ind) {
        return nextElem->value;
      }
      else if(nextElem->index > ind){
        return 0;
      }
      tmpNode = listNextNode(tmpNode);
    }
  }
  return 0;
}

// compute the greatest common divisor of two numbers (Euclidean algorithm)
int gcd(int a, int b) {
    while (b != 0) {
        int temp = b;
        b = a % b;
        a = temp;
    }
    return a;
}

// compute the greatest common divisor of multiple numbers
int gcd_multi_arr(int arr[], int n) {
    if (n <= 0) {
        return 0;
    }
    int result = arr[0];
    for (int i = 1; i < n; i++) {
        result = gcd(result, arr[i]); // compute the gcd of the current result and the next number
    }
    return result;
}
// compute the greatest common divisor of multiple numbers
int gcd_multi_list(LIST *list) {
    int n = listLen(list);
    if (n <= 0) {
        return 0;
    }
    LIST_NODE* node = listFirstNode(list);
    ASSC_ELEMENT* elem = (ASSC_ELEMENT*) listNodeData(node);
    int result = elem->value;
    while (node) {
        ASSC_ELEMENT* e = (ASSC_ELEMENT*) listNodeData(node);
        result = gcd(result, e->value); // compute the gcd of the current result and the next number
        node = listNextNode(node);
    }

    return result;
}

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
  int shift = 0;
  DEBUG_PRINT("mapping ");
  for (int i = 0; i < n; i++) {
      mapping[i] = i;
      DEBUG_PRINT("%d ", mapping[i]);
  }
  DEBUG_PRINT("\n");
  // check if there is an empty row (singular)
  for (int row = 0; row<ne; row++){
    if(listEmptyTest(rows[mapping[row]])){
      DEBUG_PRINT("INITIAL SINGULAR\n");
      return;
    }
  }
  // TODO: permutate that leading principal minors are non zero
  saves = allocList(allocAsscOperation, free, copyAsscOperation);
  save_operation = (ASSC_OPERATION*) allocAsscOperation(NULL);
  for(int k = 0; k < n-1; k++) {
    if(k == 0){
      prev_pivot = (ASSC_ELEMENT*) allocAsscElement(NULL);
      prev_pivot->index = -1;
      prev_pivot->value = 1;
      DEBUG_PRINT("no_prev_pivot ");
      if(DEBUG) {printAsscElement(prev_pivot);}
      DEBUG_PRINT("\n");
    }else{
      prev_pivot = (ASSC_ELEMENT*) listFirstData(rows[mapping[k-1]]); // M_{k-1,k-1}
      DEBUG_PRINT("prev_pivot ");
      if(DEBUG) {printAsscElement(prev_pivot);}
      DEBUG_PRINT("\n");
    }
    pivot_node = listFirstNode(rows[mapping[k]]);
    pivot = (ASSC_ELEMENT*) listFirstData(rows[mapping[k]]); // M_{k,k}
    DEBUG_PRINT("pivot ");
    if(DEBUG) {printAsscElement(pivot);}
    DEBUG_PRINT("\n");
    // check if element is nonzero == check if index is k
    // if is zero -> traverse rows down until nonzero is found (if none is found -> singular -> skip this)
    if(pivot->index != k + shift){
      DEBUG_PRINT("ZERO, k = %d, index = %d \n", k, pivot->index);
      int index_new = n;
      for(int k_new = k; k_new < n; k_new++){
        DEBUG_PRINT("k_new %d \n",k_new);
        new_pivot = (ASSC_ELEMENT*) listFirstData(rows[mapping[k_new]]); // M_{k_new,k_new}
        DEBUG_PRINT("new pivot ");
        if(DEBUG) {printAsscElement(new_pivot);}
        DEBUG_PRINT("\n");

        // take smallest
        if(new_pivot->index < index_new){
          pivot = new_pivot;
          pivot_ind = k_new;
          pivot_node = listFirstNode(rows[mapping[pivot_ind]]);
          index_new = new_pivot->index;
        }
      }
      if(pivot->index != k){ // none is found -> empty column (singular)
        shift = pivot->index - k;
        DEBUG_PRINT("pivot ");
        if(DEBUG) {printAsscElement(pivot);}
        DEBUG_PRINT("\n");
      }else{
        // adjust mapping
        DEBUG_PRINT("adjust mapping: \n");
        DEBUG_PRINT("k = %d, pivot_ind = %d \n",k, pivot_ind);
        int help_mapping = mapping[k];
        mapping[k] = mapping[pivot_ind];
        mapping[pivot_ind] = help_mapping;
        DEBUG_PRINT("mapping ");
        for (int i = 0; i < n; i++) {
          DEBUG_PRINT("%d ", mapping[i]);
        }
        DEBUG_PRINT("\n");
      }
      // save swap rows operation
      save_operation->mode = 1;
      save_operation->u.m1.index1 = k;
      save_operation->u.m1.index2 = pivot_ind;
      listPushBack(saves,save_operation);
    }

    for(int i = k+1; i < n; i++){
        save_operation->mode = 0;
        save_operation->u.m0.pivot_index = k;
        save_operation->u.m0.pivot_value = pivot->value;
        elem = (ASSC_ELEMENT*) listFirstData(rows[mapping[i]]);
        DEBUG_PRINT("first elem rows[i], i = %d, ",i);
        if(DEBUG) {printAsscElement(elem);}
        DEBUG_PRINT("\n");
        if(elem->index == k + shift){
          LIST_NODE* m_ik_node = listPopFrontNode(rows[mapping[i]]); // M_{i,k}
          ASSC_ELEMENT* m_ik_elem = (ASSC_ELEMENT*) listNodeData(m_ik_node);
          DEBUG_PRINT("m_ik elem ");
          if(DEBUG) {printAsscElement(m_ik_elem);}
          DEBUG_PRINT("\n");
          save_operation->u.m0.update_index = i;
          save_operation->u.m0.update_value = m_ik_elem->value;
          listPushBack(saves,save_operation);
          // traverse rows[k] and rows[i] simultaneously

          // next_elem_pivot_row <- rows[k].next
          // next_elem_update_row <- rows[i].next
          next_elem_pivot_row_node = listNextNode(pivot_node);
          if(next_elem_pivot_row_node == NULL){
            next_elem_pivot_row = (ASSC_ELEMENT*) allocAsscElement(NULL);
            next_elem_pivot_row->index = n;
            next_elem_pivot_row->value = 0;
          }else{
            next_elem_pivot_row = (ASSC_ELEMENT*) listNodeData(next_elem_pivot_row_node);
          }
          next_elem_update_row_node = listNextNode(m_ik_node);
          if(next_elem_update_row_node == NULL){
            next_elem_update_row = (ASSC_ELEMENT*) allocAsscElement(NULL);
            next_elem_update_row->index = n;
            next_elem_update_row->value = 0;
          }else{
            next_elem_update_row = (ASSC_ELEMENT*) listNodeData(next_elem_update_row_node);
          }
          prev_update_node = NULL;
          DEBUG_PRINT("next pivot elem ");
          if(DEBUG) {printAsscElement(next_elem_pivot_row);}
          DEBUG_PRINT("\n");
          DEBUG_PRINT("next update elem ");
          if(DEBUG) {printAsscElement(next_elem_update_row);}
          DEBUG_PRINT("\n");
          while (next_elem_pivot_row){
            // case 0: k.index == i.index == n -> break
            if(next_elem_pivot_row->index == n && next_elem_update_row->index == n){
              DEBUG_PRINT("case 0\n");
              // calculate gcd
              LIST* row = rows[mapping[i]];
              int r = 0;
              LIST_NODE* node = listFirstNode(row);
              while (node) {
                  ASSC_ELEMENT* elem = (ASSC_ELEMENT*) listNodeData(node);
                  if(abs(elem->value)>=1000){
                    r++;
                  }
                  node = listNextNode(node);
              }
              if(r==listLen(row) && r!=0){
                int gcd_val = gcd_multi_list(row);
                // save gcd operation
                save_operation->mode = 2;
                save_operation->u.m2.index = i;
                save_operation->u.m2.gcd_value = gcd_val;
                listPushBack(saves,save_operation);
                // divide each element by gcd value
                if(gcd_val != 0){
                  LIST_NODE* node = listFirstNode(row);
                  while (node) {
                      ASSC_ELEMENT* elem = (ASSC_ELEMENT*) listNodeData(node);
                      if(DEBUG) {printAsscElement(elem);}
                      DEBUG_PRINT("new value after dividing by gcd ");
                      elem->value = elem->value / gcd_val;
                      if(DEBUG) {printAsscElement(elem);}
                      DEBUG_PRINT("\n");
                      node = listNextNode(node);
                  }
                }
              }
              break;
            }
            // case 1: k.index == i.index
            else if(next_elem_pivot_row->index == next_elem_update_row->index){
              DEBUG_PRINT("case 1\n");
              new_val = (next_elem_update_row->value * pivot->value - m_ik_elem->value * next_elem_pivot_row->value);// / prev_pivot->value;
              DEBUG_PRINT("new val %d \n", new_val);
              // remove if 0
              if(new_val == 0 && listLen(rows[mapping[i]])==1)
              {
                DEBUG_PRINT("case1.1\n");
                listPopFrontNode(rows[mapping[i]]);
              }else if(new_val == 0 && listLen(rows[mapping[i]])>1){
                DEBUG_PRINT("case1.2\n");
                if(prev_update_node){
                  DEBUG_PRINT("case1.2.1\n");
                  listPopNode(rows[mapping[i]],prev_update_node);
                } else{
                  DEBUG_PRINT("case1.2.2\n");
                  listPopFrontNode(rows[mapping[i]]);
                }
              }
              else{
                next_elem_update_row->value = new_val;
              }
              // both next
              // i.next
              if(listNextNode(next_elem_update_row_node)){
                prev_update_node = next_elem_update_row_node;
                DEBUG_PRINT("prev update node ");
                if(DEBUG) {printAsscElement((ASSC_ELEMENT*) listNodeData(prev_update_node));}
                DEBUG_PRINT("\n");
                next_elem_update_row_node = listNextNode(next_elem_update_row_node);
                next_elem_update_row = (ASSC_ELEMENT*) listNodeData(next_elem_update_row_node);
                DEBUG_PRINT("next update elem ");
                if(DEBUG) {printAsscElement(next_elem_update_row);}
                DEBUG_PRINT("\n");
              }else{ // case 2+ (no next element in update row)
                if(DEBUG) {DEBUG_PRINT("no i.next\n");}
                prev_update_node = next_elem_update_row_node;
                DEBUG_PRINT("prev update node ");
                if(DEBUG) {printAsscElement((ASSC_ELEMENT*) listNodeData(prev_update_node));}
                DEBUG_PRINT("\n");
                next_elem_update_row = (ASSC_ELEMENT*) allocAsscElement(NULL);
                next_elem_update_row->index = n;
                next_elem_update_row->value = 0;
                DEBUG_PRINT("next update elem ");
                if(DEBUG) {printAsscElement(next_elem_update_row);}
                DEBUG_PRINT("\n");
              }
              // k.next
              if(listNextNode(next_elem_pivot_row_node)){
                prev_pivot_node = next_elem_pivot_row_node;
                DEBUG_PRINT("prev pivot node ");
                if(DEBUG) {printAsscElement((ASSC_ELEMENT*) listNodeData(prev_pivot_node));}
                DEBUG_PRINT("\n");
                next_elem_pivot_row_node = listNextNode(next_elem_pivot_row_node);
                next_elem_pivot_row = (ASSC_ELEMENT*) listNodeData(next_elem_pivot_row_node);
                DEBUG_PRINT("next pivot elem ");
                if(DEBUG) {printAsscElement(next_elem_pivot_row);}
                DEBUG_PRINT("\n");
              }else{ // case 3+ (no next element in pivot row)
                DEBUG_PRINT("no k.next\n");
                prev_pivot_node = next_elem_pivot_row_node;
                DEBUG_PRINT("prev pivot node ");
                if(DEBUG) {printAsscElement((ASSC_ELEMENT*) listNodeData(prev_pivot_node));}
                DEBUG_PRINT("\n");
                next_elem_pivot_row = (ASSC_ELEMENT*) allocAsscElement(NULL);
                next_elem_pivot_row->index = n;
                next_elem_pivot_row->value = 0;
                DEBUG_PRINT("next pivot elem ");
                if(DEBUG) {printAsscElement(next_elem_pivot_row);}
                DEBUG_PRINT("\n");
              }
            }
            // case 2: k.index > i.index
            else if(next_elem_pivot_row->index > next_elem_update_row->index){
              DEBUG_PRINT("case 2\n");
              new_val = (next_elem_update_row->value * pivot->value);// / prev_pivot->value;
              DEBUG_PRINT("new val %d \n", new_val);
              // remove if 0
              if(new_val == 0 && listLen(rows[mapping[i]])==1)
              {
                listPopFrontNode(rows[mapping[i]]);
              }else if(new_val == 0 && listLen(rows[mapping[i]])>1){
                listPopNode(rows[mapping[i]],prev_update_node);
              }
              else{
                next_elem_update_row->value = new_val;
              }
              // i.next
              if(listNextNode(next_elem_update_row_node)){
                prev_update_node = next_elem_update_row_node;
                DEBUG_PRINT("prev update node ");
                if(DEBUG) {printAsscElement((ASSC_ELEMENT*) listNodeData(prev_update_node));}
                DEBUG_PRINT("\n");
                next_elem_update_row_node = listNextNode(next_elem_update_row_node);
                next_elem_update_row = (ASSC_ELEMENT*) listNodeData(next_elem_update_row_node);
                DEBUG_PRINT("next update elem ");
                if(DEBUG) {printAsscElement(next_elem_update_row);}
                DEBUG_PRINT("\n");
              }else{ // case 2+ (no next element in update row)
                DEBUG_PRINT("no i.next\n");
                prev_update_node = next_elem_update_row_node;
                DEBUG_PRINT("prev update node ");
                if(DEBUG) {printAsscElement((ASSC_ELEMENT*) listNodeData(prev_update_node));}
                DEBUG_PRINT("\n");
                next_elem_update_row = (ASSC_ELEMENT*) allocAsscElement(NULL);
                next_elem_update_row->index = n;
                next_elem_update_row->value = 0;
                DEBUG_PRINT("next update elem ");
                if(DEBUG) {printAsscElement(next_elem_update_row);}
                DEBUG_PRINT("\n");
              }
            }
            // case 3: k.index < i.index
            else if(next_elem_pivot_row->index < next_elem_update_row->index){
              DEBUG_PRINT("case 3\n");
              new_val = (-m_ik_elem->value * next_elem_pivot_row->value);
              DEBUG_PRINT("new val %d \n", new_val);
              // insert (i,j)
              new_elem = (ASSC_ELEMENT*) allocAsscElement(NULL);
              new_elem->index = next_elem_pivot_row->index;
              new_elem->value = new_val;
              DEBUG_PRINT("new_elem ");
              if(DEBUG) {printAsscElement(new_elem);}
              DEBUG_PRINT("\n");
              DEBUG_PRINT("first elem before listInsert %d,%d",i,mapping[i]);
              if(listEmptyTest(rows[mapping[i]])){
                DEBUG_PRINT("no list first\n");
              }else{
                if(DEBUG) {printAsscElement((ASSC_ELEMENT*) listFirstData(rows[mapping[i]]));}
              }
              DEBUG_PRINT("\n");
              if(prev_update_node){
                DEBUG_PRINT("list insert \n");
                listInsert(rows[mapping[i]], prev_update_node, new_elem);
                if(next_elem_update_row->index == n){
                  prev_update_node = listNextNode(prev_update_node);
                  DEBUG_PRINT("prev update node ");
                  if(DEBUG) {printAsscElement((ASSC_ELEMENT*) listNodeData(prev_update_node));}
                  DEBUG_PRINT("\n");
                }
              }else{
                DEBUG_PRINT("list push front \n");
                listPushFront(rows[mapping[i]], new_elem);
              };
              DEBUG_PRINT("first elem after listInsert ");fflush(NULL);
              if(DEBUG) {printAsscElement((ASSC_ELEMENT*) listFirstData(rows[mapping[i]]));}
              DEBUG_PRINT("\n");
              // k.next
              if(listNextNode(next_elem_pivot_row_node)){
                prev_pivot_node = next_elem_pivot_row_node;
                DEBUG_PRINT("prev pivot node ");
                if(DEBUG) {printAsscElement((ASSC_ELEMENT*) listNodeData(prev_pivot_node));}
                DEBUG_PRINT("\n");
                next_elem_pivot_row_node = listNextNode(next_elem_pivot_row_node);
                next_elem_pivot_row = (ASSC_ELEMENT*) listNodeData(next_elem_pivot_row_node);
                DEBUG_PRINT("next pivot elem ");
                if(DEBUG) {printAsscElement(next_elem_pivot_row);}
                DEBUG_PRINT("\n");
              }else{ // case 3+ (no next element in pivot row)
                DEBUG_PRINT("no k.next\n");
                prev_pivot_node = next_elem_pivot_row_node;
                DEBUG_PRINT("prev pivot node ");
                if(DEBUG) {printAsscElement((ASSC_ELEMENT*) listNodeData(prev_pivot_node));}
                DEBUG_PRINT("\n");
                next_elem_pivot_row = (ASSC_ELEMENT*) allocAsscElement(NULL);
                next_elem_pivot_row->index = n;
                next_elem_pivot_row->value = 0;
                DEBUG_PRINT("next pivot elem ");
                if(DEBUG) {printAsscElement(next_elem_pivot_row);}
                DEBUG_PRINT("\n");
              }
            }
          }
        }
      }
      DEBUG_PRINT("k = %d ,shift = %d \n",k,shift);
      if(DEBUG) {
        for (int z=0; z<ne; ++z) {
          applyList(rows[mapping[z]], printAsscElement);
          printf("\n");
        }
      }
    }
  }

int getNumberOfOperations()
{
  return listLen(saves);
}

LIST* getOperations()
{
  return saves;
}

#ifdef __cplusplus
}
#endif

