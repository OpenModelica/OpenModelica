/* stdint_wrap.h - Wrapper for stdint.h not being available with C89

   Copyright (C) 2020, Modelica Association and contributors
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

#ifndef MODELICA_STDINT_WRAP_H_
#define MODELICA_STDINT_WRAP_H_

/* Have 64 bit integral types */
#if defined(_WIN32)
#if defined(__WATCOMC__) || defined(__MINGW32__) || defined(__CYGWIN__) || defined(__BORLANDC__)
#define HAVE_MODELICA_INT64_T 1
#define HAVE_MODELICA_UINT64_T 1
#elif defined(_MSC_VER) && _MSC_VER > 1300
#define HAVE_MODELICA_INT64_T 1
#define HAVE_MODELICA_UINT64_T 1
#elif defined(_MSC_VER)
#define HAVE_MODELICA_INT64_T 1
#undef HAVE_MODELICA_UINT64_T
#else
#undef HAVE_MODELICA_INT64_T
#undef HAVE_MODELICA_UINT64_T
#endif
#else
#define HAVE_MODELICA_INT64_T 1
#define HAVE_MODELICA_UINT64_T 1
#endif

/* Have the <stdint.h> header file */
#if defined(_WIN32)
#if defined(_MSC_VER) && _MSC_VER >= 1600
#define HAVE_MODELICA_STDINT_H 1
#elif defined(__WATCOMC__) || defined(__MINGW32__) || defined(__CYGWIN__)
#define HAVE_MODELICA_STDINT_H 1
#else
#undef HAVE_MODELICA_STDINT_H
#endif
#elif defined(__GNUC__) && !defined(__VXWORKS__)
#define HAVE_MODELICA_STDINT_H 1
#else
#undef HAVE_MODELICA_STDINT_H
#endif

/* Include integer type header */
#if defined(HAVE_MODELICA_STDINT_H)
#include <stdint.h>
#elif defined(_MSC_VER)
#include "stdint_msvc.h"
#else
#define int8_t signed char
#define uint8_t unsigned char
#define int16_t short
#define uint16_t unsigned short
#define int32_t int
#define uint32_t unsigned int
#if defined(HAVE_MODELICA_INT64_T)
#if defined(__BORLANDC__) || (defined(_MSC_VER) && _MSC_VER < 1300)
#define int64_t __int64
#else
#define int64_t long long
#endif
#endif
#if defined(HAVE_MODELICA_UINT64_T)
#if defined(__BORLANDC__) || (defined(_MSC_VER) && _MSC_VER < 1300)
#define uint64_t unsigned __int64
#else
#define uint64_t unsigned long long
#endif
#endif
#endif

#endif
