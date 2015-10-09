/* External functions for Modelica.Math.Random library

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
      Feb. 17, 2015: by Andreas Kloeckner and Martin Otter, DLR-SR.
                     Implemented a first version.

   This file is licensed under the BSD 2-Clause License:

   Copyright (C) 2015, DLR and Modelica Association.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice,
       this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.

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
#if !defined(MODELICA_EXPORT)
#   define MODELICA_EXPORT
#endif

/* Have ModelicaRandom int64 / uint64 */
#if defined (_WIN32)
#if defined(_MSC_VER) || defined(__MINGW32__)
#define HAVE_ModelicaRandom_INT64_T 1
#define HAVE_ModelicaRandom_UINT64_T 1
#elif defined(__WATCOMC__)
#define HAVE_ModelicaRandom_INT64_T 1
#define HAVE_ModelicaRandom_UINT64_T 1
#elif defined(__BORLANDC__)
#undef HAVE_ModelicaRandom_INT64_T
#undef HAVE_ModelicaRandom_UINT64_T
#else
#undef HAVE_ModelicaRandom_INT64_T
#undef HAVE_ModelicaRandom_UINT64_T
#endif
#else
#define HAVE_ModelicaRandom_INT64_T 1
#define HAVE_ModelicaRandom_UINT64_T 1
#endif

/* Define to 1 if <stdint.h> header file is available */
#if defined(_WIN32)
#   if (defined(_MSC_VER) && _MSC_VER >= 1600) || defined(__MINGW32__)
#       define ModelicaRandom_HAVE_STDINT_H 1
#   elif defined(__WATCOMC__)
#       define ModelicaRandom_HAVE_STDINT_H 1
#   else
#       undef ModelicaRandom_HAVE_STDINT_H
#   endif
#else
#   define ModelicaRandom_HAVE_STDINT_H 1
#endif

/* Include integer type header */
#if defined(ModelicaRandom_HAVE_STDINT_H)
#   include <stdint.h>
#else
#   define int32_t  int
#   define uint32_t unsigned int
#if defined(HAVE_ModelicaRandom_INT64_T)
#if defined(_MSC_VER) && _MSC_VER < 1300
#define int64_t __int64
#else
#define int64_t long long
#endif
#endif
#if defined(HAVE_ModelicaRandom_UINT64_T)
#if defined(_MSC_VER) && _MSC_VER < 1300
#define uint64_t unsigned __int64
#else
#define uint64_t unsigned long long
#endif
#endif
#endif

#include <stdlib.h>
#include <limits.h>
#include <math.h>
#include <string.h>
#include "ModelicaUtilities.h"
#include "gconstructor.h"

/* The standard way to detect posix is to check _POSIX_VERSION,
 * which is defined in <unistd.h>
 */
#if defined(__unix__) || defined(__linux__) || defined(__APPLE_CC__)
  #include <unistd.h>
#endif
#if !defined(_POSIX_) && defined(_POSIX_VERSION)
  #define _POSIX_ 1
#endif

/* On Posix systems define a mutex using the single static variable "m" */
#if defined(_POSIX_)
#include <pthread.h>
static pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;
#define MUTEX_LOCK() pthread_mutex_lock(&m)
#define MUTEX_UNLOCK() pthread_mutex_unlock(&m)

/* On Windows systems define a critical section using the single static variable "cs" */
#elif defined(_WIN32) && defined(G_HAS_CONSTRUCTORS)
#if !defined(WIN32_LEAN_AND_MEAN)
#define WIN32_LEAN_AND_MEAN
#endif
#include <Windows.h>
static CRITICAL_SECTION cs;
#ifdef G_DEFINE_CONSTRUCTOR_NEEDS_PRAGMA
#pragma G_DEFINE_CONSTRUCTOR_PRAGMA_ARGS(initializeCS)
#endif
G_DEFINE_CONSTRUCTOR(initializeCS)
static void initializeCS(void) {
    InitializeCriticalSection(&cs);
}
#ifdef G_DEFINE_DESTRUCTOR_NEEDS_PRAGMA
#pragma G_DEFINE_DESTRUCTOR_PRAGMA_ARGS(deleteCS)
#endif
G_DEFINE_DESTRUCTOR(deleteCS)
static void deleteCS(void) {
    DeleteCriticalSection(&cs);
}
#define MUTEX_LOCK() EnterCriticalSection(&cs)
#define MUTEX_UNLOCK() LeaveCriticalSection(&cs)

/* On other systems do not use a mutex at all */
#else
#define MUTEX_LOCK()
#define MUTEX_UNLOCK()
#endif

/* XORSHIFT ALGORITHMS */

/* For details see http://xorshift.di.unimi.it/

   Written in 2014 by Sebastiano Vigna (vigna@acm.org)

   To the extent possible under law, the author has dedicated all copyright
   and related and neighboring rights to this software to the public domain
   worldwide. This software is distributed without any warranty.

   See <http://creativecommons.org/publicdomain/zero/1.0/>.

   Adapted by Martin Otter and Andreas Kloeckner for use with Modelica:
   - Inputs and outputs must be int's, that is int32_t.
   - Inputs are casted accordingly.
   - Outputs are casted accordingly.
   - The additional double between 0 and 1 is output.
*/

/* transform 64-bit unsigned integer to double such that zero cannot appear, by
   first transforming to a 64-bit signed integer, then to a double in the range 0 .. 1.
   (using the algorithm given here: http://www.doornik.com/research/randomdouble.pdf) */
#define ModelicaRandom_INVM64 5.42101086242752217004e-20 /* = 2^(-64) */
#define ModelicaRandom_RAND(INT64) ( (int64_t)(INT64) * ModelicaRandom_INVM64 + 0.5 )

MODELICA_EXPORT void ModelicaRandom_xorshift64star(int state_in[], int state_out[], double* y) {
    /*  xorshift64* random number generator.
        For details see http://xorshift.di.unimi.it/

        Written in 2014 by Sebastiano Vigna (vigna@acm.org)

        To the extent possible under law, the author has dedicated all copyright
        and related and neighboring rights to this software to the public domain
        worldwide. This software is distributed without any warranty.

        See <http://creativecommons.org/publicdomain/zero/1.0/>.

        Adapted by Martin Otter and Andreas Kloeckner (DLR)
        for the Modelica external function interface.
    */

    /*  This is a good generator if you're short on memory, but otherwise we
        rather suggest to use a xorshift128+ (for maximum speed) or
        xorshift1024* (for speed and very long period) generator. */

    /* Convert inputs */
    union s_tag {
        int32_t  s32[2];
        uint64_t s64;
    } s;
    int i;
    uint64_t x;
    for (i=0; i<sizeof(s)/sizeof(uint32_t); i++) {
        s.s32[i] = state_in[i];
    }
    x = s.s64;

    /* The actual algorithm */
    x ^= x >> 12; /* a */
    x ^= x << 25; /* b */
    x ^= x >> 27; /* c */
#if defined(_MSC_VER)
    x  = x * 2685821657736338717i64;
#else
    x  = x * 2685821657736338717LL;
#endif
    /* Convert outputs */
    s.s64 = x;
    for (i=0; i<sizeof(s)/sizeof(uint32_t); i++) {
        state_out[i] = s.s32[i];
    }
    *y = ModelicaRandom_RAND(x);
}

MODELICA_EXPORT void ModelicaRandom_xorshift128plus(int state_in[], int state_out[], double* y) {
    /*  xorshift128+ random number generator.
        For details see http://xorshift.di.unimi.it
        Arguments seed and newSeed must be int32_t vectors with at least 4 elements each.

        Written in 2014 by Sebastiano Vigna (vigna@acm.org)

        To the extent possible under law, the author has dedicated all copyright
        and related and neighboring rights to this software to the public domain
        worldwide. This software is distributed without any warranty.

        See <http://creativecommons.org/publicdomain/zero/1.0/>.

        Adapted by Martin Otter and Andreas Kloeckner (DLR)
        for the Modelica external function interface.
    */

    /*  This is the fastest generator passing BigCrush without systematic
        errors, but due to the relatively short period it is acceptable only
        for applications with a very mild amount of parallelism; otherwise, use
        a xorshift1024* generator. */

    /*  The state must be seeded so that it is not everywhere zero. If you have
        a 64-bit seed, we suggest to pass it twice through MurmurHash3's
        avalanching function. */

    /* Convert inputs */
    union s_tag {
        int32_t  s32[4];
        uint64_t s64[2];
    } s;
    int i;
    uint64_t s1;
    uint64_t s0;
    for (i=0; i<sizeof(s)/sizeof(uint32_t); i++) {
        s.s32[i] = state_in[i];
    }

    /* The actual algorithm */
    s1       = s.s64[0];
    s0       = s.s64[1];
    s.s64[0] = s.s64[1];
    s1      ^= s1 << 23; /* a */
    s.s64[1] = ( s1 ^ s0 ^ ( s1 >> 17 ) ^ ( s0 >> 26 ) ) + s0; /* b, c */

    /* Convert outputs */
    for (i=0; i<sizeof(s)/sizeof(uint32_t); i++) {
        state_out[i] = s.s32[i];
    }
    *y = ModelicaRandom_RAND(s.s64[1]);
}

static void ModelicaRandom_xorshift1024star_internal(uint64_t s[], int* p, double* y) {
    /*  xorshift1024* random number generator.
        For details see http://xorshift.di.unimi.it

        This internal function directly operates on a pointer to the state array, such that
        no copying of states is needed.

        Written in 2014 by Sebastiano Vigna (vigna@acm.org)

        To the extent possible under law, the author has dedicated all copyright
        and related and neighboring rights to this software to the public domain
        worldwide. This software is distributed without any warranty.

        See <http://creativecommons.org/publicdomain/zero/1.0/>.

        Adapted by Martin Otter and Andreas Kloeckner (DLR)
        for the Modelica external function interface.
    */

    /*  This is a fast, top-quality generator. If 1024 bits of state are too
        much, try a xorshift128+ or a xorshift64* generator. */

    /*  The state must be seeded so that it is not everywhere zero. If you have
        a 64-bit seed,  we suggest to seed a xorshift64* generator and use its
        output to fill s. */

    /* Convert inputs */
    uint64_t s0;
    uint64_t s1;
    *p = *p & 15;

    /* The actual algorithm */
    s0 = s[*p];
    s1 = s[*p = (*p + 1) & 15];

    s1 ^= s1 << 31; /* a */
    s1 ^= s1 >> 11; /* b */
    s0 ^= s0 >> 30; /* c */

    s[*p] = s0 ^ s1;

    /* Convert outputs */
#if defined(_MSC_VER)
    *y = ModelicaRandom_RAND(s[*p]*1181783497276652981i64);
#else
    *y = ModelicaRandom_RAND(s[*p]*1181783497276652981LL);
#endif
}

MODELICA_EXPORT void ModelicaRandom_xorshift1024star(int state_in[], int state_out[], double* y) {
    /*  xorshift1024* random number generator.
        For details see http://xorshift.di.unimi.it

        This function uses ModelicaRandom_xorshift1024star_internal as generator and adapts inputs and outputs.

        Adapted by Martin Otter and Andreas Kloeckner (DLR)
        for the Modelica external function interface.
    */

    /*  This is a fast, top-quality generator. If 1024 bits of state are too
        much, try a xorshift128+ or a xorshift64* generator. */

    /*  The state must be seeded so that it is not everywhere zero. If you have
        a 64-bit seed,  we suggest to seed a xorshift64* generator and use its
        output to fill s. */

    /* Convert inputs */
    union s_tag {
        int32_t  s32[32];
        uint64_t s64[16];
    } s;
    int i;
    int p;
    for (i=0; i<sizeof(s)/sizeof(uint32_t); i++) {
        s.s32[i] = state_in[i];
    }
    p = state_in[32];

    /* The actual algorithm */
    ModelicaRandom_xorshift1024star_internal(s.s64, &p, y);

    /* Convert outputs */
    for (i=0; i<sizeof(s)/sizeof(uint32_t); i++) {
        state_out[i] = s.s32[i];
    }
    state_out[32] = p;
}

/* EXTERNAL SEED ALGORITHMS */

/* these functions give access to an external random number state
   you should be very careful about using them...

   The external variables are
   - ModelicaRandom_s:  The first part of the internal state of xorshift1024*
   - ModelicaRandom_p:  The second part of the internal state of xorshift1024*
   - ModelicaRandom_id: The check variable used for initializing the state

   We use MUTEX_LOCK() and MUTEX_UNLOCK() as defined above for
   thread-safe access to these variables.
*/

/* Internal state of impure random number generator */
static const size_t ModelicaRandom_size = 33;
static uint64_t ModelicaRandom_s[ 16 ];
static int ModelicaRandom_p;
static int ModelicaRandom_id = 0;

MODELICA_EXPORT void ModelicaRandom_setInternalState_xorshift1024star(int* state, size_t nState, int id) {
    /* receives the external states from Modelica */
    union s_tag {
        int32_t  s32[2];
        uint64_t s64;
    } s;
    int i;

    if ( nState > ModelicaRandom_size ) {
        ModelicaFormatError("External state vector is too large. Should be %lu.\n", (unsigned long)ModelicaRandom_size);
    }
    MUTEX_LOCK();
        for (i=0; i<16; i++) {
            s.s32[0] = state[2*i];
            s.s32[1] = state[2*i+1];
            ModelicaRandom_s[i] = s.s64;
        }
        ModelicaRandom_p = state[32];
        ModelicaRandom_id = id;
    MUTEX_UNLOCK();
}

MODELICA_EXPORT double ModelicaRandom_impureRandom_xorshift1024star(int id) {
    /* xorshift1024* random number generator (same as above, but with internal state, instead of external one).
       For details see http://xorshift.di.unimi.it

       Argument "id" is provided to guarantee the right calling sequence
       of the function in a Modelica environment (first calling function
       ModelicaRandom_initialize_xorshift1024star that must return "dummy" which is passed
       as input argument to ModelicaRandom_xorshift1024star. As a result, the ordering
       of the function is correct.

       This function uses ModelicaRandom_xorshift1024star_internal as generator and adapts inputs and outputs.

       Adapted by Martin Otter (DLR) to initialize the seed with ModelicaRandom_initializeRandom
       and to return a double in range 0 < randomNumber < 1.0
    */

    /* This is a fast, top-quality generator. If 1024 bits of state are too
       much, try a xorshift128+ or a xorshift64* generator. */

    /* The state must be seeded so that it is not everywhere zero. If you have
       a 64-bit seed,  we suggest to seed a xorshift64* generator and use its
       output to fill s. */

    double y;

    MUTEX_LOCK();
        /* Check that ModelicaRandom_initializeImpureRandome_xorshift1024star was called before */
        if ( id != ModelicaRandom_id ) {
            ModelicaError("Function impureRandom not initialized with function initializeImpureRandom\n");
        }

        /* Compute random number */
        ModelicaRandom_xorshift1024star_internal(ModelicaRandom_s, &ModelicaRandom_p, &y);
    MUTEX_UNLOCK();
    return y;
}

/* original algorithms */

MODELICA_EXPORT void ModelicaRandom_convertRealToIntegers(double d, int i[]) {
    /* casts a double to two integers */
    union d2i {
        double d;
        int    i[2];
    } u;

    u.d  = d;
    i[0] = u.i[0];
    i[1] = u.i[1];
}
