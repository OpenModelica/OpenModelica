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

#include "meta_modelica_builtin.h"
#include <limits.h>
#include <time.h>
#include <math.h>
#include <string.h>
#include <stdio.h>

#if defined(_MSC_VER)
#include <float.h>
#define isinf(d) (!_finite(d) && !_isnan(d))
#define isnan _isnan
#define snprintf _snprintf
#endif

extern "C" {

/* Boolean Operations */
modelica_metatype boxptr_boolAnd(modelica_metatype b1, modelica_metatype b2)
{
  return ((b1 != 0) && (b2 != 0) ? mmc_mk_icon(1) : mmc_mk_icon(0));
}

modelica_metatype boxptr_boolOr(modelica_metatype b1, modelica_metatype b2)
{
  return ((b1 != 0) || (b2 != 0) ? mmc_mk_icon(1) : mmc_mk_icon(0));
}

modelica_metatype boxptr_boolEq(modelica_metatype b1, modelica_metatype b2)
{
  return mmc_mk_icon(b1 == b2);
}

modelica_metatype boxptr_boolNot(modelica_metatype b)
{
  return (b == 0 ? mmc_mk_icon(1) : mmc_mk_icon(0));
}

modelica_metatype boxptr_boolString(modelica_metatype b)
{
  return mmc_mk_scon(boolString(b));
}

/* Integer Operations */
intAdd_rettype intAdd(modelica_integer i1, modelica_integer i2)
{
  return i1+i2;
}

intSub_rettype intSub(modelica_integer i1, modelica_integer i2)
{
  return i1-i2;
}

intMul_rettype intMul(modelica_integer i1, modelica_integer i2)
{
  return i1*i2;
}

intDiv_rettype intDiv(modelica_integer i1, modelica_integer i2)
{
  return i1/i2;
}

intMod_rettype intMod(modelica_integer i1, modelica_integer i2)
{
  return i1%i2;
}

intMax_rettype intMax(modelica_integer i1, modelica_integer i2)
{
  return i1 > i2 ? i1 : i2;
}

intMin_rettype intMin(modelica_integer i1, modelica_integer i2)
{
  return i1 < i2 ? i1 : i2;
}

modelica_metatype boxptr_intAdd(modelica_metatype i1, modelica_metatype i2)
{
  return (void*) ((long)i1+(long)i2);
}

modelica_metatype boxptr_intSub(modelica_metatype i1, modelica_metatype i2)
{
  return (void*) ((long)i1-(long)i2);
}

modelica_metatype boxptr_intMul(modelica_metatype i1, modelica_metatype i2)
{
  // Unbox first to avoid overflow
  return mmc_mk_icon(mmc__unbox__integer(i1)*mmc__unbox__integer(i2));
}

modelica_metatype boxptr_intDiv(modelica_metatype i1, modelica_metatype i2)
{
  return mmc_mk_icon((long)i1/(long)i2);
}

modelica_metatype boxptr_intMod(modelica_metatype i1, modelica_metatype i2)
{
  return (void*) ((long)i1%(long)i2);
}

modelica_metatype boxptr_intMax(modelica_metatype i1, modelica_metatype i2)
{
  return i1 > i2 ? i1 : i2;
}

modelica_metatype boxptr_intMin(modelica_metatype i1, modelica_metatype i2)
{
  return i1 < i2 ? i1 : i2;
}

intLt_rettype intLt(modelica_integer i1, modelica_integer i2)
{
  return i1 < i2;
}

intLe_rettype intLe(modelica_integer i1, modelica_integer i2)
{
  return i1 <= i2;
}

intEq_rettype intEq(modelica_integer i1, modelica_integer i2)
{
  return i1 == i2;
}

intNe_rettype intNe(modelica_integer i1, modelica_integer i2)
{
  return i1 != i2;
}

intGe_rettype intGe(modelica_integer i1, modelica_integer i2)
{
  return i1 >= i2;
}

intGt_rettype intGt(modelica_integer i1, modelica_integer i2)
{
  return i1 > i2;
}

intAbs_rettype intAbs(modelica_integer i)
{
  return abs(i);
}

intNeg_rettype intNeg(modelica_integer i)
{
  return -i;
}

intReal_rettype intReal(modelica_integer i)
{
  return (modelica_real) i;
}

intString_rettype intString(modelica_integer i)
{
  /* 32-bit integer: 1+log_10(2**31)+1 = 12 digits max */
  static char buffer[12];
  modelica_string_t res;
  sprintf(buffer, "%d", i);
  init_modelica_string(&res, buffer);
  return res;
}

modelica_metatype boxptr_intEq(modelica_metatype i1, modelica_metatype i2)
{
  return mmc_mk_icon(i1 == i2);
}

modelica_metatype boxptr_intAbs(modelica_metatype i)
{
  return mmc_mk_icon(abs(mmc__unbox__integer(i)));
}

modelica_metatype boxptr_intNeg(modelica_metatype i)
{
  return mmc_mk_icon(-(mmc__unbox__integer(i)));
}

modelica_metatype boxptr_intReal(modelica_metatype i)
{
  return mmc_mk_rcon(mmc__unbox__integer(i));
}

modelica_metatype boxptr_intString(modelica_metatype i)
{
  return mmc_mk_scon(intString(mmc__unbox__integer(i)));
}

/* String Character Conversion */

stringCharInt_rettype stringCharInt(modelica_string_t chr)
{
  if (chr[0] == '\0' || chr[1] != '\0')
    throw 1;
  return (int) chr[0];
}

intStringChar_rettype intStringChar(modelica_integer ix)
{
  modelica_string_t res;
  if (ix < 1 || ix > 255)
    throw 1;
  alloc_modelica_string(&res, 1);
  res[0] = (char) ix;
  res[1] = '\0';
  return res;
}

/* String Operations */

stringInt_rettype stringInt(modelica_string_t str)
{
  long res;
  char* endptr;
  errno = 0;
  res = strtol(str,&endptr,10);
  if (errno != 0 || str == endptr)
    throw 1;
  if (*endptr != '\0')
    throw 1;
  if (res > INT_MAX || res < INT_MIN)
    throw 1;

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
stringInt_rettype stringHash(modelica_string_const str)
{
  long res = 0, i=0;
  while (0 != (str[i])) { res += str[i]; i++; }
  return res;
}

/* adrpo: see the comment above about djb2 hash */
stringInt_rettype stringHashDjb2(modelica_string_const str)
{
  long res = djb2_hash((const unsigned char*)str);
  return res;
}

/* adrpo: see the comment above about sdbm hash */
stringInt_rettype stringHashSdbm(modelica_string_const str)
{
  long res = sdbm_hash((const unsigned char*)str);
  return res;
}

/******************** BOXED String HASH Functions ********************/
/* adrpo: really bad hash :) */
modelica_metatype boxptr_stringHash(modelica_metatype str)
{
  const char* s = MMC_STRINGDATA(str);
  modelica_metatype res = mmc_mk_icon(stringHash(s));
  return res;
}

/* adrpo: see the comment above about djb2 hash */
modelica_metatype boxptr_stringHashDjb2(modelica_metatype str)
{
  const char* s = MMC_STRINGDATA(str);
  modelica_metatype res = mmc_mk_icon(stringHashDjb2(s));
  return res;
}

/* adrpo: see the comment above about sdbm hash */
modelica_metatype boxptr_stringHashSdmb(modelica_metatype str)
{
  const char* s = MMC_STRINGDATA(str);
  modelica_metatype res = mmc_mk_icon(stringHashSdbm(s));
  return res;
}

stringListStringChar_rettype stringListStringChar(modelica_string_t str)
{
  char chr[2] = {'\0', '\0'};
  modelica_metatype revRes;
  revRes = mmc_mk_nil();
  while (*str != '\0') {
    chr[0] = *str++;
    revRes = mmc_mk_cons(mmc_mk_scon(chr), revRes);
  }
  return listReverse(revRes);
}

listStringCharString_rettype listStringCharString(modelica_metatype lst)
{
  int lstLen, i;
  modelica_string_t res;
  void* car;
  lstLen = listLength(lst);
  alloc_modelica_string(&res, lstLen+1);
  for (i=0; i<lstLen /* MMC_NILTEST not required */ ; i++, lst = MMC_CDR(lst)) {
    car = MMC_CAR(lst);
    if (1 != MMC_HDRSTRLEN(MMC_GETHDR(car))) {
     free_modelica_string(&res);
     throw 1;
    }
    res[i] = MMC_STRINGDATA(car)[0];
  }
  res[lstLen] = '\0';
  return res;
}

stringAppendList_rettype stringAppendList(modelica_metatype lst)
{
  int lstLen, i, acc, len;
  modelica_string_t res, res_head, tmp;
  modelica_metatype car, lstHead;
  lstLen = listLength(lst);
  acc = 0;
  lstHead = lst;
  for (i=0; i<lstLen /* MMC_NILTEST not required */ ; i++, lst = MMC_CDR(lst)) {
    tmp = MMC_STRINGDATA(MMC_CAR(lst));
    acc += strlen(tmp);
  }
  res = (char*) malloc(acc+1);
  res_head = res;
  lst = lstHead;
  for (i=0; i<lstLen /* MMC_NILTEST not required */ ; i++, lst = MMC_CDR(lst)) {
    car = MMC_CAR(lst);
    tmp = MMC_STRINGDATA(car);
    len = strlen(tmp);
    memcpy(res,tmp,len);
    res += len;
  }
  *res = '\0';
  return res_head;
}

/* OMC declares this const, but we don't always use it in that manner... */
stringAppendListExt_rettype stringAppendListExt(modelica_metatype lst)
{
  return stringAppendList(lst);
}

stringAppend_rettype stringAppend(modelica_string_const s1, modelica_string_const s2)
{
  int len1 = strlen(s1);
  int len2 = strlen(s2);
  char* str = (char*) malloc(len1+len2+1);

  memcpy(str, s1, len1);
  memcpy(str + len1, s2, len2 + 1);
  str[len1+len2] = '\0';
  return str;
}

modelica_metatype boxptr_stringAppend(modelica_metatype str1, modelica_metatype str2)
{
  const char* s1 = MMC_STRINGDATA(str1);
  const char* s2 = MMC_STRINGDATA(str2);
  char* str = stringAppend(s1,s2);
  modelica_metatype res = mmc_mk_scon(str);
  free(str);
  return res;
}

stringLength_rettype stringLength(modelica_string_const str)
{
  return strlen(str);
}

stringCompare_rettype stringCompare(modelica_string_t str1, modelica_string_t str2)
{
  stringCompare_rettype res = strcmp(str1,str2);
  if (res < 0)
    return -1;
  if (res > 0)
    return 1;
  return 0;
}

stringEq_rettype stringEq(modelica_string_t str1, modelica_string_t str2)
{
  return 0 == strcmp(str1,str2) ? 1 : 0;
}

stringGetStringChar_rettype stringGetStringChar(modelica_string_t str, modelica_integer ix)
{
  modelica_string_t res;
  char chr[2] = {'\0','\0'};
  if (*str == 0)
    throw 1;
  while (ix > 1) {
    if (*(++str) == 0)
      throw 1;
    ix--;
  }
  chr[0] = *str;
  init_modelica_string(&res, chr);
  return res;
}

stringUpdateStringChar_rettype stringUpdateStringChar(modelica_string_t str, modelica_string_t c, modelica_integer ix)
{
  modelica_string_t res;
  int length;
  if (ix < 1 || c[0] == '\0' || c[1] != '\0')
    throw 1;
  length = strlen(str);
  if (ix > length)
    throw 1;
  copy_modelica_string(str, &res);
  res[ix-1] = c[0];
  return res;
}

modelica_metatype boxptr_stringEq(modelica_metatype str1, modelica_metatype str2)
{
  return mmc_mk_icon(stringEq(MMC_STRINGDATA(str1),MMC_STRINGDATA(str2)));
}

/* List Operations */

listReverse_rettype listReverse(modelica_metatype lst)
{
  modelica_metatype res;
  res = mmc_mk_nil();
  while (!MMC_NILTEST(lst))
  {
    res = mmc_mk_cons(MMC_CAR(lst),res);
    lst = MMC_CDR(lst);
  }
  return res;
}

listAppend_rettype listAppend(modelica_metatype lst1,modelica_metatype lst2)
{
  if (MMC_NILTEST(lst2)) /* Don't reverse lst1 if lst2 is empty... */
    return lst1;
  lst1 = listReverse(lst1);
  while (!MMC_NILTEST(lst1))
  {
    lst2 = mmc_mk_cons(MMC_CAR(lst1),lst2);
    lst1 = MMC_CDR(lst1);
  }
  return lst2;
}

listLength_rettype listLength(modelica_metatype lst)
{
  modelica_integer res = 0;
  while (!MMC_NILTEST(lst))
  {
    lst = MMC_CDR(lst);
    res++;
  }
  return res;
}

listMember_rettype listMember(modelica_metatype obj, modelica_metatype lst)
{
  while (!MMC_NILTEST(lst))
  {
    if (mmc_boxes_equal(MMC_CAR(lst), obj))
      return 1;
    lst = MMC_CDR(lst);
  }
  return 0;
}

listGet_rettype listGet(modelica_metatype lst, modelica_integer i)
{
  if (i < 1)
    throw 1;
  while (!MMC_NILTEST(lst))
  {
    if (i == 1) {
      return MMC_CAR(lst);
    }
    lst = MMC_CDR(lst);
    i--;
  }
  throw 1; /* List was not long enough */
}

listNth_rettype listNth(modelica_metatype lst, modelica_integer i)
{
  return listGet(lst,i+1);
}

modelica_metatype boxptr_listGet(modelica_metatype lst, modelica_metatype i)
{
  return listGet(lst,MMC_UNTAGFIXNUM(i));
}

modelica_metatype boxptr_listNth(modelica_metatype lst, modelica_metatype i)
{
  return listGet(lst,MMC_UNTAGFIXNUM(i)+1);
}

listRest_rettype listRest(modelica_metatype lst)
{
  if (MMC_NILTEST(lst))
    throw 1;
  return MMC_CDR(lst);
}

listEmpty_rettype listEmpty(modelica_metatype lst)
{
  return MMC_NILTEST(lst) ? 1 : 0;
}

listDelete_rettype listDelete(modelica_metatype lst, modelica_integer ix)
{
  modelica_metatype *tmpArr;
  int i;
  tmpArr = (modelica_metatype *) malloc(sizeof(modelica_metatype)*ix); /* We know the size of the first part of the list (+1 for the element to delete) */
  if (tmpArr == NULL) {
    fprintf(stderr, "%s:%d: malloc failed", __FILE__, __LINE__);
    EXIT(1);
  }
  for (i=0; i<ix; i++)
  {
    if (MMC_NILTEST(lst))
    {
      free(tmpArr);
      throw 1;
    }
    tmpArr[i] = MMC_CAR(lst);
    lst = MMC_CDR(lst);
  }
  for (i=ix-2; i>=0; i--)
  {
    lst = mmc_mk_cons(tmpArr[i], lst);
  }
  free(tmpArr);
  return lst;
}

/* Option Operations */
optionNone_rettype optionNone(modelica_metatype opt)
{
  return 0==MMC_HDRSLOTS(MMC_GETHDR(opt)) ? 1 : 0;
}

/* Array Operations */
arrayLength_rettype arrayLength(modelica_metatype arr)
{
  return MMC_HDRSLOTS(MMC_GETHDR(arr));
}

arrayGet_rettype arrayGet(modelica_metatype arr, modelica_integer ix)
{
  if (ix < 1)
    throw 1;
  if((unsigned)ix-1 >= MMC_HDRSLOTS(MMC_GETHDR(arr)))
    throw 1;
  return MMC_STRUCTDATA(arr)[ix-1];
}

arrayCreate_rettype arrayCreate(modelica_integer nelts, modelica_metatype val)
{
  void* arr = (struct mmc_struct*)mmc_mk_box_no_assign(nelts, MMC_ARRAY_TAG);
  void **arrp = MMC_STRUCTDATA(arr);
  for(int i=0; i<nelts; i++)
    arrp[i] = val;
  return arr;
}

arrayList_rettype arrayList(modelica_metatype arr)
{
  int nelts = MMC_HDRSLOTS(MMC_GETHDR(arr))-1;
  void **vecp = MMC_STRUCTDATA(arr);
  void *res = mmc_mk_nil();
  for(; nelts >= 0; --nelts)
    res = mmc_mk_cons(vecp[nelts],res);
  return res;
}

listArray_rettype listArray(modelica_metatype lst)
{
  int nelts = listLength(lst);
  void* arr = (struct mmc_struct*)mmc_mk_box_no_assign(nelts, MMC_ARRAY_TAG);
  void **arrp = MMC_STRUCTDATA(arr);
  for(int i=0; i<nelts; i++) {
    arrp[i] = MMC_CAR(lst);
    lst = MMC_CDR(lst);
  }
  return arr;
}

arrayUpdate_rettype arrayUpdate(modelica_metatype arr, modelica_integer ix, modelica_metatype val)
{
  int nelts = MMC_HDRSLOTS(MMC_GETHDR(arr));
  if (ix < 1 || ix > nelts)
    throw 1;
  MMC_STRUCTDATA(arr)[ix-1] = val;
  return arr;
}

arrayCopy_rettype arrayCopy(modelica_metatype arr)
{
  int nelts = MMC_HDRSLOTS(MMC_GETHDR(arr));
  void* res = (struct mmc_struct*)mmc_mk_box_no_assign(nelts, MMC_ARRAY_TAG);
  void **arrp = MMC_STRUCTDATA(arr);
  void **resp = MMC_STRUCTDATA(res);
  for(int i=0; i<nelts; i++) {
    resp[i] = arrp[i];
  }
  return res;
}

arrayAdd_rettype arrayAdd(modelica_metatype arr, modelica_metatype val)
{
  int nelts = MMC_HDRSLOTS(MMC_GETHDR(arr));
  void* res = (struct mmc_struct*)mmc_mk_box_no_assign(nelts+1, MMC_ARRAY_TAG);
  void **arrp = MMC_STRUCTDATA(arr);
  void **resp = MMC_STRUCTDATA(res);
  for(int i=0; i<nelts; i++) {
    resp[i] = arrp[i];
  }
  resp[nelts] = val;
  return res;
}

arrayNth_rettype arrayNth(modelica_metatype arr, modelica_integer ix)
{
  return arrayGet(arr, ix+1);
}

modelica_metatype boxptr_arrayNth(modelica_metatype arr, modelica_metatype ix)
{
  return arrayGet(arr, MMC_UNTAGFIXNUM(ix)+1);
}

/* Misc Operations */
tick_rettype tick()
{
  static modelica_integer curTick = 0;
  return curTick++;
}

void boxptr_print(modelica_metatype str)
{
  fprintf(stdout, "%s", MMC_STRINGDATA(str));
}

void print(char* str)
{
  fprintf(stdout, "%s", str);
}

mmc__clock_rettype mmc__clock()
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

if__exp_rettype if__exp(modelica_boolean cond, modelica_metatype in1, modelica_metatype in2)
{
  return cond ? in1 : in2;
}

void equality(modelica_metatype in1, modelica_metatype in2)
{
  if (!mmc_boxes_equal(in1, in2))
    throw 1;
}

/* Weird RML crap */
static modelica_metatype global_roots[1024];

getGlobalRoot_rettype getGlobalRoot(int ix) {
  return global_roots[ix];
}

void setGlobalRoot(int ix, modelica_metatype val) {
  global_roots[ix] = val;
}

valueConstructor_rettype valueConstructor(modelica_metatype val) {
  return MMC_HDRCTOR(MMC_GETHDR(val));
}

modelica_metatype boxptr_getGlobalRoot(modelica_metatype ix) {
  return global_roots[MMC_UNTAGFIXNUM(ix)];
}

void boxptr_setGlobalRoot(modelica_metatype ix, modelica_metatype val) {
  global_roots[MMC_UNTAGFIXNUM(ix)] = val;
}

modelica_metatype boxptr_valueConstructor(modelica_metatype val) {
  return mmc_mk_icon(MMC_HDRCTOR(MMC_GETHDR(val)));
}

}
