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

#include "meta_modelica_builtin.h"
#include "meta_modelica.h"
#include <float.h>
#include <limits.h>
#include <assert.h>
#include <time.h>
#include <math.h>
#include <string.h>
#include <stdio.h>

#define GEN_META_MODELICA_BUILTIN_BOXPTR
#include "meta_modelica_builtin_boxptr.h"

metamodelica_string intString(modelica_integer i)
{
  /* 64-bit integer: 1+log_10(2**63)+1 = 20 digits max */
  char buffer[22];
  void *res;
  if (i>=0 && i<=9) /* Small integers are used so much it makes sense to cache them */
    return mmc_strings_len1['0'+i];
  sprintf(buffer, "%ld", (long) i);
  res = mmc_mk_scon(buffer);
  MMC_CHECK_STRING(res);
  return res;
}

/* String Character Conversion */

modelica_integer nobox_stringCharInt(threadData_t *threadData,metamodelica_string chr)
{
  unsigned char c;
  if (MMC_STRLEN(chr) != 1)
    MMC_THROW_INTERNAL();
  MMC_CHECK_STRING(chr);
  return (unsigned char) MMC_STRINGDATA(chr)[0];
}

metamodelica_string nobox_intStringChar(threadData_t *threadData,modelica_integer ix)
{
  char chr[2];
  if (ix < 1 || ix > 255)
    MMC_THROW_INTERNAL();
  chr[0] = (char) ix;
  chr[1] = '\0';
  return mmc_mk_scon(chr);
}

/* String Operations */

modelica_integer nobox_stringInt(threadData_t *threadData,metamodelica_string s)
{
  long res;
  char *endptr,*str=MMC_STRINGDATA(s);
  MMC_CHECK_STRING(s);
  errno = 0;
  res = strtol(str,&endptr,10);
  if (errno != 0 || str == endptr)
    MMC_THROW_INTERNAL();
  if (*endptr != '\0')
    MMC_THROW_INTERNAL();
  if (res > INT_MAX || res < INT_MIN)
    MMC_THROW_INTERNAL();
  return res;
}

modelica_real nobox_stringReal(threadData_t *threadData,metamodelica_string s)
{
  modelica_real res;
  char *endptr,*str=MMC_STRINGDATA(s);
  MMC_CHECK_STRING(s);
  errno = 0;
  res = strtod(str,&endptr);
  if (errno != 0 || str == endptr)
    MMC_THROW_INTERNAL();
  if (*endptr != '\0')
    MMC_THROW_INTERNAL();
  return res;
}

/******************** String HASH Functions ********************/
/*
 * adrpo 2008-12-02
 * http://www.cse.yorku.ca/~oz/hash.html
 * hash functions which could be useful to replace System__hash:
 */
/*** djb2 hash ***/
static inline unsigned long djb2_hash(const unsigned char *str)
{
  unsigned long hash = 5381;
  int c;
  while (0 != (c = *str++))  hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
  return hash;
}

/*** sdbm hash ***/
static inline unsigned long sdbm_hash(const unsigned char* str)
{
  unsigned long hash = 0;
  int c;
  while (0 != (c = *str++)) hash = c + (hash << 6) + (hash << 16) - hash;
  return hash;
}

/* adrpo: really bad hash :) */
modelica_integer stringHash(metamodelica_string_const s)
{
  const char* str = MMC_STRINGDATA(s);
  long res = 0, i=0;
  while (0 != (str[i])) { res += str[i]; i++; }
  return res;
}

/* adrpo: see the comment above about djb2 hash */
modelica_integer stringHashDjb2(metamodelica_string_const s)
{
  const char* str = MMC_STRINGDATA(s);
  long res = djb2_hash((const unsigned char*)str);
  res = labs(res);
  /* fprintf(stderr, "stringHashDjb2 %s-> %ld %ld %ld\n", str, res, mmc_mk_icon(res), mmc_unbox_integer(mmc_mk_icon(res))); */
  return res;
}

/* adrpo: see the comment above about djb2 hash */
modelica_integer stringHashDjb2Mod(metamodelica_string_const s, modelica_integer mod)
{
  const char* str = MMC_STRINGDATA(s);
  long res;
  if (mod == 0) {
    MMC_THROW();
  }
  res = djb2_hash((const unsigned char*)str) % (unsigned int) mod;
  res = labs(res);
  /* fprintf(stderr, "stringHashDjb2Mod %s %ld-> %ld %ld %ld\n", str, mod, res, mmc_mk_icon(res), mmc_unbox_integer(mmc_mk_icon(res))); */
  return res;
}

modelica_metatype boxptr_stringHashDjb2Mod(threadData_t *threadData,modelica_metatype v,modelica_metatype mod)
{
  modelica_integer modunbox = mmc_unbox_integer(mod);
  if (modunbox < 1) {
    MMC_THROW_INTERNAL();
  }
  return mmc_mk_icon(stringHashDjb2Mod(v,modunbox));
}

/* adrpo: see the comment above about sdbm hash */
modelica_integer stringHashSdbm(metamodelica_string_const s)
{
  const char* str = MMC_STRINGDATA(s);
  long res = sdbm_hash((const unsigned char*)str);
  return res;
}

modelica_metatype boxptr_substring(threadData_t *threadData, metamodelica_string_const str, modelica_metatype boxstart, modelica_metatype boxstop)
{
  unsigned header = 0, nwords;
  long start = MMC_UNTAGFIXNUM(boxstart) - 1;
  long stop = MMC_UNTAGFIXNUM(boxstop) - 1;
  long totalLen = MMC_STRLEN(str), len = stop-start+1;
  struct mmc_string *res;
  char *tmp;
  modelica_metatype p;
  /* Bad indexes */
  if (start < 0 || start >= totalLen || stop < start || stop >= totalLen) {
    MMC_THROW_INTERNAL();
  }
  header = MMC_STRINGHDR(len);
  nwords = MMC_HDRSLOTS(header) + 1;
  res = (struct mmc_string *) mmc_alloc_words_atomic(nwords);
  res->header = header;
  tmp = (char*) res->data;
  memcpy(tmp, MMC_STRINGDATA(str) + start, len);
  tmp[len] = '\0';
  p = MMC_TAGPTR(res);
  MMC_CHECK_STRING(p);
  return p;
}

metamodelica_string stringListStringChar(metamodelica_string s)
{
  const char *str = MMC_STRINGDATA(s);
  char chr[2] = {'\0', '\0'};
  modelica_metatype res = NULL;
  int i = 0;

  MMC_CHECK_STRING(s);
  res = mmc_mk_nil();
  for (i=MMC_STRLEN(s)-1; i>=0; i--) {
    chr[0] = str[i];
    res = mmc_mk_cons(mmc_mk_scon(chr), res);
  }
  return res;
}

metamodelica_string stringAppendList(modelica_metatype lst)
{
  /* fprintf(stderr, "stringAppendList(%s)\n", anyString(lst)); */
  modelica_integer lstLen = 0, len = 0;
  unsigned nbytes = 0, header = 0, nwords = 0;
  modelica_metatype car = NULL, lstHead = NULL, lstTmp = NULL;
  char *tmp = NULL;
  struct mmc_string *res = NULL;
  void *p = NULL;

  lstLen = 0;
  nbytes = 0;
  lstHead = lst;
  lstTmp = lst;
  while (!listEmpty(lstTmp)) {
    MMC_CHECK_STRING(MMC_CAR(lstTmp));
    nbytes += MMC_STRLEN(MMC_CAR(lstTmp));
    /* fprintf(stderr, "stringAppendList: Has success reading input %d: %s\n", lstLen, MMC_STRINGDATA(MMC_CAR(lst))); */
    lstTmp = MMC_CDR(lstTmp);
    lstLen++;
  }
  if (nbytes == 0) return mmc_emptystring;
  if (lstLen == 1) return MMC_CAR(lstHead);

  header = MMC_STRINGHDR(nbytes);
  nwords = MMC_HDRSLOTS(header) + 1;
  res = (struct mmc_string *) mmc_alloc_words_atomic(nwords);
  res->header = header;
  tmp = (char*) res->data;
  nbytes = 0;
  lstTmp = lstHead;
  while (!listEmpty(lstTmp)) {
    car = MMC_CAR(lstTmp);
    len = MMC_STRLEN(car);
    /* fprintf(stderr, "stringAppendList: %s %d %d\n", MMC_STRINGDATA(car), len, strlen(MMC_STRINGDATA(car))); */
    /* Might be useful to check this when debugging. String literals are often done wrong :) */
    MMC_DEBUG_ASSERT(len == strlen(MMC_STRINGDATA(car)));
    memcpy(tmp+nbytes,MMC_STRINGDATA(car),len);
    nbytes += len;
    lstTmp = MMC_CDR(lstTmp);
  }
  tmp[nbytes] = '\0';
  /* fprintf(stderr, "stringAppendList(%s)=>%s\n", anyString(lstHead), anyString(MMC_TAGPTR(res))); */
  p = MMC_TAGPTR(res);
  MMC_CHECK_STRING(p);
  return p;
}

modelica_metatype stringDelimitList(modelica_metatype lst, metamodelica_string_const delimiter)
{
  /* fprintf(stderr, "stringDelimitList(%s)\n", anyString(lst)); */
  modelica_integer lstLen = 0, len = 0, lenDelimiter = 0;
  unsigned nbytes = 0, header = 0, nwords = 0;
  modelica_metatype car = NULL, lstHead = NULL, lstTmp = NULL;
  char *tmp = 0, *delimiter_cstr = 0;
  struct mmc_string *res = NULL;
  void *p = NULL;

  lstLen = 0;
  nbytes = 0;
  lstHead = lst;
  lstTmp = lst;
  while (!listEmpty(lstTmp)) {
    MMC_CHECK_STRING(MMC_CAR(lstTmp));
    nbytes += MMC_STRLEN(MMC_CAR(lstTmp));
    /* fprintf(stderr, "stringDelimitList: Has success reading input %d: %s\n", lstLen, MMC_STRINGDATA(MMC_CAR(lst))); */
    lstTmp = MMC_CDR(lstTmp);
    lstLen++;
  }
  if (nbytes == 0) return mmc_emptystring;
  if (lstLen == 1) return MMC_CAR(lstHead);
  lenDelimiter = MMC_STRLEN(delimiter);
  nbytes += (lstLen-1)*lenDelimiter;
  delimiter_cstr = MMC_STRINGDATA(delimiter);
  MMC_DEBUG_ASSERT(lenDelimiter == strlen(delimiter_cstr));

  header = MMC_STRINGHDR(nbytes);
  nwords = MMC_HDRSLOTS(header) + 1;
  res = (struct mmc_string *) mmc_alloc_words_atomic(nwords);
  res->header = header;
  tmp = (char*) res->data;
  nbytes = 0;
  lstTmp = lstHead;
  { /* Unrolled first element (not delimiter in front) */
    car = MMC_CAR(lstTmp);
    len = MMC_STRLEN(car);
    MMC_DEBUG_ASSERT(len == strlen(MMC_STRINGDATA(car)));
    memcpy(tmp+nbytes,MMC_STRINGDATA(car),len);
    nbytes += len;
    lstTmp = MMC_CDR(lstTmp);
  }
  while (!listEmpty(lstTmp)) {
    memcpy(tmp+nbytes,delimiter_cstr,lenDelimiter);
    nbytes += lenDelimiter;
    car = MMC_CAR(lstTmp);
    len = MMC_STRLEN(car);
    /* fprintf(stderr, "stringDelimitList: %s %d %d\n", MMC_STRINGDATA(car), len, strlen(MMC_STRINGDATA(car))); */
    /* Might be useful to check this when debugging. String literals are often done wrong :) */
    MMC_DEBUG_ASSERT(len == strlen(MMC_STRINGDATA(car)));
    memcpy(tmp+nbytes,MMC_STRINGDATA(car),len);
    nbytes += len;
    lstTmp = MMC_CDR(lstTmp);
  }
  tmp[nbytes] = '\0';
  /* fprintf(stderr, "stringDelimitList(%s)=>%s\n", anyString(lstHead), anyString(MMC_TAGPTR(res))); */
  p = MMC_TAGPTR(res);
  MMC_CHECK_STRING(p);
  return p;
}

modelica_metatype boxptr_stringGetStringChar(threadData_t *threadData,metamodelica_string str, modelica_metatype iix)
{
  modelica_metatype res;
  int ix = MMC_UNTAGFIXNUM(iix);
  MMC_CHECK_STRING(str);
  if (ix < 1 || ix > (long) MMC_STRLEN(str))
    MMC_THROW_INTERNAL();
  return mmc_strings_len1[(size_t)MMC_STRINGDATA(str)[ix-1]];
}

modelica_integer nobox_stringGet(threadData_t *threadData,metamodelica_string str, modelica_integer ix)
{
  if (ix < 1 || ix > (long) MMC_STRLEN(str))
    MMC_THROW_INTERNAL();
  return ((unsigned char*)MMC_STRINGDATA(str))[ix-1];
}

modelica_metatype boxptr_stringUpdateStringChar(threadData_t *threadData,metamodelica_string str, metamodelica_string c, modelica_metatype iix)
{
  int ix = MMC_UNTAGFIXNUM(iix);
  int length = 0;
  unsigned header = MMC_GETHDR(str);
  unsigned nwords = MMC_HDRSLOTS(header) + 1;
  struct mmc_string *p = NULL;
  void *res = NULL;

  MMC_CHECK_STRING(str);
  MMC_CHECK_STRING(c);
  /* fprintf(stderr, "stringUpdateStringChar(%s,%s,%ld)\n", MMC_STRINGDATA(str),MMC_STRINGDATA(c),ix); */

  if (ix < 1 || MMC_STRLEN(c) != 1)
    MMC_THROW_INTERNAL();
  length = MMC_STRLEN(str);
  if (ix > length)
    MMC_THROW_INTERNAL();
  p = (struct mmc_string *) mmc_alloc_words_atomic(nwords);
  p->header = header;
  memcpy(p->data, MMC_STRINGDATA(str), length+1 /* include NULL */);
  p->data[ix-1] = MMC_STRINGDATA(c)[0];
  res = MMC_TAGPTR(p);
  MMC_CHECK_STRING(res);
  return res;
}

/* List Operations */

modelica_metatype listReverse(modelica_metatype lst)
{
  modelica_metatype res = NULL;
  if (MMC_NILTEST(lst) || MMC_NILTEST(MMC_CDR(lst))) {
    // 0/1 elements are already reversed
    return lst;
  }
  res = mmc_mk_nil();
  do {
    res = mmc_mk_cons(MMC_CAR(lst),res);
    lst = MMC_CDR(lst);
  } while (!MMC_NILTEST(lst));
  return res;
}

modelica_metatype listReverseInPlace(modelica_metatype lst)
{
  modelica_metatype prev = mmc_mk_nil();
  while (!MMC_NILTEST(lst))
  {
    modelica_metatype oldcdr = MMC_CDR(lst);
    MMC_CDR(lst) = prev;
    prev = lst;
    lst = oldcdr;
  }
  return prev;
}

void boxptr_listSetRest(threadData_t *threadData, modelica_metatype cellToDestroy, modelica_metatype newRest)
{
  if (MMC_NILTEST(cellToDestroy)) {
    MMC_THROW_INTERNAL();
  }
  MMC_CDR(cellToDestroy) = newRest;
}

void boxptr_listSetFirst(threadData_t *threadData, modelica_metatype cellToDestroy, modelica_metatype newContent)
{
  if (MMC_NILTEST(cellToDestroy)) {
    MMC_THROW_INTERNAL();
  }
  MMC_CAR(cellToDestroy) = newContent;
}

modelica_metatype listAppend(modelica_metatype l1,modelica_metatype l2)
{
  int length = 0, i = 0;
  struct mmc_cons_struct *res = NULL;
  struct mmc_cons_struct *p = NULL;
  if (MMC_NILTEST(l2)) /* If l2 is empty, simply return l1; huge performance gain for some uses of listAppend */
    return l1;
  length = listLength(l1);
  if (length == 0) /* We need to check for empty l1 */
    return l2;
  res = (struct mmc_cons_struct*)mmc_alloc_words( length * 3 /*(sizeof(struct mmc_cons_struct)/sizeof(void*))*/ ); /* Do one single big alloc. It's cheaper */
  for (i=0; i<length-1; i++) { /* Write all except the last element... */
    struct mmc_cons_struct *p = res+i;
    p->header = MMC_STRUCTHDR(2, MMC_CONS_CTOR);
    p->data[0] = MMC_CAR(l1);
    p->data[1] = MMC_TAGPTR(res+i+1);
    l1 = MMC_CDR(l1);
  }
  /* The last element is a bit special. It points to l2. */
  p = res+length-1;
  p->header = MMC_STRUCTHDR(2, MMC_CONS_CTOR);
  p->data[0] = MMC_CAR(l1);
  p->data[1] = l2;
  return MMC_TAGPTR(res);
}

modelica_integer listLength(modelica_metatype lst)
{
  modelica_integer res = 0;
  while (!MMC_NILTEST(lst))
  {
    lst = MMC_CDR(lst);
    res++;
  }
  return res;
}

modelica_boolean listMember(modelica_metatype obj, modelica_metatype lst)
{
  while (!MMC_NILTEST(lst))
  {
    if (valueEq(MMC_CAR(lst), obj)) {
      return 1;
    }
    lst = MMC_CDR(lst);
  }
  return 0;
}

modelica_metatype boxptr_listGet(threadData_t *threadData,modelica_metatype lst, modelica_metatype ii)
{
  modelica_metatype res;
  int i = mmc_unbox_integer(ii);
  if (i < 1)
    MMC_THROW_INTERNAL();
  while (!MMC_NILTEST(lst))
  {
    if (i == 1) {
      return MMC_CAR(lst);
    }
    lst = MMC_CDR(lst);
    i--;
  }
  MMC_THROW_INTERNAL(); /* List was not long enough */
}

modelica_metatype boxptr_listNth(threadData_t *threadData,modelica_metatype lst, modelica_metatype i)
{
  return boxptr_listGet(threadData,lst,mmc_mk_icon(mmc_unbox_integer(i)+1));
}

modelica_metatype boxptr_listDelete(threadData_t *threadData, modelica_metatype lst, modelica_metatype iix)
{
  /* TODO: If we assume the index exists we can do this in a much better way */
  int ix = mmc_unbox_integer(iix);
  modelica_metatype *tmpArr = NULL;
  int i = 0;

  if (ix <= 0) {
    MMC_THROW_INTERNAL();
  }

  tmpArr = (modelica_metatype *) mmc_alloc_words(ix-1); /* We know the size of the first part of the list */
  if (tmpArr == NULL) {
    fprintf(stderr, "%s:%d: malloc failed", __FILE__, __LINE__);
    EXIT(1);
  }

  for (i=0; i<ix-1; i++) {
    if (listEmpty(lst)) {
      if (tmpArr) {
        GC_free(tmpArr);
      }
      MMC_THROW_INTERNAL();
    }
    tmpArr[i] = MMC_CAR(lst);
    lst = MMC_CDR(lst);
  }

  if (listEmpty(lst)) {
    GC_free(tmpArr);
    MMC_THROW_INTERNAL();
  }
  lst = MMC_CDR(lst);

  for (i=ix-2; i>=0; i--) {
    lst = mmc_mk_cons(tmpArr[i], lst);
  }
  GC_free(tmpArr);

  return lst;
}

modelica_metatype boxptr_listRest(threadData_t *threadData, modelica_metatype lst)
{
  if (!MMC_NILTEST(lst)) {
    return MMC_CDR(lst);
  }
  MMC_THROW_INTERNAL();
}

modelica_metatype boxptr_listHead(threadData_t *threadData, modelica_metatype lst)
{
  if (!MMC_NILTEST(lst)) {
    return MMC_CAR(lst);
  }
  MMC_THROW_INTERNAL();
}

/* Array Operations */

modelica_metatype arrayList(modelica_metatype arr)
{
  modelica_metatype result;
  int nelts = MMC_HDRSLOTS(MMC_GETHDR(arr))-1;
  void **vecp = MMC_STRUCTDATA(arr);
  void *res = mmc_mk_nil();
  for(; nelts >= 0; --nelts) {
    res = mmc_mk_cons(vecp[nelts],res);
  }
  return res;
}

modelica_metatype listArray(modelica_metatype lst)
{
  int nelts = listLength(lst);
  void* arr = (struct mmc_struct*)mmc_mk_box_no_assign(nelts, MMC_ARRAY_TAG, MMC_IS_IMMEDIATE(MMC_CAR(lst)));
  void **arrp = MMC_STRUCTDATA(arr);
  int i = 0;
  for(i=0; i<nelts; i++) {
    arrp[i] = MMC_CAR(lst);
    lst = MMC_CDR(lst);
  }
  return arr;
}

modelica_metatype listArrayLiteral(modelica_metatype lst)
{
  return listArray(lst);
}

modelica_metatype arrayCopy(modelica_metatype arr)
{
  int nelts = MMC_HDRSLOTS(MMC_GETHDR(arr));
  void* res = (struct mmc_struct*)mmc_mk_box_no_assign(nelts, MMC_ARRAY_TAG, MMC_IS_IMMEDIATE(MMC_STRUCTDATA(arr)[0]));
  void **arrp = MMC_STRUCTDATA(arr);
  void **resp = MMC_STRUCTDATA(res);
  memcpy(resp, arrp, sizeof(modelica_metatype)*nelts);
  return res;
}

modelica_metatype arrayAppend(modelica_metatype arr1, modelica_metatype arr2)
{
  int nelts1 = MMC_HDRSLOTS(MMC_GETHDR(arr1));
  int nelts2 = MMC_HDRSLOTS(MMC_GETHDR(arr2));
  void* res = (struct mmc_struct*)mmc_mk_box_no_assign(nelts1 + nelts2, MMC_ARRAY_TAG, MMC_IS_IMMEDIATE(MMC_STRUCTDATA(arr1)[0]));
  void **arr1p = MMC_STRUCTDATA(arr1);
  void **arr2p = MMC_STRUCTDATA(arr2);
  void **resp = MMC_STRUCTDATA(res);
  int i;
  for (i=0; i<nelts1; ++i) {
    resp[i] = arr1p[i];
  }
  for (i=0; i<nelts2; ++i) {
    resp[i+nelts1] = arr2p[i];
  }
  return res;
}

modelica_metatype boxptr_arrayNth(threadData_t *threadData,modelica_metatype arr,modelica_metatype ix)
{
  return arrayGet(arr, mmc_unbox_integer(ix)+1);
}

/* Misc Operations */
modelica_integer tick(void)
{
  static modelica_integer curTick = 0;
  return curTick++;
}

void boxptr_print(threadData_t *threadData,modelica_metatype str)
{
  fputs(MMC_STRINGDATA(str), stdout);
}

modelica_real mmc_clock(void)
{
  static double start_t;
  static int init = 1;
  if (init) {
    start_t = ((double)clock())/CLOCKS_PER_SEC;
    init = 0;
    return 0.0;
  }
  return (clock()-start_t)/CLOCKS_PER_SEC;
}

void boxptr_equality(threadData_t *threadData,modelica_metatype in1, modelica_metatype in2)
{
  if (!valueEq(in1, in2)) {
    /* fprintf(stderr, "%s != %s\n", anyString(in1), anyString(in2)); */
    MMC_THROW_INTERNAL();
  }
}

modelica_metatype nobox_getGlobalRoot(threadData_t *threadData, modelica_integer ix) {
  void *val = 0;
  if (ix < 0 || ix >= MMC_GC_GLOBAL_ROOTS_SIZE) {
    MMC_THROW_INTERNAL();
  } else if (ix > 8) {
    val = mmc_GC_state->global_roots[ix];
  } else {
    val = threadData->localRoots[ix];
  }
  if (!val) {
    MMC_THROW_INTERNAL();
  }
  return val;
}

void boxptr_setGlobalRoot(threadData_t *threadData, modelica_metatype i, modelica_metatype val) {
  int ix = mmc_unbox_integer(i);
  if (ix < 0 || ix >= MMC_GC_GLOBAL_ROOTS_SIZE) {
    MMC_THROW_INTERNAL();
  } else if (ix > 8) {
    mmc_GC_state->global_roots[ix] = val;
  } else {
    threadData->localRoots[ix] = val;
  }
}

modelica_real realMaxLit(void)
{
  return DBL_MAX / 2048; /* in case some non-linear or ODE solver tries to add eps to this value */
}

modelica_integer intMaxLit(void)
{
  return LONG_MAX / 2;
}

modelica_boolean setStackOverflowSignal(modelica_boolean inSignal)
{
  /* return for now what we got */
  return inSignal;
}

#if defined(linux) || defined(__APPLE_CC__)
#include <execinfo.h>
metamodelica_string referenceDebugString(modelica_metatype fnptr)
{
  void *res;
  char **str = backtrace_symbols(&fnptr, 1);
  if (str == 0) {
    return mmc_mk_scon("Unknown symbol");
  }
  res = mmc_mk_scon(*str);
  free(str);
  return res;
}
#else
metamodelica_string referenceDebugString(modelica_metatype fnptr)
{
  return mmc_mk_scon("Unknown symbol");
}
#endif

metamodelica_string referencePointerString(modelica_metatype ptr)
{
  // 2 chars per byte + 3 for "0x" and null terminator.
  char str[sizeof(void*)*2 + 3];
  snprintf(str, sizeof(void*)*2 + 3, "%p", ptr);
  return mmc_mk_scon(str);
}

const char* SourceInfo_SOURCEINFO__desc__fields[7] = {"fileName","isReadOnly","lineNumberStart","columnNumberStart","lineNumberEnd","columnNumberEnd","lastEditTime"};
struct record_description SourceInfo_SOURCEINFO__desc = {
  "SourceInfo_SOURCEINFO",
  "SourceInfo.SOURCEINFO",
  SourceInfo_SOURCEINFO__desc__fields
};
