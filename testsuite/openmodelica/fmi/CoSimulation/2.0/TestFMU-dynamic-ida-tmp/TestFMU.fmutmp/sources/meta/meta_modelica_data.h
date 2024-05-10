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

/* File: meta_modelica_data.h
 * Description: This is the C header file for the definitions of the
 * MetaModelicaC data types.
 */

#ifndef META_MODELICA_DATA_H_
#define META_MODELICA_DATA_H_

#include "../util/omc_init.h"
#include "../util/base_array.h"

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


#define MMC_SIZE_META sizeof(void*)
#define MMC_WORDS_TO_BYTES(x) ((x) * MMC_SIZE_META)

/*
 * a slot is a word on any platform!
 * the maximum slots in a free slot is
 * - 2^(32-10) + 1 (header) on 32 bit systems
 * - 2^(64-10) + 1 (header) on 64 bit systems
 */
#if defined(_LP64) || defined(_LLP64) || defined(_WIN64) || defined(__MINGW64__)
#define MMC_MAX_SLOTS (18014398509481984) /* max words slots header */
#else
#define MMC_MAX_SLOTS (4194304)           /* max words slots header */
#endif

/* max object size on 32/64 bit systems in bytes */
#define MMC_MAX_OBJECT_SIZE_BYTES MMC_WORDS_TO_BYTES(MMC_MAX_SLOTS)

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

#define RML_STYLE_TAGPTR

#ifdef RML_STYLE_TAGPTR

/* RML-style tagged pointers */
#define MMC_TAGPTR(p)             ((void*)((char*)(p) + 3))
#define MMC_UNTAGPTR(x)           ((void*)((char*)(x) - 3))
#define MMC_IS_INTEGER(X)         (0 == ((mmc_sint_t) (X) & 1))
#define MMC_TAGFIXNUM(i)          ((((mmc_uint_t) (i)) << 1)+0)
#define MMC_UNTAGFIXNUM(X)        (((mmc_sint_t) (X)) >> 1)

#else

#define MMC_TAGPTR(p)             ((void*)((char*)(p) + 0))
#define MMC_UNTAGPTR(x)           ((void*)((char*)(x) - 0))
#define MMC_IS_INTEGER(X)         (1 == ((mmc_sint_t) (X) & 1))
#define MMC_TAGFIXNUM(i)          ((((mmc_uint_t) (i)) << 1)+1)
#define MMC_UNTAGFIXNUM(X)        (((mmc_sint_t) ((X)-1)) >> 1)

#endif

#define MMC_STRUCTHDR(_slots,ctor) (((_slots) << 10) + (((ctor) & 255) << 2))
#define MMC_NILHDR                MMC_STRUCTHDR(0,0)
#define MMC_CONSHDR               MMC_STRUCTHDR(2,1)
#define MMC_NONEHDR               MMC_STRUCTHDR(0,1)
#define MMC_OFFSET(p,i)           ((void*)((void**)(p) + (i)))
#define MMC_FETCH(p)              (*(void**)(p))
#define MMC_CAR(X)                MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(X),1))
#define MMC_CDR(X)                MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(X),2))
#define MMC_NILTEST(x)            (MMC_GETHDR(x) == MMC_NILHDR)
#define MMC_IMMEDIATE(i)          ((void*)(i))
#define MMC_IS_IMMEDIATE(x)       (MMC_IS_INTEGER(x))
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
#define MMC_HDRSTRINGSLOTS(hdr)   ((hdr) >> (3+MMC_LOG2_SIZE_INT))

#define MMC_HDRSLOTS(hdr)         ((MMC_HDRISSTRING(hdr)) ? (MMC_HDRSTRINGSLOTS(hdr)) : ((hdr) >> 10))
#define MMC_HDRCTOR(hdr)          (((hdr) >> 2) & 255)
#define MMC_HDRISSTRUCT(hdr)      (!((hdr) & 3))
#define MMC_STRUCTDATA(x)         (((struct mmc_struct*)MMC_UNTAGPTR(x))->data)

#define MMC_ARRAY_TAG             255
#define MMC_STRLEN(x)             (MMC_HDRSTRLEN(MMC_GETHDR(x)))
#define MMC_OPTIONNONE(x)         (0==MMC_HDRSLOTS(MMC_GETHDR(x)) ? 1 : 0)
#define MMC_OPTIONSOME(x)         (0==MMC_HDRSLOTS(MMC_GETHDR(x)) ? 0 : 1)

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
      const char data[(LEN)+1];    \
    } NAME = { MMC_STRINGHDR(LEN), VAL }
#define MMC_REFSTRINGLIT(NAME) MMC_TAGPTR(&(NAME).header)

/* Unboxing */
#define mmc_unbox_boolean(X) MMC_UNTAGFIXNUM(X)
#define mmc_unbox_integer(X) MMC_UNTAGFIXNUM(X)
#define mmc_unbox_real(X) mmc_prim_get_real(X)
#define mmc_unbox_string(X) MMC_STRINGDATA(X)
#define mmc_unbox_array(X) (*((base_array_t*)X))

#define mmc_mk_integer mmc_mk_icon
#define mmc_mk_boolean mmc_mk_bcon
#define mmc_mk_real mmc_mk_rcon

void mmc_catch_dummy_fn();

#define MMC_INIT(X) pthread_once(&mmc_init_once,mmc_init)
#define MMC_TRY_INTERNAL(X) { jmp_buf new_mmc_jumper, *old_jumper __attribute__((unused)) = threadData->X; threadData->X = &new_mmc_jumper; if (setjmp(new_mmc_jumper) == 0) {
#define MMC_TRY() { threadData_t *threadData = pthread_getspecific(mmc_thread_data_key); MMC_TRY_INTERNAL(mmc_jumper)

#if !defined(_MSC_VER)
#define MMC_CATCH_INTERNAL(X) } threadData->X = old_jumper;mmc_catch_dummy_fn();}
#else
#define MMC_CATCH_INTERNAL(X) } threadData->X = old_jumper;}
#endif
#define MMC_CATCH() MMC_CATCH_INTERNAL(mmc_jumper)}
#define MMC_RESTORE_INTERNAL(X) threadData->X = old_jumper;

#define MMC_THROW_INTERNAL() {longjmp(*threadData->mmc_jumper,1);}
#define MMC_THROW() {longjmp(*((threadData_t*)pthread_getspecific(mmc_thread_data_key))->mmc_jumper,1);}
#define MMC_ELSE() } else { threadData->mmc_jumper = old_jumper;

#define MMC_TRY_TOP() { threadData_t threadDataOnStack = {0}, *oldThreadData = (threadData_t*)pthread_getspecific(mmc_thread_data_key),*threadData = &threadDataOnStack; pthread_setspecific(mmc_thread_data_key,threadData); pthread_mutex_init(&threadData->parentMutex,NULL); mmc_init_stackoverflow_fast(threadData, oldThreadData); MMC_TRY_INTERNAL(mmc_jumper) threadData->mmc_stack_overflow_jumper = threadData->mmc_jumper; /* Let the default stack overflow handler be the top-level handler */

#define MMC_TRY_TOP_SET(X) { threadData_t threadDataOnStack = *((threadData_t*)X), *oldThreadData = (threadData_t*)pthread_getspecific(mmc_thread_data_key),*threadData = &threadDataOnStack; pthread_setspecific(mmc_thread_data_key,threadData); pthread_mutex_init(&threadData->parentMutex,NULL); mmc_init_stackoverflow_fast(threadData, oldThreadData); MMC_TRY_INTERNAL(mmc_jumper) threadData->mmc_stack_overflow_jumper = threadData->mmc_jumper; /* Let the default stack overflow handler be the top-level handler */

#define MMC_TRY_TOP_INTERNAL() { threadData_t *oldThreadData = (threadData_t*)pthread_getspecific(mmc_thread_data_key); pthread_setspecific(mmc_thread_data_key,threadData); pthread_mutex_init(&threadData->parentMutex,NULL); mmc_init_stackoverflow_fast(threadData, oldThreadData); MMC_TRY_INTERNAL(mmc_jumper) threadData->mmc_stack_overflow_jumper = threadData->mmc_jumper;
#define MMC_CATCH_TOP(X) pthread_setspecific(mmc_thread_data_key,oldThreadData); } else {pthread_setspecific(mmc_thread_data_key,oldThreadData);X;}}}

/* use this to allocate and initialize threadData */
#define MMC_ALLOC_AND_INIT_THREADDATA(_omc_threadData) { size_t len = sizeof(threadData_t); _omc_threadData = (threadData_t*)GC_malloc_uncollectable(len); memset(_omc_threadData, 0, len); pthread_setspecific(mmc_thread_data_key, _omc_threadData); pthread_mutex_init(&_omc_threadData->parentMutex,NULL); mmc_init_stackoverflow(_omc_threadData); }

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

#endif /* META_MODELICA_DATA_H_*/
