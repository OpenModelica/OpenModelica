/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


#include "modelica.h"

jmp_buf *mmc_jumper;

const struct mmc_header mmc_prim_nil = { MMC_NILHDR };

union mmc_double_as_words {
    double d;
    mmc_uint_t data[MMC_SIZE_DBL/MMC_SIZE_INT];
};

void mmc_prim_set_real(struct mmc_real *p, double d)
{
  union mmc_double_as_words u;
  u.d = d;
  p->data[0] = u.data[0];
  if (MMC_SIZE_DBL/MMC_SIZE_INT > 1)
    p->data[1] = u.data[1];
}

mmc_mk_rcon_rettype mmc_mk_rcon(double d)
{
    struct mmc_real *p = mmc_alloc_words(MMC_SIZE_DBL/MMC_SIZE_INT + 1);
    mmc_prim_set_real(p, d);
    p->header = MMC_REALHDR;
    return MMC_TAGPTR(p);
}

double mmc_prim_get_real(void *p)
{
    union mmc_double_as_words u;
    if ((0 == ((mmc_sint_t)p & 1))) return MMC_UNTAGFIXNUM(p);
    u.data[0] = MMC_REALDATA(p)[0];
    if (MMC_SIZE_DBL/MMC_SIZE_INT > 1)
      u.data[1] = MMC_REALDATA(p)[1];
    return u.d;
}

void *mmc_mk_box_arr(int slots, unsigned ctor, void** args)
{
    int i;
    struct mmc_struct *p = mmc_alloc_words(slots+1);
    p->header = MMC_STRUCTHDR(slots, ctor);
    for (i=0; i<slots; i++) {
      p->data[i] = args[i];
    }
    return MMC_TAGPTR(p);
}

void *mmc_mk_box_no_assign(int slots, unsigned ctor)
{
    struct mmc_struct *p = mmc_alloc_words(slots+1);
    p->header = MMC_STRUCTHDR(slots, ctor);
    return MMC_TAGPTR(p);
}

int mmc_boxes_equal(void* lhs, void* rhs)
{
  mmc_uint_t h_lhs;
  mmc_uint_t h_rhs;
  int numslots;
  unsigned ctor;
  int i;
  void *lhs_data, *rhs_data;
  struct record_description *lhs_desc,*rhs_desc;

  if (lhs == rhs) {
    return 1;
  }

  if ((0 == ((mmc_sint_t)lhs & 1)) && (0 == ((mmc_sint_t)rhs & 1))) {
    return lhs == rhs;
  }
  
  h_lhs = MMC_GETHDR(lhs);
  h_rhs = MMC_GETHDR(rhs);

  if (h_lhs == MMC_NILHDR && h_rhs == MMC_NILHDR) {
    return 1;
  }

  if (h_lhs == MMC_REALHDR) {
    double d1,d2;
    d1 = mmc_prim_get_real(lhs);
    d2 = mmc_prim_get_real(rhs);
    return d1 == d2;
  }
  if (MMC_HDRISSTRING(h_lhs))
    return 0 == strcmp(MMC_STRINGDATA(lhs),MMC_STRINGDATA(rhs));

  numslots = MMC_HDRSLOTS(h_lhs);
  ctor = 255 & (h_lhs >> 2);
  if (numslots != MMC_HDRSLOTS(h_rhs))
    return 0;
  if (ctor != (255 & (h_rhs >> 2)))
    return 0;
  
  if (numslots>0 && ctor > 1) { /* RECORD */
    lhs_desc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(lhs),1));
    rhs_desc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(rhs),1));
    if (0 != strcmp(lhs_desc->name,rhs_desc->name))
      return 0;
    for (i=2; i<=numslots; i++) {
      lhs_data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(lhs),i));
      rhs_data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(rhs),i));
      if (0 == mmc_boxes_equal(lhs_data,rhs_data))
        return 0;
    }
    return 1;
  }

  if (numslots>0 && ctor == 0) { /* TUPLE */
    for (i=0; i<numslots; i++) {
      void *tlhs, *trhs;
      tlhs = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(lhs),i+1));
      trhs = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(rhs),i+1));
      if (0 == mmc_boxes_equal(tlhs,trhs)) {
        return 0;
      }
    }
    return 1;
  }

  if (numslots==0 && ctor==1) /* NONE() */ {
    return 1;
  }

  if (numslots==1 && ctor==1) /* SOME(x) */ {
    return mmc_boxes_equal(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(lhs),1)),MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(rhs),1)));
  }

  if (numslots==2 && ctor==1) { /* CONS-PAIR */
    while (!MMC_NILTEST(lhs) && !MMC_NILTEST(rhs)) {
      if (!mmc_boxes_equal(MMC_CAR(lhs),MMC_CAR(rhs)))
        return 0;
      lhs = MMC_CDR(lhs);
      rhs = MMC_CDR(rhs);
    }
    return MMC_NILTEST(lhs) == MMC_NILTEST(rhs);
  }

  fprintf(stderr, "%s:%d: %d slots; ctor %d - FAILED to detect the type\n", __FILE__, __LINE__, numslots, ctor);
  EXIT(1);
}

/*
mmc__uniontype__metarecord__typedef__equal_rettype
mmc__uniontype__metarecord__typedef__equal(void* ut,int ex_ctor,int fieldNums)
{
  mmc_uint_t hdr;
  int numslots;
  unsigned ctor;
  struct record_description* desc;

  hdr = MMC_GETHDR(ut);
  numslots = MMC_HDRSLOTS(hdr);
  ctor = 255 & (hdr >> 2);

  if (numslots == fieldNums+1 && ctor == ex_ctor+3) { // RECORD
    desc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(ut),1));
    return 1;
  } else {
    return 0;
  }
}
*/

void debug__print(const char* prefix, void* any)
{
  fprintf(stderr, "%s", prefix);
  printAny(any);
}

void printAny(void* any) /* For debugging */
{
  mmc_uint_t hdr;
  int numslots;
  unsigned ctor;
  int i;
  void *data;
  struct record_description *desc;

  if ((0 == ((mmc_sint_t)any & 1))) {
    fprintf(stderr, "%ld", (long) ((mmc_sint_t)any)>>1);
    return;
  }
  
  hdr = MMC_GETHDR(any);

  if (hdr == MMC_NILHDR) {
    fprintf(stderr, "{}");
    return;
  }

  if (hdr == MMC_REALHDR) {
    fprintf(stderr, "%.7g", (double) mmc_prim_get_real(any));
    return;
  }
  if (MMC_HDRISSTRING(hdr)) {
    fprintf(stderr, "\"%s\"", MMC_STRINGDATA(any));
    return;
  }

  numslots = MMC_HDRSLOTS(hdr);
  ctor = 255 & (hdr >> 2);
  
  if (numslots>0 && ctor == MMC_ARRAY_TAG) { /* MetaModelica-style array */
    fprintf(stderr, "MetaArray(");
    for (i=1; i<=numslots; i++) {
      data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),i));
      printAny(data);
      if (i!=numslots)
        fprintf(stderr, ", ");
    }
    fprintf(stderr, ")");
    return;
  }
  if (numslots>0 && ctor > 1) { /* RECORD */
    desc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),1));
    fprintf(stderr, "%s(", desc->name);
    for (i=2; i<=numslots; i++) {
      data = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),i));
      fprintf(stderr, "%s = ", desc->fieldNames[i-2]);
      printAny(data);
      if (i!=numslots)
        fprintf(stderr, ", ");
    }
    fprintf(stderr, ")");
    return;
  }

  if (numslots>0 && ctor == 0) { /* TUPLE */
    fprintf(stderr, "(");
    for (i=0; i<numslots; i++) {
      printAny(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),i+1)));
      if (i!=numslots-1)
        fprintf(stderr, ", ");
    }
    fprintf(stderr, ")");
    return;
  }

  if (numslots==0 && ctor==1) /* NONE() */ {
    fprintf(stderr, "NONE()");
    return;
  }

  if (numslots==1 && ctor==1) /* SOME(x) */ {
    fprintf(stderr, "SOME(");
    printAny(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),1)));
    fprintf(stderr, ")");
    return;
  }

  if (numslots==2 && ctor==1) { /* CONS-PAIR */
    fprintf(stderr, "{");
    printAny(MMC_CAR(any));
    any = MMC_CDR(any);
    while (!MMC_NILTEST(any)) {
      fprintf(stderr, ", ");
      printAny(MMC_CAR(any));
      any = MMC_CDR(any);
    }
    fprintf(stderr, "}");
    return;
  }

  fprintf(stderr, "%s:%d: %d slots; ctor %d - FAILED to detect the type\n", __FILE__, __LINE__, numslots, ctor);
  EXIT(1);
}

void printTypeOfAny(void* any) /* for debugging */
{
  mmc_uint_t hdr;
  int numslots;
  unsigned ctor;
  int i;
  void *data;
  struct record_description *desc;

  if ((0 == ((mmc_sint_t)any & 1))) {
    fprintf(stderr, "Integer");
    return;
  }
  
  hdr = MMC_GETHDR(any);

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
  if (numslots>0 && ctor > 1) { /* RECORD */
    desc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),1));
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

  fprintf(stderr, "%s:%d: %d slots; ctor %d - FAILED to detect the type\n", __FILE__, __LINE__, numslots, ctor);
  EXIT(1);
}
