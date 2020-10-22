/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * file:        BackendDAEEXT.cpp
 * description: The BackendDAEEXT.cpp file is the external implementation of
 *              MetaModelica package: Compiler/BackendDAEEXT.mo.
 *              This is used for the BLT and index reduction algorithms in BackendDAE.
 *              The implementation mainly consists of several bitvectors implemented
 *              using std::vector<bool> since such functionality is not available in
 *              MetaModelica Compiler (MMC).
 *
 *
 */

#include "meta/meta_modelica.h"
#include "BackendDAEEXT.cpp"
#include <stdlib.h>
#include "errorext.h"

extern "C" {

extern int BackendDAEEXT_getVMark(int _inInteger)
{
  return BackendDAEEXTImpl__getVMark(_inInteger);
}
extern void* BackendDAEEXT_getMarkedEqns()
{
  return BackendDAEEXTImpl__getMarkedEqns();
}
extern void BackendDAEEXT_eMark(int _inInteger)
{
  BackendDAEEXTImpl__eMark(_inInteger);
}
extern void BackendDAEEXT_clearDifferentiated()
{
  BackendDAEEXTImpl__clearDifferentiated();
}
extern void* BackendDAEEXT_getDifferentiatedEqns()
{
  return BackendDAEEXTImpl__getDifferentiatedEqns();
}
extern int BackendDAEEXT_getLowLink(int _inInteger)
{
  return BackendDAEEXTImpl__getLowLink(_inInteger);
}
extern void* BackendDAEEXT_getMarkedVariables()
{
  return BackendDAEEXTImpl__getMarkedVariables();
}
extern int BackendDAEEXT_getNumber(int _inInteger)
{
  return BackendDAEEXTImpl__getNumber(_inInteger);
}
extern void BackendDAEEXT_setNumber(int _inInteger1, int _inInteger2)
{
  BackendDAEEXTImpl__setNumber(_inInteger1, _inInteger2);
}
extern void BackendDAEEXT_initMarks(int _inInteger1, int _inInteger2)
{
  BackendDAEEXTImpl__initMarks(_inInteger1, _inInteger2);
}
extern void BackendDAEEXT_initLowLink(int _inInteger)
{
  BackendDAEEXTImpl__initLowLink(_inInteger);
}
extern void BackendDAEEXT_markDifferentiated(int _inInteger)
{
  BackendDAEEXTImpl__markDifferentiated(_inInteger);
}
extern void BackendDAEEXT_initNumber(int _inInteger)
{
  BackendDAEEXTImpl__initNumber(_inInteger);
}
extern void BackendDAEEXT_setLowLink(int _inInteger1, int _inInteger2)
{
  BackendDAEEXTImpl__setLowLink(_inInteger1, _inInteger2);
}
extern void BackendDAEEXT_vMark(int _inInteger)
{
  BackendDAEEXTImpl__vMark(_inInteger);
}

extern void BackendDAEEXT_setAdjacencyMatrix(modelica_integer nvars, modelica_integer neqns, modelica_integer nz, modelica_metatype adjacencymatrix)
{
  int i=0;
  mmc_sint_t i1;
  int j=0;
  modelica_integer nelts = MMC_HDRSLOTS(MMC_GETHDR(adjacencymatrix));

  if (col_ptrs) free(col_ptrs);
  col_ptrs = (int*) malloc((neqns+1) * sizeof(int));
  col_ptrs[neqns]=nz;
  if (col_ids) free(col_ids);
  col_ids = (int*) malloc(nz * sizeof(int));

  for(i=0; i<neqns; ++i) {
    modelica_metatype ie = MMC_STRUCTDATA(adjacencymatrix)[i];
    col_ptrs[i] = j;
    while(MMC_GETHDR(ie) == MMC_CONSHDR) {
      i1 = MMC_UNTAGFIXNUM(MMC_CAR(ie));
      if (i1>0) {
        col_ids[j++] = (int)i1-1;
      }
      ie = MMC_CDR(ie);
    }
  }
}

extern void BackendDAEEXT_matching(modelica_integer nv, modelica_integer ne, modelica_integer matchingID, modelica_integer cheapID, modelica_real relabel_period, modelica_integer clear_match)
{
  int i=0;
  BackendDAEExtImpl__matching(nv, ne, matchingID, cheapID, relabel_period, clear_match);
}

extern void BackendDAEEXT_getAssignment(modelica_metatype ass1, modelica_metatype ass2)
{
  int i=0;
  mmc_uint_t len1 = MMC_HDRSLOTS(MMC_GETHDR(ass1));
  mmc_uint_t len2 = MMC_HDRSLOTS(MMC_GETHDR(ass2));
  if (n > len1 || m > len2) {
    char nstr[64],mstr[64],len1str[64],len2str[64];
    const char *tokens[4] = {len2str,mstr,len1str,nstr};
    snprintf(nstr,64,"%ld", (long) n);
    snprintf(mstr,64,"%ld", (long) m);
    snprintf(len1str,64,"%ld", (long) len1);
    snprintf(len2str,64,"%ld", (long) len2);
    c_add_message(NULL,-1,ErrorType_symbolic,ErrorLevel_internal,"BackendDAEEXT.getAssignment failed because n=%s>arrayLength(ass1)=%s or m=%s>arrayLength(ass2)=%s",tokens,4);
    MMC_THROW();
  }
  if (match != NULL) {
    for(i=0; i<n; ++i) {
      if (match[i] >= 0)
        MMC_STRUCTDATA(ass1)[i] = mmc_mk_icon(match[i]+1);
      else
        MMC_STRUCTDATA(ass1)[i] = mmc_mk_icon(-1);
    }
  }
  if (row_match != NULL) {
    for(i=0; i<m; ++i) {
      if (row_match[i] >= 0)
        MMC_STRUCTDATA(ass2)[i] = mmc_mk_icon(row_match[i]+1);
      else
        MMC_STRUCTDATA(ass2)[i] = mmc_mk_icon(-1);
    }
  }
}

extern int BackendDAEEXT_setAssignment(int lenass1, int lenass2, modelica_metatype ass1, modelica_metatype ass2)
{
  int nelts=0;
  int i=0;

  nelts = MMC_HDRSLOTS(MMC_GETHDR(ass1));
  if (nelts > 0) {
    n = lenass1;
    if(match) {
      free(match);
    }
    match = (int*) malloc(n * sizeof(int));
    for(i=0; i<n; ++i) {
      match[i] = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(ass1)[i])-1;
      if (match[i]<0) match[i] = -1;
    }
  }
  nelts = MMC_HDRSLOTS(MMC_GETHDR(ass2));
  if (nelts > 0) {
    m = lenass2;
    if(row_match) {
      free(row_match);
    }
    row_match = (int*) malloc(m * sizeof(int));
    for(i=0; i<m; ++i) {
      row_match[i] = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(ass2)[i])-1;
      if (row_match[i]<0) row_match[i] = -1;
    }
  }
  return 1;
}

}
