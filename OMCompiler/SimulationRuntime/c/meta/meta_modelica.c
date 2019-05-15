/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#include "../openmodelica.h"
#include "meta_modelica.h"
#include "meta_modelica_builtin.h"
#include "../util/base_array.h"
#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

/*
void* mmc_mk_rcon(double d)
{
    void *p = mmc_alloc_words(MMC_SIZE_DBL/MMC_SIZE_INT+1);
    ((mmc_uint_t*)p)[0] = MMC_REALHDR;
    *((double*)((mmc_uint_t*)p+1)) = d;
    p = MMC_TAGPTR(p);
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "REAL size: %u\n", MMC_SIZE_DBL/MMC_SIZE_INT+1); fflush(NULL);
#endif
    return p;
}
*/
void* mmc_mk_rcon(double d)
{
    struct mmc_real *p = (struct mmc_real*)mmc_alloc_words_atomic(MMC_SIZE_DBL/MMC_SIZE_INT + 1);
    mmc_prim_set_real(p, d);
    p->header = MMC_REALHDR;
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "REAL size: %u\n", MMC_SIZE_DBL/MMC_SIZE_INT+1); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
}

void* mmc_mk_modelica_array(base_array_t arr)
{
  base_array_t *cpy = mmc_alloc_words(sizeof(arr)/sizeof(void*) + 1);
  memcpy(cpy, &arr, sizeof(base_array_t));
  clone_base_array_spec(&arr, cpy);
  /* Note: The data is hopefully not stack-allocated and can be passed this way */
  return cpy;
}

void* mmc_mk_box_arr(mmc_sint_t slots, mmc_uint_t ctor, void** args)
{
    mmc_sint_t i;
    struct mmc_struct *p = (struct mmc_struct*)mmc_alloc_words(slots + 1);
    p->header = MMC_STRUCTHDR(slots, ctor);
    for (i = 0; i < slots; i++) {
      p->data[i] = (void*) args[i];
    }
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "STRUCT slots%d ctor %u\n", slots, ctor); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
}

char* mmc_mk_scon_len_ret_ptr(size_t nbytes)
{
    mmc_uint_t header = MMC_STRINGHDR(nbytes);
    mmc_uint_t nwords = MMC_HDRSLOTS(header) + 1;
    struct mmc_string *p;
    void *res;
    p = (struct mmc_string *)mmc_alloc_words_atomic(nwords);
    p->header = header;
    res = MMC_TAGPTR(p);
    return MMC_STRINGDATA(res);
}

modelica_boolean valueEq(modelica_metatype lhs, modelica_metatype rhs)
{
  return 0==valueCompare(lhs, rhs);
}

static int intCompare(int i1, int i2)
{
  return i1==i2 ? 0 : i1>i2 ? 1 : -1;
}

static double realCompare(double r1, double r2)
{
  return r1==r2 ? 0 : r1>r2 ? 1 : -1;
}

modelica_integer valueCompare(modelica_metatype lhs, modelica_metatype rhs)
{
  mmc_uint_t h_lhs;
  mmc_uint_t h_rhs;
  mmc_sint_t numslots;
  mmc_uint_t ctor;
  mmc_sint_t i;
  int res;

  if (lhs == rhs) {
    return 0;
  }

  res = intCompare(MMC_IS_INTEGER(lhs), MMC_IS_INTEGER(rhs));
  if (0 != res) {
    /* Should trigger an assertion for most code */
    return res;
  }

  if (MMC_IS_INTEGER(lhs)) {
    return intCompare(mmc_unbox_integer(lhs), mmc_unbox_integer(rhs));
  }

  h_lhs = MMC_GETHDR(lhs);
  h_rhs = MMC_GETHDR(rhs);

  res = intCompare(h_lhs, h_rhs);

  if (0 != res) {
    return res;
  }

  if (h_lhs == MMC_NILHDR) {
    return 0;
  }

  if (h_lhs == MMC_REALHDR) {
    return realCompare(mmc_prim_get_real(lhs), mmc_prim_get_real(rhs));
  }

  if (MMC_HDRISSTRING(h_lhs)) {
    res = intCompare(MMC_STRLEN(lhs), MMC_STRLEN(rhs));
    return res==0 ? strcmp(MMC_STRINGDATA(lhs),MMC_STRINGDATA(rhs)) : res;
  }

  numslots = MMC_HDRSLOTS(h_lhs);
  ctor = 255 & (h_lhs >> 2);

  if (numslots>0 && ctor > 1) { /* RECORD */
    /* struct record_description * lhs_desc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(lhs),1));
    struct record_description * rhs_desc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(rhs),1));
    Slow; not needed
    if (0 != strcmp(lhs_desc->name,rhs_desc->name))
      return 0;
    */
    for (i = 2; i <= numslots; i++) {
      void * lhs_data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(lhs),i));
      void * rhs_data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(rhs),i));
      res = valueCompare(lhs_data,rhs_data);
      if (0 != res) {
        return res;
      }
    }
    return 0;
  }

  if (numslots>0 && ctor == 0) { /* TUPLE */
    for (i = 0; i < numslots; i++) {
      void *tlhs, *trhs;
      tlhs = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(lhs),i+1));
      trhs = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(rhs),i+1));
      res = valueCompare(tlhs,trhs);
      if (0 != res) {
        return res;
      }
    }
    return 0;
  }

  if (numslots==0 && ctor==1) /* NONE() */ {
    return 0;
  }

  if (numslots==1 && ctor==1) /* SOME(x) */ {
    return valueCompare(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(lhs),1)),MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(rhs),1)));
  }

  if (numslots==2 && ctor==1) { /* CONS-PAIR */
    while (!MMC_NILTEST(lhs) && !MMC_NILTEST(rhs)) {
      res = valueCompare(MMC_CAR(lhs),MMC_CAR(rhs));
      if (0 != res) {
        return res;
      }
      lhs = MMC_CDR(lhs);
      rhs = MMC_CDR(rhs);
    }
    return intCompare(MMC_NILTEST(lhs), MMC_NILTEST(rhs));
  }

  if (numslots==0 && ctor == MMC_ARRAY_TAG) /* zero size array??!! */ {
    return 0;
  }

  fprintf(stderr, "%s:%d: %ld slots; ctor %lu - FAILED to detect the type\n", __FILE__, __LINE__, (long) numslots, (unsigned long) ctor);
  EXIT(1);
}

void debug__print(void* prefix, void* any)
{
  fprintf(stderr, "%s%s", MMC_STRINGDATA(prefix), anyString(any));
}

static char *anyStringBuf = 0;
mmc_sint_t anyStringBufSize = 0;

inline static void checkAnyStringBufSize(mmc_sint_t ix, mmc_sint_t szNewObject)
{
  if (anyStringBufSize-ix < szNewObject+1) {
    anyStringBuf = realloc(anyStringBuf, anyStringBufSize*2 + szNewObject);
    assert(anyStringBuf != NULL);
    anyStringBufSize = anyStringBufSize*2 + szNewObject;
  }
}

void initializeStringBuffer(void)
{
  if (anyStringBufSize == 0) {
    anyStringBuf = malloc(8192);
    anyStringBufSize = 8192;
  }
  *anyStringBuf = '\0';
}

inline static mmc_sint_t anyStringWork(void* any, mmc_sint_t ix, modelica_metatype stack)
{
  mmc_uint_t hdr;
  mmc_sint_t numslots;
  mmc_uint_t ctor;
  mmc_sint_t i;
  void *data;
  /* char buf[34] = {0}; */

  if (MMC_IS_INTEGER(any)) {
    checkAnyStringBufSize(ix,40);
    ix += sprintf(anyStringBuf+ix, "%ld", (mmc_sint_t) MMC_UNTAGFIXNUM(any));
    return ix;
  }

  if (MMC_HDR_IS_FORWARD(MMC_GETHDR(any))) {
    checkAnyStringBufSize(ix,40);
    ix += sprintf(anyStringBuf+ix, "Forward");
    return ix;
  }

  hdr = MMC_HDR_UNMARK(MMC_GETHDR(any));

  if (hdr == MMC_NILHDR) {
    checkAnyStringBufSize(ix,2);
    ix += sprintf(anyStringBuf+ix, "{NIL}");
    return ix;
  }

  if (hdr == MMC_REALHDR) {
    checkAnyStringBufSize(ix,40);
    ix += sprintf(anyStringBuf+ix, "%.7g", (double) mmc_prim_get_real(any));
    return ix;
  }
  if (MMC_HDRISSTRING(hdr)) {
    MMC_CHECK_STRING(any);
    checkAnyStringBufSize(ix,strlen(MMC_STRINGDATA(any))+4);
    ix += sprintf(anyStringBuf+ix, "%s", MMC_STRINGDATA(any));
    return ix;
  }

  numslots = MMC_HDRSLOTS(hdr);
  ctor = MMC_HDRCTOR(hdr);

  /* Ugly hack to "detect" function pointers. If these parameters are outside
   * these bounds, then we probably have a function pointer. This is just to
   * keep the debugger from crashing. */
  if (numslots < 0 || numslots > 1024 || ctor > 255) {
    checkAnyStringBufSize(ix, 2);
    ix += sprintf(anyStringBuf+ix, "0");
    return ix;
  }

  if (numslots>0 && ctor == MMC_FREE_OBJECT_CTOR) { /* FREE OBJECT! */
    checkAnyStringBufSize(ix,100);
    ix += sprintf(anyStringBuf+ix, "FREE(%ld)", (long) numslots);
    return ix;
  }
  if (numslots>=0 && ctor == MMC_ARRAY_TAG) { /* MetaModelica-style array */
    checkAnyStringBufSize(ix,40);
    ix += sprintf(anyStringBuf+ix, "MetaArray(");
    for (i = 1; i <= numslots; i++) {
      data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),i));
      ix = anyStringWork(data, ix, mmc_mk_cons(data, stack));
      if (i!=numslots) {
        checkAnyStringBufSize(ix,3);
        ix += sprintf(anyStringBuf+ix, ", ");
      }
    }
    checkAnyStringBufSize(ix,2);
    ix += sprintf(anyStringBuf+ix, ")");
    return ix;
  }
  if (numslots>0 && ctor > 1) { /* RECORD */
    struct record_description * desc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),1));
    checkAnyStringBufSize(ix,strlen(desc->name)+2);
    ix += sprintf(anyStringBuf+ix, "%s(", desc->name);
    for (i = 2; i <= numslots; i++) {
      data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),i));
      checkAnyStringBufSize(ix,strlen(desc->fieldNames[i-2])+3);
      ix += sprintf(anyStringBuf+ix, "%s = ", desc->fieldNames[i-2]);
      ix = anyStringWork(data, ix, mmc_mk_cons(any, mmc_mk_cons(data, stack)));
      if (i!=numslots) {
        checkAnyStringBufSize(ix,3);
        ix += sprintf(anyStringBuf+ix, ", ");
      }
    }
    checkAnyStringBufSize(ix,2);
    ix += sprintf(anyStringBuf+ix, ")");
    return ix;
  }

  if (numslots > 0 && ctor == 0) { /* TUPLE */
    /* Pointers.mo, pointer are saved as tuples, check if we have it in the stack so we break the cycle */
    data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),1));
    if (listMember(data, stack))
    {
      checkAnyStringBufSize(ix,12);
      ix += sprintf(anyStringBuf+ix, "(Pointer())");
      return ix;
    }
    checkAnyStringBufSize(ix,2);
    ix += sprintf(anyStringBuf+ix, "(");
    for (i = 0; i < numslots; i++) {
      data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),i+1));
      ix = anyStringWork(data, ix, mmc_mk_cons(any, mmc_mk_cons(data, stack)));
      if (i != numslots-1) {
        checkAnyStringBufSize(ix,3);
        ix += sprintf(anyStringBuf+ix, ", ");
      }
    }
    checkAnyStringBufSize(ix,2);
    ix += sprintf(anyStringBuf+ix, ")");
    return ix;
  }

  if (numslots == 0 && ctor == 1) /* NONE() */ {
    checkAnyStringBufSize(ix,7);
    ix += sprintf(anyStringBuf+ix, "NONE()");
    return ix;
  }

  if (numslots==1 && ctor==1) /* SOME(x) */ {
    checkAnyStringBufSize(ix,6);
    ix += sprintf(anyStringBuf+ix, "SOME(");
    ix = anyStringWork(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any), 1)), ix, stack);
    checkAnyStringBufSize(ix,2);
    ix += sprintf(anyStringBuf+ix, ")");
    return ix;
  }

  if (numslots==2 && ctor==1) { /* CONS-PAIR */
    checkAnyStringBufSize(ix,2);
    ix += sprintf(anyStringBuf+ix, "{");
    ix = anyStringWork(MMC_CAR(any), ix, mmc_mk_cons(any, mmc_mk_cons(MMC_CAR(any), stack)));
    any = MMC_CDR(any);
    while (!MMC_NILTEST(any)) {
      checkAnyStringBufSize(ix,3);
      ix += sprintf(anyStringBuf+ix, ", ");
      ix = anyStringWork(MMC_CAR(any), ix, mmc_mk_cons(any, mmc_mk_cons(MMC_CAR(any), stack)));
      any = MMC_CDR(any);
    }
    checkAnyStringBufSize(ix,2);
    ix += sprintf(anyStringBuf+ix, "}");
    return ix;
  }

  fprintf(stderr, "%s:%d: %ld slots; ctor %lu - FAILED to detect the type\n", __FILE__, __LINE__, (long) numslots, (unsigned long) ctor);
  /* fprintf(stderr, "object: %032s||", ltoa((int)hdr, buf, 2)); */
  checkAnyStringBufSize(ix,5);
  ix += sprintf(anyStringBuf+ix, "UNK(");
  for (i=1; i<=numslots; i++)
  {
    data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),i));
    ix = anyStringWork(data, ix, mmc_mk_cons(any, mmc_mk_cons(data, stack)));
    /* fprintf(stderr, "%032s|", ltoa((int)data, buf, 2)); */
  }
  checkAnyStringBufSize(ix,2);
  ix += sprintf(anyStringBuf+ix, ")");
  fprintf(stderr, "\n"); fflush(NULL);
  /* EXIT(1); */
  return ix;
}

char* anyString(void* any)
{
  initializeStringBuffer();
  anyStringWork(any, 0, mmc_mk_nil());
  return anyStringBuf;
}

void* mmc_anyString(void* any)
{
  initializeStringBuffer();
  anyStringWork(any, 0, mmc_mk_nil());
  return mmc_mk_scon(anyStringBuf);
}

modelica_metatype mmc_gdb_listGet(threadData_t* threadData, modelica_metatype lst, modelica_integer i)
{
  return boxptr_listGet(threadData, lst, mmc_mk_icon(i));
}

modelica_metatype mmc_gdb_arrayGet(threadData_t* threadData, modelica_metatype arr, modelica_integer i)
{
  return boxptr_arrayGet(threadData, arr, mmc_mk_icon(i));
}

void printAny(void* any)
{
  initializeStringBuffer();
  anyStringWork(any, 0, mmc_mk_nil());
  fputs(anyStringBuf, stderr);
}

static int globalId;

inline static mmc_sint_t anyStringWorkCode(void* any, mmc_sint_t ix, mmc_sint_t id, modelica_metatype stack)
{
  mmc_uint_t hdr;
  mmc_sint_t numslots;
  mmc_uint_t ctor;
  int i;
  void *data;
  int base_id;
  /* char buf[34] = {0}; */

  if (MMC_IS_IMMEDIATE(any)) {
    checkAnyStringBufSize(ix,400);
    ix += sprintf(anyStringBuf+ix, "#define omc_tmp%ld ((void*)%" PRINT_MMC_SINT_T ")\n", (long) id, (mmc_sint_t) any);
    return ix;
  }

  if (MMC_HDR_IS_FORWARD(MMC_GETHDR(any))) {
    assert(0);
  }

  hdr = MMC_HDR_UNMARK(MMC_GETHDR(any));

  if (hdr == MMC_NILHDR) {
    checkAnyStringBufSize(ix,400);
    ix += sprintf(anyStringBuf+ix, "#define omc_tmp%ld (MMC_REFSTRUCTLIT(mmc_nil))\n", (long) id);
    return ix;
  }

  if (hdr == MMC_REALHDR) {
    checkAnyStringBufSize(ix,500);
    ix += sprintf(anyStringBuf+ix, "static const MMC_DEFREALLIT(omc_tmp%ld_data,%g);\n#define omc_tmp%ld MMC_REFREALLIT(omc_tmp%ld_data)\n", (long) id, (double) mmc_prim_get_real(any), (long) id, (long) id);
    return ix;
  }
  if (MMC_HDRISSTRING(hdr)) {
    int unescapedLength;
    char *str;
    MMC_CHECK_STRING(any);
    unescapedLength = strlen(MMC_STRINGDATA(any));
    str = omc__escapedString(MMC_STRINGDATA(any), 1);
    checkAnyStringBufSize(ix,unescapedLength+800);
    ix += sprintf(anyStringBuf+ix, "#define omc_tmp%ld_data \"%s\"\n", (long) id, str ? str : MMC_STRINGDATA(any));
    ix += sprintf(anyStringBuf+ix, "static const size_t omc_tmp%ld_strlen = %d;\n", (long) id, unescapedLength);
    ix += sprintf(anyStringBuf+ix, "static const MMC_DEFSTRINGLIT(omc_tmp%ld_data2,%d,omc_tmp%ld_data);\n", (long) id, unescapedLength, (long) id);
    ix += sprintf(anyStringBuf+ix, "#define omc_tmp%ld MMC_REFSTRINGLIT(omc_tmp%ld_data2)\n", (long) id, (long) id);
    if (str) free(str);
    return ix;
  }

  numslots = MMC_HDRSLOTS(hdr);
  ctor = MMC_HDRCTOR(hdr);

  /* Ugly hack to "detect" function pointers. If these parameters are outside
   * these bounds, then we probably have a function pointer. This is just to
   * keep the debugger from crashing. */
  if (numslots < 0 || numslots > 1024 || ctor > 255) {
    checkAnyStringBufSize(ix, 100);
    assert(0);
    return ix;
  }

  if (numslots>0 && ctor == MMC_FREE_OBJECT_CTOR) { /* FREE OBJECT! */
    assert(0);
    return ix;
  }
  if (numslots>=0 && ctor == MMC_ARRAY_TAG) { /* MetaModelica-style array */
    assert(0);
    return ix;
  }
  if (numslots>0 && ctor > 1) { /* RECORD */
    int base_id = globalId;
    struct record_description* desc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),1));
    globalId += numslots-1;
    for (i=2; i<=numslots; i++) {
      data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),i));
      ix = anyStringWorkCode(data, ix, base_id+i-1, stack);
    }
    checkAnyStringBufSize(ix,numslots*100+400);
    ix += sprintf(anyStringBuf+ix, "static const MMC_DEFSTRUCTLIT(omc_tmp%ld_data,%ld,%lu) {&%s__desc", (long) id, (long) numslots, (unsigned long) ctor, desc->path);
    for (i=2; i<=numslots; i++) {
      ix += sprintf(anyStringBuf+ix, ",omc_tmp%d", base_id+i-1);
    }
    ix += sprintf(anyStringBuf+ix, "}};\n");
    ix += sprintf(anyStringBuf+ix, "#define omc_tmp%ld MMC_REFSTRUCTLIT(omc_tmp%ld_data)\n", (long) id, (long) id);
    return ix;
  }

  base_id = globalId;
  globalId += numslots;
  for (i=1; i<=numslots; i++) {
    data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),i));
    ix = anyStringWorkCode(data, ix, base_id+i, stack);
  }
  checkAnyStringBufSize(ix,numslots*100+400);
  ix += sprintf(anyStringBuf+ix, "static const MMC_DEFSTRUCTLIT(omc_tmp%ld_data,%ld,%lu) {", (long) id, (long) numslots, (unsigned long) ctor);
  for (i=1; i<=numslots; i++) {
    ix += sprintf(anyStringBuf+ix, "%somc_tmp%d", i==1 ? "" : ",", base_id+i);
  }
  ix += sprintf(anyStringBuf+ix, "}};\n");
  ix += sprintf(anyStringBuf+ix, "#define omc_tmp%ld MMC_REFSTRUCTLIT(omc_tmp%ld_data)\n", (long) id, (long) id);
  return ix;
}

void* mmc_anyStringCode(void* any)
{
  initializeStringBuffer();
  globalId = 0;
  anyStringWorkCode(any, 0, globalId++, mmc_mk_nil());
  return mmc_mk_scon(anyStringBuf);
}

const char* anyStringCode(void* any)
{
  initializeStringBuffer();
  globalId = 0;
  anyStringWorkCode(any, 0, globalId++, mmc_mk_nil());
  fprintf(stderr, "%s", anyStringBuf);
  return anyStringBuf;
}

void printTypeOfAny(void* any) /* for debugging */
{
  mmc_uint_t hdr;
  int numslots;
  unsigned int ctor;
  void *data;

  if (MMC_IS_INTEGER(any)) {
    fprintf(stderr, "Integer");
    return;
  }

  hdr = MMC_GETHDR(any);

  if (MMC_HDR_IS_FORWARD(hdr)) {
    fprintf(stderr, "Forward");
    return;
  }

  if (hdr == MMC_NILHDR) {
    fprintf(stderr, "list<Any>");
    return;
  }

  if (hdr == MMC_REALHDR) {
    fprintf(stderr, "Real");
    return;
  }

  if (MMC_HDRISSTRING(hdr)) {
    fprintf(stderr, "String");
    return;
  }

  numslots = MMC_HDRSLOTS(hdr);
  ctor = 255 & (hdr >> 2);

  if (numslots>0 && ctor == MMC_ARRAY_TAG) { /* MetaModelica-style array */
    fprintf(stderr, "meta_array<");
    data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),1));
    printTypeOfAny(data);
    fprintf(stderr, ">");
    return;
  }
  /* empty array??!! */
  if (numslots == 0 && ctor == MMC_ARRAY_TAG) { /* MetaModelica-style array */
    fprintf(stderr, "meta_array<>");
    return;
  }

  if (numslots>0 && ctor > 1) { /* RECORD */
    int i;
    struct record_description * desc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),1));
    fprintf(stderr, "%s(", desc->name);
    for (i=2; i<=numslots; i++) {
      data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),i));
      fprintf(stderr, "%s = ", desc->fieldNames[i-2]);
      printTypeOfAny(data);
      if (i!=numslots)
        fprintf(stderr, ", ");
    }
    fprintf(stderr, ")");
    return;
  }

  if (numslots>0 && ctor == 0) { /* TUPLE */
    fprintf(stderr, "tuple<");
    printTypeOfAny(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),1)));
    fprintf(stderr, ">");
    return;
  }

  if (numslots==0 && ctor==1) /* NONE() */ {
    fprintf(stderr, "Option<Any>");
    return;
  }

  if (numslots==1 && ctor==1) /* SOME(x) */ {
    fprintf(stderr, "Option<");
    printTypeOfAny(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),1)));
    fprintf(stderr, ">");
    return;
  }

  if (numslots==2 && ctor==1) { /* CONS-PAIR */
    fprintf(stderr, "list<");
    printTypeOfAny(MMC_CAR(any));
    fprintf(stderr, ">");
    return;
  }

  fprintf(stderr, "%s:%d: %d slots; ctor %u - FAILED to detect the type\n", __FILE__, __LINE__, numslots, ctor);
  EXIT(1);
}

inline static int getTypeOfAnyWork(void* any, int ix, int inRecord, modelica_metatype stack)  /* for debugging */
{
  mmc_uint_t hdr;
  int numslots;
  unsigned int ctor;
  int i;

  if (any == NULL && !inRecord) {  // To handle integer inside Record.
    checkAnyStringBufSize(ix,21);
    ix += sprintf(anyStringBuf+ix, "%s", "replaceable type Any");
    return ix;
  }

  if (MMC_IS_INTEGER(any)) {
    checkAnyStringBufSize(ix,8);
    ix += sprintf(anyStringBuf+ix, "%s", "Integer");
    return ix;
  }

  hdr = MMC_GETHDR(any);

  if (hdr == MMC_NILHDR) {
    checkAnyStringBufSize(ix,10);
    ix += sprintf(anyStringBuf+ix, "%s", "list<Any>");
    return ix;
  }

  if (hdr == MMC_REALHDR) {
    checkAnyStringBufSize(ix,5);
    ix += sprintf(anyStringBuf+ix, "%s", "Real");
    return ix;
  }

  if (MMC_HDRISSTRING(hdr)) {
    checkAnyStringBufSize(ix,7);
    ix += sprintf(anyStringBuf+ix, "%s", "String");
    return ix;
  }

  numslots = MMC_HDRSLOTS(hdr);
  ctor = 255 & (hdr >> 2);

  /* Ugly hack to "detect" function pointers. If these parameters are outside
   * these bounds, then we probably have a function pointer. This is just to
   * keep the debugger from crashing. */
  if (numslots < 0 || numslots > 1024 || ctor > 255) {
    checkAnyStringBufSize(ix, 8);
    ix += sprintf(anyStringBuf+ix, "%s", "Integer");
    return ix;
  }

  if (numslots>0 && ctor == MMC_ARRAY_TAG) {
    checkAnyStringBufSize(ix,7);
    ix += sprintf(anyStringBuf+ix, "Array<");
    ix = getTypeOfAnyWork(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),1)), ix, inRecord, stack);
    checkAnyStringBufSize(ix,2);
    ix += sprintf(anyStringBuf+ix, ">");
    return ix;
  }

  if (numslots>0 && ctor > 1) { /* RECORD */
    struct record_description * desc = MMC_CAR(any);
    checkAnyStringBufSize(ix,strlen(desc->name)+8);
    ix += sprintf(anyStringBuf+ix, "record<%s>", desc->name);
    return ix;
  }

  if (numslots>0 && ctor == 0) { /* TUPLE */
    checkAnyStringBufSize(ix,7);
    ix += sprintf(anyStringBuf+ix, "tuple<");
    for (i=0; i<numslots; i++) {
      ix = getTypeOfAnyWork(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),i+1)), ix, inRecord, stack);
      if (i!=numslots-1) {
        checkAnyStringBufSize(ix,3);
        ix += sprintf(anyStringBuf+ix, ", ");
      }
    }
    checkAnyStringBufSize(ix,2);
    ix += sprintf(anyStringBuf+ix, ">");
    return ix;
  }

  if (numslots==0 && ctor==1) /* NONE() */ {
    checkAnyStringBufSize(ix,12);
    ix += sprintf(anyStringBuf+ix, "Option<Any>");
    return ix;
  }

  if (numslots==1 && ctor==1) /* SOME(x) */ {
    checkAnyStringBufSize(ix,8);
    ix += sprintf(anyStringBuf+ix, "Option<");
    for (i=0; i<numslots; i++) {
      ix = getTypeOfAnyWork(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),i+1)), ix, inRecord, stack);
      if (i!=numslots-1) {
        checkAnyStringBufSize(ix,3);
        ix += sprintf(anyStringBuf+ix, ", ");
      }
    }
    checkAnyStringBufSize(ix,2);
    ix += sprintf(anyStringBuf+ix, ">");
    return ix;
  }

  if (numslots==2 && ctor==1) { /* CONS-PAIR */
    checkAnyStringBufSize(ix,6);
    ix += sprintf(anyStringBuf+ix, "list<");
    ix = getTypeOfAnyWork(MMC_CAR(any), ix, inRecord, stack);
    checkAnyStringBufSize(ix,2);
    ix += sprintf(anyStringBuf+ix, ">");
    return ix;
  }

  ix = sprintf(anyStringBuf+ix, "%s:%d: %d slots; ctor %u - FAILED to detect the type\n", __FILE__, __LINE__, numslots, ctor);
  return ix;
}

char* getTypeOfAny(void* any, int inRecord) /* for debugging */
{
  initializeStringBuffer();
  getTypeOfAnyWork(any,0, inRecord, mmc_mk_nil());
  return anyStringBuf;
}

/*
 * Used by MDT for debugging.
 * Returns the name of the particular field of the Record.
 * */
char* getRecordElementName(void* any, int element) {
  struct record_description *desc;

  initializeStringBuffer();

  desc = MMC_CAR(any);
  checkAnyStringBufSize(0,strlen(desc->fieldNames[element]));
  sprintf(anyStringBuf, "%s", desc->fieldNames[element]);
  return anyStringBuf;
}

/*
 * Used by MDT for debugging just return whether Option type contain something or not.
 * */
int isOptionNone(void* any)
{
  return MMC_OPTIONNONE(any);
}

/*
 * The gdb often use the buffer based stdout.
 * So printf does not print straight away on the console.
 * changing it to NULL fix the problem.
 * */
void changeStdStreamBuffer(void) {
  setbuf(stdout, NULL);
  setbuf(stderr, NULL);
}

modelica_integer mmc_gdb_arrayLength(modelica_metatype arr)
{
  return MMC_HDRSLOTS(MMC_GETHDR(arr));
}

/*
 * Used by OMEdit for debugging.
 * Returns the metatype element as an array e.g ^done,omc_element={name, displayName, type}
 */
char* getMetaTypeElement(modelica_metatype arr, modelica_integer i, metaType mt) {
  void *name;
  char *displayName = NULL, *ty = NULL, *formatString = NULL;
  const char *formattedString = NULL;
  int n, n1;

  /* get the pointer to the element from the array/list */
  switch (mt) {
    case record_metaType:
    case option_metaType:
    case tuple_metaType:
    case array_metaType:
      name = (void*)mmc_gdb_arrayGet(0, arr, i);
      break;
    case list_metaType:
      name = (void*)mmc_gdb_listGet(0, arr, i);
      break;
    default:    /* should never be reached */
      return "Unknown meta type";
  }

  /* get the name of the element */
  if (mt == record_metaType) {
    getRecordElementName(arr, i - 2);
    displayName = malloc(strlen(anyStringBuf) + 1);
    strcpy(displayName, anyStringBuf);
  }

  /* get the type of the element */
  if (mt == record_metaType) {
    getTypeOfAny(name, 1);
  } else {
    getTypeOfAny(name, 0);
  }
  ty = malloc(strlen(anyStringBuf) + 1);
  strcpy(ty, anyStringBuf);
  /* format the anyStringBuf as array to return it */
  /* if Integer then unbox the pointer */
  if (strcmp(ty, "Integer") == 0) {
    name = (char*)anyString(name);
    formatString = "^done,omc_element={name=\"%s\",displayName=\"%s\",type=\"%s\"}";
    if (-1 == GC_asprintf(&formattedString, formatString, name, displayName, ty)) {
      assert(0);
    }
  } else if (mt == record_metaType) {
    formatString = "^done,omc_element={name=\"%ld\",displayName=\"%s\",type=\"%s\"}";
    if (-1 == GC_asprintf(&formattedString, formatString, (mmc_uint_t)name, displayName, ty)) {
      assert(0);
    }
  } else {
    formatString = "^done,omc_element={name=\"%ld\",displayName=\"[%d]\",type=\"%s\"}";
    if (-1 == GC_asprintf(&formattedString, formatString, (mmc_uint_t)name, (int)i, ty)) {
      assert(0);
    }
  }
  n1 = strlen(formattedString) + 1;
  n = snprintf(anyStringBuf, n1, "%s", formattedString);
  if (n > n1) {
    checkAnyStringBufSize(0, n1);
    snprintf(anyStringBuf, n1, "%s", formattedString);
  }

  /* free the memory */
  if (mt == record_metaType) {
    free(displayName);
  }
  free(ty);

  return anyStringBuf;
}

static inline mmc_uint_t djb2_hash_iter(const unsigned char *str /* data; not null-terminated */, int len, mmc_uint_t hash /* start at 5381 */)
{
  int i;
  for (i=0; i<len; i++) {
    hash = ((hash << 5) + hash) + str[i]; /* hash * 33 + c */
  }
  return hash;
}

mmc_uint_t mmc_prim_hash(void *p, mmc_uint_t hash /* start at 5381 */)
{
  mmc_uint_t phdr = 0;

  mmc_prim_hash_tail_recur:
  if (MMC_IS_INTEGER(p))
  {
    mmc_uint_t l = (mmc_uint_t)MMC_UNTAGFIXNUM(p);
    return djb2_hash_iter((unsigned char*)&l, sizeof(mmc_uint_t), hash);
  }

  phdr = MMC_GETHDR(p);

  if( phdr == MMC_REALHDR )
  {
    double d = mmc_unbox_real(p);
    return djb2_hash_iter((unsigned char*)&d, sizeof(double), hash);
  }

  if( MMC_HDRISSTRING(phdr) )
  {
    return djb2_hash_iter((const unsigned char *) MMC_STRINGDATA(p),MMC_STRLEN(p),hash);
  }

  if( MMC_HDRISSTRUCT(phdr) )
  {
    int i;
    int slots = MMC_HDRSLOTS(phdr);
    int ctor = MMC_HDRCTOR(phdr);
    hash = djb2_hash_iter((unsigned char*)&ctor, sizeof(int), hash);
    if (slots == 0)
      return hash;

    for (i=2; i<slots; i++) {
      hash = mmc_prim_hash(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(p),i)),hash);
    }
    p = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(p),slots));
    goto mmc_prim_hash_tail_recur;
  }
  return hash;
}

modelica_integer valueHashMod(void *p, modelica_integer mod)
{
  modelica_integer res = mmc_prim_hash(p,5381) % (mmc_uint_t) mod;
  return res;
}

void* boxptr_valueHashMod(threadData_t *threadData,void *p, void *mod)
{
  return mmc_mk_icon(mmc_prim_hash(p,5381) % (mmc_uint_t) mmc_unbox_integer(mod));
}
