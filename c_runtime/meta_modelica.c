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

#include "modelica.h"

const struct mmc_header mmc_prim_nil = { MMC_NILHDR };

union mmc_double_as_words {
    double d;
    mmc_uint_t data[2];
};

void *mmc_alloc_bytes(unsigned nbytes)
{
  void *p;
  if( (p = malloc(nbytes)) == 0 ) {
    fprintf(stderr, "malloc(%u) failed: %s\n", nbytes, strerror(errno));
    exit(1);
  }
  return p;
}

void *mmc_alloc_words(unsigned nwords)
{
  return mmc_alloc_bytes(nwords * sizeof(void*));
}

void mmc_prim_set_real(struct mmc_real *p, double d)
{
  union mmc_double_as_words u;
  u.d = d;
  p->data[0] = u.data[0];
  p->data[1] = u.data[1];
}

double mmc_prim_get_real(void *p)
{
    union mmc_double_as_words u;
    u.data[0] = MMC_REALDATA(p)[0];
    u.data[1] = MMC_REALDATA(p)[1];
    return u.d;
}


void *mmc_mk_nil(void)
{
    return MMC_TAGPTR(&mmc_prim_nil);
}

void *mmc_mk_cons(void *car, void *cdr)
{
    return mmc_mk_box2(1, car, cdr);
}

mmc_mk_icon_rettype mmc_mk_icon(int i)
{
    return MMC_IMMEDIATE(MMC_TAGFIXNUM((mmc_sint_t)i));
}

mmc_mk_rcon_rettype mmc_mk_rcon(double d)
{
    struct mmc_real *p = mmc_alloc_words(MMC_SIZE_DBL/MMC_SIZE_INT + 1);
    mmc_prim_set_real(p, d);
    p->header = MMC_REALHDR;
    return MMC_TAGPTR(p);
}

mmc_mk_scon_rettype mmc_mk_scon(char *s)
{
    unsigned nbytes = strlen(s);
    unsigned header = MMC_STRINGHDR(nbytes);
    unsigned nwords = MMC_HDRSLOTS(header) + 1;
    struct mmc_string *p = mmc_alloc_words(nwords);
    p->header = header;
    memcpy(p->data, s, nbytes+1);	/* including terminating '\0' */
    return MMC_TAGPTR(p);
}

void *mmc_mk_none(void)
{
    static struct mmc_header none = { MMC_STRUCTHDR(0, 1 /* 0 is the empty list */) };
    return MMC_TAGPTR(&none);
}

void *mmc_mk_some(void *x)
{
    return mmc_mk_box1(1, x);
}

void *mmc_mk_box0(unsigned ctor)
{
    struct mmc_struct *p = mmc_alloc_words(1);
    p->header = MMC_STRUCTHDR(0, ctor);
    return MMC_TAGPTR(p);
}

void *mmc_mk_box1(unsigned ctor, void *x0)
{
    struct mmc_struct *p = mmc_alloc_words(2);
    p->header = MMC_STRUCTHDR(1, ctor);
    p->data[0] = x0;
    return MMC_TAGPTR(p);
}

void *mmc_mk_box2(unsigned ctor, void *x0, void *x1)
{
    struct mmc_struct *p = mmc_alloc_words(3);
    p->header = MMC_STRUCTHDR(2, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    return MMC_TAGPTR(p);
}

void *mmc_mk_box3(unsigned ctor, void *x0, void *x1, void *x2)
{
    struct mmc_struct *p = mmc_alloc_words(4);
    p->header = MMC_STRUCTHDR(3, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    return MMC_TAGPTR(p);
}

void *mmc_mk_box4(unsigned ctor, void *x0, void *x1, void *x2, void *x3)
{
    struct mmc_struct *p = mmc_alloc_words(5);
    p->header = MMC_STRUCTHDR(4, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    return MMC_TAGPTR(p);
}

void *mmc_mk_box5(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4)
{
    struct mmc_struct *p = mmc_alloc_words(6);
    p->header = MMC_STRUCTHDR(5, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    p->data[4] = x4;
    return MMC_TAGPTR(p);
}

void *mmc_mk_box6(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
	      void *x5)
{
    struct mmc_struct *p = mmc_alloc_words(7);
    p->header = MMC_STRUCTHDR(6, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    p->data[4] = x4;
    p->data[5] = x5;
    return MMC_TAGPTR(p);
}

void *mmc_mk_box7(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
	      void *x5, void *x6)
{
    struct mmc_struct *p = mmc_alloc_words(8);
    p->header = MMC_STRUCTHDR(7, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    p->data[4] = x4;
    p->data[5] = x5;
    p->data[6] = x6;
    return MMC_TAGPTR(p);
}

void *mmc_mk_box8(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
	      void *x5, void *x6, void *x7)
{
    struct mmc_struct *p = mmc_alloc_words(9);
    p->header = MMC_STRUCTHDR(8, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    p->data[4] = x4;
    p->data[5] = x5;
    p->data[6] = x6;
    p->data[7] = x7;
    return MMC_TAGPTR(p);
}

void *mmc_mk_box9(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
	      void *x5, void *x6, void *x7, void *x8)
{
    struct mmc_struct *p = mmc_alloc_words(10);
    p->header = MMC_STRUCTHDR(9, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    p->data[4] = x4;
    p->data[5] = x5;
    p->data[6] = x6;
    p->data[7] = x7;
    p->data[8] = x8;
    return MMC_TAGPTR(p);
}

void *mmc_mk_box(int slots, unsigned ctor, ...)
{
    int i;
    va_list argp;
    struct mmc_struct *p = mmc_alloc_words(slots+1);
    p->header = MMC_STRUCTHDR(slots, ctor);
    va_start(argp, ctor);
    for (i=0; i<slots; i++) {
      p->data[i] = va_arg(argp, void*);
    }
    va_end(argp);
    return MMC_TAGPTR(p);
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

  if ((0 == ((mmc_sint_t)lhs & 1)) && (0 == ((mmc_sint_t)rhs & 1))) {
    return lhs == rhs;
  }
  
  h_lhs = MMC_GETHDR(lhs);
  h_rhs = MMC_GETHDR(rhs);

  if (h_lhs == MMC_NILHDR && h_rhs == MMC_NILHDR) {
    return 1;
  }

  if (h_lhs == MMC_REALHDR) {
    return mmc_prim_get_real(MMC_REALDATA(lhs)) == mmc_prim_get_real(MMC_REALDATA(rhs));;
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
      if (0 == mmc_boxes_equal(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(lhs),i+1)),MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(rhs),i+1))))
        return 0;
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
  exit(1);
}

mmc__uniontype__metarecord__typedef__equal_rettype
mmc__uniontype__metarecord__typedef__equal(void* ut,int ex_ctor,int fieldNums,modelica_string pathString)
{
  mmc_uint_t hdr;
  int numslots;
  unsigned ctor;
  struct record_description* desc;
  mmc__uniontype__metarecord__typedef__equal_rettype res;

  hdr = MMC_GETHDR(ut);
  numslots = MMC_HDRSLOTS(hdr);
  ctor = 255 & (hdr >> 2);

  if (numslots == fieldNums+1 && ctor == ex_ctor+3) { /* RECORD */
    desc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(ut),1));
    res = 0 == strcmp(pathString,desc->name);
    return res;
  } else {
    return 0;
  }
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
    fprintf(stderr, "%d", (int) ((mmc_sint_t)any)>>1);
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
    fprintf(stderr, "meta_array(");
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
  exit(1);
}

