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

/* File: meta_modelica.h
 * Description: This is the C header file for the C code generated from
 * Modelica. It includes e.g. the C object representation of the builtin types
 * and arrays, etc.
 */

#ifndef META_MODELICA_H_
#define META_MODELICA_H_

#include "modelica.h"

#if defined(__cplusplus)
extern "C" {
#endif

#ifdef _LP64
#define MMC_SIZE_DBL 8
#define MMC_SIZE_INT 8
#define MMC_LOG2_SIZE_INT 3
typedef unsigned long mmc_uint_t;
typedef long mmc_sint_t;
#else
#define MMC_SIZE_DBL 8
#define MMC_SIZE_INT 4
#define MMC_LOG2_SIZE_INT 2
typedef unsigned int mmc_uint_t;
typedef int mmc_sint_t;
#endif

#define MMC_TAGPTR(p)		((void*)((char*)(p) + 3))
#define MMC_UNTAGPTR(x)		((void*)((char*)(x) - 3))
#define MMC_STRUCTHDR(slots,ctor) (((slots) << 10) + (((ctor) & 255) << 2))
#define MMC_NILHDR		MMC_STRUCTHDR(0,0)
#define MMC_CONSHDR		MMC_STRUCTHDR(2,1)
#define MMC_OFFSET(p,i)		((void*)((void**)(p) + (i)))
#define MMC_FETCH(p)		(*(void**)(p))
#define MMC_CAR(X)	MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(X),1))
#define MMC_CDR(X)	MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(X),2))
#define MMC_NILTEST(x)  (MMC_GETHDR(x) == MMC_NILHDR)
#define MMC_IMMEDIATE(i)	((void*)(i))
#define MMC_TAGFIXNUM(i)	((i) << 1)
#define MMC_UNTAGFIXNUM(X)	(((mmc_sint_t) X) >> 1)
#define MMC_REALHDR		(((MMC_SIZE_DBL/MMC_SIZE_INT) << 10) + 9)
#define MMC_REALDATA(x) (((struct mmc_real*)MMC_UNTAGPTR(x))->data)
#define MMC_STRINGHDR(nbytes)	(((nbytes)<<(10-MMC_LOG2_SIZE_INT))+((1<<10)+5))
#define MMC_HDRSLOTS(hdr)	((hdr) >> 10)
#define MMC_GETHDR(x)		(*(mmc_uint_t*)MMC_UNTAGPTR(x))
#define MMC_HDRCTOR(hdr) (((hdr) >> 2) & 255)
#define MMC_HDRISSTRING(hdr)	(((hdr) & ((1<<(10-MMC_LOG2_SIZE_INT))-1)) == 5)
#define MMC_HDRSTRLEN(hdr)	(((hdr) >> (10-MMC_LOG2_SIZE_INT)) - MMC_SIZE_INT)
#define MMC_STRINGDATA(x) (((struct mmc_string*)MMC_UNTAGPTR(x))->data)
#define MMC_STRUCTDATA(x) (((struct mmc_struct*)MMC_UNTAGPTR(x))->data)
#define MMC_ARRAY_TAG 255

#define MMC_INT_MAX ((1<<30)-1)
#define MMC_INT_MIN (-(1<<30))

struct mmc_header {
    mmc_uint_t header;
};

struct mmc_struct {
    mmc_uint_t header;	/* MMC_STRUCTHDR(slots,ctor) */
    void *data[1];	/* `slots' elements */
};

struct mmc_real {
    mmc_uint_t header;	/* MMC_REALHDR */
    mmc_uint_t data[MMC_SIZE_DBL/MMC_SIZE_INT];
};

struct mmc_string {
    mmc_uint_t header;	/* MMC_STRINGHDR(bytes) */
    char data[1];	/* `bytes' elements + terminating '\0' */
};

#define mmc__mk__bcon_rettype mmc_mk_bcon_rettype
#define mmc__mk__bcon(X) mmc_mk_bcon(X)
#define mmc__mk__icon_rettype mmc_mk_icon_rettype
#define mmc__mk__icon(X) mmc_mk_icon(X)
#define mmc__mk__rcon_rettype mmc_mk_rcon_rettype
#define mmc__mk__rcon(X) mmc_mk_rcon(X)
#define mmc__mk__scon_rettype mmc_mk_scon_rettype
#define mmc__mk__scon(X) mmc_mk_scon(X)
#define mmc__mk__acon_rettype mmc_mk_acon_rettype
#define mmc__mk__acon(X) (&(X))

typedef modelica_metatype mmc_mk_bcon_rettype;
typedef modelica_metatype mmc_mk_icon_rettype;
typedef modelica_metatype mmc_mk_rcon_rettype;
typedef modelica_metatype mmc_mk_scon_rettype;
typedef modelica_metatype mmc_mk_acon_rettype;

static void *mmc_alloc_bytes(unsigned nbytes)
{
  void *p;
  if( (p = malloc(nbytes)) == 0 ) {
    fprintf(stderr, "malloc(%u) failed: %s\n", nbytes, strerror(errno));
    EXIT(1);
  }
  return p;
}

static void *mmc_alloc_words(unsigned nwords)
{
  return mmc_alloc_bytes(nwords * sizeof(void*));
}

#define MMC_FALSE (mmc_mk_icon(0))
#define MMC_TRUE (mmc_mk_icon(1))
#define mmc_mk_bcon(X) (X != 0 ? MMC_TRUE : MMC_FALSE)

static inline mmc_mk_icon_rettype mmc_mk_icon(int i)
{
    return MMC_IMMEDIATE(MMC_TAGFIXNUM((mmc_sint_t)i));
}

mmc_mk_rcon_rettype mmc_mk_rcon(double d);

static inline mmc_mk_scon_rettype mmc_mk_scon(const char *s)
{
    unsigned nbytes = strlen(s);
    unsigned header = MMC_STRINGHDR(nbytes);
    unsigned nwords = MMC_HDRSLOTS(header) + 1;
    struct mmc_string *p = (struct mmc_string *) mmc_alloc_words(nwords);
    p->header = header;
    memcpy(p->data, s, nbytes+1);	/* including terminating '\0' */
    return MMC_TAGPTR(p);
}

static inline void *mmc_mk_box0(unsigned ctor)
{
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(1);
    p->header = MMC_STRUCTHDR(0, ctor);
    return MMC_TAGPTR(p);
}

static inline void *mmc_mk_box1(unsigned ctor, void *x0)
{
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(2);
    p->header = MMC_STRUCTHDR(1, ctor);
    p->data[0] = x0;
    return MMC_TAGPTR(p);
}

static inline void *mmc_mk_box2(unsigned ctor, void *x0, void *x1)
{
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(3);
    p->header = MMC_STRUCTHDR(2, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    return MMC_TAGPTR(p);
}

static inline void *mmc_mk_box3(unsigned ctor, void *x0, void *x1, void *x2)
{
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(4);
    p->header = MMC_STRUCTHDR(3, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    return MMC_TAGPTR(p);
}

static inline void *mmc_mk_box4(unsigned ctor, void *x0, void *x1, void *x2, void *x3)
{
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(5);
    p->header = MMC_STRUCTHDR(4, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    return MMC_TAGPTR(p);
}

static inline void *mmc_mk_box5(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4)
{
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(6);
    p->header = MMC_STRUCTHDR(5, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    p->data[4] = x4;
    return MMC_TAGPTR(p);
}

static inline void *mmc_mk_box6(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
	      void *x5)
{
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(7);
    p->header = MMC_STRUCTHDR(6, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    p->data[4] = x4;
    p->data[5] = x5;
    return MMC_TAGPTR(p);
}

static inline void *mmc_mk_box7(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
	      void *x5, void *x6)
{
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(8);
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

static inline void *mmc_mk_box8(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
	      void *x5, void *x6, void *x7)
{
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(9);
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

static inline void *mmc_mk_box9(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
	      void *x5, void *x6, void *x7, void *x8)
{
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(10);
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

static inline void *mmc_mk_box(int slots, unsigned ctor, ...)
{
    int i;
    va_list argp;
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(slots+1);
    p->header = MMC_STRUCTHDR(slots, ctor);
    va_start(argp, ctor);
    for (i=0; i<slots; i++) {
      p->data[i] = va_arg(argp, void*);
    }
    va_end(argp);
    return MMC_TAGPTR(p);
}

extern const struct mmc_header mmc_prim_nil;

static inline void *mmc_mk_nil(void)
{
    return MMC_TAGPTR(&mmc_prim_nil);
}

static inline void *mmc_mk_cons(void *car, void *cdr)
{
    return mmc_mk_box2(1, car, cdr);
}

static inline void *mmc_mk_none(void)
{
    static struct mmc_header none = { MMC_STRUCTHDR(0, 1 /* 0 is the empty list */) };
    return MMC_TAGPTR(&none);
}

static inline void *mmc_mk_some(void *x)
{
    return mmc_mk_box1(1, x);
}

void *mmc_mk_box_arr(int slots, unsigned ctor, void** args);
void *mmc_mk_box_no_assign(int slots, unsigned ctor);

int mmc_boxes_equal(void*, void*);
void mmc__unbox(modelica_metatype box, void* res);

typedef modelica_boolean mmc__uniontype__metarecord__typedef__equal_rettype;
#define mmc__uniontype__metarecord__typedef__equal(UT,CTOR,NFIELDS) (MMC_GETHDR(UT)==MMC_STRUCTHDR(NFIELDS+1,CTOR+3))
/* mmc__uniontype__metarecord__typedef__equal_rettype mmc__uniontype__metarecord__typedef__equal(void*,int,int); */

void debug__print(const char*,void*); /* For debugging */
void printAny(void*); /* For debugging */
void printTypeOfAny(void*); /* For debugging */

/*
 * Generated (Meta)Records should access a static, constant value of 
 * the record_description structure. This means the additional cost
 * of including the description is 1 word of memory and O(1) time.
 * When sending structures between the compiler and generated files,
 * the descriptions will be duplicated, and cost additional memory
 * for each and every Values.Value copied. /sjoelund 2009-05-20
 */
struct record_description {
  const char* path; /* package_record__X */
  const char* name; /* package.record_X */
  const char** fieldNames;
};

/* Unboxing */
typedef modelica_integer  mmc__unbox__integer_rettype;
typedef modelica_real     mmc__unbox__real_rettype;
typedef modelica_string_t mmc__unbox__string_rettype;
typedef base_array_t      mmc__unbox__array_rettype;

modelica_real mmc_prim_get_real(void *p);

#define mmc__unbox__integer(X) MMC_UNTAGFIXNUM(X)
#define mmc__unbox__real(X) mmc_prim_get_real(X)
#define mmc__unbox__string(X) MMC_STRINGDATA(X)
#define mmc__unbox__array(X) (*((base_array_t*)X))

#include <setjmp.h>

#if 1
/* Use something like this if needed...
#define MMC_JMP_BUF_SIZE 8192
extern jmp_buf mmc_jumper[MMC_JMP_BUF_SIZE];
extern int jmp_buf_index;
*/
extern jmp_buf *mmc_jumper;
#define MMC_TRY() {jmp_buf new_mmc_jumper, *old_jumper; old_jumper = mmc_jumper; mmc_jumper = &new_mmc_jumper; if (setjmp(new_mmc_jumper) == 0) {
#define MMC_CATCH() } mmc_jumper = old_jumper;}
#define MMC_THROW() longjmp(*mmc_jumper,1)

#define MMC_TRY_TOP() MMC_TRY()
#define MMC_CATCH_TOP(X) mmc_jumper = old_jumper;} else {mmc_jumper = old_jumper;X;}}

#else
/* Old C++ try/catch/throw implementation */
#define MMC_TRY() try {
#define MMC_CATCH() } catch (...) {}
#define MMC_THROW() throw 1

#define MMC_TRY_TOP() try{
#define MMC_CATCH_TOP(X) } catch (...) {X;}

#endif

#if defined(__cplusplus)
}
#endif

#endif
