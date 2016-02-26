/* ModelicaUtilities.h - External utility functions header

   Copyright (C) 2010-2016, Modelica Association and DLR
   All rights reserved.

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

/* Utility functions which can be called by external Modelica functions.

   These functions are defined in section 12.8.6 of the
   Modelica Specification 3.0 and section 12.9.6 of the
   Modelica Specification 3.1 and 3.2.

   A generic C-implementation of these functions cannot be given,
   because it is tool dependent how strings are output in a
   window of the respective simulation tool. Therefore, only
   this header file is shipped with the Modelica Standard Library.
*/

#ifndef MODELICA_UTILITIES_H
#define MODELICA_UTILITIES_H

#include <stddef.h>
#include <stdarg.h>
#if defined(__cplusplus)
extern "C" {
#endif

/*
  Some of the functions never return to the caller. In order to compile
  external Modelica C-code in most compilers, noreturn attributes need to
  be present to avoid warnings or errors.

  The following macros handle noreturn attributes according to the latest
  C11/C++11 standard with fallback to GNU, Clang or MSVC extensions if using
  an older compiler.
*/

#if __STDC_VERSION__ >= 201112L
#define MODELICA_NORETURN _Noreturn
#define MODELICA_NORETURNATTR
#elif __cplusplus >= 201103L
#if (defined(__GNUC__) && __GNUC__ >= 5) || \
    (defined(__GNUC__) && defined(__GNUC_MINOR__) && __GNUC__ == 4 && __GNUC_MINOR__ >= 8)
#define MODELICA_NORETURN [[noreturn]]
#define MODELICA_NORETURNATTR
#elif (defined(__GNUC__) && __GNUC__ >= 3) || \
      (defined(__GNUC__) && defined(__GNUC_MINOR__) && __GNUC__ == 2 && __GNUC_MINOR__ >= 8)
#define MODELICA_NORETURN
#define MODELICA_NORETURNATTR __attribute__((noreturn))
#elif defined(__GNUC__)
#define MODELICA_NORETURN
#define MODELICA_NORETURNATTR
#else
#define MODELICA_NORETURN [[noreturn]]
#define MODELICA_NORETURNATTR
#endif
#elif defined(__clang__)
#if __has_attribute(noreturn)
#define MODELICA_NORETURN
#define MODELICA_NORETURNATTR __attribute__((noreturn))
#else
#define MODELICA_NORETURN
#define MODELICA_NORETURNATTR
#endif
#elif (defined(__GNUC__) && __GNUC__ >= 3) || \
      (defined(__GNUC__) && defined(__GNUC_MINOR__) && __GNUC__ == 2 && __GNUC_MINOR__ >= 8) || \
      (defined(__SUNPRO_C) && __SUNPRO_C >= 0x5110)
#define MODELICA_NORETURN
#define MODELICA_NORETURNATTR __attribute__((noreturn))
#elif (defined(_MSC_VER) && _MSC_VER >= 1200) || \
       defined(__BORLANDC__)
#define MODELICA_NORETURN __declspec(noreturn)
#define MODELICA_NORETURNATTR
#else
#define MODELICA_NORETURN
#define MODELICA_NORETURNATTR
#endif

void ModelicaMessage(const char *string);
/*
Output the message string (no format control).
*/


void ModelicaFormatMessage(const char *string, ...);
/*
Output the message under the same format control as the C-function printf.
*/


void ModelicaVFormatMessage(const char *string, va_list args);
/*
Output the message under the same format control as the C-function vprintf.
*/


MODELICA_NORETURN void ModelicaError(const char *string) MODELICA_NORETURNATTR;
/*
Output the error message string (no format control). This function
never returns to the calling function, but handles the error
similarly to an assert in the Modelica code.
*/


MODELICA_NORETURN void ModelicaFormatError(const char *string, ...) MODELICA_NORETURNATTR;
/*
Output the error message under the same format control as the C-function
printf. This function never returns to the calling function,
but handles the error similarly to an assert in the Modelica code.
*/


MODELICA_NORETURN void ModelicaVFormatError(const char *string, va_list args) MODELICA_NORETURNATTR;
/*
Output the error message under the same format control as the C-function
vprintf. This function never returns to the calling function,
but handles the error similarly to an assert in the Modelica code.
*/


char* ModelicaAllocateString(size_t len);
/*
Allocate memory for a Modelica string which is used as return
argument of an external Modelica function. Note, that the storage
for string arrays (= pointer to string array) is still provided by the
calling program, as for any other array. If an error occurs, this
function does not return, but calls "ModelicaError".
*/


char* ModelicaAllocateStringWithErrorReturn(size_t len);
/*
Same as ModelicaAllocateString, except that in case of error, the
function returns 0. This allows the external function to close files
and free other open resources in case of error. After cleaning up
resources use ModelicaError or ModelicaFormatError to signal
the error.
*/

#if defined(__cplusplus)
}
#endif

#endif
