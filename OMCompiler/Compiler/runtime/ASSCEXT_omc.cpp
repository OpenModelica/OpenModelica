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
 * file:        ASSCEXT_omc.cpp
 * description: The ASSCEXT_omc.cpp file is the external implementation of
 *              MetaModelica package: Compiler/ASSC.mo.
 *              It contains the headers for ASSCEXT.cpp.
 *              This is used for the analytical to structural singularity conversion
 *              (ASSC) algorithm which is used for alias elimination and before index
 *              reduction.
 */

#include "meta/meta_modelica.h"
#include "ASSCEXT.cpp"
#include <stdlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "errorext.h"

#ifdef __cplusplus
extern "C" {
#endif

LIST** ASSC_fromDense(int* dense, int nv_, int ne_, int* nnz){
  // initialize rows
  int count = 0;
  LIST** mat = (LIST**) malloc(ne_ * sizeof(LIST*));
  for(int i=0; i<ne_; i++){
    mat[i] = allocList(allocAsscElement, free, copyAsscElement);
    for(int j=0; j<nv_; j++){
      if(dense[i*nv_+j] != 0){
        ASSC_ELEMENT elem = {.index = j, .value = dense[i*nv_+j]};
        listPushBack(mat[i], &elem);
        count++;
      };
    };
  };
  if (nnz)
  {
    *nnz = count;
  }
  return mat;
};

void ASSC_setMatrixDebug(int* dense, int nv_, int ne_){
  int nnz_;
  rows = ASSC_fromDense(dense, nv_, ne_, &nnz_);
  // initialize mapping
  mapping = (int*) malloc(ne_ * sizeof(int));

  for (int i = 0; i < ne_; i++) {
    mapping[i] = i;
  }
  ne = ne_;
  nv = nv_;
  nnz = nnz_;
}

// function to shuffle array
void randperm(int *array, int n) {
  if (n > 1) {
    for (int i = 0; i < n - 1; i++) {
      // j is random index such that i <= j < n
      int j = i + rand() / (RAND_MAX / (n - i) + 1);

      // swap array[i] and array[j]
      int temp = array[j];
      array[j] = array[i];
      array[i] = temp;
    }
  }
}

int main() {
int n = 10;
int arr[10];

// initialize array with 0 to n-1
for(int i = 0; i < n; i++) arr[i] = i;

// seed the random number generator
srand(time(NULL));

// generate permutation
randperm(arr, n);

// print result
for(int i = 0; i < n; i++) printf("%d ", arr[i]);
printf("\n");

return 0;
}

extern void ASSC_setMatrix(modelica_integer nvars, modelica_integer neqns, modelica_integer nz, modelica_metatype adj, modelica_metatype val)
{
  nv = nvars;
  ne = neqns;
  nnz = nz;

  int i=0;
  int j=0;
  mmc_sint_t adj_i, val_i;

  // initialize rows
  rows = (LIST**) malloc(ne * sizeof(LIST*));
  // initialize mapping
  mapping = (int*) malloc(ne * sizeof(int));
  for (int i = 0; i < ne; i++) {
    mapping[i] = i;
  }


  for (i=0; i<ne; ++i) {
    rows[i] = allocList(allocAsscElement, free, copyAsscElement);
    // TODO: check if adj_col and val_col have same size
    modelica_metatype adj_col = MMC_STRUCTDATA(adj)[i];
    modelica_metatype val_col = MMC_STRUCTDATA(val)[i];

    while ((MMC_GETHDR(adj_col) == MMC_CONSHDR) && (MMC_GETHDR(val_col) == MMC_CONSHDR)) {
      adj_i = MMC_UNTAGFIXNUM(MMC_CAR(adj_col));
      val_i = MMC_UNTAGFIXNUM(MMC_CAR(val_col));
      adj_col = MMC_CDR(adj_col);
      val_col = MMC_CDR(val_col);

      ASSC_ELEMENT elem = {.index = ((int)adj_i)-1, .value = (int)val_i};
      listPushBack(rows[i], &elem);
    }
  }
}

extern void ASSC_getMatrix(modelica_metatype adj, modelica_metatype val)
{
  mmc_uint_t len_adj = MMC_HDRSLOTS(MMC_GETHDR(adj));
  for (int i = 0; i <= len_adj-1; i++) {
    int length = listLen(rows[mapping[i]]);
    modelica_metatype adj_col = MMC_STRUCTDATA(adj)[i];
    modelica_metatype val_col = MMC_STRUCTDATA(val)[i];
    if (!listEmptyTest(rows[mapping[i]])) {
      LIST_NODE* node = listFirstNode(rows[mapping[i]]);
      ASSC_ELEMENT* node_data = (ASSC_ELEMENT*) listNodeData(node);
      adj_col = mmc_mk_cons(mmc_mk_icon(node_data->index),adj_col);
      val_col = mmc_mk_cons(mmc_mk_icon(node_data->value),val_col);
      while (listNextNode(node)) {
        ASSC_ELEMENT* nextElem = (ASSC_ELEMENT*) listNodeData(listNextNode(node));
        adj_col = mmc_mk_cons(mmc_mk_icon(nextElem->index),adj_col);
        val_col = mmc_mk_cons(mmc_mk_icon(nextElem->value),val_col);
        node = listNextNode(node);
      }
      MMC_STRUCTDATA(adj)[i] = listReverse(adj_col);
      MMC_STRUCTDATA(val)[i] = listReverse(val_col);
    }
  }
}

extern void ASSC_freeMatrix()
{
  if (rows){
    for (int i=0; i<ne; i++)
      freeList(rows[i]);
    free(rows);
  }
  rows=NULL;
}

extern void ASSC_printMatrix()
{
  cout << "Sparse Matrix:" << endl << "================" << endl;
  for (int i=0; i<ne; ++i) {
    if(abs(mapping[0]) > ne*ne){
      printf("%d: ",i);
    }else{
      printf("%d: ",mapping[i]);
    }
    applyList(rows[i], printAsscElement);
    printf("\n");
  }
}

extern void ASSC_bareiss()
{
  bareiss();
}

extern int ASSC_getNumberOfOperations(modelica_metatype nop)
{
  // get size of operations and save to nop
  int num = getNumberOfOperations();
  MMC_STRUCTDATA(nop)[1] = mmc_mk_icon(num);
  return num;
}

static void failBecauseLength(const char *function, const char *var1str, long len1, const char *var2str, long len2)
{
  char len1str[64],len2str[64];
  const char *tokens[5] = {var2str,len2str,len1str,var1str,function};
  snprintf(len1str,64,"%ld", (long) len1);
  snprintf(len2str,64,"%ld", (long) len2);
  c_add_message(NULL,-1,ErrorType_symbolic,ErrorLevel_internal,"%s failed because %s=%s!=%s=%s",tokens,5);
}

extern void ASSC_getOperations(modelica_metatype op_modes, modelica_metatype op_val1, modelica_metatype op_val2, modelica_metatype op_val3, modelica_metatype op_val4)
{
  // operations = NULL ?
  LIST* ops = getOperations();
  int ops_len = listLen(ops);
  //ops = NULL; //error test
  if (ops == NULL) {
    c_add_message(NULL, -1, ErrorType_symbolic, ErrorLevel_internal, "ASSCEXT.getOperations failed because ops == NULL",{},0);
    MMC_THROW();
  }
  if (op_modes == NULL) {
    c_add_message(NULL, -1, ErrorType_symbolic, ErrorLevel_internal, "ASSCEXT.getOperations failed because op_modes == NULL",{},0);
    MMC_THROW();
  }
  // size of all input arrays = size of operations ?
  mmc_uint_t len_modes = MMC_HDRSLOTS(MMC_GETHDR(op_modes));
  mmc_uint_t len1 = MMC_HDRSLOTS(MMC_GETHDR(op_val1));
  mmc_uint_t len2 = MMC_HDRSLOTS(MMC_GETHDR(op_val2));
  mmc_uint_t len3 = MMC_HDRSLOTS(MMC_GETHDR(op_val3));
  mmc_uint_t len4 = MMC_HDRSLOTS(MMC_GETHDR(op_val4));
  if (ops_len != len_modes) {
    failBecauseLength("BackendDAEEXT.getAssignment", "op length", ops_len, "op_modes length", len_modes);
    MMC_THROW();
  }
  if (ops_len != len1) {
    failBecauseLength("BackendDAEEXT.getAssignment", "op length", ops_len, "op_val1 length", len1);
    MMC_THROW();
  }
  if (ops_len != len2) {
    failBecauseLength("BackendDAEEXT.getAssignment", "op length", ops_len, "op_val2 length", len2);
    MMC_THROW();
  }
  if (ops_len != len3) {
    failBecauseLength("BackendDAEEXT.getAssignment", "op length", ops_len, "op_val3 length", len3);
    MMC_THROW();
  }
  if (ops_len != len4) {
    failBecauseLength("BackendDAEEXT.getAssignment", "op length", ops_len, "op_val4 length", len4);
    MMC_THROW();
  }
  // for loop over all operations; switch the mode and save values to the arrays
  LIST_NODE* node = listFirstNode(ops);
  int i = 0;
  while (node) {
      ASSC_OPERATION* op = (ASSC_OPERATION*) listNodeData(node);
      switch (op->mode) {
        case 0:
          MMC_STRUCTDATA(op_modes)[i] = mmc_mk_icon(op->mode);
          MMC_STRUCTDATA(op_val1)[i] = mmc_mk_icon(op->u.m0.pivot_index);
          MMC_STRUCTDATA(op_val2)[i] = mmc_mk_icon(op->u.m0.pivot_value);
          MMC_STRUCTDATA(op_val3)[i] = mmc_mk_icon(op->u.m0.update_index);
          MMC_STRUCTDATA(op_val4)[i] = mmc_mk_icon(op->u.m0.update_value);
          break;
        case 1:
          MMC_STRUCTDATA(op_modes)[i] = mmc_mk_icon(op->mode);
          MMC_STRUCTDATA(op_val1)[i] = mmc_mk_icon(op->u.m1.index1);
          MMC_STRUCTDATA(op_val2)[i] = mmc_mk_icon(op->u.m1.index2);
          break;
        case 2:
          MMC_STRUCTDATA(op_modes)[i] = mmc_mk_icon(op->mode);
          MMC_STRUCTDATA(op_val1)[i] = mmc_mk_icon(op->u.m2.index);
          MMC_STRUCTDATA(op_val2)[i] = mmc_mk_icon(op->u.m2.gcd_value);
          break;}
      node = listNextNode(node);
      i += 1;
  }
}

#ifdef __cplusplus
}
#endif
