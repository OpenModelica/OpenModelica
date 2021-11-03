/* ModelicaMatIO.h - MAT file I/O functions header

   Copyright (C) 2013-2021, Modelica Association and contributors
   Copyright (C) 2005-2013, Christopher C. Hulbert
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

/*
   This file was created by concatenation of the following header files of the
   MAT file I/O library from <http://sourceforge.net/projects/matio/>:

   matio.h
   matio_pubconf.h
*/

#ifndef MODELICA_MATIO_H_
#define MODELICA_MATIO_H_

#include <stdlib.h>
#include <stdio.h>

#ifndef MATIO_PUBCONF_H
#define MATIO_PUBCONF_H 1

/* Matio major version number */
#define MATIO_MAJOR_VERSION 1

/* Matio minor version number */
#define MATIO_MINOR_VERSION 5

/* Matio release level number */
#define MATIO_RELEASE_LEVEL 21

/* Matio version number */
#define MATIO_VERSION 1521

/* Matio version string */
#define MATIO_VERSION_STR "1.5.21"

/* Default file format */
#define MAT_FT_DEFAULT MAT_FT_MAT5

/* Have MAT int64 / uint64 */
#if defined(_WIN32)
#if defined(__WATCOMC__) || defined(__MINGW32__) || defined(__CYGWIN__) || defined(__BORLANDC__)
#define HAVE_MATIO_INT64_T 1
#define HAVE_MATIO_UINT64_T 1
#elif defined(_MSC_VER) && _MSC_VER > 1300
#define HAVE_MATIO_INT64_T 1
#define HAVE_MATIO_UINT64_T 1
#elif defined(_MSC_VER)
#define HAVE_MATIO_INT64_T 1
#undef HAVE_MATIO_UINT64_T
#else
#undef HAVE_MATIO_INT64_T
#undef HAVE_MATIO_UINT64_T
#endif
#else
#define HAVE_MATIO_INT64_T 1
#define HAVE_MATIO_UINT64_T 1
#endif

/* Have the <stdint.h> header file */
#if defined(_WIN32)
#if defined(_MSC_VER) && _MSC_VER >= 1600
#define HAVE_MATIO_STDINT_H 1
#elif defined(__WATCOMC__) || defined(__MINGW32__) || defined(__CYGWIN__)
#define HAVE_MATIO_STDINT_H 1
#else
#undef HAVE_MATIO_STDINT_H
#endif
#elif defined(__GNUC__) && !defined(__VXWORKS__)
#define HAVE_MATIO_STDINT_H 1
#else
#undef HAVE_MATIO_STDINT_H
#endif

/* Include integer type header */
#if defined(HAVE_MATIO_STDINT_H)
#include <stdint.h>
#elif defined(_MSC_VER)
#define HAVE_MATIO_STDINT_H 1
#include "stdint_msvc.h"
#endif

#if defined(HAVE_MATIO_STDINT_H)
typedef int16_t mat_int16_t;
typedef int32_t mat_int32_t;
typedef int64_t mat_int64_t;
typedef int8_t mat_int8_t;
typedef uint16_t mat_uint16_t;
typedef uint32_t mat_uint32_t;
typedef uint64_t mat_uint64_t;
typedef uint8_t mat_uint8_t;
#else
#define mat_int16_t short
#define mat_int32_t int
#if defined(HAVE_MATIO_INT64_T)
#if defined(__BORLANDC__) || (defined(_MSC_VER) && _MSC_VER < 1300)
#define mat_int64_t __int64
#else
#define mat_int64_t long long
#endif
#endif
#define mat_int8_t signed char
#define mat_uint16_t unsigned short
#define mat_uint32_t unsigned
#if defined(HAVE_MATIO_UINT64_T)
#if defined(__BORLANDC__) || (defined(_MSC_VER) && _MSC_VER < 1300)
#define mat_uint64_t unsigned __int64
#else
#define mat_uint64_t unsigned long long
#endif
#endif
#define mat_uint8_t unsigned char
#endif

/*
  The following macros handle format attributes for type-checks against a
  format string.
*/

#if defined(__GNUC__) && __GNUC__ >= 3
#define MATIO_FORMATATTR_PRINTF1 __attribute__((format(printf, 1, 2)))
#define MATIO_FORMATATTR_VPRINTF __attribute__((format(printf, 1, 0)))
#elif defined(__clang__)
#if __has_attribute(format)
#define MATIO_FORMATATTR_PRINTF1 __attribute__((format(printf, 1, 2)))
#define MATIO_FORMATATTR_VPRINTF __attribute__((format(printf, 1, 0)))
#else
#define MATIO_FORMATATTR_PRINTF1
#define MATIO_FORMATATTR_VPRINTF
#endif
#else
#define MATIO_FORMATATTR_PRINTF1
#define MATIO_FORMATATTR_VPRINTF
#endif

#endif /* MATIO_PUBCONF_H */

#include <stdarg.h>

#if !defined(MATIO_EXTERN)
#if defined(__cplusplus)
#define MATIO_EXTERN extern "C"
#else
#define MATIO_EXTERN
#endif
#endif

/** @defgroup MAT Matlab MAT File I/O Library */
/** @defgroup mat_util MAT File I/O Utility Functions */
/** @if mat_devman @defgroup mat_internal Internal Functions @endif */

/** @brief MAT file access types
 *
 * @ingroup MAT
 * MAT file access types
 */
enum mat_acc
{
    MAT_ACC_RDONLY = 0, /**< @brief Read only file access                */
    MAT_ACC_RDWR = 1    /**< @brief Read/Write file access               */
};

/** @brief MAT file versions
 *
 * @ingroup MAT
 * MAT file versions
 */
enum mat_ft
{
    MAT_FT_MAT73 = 0x0200, /**< @brief Matlab version 7.3 file             */
    MAT_FT_MAT5 = 0x0100,  /**< @brief Matlab version 5 file               */
    MAT_FT_MAT4 = 0x0010,  /**< @brief Matlab version 4 file               */
    MAT_FT_UNDEFINED = 0   /**< @brief Undefined version                   */
};

/** @brief Matlab data types
 *
 * @ingroup MAT
 * Matlab data types
 */
enum matio_types
{
    MAT_T_UNKNOWN = 0,     /**< @brief UNKNOWN data type                   */
    MAT_T_INT8 = 1,        /**< @brief 8-bit signed integer data type      */
    MAT_T_UINT8 = 2,       /**< @brief 8-bit unsigned integer data type    */
    MAT_T_INT16 = 3,       /**< @brief 16-bit signed integer data type     */
    MAT_T_UINT16 = 4,      /**< @brief 16-bit unsigned integer data type   */
    MAT_T_INT32 = 5,       /**< @brief 32-bit signed integer data type     */
    MAT_T_UINT32 = 6,      /**< @brief 32-bit unsigned integer data type   */
    MAT_T_SINGLE = 7,      /**< @brief IEEE 754 single precision data type */
    MAT_T_DOUBLE = 9,      /**< @brief IEEE 754 double precision data type */
    MAT_T_INT64 = 12,      /**< @brief 64-bit signed integer data type     */
    MAT_T_UINT64 = 13,     /**< @brief 64-bit unsigned integer data type   */
    MAT_T_MATRIX = 14,     /**< @brief matrix data type                    */
    MAT_T_COMPRESSED = 15, /**< @brief compressed data type                */
    MAT_T_UTF8 = 16,       /**< @brief 8-bit Unicode text data type        */
    MAT_T_UTF16 = 17,      /**< @brief 16-bit Unicode text data type       */
    MAT_T_UTF32 = 18,      /**< @brief 32-bit Unicode text data type       */

    MAT_T_STRING = 20,  /**< @brief String data type                    */
    MAT_T_CELL = 21,    /**< @brief Cell array data type                */
    MAT_T_STRUCT = 22,  /**< @brief Structure data type                 */
    MAT_T_ARRAY = 23,   /**< @brief Array data type                     */
    MAT_T_FUNCTION = 24 /**< @brief Function data type                  */
};

/** @brief Matlab variable classes
 *
 * @ingroup MAT
 * Matlab variable classes
 */
enum matio_classes
{
    MAT_C_EMPTY = 0,     /**< @brief Empty array                           */
    MAT_C_CELL = 1,      /**< @brief Matlab cell array class               */
    MAT_C_STRUCT = 2,    /**< @brief Matlab structure class                */
    MAT_C_OBJECT = 3,    /**< @brief Matlab object class                   */
    MAT_C_CHAR = 4,      /**< @brief Matlab character array class          */
    MAT_C_SPARSE = 5,    /**< @brief Matlab sparse array class             */
    MAT_C_DOUBLE = 6,    /**< @brief Matlab double-precision class         */
    MAT_C_SINGLE = 7,    /**< @brief Matlab single-precision class         */
    MAT_C_INT8 = 8,      /**< @brief Matlab signed 8-bit integer class     */
    MAT_C_UINT8 = 9,     /**< @brief Matlab unsigned 8-bit integer class   */
    MAT_C_INT16 = 10,    /**< @brief Matlab signed 16-bit integer class    */
    MAT_C_UINT16 = 11,   /**< @brief Matlab unsigned 16-bit integer class  */
    MAT_C_INT32 = 12,    /**< @brief Matlab signed 32-bit integer class    */
    MAT_C_UINT32 = 13,   /**< @brief Matlab unsigned 32-bit integer class  */
    MAT_C_INT64 = 14,    /**< @brief Matlab signed 64-bit integer class    */
    MAT_C_UINT64 = 15,   /**< @brief Matlab unsigned 64-bit integer class  */
    MAT_C_FUNCTION = 16, /**< @brief Matlab function class                 */
    MAT_C_OPAQUE = 17    /**< @brief Matlab opaque class                   */
};

/** @brief Matlab array flags
 *
 * @ingroup MAT
 * Matlab array flags
 */
enum matio_flags
{
    MAT_F_COMPLEX = 0x0800,       /**< @brief Complex bit flag */
    MAT_F_GLOBAL = 0x0400,        /**< @brief Global bit flag */
    MAT_F_LOGICAL = 0x0200,       /**< @brief Logical bit flag */
    MAT_F_DONT_COPY_DATA = 0x0001 /**< Don't copy data, use keep the pointer */
};

/** @brief MAT file compression options
 *
 * This option is only used on version 5 MAT files
 * @ingroup MAT
 */
enum matio_compression
{
    MAT_COMPRESSION_NONE = 0, /**< @brief No compression */
    MAT_COMPRESSION_ZLIB = 1  /**< @brief zlib compression */
};

/** @brief matio lookup type
 *
 * @ingroup MAT
 * matio lookup type
 */
enum
{
    MAT_BY_NAME = 1, /**< Lookup by name */
    MAT_BY_INDEX = 2 /**< Lookup by index */
};

/** @brief Complex data type using split storage
 *
 * Complex data type using split real/imaginary pointers
 * @ingroup MAT
 */
typedef struct mat_complex_split_t
{
    void *Re; /**< Pointer to the real part */
    void *Im; /**< Pointer to the imaginary part */
} mat_complex_split_t;

struct _mat_t;
/** @brief Matlab MAT File information
 * Contains information about a Matlab MAT file
 * @ingroup MAT
 */
typedef struct _mat_t mat_t;

/* Incomplete definition for private library data */
struct matvar_internal;

/** @brief Matlab variable information
 *
 * Contains information about a Matlab variable
 * @ingroup MAT
 */
typedef struct matvar_t
{
    size_t nbytes;                      /**< Number of bytes for the MAT variable */
    int rank;                           /**< Rank (Number of dimensions) of the data */
    enum matio_types data_type;         /**< Data type (MAT_T_*) */
    int data_size;                      /**< Bytes / element for the data */
    enum matio_classes class_type;      /**< Class type in Matlab (MAT_C_DOUBLE, etc) */
    int isComplex;                      /**< non-zero if the data is complex, 0 if real */
    int isGlobal;                       /**< non-zero if the variable is global */
    int isLogical;                      /**< non-zero if the variable is logical */
    size_t *dims;                       /**< Array of lengths for each dimension */
    char *name;                         /**< Name of the variable */
    void *data;                         /**< Pointer to the data */
    int mem_conserve;                   /**< 1 if Memory was conserved with data */
    enum matio_compression compression; /**< Variable compression type */
    struct matvar_internal *internal;   /**< matio internal data */
} matvar_t;

/** @brief sparse data information
 *
 * Contains information and data for a sparse matrix
 * @ingroup MAT
 */
typedef struct mat_sparse_t
{
    mat_uint32_t nzmax; /**< Maximum number of non-zero elements */
    mat_uint32_t *ir;   /**< Array of size nzmax where ir[k] is the row of
                               *  data[k].  0 <= k <= nzmax
                               */
    mat_uint32_t nir;   /**< number of elements in ir */
    mat_uint32_t *jc;   /**< Array size N+1 (N is number of columns) with
                               *  jc[k] being the index into ir/data of the
                               *  first non-zero element for row k.
                               */
    mat_uint32_t njc;   /**< Number of elements in jc */
    mat_uint32_t ndata; /**< Number of complex/real data values */
    void *data;         /**< Array of data elements */
} mat_sparse_t;

/** @cond 0 */
#define MATIO_E_NO_ERROR 0
#define MATIO_E_UNKNOWN_ERROR 1
#define MATIO_E_GENERIC_READ_ERROR 2
#define MATIO_E_GENERIC_WRITE_ERROR 3
#define MATIO_E_INDEX_TOO_BIG 4
#define MATIO_E_FILE_FORMAT_VIOLATION 5
#define MATIO_E_FAIL_TO_IDENTIFY 6
#define MATIO_E_BAD_ARGUMENT 7
#define MATIO_E_OUTPUT_BAD_DATA 8
#define MATIO_E_OPERATION_NOT_SUPPORTED 13
#define MATIO_E_OUT_OF_MEMORY 14
#define MATIO_E_BAD_VARIABLE_NAME 15
#define MATIO_E_OPERATION_PROHIBITED_IN_WRITE_MODE 16
#define MATIO_E_OPERATION_PROHIBITED_IN_READ_MODE 17
#define MATIO_E_WRITE_VARIABLE_DOES_NOT_EXIST 18
#define MATIO_E_READ_VARIABLE_DOES_NOT_EXIST 19
#define MATIO_E_FILESYSTEM_COULD_NOT_OPEN 20
#define MATIO_E_FILESYSTEM_COULD_NOT_OPEN_TEMPORARY 21
#define MATIO_E_FILESYSTEM_COULD_NOT_REOPEN 22
#define MATIO_E_BAD_OPEN_MODE 23
#define MATIO_E_FILESYSTEM_ERROR_ON_CLOSE 24
/** @endcond */

/* Library function */
MATIO_EXTERN void Mat_GetLibraryVersion(int *major, int *minor, int *release);

/* io.c */
MATIO_EXTERN void Mat_Critical(const char *format, ...) MATIO_FORMATATTR_PRINTF1;
MATIO_EXTERN void Mat_Warning(const char *format, ...) MATIO_FORMATATTR_PRINTF1;
MATIO_EXTERN size_t Mat_SizeOf(enum matio_types data_type);
MATIO_EXTERN size_t Mat_SizeOfClass(int class_type);

/* MAT File functions */
#define Mat_Create(a, b) Mat_CreateVer(a, b, MAT_FT_DEFAULT)
MATIO_EXTERN mat_t *Mat_CreateVer(const char *matname, const char *hdr_str,
                                  enum mat_ft mat_file_ver);
MATIO_EXTERN int Mat_Close(mat_t *mat);
MATIO_EXTERN mat_t *Mat_Open(const char *matname, int mode);
MATIO_EXTERN const char *Mat_GetFilename(mat_t *mat);
MATIO_EXTERN const char *Mat_GetHeader(mat_t *mat);
MATIO_EXTERN enum mat_ft Mat_GetVersion(mat_t *mat);
MATIO_EXTERN char **Mat_GetDir(mat_t *mat, size_t *n);
MATIO_EXTERN int Mat_Rewind(mat_t *mat);

/* MAT variable functions */
MATIO_EXTERN matvar_t *Mat_VarCalloc(void);
MATIO_EXTERN matvar_t *Mat_VarCreate(const char *name, enum matio_classes class_type,
                                     enum matio_types data_type, int rank, size_t *dims, void *data,
                                     int opt);
MATIO_EXTERN matvar_t *Mat_VarCreateStruct(const char *name, int rank, size_t *dims,
                                           const char **fields, unsigned nfields);
MATIO_EXTERN int Mat_VarDelete(mat_t *mat, const char *name);
MATIO_EXTERN matvar_t *Mat_VarDuplicate(const matvar_t *in, int opt);
MATIO_EXTERN void Mat_VarFree(matvar_t *matvar);
MATIO_EXTERN matvar_t *Mat_VarGetCell(matvar_t *matvar, int index);
MATIO_EXTERN matvar_t **Mat_VarGetCells(matvar_t *matvar, int *start, int *stride, int *edge);
MATIO_EXTERN matvar_t **Mat_VarGetCellsLinear(matvar_t *matvar, int start, int stride, int edge);
MATIO_EXTERN size_t Mat_VarGetSize(matvar_t *matvar);
MATIO_EXTERN unsigned Mat_VarGetNumberOfFields(matvar_t *matvar);
MATIO_EXTERN int Mat_VarAddStructField(matvar_t *matvar, const char *fieldname);
MATIO_EXTERN char *const *Mat_VarGetStructFieldnames(const matvar_t *matvar);
MATIO_EXTERN matvar_t *Mat_VarGetStructFieldByIndex(matvar_t *matvar, size_t field_index,
                                                    size_t index);
MATIO_EXTERN matvar_t *Mat_VarGetStructFieldByName(matvar_t *matvar, const char *field_name,
                                                   size_t index);
MATIO_EXTERN matvar_t *Mat_VarGetStructField(matvar_t *matvar, void *name_or_index, int opt,
                                             int index);
MATIO_EXTERN matvar_t *Mat_VarGetStructs(matvar_t *matvar, int *start, int *stride, int *edge,
                                         int copy_fields);
MATIO_EXTERN matvar_t *Mat_VarGetStructsLinear(matvar_t *matvar, int start, int stride, int edge,
                                               int copy_fields);
MATIO_EXTERN void Mat_VarPrint(matvar_t *matvar, int printdata);
MATIO_EXTERN matvar_t *Mat_VarRead(mat_t *mat, const char *name);
MATIO_EXTERN int Mat_VarReadData(mat_t *mat, matvar_t *matvar, void *data, int *start, int *stride,
                                 int *edge);
MATIO_EXTERN int Mat_VarReadDataAll(mat_t *mat, matvar_t *matvar);
MATIO_EXTERN int Mat_VarReadDataLinear(mat_t *mat, matvar_t *matvar, void *data, int start,
                                       int stride, int edge);
MATIO_EXTERN matvar_t *Mat_VarReadInfo(mat_t *mat, const char *name);
MATIO_EXTERN matvar_t *Mat_VarReadNext(mat_t *mat);
MATIO_EXTERN matvar_t *Mat_VarReadNextInfo(mat_t *mat);
MATIO_EXTERN matvar_t *Mat_VarSetCell(matvar_t *matvar, int index, matvar_t *cell);
MATIO_EXTERN matvar_t *Mat_VarSetStructFieldByIndex(matvar_t *matvar, size_t field_index,
                                                    size_t index, matvar_t *field);
MATIO_EXTERN matvar_t *Mat_VarSetStructFieldByName(matvar_t *matvar, const char *field_name,
                                                   size_t index, matvar_t *field);
MATIO_EXTERN int Mat_VarWrite(mat_t *mat, matvar_t *matvar, enum matio_compression compress);
MATIO_EXTERN int Mat_VarWriteAppend(mat_t *mat, matvar_t *matvar, enum matio_compression compress,
                                    int dim);
MATIO_EXTERN int Mat_VarWriteInfo(mat_t *mat, matvar_t *matvar);
MATIO_EXTERN int Mat_VarWriteData(mat_t *mat, matvar_t *matvar, void *data, int *start, int *stride,
                                  int *edge);

/* Other functions */
MATIO_EXTERN int Mat_CalcSingleSubscript(int rank, int *dims, int *subs);
MATIO_EXTERN int Mat_CalcSingleSubscript2(int rank, size_t *dims, size_t *subs, size_t *index);
MATIO_EXTERN int *Mat_CalcSubscripts(int rank, int *dims, int index);
MATIO_EXTERN size_t *Mat_CalcSubscripts2(int rank, size_t *dims, size_t index);

#endif /* MODELICAMATIO_H */
