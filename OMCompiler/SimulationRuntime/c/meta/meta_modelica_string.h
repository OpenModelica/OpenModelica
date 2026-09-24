/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */


#ifndef META_MODELICA_STRING_H_
#define META_MODELICA_STRING_H_

/* The MetaModelica string: a tagged pointer to an mmc_header'd object. The
 * simulation's (util/omc_string.h) is counted and untagged. */

#include <string.h>
#include <stdarg.h>
#include "meta_modelica_data.h"
#include "meta_modelica_string_lit.h"

#if defined(__cplusplus)
extern "C" {
#endif

/* The string vocabulary generated code uses; both runtimes define these. */
#define omc_string_data(x) MMC_STRINGDATA(x)
#define omc_string_len(x)  MMC_STRLEN(x)
#define omc_string_new(s)          mmc_mk_scon(s)
#define omc_string_new_len(s,n)    mmc_mk_scon_n((s),(n))
#define omc_string_new_persist(s)  mmc_mk_scon_persist(s)
#define omc_string_alloc(n)        mmc_alloc_scon(n)
#define omc_string_empty           mmc_emptystring
#define omc_strings_len1           mmc_strings_len1
#define omc_string_uninitialized   mmc_string_uninitialized
#define omc_strings_boolString     mmc_strings_boolString
/* Collected, so a store is a plain assignment. */
#define omc_string_store(SLOT, S)  (*(SLOT) = (S))
#define omc_string_move(SLOT, S)   (*(SLOT) = (S))
#define omc_string_retain(S)       (S)
#define omc_string_release(S)      ((void)0)
/* Nothing was owned, so there is nothing to give up. */
#define omc_string_disown(S)       ((void)0)

extern void* stringAppend(void *s1, void *s2);
extern modelica_integer mmc_stringCompare(const void *str1, const void *str2);
#define stringCompare(x,y) mmc_stringCompare(x,y)
#define stringEqual(x,y) (MMC_STRLEN(x) == MMC_STRLEN(y) && !stringCompare(x,y))

#include "../util/omc_str_utils.h"

static inline void* mmc_alloc_scon(size_t nbytes)
{
    mmc_uint_t header = MMC_STRINGHDR(nbytes);
    mmc_uint_t nwords = MMC_HDRSLOTS(header) + 1;
    struct mmc_string *p;
    if (nbytes == 0) return mmc_emptystring;
    p = (struct mmc_string *) mmc_check_out_of_memory(omc_alloc_interface.malloc_atomic(nwords*sizeof(void*)));
    p->header = header;
    p->data[0] = 0;
    return MMC_TAGPTR(p);
}

static inline void* mmc_mk_scon_len(mmc_uint_t nbytes)
{
    mmc_uint_t header = MMC_STRINGHDR(nbytes);
    mmc_uint_t nwords = MMC_HDRSLOTS(header) + 1;
    struct mmc_string *p;
    p = (struct mmc_string *) mmc_check_out_of_memory(omc_alloc_interface.malloc_atomic(nwords*sizeof(void*)));
    p->header = header;
    return MMC_TAGPTR(p);
}

static inline void* mmc_mk_scon_n(const char *s, int length)
{
    size_t header = MMC_STRINGHDR(length);
    size_t nwords = MMC_HDRSLOTS(header) + 1;
    struct mmc_string *p;
    void *res;
    if (length == 0) return mmc_emptystring;
    if (length == 1) {
      unsigned char c = *s;
      return mmc_strings_len1[(unsigned int)c];
    }
    p = (struct mmc_string *) mmc_check_out_of_memory(omc_alloc_interface.malloc_atomic(nwords*sizeof(void*)));
    p->header = header;
    memcpy(p->data, s, length);
    p->data[length] = '\0';
    res = MMC_TAGPTR(p);
    MMC_CHECK_STRING(res);
    return res;
}

static inline void* mmc_mk_scon(const char *s)
{
    size_t nbytes = strlen(s);
    size_t header = MMC_STRINGHDR(nbytes);
    size_t nwords = MMC_HDRSLOTS(header) + 1;
    struct mmc_string *p;
    void *res;
    if (nbytes == 0) return mmc_emptystring;
    if (nbytes == 1) {
      unsigned char c = *s;
      return mmc_strings_len1[(unsigned int)c];
    }
    p = (struct mmc_string *) mmc_check_out_of_memory(omc_alloc_interface.malloc_atomic(nwords*sizeof(void*)));
    p->header = header;
    memcpy(p->data, s, nbytes+1);
    res = MMC_TAGPTR(p);
    MMC_CHECK_STRING(res);
    return res;
}

static inline void* mmc_mk_scon_persist(const char *s)
{
    size_t nbytes = strlen(s);
    size_t header = MMC_STRINGHDR(nbytes);
    size_t nwords = MMC_HDRSLOTS(header) + 1;
    struct mmc_string *p;
    void *res;
    if (nbytes == 0) return mmc_emptystring;
    if (nbytes == 1) {
      unsigned char c = *s;
      return mmc_strings_len1[(unsigned int)c];
    }
    p = (struct mmc_string *) mmc_check_out_of_memory(omc_alloc_interface.malloc_string_persist(nwords*sizeof(void*)));
    p->header = header;
    memcpy(p->data, s, nbytes+1);
    res = MMC_TAGPTR(p);
    MMC_CHECK_STRING(res);
    return res;
}

#if defined(__cplusplus)
} /* end extern "C" */
#endif

#endif /* META_MODELICA_STRING_H_ */
