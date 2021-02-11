/* ModelicaIO.h - Array I/O functions header

   Copyright (C) 2016-2020, Modelica Association and contributors
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

   NO_FILE_SYSTEM : A file system is not present (e.g. on dSPACE or xPC).
   NO_LOCALE      : locale.h is not present (e.g. on AVR).
   MODELICA_EXPORT: Prefix used for function calls. If not defined, blank is used
                    Useful definition:
                    - "__declspec(dllexport)" if included in a DLL and the
                      functions shall be visible outside of the DLL

   Changelog:
      Dec. 22, 2020: by Thomas Beutlich
                     Added reading of CSV files (ticket #1153)

      Mar. 08, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Added ModelicaIO_readRealTable from ModelicaStandardTables
                     (ticket #2192)

      Mar. 03, 2016: by Thomas Beutlich, ITI GmbH and Martin Otter, DLR
                     Implemented a first version (ticket #1856)
*/

#ifndef MODELICA_IO_H_
#define MODELICA_IO_H_

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
#if defined(__GNUC__)
#define MODELICA_NONNULLATTR __attribute__((nonnull))
#else
#define MODELICA_NONNULLATTR
#endif
#if !defined(__ATTR_SAL)
#undef _In_
#undef _In_z_
#undef _Inout_
#undef _Out_
#define _In_
#define _In_z_
#define _Inout_
#define _Out_
#endif

MODELICA_EXPORT void ModelicaIO_readMatrixSizes(_In_z_ const char* fileName,
                                _In_z_ const char* matrixName,
                                _Out_ int* dim) MODELICA_NONNULLATTR;
  /* Read matrix dimensions from file

     -> fileName: Name of file
     -> matrixName: Name of matrix
     -> dim: Output array for number of rows and columns
  */

MODELICA_EXPORT void ModelicaIO_readRealMatrix(_In_z_ const char* fileName,
                               _In_z_ const char* matrixName,
                               _Inout_ double* matrix, size_t m, size_t n,
                               int verbose) MODELICA_NONNULLATTR;
  /* Read matrix from file

     -> fileName: Name of file
     -> matrixName: Name of matrix
     -> matrix: Output array of dimensions m by n
     -> m: Number of rows
     -> n: Number of columns
     -> verbose: Print message that file is loading
  */

MODELICA_EXPORT int ModelicaIO_writeRealMatrix(_In_z_ const char* fileName,
                               _In_z_ const char* matrixName,
                               _In_ double* matrix, size_t m, size_t n,
                               int append,
                               _In_z_ const char* version) MODELICA_NONNULLATTR;
  /* Write matrix to file

     -> fileName: Name of file
     -> matrixName: Name of matrix
     -> matrix: Input array of dimensions m by n
     -> m: Number of rows
     -> n: Number of columns
     -> append: File append flag
                = 1: if matrix is to be appended to (existing) file,
                = 0: if file is to be newly created
     -> version: Desired file version
                 = "4": MATLAB MAT-file of version 4
                 = "6": MATLAB MAT-file of version 6
                 = "7": MATLAB MAT-file of version 7
                 = "7.3": MATLAB MAT-file of version 7.3
  */

MODELICA_EXPORT double* ModelicaIO_readRealTable(_In_z_ const char* fileName,
                                 _In_z_ const char* tableName,
                                 _Out_ size_t* m, _Out_ size_t* n,
                                 int verbose) MODELICA_NONNULLATTR;
  /* Read matrix and its dimensions from file
     Note: Only called from ModelicaStandardTables, but impossible to be called
     from a Modelica environment

     -> fileName: Name of file
     -> matrixName: Name of matrix
     -> m: Number of rows
     -> n: Number of columns
     -> verbose: Print message that file is loading
     <- RETURN: Array of dimensions m by n
  */

MODELICA_EXPORT double* ModelicaIO_readRealTable2(_In_z_ const char* fileName,
                                 _In_z_ const char* tableName,
                                 _Out_ size_t* m, _Out_ size_t* n,
                                 int verbose, _In_z_ const char* delimiter,
                                 int nHeaderLines) MODELICA_NONNULLATTR;
  /* Read matrix and its dimensions from file
     Note: Only called from ModelicaStandardTables, but impossible to be called
     from a Modelica environment

     -> fileName: Name of file
     -> matrixName: Name of matrix
     -> m: Number of rows
     -> n: Number of columns
     -> verbose: Print message that file is loading
     -> delimiter: Column delimiter character (CSV file only)
     -> nHeaderLines: Number of header lines to ignore (CSV file only)
     <- RETURN: Array of dimensions m by n
  */

MODELICA_EXPORT void ModelicaIO_freeRealTable(double* table);
  /* Free table
     Note: Only called from ModelicaStandardTables to free the allocated memory by
     ModelicaIO_readRealTable
  */

#endif
