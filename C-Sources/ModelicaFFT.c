/* ModelicaFFT.c - FFT functions

   Copyright (C) 2003-2010, Mark Borgerding
   Copyright (C) 2015, Modelica Association and DLR
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

   3. Neither the author nor the names of any contributors may be used to
      endorse or promote products derived from this software without specific
      prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
   FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
   CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
   OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/* Adapted to the needs of the Modelica Standard Library library:

   The functions in this file are non-portable. The following #define's are used
   to define the system calls of the operating system

   _MSC_VER       : Microsoft Visual C++
   MODELICA_EXPORT: Prefix used for function calls. If not defined, blank is used
                    Useful definitions:
                    - "static" that is all functions become static
                      (useful if file is included with other C-sources for an
                       embedded system)
                    - "__declspec(dllexport)" if included in a DLL and the
                      functions shall be visible outside of the DLL

   Release Notes:
      Dec. 02, 2015: by Martin Otter, DLR
                     Combined the C- and Header files of Kiss-FFT as needed for MSL
                     Adapted the memory allocation scheme so that for exponents of 2,3,5
                     memory has to be provided from the calling function
                     (for if length of vector is not a multiple of 2,3,5, the function
                     allocates additional memory, whenever it is called, and frees it before
                     the function is left)
*/

#ifndef MRKISS_FTR_H
#define MRKISS_FTR_H

#include <math.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

#if !defined(MODELICA_EXPORT)
#   define MODELICA_EXPORT
#endif

#define MRKISS_FFT_TMP_ALLOC malloc
#define MRKISS_FFT_TMP_FREE free

#define mrkiss_fft_scalar double
#define MAXFACTORS 32
/* e.g. an fft of length 128 has 4 factors
 as far as kissfft is concerned
 4*4*4*2
*/

typedef struct {
    mrkiss_fft_scalar r;
    mrkiss_fft_scalar i;
} mrkiss_fft_cpx;

struct mrkiss_fft_state {
    int nfft;
    int inverse;
    int factors[2*MAXFACTORS];
    mrkiss_fft_cpx *twiddles;     /* twiddles[nfft] */
};
typedef struct mrkiss_fft_state* mrkiss_fft_cfg;

struct mrkiss_fftr_state {
    mrkiss_fft_cfg substate;
    mrkiss_fft_cpx * tmpbuf;
    mrkiss_fft_cpx * super_twiddles;
};
typedef struct mrkiss_fftr_state* mrkiss_fftr_cfg;

/* include from _kiss_fft_guts.h ------------------------------------------ */

/*
  Explanation of macros dealing with complex math:

   C_MUL(m,a,b)         : m = a*b
   C_FIXDIV( c , div )  : if a fixed point impl., c /= div. noop otherwise
   C_SUB( res, a,b)     : res = a - b
   C_SUBFROM( res , a)  : res -= a
   C_ADDTO( res , a)    : res += a
 * */

#define S_MUL(a,b) ( (a)*(b) )
#define C_MUL(m,a,b) \
    do{ (m).r = (a).r*(b).r - (a).i*(b).i;\
        (m).i = (a).r*(b).i + (a).i*(b).r; }while(0)
#define C_FIXDIV(c,div) /* NOOP */
#define C_MULBYSCALAR( c, s ) \
    do{ (c).r *= (s);\
        (c).i *= (s); }while(0)

#ifndef CHECK_OVERFLOW_OP
#  define CHECK_OVERFLOW_OP(a,op,b) /* noop */
#endif

#define  C_ADD( res, a,b)\
    do { \
        CHECK_OVERFLOW_OP((a).r,+,(b).r)\
        CHECK_OVERFLOW_OP((a).i,+,(b).i)\
        (res).r=(a).r+(b).r;  (res).i=(a).i+(b).i; \
    }while(0)
#define  C_SUB( res, a,b)\
    do { \
        CHECK_OVERFLOW_OP((a).r,-,(b).r)\
        CHECK_OVERFLOW_OP((a).i,-,(b).i)\
        (res).r=(a).r-(b).r;  (res).i=(a).i-(b).i; \
    }while(0)
#define C_ADDTO( res , a)\
    do { \
        CHECK_OVERFLOW_OP((res).r,+,(a).r)\
        CHECK_OVERFLOW_OP((res).i,+,(a).i)\
        (res).r += (a).r;  (res).i += (a).i;\
    }while(0)

#define C_SUBFROM( res , a)\
    do {\
        CHECK_OVERFLOW_OP((res).r,-,(a).r)\
        CHECK_OVERFLOW_OP((res).i,-,(a).i)\
        (res).r -= (a).r;  (res).i -= (a).i; \
    }while(0)

#define MRKISS_FFT_COS(phase) (mrkiss_fft_scalar) cos(phase)
#define MRKISS_FFT_SIN(phase) (mrkiss_fft_scalar) sin(phase)
#define HALF_OF(x) ((x)*.5)

#define  kf_cexp(x,phase) \
    do{ \
        (x)->r = MRKISS_FFT_COS(phase);\
        (x)->i = MRKISS_FFT_SIN(phase);\
    }while(0)

/* end of include from _kiss_fft_guts.h ------------------------------------------ */

/* include of kiss_fft.c -------------------------------------------------------- */

static void kf_bfly2(
    mrkiss_fft_cpx * Fout,
    const size_t fstride,
    const mrkiss_fft_cfg st,
    int m
) {
    mrkiss_fft_cpx * Fout2;
    mrkiss_fft_cpx * tw1 = st->twiddles;
    mrkiss_fft_cpx t;
    Fout2 = Fout + m;
    do {
        C_FIXDIV(*Fout,2);
        C_FIXDIV(*Fout2,2);

        C_MUL (t,  *Fout2 , *tw1);
        tw1 += fstride;
        C_SUB( *Fout2 ,  *Fout , t );
        C_ADDTO( *Fout ,  t );
        ++Fout2;
        ++Fout;
    } while (--m);
}

static void kf_bfly4(
    mrkiss_fft_cpx * Fout,
    const size_t fstride,
    const mrkiss_fft_cfg st,
    const size_t m
) {
    mrkiss_fft_cpx *tw1,*tw2,*tw3;
    mrkiss_fft_cpx scratch[6];
    size_t k=m;
    const size_t m2=2*m;
    const size_t m3=3*m;

    tw3 = tw2 = tw1 = st->twiddles;

    do {
        C_FIXDIV(*Fout,4);
        C_FIXDIV(Fout[m],4);
        C_FIXDIV(Fout[m2],4);
        C_FIXDIV(Fout[m3],4);

        C_MUL(scratch[0],Fout[m] , *tw1 );
        C_MUL(scratch[1],Fout[m2] , *tw2 );
        C_MUL(scratch[2],Fout[m3] , *tw3 );

        C_SUB( scratch[5] , *Fout, scratch[1] );
        C_ADDTO(*Fout, scratch[1]);
        C_ADD( scratch[3] , scratch[0] , scratch[2] );
        C_SUB( scratch[4] , scratch[0] , scratch[2] );
        C_SUB( Fout[m2], *Fout, scratch[3] );
        tw1 += fstride;
        tw2 += fstride*2;
        tw3 += fstride*3;
        C_ADDTO( *Fout , scratch[3] );

        if(st->inverse) {
            Fout[m].r = scratch[5].r - scratch[4].i;
            Fout[m].i = scratch[5].i + scratch[4].r;
            Fout[m3].r = scratch[5].r + scratch[4].i;
            Fout[m3].i = scratch[5].i - scratch[4].r;
        } else {
            Fout[m].r = scratch[5].r + scratch[4].i;
            Fout[m].i = scratch[5].i - scratch[4].r;
            Fout[m3].r = scratch[5].r - scratch[4].i;
            Fout[m3].i = scratch[5].i + scratch[4].r;
        }
        ++Fout;
    } while(--k);
}

static void kf_bfly3(
    mrkiss_fft_cpx * Fout,
    const size_t fstride,
    const mrkiss_fft_cfg st,
    size_t m
) {
    size_t k=m;
    const size_t m2 = 2*m;
    mrkiss_fft_cpx *tw1,*tw2;
    mrkiss_fft_cpx scratch[5];
    mrkiss_fft_cpx epi3;
    epi3 = st->twiddles[fstride*m];

    tw1=tw2=st->twiddles;

    do {
        C_FIXDIV(*Fout,3);
        C_FIXDIV(Fout[m],3);
        C_FIXDIV(Fout[m2],3);

        C_MUL(scratch[1],Fout[m] , *tw1);
        C_MUL(scratch[2],Fout[m2] , *tw2);

        C_ADD(scratch[3],scratch[1],scratch[2]);
        C_SUB(scratch[0],scratch[1],scratch[2]);
        tw1 += fstride;
        tw2 += fstride*2;

        Fout[m].r = Fout->r - HALF_OF(scratch[3].r);
        Fout[m].i = Fout->i - HALF_OF(scratch[3].i);

        C_MULBYSCALAR( scratch[0] , epi3.i );

        C_ADDTO(*Fout,scratch[3]);

        Fout[m2].r = Fout[m].r + scratch[0].i;
        Fout[m2].i = Fout[m].i - scratch[0].r;

        Fout[m].r -= scratch[0].i;
        Fout[m].i += scratch[0].r;

        ++Fout;
    } while(--k);
}

static void kf_bfly5(
    mrkiss_fft_cpx * Fout,
    const size_t fstride,
    const mrkiss_fft_cfg st,
    int m
) {
    mrkiss_fft_cpx *Fout0,*Fout1,*Fout2,*Fout3,*Fout4;
    int u;
    mrkiss_fft_cpx scratch[13];
    mrkiss_fft_cpx * twiddles = st->twiddles;
    mrkiss_fft_cpx *tw;
    mrkiss_fft_cpx ya,yb;
    ya = twiddles[fstride*m];
    yb = twiddles[fstride*2*m];

    Fout0=Fout;
    Fout1=Fout0+m;
    Fout2=Fout0+2*m;
    Fout3=Fout0+3*m;
    Fout4=Fout0+4*m;

    tw=st->twiddles;
    for ( u=0; u<m; ++u ) {
        C_FIXDIV( *Fout0,5);
        C_FIXDIV( *Fout1,5);
        C_FIXDIV( *Fout2,5);
        C_FIXDIV( *Fout3,5);
        C_FIXDIV( *Fout4,5);
        scratch[0] = *Fout0;

        C_MUL(scratch[1] ,*Fout1, tw[u*fstride]);
        C_MUL(scratch[2] ,*Fout2, tw[2*u*fstride]);
        C_MUL(scratch[3] ,*Fout3, tw[3*u*fstride]);
        C_MUL(scratch[4] ,*Fout4, tw[4*u*fstride]);

        C_ADD( scratch[7],scratch[1],scratch[4]);
        C_SUB( scratch[10],scratch[1],scratch[4]);
        C_ADD( scratch[8],scratch[2],scratch[3]);
        C_SUB( scratch[9],scratch[2],scratch[3]);

        Fout0->r += scratch[7].r + scratch[8].r;
        Fout0->i += scratch[7].i + scratch[8].i;

        scratch[5].r = scratch[0].r + S_MUL(scratch[7].r,ya.r) + S_MUL(scratch[8].r,yb.r);
        scratch[5].i = scratch[0].i + S_MUL(scratch[7].i,ya.r) + S_MUL(scratch[8].i,yb.r);

        scratch[6].r =  S_MUL(scratch[10].i,ya.i) + S_MUL(scratch[9].i,yb.i);
        scratch[6].i = -S_MUL(scratch[10].r,ya.i) - S_MUL(scratch[9].r,yb.i);

        C_SUB(*Fout1,scratch[5],scratch[6]);
        C_ADD(*Fout4,scratch[5],scratch[6]);

        scratch[11].r = scratch[0].r + S_MUL(scratch[7].r,yb.r) + S_MUL(scratch[8].r,ya.r);
        scratch[11].i = scratch[0].i + S_MUL(scratch[7].i,yb.r) + S_MUL(scratch[8].i,ya.r);
        scratch[12].r = - S_MUL(scratch[10].i,yb.i) + S_MUL(scratch[9].i,ya.i);
        scratch[12].i = S_MUL(scratch[10].r,yb.i) - S_MUL(scratch[9].r,ya.i);

        C_ADD(*Fout2,scratch[11],scratch[12]);
        C_SUB(*Fout3,scratch[11],scratch[12]);

        ++Fout0;
        ++Fout1;
        ++Fout2;
        ++Fout3;
        ++Fout4;
    }
}

/* perform the butterfly for one stage of a mixed radix FFT */
static void kf_bfly_generic(
    mrkiss_fft_cpx * Fout,
    const size_t fstride,
    const mrkiss_fft_cfg st,
    int m,
    int p
) {
    int u,k,q1,q;
    mrkiss_fft_cpx * twiddles = st->twiddles;
    mrkiss_fft_cpx t;
    int Norig = st->nfft;

    mrkiss_fft_cpx * scratch = (mrkiss_fft_cpx*)MRKISS_FFT_TMP_ALLOC(sizeof(mrkiss_fft_cpx)*p);

    for ( u=0; u<m; ++u ) {
        k=u;
        for ( q1=0 ; q1<p ; ++q1 ) {
            scratch[q1] = Fout[ k  ];
            C_FIXDIV(scratch[q1],p);
            k += m;
        }

        k=u;
        for ( q1=0 ; q1<p ; ++q1 ) {
            int twidx=0;
            Fout[ k ] = scratch[0];
            for (q=1; q<p; ++q ) {
                twidx += fstride * k;
                if (twidx>=Norig) twidx-=Norig;
                C_MUL(t,scratch[q] , twiddles[twidx] );
                C_ADDTO( Fout[ k ] ,t);
            }
            k += m;
        }
    }
    MRKISS_FFT_TMP_FREE(scratch);
}

static void kf_work(
    mrkiss_fft_cpx * Fout,
    const mrkiss_fft_cpx * f,
    const size_t fstride,
    int in_stride,
    int * factors,
    const mrkiss_fft_cfg st
) {
    mrkiss_fft_cpx * Fout_beg=Fout;
    const int p=*factors++; /* the radix  */
    const int m=*factors++; /* stage's fft length/p */
    const mrkiss_fft_cpx * Fout_end = Fout + p*m;

    if (m==1) {
        do {
            *Fout = *f;
            f += fstride*in_stride;
        } while(++Fout != Fout_end );
    } else {
        do {
            /* recursive call:
               DFT of size m*p performed by doing
               p instances of smaller DFTs of size m,
               each one takes a decimated version of the input */
            kf_work( Fout , f, fstride*p, in_stride, factors,st);
            f += fstride*in_stride;
        } while( (Fout += m) != Fout_end );
    }

    Fout=Fout_beg;

    /* recombine the p smaller DFTs */
    switch (p) {
        case 2:
            kf_bfly2(Fout,fstride,st,m);
            break;
        case 3:
            kf_bfly3(Fout,fstride,st,m);
            break;
        case 4:
            kf_bfly4(Fout,fstride,st,m);
            break;
        case 5:
            kf_bfly5(Fout,fstride,st,m);
            break;
        default:
            kf_bfly_generic(Fout,fstride,st,m,p);
            break;
    }
}

/*  facbuf is populated by p1,m1,p2,m2, ...
    where
    p[i] * m[i] = m[i-1]
    m0 = n                  */
static void kf_factor(int n,int * facbuf) {
    int p=4;
    double floor_sqrt;
    floor_sqrt = floor( sqrt((double)n) );

    /* factor out powers of 4, powers of 2, then any remaining primes */
    do {
        while (n % p) {
            switch (p) {
                case 4:
                    p = 2;
                    break;
                case 2:
                    p = 3;
                    break;
                default:
                    p += 2;
                    break;
            }
            if (p > floor_sqrt)
                p = n;          /* no more factors, skip to end */
        }
        n /= p;
        *facbuf++ = p;
        *facbuf++ = n;
    } while (n > 1);
}

static void mrkiss_fft_stride(mrkiss_fft_cfg st,const mrkiss_fft_cpx *fin,mrkiss_fft_cpx *fout,int in_stride) {
    if (fin == fout) {
        /* NOTE: this is not really an in-place FFT algorithm. */
        /* It just performs an out-of-place FFT into a temp buffer */
        mrkiss_fft_cpx * tmpbuf = (mrkiss_fft_cpx*)MRKISS_FFT_TMP_ALLOC( sizeof(mrkiss_fft_cpx)*st->nfft);
        kf_work(tmpbuf,fin,1,in_stride, st->factors,st);
        memcpy(fout,tmpbuf,sizeof(mrkiss_fft_cpx)*st->nfft);
        MRKISS_FFT_TMP_FREE(tmpbuf);
    } else {
        kf_work( fout, fin, 1,in_stride, st->factors,st );
    }
}

static void mrkiss_fft(mrkiss_fft_cfg cfg,const mrkiss_fft_cpx *fin,mrkiss_fft_cpx *fout) {
    mrkiss_fft_stride(cfg,fin,fout,1);
}

/* end of include from kiss_fft.c --------------------------------------------------*/

static void mrkiss_fft_alloc(int nfft, mrkiss_fft_cfg cfg) {
    int i;
    cfg->nfft    = nfft;
    cfg->inverse = 0;

    for (i=0; i<nfft; ++i) {
        const double pi=3.141592653589793238462643383279502884197169399375105820974944;
        double phase = -2*pi*i / nfft;
        kf_cexp(cfg->twiddles+i, phase);
    }
    kf_factor(nfft, cfg->factors);
}

static void mrkiss_fftr(mrkiss_fftr_cfg st, const mrkiss_fft_scalar *timedata, mrkiss_fft_cpx *freqdata) {
    /* input buffer timedata is stored row-wise */
    int k,ncfft;
    mrkiss_fft_cpx fpnk,fpk,f1k,f2k,tw,tdc;

    ncfft = st->substate->nfft;

    /*perform the parallel fft of two real signals packed in real,imag*/
    mrkiss_fft( st->substate , (const mrkiss_fft_cpx*)timedata, st->tmpbuf );

    tdc.r = st->tmpbuf[0].r;
    tdc.i = st->tmpbuf[0].i;
    C_FIXDIV(tdc,2);
    CHECK_OVERFLOW_OP(tdc.r ,+, tdc.i);
    CHECK_OVERFLOW_OP(tdc.r ,-, tdc.i);
    freqdata[0].r = tdc.r + tdc.i;
    freqdata[ncfft].r = tdc.r - tdc.i;
    freqdata[ncfft].i = freqdata[0].i = 0;

    for ( k=1; k <= ncfft/2 ; ++k ) {
        fpk    = st->tmpbuf[k];
        fpnk.r =   st->tmpbuf[ncfft-k].r;
        fpnk.i = - st->tmpbuf[ncfft-k].i;
        C_FIXDIV(fpk,2);
        C_FIXDIV(fpnk,2);

        C_ADD( f1k, fpk , fpnk );
        C_SUB( f2k, fpk , fpnk );
        C_MUL( tw , f2k , st->super_twiddles[k-1]);

        freqdata[k].r = HALF_OF(f1k.r + tw.r);
        freqdata[k].i = HALF_OF(f1k.i + tw.i);
        freqdata[ncfft-k].r = HALF_OF(f1k.r - tw.r);
        freqdata[ncfft-k].i = HALF_OF(tw.i - f1k.i);
    }
}

MODELICA_EXPORT int ModelicaFFT_kiss_fftr(double u[], size_t nu, double work[], size_t nwork,
        double *amplitudes, double *phases) {

    /* Compute real FFT with mrkiss_fftr
       -> u[nu]        : Real data at sample points; nu must be even
       -> work[nwork]  : Work array; nwork >= 3*nu + 2*nf (nf = nu/2+1)
       <- amplitude[nf]: Amplitudes; nf = nu/2+1
       <- phases   [nf]: phases
       <- return       : info = 0: computation o.k.
                              = 1: nu is not even
                              = 2: nwork is wrong
                              = 3: another error

    */
    int i;
    int nu2 = nu / 2;
    int nf  = nu2+1;

    struct mrkiss_fft_state  fft_obj;
    struct mrkiss_fftr_state fftr_obj;
    mrkiss_fft_cpx *freqdata;

    /* Check dimensions */
    if ( nu % 2 != 0 ) return 1;
    if ( nwork < 3*nu + 2*(nu/2+1) ) return 2;

    /* Set values of struct fft_obj */
    fft_obj.twiddles = (mrkiss_fft_cpx *) &work[0];    /* length nu (2*nu2) */
    mrkiss_fft_alloc(nu2, &fft_obj);

    /* Set values of struct fftr_obj */
    fftr_obj.substate       = &fft_obj;
    fftr_obj.tmpbuf         = (mrkiss_fft_cpx *) &work[nu];     /* length: nu */
    fftr_obj.super_twiddles = (mrkiss_fft_cpx *) &work[nu+nu];  /* length: nu  */
    for (i = 0; i < nu2/2; ++i) {
        double phase =
            -3.14159265358979323846264338327 * ((double) (i+1) / nu2 + .5);
        kf_cexp (fftr_obj.super_twiddles+i,phase);
    }

    /* Compute FFT */
    freqdata = (mrkiss_fft_cpx *) &work[nu+nu+nu];  /* length: 2*nf */
    mrkiss_fftr(&fftr_obj, u, freqdata);
    for (i=0; i<nf; i++) {
        amplitudes[i] = sqrt (freqdata[i].r*freqdata[i].r + freqdata[i].i*freqdata[i].i) / nf;
        phases[i]     = atan2(freqdata[i].i, freqdata[i].r);
    }
    return 0;
}

#endif
