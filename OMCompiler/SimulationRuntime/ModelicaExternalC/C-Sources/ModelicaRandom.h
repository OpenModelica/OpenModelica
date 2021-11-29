/* ModelicaRandom.h - External functions header for Modelica.Math.Random library

   Copyright (C) 2015-2020, Modelica Association and contributors
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

   3. Neither the name of the copyright holder nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

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

/* The following #define's are available.

   NO_MUTEX       : Pthread mutex is not present (e.g. on dSPACE)
   MODELICA_EXPORT: Prefix used for function calls. If not defined, blank is used
                    Useful definition:
                    - "__declspec(dllexport)" if included in a DLL and the
                      functions shall be visible outside of the DLL
*/

#ifndef MODELICA_RANDOM_H_
#define MODELICA_RANDOM_H_

#include <stdlib.h>

#if !defined(MODELICA_EXPORT)
#if defined(__cplusplus)
#define MODELICA_EXPORT extern "C"
#else
#define MODELICA_EXPORT
#endif
#endif

/*
 * Non-null pointers need to be passed to external functions.
 *
 * The following macros handle nonnull attributes for GNU C and Microsoft SAL.
 */
#undef MODELICA_NONNULLATTR
#if defined(__GNUC__)
#define MODELICA_NONNULLATTR __attribute__((nonnull))
#else
#define MODELICA_NONNULLATTR
#endif
#if !defined(__ATTR_SAL)
#undef _In_
#undef _Out_
#define _In_
#define _Out_
#endif

MODELICA_EXPORT void ModelicaRandom_xorshift64star(_In_ int* state_in,
    _Out_ int* state_out, _Out_ double* y) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaRandom_xorshift128plus(_In_ int* state_in,
    _Out_ int* state_out, _Out_ double* y) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaRandom_xorshift1024star(_In_ int* state_in,
    _Out_ int* state_out, _Out_ double* y) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaRandom_setInternalState_xorshift1024star(
    _In_ int* state, size_t nState, int id) MODELICA_NONNULLATTR;
MODELICA_EXPORT double ModelicaRandom_impureRandom_xorshift1024star(int id);
MODELICA_EXPORT int ModelicaRandom_automaticGlobalSeed(double dummy);
MODELICA_EXPORT void ModelicaRandom_convertRealToIntegers(double d,
    _Out_ int* i) MODELICA_NONNULLATTR;

#endif
