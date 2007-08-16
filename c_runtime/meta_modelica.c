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

#include "modelica.h"

struct mmc_header {
    mmc_uint_t header;
};

const struct mmc_header mmc_prim_nil = { MMC_NILHDR };


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

union mmc_double_as_words {
    double d;
    mmc_uint_t data[2];
};

void *alloc_bytes(unsigned nbytes)
{
    void *p;
    if( (p = malloc(nbytes)) == 0 ) {
	fprintf(stderr, "malloc(%u) failed: %s\n", nbytes, strerror(errno));
	exit(1);
    }
    return p;
}

void *alloc_words(unsigned nwords)
{
    return alloc_bytes(nwords * sizeof(void*));
}

void mmc_prim_set_real(struct mmc_real *p, double d)
{
    union mmc_double_as_words u;
    u.d = d;
    p->data[0] = u.data[0];
    p->data[1] = u.data[1];
}

void *mmc_mk_nil(void)
{
    return MMC_TAGPTR(&mmc_prim_nil);
}

void *mmc_mk_cons(void *car, void *cdr)
{
    return mmc_mk_box2(1, car, cdr);
}

void *mmc_mk_box2(unsigned ctor, void *x0, void *x1)
{
    struct mmc_struct *p = alloc_words(3);
    p->header = MMC_STRUCTHDR(2, ctor);
    p->data[0] = x0;
    p->data[1] = x1;
    return MMC_TAGPTR(p);
}

void *mmc_mk_icon(int i)
{
    return MMC_IMMEDIATE(MMC_TAGFIXNUM((mmc_sint_t)i));
}

void *mmc_mk_rcon(double d)
{
    struct mmc_real *p = alloc_words(MMC_SIZE_DBL/MMC_SIZE_INT + 1);
    mmc_prim_set_real(p, d);
    p->header = MMC_REALHDR;
    return MMC_TAGPTR(p);
}

void *mmc_mk_scon(char *s)
{
    unsigned nbytes = strlen(s);
    unsigned header = MMC_STRINGHDR(nbytes);
    unsigned nwords = MMC_HDRSLOTS(header) + 1;
    struct mmc_string *p = alloc_words(nwords);
    p->header = header;
    memcpy(p->data, s, nbytes+1);	/* including terminating '\0' */
    return MMC_TAGPTR(p);
}
