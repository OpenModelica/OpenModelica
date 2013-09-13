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

/* File: meta_modelica.h
 * Description: This is the C header file for the C code generated from
 * Modelica. It includes e.g. the C object representation of the builtin types
 * and arrays, etc.
 */

#ifndef META_MODELICA_H_
#define META_MODELICA_H_

#if defined(__cplusplus)
extern "C" {
#endif

#include "openmodelica.h"
#include "mmc_gc.h"
#include "meta_modelica_string_lit.h"
#include "meta_modelica_builtin.h"
#include "meta_modelica_segv.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>


/*
 *
 * adrpo: define this to have mmk_mk_* function tracing
 * #define MMC_MK_DEBUG
 *
 */

#if 0 /* Enable if you need to debug some MMC runtime assertions */
#define MMC_DEBUG_ASSERT(x) assert(x)
#else
#define MMC_DEBUG_ASSERT(x)
#endif
#define MMC_CHECK_STRING(x) MMC_DEBUG_ASSERT(!((MMC_STRLEN(x) != strlen(MMC_STRINGDATA(x))) && (MMC_STRLEN(x) >=0)))


#define MMC_SIZE_META sizeof(modelica_metatype)
#define MMC_WORDS_TO_BYTES(x) ((x) * MMC_SIZE_META)

/*
 * a slot is a word on any platform!
 * the maximum slots in a free slot is
 * - 2^(32-10) + 1 (header) on 32 bit systems
 * - 2^(64-10) + 1 (header) on 64 bit systems
 */
#ifdef _LP64
#define MMC_MAX_SLOTS (18014398509481984) /* max words slots header */
#else
#define MMC_MAX_SLOTS (4194304)           /* max words slots header */
#endif

/* max object size on 32/64 bit systems in bytes */
#define MMC_MAX_OBJECT_SIZE_BYTES MMC_WORDS_TO_BYTES(MMC_MAX_SLOTS)

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

/* adrpo: circumvent MinGW GCC 4.4.0 bugs with optimization */
#if defined(__MINGW32__)
#define GCC_VERSION (__GNUC__ * 10000 \
                               + __GNUC_MINOR__ * 100 \
                               + __GNUC_PATCHLEVEL__)

/* Test for MinGW GCC = 4.4.0 */
#if (GCC_VERSION == 40400)

typedef float mmc_switch_type;
#define MMC_SWITCH_CAST(X) ((int)X)

#else /* not MinGW GCC 4.4.0 */

typedef int mmc_switch_type;
#define MMC_SWITCH_CAST(X) (X)

#endif

#else /* not MINGW */

typedef int mmc_switch_type;
#define MMC_SWITCH_CAST(X) (X)

#endif

#define MMC_TAGPTR(p)             ((void*)((char*)(p) + 3))
#define MMC_UNTAGPTR(x)           ((void*)((char*)(x) - 3))
#define MMC_STRUCTHDR(slots,ctor) (((slots) << 10) + (((ctor) & 255) << 2))
#define MMC_NILHDR                MMC_STRUCTHDR(0,0)
#define MMC_CONSHDR               MMC_STRUCTHDR(2,1)
#define MMC_NONEHDR               MMC_STRUCTHDR(0,1)
#define MMC_OFFSET(p,i)           ((void*)((void**)(p) + (i)))
#define MMC_FETCH(p)              (*(void**)(p))
#define MMC_CAR(X)                MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(X),1))
#define MMC_CDR(X)                MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(X),2))
#define MMC_NILTEST(x)            (MMC_GETHDR(x) == MMC_NILHDR)
#define MMC_IMMEDIATE(i)          ((void*)(i))
#define MMC_IS_IMMEDIATE(x)       (!((mmc_uint_t)(x) & 1))
#define MMC_TAGFIXNUM(i)          ((i) << 1)
#define MMC_UNTAGFIXNUM(X)        (((mmc_sint_t) X) >> 1)
#define MMC_REALHDR               (((MMC_SIZE_DBL/MMC_SIZE_INT) << 10) + 9)
#define MMC_HDR_IS_FORWARD(hdr)   (((hdr) & 3) == 3)
/*
#define MMC_REALDATA(x) (*((double*)(((mmc_uint_t*)MMC_UNTAGPTR(x))+1)))
*/
#define MMC_REALDATA(x)           (((struct mmc_real*)MMC_UNTAGPTR(x))->data)

#define MMC_GETHDR(x)             (*(mmc_uint_t*)MMC_UNTAGPTR(x))

#define MMC_STRINGHDR(nbytes)     ((((mmc_uint_t)nbytes)<<(3))+((1<<(3+MMC_LOG2_SIZE_INT))+5))
#define MMC_HDRISSTRING(hdr)      (((hdr) & (7)) == 5)
#define MMC_HDRSTRLEN(hdr)        (((hdr) >> (3)) - MMC_SIZE_INT)
#define MMC_STRINGDATA(x)         (((struct mmc_string*)MMC_UNTAGPTR(x))->data)
#define MMC_HDRSTRINGSLOTS(hdr)   (hdr >> (3+MMC_LOG2_SIZE_INT))

#define MMC_HDRSLOTS(hdr)         ((MMC_HDRISSTRING(hdr)) ? (MMC_HDRSTRINGSLOTS(hdr)) : ((hdr) >> 10))
#define MMC_HDRCTOR(hdr)          (((hdr) >> 2) & 255)
#define MMC_HDRISSTRUCT(hdr)      (!((hdr) & 3))
#define MMC_STRUCTDATA(x)         (((struct mmc_struct*)MMC_UNTAGPTR(x))->data)

#define MMC_ARRAY_TAG             255
#define MMC_STRLEN(x)             (MMC_HDRSTRLEN(MMC_GETHDR(x)))
#define MMC_OPTIONNONE(x)         (0==MMC_HDRSLOTS(MMC_GETHDR(x)) ? 1 : 0)

/*
 * adrpo: if a structure has pointers
 * Bit 0 is zero if the node contains pointers, 1 otherwise.
 */
#define MMC_HDRHASPTRS(hdr)       (!((hdr) & 1))
/*
 * adrpo: if this object was marked, used by GC!
 * [xxxxxxxx1x]        (used during garbage collection) a marked node;
 */
#define MMC_HDRISMARKED(hdr)      ((hdr) &  2)
#define MMC_HDR_MARK(hdr)         ((hdr) |  2)
#define MMC_HDR_UNMARK(hdr)       ((hdr) & ~((mmc_uint_t)2))


#define MMC_INT_MAX ((1<<30)-1)
#define MMC_INT_MIN (-(1<<30))

#define MMC_DEFSTRUCTLIT(NAME,LEN,CON)  \
    struct { \
      mmc_uint_t header; \
      const void *data[LEN]; \
    } NAME = { MMC_STRUCTHDR(LEN,CON),
#define MMC_DEFSTRUCT0LIT(NAME,CON) struct mmc_header NAME = { MMC_STRUCTHDR(0,CON) }
#define MMC_REFSTRUCTLIT(NAME) MMC_TAGPTR(&(NAME).header)

#define MMC_DEFSTRINGLIT(NAME,LEN,VAL)  \
    struct {        \
      mmc_uint_t header;    \
      const char data[LEN+1];    \
    } NAME = { MMC_STRINGHDR(LEN), VAL }
#define MMC_REFSTRINGLIT(NAME) MMC_TAGPTR(&(NAME).header)

/* adrpo: assume MMC_DBL_PAD always! */
struct mmc_real_lit { /* there must be no padding between `header' and `data' */
    mmc_uint_t filler;
    mmc_uint_t header;
    double data;
};
#define MMC_DEFREALLIT(NAME,VAL) struct mmc_real_lit NAME = {0,MMC_REALHDR,VAL}
#define MMC_REFREALLIT(NAME) MMC_TAGPTR(&(NAME).header)

struct mmc_header {
    mmc_uint_t header;
};

struct mmc_struct {
    mmc_uint_t header;  /* MMC_STRUCTHDR(slots,ctor) */
    void *data[1];  /* `slots' elements */
};

struct mmc_cons_struct {
    mmc_uint_t header;  /* MMC_STRUCTHDR(slots,ctor) */
    void *data[2];  /* `slots' elements */
};

/* adrpo: assume MMC_DBL_STRICT always! */
struct mmc_real {
    mmc_uint_t header;  /* MMC_REALHDR */
    mmc_uint_t data[MMC_SIZE_DBL/MMC_SIZE_INT];
};

struct mmc_string {
    mmc_uint_t header;  /* MMC_STRINGHDR(bytes) */
    char data[1];  /* `bytes' elements + terminating '\0' */
};

#define MMC_FALSE (mmc_mk_icon(0))
#define MMC_TRUE (mmc_mk_icon(1))
#define mmc_mk_bcon(X) ((X) != 0 ? MMC_TRUE : MMC_FALSE)

static inline void* mmc_mk_icon(mmc_sint_t i)
{
    return MMC_IMMEDIATE(MMC_TAGFIXNUM(i));
}

void* mmc_mk_rcon(double d);

union mmc_double_as_words {
    double d;
    mmc_uint_t data[2];
};
static inline double mmc_prim_get_real(void *p)
{
  union mmc_double_as_words u;
  mmc_uint_t *data = &(MMC_REALDATA(p)[0]);

  u.data[0] = *data;
  u.data[1] = *(data + 1);
  return u.d;
}

static inline void mmc_prim_set_real(struct mmc_real *p, double d)
{
  union mmc_double_as_words u;
  mmc_uint_t *data;
  u.d = d;

  data = &(p->data[0]);
  *data = u.data[0];
  *(data + 1) = u.data[1];
}

static inline void* mmc_mk_scon(const char *s)
{
    unsigned nbytes = strlen(s);
    unsigned header = MMC_STRINGHDR(nbytes);
    unsigned nwords = MMC_HDRSLOTS(header) + 1;
    struct mmc_string *p;
    void *res;
    if (nbytes == 0) return mmc_emptystring;
    if (nbytes == 1) {
      unsigned char c = *s;
      return mmc_strings_len1[(unsigned int)c];
    }
    p = (struct mmc_string *) mmc_alloc_words(nwords);
    p->header = header;
    memcpy(p->data, s, nbytes+1);  /* including terminating '\0' */
    res = MMC_TAGPTR(p);
    MMC_CHECK_STRING(res);
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "STRING slots: %u size: %d str: %s\n", MMC_HDRSLOTS(header), strlen(s), s); fflush(NULL);
#endif
    return res;
}

static inline void* mmc_mk_scon_len(unsigned nbytes)
{
    unsigned header = MMC_STRINGHDR(nbytes);
    unsigned nwords = MMC_HDRSLOTS(header) + 1;
    struct mmc_string *p;
    void *res;
    p = (struct mmc_string *) mmc_alloc_words(nwords);
    p->header = header;
    res = MMC_TAGPTR(p);
    return res;
}

char* mmc_mk_scon_len_ret_ptr(size_t nbytes);

static inline void *mmc_mk_box0(unsigned ctor)
{
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(1);
    p->header = MMC_STRUCTHDR(0, ctor);
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "BOX0 %u\n", ctor); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
}

static inline void *mmc_mk_box1(unsigned ctor, void *x0)
{
  mmc_GC_add_roots(&x0, 1, 0, "");
  {
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(2);
    p->header = MMC_STRUCTHDR(1, ctor);
    p->data[0] = (void*) x0;
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "BOX1 %u\n", ctor); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
  }
}

void printAny(void* any);

static inline void *mmc_mk_box2(unsigned ctor, void *x0, void *x1)
{
  mmc_GC_add_roots(&x0, 1, 0, "");
  mmc_GC_add_roots(&x1, 1, 0, "");

  {
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(3);
    void **data = p->data;
    p->header = MMC_STRUCTHDR(2, ctor);
    data[0] = (void*) x0;
    data[1] = (void*) x1;
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "BOX2 %u\n", ctor); fflush(NULL);
    /* printAny(MMC_TAGPTR(p)); fprintf(stderr, "\n"); fflush(NULL); */
#endif
    return MMC_TAGPTR(p);
  }
}

static inline void *mmc_mk_box3(unsigned ctor, void *x0, void *x1, void *x2)
{
  mmc_GC_add_roots(&x0, 1, 0, "");
  mmc_GC_add_roots(&x1, 1, 0, "");
  mmc_GC_add_roots(&x2, 1, 0, "");

  {

    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(4);
    void **data = p->data;
    p->header = MMC_STRUCTHDR(3, ctor);
    data[0] = (void*) x0;
    data[1] = (void*) x1;
    data[2] = (void*) x2;
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "BOX3 %u\n", ctor); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
  }
}

static inline void *mmc_mk_box4(unsigned ctor, void *x0, void *x1, void *x2, void *x3)
{
  mmc_GC_add_roots(&x0, 1, 0, "");
  mmc_GC_add_roots(&x1, 1, 0, "");
  mmc_GC_add_roots(&x2, 1, 0, "");
  mmc_GC_add_roots(&x3, 1, 0, "");

  {
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(5);
    void **data = p->data;
    p->header = MMC_STRUCTHDR(4, ctor);
    data[0] = (void*) x0;
    data[1] = (void*) x1;
    data[2] = (void*) x2;
    data[3] = (void*) x3;
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "BOX4 %u\n", ctor); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
  }
}

static inline void *mmc_mk_box5(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4)
{
  mmc_GC_add_roots(&x0, 1, 0, "");
  mmc_GC_add_roots(&x1, 1, 0, "");
  mmc_GC_add_roots(&x2, 1, 0, "");
  mmc_GC_add_roots(&x3, 1, 0, "");
  mmc_GC_add_roots(&x4, 1, 0, "");

  {
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(6);
    void **data = p->data;
    p->header = MMC_STRUCTHDR(5, ctor);
    data[0] = (void*) x0;
    data[1] = (void*) x1;
    data[2] = (void*) x2;
    data[3] = (void*) x3;
    data[4] = (void*) x4;
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "BOX5 %u\n", ctor); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
  }
}

static inline void *mmc_mk_box6(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4, void *x5)
{
  mmc_GC_add_roots(&x0, 1, 0, "");
  mmc_GC_add_roots(&x1, 1, 0, "");
  mmc_GC_add_roots(&x2, 1, 0, "");
  mmc_GC_add_roots(&x3, 1, 0, "");
  mmc_GC_add_roots(&x4, 1, 0, "");
  mmc_GC_add_roots(&x5, 1, 0, "");

  {
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(7);
    void **data = p->data;
    p->header = MMC_STRUCTHDR(6, ctor);
    data[0] = (void*) x0;
    data[1] = (void*) x1;
    data[2] = (void*) x2;
    data[3] = (void*) x3;
    data[4] = (void*) x4;
    data[5] = (void*) x5;
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "BOX6 %u\n", ctor); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
  }
}

static inline void *mmc_mk_box7(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4, void *x5, void *x6)
{
  mmc_GC_add_roots(&x0, 1, 0, "");
  mmc_GC_add_roots(&x1, 1, 0, "");
  mmc_GC_add_roots(&x2, 1, 0, "");
  mmc_GC_add_roots(&x3, 1, 0, "");
  mmc_GC_add_roots(&x4, 1, 0, "");
  mmc_GC_add_roots(&x5, 1, 0, "");
  mmc_GC_add_roots(&x6, 1, 0, "");

  {
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(8);
    void **data = p->data;
    p->header = MMC_STRUCTHDR(7, ctor);
    data[0] = (void*) x0;
    data[1] = (void*) x1;
    data[2] = (void*) x2;
    data[3] = (void*) x3;
    data[4] = (void*) x4;
    data[5] = (void*) x5;
    data[6] = (void*) x6;
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "BOX7 %u\n", ctor); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
  }
}

static inline void *mmc_mk_box8(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4, void *x5, void *x6, void *x7)
{
  mmc_GC_add_roots(&x0, 1, 0, "");
  mmc_GC_add_roots(&x1, 1, 0, "");
  mmc_GC_add_roots(&x2, 1, 0, "");
  mmc_GC_add_roots(&x3, 1, 0, "");
  mmc_GC_add_roots(&x4, 1, 0, "");
  mmc_GC_add_roots(&x5, 1, 0, "");
  mmc_GC_add_roots(&x6, 1, 0, "");
  mmc_GC_add_roots(&x7, 1, 0, "");

  {
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(9);
    void **data = p->data;
    p->header = MMC_STRUCTHDR(8, ctor);
    data[0] = (void*) x0;
    data[1] = (void*) x1;
    data[2] = (void*) x2;
    data[3] = (void*) x3;
    data[4] = (void*) x4;
    data[5] = (void*) x5;
    data[6] = (void*) x6;
    data[7] = (void*) x7;
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "BOX8 %u\n", ctor); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
  }
}

static inline void *mmc_mk_box9(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4, void *x5, void *x6, void *x7, void *x8)
{
  mmc_GC_add_roots(&x0, 1, 0, "");
  mmc_GC_add_roots(&x1, 1, 0, "");
  mmc_GC_add_roots(&x2, 1, 0, "");
  mmc_GC_add_roots(&x3, 1, 0, "");
  mmc_GC_add_roots(&x4, 1, 0, "");
  mmc_GC_add_roots(&x5, 1, 0, "");
  mmc_GC_add_roots(&x6, 1, 0, "");
  mmc_GC_add_roots(&x7, 1, 0, "");
  mmc_GC_add_roots(&x8, 1, 0, "");

  {
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(10);
    void **data = p->data;
    p->header = MMC_STRUCTHDR(9, ctor);
    data[0] = (void*) x0;
    data[1] = (void*) x1;
    data[2] = (void*) x2;
    data[3] = (void*) x3;
    data[4] = (void*) x4;
    data[5] = (void*) x5;
    data[6] = (void*) x6;
    data[7] = (void*) x7;
    data[8] = (void*) x8;
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "BOX9 %u\n", ctor); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
  }
}

static inline void *mmc_mk_box(int slots, unsigned ctor, ...)
{
    int i;
    va_list argp;

    /* adrpo: how do I add the va_list args to the roots??!!  */
#if defined(_MSC_VER)
    va_start(argp, ctor);
    for (i=0; i<slots; i++) {
      mmc_GC_add_roots(&(va_arg(argp, void*)), 1, 0, "");
    }
    va_end(argp);
#endif

    {
    struct mmc_struct *p = (struct mmc_struct *) mmc_alloc_words(slots+1);
    p->header = MMC_STRUCTHDR(slots, ctor);
    va_start(argp, ctor);
    for (i=0; i<slots; i++) {
      p->data[i] = va_arg(argp, void*);
    }
    va_end(argp);
#ifdef MMC_MK_DEBUG
    fprintf(stderr, "BOXNN slots:%d ctor: %u\n", slots, ctor); fflush(NULL);
#endif
    return MMC_TAGPTR(p);
    }
}

static const MMC_DEFSTRUCT0LIT(mmc_nil,0);
static const MMC_DEFSTRUCT0LIT(mmc_none,1);

#define mmc_mk_nil() MMC_REFSTRUCTLIT(mmc_nil)
#define mmc_mk_none() MMC_REFSTRUCTLIT(mmc_none)

#define MMC_CONS_CTOR 1

static inline void *mmc_mk_cons(void *car, void *cdr)
{
    return mmc_mk_box2(MMC_CONS_CTOR, car, cdr);
}

static inline void *mmc_mk_some(void *x)
{
    return mmc_mk_box1(1, x);
}

extern void *mmc_mk_box_arr(int slots, unsigned ctor, void** args);
extern void *mmc_mk_box_no_assign(int slots, unsigned ctor);

extern modelica_boolean valueEq(modelica_metatype lhs,modelica_metatype rhs);
extern modelica_metatype boxptr_valueEq(modelica_metatype lhs,modelica_metatype rhs);

extern modelica_integer valueHashMod(modelica_metatype p,modelica_integer mod);
extern void* boxptr_valueHashMod(void *p, void *mod);

extern void mmc__unbox(modelica_metatype box, void* res);

#define mmc__uniontype__metarecord__typedef__equal(UT,CTOR,NFIELDS) (MMC_GETHDR(UT)==MMC_STRUCTHDR(NFIELDS+1,CTOR+3))

extern void debug__print(void*prefix,void*any); /* For debugging */
extern void initializeStringBuffer(void);
extern char* anyString(void*any); /* For debugging in external functions */
extern void* mmc_anyString(void*any); /* For debugging */
extern void printAny(void*any); /* For debugging */
extern void printTypeOfAny(void*any); /* For debugging */
extern char* getTypeOfAny(void*any); /* For debugging */
extern char* getRecordElementName(void*any, int element); /* For debugging */
extern int isOptionNone(void*any); /* For debugging */
extern void changeStdStreamBuffer(void); /* For debugging */

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
#define mmc_mk_integer mmc_mk_icon
#define mmc_mk_boolean mmc_mk_bcon
#define mmc_mk_real mmc_mk_rcon

#define mmc_unbox_boolean(X) MMC_UNTAGFIXNUM(X)
#define mmc_unbox_integer(X) MMC_UNTAGFIXNUM(X)
#define mmc_unbox_real(X) mmc_prim_get_real(X)
#define mmc_unbox_string(X) MMC_STRINGDATA(X)
#define mmc_unbox_array(X) (*((base_array_t*)X))

#include <setjmp.h>
#include <pthread.h>

void mmc_catch_dummy_fn();

extern pthread_key_t mmc_jumper;
extern pthread_once_t mmc_init_once;
extern void mmc_init();
#define MMC_INIT() pthread_once(&mmc_init_once,mmc_init)
#define MMC_TRY_INTERNAL(X) { jmp_buf new_mmc_jumper, *old_jumper; old_jumper = (jmp_buf*)pthread_getspecific(X); pthread_setspecific(X,&new_mmc_jumper); if (setjmp(new_mmc_jumper) == 0) {
#define MMC_TRY() MMC_TRY_INTERNAL(mmc_jumper)

#if !defined(_MSC_VER)
#define MMC_CATCH_INTERNAL(X) } pthread_setspecific(X,old_jumper);mmc_catch_dummy_fn();}
#else
#define MMC_CATCH_INTERNAL(X) } pthread_setspecific(X,old_jumper);}
#endif
#define MMC_CATCH() MMC_CATCH_INTERNAL(mmc_jumper)

#define MMC_THROW() {longjmp(*((jmp_buf*)pthread_getspecific(mmc_jumper)),1);}
#define MMC_ELSE() } else {

#define MMC_TRY_TOP() MMC_TRY()
#define MMC_CATCH_TOP(X) pthread_setspecific(mmc_jumper,old_jumper);} else {pthread_setspecific(mmc_jumper,old_jumper);X;}}

#if defined(__cplusplus)
}
#endif

#endif
