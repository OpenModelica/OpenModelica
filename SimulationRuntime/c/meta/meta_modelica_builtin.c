/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#define __OPENMODELICA__METAMODELICA

#include "meta_modelica_builtin.h"
#include "meta_modelica.h"
#include <float.h>
#include <limits.h>
#include <assert.h>
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

#define GEN_META_MODELICA_BUILTIN_BOXPTR
#include "meta_modelica_builtin_boxptr.h"

metamodelica_string intString(modelica_integer i)
{
  /* 64-bit integer: 1+log_10(2**63)+1 = 20 digits max */
  static char buffer[32];
  void *res;
  if (i>=0 && i<=9) /* Small integers are used so much it makes sense to cache them */
    return mmc_strings_len1['0'+i];
  sprintf(buffer, "%ld", (long) i);
  res = mmc_mk_scon(buffer);
  MMC_CHECK_STRING(res);
  return res;
}

modelica_metatype boxptr_intMax(modelica_metatype a,modelica_metatype b)
{
  /* We need to unbox because pointers may be unsigned */
  return mmc_unbox_integer(a) > mmc_unbox_integer(b) ? a : b;
}


modelica_metatype boxptr_intMin(modelica_metatype a,modelica_metatype b)
{
  /* We need to unbox because pointers may be unsigned */
  return mmc_unbox_integer(a) < mmc_unbox_integer(b) ? a : b;
}


/* String Character Conversion */

modelica_integer stringCharInt(metamodelica_string chr)
{
  unsigned char c;
  if (MMC_STRLEN(chr) != 1)
    MMC_THROW();
  MMC_CHECK_STRING(chr);
  c = (unsigned char) MMC_STRINGDATA(chr)[0];
  return c;
}

metamodelica_string intStringChar(modelica_integer ix)
{
  char chr[2];
  if (ix < 1 || ix > 255)
    MMC_THROW();
  chr[0] = (char) ix;
  chr[1] = '\0';
  return mmc_mk_scon(chr);
}

/* String Operations */

modelica_integer stringInt(metamodelica_string s)
{
  long res;
  char *endptr,*str=MMC_STRINGDATA(s);
  MMC_CHECK_STRING(s);
  errno = 0;
  res = strtol(str,&endptr,10);
  if (errno != 0 || str == endptr)
    MMC_THROW();
  if (*endptr != '\0')
    MMC_THROW();
  if (res > INT_MAX || res < INT_MIN)
    MMC_THROW();

  return res;
}

modelica_real stringReal(metamodelica_string s)
{
  double res;
  char *endptr,*str=MMC_STRINGDATA(s);
  MMC_CHECK_STRING(s);
  errno = 0;
  res = strtod(str,&endptr);
  if (errno != 0 || str == endptr)
    MMC_THROW();
  if (*endptr != '\0')
    MMC_THROW();

  return res;
}

modelica_metatype boxptr_stringEq(modelica_metatype a, modelica_metatype b)
{
  mmc_GC_add_roots(&a, 1, 0, "");
  mmc_GC_add_roots(&b, 1, 0, "");
  return mmc_mk_bcon(stringEqual(a,b));
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
  res = abs(res);
  /* fprintf(stderr, "stringHashDjb2 %s-> %ld %ld %ld\n", str, res, mmc_mk_icon(res), mmc_unbox_integer(mmc_mk_icon(res))); */
  return res;
}

/* adrpo: see the comment above about djb2 hash */
modelica_integer stringHashDjb2Mod(metamodelica_string_const s, modelica_integer mod)
{
  const char* str = MMC_STRINGDATA(s);
  long res = djb2_hash((const unsigned char*)str) % (unsigned int) mod;
  res = abs(res);
  /* fprintf(stderr, "stringHashDjb2Mod %s %ld-> %ld %ld %ld\n", str, mod, res, mmc_mk_icon(res), mmc_unbox_integer(mmc_mk_icon(res))); */
  return res;
}

modelica_metatype boxptr_stringHashDjb2Mod(modelica_metatype v,modelica_metatype mod)
{
  mmc_GC_add_roots(&v, 1, 0, "");
  mmc_GC_add_roots(&mod, 1, 0, "");
  return mmc_mk_icon(stringHashDjb2Mod(v,mmc_unbox_integer(mod)));
}

/* adrpo: see the comment above about sdbm hash */
modelica_integer stringHashSdbm(metamodelica_string_const s)
{
  const char* str = MMC_STRINGDATA(s);
  long res = sdbm_hash((const unsigned char*)str);
  return res;
}

/******************** BOXED String HASH Functions ********************/
/* adrpo: really bad hash :) */
modelica_metatype boxptr_stringHash(modelica_metatype str)
{
  mmc_GC_add_roots(&str, 1, 0, "");
  return mmc_mk_icon(stringHash(str));
}

/* adrpo: see the comment above about djb2 hash */
modelica_metatype boxptr_stringHashDjb2(modelica_metatype str)
{
  mmc_GC_add_roots(&str, 1, 0, "");
  return mmc_mk_icon(stringHashDjb2(str));
}

/* adrpo: see the comment above about sdbm hash */
modelica_metatype boxptr_stringHashSdbm(modelica_metatype str)
{
  mmc_GC_add_roots(&str, 1, 0, "");
  return mmc_mk_icon(stringHashSdbm(str));
}

metamodelica_string stringListStringChar(metamodelica_string s)
{
  const char *str = MMC_STRINGDATA(s);
  char chr[2] = {'\0', '\0'};
  modelica_metatype res = NULL;
  int i = 0;

  mmc_GC_add_roots(&s, 1, 0, "");
  mmc_GC_add_roots(&res, 1, 0, "");

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

  mmc_GC_add_roots(&lst, 1, 0, "");
  mmc_GC_add_roots(&lstHead, 1, 0, "");
  mmc_GC_add_roots(&lstTmp, 1, 0, "");
  mmc_GC_add_roots(&car, 1, 0, "");

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
  res = (struct mmc_string *) mmc_alloc_words(nwords);
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

metamodelica_string stringDelimitList(modelica_metatype lst, metamodelica_string_const delimiter)
{
  /* fprintf(stderr, "stringDelimitList(%s)\n", anyString(lst)); */
  modelica_integer lstLen = 0, len = 0, lenDelimiter = 0;
  unsigned nbytes = 0, header = 0, nwords = 0;
  modelica_metatype car = NULL, lstHead = NULL, lstTmp = NULL;
  char *tmp = 0, *delimiter_cstr = 0;
  struct mmc_string *res = NULL;
  void *p = NULL;

  mmc_GC_add_roots(&lst, 1, 0, "");
  mmc_GC_add_roots((void*)&delimiter, 1, 0, "");
  mmc_GC_add_roots(&lstHead, 1, 0, "");
  mmc_GC_add_roots(&lstTmp, 1, 0, "");
  mmc_GC_add_roots(&car, 1, 0, "");

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
  res = (struct mmc_string *) mmc_alloc_words(nwords);
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

modelica_integer mmc_stringCompare(const void *str1, const void *str2)
{
  int res;
  MMC_CHECK_STRING(str1);
  MMC_CHECK_STRING(str2);
  res = strcmp(MMC_STRINGDATA(str1),MMC_STRINGDATA(str2));
  if (res < 0)
    return -1;
  if (res > 0)
    return 1;
  return 0;
}

modelica_metatype stringGetStringChar(metamodelica_string str, modelica_integer ix)
{
  char chr[2] = {'\0','\0'};
  void *res;
  MMC_CHECK_STRING(str);
  if (ix < 1 || ix > (long) MMC_STRLEN(str))
    MMC_THROW();
  chr[0] = MMC_STRINGDATA(str)[ix-1];
  res = mmc_mk_scon(chr);
  MMC_CHECK_STRING(res);
  return res;
}

modelica_metatype stringUpdateStringChar(metamodelica_string str, metamodelica_string c, modelica_integer ix)
{
  int length = 0;
  unsigned header = MMC_GETHDR(str);
  unsigned nwords = MMC_HDRSLOTS(header) + 1;
  struct mmc_string *p = NULL;
  void *res = NULL;

  mmc_GC_add_roots((void*)&str, 1, 0, "");
  mmc_GC_add_roots((void*)&c, 1, 0, "");

  MMC_CHECK_STRING(str);
  MMC_CHECK_STRING(c);
  /* fprintf(stderr, "stringUpdateStringChar(%s,%s,%ld)\n", anyString(str),anyString(c),ix); */

  if (ix < 1 || MMC_STRLEN(c) != 1)
    MMC_THROW();
  length = MMC_STRLEN(str);
  if (ix > length)
    MMC_THROW();
  p = (struct mmc_string *) mmc_alloc_words(nwords);
  p->header = header;
  memcpy(p->data, MMC_STRINGDATA(str), length);
  p->data[ix-1] = MMC_STRINGDATA(c)[0];
  res = MMC_TAGPTR(p);
  MMC_CHECK_STRING(res);
  return res;
}

metamodelica_string_const stringAppend(metamodelica_string_const s1, metamodelica_string_const s2)
{
  unsigned len1 = 0, len2 = 0, nbytes = 0, header = 0, nwords = 0;
  void *res = NULL;
  struct mmc_string *p = NULL;
  MMC_CHECK_STRING(s1);
  MMC_CHECK_STRING(s2);

  mmc_GC_add_roots((void*)&s1, 1, 0, "");
  mmc_GC_add_roots((void*)&s2, 1, 0, "");

  /* fprintf(stderr, "stringAppend([%p] %s, [%p] %s)->\n", s1, anyString(s1), s2, anyString(s2)); fflush(NULL); */
  len1 = MMC_STRLEN(s1);
  len2 = MMC_STRLEN(s2);
  nbytes = len1+len2;
  header = MMC_STRINGHDR(nbytes);
  nwords = MMC_HDRSLOTS(header) + 1;
  p = (struct mmc_string *) mmc_alloc_words(nwords);
  /* fprintf(stderr, "at address %p\n", MMC_TAGPTR(p)); fflush(NULL); */
  p->header = header;

  memcpy(p->data, MMC_STRINGDATA(s1), len1);
  memcpy(p->data + len1, MMC_STRINGDATA(s2), len2 + 1);
  res = MMC_TAGPTR(p);
  MMC_CHECK_STRING(res);
  /* fprintf(stderr, "-> %s\n", anyString(res)); fflush(NULL); */
  return res;
}

/* List Operations */

modelica_metatype listReverse(modelica_metatype lst)
{
  modelica_metatype res = NULL;

  mmc_GC_add_roots(&lst, 1, 0, "");
  mmc_GC_add_roots(&res, 1, 0, "");

  res = mmc_mk_nil();
  while (!MMC_NILTEST(lst))
  {
    res = mmc_mk_cons(MMC_CAR(lst),res);
    lst = MMC_CDR(lst);
  }
  return res;
}

modelica_metatype listAppend(modelica_metatype lst1,modelica_metatype lst2)
{

  mmc_GC_add_roots(&lst1, 1, 0, "listAppend");
  mmc_GC_add_roots(&lst2, 1, 0, "listAppend");

  {
  int length = 0, i = 0;
  struct mmc_cons_struct *res = NULL;
  struct mmc_cons_struct *p = NULL;
  if (MMC_NILTEST(lst2)) /* If lst2 is empty, simply return lst1; huge performance gain for some uses of listAppend */
    return lst1;
  length = listLength(lst1);
  if (length == 0) /* We need to check for empty lst1 */
    return lst2;
  res = (struct mmc_cons_struct*) mmc_alloc_words( length * 3 /*(sizeof(struct mmc_cons_struct)/sizeof(void*))*/ ); /* Do one single big alloc. It's cheaper */
  for (i=0; i<length-1; i++) { /* Write all except the last element... */
    struct mmc_cons_struct *p = res+i;
    p->header = MMC_STRUCTHDR(2, MMC_CONS_CTOR);
    p->data[0] = MMC_CAR(lst1);
    p->data[1] = MMC_TAGPTR(res+i+1);
    lst1 = MMC_CDR(lst1);
  }
  /* The last element is a bit special. It points to lst2. */
  p = res+length-1;
  p->header = MMC_STRUCTHDR(2, MMC_CONS_CTOR);
  p->data[0] = MMC_CAR(lst1);
  p->data[1] = lst2;
  return MMC_TAGPTR(res);
  }
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
    if (valueEq(MMC_CAR(lst), obj))
      return 1;
    lst = MMC_CDR(lst);
  }
  return 0;
}

modelica_metatype listGet(modelica_metatype lst, modelica_integer i)
{
  if (i < 1)
    MMC_THROW();
  while (!MMC_NILTEST(lst))
  {
    if (i == 1) {
      return MMC_CAR(lst);
    }
    lst = MMC_CDR(lst);
    i--;
  }
  MMC_THROW(); /* List was not long enough */
}

modelica_metatype boxptr_listGet(modelica_metatype lst, modelica_metatype i)
{
  return listGet(lst,MMC_UNTAGFIXNUM(i));
}

modelica_metatype boxptr_listNth(modelica_metatype lst, modelica_metatype i)
{
  return listGet(lst,mmc_unbox_integer(i)+1);
}

modelica_metatype boxptr_listDelete(modelica_metatype lst, modelica_metatype i)
{
  return listDelete(lst,mmc_unbox_integer(i));
}

modelica_metatype listDelete(modelica_metatype lst, modelica_integer ix)
{
  modelica_metatype *tmpArr = NULL;
  int i = 0;

  mmc_GC_add_roots(&lst, 1, 0, "");

  if (ix < 0)
    MMC_THROW();
  if (ix == 0) {
    if (listEmpty(lst))
      MMC_THROW();
    return MMC_CDR(lst);
  }
  tmpArr = (modelica_metatype *) malloc(sizeof(modelica_metatype)*(ix)); /* We know the size of the first part of the list (+1 for the element to delete) */
  if (tmpArr == NULL) {
    fprintf(stderr, "%s:%d: malloc failed", __FILE__, __LINE__);
    EXIT(1);
  }
  for (i=0; i<ix; i++)
  {
    if (MMC_NILTEST(lst))
    {
      if (tmpArr)
        free(tmpArr);
      MMC_THROW();
    }
    tmpArr[i] = MMC_CAR(lst);
    lst = MMC_CDR(lst);
  }
  if (listEmpty(lst)) {
    free(tmpArr);
    MMC_THROW();
  }

  mmc_GC_add_roots(tmpArr, ix, 0, "");

  lst = MMC_CDR(lst);
  for (i=ix-1; i>=0; i--)
  {
    lst = mmc_mk_cons(tmpArr[i], lst);
  }
  free(tmpArr);

  return lst;
}

/* Array Operations */
modelica_integer arrayLength(modelica_metatype arr)
{
  return MMC_HDRSLOTS(MMC_GETHDR(arr));
}

modelica_metatype arrayGet(modelica_metatype arr, modelica_integer ix)
{
  if (ix < 1)
    MMC_THROW();
  if((unsigned)ix-1 >= MMC_HDRSLOTS(MMC_GETHDR(arr)))
    MMC_THROW();
  return MMC_STRUCTDATA(arr)[ix-1];
}

modelica_metatype boxptr_arrayGet(modelica_metatype a, modelica_metatype i)
{
  return arrayGet(a,MMC_UNTAGFIXNUM(i));
}

modelica_metatype arrayCreate(modelica_integer nelts, modelica_metatype val)
{
  mmc_GC_add_roots(&val, 1, 0, "");

  {
  void* arr = (struct mmc_struct*)mmc_mk_box_no_assign(nelts, MMC_ARRAY_TAG);
  void **arrp = MMC_STRUCTDATA(arr);
  int i = 0;
  for(i=0; i<nelts; i++)
    arrp[i] = val;
  return arr;
  }
}

modelica_metatype arrayList(modelica_metatype arr)
{
  int nelts = MMC_HDRSLOTS(MMC_GETHDR(arr))-1;
  void **vecp = MMC_STRUCTDATA(arr);
  void *res = mmc_mk_nil();

  mmc_GC_add_roots(&arr, 1, 0, "");
  mmc_GC_add_roots(&res, 1, 0, "");

  for(; nelts >= 0; --nelts)
    res = mmc_mk_cons(vecp[nelts],res);
  return res;
}

modelica_metatype listArray(modelica_metatype lst)
{
  mmc_GC_add_roots(&lst, 1, 0, "");
  {
  int nelts = listLength(lst);
  void* arr = (struct mmc_struct*)mmc_mk_box_no_assign(nelts, MMC_ARRAY_TAG);
  void **arrp = MMC_STRUCTDATA(arr);
  int i = 0;
  for(i=0; i<nelts; i++) {
    arrp[i] = MMC_CAR(lst);
    lst = MMC_CDR(lst);
  }
  return arr;
  }
}

modelica_metatype arrayUpdate(modelica_metatype arr, modelica_integer ix, modelica_metatype val)
{
  int nelts = MMC_HDRSLOTS(MMC_GETHDR(arr));
  if (ix < 1 || ix > nelts)
    MMC_THROW();
  MMC_STRUCTDATA(arr)[ix-1] = val;
#if defined(_MMC_GC_)
  /* save it in the array trail! */
  if (!MMC_IS_IMMEDIATE(val))
  {
    mmc_uint_t idx;
    /* also check here if the array is not already in the trail */
    for (idx = mmc_GC_state->gen.array_trail_size; &mmc_GC_state->gen.array_trail[idx] >= mmc_GC_state->gen.ATP; idx--)
    if (mmc_GC_state->gen.array_trail[idx] == val) /* if found, do not add again */
    {
      return arr;
    }
    /* add the address of the array into the roots to be
    taken into consideration at the garbage collection time */
    if( mmc_GC_state->gen.ATP == mmc_GC_state->gen.array_trail )
    {
      (void)fprintf(stderr, "Array Trail Overflow!\n");
      mmc_exit(1);
    }
    *--mmc_GC_state->gen.ATP = arr;
  }
#endif
  return arr;
}

modelica_metatype boxptr_arrayUpdate(modelica_metatype arr, modelica_integer ix, modelica_metatype val)
{
  return arrayUpdate(arr,MMC_UNTAGFIXNUM(ix),val);
}

modelica_metatype arrayCopy(modelica_metatype arr)
{
  mmc_GC_add_roots(&arr, 1, 0, "");
  {
  int nelts = MMC_HDRSLOTS(MMC_GETHDR(arr));
  void* res = (struct mmc_struct*)mmc_mk_box_no_assign(nelts, MMC_ARRAY_TAG);
  void **arrp = MMC_STRUCTDATA(arr);
  void **resp = MMC_STRUCTDATA(res);
  int i = 0;
  for(i=0; i<nelts; i++) {
    resp[i] = arrp[i];
  }
  return res;
  }
}

modelica_metatype arrayAdd(modelica_metatype arr, modelica_metatype val)
{
  mmc_GC_add_roots(&arr, 1, 0, "");
  mmc_GC_add_roots(&val, 1, 0, "");
  {
  int nelts = MMC_HDRSLOTS(MMC_GETHDR(arr));
  void* res = (struct mmc_struct*)mmc_mk_box_no_assign(nelts+1, MMC_ARRAY_TAG);
  void **arrp = MMC_STRUCTDATA(arr);
  void **resp = MMC_STRUCTDATA(res);
  int i = 0;
  for(i=0; i<nelts; i++) {
    resp[i] = arrp[i];
  }
  resp[nelts] = val;
  return res;
  }
}

modelica_metatype boxptr_arrayNth(modelica_metatype arr,modelica_metatype ix)
{
  return arrayGet(arr, mmc_unbox_integer(ix)+1);
}

/* Misc Operations */
modelica_integer tick(void)
{
  static modelica_integer curTick = 0;
  return curTick++;
}

void print(modelica_metatype str)
{
  fprintf(stdout, "%s", MMC_STRINGDATA(str));
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

void equality(modelica_metatype in1, modelica_metatype in2)
{
  if (!valueEq(in1, in2)) {
    /* fprintf(stderr, "%s != %s\n", anyString(in1), anyString(in2)); */
    MMC_THROW();
  }
}

void fail()
{
  MMC_THROW();
}

modelica_metatype getGlobalRoot(int ix) {
  if (!mmc_GC_state->global_roots[ix])
    MMC_THROW();
  return mmc_GC_state->global_roots[ix];
}

void setGlobalRoot(int ix, modelica_metatype val) {
  mmc_GC_state->global_roots[ix] = val;
}

modelica_metatype boxptr_getGlobalRoot(modelica_metatype ix) {
  return mmc_GC_state->global_roots[MMC_UNTAGFIXNUM(ix)];
}

void boxptr_setGlobalRoot(modelica_metatype ix, modelica_metatype val) {
  mmc_GC_state->global_roots[MMC_UNTAGFIXNUM(ix)] = val;
}

modelica_metatype boxptr_valueConstructor(modelica_metatype val) {
  return mmc_mk_icon(valueConstructor(val));
}

modelica_metatype boxptr_listFirst(modelica_metatype lst)
{
  return MMC_CAR(lst);
}

modelica_metatype boxptr_listRest(modelica_metatype lst)
{
  return MMC_CDR(lst);
}

modelica_real realMaxLit(void)
{
  return DBL_MAX / 2048; /* in case some non-linear or ODE solver tries to add eps to this value */
}

modelica_integer intMaxLit(void)
{
  return INT_MAX / 2;
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
