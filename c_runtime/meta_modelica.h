/*
Copyright (c) 1998-2007, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
