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
  freePieces();
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

extern void BackendDAEEXT_setAdjacencyMatrixFlat(modelica_integer nvars, modelica_integer neqns, modelica_integer nz, modelica_metatype start, modelica_metatype len, modelica_metatype data)
{
  freePieces();
  int i, j=0, k, first, n;

  if (col_ptrs) free(col_ptrs);
  col_ptrs = (int*) malloc((neqns+1) * sizeof(int));
  col_ptrs[neqns]=nz;
  if (col_ids) free(col_ids);
  col_ids = (int*) malloc(nz * sizeof(int));

  for(i=0; i<neqns; ++i) {
    first = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(start)[i]);
    n = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(len)[i]);
    col_ptrs[i] = j;
    for(k=first; k<first+n; ++k) {
      mmc_sint_t i1 = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(data)[k-1]);
      if (i1>0) {
        col_ids[j++] = (int)i1-1;
      }
    }
  }
}

extern void BackendDAEEXT_setAdjacencyMatrixPieces(modelica_integer nvars, modelica_integer neqns, modelica_metatype first, modelica_metatype count, modelica_metatype pstart, modelica_metatype plen, modelica_metatype data)
{
  /* rows are lists of pieces, every piece a range of data (all 1-based). A range
   * used by several pieces is copied once, without its non-positive entries. */
  int i, p, k, e, ps, pl, nids = 0, npieces = 0, cstart, clen;
  modelica_integer ndata = MMC_HDRSLOTS(MMC_GETHDR(data));
  int* target = (int*) malloc((ndata + 1) * sizeof(int));
  int* tlen = (int*) malloc((ndata + 1) * sizeof(int));
  int* srclen = (int*) malloc((ndata + 1) * sizeof(int));

  freePieces();
  if (col_ptrs) {free(col_ptrs); col_ptrs = NULL;}
  if (col_ids) {free(col_ids); col_ids = NULL;}

  for(k=0; k<=ndata; ++k) {target[k] = -1;}
  for(i=0; i<neqns; ++i) {npieces += MMC_UNTAGFIXNUM(MMC_STRUCTDATA(count)[i]);}

  pieces.row_first = (int*) malloc((neqns + 1) * sizeof(int));
  pieces.row_count = (int*) malloc((neqns + 1) * sizeof(int));
  pieces.piece_start = (int*) malloc((npieces + 1) * sizeof(int));
  pieces.piece_len = (int*) malloc((npieces + 1) * sizeof(int));
  pieces.ids = (int*) malloc((ndata + 1) * sizeof(int));

  npieces = 0;
  for(i=0; i<neqns; ++i) {
    p = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(first)[i]);
    e = p + MMC_UNTAGFIXNUM(MMC_STRUCTDATA(count)[i]);
    pieces.row_first[i] = npieces;
    for(; p<e; ++p) {
      ps = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(pstart)[p-1]);
      pl = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(plen)[p-1]);
      if (target[ps] >= 0 && srclen[ps] == pl) {
        cstart = target[ps];
        clen = tlen[ps];
      } else {
        cstart = nids;
        for(k=ps; k<ps+pl; ++k) {
          mmc_sint_t i1 = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(data)[k-1]);
          if (i1>0) {
            pieces.ids[nids++] = (int)i1-1;
          }
        }
        clen = nids - cstart;
        if (target[ps] < 0) {
          target[ps] = cstart; tlen[ps] = clen; srclen[ps] = pl;
        }
      }
      if (clen > 0) {
        pieces.piece_start[npieces] = cstart;
        pieces.piece_len[npieces] = clen;
        npieces++;
      }
    }
    pieces.row_count[i] = npieces - pieces.row_first[i];
  }
  use_pieces = 1;

  free(srclen);
  free(tlen);
  free(target);
}

extern void BackendDAEEXT_matching(modelica_integer nv, modelica_integer ne, modelica_integer matchingID, modelica_integer cheapID, modelica_real relabel_period, modelica_integer clear_match)
{
  int i=0;
  BackendDAEExtImpl__matching(nv, ne, matchingID, cheapID, relabel_period, clear_match);
}

static void backendFailBecauseLength(const char *function, const char *var1str, long len1, const char *var2str, long len2)
{
  char len1str[64],len2str[64];
  const char *tokens[5] = {var2str,len2str,len1str,var1str,function};
  snprintf(len1str,64,"%ld", (long) len1);
  snprintf(len2str,64,"%ld", (long) len2);
  c_add_message(NULL,-1,ErrorType_symbolic,ErrorLevel_internal,"%s failed because %s=%s>%s=%s",tokens,5);
}

extern void BackendDAEEXT_getAssignment(modelica_metatype ass1, modelica_metatype ass2)
{
  int i=0;
  mmc_uint_t len1 = MMC_HDRSLOTS(MMC_GETHDR(ass1));
  mmc_uint_t len2 = MMC_HDRSLOTS(MMC_GETHDR(ass2));
  if (n > len1) {
    backendFailBecauseLength("BackendDAEEXT.getAssignment", "n", n, "arrayLength(ass1)", len1);
    MMC_THROW();
  }
  if (m > len2) {
    backendFailBecauseLength("BackendDAEEXT.getAssignment", "m", m, "arrayLength(ass2)", len2);
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
    if (n > nelts) {
      backendFailBecauseLength("BackendDAEEXT.setAssignment", "n", n, "arrayLength(ass1)", nelts);
      return 0;
    }
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
    if (m > nelts) {
      backendFailBecauseLength("BackendDAEEXT.setAssignment", "m", m, "arrayLength(ass2)", nelts);
      return 0;
    }
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
