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

#define MMC_SIZE_DBL 8
#define MMC_SIZE_INT 4
#define MMC_LOG2_SIZE_INT 2
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
#define MMC_REALHDR		(((MMC_SIZE_DBL/MMC_SIZE_INT) << 10) + 9)
#define MMC_STRINGHDR(nbytes)	(((nbytes)<<(10-MMC_LOG2_SIZE_INT))+((1<<10)+5))
#define MMC_HDRSLOTS(hdr)	((hdr) >> 10)
#define MMC_GETHDR(x)		(*(mmc_uint_t*)MMC_UNTAGPTR(x))

typedef unsigned int mmc_uint_t;
typedef int mmc_sint_t;

extern void *mmc_mk_nil(void);
extern void *mmc_mk_cons(void *car, void *cdr);
extern void *mmc_mk_box2(unsigned ctor, void *x0, void *x1);
extern void *mmc_mk_icon(int i);
extern void *mmc_mk_rcon(double d);
extern void *mmc_mk_scon(char *s);

#if defined(__cplusplus)
}
#endif

#endif
