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
 * RCS: $Id$
 *
 */

#include "meta_modelica.h"
#include "rml_compatibility.h"
#include "BackendDAEEXT.cpp"
#include <stdlib.h>

extern "C" {
#include "matchmaker.h"
}

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

unsigned int n=0;
unsigned int m=0;
int* match=NULL;
int* row_match=NULL;
int* col_ptrs=NULL;
int* col_ids=NULL;

extern void BackendDAEEXT_setIncidenceMatrix(modelica_integer nvars, modelica_integer neqns, modelica_integer nz, modelica_metatype incidencematrix)
{
  int i=0;
  long int i1;
  int j=0;
  modelica_integer nelts = MMC_HDRSLOTS(MMC_GETHDR(incidencematrix));

  if (col_ptrs) free(col_ptrs);
  col_ptrs = (int*) malloc((neqns+1) * sizeof(int));
  col_ptrs[neqns]=nz;
  if (col_ids) free(col_ids);
  col_ids = (int*) malloc(nz * sizeof(int));

  for(i=0; i<neqns; ++i) {
    modelica_metatype ie = MMC_STRUCTDATA(incidencematrix)[i];
    col_ptrs[i] = j;
    while(MMC_GETHDR(ie) == MMC_CONSHDR) {
      i1 = MMC_UNTAGFIXNUM(MMC_CAR(ie));
      if (i1>=0) {
        col_ids[j++] = i1-1;
      }
      ie = MMC_CDR(ie);
    }
  }
}

extern void BackendDAEEXT_matching(modelica_integer nv, modelica_integer ne, modelica_integer matchingID, modelica_integer cheapID, modelica_real relabel_period, modelica_integer clear_match)
{
  int i=0;
  if (clear_match==0){
    if (ne>n) {
      int* tmp = (int*) malloc(ne * sizeof(int));
      if(match)
      {
        memcpy(tmp,match,n*sizeof(int));
        free(match);
        match = tmp;
    for (i = n; i < ne; i++) {
      match[i] = -1;
    }
      }
      else {
         match = (int*) malloc(ne * sizeof(int));
         memset(match,-1,ne * sizeof(int));
      }
      n = ne;
    }
    if (nv>m) {
      int* tmp = (int*) malloc(nv * sizeof(int));
      if(row_match)
      {
        memcpy(tmp,row_match,m*sizeof(int));
        free(row_match);
        row_match = tmp;
    for (i = m; i < nv; i++) {
      row_match[i] = -1;
    }
      }
      else {
        row_match = (int*) malloc(nv * sizeof(int));
        memset(row_match,-1,nv * sizeof(int));
      }
      m = nv;
    }
  }
  else {
  if (ne>n) {
      if (match) free(match);
      match = (int*) malloc(ne * sizeof(int));
      memset(match,-1,ne * sizeof(int));
  } else {
      memset(match,-1,n * sizeof(int));
  }
    n = ne;
    if (nv>m) {
      if (row_match) free(row_match);
      row_match = (int*) malloc(nv * sizeof(int));
      memset(row_match,-1,nv * sizeof(int));
    } else {
      memset(row_match,-1,m * sizeof(int));
    }
    m = nv;
  }
  if ((match != NULL) && (row_match != NULL)) {
    matching(col_ptrs,col_ids,match,row_match,nv,ne,matchingID,cheapID,relabel_period,clear_match);
  }
}

extern void* BackendDAEEXT_getEqnsforIndexReduction()
{
  int i=0;
  int *eqns = (int*) malloc((n+1) * sizeof(int));
  int eqns_size=0;
  void *res = mk_nil();
  if ((match != NULL) && (row_match != NULL) && (eqns != NULL)) {
    eqns_size = getEqnsForIndexReduction(col_ptrs,col_ids,match,row_match,n,m,eqns);
  }
  for (i = 0; i < eqns_size; i++) {
    res = mk_cons(mk_icon(eqns[i]+1),res);
  }
  free(eqns);
  return res;
}

extern void BackendDAEEXT_getAssignment(modelica_metatype ass1, modelica_metatype ass2)
{
  int i=0;
  if (match != NULL) {
    for(i=0; i<n; ++i) {
      if (match[i] >= 0)
        MMC_STRUCTDATA(ass1)[i] = mk_icon(match[i]+1);
      else
        MMC_STRUCTDATA(ass1)[i] = mk_icon(-1);
    }
  }
  if (row_match != NULL) {
    for(i=0; i<m; ++i) {
      if (row_match[i] >= 0)
        MMC_STRUCTDATA(ass2)[i] = mk_icon(row_match[i]+1);
      else
        MMC_STRUCTDATA(ass2)[i] = mk_icon(-1);
    }
  }
}

extern int BackendDAEEXT_setAssignment(int lenass1, int lenass2, modelica_metatype ass1, modelica_metatype ass2)
{
  int nelts=0;
  int i=0;

  nelts = MMC_HDRSLOTS(MMC_GETHDR(ass1));
  if (lenass1 > nelts)
    return 0;
  if (nelts > 0) {
    n = lenass1;
    if(match) {
      free(match);
    }
    match = (int*) malloc(n * sizeof(int));
    memset(match,-1,n * sizeof(int));
    for(i=0; i<n; ++i) {
      match[i] = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(ass1)[i])-1;
      if (match[i]<0) match[i] = -1;
    }
  }
  nelts = MMC_HDRSLOTS(MMC_GETHDR(ass2));
  if (lenass2 > nelts)
    return 0;
  if (nelts > 0) {
    m = lenass2;
    if(row_match) {
      free(row_match);
    }
    row_match = (int*) malloc(m * sizeof(int));
    memset(row_match,-1,m * sizeof(int));
    for(i=0; i<m; ++i) {
      row_match[i] = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(ass2)[i])-1;
      if (row_match[i]<0) row_match[i] = -1;
    }
  }
  return 1;
}

}
