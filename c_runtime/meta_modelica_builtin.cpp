/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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
#include "limits.h"
#include "time.h"

/* Boolean Operations */
boolAnd_rettype boolAnd(modelica_boolean b1, modelica_boolean b2)
{
  return ((b1 != 0) && b2 != 0 ? 1 : 0);
}

boolOr_rettype boolOr(modelica_boolean b1, modelica_boolean b2)
{
  return ((b1 != 0) || b2 != 0 ? 1 : 0);
}

boolNot_rettype boolNot(modelica_boolean b)
{
  return (b == 0 ? 1 : 0);
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
  return max(i1,i2);
}

intMin_rettype intMin(modelica_integer i1, modelica_integer i2)
{
  return min(i1,i2);
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

/* Real Operations */
realAdd_rettype realAdd(modelica_real r1, modelica_real r2)
{
  return r1+r2;
}

realSub_rettype realSub(modelica_real r1, modelica_real r2)
{
  return r1-r2;
}

realMul_rettype realMul(modelica_real r1, modelica_real r2)
{
  return r1*r2;
}

realDiv_rettype realDiv(modelica_real r1, modelica_real r2)
{
  return r1/r2;
}

realMod_rettype realMod(modelica_real r1, modelica_real r2)
{
  return fmod(r1,r2);
}

realPow_rettype realPow(modelica_real r1, modelica_real r2)
{
  return pow(r1,r2);
}

realMax_rettype realMax(modelica_real r1, modelica_real r2)
{
  return max(r1,r2);
}

realMin_rettype realMin(modelica_real r1, modelica_real r2)
{
  return min(r1,r2);
}

realAbs_rettype realAbs(modelica_real r)
{
  return fabs(r);
}

realNeg_rettype realNeg(modelica_real r)
{
  return -r;
}

realCos_rettype realCos(modelica_real r)
{
  return cos(r);
}

realSin_rettype realSin(modelica_real r)
{
  return sin(r);
}

realAtan_rettype realAtan(modelica_real r)
{
  return atan(r);
}

realExp_rettype realExp(modelica_real r)
{
  return exp(r);
}

realLn_rettype realLn(modelica_real r)
{
  return log(r);
}

realFloor_rettype realFloor(modelica_real r)
{
  return floor(r);
}

realSqrt_rettype realSqrt(modelica_real r)
{
  return sqrt(r);
}

realLt_rettype realLt(modelica_real r1, modelica_real r2)
{
  return r1 < r2;
}

realLe_rettype realLe(modelica_real r1, modelica_real r2)
{
  return r1 <= r2;
}

realEq_rettype realEq(modelica_real r1, modelica_real r2)
{
  return r1 == r2;
}

realNe_rettype realNe(modelica_real r1, modelica_real r2)
{
  return r1 != r2;
}

realGe_rettype realGe(modelica_real r1, modelica_real r2)
{
  return r1 >= r2;
}

realGt_rettype realGt(modelica_real r1, modelica_real r2)
{
  return r1 > r2;
}

realInt_rettype realInt(modelica_real r)
{
  return (modelica_integer) r;
}

realString_rettype realString(modelica_real r)
{
  /* 64-bit (1+11+52) double: -d.[15 digits]E-[4 digits] = ~24 digits max.
   * Add safety margin. */
  static char buffer[32];
  modelica_string_t res;
  if (isinf(r) && r < 0)
    init_modelica_string(&res, "-inf");
  else if (isinf(r))
    init_modelica_string(&res, "inf");
  else if (isnan(r))
    init_modelica_string(&res, "NaN");
  else if (snprintf(buffer, 32, "%.16g", r) <= 0)
    throw 1;
  else
    init_modelica_string(&res, buffer);
  return res;
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

stringListStringChar_rettype stringListStringChar(modelica_string_t str)
{
  char chr[2] = {'\0', '\0'};
  metamodelica_type revRes;
  revRes = mmc_mk_nil();
  while (*str != '\0') {
    chr[0] = *str++;
    revRes = mmc_mk_cons(mmc_mk_scon(chr), revRes);
  }
  return listReverse(revRes);
}

listStringCharString_rettype listStringCharString(metamodelica_type lst)
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

stringAppendList_rettype stringAppendList(metamodelica_type lst)
{
  int lstLen, i, acc, len;
  modelica_string_t res, res_head;
  metamodelica_type car, lstHead;
  lstLen = listLength(lst);
  acc = 0;
  lstHead = lst;
  for (i=0; i<lstLen /* MMC_NILTEST not required */ ; i++, lst = MMC_CDR(lst)) {
    acc += MMC_HDRSTRLEN(MMC_GETHDR(MMC_CAR(lst)));
  }
  alloc_modelica_string(&res, acc+1);
  res_head = res;
  lst = lstHead;
  for (i=0; i<lstLen /* MMC_NILTEST not required */ ; i++, lst = MMC_CDR(lst)) {
    car = MMC_CAR(lst);
    len = MMC_HDRSTRLEN(MMC_GETHDR(car));
    strncpy(res,MMC_STRINGDATA(car),len);
    res += len;
  }
  *res = '\0';
  return res_head;
}

stringAppend_rettype stringAppend(modelica_string_t str1, modelica_string_t str2)
{
  modelica_string_t tmp;
  cat_modelica_string(&tmp,&str1,&str2);
  return tmp;
}

stringLength_rettype stringLength(modelica_string_t str)
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

stringEqual_rettype stringEqual(modelica_string_t str1, modelica_string_t str2)
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
  copy_modelica_string(&str, &res);
  res[ix-1] = c[0];
  return res;
}

/* List Operations */

listReverse_rettype listReverse(metamodelica_type lst)
{
  metamodelica_type res;
  res = mmc_mk_nil();
  while (!MMC_NILTEST(lst))
  {
    res = mmc_mk_cons(MMC_CAR(lst),res);
    lst = MMC_CDR(lst);
  }
  return res;
}

listAppend_rettype listAppend(metamodelica_type lst1,metamodelica_type lst2)
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

listLength_rettype listLength(metamodelica_type lst)
{
  modelica_integer res = 0;
  while (!MMC_NILTEST(lst))
  {
    lst = MMC_CDR(lst);
    res++;
  }
  return res;
}

listMember_rettype listMember(metamodelica_type lst, metamodelica_type obj)
{
  while (!MMC_NILTEST(lst))
  {
    if (mmc_boxes_equal(MMC_CAR(lst), obj))
      return 1;
    lst = MMC_CDR(lst);
  }
  return 0;
}

listGet_rettype listGet(metamodelica_type lst, modelica_integer i)
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

listNth_rettype listNth(metamodelica_type lst, modelica_integer i)
{
  return listGet(lst,i+1);
}

listRest_rettype listRest(metamodelica_type lst)
{
  if (MMC_NILTEST(lst))
    throw 1;
  return MMC_CDR(lst);
}

listEmpty_rettype listEmpty(metamodelica_type lst)
{
  return MMC_NILTEST(lst) ? 1 : 0;
}

listDelete_rettype listDelete(metamodelica_type lst, modelica_integer ix)
{
  metamodelica_type *tmpArr;
  int i;
  tmpArr = (metamodelica_type *) malloc(sizeof(metamodelica_type)*ix); /* We know the size of the first part of the list (+1 for the element to delete) */
  if (tmpArr == NULL) {
    fprintf(stderr, "%s:%d: malloc failed", __FILE__, __LINE__);
    exit(1);
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
optionNone_rettype optionNone(metamodelica_type opt)
{
  return 0==MMC_HDRSLOTS(MMC_GETHDR(opt)) ? 1 : 0;
}

/* Array Operations */
arrayLength_rettype arrayLength(base_array_t arr)
{
  return base_array_nr_of_elements(&arr);
}

arrayIntegerGet_rettype arrayIntegerGet(integer_array_t arr, modelica_integer ix)
{
  if (ix < 1 || base_array_nr_of_elements(&arr) < (unsigned) ix)
    throw 1;
  return integer_get(&arr,ix-1);
}

arrayRealGet_rettype arrayRealGet(real_array_t arr, modelica_integer ix)
{
  if (ix < 1 || base_array_nr_of_elements(&arr) < (unsigned) ix)
    throw 1;
  return real_get(&arr,ix-1);
}

arrayBooleanGet_rettype arrayBooleanGet(boolean_array_t arr, modelica_integer ix)
{
  if (ix < 1 || base_array_nr_of_elements(&arr) < (unsigned) ix)
    throw 1;
  return boolean_get(&arr,ix-1);
}

arrayStringGet_rettype arrayStringGet(string_array_t arr, modelica_integer ix)
{
  if (ix < 1 || base_array_nr_of_elements(&arr) < (unsigned) ix)
    throw 1;
  return string_get(&arr,ix-1);
}

arrayIntegerCreate_rettype arrayIntegerCreate(modelica_integer num, modelica_integer val)
{
  integer_array_t arr;
  if (num < 1)
    throw 1;
  simple_alloc_1d_integer_array(&arr, num);
  fill_integer_array(&arr, val);
  return arr;
}

arrayRealCreate_rettype arrayRealCreate(modelica_integer num, modelica_real val)
{
  real_array_t arr;
  if (num < 1)
    throw 1;
  simple_alloc_1d_real_array(&arr, num);
  fill_real_array(&arr, val);
  return arr;
}

arrayBooleanCreate_rettype arrayBooleanCreate(modelica_integer num, modelica_boolean val)
{
  boolean_array_t arr;
  if (num < 1)
    throw 1;
  simple_alloc_1d_boolean_array(&arr, num);
  fill_boolean_array(&arr, val);
  return arr;
}

arrayStringCreate_rettype arrayStringCreate(modelica_integer num, modelica_string_t val)
{
  string_array_t arr;
  if (num < 1)
    throw 1;
  simple_alloc_1d_string_array(&arr, num);
  fill_string_array(&arr, val);
  return arr;
}

/* Misc Operations */
tick_rettype tick()
{
  static modelica_integer curTick = 0;
  return curTick++;
}

void print(char* str)
{
  fprintf(stdout, "%s", str);
}

mmc__clock_rettype mmc__clock()
{
  static double start_t = clock();
  return (clock()-start_t)/CLOCKS_PER_SEC;
}

if__exp_rettype if__exp(modelica_boolean cond, metamodelica_type in1, metamodelica_type in2)
{
  return cond ? in1 : in2;
}

void equality(metamodelica_type in1, metamodelica_type in2)
{
  if (!mmc_boxes_equal(in1, in2))
    throw 1;
}

