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

/* yacclib.c */
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "rml.h"
#include "yacclib.h"

void *alloc_bytes(unsigned nbytes)
{
    void *p;
    if( (p = malloc(nbytes)) == 0 ) {
    	fprintf(stderr, "yacclib.c: malloc(%u) failed: %s\n", nbytes, strerror(errno));
    	exit(1);
    }
    return p;
}

void *alloc_words(unsigned nwords)
{
    return alloc_bytes(nwords * sizeof(void*));
}

void print_icon(FILE *fp, void *icon)
{
    fprintf(fp, "%d", RML_UNTAGFIXNUM(icon));
}

void print_rcon(FILE *fp, void *rcon)
{
    fprintf(fp, "%.15g", rml_prim_get_real(rcon));
}

void print_scon(FILE *fp, void *scon)
{
    fprintf(fp, "%.*s", RML_HDRSTRLEN(RML_GETHDR(scon)), RML_STRINGDATA(scon));
}

void *mk_icon(int i)
{
    return RML_IMMEDIATE(RML_TAGFIXNUM((rml_sint_t)i));
}

void *mk_rcon(double d)
{
    struct rml_real *p = alloc_words(RML_SIZE_DBL/RML_SIZE_INT + 1);
    rml_prim_set_real(p, d);
    p->header = RML_REALHDR;
    return RML_TAGPTR(p);
}

void *mk_scon(char *s)
{
    unsigned nbytes = strlen(s);
    unsigned header = RML_STRINGHDR(nbytes);
    unsigned nwords = RML_HDRSLOTS(header) + 1;
    struct rml_string *p = alloc_words(nwords);
    p->header = header;
    memcpy(p->data, s, nbytes+1);	/* including terminating '\0' */
    return RML_TAGPTR(p);
}

void *mk_nil(void)
{
    return RML_TAGPTR(&rml_prim_nil);
}

void *mk_cons(void *car, void *cdr)
{
    return mk_box2(1, car, cdr);
}

void *mk_none(void)
{
    static struct rml_header none = { RML_STRUCTHDR(0, 0) };
    return RML_TAGPTR(&none);
}

void *mk_some(void *x)
{
    return mk_box1(1, x);
}

void *mk_box0(unsigned ctor)
{
    struct rml_struct *p = alloc_words(1);
    p->header = RML_STRUCTHDR(0, ctor);
    return RML_TAGPTR(p);
}

void *mk_box1(unsigned ctor, void *x0)
{
    struct rml_struct *p = alloc_words(2);
    p->header = RML_STRUCTHDR(1, ctor);
    p->data[0] = x0;
    return RML_TAGPTR(p);
}

void *mk_box2(unsigned ctor, void *x0, void *x1)
{
    struct rml_struct *p = alloc_words(3);
    p->header = RML_STRUCTHDR(2, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    return RML_TAGPTR(p);
}

void *mk_box3(unsigned ctor, void *x0, void *x1, void *x2)
{
    struct rml_struct *p = alloc_words(4);
    p->header = RML_STRUCTHDR(3, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    return RML_TAGPTR(p);
}

void *mk_box4(unsigned ctor, void *x0, void *x1, void *x2, void *x3)
{
    struct rml_struct *p = alloc_words(5);
    p->header = RML_STRUCTHDR(4, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    return RML_TAGPTR(p);
}

void *mk_box5(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4)
{
    struct rml_struct *p = alloc_words(6);
    p->header = RML_STRUCTHDR(5, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    p->data[4] = x4;
    return RML_TAGPTR(p);
}

void *mk_box6(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
	      void *x5)
{
    struct rml_struct *p = alloc_words(7);
    p->header = RML_STRUCTHDR(6, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    p->data[4] = x4;
    p->data[5] = x5;
    return RML_TAGPTR(p);
}

void *mk_box7(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
	      void *x5, void *x6)
{
    struct rml_struct *p = alloc_words(8);
    p->header = RML_STRUCTHDR(7, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    p->data[4] = x4;
    p->data[5] = x5;
    p->data[6] = x6;
    return RML_TAGPTR(p);
}

void *mk_box8(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
	      void *x5, void *x6, void *x7)
{
    struct rml_struct *p = alloc_words(9);
    p->header = RML_STRUCTHDR(8, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    p->data[4] = x4;
    p->data[5] = x5;
    p->data[6] = x6;
    p->data[7] = x7;
    return RML_TAGPTR(p);
}

void *mk_box9(unsigned ctor, void *x0, void *x1, void *x2, void *x3, void *x4,
	      void *x5, void *x6, void *x7, void *x8)
{
    struct rml_struct *p = alloc_words(10);
    p->header = RML_STRUCTHDR(9, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    p->data[2] = x2;
    p->data[3] = x3;
    p->data[4] = x4;
    p->data[5] = x5;
    p->data[6] = x6;
    p->data[7] = x7;
    p->data[8] = x8;
    return RML_TAGPTR(p);
}
