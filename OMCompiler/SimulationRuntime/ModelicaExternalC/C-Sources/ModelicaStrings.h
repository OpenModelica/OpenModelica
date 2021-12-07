/* ModelicaStrings.h - External functions header for Modelica.Utilities.Strings

   Copyright (C) 2002-2020, Modelica Association and contributors
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

/* The functions are mostly non-portable. The following #define's are used
   to define the system calls of the operating system

   NO_LOCALE      : locale.h is not present (e.g. on AVR).
   MODELICA_EXPORT: Prefix used for function calls. If not defined, blank is used
                    Useful definition:
                    - "__declspec(dllexport)" if included in a DLL and the
                      functions shall be visible outside of the DLL
*/

#ifndef MODELICA_STRINGS_H_
#define MODELICA_STRINGS_H_

#include <stdlib.h>

#if !defined(MODELICA_EXPORT)
#if defined(__cplusplus)
#define MODELICA_EXPORT extern "C"
#else
#define MODELICA_EXPORT
#endif
#endif

/*
 * Non-null pointers and esp. null-terminated strings need to be passed to
 * external functions.
 *
 * The following macros handle nonnull attributes for GNU C and Microsoft SAL.
 */
#undef MODELICA_NONNULLATTR
#undef MODELICA_RETURNNONNULLATTR
#if defined(__GNUC__)
#define MODELICA_NONNULLATTR __attribute__((nonnull))
#if defined(__GNUC_MINOR__) && (__GNUC__ > 3 && __GNUC_MINOR__ > 8)
#define MODELICA_RETURNNONNULLATTR __attribute__((returns_nonnull))
#else
#define MODELICA_RETURNNONNULLATTR
#endif
#elif defined(__ATTR_SAL)
#define MODELICA_NONNULLATTR
#define MODELICA_RETURNNONNULLATTR _Ret_z_ /* _Ret_notnull_ and null-terminated */
#else
#define MODELICA_NONNULLATTR
#define MODELICA_RETURNNONNULLATTR
#endif
#if !defined(__ATTR_SAL)
#undef _In_z_
#undef _Out_
#undef _Ret_z_
#define _In_z_
#define _Out_
#define _Ret_z_
#endif

MODELICA_EXPORT MODELICA_RETURNNONNULLATTR const char* ModelicaStrings_substring(
    _In_z_ const char* string, int startIndex, int endIndex) MODELICA_NONNULLATTR;
MODELICA_EXPORT int ModelicaStrings_length(_In_z_ const char* string) MODELICA_NONNULLATTR;
MODELICA_EXPORT int ModelicaStrings_compare(_In_z_ const char* string1,
    _In_z_ const char* string2, int caseSensitive) MODELICA_NONNULLATTR;
MODELICA_EXPORT int ModelicaStrings_skipWhiteSpace(_In_z_ const char* string,
    int i) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaStrings_scanIdentifier(_In_z_ const char* string,
    int startIndex, _Out_ int* nextIndex, _Out_ const char** identifier) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaStrings_scanInteger(_In_z_ const char* string,
    int startIndex, int unsignedNumber, _Out_ int* nextIndex,
    _Out_ int* integerNumber) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaStrings_scanReal(_In_z_ const char* string, int startIndex,
    int unsignedNumber, _Out_ int* nextIndex, _Out_ double* number) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaStrings_scanString(_In_z_ const char* string, int startIndex,
    _Out_ int* nextIndex, _Out_ const char** result) MODELICA_NONNULLATTR;
MODELICA_EXPORT int ModelicaStrings_hashString(_In_z_ const char* str) MODELICA_NONNULLATTR;

#endif
