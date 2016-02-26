/* ModelicaIO.h - Array I/O functions header

   Copyright (C) 2016, Modelica Association
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

#if !defined(MODELICAIO_H)
#define MODELICAIO_H

#include <stdlib.h>

#if defined(__GNUC__)
#define MODELICA_NONNULLATTR __attribute__((nonnull))
#else
#define MODELICA_NONNULLATTR
#endif
#if !defined(__ATTR_SAL)
#define _In_
#define _In_z_
#define _Out_
#endif

void ModelicaIO_readMatrixSizes(_In_z_ const char* fileName, _In_z_ const char* arrayName, _Out_ int* dim) MODELICA_NONNULLATTR;
void ModelicaIO_readRealMatrix(_In_z_ const char* fileName, _In_z_ const char* arrayName, _Out_ double* a, size_t m, size_t n, int verbose) MODELICA_NONNULLATTR;
int  ModelicaIO_writeRealMatrix(_In_z_ const char* fileName, _In_z_ const char* arrayName, _In_ double* a, size_t m, size_t n, int append, _In_z_ const char* version) MODELICA_NONNULLATTR;

#endif
