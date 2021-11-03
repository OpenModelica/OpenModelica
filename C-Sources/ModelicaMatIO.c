/* ModelicaMatIO.c - MAT file I/O functions

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

/* This file was created by concatenation of the following C source files of the
   MAT file I/O library from <http://sourceforge.net/projects/matio/>:

   endian.c
   inflate.c
   io.c
   read_data.c
   mat.c
   mat4.c
   mat5.c
   mat73.c
   matvar_cell.c
   matvar_struct.c
*/

/* By default v4 and v6 MAT-files are supported. The v7 and v7.3 MAT-file
   formats require additional preprocessor options and third-party libraries.
   The following #define's are available.

   NO_FILE_SYSTEM: A file system is not present (e.g. on dSPACE or xPC).
   NO_LOCALE     : locale.h is not present (e.g. on AVR).
   HAVE_ZLIB=1   : Enables the support of v7 MAT-files
                   The zlib (>= v1.2.3) library is required.
   HAVE_HDF5=1   : Enables the support of v7.3 MAT-files
                   The hdf5 (>= v1.8) library is required.
*/

#if !defined(NO_FILE_SYSTEM)
#if defined(__gnu_linux__)
#define _GNU_SOURCE 1
#elif defined(__MINGW32__) && !defined(__USE_MINGW_ANSI_STDIO)
#define __USE_MINGW_ANSI_STDIO 1
#endif
#include <stdarg.h>
#include "ModelicaUtilities.h"

/* -------------------------------
 * ---------- endian.c
 * -------------------------------
 */
/** @file endian.c
 * @brief Functions to handle endian specifics
 */
#include <stdlib.h>
#ifndef MATIO_PRIVATE_H
#define MATIO_PRIVATE_H

/* Extended sparse matrix data types */
/* #undef EXTENDED_SPARSE */

/* Define to 1 if you have the <inttypes.h> header file. */
#if defined(_WIN32)
#if defined(_MSC_VER) && _MSC_VER >= 1800
#define HAVE_INTTYPES_H 1
#elif defined(__WATCOMC__) || defined(__MINGW32__) || defined(__CYGWIN__)
#define HAVE_INTTYPES_H 1
#else
#undef HAVE_INTTYPES_H
#endif
#elif defined(__GNUC__)
#define HAVE_INTTYPES_H 1
#else
#undef HAVE_INTTYPES_H
#endif

/* Define to 1 if you have the <intsafe.h> header file. */
#if defined(_MSC_VER) && _MSC_VER >= 1600
#define HAVE_INTSAFE_H 1
#else
#undef HAVE_INTSAFE_H
#endif

#if !defined(__BORLANDC__) && !defined(__LCC__) && !(defined(_MSC_VER) && _MSC_VER < 1400)
#define HAVE_SAFE_MATH 1
#else
#undef HAVE_SAFE_MATH
#endif

#if !defined(NO_LOCALE)
/* Define to 1 if you have the `localeconv' function. */
#define HAVE_LOCALECONV 1

/* Define to 1 if you have the <locale.h> header file. */
#define HAVE_LOCALE_H 1
#endif

/* Define to 1 if the system has the type `long double'. */
#if defined(_WIN32)
#if defined(__WATCOMC__) || (defined(_MSC_VER) && _MSC_VER >= 1300)
#define HAVE_LONG_DOUBLE 1
#endif
#endif
#if defined(__GNUC__)
#define HAVE_LONG_DOUBLE 1
#endif

/* Define to 1 if the system has the type `long long int'. */
#if defined(_WIN32)
#if defined(__WATCOMC__) || (defined(_MSC_VER) && _MSC_VER >= 1300)
#define HAVE_LONG_LONG_INT 1
#endif
#endif
#if defined(__GNUC__) && __STDC_VERSION__ >= 199901L
#define HAVE_LONG_LONG_INT 1
#endif

/* Define to 1 if the system has the type `ptrdiff_t'. */
#define HAVE_PTRDIFF_T 1

/* Define to 1 if you have a C99 compliant `snprintf' function. */
#if defined(STDC99)
#define HAVE_SNPRINTF 1
#elif defined(__MINGW32__) || defined(__CYGWIN__)
#if __STDC_VERSION__ >= 199901L
#define HAVE_SNPRINTF 1
#endif
#elif defined(__WATCOMC__)
#define HAVE_SNPRINTF 1
#elif defined(__TURBOC__) && __TURBOC__ >= 0x550
#define HAVE_SNPRINTF 1
#elif defined(MSDOS) && defined(__BORLANDC__) && (BORLANDC > 0x410)
#define HAVE_SNPRINTF 1
#elif defined(_MSC_VER) && _MSC_VER >= 1900
#define HAVE_SNPRINTF 1
#else
#undef HAVE_SNPRINTF
#endif

/* Define to 1 if you have the <stdarg.h> header file. */
#define HAVE_STDARG_H 1

/* Define to 1 if you have the <stddef.h> header file. */
#define HAVE_STDDEF_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if `decimal_point' is member of `struct lconv'. */
#define HAVE_STRUCT_LCONV_DECIMAL_POINT 1

/* Define to 1 if `thousands_sep' is member of `struct lconv'. */
#define HAVE_STRUCT_LCONV_THOUSANDS_SEP 1

/* Define to 1 if the system has the type `unsigned long long int'. */
#if defined(_WIN32)
#if defined(__WATCOMC__) || (defined(_MSC_VER) && _MSC_VER >= 1300)
#define HAVE_UNSIGNED_LONG_LONG_INT 1
#endif
#endif
#if defined(__GNUC__) && __STDC_VERSION__ >= 199901L
#define HAVE_UNSIGNED_LONG_LONG_INT 1
#endif

/* Define to 1 if you have the `va_copy' function or macro. */
#if defined(__GNUC__) && __STDC_VERSION__ >= 199901L
#define HAVE_VA_COPY 1
#elif defined(_MSC_VER) && _MSC_VER >= 1800
#define HAVE_VA_COPY 1
#elif defined(__WATCOMC__)
#define HAVE_VA_COPY 1
#else
#undef HAVE_VA_COPY
#endif

/* Define to 1 if you have the `__va_copy' function or macro. */
#if defined(__GNUC__)
#define HAVE___VA_COPY 1
#elif defined(__WATCOMC__)
#define HAVE___VA_COPY 1
#else
#undef HAVE___VA_COPY
#endif

/* Platform */
#if defined(_MSC_VER) && defined(_WIN64)
#define MATIO_PLATFORM "x86_64-pc-windows"
#elif defined(_MSC_VER) && defined(_WIN32)
#define MATIO_PLATFORM "i686-pc-windows"
#else
#define MATIO_PLATFORM "UNKNOWN"
#endif

/* Fixed types in safe-math.h disabled */
#define PSNIP_SAFE_NO_FIXED 1

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Z prefix */
#undef Z_PREFIX

#include "ModelicaMatIO.h"

#if HAVE_SAFE_MATH
#include "safe-math.h"
#endif

#include <limits.h>
#include <math.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#if defined(__GLIBC__)
#include <endian.h>
#endif

#if HAVE_INTTYPES_H
#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#endif

#if HAVE_ZLIB
#define ZLIB_BYTE_PTR(a) ((Bytef *)(a))
#include <zlib.h>
#endif

#if HAVE_HDF5
#include <hdf5.h>
#endif

#if ( defined(_WIN64) || defined(_WIN32) ) && !defined(__CYGWIN__)
#include <io.h>
#endif

#if defined(_MSC_VER) || defined(__MINGW32__)
#define SIZE_T_FMTSTR "Iu"
#else
#define SIZE_T_FMTSTR "zu"
#endif

#ifndef INT32_MAX
#define INT32_MAX INT_MAX
#endif

#ifndef UINT32_MAX
#ifdef UINT_MAX
#define UINT32_MAX UINT_MAX
#else
#define UINT32_MAX INT_MAX
#endif
#endif

#if !defined(READ_BLOCK_SIZE)
#define READ_BLOCK_SIZE (256)
#endif

#define _CAT(X, Y) X##Y
#define CAT(X, Y) _CAT(X, Y)

/** @if mat_devman
 * @brief Matlab MAT File information
 *
 * Contains information about a Matlab MAT file
 * @ingroup mat_internal
 * @endif
 */
struct _mat_t
{
    void *fp;            /**< File pointer for the MAT file */
    char *header;        /**< MAT file header string */
    char *subsys_offset; /**< Offset */
    char *filename;      /**< Filename of the MAT file */
    int version;         /**< MAT file version */
    int byteswap;        /**< 1 if byte swapping is required, 0 otherwise */
    int mode;            /**< Access mode */
    long bof;            /**< Beginning of file not including any header */
    size_t next_index;   /**< Index/File position of next variable to read */
    size_t num_datasets; /**< Number of datasets in the file */
#if HAVE_HDF5
    hid_t refs_id; /**< Id of the /#refs# group in HDF5 */
#endif
    char **dir; /**< Names of the datasets in the file */
};

/** @if mat_devman
 * @brief internal structure for MAT variables
 * @ingroup mat_internal
 * @endif
 */
struct matvar_internal
{
#if HAVE_HDF5
    char *hdf5_name;     /**< Name */
    hobj_ref_t hdf5_ref; /**< Reference */
    hid_t id;            /**< Id */
#endif
    long datapos;        /**< Offset from the beginning of the MAT file to the data */
    unsigned num_fields; /**< Number of fields */
    char **fieldnames;   /**< Pointer to fieldnames */
#if HAVE_ZLIB
    z_streamp z; /**< zlib compression state */
    void *data;  /**< Inflated data array */
#endif
};

/* snprintf.c */
#if !HAVE_SNPRINTF
int rpl_snprintf(char *, size_t, const char *, ...);
#define mat_snprintf rpl_snprintf
#else
#define mat_snprintf snprintf
#endif /* !HAVE_SNPRINTF */

/* endian.c */
static double Mat_doubleSwap(double *a);
static float Mat_floatSwap(float *a);
#ifdef HAVE_MATIO_INT64_T
static mat_int64_t Mat_int64Swap(mat_int64_t *a);
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
static mat_uint64_t Mat_uint64Swap(mat_uint64_t *a);
#endif /* HAVE_MATIO_UINT64_T */
static mat_int32_t Mat_int32Swap(mat_int32_t *a);
static mat_uint32_t Mat_uint32Swap(mat_uint32_t *a);
static mat_int16_t Mat_int16Swap(mat_int16_t *a);
static mat_uint16_t Mat_uint16Swap(mat_uint16_t *a);

/* read_data.c */
static size_t ReadDoubleData(mat_t *mat, double *data, enum matio_types data_type, size_t len);
static size_t ReadSingleData(mat_t *mat, float *data, enum matio_types data_type, size_t len);
#ifdef HAVE_MATIO_INT64_T
static size_t ReadInt64Data(mat_t *mat, mat_int64_t *data, enum matio_types data_type, size_t len);
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
static size_t ReadUInt64Data(mat_t *mat, mat_uint64_t *data, enum matio_types data_type,
                             size_t len);
#endif /* HAVE_MATIO_UINT64_T */
static size_t ReadInt32Data(mat_t *mat, mat_int32_t *data, enum matio_types data_type, size_t len);
static size_t ReadUInt32Data(mat_t *mat, mat_uint32_t *data, enum matio_types data_type,
                             size_t len);
static size_t ReadInt16Data(mat_t *mat, mat_int16_t *data, enum matio_types data_type, size_t len);
static size_t ReadUInt16Data(mat_t *mat, mat_uint16_t *data, enum matio_types data_type,
                             size_t len);
static size_t ReadInt8Data(mat_t *mat, mat_int8_t *data, enum matio_types data_type, size_t len);
static size_t ReadUInt8Data(mat_t *mat, mat_uint8_t *data, enum matio_types data_type, size_t len);
static size_t ReadCharData(mat_t *mat, void *data, enum matio_types data_type, size_t len);
static int ReadDataSlab1(mat_t *mat, void *data, enum matio_classes class_type,
                         enum matio_types data_type, int start, int stride, int edge);
static int ReadDataSlab2(mat_t *mat, void *data, enum matio_classes class_type,
                         enum matio_types data_type, size_t *dims, int *start, int *stride,
                         int *edge);
static int ReadDataSlabN(mat_t *mat, void *data, enum matio_classes class_type,
                         enum matio_types data_type, int rank, size_t *dims, int *start,
                         int *stride, int *edge);
#if HAVE_ZLIB
static int ReadCompressedDoubleData(mat_t *mat, z_streamp z, double *data,
                                    enum matio_types data_type, int len);
static int ReadCompressedSingleData(mat_t *mat, z_streamp z, float *data,
                                    enum matio_types data_type, int len);
#ifdef HAVE_MATIO_INT64_T
static int ReadCompressedInt64Data(mat_t *mat, z_streamp z, mat_int64_t *data,
                                   enum matio_types data_type, int len);
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
static int ReadCompressedUInt64Data(mat_t *mat, z_streamp z, mat_uint64_t *data,
                                    enum matio_types data_type, int len);
#endif /* HAVE_MATIO_UINT64_T */
static int ReadCompressedInt32Data(mat_t *mat, z_streamp z, mat_int32_t *data,
                                   enum matio_types data_type, int len);
static int ReadCompressedUInt32Data(mat_t *mat, z_streamp z, mat_uint32_t *data,
                                    enum matio_types data_type, int len);
static int ReadCompressedInt16Data(mat_t *mat, z_streamp z, mat_int16_t *data,
                                   enum matio_types data_type, int len);
static int ReadCompressedUInt16Data(mat_t *mat, z_streamp z, mat_uint16_t *data,
                                    enum matio_types data_type, int len);
static int ReadCompressedInt8Data(mat_t *mat, z_streamp z, mat_int8_t *data,
                                  enum matio_types data_type, int len);
static int ReadCompressedUInt8Data(mat_t *mat, z_streamp z, mat_uint8_t *data,
                                   enum matio_types data_type, int len);
static int ReadCompressedCharData(mat_t *mat, z_streamp z, void *data, enum matio_types data_type,
                                  size_t len);
static int ReadCompressedDataSlab1(mat_t *mat, z_streamp z, void *data,
                                   enum matio_classes class_type, enum matio_types data_type,
                                   int start, int stride, int edge);
static int ReadCompressedDataSlab2(mat_t *mat, z_streamp z, void *data,
                                   enum matio_classes class_type, enum matio_types data_type,
                                   size_t *dims, int *start, int *stride, int *edge);
static int ReadCompressedDataSlabN(mat_t *mat, z_streamp z, void *data,
                                   enum matio_classes class_type, enum matio_types data_type,
                                   int rank, size_t *dims, int *start, int *stride, int *edge);

/* inflate.c */
static int InflateSkip(mat_t *mat, z_streamp z, int nBytes, size_t *bytesread);
static int InflateSkipData(mat_t *mat, z_streamp z, enum matio_types data_type, int len);
static int InflateRankDims(mat_t *mat, z_streamp z, void *buf, size_t nBytes, mat_uint32_t **dims,
                           size_t *bytesread);
static int Inflate(mat_t *mat, z_streamp z, void *buf, unsigned int nBytes, size_t *bytesread);
static int InflateData(mat_t *mat, z_streamp z, void *buf, unsigned int nBytes);
#endif

/* mat.c */
static mat_complex_split_t *ComplexMalloc(size_t nbytes);
static void ComplexFree(mat_complex_split_t *complex_data);
static enum matio_types ClassType2DataType(enum matio_classes class_type);
static int Add(size_t *res, size_t a, size_t b);
static int Mul(size_t *res, size_t a, size_t b);
static int Mat_MulDims(const matvar_t *matvar, size_t *nelems);
static int Read(void *buf, size_t size, size_t count, FILE *fp, size_t *bytesread);
static int IsEndOfFile(FILE *fp, long *fpos);

/* io.c */
#if defined(_WIN32) && defined(_MSC_VER)
static wchar_t *utf82u(const char *src);
#endif

#endif

/** @brief swap the bytes @c a and @c b
 * @ingroup mat_internal
 */
#define swap(a, b) \
    a ^= b;        \
    b ^= a;        \
    a ^= b

#ifdef HAVE_MATIO_INT64_T
/** @brief swap the bytes of a 64-bit signed integer
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static mat_int64_t
Mat_int64Swap(mat_int64_t *a)
{
    union {
        mat_int8_t i1[8];
        mat_int64_t i8;
    } tmp;

    tmp.i8 = *a;

    swap(tmp.i1[0], tmp.i1[7]);
    swap(tmp.i1[1], tmp.i1[6]);
    swap(tmp.i1[2], tmp.i1[5]);
    swap(tmp.i1[3], tmp.i1[4]);

    *a = tmp.i8;

    return *a;
}
#endif /* HAVE_MATIO_INT64_T */

#ifdef HAVE_MATIO_UINT64_T
/** @brief swap the bytes of a 64-bit unsigned integer
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static mat_uint64_t
Mat_uint64Swap(mat_uint64_t *a)
{
    union {
        mat_uint8_t i1[8];
        mat_uint64_t i8;
    } tmp;

    tmp.i8 = *a;

    swap(tmp.i1[0], tmp.i1[7]);
    swap(tmp.i1[1], tmp.i1[6]);
    swap(tmp.i1[2], tmp.i1[5]);
    swap(tmp.i1[3], tmp.i1[4]);

    *a = tmp.i8;

    return *a;
}
#endif /* HAVE_MATIO_UINT64_T */

/** @brief swap the bytes of a 32-bit signed integer
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static mat_int32_t
Mat_int32Swap(mat_int32_t *a)
{
    union {
        mat_int8_t i1[4];
        mat_int32_t i4;
    } tmp;

    tmp.i4 = *a;

    swap(tmp.i1[0], tmp.i1[3]);
    swap(tmp.i1[1], tmp.i1[2]);

    *a = tmp.i4;

    return *a;
}

/** @brief swap the bytes of a 32-bit unsigned integer
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static mat_uint32_t
Mat_uint32Swap(mat_uint32_t *a)
{
    union {
        mat_uint8_t i1[4];
        mat_uint32_t i4;
    } tmp;

    tmp.i4 = *a;

    swap(tmp.i1[0], tmp.i1[3]);
    swap(tmp.i1[1], tmp.i1[2]);

    *a = tmp.i4;

    return *a;
}

/** @brief swap the bytes of a 16-bit signed integer
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static mat_int16_t
Mat_int16Swap(mat_int16_t *a)
{
    union {
        mat_int8_t i1[2];
        mat_int16_t i2;
    } tmp;

    tmp.i2 = *a;

    swap(tmp.i1[0], tmp.i1[1]);

    *a = tmp.i2;
    return *a;
}

/** @brief swap the bytes of a 16-bit unsigned integer
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static mat_uint16_t
Mat_uint16Swap(mat_uint16_t *a)
{
    union {
        mat_uint8_t i1[2];
        mat_uint16_t i2;
    } tmp;

    tmp.i2 = *a;

    swap(tmp.i1[0], tmp.i1[1]);

    *a = tmp.i2;
    return *a;
}

/** @brief swap the bytes of a 4 byte single-precision float
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static float
Mat_floatSwap(float *a)
{
    union {
        char i1[4];
        float r4;
    } tmp;

    tmp.r4 = *a;

    swap(tmp.i1[0], tmp.i1[3]);
    swap(tmp.i1[1], tmp.i1[2]);

    *a = tmp.r4;
    return *a;
}

/** @brief swap the bytes of a 4 or 8 byte double-precision float
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static double
Mat_doubleSwap(double *a)
{
#ifndef SIZEOF_DOUBLE
#define SIZEOF_DOUBLE 8
#endif

    union {
        char a[SIZEOF_DOUBLE];
        double b;
    } tmp;

    tmp.b = *a;

#if SIZEOF_DOUBLE == 4
    swap(tmp.a[0], tmp.a[3]);
    swap(tmp.a[1], tmp.a[2]);
#elif SIZEOF_DOUBLE == 8
    swap(tmp.a[0], tmp.a[7]);
    swap(tmp.a[1], tmp.a[6]);
    swap(tmp.a[2], tmp.a[5]);
    swap(tmp.a[3], tmp.a[4]);
#elif SIZEOF_DOUBLE == 16
    swap(tmp.a[0], tmp.a[15]);
    swap(tmp.a[1], tmp.a[14]);
    swap(tmp.a[2], tmp.a[13]);
    swap(tmp.a[3], tmp.a[12]);
    swap(tmp.a[4], tmp.a[11]);
    swap(tmp.a[5], tmp.a[10]);
    swap(tmp.a[6], tmp.a[9]);
    swap(tmp.a[7], tmp.a[8]);
#endif
    *a = tmp.b;
    return *a;
}

/* -------------------------------
 * ---------- inflate.c
 * -------------------------------
 */
/** @file inflate.c
 * @brief Functions to inflate data/tags
 * @ingroup MAT
 */

#if HAVE_ZLIB

/** @cond mat_devman */

/** @brief Inflate the data until @c nBytes of uncompressed data has been
 *         inflated
 *
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param z zlib compression stream
 * @param nBytes Number of uncompressed bytes to skip
 * @param[out] bytesread Number of bytes read from the file
 * @retval 0 on success

 */
static int
InflateSkip(mat_t *mat, z_streamp z, int nBytes, size_t *bytesread)
{
    mat_uint8_t comp_buf[READ_BLOCK_SIZE], uncomp_buf[READ_BLOCK_SIZE];
    int n, err = MATIO_E_NO_ERROR, cnt = 0;

    if ( nBytes < 1 )
        return MATIO_E_NO_ERROR;

    n = nBytes < READ_BLOCK_SIZE ? nBytes : READ_BLOCK_SIZE;
    if ( !z->avail_in ) {
        size_t nbytes = fread(comp_buf, 1, n, (FILE *)mat->fp);
        if ( 0 == nbytes ) {
            return err;
        }
        if ( NULL != bytesread ) {
            *bytesread += nbytes;
        }
        z->avail_in = (uInt)nbytes;
        z->next_in = comp_buf;
    }
    z->avail_out = n;
    z->next_out = uncomp_buf;
    err = inflate(z, Z_FULL_FLUSH);
    if ( err == Z_STREAM_END ) {
        return MATIO_E_NO_ERROR;
    } else if ( err != Z_OK ) {
        Mat_Critical("InflateSkip: inflate returned %s",
                     zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return MATIO_E_FILE_FORMAT_VIOLATION;
    } else {
        err = MATIO_E_NO_ERROR;
    }
    if ( !z->avail_out ) {
        cnt += n;
        n = nBytes - cnt;
        if ( n > READ_BLOCK_SIZE ) {
            n = READ_BLOCK_SIZE;
        }
        z->avail_out = n;
        z->next_out = uncomp_buf;
    }
    while ( cnt < nBytes ) {
        if ( !z->avail_in ) {
            size_t nbytes = fread(comp_buf, 1, n, (FILE *)mat->fp);
            if ( 0 == nbytes ) {
                break;
            }
            if ( NULL != bytesread ) {
                *bytesread += nbytes;
            }
            z->avail_in = (uInt)nbytes;
            z->next_in = comp_buf;
        }
        err = inflate(z, Z_FULL_FLUSH);
        if ( err == Z_STREAM_END ) {
            err = MATIO_E_NO_ERROR;
            break;
        } else if ( err != Z_OK ) {
            const char *errMsg = zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err);
            err = MATIO_E_FILE_FORMAT_VIOLATION;
            Mat_Critical("InflateSkip: inflate returned %s", errMsg);
            break;
        } else {
            err = MATIO_E_NO_ERROR;
        }
        if ( !z->avail_out ) {
            cnt += n;
            n = nBytes - cnt;
            if ( n > READ_BLOCK_SIZE ) {
                n = READ_BLOCK_SIZE;
            }
            z->avail_out = n;
            z->next_out = uncomp_buf;
        }
    }

    if ( z->avail_in ) {
        const long offset = -(long)z->avail_in;
        (void)fseek((FILE *)mat->fp, offset, SEEK_CUR);
        if ( NULL != bytesread ) {
            *bytesread -= z->avail_in;
        }
        z->avail_in = 0;
    }

    return err;
}

/** @brief Inflate the data until @c len elements of compressed data with data
 *         type @c data_type has been inflated
 *
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param z zlib compression stream
 * @param data_type Data type (matio_types enumerations)
 * @param len Number of elements of datatype @c data_type to skip
 * @param[out] bytesread Number of bytes read from the file
 * @retval 0 on success

 */
static int
InflateSkipData(mat_t *mat, z_streamp z, enum matio_types data_type, int len)
{
    if ( mat == NULL || z == NULL || len < 1 )
        return MATIO_E_BAD_ARGUMENT;

    switch ( data_type ) {
        case MAT_T_UTF8:
        case MAT_T_UTF16:
        case MAT_T_UTF32:
            return MATIO_E_OPERATION_NOT_SUPPORTED;
        default:
            break;
    }

    return InflateSkip(mat, z, (unsigned int)Mat_SizeOf(data_type) * len, NULL);
}

/** @brief Inflates the dimensions tag and the dimensions data
 *
 * @c buf must hold at least (8+4*rank) bytes where rank is the number of
 * dimensions. If the end of the dimensions data is not aligned on an 8-byte
 * boundary, this function eats up those bytes and stores then in @c buf.
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param z zlib compression stream
 * @param buf Pointer to store the dimensions flag and data
 * @param nBytes Size of buf in bytes
 * @param dims Output buffer to be allocated if (8+4*rank) > nBytes
 * @param[out] bytesread Number of bytes read from the file
 * @retval 0 on success

 */
static int
InflateRankDims(mat_t *mat, z_streamp z, void *buf, size_t nBytes, mat_uint32_t **dims,
                size_t *bytesread)
{
    mat_int32_t tag[2];
    int rank, i, err;

    if ( buf == NULL )
        return MATIO_E_BAD_ARGUMENT;

    err = Inflate(mat, z, buf, 8, bytesread);
    if ( err ) {
        return err;
    }
    tag[0] = *(int *)buf;
    tag[1] = *((int *)buf + 1);
    if ( mat->byteswap ) {
        Mat_int32Swap(tag);
        Mat_int32Swap(tag + 1);
    }
    if ( (tag[0] & 0x0000ffff) != MAT_T_INT32 ) {
        Mat_Critical("InflateRankDims: Reading dimensions expected type MAT_T_INT32");
        return MATIO_E_FILE_FORMAT_VIOLATION;
    }
    rank = tag[1];
    if ( rank % 8 != 0 )
        i = 8 - (rank % 8);
    else
        i = 0;
    rank += i;

    if ( sizeof(mat_uint32_t) * (rank + 2) <= nBytes ) {
        err = Inflate(mat, z, (mat_int32_t *)buf + 2, (unsigned int)rank, bytesread);
    } else {
        /* Cannot use too small buf, but can allocate output buffer dims */
        *dims = (mat_uint32_t *)calloc(rank, sizeof(mat_uint32_t));
        if ( NULL != *dims ) {
            err = Inflate(mat, z, *dims, (unsigned int)rank, bytesread);
        } else {
            *((mat_int32_t *)buf + 1) = 0;
            Mat_Critical("Error allocating memory for dims");
            return MATIO_E_OUT_OF_MEMORY;
        }
    }

    return err;
}

/** @brief Inflates the data
 *
 * buf must hold at least @c nBytes bytes
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param z zlib compression stream
 * @param buf Pointer to store the uncompressed data
 * @param nBytes Number of uncompressed bytes to inflate
 * @param[out] bytesread Number of bytes read from the file
 * @retval 0 on success

 */
static int
Inflate(mat_t *mat, z_streamp z, void *buf, unsigned int nBytes, size_t *bytesread)
{
    mat_uint8_t comp_buf[4];
    int err = MATIO_E_NO_ERROR;

    if ( buf == NULL )
        return MATIO_E_BAD_ARGUMENT;

    if ( !z->avail_in ) {
        size_t nbytes = fread(comp_buf, 1, 1, (FILE *)mat->fp);
        if ( 0 == nbytes ) {
            return err;
        }
        if ( NULL != bytesread ) {
            *bytesread += nbytes;
        }
        z->avail_in = (uInt)nbytes;
        z->next_in = comp_buf;
    }
    z->avail_out = nBytes;
    z->next_out = ZLIB_BYTE_PTR(buf);
    err = inflate(z, Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("Inflate: inflate returned %s",
                     zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return MATIO_E_FILE_FORMAT_VIOLATION;
    } else {
        err = MATIO_E_NO_ERROR;
    }
    while ( z->avail_out && !z->avail_in ) {
        size_t nbytes = fread(comp_buf, 1, 1, (FILE *)mat->fp);
        if ( 0 == nbytes ) {
            break;
        }
        if ( NULL != bytesread ) {
            *bytesread += nbytes;
        }
        z->avail_in = (uInt)nbytes;
        z->next_in = comp_buf;
        err = inflate(z, Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("Inflate: inflate returned %s",
                         zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            return MATIO_E_FILE_FORMAT_VIOLATION;
        } else {
            err = MATIO_E_NO_ERROR;
        }
    }

    if ( z->avail_in ) {
        const long offset = -(long)z->avail_in;
        (void)fseek((FILE *)mat->fp, offset, SEEK_CUR);
        if ( NULL != bytesread ) {
            *bytesread -= z->avail_in;
        }
        z->avail_in = 0;
    }

    if ( z->avail_out && feof((FILE *)mat->fp) ) {
        Mat_Warning(
            "Unexpected end-of-file: "
            "Processed %u bytes, expected %u bytes",
            nBytes - z->avail_out, nBytes);
        memset(buf, 0, nBytes);
    }

    return err;
}

/** @brief Inflates the data in blocks
 *
 * buf must hold at least @c nBytes bytes
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param z zlib compression stream
 * @param buf Pointer to store the uncompressed data
 * @param nBytes Number of uncompressed bytes to inflate
 * @param[out] bytesread Number of bytes read from the file
 * @retval 0 on success

 */
static int
InflateData(mat_t *mat, z_streamp z, void *buf, unsigned int nBytes)
{
    mat_uint8_t comp_buf[READ_BLOCK_SIZE];
    int err = MATIO_E_NO_ERROR;
    unsigned int n;
    size_t bytesread = 0;

    if ( buf == NULL )
        return MATIO_E_BAD_ARGUMENT;
    if ( nBytes == 0 ) {
        return MATIO_E_NO_ERROR;
    }

    n = nBytes < READ_BLOCK_SIZE ? nBytes : READ_BLOCK_SIZE;
    if ( !z->avail_in ) {
        size_t nbytes = fread(comp_buf, 1, n, (FILE *)mat->fp);
        if ( 0 == nbytes ) {
            return err;
        }
        bytesread += nbytes;
        z->avail_in = (uInt)nbytes;
        z->next_in = comp_buf;
    }
    z->avail_out = nBytes;
    z->next_out = ZLIB_BYTE_PTR(buf);
    err = inflate(z, Z_FULL_FLUSH);
    if ( err == Z_STREAM_END ) {
        return MATIO_E_NO_ERROR;
    } else if ( err != Z_OK ) {
        Mat_Critical("InflateData: inflate returned %s",
                     zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return MATIO_E_FAIL_TO_IDENTIFY;
    } else {
        err = MATIO_E_NO_ERROR;
    }
    while ( z->avail_out && !z->avail_in ) {
        size_t nbytes;
        if ( nBytes > READ_BLOCK_SIZE + bytesread ) {
            nbytes = fread(comp_buf, 1, READ_BLOCK_SIZE, (FILE *)mat->fp);
        } else if ( nBytes < 1 + bytesread ) { /* Read a byte at a time */
            nbytes = fread(comp_buf, 1, 1, (FILE *)mat->fp);
        } else {
            nbytes = fread(comp_buf, 1, nBytes - bytesread, (FILE *)mat->fp);
        }
        if ( 0 == nbytes ) {
            break;
        }
        bytesread += nbytes;
        z->avail_in = (uInt)nbytes;
        z->next_in = comp_buf;
        err = inflate(z, Z_FULL_FLUSH);
        if ( err == Z_STREAM_END ) {
            err = MATIO_E_NO_ERROR;
            break;
        } else if ( err != Z_OK ) {
            const char *errMsg = zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err);
            err = MATIO_E_FAIL_TO_IDENTIFY;
            Mat_Critical("InflateData: inflate returned %s", errMsg);
            break;
        } else {
            err = MATIO_E_NO_ERROR;
        }
    }

    if ( z->avail_in ) {
        const long offset = -(long)z->avail_in;
        (void)fseek((FILE *)mat->fp, offset, SEEK_CUR);
        bytesread -= z->avail_in;
        z->avail_in = 0;
    }

    if ( z->avail_out && feof((FILE *)mat->fp) ) {
        Mat_Warning("InflateData: Read beyond EOF error: Processed %u bytes, expected %u bytes",
                    nBytes - z->avail_out, nBytes);
        memset(buf, 0, nBytes);
    }

    return err;
}

/** @endcond */

#endif

/* -------------------------------
 * ---------- io.c
 * -------------------------------
 */
/** @file io.c
 * MAT File I/O Utility Functions
 */
#if defined(_WIN32) && defined(_MSC_VER)
#define WIN32_LEAN_AND_MEAN
#define NOGDI
#include <Windows.h>
#endif

#if !defined(HAVE_VA_COPY) && !defined(va_copy) && defined(HAVE___VA_COPY)
#define va_copy(d, s) __va_copy(d, s)
#elif !defined(HAVE_VA_COPY) && !defined(va_copy)
#define va_copy(d, s) memcpy(&(d), &(s), sizeof(va_list))
#endif

#if defined(_WIN32) && defined(_MSC_VER)
/** @brief Convert from narrow UTF-8 string to wide string
 *
 * @ingroup mat_util
 * @param src narrow string
 * @return Pointer to resulting wide string, or NULL if there was an error
 */
wchar_t *
utf82u(const char *src)
{
    if ( NULL != src ) {
        int srcLen = (int)strlen(src);
        if ( 0 != srcLen ) {
            int rc = MultiByteToWideChar(CP_UTF8, 0, src, srcLen, 0, 0);
            if ( 0 != rc ) {
                wchar_t *w = (wchar_t *)malloc(sizeof(wchar_t) * (rc + 1));
                if ( NULL != w ) {
                    w[rc] = L'\0';
                    rc = MultiByteToWideChar(CP_UTF8, 0, src, srcLen, w, rc);
                    if ( 0 != rc ) {
                        return w;
                    } else {
                        free(w);
                    }
                }
            }
        } else {
            wchar_t *w = (wchar_t *)malloc(sizeof(wchar_t));
            if ( NULL != w ) {
                w[0] = L'\0';
                return w;
            }
        }
    }
    return NULL;
}
#endif

/** @brief Logs a Critical message and aborts the program
 *
 * Logs an Error message and aborts
 * @ingroup mat_util
 * @param format format string identical to printf format
 * @param ... arguments to the format string
 */
void
Mat_Critical(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    ModelicaVFormatError(format, ap);
    va_end(ap);
}

/** @brief Prints a warning message
 *
 * Logs a warning message then returns
 * @ingroup mat_util
 * @param format format string identical to printf format
 * @param ... arguments to the format string
 */
void
Mat_Warning(const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    ModelicaVFormatWarning(format, ap);
    va_end(ap);
}

/** @brief Calculate the size of MAT data types
 *
 * @ingroup mat_util
 * @param data_type Data type enumeration
 * @return size of the data type in bytes
 */
size_t
Mat_SizeOf(enum matio_types data_type)
{
    switch ( data_type ) {
        case MAT_T_DOUBLE:
            return sizeof(double);
        case MAT_T_SINGLE:
            return sizeof(float);
#ifdef HAVE_MATIO_INT64_T
        case MAT_T_INT64:
            return sizeof(mat_int64_t);
#endif
#ifdef HAVE_MATIO_UINT64_T
        case MAT_T_UINT64:
            return sizeof(mat_uint64_t);
#endif
        case MAT_T_INT32:
            return sizeof(mat_int32_t);
        case MAT_T_UINT32:
            return sizeof(mat_uint32_t);
        case MAT_T_INT16:
            return sizeof(mat_int16_t);
        case MAT_T_UINT16:
            return sizeof(mat_uint16_t);
        case MAT_T_INT8:
            return sizeof(mat_int8_t);
        case MAT_T_UINT8:
            return sizeof(mat_uint8_t);
        case MAT_T_UTF8:
            return 1;
        case MAT_T_UTF16:
            return 2;
        case MAT_T_UTF32:
            return 4;
        default:
            return 0;
    }
}

/* -------------------------------
 * ---------- read_data.c
 * -------------------------------
 */
/** @file read_data.c
 * Matlab MAT version 5 file functions
 * @ingroup MAT
 */

/* FIXME: Implement Unicode support */

#define READ_DATA_NOSWAP(T)                                           \
    do {                                                              \
        const size_t block_size = READ_BLOCK_SIZE / data_size;        \
        if ( len <= block_size ) {                                    \
            readcount = fread(v, data_size, len, (FILE *)mat->fp);    \
            if ( readcount == len ) {                                 \
                for ( i = 0; i < len; i++ ) {                         \
                    data[i] = (T)v[i];                                \
                }                                                     \
            }                                                         \
        } else {                                                      \
            size_t j;                                                 \
            int err = 0;                                              \
            readcount = 0;                                            \
            for ( i = 0; i < len - block_size; i += block_size ) {    \
                j = fread(v, data_size, block_size, (FILE *)mat->fp); \
                readcount += j;                                       \
                if ( j == block_size ) {                              \
                    for ( j = 0; j < block_size; j++ ) {              \
                        data[i + j] = (T)v[j];                        \
                    }                                                 \
                } else {                                              \
                    err = 1;                                          \
                    break;                                            \
                }                                                     \
            }                                                         \
            if ( 0 == err && len > i ) {                              \
                j = fread(v, data_size, len - i, (FILE *)mat->fp);    \
                readcount += j;                                       \
                if ( j == len - i ) {                                 \
                    for ( j = 0; j < len - i; j++ ) {                 \
                        data[i + j] = (T)v[j];                        \
                    }                                                 \
                }                                                     \
            }                                                         \
        }                                                             \
    } while ( 0 )

#define READ_DATA(T, SwapFunc)                                            \
    do {                                                                  \
        if ( mat->byteswap ) {                                            \
            const size_t block_size = READ_BLOCK_SIZE / data_size;        \
            if ( len <= block_size ) {                                    \
                readcount = fread(v, data_size, len, (FILE *)mat->fp);    \
                if ( readcount == len ) {                                 \
                    for ( i = 0; i < len; i++ ) {                         \
                        data[i] = (T)SwapFunc(&v[i]);                     \
                    }                                                     \
                }                                                         \
            } else {                                                      \
                size_t j;                                                 \
                int err = 0;                                              \
                readcount = 0;                                            \
                for ( i = 0; i < len - block_size; i += block_size ) {    \
                    j = fread(v, data_size, block_size, (FILE *)mat->fp); \
                    readcount += j;                                       \
                    if ( j == block_size ) {                              \
                        for ( j = 0; j < block_size; j++ ) {              \
                            data[i + j] = (T)SwapFunc(&v[j]);             \
                        }                                                 \
                    } else {                                              \
                        err = 1;                                          \
                        break;                                            \
                    }                                                     \
                }                                                         \
                if ( 0 == err && len > i ) {                              \
                    j = fread(v, data_size, len - i, (FILE *)mat->fp);    \
                    readcount += j;                                       \
                    if ( j == len - i ) {                                 \
                        for ( j = 0; j < len - i; j++ ) {                 \
                            data[i + j] = (T)SwapFunc(&v[j]);             \
                        }                                                 \
                    }                                                     \
                }                                                         \
            }                                                             \
        } else {                                                          \
            READ_DATA_NOSWAP(T);                                          \
        }                                                                 \
    } while ( 0 )

#if HAVE_ZLIB
#define READ_COMPRESSED_DATA_NOSWAP(T)                         \
    do {                                                       \
        const size_t block_size = READ_BLOCK_SIZE / data_size; \
        if ( len <= block_size ) {                             \
            InflateData(mat, z, v, len *data_size);            \
            for ( i = 0; i < len; i++ ) {                      \
                data[i] = (T)v[i];                             \
            }                                                  \
        } else {                                               \
            mat_uint32_t j;                                    \
            len -= block_size;                                 \
            for ( i = 0; i < len; i += block_size ) {          \
                InflateData(mat, z, v, block_size *data_size); \
                for ( j = 0; j < block_size; j++ ) {           \
                    data[i + j] = (T)v[j];                     \
                }                                              \
            }                                                  \
            len -= (i - block_size);                           \
            InflateData(mat, z, v, len *data_size);            \
            for ( j = 0; j < len; j++ ) {                      \
                data[i + j] = (T)v[j];                         \
            }                                                  \
        }                                                      \
    } while ( 0 )

#define READ_COMPRESSED_DATA(T, SwapFunc)                          \
    do {                                                           \
        if ( mat->byteswap ) {                                     \
            const size_t block_size = READ_BLOCK_SIZE / data_size; \
            if ( len <= block_size ) {                             \
                InflateData(mat, z, v, len *data_size);            \
                for ( i = 0; i < len; i++ ) {                      \
                    data[i] = (T)SwapFunc(&v[i]);                  \
                }                                                  \
            } else {                                               \
                mat_uint32_t j;                                    \
                len -= block_size;                                 \
                for ( i = 0; i < len; i += block_size ) {          \
                    InflateData(mat, z, v, block_size *data_size); \
                    for ( j = 0; j < block_size; j++ ) {           \
                        data[i + j] = (T)SwapFunc(&v[j]);          \
                    }                                              \
                }                                                  \
                len -= (i - block_size);                           \
                InflateData(mat, z, v, len *data_size);            \
                for ( j = 0; j < len; j++ ) {                      \
                    data[i + j] = (T)SwapFunc(&v[j]);              \
                }                                                  \
            }                                                      \
        } else {                                                   \
            READ_COMPRESSED_DATA_NOSWAP(T);                        \
        }                                                          \
    } while ( 0 )

#endif

/*
 * --------------------------------------------------------------------------
 *    Routines to read data of any type into arrays of a specific type
 * --------------------------------------------------------------------------
 */

/** @cond mat_devman */

#define READ_TYPE_DOUBLE 1
#define READ_TYPE_SINGLE 2
#define READ_TYPE_INT64 3
#define READ_TYPE_UINT64 4
#define READ_TYPE_INT32 5
#define READ_TYPE_UINT32 6
#define READ_TYPE_INT16 7
#define READ_TYPE_UINT16 8
#define READ_TYPE_INT8 9
#define READ_TYPE_UINT8 10

#define READ_TYPE double
#define READ_TYPE_TYPE READ_TYPE_DOUBLE
#define READ_TYPED_FUNC1 ReadDoubleData
#define READ_TYPED_FUNC2 ReadCompressedDoubleData
#include "read_data_impl.h"
#undef READ_TYPE
#undef READ_TYPE_TYPE
#undef READ_TYPED_FUNC1
#undef READ_TYPED_FUNC2

#define READ_TYPE float
#define READ_TYPE_TYPE READ_TYPE_SINGLE
#define READ_TYPED_FUNC1 ReadSingleData
#define READ_TYPED_FUNC2 ReadCompressedSingleData
#include "read_data_impl.h"
#undef READ_TYPE
#undef READ_TYPE_TYPE
#undef READ_TYPED_FUNC1
#undef READ_TYPED_FUNC2

#ifdef HAVE_MATIO_INT64_T
#define READ_TYPE mat_int64_t
#define READ_TYPE_TYPE READ_TYPE_INT64
#define READ_TYPED_FUNC1 ReadInt64Data
#define READ_TYPED_FUNC2 ReadCompressedInt64Data
#include "read_data_impl.h"
#undef READ_TYPE
#undef READ_TYPE_TYPE
#undef READ_TYPED_FUNC1
#undef READ_TYPED_FUNC2
#endif /* HAVE_MATIO_INT64_T */

#ifdef HAVE_MATIO_UINT64_T
#define READ_TYPE mat_uint64_t
#define READ_TYPE_TYPE READ_TYPE_UINT64
#define READ_TYPED_FUNC1 ReadUInt64Data
#define READ_TYPED_FUNC2 ReadCompressedUInt64Data
#include "read_data_impl.h"
#undef READ_TYPE
#undef READ_TYPE_TYPE
#undef READ_TYPED_FUNC1
#undef READ_TYPED_FUNC2
#endif /* HAVE_MATIO_UINT64_T */

#define READ_TYPE mat_int32_t
#define READ_TYPE_TYPE READ_TYPE_INT32
#define READ_TYPED_FUNC1 ReadInt32Data
#define READ_TYPED_FUNC2 ReadCompressedInt32Data
#include "read_data_impl.h"
#undef READ_TYPE
#undef READ_TYPE_TYPE
#undef READ_TYPED_FUNC1
#undef READ_TYPED_FUNC2

#define READ_TYPE mat_uint32_t
#define READ_TYPE_TYPE READ_TYPE_UINT32
#define READ_TYPED_FUNC1 ReadUInt32Data
#define READ_TYPED_FUNC2 ReadCompressedUInt32Data
#include "read_data_impl.h"
#undef READ_TYPE
#undef READ_TYPE_TYPE
#undef READ_TYPED_FUNC1
#undef READ_TYPED_FUNC2

#define READ_TYPE mat_int16_t
#define READ_TYPE_TYPE READ_TYPE_INT16
#define READ_TYPED_FUNC1 ReadInt16Data
#define READ_TYPED_FUNC2 ReadCompressedInt16Data
#include "read_data_impl.h"
#undef READ_TYPE
#undef READ_TYPE_TYPE
#undef READ_TYPED_FUNC1
#undef READ_TYPED_FUNC2

#define READ_TYPE mat_uint16_t
#define READ_TYPE_TYPE READ_TYPE_UINT16
#define READ_TYPED_FUNC1 ReadUInt16Data
#define READ_TYPED_FUNC2 ReadCompressedUInt16Data
#include "read_data_impl.h"
#undef READ_TYPE
#undef READ_TYPE_TYPE
#undef READ_TYPED_FUNC1
#undef READ_TYPED_FUNC2

#define READ_TYPE mat_int8_t
#define READ_TYPE_TYPE READ_TYPE_INT8
#define READ_TYPED_FUNC1 ReadInt8Data
#define READ_TYPED_FUNC2 ReadCompressedInt8Data
#include "read_data_impl.h"
#undef READ_TYPE
#undef READ_TYPE_TYPE
#undef READ_TYPED_FUNC1
#undef READ_TYPED_FUNC2

#define READ_TYPE mat_uint8_t
#define READ_TYPE_TYPE READ_TYPE_UINT8
#define READ_TYPED_FUNC1 ReadUInt8Data
#define READ_TYPED_FUNC2 ReadCompressedUInt8Data
#include "read_data_impl.h"
#undef READ_TYPE
#undef READ_TYPE_TYPE
#undef READ_TYPED_FUNC1
#undef READ_TYPED_FUNC2

#if HAVE_ZLIB
/** @brief Reads data of type @c data_type into a char type
 *
 * Reads from the MAT file @c len compressed elements of data type @c data_type
 * storing them as char's in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z Pointer to the zlib stream for inflation
 * @param data Pointer to store the output char values (len*sizeof(char))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadCompressedCharData(mat_t *mat, z_streamp z, void *data, enum matio_types data_type, size_t len)
{
    size_t nBytes = 0;
    int err;

    if ( mat == NULL || data == NULL || mat->fp == NULL )
        return 0;

    err = Mul(&nBytes, len, Mat_SizeOf(data_type));
    if ( err ) {
        return 0;
    }

    switch ( data_type ) {
        case MAT_T_UINT8:
        case MAT_T_UTF8:
            err = InflateData(mat, z, data, (mat_uint32_t)nBytes);
            break;
        case MAT_T_UINT16:
        case MAT_T_UTF16:
            err = InflateData(mat, z, data, (mat_uint32_t)nBytes);
            if ( mat->byteswap ) {
                mat_uint16_t *ptr = (mat_uint16_t *)data;
                size_t i;
                for ( i = 0; i < len; i++ ) {
                    Mat_uint16Swap((mat_uint16_t *)&ptr[i]);
                }
            }
            break;
        default:
            Mat_Warning(
                "ReadCompressedCharData: %d is not a supported data "
                "type for character data",
                data_type);
            break;
    }

    if ( err ) {
        nBytes = 0;
    }
    return (int)nBytes;
}
#endif

static size_t
ReadCharData(mat_t *mat, void *_data, enum matio_types data_type, size_t len)
{
    size_t nBytes = 0;
    int err = 0;
    size_t data_size;

    if ( mat == NULL || _data == NULL || mat->fp == NULL )
        return 0;

    data_size = Mat_SizeOf(data_type);

    switch ( data_type ) {
        case MAT_T_UINT8:
        case MAT_T_UTF8: {
            err = Read(_data, data_size, len, (FILE *)mat->fp, &nBytes);
            break;
        }
        case MAT_T_UINT16:
        case MAT_T_UTF16: {
            size_t i, readcount;
            mat_uint16_t *data = (mat_uint16_t *)_data;
            mat_uint16_t v[READ_BLOCK_SIZE / sizeof(mat_uint16_t)];
            READ_DATA(mat_uint16_t, Mat_uint16Swap);
            err = Mul(&nBytes, readcount, data_size);
            break;
        }
        default:
            Mat_Warning(
                "ReadCharData: %d is not a supported data type for "
                "character data",
                data_type);
            break;
    }
    if ( err ) {
        nBytes = 0;
    }
    return nBytes;
}

#undef READ_DATA
#undef READ_DATA_NOSWAP

/*
 *-------------------------------------------------------------------
 *  Routines to read "slabs" of data
 *-------------------------------------------------------------------
 */

#define READ_DATA_SLABN_RANK_LOOP                                                                \
    do {                                                                                         \
        for ( j = 1; j < rank; j++ ) {                                                           \
            cnt[j]++;                                                                            \
            if ( (cnt[j] % edge[j]) == 0 ) {                                                     \
                cnt[j] = 0;                                                                      \
                if ( (I % dimp[j]) != 0 ) {                                                      \
                    (void)fseek((FILE *)mat->fp,                                                 \
                                data_size *(dimp[j] - (I % dimp[j]) + dimp[j - 1] * start[j]),   \
                                SEEK_CUR);                                                       \
                    I += dimp[j] - (I % dimp[j]) + (ptrdiff_t)dimp[j - 1] * start[j];            \
                } else if ( start[j] ) {                                                         \
                    (void)fseek((FILE *)mat->fp, data_size *(dimp[j - 1] * start[j]), SEEK_CUR); \
                    I += (ptrdiff_t)dimp[j - 1] * start[j];                                      \
                }                                                                                \
            } else {                                                                             \
                I += inc[j];                                                                     \
                (void)fseek((FILE *)mat->fp, data_size *inc[j], SEEK_CUR);                       \
                break;                                                                           \
            }                                                                                    \
        }                                                                                        \
    } while ( 0 )

#define READ_DATA_SLABN(ReadDataFunc)                                                              \
    do {                                                                                           \
        inc[0] = stride[0] - 1;                                                                    \
        dimp[0] = dims[0];                                                                         \
        N = edge[0];                                                                               \
        I = 0; /* start[0]; */                                                                     \
        for ( i = 1; i < rank; i++ ) {                                                             \
            inc[i] = stride[i] - 1;                                                                \
            dimp[i] = dims[i - 1];                                                                 \
            for ( j = i; j--; ) {                                                                  \
                inc[i] *= dims[j];                                                                 \
                dimp[i] *= dims[j + 1];                                                            \
            }                                                                                      \
            N *= edge[i];                                                                          \
            I += (ptrdiff_t)dimp[i - 1] * start[i];                                                \
        }                                                                                          \
        (void)fseek((FILE *)mat->fp, I *data_size, SEEK_CUR);                                      \
        if ( stride[0] == 1 ) {                                                                    \
            for ( i = 0; i < N; i += edge[0] ) {                                                   \
                if ( start[0] ) {                                                                  \
                    (void)fseek((FILE *)mat->fp, start[0] * data_size, SEEK_CUR);                  \
                    I += start[0];                                                                 \
                }                                                                                  \
                ReadDataFunc(mat, ptr + i, data_type, edge[0]);                                    \
                I += dims[0] - start[0];                                                           \
                (void)fseek((FILE *)mat->fp, data_size *(dims[0] - edge[0] - start[0]), SEEK_CUR); \
                READ_DATA_SLABN_RANK_LOOP;                                                         \
            }                                                                                      \
        } else {                                                                                   \
            for ( i = 0; i < N; i += edge[0] ) {                                                   \
                if ( start[0] ) {                                                                  \
                    (void)fseek((FILE *)mat->fp, start[0] * data_size, SEEK_CUR);                  \
                    I += start[0];                                                                 \
                }                                                                                  \
                for ( j = 0; j < edge[0]; j++ ) {                                                  \
                    ReadDataFunc(mat, ptr + i + j, data_type, 1);                                  \
                    (void)fseek((FILE *)mat->fp, data_size *(stride[0] - 1), SEEK_CUR);            \
                    I += stride[0];                                                                \
                }                                                                                  \
                I += dims[0] - (ptrdiff_t)edge[0] * stride[0] - start[0];                          \
                (void)fseek((FILE *)mat->fp,                                                       \
                            data_size *(dims[0] - (ptrdiff_t)edge[0] * stride[0] - start[0]),      \
                            SEEK_CUR);                                                             \
                READ_DATA_SLABN_RANK_LOOP;                                                         \
            }                                                                                      \
        }                                                                                          \
    } while ( 0 )

/** @brief Reads data of type @c data_type by user-defined dimensions
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data Pointer to store the output data
 * @param class_type Type of data class (matio_classes enumerations)
 * @param data_type Datatype of the stored data (matio_types enumerations)
 * @param rank Number of dimensions in the data
 * @param dims Dimensions of the data
 * @param start Index to start reading data in each dimension
 * @param stride Read every @c stride elements in each dimension
 * @param edge Number of elements to read in each dimension
 * @retval Number of bytes read from the file, or -1 on error
 */
static int
ReadDataSlabN(mat_t *mat, void *data, enum matio_classes class_type, enum matio_types data_type,
              int rank, size_t *dims, int *start, int *stride, int *edge)
{
    int nBytes = 0, i, j, N, I = 0;
    int inc[10] =
        {
            0,
        },
        cnt[10] =
            {
                0,
            },
        dimp[10] = {
            0,
        };
    size_t data_size;

    if ( (mat == NULL) || (data == NULL) || (mat->fp == NULL) || (start == NULL) ||
         (stride == NULL) || (edge == NULL) ) {
        return -1;
    } else if ( rank > 10 ) {
        return -1;
    }

    data_size = Mat_SizeOf(data_type);

    switch ( class_type ) {
        case MAT_C_DOUBLE: {
            double *ptr = (double *)data;
            READ_DATA_SLABN(ReadDoubleData);
            break;
        }
        case MAT_C_SINGLE: {
            float *ptr = (float *)data;
            READ_DATA_SLABN(ReadSingleData);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64: {
            mat_int64_t *ptr = (mat_int64_t *)data;
            READ_DATA_SLABN(ReadInt64Data);
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64: {
            mat_uint64_t *ptr = (mat_uint64_t *)data;
            READ_DATA_SLABN(ReadUInt64Data);
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32: {
            mat_int32_t *ptr = (mat_int32_t *)data;
            READ_DATA_SLABN(ReadInt32Data);
            break;
        }
        case MAT_C_UINT32: {
            mat_uint32_t *ptr = (mat_uint32_t *)data;
            READ_DATA_SLABN(ReadUInt32Data);
            break;
        }
        case MAT_C_INT16: {
            mat_int16_t *ptr = (mat_int16_t *)data;
            READ_DATA_SLABN(ReadInt16Data);
            break;
        }
        case MAT_C_UINT16: {
            mat_uint16_t *ptr = (mat_uint16_t *)data;
            READ_DATA_SLABN(ReadUInt16Data);
            break;
        }
        case MAT_C_INT8: {
            mat_int8_t *ptr = (mat_int8_t *)data;
            READ_DATA_SLABN(ReadInt8Data);
            break;
        }
        case MAT_C_UINT8: {
            mat_uint8_t *ptr = (mat_uint8_t *)data;
            READ_DATA_SLABN(ReadUInt8Data);
            break;
        }
        default:
            nBytes = 0;
    }
    return nBytes;
}

#undef READ_DATA_SLABN
#undef READ_DATA_SLABN_RANK_LOOP

#if HAVE_ZLIB
#define READ_COMPRESSED_DATA_SLABN_RANK_LOOP                                           \
    do {                                                                               \
        for ( j = 1; j < rank; j++ ) {                                                 \
            cnt[j]++;                                                                  \
            if ( (cnt[j] % edge[j]) == 0 ) {                                           \
                cnt[j] = 0;                                                            \
                if ( (I % dimp[j]) != 0 ) {                                            \
                    InflateSkipData(mat, &z_copy, data_type,                           \
                                    dimp[j] - (I % dimp[j]) + dimp[j - 1] * start[j]); \
                    I += dimp[j] - (I % dimp[j]) + (ptrdiff_t)dimp[j - 1] * start[j];  \
                } else if ( start[j] ) {                                               \
                    InflateSkipData(mat, &z_copy, data_type, dimp[j - 1] * start[j]);  \
                    I += (ptrdiff_t)dimp[j - 1] * start[j];                            \
                }                                                                      \
            } else {                                                                   \
                if ( inc[j] ) {                                                        \
                    I += inc[j];                                                       \
                    InflateSkipData(mat, &z_copy, data_type, inc[j]);                  \
                }                                                                      \
                break;                                                                 \
            }                                                                          \
        }                                                                              \
    } while ( 0 )

#define READ_COMPRESSED_DATA_SLABN(ReadDataFunc)                                                \
    do {                                                                                        \
        inc[0] = stride[0] - 1;                                                                 \
        dimp[0] = dims[0];                                                                      \
        N = edge[0];                                                                            \
        I = 0;                                                                                  \
        for ( i = 1; i < rank; i++ ) {                                                          \
            inc[i] = stride[i] - 1;                                                             \
            dimp[i] = dims[i - 1];                                                              \
            for ( j = i; j--; ) {                                                               \
                inc[i] *= dims[j];                                                              \
                dimp[i] *= dims[j + 1];                                                         \
            }                                                                                   \
            N *= edge[i];                                                                       \
            I += (ptrdiff_t)dimp[i - 1] * start[i];                                             \
        }                                                                                       \
        /* Skip all data to the starting indices */                                             \
        InflateSkipData(mat, &z_copy, data_type, I);                                            \
        if ( stride[0] == 1 ) {                                                                 \
            for ( i = 0; i < N; i += edge[0] ) {                                                \
                if ( start[0] ) {                                                               \
                    InflateSkipData(mat, &z_copy, data_type, start[0]);                         \
                    I += start[0];                                                              \
                }                                                                               \
                ReadDataFunc(mat, &z_copy, ptr + i, data_type, edge[0]);                        \
                InflateSkipData(mat, &z_copy, data_type, dims[0] - start[0] - edge[0]);         \
                I += dims[0] - start[0];                                                        \
                READ_COMPRESSED_DATA_SLABN_RANK_LOOP;                                           \
            }                                                                                   \
        } else {                                                                                \
            for ( i = 0; i < N; i += edge[0] ) {                                                \
                if ( start[0] ) {                                                               \
                    InflateSkipData(mat, &z_copy, data_type, start[0]);                         \
                    I += start[0];                                                              \
                }                                                                               \
                for ( j = 0; j < edge[0] - 1; j++ ) {                                           \
                    ReadDataFunc(mat, &z_copy, ptr + i + j, data_type, 1);                      \
                    InflateSkipData(mat, &z_copy, data_type, (stride[0] - 1));                  \
                    I += stride[0];                                                             \
                }                                                                               \
                ReadDataFunc(mat, &z_copy, ptr + i + j, data_type, 1);                          \
                I += dims[0] - (ptrdiff_t)(edge[0] - 1) * stride[0] - start[0];                 \
                InflateSkipData(mat, &z_copy, data_type,                                        \
                                dims[0] - (ptrdiff_t)(edge[0] - 1) * stride[0] - start[0] - 1); \
                READ_COMPRESSED_DATA_SLABN_RANK_LOOP;                                           \
            }                                                                                   \
        }                                                                                       \
    } while ( 0 )

/** @brief Reads data of type @c data_type by user-defined dimensions
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z zlib compression stream
 * @param data Pointer to store the output data
 * @param class_type Type of data class (matio_classes enumerations)
 * @param data_type Datatype of the stored data (matio_types enumerations)
 * @param rank Number of dimensions in the data
 * @param dims Dimensions of the data
 * @param start Index to start reading data in each dimension
 * @param stride Read every @c stride elements in each dimension
 * @param edge Number of elements to read in each dimension
 * @retval Number of bytes read from the file, or -1 on error
 */
static int
ReadCompressedDataSlabN(mat_t *mat, z_streamp z, void *data, enum matio_classes class_type,
                        enum matio_types data_type, int rank, size_t *dims, int *start, int *stride,
                        int *edge)
{
    int nBytes = 0, i, j, N, I = 0, err;
    int inc[10] =
        {
            0,
        },
        cnt[10] =
            {
                0,
            },
        dimp[10] = {
            0,
        };
    z_stream z_copy = {
        0,
    };

    if ( (mat == NULL) || (data == NULL) || (mat->fp == NULL) || (start == NULL) ||
         (stride == NULL) || (edge == NULL) ) {
        return 0;
    } else if ( rank > 10 ) {
        return 0;
    }

    err = inflateCopy(&z_copy, z);
    if ( err != Z_OK ) {
        Mat_Critical("inflateCopy returned error %s", zError(err));
        return -1;
    }
    switch ( class_type ) {
        case MAT_C_DOUBLE: {
            double *ptr = (double *)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedDoubleData);
            break;
        }
        case MAT_C_SINGLE: {
            float *ptr = (float *)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedSingleData);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64: {
            mat_int64_t *ptr = (mat_int64_t *)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedInt64Data);
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64: {
            mat_uint64_t *ptr = (mat_uint64_t *)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedUInt64Data);
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32: {
            mat_int32_t *ptr = (mat_int32_t *)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedInt32Data);
            break;
        }
        case MAT_C_UINT32: {
            mat_uint32_t *ptr = (mat_uint32_t *)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedUInt32Data);
            break;
        }
        case MAT_C_INT16: {
            mat_int16_t *ptr = (mat_int16_t *)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedInt16Data);
            break;
        }
        case MAT_C_UINT16: {
            mat_uint16_t *ptr = (mat_uint16_t *)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedUInt16Data);
            break;
        }
        case MAT_C_INT8: {
            mat_int8_t *ptr = (mat_int8_t *)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedInt8Data);
            break;
        }
        case MAT_C_UINT8: {
            mat_uint8_t *ptr = (mat_uint8_t *)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedUInt8Data);
            break;
        }
        default:
            nBytes = 0;
    }
    inflateEnd(&z_copy);
    return nBytes;
}

#undef READ_COMPRESSED_DATA_SLABN
#undef READ_COMPRESSED_DATA_SLABN_RANK_LOOP
#endif

#define READ_DATA_SLAB1(ReadDataFunc)                                  \
    do {                                                               \
        if ( !stride ) {                                               \
            bytesread += ReadDataFunc(mat, ptr, data_type, edge);      \
        } else {                                                       \
            for ( i = 0; i < edge; i++ ) {                             \
                bytesread += ReadDataFunc(mat, ptr + i, data_type, 1); \
                (void)fseek((FILE *)mat->fp, stride, SEEK_CUR);        \
            }                                                          \
        }                                                              \
    } while ( 0 )

/** @brief Reads data of type @c data_type by user-defined dimensions for 1-D
 *         data
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data Pointer to store the output data
 * @param class_type Type of data class (matio_classes enumerations)
 * @param data_type Datatype of the stored data (matio_types enumerations)
 * @param start Index to start reading data
 * @param stride Read every @c stride elements
 * @param edge Number of elements to read
 * @return Number of bytes read from the file, or -1 on error
 */
static int
ReadDataSlab1(mat_t *mat, void *data, enum matio_classes class_type, enum matio_types data_type,
              int start, int stride, int edge)
{
    int i;
    size_t data_size;
    int bytesread = 0;

    data_size = Mat_SizeOf(data_type);
    (void)fseek((FILE *)mat->fp, start * data_size, SEEK_CUR);
    stride = data_size * (stride - 1);

    switch ( class_type ) {
        case MAT_C_DOUBLE: {
            double *ptr = (double *)data;
            READ_DATA_SLAB1(ReadDoubleData);
            break;
        }
        case MAT_C_SINGLE: {
            float *ptr = (float *)data;
            READ_DATA_SLAB1(ReadSingleData);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64: {
            mat_int64_t *ptr = (mat_int64_t *)data;
            READ_DATA_SLAB1(ReadInt64Data);
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64: {
            mat_uint64_t *ptr = (mat_uint64_t *)data;
            READ_DATA_SLAB1(ReadUInt64Data);
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32: {
            mat_int32_t *ptr = (mat_int32_t *)data;
            READ_DATA_SLAB1(ReadInt32Data);
            break;
        }
        case MAT_C_UINT32: {
            mat_uint32_t *ptr = (mat_uint32_t *)data;
            READ_DATA_SLAB1(ReadUInt32Data);
            break;
        }
        case MAT_C_INT16: {
            mat_int16_t *ptr = (mat_int16_t *)data;
            READ_DATA_SLAB1(ReadInt16Data);
            break;
        }
        case MAT_C_UINT16: {
            mat_uint16_t *ptr = (mat_uint16_t *)data;
            READ_DATA_SLAB1(ReadUInt16Data);
            break;
        }
        case MAT_C_INT8: {
            mat_int8_t *ptr = (mat_int8_t *)data;
            READ_DATA_SLAB1(ReadInt8Data);
            break;
        }
        case MAT_C_UINT8: {
            mat_uint8_t *ptr = (mat_uint8_t *)data;
            READ_DATA_SLAB1(ReadUInt8Data);
            break;
        }
        default:
            return 0;
    }

    return bytesread;
}

#undef READ_DATA_SLAB1

#define READ_DATA_SLAB2(ReadDataFunc)                                                     \
    do {                                                                                  \
        /* If stride[0] is 1 and stride[1] is 1, we are reading all of the */             \
        /* data so get rid of the loops. */                                               \
        if ( (stride[0] == 1 && (size_t)edge[0] == dims[0]) && (stride[1] == 1) ) {       \
            ReadDataFunc(mat, ptr, data_type, (ptrdiff_t)edge[0] * edge[1]);              \
        } else {                                                                          \
            row_stride = (long)(stride[0] - 1) * data_size;                               \
            col_stride = (long)stride[1] * dims[0] * data_size;                           \
            pos = ftell((FILE *)mat->fp);                                                 \
            if ( pos == -1L ) {                                                           \
                Mat_Critical("Couldn't determine file position");                         \
                return -1;                                                                \
            }                                                                             \
            (void)fseek((FILE *)mat->fp, (long)start[1] * dims[0] * data_size, SEEK_CUR); \
            for ( i = 0; i < edge[1]; i++ ) {                                             \
                pos = ftell((FILE *)mat->fp);                                             \
                if ( pos == -1L ) {                                                       \
                    Mat_Critical("Couldn't determine file position");                     \
                    return -1;                                                            \
                }                                                                         \
                (void)fseek((FILE *)mat->fp, (long)start[0] * data_size, SEEK_CUR);       \
                for ( j = 0; j < edge[0]; j++ ) {                                         \
                    ReadDataFunc(mat, ptr++, data_type, 1);                               \
                    (void)fseek((FILE *)mat->fp, row_stride, SEEK_CUR);                   \
                }                                                                         \
                pos2 = ftell((FILE *)mat->fp);                                            \
                if ( pos2 == -1L ) {                                                      \
                    Mat_Critical("Couldn't determine file position");                     \
                    return -1;                                                            \
                }                                                                         \
                pos += col_stride - pos2;                                                 \
                (void)fseek((FILE *)mat->fp, pos, SEEK_CUR);                              \
            }                                                                             \
        }                                                                                 \
    } while ( 0 )

/** @brief Reads data of type @c data_type by user-defined dimensions for 2-D
 *         data
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data Pointer to store the output data
 * @param class_type Type of data class (matio_classes enumerations)
 * @param data_type Datatype of the stored data (matio_types enumerations)
 * @param dims Dimensions of the data
 * @param start Index to start reading data in each dimension
 * @param stride Read every @c stride elements in each dimension
 * @param edge Number of elements to read in each dimension
 * @retval Number of bytes read from the file, or -1 on error
 */
static int
ReadDataSlab2(mat_t *mat, void *data, enum matio_classes class_type, enum matio_types data_type,
              size_t *dims, int *start, int *stride, int *edge)
{
    int nBytes = 0, data_size, i, j;
    long pos, row_stride, col_stride, pos2;

    if ( (mat == NULL) || (data == NULL) || (mat->fp == NULL) || (start == NULL) ||
         (stride == NULL) || (edge == NULL) ) {
        return 0;
    }

    data_size = Mat_SizeOf(data_type);

    switch ( class_type ) {
        case MAT_C_DOUBLE: {
            double *ptr = (double *)data;
            READ_DATA_SLAB2(ReadDoubleData);
            break;
        }
        case MAT_C_SINGLE: {
            float *ptr = (float *)data;
            READ_DATA_SLAB2(ReadSingleData);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64: {
            mat_int64_t *ptr = (mat_int64_t *)data;
            READ_DATA_SLAB2(ReadInt64Data);
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64: {
            mat_uint64_t *ptr = (mat_uint64_t *)data;
            READ_DATA_SLAB2(ReadUInt64Data);
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32: {
            mat_int32_t *ptr = (mat_int32_t *)data;
            READ_DATA_SLAB2(ReadInt32Data);
            break;
        }
        case MAT_C_UINT32: {
            mat_uint32_t *ptr = (mat_uint32_t *)data;
            READ_DATA_SLAB2(ReadUInt32Data);
            break;
        }
        case MAT_C_INT16: {
            mat_int16_t *ptr = (mat_int16_t *)data;
            READ_DATA_SLAB2(ReadInt16Data);
            break;
        }
        case MAT_C_UINT16: {
            mat_uint16_t *ptr = (mat_uint16_t *)data;
            READ_DATA_SLAB2(ReadUInt16Data);
            break;
        }
        case MAT_C_INT8: {
            mat_int8_t *ptr = (mat_int8_t *)data;
            READ_DATA_SLAB2(ReadInt8Data);
            break;
        }
        case MAT_C_UINT8: {
            mat_uint8_t *ptr = (mat_uint8_t *)data;
            READ_DATA_SLAB2(ReadUInt8Data);
            break;
        }
        default:
            nBytes = 0;
    }
    return nBytes;
}

#undef READ_DATA_SLAB2

#if HAVE_ZLIB
#define READ_COMPRESSED_DATA_SLAB1(ReadDataFunc)                             \
    do {                                                                     \
        if ( !stride ) {                                                     \
            nBytes += ReadDataFunc(mat, &z_copy, ptr, data_type, edge);      \
        } else {                                                             \
            for ( i = 0; i < edge; i++ ) {                                   \
                nBytes += ReadDataFunc(mat, &z_copy, ptr + i, data_type, 1); \
                InflateSkipData(mat, &z_copy, data_type, stride);            \
            }                                                                \
        }                                                                    \
    } while ( 0 )

/** @brief Reads data of type @c data_type by user-defined dimensions for 1-D
 *         data
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z zlib compression stream
 * @param data Pointer to store the output data
 * @param class_type Type of data class (matio_classes enumerations)
 * @param data_type Datatype of the stored data (matio_types enumerations)
 * @param dims Dimensions of the data
 * @param start Index to start reading data in each dimension
 * @param stride Read every @c stride elements in each dimension
 * @param edge Number of elements to read in each dimension
 * @retval Number of bytes read from the file, or -1 on error
 */
static int
ReadCompressedDataSlab1(mat_t *mat, z_streamp z, void *data, enum matio_classes class_type,
                        enum matio_types data_type, int start, int stride, int edge)
{
    int nBytes = 0, i, err;
    z_stream z_copy = {
        0,
    };

    if ( (mat == NULL) || (data == NULL) || (mat->fp == NULL) )
        return 0;

    stride--;
    err = inflateCopy(&z_copy, z);
    if ( err != Z_OK ) {
        Mat_Critical("inflateCopy returned error %s", zError(err));
        return -1;
    }
    InflateSkipData(mat, &z_copy, data_type, start);
    switch ( class_type ) {
        case MAT_C_DOUBLE: {
            double *ptr = (double *)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedDoubleData);
            break;
        }
        case MAT_C_SINGLE: {
            float *ptr = (float *)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedSingleData);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64: {
            mat_int64_t *ptr = (mat_int64_t *)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedInt64Data);
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64: {
            mat_uint64_t *ptr = (mat_uint64_t *)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedUInt64Data);
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32: {
            mat_int32_t *ptr = (mat_int32_t *)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedInt32Data);
            break;
        }
        case MAT_C_UINT32: {
            mat_uint32_t *ptr = (mat_uint32_t *)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedUInt32Data);
            break;
        }
        case MAT_C_INT16: {
            mat_int16_t *ptr = (mat_int16_t *)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedInt16Data);
            break;
        }
        case MAT_C_UINT16: {
            mat_uint16_t *ptr = (mat_uint16_t *)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedUInt16Data);
            break;
        }
        case MAT_C_INT8: {
            mat_int8_t *ptr = (mat_int8_t *)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedInt8Data);
            break;
        }
        case MAT_C_UINT8: {
            mat_uint8_t *ptr = (mat_uint8_t *)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedUInt8Data);
            break;
        }
        default:
            break;
    }
    inflateEnd(&z_copy);
    return nBytes;
}

#undef READ_COMPRESSED_DATA_SLAB1

#define READ_COMPRESSED_DATA_SLAB2(ReadDataFunc)                                                  \
    do {                                                                                          \
        row_stride = (stride[0] - 1);                                                             \
        col_stride = (stride[1] - 1) * dims[0];                                                   \
        InflateSkipData(mat, &z_copy, data_type, start[1] * dims[0]);                             \
        /* If stride[0] is 1 and stride[1] is 1, we are reading all of the */                     \
        /* data so get rid of the loops.  If stride[0] is 1 and stride[1] */                      \
        /* is not 0, we are reading whole columns, so get rid of inner loop */                    \
        /* to speed up the code */                                                                \
        if ( (stride[0] == 1 && (size_t)edge[0] == dims[0]) && (stride[1] == 1) ) {               \
            ReadDataFunc(mat, &z_copy, ptr, data_type, (ptrdiff_t)edge[0] * edge[1]);             \
        } else if ( stride[0] == 1 ) {                                                            \
            for ( i = 0; i < edge[1]; i++ ) {                                                     \
                InflateSkipData(mat, &z_copy, data_type, start[0]);                               \
                ReadDataFunc(mat, &z_copy, ptr, data_type, edge[0]);                              \
                ptr += edge[0];                                                                   \
                pos = dims[0] - (ptrdiff_t)(edge[0] - 1) * stride[0] - 1 - start[0] + col_stride; \
                InflateSkipData(mat, &z_copy, data_type, pos);                                    \
            }                                                                                     \
        } else {                                                                                  \
            for ( i = 0; i < edge[1]; i++ ) {                                                     \
                InflateSkipData(mat, &z_copy, data_type, start[0]);                               \
                for ( j = 0; j < edge[0] - 1; j++ ) {                                             \
                    ReadDataFunc(mat, &z_copy, ptr++, data_type, 1);                              \
                    InflateSkipData(mat, &z_copy, data_type, row_stride);                         \
                }                                                                                 \
                ReadDataFunc(mat, &z_copy, ptr++, data_type, 1);                                  \
                pos = dims[0] - (ptrdiff_t)(edge[0] - 1) * stride[0] - 1 - start[0] + col_stride; \
                InflateSkipData(mat, &z_copy, data_type, pos);                                    \
            }                                                                                     \
        }                                                                                         \
    } while ( 0 )

/** @brief Reads data of type @c data_type by user-defined dimensions for 2-D
 *         data
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z zlib compression stream
 * @param data Pointer to store the output data
 * @param class_type Type of data class (matio_classes enumerations)
 * @param data_type Datatype of the stored data (matio_types enumerations)
 * @param dims Dimensions of the data
 * @param start Index to start reading data in each dimension
 * @param stride Read every @c stride elements in each dimension
 * @param edge Number of elements to read in each dimension
 * @retval Number of bytes read from the file, or -1 on error
 */
static int
ReadCompressedDataSlab2(mat_t *mat, z_streamp z, void *data, enum matio_classes class_type,
                        enum matio_types data_type, size_t *dims, int *start, int *stride,
                        int *edge)
{
    int nBytes = 0, i, j, err;
    int pos, row_stride, col_stride;
    z_stream z_copy = {
        0,
    };

    if ( (mat == NULL) || (data == NULL) || (mat->fp == NULL) || (start == NULL) ||
         (stride == NULL) || (edge == NULL) ) {
        return 0;
    }

    err = inflateCopy(&z_copy, z);
    if ( err != Z_OK ) {
        Mat_Critical("inflateCopy returned error %s", zError(err));
        return -1;
    }
    switch ( class_type ) {
        case MAT_C_DOUBLE: {
            double *ptr = (double *)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedDoubleData);
            break;
        }
        case MAT_C_SINGLE: {
            float *ptr = (float *)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedSingleData);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64: {
            mat_int64_t *ptr = (mat_int64_t *)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedInt64Data);
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64: {
            mat_uint64_t *ptr = (mat_uint64_t *)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedUInt64Data);
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32: {
            mat_int32_t *ptr = (mat_int32_t *)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedInt32Data);
            break;
        }
        case MAT_C_UINT32: {
            mat_uint32_t *ptr = (mat_uint32_t *)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedUInt32Data);
            break;
        }
        case MAT_C_INT16: {
            mat_int16_t *ptr = (mat_int16_t *)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedInt16Data);
            break;
        }
        case MAT_C_UINT16: {
            mat_uint16_t *ptr = (mat_uint16_t *)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedUInt16Data);
            break;
        }
        case MAT_C_INT8: {
            mat_int8_t *ptr = (mat_int8_t *)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedInt8Data);
            break;
        }
        case MAT_C_UINT8: {
            mat_uint8_t *ptr = (mat_uint8_t *)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedUInt8Data);
            break;
        }
        default:
            nBytes = 0;
    }
    inflateEnd(&z_copy);
    return nBytes;
}

#undef READ_COMPRESSED_DATA_SLAB2
#endif

/** @endcond */

/* -------------------------------
 * ---------- mat.c
 * -------------------------------
 */
/** @file mat.c
 * Matlab MAT file functions
 * @ingroup MAT
 */

/* FIXME: Implement Unicode support */

#ifndef MAT5_H
#define MAT5_H

static mat_t *Mat_Create5(const char *matname, const char *hdr_str);

static matvar_t *Mat_VarReadNextInfo5(mat_t *mat);
static int Mat_VarRead5(mat_t *mat, matvar_t *matvar);
static int Mat_VarReadData5(mat_t *mat, matvar_t *matvar, void *data, int *start, int *stride,
                            int *edge);
static int Mat_VarReadDataLinear5(mat_t *mat, matvar_t *matvar, void *data, int start, int stride,
                                  int edge);
static int Mat_VarWrite5(mat_t *mat, matvar_t *matvar, int compress);

#endif

#ifndef MAT4_H
#define MAT4_H

static mat_t *Mat_Create4(const char *matname);

static int Mat_VarWrite4(mat_t *mat, matvar_t *matvar);
static int Mat_VarRead4(mat_t *mat, matvar_t *matvar);
static int Mat_VarReadData4(mat_t *mat, matvar_t *matvar, void *data, int *start, int *stride,
                            int *edge);
static int Mat_VarReadDataLinear4(mat_t *mat, matvar_t *matvar, void *data, int start, int stride,
                                  int edge);
static matvar_t *Mat_VarReadNextInfo4(mat_t *mat);

#endif

#ifndef MAT73_H
#define MAT73_H

#if HAVE_HDF5
static mat_t *Mat_Create73(const char *matname, const char *hdr_str);
static int Mat_Close73(mat_t *mat);
static int Mat_VarRead73(mat_t *mat, matvar_t *matvar);
static int Mat_VarReadData73(mat_t *mat, matvar_t *matvar, void *data, int *start, int *stride,
                             int *edge);
static int Mat_VarReadDataLinear73(mat_t *mat, matvar_t *matvar, void *data, int start, int stride,
                                   int edge);
static matvar_t *Mat_VarReadNextInfo73(mat_t *mat);
static int Mat_VarWrite73(mat_t *mat, matvar_t *matvar, int compress);
static int Mat_VarWriteAppend73(mat_t *mat, matvar_t *matvar, int compress, int dim);
#endif
#endif

/*
 *===================================================================
 *                 Private Functions
 *===================================================================
 */

static char *
Mat_strdup(const char *s)
{
    size_t len = strlen(s) + 1;
    char *d = (char *)malloc(len);
    return d ? (char *)memcpy(d, s, len) : NULL;
}

#define MAT_MKTEMP_DIR "/tmp/"
#define MAT_MKTEMP_TPL "XXXXXX"
#define MAT_MKTEMP_FILE "/temp.mat"

#define MAT_MKTEMP_BUF_SIZE \
    (sizeof(MAT_MKTEMP_DIR) + sizeof(MAT_MKTEMP_TPL) + sizeof(MAT_MKTEMP_FILE) - 2)

static char *
Mat_mktemp(char *path_buf, char *dir_buf)
{
    char *ret = NULL;

    *path_buf = '\0';
    *dir_buf = '\0';

#if ( defined(_WIN64) || defined(_WIN32) ) && !defined(__CYGWIN__)
    strcpy(path_buf, MAT_MKTEMP_TPL);
    if ( NULL != _mktemp(path_buf) )
        ret = path_buf;
#else
    /* On Linux, using mktemp() causes annoying linker errors that can't be
       suppressed. So, create a temporary directory with mkdtemp() instead,
       and then just always use the same hardcoded filename inside that temp dir.
     */
    strcpy(dir_buf, MAT_MKTEMP_DIR MAT_MKTEMP_TPL);
    if ( NULL != mkdtemp(dir_buf) ) {
        strcpy(path_buf, dir_buf);
        strcat(path_buf, MAT_MKTEMP_FILE);
        ret = path_buf;
    }
#endif

    return ret;
}

static int
ReadData(mat_t *mat, matvar_t *matvar)
{
    if ( mat == NULL || matvar == NULL || mat->fp == NULL )
        return MATIO_E_BAD_ARGUMENT;
    else if ( mat->version == MAT_FT_MAT5 )
        return Mat_VarRead5(mat, matvar);
#if HAVE_HDF5
    else if ( mat->version == MAT_FT_MAT73 )
        return Mat_VarRead73(mat, matvar);
#endif
    else if ( mat->version == MAT_FT_MAT4 )
        return Mat_VarRead4(mat, matvar);
    return MATIO_E_FAIL_TO_IDENTIFY;
}

static void
Mat_PrintNumber(enum matio_types type, void *data)
{
    switch ( type ) {
        case MAT_T_DOUBLE:
            printf("%g", *(double *)data);
            break;
        case MAT_T_SINGLE:
            printf("%g", *(float *)data);
            break;
#ifdef HAVE_MATIO_INT64_T
        case MAT_T_INT64:
#if HAVE_INTTYPES_H
            printf("%" PRIi64, *(mat_int64_t *)data);
#elif defined(_MSC_VER) && _MSC_VER >= 1200
            printf("%I64i", *(mat_int64_t *)data);
#elif defined(HAVE_LONG_LONG_INT)
            printf("%lld", (long long)(*(mat_int64_t *)data));
#else
            printf("%ld", (long)(*(mat_int64_t *)data));
#endif
            break;
#endif
#ifdef HAVE_MATIO_UINT64_T
        case MAT_T_UINT64:
#if HAVE_INTTYPES_H
            printf("%" PRIu64, *(mat_uint64_t *)data);
#elif defined(_MSC_VER) && _MSC_VER >= 1200
            printf("%I64u", *(mat_uint64_t *)data);
#elif defined(HAVE_UNSIGNED_LONG_LONG_INT)
            printf("%llu", (unsigned long long)(*(mat_uint64_t *)data));
#else
            printf("%lu", (unsigned long)(*(mat_uint64_t *)data));
#endif
            break;
#endif
        case MAT_T_INT32:
            printf("%d", *(mat_int32_t *)data);
            break;
        case MAT_T_UINT32:
            printf("%u", *(mat_uint32_t *)data);
            break;
        case MAT_T_INT16:
            printf("%hd", *(mat_int16_t *)data);
            break;
        case MAT_T_UINT16:
            printf("%hu", *(mat_uint16_t *)data);
            break;
        case MAT_T_INT8:
#if defined(__GNUC__) && __STDC_VERSION__ >= 199901L
            printf("%hhd", *(mat_int8_t *)data);
#else
            printf("%hd", (mat_int16_t)(*(mat_int8_t *)data));
#endif
            break;
        case MAT_T_UINT8:
#if defined(__GNUC__) && __STDC_VERSION__ >= 199901L
            printf("%hhu", *(mat_uint8_t *)data);
#else
            printf("%hu", (mat_uint16_t)(*(mat_uint8_t *)data));
#endif
            break;
        default:
            break;
    }
}

static mat_complex_split_t *
ComplexMalloc(size_t nbytes)
{
    mat_complex_split_t *complex_data = (mat_complex_split_t *)malloc(sizeof(*complex_data));
    if ( NULL != complex_data ) {
        complex_data->Re = malloc(nbytes);
        if ( NULL != complex_data->Re ) {
            complex_data->Im = malloc(nbytes);
            if ( NULL == complex_data->Im ) {
                free(complex_data->Re);
                free(complex_data);
                complex_data = NULL;
            }
        } else {
            free(complex_data);
            complex_data = NULL;
        }
    }

    return complex_data;
}

static void
ComplexFree(mat_complex_split_t *complex_data)
{
    free(complex_data->Re);
    free(complex_data->Im);
    free(complex_data);
}

static enum matio_types
ClassType2DataType(enum matio_classes class_type)
{
    switch ( class_type ) {
        case MAT_C_DOUBLE:
            return MAT_T_DOUBLE;
        case MAT_C_SINGLE:
            return MAT_T_SINGLE;
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
            return MAT_T_INT64;
#endif
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
            return MAT_T_UINT64;
#endif
        case MAT_C_INT32:
            return MAT_T_INT32;
        case MAT_C_UINT32:
            return MAT_T_UINT32;
        case MAT_C_INT16:
            return MAT_T_INT16;
        case MAT_C_UINT16:
            return MAT_T_UINT16;
        case MAT_C_INT8:
            return MAT_T_INT8;
        case MAT_C_CHAR:
            return MAT_T_UINT8;
        case MAT_C_UINT8:
            return MAT_T_UINT8;
        case MAT_C_CELL:
            return MAT_T_CELL;
        case MAT_C_STRUCT:
            return MAT_T_STRUCT;
        default:
            return MAT_T_UNKNOWN;
    }
}

/** @brief Gets number of elements from a variable
 *
 * Gets number of elements from a variable by overflow-safe
 * multiplication
 * @ingroup MAT
 * @param matvar MAT variable information
 * @param nelems Number of elements
 * @retval 0 on success
 */
static int
Mat_MulDims(const matvar_t *matvar, size_t *nelems)
{
    int i;

    if ( matvar->rank == 0 ) {
        *nelems = 0;
        return MATIO_E_NO_ERROR;
    }

    for ( i = 0; i < matvar->rank; i++ ) {
#if HAVE_SAFE_MATH
        if ( !psnip_safe_size_mul(nelems, *nelems, matvar->dims[i]) ) {
            *nelems = 0;
            return MATIO_E_INDEX_TOO_BIG;
        }
#else
        *nelems *= matvar->dims[i];
#endif
    }

    return MATIO_E_NO_ERROR;
}

/** @brief Multiplies two unsigned integers
 *
 * @param res Result
 * @param a First operand
 * @param b Second operand
 * @retval 0 on success
 */
static int
Mul(size_t *res, size_t a, size_t b)
{
#if HAVE_SAFE_MATH
    if ( !psnip_safe_size_mul(res, a, b) ) {
        *res = 0;
        return MATIO_E_INDEX_TOO_BIG;
    }
#else
    *res = a * b;
#endif
    return MATIO_E_NO_ERROR;
}

/** @brief Adds two unsigned integers
 *
 * @param res Result
 * @param a First operand
 * @param b Second operand
 * @retval 0 on success
 */
static int
Add(size_t *res, size_t a, size_t b)
{
#if HAVE_SAFE_MATH
    if ( !psnip_safe_size_add(res, a, b) ) {
        *res = 0;
        return MATIO_E_INDEX_TOO_BIG;
    }
#else
    *res = a + b;
#endif
    return MATIO_E_NO_ERROR;
}

/** @brief Read from file and check success
 *
 * @param buf Buffer for reading
 * @param size Element size in bytes
 * @param count Element count
 * @param fp File pointer
 * @param[out] bytesread Number of bytes read from the file
 * @retval 0 on success
 */
static int
Read(void *buf, size_t size, size_t count, FILE *fp, size_t *bytesread)
{
    const size_t readcount = fread(buf, size, count, fp);
    int err = readcount != count;
    if ( NULL != bytesread ) {
        *bytesread += readcount * size;
    }
    if ( err ) {
        Mat_Warning(
            "Unexpected end-of-file: Read %zu"
            " bytes, expected %zu"
            " bytes",
            readcount * size, count * size);
        memset(buf, 0, count * size);
    }
    return err;
}

/** @brief Check for End of file
 *
 * @param fp File pointer
 * @param[out] fpos Current file position
 * @retval 0 on success
 */
static int
IsEndOfFile(FILE *fp, long *fpos)
{
    int isEOF = feof(fp);
    long fPos = ftell(fp);
    if ( !isEOF ) {
        if ( fPos == -1L ) {
            Mat_Critical("Couldn't determine file position");
        } else {
            (void)fseek(fp, 0, SEEK_END);
            isEOF = fPos == ftell(fp);
            if ( !isEOF ) {
                (void)fseek(fp, fPos, SEEK_SET);
            }
        }
    }
    if ( NULL != fpos ) {
        *fpos = fPos;
    }
    return isEOF;
}

/*
 *===================================================================
 *                 Public Functions
 *===================================================================
 */

/** @brief Get the version of the library
 *
 * Gets the version number of the library
 * @param major Pointer to store the library major version number
 * @param minor Pointer to store the library minor version number
 * @param release Pointer to store the library release version number
 */
void
Mat_GetLibraryVersion(int *major, int *minor, int *release)
{
    if ( NULL != major )
        *major = MATIO_MAJOR_VERSION;
    if ( NULL != minor )
        *minor = MATIO_MINOR_VERSION;
    if ( NULL != release )
        *release = MATIO_RELEASE_LEVEL;
}

/** @brief Creates a new Matlab MAT file
 *
 * Tries to create a new Matlab MAT file with the given name and optional
 * header string.  If no header string is given, the default string
 * is used containing the software, version, and date in it.  If a header
 * string is given, at most the first 116 characters is written to the file.
 * The given header string need not be the full 116 characters, but MUST be
 * NULL terminated.
 * @ingroup MAT
 * @param matname Name of MAT file to create
 * @param hdr_str Optional header string, NULL to use default
 * @param mat_file_ver MAT file version to create
 * @return A pointer to the MAT file or NULL if it failed.  This is not a
 * simple FILE * and should not be used as one.
 */
mat_t *
Mat_CreateVer(const char *matname, const char *hdr_str, enum mat_ft mat_file_ver)
{
    mat_t *mat;

    switch ( mat_file_ver ) {
        case MAT_FT_MAT4:
            mat = Mat_Create4(matname);
            break;
        case MAT_FT_MAT5:
            mat = Mat_Create5(matname, hdr_str);
            break;
        case MAT_FT_MAT73:
#if HAVE_HDF5
            mat = Mat_Create73(matname, hdr_str);
#else
            mat = NULL;
#endif
            break;
        default:
            mat = NULL;
            break;
    }

    return mat;
}

/** @brief Opens an existing Matlab MAT file
 *
 * Tries to open a Matlab MAT file with the given name
 * @ingroup MAT
 * @param matname Name of MAT file to open
 * @param mode File access mode (MAT_ACC_RDONLY,MAT_ACC_RDWR,etc).
 * @return A pointer to the MAT file or NULL if it failed.  This is not a
 * simple FILE * and should not be used as one.
 */
mat_t *
Mat_Open(const char *matname, int mode)
{
    FILE *fp = NULL;
    mat_int16_t tmp, tmp2;
    mat_t *mat = NULL;
    size_t bytesread = 0;

    if ( (mode & 0x01) == MAT_ACC_RDONLY ) {
#if defined(_WIN32) && defined(_MSC_VER)
        wchar_t *wname = utf82u(matname);
        if ( NULL != wname ) {
            fp = _wfopen(wname, L"rb");
            free(wname);
        }
#else
        fp = fopen(matname, "rb");
#endif
        if ( !fp )
            return NULL;
    } else if ( (mode & 0x01) == MAT_ACC_RDWR ) {
#if defined(_WIN32) && defined(_MSC_VER)
        wchar_t *wname = utf82u(matname);
        if ( NULL != wname ) {
            fp = _wfopen(wname, L"r+b");
            free(wname);
        }
#else
        fp = fopen(matname, "r+b");
#endif
        if ( !fp ) {
            mat = Mat_CreateVer(matname, NULL, (enum mat_ft)(mode & 0xfffffffe));
            return mat;
        }
    } else {
        Mat_Critical("Invalid file open mode");
        return NULL;
    }

    mat = (mat_t *)malloc(sizeof(*mat));
    if ( NULL == mat ) {
        fclose(fp);
        Mat_Critical("Couldn't allocate memory for the MAT file");
        return NULL;
    }

    mat->fp = fp;
    mat->header = (char *)calloc(128, sizeof(char));
    if ( NULL == mat->header ) {
        free(mat);
        fclose(fp);
        Mat_Critical("Couldn't allocate memory for the MAT file header");
        return NULL;
    }
    mat->subsys_offset = (char *)calloc(8, sizeof(char));
    if ( NULL == mat->subsys_offset ) {
        free(mat->header);
        free(mat);
        fclose(fp);
        Mat_Critical("Couldn't allocate memory for the MAT file subsys offset");
        return NULL;
    }
    mat->filename = NULL;
    mat->version = 0;
    mat->byteswap = 0;
    mat->num_datasets = 0;
#if HAVE_HDF5
    mat->refs_id = -1;
#endif
    mat->dir = NULL;

    bytesread += fread(mat->header, 1, 116, fp);
    mat->header[116] = '\0';
    bytesread += fread(mat->subsys_offset, 1, 8, fp);
    bytesread += 2 * fread(&tmp2, 2, 1, fp);
    bytesread += fread(&tmp, 1, 2, fp);

    if ( 128 == bytesread ) {
        /* v5 and v7.3 files have at least 128 byte header */
        mat->byteswap = -1;
        if ( tmp == 0x4d49 )
            mat->byteswap = 0;
        else if ( tmp == 0x494d ) {
            mat->byteswap = 1;
            Mat_int16Swap(&tmp2);
        }

        mat->version = (int)tmp2;
        if ( (mat->version == 0x0100 || mat->version == 0x0200) && -1 != mat->byteswap ) {
            mat->bof = ftell((FILE *)mat->fp);
            if ( mat->bof == -1L ) {
                free(mat->header);
                free(mat->subsys_offset);
                free(mat);
                fclose(fp);
                Mat_Critical("Couldn't determine file position");
                return NULL;
            }
            mat->next_index = 0;
        } else {
            mat->version = 0;
        }
    }

    if ( 0 == mat->version ) {
        /* Maybe a V4 MAT file */
        matvar_t *var;

        free(mat->header);
        free(mat->subsys_offset);

        mat->header = NULL;
        mat->subsys_offset = NULL;
        mat->fp = fp;
        mat->version = MAT_FT_MAT4;
        mat->byteswap = 0;
        mat->mode = mode;
        mat->bof = 0;
        mat->next_index = 0;
#if HAVE_HDF5
        mat->refs_id = -1;
#endif

        Mat_Rewind(mat);
        var = Mat_VarReadNextInfo4(mat);
        if ( NULL == var && bytesread != 0 ) { /* Accept 0 bytes files as a valid V4 file */
            /* Does not seem to be a valid V4 file */
            Mat_Close(mat);
            mat = NULL;
            Mat_Critical("\"%s\" does not seem to be a valid MAT file", matname);
        } else {
            Mat_VarFree(var);
            Mat_Rewind(mat);
        }
    }

    if ( NULL == mat )
        return mat;

    mat->filename = Mat_strdup(matname);
    mat->mode = mode;

    if ( mat->version == 0x0200 ) {
        fclose((FILE *)mat->fp);
#if HAVE_HDF5
        mat->fp = malloc(sizeof(hid_t));

        if ( (mode & 0x01) == MAT_ACC_RDONLY )
            *(hid_t *)mat->fp = H5Fopen(matname, H5F_ACC_RDONLY, H5P_DEFAULT);
        else if ( (mode & 0x01) == MAT_ACC_RDWR ) {
            hid_t plist_ap;
            plist_ap = H5Pcreate(H5P_FILE_ACCESS);
#if H5_VERSION_GE(1, 10, 2)
            H5Pset_libver_bounds(plist_ap, H5F_LIBVER_EARLIEST, H5F_LIBVER_V18);
#endif
            *(hid_t *)mat->fp = H5Fopen(matname, H5F_ACC_RDWR, plist_ap);
            H5Pclose(plist_ap);
        } else {
            mat->fp = NULL;
            Mat_Close(mat);
            mat = NULL;
        }

        if ( -1 < *(hid_t *)mat->fp ) {
            H5G_info_t group_info;
            herr_t herr;
            memset(&group_info, 0, sizeof(group_info));
            herr = H5Gget_info(*(hid_t *)mat->fp, &group_info);
            if ( herr < 0 ) {
                Mat_Close(mat);
                mat = NULL;
            } else {
                mat->num_datasets = (size_t)group_info.nlinks;
                mat->refs_id = -1;
            }
        }
#else
        mat->fp = NULL;
        Mat_Close(mat);
        mat = NULL;
        Mat_Critical(
            "No HDF5 support which is required to read the v7.3 "
            "MAT file \"%s\"",
            matname);
#endif
    }

    return mat;
}

/** @brief Closes an open Matlab MAT file
 *
 * Closes the given Matlab MAT file and frees any memory with it.
 * @ingroup MAT
 * @param mat Pointer to the MAT file
 * @retval 0 on success
 */
int
Mat_Close(mat_t *mat)
{
    int err = MATIO_E_NO_ERROR;

    if ( NULL != mat ) {
#if HAVE_HDF5
        if ( mat->version == 0x0200 ) {
            err = Mat_Close73(mat);
        }
#endif
        if ( NULL != mat->fp ) {
            err = fclose((FILE *)mat->fp);
            if ( 0 == err ) {
                err = MATIO_E_NO_ERROR;
            } else {
                err = MATIO_E_FILESYSTEM_ERROR_ON_CLOSE;
            }
        }
        if ( NULL != mat->header )
            free(mat->header);
        if ( NULL != mat->subsys_offset )
            free(mat->subsys_offset);
        if ( NULL != mat->filename )
            free(mat->filename);
        if ( NULL != mat->dir ) {
            size_t i;
            for ( i = 0; i < mat->num_datasets; i++ ) {
                if ( NULL != mat->dir[i] )
                    free(mat->dir[i]);
            }
            free(mat->dir);
        }
        free(mat);
    } else {
        err = MATIO_E_BAD_ARGUMENT;
    }

    return err;
}

/** @brief Gets the filename for the given MAT file
 *
 * Gets the filename for the given MAT file
 * @ingroup MAT
 * @param mat Pointer to the MAT file
 * @return MAT filename
 */
const char *
Mat_GetFilename(mat_t *mat)
{
    const char *filename = NULL;
    if ( NULL != mat )
        filename = mat->filename;
    return filename;
}

/** @brief Gets the header for the given MAT file
 *
 * Gets the header for the given MAT file
 * @ingroup MAT
 * @param mat Pointer to the MAT file
 * @return MAT header
 */
const char *
Mat_GetHeader(mat_t *mat)
{
    const char *header = NULL;
    if ( NULL != mat )
        header = mat->header;
    return header;
}

/** @brief Gets the version of the given MAT file
 *
 * Gets the version of the given MAT file
 * @ingroup MAT
 * @param mat Pointer to the MAT file
 * @return MAT file version
 */
enum mat_ft
Mat_GetVersion(mat_t *mat)
{
    enum mat_ft file_type = MAT_FT_UNDEFINED;
    if ( NULL != mat )
        file_type = (enum mat_ft)mat->version;
    return file_type;
}

/** @brief Gets a list of the variables of a MAT file
 *
 * Gets a list of the variables of a MAT file
 * @ingroup MAT
 * @param mat Pointer to the MAT file
 * @param[out] n Number of variables in the given MAT file
 * @return Array of variable names
 */
char **
Mat_GetDir(mat_t *mat, size_t *n)
{
    char **dir = NULL;

    if ( NULL == n )
        return dir;

    if ( NULL == mat ) {
        *n = 0;
        return dir;
    }

    if ( NULL == mat->dir ) {
        matvar_t *matvar = NULL;

        if ( mat->version == MAT_FT_MAT73 ) {
            size_t i = 0;
            size_t fpos = mat->next_index;
            if ( mat->num_datasets == 0 ) {
                *n = 0;
                return dir;
            }
            mat->dir = (char **)calloc(mat->num_datasets, sizeof(char *));
            if ( NULL == mat->dir ) {
                *n = 0;
                Mat_Critical("Couldn't allocate memory for the directory");
                return dir;
            }
            mat->next_index = 0;
            while ( mat->next_index < mat->num_datasets ) {
                matvar = Mat_VarReadNextInfo(mat);
                if ( NULL != matvar ) {
                    if ( NULL != matvar->name ) {
                        mat->dir[i++] = Mat_strdup(matvar->name);
                    }
                    Mat_VarFree(matvar);
                } else {
                    Mat_Critical("An error occurred in reading the MAT file");
                    break;
                }
            }
            mat->next_index = fpos;
            *n = i;
        } else {
            long fpos = ftell((FILE *)mat->fp);
            if ( fpos == -1L ) {
                *n = 0;
                Mat_Critical("Couldn't determine file position");
                return dir;
            }
            (void)fseek((FILE *)mat->fp, mat->bof, SEEK_SET);
            mat->num_datasets = 0;
            do {
                matvar = Mat_VarReadNextInfo(mat);
                if ( NULL != matvar ) {
                    if ( NULL != matvar->name ) {
                        if ( NULL == mat->dir ) {
                            dir = (char **)malloc(sizeof(char *));
                        } else {
                            dir = (char **)realloc(mat->dir,
                                                   (mat->num_datasets + 1) * (sizeof(char *)));
                        }
                        if ( NULL != dir ) {
                            mat->dir = dir;
                            mat->dir[mat->num_datasets++] = Mat_strdup(matvar->name);
                        } else {
                            Mat_Critical("Couldn't allocate memory for the directory");
                            break;
                        }
                    }
                    Mat_VarFree(matvar);
                } else if ( !IsEndOfFile((FILE *)mat->fp, NULL) ) {
                    Mat_Critical("An error occurred in reading the MAT file");
                    break;
                }
            } while ( !IsEndOfFile((FILE *)mat->fp, NULL) );
            (void)fseek((FILE *)mat->fp, fpos, SEEK_SET);
            *n = mat->num_datasets;
        }
    } else {
        if ( mat->version == MAT_FT_MAT73 ) {
            *n = 0;
            while ( *n < mat->num_datasets && NULL != mat->dir[*n] ) {
                (*n)++;
            }
        } else {
            *n = mat->num_datasets;
        }
    }
    dir = mat->dir;
    return dir;
}

/** @brief Rewinds a Matlab MAT file to the first variable
 *
 * Rewinds a Matlab MAT file to the first variable
 * @ingroup MAT
 * @param mat Pointer to the MAT file
 * @retval 0 on success
 */
int
Mat_Rewind(mat_t *mat)
{
    int err = MATIO_E_NO_ERROR;

    switch ( mat->version ) {
        case MAT_FT_MAT5:
            (void)fseek((FILE *)mat->fp, 128L, SEEK_SET);
            break;
        case MAT_FT_MAT73:
            mat->next_index = 0;
            break;
        case MAT_FT_MAT4:
            (void)fseek((FILE *)mat->fp, 0L, SEEK_SET);
            break;
        default:
            err = MATIO_E_FAIL_TO_IDENTIFY;
            break;
    }

    return err;
}

/** @brief Returns the size of a Matlab Class
 *
 * Returns the size (in bytes) of the matlab class class_type
 * @ingroup MAT
 * @param class_type Matlab class type (MAT_C_*)
 * @returns Size of the class
 */
size_t
Mat_SizeOfClass(int class_type)
{
    switch ( class_type ) {
        case MAT_C_DOUBLE:
            return sizeof(double);
        case MAT_C_SINGLE:
            return sizeof(float);
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
            return sizeof(mat_int64_t);
#endif
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
            return sizeof(mat_uint64_t);
#endif
        case MAT_C_INT32:
            return sizeof(mat_int32_t);
        case MAT_C_UINT32:
            return sizeof(mat_uint32_t);
        case MAT_C_INT16:
            return sizeof(mat_int16_t);
        case MAT_C_UINT16:
            return sizeof(mat_uint16_t);
        case MAT_C_INT8:
            return sizeof(mat_int8_t);
        case MAT_C_UINT8:
            return sizeof(mat_uint8_t);
        case MAT_C_CHAR:
            return sizeof(mat_int16_t);
        default:
            return 0;
    }
}

/*
 *===================================================================
 *    MAT Variable Functions
 *===================================================================
 */

/** @brief Allocates memory for a new matvar_t and initializes all the fields
 *
 * @ingroup MAT
 * @return A newly allocated matvar_t
 */
matvar_t *
Mat_VarCalloc(void)
{
    matvar_t *matvar;

    matvar = (matvar_t *)malloc(sizeof(*matvar));

    if ( NULL != matvar ) {
        matvar->nbytes = 0;
        matvar->rank = 0;
        matvar->data_type = MAT_T_UNKNOWN;
        matvar->data_size = 0;
        matvar->class_type = MAT_C_EMPTY;
        matvar->isComplex = 0;
        matvar->isGlobal = 0;
        matvar->isLogical = 0;
        matvar->dims = NULL;
        matvar->name = NULL;
        matvar->data = NULL;
        matvar->mem_conserve = 0;
        matvar->compression = MAT_COMPRESSION_NONE;
        matvar->internal = (struct matvar_internal *)malloc(sizeof(*matvar->internal));
        if ( NULL == matvar->internal ) {
            free(matvar);
            matvar = NULL;
        } else {
#if HAVE_HDF5
            matvar->internal->hdf5_name = NULL;
            matvar->internal->hdf5_ref = 0;
            matvar->internal->id = -1;
#endif
            matvar->internal->datapos = 0;
            matvar->internal->num_fields = 0;
            matvar->internal->fieldnames = NULL;
#if HAVE_ZLIB
            matvar->internal->z = NULL;
            matvar->internal->data = NULL;
#endif
        }
    }

    return matvar;
}

/** @brief Creates a MAT Variable with the given name and (optionally) data
 *
 * Creates a MAT variable that can be written to a Matlab MAT file with the
 * given name, data type, dimensions and data.  Rank should always be 2 or more.
 * i.e. Scalar values would have rank=2 and dims[2] = {1,1}.  Data type is
 * one of the MAT_T types.  MAT adds MAT_T_STRUCT and MAT_T_CELL to create
 * Structures and Cell Arrays respectively.  For MAT_T_STRUCT, data should be a
 * NULL terminated array of matvar_t * variables (i.e. for a 3x2 structure with
 * 10 fields, there should be 61 matvar_t * variables where the last one is
 * NULL).  For cell arrays, the NULL termination isn't necessary.  So to create
 * a cell array of size 3x2, data would be the address of an array of 6
 * matvar_t * variables.
 *
 * EXAMPLE:
 *   To create a struct of size 3x2 with 3 fields:
 * @code
 *     int rank=2, dims[2] = {3,2}, nfields = 3;
 *     matvar_t **vars;
 *
 *     vars = malloc((3*2*nfields+1)*sizeof(matvar_t *));
 *     vars[0]             = Mat_VarCreate(...);
 *        :
 *     vars[3*2*nfields-1] = Mat_VarCreate(...);
 *     vars[3*2*nfields]   = NULL;
 * @endcode
 *
 * EXAMPLE:
 *   To create a cell array of size 3x2:
 * @code
 *     int rank=2, dims[2] = {3,2};
 *     matvar_t **vars;
 *
 *     vars = malloc(3*2*sizeof(matvar_t *));
 *     vars[0]             = Mat_VarCreate(...);
 *        :
 *     vars[5] = Mat_VarCreate(...);
 * @endcode
 *
 * @ingroup MAT
 * @param name Name of the variable to create
 * @param class_type class type of the variable in Matlab(one of the mx Classes)
 * @param data_type data type of the variable (one of the MAT_T_ Types)
 * @param rank Rank of the variable
 * @param dims array of dimensions of the variable of size rank
 * @param data pointer to the data
 * @param opt 0, or bitwise or of the following options:
 * - MAT_F_DONT_COPY_DATA to just use the pointer to the data and not copy the
 *       data itself. Note that the pointer should not be freed until you are
 *       done with the mat variable.  The Mat_VarFree function will NOT free
 *       data that was created with MAT_F_DONT_COPY_DATA, so free it yourself.
 * - MAT_F_COMPLEX to specify that the data is complex.  The data variable
 *       should be a pointer to a mat_complex_split_t type.
 * - MAT_F_GLOBAL to assign the variable as a global variable
 * - MAT_F_LOGICAL to specify that it is a logical variable
 * @return A MAT variable that can be written to a file or otherwise used
 */
matvar_t *
Mat_VarCreate(const char *name, enum matio_classes class_type, enum matio_types data_type, int rank,
              size_t *dims, void *data, int opt)
{
    size_t nelems = 1, data_size;
    matvar_t *matvar = NULL;
    int j, err;

    if ( dims == NULL )
        return NULL;

    matvar = Mat_VarCalloc();
    if ( NULL == matvar )
        return NULL;

    matvar->compression = MAT_COMPRESSION_NONE;
    matvar->isComplex = opt & MAT_F_COMPLEX;
    matvar->isGlobal = opt & MAT_F_GLOBAL;
    matvar->isLogical = opt & MAT_F_LOGICAL;
    if ( name )
        matvar->name = Mat_strdup(name);
    matvar->rank = rank;
    matvar->dims = (size_t *)malloc(matvar->rank * sizeof(*matvar->dims));
    for ( j = 0; j < matvar->rank; j++ ) {
        matvar->dims[j] = dims[j];
        nelems *= dims[j];
    }
    matvar->class_type = class_type;
    matvar->data_type = data_type;
    switch ( data_type ) {
        case MAT_T_INT8:
            data_size = 1;
            break;
        case MAT_T_UINT8:
            data_size = 1;
            break;
        case MAT_T_INT16:
            data_size = 2;
            break;
        case MAT_T_UINT16:
            data_size = 2;
            break;
        case MAT_T_INT64:
            data_size = 8;
            break;
        case MAT_T_UINT64:
            data_size = 8;
            break;
        case MAT_T_INT32:
            data_size = 4;
            break;
        case MAT_T_UINT32:
            data_size = 4;
            break;
        case MAT_T_SINGLE:
            data_size = sizeof(float);
            break;
        case MAT_T_DOUBLE:
            data_size = sizeof(double);
            break;
        case MAT_T_UTF8:
            data_size = 1;
            break;
        case MAT_T_UTF16:
            data_size = 2;
            break;
        case MAT_T_UTF32:
            data_size = 4;
            break;
        case MAT_T_CELL:
            data_size = sizeof(matvar_t **);
            break;
        case MAT_T_STRUCT: {
            data_size = sizeof(matvar_t **);
            if ( data != NULL ) {
                matvar_t **fields = (matvar_t **)data;
                size_t nfields = 0;
                while ( fields[nfields] != NULL )
                    nfields++;
                if ( nelems )
                    nfields /= nelems;
                matvar->internal->num_fields = nfields;
                if ( nfields ) {
                    size_t i;
                    matvar->internal->fieldnames =
                        (char **)calloc(nfields, sizeof(*matvar->internal->fieldnames));
                    for ( i = 0; i < nfields; i++ )
                        matvar->internal->fieldnames[i] = Mat_strdup(fields[i]->name);
                    err = Mul(&nelems, nelems, nfields);
                    if ( err ) {
                        Mat_VarFree(matvar);
                        Mat_Critical("Integer multiplication overflow");
                        return NULL;
                    }
                }
            }
            break;
        }
        default:
            Mat_VarFree(matvar);
            Mat_Critical("Unrecognized data_type");
            return NULL;
    }
    if ( matvar->class_type == MAT_C_SPARSE ) {
        matvar->data_size = sizeof(mat_sparse_t);
        matvar->nbytes = matvar->data_size;
    } else if ( matvar->class_type == MAT_C_CHAR && matvar->data_type == MAT_T_UTF8 ) {
        size_t k = 0;
        if ( data != NULL ) {
            size_t i;
            mat_uint8_t *ptr = (mat_uint8_t *)data;
            for ( i = 0; i < nelems; i++ ) {
                const mat_uint8_t c = ptr[k];
                if ( c <= 0x7F ) {
                    k++;
                } else if ( (c & 0xE0) == 0xC0 ) {
                    k += 2;
                } else if ( (c & 0xF0) == 0xE0 ) {
                    k += 3;
                } else if ( (c & 0xF8) == 0xF0 ) {
                    k += 4;
                }
            }
        }
        matvar->nbytes = k;
        matvar->data_size = (int)data_size;
    } else {
        matvar->data_size = (int)data_size;
        err = Mul(&matvar->nbytes, nelems, matvar->data_size);
        if ( err ) {
            Mat_VarFree(matvar);
            Mat_Critical("Integer multiplication overflow");
            return NULL;
        }
    }
    if ( data == NULL ) {
        if ( MAT_C_CELL == matvar->class_type && nelems > 0 )
            matvar->data = calloc(nelems, sizeof(matvar_t *));
    } else if ( opt & MAT_F_DONT_COPY_DATA ) {
        matvar->data = data;
        matvar->mem_conserve = 1;
    } else if ( MAT_C_SPARSE == matvar->class_type ) {
        mat_sparse_t *sparse_data, *sparse_data_in;

        sparse_data_in = (mat_sparse_t *)data;
        sparse_data = (mat_sparse_t *)malloc(sizeof(mat_sparse_t));
        if ( NULL != sparse_data ) {
            sparse_data->nzmax = sparse_data_in->nzmax;
            sparse_data->nir = sparse_data_in->nir;
            sparse_data->njc = sparse_data_in->njc;
            sparse_data->ndata = sparse_data_in->ndata;
            sparse_data->ir = (mat_uint32_t *)malloc(sparse_data->nir * sizeof(*sparse_data->ir));
            if ( NULL != sparse_data->ir )
                memcpy(sparse_data->ir, sparse_data_in->ir,
                       sparse_data->nir * sizeof(*sparse_data->ir));
            sparse_data->jc = (mat_uint32_t *)malloc(sparse_data->njc * sizeof(*sparse_data->jc));
            if ( NULL != sparse_data->jc )
                memcpy(sparse_data->jc, sparse_data_in->jc,
                       sparse_data->njc * sizeof(*sparse_data->jc));
            if ( matvar->isComplex ) {
                sparse_data->data = malloc(sizeof(mat_complex_split_t));
                if ( NULL != sparse_data->data ) {
                    mat_complex_split_t *complex_data, *complex_data_in;
                    complex_data = (mat_complex_split_t *)sparse_data->data;
                    complex_data_in = (mat_complex_split_t *)sparse_data_in->data;
                    complex_data->Re = malloc(sparse_data->ndata * data_size);
                    complex_data->Im = malloc(sparse_data->ndata * data_size);
                    if ( NULL != complex_data->Re )
                        memcpy(complex_data->Re, complex_data_in->Re,
                               sparse_data->ndata * data_size);
                    if ( NULL != complex_data->Im )
                        memcpy(complex_data->Im, complex_data_in->Im,
                               sparse_data->ndata * data_size);
                }
            } else {
                sparse_data->data = malloc(sparse_data->ndata * data_size);
                if ( NULL != sparse_data->data )
                    memcpy(sparse_data->data, sparse_data_in->data, sparse_data->ndata * data_size);
            }
        }
        matvar->data = sparse_data;
    } else {
        if ( matvar->isComplex ) {
            matvar->data = malloc(sizeof(mat_complex_split_t));
            if ( NULL != matvar->data && matvar->nbytes > 0 ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t *)matvar->data;
                mat_complex_split_t *complex_data_in = (mat_complex_split_t *)data;

                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);
                if ( NULL != complex_data->Re )
                    memcpy(complex_data->Re, complex_data_in->Re, matvar->nbytes);
                if ( NULL != complex_data->Im )
                    memcpy(complex_data->Im, complex_data_in->Im, matvar->nbytes);
            }
        } else if ( matvar->nbytes > 0 ) {
            matvar->data = malloc(matvar->nbytes);
            if ( NULL != matvar->data )
                memcpy(matvar->data, data, matvar->nbytes);
        }
        matvar->mem_conserve = 0;
    }

    return matvar;
}

/** @brief Copies a file
 *
 * @param src source file path
 * @param dst destination file path
 * @retval 0 on success
 */
static int
Mat_CopyFile(const char *src, const char *dst)
{
    size_t len;
    char buf[BUFSIZ] = {'\0'};
    FILE *in = NULL;
    FILE *out = NULL;

#if defined(_WIN32) && defined(_MSC_VER)
    {
        wchar_t *wname = utf82u(src);
        if ( NULL != wname ) {
            in = _wfopen(wname, L"rb");
            free(wname);
        }
    }
#else
    in = fopen(src, "rb");
#endif
    if ( in == NULL ) {
        Mat_Critical("Cannot open file \"%s\" for reading.", src);
        return MATIO_E_FILESYSTEM_COULD_NOT_OPEN;
    }

#if defined(_WIN32) && defined(_MSC_VER)
    {
        wchar_t *wname = utf82u(dst);
        if ( NULL != wname ) {
            out = _wfopen(wname, L"wb");
            free(wname);
        }
    }
#else
    out = fopen(dst, "wb");
#endif
    if ( out == NULL ) {
        fclose(in);
        Mat_Critical("Cannot open file \"%s\" for writing.", dst);
        return MATIO_E_FILESYSTEM_COULD_NOT_OPEN;
    }

    while ( (len = fread(buf, sizeof(char), BUFSIZ, in)) > 0 ) {
        if ( len != fwrite(buf, sizeof(char), len, out) ) {
            fclose(in);
            fclose(out);
            Mat_Critical("Error writing to file \"%s\".", dst);
            return MATIO_E_GENERIC_WRITE_ERROR;
        }
    }
    fclose(in);
    fclose(out);
    return MATIO_E_NO_ERROR;
}

/** @brief Deletes a variable from a file
 *
 * @ingroup MAT
 * @param mat Pointer to the mat_t file structure
 * @param name Name of the variable to delete
 * @returns 0 on success
 */
int
Mat_VarDelete(mat_t *mat, const char *name)
{
    int err = MATIO_E_BAD_ARGUMENT;
    char path_buf[MAT_MKTEMP_BUF_SIZE];
    char dir_buf[MAT_MKTEMP_BUF_SIZE];

    if ( NULL == mat || NULL == name )
        return err;

    if ( NULL != Mat_mktemp(path_buf, dir_buf) ) {
        enum mat_ft mat_file_ver;
        mat_t *tmp;

        switch ( mat->version ) {
            case 0x0100:
                mat_file_ver = MAT_FT_MAT5;
                break;
            case 0x0200:
                mat_file_ver = MAT_FT_MAT73;
                break;
            case 0x0010:
                mat_file_ver = MAT_FT_MAT4;
                break;
            default:
                mat_file_ver = MAT_FT_DEFAULT;
                break;
        }

        tmp = Mat_CreateVer(path_buf, mat->header, mat_file_ver);
        if ( tmp != NULL ) {
            matvar_t *matvar;
            char **dir;
            size_t n;

            Mat_Rewind(mat);
            while ( NULL != (matvar = Mat_VarReadNext(mat)) ) {
                if ( 0 != strcmp(matvar->name, name) )
                    err = Mat_VarWrite(tmp, matvar, matvar->compression);
                else
                    err = MATIO_E_NO_ERROR;
                Mat_VarFree(matvar);
            }
            dir = tmp->dir; /* Keep directory for later assignment */
            tmp->dir = NULL;
            n = tmp->num_datasets;
            Mat_Close(tmp);

            if ( MATIO_E_NO_ERROR == err ) {
                char *new_name = Mat_strdup(mat->filename);
#if HAVE_HDF5
                if ( mat_file_ver == MAT_FT_MAT73 ) {
                    err = Mat_Close73(mat);
                }
#endif
                if ( mat->fp != NULL ) {
                    fclose((FILE *)mat->fp);
                    mat->fp = NULL;
                }

                if ( (err = Mat_CopyFile(path_buf, new_name)) != MATIO_E_NO_ERROR ) {
                    if ( NULL != dir ) {
                        size_t i;
                        for ( i = 0; i < n; i++ ) {
                            if ( dir[i] )
                                free(dir[i]);
                        }
                        free(dir);
                    }
                    Mat_Critical("Cannot copy file from \"%s\" to \"%s\".", path_buf, new_name);
                } else if ( (err = remove(path_buf)) != 0 ) {
                    err = MATIO_E_UNKNOWN_ERROR;
                    if ( NULL != dir ) {
                        size_t i;
                        for ( i = 0; i < n; i++ ) {
                            if ( dir[i] )
                                free(dir[i]);
                        }
                        free(dir);
                    }
                    Mat_Critical("Cannot remove file \"%s\".", path_buf);
                } else if ( *dir_buf != '\0' && (err = remove(dir_buf)) != 0 ) {
                    err = MATIO_E_UNKNOWN_ERROR;
                    if ( NULL != dir ) {
                        size_t i;
                        for ( i = 0; i < n; i++ ) {
                            if ( dir[i] )
                                free(dir[i]);
                        }
                        free(dir);
                    }
                    Mat_Critical("Cannot remove directory \"%s\".", dir_buf);
                } else {
                    tmp = Mat_Open(new_name, mat->mode);
                    if ( NULL != tmp ) {
                        if ( mat->header )
                            free(mat->header);
                        if ( mat->subsys_offset )
                            free(mat->subsys_offset);
                        if ( mat->filename )
                            free(mat->filename);
                        if ( mat->dir ) {
                            size_t i;
                            for ( i = 0; i < mat->num_datasets; i++ ) {
                                if ( mat->dir[i] )
                                    free(mat->dir[i]);
                            }
                            free(mat->dir);
                        }
                        memcpy(mat, tmp, sizeof(mat_t));
                        free(tmp);
                        mat->num_datasets = n;
                        mat->dir = dir;
                    } else {
                        Mat_Critical("Cannot open file \"%s\".", new_name);
                        err = MATIO_E_FILESYSTEM_COULD_NOT_OPEN;
                    }
                }
                free(new_name);
            } else if ( (err = remove(path_buf)) != 0 ) {
                err = MATIO_E_UNKNOWN_ERROR;
                Mat_Critical("Cannot remove file \"%s\".", path_buf);
            } else if ( *dir_buf != '\0' && (err = remove(dir_buf)) != 0 ) {
                err = MATIO_E_UNKNOWN_ERROR;
                Mat_Critical("Cannot remove directory \"%s\".", dir_buf);
            }
        } else {
            err = MATIO_E_UNKNOWN_ERROR;
        }
    } else {
        Mat_Critical("Cannot create a unique file name.");
        err = MATIO_E_FILESYSTEM_COULD_NOT_OPEN_TEMPORARY;
    }

    return err;
}

/** @brief Duplicates a matvar_t structure
 *
 * Provides a clean function for duplicating a matvar_t structure.
 * @ingroup MAT
 * @param in pointer to the matvar_t structure to be duplicated
 * @param opt 0 does a shallow duplicate and only assigns the data pointer to
 *            the duplicated array.  1 will do a deep duplicate and actually
 *            duplicate the contents of the data.  Warning: If you do a shallow
 *            copy and free both structures, the data will be freed twice and
 *            memory will be corrupted.  This may be fixed in a later release.
 * @returns Pointer to the duplicated matvar_t structure.
 */
matvar_t *
Mat_VarDuplicate(const matvar_t *in, int opt)
{
    matvar_t *out;
    size_t i;

    out = Mat_VarCalloc();
    if ( out == NULL )
        return NULL;

    out->nbytes = in->nbytes;
    out->rank = in->rank;
    out->data_type = in->data_type;
    out->data_size = in->data_size;
    out->class_type = in->class_type;
    out->isComplex = in->isComplex;
    out->isGlobal = in->isGlobal;
    out->isLogical = in->isLogical;
    out->mem_conserve = in->mem_conserve;
    out->compression = in->compression;

    if ( NULL != in->name ) {
        size_t len = strlen(in->name) + 1;
        out->name = (char *)malloc(len);
        if ( NULL != out->name )
            memcpy(out->name, in->name, len);
    }

    out->dims = (size_t *)malloc(in->rank * sizeof(*out->dims));
    if ( out->dims != NULL )
        memcpy(out->dims, in->dims, in->rank * sizeof(*out->dims));

    if ( NULL != in->internal ) {
#if HAVE_HDF5
        if ( NULL != in->internal->hdf5_name )
            out->internal->hdf5_name = Mat_strdup(in->internal->hdf5_name);

        out->internal->hdf5_ref = in->internal->hdf5_ref;
        out->internal->id = in->internal->id;
#endif
        out->internal->datapos = in->internal->datapos;
#if HAVE_ZLIB
        out->internal->z = NULL;
        out->internal->data = NULL;
#endif
        out->internal->num_fields = in->internal->num_fields;
        if ( NULL != in->internal->fieldnames && in->internal->num_fields > 0 ) {
            out->internal->fieldnames =
                (char **)calloc(in->internal->num_fields, sizeof(*in->internal->fieldnames));
            if ( NULL != out->internal->fieldnames ) {
                for ( i = 0; i < in->internal->num_fields; i++ ) {
                    if ( NULL != in->internal->fieldnames[i] )
                        out->internal->fieldnames[i] = Mat_strdup(in->internal->fieldnames[i]);
                }
            }
        }

#if HAVE_ZLIB
        if ( in->internal->z != NULL ) {
            out->internal->z = (z_streamp)malloc(sizeof(z_stream));
            if ( NULL != out->internal->z ) {
                int err = inflateCopy(out->internal->z, in->internal->z);
                if ( err != Z_OK ) {
                    free(out->internal->z);
                    out->internal->z = NULL;
                }
            }
        }
        if ( in->internal->data != NULL ) {
            if ( in->class_type == MAT_C_SPARSE ) {
                out->internal->data = malloc(sizeof(mat_sparse_t));
                if ( out->internal->data != NULL ) {
                    mat_sparse_t *out_sparse = (mat_sparse_t *)out->internal->data;
                    mat_sparse_t *in_sparse = (mat_sparse_t *)in->internal->data;
                    out_sparse->nzmax = in_sparse->nzmax;
                    out_sparse->nir = in_sparse->nir;
                    out_sparse->ir =
                        (mat_uint32_t *)malloc(in_sparse->nir * sizeof(*out_sparse->ir));
                    if ( out_sparse->ir != NULL )
                        memcpy(out_sparse->ir, in_sparse->ir,
                               in_sparse->nir * sizeof(*out_sparse->ir));
                    out_sparse->njc = in_sparse->njc;
                    out_sparse->jc =
                        (mat_uint32_t *)malloc(in_sparse->njc * sizeof(*out_sparse->jc));
                    if ( out_sparse->jc != NULL )
                        memcpy(out_sparse->jc, in_sparse->jc,
                               in_sparse->njc * sizeof(*out_sparse->jc));
                    out_sparse->ndata = in_sparse->ndata;
                    if ( out->isComplex && NULL != in_sparse->data ) {
                        out_sparse->data = malloc(sizeof(mat_complex_split_t));
                        if ( out_sparse->data != NULL ) {
                            mat_complex_split_t *out_data = (mat_complex_split_t *)out_sparse->data;
                            mat_complex_split_t *in_data = (mat_complex_split_t *)in_sparse->data;
                            out_data->Re = malloc(in_sparse->ndata * Mat_SizeOf(in->data_type));
                            if ( NULL != out_data->Re )
                                memcpy(out_data->Re, in_data->Re,
                                       in_sparse->ndata * Mat_SizeOf(in->data_type));
                            out_data->Im = malloc(in_sparse->ndata * Mat_SizeOf(in->data_type));
                            if ( NULL != out_data->Im )
                                memcpy(out_data->Im, in_data->Im,
                                       in_sparse->ndata * Mat_SizeOf(in->data_type));
                        }
                    } else if ( in_sparse->data != NULL ) {
                        out_sparse->data = malloc(in_sparse->ndata * Mat_SizeOf(in->data_type));
                        if ( NULL != out_sparse->data )
                            memcpy(out_sparse->data, in_sparse->data,
                                   in_sparse->ndata * Mat_SizeOf(in->data_type));
                    }
                }
            } else if ( out->isComplex ) {
                out->internal->data = malloc(sizeof(mat_complex_split_t));
                if ( out->internal->data != NULL ) {
                    mat_complex_split_t *out_data = (mat_complex_split_t *)out->internal->data;
                    mat_complex_split_t *in_data = (mat_complex_split_t *)in->internal->data;
                    out_data->Re = malloc(out->nbytes);
                    if ( NULL != out_data->Re )
                        memcpy(out_data->Re, in_data->Re, out->nbytes);
                    out_data->Im = malloc(out->nbytes);
                    if ( NULL != out_data->Im )
                        memcpy(out_data->Im, in_data->Im, out->nbytes);
                }
            } else if ( NULL != (out->internal->data = malloc(in->nbytes)) ) {
                memcpy(out->internal->data, in->internal->data, in->nbytes);
            }
        }
#endif
    } else {
        free(out->internal);
        out->internal = NULL;
    }

    if ( !opt ) {
        out->data = in->data;
    } else if ( (in->data != NULL) && (in->class_type == MAT_C_STRUCT) ) {
        out->data = malloc(in->nbytes);
        if ( out->data != NULL && in->data_size > 0 ) {
            size_t nfields = in->nbytes / in->data_size;
            matvar_t **infields = (matvar_t **)in->data;
            matvar_t **outfields = (matvar_t **)out->data;
            for ( i = 0; i < nfields; i++ ) {
                outfields[i] = Mat_VarDuplicate(infields[i], opt);
            }
        }
    } else if ( (in->data != NULL) && (in->class_type == MAT_C_CELL) ) {
        out->data = malloc(in->nbytes);
        if ( out->data != NULL && in->data_size > 0 ) {
            size_t nelems = in->nbytes / in->data_size;
            matvar_t **incells = (matvar_t **)in->data;
            matvar_t **outcells = (matvar_t **)out->data;
            for ( i = 0; i < nelems; i++ ) {
                outcells[i] = Mat_VarDuplicate(incells[i], opt);
            }
        }
    } else if ( (in->data != NULL) && (in->class_type == MAT_C_SPARSE) ) {
        out->data = malloc(sizeof(mat_sparse_t));
        if ( out->data != NULL ) {
            mat_sparse_t *out_sparse = (mat_sparse_t *)out->data;
            mat_sparse_t *in_sparse = (mat_sparse_t *)in->data;
            out_sparse->nzmax = in_sparse->nzmax;
            out_sparse->nir = in_sparse->nir;
            out_sparse->ir = (mat_uint32_t *)malloc(in_sparse->nir * sizeof(*out_sparse->ir));
            if ( out_sparse->ir != NULL )
                memcpy(out_sparse->ir, in_sparse->ir, in_sparse->nir * sizeof(*out_sparse->ir));
            out_sparse->njc = in_sparse->njc;
            out_sparse->jc = (mat_uint32_t *)malloc(in_sparse->njc * sizeof(*out_sparse->jc));
            if ( out_sparse->jc != NULL )
                memcpy(out_sparse->jc, in_sparse->jc, in_sparse->njc * sizeof(*out_sparse->jc));
            out_sparse->ndata = in_sparse->ndata;
            if ( out->isComplex && NULL != in_sparse->data ) {
                out_sparse->data = malloc(sizeof(mat_complex_split_t));
                if ( out_sparse->data != NULL ) {
                    mat_complex_split_t *out_data = (mat_complex_split_t *)out_sparse->data;
                    mat_complex_split_t *in_data = (mat_complex_split_t *)in_sparse->data;
                    out_data->Re = malloc(in_sparse->ndata * Mat_SizeOf(in->data_type));
                    if ( NULL != out_data->Re )
                        memcpy(out_data->Re, in_data->Re,
                               in_sparse->ndata * Mat_SizeOf(in->data_type));
                    out_data->Im = malloc(in_sparse->ndata * Mat_SizeOf(in->data_type));
                    if ( NULL != out_data->Im )
                        memcpy(out_data->Im, in_data->Im,
                               in_sparse->ndata * Mat_SizeOf(in->data_type));
                }
            } else if ( in_sparse->data != NULL ) {
                out_sparse->data = malloc(in_sparse->ndata * Mat_SizeOf(in->data_type));
                if ( NULL != out_sparse->data )
                    memcpy(out_sparse->data, in_sparse->data,
                           in_sparse->ndata * Mat_SizeOf(in->data_type));
            } else {
                out_sparse->data = NULL;
            }
        }
    } else if ( in->data != NULL ) {
        if ( out->isComplex ) {
            out->data = malloc(sizeof(mat_complex_split_t));
            if ( out->data != NULL ) {
                mat_complex_split_t *out_data = (mat_complex_split_t *)out->data;
                mat_complex_split_t *in_data = (mat_complex_split_t *)in->data;
                out_data->Re = malloc(out->nbytes);
                if ( NULL != out_data->Re )
                    memcpy(out_data->Re, in_data->Re, out->nbytes);
                out_data->Im = malloc(out->nbytes);
                if ( NULL != out_data->Im )
                    memcpy(out_data->Im, in_data->Im, out->nbytes);
            }
        } else {
            out->data = malloc(in->nbytes);
            if ( out->data != NULL )
                memcpy(out->data, in->data, in->nbytes);
        }
    }

    return out;
}

/** @brief Frees all the allocated memory associated with the structure
 *
 * Frees memory used by a MAT variable.  Frees the data associated with a
 * MAT variable if it's non-NULL and MAT_F_DONT_COPY_DATA was not used.
 * @ingroup MAT
 * @param matvar Pointer to the matvar_t structure
 */
void
Mat_VarFree(matvar_t *matvar)
{
    size_t nelems = 0;
    int err;

    if ( NULL == matvar )
        return;
    if ( NULL != matvar->dims ) {
        nelems = 1;
        err = Mat_MulDims(matvar, &nelems);
        free(matvar->dims);
    } else {
        err = MATIO_E_BAD_ARGUMENT;
    }
    if ( NULL != matvar->data ) {
        switch ( matvar->class_type ) {
            case MAT_C_STRUCT:
                if ( !matvar->mem_conserve ) {
                    if ( MATIO_E_NO_ERROR == err ) {
                        matvar_t **fields = (matvar_t **)matvar->data;
                        size_t nelems_x_nfields;
                        err = Mul(&nelems_x_nfields, nelems, matvar->internal->num_fields);
                        if ( MATIO_E_NO_ERROR == err && nelems_x_nfields > 0 ) {
                            size_t i;
                            for ( i = 0; i < nelems_x_nfields; i++ )
                                Mat_VarFree(fields[i]);
                        }
                    }
                    free(matvar->data);
                }
                break;
            case MAT_C_CELL:
                if ( !matvar->mem_conserve ) {
                    if ( MATIO_E_NO_ERROR == err ) {
                        matvar_t **cells = (matvar_t **)matvar->data;
                        size_t i;
                        for ( i = 0; i < nelems; i++ )
                            Mat_VarFree(cells[i]);
                    }
                    free(matvar->data);
                }
                break;
            case MAT_C_SPARSE:
                if ( !matvar->mem_conserve ) {
                    mat_sparse_t *sparse;
                    sparse = (mat_sparse_t *)matvar->data;
                    if ( sparse->ir != NULL )
                        free(sparse->ir);
                    if ( sparse->jc != NULL )
                        free(sparse->jc);
                    if ( matvar->isComplex && NULL != sparse->data ) {
                        ComplexFree((mat_complex_split_t *)sparse->data);
                    } else if ( sparse->data != NULL ) {
                        free(sparse->data);
                    }
                    free(sparse);
                }
                break;
            case MAT_C_DOUBLE:
            case MAT_C_SINGLE:
            case MAT_C_INT64:
            case MAT_C_UINT64:
            case MAT_C_INT32:
            case MAT_C_UINT32:
            case MAT_C_INT16:
            case MAT_C_UINT16:
            case MAT_C_INT8:
            case MAT_C_UINT8:
            case MAT_C_CHAR:
                if ( !matvar->mem_conserve ) {
                    if ( matvar->isComplex ) {
                        ComplexFree((mat_complex_split_t *)matvar->data);
                    } else {
                        free(matvar->data);
                    }
                }
                break;
            case MAT_C_FUNCTION:
                if ( !matvar->mem_conserve ) {
                    free(matvar->data);
                }
                break;
            case MAT_C_EMPTY:
            case MAT_C_OBJECT:
            case MAT_C_OPAQUE:
                break;
        }
    }

    if ( NULL != matvar->internal ) {
#if HAVE_ZLIB
        if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
            inflateEnd(matvar->internal->z);
            free(matvar->internal->z);
            if ( matvar->class_type == MAT_C_SPARSE && NULL != matvar->internal->data ) {
                mat_sparse_t *sparse;
                sparse = (mat_sparse_t *)matvar->internal->data;
                if ( sparse->ir != NULL )
                    free(sparse->ir);
                if ( sparse->jc != NULL )
                    free(sparse->jc);
                if ( matvar->isComplex && NULL != sparse->data ) {
                    ComplexFree((mat_complex_split_t *)sparse->data);
                } else if ( sparse->data != NULL ) {
                    free(sparse->data);
                }
                free(sparse);
            } else if ( matvar->isComplex && NULL != matvar->internal->data ) {
                ComplexFree((mat_complex_split_t *)matvar->internal->data);
            } else if ( NULL != matvar->internal->data ) {
                free(matvar->internal->data);
            }
        }
#endif
#if HAVE_HDF5
        if ( -1 < matvar->internal->id ) {
            switch ( H5Iget_type(matvar->internal->id) ) {
                case H5I_GROUP:
                    H5Gclose(matvar->internal->id);
                    matvar->internal->id = -1;
                    break;
                case H5I_DATASET:
                    H5Dclose(matvar->internal->id);
                    matvar->internal->id = -1;
                    break;
                default:
                    break;
            }
        }
        if ( 0 < matvar->internal->hdf5_ref ) {
            switch ( H5Iget_type(matvar->internal->id) ) {
                case H5I_GROUP:
                    H5Gclose(matvar->internal->id);
                    matvar->internal->hdf5_ref = -1;
                    break;
                case H5I_DATASET:
                    H5Dclose(matvar->internal->id);
                    matvar->internal->hdf5_ref = -1;
                    break;
                default:
                    break;
            }
        }
        if ( NULL != matvar->internal->hdf5_name ) {
            free(matvar->internal->hdf5_name);
            matvar->internal->hdf5_name = NULL;
        }
#endif
        if ( NULL != matvar->internal->fieldnames && matvar->internal->num_fields > 0 ) {
            size_t i;
            for ( i = 0; i < matvar->internal->num_fields; i++ ) {
                if ( NULL != matvar->internal->fieldnames[i] )
                    free(matvar->internal->fieldnames[i]);
            }
            free(matvar->internal->fieldnames);
        }
        free(matvar->internal);
        matvar->internal = NULL;
    }
    if ( NULL != matvar->name )
        free(matvar->name);
    free(matvar);
}

/** @brief Calculate a single subscript from a set of subscript values
 *
 * Calculates a single linear subscript (0-relative) given a 1-relative
 * subscript for each dimension.  The calculation uses the formula below where
 * index is the linear index, s is an array of length RANK where each element
 * is the subscript for the corresponding dimension, D is an array whose
 * elements are the dimensions of the variable.
 * \f[
 *   index = \sum\limits_{k=0}^{RANK-1} [(s_k - 1) \prod\limits_{l=0}^{k} D_l ]
 * \f]
 * @ingroup MAT
 * @param rank Rank of the variable
 * @param dims Dimensions of the variable
 * @param subs Array of dimension subscripts
 * @return Single (linear) subscript
 */
int
Mat_CalcSingleSubscript(int rank, int *dims, int *subs)
{
    int index = 0, i, j, err = MATIO_E_NO_ERROR;

    for ( i = 0; i < rank; i++ ) {
        int k = subs[i];
        if ( k > dims[i] ) {
            err = MATIO_E_BAD_ARGUMENT;
            Mat_Critical("Mat_CalcSingleSubscript: index out of bounds");
            break;
        } else if ( k < 1 ) {
            err = MATIO_E_BAD_ARGUMENT;
            break;
        }
        k--;
        for ( j = i; j--; )
            k *= dims[j];
        index += k;
    }
    if ( err )
        index = -1;

    return index;
}

/** @brief Calculate a single subscript from a set of subscript values
 *
 * Calculates a single linear subscript (0-relative) given a 1-relative
 * subscript for each dimension.  The calculation uses the formula below where
 * index is the linear index, s is an array of length RANK where each element
 * is the subscript for the corresponding dimension, D is an array whose
 * elements are the dimensions of the variable.
 * \f[
 *   index = \sum\limits_{k=0}^{RANK-1} [(s_k - 1) \prod\limits_{l=0}^{k} D_l ]
 * \f]
 * @ingroup MAT
 * @param rank Rank of the variable
 * @param dims Dimensions of the variable
 * @param subs Array of dimension subscripts
 * @param[out] index Single (linear) subscript
 * @retval 0 on success
 */
int
Mat_CalcSingleSubscript2(int rank, size_t *dims, size_t *subs, size_t *index)
{
    int i, err = MATIO_E_NO_ERROR;

    for ( i = 0; i < rank; i++ ) {
        int j;
        size_t k = subs[i];
        if ( k > dims[i] ) {
            err = MATIO_E_BAD_ARGUMENT;
            Mat_Critical("Mat_CalcSingleSubscript2: index out of bounds");
            break;
        } else if ( k < 1 ) {
            err = MATIO_E_BAD_ARGUMENT;
            break;
        }
        k--;
        for ( j = i; j--; )
            k *= dims[j];
        *index += k;
    }

    return err;
}

/** @brief Calculate a set of subscript values from a single(linear) subscript
 *
 * Calculates 1-relative subscripts for each dimension given a 0-relative
 * linear index.  Subscripts are calculated as follows where s is the array
 * of dimension subscripts, D is the array of dimensions, and index is the
 * linear index.
 * \f[
 *   s_k = \lfloor\frac{1}{L} \prod\limits_{l = 0}^{k} D_l\rfloor + 1
 * \f]
 * \f[
 *   L = index - \sum\limits_{l = k}^{RANK - 1} s_k \prod\limits_{m = 0}^{k} D_m
 * \f]
 * @ingroup MAT
 * @param rank Rank of the variable
 * @param dims Dimensions of the variable
 * @param index Linear index
 * @return Array of dimension subscripts
 */
int *
Mat_CalcSubscripts(int rank, int *dims, int index)
{
    int i, j, *subs;
    double l;

    subs = (int *)malloc(rank * sizeof(int));
    if ( NULL == subs ) {
        return subs;
    }

    l = index;
    for ( i = rank; i--; ) {
        int k = 1;
        for ( j = i; j--; )
            k *= dims[j];
        subs[i] = (int)floor(l / (double)k);
        l -= subs[i] * k;
        subs[i]++;
    }

    return subs;
}

/** @brief Calculate a set of subscript values from a single(linear) subscript
 *
 * Calculates 1-relative subscripts for each dimension given a 0-relative
 * linear index.  Subscripts are calculated as follows where s is the array
 * of dimension subscripts, D is the array of dimensions, and index is the
 * linear index.
 * \f[
 *   s_k = \lfloor\frac{1}{L} \prod\limits_{l = 0}^{k} D_l\rfloor + 1
 * \f]
 * \f[
 *   L = index - \sum\limits_{l = k}^{RANK - 1} s_k \prod\limits_{m = 0}^{k} D_m
 * \f]
 * @ingroup MAT
 * @param rank Rank of the variable
 * @param dims Dimensions of the variable
 * @param index Linear index
 * @return Array of dimension subscripts
 */
size_t *
Mat_CalcSubscripts2(int rank, size_t *dims, size_t index)
{
    int i;
    size_t *subs;
    double l;

    subs = (size_t *)malloc(rank * sizeof(size_t));
    if ( NULL == subs ) {
        return subs;
    }

    l = (double)index;
    for ( i = rank; i--; ) {
        int j;
        size_t k = 1;
        for ( j = i; j--; )
            k *= dims[j];
        subs[i] = (size_t)floor(l / (double)k);
        l -= subs[i] * k;
        subs[i]++;
    }

    return subs;
}

/** @brief Calculates the size of a matlab variable in bytes
 *
 * @ingroup MAT
 * @param matvar matlab variable
 * @returns size of the variable in bytes, or 0 on error
 */
size_t
Mat_VarGetSize(matvar_t *matvar)
{
    int err;
    size_t i;
    size_t bytes = 0, overhead = 0, ptr = 0;

#if defined(_WIN64) || (defined(__SIZEOF_POINTER__) && (__SIZEOF_POINTER__ == 8)) || \
    (defined(SIZEOF_VOID_P) && (SIZEOF_VOID_P == 8))
    /* 112 bytes cell/struct overhead for 64-bit system */
    overhead = 112;
    ptr = 8;
#elif defined(_WIN32) || (defined(__SIZEOF_POINTER__) && (__SIZEOF_POINTER__ == 4)) || \
    (defined(SIZEOF_VOID_P) && (SIZEOF_VOID_P == 4))
    /* 60 bytes cell/struct overhead for 32-bit system */
    overhead = 60;
    ptr = 4;
#endif

    if ( matvar->class_type == MAT_C_STRUCT ) {
        matvar_t **fields = (matvar_t **)matvar->data;
        size_t field_name_length;
        if ( NULL != fields ) {
            size_t nelems_x_nfields = matvar->internal->num_fields;
            err = Mat_MulDims(matvar, &nelems_x_nfields);
            err |= Mul(&bytes, nelems_x_nfields, overhead);
            if ( err )
                return 0;

            for ( i = 0; i < nelems_x_nfields; i++ ) {
                if ( NULL != fields[i] ) {
                    if ( MAT_C_EMPTY != fields[i]->class_type ) {
                        err = Add(&bytes, bytes, Mat_VarGetSize(fields[i]));
                        if ( err )
                            return 0;
                    } else {
                        bytes -= overhead;
                        bytes += ptr;
                    }
                }
            }
        }
        err = Mul(&field_name_length, 64 /* max field name length */, matvar->internal->num_fields);
        err |= Add(&bytes, bytes, field_name_length);
        if ( err )
            return 0;
    } else if ( matvar->class_type == MAT_C_CELL ) {
        matvar_t **cells = (matvar_t **)matvar->data;
        if ( NULL != cells ) {
            size_t nelems = matvar->nbytes / matvar->data_size;
            err = Mul(&bytes, nelems, overhead);
            if ( err )
                return 0;

            for ( i = 0; i < nelems; i++ ) {
                if ( NULL != cells[i] ) {
                    if ( MAT_C_EMPTY != cells[i]->class_type ) {
                        err = Add(&bytes, bytes, Mat_VarGetSize(cells[i]));
                        if ( err )
                            return 0;
                    } else {
                        bytes -= overhead;
                        bytes += ptr;
                    }
                }
            }
        }
    } else if ( matvar->class_type == MAT_C_SPARSE ) {
        mat_sparse_t *sparse = (mat_sparse_t *)matvar->data;
        if ( NULL != sparse ) {
            size_t sparse_size = 0;
            err = Mul(&bytes, sparse->ndata, Mat_SizeOf(matvar->data_type));
            if ( err )
                return 0;

            if ( matvar->isComplex ) {
                err = Mul(&bytes, bytes, 2);
                if ( err )
                    return 0;
            }

#if defined(_WIN64) || (defined(__SIZEOF_POINTER__) && (__SIZEOF_POINTER__ == 8)) || \
    (defined(SIZEOF_VOID_P) && (SIZEOF_VOID_P == 8))
            /* 8 byte integers for 64-bit system (as displayed in MATLAB (x64) whos) */
            err = Mul(&sparse_size, sparse->nir + sparse->njc, 8);
#elif defined(_WIN32) || (defined(__SIZEOF_POINTER__) && (__SIZEOF_POINTER__ == 4)) || \
    (defined(SIZEOF_VOID_P) && (SIZEOF_VOID_P == 4))
            /* 4 byte integers for 32-bit system (as defined by mat_sparse_t) */
            err = Mul(&sparse_size, sparse->nir + sparse->njc, 4);
#endif
            err |= Add(&bytes, bytes, sparse_size);
            if ( err )
                return 0;

            if ( sparse->ndata == 0 || sparse->nir == 0 || sparse->njc == 0 ) {
                err = Add(&bytes, bytes, matvar->isLogical ? 1 : 8);
                if ( err )
                    return 0;
            }
        }
    } else {
        if ( matvar->rank > 0 ) {
            bytes = Mat_SizeOfClass(matvar->class_type);
            err = Mat_MulDims(matvar, &bytes);
            if ( err )
                return 0;

            if ( matvar->isComplex ) {
                err = Mul(&bytes, bytes, 2);
                if ( err )
                    return 0;
            }
        }
    }

    return bytes;
}

/** @brief Prints the variable information
 *
 * Prints to stdout the values of the @ref matvar_t structure
 * @ingroup MAT
 * @param matvar Pointer to the matvar_t structure
 * @param printdata set to 1 if the Variables data should be printed, else 0
 */
void
Mat_VarPrint(matvar_t *matvar, int printdata)
{
    size_t nelems = 0, i, j;
    const char *class_type_desc[18] = {"Undefined",
                                       "Cell Array",
                                       "Structure",
                                       "Object",
                                       "Character Array",
                                       "Sparse Array",
                                       "Double Precision Array",
                                       "Single Precision Array",
                                       "8-bit, signed integer array",
                                       "8-bit, unsigned integer array",
                                       "16-bit, signed integer array",
                                       "16-bit, unsigned integer array",
                                       "32-bit, signed integer array",
                                       "32-bit, unsigned integer array",
                                       "64-bit, signed integer array",
                                       "64-bit, unsigned integer array",
                                       "Function",
                                       "Opaque"};

    if ( matvar == NULL )
        return;
    if ( NULL != matvar->name )
        printf("      Name: %s\n", matvar->name);
    printf("      Rank: %d\n", matvar->rank);
    if ( matvar->rank <= 0 )
        return;
    if ( NULL != matvar->dims ) {
        int err;
        nelems = 1;
        err = Mat_MulDims(matvar, &nelems);
        printf("Dimensions: %" SIZE_T_FMTSTR, matvar->dims[0]);
        if ( MATIO_E_NO_ERROR == err ) {
            int k;
            for ( k = 1; k < matvar->rank; k++ ) {
                printf(" x %" SIZE_T_FMTSTR, matvar->dims[k]);
            }
        }
        printf("\n");
    }
    printf("Class Type: %s", class_type_desc[matvar->class_type]);
    if ( matvar->isComplex )
        printf(" (complex)");
    else if ( matvar->isLogical )
        printf(" (logical)");
    printf("\n");
    if ( matvar->data_type ) {
        const char *data_type_desc[25] = {"Unknown",
                                          "8-bit, signed integer",
                                          "8-bit, unsigned integer",
                                          "16-bit, signed integer",
                                          "16-bit, unsigned integer",
                                          "32-bit, signed integer",
                                          "32-bit, unsigned integer",
                                          "IEEE 754 single-precision",
                                          "RESERVED",
                                          "IEEE 754 double-precision",
                                          "RESERVED",
                                          "RESERVED",
                                          "64-bit, signed integer",
                                          "64-bit, unsigned integer",
                                          "Matlab Array",
                                          "Compressed Data",
                                          "Unicode UTF-8 Encoded Character Data",
                                          "Unicode UTF-16 Encoded Character Data",
                                          "Unicode UTF-32 Encoded Character Data",
                                          "RESERVED",
                                          "String",
                                          "Cell Array",
                                          "Structure",
                                          "Array",
                                          "Function"};
        printf(" Data Type: %s\n", data_type_desc[matvar->data_type]);
    }

    if ( MAT_C_STRUCT == matvar->class_type ) {
        matvar_t **fields = (matvar_t **)matvar->data;
        size_t nfields = matvar->internal->num_fields;
        size_t nelems_x_nfields = 1;
        int err = Mul(&nelems_x_nfields, nelems, nfields);
        if ( MATIO_E_NO_ERROR == err && nelems_x_nfields > 0 ) {
            printf("Fields[%" SIZE_T_FMTSTR "] {\n", nelems_x_nfields);
            for ( i = 0; i < nelems_x_nfields; i++ ) {
                if ( NULL == fields[i] ) {
                    printf("      Name: %s\n      Rank: %d\n",
                           matvar->internal->fieldnames[i % nfields], 0);
                } else {
                    Mat_VarPrint(fields[i], printdata);
                }
            }
            printf("}\n");
        } else {
            printf("Fields[%" SIZE_T_FMTSTR "] {\n", nfields);
            for ( i = 0; i < nfields; i++ )
                printf("      Name: %s\n      Rank: %d\n", matvar->internal->fieldnames[i], 0);
            printf("}\n");
        }
        return;
    } else if ( matvar->data == NULL || matvar->data_size < 1 ) {
        if ( printdata )
            printf("{\n}\n");
        return;
    } else if ( MAT_C_CELL == matvar->class_type ) {
        matvar_t **cells = (matvar_t **)matvar->data;
        nelems = matvar->nbytes / matvar->data_size;
        printf("{\n");
        for ( i = 0; i < nelems; i++ )
            Mat_VarPrint(cells[i], printdata);
        printf("}\n");
        return;
    } else if ( !printdata ) {
        return;
    }

    printf("{\n");

    if ( matvar->rank > 2 ) {
        printf("I can't print more than 2 dimensions\n");
    } else if ( matvar->rank == 1 && NULL != matvar->dims && matvar->dims[0] > 15 ) {
        printf("I won't print more than 15 elements in a vector\n");
    } else if ( matvar->rank == 2 && NULL != matvar->dims ) {
        switch ( matvar->class_type ) {
            case MAT_C_DOUBLE:
            case MAT_C_SINGLE:
#ifdef HAVE_MATIO_INT64_T
            case MAT_C_INT64:
#endif
#ifdef HAVE_MATIO_UINT64_T
            case MAT_C_UINT64:
#endif
            case MAT_C_INT32:
            case MAT_C_UINT32:
            case MAT_C_INT16:
            case MAT_C_UINT16:
            case MAT_C_INT8:
            case MAT_C_UINT8: {
                size_t stride = Mat_SizeOf(matvar->data_type);
                if ( matvar->isComplex ) {
                    mat_complex_split_t *complex_data = (mat_complex_split_t *)matvar->data;
                    char *rp = (char *)complex_data->Re;
                    char *ip = (char *)complex_data->Im;
                    for ( i = 0; i < matvar->dims[0] && i < 15; i++ ) {
                        for ( j = 0; j < matvar->dims[1] && j < 15; j++ ) {
                            size_t idx = matvar->dims[0] * j + i;
                            Mat_PrintNumber(matvar->data_type, rp + idx * stride);
                            printf(" + ");
                            Mat_PrintNumber(matvar->data_type, ip + idx * stride);
                            printf("i ");
                        }
                        if ( j < matvar->dims[1] )
                            printf("...");
                        printf("\n");
                    }
                    if ( i < matvar->dims[0] )
                        printf(".\n.\n.\n");
                } else {
                    char *data = (char *)matvar->data;
                    for ( i = 0; i < matvar->dims[0] && i < 15; i++ ) {
                        for ( j = 0; j < matvar->dims[1] && j < 15; j++ ) {
                            size_t idx = matvar->dims[0] * j + i;
                            Mat_PrintNumber(matvar->data_type, data + idx * stride);
                            printf(" ");
                        }
                        if ( j < matvar->dims[1] )
                            printf("...");
                        printf("\n");
                    }
                    if ( i < matvar->dims[0] )
                        printf(".\n.\n.\n");
                }
                break;
            }
            case MAT_C_CHAR: {
                switch ( matvar->data_type ) {
                    case MAT_T_UINT16:
                    case MAT_T_UTF16: {
                        const mat_uint16_t *data = (const mat_uint16_t *)matvar->data;
                        for ( i = 0; i < matvar->dims[0]; i++ ) {
                            for ( j = 0; j < matvar->dims[1]; j++ ) {
                                const mat_uint16_t c = data[j * matvar->dims[0] + i];
#if defined VARPRINT_UTF16
                                printf("%c%c", c & 0xFF, (c >> 8) & 0xFF);
#elif defined VARPRINT_UTF16_DECIMAL
                                Mat_PrintNumber(MAT_T_UINT16, &c);
                                printf(" ");
#else
                                /* Convert to UTF-8 */
                                if ( c <= 0x7F ) {
                                    printf("%c", c);
                                } else if ( c <= 0x7FF ) {
                                    printf("%c%c", 0xC0 | (c >> 6), 0x80 | (c & 0x3F));
                                } else /* if (c <= 0xFFFF) */ {
                                    printf("%c%c%c", 0xE0 | (c >> 12), 0x80 | ((c >> 6) & 0x3F),
                                           0x80 | (c & 0x3F));
                                }
#endif
                            }
                            printf("\n");
                        }
                        break;
                    }
                    case MAT_T_UTF8: {
                        const mat_uint8_t *data = (const mat_uint8_t *)matvar->data;
                        size_t k = 0;
                        size_t *idxOffset;
                        if ( matvar->nbytes == 0 ) {
                            break;
                        }
                        idxOffset = (size_t *)calloc(nelems, sizeof(size_t));
                        if ( idxOffset == NULL ) {
                            break;
                        }
                        for ( i = 0; i < matvar->dims[0]; i++ ) {
                            for ( j = 0; j < matvar->dims[1]; j++ ) {
                                mat_uint8_t c;
                                if ( k >= matvar->nbytes ) {
                                    break;
                                }
                                idxOffset[i * matvar->dims[1] + j] = k;
                                c = data[k];
                                if ( c <= 0x7F ) {
                                } else if ( (c & 0xE0) == 0xC0 && k + 1 < matvar->nbytes ) {
                                    k = k + 1;
                                } else if ( (c & 0xF0) == 0xE0 && k + 2 < matvar->nbytes ) {
                                    k = k + 2;
                                } else if ( (c & 0xF8) == 0xF0 && k + 3 < matvar->nbytes ) {
                                    k = k + 3;
                                }
                                ++k;
                            }
                        }
                        for ( i = 0; i < matvar->dims[0]; i++ ) {
                            for ( j = 0; j < matvar->dims[1]; j++ ) {
                                mat_uint8_t c;
                                k = idxOffset[j * matvar->dims[0] + i];
                                c = data[k];
                                if ( c <= 0x7F ) {
                                    printf("%c", c);
                                } else if ( (c & 0xE0) == 0xC0 ) {
                                    printf("%c%c", c, data[k + 1]);
                                } else if ( (c & 0xF0) == 0xE0 ) {
                                    printf("%c%c%c", c, data[k + 1], data[k + 2]);
                                } else if ( (c & 0xF8) == 0xF0 ) {
                                    printf("%c%c%c%c", c, data[k + 1], data[k + 2], data[k + 3]);
                                }
                            }
                            printf("\n");
                        }
                        free(idxOffset);
                        break;
                    }
                    default: {
                        const char *data = (const char *)matvar->data;
                        for ( i = 0; i < matvar->dims[0]; i++ ) {
                            for ( j = 0; j < matvar->dims[1]; j++ )
                                printf("%c", data[j * matvar->dims[0] + i]);
                            printf("\n");
                        }
                        break;
                    }
                }
                break;
            }
            case MAT_C_SPARSE: {
                mat_sparse_t *sparse;
                size_t stride = Mat_SizeOf(matvar->data_type);
#if !defined(EXTENDED_SPARSE)
                if ( MAT_T_DOUBLE != matvar->data_type )
                    break;
#endif
                sparse = (mat_sparse_t *)matvar->data;
                if ( matvar->isComplex ) {
                    mat_complex_split_t *complex_data = (mat_complex_split_t *)sparse->data;
                    char *re = (char *)complex_data->Re;
                    char *im = (char *)complex_data->Im;
                    for ( i = 0; i < (size_t)sparse->njc - 1; i++ ) {
                        for ( j = sparse->jc[i];
                              j < (size_t)sparse->jc[i + 1] && j < (size_t)sparse->ndata; j++ ) {
                            printf("    (%u,%" SIZE_T_FMTSTR ")  ", sparse->ir[j] + 1, i + 1);
                            Mat_PrintNumber(matvar->data_type, re + j * stride);
                            printf(" + ");
                            Mat_PrintNumber(matvar->data_type, im + j * stride);
                            printf("i\n");
                        }
                    }
                } else {
                    char *data = (char *)sparse->data;
                    for ( i = 0; i < (size_t)sparse->njc - 1; i++ ) {
                        for ( j = sparse->jc[i];
                              j < (size_t)sparse->jc[i + 1] && j < (size_t)sparse->ndata; j++ ) {
                            printf("    (%u,%" SIZE_T_FMTSTR ")  ", sparse->ir[j] + 1, i + 1);
                            Mat_PrintNumber(matvar->data_type, data + j * stride);
                            printf("\n");
                        }
                    }
                }
                break;
            } /* case MAT_C_SPARSE: */
            default:
                break;
        } /* switch( matvar->class_type ) */
    }

    printf("}\n");

    return;
}

/** @brief Reads MAT variable data from a file
 *
 * Reads data from a MAT variable.  The variable must have been read by
 * Mat_VarReadInfo.
 * @ingroup MAT
 * @param mat MAT file to read data from
 * @param matvar MAT variable information
 * @param data pointer to store data in (must be pre-allocated)
 * @param start array of starting indices
 * @param stride stride of data
 * @param edge array specifying the number to read in each direction
 * @retval 0 on success
 */
int
Mat_VarReadData(mat_t *mat, matvar_t *matvar, void *data, int *start, int *stride, int *edge)
{
    int err = MATIO_E_NO_ERROR;

    switch ( matvar->class_type ) {
        case MAT_C_DOUBLE:
        case MAT_C_SINGLE:
        case MAT_C_INT64:
        case MAT_C_UINT64:
        case MAT_C_INT32:
        case MAT_C_UINT32:
        case MAT_C_INT16:
        case MAT_C_UINT16:
        case MAT_C_INT8:
        case MAT_C_UINT8:
            break;
        default:
            return MATIO_E_OPERATION_NOT_SUPPORTED;
    }

    switch ( mat->version ) {
        case MAT_FT_MAT5:
            err = Mat_VarReadData5(mat, matvar, data, start, stride, edge);
            break;
        case MAT_FT_MAT73:
#if HAVE_HDF5
            err = Mat_VarReadData73(mat, matvar, data, start, stride, edge);
#else
            err = MATIO_E_OPERATION_NOT_SUPPORTED;
#endif
            break;
        case MAT_FT_MAT4:
            err = Mat_VarReadData4(mat, matvar, data, start, stride, edge);
            break;
        default:
            err = MATIO_E_FAIL_TO_IDENTIFY;
            break;
    }

    return err;
}

/** @brief Reads all the data for a matlab variable
 *
 * Allocates memory and reads the data for a given matlab variable.
 * @ingroup MAT
 * @param mat Matlab MAT file structure pointer
 * @param matvar Variable whose data is to be read
 * @returns non-zero on error
 */
int
Mat_VarReadDataAll(mat_t *mat, matvar_t *matvar)
{
    int err = MATIO_E_NO_ERROR;

    if ( mat == NULL || matvar == NULL )
        err = MATIO_E_BAD_ARGUMENT;
    else
        err = ReadData(mat, matvar);

    return err;
}

/** @brief Reads a subset of a MAT variable using a 1-D indexing
 *
 * Reads data from a MAT variable using a linear (1-D) indexing mode. The
 * variable must have been read by Mat_VarReadInfo.
 * @ingroup MAT
 * @param mat MAT file to read data from
 * @param matvar MAT variable information
 * @param data pointer to store data in (must be pre-allocated)
 * @param start starting index
 * @param stride stride of data
 * @param edge number of elements to read
 * @retval 0 on success
 */
int
Mat_VarReadDataLinear(mat_t *mat, matvar_t *matvar, void *data, int start, int stride, int edge)
{
    int err = MATIO_E_NO_ERROR;

    switch ( matvar->class_type ) {
        case MAT_C_DOUBLE:
        case MAT_C_SINGLE:
        case MAT_C_INT64:
        case MAT_C_UINT64:
        case MAT_C_INT32:
        case MAT_C_UINT32:
        case MAT_C_INT16:
        case MAT_C_UINT16:
        case MAT_C_INT8:
        case MAT_C_UINT8:
            break;
        default:
            return MATIO_E_OPERATION_NOT_SUPPORTED;
    }

    switch ( mat->version ) {
        case MAT_FT_MAT5:
            err = Mat_VarReadDataLinear5(mat, matvar, data, start, stride, edge);
            break;
        case MAT_FT_MAT73:
#if HAVE_HDF5
            err = Mat_VarReadDataLinear73(mat, matvar, data, start, stride, edge);
#else
            err = MATIO_E_OPERATION_NOT_SUPPORTED;
#endif
            break;
        case MAT_FT_MAT4:
            err = Mat_VarReadDataLinear4(mat, matvar, data, start, stride, edge);
            break;
        default:
            err = MATIO_E_FAIL_TO_IDENTIFY;
            break;
    }

    return err;
}

/** @brief Reads the information of the next variable in a MAT file
 *
 * Reads the next variable's information (class,flags-complex/global/logical,
 * rank,dimensions, name, etc) from the Matlab MAT file.  After reading, the MAT
 * file is positioned past the current variable.
 * @ingroup MAT
 * @param mat Pointer to the MAT file
 * @return Pointer to the @ref matvar_t structure containing the MAT
 * variable information
 */
matvar_t *
Mat_VarReadNextInfo(mat_t *mat)
{
    matvar_t *matvar;
    if ( mat == NULL )
        return NULL;

    switch ( mat->version ) {
        case MAT_FT_MAT5:
            matvar = Mat_VarReadNextInfo5(mat);
            break;
        case MAT_FT_MAT73:
#if HAVE_HDF5
            matvar = Mat_VarReadNextInfo73(mat);
#else
            matvar = NULL;
#endif
            break;
        case MAT_FT_MAT4:
            matvar = Mat_VarReadNextInfo4(mat);
            break;
        default:
            matvar = NULL;
            break;
    }

    return matvar;
}

/** @brief Reads the information of a variable with the given name from a MAT file
 *
 * Reads the named variable (or the next variable if name is NULL) information
 * (class,flags-complex/global/logical,rank,dimensions,and name) from the
 * Matlab MAT file
 * @ingroup MAT
 * @param mat Pointer to the MAT file
 * @param name Name of the variable to read
 * @return Pointer to the @ref matvar_t structure containing the MAT
 * variable information
 */
matvar_t *
Mat_VarReadInfo(mat_t *mat, const char *name)
{
    matvar_t *matvar = NULL;

    if ( mat == NULL || name == NULL )
        return NULL;

    if ( mat->version == MAT_FT_MAT73 ) {
        size_t fpos = mat->next_index;
        mat->next_index = 0;
        while ( NULL == matvar && mat->next_index < mat->num_datasets ) {
            matvar = Mat_VarReadNextInfo(mat);
            if ( matvar != NULL ) {
                if ( matvar->name == NULL || 0 != strcmp(matvar->name, name) ) {
                    Mat_VarFree(matvar);
                    matvar = NULL;
                }
            } else {
                Mat_Critical("An error occurred in reading the MAT file");
                break;
            }
        }
        mat->next_index = fpos;
    } else {
        long fpos = ftell((FILE *)mat->fp);
        if ( fpos != -1L ) {
            (void)fseek((FILE *)mat->fp, mat->bof, SEEK_SET);
            do {
                matvar = Mat_VarReadNextInfo(mat);
                if ( matvar != NULL ) {
                    if ( matvar->name == NULL || 0 != strcmp(matvar->name, name) ) {
                        Mat_VarFree(matvar);
                        matvar = NULL;
                    }
                } else if ( !IsEndOfFile((FILE *)mat->fp, NULL) ) {
                    Mat_Critical("An error occurred in reading the MAT file");
                    break;
                }
            } while ( NULL == matvar && !IsEndOfFile((FILE *)mat->fp, NULL) );
            (void)fseek((FILE *)mat->fp, fpos, SEEK_SET);
        } else {
            Mat_Critical("Couldn't determine file position");
        }
    }

    return matvar;
}

/** @brief Reads the variable with the given name from a MAT file
 *
 * Reads the next variable in the Matlab MAT file
 * @ingroup MAT
 * @param mat Pointer to the MAT file
 * @param name Name of the variable to read
 * @return Pointer to the @ref matvar_t structure containing the MAT
 * variable information
 */
matvar_t *
Mat_VarRead(mat_t *mat, const char *name)
{
    matvar_t *matvar = NULL;

    if ( mat == NULL || name == NULL )
        return NULL;

    if ( MAT_FT_MAT73 != mat->version ) {
        long fpos = ftell((FILE *)mat->fp);
        if ( fpos == -1L ) {
            Mat_Critical("Couldn't determine file position");
            return NULL;
        }
        matvar = Mat_VarReadInfo(mat, name);
        if ( matvar ) {
            const int err = ReadData(mat, matvar);
            if ( err ) {
                Mat_VarFree(matvar);
                matvar = NULL;
            }
        }
        (void)fseek((FILE *)mat->fp, fpos, SEEK_SET);
    } else {
        size_t fpos = mat->next_index;
        mat->next_index = 0;
        matvar = Mat_VarReadInfo(mat, name);
        if ( matvar ) {
            const int err = ReadData(mat, matvar);
            if ( err ) {
                Mat_VarFree(matvar);
                matvar = NULL;
            }
        }
        mat->next_index = fpos;
    }

    return matvar;
}

/** @brief Reads the next variable in a MAT file
 *
 * Reads the next variable in the Matlab MAT file
 * @ingroup MAT
 * @param mat Pointer to the MAT file
 * @return Pointer to the @ref matvar_t structure containing the MAT
 * variable information
 */
matvar_t *
Mat_VarReadNext(mat_t *mat)
{
    long fpos;
    matvar_t *matvar;

    if ( mat->version != MAT_FT_MAT73 ) {
        if ( IsEndOfFile((FILE *)mat->fp, &fpos) )
            return NULL;
        if ( fpos == -1L ) {
            return NULL;
        }
    }
    matvar = Mat_VarReadNextInfo(mat);
    if ( matvar ) {
        const int err = ReadData(mat, matvar);
        if ( err ) {
            Mat_VarFree(matvar);
            matvar = NULL;
        }
    } else if ( mat->version != MAT_FT_MAT73 ) {
        /* Reset the file position */
        (void)fseek((FILE *)mat->fp, fpos, SEEK_SET);
    }

    return matvar;
}

/** @brief Writes the given MAT variable to a MAT file
 *
 * Writes the MAT variable information stored in matvar to the given MAT file.
 * The variable will be written to the end of the file.
 * @ingroup MAT
 * @param mat MAT file to write to
 * @param matvar MAT variable information to write
 * @retval 1
 * @deprecated
 * @see Mat_VarWrite/Mat_VarWriteAppend
 */
int
Mat_VarWriteInfo(mat_t *mat, matvar_t *matvar)
{
    Mat_Critical(
        "Mat_VarWriteInfo/Mat_VarWriteData is not supported. "
        "Use %s instead!",
        mat->version == MAT_FT_MAT73 ? "Mat_VarWrite/Mat_VarWriteAppend" : "Mat_VarWrite");
    return MATIO_E_OPERATION_NOT_SUPPORTED;
}

/** @brief Writes the given data to the MAT variable
 *
 * Writes data to a MAT variable.  The variable must have previously been
 * written with Mat_VarWriteInfo.
 * @ingroup MAT
 * @param mat MAT file to write to
 * @param matvar MAT variable information to write
 * @param data pointer to the data to write
 * @param start array of starting indices
 * @param stride stride of data
 * @param edge array specifying the number to read in each direction
 * @retval 1
 * @deprecated
 * @see Mat_VarWrite/Mat_VarWriteAppend
 */
int
Mat_VarWriteData(mat_t *mat, matvar_t *matvar, void *data, int *start, int *stride, int *edge)
{
    Mat_Critical(
        "Mat_VarWriteInfo/Mat_VarWriteData is not supported. "
        "Use %s instead!",
        mat->version == MAT_FT_MAT73 ? "Mat_VarWrite/Mat_VarWriteAppend" : "Mat_VarWrite");
    return MATIO_E_OPERATION_NOT_SUPPORTED;
}

/** @brief Writes the given MAT variable to a MAT file
 *
 * Writes the MAT variable information stored in matvar to the given MAT file.
 * The variable will be written to the end of the file.
 * @ingroup MAT
 * @param mat MAT file to write to
 * @param matvar MAT variable information to write
 * @param compress Whether or not to compress the data
 *        (Only valid for version 5 and 7.3 MAT files and variables with
           numeric data)
 * @retval 0 on success
 */
int
Mat_VarWrite(mat_t *mat, matvar_t *matvar, enum matio_compression compress)
{
    int err;

    if ( NULL == mat || NULL == matvar )
        return MATIO_E_BAD_ARGUMENT;

    if ( NULL == mat->dir ) {
        size_t n = 0;
        (void)Mat_GetDir(mat, &n);
    }

    {
        /* Error if MAT variable already exists in MAT file */
        size_t i;
        for ( i = 0; i < mat->num_datasets; i++ ) {
            if ( NULL != mat->dir[i] && 0 == strcmp(mat->dir[i], matvar->name) ) {
                Mat_Critical("Variable %s already exists.", matvar->name);
                return MATIO_E_OUTPUT_BAD_DATA;
            }
        }
    }

    if ( mat->version == MAT_FT_MAT5 )
        err = Mat_VarWrite5(mat, matvar, compress);
    else if ( mat->version == MAT_FT_MAT73 )
#if HAVE_HDF5
        err = Mat_VarWrite73(mat, matvar, compress);
#else
        err = MATIO_E_OPERATION_NOT_SUPPORTED;
#endif
    else if ( mat->version == MAT_FT_MAT4 )
        err = Mat_VarWrite4(mat, matvar);
    else
        err = MATIO_E_FAIL_TO_IDENTIFY;

    if ( err == MATIO_E_NO_ERROR ) {
        /* Update directory */
        char **dir;
        if ( NULL == mat->dir ) {
            dir = (char **)malloc(sizeof(char *));
        } else {
            dir = (char **)realloc(mat->dir, (mat->num_datasets + 1) * (sizeof(char *)));
        }
        if ( NULL != dir ) {
            mat->dir = dir;
            if ( NULL != matvar->name ) {
                mat->dir[mat->num_datasets++] = Mat_strdup(matvar->name);
            } else {
                mat->dir[mat->num_datasets++] = NULL;
            }
        } else {
            err = MATIO_E_OUT_OF_MEMORY;
            Mat_Critical("Couldn't allocate memory for the directory");
        }
    }

    return err;
}

/** @brief Writes/appends the given MAT variable to a version 7.3 MAT file
 *
 * Writes the numeric data of the MAT variable stored in matvar to the given
 * MAT file. The variable will be written to the end of the file if it does
 * not yet exist or appended to the existing variable.
 * @ingroup MAT
 * @param mat MAT file to write to
 * @param matvar MAT variable information to write
 * @param compress Whether or not to compress the data
 *        (Only valid for version 7.3 MAT files and variables with numeric data)
 * @param dim dimension to append data
 *        (Only valid for version 7.3 MAT files and variables with numeric data)
 * @retval 0 on success
 */
int
Mat_VarWriteAppend(mat_t *mat, matvar_t *matvar, enum matio_compression compress, int dim)
{
    int err;

    if ( NULL == mat || NULL == matvar )
        return MATIO_E_BAD_ARGUMENT;

    if ( NULL == mat->dir ) {
        size_t n = 0;
        (void)Mat_GetDir(mat, &n);
    }

    if ( mat->version == MAT_FT_MAT73 ) {
#if HAVE_HDF5
        int append = 0;
        {
            /* Check if MAT variable already exists in MAT file */
            size_t i;
            for ( i = 0; i < mat->num_datasets; i++ ) {
                if ( NULL != mat->dir[i] && 0 == strcmp(mat->dir[i], matvar->name) ) {
                    append = 1;
                    break;
                }
            }
        }
        err = Mat_VarWriteAppend73(mat, matvar, compress, dim);
        if ( err == MATIO_E_NO_ERROR && 0 == append ) {
            /* Update directory */
            char **dir;
            if ( NULL == mat->dir ) {
                dir = (char **)malloc(sizeof(char *));
            } else {
                dir = (char **)realloc(mat->dir, (mat->num_datasets + 1) * (sizeof(char *)));
            }
            if ( NULL != dir ) {
                mat->dir = dir;
                if ( NULL != matvar->name ) {
                    mat->dir[mat->num_datasets++] = Mat_strdup(matvar->name);
                } else {
                    mat->dir[mat->num_datasets++] = NULL;
                }
            } else {
                err = MATIO_E_OUT_OF_MEMORY;
                Mat_Critical("Couldn't allocate memory for the directory");
            }
        }
#else
        err = MATIO_E_OPERATION_NOT_SUPPORTED;
#endif
    } else if ( mat->version == MAT_FT_MAT4 || mat->version == MAT_FT_MAT5 ) {
        err = MATIO_E_OPERATION_NOT_SUPPORTED;
    } else {
        err = MATIO_E_FAIL_TO_IDENTIFY;
    }

    return err;
}

/* -------------------------------
 * ---------- mat4.c
 * -------------------------------
 */
/** @file mat4.c
 * Matlab MAT version 4 file functions
 * @ingroup MAT
 */

/** @if mat_devman
 * @brief Creates a new Matlab MAT version 4 file
 *
 * Tries to create a new Matlab MAT file with the given name.
 * @ingroup MAT
 * @param matname Name of MAT file to create
 * @return A pointer to the MAT file or NULL if it failed.  This is not a
 * simple FILE * and should not be used as one.
 * @endif
 */
static mat_t *
Mat_Create4(const char *matname)
{
    FILE *fp = NULL;
    mat_t *mat = NULL;

#if defined(_WIN32) && defined(_MSC_VER)
    wchar_t *wname = utf82u(matname);
    if ( NULL != wname ) {
        fp = _wfopen(wname, L"w+b");
        free(wname);
    }
#else
    fp = fopen(matname, "w+b");
#endif
    if ( !fp )
        return NULL;

    mat = (mat_t *)malloc(sizeof(*mat));
    if ( NULL == mat ) {
        fclose(fp);
        Mat_Critical("Couldn't allocate memory for the MAT file");
        return NULL;
    }

    mat->fp = fp;
    mat->header = NULL;
    mat->subsys_offset = NULL;
    mat->filename = Mat_strdup(matname);
    mat->version = MAT_FT_MAT4;
    mat->byteswap = 0;
    mat->mode = 0;
    mat->bof = 0;
    mat->next_index = 0;
    mat->num_datasets = 0;
#if HAVE_HDF5
    mat->refs_id = -1;
#endif
    mat->dir = NULL;

    Mat_Rewind(mat);

    return mat;
}

/** @if mat_devman
 * @brief Writes a matlab variable to a version 4 matlab file
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWrite4(mat_t *mat, matvar_t *matvar)
{
    typedef struct
    {
        mat_int32_t type;
        mat_int32_t mrows;
        mat_int32_t ncols;
        mat_int32_t imagf;
        mat_int32_t namelen;
    } Fmatrix;

    mat_uint32_t i;
    Fmatrix x;

    if ( NULL == mat || NULL == matvar )
        return MATIO_E_BAD_ARGUMENT;
    if ( NULL == matvar->name || matvar->rank != 2 )
        return MATIO_E_OUTPUT_BAD_DATA;

    switch ( matvar->data_type ) {
        case MAT_T_DOUBLE:
            x.type = 0;
            break;
        case MAT_T_SINGLE:
            x.type = 10;
            break;
        case MAT_T_INT32:
            x.type = 20;
            break;
        case MAT_T_INT16:
            x.type = 30;
            break;
        case MAT_T_UINT16:
            x.type = 40;
            break;
        case MAT_T_UINT8:
            x.type = 50;
            break;
        default:
            return MATIO_E_OUTPUT_BAD_DATA;
    }

#if defined(__GLIBC__)
#if ( __BYTE_ORDER == __LITTLE_ENDIAN )
#elif (__BYTE_ORDER == __BIG_ENDIAN)
    x.type += 1000;
#else
    return MATIO_E_OPERATION_NOT_SUPPORTED;
#endif
#elif defined(_BIG_ENDIAN) && !defined(_LITTLE_ENDIAN)
    x.type += 1000;
#elif defined(_LITTLE_ENDIAN) && !defined(_BIG_ENDIAN)
#elif defined(__sparc) || defined(__sparc__) || defined(_POWER) || defined(__powerpc__) || \
    defined(__ppc__) || defined(__hpux) || defined(_MIPSEB) || defined(_POWER) ||          \
    defined(__s390__)
    x.type += 1000;
#elif defined(__i386__) || defined(__alpha__) || defined(__ia64) || defined(__ia64__) ||   \
    defined(_M_IX86) || defined(_M_IA64) || defined(_M_ALPHA) || defined(__amd64) ||       \
    defined(__amd64__) || defined(_M_AMD64) || defined(__x86_64) || defined(__x86_64__) || \
    defined(_M_X64) || defined(__bfin__)
#else
    return MATIO_E_OPERATION_NOT_SUPPORTED;
#endif

    x.namelen = (mat_int32_t)strlen(matvar->name) + 1;

    /* FIXME: SEEK_END is not Guaranteed by the C standard */
    (void)fseek((FILE *)mat->fp, 0, SEEK_END); /* Always write at end of file */

    switch ( matvar->class_type ) {
        case MAT_C_CHAR:
            x.type++;
            /* Fall through */
        case MAT_C_DOUBLE:
        case MAT_C_SINGLE:
        case MAT_C_INT32:
        case MAT_C_INT16:
        case MAT_C_UINT16:
        case MAT_C_UINT8: {
            size_t nelems = 1;
            int err = Mat_MulDims(matvar, &nelems);
            if ( err ) {
                Mat_Critical("Integer multiplication overflow");
                return err;
            }

            x.mrows = (mat_int32_t)matvar->dims[0];
            x.ncols = (mat_int32_t)matvar->dims[1];
            x.imagf = matvar->isComplex ? 1 : 0;
            fwrite(&x, sizeof(Fmatrix), 1, (FILE *)mat->fp);
            fwrite(matvar->name, sizeof(char), x.namelen, (FILE *)mat->fp);
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                complex_data = (mat_complex_split_t *)matvar->data;
                fwrite(complex_data->Re, matvar->data_size, nelems, (FILE *)mat->fp);
                fwrite(complex_data->Im, matvar->data_size, nelems, (FILE *)mat->fp);
            } else {
                fwrite(matvar->data, matvar->data_size, nelems, (FILE *)mat->fp);
            }
            break;
        }
        case MAT_C_SPARSE: {
            mat_sparse_t *sparse;
            double tmp;
            mat_uint32_t j;
            size_t stride = Mat_SizeOf(matvar->data_type);
#if !defined(EXTENDED_SPARSE)
            if ( MAT_T_DOUBLE != matvar->data_type )
                break;
#endif

            sparse = (mat_sparse_t *)matvar->data;
            x.type += 2;
            x.mrows = sparse->njc > 0 ? sparse->jc[sparse->njc - 1] + 1 : 1;
            x.ncols = matvar->isComplex ? 4 : 3;
            x.imagf = 0;

            fwrite(&x, sizeof(Fmatrix), 1, (FILE *)mat->fp);
            fwrite(matvar->name, sizeof(char), x.namelen, (FILE *)mat->fp);

            for ( i = 0; i < sparse->njc - 1; i++ ) {
                for ( j = sparse->jc[i]; j < sparse->jc[i + 1] && j < sparse->ndata; j++ ) {
                    tmp = sparse->ir[j] + 1;
                    fwrite(&tmp, sizeof(double), 1, (FILE *)mat->fp);
                }
            }
            tmp = (double)matvar->dims[0];
            fwrite(&tmp, sizeof(double), 1, (FILE *)mat->fp);
            for ( i = 0; i < sparse->njc - 1; i++ ) {
                for ( j = sparse->jc[i]; j < sparse->jc[i + 1] && j < sparse->ndata; j++ ) {
                    tmp = i + 1;
                    fwrite(&tmp, sizeof(double), 1, (FILE *)mat->fp);
                }
            }
            tmp = (double)matvar->dims[1];
            fwrite(&tmp, sizeof(double), 1, (FILE *)mat->fp);
            tmp = 0.;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;
                char *re, *im;

                complex_data = (mat_complex_split_t *)sparse->data;
                re = (char *)complex_data->Re;
                im = (char *)complex_data->Im;
                for ( i = 0; i < sparse->njc - 1; i++ ) {
                    for ( j = sparse->jc[i]; j < sparse->jc[i + 1] && j < sparse->ndata; j++ ) {
                        fwrite(re + j * stride, stride, 1, (FILE *)mat->fp);
                    }
                }
                fwrite(&tmp, stride, 1, (FILE *)mat->fp);
                for ( i = 0; i < sparse->njc - 1; i++ ) {
                    for ( j = sparse->jc[i]; j < sparse->jc[i + 1] && j < sparse->ndata; j++ ) {
                        fwrite(im + j * stride, stride, 1, (FILE *)mat->fp);
                    }
                }
            } else {
                char *data = (char *)sparse->data;
                for ( i = 0; i < sparse->njc - 1; i++ ) {
                    for ( j = sparse->jc[i]; j < sparse->jc[i + 1] && j < sparse->ndata; j++ ) {
                        fwrite(data + j * stride, stride, 1, (FILE *)mat->fp);
                    }
                }
            }
            fwrite(&tmp, stride, 1, (FILE *)mat->fp);
            break;
        }
        default:
            break;
    }

    return MATIO_E_NO_ERROR;
}

/** @if mat_devman
 * @brief Reads the data of a version 4 MAT file variable
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar MAT variable pointer to read the data
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarRead4(mat_t *mat, matvar_t *matvar)
{
    int err;
    size_t nelems = 1;

    err = Mat_MulDims(matvar, &nelems);
    if ( err ) {
        Mat_Critical("Integer multiplication overflow");
        return err;
    }

    (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);

    switch ( matvar->class_type ) {
        case MAT_C_DOUBLE:
            matvar->data_size = sizeof(double);
            err = Mul(&matvar->nbytes, nelems, matvar->data_size);
            if ( err ) {
                Mat_Critical("Integer multiplication overflow");
                return err;
            }

            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = ComplexMalloc(matvar->nbytes);
                if ( NULL != complex_data ) {
                    size_t readcount;
                    readcount =
                        ReadDoubleData(mat, (double *)complex_data->Re, matvar->data_type, nelems);
                    err = readcount != nelems;
                    readcount =
                        ReadDoubleData(mat, (double *)complex_data->Im, matvar->data_type, nelems);
                    err |= readcount != nelems;
                    if ( 0 == err ) {
                        matvar->data = complex_data;
                    } else {
                        ComplexFree(complex_data);
                        return MATIO_E_FILE_FORMAT_VIOLATION;
                    }
                } else {
                    Mat_Critical("Couldn't allocate memory for the complex data");
                    return MATIO_E_OUT_OF_MEMORY;
                }
            } else {
                matvar->data = malloc(matvar->nbytes);
                if ( NULL != matvar->data ) {
                    const size_t readcount =
                        ReadDoubleData(mat, (double *)matvar->data, matvar->data_type, nelems);
                    if ( readcount != nelems ) {
                        free(matvar->data);
                        matvar->data = NULL;
                        return MATIO_E_FILE_FORMAT_VIOLATION;
                    }
                } else {
                    Mat_Critical("Couldn't allocate memory for the data");
                    return MATIO_E_OUT_OF_MEMORY;
                }
            }
            /* Update data type to match format of matvar->data */
            matvar->data_type = MAT_T_DOUBLE;
            break;
        case MAT_C_CHAR:
            matvar->data_size = 1;
            matvar->nbytes = nelems;
            matvar->data = malloc(matvar->nbytes);
            if ( NULL != matvar->data ) {
                const size_t readcount =
                    ReadUInt8Data(mat, (mat_uint8_t *)matvar->data, matvar->data_type, nelems);
                if ( readcount != nelems ) {
                    free(matvar->data);
                    matvar->data = NULL;
                    return MATIO_E_FILE_FORMAT_VIOLATION;
                }
            } else {
                Mat_Critical("Couldn't allocate memory for the data");
                return MATIO_E_OUT_OF_MEMORY;
            }
            matvar->data_type = MAT_T_UINT8;
            break;
        case MAT_C_SPARSE:
            matvar->data_size = sizeof(mat_sparse_t);
            matvar->data = calloc(1, matvar->data_size);
            if ( NULL != matvar->data ) {
                double tmp;
                mat_uint32_t i;
                mat_sparse_t *sparse;
                long fpos;
                enum matio_types data_type = MAT_T_DOUBLE;
                size_t readcount;

                /* matvar->dims[1] either is 3 for real or 4 for complex sparse */
                matvar->isComplex = matvar->dims[1] == 4 ? 1 : 0;
                if ( matvar->dims[0] < 2 ) {
                    return MATIO_E_FILE_FORMAT_VIOLATION;
                }
                sparse = (mat_sparse_t *)matvar->data;
                sparse->nir = matvar->dims[0] - 1;
                sparse->nzmax = sparse->nir;
                err = Mul(&readcount, sparse->nir, sizeof(mat_uint32_t));
                if ( err ) {
                    Mat_Critical("Integer multiplication overflow");
                    return err;
                }
                sparse->ir = (mat_uint32_t *)malloc(readcount);
                if ( sparse->ir != NULL ) {
                    readcount = ReadUInt32Data(mat, sparse->ir, data_type, sparse->nir);
                    if ( readcount != sparse->nir ) {
                        free(sparse->ir);
                        free(matvar->data);
                        matvar->data = NULL;
                        return MATIO_E_FILE_FORMAT_VIOLATION;
                    }
                    for ( i = 0; i < sparse->nir; i++ ) {
                        if ( 0 == sparse->ir[i] ) {
                            err = MATIO_E_FILE_FORMAT_VIOLATION;
                            break;
                        }
                        sparse->ir[i] = sparse->ir[i] - 1;
                    }
                    if ( err ) {
                        free(sparse->ir);
                        free(matvar->data);
                        matvar->data = NULL;
                        return err;
                    }
                } else {
                    free(matvar->data);
                    matvar->data = NULL;
                    Mat_Critical("Couldn't allocate memory for the sparse row array");
                    return MATIO_E_OUT_OF_MEMORY;
                }
                readcount = ReadDoubleData(mat, &tmp, data_type, 1);
                if ( readcount != 1 || tmp > UINT_MAX - 1 || tmp < 0 ) {
                    free(sparse->ir);
                    free(matvar->data);
                    matvar->data = NULL;
                    Mat_Critical("Invalid row dimension for sparse matrix");
                    return MATIO_E_FILE_FORMAT_VIOLATION;
                }
                matvar->dims[0] = (size_t)tmp;

                fpos = ftell((FILE *)mat->fp);
                if ( fpos == -1L ) {
                    free(sparse->ir);
                    free(matvar->data);
                    matvar->data = NULL;
                    Mat_Critical("Couldn't determine file position");
                    return MATIO_E_FILE_FORMAT_VIOLATION;
                }
                (void)fseek((FILE *)mat->fp, sparse->nir * Mat_SizeOf(data_type), SEEK_CUR);
                readcount = ReadDoubleData(mat, &tmp, data_type, 1);
                if ( readcount != 1 || tmp > UINT_MAX - 1 || tmp < 0 ) {
                    free(sparse->ir);
                    free(matvar->data);
                    matvar->data = NULL;
                    Mat_Critical("Invalid column dimension for sparse matrix");
                    return MATIO_E_FILE_FORMAT_VIOLATION;
                }
                matvar->dims[1] = (size_t)tmp;
                (void)fseek((FILE *)mat->fp, fpos, SEEK_SET);
                if ( matvar->dims[1] > UINT_MAX - 1 ) {
                    free(sparse->ir);
                    free(matvar->data);
                    matvar->data = NULL;
                    Mat_Critical("Invalid column dimension for sparse matrix");
                    return MATIO_E_FILE_FORMAT_VIOLATION;
                }
                sparse->njc = (mat_uint32_t)matvar->dims[1] + 1;
                err = Mul(&readcount, sparse->njc, sizeof(mat_uint32_t));
                if ( err ) {
                    Mat_Critical("Integer multiplication overflow");
                    return err;
                }
                sparse->jc = (mat_uint32_t *)malloc(readcount);
                if ( sparse->jc != NULL ) {
                    mat_uint32_t *jc;
                    err = Mul(&readcount, sparse->nir, sizeof(mat_uint32_t));
                    if ( err ) {
                        Mat_Critical("Integer multiplication overflow");
                        return err;
                    }
                    jc = (mat_uint32_t *)malloc(readcount);
                    if ( jc != NULL ) {
                        mat_uint32_t j = 0;
                        sparse->jc[0] = 0;
                        readcount = ReadUInt32Data(mat, jc, data_type, sparse->nir);
                        if ( readcount != sparse->nir ) {
                            free(jc);
                            free(sparse->jc);
                            free(sparse->ir);
                            free(matvar->data);
                            matvar->data = NULL;
                            return MATIO_E_FILE_FORMAT_VIOLATION;
                        }
                        for ( i = 1; i < sparse->njc - 1; i++ ) {
                            while ( j < sparse->nir && jc[j] <= i )
                                j++;
                            sparse->jc[i] = j;
                        }
                        free(jc);
                        /* terminating nnz */
                        sparse->jc[sparse->njc - 1] = sparse->nir;
                    } else {
                        free(sparse->jc);
                        free(sparse->ir);
                        free(matvar->data);
                        matvar->data = NULL;
                        Mat_Critical("Couldn't allocate memory for the sparse index array");
                        return MATIO_E_OUT_OF_MEMORY;
                    }
                } else {
                    free(sparse->ir);
                    free(matvar->data);
                    matvar->data = NULL;
                    Mat_Critical("Couldn't allocate memory for the sparse index array");
                    return MATIO_E_OUT_OF_MEMORY;
                }
                readcount = ReadDoubleData(mat, &tmp, data_type, 1);
                if ( readcount != 1 ) {
                    free(sparse->jc);
                    free(sparse->ir);
                    free(matvar->data);
                    matvar->data = NULL;
                    return MATIO_E_FILE_FORMAT_VIOLATION;
                }
                sparse->ndata = sparse->nir;
                data_type = matvar->data_type;
                if ( matvar->isComplex ) {
                    mat_complex_split_t *complex_data =
                        ComplexMalloc(sparse->ndata * Mat_SizeOf(data_type));
                    if ( NULL != complex_data ) {
                        sparse->data = complex_data;
#if defined(EXTENDED_SPARSE)
                        switch ( data_type ) {
                            case MAT_T_DOUBLE:
                                readcount = ReadDoubleData(mat, (double *)complex_data->Re,
                                                           data_type, sparse->ndata);
                                err = readcount != sparse->ndata;
                                readcount = ReadDoubleData(mat, &tmp, data_type, 1);
                                err |= readcount != 1;
                                readcount = ReadDoubleData(mat, (double *)complex_data->Im,
                                                           data_type, sparse->ndata);
                                err |= readcount != sparse->ndata;
                                readcount = ReadDoubleData(mat, &tmp, data_type, 1);
                                err |= readcount != 1;
                                break;
                            case MAT_T_SINGLE: {
                                float tmp2;
                                readcount = ReadSingleData(mat, (float *)complex_data->Re,
                                                           data_type, sparse->ndata);
                                err = readcount != sparse->ndata;
                                readcount = ReadSingleData(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                readcount = ReadSingleData(mat, (float *)complex_data->Im,
                                                           data_type, sparse->ndata);
                                err |= readcount != sparse->ndata;
                                readcount = ReadSingleData(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                break;
                            }
                            case MAT_T_INT32: {
                                mat_int32_t tmp2;
                                readcount = ReadInt32Data(mat, (mat_int32_t *)complex_data->Re,
                                                          data_type, sparse->ndata);
                                err = readcount != sparse->ndata;
                                readcount = ReadInt32Data(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                readcount = ReadInt32Data(mat, (mat_int32_t *)complex_data->Im,
                                                          data_type, sparse->ndata);
                                err |= readcount != sparse->ndata;
                                readcount = ReadInt32Data(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                break;
                            }
                            case MAT_T_INT16: {
                                mat_int16_t tmp2;
                                readcount = ReadInt16Data(mat, (mat_int16_t *)complex_data->Re,
                                                          data_type, sparse->ndata);
                                err = readcount != sparse->ndata;
                                readcount = ReadInt16Data(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                readcount = ReadInt16Data(mat, (mat_int16_t *)complex_data->Im,
                                                          data_type, sparse->ndata);
                                err |= readcount != sparse->ndata;
                                readcount = ReadInt16Data(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                break;
                            }
                            case MAT_T_UINT16: {
                                mat_uint16_t tmp2;
                                readcount = ReadUInt16Data(mat, (mat_uint16_t *)complex_data->Re,
                                                           data_type, sparse->ndata);
                                err = readcount != sparse->ndata;
                                readcount = ReadUInt16Data(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                readcount = ReadUInt16Data(mat, (mat_uint16_t *)complex_data->Im,
                                                           data_type, sparse->ndata);
                                err |= readcount != sparse->ndata;
                                readcount = ReadUInt16Data(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                break;
                            }
                            case MAT_T_UINT8: {
                                mat_uint8_t tmp2;
                                readcount = ReadUInt8Data(mat, (mat_uint8_t *)complex_data->Re,
                                                          data_type, sparse->ndata);
                                err = readcount != sparse->ndata;
                                readcount = ReadUInt8Data(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                readcount = ReadUInt8Data(mat, (mat_uint8_t *)complex_data->Im,
                                                          data_type, sparse->ndata);
                                err |= readcount != sparse->ndata;
                                readcount = ReadUInt8Data(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                break;
                            }
                            default:
                                ComplexFree(complex_data);
                                free(sparse->jc);
                                free(sparse->ir);
                                free(matvar->data);
                                matvar->data = NULL;
                                Mat_Critical(
                                    "Mat_VarRead4: %d is not a supported data type for "
                                    "extended sparse",
                                    data_type);
                                return MATIO_E_FILE_FORMAT_VIOLATION;
                        }
#else
                        readcount = ReadDoubleData(mat, (double *)complex_data->Re, data_type,
                                                   sparse->ndata);
                        err = readcount != sparse->ndata;
                        readcount = ReadDoubleData(mat, &tmp, data_type, 1);
                        err |= readcount != 1;
                        readcount = ReadDoubleData(mat, (double *)complex_data->Im, data_type,
                                                   sparse->ndata);
                        err |= readcount != sparse->ndata;
                        readcount = ReadDoubleData(mat, &tmp, data_type, 1);
                        err |= readcount != 1;
#endif
                        if ( err ) {
                            ComplexFree(complex_data);
                            free(sparse->jc);
                            free(sparse->ir);
                            free(matvar->data);
                            matvar->data = NULL;
                            return MATIO_E_FILE_FORMAT_VIOLATION;
                        }
                    } else {
                        free(sparse->jc);
                        free(sparse->ir);
                        free(matvar->data);
                        matvar->data = NULL;
                        Mat_Critical("Couldn't allocate memory for the complex sparse data");
                        return MATIO_E_OUT_OF_MEMORY;
                    }
                } else {
                    sparse->data = malloc(sparse->ndata * Mat_SizeOf(data_type));
                    if ( sparse->data != NULL ) {
#if defined(EXTENDED_SPARSE)
                        switch ( data_type ) {
                            case MAT_T_DOUBLE:
                                readcount = ReadDoubleData(mat, (double *)sparse->data, data_type,
                                                           sparse->ndata);
                                err = readcount != sparse->ndata;
                                readcount = ReadDoubleData(mat, &tmp, data_type, 1);
                                err |= readcount != 1;
                                break;
                            case MAT_T_SINGLE: {
                                float tmp2;
                                readcount = ReadSingleData(mat, (float *)sparse->data, data_type,
                                                           sparse->ndata);
                                err = readcount != sparse->ndata;
                                readcount = ReadSingleData(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                break;
                            }
                            case MAT_T_INT32: {
                                mat_int32_t tmp2;
                                readcount = ReadInt32Data(mat, (mat_int32_t *)sparse->data,
                                                          data_type, sparse->ndata);
                                err = readcount != sparse->ndata;
                                readcount = ReadInt32Data(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                break;
                            }
                            case MAT_T_INT16: {
                                mat_int16_t tmp2;
                                readcount = ReadInt16Data(mat, (mat_int16_t *)sparse->data,
                                                          data_type, sparse->ndata);
                                err = readcount != sparse->ndata;
                                readcount = ReadInt16Data(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                break;
                            }
                            case MAT_T_UINT16: {
                                mat_uint16_t tmp2;
                                readcount = ReadUInt16Data(mat, (mat_uint16_t *)sparse->data,
                                                           data_type, sparse->ndata);
                                err = readcount != sparse->ndata;
                                readcount = ReadUInt16Data(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                break;
                            }
                            case MAT_T_UINT8: {
                                mat_uint8_t tmp2;
                                readcount = ReadUInt8Data(mat, (mat_uint8_t *)sparse->data,
                                                          data_type, sparse->ndata);
                                err = readcount != sparse->ndata;
                                readcount = ReadUInt8Data(mat, &tmp2, data_type, 1);
                                err |= readcount != 1;
                                break;
                            }
                            default:
                                free(sparse->data);
                                free(sparse->jc);
                                free(sparse->ir);
                                free(matvar->data);
                                matvar->data = NULL;
                                Mat_Critical(
                                    "Mat_VarRead4: %d is not a supported data type for "
                                    "extended sparse",
                                    data_type);
                                return MATIO_E_FILE_FORMAT_VIOLATION;
                        }
#else
                        readcount =
                            ReadDoubleData(mat, (double *)sparse->data, data_type, sparse->ndata);
                        err = readcount != sparse->ndata;
                        readcount = ReadDoubleData(mat, &tmp, data_type, 1);
                        err |= readcount != 1;
#endif
                        if ( err ) {
                            free(sparse->data);
                            free(sparse->jc);
                            free(sparse->ir);
                            free(matvar->data);
                            matvar->data = NULL;
                            return MATIO_E_FILE_FORMAT_VIOLATION;
                        }
                    } else {
                        free(sparse->jc);
                        free(sparse->ir);
                        free(matvar->data);
                        matvar->data = NULL;
                        Mat_Critical("Couldn't allocate memory for the sparse data");
                        return MATIO_E_OUT_OF_MEMORY;
                    }
                }
                break;
            } else {
                Mat_Critical("Couldn't allocate memory for the data");
                return MATIO_E_OUT_OF_MEMORY;
            }
        default:
            Mat_Critical("MAT V4 data type error");
            return MATIO_E_FILE_FORMAT_VIOLATION;
    }

    return MATIO_E_NO_ERROR;
}

/** @if mat_devman
 * @brief Reads a slab of data from a version 4 MAT file for the @c matvar variable
 *
 * @ingroup mat_internal
 * @param mat Version 4 MAT file pointer
 * @param matvar pointer to the mat variable
 * @param data pointer to store the read data in (must be of size
 *             edge[0]*...edge[rank-1]*Mat_SizeOfClass(matvar->class_type))
 * @param start index to start reading data in each dimension
 * @param stride write data every @c stride elements in each dimension
 * @param edge number of elements to read in each dimension
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarReadData4(mat_t *mat, matvar_t *matvar, void *data, int *start, int *stride, int *edge)
{
    int err = MATIO_E_NO_ERROR;

    (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);

    switch ( matvar->data_type ) {
        case MAT_T_DOUBLE:
        case MAT_T_SINGLE:
        case MAT_T_INT32:
        case MAT_T_INT16:
        case MAT_T_UINT16:
        case MAT_T_UINT8:
            break;
        default:
            return MATIO_E_FILE_FORMAT_VIOLATION;
    }

    if ( matvar->rank == 2 ) {
        if ( (size_t)stride[0] * (edge[0] - 1) + start[0] + 1 > matvar->dims[0] )
            err = MATIO_E_BAD_ARGUMENT;
        else if ( (size_t)stride[1] * (edge[1] - 1) + start[1] + 1 > matvar->dims[1] )
            err = MATIO_E_BAD_ARGUMENT;
        if ( matvar->isComplex ) {
            mat_complex_split_t *cdata = (mat_complex_split_t *)data;
            size_t nbytes = Mat_SizeOf(matvar->data_type);
            err = Mat_MulDims(matvar, &nbytes);
            if ( err ) {
                Mat_Critical("Integer multiplication overflow");
                return err;
            }

            ReadDataSlab2(mat, cdata->Re, matvar->class_type, matvar->data_type, matvar->dims,
                          start, stride, edge);
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos + nbytes, SEEK_SET);
            ReadDataSlab2(mat, cdata->Im, matvar->class_type, matvar->data_type, matvar->dims,
                          start, stride, edge);
        } else {
            ReadDataSlab2(mat, data, matvar->class_type, matvar->data_type, matvar->dims, start,
                          stride, edge);
        }
    } else if ( matvar->isComplex ) {
        mat_complex_split_t *cdata = (mat_complex_split_t *)data;
        size_t nbytes = Mat_SizeOf(matvar->data_type);
        err = Mat_MulDims(matvar, &nbytes);
        if ( err ) {
            Mat_Critical("Integer multiplication overflow");
            return err;
        }

        ReadDataSlabN(mat, cdata->Re, matvar->class_type, matvar->data_type, matvar->rank,
                      matvar->dims, start, stride, edge);
        (void)fseek((FILE *)mat->fp, matvar->internal->datapos + nbytes, SEEK_SET);
        ReadDataSlabN(mat, cdata->Im, matvar->class_type, matvar->data_type, matvar->rank,
                      matvar->dims, start, stride, edge);
    } else {
        ReadDataSlabN(mat, data, matvar->class_type, matvar->data_type, matvar->rank, matvar->dims,
                      start, stride, edge);
    }

    return err;
}

/** @brief Reads a subset of a MAT variable using a 1-D indexing
 *
 * Reads data from a MAT variable using a linear (1-D) indexing mode. The
 * variable must have been read by Mat_VarReadInfo.
 * @ingroup MAT
 * @param mat MAT file to read data from
 * @param matvar MAT variable information
 * @param data pointer to store data in (must be pre-allocated)
 * @param start starting index
 * @param stride stride of data
 * @param edge number of elements to read
 * @retval 0 on success
 */
static int
Mat_VarReadDataLinear4(mat_t *mat, matvar_t *matvar, void *data, int start, int stride, int edge)
{
    int err;
    size_t nelems = 1;

    err = Mat_MulDims(matvar, &nelems);
    if ( err ) {
        Mat_Critical("Integer multiplication overflow");
        return err;
    }

    (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);

    matvar->data_size = Mat_SizeOf(matvar->data_type);

    if ( (size_t)stride * (edge - 1) + start + 1 > nelems ) {
        return MATIO_E_BAD_ARGUMENT;
    }
    if ( matvar->isComplex ) {
        mat_complex_split_t *complex_data = (mat_complex_split_t *)data;
        err = Mul(&nelems, nelems, matvar->data_size);
        if ( err ) {
            Mat_Critical("Integer multiplication overflow");
            return err;
        }

        ReadDataSlab1(mat, complex_data->Re, matvar->class_type, matvar->data_type, start, stride,
                      edge);
        (void)fseek((FILE *)mat->fp, matvar->internal->datapos + nelems, SEEK_SET);
        ReadDataSlab1(mat, complex_data->Im, matvar->class_type, matvar->data_type, start, stride,
                      edge);
    } else {
        ReadDataSlab1(mat, data, matvar->class_type, matvar->data_type, start, stride, edge);
    }

    return err;
}

/** @if mat_devman
 * @brief Reads the header information for the next MAT variable in a version 4 MAT file
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @return pointer to the MAT variable or NULL
 * @endif
 */
static matvar_t *
Mat_VarReadNextInfo4(mat_t *mat)
{
    int M, O, data_type, class_type;
    mat_int32_t tmp;
    long nBytes, fpos;
    matvar_t *matvar = NULL;
    union {
        mat_uint32_t u;
        mat_uint8_t c[4];
    } endian;

    if ( mat == NULL || mat->fp == NULL )
        return NULL;

    if ( IsEndOfFile((FILE *)mat->fp, &fpos) )
        return NULL;

    if ( fpos == -1L )
        return NULL;

    {
        size_t nbytes = 0;
        int err = Read(&tmp, sizeof(mat_int32_t), 1, (FILE *)mat->fp, &nbytes);
        if ( err || 0 == nbytes )
            return NULL;
    }

    endian.u = 0x01020304;

    /* See if MOPT may need byteswapping */
    if ( tmp < 0 || tmp > 4052 ) {
        if ( Mat_int32Swap(&tmp) > 4052 ) {
            return NULL;
        }
    }

    M = (int)floor(tmp / 1000.0);
    switch ( M ) {
        case 0:
            /* IEEE little endian */
            mat->byteswap = endian.c[0] != 4;
            break;
        case 1:
            /* IEEE big endian */
            mat->byteswap = endian.c[0] != 1;
            break;
        default:
            /* VAX, Cray, or bogus */
            return NULL;
    }

    tmp -= M * 1000;
    O = (int)floor(tmp / 100.0);
    /* O must be zero */
    if ( 0 != O ) {
        return NULL;
    }

    if ( NULL == (matvar = Mat_VarCalloc()) )
        return NULL;

    tmp -= O * 100;
    data_type = (int)floor(tmp / 10.0);
    /* Convert the V4 data type */
    switch ( data_type ) {
        case 0:
            matvar->data_type = MAT_T_DOUBLE;
            break;
        case 1:
            matvar->data_type = MAT_T_SINGLE;
            break;
        case 2:
            matvar->data_type = MAT_T_INT32;
            break;
        case 3:
            matvar->data_type = MAT_T_INT16;
            break;
        case 4:
            matvar->data_type = MAT_T_UINT16;
            break;
        case 5:
            matvar->data_type = MAT_T_UINT8;
            break;
        default:
            Mat_VarFree(matvar);
            return NULL;
    }

    tmp -= data_type * 10;
    class_type = (int)floor(tmp / 1.0);
    switch ( class_type ) {
        case 0:
            matvar->class_type = MAT_C_DOUBLE;
            break;
        case 1:
            matvar->class_type = MAT_C_CHAR;
            break;
        case 2:
            matvar->class_type = MAT_C_SPARSE;
            break;
        default:
            Mat_VarFree(matvar);
            return NULL;
    }

    matvar->rank = 2;
    matvar->dims = (size_t *)calloc(2, sizeof(*matvar->dims));
    if ( NULL == matvar->dims ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    if ( 0 != Read(&tmp, sizeof(int), 1, (FILE *)mat->fp, NULL) ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    if ( mat->byteswap )
        Mat_int32Swap(&tmp);
    matvar->dims[0] = tmp;

    if ( 0 != Read(&tmp, sizeof(int), 1, (FILE *)mat->fp, NULL) ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    if ( mat->byteswap )
        Mat_int32Swap(&tmp);
    matvar->dims[1] = tmp;

    if ( 0 != Read(&(matvar->isComplex), sizeof(int), 1, (FILE *)mat->fp, NULL) ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    if ( matvar->isComplex && MAT_C_CHAR == matvar->class_type ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    if ( 0 != Read(&tmp, sizeof(int), 1, (FILE *)mat->fp, NULL) ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    if ( mat->byteswap )
        Mat_int32Swap(&tmp);
    /* Check that the length of the variable name is at least 1 */
    if ( tmp < 1 ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    matvar->name = (char *)malloc(tmp);
    if ( NULL == matvar->name ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    if ( 0 != Read(matvar->name, sizeof(char), tmp, (FILE *)mat->fp, NULL) ) {
        Mat_VarFree(matvar);
        return NULL;
    } else {
        matvar->name[tmp - 1] = '\0';
    }

    matvar->internal->datapos = ftell((FILE *)mat->fp);
    if ( matvar->internal->datapos == -1L ) {
        Mat_VarFree(matvar);
        Mat_Critical("Couldn't determine file position");
        return NULL;
    }
    {
        int err;
        size_t tmp2 = Mat_SizeOf(matvar->data_type);
        if ( matvar->isComplex )
            tmp2 *= 2;
        err = Mat_MulDims(matvar, &tmp2);
        if ( err ) {
            Mat_VarFree(matvar);
            Mat_Critical("Integer multiplication overflow");
            return NULL;
        }

        nBytes = (long)tmp2;
    }
    (void)fseek((FILE *)mat->fp, nBytes, SEEK_CUR);

    return matvar;
}

/* -------------------------------
 * ---------- mat5.c
 * -------------------------------
 */
/** @file mat5.c
 * Matlab MAT version 5 file functions
 * @ingroup MAT
 */

/* FIXME: Implement Unicode support */

/** Get type from tag */
#define TYPE_FROM_TAG(a) \
    (((a)&0x000000ff) <= MAT_T_FUNCTION) ? (enum matio_types)((a)&0x000000ff) : MAT_T_UNKNOWN
/** Get class from array flag */
#define CLASS_FROM_ARRAY_FLAGS(a) \
    (((a)&0x000000ff) <= MAT_C_OPAQUE) ? ((enum matio_classes)((a)&0x000000ff)) : MAT_C_EMPTY
/** Class type mask */
#define CLASS_TYPE_MASK 0x000000ff

static mat_complex_split_t null_complex_data = {NULL, NULL};

/*===========================================================================
 *  Private functions
 *===========================================================================
 */
static int GetTypeBufSize(matvar_t *matvar, size_t *size);
static int GetStructFieldBufSize(matvar_t *matvar, size_t *size);
static int GetCellArrayFieldBufSize(matvar_t *matvar, size_t *size);
static void SetFieldNames(matvar_t *matvar, char *buf, size_t nfields,
                          mat_uint32_t fieldname_length);
static size_t ReadSparse(mat_t *mat, matvar_t *matvar, mat_uint32_t *n, mat_uint32_t **v);
#if HAVE_ZLIB
static int GetMatrixMaxBufSize(matvar_t *matvar, size_t *size);
#endif
static int GetEmptyMatrixMaxBufSize(const char *name, int rank, size_t *size);
static size_t WriteCharData(mat_t *mat, void *data, size_t N, enum matio_types data_type);
static size_t ReadNextCell(mat_t *mat, matvar_t *matvar);
static size_t ReadNextStructField(mat_t *mat, matvar_t *matvar);
static size_t ReadNextFunctionHandle(mat_t *mat, matvar_t *matvar);
static int ReadRankDims(mat_t *mat, matvar_t *matvar, enum matio_types data_type,
                        mat_uint32_t nbytes, size_t *read_bytes);
static int WriteType(mat_t *mat, matvar_t *matvar);
static int WriteCellArrayField(mat_t *mat, matvar_t *matvar);
static int WriteStructField(mat_t *mat, matvar_t *matvar);
static int WriteData(mat_t *mat, void *data, size_t N, enum matio_types data_type);
static size_t Mat_WriteEmptyVariable5(mat_t *mat, const char *name, int rank, size_t *dims);
static int Mat_VarReadNumeric5(mat_t *mat, matvar_t *matvar, void *data, size_t N);
#if HAVE_ZLIB
static size_t WriteCompressedCharData(mat_t *mat, z_streamp z, void *data, size_t N,
                                      enum matio_types data_type);
static size_t WriteCompressedData(mat_t *mat, z_streamp z, void *data, int N,
                                  enum matio_types data_type);
static size_t WriteCompressedTypeArrayFlags(mat_t *mat, matvar_t *matvar, z_streamp z);
static size_t WriteCompressedType(mat_t *mat, matvar_t *matvar, z_streamp z);
static size_t WriteCompressedCellArrayField(mat_t *mat, matvar_t *matvar, z_streamp z);
static size_t WriteCompressedStructField(mat_t *mat, matvar_t *matvar, z_streamp z);
static size_t Mat_WriteCompressedEmptyVariable5(mat_t *mat, const char *name, int rank,
                                                size_t *dims, z_streamp z);
#endif

/** @brief determines the number of bytes for a given class type
 *
 * @ingroup mat_internal
 * @param matvar MAT variable
 * @param size the number of bytes needed to store the MAT variable
 * @return 0 on success
 */
static int
GetTypeBufSize(matvar_t *matvar, size_t *size)
{
    int err;
    size_t nBytes, data_bytes;
    size_t tag_size = 8;
    size_t nelems = 1;
    size_t rank_size;

    *size = 0;

    err = Mat_MulDims(matvar, &nelems);
    if ( err )
        return err;

    /* Add rank and dimensions, padded to an 8 byte block */
    err = Mul(&rank_size, matvar->rank, 4);
    if ( err )
        return err;

    if ( matvar->rank % 2 )
        nBytes = tag_size + 4;
    else
        nBytes = tag_size;

    err = Add(&nBytes, nBytes, rank_size);
    if ( err )
        return err;

    switch ( matvar->class_type ) {
        case MAT_C_STRUCT: {
            matvar_t **fields = (matvar_t **)matvar->data;
            size_t nfields = matvar->internal->num_fields;
            size_t maxlen = 0, i, field_buf_size;

            for ( i = 0; i < nfields; i++ ) {
                char *fieldname = matvar->internal->fieldnames[i];
                if ( NULL != fieldname && strlen(fieldname) > maxlen )
                    maxlen = strlen(fieldname);
            }
            maxlen++;
            while ( nfields * maxlen % 8 != 0 )
                maxlen++;

            err = Mul(&field_buf_size, maxlen, nfields);
            if ( err )
                return err;
            err = Add(&nBytes, nBytes, tag_size + tag_size);
            if ( err )
                return err;
            err = Add(&nBytes, nBytes, field_buf_size);
            if ( err )
                return err;

            /* FIXME: Add bytes for the fieldnames */
            if ( NULL != fields && nfields > 0 ) {
                size_t nelems_x_nfields = 1;
                err = Mul(&nelems_x_nfields, nelems, nfields);
                if ( err )
                    return err;

                for ( i = 0; i < nelems_x_nfields; i++ ) {
                    err = GetStructFieldBufSize(fields[i], &field_buf_size);
                    if ( err )
                        return err;
                    err = Add(&nBytes, nBytes, tag_size);
                    if ( err )
                        return err;
                    err = Add(&nBytes, nBytes, field_buf_size);
                    if ( err )
                        return err;
                }
            }
            break;
        }
        case MAT_C_CELL: {
            matvar_t **cells = (matvar_t **)matvar->data;

            if ( matvar->nbytes == 0 || matvar->data_size == 0 )
                break;

            nelems = matvar->nbytes / matvar->data_size;
            if ( NULL != cells && nelems > 0 ) {
                size_t i, field_buf_size;
                for ( i = 0; i < nelems; i++ ) {
                    err = GetCellArrayFieldBufSize(cells[i], &field_buf_size);
                    if ( err )
                        return err;
                    err = Add(&nBytes, nBytes, tag_size);
                    if ( err )
                        return err;
                    err = Add(&nBytes, nBytes, field_buf_size);
                    if ( err )
                        return err;
                }
            }
            break;
        }
        case MAT_C_SPARSE: {
            mat_sparse_t *sparse = (mat_sparse_t *)matvar->data;

            err = Mul(&data_bytes, sparse->nir, sizeof(mat_uint32_t));
            if ( err )
                return err;
            if ( data_bytes % 8 ) {
                err = Add(&data_bytes, data_bytes, 8 - data_bytes % 8);
                if ( err )
                    return err;
            }
            err = Add(&nBytes, nBytes, tag_size);
            if ( err )
                return err;
            err = Add(&nBytes, nBytes, data_bytes);
            if ( err )
                return err;

            err = Mul(&data_bytes, sparse->njc, sizeof(mat_uint32_t));
            if ( err )
                return err;
            if ( data_bytes % 8 ) {
                err = Add(&data_bytes, data_bytes, 8 - data_bytes % 8);
                if ( err )
                    return err;
            }
            err = Add(&nBytes, nBytes, tag_size);
            if ( err )
                return err;
            err = Add(&nBytes, nBytes, data_bytes);
            if ( err )
                return err;

            err = Mul(&data_bytes, sparse->ndata, Mat_SizeOf(matvar->data_type));
            if ( err )
                return err;
            if ( data_bytes % 8 ) {
                err = Add(&data_bytes, data_bytes, 8 - data_bytes % 8);
                if ( err )
                    return err;
            }
            err = Add(&nBytes, nBytes, tag_size);
            if ( err )
                return err;
            err = Add(&nBytes, nBytes, data_bytes);
            if ( err )
                return err;

            if ( matvar->isComplex ) {
                err = Add(&nBytes, nBytes, tag_size);
                if ( err )
                    return err;
                err = Add(&nBytes, nBytes, data_bytes);
                if ( err )
                    return err;
            }

            break;
        }
        case MAT_C_CHAR:
            if ( MAT_T_UINT8 == matvar->data_type || MAT_T_INT8 == matvar->data_type )
                err = Mul(&data_bytes, nelems, Mat_SizeOf(MAT_T_UINT16));
            else
                err = Mul(&data_bytes, nelems, Mat_SizeOf(matvar->data_type));
            if ( err )
                return err;
            if ( data_bytes % 8 ) {
                err = Add(&data_bytes, data_bytes, 8 - data_bytes % 8);
                if ( err )
                    return err;
            }

            err = Add(&nBytes, nBytes, tag_size);
            if ( err )
                return err;
            err = Add(&nBytes, nBytes, data_bytes);
            if ( err )
                return err;

            if ( matvar->isComplex ) {
                err = Add(&nBytes, nBytes, tag_size);
                if ( err )
                    return err;
                err = Add(&nBytes, nBytes, data_bytes);
                if ( err )
                    return err;
            }

            break;
        default:
            err = Mul(&data_bytes, nelems, Mat_SizeOf(matvar->data_type));
            if ( err )
                return err;
            if ( data_bytes % 8 ) {
                err = Add(&data_bytes, data_bytes, 8 - data_bytes % 8);
                if ( err )
                    return err;
            }

            err = Add(&nBytes, nBytes, tag_size);
            if ( err )
                return err;
            err = Add(&nBytes, nBytes, data_bytes);
            if ( err )
                return err;

            if ( matvar->isComplex ) {
                err = Add(&nBytes, nBytes, tag_size);
                if ( err )
                    return err;
                err = Add(&nBytes, nBytes, data_bytes);
                if ( err )
                    return err;
            }
    } /* switch ( matvar->class_type ) */

    *size = nBytes;
    return MATIO_E_NO_ERROR;
}

/** @brief determines the number of bytes needed to store the given struct field
 *
 * @ingroup mat_internal
 * @param matvar field of a structure
 * @param size the number of bytes needed to store the struct field
 * @return 0 on success
 */
static int
GetStructFieldBufSize(matvar_t *matvar, size_t *size)
{
    int err;
    size_t nBytes = 0, type_buf_size;
    size_t tag_size = 8, array_flags_size = 8;

    *size = 0;

    if ( matvar == NULL )
        return GetEmptyMatrixMaxBufSize(NULL, 2, size);

    /* Add the Array Flags tag and space to the number of bytes */
    nBytes += tag_size + array_flags_size;

    /* In a struct field, the name is just a tag with 0 bytes */
    nBytes += tag_size;

    err = GetTypeBufSize(matvar, &type_buf_size);
    if ( err )
        return err;
    err = Add(&nBytes, nBytes, type_buf_size);
    if ( err )
        return err;

    *size = nBytes;
    return MATIO_E_NO_ERROR;
}

/** @brief determines the number of bytes needed to store the cell array element
 *
 * @ingroup mat_internal
 * @param matvar MAT variable
 * @param size the number of bytes needed to store the variable
 * @return 0 on success
 */
static int
GetCellArrayFieldBufSize(matvar_t *matvar, size_t *size)
{
    int err;
    size_t nBytes = 0, type_buf_size;
    size_t tag_size = 8, array_flags_size = 8;

    *size = 0;

    if ( matvar == NULL )
        return MATIO_E_BAD_ARGUMENT;

    /* Add the Array Flags tag and space to the number of bytes */
    nBytes += tag_size + array_flags_size;

    /* In an element of a cell array, the name is just a tag with 0 bytes */
    nBytes += tag_size;

    err = GetTypeBufSize(matvar, &type_buf_size);
    if ( err )
        return err;
    err = Add(&nBytes, nBytes, type_buf_size);
    if ( err )
        return err;

    *size = nBytes;
    return MATIO_E_NO_ERROR;
}

/** @brief determines the number of bytes needed to store the given variable
 *
 * @ingroup mat_internal
 * @param matvar MAT variable
 * @param rank rank of the variable
 * @param size the number of bytes needed to store the variable
 * @return 0 on success
 */
static int
GetEmptyMatrixMaxBufSize(const char *name, int rank, size_t *size)
{
    int err = 0;
    size_t nBytes = 0, len, rank_size;
    size_t tag_size = 8, array_flags_size = 8;

    /* Add the Array Flags tag and space to the number of bytes */
    nBytes += tag_size + array_flags_size;

    /* Get size of variable name, pad it to an 8 byte block, and add it to nBytes */
    if ( NULL != name )
        len = strlen(name);
    else
        len = 4;

    if ( len <= 4 ) {
        nBytes += tag_size;
    } else {
        nBytes += tag_size;
        if ( len % 8 ) {
            err = Add(&len, len, 8 - len % 8);
            if ( err )
                return err;
        }

        err = Add(&nBytes, nBytes, len);
        if ( err )
            return err;
    }

    /* Add rank and dimensions, padded to an 8 byte block */
    err = Mul(&rank_size, rank, 4);
    if ( err )
        return err;
    if ( rank % 2 )
        err = Add(&nBytes, nBytes, tag_size + 4);
    else
        err = Add(&nBytes, nBytes, tag_size);
    if ( err )
        return err;

    err = Add(&nBytes, nBytes, rank_size);
    if ( err )
        return err;
    /* Data tag */
    err = Add(&nBytes, nBytes, tag_size);
    if ( err )
        return err;

    *size = nBytes;
    return MATIO_E_NO_ERROR;
}

static void
SetFieldNames(matvar_t *matvar, char *buf, size_t nfields, mat_uint32_t fieldname_length)
{
    matvar->internal->num_fields = nfields;
    matvar->internal->fieldnames = (char **)calloc(nfields, sizeof(*matvar->internal->fieldnames));
    if ( NULL != matvar->internal->fieldnames ) {
        size_t i;
        for ( i = 0; i < nfields; i++ ) {
            matvar->internal->fieldnames[i] = (char *)malloc(fieldname_length);
            if ( NULL != matvar->internal->fieldnames[i] ) {
                memcpy(matvar->internal->fieldnames[i], buf + i * fieldname_length,
                       fieldname_length);
                matvar->internal->fieldnames[i][fieldname_length - 1] = '\0';
            }
        }
    }
}

static size_t
ReadSparse(mat_t *mat, matvar_t *matvar, mat_uint32_t *n, mat_uint32_t **v)
{
    int data_in_tag = 0;
    enum matio_types packed_type;
    mat_uint32_t tag[2];
    size_t bytesread = 0;
    mat_uint32_t N = 0;

    if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
#if HAVE_ZLIB
        matvar->internal->z->avail_in = 0;
        if ( 0 != Inflate(mat, matvar->internal->z, tag, 4, &bytesread) ) {
            return bytesread;
        }
        if ( mat->byteswap )
            (void)Mat_uint32Swap(tag);
        packed_type = TYPE_FROM_TAG(tag[0]);
        if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
            data_in_tag = 1;
            N = (tag[0] & 0xffff0000) >> 16;
        } else {
            data_in_tag = 0;
            (void)ReadCompressedUInt32Data(mat, matvar->internal->z, &N, MAT_T_UINT32, 1);
        }
#endif
    } else {
        if ( 0 != Read(tag, 4, 1, (FILE *)mat->fp, &bytesread) ) {
            return bytesread;
        }
        if ( mat->byteswap )
            (void)Mat_uint32Swap(tag);
        packed_type = TYPE_FROM_TAG(tag[0]);
        if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
            data_in_tag = 1;
            N = (tag[0] & 0xffff0000) >> 16;
        } else {
            data_in_tag = 0;
            if ( 0 != Read(&N, 4, 1, (FILE *)mat->fp, &bytesread) ) {
                return bytesread;
            }
            if ( mat->byteswap )
                (void)Mat_uint32Swap(&N);
        }
    }
    if ( 0 == N )
        return bytesread;
    *n = N / 4;
    *v = (mat_uint32_t *)calloc(N, 1);
    if ( NULL != *v ) {
        int nBytes;
        if ( matvar->compression == MAT_COMPRESSION_NONE ) {
            nBytes = ReadUInt32Data(mat, *v, packed_type, *n);
            /*
                * If the data was in the tag we started on a 4-byte
                * boundary so add 4 to make it an 8-byte
                */
            nBytes *= Mat_SizeOf(packed_type);
            if ( data_in_tag )
                nBytes += 4;
            if ( (nBytes % 8) != 0 )
                (void)fseek((FILE *)mat->fp, 8 - (nBytes % 8), SEEK_CUR);
#if HAVE_ZLIB
        } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
            nBytes = ReadCompressedUInt32Data(mat, matvar->internal->z, *v, packed_type, *n);
            /*
                * If the data was in the tag we started on a 4-byte
                * boundary so add 4 to make it an 8-byte
                */
            if ( data_in_tag )
                nBytes += 4;
            if ( (nBytes % 8) != 0 )
                InflateSkip(mat, matvar->internal->z, 8 - (nBytes % 8), NULL);
#endif
        }
    } else {
        Mat_Critical("Couldn't allocate memory");
    }

    return bytesread;
}

#if HAVE_ZLIB
/** @brief determines the number of bytes needed to store the given variable
 *
 * @ingroup mat_internal
 * @param matvar MAT variable
 * @param size the number of bytes needed to store the variable
 * @return 0 on success
 */
static int
GetMatrixMaxBufSize(matvar_t *matvar, size_t *size)
{
    int err = MATIO_E_NO_ERROR;
    size_t nBytes = 0, len, type_buf_size;
    size_t tag_size = 8, array_flags_size = 8;

    if ( matvar == NULL )
        return MATIO_E_BAD_ARGUMENT;

    /* Add the Array Flags tag and space to the number of bytes */
    nBytes += tag_size + array_flags_size;

    /* Get size of variable name, pad it to an 8 byte block, and add it to nBytes */
    if ( NULL != matvar->name )
        len = strlen(matvar->name);
    else
        len = 4;

    if ( len <= 4 ) {
        nBytes += tag_size;
    } else {
        nBytes += tag_size;
        if ( len % 8 ) {
            err = Add(&len, len, 8 - len % 8);
            if ( err )
                return err;
        }

        err = Add(&nBytes, nBytes, len);
        if ( err )
            return err;
    }

    err = GetTypeBufSize(matvar, &type_buf_size);
    if ( err )
        return err;
    err = Add(&nBytes, nBytes, type_buf_size);
    if ( err )
        return err;

    *size = nBytes;
    return MATIO_E_NO_ERROR;
}
#endif

/** @if mat_devman
 * @brief Creates a new Matlab MAT version 5 file
 *
 * Tries to create a new Matlab MAT file with the given name and optional
 * header string.  If no header string is given, the default string
 * is used containing the software, version, and date in it.  If a header
 * string is given, at most the first 116 characters is written to the file.
 * The given header string need not be the full 116 characters, but MUST be
 * NULL terminated.
 * @ingroup MAT
 * @param matname Name of MAT file to create
 * @param hdr_str Optional header string, NULL to use default
 * @return A pointer to the MAT file or NULL if it failed.  This is not a
 * simple FILE * and should not be used as one.
 * @endif
 */
static mat_t *
Mat_Create5(const char *matname, const char *hdr_str)
{
    FILE *fp = NULL;
    mat_int16_t endian = 0, version;
    mat_t *mat = NULL;
    size_t err;
    time_t t;

#if defined(_WIN32) && defined(_MSC_VER)
    wchar_t *wname = utf82u(matname);
    if ( NULL != wname ) {
        fp = _wfopen(wname, L"w+b");
        free(wname);
    }
#else
    fp = fopen(matname, "w+b");
#endif
    if ( !fp )
        return NULL;

    mat = (mat_t *)malloc(sizeof(*mat));
    if ( mat == NULL ) {
        fclose(fp);
        return NULL;
    }

    mat->fp = NULL;
    mat->header = NULL;
    mat->subsys_offset = NULL;
    mat->filename = NULL;
    mat->version = 0;
    mat->byteswap = 0;
    mat->mode = 0;
    mat->bof = 128;
    mat->next_index = 0;
    mat->num_datasets = 0;
#if HAVE_HDF5
    mat->refs_id = -1;
#endif
    mat->dir = NULL;

    t = time(NULL);
    mat->fp = fp;
    mat->filename = Mat_strdup(matname);
    mat->mode = MAT_ACC_RDWR;
    mat->byteswap = 0;
    mat->header = (char *)malloc(128 * sizeof(char));
    mat->subsys_offset = (char *)malloc(8 * sizeof(char));
    memset(mat->header, ' ', 128);
    if ( hdr_str == NULL ) {
        err = mat_snprintf(mat->header, 116,
                           "MATLAB 5.0 MAT-file, Platform: %s, "
                           "Created by: libmatio v%d.%d.%d on %s",
                           MATIO_PLATFORM, MATIO_MAJOR_VERSION, MATIO_MINOR_VERSION,
                           MATIO_RELEASE_LEVEL, ctime(&t));
    } else {
        err = mat_snprintf(mat->header, 116, "%s", hdr_str);
    }
    if ( err >= 116 )
        mat->header[115] = '\0'; /* Just to make sure it's NULL terminated */
    memset(mat->subsys_offset, ' ', 8);
    mat->version = (int)0x0100;
    endian = 0x4d49;

    version = 0x0100;

    fwrite(mat->header, 1, 116, (FILE *)mat->fp);
    fwrite(mat->subsys_offset, 1, 8, (FILE *)mat->fp);
    fwrite(&version, 2, 1, (FILE *)mat->fp);
    fwrite(&endian, 2, 1, (FILE *)mat->fp);

    return mat;
}

/** @if mat_devman
 * @brief Writes @c data as character data
 *
 * This function uses the knowledge that the data is part of a character class
 * to avoid some pitfalls with Matlab listed below.
 *   @li Matlab character data cannot be unsigned 8-bit integers, it needs at
 *       least unsigned 16-bit integers
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data character data to write
 * @param N Number of elements to write
 * @param data_type character data type (enum matio_types)
 * @return number of bytes written
 * @endif
 */
static size_t
WriteCharData(mat_t *mat, void *data, size_t N, enum matio_types data_type)
{
    mat_uint32_t nBytes = 0;
    size_t nbytes, i;
    size_t byteswritten = 0;
    const mat_uint8_t pad1 = 0;
    int err;

    switch ( data_type ) {
        case MAT_T_UINT8:
        case MAT_T_UINT16:
        case MAT_T_UTF8:
        case MAT_T_UTF16: {
            data_type = MAT_T_UINT8 == data_type ? MAT_T_UTF8 : data_type;
            err = Mul(&nbytes, N, Mat_SizeOf(data_type));
            if ( err ) {
                return 0;
            }
            nBytes = (mat_uint32_t)nbytes;
            fwrite(&data_type, 4, 1, (FILE *)mat->fp);
            fwrite(&nBytes, 4, 1, (FILE *)mat->fp);
            if ( NULL != data && N > 0 )
                fwrite(data, 1, nbytes, (FILE *)mat->fp);
            if ( nBytes % 8 ) {
                for ( i = nbytes % 8; i < 8; i++ )
                    fwrite(&pad1, 1, 1, (FILE *)mat->fp);
            }
            break;
        }
        case MAT_T_INT8: {
            mat_int8_t *ptr;
            mat_uint16_t c;

            /* Matlab can't read MAT_C_CHAR as int8, needs uint16 */
            data_type = MAT_T_UINT16;
            err = Mul(&nbytes, N, Mat_SizeOf(data_type));
            if ( err ) {
                return 0;
            }
            nBytes = (mat_uint32_t)nbytes;
            fwrite(&data_type, 4, 1, (FILE *)mat->fp);
            fwrite(&nBytes, 4, 1, (FILE *)mat->fp);
            ptr = (mat_int8_t *)data;
            if ( NULL == data )
                break;
            for ( i = 0; i < N; i++ ) {
                c = (mat_uint16_t) * (char *)ptr;
                fwrite(&c, 2, 1, (FILE *)mat->fp);
                ptr++;
            }
            if ( nbytes % 8 )
                for ( i = nbytes % 8; i < 8; i++ )
                    fwrite(&pad1, 1, 1, (FILE *)mat->fp);
            break;
        }
        case MAT_T_UNKNOWN: {
            /* Sometimes empty char data will have MAT_T_UNKNOWN, so just write
             * a data tag
             */
            data_type = MAT_T_UINT16;
            err = Mul(&nbytes, N, Mat_SizeOf(data_type));
            if ( err ) {
                return 0;
            }
            nBytes = (mat_uint32_t)nbytes;
            fwrite(&data_type, 4, 1, (FILE *)mat->fp);
            fwrite(&nBytes, 4, 1, (FILE *)mat->fp);
            break;
        }
        default:
            nbytes = 0;
            break;
    }
    byteswritten += nbytes;
    return byteswritten;
}

#if HAVE_ZLIB
/** @brief Writes @c data as compressed character data
 *
 * This function uses the knowledge that the data is part of a character class
 * to avoid some pitfalls with Matlab listed below.
 *   @li Matlab character data cannot be unsigned 8-bit integers, it needs at
 *       least unsigned 16-bit integers
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z pointer to the zlib compression stream
 * @param data character data to write
 * @param N Number of elements to write
 * @param data_type character data type (enum matio_types)
 * @return number of bytes written
 */
static size_t
WriteCompressedCharData(mat_t *mat, z_streamp z, void *data, size_t N, enum matio_types data_type)
{
    size_t data_size, byteswritten = 0, nbytes;
    mat_uint32_t data_tag[2];
    int buf_size = 1024;
    int err;
    mat_uint8_t buf[1024], pad[8] = {0, 0, 0, 0, 0, 0, 0, 0};

    if ( mat == NULL || mat->fp == NULL )
        return 0;

    if ( data_type == MAT_T_UNKNOWN ) {
        data_size = Mat_SizeOf(MAT_T_UINT16);
    } else {
        data_size = Mat_SizeOf(data_type);
    }

    err = Mul(&nbytes, N, data_size);
    if ( err ) {
        return byteswritten;
    }

    switch ( data_type ) {
        case MAT_T_UINT8:
        case MAT_T_UINT16:
        case MAT_T_UTF8:
        case MAT_T_UTF16:
            data_tag[0] = MAT_T_UINT8 == data_type ? MAT_T_UTF8 : data_type;
            data_tag[1] = (mat_uint32_t)nbytes;
            z->next_in = ZLIB_BYTE_PTR(data_tag);
            z->avail_in = 8;
            do {
                z->next_out = buf;
                z->avail_out = buf_size;
                deflate(z, Z_NO_FLUSH);
                byteswritten += fwrite(buf, 1, buf_size - z->avail_out, (FILE *)mat->fp);
            } while ( z->avail_out == 0 );

            /* exit early if this is an empty data */
            if ( NULL == data || N < 1 )
                break;

            z->next_in = (Bytef *)data;
            z->avail_in = (mat_uint32_t)nbytes;
            do {
                z->next_out = buf;
                z->avail_out = buf_size;
                deflate(z, Z_NO_FLUSH);
                byteswritten += fwrite(buf, 1, buf_size - z->avail_out, (FILE *)mat->fp);
            } while ( z->avail_out == 0 );
            /* Add/Compress padding to pad to 8-byte boundary */
            if ( nbytes % 8 ) {
                z->next_in = pad;
                z->avail_in = 8 - (nbytes % 8);
                do {
                    z->next_out = buf;
                    z->avail_out = buf_size;
                    deflate(z, Z_NO_FLUSH);
                    byteswritten += fwrite(buf, 1, buf_size - z->avail_out, (FILE *)mat->fp);
                } while ( z->avail_out == 0 );
            }
            break;
        case MAT_T_UNKNOWN:
            /* Sometimes empty char data will have MAT_T_UNKNOWN, so just write a data tag */
            data_tag[0] = MAT_T_UINT16;
            data_tag[1] = (mat_uint32_t)nbytes;
            z->next_in = ZLIB_BYTE_PTR(data_tag);
            z->avail_in = 8;
            do {
                z->next_out = buf;
                z->avail_out = buf_size;
                deflate(z, Z_NO_FLUSH);
                byteswritten += fwrite(buf, 1, buf_size - z->avail_out, (FILE *)mat->fp);
            } while ( z->avail_out == 0 );
            break;
        default:
            break;
    }

    return byteswritten;
}
#endif

/** @brief Writes the data buffer to the file
 *
 * @param mat MAT file pointer
 * @param data pointer to the data to write
 * @param N number of elements to write
 * @param data_type data type of the data
 * @return number of bytes written
 */
static int
WriteData(mat_t *mat, void *data, size_t N, enum matio_types data_type)
{
    int nBytes = 0, data_size;

    if ( mat == NULL || mat->fp == NULL )
        return 0;

    data_size = Mat_SizeOf(data_type);
    nBytes = N * data_size;
    fwrite(&data_type, 4, 1, (FILE *)mat->fp);
    fwrite(&nBytes, 4, 1, (FILE *)mat->fp);

    if ( data != NULL && N > 0 )
        fwrite(data, data_size, N, (FILE *)mat->fp);

    return nBytes;
}

#if HAVE_ZLIB
/* Compresses the data buffer and writes it to the file */
static size_t
WriteCompressedData(mat_t *mat, z_streamp z, void *data, int N, enum matio_types data_type)
{
    int nBytes = 0, data_size, data_tag[2], byteswritten = 0;
    int buf_size = 1024;
    mat_uint8_t buf[1024], pad[8] = {0, 0, 0, 0, 0, 0, 0, 0};

    if ( mat == NULL || mat->fp == NULL )
        return 0;

    data_size = Mat_SizeOf(data_type);
    data_tag[0] = data_type;
    data_tag[1] = data_size * N;
    z->next_in = ZLIB_BYTE_PTR(data_tag);
    z->avail_in = 8;
    do {
        z->next_out = buf;
        z->avail_out = buf_size;
        deflate(z, Z_NO_FLUSH);
        byteswritten += fwrite(buf, 1, buf_size - z->avail_out, (FILE *)mat->fp);
    } while ( z->avail_out == 0 );

    /* exit early if this is an empty data */
    if ( NULL == data || N < 1 )
        return byteswritten;

    z->next_in = (Bytef *)data;
    z->avail_in = N * data_size;
    do {
        z->next_out = buf;
        z->avail_out = buf_size;
        deflate(z, Z_NO_FLUSH);
        byteswritten += fwrite(buf, 1, buf_size - z->avail_out, (FILE *)mat->fp);
    } while ( z->avail_out == 0 );
    /* Add/Compress padding to pad to 8-byte boundary */
    if ( N * data_size % 8 ) {
        z->next_in = pad;
        z->avail_in = 8 - (N * data_size % 8);
        do {
            z->next_out = buf;
            z->avail_out = buf_size;
            deflate(z, Z_NO_FLUSH);
            byteswritten += fwrite(buf, 1, buf_size - z->avail_out, (FILE *)mat->fp);
        } while ( z->avail_out == 0 );
    }
    nBytes = byteswritten;
    return nBytes;
}
#endif

/** @brief Reads the next cell of the cell array in @c matvar
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar MAT variable pointer
 * @return Number of bytes read
 */
static size_t
ReadNextCell(mat_t *mat, matvar_t *matvar)
{
    size_t bytesread = 0, i;
    int err;
    matvar_t **cells = NULL;
    size_t nelems = 1;

    err = Mat_MulDims(matvar, &nelems);
    if ( err ) {
        Mat_Critical("Integer multiplication overflow");
        return bytesread;
    }
    matvar->data_size = sizeof(matvar_t *);
    err = Mul(&matvar->nbytes, nelems, matvar->data_size);
    if ( err ) {
        Mat_Critical("Integer multiplication overflow");
        return bytesread;
    }

    matvar->data = calloc(nelems, matvar->data_size);
    if ( NULL == matvar->data ) {
        if ( NULL != matvar->name )
            Mat_Critical("Couldn't allocate memory for %s->data", matvar->name);
        return bytesread;
    }
    cells = (matvar_t **)matvar->data;

    if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
#if HAVE_ZLIB
        mat_uint32_t uncomp_buf[16];
        mat_uint32_t nBytes;
        mat_uint32_t array_flags;

        memset(&uncomp_buf, 0, sizeof(uncomp_buf));
        for ( i = 0; i < nelems; i++ ) {
            cells[i] = Mat_VarCalloc();
            if ( NULL == cells[i] ) {
                Mat_Critical("Couldn't allocate memory for cell %zu", i);
                continue;
            }

            /* Read variable tag for cell */
            uncomp_buf[0] = 0;
            uncomp_buf[1] = 0;
            err = Inflate(mat, matvar->internal->z, uncomp_buf, 8, &bytesread);
            if ( err ) {
                Mat_VarFree(cells[i]);
                cells[i] = NULL;
                break;
            }
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf + 1);
            }
            nBytes = uncomp_buf[1];
            if ( 0 == nBytes ) {
                /* Empty cell: Memory optimization */
                free(cells[i]->internal);
                cells[i]->internal = NULL;
                continue;
            } else if ( uncomp_buf[0] != MAT_T_MATRIX ) {
                Mat_VarFree(cells[i]);
                cells[i] = NULL;
                Mat_Critical("cells[%zu], Uncompressed type not MAT_T_MATRIX", i);
                break;
            }
            cells[i]->compression = MAT_COMPRESSION_ZLIB;
            err = Inflate(mat, matvar->internal->z, uncomp_buf, 16, &bytesread);
            if ( err ) {
                Mat_VarFree(cells[i]);
                cells[i] = NULL;
                break;
            }
            nBytes -= 16;
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf + 1);
                (void)Mat_uint32Swap(uncomp_buf + 2);
                (void)Mat_uint32Swap(uncomp_buf + 3);
            }
            /* Array Flags */
            if ( uncomp_buf[0] == MAT_T_UINT32 ) {
                array_flags = uncomp_buf[2];
                cells[i]->class_type = CLASS_FROM_ARRAY_FLAGS(array_flags);
                cells[i]->isComplex = (array_flags & MAT_F_COMPLEX);
                cells[i]->isGlobal = (array_flags & MAT_F_GLOBAL);
                cells[i]->isLogical = (array_flags & MAT_F_LOGICAL);
                if ( cells[i]->class_type == MAT_C_SPARSE ) {
                    /* Need to find a more appropriate place to store nzmax */
                    cells[i]->nbytes = uncomp_buf[3];
                }
            } else {
                Mat_Critical("Expected MAT_T_UINT32 for array tags, got %d", uncomp_buf[0]);
                InflateSkip(mat, matvar->internal->z, nBytes, &bytesread);
            }
            if ( cells[i]->class_type != MAT_C_OPAQUE ) {
                mat_uint32_t *dims = NULL;
                int do_clean = 0;
                err = InflateRankDims(mat, matvar->internal->z, uncomp_buf, sizeof(uncomp_buf),
                                      &dims, &bytesread);
                if ( NULL == dims ) {
                    dims = uncomp_buf + 2;
                } else {
                    do_clean = 1;
                }
                if ( err ) {
                    if ( do_clean ) {
                        free(dims);
                    }
                    Mat_VarFree(cells[i]);
                    cells[i] = NULL;
                    break;
                }
                nBytes -= 8;
                if ( mat->byteswap ) {
                    (void)Mat_uint32Swap(uncomp_buf);
                    (void)Mat_uint32Swap(uncomp_buf + 1);
                }
                /* Rank and Dimension */
                if ( uncomp_buf[0] == MAT_T_INT32 ) {
                    int j;
                    size_t size;
                    cells[i]->rank = uncomp_buf[1];
                    nBytes -= cells[i]->rank;
                    cells[i]->rank /= 4;
                    if ( 0 == do_clean && cells[i]->rank > 13 ) {
                        int rank = cells[i]->rank;
                        cells[i]->rank = 0;
                        Mat_Critical("%d is not a valid rank", rank);
                        continue;
                    }
                    err = Mul(&size, cells[i]->rank, sizeof(*cells[i]->dims));
                    if ( err ) {
                        if ( do_clean ) {
                            free(dims);
                        }
                        Mat_VarFree(cells[i]);
                        cells[i] = NULL;
                        Mat_Critical("Integer multiplication overflow");
                        continue;
                    }
                    cells[i]->dims = (size_t *)malloc(size);
                    if ( mat->byteswap ) {
                        for ( j = 0; j < cells[i]->rank; j++ )
                            cells[i]->dims[j] = Mat_uint32Swap(dims + j);
                    } else {
                        for ( j = 0; j < cells[i]->rank; j++ )
                            cells[i]->dims[j] = dims[j];
                    }
                    if ( cells[i]->rank % 2 != 0 )
                        nBytes -= 4;
                }
                if ( do_clean ) {
                    free(dims);
                }
                /* Variable name tag */
                err = Inflate(mat, matvar->internal->z, uncomp_buf, 8, &bytesread);
                if ( err ) {
                    Mat_VarFree(cells[i]);
                    cells[i] = NULL;
                    break;
                }
                nBytes -= 8;
                if ( mat->byteswap ) {
                    (void)Mat_uint32Swap(uncomp_buf);
                    (void)Mat_uint32Swap(uncomp_buf + 1);
                }
                /* Handle cell elements written with a variable name */
                if ( uncomp_buf[1] > 0 ) {
                    /* Name of variable */
                    if ( uncomp_buf[0] == MAT_T_INT8 ) { /* Name not in tag */
                        mat_uint32_t len = uncomp_buf[1];

                        if ( len % 8 > 0 ) {
                            if ( len < UINT32_MAX - 8 + (len % 8) )
                                len = len + 8 - (len % 8);
                            else {
                                Mat_VarFree(cells[i]);
                                cells[i] = NULL;
                                break;
                            }
                        }
                        cells[i]->name = (char *)malloc(len + 1);
                        nBytes -= len;
                        if ( NULL != cells[i]->name ) {
                            /* Variable name */
                            err =
                                Inflate(mat, matvar->internal->z, cells[i]->name, len, &bytesread);
                            if ( err ) {
                                Mat_VarFree(cells[i]);
                                cells[i] = NULL;
                                break;
                            }
                            cells[i]->name[len] = '\0';
                        }
                    } else {
                        mat_uint32_t len = (uncomp_buf[0] & 0xffff0000) >> 16;
                        if ( ((uncomp_buf[0] & 0x0000ffff) == MAT_T_INT8) && len > 0 && len <= 4 ) {
                            /* Name packed in tag */
                            cells[i]->name = (char *)malloc(len + 1);
                            if ( NULL != cells[i]->name ) {
                                memcpy(cells[i]->name, uncomp_buf + 1, len);
                                cells[i]->name[len] = '\0';
                            }
                        }
                    }
                }
                cells[i]->internal->z = (z_streamp)calloc(1, sizeof(z_stream));
                if ( cells[i]->internal->z != NULL ) {
                    err = inflateCopy(cells[i]->internal->z, matvar->internal->z);
                    if ( err == Z_OK ) {
                        cells[i]->internal->datapos = ftell((FILE *)mat->fp);
                        if ( cells[i]->internal->datapos != -1L ) {
                            cells[i]->internal->datapos -= matvar->internal->z->avail_in;
                            if ( cells[i]->class_type == MAT_C_STRUCT )
                                bytesread += ReadNextStructField(mat, cells[i]);
                            else if ( cells[i]->class_type == MAT_C_CELL )
                                bytesread += ReadNextCell(mat, cells[i]);
                            else if ( nBytes <= (1 << MAX_WBITS) ) {
                                /* Memory optimization: Read data if less in size
                                   than the zlib inflate state (approximately) */
                                err = Mat_VarRead5(mat, cells[i]);
                                cells[i]->internal->data = cells[i]->data;
                                cells[i]->data = NULL;
                            }
                            (void)fseek((FILE *)mat->fp, cells[i]->internal->datapos, SEEK_SET);
                        } else {
                            Mat_Critical("Couldn't determine file position");
                        }
                        if ( cells[i]->internal->data != NULL ||
                             cells[i]->class_type == MAT_C_STRUCT ||
                             cells[i]->class_type == MAT_C_CELL ) {
                            /* Memory optimization: Free inflate state */
                            inflateEnd(cells[i]->internal->z);
                            free(cells[i]->internal->z);
                            cells[i]->internal->z = NULL;
                        }
                    } else {
                        Mat_Critical("inflateCopy returned error %s", zError(err));
                    }
                } else {
                    Mat_Critical("Couldn't allocate memory");
                }
            }
            InflateSkip(mat, matvar->internal->z, nBytes, &bytesread);
        }
#else
        Mat_Critical("Not compiled with zlib support");
#endif

    } else {
        mat_uint32_t buf[6] = {0, 0, 0, 0, 0, 0};
        mat_uint32_t nBytes;
        mat_uint32_t array_flags;

        for ( i = 0; i < nelems; i++ ) {
            size_t nbytes = 0;
            mat_uint32_t name_len;
            cells[i] = Mat_VarCalloc();
            if ( NULL == cells[i] ) {
                Mat_Critical("Couldn't allocate memory for cell %zu", i);
                continue;
            }

            /* Read variable tag for cell */
            err = Read(buf, 4, 2, (FILE *)mat->fp, &nbytes);

            /* Empty cells at the end of a file may cause an EOF */
            if ( 0 == err && 0 == nbytes )
                continue;
            bytesread += nbytes;
            if ( err ) {
                Mat_VarFree(cells[i]);
                cells[i] = NULL;
                break;
            }
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(buf);
                (void)Mat_uint32Swap(buf + 1);
            }
            nBytes = buf[1];
            if ( 0 == nBytes ) {
                /* Empty cell: Memory optimization */
                free(cells[i]->internal);
                cells[i]->internal = NULL;
                continue;
            } else if ( buf[0] != MAT_T_MATRIX ) {
                Mat_VarFree(cells[i]);
                cells[i] = NULL;
                Mat_Critical("cells[%zu] not MAT_T_MATRIX, fpos = %ld", i, ftell((FILE *)mat->fp));
                break;
            }

            /* Read array flags and the dimensions tag */
            err = Read(buf, 4, 6, (FILE *)mat->fp, &bytesread);
            if ( err ) {
                Mat_VarFree(cells[i]);
                cells[i] = NULL;
                break;
            }
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(buf);
                (void)Mat_uint32Swap(buf + 1);
                (void)Mat_uint32Swap(buf + 2);
                (void)Mat_uint32Swap(buf + 3);
                (void)Mat_uint32Swap(buf + 4);
                (void)Mat_uint32Swap(buf + 5);
            }
            nBytes -= 24;
            /* Array flags */
            if ( buf[0] == MAT_T_UINT32 ) {
                array_flags = buf[2];
                cells[i]->class_type = CLASS_FROM_ARRAY_FLAGS(array_flags);
                cells[i]->isComplex = (array_flags & MAT_F_COMPLEX);
                cells[i]->isGlobal = (array_flags & MAT_F_GLOBAL);
                cells[i]->isLogical = (array_flags & MAT_F_LOGICAL);
                if ( cells[i]->class_type == MAT_C_SPARSE ) {
                    /* Need to find a more appropriate place to store nzmax */
                    cells[i]->nbytes = buf[3];
                }
            }
            /* Rank and dimension */
            nbytes = 0;
            err = ReadRankDims(mat, cells[i], (enum matio_types)buf[4], buf[5], &nbytes);
            bytesread += nbytes;
            nBytes -= nbytes;
            if ( err ) {
                Mat_VarFree(cells[i]);
                cells[i] = NULL;
                break;
            }
            /* Variable name tag */
            if ( 0 != Read(buf, 1, 8, (FILE *)mat->fp, &bytesread) ) {
                Mat_VarFree(cells[i]);
                cells[i] = NULL;
                break;
            }
            nBytes -= 8;
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(buf);
                (void)Mat_uint32Swap(buf + 1);
            }
            name_len = 0;
            if ( buf[1] > 0 ) {
                /* Name of variable */
                if ( buf[0] == MAT_T_INT8 ) { /* Name not in tag */
                    name_len = buf[1];
                    if ( name_len % 8 > 0 ) {
                        if ( name_len < UINT32_MAX - 8 + (name_len % 8) ) {
                            name_len = name_len + 8 - (name_len % 8);
                        } else {
                            Mat_VarFree(cells[i]);
                            cells[i] = NULL;
                            break;
                        }
                    }
                    nBytes -= name_len;
                    (void)fseek((FILE *)mat->fp, name_len, SEEK_CUR);
                }
            }
            cells[i]->internal->datapos = ftell((FILE *)mat->fp);
            if ( cells[i]->internal->datapos != -1L ) {
                if ( cells[i]->class_type == MAT_C_STRUCT )
                    bytesread += ReadNextStructField(mat, cells[i]);
                if ( cells[i]->class_type == MAT_C_CELL )
                    bytesread += ReadNextCell(mat, cells[i]);
                (void)fseek((FILE *)mat->fp, cells[i]->internal->datapos + nBytes, SEEK_SET);
            } else {
                Mat_Critical("Couldn't determine file position");
            }
        }
    }

    return bytesread;
}

/** @brief Reads the next struct field of the structure in @c matvar
 *
 * Reads the next struct fields (fieldname length,names,data headers for all
 * the fields
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar MAT variable pointer
 * @return Number of bytes read
 */
static size_t
ReadNextStructField(mat_t *mat, matvar_t *matvar)
{
    mat_uint32_t fieldname_size;
    int err;
    size_t bytesread = 0, nfields, i;
    matvar_t **fields = NULL;
    size_t nelems = 1, nelems_x_nfields;

    err = Mat_MulDims(matvar, &nelems);
    if ( err ) {
        Mat_Critical("Integer multiplication overflow");
        return bytesread;
    }
    if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
#if HAVE_ZLIB
        mat_uint32_t uncomp_buf[16];
        mat_uint32_t array_flags, len;

        memset(&uncomp_buf, 0, sizeof(uncomp_buf));
        /* Field name length */
        err = Inflate(mat, matvar->internal->z, uncomp_buf, 8, &bytesread);
        if ( err ) {
            return bytesread;
        }
        if ( mat->byteswap ) {
            (void)Mat_uint32Swap(uncomp_buf);
            (void)Mat_uint32Swap(uncomp_buf + 1);
        }
        if ( (uncomp_buf[0] & 0x0000ffff) == MAT_T_INT32 && uncomp_buf[1] > 0 ) {
            fieldname_size = uncomp_buf[1];
        } else {
            Mat_Critical("Error getting fieldname size");
            return bytesread;
        }

        /* Field name tag */
        err = Inflate(mat, matvar->internal->z, uncomp_buf, 8, &bytesread);
        if ( err ) {
            return bytesread;
        }
        if ( mat->byteswap )
            (void)Mat_uint32Swap(uncomp_buf);
        /* Name of field */
        if ( uncomp_buf[0] == MAT_T_INT8 ) { /* Name not in tag */
            if ( mat->byteswap )
                len = Mat_uint32Swap(uncomp_buf + 1);
            else
                len = uncomp_buf[1];
            nfields = len / fieldname_size;
            if ( nfields * fieldname_size % 8 != 0 )
                i = 8 - (nfields * fieldname_size % 8);
            else
                i = 0;
            if ( nfields ) {
                char *ptr = (char *)malloc(nfields * fieldname_size + i);
                if ( NULL != ptr ) {
                    err = Inflate(mat, matvar->internal->z, ptr,
                                  (unsigned int)(nfields * fieldname_size + i), &bytesread);
                    if ( 0 == err ) {
                        SetFieldNames(matvar, ptr, nfields, fieldname_size);
                    } else {
                        matvar->internal->num_fields = nfields;
                        matvar->internal->fieldnames = NULL;
                    }
                    free(ptr);
                }
            } else {
                matvar->internal->num_fields = 0;
                matvar->internal->fieldnames = NULL;
            }
        } else {
            len = (uncomp_buf[0] & 0xffff0000) >> 16;
            if ( ((uncomp_buf[0] & 0x0000ffff) == MAT_T_INT8) && len > 0 && len <= 4 ) {
                /* Name packed in tag */
                nfields = len / fieldname_size;
                if ( nfields ) {
                    SetFieldNames(matvar, (char *)(uncomp_buf + 1), nfields, fieldname_size);
                } else {
                    matvar->internal->num_fields = 0;
                    matvar->internal->fieldnames = NULL;
                }
            } else {
                nfields = 0;
            }
        }

        matvar->data_size = sizeof(matvar_t *);
        err = Mul(&nelems_x_nfields, nelems, nfields);
        if ( err ) {
            Mat_Critical("Integer multiplication overflow");
            return bytesread;
        }
        err = Mul(&matvar->nbytes, nelems_x_nfields, matvar->data_size);
        if ( err ) {
            Mat_Critical("Integer multiplication overflow");
            return bytesread;
        }
        if ( !matvar->nbytes )
            return bytesread;

        matvar->data = calloc(nelems_x_nfields, matvar->data_size);
        if ( NULL == matvar->data ) {
            Mat_Critical("Couldn't allocate memory for the data");
            return bytesread;
        }

        fields = (matvar_t **)matvar->data;
        for ( i = 0; i < nelems; i++ ) {
            size_t k;
            for ( k = 0; k < nfields; k++ ) {
                fields[i * nfields + k] = Mat_VarCalloc();
            }
        }
        if ( NULL != matvar->internal->fieldnames ) {
            for ( i = 0; i < nelems; i++ ) {
                size_t k;
                for ( k = 0; k < nfields; k++ ) {
                    if ( NULL != matvar->internal->fieldnames[k] ) {
                        fields[i * nfields + k]->name = Mat_strdup(matvar->internal->fieldnames[k]);
                    }
                }
            }
        }

        for ( i = 0; i < nelems_x_nfields; i++ ) {
            mat_uint32_t nBytes;
            /* Read variable tag for struct field */
            err = Inflate(mat, matvar->internal->z, uncomp_buf, 8, &bytesread);
            if ( err ) {
                Mat_VarFree(fields[i]);
                fields[i] = NULL;
                break;
            }
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf + 1);
            }
            nBytes = uncomp_buf[1];
            if ( uncomp_buf[0] != MAT_T_MATRIX ) {
                Mat_VarFree(fields[i]);
                fields[i] = NULL;
                Mat_Critical("fields[%zu], Uncompressed type not MAT_T_MATRIX", i);
                break;
            } else if ( 0 == nBytes ) {
                /* Empty field: Memory optimization */
                free(fields[i]->internal);
                fields[i]->internal = NULL;
                continue;
            }
            fields[i]->compression = MAT_COMPRESSION_ZLIB;
            err = Inflate(mat, matvar->internal->z, uncomp_buf, 16, &bytesread);
            if ( err ) {
                Mat_VarFree(fields[i]);
                fields[i] = NULL;
                break;
            }
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf + 1);
                (void)Mat_uint32Swap(uncomp_buf + 2);
                (void)Mat_uint32Swap(uncomp_buf + 3);
            }
            nBytes -= 16;
            /* Array flags */
            if ( uncomp_buf[0] == MAT_T_UINT32 ) {
                array_flags = uncomp_buf[2];
                fields[i]->class_type = CLASS_FROM_ARRAY_FLAGS(array_flags);
                fields[i]->isComplex = (array_flags & MAT_F_COMPLEX);
                fields[i]->isGlobal = (array_flags & MAT_F_GLOBAL);
                fields[i]->isLogical = (array_flags & MAT_F_LOGICAL);
                if ( fields[i]->class_type == MAT_C_SPARSE ) {
                    /* Need to find a more appropriate place to store nzmax */
                    fields[i]->nbytes = uncomp_buf[3];
                }
            } else {
                Mat_Critical("Expected MAT_T_UINT32 for array tags, got %d", uncomp_buf[0]);
                InflateSkip(mat, matvar->internal->z, nBytes, &bytesread);
            }
            if ( fields[i]->class_type != MAT_C_OPAQUE ) {
                mat_uint32_t *dims = NULL;
                int do_clean = 0;
                err = InflateRankDims(mat, matvar->internal->z, uncomp_buf, sizeof(uncomp_buf),
                                      &dims, &bytesread);
                if ( NULL == dims ) {
                    dims = uncomp_buf + 2;
                } else {
                    do_clean = 1;
                }
                if ( err ) {
                    if ( do_clean ) {
                        free(dims);
                    }
                    Mat_VarFree(fields[i]);
                    fields[i] = NULL;
                    break;
                }
                nBytes -= 8;
                if ( mat->byteswap ) {
                    (void)Mat_uint32Swap(uncomp_buf);
                    (void)Mat_uint32Swap(uncomp_buf + 1);
                }
                /* Rank and dimension */
                if ( uncomp_buf[0] == MAT_T_INT32 ) {
                    int j;
                    size_t size;
                    fields[i]->rank = uncomp_buf[1];
                    nBytes -= fields[i]->rank;
                    fields[i]->rank /= 4;
                    if ( 0 == do_clean && fields[i]->rank > 13 ) {
                        int rank = fields[i]->rank;
                        fields[i]->rank = 0;
                        Mat_Critical("%d is not a valid rank", rank);
                        continue;
                    }
                    err = Mul(&size, fields[i]->rank, sizeof(*fields[i]->dims));
                    if ( err ) {
                        if ( do_clean ) {
                            free(dims);
                        }
                        Mat_VarFree(fields[i]);
                        fields[i] = NULL;
                        Mat_Critical("Integer multiplication overflow");
                        continue;
                    }
                    fields[i]->dims = (size_t *)malloc(size);
                    if ( mat->byteswap ) {
                        for ( j = 0; j < fields[i]->rank; j++ )
                            fields[i]->dims[j] = Mat_uint32Swap(dims + j);
                    } else {
                        for ( j = 0; j < fields[i]->rank; j++ )
                            fields[i]->dims[j] = dims[j];
                    }
                    if ( fields[i]->rank % 2 != 0 )
                        nBytes -= 4;
                }
                if ( do_clean ) {
                    free(dims);
                }
                /* Variable name tag */
                err = Inflate(mat, matvar->internal->z, uncomp_buf, 8, &bytesread);
                if ( err ) {
                    Mat_VarFree(fields[i]);
                    fields[i] = NULL;
                    break;
                }
                nBytes -= 8;
                fields[i]->internal->z = (z_streamp)calloc(1, sizeof(z_stream));
                if ( fields[i]->internal->z != NULL ) {
                    err = inflateCopy(fields[i]->internal->z, matvar->internal->z);
                    if ( err == Z_OK ) {
                        fields[i]->internal->datapos = ftell((FILE *)mat->fp);
                        if ( fields[i]->internal->datapos != -1L ) {
                            fields[i]->internal->datapos -= matvar->internal->z->avail_in;
                            if ( fields[i]->class_type == MAT_C_STRUCT )
                                bytesread += ReadNextStructField(mat, fields[i]);
                            else if ( fields[i]->class_type == MAT_C_CELL )
                                bytesread += ReadNextCell(mat, fields[i]);
                            else if ( nBytes <= (1 << MAX_WBITS) ) {
                                /* Memory optimization: Read data if less in size
                                   than the zlib inflate state (approximately) */
                                err = Mat_VarRead5(mat, fields[i]);
                                fields[i]->internal->data = fields[i]->data;
                                fields[i]->data = NULL;
                            }
                            (void)fseek((FILE *)mat->fp, fields[i]->internal->datapos, SEEK_SET);
                        } else {
                            Mat_Critical("Couldn't determine file position");
                        }
                        if ( fields[i]->internal->data != NULL ||
                             fields[i]->class_type == MAT_C_STRUCT ||
                             fields[i]->class_type == MAT_C_CELL ) {
                            /* Memory optimization: Free inflate state */
                            inflateEnd(fields[i]->internal->z);
                            free(fields[i]->internal->z);
                            fields[i]->internal->z = NULL;
                        }
                    } else {
                        Mat_Critical("inflateCopy returned error %s", zError(err));
                    }
                } else {
                    Mat_Critical("Couldn't allocate memory");
                }
            }
            InflateSkip(mat, matvar->internal->z, nBytes, &bytesread);
        }
#else
        Mat_Critical("Not compiled with zlib support");
#endif
    } else {
        mat_uint32_t buf[6] = {0, 0, 0, 0, 0, 0};
        mat_uint32_t array_flags, len;

        err = Read(buf, 4, 2, (FILE *)mat->fp, &bytesread);
        if ( err ) {
            return bytesread;
        }
        if ( mat->byteswap ) {
            (void)Mat_uint32Swap(buf);
            (void)Mat_uint32Swap(buf + 1);
        }
        if ( (buf[0] & 0x0000ffff) == MAT_T_INT32 && buf[1] > 0 ) {
            fieldname_size = buf[1];
        } else {
            Mat_Critical("Error getting fieldname size");
            return bytesread;
        }

        /* Field name tag */
        err = Read(buf, 4, 2, (FILE *)mat->fp, &bytesread);
        if ( err ) {
            return bytesread;
        }
        if ( mat->byteswap )
            (void)Mat_uint32Swap(buf);
        /* Name of field */
        if ( buf[0] == MAT_T_INT8 ) { /* Name not in tag */
            if ( mat->byteswap )
                len = Mat_uint32Swap(buf + 1);
            else
                len = buf[1];
            nfields = len / fieldname_size;
            if ( nfields ) {
                char *ptr = (char *)malloc(nfields * fieldname_size);
                if ( NULL != ptr ) {
                    err = Read(ptr, 1, nfields * fieldname_size, (FILE *)mat->fp, &bytesread);
                    if ( 0 == err ) {
                        SetFieldNames(matvar, ptr, nfields, fieldname_size);
                    } else {
                        matvar->internal->num_fields = nfields;
                        matvar->internal->fieldnames = NULL;
                    }
                    free(ptr);
                }
                if ( (nfields * fieldname_size) % 8 ) {
                    (void)fseek((FILE *)mat->fp, 8 - ((nfields * fieldname_size) % 8), SEEK_CUR);
                    bytesread += 8 - ((nfields * fieldname_size) % 8);
                }
            } else {
                matvar->internal->num_fields = 0;
                matvar->internal->fieldnames = NULL;
            }
        } else {
            len = (buf[0] & 0xffff0000) >> 16;
            if ( ((buf[0] & 0x0000ffff) == MAT_T_INT8) && len > 0 && len <= 4 ) {
                /* Name packed in tag */
                nfields = len / fieldname_size;
                if ( nfields ) {
                    SetFieldNames(matvar, (char *)(buf + 1), nfields, fieldname_size);
                } else {
                    matvar->internal->num_fields = 0;
                    matvar->internal->fieldnames = NULL;
                }
            } else {
                nfields = 0;
            }
        }

        matvar->data_size = sizeof(matvar_t *);
        err = Mul(&nelems_x_nfields, nelems, nfields);
        if ( err ) {
            Mat_Critical("Integer multiplication overflow");
            return bytesread;
        }
        err = Mul(&matvar->nbytes, nelems_x_nfields, matvar->data_size);
        if ( err ) {
            Mat_Critical("Integer multiplication overflow");
            return bytesread;
        }
        if ( !matvar->nbytes )
            return bytesread;

        matvar->data = calloc(nelems_x_nfields, matvar->data_size);
        if ( NULL == matvar->data ) {
            Mat_Critical("Couldn't allocate memory for the data");
            return bytesread;
        }

        fields = (matvar_t **)matvar->data;
        for ( i = 0; i < nelems_x_nfields; i++ ) {
            mat_uint32_t nBytes;

            fields[i] = Mat_VarCalloc();
            if ( NULL == fields[i] ) {
                Mat_Critical("Couldn't allocate memory for field %zu", i);
                continue;
            }

            /* Read variable tag for struct field */
            err = Read(buf, 4, 2, (FILE *)mat->fp, &bytesread);
            if ( err ) {
                Mat_VarFree(fields[i]);
                fields[i] = NULL;
                break;
            }
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(buf);
                (void)Mat_uint32Swap(buf + 1);
            }
            nBytes = buf[1];
            if ( buf[0] != MAT_T_MATRIX ) {
                Mat_VarFree(fields[i]);
                fields[i] = NULL;
                Mat_Critical("fields[%zu] not MAT_T_MATRIX, fpos = %ld", i, ftell((FILE *)mat->fp));
                break;
            } else if ( 0 == nBytes ) {
                /* Empty field: Memory optimization */
                free(fields[i]->internal);
                fields[i]->internal = NULL;
                continue;
            }

            /* Read array flags and the dimensions tag */
            err = Read(buf, 4, 6, (FILE *)mat->fp, &bytesread);
            if ( err ) {
                Mat_VarFree(fields[i]);
                fields[i] = NULL;
                break;
            }
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(buf);
                (void)Mat_uint32Swap(buf + 1);
                (void)Mat_uint32Swap(buf + 2);
                (void)Mat_uint32Swap(buf + 3);
                (void)Mat_uint32Swap(buf + 4);
                (void)Mat_uint32Swap(buf + 5);
            }
            nBytes -= 24;
            /* Array flags */
            if ( buf[0] == MAT_T_UINT32 ) {
                array_flags = buf[2];
                fields[i]->class_type = CLASS_FROM_ARRAY_FLAGS(array_flags);
                fields[i]->isComplex = (array_flags & MAT_F_COMPLEX);
                fields[i]->isGlobal = (array_flags & MAT_F_GLOBAL);
                fields[i]->isLogical = (array_flags & MAT_F_LOGICAL);
                if ( fields[i]->class_type == MAT_C_SPARSE ) {
                    /* Need to find a more appropriate place to store nzmax */
                    fields[i]->nbytes = buf[3];
                }
            }
            /* Rank and dimension */
            {
                size_t nbytes = 0;
                err = ReadRankDims(mat, fields[i], (enum matio_types)buf[4], buf[5], &nbytes);
                bytesread += nbytes;
                nBytes -= nbytes;
                if ( err ) {
                    Mat_VarFree(fields[i]);
                    fields[i] = NULL;
                    break;
                }
            }
            /* Variable name tag */
            err = Read(buf, 1, 8, (FILE *)mat->fp, &bytesread);
            if ( err ) {
                Mat_VarFree(fields[i]);
                fields[i] = NULL;
                break;
            }
            nBytes -= 8;
            fields[i]->internal->datapos = ftell((FILE *)mat->fp);
            if ( fields[i]->internal->datapos != -1L ) {
                if ( fields[i]->class_type == MAT_C_STRUCT )
                    bytesread += ReadNextStructField(mat, fields[i]);
                else if ( fields[i]->class_type == MAT_C_CELL )
                    bytesread += ReadNextCell(mat, fields[i]);
                (void)fseek((FILE *)mat->fp, fields[i]->internal->datapos + nBytes, SEEK_SET);
            } else {
                Mat_Critical("Couldn't determine file position");
            }
        }

        if ( NULL != matvar->internal->fieldnames ) {
            for ( i = 0; i < nelems; i++ ) {
                size_t k;
                for ( k = 0; k < nfields; k++ ) {
                    if ( NULL != matvar->internal->fieldnames[k] &&
                         NULL != fields[i * nfields + k] ) {
                        fields[i * nfields + k]->name = Mat_strdup(matvar->internal->fieldnames[k]);
                    }
                }
            }
        }
    }

    return bytesread;
}

/** @brief Reads the function handle data of the function handle in @c matvar
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar MAT variable pointer
 * @return Number of bytes read
 */
static size_t
ReadNextFunctionHandle(mat_t *mat, matvar_t *matvar)
{
    int err;
    size_t nelems = 1;

    err = Mat_MulDims(matvar, &nelems);
    matvar->data_size = sizeof(matvar_t *);
    err |= Mul(&matvar->nbytes, nelems, matvar->data_size);
    if ( err )
        return 0;

    matvar->data = malloc(matvar->nbytes);
    if ( matvar->data != NULL ) {
        size_t i;
        matvar_t **functions = (matvar_t **)matvar->data;
        for ( i = 0; i < nelems; i++ ) {
            functions[i] = Mat_VarReadNextInfo(mat);
            err = NULL == functions[i];
            if ( err )
                break;
        }
        if ( err ) {
            free(matvar->data);
            matvar->data = NULL;
            matvar->data_size = 0;
            matvar->nbytes = 0;
        }
    } else {
        matvar->data_size = 0;
        matvar->nbytes = 0;
    }

    return 0;
}

/** @brief Reads the rank and dimensions in @c matvar
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar MAT variable pointer
 * @param data_type data type of dimension array
 * @param nbytes len of dimension array in bytes
 * @param[out] read_bytes Read bytes
 * @retval 0 on success
 */
static int
ReadRankDims(mat_t *mat, matvar_t *matvar, enum matio_types data_type, mat_uint32_t nbytes,
             size_t *read_bytes)
{
    int err = MATIO_E_NO_ERROR;
    /* Rank and dimension */
    if ( data_type == MAT_T_INT32 ) {
        matvar->rank = nbytes / sizeof(mat_uint32_t);
        matvar->dims = (size_t *)malloc(matvar->rank * sizeof(*matvar->dims));
        if ( NULL != matvar->dims ) {
            int i;
            mat_uint32_t buf;

            for ( i = 0; i < matvar->rank; i++ ) {
                err = Read(&buf, sizeof(mat_uint32_t), 1, (FILE *)mat->fp, read_bytes);
                if ( MATIO_E_NO_ERROR == err ) {
                    if ( mat->byteswap ) {
                        matvar->dims[i] = Mat_uint32Swap(&buf);
                    } else {
                        matvar->dims[i] = buf;
                    }
                } else {
                    free(matvar->dims);
                    matvar->dims = NULL;
                    matvar->rank = 0;
                    return err;
                }
            }

            if ( matvar->rank % 2 != 0 ) {
                err = Read(&buf, sizeof(mat_uint32_t), 1, (FILE *)mat->fp, read_bytes);
                if ( err ) {
                    free(matvar->dims);
                    matvar->dims = NULL;
                    matvar->rank = 0;
                    return err;
                }
            }
        } else {
            matvar->rank = 0;
            err = MATIO_E_OUT_OF_MEMORY;
            Mat_Critical("Error allocating memory for dims");
        }
    }
    return err;
}

/** @brief Writes the header and data for a given type
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @retval 0 on success
 */
static int
WriteType(mat_t *mat, matvar_t *matvar)
{
    int err;
    const mat_uint8_t pad1 = 0;
    int nBytes, j;
    size_t nelems = 1;

    err = Mat_MulDims(matvar, &nelems);
    if ( err )
        return err;

    switch ( matvar->class_type ) {
        case MAT_C_DOUBLE:
        case MAT_C_SINGLE:
        case MAT_C_INT64:
        case MAT_C_UINT64:
        case MAT_C_INT32:
        case MAT_C_UINT32:
        case MAT_C_INT16:
        case MAT_C_UINT16:
        case MAT_C_INT8:
        case MAT_C_UINT8: {
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t *)matvar->data;

                if ( NULL == matvar->data )
                    complex_data = &null_complex_data;

                nBytes = WriteData(mat, complex_data->Re, nelems, matvar->data_type);
                if ( nBytes % 8 )
                    for ( j = nBytes % 8; j < 8; j++ )
                        fwrite(&pad1, 1, 1, (FILE *)mat->fp);
                nBytes = WriteData(mat, complex_data->Im, nelems, matvar->data_type);
                if ( nBytes % 8 )
                    for ( j = nBytes % 8; j < 8; j++ )
                        fwrite(&pad1, 1, 1, (FILE *)mat->fp);
            } else {
                nBytes = WriteData(mat, matvar->data, nelems, matvar->data_type);
                if ( nBytes % 8 )
                    for ( j = nBytes % 8; j < 8; j++ )
                        fwrite(&pad1, 1, 1, (FILE *)mat->fp);
            }
            break;
        }
        case MAT_C_CHAR:
            if ( matvar->data_type == MAT_T_UTF8 ) {
                nelems = matvar->nbytes;
            }
            nBytes = WriteCharData(mat, matvar->data, nelems, matvar->data_type);
            break;
        case MAT_C_CELL: {
            size_t i;
            matvar_t **cells = (matvar_t **)matvar->data;

            /* Check for an empty cell array */
            if ( matvar->nbytes == 0 || matvar->data_size == 0 || matvar->data == NULL )
                break;
            nelems = matvar->nbytes / matvar->data_size;
            for ( i = 0; i < nelems; i++ )
                WriteCellArrayField(mat, cells[i]);
            break;
        }
        case MAT_C_STRUCT: {
            const mat_uint32_t array_name_type = MAT_T_INT8;
            const mat_uint32_t fieldname_type = MAT_T_INT32;
            const mat_uint32_t fieldname_data_size = 4;
            char *padzero;
            mat_uint32_t fieldname_size;
            size_t maxlen = 0, nfields, i, nelems_x_nfields;
            matvar_t **fields = (matvar_t **)matvar->data;
            mat_uint32_t fieldname;

            /* nelems*matvar->data_size can be zero when saving a struct that
             * contains an empty struct in one of its fields
             * (e.g. x.y = struct('z', {})). If it's zero, we would divide
             * by zero.
             */
            nfields = matvar->internal->num_fields;
            /* Check for a structure with no fields */
            if ( nfields < 1 ) {
                fieldname = (fieldname_data_size << 16) | fieldname_type;
                fwrite(&fieldname, 4, 1, (FILE *)mat->fp);
                fieldname_size = 1;
                fwrite(&fieldname_size, 4, 1, (FILE *)mat->fp);
                fwrite(&array_name_type, 4, 1, (FILE *)mat->fp);
                nBytes = 0;
                fwrite(&nBytes, 4, 1, (FILE *)mat->fp);
                break;
            }

            for ( i = 0; i < nfields; i++ ) {
                size_t len = strlen(matvar->internal->fieldnames[i]);
                if ( len > maxlen )
                    maxlen = len;
            }
            maxlen++;
            fieldname_size = maxlen;
            while ( nfields * fieldname_size % 8 != 0 )
                fieldname_size++;
            fieldname = (fieldname_data_size << 16) | fieldname_type;
            fwrite(&fieldname, 4, 1, (FILE *)mat->fp);
            fwrite(&fieldname_size, 4, 1, (FILE *)mat->fp);
            fwrite(&array_name_type, 4, 1, (FILE *)mat->fp);
            nBytes = nfields * fieldname_size;
            fwrite(&nBytes, 4, 1, (FILE *)mat->fp);
            padzero = (char *)calloc(fieldname_size, 1);
            for ( i = 0; i < nfields; i++ ) {
                size_t len = strlen(matvar->internal->fieldnames[i]);
                fwrite(matvar->internal->fieldnames[i], 1, len, (FILE *)mat->fp);
                fwrite(padzero, 1, fieldname_size - len, (FILE *)mat->fp);
            }
            free(padzero);
            err = Mul(&nelems_x_nfields, nelems, nfields);
            if ( err )
                break;
            for ( i = 0; i < nelems_x_nfields; i++ )
                WriteStructField(mat, fields[i]);
            break;
        }
        case MAT_C_SPARSE: {
            mat_sparse_t *sparse = (mat_sparse_t *)matvar->data;

            nBytes = WriteData(mat, sparse->ir, sparse->nir, MAT_T_UINT32);
            if ( nBytes % 8 )
                for ( j = nBytes % 8; j < 8; j++ )
                    fwrite(&pad1, 1, 1, (FILE *)mat->fp);
            nBytes = WriteData(mat, sparse->jc, sparse->njc, MAT_T_UINT32);
            if ( nBytes % 8 )
                for ( j = nBytes % 8; j < 8; j++ )
                    fwrite(&pad1, 1, 1, (FILE *)mat->fp);
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t *)sparse->data;
                nBytes = WriteData(mat, complex_data->Re, sparse->ndata, matvar->data_type);
                if ( nBytes % 8 )
                    for ( j = nBytes % 8; j < 8; j++ )
                        fwrite(&pad1, 1, 1, (FILE *)mat->fp);
                nBytes = WriteData(mat, complex_data->Im, sparse->ndata, matvar->data_type);
                if ( nBytes % 8 )
                    for ( j = nBytes % 8; j < 8; j++ )
                        fwrite(&pad1, 1, 1, (FILE *)mat->fp);
            } else {
                nBytes = WriteData(mat, sparse->data, sparse->ndata, matvar->data_type);
                if ( nBytes % 8 )
                    for ( j = nBytes % 8; j < 8; j++ )
                        fwrite(&pad1, 1, 1, (FILE *)mat->fp);
            }
        }
        case MAT_C_FUNCTION:
        case MAT_C_OBJECT:
        case MAT_C_EMPTY:
        case MAT_C_OPAQUE:
            break;
        default:
            err = MATIO_E_OUTPUT_BAD_DATA;
            break;
    }

    return err;
}

/** @brief Writes the header and data for an element of a cell array
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @retval 0 on success
 */
static int
WriteCellArrayField(mat_t *mat, matvar_t *matvar)
{
    mat_uint32_t array_flags, nzmax = 0;
    int array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int array_flags_size = 8, matrix_type = MAT_T_MATRIX;
    const mat_uint32_t pad4 = 0;
    const mat_uint8_t pad1 = 0;
    int nBytes, i;
    long start = 0, end = 0;

    if ( matvar == NULL || mat == NULL )
        return MATIO_E_BAD_ARGUMENT;

    fwrite(&matrix_type, 4, 1, (FILE *)mat->fp);
    fwrite(&pad4, 4, 1, (FILE *)mat->fp);
    if ( MAT_C_EMPTY == matvar->class_type ) {
        /* exit early if this is an empty data */
        return MATIO_E_NO_ERROR;
    }
    start = ftell((FILE *)mat->fp);

    /* Array Flags */
    array_flags = matvar->class_type & CLASS_TYPE_MASK;
    if ( matvar->isComplex )
        array_flags |= MAT_F_COMPLEX;
    if ( matvar->isGlobal )
        array_flags |= MAT_F_GLOBAL;
    if ( matvar->isLogical )
        array_flags |= MAT_F_LOGICAL;
    if ( matvar->class_type == MAT_C_SPARSE )
        nzmax = ((mat_sparse_t *)matvar->data)->nzmax;

    if ( mat->byteswap )
        array_flags = Mat_int32Swap((mat_int32_t *)&array_flags);
    fwrite(&array_flags_type, 4, 1, (FILE *)mat->fp);
    fwrite(&array_flags_size, 4, 1, (FILE *)mat->fp);
    fwrite(&array_flags, 4, 1, (FILE *)mat->fp);
    fwrite(&nzmax, 4, 1, (FILE *)mat->fp);
    /* Rank and Dimension */
    nBytes = matvar->rank * 4;
    fwrite(&dims_array_type, 4, 1, (FILE *)mat->fp);
    fwrite(&nBytes, 4, 1, (FILE *)mat->fp);
    for ( i = 0; i < matvar->rank; i++ ) {
        mat_int32_t dim;
        dim = matvar->dims[i];
        fwrite(&dim, 4, 1, (FILE *)mat->fp);
    }
    if ( matvar->rank % 2 != 0 )
        fwrite(&pad4, 4, 1, (FILE *)mat->fp);
    /* Name of variable */
    if ( !matvar->name ) {
        const mat_uint32_t array_name_type = MAT_T_INT8;
        fwrite(&array_name_type, 4, 1, (FILE *)mat->fp);
        fwrite(&pad4, 4, 1, (FILE *)mat->fp);
    } else if ( strlen(matvar->name) <= 4 ) {
        mat_uint32_t array_name_type = MAT_T_INT8;
        const mat_uint32_t array_name_len = (mat_uint32_t)strlen(matvar->name);
        array_name_type |= array_name_len << 16;
        fwrite(&array_name_type, 4, 1, (FILE *)mat->fp);
        fwrite(matvar->name, 1, array_name_len, (FILE *)mat->fp);
        for ( i = array_name_len; i < 4; i++ )
            fwrite(&pad1, 1, 1, (FILE *)mat->fp);
    } else {
        const mat_uint32_t array_name_type = MAT_T_INT8;
        const mat_uint32_t array_name_len = (mat_uint32_t)strlen(matvar->name);
        fwrite(&array_name_type, 4, 1, (FILE *)mat->fp);
        fwrite(&array_name_len, 4, 1, (FILE *)mat->fp);
        fwrite(matvar->name, 1, array_name_len, (FILE *)mat->fp);
        if ( array_name_len % 8 )
            for ( i = array_name_len % 8; i < 8; i++ )
                fwrite(&pad1, 1, 1, (FILE *)mat->fp);
    }

    WriteType(mat, matvar);
    end = ftell((FILE *)mat->fp);
    if ( start != -1L && end != -1L ) {
        nBytes = (int)(end - start);
        (void)fseek((FILE *)mat->fp, (long)-(nBytes + 4), SEEK_CUR);
        fwrite(&nBytes, 4, 1, (FILE *)mat->fp);
        (void)fseek((FILE *)mat->fp, end, SEEK_SET);
    } else {
        Mat_Critical("Couldn't determine file position");
    }

    return MATIO_E_NO_ERROR;
}

#if HAVE_ZLIB
/** @brief Writes the header and data for a given class type
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @return number of bytes written to the MAT file
 */
static size_t
WriteCompressedTypeArrayFlags(mat_t *mat, matvar_t *matvar, z_streamp z)
{
    mat_uint32_t array_flags;
    const mat_uint32_t array_name_type = MAT_T_INT8;
    int array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int array_flags_size = 8;
    int nBytes, i, nzmax = 0;

    mat_uint32_t comp_buf[512];
    mat_uint32_t uncomp_buf[512];
    int buf_size = 512;
    size_t byteswritten = 0;

    if ( MAT_C_EMPTY == matvar->class_type ) {
        /* exit early if this is an empty data */
        return byteswritten;
    }

    memset(&uncomp_buf, 0, sizeof(uncomp_buf));
    /* Array Flags */
    array_flags = matvar->class_type & CLASS_TYPE_MASK;
    if ( matvar->isComplex )
        array_flags |= MAT_F_COMPLEX;
    if ( matvar->isGlobal )
        array_flags |= MAT_F_GLOBAL;
    if ( matvar->isLogical )
        array_flags |= MAT_F_LOGICAL;
    if ( matvar->class_type == MAT_C_SPARSE )
        nzmax = ((mat_sparse_t *)matvar->data)->nzmax;
    uncomp_buf[0] = array_flags_type;
    uncomp_buf[1] = array_flags_size;
    uncomp_buf[2] = array_flags;
    uncomp_buf[3] = nzmax;
    /* Rank and Dimension */
    nBytes = matvar->rank * 4;
    uncomp_buf[4] = dims_array_type;
    uncomp_buf[5] = nBytes;
    for ( i = 0; i < matvar->rank; i++ ) {
        mat_int32_t dim;
        dim = matvar->dims[i];
        uncomp_buf[6 + i] = dim;
    }
    if ( matvar->rank % 2 != 0 ) {
        const mat_uint32_t pad4 = 0;
        uncomp_buf[6 + i] = pad4;
        i++;
    }

    z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = (6 + i) * sizeof(*uncomp_buf);
    do {
        z->next_out = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size * sizeof(*comp_buf);
        deflate(z, Z_NO_FLUSH);
        byteswritten +=
            fwrite(comp_buf, 1, buf_size * sizeof(*comp_buf) - z->avail_out, (FILE *)mat->fp);
    } while ( z->avail_out == 0 );
    /* Name of variable */
    uncomp_buf[0] = array_name_type;
    uncomp_buf[1] = 0;
    z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = 8;
    do {
        z->next_out = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size * sizeof(*comp_buf);
        deflate(z, Z_NO_FLUSH);
        byteswritten +=
            fwrite(comp_buf, 1, buf_size * sizeof(*comp_buf) - z->avail_out, (FILE *)mat->fp);
    } while ( z->avail_out == 0 );

    matvar->internal->datapos = ftell((FILE *)mat->fp);
    if ( matvar->internal->datapos == -1L ) {
        Mat_Critical("Couldn't determine file position");
    }

    byteswritten += WriteCompressedType(mat, matvar, z);
    return byteswritten;
}

/** @brief Writes the header and data for a given class type
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @return number of bytes written to the MAT file
 */
static size_t
WriteCompressedType(mat_t *mat, matvar_t *matvar, z_streamp z)
{
    int err;
    mat_uint32_t comp_buf[512];
    mat_uint32_t uncomp_buf[512];
    size_t byteswritten = 0, nelems = 1;

    if ( MAT_C_EMPTY == matvar->class_type ) {
        /* exit early if this is an empty data */
        return byteswritten;
    }

    memset(&uncomp_buf, 0, sizeof(uncomp_buf));
    err = Mat_MulDims(matvar, &nelems);
    if ( err ) {
        Mat_Critical("Integer multiplication overflow");
        return byteswritten;
    }

    switch ( matvar->class_type ) {
        case MAT_C_DOUBLE:
        case MAT_C_SINGLE:
        case MAT_C_INT64:
        case MAT_C_UINT64:
        case MAT_C_INT32:
        case MAT_C_UINT32:
        case MAT_C_INT16:
        case MAT_C_UINT16:
        case MAT_C_INT8:
        case MAT_C_UINT8: {
            /* WriteCompressedData makes sure uncompressed data is aligned
             * on an 8-byte boundary */
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t *)matvar->data;

                if ( NULL == matvar->data )
                    complex_data = &null_complex_data;

                byteswritten +=
                    WriteCompressedData(mat, z, complex_data->Re, nelems, matvar->data_type);
                byteswritten +=
                    WriteCompressedData(mat, z, complex_data->Im, nelems, matvar->data_type);
            } else {
                byteswritten +=
                    WriteCompressedData(mat, z, matvar->data, nelems, matvar->data_type);
            }
            break;
        }
        case MAT_C_CHAR: {
            if ( matvar->data_type == MAT_T_UTF8 ) {
                nelems = matvar->nbytes;
            }
            byteswritten +=
                WriteCompressedCharData(mat, z, matvar->data, nelems, matvar->data_type);
            break;
        }
        case MAT_C_CELL: {
            size_t i;
            matvar_t **cells = (matvar_t **)matvar->data;

            /* Check for an empty cell array */
            if ( matvar->nbytes == 0 || matvar->data_size == 0 || matvar->data == NULL )
                break;
            nelems = matvar->nbytes / matvar->data_size;
            for ( i = 0; i < nelems; i++ )
                WriteCompressedCellArrayField(mat, cells[i], z);
            break;
        }
        case MAT_C_STRUCT: {
            int buf_size = 512;
            const mat_uint32_t fieldname_type = MAT_T_INT32;
            const mat_uint32_t fieldname_data_size = 4;
            unsigned char *padzero;
            int fieldname_size;
            size_t maxlen = 0, nfields, i, nelems_x_nfields;
            const mat_uint32_t array_name_type = MAT_T_INT8;
            matvar_t **fields = (matvar_t **)matvar->data;

            nfields = matvar->internal->num_fields;
            /* Check for a structure with no fields */
            if ( nfields < 1 ) {
                fieldname_size = 1;
                uncomp_buf[0] = (fieldname_data_size << 16) | fieldname_type;
                uncomp_buf[1] = fieldname_size;
                uncomp_buf[2] = array_name_type;
                uncomp_buf[3] = 0;
                z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
                z->avail_in = 16;
                do {
                    z->next_out = ZLIB_BYTE_PTR(comp_buf);
                    z->avail_out = buf_size * sizeof(*comp_buf);
                    deflate(z, Z_NO_FLUSH);
                    byteswritten += fwrite(comp_buf, 1, buf_size * sizeof(*comp_buf) - z->avail_out,
                                           (FILE *)mat->fp);
                } while ( z->avail_out == 0 );
                break;
            }

            for ( i = 0; i < nfields; i++ ) {
                size_t len = strlen(matvar->internal->fieldnames[i]);
                if ( len > maxlen )
                    maxlen = len;
            }
            maxlen++;
            fieldname_size = maxlen;
            while ( nfields * fieldname_size % 8 != 0 )
                fieldname_size++;
            uncomp_buf[0] = (fieldname_data_size << 16) | fieldname_type;
            uncomp_buf[1] = fieldname_size;
            uncomp_buf[2] = array_name_type;
            uncomp_buf[3] = nfields * fieldname_size;

            padzero = (unsigned char *)calloc(fieldname_size, 1);
            z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
            z->avail_in = 16;
            do {
                z->next_out = ZLIB_BYTE_PTR(comp_buf);
                z->avail_out = buf_size * sizeof(*comp_buf);
                deflate(z, Z_NO_FLUSH);
                byteswritten += fwrite(comp_buf, 1, buf_size * sizeof(*comp_buf) - z->avail_out,
                                       (FILE *)mat->fp);
            } while ( z->avail_out == 0 );
            for ( i = 0; i < nfields; i++ ) {
                size_t len = strlen(matvar->internal->fieldnames[i]);
                memset(padzero, '\0', fieldname_size);
                memcpy(padzero, matvar->internal->fieldnames[i], len);
                z->next_in = ZLIB_BYTE_PTR(padzero);
                z->avail_in = fieldname_size;
                do {
                    z->next_out = ZLIB_BYTE_PTR(comp_buf);
                    z->avail_out = buf_size * sizeof(*comp_buf);
                    deflate(z, Z_NO_FLUSH);
                    byteswritten += fwrite(comp_buf, 1, buf_size * sizeof(*comp_buf) - z->avail_out,
                                           (FILE *)mat->fp);
                } while ( z->avail_out == 0 );
            }
            free(padzero);
            err = Mul(&nelems_x_nfields, nelems, nfields);
            if ( err ) {
                Mat_Critical("Integer multiplication overflow");
                return byteswritten;
            }
            for ( i = 0; i < nelems_x_nfields; i++ )
                byteswritten += WriteCompressedStructField(mat, fields[i], z);
            break;
        }
        case MAT_C_SPARSE: {
            mat_sparse_t *sparse = (mat_sparse_t *)matvar->data;

            byteswritten += WriteCompressedData(mat, z, sparse->ir, sparse->nir, MAT_T_UINT32);
            byteswritten += WriteCompressedData(mat, z, sparse->jc, sparse->njc, MAT_T_UINT32);
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t *)sparse->data;
                byteswritten +=
                    WriteCompressedData(mat, z, complex_data->Re, sparse->ndata, matvar->data_type);
                byteswritten +=
                    WriteCompressedData(mat, z, complex_data->Im, sparse->ndata, matvar->data_type);
            } else {
                byteswritten +=
                    WriteCompressedData(mat, z, sparse->data, sparse->ndata, matvar->data_type);
            }
            break;
        }
        case MAT_C_FUNCTION:
        case MAT_C_OBJECT:
        case MAT_C_EMPTY:
        case MAT_C_OPAQUE:
            break;
    }

    return byteswritten;
}

/** @brief Writes the header and data for a field of a compressed cell array
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @return number of bytes written to the MAT file
 */
static size_t
WriteCompressedCellArrayField(mat_t *mat, matvar_t *matvar, z_streamp z)
{
    mat_uint32_t comp_buf[512];
    mat_uint32_t uncomp_buf[512];
    int buf_size = 512;
    size_t byteswritten = 0, field_buf_size;

    if ( NULL == matvar || NULL == mat || NULL == z )
        return 0;

    memset(&uncomp_buf, 0, sizeof(uncomp_buf));
    uncomp_buf[0] = MAT_T_MATRIX;
    if ( MAT_C_EMPTY != matvar->class_type ) {
        int err = GetCellArrayFieldBufSize(matvar, &field_buf_size);
        if ( err || field_buf_size > UINT32_MAX )
            return 0;

        uncomp_buf[1] = field_buf_size;
    } else {
        uncomp_buf[1] = 0;
    }
    z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = 8;
    do {
        z->next_out = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size * sizeof(*comp_buf);
        deflate(z, Z_NO_FLUSH);
        byteswritten +=
            fwrite(comp_buf, 1, buf_size * sizeof(*comp_buf) - z->avail_out, (FILE *)mat->fp);
    } while ( z->avail_out == 0 );

    byteswritten += WriteCompressedTypeArrayFlags(mat, matvar, z);
    return byteswritten;
}
#endif

/** @brief Writes the header and data for a field of a struct array
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @retval 0 on success
 */
static int
WriteStructField(mat_t *mat, matvar_t *matvar)
{
    mat_uint32_t array_flags;
    const mat_uint32_t array_name_type = MAT_T_INT8;
    int array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int array_flags_size = 8, matrix_type = MAT_T_MATRIX;
    const mat_uint32_t pad4 = 0;
    int nBytes, i, nzmax = 0;
    long start = 0, end = 0;

    if ( mat == NULL )
        return MATIO_E_BAD_ARGUMENT;

    if ( NULL == matvar ) {
        size_t dims[2] = {0, 0};
        Mat_WriteEmptyVariable5(mat, NULL, 2, dims);
        return MATIO_E_NO_ERROR;
    }

    fwrite(&matrix_type, 4, 1, (FILE *)mat->fp);
    fwrite(&pad4, 4, 1, (FILE *)mat->fp);
    if ( MAT_C_EMPTY == matvar->class_type ) {
        /* exit early if this is an empty data */
        return MATIO_E_NO_ERROR;
    }
    start = ftell((FILE *)mat->fp);

    /* Array Flags */
    array_flags = matvar->class_type & CLASS_TYPE_MASK;
    if ( matvar->isComplex )
        array_flags |= MAT_F_COMPLEX;
    if ( matvar->isGlobal )
        array_flags |= MAT_F_GLOBAL;
    if ( matvar->isLogical )
        array_flags |= MAT_F_LOGICAL;
    if ( matvar->class_type == MAT_C_SPARSE )
        nzmax = ((mat_sparse_t *)matvar->data)->nzmax;

    if ( mat->byteswap )
        array_flags = Mat_int32Swap((mat_int32_t *)&array_flags);
    fwrite(&array_flags_type, 4, 1, (FILE *)mat->fp);
    fwrite(&array_flags_size, 4, 1, (FILE *)mat->fp);
    fwrite(&array_flags, 4, 1, (FILE *)mat->fp);
    fwrite(&nzmax, 4, 1, (FILE *)mat->fp);
    /* Rank and Dimension */
    nBytes = matvar->rank * 4;
    fwrite(&dims_array_type, 4, 1, (FILE *)mat->fp);
    fwrite(&nBytes, 4, 1, (FILE *)mat->fp);
    for ( i = 0; i < matvar->rank; i++ ) {
        mat_int32_t dim;
        dim = matvar->dims[i];
        fwrite(&dim, 4, 1, (FILE *)mat->fp);
    }
    if ( matvar->rank % 2 != 0 )
        fwrite(&pad4, 4, 1, (FILE *)mat->fp);

    /* Name of variable */
    fwrite(&array_name_type, 4, 1, (FILE *)mat->fp);
    fwrite(&pad4, 4, 1, (FILE *)mat->fp);

    WriteType(mat, matvar);
    end = ftell((FILE *)mat->fp);
    if ( start != -1L && end != -1L ) {
        nBytes = (int)(end - start);
        (void)fseek((FILE *)mat->fp, (long)-(nBytes + 4), SEEK_CUR);
        fwrite(&nBytes, 4, 1, (FILE *)mat->fp);
        (void)fseek((FILE *)mat->fp, end, SEEK_SET);
    } else {
        Mat_Critical("Couldn't determine file position");
    }

    return MATIO_E_NO_ERROR;
}

#if HAVE_ZLIB
/** @brief Writes the header and data for a field of a compressed struct array
 *
 * @ingroup mat_internal
 * @fixme Currently does not work for cell arrays or sparse data
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @return number of bytes written to the MAT file
 */
static size_t
WriteCompressedStructField(mat_t *mat, matvar_t *matvar, z_streamp z)
{
    mat_uint32_t comp_buf[512];
    mat_uint32_t uncomp_buf[512];
    int buf_size = 512;
    size_t byteswritten = 0, field_buf_size;

    if ( NULL == mat || NULL == z )
        return 0;

    if ( NULL == matvar ) {
        size_t dims[2] = {0, 0};
        byteswritten = Mat_WriteCompressedEmptyVariable5(mat, NULL, 2, dims, z);
        return byteswritten;
    }

    memset(&uncomp_buf, 0, sizeof(uncomp_buf));
    uncomp_buf[0] = MAT_T_MATRIX;
    if ( MAT_C_EMPTY != matvar->class_type ) {
        int err = GetStructFieldBufSize(matvar, &field_buf_size);
        if ( err || field_buf_size > UINT32_MAX )
            return 0;
        uncomp_buf[1] = field_buf_size;
    } else {
        uncomp_buf[1] = 0;
    }
    z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = 8;
    do {
        z->next_out = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size * sizeof(*comp_buf);
        deflate(z, Z_NO_FLUSH);
        byteswritten +=
            fwrite(comp_buf, 1, buf_size * sizeof(*comp_buf) - z->avail_out, (FILE *)mat->fp);
    } while ( z->avail_out == 0 );

    byteswritten += WriteCompressedTypeArrayFlags(mat, matvar, z);
    return byteswritten;
}
#endif

static size_t
Mat_WriteEmptyVariable5(mat_t *mat, const char *name, int rank, size_t *dims)
{
    mat_uint32_t array_flags;
    mat_uint32_t array_name_type = MAT_T_INT8;
    const mat_uint32_t matrix_type = MAT_T_MATRIX;
    int array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int array_flags_size = 8, nBytes, i;
    const mat_uint32_t pad4 = 0;
    const mat_uint8_t pad1 = 0;
    size_t byteswritten = 0;
    long start = 0, end = 0;

    fwrite(&matrix_type, 4, 1, (FILE *)mat->fp);
    fwrite(&pad4, 4, 1, (FILE *)mat->fp);
    start = ftell((FILE *)mat->fp);

    /* Array Flags */
    array_flags = MAT_C_DOUBLE;

    if ( mat->byteswap )
        array_flags = Mat_int32Swap((mat_int32_t *)&array_flags);
    byteswritten += fwrite(&array_flags_type, 4, 1, (FILE *)mat->fp);
    byteswritten += fwrite(&array_flags_size, 4, 1, (FILE *)mat->fp);
    byteswritten += fwrite(&array_flags, 4, 1, (FILE *)mat->fp);
    byteswritten += fwrite(&pad4, 4, 1, (FILE *)mat->fp);
    /* Rank and Dimension */
    nBytes = rank * 4;
    byteswritten += fwrite(&dims_array_type, 4, 1, (FILE *)mat->fp);
    byteswritten += fwrite(&nBytes, 4, 1, (FILE *)mat->fp);
    for ( i = 0; i < rank; i++ ) {
        mat_int32_t dim;
        dim = dims[i];
        byteswritten += fwrite(&dim, 4, 1, (FILE *)mat->fp);
    }
    if ( rank % 2 != 0 )
        byteswritten += fwrite(&pad4, 4, 1, (FILE *)mat->fp);

    if ( NULL == name ) {
        /* Name of variable */
        byteswritten += fwrite(&array_name_type, 4, 1, (FILE *)mat->fp);
        byteswritten += fwrite(&pad4, 4, 1, (FILE *)mat->fp);
    } else {
        mat_int32_t array_name_len = (mat_int32_t)strlen(name);
        /* Name of variable */
        if ( array_name_len <= 4 ) {
            array_name_type |= array_name_len << 16;
            byteswritten += fwrite(&array_name_type, 4, 1, (FILE *)mat->fp);
            byteswritten += fwrite(name, 1, array_name_len, (FILE *)mat->fp);
            for ( i = array_name_len; i < 4; i++ )
                byteswritten += fwrite(&pad1, 1, 1, (FILE *)mat->fp);
        } else {
            byteswritten += fwrite(&array_name_type, 4, 1, (FILE *)mat->fp);
            byteswritten += fwrite(&array_name_len, 4, 1, (FILE *)mat->fp);
            byteswritten += fwrite(name, 1, array_name_len, (FILE *)mat->fp);
            if ( array_name_len % 8 )
                for ( i = array_name_len % 8; i < 8; i++ )
                    byteswritten += fwrite(&pad1, 1, 1, (FILE *)mat->fp);
        }
    }

    nBytes = WriteData(mat, NULL, 0, MAT_T_DOUBLE);
    byteswritten += nBytes;
    if ( nBytes % 8 )
        for ( i = nBytes % 8; i < 8; i++ )
            byteswritten += fwrite(&pad1, 1, 1, (FILE *)mat->fp);

    end = ftell((FILE *)mat->fp);
    if ( start != -1L && end != -1L ) {
        nBytes = (int)(end - start);
        (void)fseek((FILE *)mat->fp, (long)-(nBytes + 4), SEEK_CUR);
        fwrite(&nBytes, 4, 1, (FILE *)mat->fp);
        (void)fseek((FILE *)mat->fp, end, SEEK_SET);
    } else {
        Mat_Critical("Couldn't determine file position");
    }

    return byteswritten;
}

#if HAVE_ZLIB
static size_t
Mat_WriteCompressedEmptyVariable5(mat_t *mat, const char *name, int rank, size_t *dims, z_streamp z)
{
    mat_uint32_t array_flags;
    int array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int array_flags_size = 8;
    int i, err;
    size_t nBytes, empty_matrix_max_buf_size;

    mat_uint32_t comp_buf[512];
    mat_uint32_t uncomp_buf[512];
    int buf_size = 512;
    size_t byteswritten = 0, buf_size_bytes;

    if ( NULL == mat || NULL == z )
        return byteswritten;

    buf_size_bytes = buf_size * sizeof(*comp_buf);

    /* Array Flags */
    array_flags = MAT_C_DOUBLE;

    memset(&uncomp_buf, 0, sizeof(uncomp_buf));
    uncomp_buf[0] = MAT_T_MATRIX;
    err = GetEmptyMatrixMaxBufSize(name, rank, &empty_matrix_max_buf_size);
    if ( err || empty_matrix_max_buf_size > UINT32_MAX )
        return byteswritten;
    uncomp_buf[1] = empty_matrix_max_buf_size;
    z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = 8;
    do {
        z->next_out = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size_bytes;
        deflate(z, Z_NO_FLUSH);
        byteswritten += fwrite(comp_buf, 1, buf_size_bytes - z->avail_out, (FILE *)mat->fp);
    } while ( z->avail_out == 0 );
    uncomp_buf[0] = array_flags_type;
    uncomp_buf[1] = array_flags_size;
    uncomp_buf[2] = array_flags;
    uncomp_buf[3] = 0;
    /* Rank and Dimension */
    nBytes = rank * 4;
    uncomp_buf[4] = dims_array_type;
    uncomp_buf[5] = nBytes;
    for ( i = 0; i < rank; i++ ) {
        mat_int32_t dim;
        dim = dims[i];
        uncomp_buf[6 + i] = dim;
    }
    if ( rank % 2 != 0 ) {
        const mat_uint32_t pad4 = 0;
        uncomp_buf[6 + i] = pad4;
        i++;
    }

    z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = (6 + i) * sizeof(*uncomp_buf);
    do {
        z->next_out = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size_bytes;
        deflate(z, Z_NO_FLUSH);
        byteswritten += fwrite(comp_buf, 1, buf_size_bytes - z->avail_out, (FILE *)mat->fp);
    } while ( z->avail_out == 0 );
    /* Name of variable */
    if ( NULL == name ) {
        const mat_uint32_t array_name_type = MAT_T_INT8;
        uncomp_buf[0] = array_name_type;
        uncomp_buf[1] = 0;
        z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
        z->avail_in = 8;
        do {
            z->next_out = ZLIB_BYTE_PTR(comp_buf);
            z->avail_out = buf_size_bytes;
            deflate(z, Z_NO_FLUSH);
            byteswritten += fwrite(comp_buf, 1, buf_size_bytes - z->avail_out, (FILE *)mat->fp);
        } while ( z->avail_out == 0 );
    } else if ( strlen(name) <= 4 ) {
        mat_uint32_t array_name_len = (mat_uint32_t)strlen(name);
        const mat_uint32_t array_name_type = MAT_T_INT8;

        memset(uncomp_buf, 0, 8);
        uncomp_buf[0] = (array_name_len << 16) | array_name_type;
        memcpy(uncomp_buf + 1, name, array_name_len);
        if ( array_name_len % 4 )
            array_name_len += 4 - (array_name_len % 4);

        z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
        z->avail_in = 8;
        do {
            z->next_out = ZLIB_BYTE_PTR(comp_buf);
            z->avail_out = buf_size_bytes;
            deflate(z, Z_NO_FLUSH);
            byteswritten += fwrite(comp_buf, 1, buf_size_bytes - z->avail_out, (FILE *)mat->fp);
        } while ( z->avail_out == 0 );
    } else {
        mat_uint32_t array_name_len = (mat_uint32_t)strlen(name);
        const mat_uint32_t array_name_type = MAT_T_INT8;

        memset(uncomp_buf, 0, buf_size * sizeof(*uncomp_buf));
        uncomp_buf[0] = array_name_type;
        uncomp_buf[1] = array_name_len;
        memcpy(uncomp_buf + 2, name, array_name_len);
        if ( array_name_len % 8 )
            array_name_len += 8 - (array_name_len % 8);
        z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
        z->avail_in = 8 + array_name_len;
        do {
            z->next_out = ZLIB_BYTE_PTR(comp_buf);
            z->avail_out = buf_size_bytes;
            deflate(z, Z_NO_FLUSH);
            byteswritten += fwrite(comp_buf, 1, buf_size_bytes - z->avail_out, (FILE *)mat->fp);
        } while ( z->avail_out == 0 );
    }

    byteswritten += WriteCompressedData(mat, z, NULL, 0, MAT_T_DOUBLE);
    return byteswritten;
}
#endif

/** @if mat_devman
 * @brief Reads a data element including tag and data
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar MAT variable pointer
 * @param data Pointer to store the data
 * @param N number of data elements allocated for the pointer
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarReadNumeric5(mat_t *mat, matvar_t *matvar, void *data, size_t N)
{
    int nBytes = 0, data_in_tag = 0, err = MATIO_E_NO_ERROR;
    enum matio_types packed_type = MAT_T_UNKNOWN;
    mat_uint32_t tag[2];

    if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
#if HAVE_ZLIB
        matvar->internal->z->avail_in = 0;
        err = Inflate(mat, matvar->internal->z, tag, 4, NULL);
        if ( err ) {
            return err;
        }
        if ( mat->byteswap )
            (void)Mat_uint32Swap(tag);

        packed_type = TYPE_FROM_TAG(tag[0]);
        if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
            data_in_tag = 1;
            nBytes = (tag[0] & 0xffff0000) >> 16;
        } else {
            data_in_tag = 0;
            err = Inflate(mat, matvar->internal->z, tag + 1, 4, NULL);
            if ( err ) {
                return err;
            }
            if ( mat->byteswap )
                (void)Mat_uint32Swap(tag + 1);
            nBytes = tag[1];
        }
#endif
    } else {
        err = Read(tag, 4, 1, (FILE *)mat->fp, NULL);
        if ( err ) {
            return err;
        }
        if ( mat->byteswap )
            (void)Mat_uint32Swap(tag);
        packed_type = TYPE_FROM_TAG(tag[0]);
        if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
            data_in_tag = 1;
            nBytes = (tag[0] & 0xffff0000) >> 16;
        } else {
            data_in_tag = 0;
            err = Read(tag + 1, 4, 1, (FILE *)mat->fp, NULL);
            if ( err ) {
                return err;
            }
            if ( mat->byteswap )
                (void)Mat_uint32Swap(tag + 1);
            nBytes = tag[1];
        }
    }
    if ( nBytes == 0 ) {
        matvar->nbytes = 0;
        return err;
    }

    if ( matvar->compression == MAT_COMPRESSION_NONE ) {
        switch ( matvar->class_type ) {
            case MAT_C_DOUBLE:
                nBytes = ReadDoubleData(mat, (double *)data, packed_type, N);
                break;
            case MAT_C_SINGLE:
                nBytes = ReadSingleData(mat, (float *)data, packed_type, N);
                break;
            case MAT_C_INT64:
#ifdef HAVE_MATIO_INT64_T
                nBytes = ReadInt64Data(mat, (mat_int64_t *)data, packed_type, N);
#endif
                break;
            case MAT_C_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                nBytes = ReadUInt64Data(mat, (mat_uint64_t *)data, packed_type, N);
#endif
                break;
            case MAT_C_INT32:
                nBytes = ReadInt32Data(mat, (mat_int32_t *)data, packed_type, N);
                break;
            case MAT_C_UINT32:
                nBytes = ReadUInt32Data(mat, (mat_uint32_t *)data, packed_type, N);
                break;
            case MAT_C_INT16:
                nBytes = ReadInt16Data(mat, (mat_int16_t *)data, packed_type, N);
                break;
            case MAT_C_UINT16:
                nBytes = ReadUInt16Data(mat, (mat_uint16_t *)data, packed_type, N);
                break;
            case MAT_C_INT8:
                nBytes = ReadInt8Data(mat, (mat_int8_t *)data, packed_type, N);
                break;
            case MAT_C_UINT8:
                nBytes = ReadUInt8Data(mat, (mat_uint8_t *)data, packed_type, N);
                break;
            default:
                break;
        }
        nBytes *= Mat_SizeOf(packed_type);
        /*
         * If the data was in the tag we started on a 4-byte
         * boundary so add 4 to make it an 8-byte
         */
        if ( data_in_tag )
            nBytes += 4;
        if ( (nBytes % 8) != 0 )
            (void)fseek((FILE *)mat->fp, 8 - (nBytes % 8), SEEK_CUR);
#if HAVE_ZLIB
    } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
        switch ( matvar->class_type ) {
            case MAT_C_DOUBLE:
                nBytes = ReadCompressedDoubleData(mat, matvar->internal->z, (double *)data,
                                                  packed_type, N);
                break;
            case MAT_C_SINGLE:
                nBytes = ReadCompressedSingleData(mat, matvar->internal->z, (float *)data,
                                                  packed_type, N);
                break;
            case MAT_C_INT64:
#ifdef HAVE_MATIO_INT64_T
                nBytes = ReadCompressedInt64Data(mat, matvar->internal->z, (mat_int64_t *)data,
                                                 packed_type, N);
#endif
                break;
            case MAT_C_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                nBytes = ReadCompressedUInt64Data(mat, matvar->internal->z, (mat_uint64_t *)data,
                                                  packed_type, N);
#endif
                break;
            case MAT_C_INT32:
                nBytes = ReadCompressedInt32Data(mat, matvar->internal->z, (mat_int32_t *)data,
                                                 packed_type, N);
                break;
            case MAT_C_UINT32:
                nBytes = ReadCompressedUInt32Data(mat, matvar->internal->z, (mat_uint32_t *)data,
                                                  packed_type, N);
                break;
            case MAT_C_INT16:
                nBytes = ReadCompressedInt16Data(mat, matvar->internal->z, (mat_int16_t *)data,
                                                 packed_type, N);
                break;
            case MAT_C_UINT16:
                nBytes = ReadCompressedUInt16Data(mat, matvar->internal->z, (mat_uint16_t *)data,
                                                  packed_type, N);
                break;
            case MAT_C_INT8:
                nBytes = ReadCompressedInt8Data(mat, matvar->internal->z, (mat_int8_t *)data,
                                                packed_type, N);
                break;
            case MAT_C_UINT8:
                nBytes = ReadCompressedUInt8Data(mat, matvar->internal->z, (mat_uint8_t *)data,
                                                 packed_type, N);
                break;
            default:
                break;
        }
        /*
         * If the data was in the tag we started on a 4-byte
         * boundary so add 4 to make it an 8-byte
         */
        if ( data_in_tag )
            nBytes += 4;
        if ( (nBytes % 8) != 0 )
            err = InflateSkip(mat, matvar->internal->z, 8 - (nBytes % 8), NULL);
#endif
    }
    return err;
}

/** @if mat_devman
 * @brief Reads the data of a version 5 MAT variable
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar MAT variable pointer to read the data
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarRead5(mat_t *mat, matvar_t *matvar)
{
    int nBytes = 0, byteswap, data_in_tag = 0, err;
    size_t nelems = 1;
    enum matio_types packed_type = MAT_T_UNKNOWN;
    long fpos;
    mat_uint32_t tag[2];
    size_t bytesread = 0;

    if ( matvar == NULL )
        return MATIO_E_BAD_ARGUMENT;
    else if ( matvar->rank == 0 ) /* An empty data set */
        return MATIO_E_NO_ERROR;
#if HAVE_ZLIB
    else if ( NULL != matvar->internal->data ) {
        /* Data already read in ReadNextStructField or ReadNextCell */
        matvar->data = matvar->internal->data;
        matvar->internal->data = NULL;
        return MATIO_E_NO_ERROR;
    }
#endif
    fpos = ftell((FILE *)mat->fp);
    if ( fpos == -1L ) {
        Mat_Critical("Couldn't determine file position");
        return MATIO_E_GENERIC_READ_ERROR;
    }
    err = Mat_MulDims(matvar, &nelems);
    if ( err ) {
        Mat_Critical("Integer multiplication overflow");
        return err;
    }
    byteswap = mat->byteswap;
    switch ( matvar->class_type ) {
        case MAT_C_EMPTY:
            matvar->nbytes = 0;
            matvar->data_size = sizeof(double);
            matvar->data_type = MAT_T_DOUBLE;
            matvar->rank = 2;
            if ( NULL != matvar->dims ) {
                free(matvar->dims);
            }
            matvar->dims = (size_t *)calloc(matvar->rank, sizeof(*(matvar->dims)));
            break;
        case MAT_C_DOUBLE:
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
            matvar->data_size = sizeof(double);
            matvar->data_type = MAT_T_DOUBLE;
            break;
        case MAT_C_SINGLE:
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
            matvar->data_size = sizeof(float);
            matvar->data_type = MAT_T_SINGLE;
            break;
        case MAT_C_INT64:
#ifdef HAVE_MATIO_INT64_T
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
            matvar->data_size = sizeof(mat_int64_t);
            matvar->data_type = MAT_T_INT64;
#endif
            break;
        case MAT_C_UINT64:
#ifdef HAVE_MATIO_UINT64_T
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
            matvar->data_size = sizeof(mat_uint64_t);
            matvar->data_type = MAT_T_UINT64;
#endif
            break;
        case MAT_C_INT32:
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
            matvar->data_size = sizeof(mat_int32_t);
            matvar->data_type = MAT_T_INT32;
            break;
        case MAT_C_UINT32:
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
            matvar->data_size = sizeof(mat_uint32_t);
            matvar->data_type = MAT_T_UINT32;
            break;
        case MAT_C_INT16:
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
            matvar->data_size = sizeof(mat_int16_t);
            matvar->data_type = MAT_T_INT16;
            break;
        case MAT_C_UINT16:
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
            matvar->data_size = sizeof(mat_uint16_t);
            matvar->data_type = MAT_T_UINT16;
            break;
        case MAT_C_INT8:
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
            matvar->data_size = sizeof(mat_int8_t);
            matvar->data_type = MAT_T_INT8;
            break;
        case MAT_C_UINT8:
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
            matvar->data_size = sizeof(mat_uint8_t);
            matvar->data_type = MAT_T_UINT8;
            break;
        case MAT_C_CHAR:
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
            if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
#if HAVE_ZLIB
                matvar->internal->z->avail_in = 0;
                err = Inflate(mat, matvar->internal->z, tag, 4, &bytesread);
                if ( err ) {
                    break;
                }
                if ( byteswap )
                    (void)Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    nBytes = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    err = Inflate(mat, matvar->internal->z, tag + 1, 4, &bytesread);
                    if ( err ) {
                        break;
                    }
                    if ( byteswap )
                        (void)Mat_uint32Swap(tag + 1);
                    nBytes = tag[1];
                }
#endif
                matvar->data_type = packed_type;
                matvar->data_size = Mat_SizeOf(matvar->data_type);
                matvar->nbytes = nBytes;
            } else {
                err = Read(tag, 4, 1, (FILE *)mat->fp, &bytesread);
                if ( err ) {
                    break;
                }
                if ( byteswap )
                    (void)Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    nBytes = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    err = Read(tag + 1, 4, 1, (FILE *)mat->fp, &bytesread);
                    if ( err ) {
                        break;
                    }
                    if ( byteswap )
                        (void)Mat_uint32Swap(tag + 1);
                    nBytes = tag[1];
                }
                matvar->data_type = packed_type;
                matvar->data_size = Mat_SizeOf(matvar->data_type);
                matvar->nbytes = nBytes;
            }
            if ( matvar->isComplex ) {
                break;
            }
            if ( 0 == matvar->nbytes ) {
                matvar->data = calloc(1, 1);
            } else {
                matvar->data = calloc(matvar->nbytes, 1);
            }
            if ( NULL == matvar->data ) {
                err = MATIO_E_OUT_OF_MEMORY;
                Mat_Critical("Couldn't allocate memory for the data");
                break;
            }
            if ( 0 == matvar->nbytes ) {
                break;
            }
            {
                size_t nbytes;
                err = Mul(&nbytes, nelems, matvar->data_size);
                if ( err || nbytes > matvar->nbytes ) {
                    break;
                }
            }
            if ( matvar->data_type == MAT_T_UTF8 ) {
                nelems = matvar->nbytes;
            }
            if ( matvar->compression == MAT_COMPRESSION_NONE ) {
                nBytes = ReadCharData(mat, matvar->data, matvar->data_type, nelems);
                /*
                 * If the data was in the tag we started on a 4-byte
                 * boundary so add 4 to make it an 8-byte
                 */
                if ( data_in_tag )
                    nBytes += 4;
                if ( (nBytes % 8) != 0 )
                    (void)fseek((FILE *)mat->fp, 8 - (nBytes % 8), SEEK_CUR);
#if HAVE_ZLIB
            } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
                nBytes = ReadCompressedCharData(mat, matvar->internal->z, matvar->data,
                                                matvar->data_type, nelems);
                /*
                 * If the data was in the tag we started on a 4-byte
                 * boundary so add 4 to make it an 8-byte
                 */
                if ( data_in_tag )
                    nBytes += 4;
                if ( (nBytes % 8) != 0 )
                    InflateSkip(mat, matvar->internal->z, 8 - (nBytes % 8), NULL);
#endif
            }
            break;
        case MAT_C_STRUCT: {
            matvar_t **fields;
            size_t i, nelems_x_nfields;

            matvar->data_type = MAT_T_STRUCT;
            err = Mul(&nelems_x_nfields, nelems, matvar->internal->num_fields);
            if ( err || !matvar->nbytes || !matvar->data_size || NULL == matvar->data )
                break;
            fields = (matvar_t **)matvar->data;
            for ( i = 0; i < nelems_x_nfields; i++ ) {
                if ( NULL != fields[i] ) {
                    err = Mat_VarRead5(mat, fields[i]);
                    if ( err )
                        break;
                }
            }
            break;
        }
        case MAT_C_CELL: {
            matvar_t **cells;
            size_t i;

            if ( NULL == matvar->data ) {
                Mat_Critical("Data is NULL for cell array %s", matvar->name);
                err = MATIO_E_FILE_FORMAT_VIOLATION;
                break;
            }
            cells = (matvar_t **)matvar->data;
            for ( i = 0; i < nelems; i++ ) {
                if ( NULL != cells[i] ) {
                    err = Mat_VarRead5(mat, cells[i]);
                    if ( err )
                        break;
                }
            }
            /* FIXME: */
            matvar->data_type = MAT_T_CELL;
            break;
        }
        case MAT_C_SPARSE: {
            mat_uint32_t N = 0;
            mat_sparse_t *sparse;

            matvar->data_size = sizeof(mat_sparse_t);
            matvar->data = calloc(1, matvar->data_size);
            if ( matvar->data == NULL ) {
                err = MATIO_E_OUT_OF_MEMORY;
                Mat_Critical("Mat_VarRead5: Allocation of data pointer failed");
                break;
            }
            sparse = (mat_sparse_t *)matvar->data;
            sparse->nzmax = matvar->nbytes;
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
            /*  Read ir    */
            bytesread += ReadSparse(mat, matvar, &sparse->nir, &sparse->ir);
            /*  Read jc    */
            bytesread += ReadSparse(mat, matvar, &sparse->njc, &sparse->jc);
            /*  Read data  */
            if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
#if HAVE_ZLIB
                matvar->internal->z->avail_in = 0;
                err = Inflate(mat, matvar->internal->z, tag, 4, &bytesread);
                if ( err ) {
                    break;
                }
                if ( mat->byteswap )
                    (void)Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    N = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    (void)ReadCompressedUInt32Data(mat, matvar->internal->z, &N, MAT_T_UINT32, 1);
                }
#endif
            } else {
                err = Read(tag, 4, 1, (FILE *)mat->fp, &bytesread);
                if ( err ) {
                    break;
                }
                if ( mat->byteswap )
                    (void)Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    N = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    err = Read(&N, 4, 1, (FILE *)mat->fp, &bytesread);
                    if ( err ) {
                        break;
                    }
                    if ( mat->byteswap )
                        (void)Mat_uint32Swap(&N);
                }
            }
            if ( matvar->isLogical && packed_type == MAT_T_DOUBLE ) {
                /* For some reason, MAT says the data type is a double,
                 * but it appears to be written as 8-bit unsigned integer.
                 */
                packed_type = MAT_T_UINT8;
            }
#if defined(EXTENDED_SPARSE)
            matvar->data_type = packed_type;
#else
            matvar->data_type = MAT_T_DOUBLE;
#endif
            {
                size_t s_type = Mat_SizeOf(packed_type);
                if ( s_type == 0 )
                    break;
                sparse->ndata = N / s_type;
            }
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;
                size_t nbytes;
                err = Mul(&nbytes, sparse->ndata, Mat_SizeOf(matvar->data_type));
                if ( err ) {
                    Mat_Critical("Integer multiplication overflow");
                    break;
                }
                complex_data = ComplexMalloc(nbytes);
                if ( NULL == complex_data ) {
                    err = MATIO_E_OUT_OF_MEMORY;
                    Mat_Critical("Couldn't allocate memory for the complex sparse data");
                    break;
                }
                if ( matvar->compression == MAT_COMPRESSION_NONE ) {
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadDoubleData(mat, (double *)complex_data->Re, packed_type,
                                                    sparse->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadSingleData(mat, (float *)complex_data->Re, packed_type,
                                                    sparse->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadInt64Data(mat, (mat_int64_t *)complex_data->Re,
                                                   packed_type, sparse->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadUInt64Data(mat, (mat_uint64_t *)complex_data->Re,
                                                    packed_type, sparse->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadInt32Data(mat, (mat_int32_t *)complex_data->Re,
                                                   packed_type, sparse->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadUInt32Data(mat, (mat_uint32_t *)complex_data->Re,
                                                    packed_type, sparse->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadInt16Data(mat, (mat_int16_t *)complex_data->Re,
                                                   packed_type, sparse->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadUInt16Data(mat, (mat_uint16_t *)complex_data->Re,
                                                    packed_type, sparse->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadInt8Data(mat, (mat_int8_t *)complex_data->Re, packed_type,
                                                  sparse->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadUInt8Data(mat, (mat_uint8_t *)complex_data->Re,
                                                   packed_type, sparse->ndata);
                            break;
                        default:
                            break;
                    }
#else
                    nBytes =
                        ReadDoubleData(mat, (double *)complex_data->Re, packed_type, sparse->ndata);
#endif
                    nBytes *= Mat_SizeOf(packed_type);
                    if ( data_in_tag )
                        nBytes += 4;
                    if ( (nBytes % 8) != 0 )
                        (void)fseek((FILE *)mat->fp, 8 - (nBytes % 8), SEEK_CUR);

                    /* Complex Data Tag */
                    err = Read(tag, 4, 1, (FILE *)mat->fp, &bytesread);
                    if ( err ) {
                        ComplexFree(complex_data);
                        break;
                    }
                    if ( byteswap )
                        (void)Mat_uint32Swap(tag);
                    packed_type = TYPE_FROM_TAG(tag[0]);
                    if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                        data_in_tag = 1;
                        nBytes = (tag[0] & 0xffff0000) >> 16;
                    } else {
                        data_in_tag = 0;
                        err = Read(tag + 1, 4, 1, (FILE *)mat->fp, &bytesread);
                        if ( err ) {
                            ComplexFree(complex_data);
                            break;
                        }
                        if ( byteswap )
                            (void)Mat_uint32Swap(tag + 1);
                        nBytes = tag[1];
                    }
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadDoubleData(mat, (double *)complex_data->Im, packed_type,
                                                    sparse->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadSingleData(mat, (float *)complex_data->Im, packed_type,
                                                    sparse->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadInt64Data(mat, (mat_int64_t *)complex_data->Im,
                                                   packed_type, sparse->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadUInt64Data(mat, (mat_uint64_t *)complex_data->Im,
                                                    packed_type, sparse->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadInt32Data(mat, (mat_int32_t *)complex_data->Im,
                                                   packed_type, sparse->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadUInt32Data(mat, (mat_uint32_t *)complex_data->Im,
                                                    packed_type, sparse->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadInt16Data(mat, (mat_int16_t *)complex_data->Im,
                                                   packed_type, sparse->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadUInt16Data(mat, (mat_uint16_t *)complex_data->Im,
                                                    packed_type, sparse->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadInt8Data(mat, (mat_int8_t *)complex_data->Im, packed_type,
                                                  sparse->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadUInt8Data(mat, (mat_uint8_t *)complex_data->Im,
                                                   packed_type, sparse->ndata);
                            break;
                        default:
                            break;
                    }
#else /* EXTENDED_SPARSE */
                    nBytes =
                        ReadDoubleData(mat, (double *)complex_data->Im, packed_type, sparse->ndata);
#endif /* EXTENDED_SPARSE */
                    nBytes *= Mat_SizeOf(packed_type);
                    if ( data_in_tag )
                        nBytes += 4;
                    if ( (nBytes % 8) != 0 )
                        (void)fseek((FILE *)mat->fp, 8 - (nBytes % 8), SEEK_CUR);
#if HAVE_ZLIB
                } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadCompressedDoubleData(mat, matvar->internal->z,
                                                              (double *)complex_data->Re,
                                                              packed_type, sparse->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadCompressedSingleData(mat, matvar->internal->z,
                                                              (float *)complex_data->Re,
                                                              packed_type, sparse->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadCompressedInt64Data(mat, matvar->internal->z,
                                                             (mat_int64_t *)complex_data->Re,
                                                             packed_type, sparse->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadCompressedUInt64Data(mat, matvar->internal->z,
                                                              (mat_uint64_t *)complex_data->Re,
                                                              packed_type, sparse->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadCompressedInt32Data(mat, matvar->internal->z,
                                                             (mat_int32_t *)complex_data->Re,
                                                             packed_type, sparse->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadCompressedUInt32Data(mat, matvar->internal->z,
                                                              (mat_uint32_t *)complex_data->Re,
                                                              packed_type, sparse->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadCompressedInt16Data(mat, matvar->internal->z,
                                                             (mat_int16_t *)complex_data->Re,
                                                             packed_type, sparse->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadCompressedUInt16Data(mat, matvar->internal->z,
                                                              (mat_uint16_t *)complex_data->Re,
                                                              packed_type, sparse->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadCompressedInt8Data(mat, matvar->internal->z,
                                                            (mat_int8_t *)complex_data->Re,
                                                            packed_type, sparse->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadCompressedUInt8Data(mat, matvar->internal->z,
                                                             (mat_uint8_t *)complex_data->Re,
                                                             packed_type, sparse->ndata);
                            break;
                        default:
                            break;
                    }
#else /* EXTENDED_SPARSE */
                    nBytes = ReadCompressedDoubleData(mat, matvar->internal->z,
                                                      (double *)complex_data->Re, packed_type,
                                                      sparse->ndata);
#endif /* EXTENDED_SPARSE */
                    if ( data_in_tag )
                        nBytes += 4;
                    if ( (nBytes % 8) != 0 )
                        InflateSkip(mat, matvar->internal->z, 8 - (nBytes % 8), NULL);

                    /* Complex Data Tag */
                    err = Inflate(mat, matvar->internal->z, tag, 4, NULL);
                    if ( err ) {
                        ComplexFree(complex_data);
                        break;
                    }
                    if ( byteswap )
                        (void)Mat_uint32Swap(tag);

                    packed_type = TYPE_FROM_TAG(tag[0]);
                    if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                        data_in_tag = 1;
                        nBytes = (tag[0] & 0xffff0000) >> 16;
                    } else {
                        data_in_tag = 0;
                        err = Inflate(mat, matvar->internal->z, tag + 1, 4, NULL);
                        if ( err ) {
                            ComplexFree(complex_data);
                            break;
                        }
                        if ( byteswap )
                            (void)Mat_uint32Swap(tag + 1);
                        nBytes = tag[1];
                    }
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadCompressedDoubleData(mat, matvar->internal->z,
                                                              (double *)complex_data->Im,
                                                              packed_type, sparse->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadCompressedSingleData(mat, matvar->internal->z,
                                                              (float *)complex_data->Im,
                                                              packed_type, sparse->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadCompressedInt64Data(mat, matvar->internal->z,
                                                             (mat_int64_t *)complex_data->Im,
                                                             packed_type, sparse->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadCompressedUInt64Data(mat, matvar->internal->z,
                                                              (mat_uint64_t *)complex_data->Im,
                                                              packed_type, sparse->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadCompressedInt32Data(mat, matvar->internal->z,
                                                             (mat_int32_t *)complex_data->Im,
                                                             packed_type, sparse->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadCompressedUInt32Data(mat, matvar->internal->z,
                                                              (mat_uint32_t *)complex_data->Im,
                                                              packed_type, sparse->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadCompressedInt16Data(mat, matvar->internal->z,
                                                             (mat_int16_t *)complex_data->Im,
                                                             packed_type, sparse->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadCompressedUInt16Data(mat, matvar->internal->z,
                                                              (mat_uint16_t *)complex_data->Im,
                                                              packed_type, sparse->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadCompressedInt8Data(mat, matvar->internal->z,
                                                            (mat_int8_t *)complex_data->Im,
                                                            packed_type, sparse->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadCompressedUInt8Data(mat, matvar->internal->z,
                                                             (mat_uint8_t *)complex_data->Im,
                                                             packed_type, sparse->ndata);
                            break;
                        default:
                            break;
                    }
#else /* EXTENDED_SPARSE */
                    nBytes = ReadCompressedDoubleData(mat, matvar->internal->z,
                                                      (double *)complex_data->Im, packed_type,
                                                      sparse->ndata);
#endif /* EXTENDED_SPARSE */
                    if ( data_in_tag )
                        nBytes += 4;
                    if ( (nBytes % 8) != 0 )
                        err = InflateSkip(mat, matvar->internal->z, 8 - (nBytes % 8), NULL);
#endif /* HAVE_ZLIB */
                }
                sparse->data = complex_data;
            } else { /* isComplex */
                size_t nbytes;
                err = Mul(&nbytes, sparse->ndata, Mat_SizeOf(matvar->data_type));
                if ( err ) {
                    Mat_Critical("Integer multiplication overflow");
                    break;
                }
                sparse->data = malloc(nbytes);
                if ( sparse->data == NULL ) {
                    err = MATIO_E_OUT_OF_MEMORY;
                    Mat_Critical("Couldn't allocate memory for the sparse data");
                    break;
                }
                if ( matvar->compression == MAT_COMPRESSION_NONE ) {
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadDoubleData(mat, (double *)sparse->data, packed_type,
                                                    sparse->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadSingleData(mat, (float *)sparse->data, packed_type,
                                                    sparse->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadInt64Data(mat, (mat_int64_t *)sparse->data, packed_type,
                                                   sparse->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadUInt64Data(mat, (mat_uint64_t *)sparse->data, packed_type,
                                                    sparse->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadInt32Data(mat, (mat_int32_t *)sparse->data, packed_type,
                                                   sparse->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadUInt32Data(mat, (mat_uint32_t *)sparse->data, packed_type,
                                                    sparse->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadInt16Data(mat, (mat_int16_t *)sparse->data, packed_type,
                                                   sparse->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadUInt16Data(mat, (mat_uint16_t *)sparse->data, packed_type,
                                                    sparse->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadInt8Data(mat, (mat_int8_t *)sparse->data, packed_type,
                                                  sparse->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadUInt8Data(mat, (mat_uint8_t *)sparse->data, packed_type,
                                                   sparse->ndata);
                            break;
                        default:
                            break;
                    }
#else
                    nBytes =
                        ReadDoubleData(mat, (double *)sparse->data, packed_type, sparse->ndata);
#endif
                    nBytes *= Mat_SizeOf(packed_type);
                    if ( data_in_tag )
                        nBytes += 4;
                    if ( (nBytes % 8) != 0 )
                        (void)fseek((FILE *)mat->fp, 8 - (nBytes % 8), SEEK_CUR);
#if HAVE_ZLIB
                } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadCompressedDoubleData(mat, matvar->internal->z,
                                                              (double *)sparse->data, packed_type,
                                                              sparse->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadCompressedSingleData(mat, matvar->internal->z,
                                                              (float *)sparse->data, packed_type,
                                                              sparse->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadCompressedInt64Data(mat, matvar->internal->z,
                                                             (mat_int64_t *)sparse->data,
                                                             packed_type, sparse->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadCompressedUInt64Data(mat, matvar->internal->z,
                                                              (mat_uint64_t *)sparse->data,
                                                              packed_type, sparse->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadCompressedInt32Data(mat, matvar->internal->z,
                                                             (mat_int32_t *)sparse->data,
                                                             packed_type, sparse->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadCompressedUInt32Data(mat, matvar->internal->z,
                                                              (mat_uint32_t *)sparse->data,
                                                              packed_type, sparse->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadCompressedInt16Data(mat, matvar->internal->z,
                                                             (mat_int16_t *)sparse->data,
                                                             packed_type, sparse->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadCompressedUInt16Data(mat, matvar->internal->z,
                                                              (mat_uint16_t *)sparse->data,
                                                              packed_type, sparse->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadCompressedInt8Data(mat, matvar->internal->z,
                                                            (mat_int8_t *)sparse->data, packed_type,
                                                            sparse->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadCompressedUInt8Data(mat, matvar->internal->z,
                                                             (mat_uint8_t *)sparse->data,
                                                             packed_type, sparse->ndata);
                            break;
                        default:
                            break;
                    }
#else /* EXTENDED_SPARSE */
                    nBytes =
                        ReadCompressedDoubleData(mat, matvar->internal->z, (double *)sparse->data,
                                                 packed_type, sparse->ndata);
#endif /* EXTENDED_SPARSE */
                    if ( data_in_tag )
                        nBytes += 4;
                    if ( (nBytes % 8) != 0 )
                        err = InflateSkip(mat, matvar->internal->z, 8 - (nBytes % 8), NULL);
#endif /* HAVE_ZLIB */
                }
            }
            break;
        }
        case MAT_C_FUNCTION: {
            matvar_t **functions;
            size_t nfunctions = 0;

            if ( !matvar->nbytes || !matvar->data_size )
                break;
            nfunctions = matvar->nbytes / matvar->data_size;
            functions = (matvar_t **)matvar->data;
            if ( NULL != functions ) {
                size_t i;
                for ( i = 0; i < nfunctions; i++ ) {
                    err = Mat_VarRead5(mat, functions[i]);
                    if ( err )
                        break;
                }
            }
            /* FIXME: */
            matvar->data_type = MAT_T_FUNCTION;
            break;
        }
        case MAT_C_OBJECT:
            Mat_Warning("Mat_VarRead5: %d is not a supported class", matvar->class_type);
            break;
        default:
            err = MATIO_E_OPERATION_NOT_SUPPORTED;
            Mat_Critical("Mat_VarRead5: %d is not a supported class", matvar->class_type);
            break;
    }
    switch ( matvar->class_type ) {
        case MAT_C_DOUBLE:
        case MAT_C_SINGLE:
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
#endif
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
#endif
        case MAT_C_INT32:
        case MAT_C_UINT32:
        case MAT_C_INT16:
        case MAT_C_UINT16:
        case MAT_C_INT8:
        case MAT_C_UINT8:
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                err = Mul(&matvar->nbytes, nelems, matvar->data_size);
                if ( err ) {
                    Mat_Critical("Integer multiplication overflow");
                    break;
                }

                complex_data = ComplexMalloc(matvar->nbytes);
                if ( NULL == complex_data ) {
                    err = MATIO_E_OUT_OF_MEMORY;
                    Mat_Critical("Couldn't allocate memory for the complex data");
                    break;
                }

                err = Mat_VarReadNumeric5(mat, matvar, complex_data->Re, nelems);
                if ( err ) {
                    ComplexFree(complex_data);
                    break;
                }
                err = Mat_VarReadNumeric5(mat, matvar, complex_data->Im, nelems);
                if ( err ) {
                    ComplexFree(complex_data);
                    break;
                }
                matvar->data = complex_data;
            } else {
                void *data;
                err = Mul(&matvar->nbytes, nelems, matvar->data_size);
                if ( err ) {
                    Mat_Critical("Integer multiplication overflow");
                    break;
                }

                data = malloc(matvar->nbytes);
                if ( NULL == data ) {
                    err = MATIO_E_OUT_OF_MEMORY;
                    Mat_Critical("Couldn't allocate memory for the data");
                    break;
                }
                err = Mat_VarReadNumeric5(mat, matvar, data, nelems);
                if ( err ) {
                    free(data);
                    break;
                }
                matvar->data = data;
            }
        default:
            break;
    }
    (void)fseek((FILE *)mat->fp, fpos, SEEK_SET);

    return err;
}

#if HAVE_ZLIB
#define GET_DATA_SLABN_RANK_LOOP                                                \
    do {                                                                        \
        for ( j = 1; j < rank; j++ ) {                                          \
            cnt[j]++;                                                           \
            if ( (cnt[j] % edge[j]) == 0 ) {                                    \
                cnt[j] = 0;                                                     \
                if ( (I % dimp[j]) != 0 ) {                                     \
                    ptr_in += dimp[j] - (I % dimp[j]) + dimp[j - 1] * start[j]; \
                    I += dimp[j] - (I % dimp[j]) + dimp[j - 1] * start[j];      \
                } else if ( start[j] ) {                                        \
                    ptr_in += dimp[j - 1] * start[j];                           \
                    I += dimp[j - 1] * start[j];                                \
                }                                                               \
            } else {                                                            \
                I += inc[j];                                                    \
                ptr_in += inc[j];                                               \
                break;                                                          \
            }                                                                   \
        }                                                                       \
    } while ( 0 )

#define GET_DATA_SLAB2(T)                              \
    do {                                               \
        ptr_in += start[1] * dims[0] + start[0];       \
        for ( i = 0; i < edge[1]; i++ ) {              \
            for ( j = 0; j < edge[0]; j++ ) {          \
                *ptr = (T)(*(ptr_in + j * stride[0])); \
                ptr++;                                 \
            }                                          \
            ptr_in += stride[1] * dims[0];             \
        }                                              \
    } while ( 0 )

#define GET_DATA_SLABN(T)                                                      \
    do {                                                                       \
        inc[0] = stride[0] - 1;                                                \
        dimp[0] = dims[0];                                                     \
        N = edge[0];                                                           \
        I = 0; /* start[0]; */                                                 \
        for ( i = 1; i < rank; i++ ) {                                         \
            inc[i] = stride[i] - 1;                                            \
            dimp[i] = dims[i - 1];                                             \
            for ( j = i; j--; ) {                                              \
                inc[i] *= dims[j];                                             \
                dimp[i] *= dims[j + 1];                                        \
            }                                                                  \
            N *= edge[i];                                                      \
            I += dimp[i - 1] * start[i];                                       \
        }                                                                      \
        ptr_in += I;                                                           \
        if ( stride[0] == 1 ) {                                                \
            for ( i = 0; i < N; i += edge[0] ) {                               \
                int k;                                                         \
                if ( start[0] ) {                                              \
                    ptr_in += start[0];                                        \
                    I += start[0];                                             \
                }                                                              \
                for ( k = 0; k < edge[0]; k++ ) {                              \
                    *(ptr + i + k) = (T)(*(ptr_in + k));                       \
                }                                                              \
                I += dims[0] - start[0];                                       \
                ptr_in += dims[0] - start[0];                                  \
                GET_DATA_SLABN_RANK_LOOP;                                      \
            }                                                                  \
        } else {                                                               \
            for ( i = 0; i < N; i += edge[0] ) {                               \
                if ( start[0] ) {                                              \
                    ptr_in += start[0];                                        \
                    I += start[0];                                             \
                }                                                              \
                for ( j = 0; j < edge[0]; j++ ) {                              \
                    *(ptr + i + j) = (T)(*ptr_in);                             \
                    ptr_in += stride[0];                                       \
                    I += stride[0];                                            \
                }                                                              \
                I += dims[0] - (ptrdiff_t)edge[0] * stride[0] - start[0];      \
                ptr_in += dims[0] - (ptrdiff_t)edge[0] * stride[0] - start[0]; \
                GET_DATA_SLABN_RANK_LOOP;                                      \
            }                                                                  \
        }                                                                      \
    } while ( 0 )

#ifdef HAVE_MATIO_INT64_T
#define GET_DATA_SLAB2_INT64(T)                           \
    do {                                                  \
        if ( MAT_T_INT64 == data_type ) {                 \
            mat_int64_t *ptr_in = (mat_int64_t *)data_in; \
            GET_DATA_SLAB2(T);                            \
            err = MATIO_E_NO_ERROR;                       \
        }                                                 \
    } while ( 0 )
#else
#define GET_DATA_SLAB2_INT64(T)
#endif /* HAVE_MATIO_INT64_T */

#ifdef HAVE_MATIO_UINT64_T
#define GET_DATA_SLAB2_UINT64(T)                            \
    do {                                                    \
        if ( MAT_T_UINT64 == data_type ) {                  \
            mat_uint64_t *ptr_in = (mat_uint64_t *)data_in; \
            GET_DATA_SLAB2(T);                              \
            err = MATIO_E_NO_ERROR;                         \
        }                                                   \
    } while ( 0 )
#else
#define GET_DATA_SLAB2_UINT64(T)
#endif /* HAVE_MATIO_UINT64_T */

#define GET_DATA_SLAB2_TYPE(T)                                  \
    do {                                                        \
        switch ( data_type ) {                                  \
            case MAT_T_DOUBLE: {                                \
                double *ptr_in = (double *)data_in;             \
                GET_DATA_SLAB2(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_SINGLE: {                                \
                float *ptr_in = (float *)data_in;               \
                GET_DATA_SLAB2(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_INT32: {                                 \
                mat_int32_t *ptr_in = (mat_int32_t *)data_in;   \
                GET_DATA_SLAB2(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_UINT32: {                                \
                mat_uint32_t *ptr_in = (mat_uint32_t *)data_in; \
                GET_DATA_SLAB2(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_INT16: {                                 \
                mat_int16_t *ptr_in = (mat_int16_t *)data_in;   \
                GET_DATA_SLAB2(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_UINT16: {                                \
                mat_uint16_t *ptr_in = (mat_uint16_t *)data_in; \
                GET_DATA_SLAB2(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_INT8: {                                  \
                mat_int8_t *ptr_in = (mat_int8_t *)data_in;     \
                GET_DATA_SLAB2(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_UINT8: {                                 \
                mat_uint8_t *ptr_in = (mat_uint8_t *)data_in;   \
                GET_DATA_SLAB2(T);                              \
                break;                                          \
            }                                                   \
            default:                                            \
                err = MATIO_E_OPERATION_NOT_SUPPORTED;          \
                GET_DATA_SLAB2_INT64(T);                        \
                GET_DATA_SLAB2_UINT64(T);                       \
                break;                                          \
        }                                                       \
    } while ( 0 )

#ifdef HAVE_MATIO_INT64_T
#define GET_DATA_SLABN_INT64(T)                           \
    do {                                                  \
        if ( MAT_T_INT64 == data_type ) {                 \
            mat_int64_t *ptr_in = (mat_int64_t *)data_in; \
            GET_DATA_SLABN(T);                            \
            err = MATIO_E_NO_ERROR;                       \
        }                                                 \
    } while ( 0 )
#else
#define GET_DATA_SLABN_INT64(T)
#endif /* HAVE_MATIO_INT64_T */

#ifdef HAVE_MATIO_UINT64_T
#define GET_DATA_SLABN_UINT64(T)                            \
    do {                                                    \
        if ( MAT_T_UINT64 == data_type ) {                  \
            mat_uint64_t *ptr_in = (mat_uint64_t *)data_in; \
            GET_DATA_SLABN(T);                              \
            err = 0;                                        \
        }                                                   \
    } while ( 0 )
#else
#define GET_DATA_SLABN_UINT64(T)
#endif /* HAVE_MATIO_UINT64_T */

#define GET_DATA_SLABN_TYPE(T)                                  \
    do {                                                        \
        switch ( data_type ) {                                  \
            case MAT_T_DOUBLE: {                                \
                double *ptr_in = (double *)data_in;             \
                GET_DATA_SLABN(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_SINGLE: {                                \
                float *ptr_in = (float *)data_in;               \
                GET_DATA_SLABN(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_INT32: {                                 \
                mat_int32_t *ptr_in = (mat_int32_t *)data_in;   \
                GET_DATA_SLABN(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_UINT32: {                                \
                mat_uint32_t *ptr_in = (mat_uint32_t *)data_in; \
                GET_DATA_SLABN(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_INT16: {                                 \
                mat_int16_t *ptr_in = (mat_int16_t *)data_in;   \
                GET_DATA_SLABN(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_UINT16: {                                \
                mat_uint16_t *ptr_in = (mat_uint16_t *)data_in; \
                GET_DATA_SLABN(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_INT8: {                                  \
                mat_int8_t *ptr_in = (mat_int8_t *)data_in;     \
                GET_DATA_SLABN(T);                              \
                break;                                          \
            }                                                   \
            case MAT_T_UINT8: {                                 \
                mat_uint8_t *ptr_in = (mat_uint8_t *)data_in;   \
                GET_DATA_SLABN(T);                              \
                break;                                          \
            }                                                   \
            default:                                            \
                err = MATIO_E_OPERATION_NOT_SUPPORTED;          \
                GET_DATA_SLABN_INT64(T);                        \
                GET_DATA_SLABN_UINT64(T);                       \
                break;                                          \
        }                                                       \
    } while ( 0 )

static int
GetDataSlab(void *data_in, void *data_out, enum matio_classes class_type,
            enum matio_types data_type, size_t *dims, int *start, int *stride, int *edge, int rank,
            size_t nbytes)
{
    int err = MATIO_E_NO_ERROR;
    int same_type = 0;
    if ( (class_type == MAT_C_DOUBLE && data_type == MAT_T_DOUBLE) ||
         (class_type == MAT_C_SINGLE && data_type == MAT_T_SINGLE) ||
         (class_type == MAT_C_INT16 && data_type == MAT_T_INT16) ||
         (class_type == MAT_C_INT32 && data_type == MAT_T_INT32) ||
         (class_type == MAT_C_INT64 && data_type == MAT_T_INT64) ||
         (class_type == MAT_C_INT8 && data_type == MAT_T_INT8) ||
         (class_type == MAT_C_UINT16 && data_type == MAT_T_UINT16) ||
         (class_type == MAT_C_UINT32 && data_type == MAT_T_UINT32) ||
         (class_type == MAT_C_UINT64 && data_type == MAT_T_UINT64) ||
         (class_type == MAT_C_UINT8 && data_type == MAT_T_UINT8) )
        same_type = 1;

    if ( rank == 2 ) {
        if ( (size_t)stride[0] * (edge[0] - 1) + start[0] + 1 > dims[0] )
            err = MATIO_E_BAD_ARGUMENT;
        else if ( (size_t)stride[1] * (edge[1] - 1) + start[1] + 1 > dims[1] )
            err = MATIO_E_BAD_ARGUMENT;
        else if ( (stride[0] == 1 && (size_t)edge[0] == dims[0]) && (stride[1] == 1) &&
                  (same_type == 1) )
            memcpy(data_out, data_in, nbytes);
        else {
            int i, j;

            switch ( class_type ) {
                case MAT_C_DOUBLE: {
                    double *ptr = (double *)data_out;
                    GET_DATA_SLAB2_TYPE(double);
                    break;
                }
                case MAT_C_SINGLE: {
                    float *ptr = (float *)data_out;
                    GET_DATA_SLAB2_TYPE(float);
                    break;
                }
#ifdef HAVE_MATIO_INT64_T
                case MAT_C_INT64: {
                    mat_int64_t *ptr = (mat_int64_t *)data_out;
                    GET_DATA_SLAB2_TYPE(mat_int64_t);
                    break;
                }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
                case MAT_C_UINT64: {
                    mat_uint64_t *ptr = (mat_uint64_t *)data_out;
                    GET_DATA_SLAB2_TYPE(mat_uint64_t);
                    break;
                }
#endif /* HAVE_MATIO_UINT64_T */
                case MAT_C_INT32: {
                    mat_int32_t *ptr = (mat_int32_t *)data_out;
                    GET_DATA_SLAB2_TYPE(mat_int32_t);
                    break;
                }
                case MAT_C_UINT32: {
                    mat_uint32_t *ptr = (mat_uint32_t *)data_out;
                    GET_DATA_SLAB2_TYPE(mat_uint32_t);
                    break;
                }
                case MAT_C_INT16: {
                    mat_int16_t *ptr = (mat_int16_t *)data_out;
                    GET_DATA_SLAB2_TYPE(mat_int16_t);
                    break;
                }
                case MAT_C_UINT16: {
                    mat_uint16_t *ptr = (mat_uint16_t *)data_out;
                    GET_DATA_SLAB2_TYPE(mat_uint16_t);
                    break;
                }
                case MAT_C_INT8: {
                    mat_int8_t *ptr = (mat_int8_t *)data_out;
                    GET_DATA_SLAB2_TYPE(mat_int8_t);
                    break;
                }
                case MAT_C_UINT8: {
                    mat_uint8_t *ptr = (mat_uint8_t *)data_out;
                    GET_DATA_SLAB2_TYPE(mat_uint8_t);
                    break;
                }
                default:
                    err = MATIO_E_OPERATION_NOT_SUPPORTED;
                    break;
            }
        }
    } else {
        int i, j, N, I = 0;
        int inc[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        int cnt[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        int dimp[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

        switch ( class_type ) {
            case MAT_C_DOUBLE: {
                double *ptr = (double *)data_out;
                GET_DATA_SLABN_TYPE(double);
                break;
            }
            case MAT_C_SINGLE: {
                float *ptr = (float *)data_out;
                GET_DATA_SLABN_TYPE(float);
                break;
            }
#ifdef HAVE_MATIO_INT64_T
            case MAT_C_INT64: {
                mat_int64_t *ptr = (mat_int64_t *)data_out;
                GET_DATA_SLABN_TYPE(mat_int64_t);
                break;
            }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
            case MAT_C_UINT64: {
                mat_uint64_t *ptr = (mat_uint64_t *)data_out;
                GET_DATA_SLABN_TYPE(mat_uint64_t);
                break;
            }
#endif /* HAVE_MATIO_UINT64_T */
            case MAT_C_INT32: {
                mat_int32_t *ptr = (mat_int32_t *)data_out;
                GET_DATA_SLABN_TYPE(mat_int32_t);
                break;
            }
            case MAT_C_UINT32: {
                mat_uint32_t *ptr = (mat_uint32_t *)data_out;
                GET_DATA_SLABN_TYPE(mat_uint32_t);
                break;
            }
            case MAT_C_INT16: {
                mat_int16_t *ptr = (mat_int16_t *)data_out;
                GET_DATA_SLABN_TYPE(mat_int16_t);
                break;
            }
            case MAT_C_UINT16: {
                mat_uint16_t *ptr = (mat_uint16_t *)data_out;
                GET_DATA_SLABN_TYPE(mat_uint16_t);
                break;
            }
            case MAT_C_INT8: {
                mat_int8_t *ptr = (mat_int8_t *)data_out;
                GET_DATA_SLABN_TYPE(mat_int8_t);
                break;
            }
            case MAT_C_UINT8: {
                mat_uint8_t *ptr = (mat_uint8_t *)data_out;
                GET_DATA_SLABN_TYPE(mat_uint8_t);
                break;
            }
            default:
                err = MATIO_E_OPERATION_NOT_SUPPORTED;
                break;
        }
    }

    return err;
}

#undef GET_DATA_SLAB2
#undef GET_DATA_SLAB2_TYPE
#undef GET_DATA_SLAB2_INT64
#undef GET_DATA_SLAB2_UINT64
#undef GET_DATA_SLABN
#undef GET_DATA_SLABN_TYPE
#undef GET_DATA_SLABN_INT64
#undef GET_DATA_SLABN_UINT64
#undef GET_DATA_SLABN_RANK_LOOP

#define GET_DATA_LINEAR                                        \
    do {                                                       \
        ptr_in += start;                                       \
        if ( !stride ) {                                       \
            memcpy(ptr, ptr_in, (size_t)edge *data_size);      \
        } else {                                               \
            int i;                                             \
            for ( i = 0; i < edge; i++ )                       \
                memcpy(ptr++, ptr_in + i * stride, data_size); \
        }                                                      \
    } while ( 0 )

static int
GetDataLinear(void *data_in, void *data_out, enum matio_classes class_type,
              enum matio_types data_type, int start, int stride, int edge)
{
    int err = MATIO_E_NO_ERROR;
    size_t data_size = Mat_SizeOf(data_type);

    switch ( class_type ) {
        case MAT_C_DOUBLE: {
            double *ptr = (double *)data_out;
            double *ptr_in = (double *)data_in;
            GET_DATA_LINEAR;
            break;
        }
        case MAT_C_SINGLE: {
            float *ptr = (float *)data_out;
            float *ptr_in = (float *)data_in;
            GET_DATA_LINEAR;
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64: {
            mat_int64_t *ptr = (mat_int64_t *)data_out;
            mat_int64_t *ptr_in = (mat_int64_t *)data_in;
            GET_DATA_LINEAR;
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64: {
            mat_uint64_t *ptr = (mat_uint64_t *)data_out;
            mat_uint64_t *ptr_in = (mat_uint64_t *)data_in;
            GET_DATA_LINEAR;
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32: {
            mat_int32_t *ptr = (mat_int32_t *)data_out;
            mat_int32_t *ptr_in = (mat_int32_t *)data_in;
            GET_DATA_LINEAR;
            break;
        }
        case MAT_C_UINT32: {
            mat_uint32_t *ptr = (mat_uint32_t *)data_out;
            mat_uint32_t *ptr_in = (mat_uint32_t *)data_in;
            GET_DATA_LINEAR;
            break;
        }
        case MAT_C_INT16: {
            mat_int16_t *ptr = (mat_int16_t *)data_out;
            mat_int16_t *ptr_in = (mat_int16_t *)data_in;
            GET_DATA_LINEAR;
            break;
        }
        case MAT_C_UINT16: {
            mat_uint16_t *ptr = (mat_uint16_t *)data_out;
            mat_uint16_t *ptr_in = (mat_uint16_t *)data_in;
            GET_DATA_LINEAR;
            break;
        }
        case MAT_C_INT8: {
            mat_int8_t *ptr = (mat_int8_t *)data_out;
            mat_int8_t *ptr_in = (mat_int8_t *)data_in;
            GET_DATA_LINEAR;
            break;
        }
        case MAT_C_UINT8: {
            mat_uint8_t *ptr = (mat_uint8_t *)data_out;
            mat_uint8_t *ptr_in = (mat_uint8_t *)data_in;
            GET_DATA_LINEAR;
            break;
        }
        default:
            err = MATIO_E_OPERATION_NOT_SUPPORTED;
            break;
    }

    return err;
}

#undef GET_DATA_LINEAR
#endif

/** @if mat_devman
 * @brief Reads a slab of data from the mat variable @c matvar
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @param data pointer to store the read data in (must be of size
 *             edge[0]*...edge[rank-1]*Mat_SizeOfClass(matvar->class_type))
 * @param start index to start reading data in each dimension
 * @param stride write data every @c stride elements in each dimension
 * @param edge number of elements to read in each dimension
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarReadData5(mat_t *mat, matvar_t *matvar, void *data, int *start, int *stride, int *edge)
{
    int err = MATIO_E_NO_ERROR, real_bytes = 0;
    mat_int32_t tag[2];
#if HAVE_ZLIB
    z_stream z;
#endif

    (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
    if ( matvar->compression == MAT_COMPRESSION_NONE ) {
        err = Read(tag, 4, 2, (FILE *)mat->fp, NULL);
        if ( err ) {
            return err;
        }
        if ( mat->byteswap ) {
            (void)Mat_int32Swap(tag);
            (void)Mat_int32Swap(tag + 1);
        }
        matvar->data_type = TYPE_FROM_TAG(tag[0]);
        if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
            (void)fseek((FILE *)mat->fp, -4, SEEK_CUR);
            real_bytes = 4 + (tag[0] >> 16);
        } else {
            real_bytes = 8 + tag[1];
        }
#if HAVE_ZLIB
    } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
        if ( NULL != matvar->internal->data ) {
            /* Data already read in ReadNextStructField or ReadNextCell */
            if ( matvar->isComplex ) {
                mat_complex_split_t *ci, *co;

                co = (mat_complex_split_t *)data;
                ci = (mat_complex_split_t *)matvar->internal->data;
                err = GetDataSlab(ci->Re, co->Re, matvar->class_type, matvar->data_type,
                                  matvar->dims, start, stride, edge, matvar->rank, matvar->nbytes);
                if ( MATIO_E_NO_ERROR == err )
                    err = GetDataSlab(ci->Im, co->Im, matvar->class_type, matvar->data_type,
                                      matvar->dims, start, stride, edge, matvar->rank,
                                      matvar->nbytes);
                return err;
            } else {
                return GetDataSlab(matvar->internal->data, data, matvar->class_type,
                                   matvar->data_type, matvar->dims, start, stride, edge,
                                   matvar->rank, matvar->nbytes);
            }
        }

        err = inflateCopy(&z, matvar->internal->z);
        if ( err != Z_OK ) {
            Mat_Critical("inflateCopy returned error %s", zError(err));
            return MATIO_E_FILE_FORMAT_VIOLATION;
        }
        z.avail_in = 0;
        err = Inflate(mat, &z, tag, 4, NULL);
        if ( err ) {
            return err;
        }
        if ( mat->byteswap ) {
            (void)Mat_int32Swap(tag);
        }
        matvar->data_type = TYPE_FROM_TAG(tag[0]);
        if ( !(tag[0] & 0xffff0000) ) { /* Data is NOT packed in the tag */
            err = Inflate(mat, &z, tag + 1, 4, NULL);
            if ( err ) {
                return err;
            }
            if ( mat->byteswap ) {
                (void)Mat_int32Swap(tag + 1);
            }
            real_bytes = 8 + tag[1];
        } else {
            real_bytes = 4 + (tag[0] >> 16);
        }
#endif
    }
    if ( real_bytes % 8 )
        real_bytes += (8 - (real_bytes % 8));

    if ( matvar->rank == 2 ) {
        if ( (size_t)stride[0] * (edge[0] - 1) + start[0] + 1 > matvar->dims[0] )
            err = MATIO_E_BAD_ARGUMENT;
        else if ( (size_t)stride[1] * (edge[1] - 1) + start[1] + 1 > matvar->dims[1] )
            err = MATIO_E_BAD_ARGUMENT;
        else if ( matvar->compression == MAT_COMPRESSION_NONE ) {
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t *)data;

                ReadDataSlab2(mat, complex_data->Re, matvar->class_type, matvar->data_type,
                              matvar->dims, start, stride, edge);
                (void)fseek((FILE *)mat->fp, matvar->internal->datapos + real_bytes, SEEK_SET);
                err = Read(tag, 4, 2, (FILE *)mat->fp, NULL);
                if ( err ) {
                    return err;
                }
                if ( mat->byteswap ) {
                    (void)Mat_int32Swap(tag);
                    (void)Mat_int32Swap(tag + 1);
                }
                matvar->data_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
                    (void)fseek((FILE *)mat->fp, -4, SEEK_CUR);
                }
                ReadDataSlab2(mat, complex_data->Im, matvar->class_type, matvar->data_type,
                              matvar->dims, start, stride, edge);
            } else {
                ReadDataSlab2(mat, data, matvar->class_type, matvar->data_type, matvar->dims, start,
                              stride, edge);
            }
        }
#if HAVE_ZLIB
        else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t *)data;

                ReadCompressedDataSlab2(mat, &z, complex_data->Re, matvar->class_type,
                                        matvar->data_type, matvar->dims, start, stride, edge);

                (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);

                /* Reset zlib knowledge to before reading real tag */
                inflateEnd(&z);
                err = inflateCopy(&z, matvar->internal->z);
                if ( err != Z_OK ) {
                    Mat_Critical("inflateCopy returned error %s", zError(err));
                    return MATIO_E_FILE_FORMAT_VIOLATION;
                }
                InflateSkip(mat, &z, real_bytes, NULL);
                z.avail_in = 0;
                err = Inflate(mat, &z, tag, 4, NULL);
                if ( err ) {
                    return err;
                }
                if ( mat->byteswap ) {
                    (void)Mat_int32Swap(tag);
                }
                matvar->data_type = TYPE_FROM_TAG(tag[0]);
                if ( !(tag[0] & 0xffff0000) ) { /*Data is NOT packed in the tag*/
                    InflateSkip(mat, &z, 4, NULL);
                }
                ReadCompressedDataSlab2(mat, &z, complex_data->Im, matvar->class_type,
                                        matvar->data_type, matvar->dims, start, stride, edge);
            } else {
                ReadCompressedDataSlab2(mat, &z, data, matvar->class_type, matvar->data_type,
                                        matvar->dims, start, stride, edge);
            }
            inflateEnd(&z);
        }
#endif
    } else {
        if ( matvar->compression == MAT_COMPRESSION_NONE ) {
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t *)data;

                ReadDataSlabN(mat, complex_data->Re, matvar->class_type, matvar->data_type,
                              matvar->rank, matvar->dims, start, stride, edge);

                (void)fseek((FILE *)mat->fp, matvar->internal->datapos + real_bytes, SEEK_SET);
                err = Read(tag, 4, 2, (FILE *)mat->fp, NULL);
                if ( err ) {
                    return err;
                }
                if ( mat->byteswap ) {
                    (void)Mat_int32Swap(tag);
                    (void)Mat_int32Swap(tag + 1);
                }
                matvar->data_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
                    (void)fseek((FILE *)mat->fp, -4, SEEK_CUR);
                }
                ReadDataSlabN(mat, complex_data->Im, matvar->class_type, matvar->data_type,
                              matvar->rank, matvar->dims, start, stride, edge);
            } else {
                ReadDataSlabN(mat, data, matvar->class_type, matvar->data_type, matvar->rank,
                              matvar->dims, start, stride, edge);
            }
        }
#if HAVE_ZLIB
        else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t *)data;

                ReadCompressedDataSlabN(mat, &z, complex_data->Re, matvar->class_type,
                                        matvar->data_type, matvar->rank, matvar->dims, start,
                                        stride, edge);

                (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
                /* Reset zlib knowledge to before reading real tag */
                inflateEnd(&z);
                err = inflateCopy(&z, matvar->internal->z);
                if ( err != Z_OK ) {
                    Mat_Critical("inflateCopy returned error %s", zError(err));
                    return MATIO_E_FILE_FORMAT_VIOLATION;
                }
                InflateSkip(mat, &z, real_bytes, NULL);
                z.avail_in = 0;
                err = Inflate(mat, &z, tag, 4, NULL);
                if ( err ) {
                    return err;
                }
                if ( mat->byteswap ) {
                    (void)Mat_int32Swap(tag);
                }
                matvar->data_type = TYPE_FROM_TAG(tag[0]);
                if ( !(tag[0] & 0xffff0000) ) { /*Data is NOT packed in the tag*/
                    InflateSkip(mat, &z, 4, NULL);
                }
                ReadCompressedDataSlabN(mat, &z, complex_data->Im, matvar->class_type,
                                        matvar->data_type, matvar->rank, matvar->dims, start,
                                        stride, edge);
            } else {
                ReadCompressedDataSlabN(mat, &z, data, matvar->class_type, matvar->data_type,
                                        matvar->rank, matvar->dims, start, stride, edge);
            }
            inflateEnd(&z);
        }
#endif
    }
    if ( err == MATIO_E_NO_ERROR ) {
        matvar->data_type = ClassType2DataType(matvar->class_type);
        matvar->data_size = Mat_SizeOfClass(matvar->class_type);
    }
    return err;
}

/** @brief Reads a subset of a MAT variable using a 1-D indexing
 *
 * Reads data from a MAT variable using a linear (1-D) indexing mode. The
 * variable must have been read by Mat_VarReadInfo.
 * @ingroup MAT
 * @param mat MAT file to read data from
 * @param matvar MAT variable information
 * @param data pointer to store data in (must be pre-allocated)
 * @param start starting index
 * @param stride stride of data
 * @param edge number of elements to read
 * @retval 0 on success
 */
static int
Mat_VarReadDataLinear5(mat_t *mat, matvar_t *matvar, void *data, int start, int stride, int edge)
{
    int err = MATIO_E_NO_ERROR, real_bytes = 0;
    mat_int32_t tag[2];
#if HAVE_ZLIB
    z_stream z;
#endif
    size_t nelems = 1;

    if ( mat->version == MAT_FT_MAT4 )
        return -1;
    (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);
    if ( matvar->compression == MAT_COMPRESSION_NONE ) {
        err = Read(tag, 4, 2, (FILE *)mat->fp, NULL);
        if ( err ) {
            return err;
        }
        if ( mat->byteswap ) {
            (void)Mat_int32Swap(tag);
            (void)Mat_int32Swap(tag + 1);
        }
        matvar->data_type = (enum matio_types)(tag[0] & 0x000000ff);
        if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
            (void)fseek((FILE *)mat->fp, -4, SEEK_CUR);
            real_bytes = 4 + (tag[0] >> 16);
        } else {
            real_bytes = 8 + tag[1];
        }
#if HAVE_ZLIB
    } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
        if ( NULL != matvar->internal->data ) {
            /* Data already read in ReadNextStructField or ReadNextCell */
            if ( matvar->isComplex ) {
                mat_complex_split_t *ci, *co;

                co = (mat_complex_split_t *)data;
                ci = (mat_complex_split_t *)matvar->internal->data;
                err = GetDataLinear(ci->Re, co->Re, matvar->class_type, matvar->data_type, start,
                                    stride, edge);
                if ( err == MATIO_E_NO_ERROR )
                    err = GetDataLinear(ci->Im, co->Im, matvar->class_type, matvar->data_type,
                                        start, stride, edge);
                return err;
            } else {
                return GetDataLinear(matvar->internal->data, data, matvar->class_type,
                                     matvar->data_type, start, stride, edge);
            }
        }

        matvar->internal->z->avail_in = 0;
        err = inflateCopy(&z, matvar->internal->z);
        if ( err != Z_OK ) {
            Mat_Critical("inflateCopy returned error %s", zError(err));
            return MATIO_E_FILE_FORMAT_VIOLATION;
        }
        err = Inflate(mat, &z, tag, 4, NULL);
        if ( err ) {
            return err;
        }
        if ( mat->byteswap ) {
            (void)Mat_int32Swap(tag);
            (void)Mat_int32Swap(tag + 1);
        }
        matvar->data_type = (enum matio_types)(tag[0] & 0x000000ff);
        if ( !(tag[0] & 0xffff0000) ) { /* Data is NOT packed in the tag */
            err = Inflate(mat, &z, tag + 1, 4, NULL);
            if ( err ) {
                return err;
            }
            if ( mat->byteswap ) {
                (void)Mat_int32Swap(tag + 1);
            }
            real_bytes = 8 + tag[1];
        } else {
            real_bytes = 4 + (tag[0] >> 16);
        }
#endif
    }
    if ( real_bytes % 8 )
        real_bytes += (8 - (real_bytes % 8));

    err = Mat_MulDims(matvar, &nelems);
    if ( err ) {
        Mat_Critical("Integer multiplication overflow");
        return err;
    }

    if ( (size_t)stride * (edge - 1) + start + 1 > nelems ) {
        err = MATIO_E_BAD_ARGUMENT;
    } else if ( matvar->compression == MAT_COMPRESSION_NONE ) {
        if ( matvar->isComplex ) {
            mat_complex_split_t *complex_data = (mat_complex_split_t *)data;

            ReadDataSlab1(mat, complex_data->Re, matvar->class_type, matvar->data_type, start,
                          stride, edge);
            (void)fseek((FILE *)mat->fp, matvar->internal->datapos + real_bytes, SEEK_SET);
            err = Read(tag, 4, 2, (FILE *)mat->fp, NULL);
            if ( err ) {
                return err;
            }
            if ( mat->byteswap ) {
                (void)Mat_int32Swap(tag);
                (void)Mat_int32Swap(tag + 1);
            }
            matvar->data_type = (enum matio_types)(tag[0] & 0x000000ff);
            if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
                (void)fseek((FILE *)mat->fp, -4, SEEK_CUR);
            }
            ReadDataSlab1(mat, complex_data->Im, matvar->class_type, matvar->data_type, start,
                          stride, edge);
        } else {
            ReadDataSlab1(mat, data, matvar->class_type, matvar->data_type, start, stride, edge);
        }
#if HAVE_ZLIB
    } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
        if ( matvar->isComplex ) {
            mat_complex_split_t *complex_data = (mat_complex_split_t *)data;

            ReadCompressedDataSlab1(mat, &z, complex_data->Re, matvar->class_type,
                                    matvar->data_type, start, stride, edge);

            (void)fseek((FILE *)mat->fp, matvar->internal->datapos, SEEK_SET);

            /* Reset zlib knowledge to before reading real tag */
            inflateEnd(&z);
            err = inflateCopy(&z, matvar->internal->z);
            if ( err != Z_OK ) {
                Mat_Critical("inflateCopy returned error %s", zError(err));
                return MATIO_E_FILE_FORMAT_VIOLATION;
            }
            InflateSkip(mat, &z, real_bytes, NULL);
            z.avail_in = 0;
            err = Inflate(mat, &z, tag, 4, NULL);
            if ( err ) {
                return err;
            }
            if ( mat->byteswap ) {
                (void)Mat_int32Swap(tag);
            }
            matvar->data_type = (enum matio_types)(tag[0] & 0x000000ff);
            if ( !(tag[0] & 0xffff0000) ) { /*Data is NOT packed in the tag*/
                InflateSkip(mat, &z, 4, NULL);
            }
            ReadCompressedDataSlab1(mat, &z, complex_data->Im, matvar->class_type,
                                    matvar->data_type, start, stride, edge);
        } else {
            ReadCompressedDataSlab1(mat, &z, data, matvar->class_type, matvar->data_type, start,
                                    stride, edge);
        }
        inflateEnd(&z);
#endif
    }

    matvar->data_type = ClassType2DataType(matvar->class_type);
    matvar->data_size = Mat_SizeOfClass(matvar->class_type);

    return err;
}

/** @if mat_devman
 * @brief Writes a matlab variable to a version 5 matlab file
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @param compress option to compress the variable
 *                 (only works for numeric types)
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWrite5(mat_t *mat, matvar_t *matvar, int compress)
{
    mat_uint32_t array_flags;
    int array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int array_flags_size = 8, matrix_type = MAT_T_MATRIX;
    const mat_uint32_t pad4 = 0;
    int nBytes, i, nzmax = 0;
    long start = 0, end = 0;

    if ( NULL == mat )
        return MATIO_E_BAD_ARGUMENT;

    /* FIXME: SEEK_END is not Guaranteed by the C standard */
    (void)fseek((FILE *)mat->fp, 0, SEEK_END); /* Always write at end of file */

    if ( NULL == matvar || NULL == matvar->name )
        return MATIO_E_BAD_ARGUMENT;

#if HAVE_ZLIB
    if ( compress == MAT_COMPRESSION_NONE ) {
#else
    {
#endif
        fwrite(&matrix_type, 4, 1, (FILE *)mat->fp);
        fwrite(&pad4, 4, 1, (FILE *)mat->fp);
        start = ftell((FILE *)mat->fp);

        /* Array Flags */
        array_flags = matvar->class_type & CLASS_TYPE_MASK;
        if ( matvar->isComplex )
            array_flags |= MAT_F_COMPLEX;
        if ( matvar->isGlobal )
            array_flags |= MAT_F_GLOBAL;
        if ( matvar->isLogical )
            array_flags |= MAT_F_LOGICAL;
        if ( matvar->class_type == MAT_C_SPARSE )
            nzmax = ((mat_sparse_t *)matvar->data)->nzmax;

        fwrite(&array_flags_type, 4, 1, (FILE *)mat->fp);
        fwrite(&array_flags_size, 4, 1, (FILE *)mat->fp);
        fwrite(&array_flags, 4, 1, (FILE *)mat->fp);
        fwrite(&nzmax, 4, 1, (FILE *)mat->fp);
        /* Rank and Dimension */
        nBytes = matvar->rank * 4;
        fwrite(&dims_array_type, 4, 1, (FILE *)mat->fp);
        fwrite(&nBytes, 4, 1, (FILE *)mat->fp);
        for ( i = 0; i < matvar->rank; i++ ) {
            mat_int32_t dim;
            dim = matvar->dims[i];
            fwrite(&dim, 4, 1, (FILE *)mat->fp);
        }
        if ( matvar->rank % 2 != 0 )
            fwrite(&pad4, 4, 1, (FILE *)mat->fp);
        /* Name of variable */
        if ( strlen(matvar->name) <= 4 ) {
            mat_uint32_t array_name_type = MAT_T_INT8;
            const mat_uint32_t array_name_len = (mat_uint32_t)strlen(matvar->name);
            const mat_uint8_t pad1 = 0;
            array_name_type |= array_name_len << 16;
            fwrite(&array_name_type, 4, 1, (FILE *)mat->fp);
            fwrite(matvar->name, 1, array_name_len, (FILE *)mat->fp);
            for ( i = array_name_len; i < 4; i++ )
                fwrite(&pad1, 1, 1, (FILE *)mat->fp);
        } else {
            const mat_uint32_t array_name_type = MAT_T_INT8;
            const mat_uint32_t array_name_len = (mat_uint32_t)strlen(matvar->name);
            const mat_uint8_t pad1 = 0;

            fwrite(&array_name_type, 4, 1, (FILE *)mat->fp);
            fwrite(&array_name_len, 4, 1, (FILE *)mat->fp);
            fwrite(matvar->name, 1, array_name_len, (FILE *)mat->fp);
            if ( array_name_len % 8 )
                for ( i = array_name_len % 8; i < 8; i++ )
                    fwrite(&pad1, 1, 1, (FILE *)mat->fp);
        }

        if ( NULL != matvar->internal ) {
            matvar->internal->datapos = ftell((FILE *)mat->fp);
            if ( matvar->internal->datapos == -1L ) {
                Mat_Critical("Couldn't determine file position");
                return MATIO_E_GENERIC_READ_ERROR;
            }
        } else {
            /* Must be empty */
            matvar->class_type = MAT_C_EMPTY;
        }
        WriteType(mat, matvar);
#if HAVE_ZLIB
    } else if ( compress == MAT_COMPRESSION_ZLIB ) {
        mat_uint32_t comp_buf[512];
        mat_uint32_t uncomp_buf[512];
        int buf_size = 512, err;
        size_t byteswritten = 0, matrix_max_buf_size;
        z_streamp z;

        z = (z_streamp)calloc(1, sizeof(*z));
        if ( z == NULL )
            return MATIO_E_OUT_OF_MEMORY;
        err = deflateInit(z, Z_DEFAULT_COMPRESSION);
        if ( err != Z_OK ) {
            free(z);
            Mat_Critical("deflateInit returned %s", zError(err));
            return MATIO_E_FILE_FORMAT_VIOLATION;
        }

        matrix_type = MAT_T_COMPRESSED;
        fwrite(&matrix_type, 4, 1, (FILE *)mat->fp);
        fwrite(&pad4, 4, 1, (FILE *)mat->fp);
        start = ftell((FILE *)mat->fp);

        /* Array Flags */
        array_flags = matvar->class_type & CLASS_TYPE_MASK;
        if ( matvar->isComplex )
            array_flags |= MAT_F_COMPLEX;
        if ( matvar->isGlobal )
            array_flags |= MAT_F_GLOBAL;
        if ( matvar->isLogical )
            array_flags |= MAT_F_LOGICAL;
        if ( matvar->class_type == MAT_C_SPARSE )
            nzmax = ((mat_sparse_t *)matvar->data)->nzmax;

        memset(&uncomp_buf, 0, sizeof(uncomp_buf));
        uncomp_buf[0] = MAT_T_MATRIX;
        err = GetMatrixMaxBufSize(matvar, &matrix_max_buf_size);
        if ( err ) {
            free(z);
            return err;
        }
        if ( matrix_max_buf_size > UINT32_MAX ) {
            free(z);
            return MATIO_E_INDEX_TOO_BIG;
        }
        uncomp_buf[1] = matrix_max_buf_size;
        z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
        z->avail_in = 8;
        do {
            z->next_out = ZLIB_BYTE_PTR(comp_buf);
            z->avail_out = buf_size * sizeof(*comp_buf);
            deflate(z, Z_NO_FLUSH);
            byteswritten +=
                fwrite(comp_buf, 1, buf_size * sizeof(*comp_buf) - z->avail_out, (FILE *)mat->fp);
        } while ( z->avail_out == 0 );
        uncomp_buf[0] = array_flags_type;
        uncomp_buf[1] = array_flags_size;
        uncomp_buf[2] = array_flags;
        uncomp_buf[3] = nzmax;
        /* Rank and Dimension */
        nBytes = matvar->rank * 4;
        uncomp_buf[4] = dims_array_type;
        uncomp_buf[5] = nBytes;
        for ( i = 0; i < matvar->rank; i++ ) {
            mat_int32_t dim;
            dim = matvar->dims[i];
            uncomp_buf[6 + i] = dim;
        }
        if ( matvar->rank % 2 != 0 ) {
            uncomp_buf[6 + i] = pad4;
            i++;
        }

        z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
        z->avail_in = (6 + i) * sizeof(*uncomp_buf);
        do {
            z->next_out = ZLIB_BYTE_PTR(comp_buf);
            z->avail_out = buf_size * sizeof(*comp_buf);
            deflate(z, Z_NO_FLUSH);
            byteswritten +=
                fwrite(comp_buf, 1, buf_size * sizeof(*comp_buf) - z->avail_out, (FILE *)mat->fp);
        } while ( z->avail_out == 0 );
        /* Name of variable */
        if ( strlen(matvar->name) <= 4 ) {
            mat_uint32_t array_name_len = (mat_uint32_t)strlen(matvar->name);
            const mat_uint32_t array_name_type = MAT_T_INT8;

            memset(uncomp_buf, 0, 8);
            uncomp_buf[0] = (array_name_len << 16) | array_name_type;
            memcpy(uncomp_buf + 1, matvar->name, array_name_len);
            if ( array_name_len % 4 )
                array_name_len += 4 - (array_name_len % 4);

            z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
            z->avail_in = 8;
            do {
                z->next_out = ZLIB_BYTE_PTR(comp_buf);
                z->avail_out = buf_size * sizeof(*comp_buf);
                deflate(z, Z_NO_FLUSH);
                byteswritten += fwrite(comp_buf, 1, buf_size * sizeof(*comp_buf) - z->avail_out,
                                       (FILE *)mat->fp);
            } while ( z->avail_out == 0 );
        } else {
            mat_uint32_t array_name_len = (mat_uint32_t)strlen(matvar->name);
            const mat_uint32_t array_name_type = MAT_T_INT8;

            memset(uncomp_buf, 0, buf_size * sizeof(*uncomp_buf));
            uncomp_buf[0] = array_name_type;
            uncomp_buf[1] = array_name_len;
            memcpy(uncomp_buf + 2, matvar->name, array_name_len);
            if ( array_name_len % 8 )
                array_name_len += 8 - (array_name_len % 8);
            z->next_in = ZLIB_BYTE_PTR(uncomp_buf);
            z->avail_in = 8 + array_name_len;
            do {
                z->next_out = ZLIB_BYTE_PTR(comp_buf);
                z->avail_out = buf_size * sizeof(*comp_buf);
                deflate(z, Z_NO_FLUSH);
                byteswritten += fwrite(comp_buf, 1, buf_size * sizeof(*comp_buf) - z->avail_out,
                                       (FILE *)mat->fp);
            } while ( z->avail_out == 0 );
        }
        if ( NULL != matvar->internal ) {
            matvar->internal->datapos = ftell((FILE *)mat->fp);
            if ( matvar->internal->datapos == -1L ) {
                free(z);
                Mat_Critical("Couldn't determine file position");
                return MATIO_E_GENERIC_READ_ERROR;
            }
        } else {
            /* Must be empty */
            matvar->class_type = MAT_C_EMPTY;
        }
        WriteCompressedType(mat, matvar, z);
        z->next_in = NULL;
        z->avail_in = 0;
        do {
            z->next_out = ZLIB_BYTE_PTR(comp_buf);
            z->avail_out = buf_size * sizeof(*comp_buf);
            err = deflate(z, Z_FINISH);
            byteswritten +=
                fwrite(comp_buf, 1, buf_size * sizeof(*comp_buf) - z->avail_out, (FILE *)mat->fp);
        } while ( err != Z_STREAM_END && z->avail_out == 0 );
        (void)deflateEnd(z);
        free(z);
#endif
    }
    end = ftell((FILE *)mat->fp);
    if ( start != -1L && end != -1L ) {
        nBytes = (int)(end - start);
        (void)fseek((FILE *)mat->fp, (long)-(nBytes + 4), SEEK_CUR);
        fwrite(&nBytes, 4, 1, (FILE *)mat->fp);
        (void)fseek((FILE *)mat->fp, end, SEEK_SET);
    } else {
        Mat_Critical("Couldn't determine file position");
    }

    return MATIO_E_NO_ERROR;
}

/** @if mat_devman
 * @brief Reads the header information for the next MAT variable
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @return pointer to the MAT variable or NULL
 * @endif
 */
static matvar_t *
Mat_VarReadNextInfo5(mat_t *mat)
{
    int err;
    mat_uint32_t data_type, array_flags, nBytes;
    long fpos;
    matvar_t *matvar = NULL;

    if ( mat == NULL || mat->fp == NULL )
        return NULL;

    if ( IsEndOfFile((FILE *)mat->fp, &fpos) )
        return NULL;

    if ( fpos == -1L )
        return NULL;

    {
        size_t nbytes = 0;
        err = Read(&data_type, sizeof(mat_uint32_t), 1, (FILE *)mat->fp, &nbytes);
        if ( err || 0 == nbytes )
            return NULL;
    }
    err = Read(&nBytes, sizeof(mat_uint32_t), 1, (FILE *)mat->fp, NULL);
    if ( err )
        return NULL;
    if ( mat->byteswap ) {
        (void)Mat_uint32Swap(&data_type);
        (void)Mat_uint32Swap(&nBytes);
    }
    if ( nBytes > INT32_MAX - 8 - (mat_uint32_t)fpos )
        return NULL;
    switch ( data_type ) {
        case MAT_T_COMPRESSED: {
#if HAVE_ZLIB
            mat_uint32_t uncomp_buf[16];
            int nbytes;
            size_t bytesread = 0;

            memset(&uncomp_buf, 0, sizeof(uncomp_buf));
            matvar = Mat_VarCalloc();
            if ( NULL == matvar ) {
                Mat_Critical("Couldn't allocate memory");
                break;
            }

            matvar->compression = MAT_COMPRESSION_ZLIB;
            matvar->internal->z = (z_streamp)calloc(1, sizeof(z_stream));
            err = inflateInit(matvar->internal->z);
            if ( err != Z_OK ) {
                Mat_VarFree(matvar);
                matvar = NULL;
                Mat_Critical("inflateInit returned %s", zError(err));
                break;
            }

            /* Read variable tag */
            err = Inflate(mat, matvar->internal->z, uncomp_buf, 8, &bytesread);
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf + 1);
            }
            nbytes = uncomp_buf[1];
            if ( uncomp_buf[0] != MAT_T_MATRIX ) {
                (void)fseek((FILE *)mat->fp, (long)(nBytes - bytesread), SEEK_CUR);
                Mat_VarFree(matvar);
                matvar = NULL;
                Mat_Critical("Uncompressed type not MAT_T_MATRIX");
                break;
            }
            /* Array flags */
            err = Inflate(mat, matvar->internal->z, uncomp_buf, 16, &bytesread);
            if ( err ) {
                Mat_VarFree(matvar);
                matvar = NULL;
                break;
            }
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf + 2);
                (void)Mat_uint32Swap(uncomp_buf + 3);
            }
            /* Array flags */
            if ( uncomp_buf[0] == MAT_T_UINT32 ) {
                array_flags = uncomp_buf[2];
                matvar->class_type = CLASS_FROM_ARRAY_FLAGS(array_flags);
                matvar->isComplex = (array_flags & MAT_F_COMPLEX);
                matvar->isGlobal = (array_flags & MAT_F_GLOBAL);
                matvar->isLogical = (array_flags & MAT_F_LOGICAL);
                if ( matvar->class_type == MAT_C_SPARSE ) {
                    /* Need to find a more appropriate place to store nzmax */
                    matvar->nbytes = uncomp_buf[3];
                }
            }
            if ( matvar->class_type != MAT_C_OPAQUE ) {
                mat_uint32_t *dims = NULL;
                int do_clean = 0;
                err = InflateRankDims(mat, matvar->internal->z, uncomp_buf, sizeof(uncomp_buf),
                                      &dims, &bytesread);
                if ( NULL == dims ) {
                    dims = uncomp_buf + 2;
                } else {
                    do_clean = 1;
                }
                if ( err ) {
                    if ( do_clean ) {
                        free(dims);
                    }
                    Mat_VarFree(matvar);
                    matvar = NULL;
                    break;
                }
                if ( mat->byteswap ) {
                    (void)Mat_uint32Swap(uncomp_buf);
                    (void)Mat_uint32Swap(uncomp_buf + 1);
                }
                /* Rank and dimension */
                if ( uncomp_buf[0] == MAT_T_INT32 ) {
                    int j;
                    size_t size;
                    nbytes = uncomp_buf[1];
                    matvar->rank = nbytes / 4;
                    if ( 0 == do_clean && matvar->rank > 13 ) {
                        int rank = matvar->rank;
                        matvar->rank = 0;
                        Mat_Critical("%d is not a valid rank", rank);
                        break;
                    }
                    err = Mul(&size, matvar->rank, sizeof(*matvar->dims));
                    if ( err ) {
                        if ( do_clean ) {
                            free(dims);
                        }
                        (void)fseek((FILE *)mat->fp, (long)(nBytes - bytesread), SEEK_CUR);
                        Mat_VarFree(matvar);
                        matvar = NULL;
                        Mat_Critical("Integer multiplication overflow");
                        break;
                    }
                    matvar->dims = (size_t *)malloc(size);
                    if ( NULL == matvar->dims ) {
                        if ( do_clean )
                            free(dims);
                        (void)fseek((FILE *)mat->fp, (long)(nBytes - bytesread), SEEK_CUR);
                        Mat_VarFree(matvar);
                        matvar = NULL;
                        Mat_Critical("Couldn't allocate memory");
                        break;
                    }
                    if ( mat->byteswap ) {
                        for ( j = 0; j < matvar->rank; j++ )
                            matvar->dims[j] = Mat_uint32Swap(dims + j);
                    } else {
                        for ( j = 0; j < matvar->rank; j++ )
                            matvar->dims[j] = dims[j];
                    }
                }
                if ( do_clean ) {
                    free(dims);
                }
                /* Variable name tag */
                err = Inflate(mat, matvar->internal->z, uncomp_buf, 8, &bytesread);
                if ( err ) {
                    Mat_VarFree(matvar);
                    matvar = NULL;
                    break;
                }
                if ( mat->byteswap )
                    (void)Mat_uint32Swap(uncomp_buf);
                /* Name of variable */
                if ( uncomp_buf[0] == MAT_T_INT8 ) { /* Name not in tag */
                    mat_uint32_t len, len_pad;
                    if ( mat->byteswap )
                        len = Mat_uint32Swap(uncomp_buf + 1);
                    else
                        len = uncomp_buf[1];

                    if ( len % 8 == 0 )
                        len_pad = len;
                    else if ( len < UINT32_MAX - 8 + (len % 8) )
                        len_pad = len + 8 - (len % 8);
                    else {
                        Mat_VarFree(matvar);
                        matvar = NULL;
                        break;
                    }
                    matvar->name = (char *)malloc(len_pad + 1);
                    if ( NULL != matvar->name ) {
                        /* Variable name */
                        err = Inflate(mat, matvar->internal->z, matvar->name, len_pad, &bytesread);
                        if ( err ) {
                            Mat_VarFree(matvar);
                            matvar = NULL;
                            break;
                        }
                        matvar->name[len] = '\0';
                    }
                } else {
                    mat_uint32_t len = (uncomp_buf[0] & 0xffff0000) >> 16;
                    if ( ((uncomp_buf[0] & 0x0000ffff) == MAT_T_INT8) && len > 0 && len <= 4 ) {
                        /* Name packed in tag */
                        matvar->name = (char *)malloc(len + 1);
                        if ( NULL != matvar->name ) {
                            memcpy(matvar->name, uncomp_buf + 1, len);
                            matvar->name[len] = '\0';
                        }
                    }
                }
                if ( matvar->class_type == MAT_C_STRUCT )
                    (void)ReadNextStructField(mat, matvar);
                else if ( matvar->class_type == MAT_C_CELL )
                    (void)ReadNextCell(mat, matvar);
                (void)fseek((FILE *)mat->fp, -(int)matvar->internal->z->avail_in, SEEK_CUR);
                matvar->internal->datapos = ftell((FILE *)mat->fp);
                if ( matvar->internal->datapos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                }
            }
            (void)fseek((FILE *)mat->fp, nBytes + 8 + fpos, SEEK_SET);
            break;
#else
            Mat_Critical(
                "Compressed variable found in \"%s\", but matio was "
                "built without zlib support",
                mat->filename);
            (void)fseek((FILE *)mat->fp, nBytes + 8 + fpos, SEEK_SET);
            return NULL;
#endif
        }
        case MAT_T_MATRIX: {
            mat_uint32_t buf[6];

            /* Read array flags and the dimensions tag */
            err = Read(buf, 4, 6, (FILE *)mat->fp, NULL);
            if ( err ) {
                (void)fseek((FILE *)mat->fp, fpos, SEEK_SET);
                break;
            }
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(buf);
                (void)Mat_uint32Swap(buf + 1);
                (void)Mat_uint32Swap(buf + 2);
                (void)Mat_uint32Swap(buf + 3);
                (void)Mat_uint32Swap(buf + 4);
                (void)Mat_uint32Swap(buf + 5);
            }

            matvar = Mat_VarCalloc();
            if ( NULL == matvar ) {
                Mat_Critical("Couldn't allocate memory");
                break;
            }

            /* Array flags */
            if ( buf[0] == MAT_T_UINT32 || buf[0] == MAT_T_INT32 ) { /* Also allow INT32 for SWAN */
                array_flags = buf[2];
                matvar->class_type = CLASS_FROM_ARRAY_FLAGS(array_flags);
                matvar->isComplex = (array_flags & MAT_F_COMPLEX);
                matvar->isGlobal = (array_flags & MAT_F_GLOBAL);
                matvar->isLogical = (array_flags & MAT_F_LOGICAL);
                if ( matvar->class_type == MAT_C_SPARSE ) {
                    /* Need to find a more appropriate place to store nzmax */
                    matvar->nbytes = buf[3];
                }
            }
            /* Rank and dimension */
            {
                size_t nbytes = 0;
                err = ReadRankDims(mat, matvar, (enum matio_types)buf[4], buf[5], &nbytes);
                if ( err ) {
                    Mat_VarFree(matvar);
                    matvar = NULL;
                    (void)fseek((FILE *)mat->fp, fpos, SEEK_SET);
                    break;
                }
            }
            /* Variable name tag */
            err = Read(buf, 4, 2, (FILE *)mat->fp, NULL);
            if ( err ) {
                Mat_VarFree(matvar);
                matvar = NULL;
                (void)fseek((FILE *)mat->fp, fpos, SEEK_SET);
                break;
            }
            if ( mat->byteswap )
                (void)Mat_uint32Swap(buf);
            /* Name of variable */
            if ( buf[0] == MAT_T_INT8 ) { /* Name not in tag */
                mat_uint32_t len, len_pad;
                if ( mat->byteswap )
                    len = Mat_uint32Swap(buf + 1);
                else
                    len = buf[1];
                if ( len % 8 == 0 )
                    len_pad = len;
                else if ( len < UINT32_MAX - 8 + (len % 8) )
                    len_pad = len + 8 - (len % 8);
                else {
                    Mat_VarFree(matvar);
                    matvar = NULL;
                    (void)fseek((FILE *)mat->fp, fpos, SEEK_SET);
                    break;
                }
                matvar->name = (char *)malloc(len_pad + 1);
                if ( NULL != matvar->name ) {
                    err = Read(matvar->name, 1, len_pad, (FILE *)mat->fp, NULL);
                    if ( MATIO_E_NO_ERROR == err ) {
                        matvar->name[len] = '\0';
                    } else {
                        Mat_VarFree(matvar);
                        matvar = NULL;
                        (void)fseek((FILE *)mat->fp, fpos, SEEK_SET);
                        break;
                    }
                }
            } else {
                mat_uint32_t len = (buf[0] & 0xffff0000) >> 16;
                if ( ((buf[0] & 0x0000ffff) == MAT_T_INT8) && len > 0 && len <= 4 ) {
                    /* Name packed in tag */
                    matvar->name = (char *)malloc(len + 1);
                    if ( NULL != matvar->name ) {
                        memcpy(matvar->name, buf + 1, len);
                        matvar->name[len] = '\0';
                    }
                }
            }
            if ( matvar->class_type == MAT_C_STRUCT )
                (void)ReadNextStructField(mat, matvar);
            else if ( matvar->class_type == MAT_C_CELL )
                (void)ReadNextCell(mat, matvar);
            else if ( matvar->class_type == MAT_C_FUNCTION )
                (void)ReadNextFunctionHandle(mat, matvar);
            matvar->internal->datapos = ftell((FILE *)mat->fp);
            if ( matvar->internal->datapos == -1L ) {
                Mat_Critical("Couldn't determine file position");
            }
            (void)fseek((FILE *)mat->fp, nBytes + 8 + fpos, SEEK_SET);
            break;
        }
        default:
            Mat_Critical("%d is not valid (MAT_T_MATRIX or MAT_T_COMPRESSED)", data_type);
            return NULL;
    }

    return matvar;
}

/* -------------------------------
 * ---------- mat73.c
 * -------------------------------
 */
/** @file mat73.c
 * Matlab MAT version 7.3 file functions
 * @ingroup MAT
 */

#if HAVE_HDF5

static const char *ClassNames[] = {"",       "cell",   "struct", "object", "char",    "sparse",
                                   "double", "single", "int8",   "uint8",  "int16",   "uint16",
                                   "int32",  "uint32", "int64",  "uint64", "function"};

struct ReadNextIterData
{
    mat_t *mat;
    matvar_t *matvar;
};

struct ReadGroupInfoIterData
{
    hsize_t nfields;
    matvar_t *matvar;
};

#if H5_VERSION_GE(1, 10, 0)
#define H5RDEREFERENCE(obj_id, ref_type, _ref) \
    H5Rdereference2((obj_id), H5P_DATASET_ACCESS_DEFAULT, (ref_type), (_ref))
#else
#define H5RDEREFERENCE(obj_id, ref_type, _ref) H5Rdereference((obj_id), (ref_type), (_ref))
#endif

#if H5_VERSION_GE(1, 12, 0)
#define H5O_INFO_T H5O_info2_t
#define H5OGET_INFO_BY_NAME(loc_id, name, oinfo, lapl_id) \
    H5Oget_info_by_name3((loc_id), (name), (oinfo), H5O_INFO_BASIC, (lapl_id));
#elif H5_VERSION_GE(1, 10, 3)
#define H5O_INFO_T H5O_info_t
#define H5OGET_INFO_BY_NAME(loc_id, name, oinfo, lapl_id) \
    H5Oget_info_by_name2((loc_id), (name), (oinfo), H5O_INFO_BASIC, (lapl_id));
#else
#define H5O_INFO_T H5O_info_t
#define H5OGET_INFO_BY_NAME(loc_id, name, oinfo, lapl_id) \
    H5Oget_info_by_name((loc_id), (name), (oinfo), (lapl_id));
#endif

#if !defined(MAX_RANK)
/* Maximal number of dimensions for stack allocated temporary dimension arrays */
#define MAX_RANK (3)
#endif

/*===========================================================================
 *  Private functions
 *===========================================================================
 */
static enum matio_classes ClassStr2ClassType(const char *name);
static enum matio_classes DataType2ClassType(enum matio_types type);
static hid_t ClassType2H5T(enum matio_classes class_type);
static hid_t DataType2H5T(enum matio_types data_type);
static hid_t SizeType2H5T(void);
static hid_t DataType(hid_t h5_type, int isComplex);
static void Mat_H5GetChunkSize(size_t rank, hsize_t *dims, hsize_t *chunk_dims);
static int Mat_H5ReadVarInfo(matvar_t *matvar, hid_t dset_id);
static size_t *Mat_H5ReadDims(hid_t dset_id, hsize_t *nelems, int *rank);
static int Mat_H5ReadFieldNames(matvar_t *matvar, hid_t dset_id, hsize_t *nfields);
static int Mat_H5ReadDatasetInfo(mat_t *mat, matvar_t *matvar, hid_t dset_id);
static int Mat_H5ReadGroupInfo(mat_t *mat, matvar_t *matvar, hid_t dset_id);
static int Mat_H5ReadNextReferenceInfo(hid_t ref_id, matvar_t *matvar, mat_t *mat);
static int Mat_H5ReadNextReferenceData(hid_t ref_id, matvar_t *matvar, mat_t *mat);
static int Mat_VarWriteEmpty(hid_t id, matvar_t *matvar, const char *name, const char *class_name);
static int Mat_VarWriteCell73(hid_t id, matvar_t *matvar, const char *name, hid_t *refs_id,
                              hsize_t *dims);
static int Mat_VarWriteChar73(hid_t id, matvar_t *matvar, const char *name, hsize_t *dims);
static int Mat_WriteEmptyVariable73(hid_t id, const char *name, hsize_t rank, size_t *dims);
static int Mat_VarWriteLogical73(hid_t id, matvar_t *matvar, const char *name, hsize_t *dims);
static int Mat_VarWriteNumeric73(hid_t id, matvar_t *matvar, const char *name, hsize_t *dims,
                                 hsize_t *max_dims);
static int Mat_VarWriteAppendNumeric73(hid_t id, matvar_t *matvar, const char *name, hsize_t *dims,
                                       int dim);
static int Mat_VarWriteSparse73(hid_t id, matvar_t *matvar, const char *name);
static int Mat_VarWriteStruct73(hid_t id, matvar_t *matvar, const char *name, hid_t *refs_id,
                                hsize_t *dims, hsize_t *max_dims);
static int Mat_VarWriteAppendStruct73(hid_t id, matvar_t *matvar, const char *name, hid_t *refs_id,
                                      hsize_t *dims, int dim);
static int Mat_VarWriteNext73(hid_t id, matvar_t *matvar, const char *name, hid_t *refs_id);
static int Mat_VarWriteAppendNext73(hid_t id, matvar_t *matvar, const char *name, hid_t *refs_id,
                                    int dim);
static int Mat_VarWriteNextType73(hid_t id, matvar_t *matvar, const char *name, hid_t *refs_id,
                                  hsize_t *dims);
static int Mat_VarWriteAppendNextType73(hid_t id, matvar_t *matvar, const char *name,
                                        hid_t *refs_id, hsize_t *dims, int dim);
static herr_t Mat_VarReadNextInfoIterate(hid_t id, const char *name, const H5L_info_t *info,
                                         void *op_data);
static herr_t Mat_H5ReadGroupInfoIterate(hid_t dset_id, const char *name, const H5L_info_t *info,
                                         void *op_data);
static int Mat_H5ReadData(hid_t dset_id, hid_t h5_type, hid_t mem_space, hid_t dset_space,
                          int isComplex, void *data);
static int Mat_H5WriteData(hid_t dset_id, hid_t h5_type, hid_t mem_space, hid_t dset_space,
                           int isComplex, void *data);
static int Mat_H5WriteAppendData(hid_t id, hid_t h5_type, int mrank, const char *name,
                                 const size_t *mdims, hsize_t *dims, int dim, int isComplex,
                                 void *data);
static int Mat_VarWriteRef(hid_t id, matvar_t *matvar, enum matio_compression compression,
                           hid_t *refs_id, hobj_ref_t *ref);

static enum matio_classes
ClassStr2ClassType(const char *name)
{
    enum matio_classes id = MAT_C_EMPTY;
    if ( NULL != name ) {
        int k;
        for ( k = 1; k < 17; k++ ) {
            if ( 0 == strcmp(name, ClassNames[k]) ) {
                id = (enum matio_classes)k;
                break;
            }
        }
    }

    return id;
}

static enum matio_classes
DataType2ClassType(enum matio_types type)
{
    switch ( type ) {
        case MAT_T_DOUBLE:
            return MAT_C_DOUBLE;
        case MAT_T_SINGLE:
            return MAT_C_SINGLE;
#ifdef HAVE_MATIO_INT64_T
        case MAT_T_INT64:
            return MAT_C_INT64;
#endif
#ifdef HAVE_MATIO_UINT64_T
        case MAT_T_UINT64:
            return MAT_C_UINT64;
#endif
        case MAT_T_INT32:
            return MAT_C_INT32;
        case MAT_T_UINT32:
            return MAT_C_UINT32;
        case MAT_T_INT16:
            return MAT_C_INT16;
        case MAT_T_UINT16:
            return MAT_C_UINT16;
        case MAT_T_INT8:
            return MAT_C_INT8;
        case MAT_T_UINT8:
            return MAT_C_UINT8;
        default:
            return MAT_C_EMPTY;
    }
}

static hid_t
ClassType2H5T(enum matio_classes class_type)
{
    switch ( class_type ) {
        case MAT_C_DOUBLE:
            return H5T_NATIVE_DOUBLE;
        case MAT_C_SINGLE:
            return H5T_NATIVE_FLOAT;
        case MAT_C_INT64:
            if ( CHAR_BIT * sizeof(long long) == 64 )
                return H5T_NATIVE_LLONG;
            else if ( CHAR_BIT * sizeof(long) == 64 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT * sizeof(int) == 64 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT * sizeof(short) == 64 )
                return H5T_NATIVE_SHORT;
            else
                return -1;
        case MAT_C_UINT64:
            if ( CHAR_BIT * sizeof(long long) == 64 )
                return H5T_NATIVE_ULLONG;
            else if ( CHAR_BIT * sizeof(long) == 64 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT * sizeof(int) == 64 )
                return H5T_NATIVE_UINT;
            if ( CHAR_BIT * sizeof(short) == 64 )
                return H5T_NATIVE_USHORT;
            else
                return -1;
        case MAT_C_INT32:
            if ( CHAR_BIT * sizeof(int) == 32 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT * sizeof(short) == 32 )
                return H5T_NATIVE_SHORT;
            else if ( CHAR_BIT * sizeof(long) == 32 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT * sizeof(long long) == 32 )
                return H5T_NATIVE_LLONG;
            else if ( CHAR_BIT == 32 )
                return H5T_NATIVE_SCHAR;
            else
                return -1;
        case MAT_C_UINT32:
            if ( CHAR_BIT * sizeof(int) == 32 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT * sizeof(short) == 32 )
                return H5T_NATIVE_USHORT;
            else if ( CHAR_BIT * sizeof(long) == 32 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT * sizeof(long long) == 32 )
                return H5T_NATIVE_ULLONG;
            else if ( CHAR_BIT == 32 )
                return H5T_NATIVE_UCHAR;
            else
                return -1;
        case MAT_C_INT16:
            if ( CHAR_BIT * sizeof(short) == 16 )
                return H5T_NATIVE_SHORT;
            else if ( CHAR_BIT * sizeof(int) == 16 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT * sizeof(long) == 16 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT * sizeof(long long) == 16 )
                return H5T_NATIVE_LLONG;
            else if ( CHAR_BIT == 16 )
                return H5T_NATIVE_SCHAR;
            else
                return -1;
        case MAT_C_UINT16:
            if ( CHAR_BIT * sizeof(short) == 16 )
                return H5T_NATIVE_USHORT;
            else if ( CHAR_BIT * sizeof(int) == 16 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT * sizeof(long) == 16 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT * sizeof(long long) == 16 )
                return H5T_NATIVE_ULLONG;
            else if ( CHAR_BIT == 16 )
                return H5T_NATIVE_UCHAR;
            else
                return -1;
        case MAT_C_INT8:
            if ( CHAR_BIT == 8 )
                return H5T_NATIVE_SCHAR;
            else if ( CHAR_BIT * sizeof(short) == 8 )
                return H5T_NATIVE_SHORT;
            else if ( CHAR_BIT * sizeof(int) == 8 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT * sizeof(long) == 8 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT * sizeof(long long) == 8 )
                return H5T_NATIVE_LLONG;
            else
                return -1;
        case MAT_C_UINT8:
            if ( CHAR_BIT == 8 )
                return H5T_NATIVE_UCHAR;
            else if ( CHAR_BIT * sizeof(short) == 8 )
                return H5T_NATIVE_USHORT;
            else if ( CHAR_BIT * sizeof(int) == 8 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT * sizeof(long) == 8 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT * sizeof(long long) == 8 )
                return H5T_NATIVE_ULLONG;
            else
                return -1;
        default:
            return -1;
    }
}

static hid_t
DataType2H5T(enum matio_types data_type)
{
    switch ( data_type ) {
        case MAT_T_DOUBLE:
            return H5T_NATIVE_DOUBLE;
        case MAT_T_SINGLE:
            return H5T_NATIVE_FLOAT;
        case MAT_T_INT64:
            if ( CHAR_BIT * sizeof(long long) == 64 )
                return H5T_NATIVE_LLONG;
            else if ( CHAR_BIT * sizeof(long) == 64 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT * sizeof(int) == 64 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT * sizeof(short) == 64 )
                return H5T_NATIVE_SHORT;
            else
                return -1;
        case MAT_T_UINT64:
            if ( CHAR_BIT * sizeof(long long) == 64 )
                return H5T_NATIVE_ULLONG;
            else if ( CHAR_BIT * sizeof(long) == 64 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT * sizeof(int) == 64 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT * sizeof(short) == 64 )
                return H5T_NATIVE_USHORT;
            else
                return -1;
        case MAT_T_INT32:
            if ( CHAR_BIT * sizeof(int) == 32 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT * sizeof(short) == 32 )
                return H5T_NATIVE_SHORT;
            else if ( CHAR_BIT * sizeof(long) == 32 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT * sizeof(long long) == 32 )
                return H5T_NATIVE_LLONG;
            else if ( CHAR_BIT == 32 )
                return H5T_NATIVE_SCHAR;
            else
                return -1;
        case MAT_T_UINT32:
            if ( CHAR_BIT * sizeof(int) == 32 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT * sizeof(short) == 32 )
                return H5T_NATIVE_USHORT;
            else if ( CHAR_BIT * sizeof(long) == 32 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT * sizeof(long long) == 32 )
                return H5T_NATIVE_ULLONG;
            else if ( CHAR_BIT == 32 )
                return H5T_NATIVE_UCHAR;
            else
                return -1;
        case MAT_T_INT16:
            if ( CHAR_BIT * sizeof(short) == 16 )
                return H5T_NATIVE_SHORT;
            else if ( CHAR_BIT * sizeof(int) == 16 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT * sizeof(long) == 16 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT * sizeof(long long) == 16 )
                return H5T_NATIVE_LLONG;
            else if ( CHAR_BIT == 16 )
                return H5T_NATIVE_SCHAR;
            else
                return -1;
        case MAT_T_UINT16:
            if ( CHAR_BIT * sizeof(short) == 16 )
                return H5T_NATIVE_USHORT;
            else if ( CHAR_BIT * sizeof(int) == 16 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT * sizeof(long) == 16 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT * sizeof(long long) == 16 )
                return H5T_NATIVE_ULLONG;
            else if ( CHAR_BIT == 16 )
                return H5T_NATIVE_UCHAR;
            else
                return -1;
        case MAT_T_INT8:
            if ( CHAR_BIT == 8 )
                return H5T_NATIVE_SCHAR;
            else if ( CHAR_BIT * sizeof(short) == 8 )
                return H5T_NATIVE_SHORT;
            else if ( CHAR_BIT * sizeof(int) == 8 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT * sizeof(long) == 8 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT * sizeof(long long) == 8 )
                return H5T_NATIVE_LLONG;
            else
                return -1;
        case MAT_T_UINT8:
            if ( CHAR_BIT == 8 )
                return H5T_NATIVE_UCHAR;
            else if ( CHAR_BIT * sizeof(short) == 8 )
                return H5T_NATIVE_USHORT;
            else if ( CHAR_BIT * sizeof(int) == 8 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT * sizeof(long) == 8 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT * sizeof(long long) == 8 )
                return H5T_NATIVE_ULLONG;
            else
                return -1;
        case MAT_T_UTF8:
            return H5T_NATIVE_CHAR;
        default:
            return -1;
    }
}

static hid_t
SizeType2H5T(void)
{
    if ( sizeof(size_t) == H5Tget_size(H5T_NATIVE_HSIZE) )
        return H5T_NATIVE_HSIZE;
    else if ( sizeof(size_t) == H5Tget_size(H5T_NATIVE_ULLONG) )
        return H5T_NATIVE_ULLONG;
    else if ( sizeof(size_t) == H5Tget_size(H5T_NATIVE_ULONG) )
        return H5T_NATIVE_ULONG;
    else if ( sizeof(size_t) == H5Tget_size(H5T_NATIVE_UINT) )
        return H5T_NATIVE_UINT;
    else if ( sizeof(size_t) == H5Tget_size(H5T_NATIVE_USHORT) )
        return H5T_NATIVE_USHORT;
    else
        return -1;
}

static hid_t
DataType(hid_t h5_type, int isComplex)
{
    hid_t h5_dtype;
    if ( isComplex ) {
        size_t h5_size = H5Tget_size(h5_type);
        h5_dtype = H5Tcreate(H5T_COMPOUND, 2 * h5_size);
        H5Tinsert(h5_dtype, "real", 0, h5_type);
        H5Tinsert(h5_dtype, "imag", h5_size, h5_type);
    } else {
        h5_dtype = H5Tcopy(h5_type);
    }
    return h5_dtype;
}

static void
Mat_H5GetChunkSize(size_t rank, hsize_t *dims, hsize_t *chunk_dims)
{
    hsize_t i, j, chunk_size = 1;

    for ( i = 0; i < rank; i++ ) {
        chunk_dims[i] = 1;
        for ( j = 4096 / chunk_size; j > 1; j >>= 1 ) {
            if ( dims[i] >= j ) {
                chunk_dims[i] = j;
                break;
            }
        }
        chunk_size *= chunk_dims[i];
    }
}

static int
Mat_H5ReadVarInfo(matvar_t *matvar, hid_t dset_id)
{
    hid_t attr_id, type_id;
    ssize_t name_len;
    int err = MATIO_E_NO_ERROR;

    /* Get the HDF5 name of the variable */
    name_len = H5Iget_name(dset_id, NULL, 0);
    if ( name_len > 0 ) {
        matvar->internal->hdf5_name = (char *)malloc(name_len + 1);
        (void)H5Iget_name(dset_id, matvar->internal->hdf5_name, name_len + 1);
    } else {
        /* Can not get an internal name, so leave the identifier open */
        matvar->internal->id = dset_id;
    }

    attr_id = H5Aopen_by_name(dset_id, ".", "MATLAB_class", H5P_DEFAULT, H5P_DEFAULT);
    type_id = H5Aget_type(attr_id);
    if ( H5T_STRING == H5Tget_class(type_id) ) {
        char *class_str = (char *)calloc(H5Tget_size(type_id) + 1, 1);
        if ( NULL != class_str ) {
            herr_t herr;
            hid_t class_id = H5Tcopy(H5T_C_S1);
            H5Tset_size(class_id, H5Tget_size(type_id));
            herr = H5Aread(attr_id, class_id, class_str);
            H5Tclose(class_id);
            if ( herr < 0 ) {
                free(class_str);
                H5Tclose(type_id);
                H5Aclose(attr_id);
                return MATIO_E_GENERIC_READ_ERROR;
            }
            matvar->class_type = ClassStr2ClassType(class_str);
            if ( MAT_C_EMPTY == matvar->class_type || MAT_C_CHAR == matvar->class_type ) {
                int int_decode = 0;
                if ( H5Aexists_by_name(dset_id, ".", "MATLAB_int_decode", H5P_DEFAULT) ) {
                    hid_t attr_id2 = H5Aopen_by_name(dset_id, ".", "MATLAB_int_decode", H5P_DEFAULT,
                                                     H5P_DEFAULT);
                    /* FIXME: Check that dataspace is scalar */
                    herr = H5Aread(attr_id2, H5T_NATIVE_INT, &int_decode);
                    H5Aclose(attr_id2);
                    if ( herr < 0 ) {
                        free(class_str);
                        H5Tclose(type_id);
                        H5Aclose(attr_id);
                        return MATIO_E_GENERIC_READ_ERROR;
                    }
                }
                switch ( int_decode ) {
                    case 2:
                        matvar->data_type = MAT_T_UINT16;
                        break;
                    case 1:
                        matvar->data_type = MAT_T_UINT8;
                        break;
                    case 4:
                        matvar->data_type = MAT_T_UINT32;
                        break;
                    default:
                        matvar->data_type = MAT_T_UNKNOWN;
                        break;
                }
                if ( MAT_C_EMPTY == matvar->class_type ) {
                    /* Check if this is a logical variable */
                    if ( 0 == strcmp(class_str, "logical") ) {
                        matvar->isLogical = MAT_F_LOGICAL;
                    }
                    matvar->class_type = DataType2ClassType(matvar->data_type);
                } else if ( MAT_T_UNKNOWN == matvar->data_type ) {
                    matvar->data_type = MAT_T_UINT16;
                }
            } else {
                matvar->data_type = ClassType2DataType(matvar->class_type);
            }
            free(class_str);
        } else {
            err = MATIO_E_OUT_OF_MEMORY;
        }
    }
    H5Tclose(type_id);
    H5Aclose(attr_id);

    if ( err ) {
        return err;
    }

    /* Check if the variable is global */
    if ( H5Aexists_by_name(dset_id, ".", "MATLAB_global", H5P_DEFAULT) ) {
        herr_t herr;
        attr_id = H5Aopen_by_name(dset_id, ".", "MATLAB_global", H5P_DEFAULT, H5P_DEFAULT);
        /* FIXME: Check that dataspace is scalar */
        herr = H5Aread(attr_id, H5T_NATIVE_INT, &matvar->isGlobal);
        H5Aclose(attr_id);
        if ( herr < 0 ) {
            return MATIO_E_GENERIC_READ_ERROR;
        }
    }

    return err;
}

static size_t *
Mat_H5ReadDims(hid_t dset_id, hsize_t *nelems, int *rank)
{
    hid_t space_id;
    size_t *perm_dims;

    *nelems = 0;
    space_id = H5Dget_space(dset_id);
    *rank = H5Sget_simple_extent_ndims(space_id);
    if ( 0 > *rank ) {
        *rank = 0;
        H5Sclose(space_id);
        return NULL;
    }
    perm_dims = (size_t *)malloc(*rank * sizeof(*perm_dims));
    if ( NULL != perm_dims ) {
        int err = 0;
        if ( MAX_RANK >= *rank ) {
            hsize_t dims[MAX_RANK];
            int k;
            size_t tmp = 1;
            (void)H5Sget_simple_extent_dims(space_id, dims, NULL);
            /* Permute dimensions */
            for ( k = 0; k < *rank; k++ ) {
                perm_dims[k] = (size_t)dims[*rank - k - 1];
                err |= Mul(&tmp, tmp, perm_dims[k]);
            }
            if ( err ) {
                Mat_Critical("Integer multiplication overflow");
                free(perm_dims);
                perm_dims = NULL;
                *rank = 0;
            }
            *nelems = (hsize_t)tmp;
            H5Sclose(space_id);
        } else {
            hsize_t *dims = (hsize_t *)malloc(*rank * sizeof(hsize_t));
            if ( NULL != dims ) {
                int k;
                size_t tmp = 1;
                (void)H5Sget_simple_extent_dims(space_id, dims, NULL);
                /* Permute dimensions */
                for ( k = 0; k < *rank; k++ ) {
                    perm_dims[k] = (size_t)dims[*rank - k - 1];
                    err |= Mul(&tmp, tmp, perm_dims[k]);
                }
                if ( err ) {
                    Mat_Critical("Integer multiplication overflow");
                    free(perm_dims);
                    perm_dims = NULL;
                    *rank = 0;
                }
                *nelems = (hsize_t)tmp;
                free(dims);
                H5Sclose(space_id);
            } else {
                free(perm_dims);
                perm_dims = NULL;
                *rank = 0;
                H5Sclose(space_id);
                Mat_Critical("Error allocating memory for dims");
            }
        }
    } else {
        *rank = 0;
        H5Sclose(space_id);
        Mat_Critical("Error allocating memory for matvar->dims");
    }

    return perm_dims;
}

static int
Mat_H5ReadFieldNames(matvar_t *matvar, hid_t dset_id, hsize_t *nfields)
{
    hsize_t i;
    hid_t field_id, attr_id, space_id;
    hvl_t *fieldnames_vl;
    herr_t herr;
    int err;

    attr_id = H5Aopen_by_name(dset_id, ".", "MATLAB_fields", H5P_DEFAULT, H5P_DEFAULT);
    space_id = H5Aget_space(attr_id);
    err = H5Sget_simple_extent_dims(space_id, nfields, NULL);
    if ( err < 0 ) {
        H5Sclose(space_id);
        H5Aclose(attr_id);
        return MATIO_E_GENERIC_READ_ERROR;
    } else {
        err = MATIO_E_NO_ERROR;
    }
    fieldnames_vl = (hvl_t *)calloc((size_t)(*nfields), sizeof(*fieldnames_vl));
    if ( fieldnames_vl == NULL ) {
        H5Sclose(space_id);
        H5Aclose(attr_id);
        return MATIO_E_OUT_OF_MEMORY;
    }
    field_id = H5Aget_type(attr_id);
    herr = H5Aread(attr_id, field_id, fieldnames_vl);
    if ( herr >= 0 ) {
        matvar->internal->num_fields = (unsigned int)*nfields;
        matvar->internal->fieldnames =
            (char **)calloc((size_t)(*nfields), sizeof(*matvar->internal->fieldnames));
        if ( matvar->internal->fieldnames != NULL ) {
            for ( i = 0; i < *nfields; i++ ) {
                matvar->internal->fieldnames[i] = (char *)calloc(fieldnames_vl[i].len + 1, 1);
                if ( matvar->internal->fieldnames[i] != NULL ) {
                    if ( fieldnames_vl[i].p != NULL ) {
                        memcpy(matvar->internal->fieldnames[i], fieldnames_vl[i].p,
                               fieldnames_vl[i].len);
                    }
                } else {
                    err = MATIO_E_OUT_OF_MEMORY;
                    break;
                }
            }
        } else {
            err = MATIO_E_OUT_OF_MEMORY;
        }
#if H5_VERSION_GE(1, 12, 0)
        H5Treclaim(field_id, space_id, H5P_DEFAULT, fieldnames_vl);
#else
        H5Dvlen_reclaim(field_id, space_id, H5P_DEFAULT, fieldnames_vl);
#endif
    } else {
        err = MATIO_E_GENERIC_READ_ERROR;
    }

    H5Sclose(space_id);
    H5Tclose(field_id);
    H5Aclose(attr_id);
    free(fieldnames_vl);

    return err;
}

static int
Mat_H5ReadDatasetInfo(mat_t *mat, matvar_t *matvar, hid_t dset_id)
{
    int err;
    hsize_t nelems;

    err = Mat_H5ReadVarInfo(matvar, dset_id);
    if ( err ) {
        return err;
    }

    matvar->dims = Mat_H5ReadDims(dset_id, &nelems, &matvar->rank);
    if ( NULL == matvar->dims ) {
        return MATIO_E_UNKNOWN_ERROR;
    }

    /* Check for attribute that indicates an empty array */
    if ( H5Aexists_by_name(dset_id, ".", "MATLAB_empty", H5P_DEFAULT) ) {
        int empty = 0;
        herr_t herr;
        hid_t attr_id = H5Aopen_by_name(dset_id, ".", "MATLAB_empty", H5P_DEFAULT, H5P_DEFAULT);
        /* FIXME: Check that dataspace is scalar */
        herr = H5Aread(attr_id, H5T_NATIVE_INT, &empty);
        H5Aclose(attr_id);
        if ( herr < 0 ) {
            err = MATIO_E_GENERIC_READ_ERROR;
        } else if ( empty ) {
            matvar->rank = (int)matvar->dims[0];
            free(matvar->dims);
            matvar->dims = (size_t *)calloc(matvar->rank, sizeof(*matvar->dims));
            if ( matvar->dims == NULL ) {
                err = MATIO_E_OUT_OF_MEMORY;
            } else {
                herr =
                    H5Dread(dset_id, SizeType2H5T(), H5S_ALL, H5S_ALL, H5P_DEFAULT, matvar->dims);
                if ( herr < 0 ) {
                    err = MATIO_E_GENERIC_READ_ERROR;
                } else {
                    size_t tmp = 1;
                    err = Mat_MulDims(matvar, &tmp);
                    nelems = (hsize_t)tmp;
                }
            }
        }
        if ( err ) {
            return err;
        }
    }

    /* Test if dataset type is compound and if so if it's complex */
    {
        hid_t type_id = H5Dget_type(dset_id);
        if ( H5T_COMPOUND == H5Tget_class(type_id) ) {
            /* FIXME: Any more checks? */
            matvar->isComplex = MAT_F_COMPLEX;
        }
        H5Tclose(type_id);
    }

    /* Test if dataset is deflated */
    {
        hid_t plist_id = H5Dget_create_plist(dset_id);
        if ( plist_id > 0 ) {
            const int nFilters = H5Pget_nfilters(plist_id);
            int i;
            for ( i = 0; i < nFilters; i++ ) {
                const H5Z_filter_t filterType =
                    H5Pget_filter2(plist_id, i, NULL, NULL, 0, 0, NULL, NULL);
                if ( H5Z_FILTER_DEFLATE == filterType ) {
                    matvar->compression = MAT_COMPRESSION_ZLIB;
                    break;
                }
            }
            H5Pclose(plist_id);
        }
    }

    /* If the dataset is a cell array read the info of the cells */
    if ( MAT_C_CELL == matvar->class_type ) {
        matvar_t **cells;

        matvar->data_size = sizeof(matvar_t **);
        err = Mul(&matvar->nbytes, nelems, matvar->data_size);
        if ( err ) {
            Mat_Critical("Integer multiplication overflow");
            return err;
        }
        matvar->data = calloc(matvar->nbytes, 1);
        if ( NULL == matvar->data ) {
            Mat_Critical("Couldn't allocate memory for the data");
            return MATIO_E_OUT_OF_MEMORY;
        }
        cells = (matvar_t **)matvar->data;

        if ( nelems ) {
            hobj_ref_t *ref_ids = (hobj_ref_t *)calloc(nelems, sizeof(*ref_ids));
            if ( ref_ids != NULL ) {
                size_t i;
                herr_t herr =
                    H5Dread(dset_id, H5T_STD_REF_OBJ, H5S_ALL, H5S_ALL, H5P_DEFAULT, ref_ids);
                if ( herr < 0 ) {
                    free(ref_ids);
                    return MATIO_E_GENERIC_READ_ERROR;
                }
                for ( i = 0; i < nelems; i++ ) {
                    hid_t ref_id;
                    cells[i] = Mat_VarCalloc();
                    cells[i]->internal->hdf5_ref = ref_ids[i];
                    /* Closing of ref_id is done in Mat_H5ReadNextReferenceInfo */
                    ref_id = H5RDEREFERENCE(dset_id, H5R_OBJECT, ref_ids + i);
                    if ( ref_id < 0 ) {
                        err = MATIO_E_GENERIC_READ_ERROR;
                    } else {
                        cells[i]->internal->id = ref_id;
                        err = Mat_H5ReadNextReferenceInfo(ref_id, cells[i], mat);
                    }
                    if ( err ) {
                        break;
                    }
                }
                free(ref_ids);
            } else {
                err = MATIO_E_OUT_OF_MEMORY;
            }
        }
    } else if ( MAT_C_STRUCT == matvar->class_type ) {
        /* Empty structures can be a dataset */

        /* Check if the structure defines its fields in MATLAB_fields */
        if ( H5Aexists_by_name(dset_id, ".", "MATLAB_fields", H5P_DEFAULT) ) {
            hsize_t nfields;
            err = Mat_H5ReadFieldNames(matvar, dset_id, &nfields);
        }
    }

    return err;
}

static int
Mat_H5ReadGroupInfo(mat_t *mat, matvar_t *matvar, hid_t dset_id)
{
    int fields_are_variables = 1;
    hsize_t nfields = 0, nelems;
    hid_t attr_id, field_id;
    matvar_t **fields;
    H5O_type_t obj_type;
    int err;

    err = Mat_H5ReadVarInfo(matvar, dset_id);
    if ( err < 0 ) {
        return err;
    }

    /* Check if the variable is sparse */
    if ( H5Aexists_by_name(dset_id, ".", "MATLAB_sparse", H5P_DEFAULT) ) {
        herr_t herr;
        hid_t sparse_dset_id;
        unsigned nrows = 0;

        attr_id = H5Aopen_by_name(dset_id, ".", "MATLAB_sparse", H5P_DEFAULT, H5P_DEFAULT);
        herr = H5Aread(attr_id, H5T_NATIVE_UINT, &nrows);
        H5Aclose(attr_id);
        if ( herr < 0 ) {
            return MATIO_E_GENERIC_READ_ERROR;
        }

        matvar->class_type = MAT_C_SPARSE;

        sparse_dset_id = H5Dopen(dset_id, "jc", H5P_DEFAULT);
        matvar->dims = Mat_H5ReadDims(sparse_dset_id, &nelems, &matvar->rank);
        H5Dclose(sparse_dset_id);
        if ( NULL != matvar->dims ) {
            if ( 1 == matvar->rank ) {
                size_t *dims = (size_t *)realloc(matvar->dims, 2 * sizeof(*matvar->dims));
                if ( NULL != dims ) {
                    matvar->rank = 2;
                    matvar->dims = dims;
                }
            }
            if ( 2 == matvar->rank ) {
                matvar->dims[1] = matvar->dims[0] - 1;
                matvar->dims[0] = nrows;
            }
        } else {
            return MATIO_E_UNKNOWN_ERROR;
        }

        /* Test if dataset type is compound and if so if it's complex */
        if ( H5Lexists(dset_id, "data", H5P_DEFAULT) ) {
            hid_t type_id;
            sparse_dset_id = H5Dopen(dset_id, "data", H5P_DEFAULT);
            type_id = H5Dget_type(sparse_dset_id);
            if ( H5T_COMPOUND == H5Tget_class(type_id) ) {
                /* FIXME: Any more checks? */
                matvar->isComplex = MAT_F_COMPLEX;
            }
            H5Tclose(type_id);
            H5Dclose(sparse_dset_id);
        }
        return MATIO_E_NO_ERROR;
    }

    if ( MAT_C_STRUCT != matvar->class_type ) {
        return MATIO_E_GENERIC_READ_ERROR;
    }

    /* Check if the structure defines its fields in MATLAB_fields */
    if ( H5Aexists_by_name(dset_id, ".", "MATLAB_fields", H5P_DEFAULT) ) {
        err = Mat_H5ReadFieldNames(matvar, dset_id, &nfields);
        if ( err ) {
            return err;
        }
    } else {
        herr_t herr;
        H5G_info_t group_info;
        matvar->internal->num_fields = 0;
        group_info.nlinks = 0;
        herr = H5Gget_info(dset_id, &group_info);
        if ( herr >= 0 && group_info.nlinks > 0 ) {
            struct ReadGroupInfoIterData group_data = {0, NULL};

            /* First iteration to retrieve number of relevant links */
            herr = H5Literate_by_name(dset_id, matvar->internal->hdf5_name, H5_INDEX_NAME,
                                      H5_ITER_NATIVE, NULL, Mat_H5ReadGroupInfoIterate,
                                      (void *)&group_data, H5P_DEFAULT);
            if ( herr > 0 && group_data.nfields > 0 ) {
                matvar->internal->fieldnames = (char **)calloc(
                    (size_t)(group_data.nfields), sizeof(*matvar->internal->fieldnames));
                group_data.nfields = 0;
                group_data.matvar = matvar;
                if ( matvar->internal->fieldnames != NULL ) {
                    /* Second iteration to fill fieldnames */
                    H5Literate_by_name(dset_id, matvar->internal->hdf5_name, H5_INDEX_NAME,
                                       H5_ITER_NATIVE, NULL, Mat_H5ReadGroupInfoIterate,
                                       (void *)&group_data, H5P_DEFAULT);
                }
                matvar->internal->num_fields = (unsigned)group_data.nfields;
                nfields = group_data.nfields;
            }
        }
    }

    if ( nfields > 0 ) {
        H5O_INFO_T object_info;
        object_info.type = H5O_TYPE_UNKNOWN;
        H5OGET_INFO_BY_NAME(dset_id, matvar->internal->fieldnames[0], &object_info, H5P_DEFAULT);
        obj_type = object_info.type;
    } else {
        obj_type = H5O_TYPE_UNKNOWN;
    }
    if ( obj_type == H5O_TYPE_DATASET ) {
        hid_t field_type_id;
        field_id = H5Dopen(dset_id, matvar->internal->fieldnames[0], H5P_DEFAULT);
        field_type_id = H5Dget_type(field_id);
        if ( H5T_REFERENCE == H5Tget_class(field_type_id) ) {
            /* Check if the field has the MATLAB_class attribute. If so, it
             * means the structure is a scalar. Otherwise, the dimensions of
             * the field dataset is the dimensions of the structure
             */
            if ( H5Aexists_by_name(field_id, ".", "MATLAB_class", H5P_DEFAULT) ) {
                matvar->rank = 2;
                matvar->dims = (size_t *)malloc(2 * sizeof(*matvar->dims));
                if ( NULL != matvar->dims ) {
                    matvar->dims[0] = 1;
                    matvar->dims[1] = 1;
                    nelems = 1;
                } else {
                    H5Tclose(field_type_id);
                    H5Dclose(field_id);
                    Mat_Critical("Error allocating memory for matvar->dims");
                    return MATIO_E_OUT_OF_MEMORY;
                }
            } else {
                matvar->dims = Mat_H5ReadDims(field_id, &nelems, &matvar->rank);
                if ( NULL != matvar->dims ) {
                    fields_are_variables = 0;
                } else {
                    H5Tclose(field_type_id);
                    H5Dclose(field_id);
                    return MATIO_E_UNKNOWN_ERROR;
                }
            }
        } else {
            /* Structure should be a scalar */
            matvar->rank = 2;
            matvar->dims = (size_t *)malloc(2 * sizeof(*matvar->dims));
            if ( NULL != matvar->dims ) {
                matvar->dims[0] = 1;
                matvar->dims[1] = 1;
                nelems = 1;
            } else {
                H5Tclose(field_type_id);
                H5Dclose(field_id);
                Mat_Critical("Error allocating memory for matvar->dims");
                return MATIO_E_UNKNOWN_ERROR;
            }
        }
        H5Tclose(field_type_id);
        H5Dclose(field_id);
    } else {
        /* Structure should be a scalar */
        matvar->rank = 2;
        matvar->dims = (size_t *)malloc(2 * sizeof(*matvar->dims));
        if ( NULL != matvar->dims ) {
            matvar->dims[0] = 1;
            matvar->dims[1] = 1;
            nelems = 1;
        } else {
            Mat_Critical("Error allocating memory for matvar->dims");
            return MATIO_E_OUT_OF_MEMORY;
        }
    }

    if ( nelems < 1 || nfields < 1 )
        return err;

    matvar->data_size = sizeof(*fields);
    {
        size_t nelems_x_nfields;
        err = Mul(&nelems_x_nfields, nelems, nfields);
        err |= Mul(&matvar->nbytes, nelems_x_nfields, matvar->data_size);
        if ( err ) {
            Mat_Critical("Integer multiplication overflow");
            matvar->nbytes = 0;
            return err;
        }
    }
    fields = (matvar_t **)calloc(matvar->nbytes, 1);
    matvar->data = fields;
    if ( NULL != fields ) {
        hsize_t k;
        for ( k = 0; k < nfields; k++ ) {
            H5O_INFO_T object_info;
            fields[k] = NULL;
            object_info.type = H5O_TYPE_UNKNOWN;
            H5OGET_INFO_BY_NAME(dset_id, matvar->internal->fieldnames[k], &object_info,
                                H5P_DEFAULT);
            if ( object_info.type == H5O_TYPE_DATASET ) {
                field_id = H5Dopen(dset_id, matvar->internal->fieldnames[k], H5P_DEFAULT);
                if ( !fields_are_variables ) {
                    hobj_ref_t *ref_ids = (hobj_ref_t *)calloc((size_t)nelems, sizeof(*ref_ids));
                    if ( ref_ids != NULL ) {
                        hsize_t l;
                        herr_t herr = H5Dread(field_id, H5T_STD_REF_OBJ, H5S_ALL, H5S_ALL,
                                              H5P_DEFAULT, ref_ids);
                        if ( herr < 0 ) {
                            err = MATIO_E_GENERIC_READ_ERROR;
                        } else {
                            for ( l = 0; l < nelems; l++ ) {
                                hid_t ref_id;
                                fields[l * nfields + k] = Mat_VarCalloc();
                                fields[l * nfields + k]->name =
                                    Mat_strdup(matvar->internal->fieldnames[k]);
                                fields[l * nfields + k]->internal->hdf5_ref = ref_ids[l];
                                /* Closing of ref_id is done in Mat_H5ReadNextReferenceInfo */
                                ref_id = H5RDEREFERENCE(field_id, H5R_OBJECT, ref_ids + l);
                                if ( ref_id < 0 ) {
                                    err = MATIO_E_GENERIC_READ_ERROR;
                                } else {
                                    fields[l * nfields + k]->internal->id = ref_id;
                                    err = Mat_H5ReadNextReferenceInfo(ref_id,
                                                                      fields[l * nfields + k], mat);
                                }
                                if ( err ) {
                                    break;
                                }
                            }
                        }
                        free(ref_ids);
                    } else {
                        err = MATIO_E_OUT_OF_MEMORY;
                    }
                } else {
                    fields[k] = Mat_VarCalloc();
                    fields[k]->name = Mat_strdup(matvar->internal->fieldnames[k]);
                    err = Mat_H5ReadDatasetInfo(mat, fields[k], field_id);
                }
                H5Dclose(field_id);
            } else if ( object_info.type == H5O_TYPE_GROUP ) {
                field_id = H5Gopen(dset_id, matvar->internal->fieldnames[k], H5P_DEFAULT);
                if ( -1 < field_id ) {
                    fields[k] = Mat_VarCalloc();
                    fields[k]->name = Mat_strdup(matvar->internal->fieldnames[k]);
                    err = Mat_H5ReadGroupInfo(mat, fields[k], field_id);
                    H5Gclose(field_id);
                }
            }
            if ( err ) {
                break;
            }
        }
    } else {
        err = MATIO_E_OUT_OF_MEMORY;
    }

    return err;
}

static herr_t
Mat_H5ReadGroupInfoIterate(hid_t dset_id, const char *name, const H5L_info_t *info, void *op_data)
{
    matvar_t *matvar;
    H5O_INFO_T object_info;
    struct ReadGroupInfoIterData *group_data;

    /* FIXME: follow symlinks, datatypes? */

    object_info.type = H5O_TYPE_UNKNOWN;
    H5OGET_INFO_BY_NAME(dset_id, name, &object_info, H5P_DEFAULT);
    if ( H5O_TYPE_DATASET != object_info.type && H5O_TYPE_GROUP != object_info.type )
        return 0;

    group_data = (struct ReadGroupInfoIterData *)op_data;
    if ( group_data == NULL )
        return -1;
    matvar = group_data->matvar;

    switch ( object_info.type ) {
        case H5O_TYPE_GROUP:
            /* Check that this is not the /#refs# group */
            if ( 0 == strcmp(name, "#refs#") )
                return 0;
            /* Fall through */
        case H5O_TYPE_DATASET:
            if ( matvar != NULL ) {
                matvar->internal->fieldnames[group_data->nfields] = Mat_strdup(name);
            }
            group_data->nfields++;
            break;
        default:
            /* Not possible to get here */
            break;
    }

    return 1;
}

static int
Mat_H5ReadNextReferenceInfo(hid_t ref_id, matvar_t *matvar, mat_t *mat)
{
    int err;
    if ( ref_id < 0 || matvar == NULL )
        return MATIO_E_NO_ERROR;

    switch ( H5Iget_type(ref_id) ) {
        case H5I_DATASET:
            err = Mat_H5ReadDatasetInfo(mat, matvar, ref_id);
            if ( matvar->internal->id != ref_id ) {
                /* Close dataset and increment count */
                H5Dclose(ref_id);
            }

            /*H5Dclose(ref_id);*/
            break;

        case H5I_GROUP:
            err = Mat_H5ReadGroupInfo(mat, matvar, ref_id);
            break;

        default:
            err = MATIO_E_NO_ERROR;
            break;
    }

    return err;
}

static int
Mat_H5ReadData(hid_t dset_id, hid_t h5_type, hid_t mem_space, hid_t dset_space, int isComplex,
               void *data)
{
    herr_t herr;

    if ( !isComplex ) {
        herr = H5Dread(dset_id, h5_type, mem_space, dset_space, H5P_DEFAULT, data);
        if ( herr < 0 ) {
            return MATIO_E_GENERIC_READ_ERROR;
        }
    } else {
        mat_complex_split_t *complex_data = (mat_complex_split_t *)data;
        hid_t h5_complex;
        size_t h5_size = H5Tget_size(h5_type);

        h5_complex = H5Tcreate(H5T_COMPOUND, h5_size);
        H5Tinsert(h5_complex, "real", 0, h5_type);
        herr = H5Dread(dset_id, h5_complex, mem_space, dset_space, H5P_DEFAULT, complex_data->Re);
        H5Tclose(h5_complex);
        if ( herr < 0 ) {
            return MATIO_E_GENERIC_READ_ERROR;
        }

        h5_complex = H5Tcreate(H5T_COMPOUND, h5_size);
        H5Tinsert(h5_complex, "imag", 0, h5_type);
        herr = H5Dread(dset_id, h5_complex, mem_space, dset_space, H5P_DEFAULT, complex_data->Im);
        H5Tclose(h5_complex);
        if ( herr < 0 ) {
            return MATIO_E_GENERIC_READ_ERROR;
        }
    }

    return MATIO_E_NO_ERROR;
}

static int
Mat_H5ReadNextReferenceData(hid_t ref_id, matvar_t *matvar, mat_t *mat)
{
    int err = MATIO_E_NO_ERROR;
    size_t nelems = 1;

    if ( ref_id < 0 || matvar == NULL )
        return err;

    /* If the datatype with references is a cell, we've already read info into
     * the variable data, so just loop over each cell element and call
     * Mat_H5ReadNextReferenceData on it.
     */
    if ( MAT_C_CELL == matvar->class_type ) {
        size_t i;
        matvar_t **cells;

        if ( NULL == matvar->data ) {
            return err;
        }
        err = Mat_MulDims(matvar, &nelems);
        if ( err ) {
            return err;
        }
        cells = (matvar_t **)matvar->data;
        for ( i = 0; i < nelems; i++ ) {
            if ( NULL != cells[i] ) {
                err = Mat_H5ReadNextReferenceData(cells[i]->internal->id, cells[i], mat);
            }
            if ( err ) {
                break;
            }
        }
        return err;
    }

    switch ( H5Iget_type(ref_id) ) {
        case H5I_DATASET: {
            hid_t data_type_id, dset_id;
            if ( MAT_C_CHAR == matvar->class_type ) {
                matvar->data_type = MAT_T_UINT8;
                matvar->data_size = (int)Mat_SizeOf(MAT_T_UINT8);
                data_type_id = DataType2H5T(MAT_T_UINT8);
            } else if ( MAT_C_STRUCT == matvar->class_type ) {
                /* Empty structure array */
                break;
            } else {
                matvar->data_size = (int)Mat_SizeOfClass(matvar->class_type);
                data_type_id = ClassType2H5T(matvar->class_type);
            }

            err = Mat_MulDims(matvar, &nelems);
            err |= Mul(&matvar->nbytes, nelems, matvar->data_size);
            if ( err || matvar->nbytes < 1 ) {
                H5Dclose(ref_id);
                break;
            }

            dset_id = ref_id;

            if ( !matvar->isComplex ) {
                matvar->data = malloc(matvar->nbytes);
            } else {
                matvar->data = ComplexMalloc(matvar->nbytes);
            }
            if ( NULL != matvar->data ) {
                err = Mat_H5ReadData(dset_id, data_type_id, H5S_ALL, H5S_ALL, matvar->isComplex,
                                     matvar->data);
            }
            H5Dclose(dset_id);
            break;
        }
        case H5I_GROUP: {
            if ( MAT_C_SPARSE == matvar->class_type ) {
                err = Mat_VarRead73(mat, matvar);
            } else {
                matvar_t **fields;
                size_t i;

                if ( !matvar->nbytes || !matvar->data_size || NULL == matvar->data )
                    break;
                nelems = matvar->nbytes / matvar->data_size;
                fields = (matvar_t **)matvar->data;
                for ( i = 0; i < nelems; i++ ) {
                    if ( NULL != fields[i] && 0 < fields[i]->internal->hdf5_ref &&
                         -1 < fields[i]->internal->id ) {
                        /* Dataset of references */
                        err = Mat_H5ReadNextReferenceData(fields[i]->internal->id, fields[i], mat);
                    } else {
                        err = Mat_VarRead73(mat, fields[i]);
                    }
                    if ( err ) {
                        break;
                    }
                }
            }
            break;
        }
        default:
            break;
    }

    return err;
}

static int
Mat_H5WriteData(hid_t dset_id, hid_t h5_type, hid_t mem_space, hid_t dset_space, int isComplex,
                void *data)
{
    int err = MATIO_E_NO_ERROR;

    if ( !isComplex ) {
        if ( 0 > H5Dwrite(dset_id, h5_type, mem_space, dset_space, H5P_DEFAULT, data) )
            err = MATIO_E_GENERIC_WRITE_ERROR;
    } else {
        mat_complex_split_t *complex_data = (mat_complex_split_t *)data;
        hid_t h5_complex;
        size_t h5_size = H5Tget_size(h5_type);

        /* Write real part of dataset */
        h5_complex = H5Tcreate(H5T_COMPOUND, h5_size);
        H5Tinsert(h5_complex, "real", 0, h5_type);
        err = Mat_H5WriteData(dset_id, h5_complex, mem_space, dset_space, 0, complex_data->Re);
        H5Tclose(h5_complex);

        /* Write imaginary part of dataset */
        h5_complex = H5Tcreate(H5T_COMPOUND, h5_size);
        H5Tinsert(h5_complex, "imag", 0, h5_type);
        err += Mat_H5WriteData(dset_id, h5_complex, mem_space, dset_space, 0, complex_data->Im);
        H5Tclose(h5_complex);
    }

    return err;
}

static int
Mat_H5WriteAppendData(hid_t id, hid_t h5_type, int mrank, const char *name, const size_t *mdims,
                      hsize_t *dims, int dim, int isComplex, void *data)
{
    int err = MATIO_E_NO_ERROR;
    hid_t dset_id, space_id;
    int rank;

    if ( dim < 1 || dim > mrank )
        return MATIO_E_BAD_ARGUMENT;

    dset_id = H5Dopen(id, name, H5P_DEFAULT);
    space_id = H5Dget_space(dset_id);
    rank = H5Sget_simple_extent_ndims(space_id);
    if ( rank == mrank ) {
        hsize_t *size_offset_dims;
        size_offset_dims = (hsize_t *)malloc(rank * sizeof(*size_offset_dims));
        if ( NULL != size_offset_dims ) {
            hsize_t offset;
            hid_t mspace_id;
            int k;

            (void)H5Sget_simple_extent_dims(space_id, size_offset_dims, NULL);
            offset = size_offset_dims[rank - dim];
            size_offset_dims[rank - dim] += mdims[dim - 1];
            H5Dset_extent(dset_id, size_offset_dims);
            for ( k = 0; k < rank; k++ ) {
                size_offset_dims[k] = 0;
            }
            size_offset_dims[rank - dim] = offset;
            /* Need to reopen */
            H5Sclose(space_id);
            space_id = H5Dget_space(dset_id);
            H5Sselect_hyperslab(space_id, H5S_SELECT_SET, size_offset_dims, NULL, dims, NULL);
            free(size_offset_dims);
            mspace_id = H5Screate_simple(rank, dims, NULL);
            err = Mat_H5WriteData(dset_id, h5_type, mspace_id, space_id, isComplex, data);
            H5Sclose(mspace_id);
        } else {
            err = MATIO_E_OUT_OF_MEMORY;
        }
    } else {
        err = MATIO_E_GENERIC_WRITE_ERROR;
    }
    H5Sclose(space_id);
    H5Dclose(dset_id);

    return err;
}

static int
Mat_VarWriteRef(hid_t id, matvar_t *matvar, enum matio_compression compression, hid_t *refs_id,
                hobj_ref_t *ref)
{
    int err;
    herr_t herr;
    char obj_name[64];
    H5G_info_t group_info;

    group_info.nlinks = 0;
    herr = H5Gget_info(*refs_id, &group_info);
    if ( herr < 0 ) {
        err = MATIO_E_BAD_ARGUMENT;
    } else {
        sprintf(obj_name, "%llu", group_info.nlinks);
        if ( NULL != matvar )
            matvar->compression = compression;
        err = Mat_VarWriteNext73(*refs_id, matvar, obj_name, refs_id);
        sprintf(obj_name, "/#refs#/%llu", group_info.nlinks);
        H5Rcreate(ref, id, obj_name, H5R_OBJECT, -1);
    }
    return err;
}

static int
Mat_VarWriteEmpty(hid_t id, matvar_t *matvar, const char *name, const char *class_name)
{
    int err = MATIO_E_NO_ERROR;
    hsize_t rank = matvar->rank;
    unsigned empty = 1;
    hid_t mspace_id, dset_id, attr_type_id, aspace_id, attr_id;

    mspace_id = H5Screate_simple(1, &rank, NULL);
    dset_id =
        H5Dcreate(id, name, H5T_NATIVE_HSIZE, mspace_id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    attr_type_id = H5Tcopy(H5T_C_S1);
    H5Tset_size(attr_type_id, strlen(class_name));
    aspace_id = H5Screate(H5S_SCALAR);
    attr_id = H5Acreate(dset_id, "MATLAB_class", attr_type_id, aspace_id, H5P_DEFAULT, H5P_DEFAULT);
    if ( 0 > H5Awrite(attr_id, attr_type_id, class_name) )
        err = MATIO_E_GENERIC_WRITE_ERROR;
    H5Sclose(aspace_id);
    H5Aclose(attr_id);
    H5Tclose(attr_type_id);

    if ( MATIO_E_NO_ERROR == err ) {
        if ( 0 == strcmp(class_name, "struct") ) {
            /* Write the fields attribute */
            hsize_t nfields = matvar->internal->num_fields;
            if ( nfields ) {
                hvl_t *fieldnames = (hvl_t *)malloc((size_t)nfields * sizeof(*fieldnames));
                if ( NULL != fieldnames ) {
                    hid_t str_type_id, fieldnames_id;
                    hsize_t k;

                    str_type_id = H5Tcopy(H5T_C_S1);
                    for ( k = 0; k < nfields; k++ ) {
                        fieldnames[k].len = strlen(matvar->internal->fieldnames[k]);
                        fieldnames[k].p = matvar->internal->fieldnames[k];
                    }
                    H5Tset_size(str_type_id, 1);
                    fieldnames_id = H5Tvlen_create(str_type_id);
                    aspace_id = H5Screate_simple(1, &nfields, NULL);
                    attr_id = H5Acreate(dset_id, "MATLAB_fields", fieldnames_id, aspace_id,
                                        H5P_DEFAULT, H5P_DEFAULT);
                    if ( 0 > H5Awrite(attr_id, fieldnames_id, fieldnames) )
                        err = MATIO_E_GENERIC_WRITE_ERROR;
                    H5Aclose(attr_id);
                    H5Sclose(aspace_id);
                    H5Tclose(fieldnames_id);
                    H5Tclose(str_type_id);
                    free(fieldnames);
                } else {
                    err = MATIO_E_OUT_OF_MEMORY;
                }
            }
        } else if ( 0 == strcmp(class_name, "logical") ) {
            /* Write the MATLAB_int_decode attribute */
            int int_decode = 1;
            aspace_id = H5Screate(H5S_SCALAR);
            attr_id = H5Acreate(dset_id, "MATLAB_int_decode", H5T_NATIVE_INT, aspace_id,
                                H5P_DEFAULT, H5P_DEFAULT);
            if ( 0 > H5Awrite(attr_id, H5T_NATIVE_INT, &int_decode) )
                err = MATIO_E_GENERIC_WRITE_ERROR;
            H5Sclose(aspace_id);
            H5Aclose(attr_id);
        }

        if ( MATIO_E_NO_ERROR == err ) {
            /* Write the empty attribute */
            aspace_id = H5Screate(H5S_SCALAR);
            attr_id = H5Acreate(dset_id, "MATLAB_empty", H5T_NATIVE_UINT, aspace_id, H5P_DEFAULT,
                                H5P_DEFAULT);
            if ( 0 > H5Awrite(attr_id, H5T_NATIVE_UINT, &empty) )
                err = MATIO_E_GENERIC_WRITE_ERROR;
            H5Sclose(aspace_id);
            H5Aclose(attr_id);
        }

        if ( MATIO_E_NO_ERROR == err ) {
            /* Write the dimensions as the data */
            if ( 0 >
                 H5Dwrite(dset_id, SizeType2H5T(), H5S_ALL, H5S_ALL, H5P_DEFAULT, matvar->dims) )
                err = MATIO_E_GENERIC_WRITE_ERROR;
        }
    }
    H5Dclose(dset_id);
    H5Sclose(mspace_id);

    return err;
}

/** @if mat_devman
 * @brief Writes a cell array matlab variable to the specified HDF id with the
 *        given name
 *
 * @ingroup mat_internal
 * @param id HDF id of the parent object
 * @param matvar pointer to the cell array variable
 * @param name Name of the HDF dataset
 * @param refs_id pointer to the id of the /#refs# group in HDF5
 * @param dims array of permuted dimensions
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWriteCell73(hid_t id, matvar_t *matvar, const char *name, hid_t *refs_id, hsize_t *dims)
{
    int k;
    hsize_t nelems = 1, l;
    matvar_t **cells;
    int err = MATIO_E_NO_ERROR;

    cells = (matvar_t **)matvar->data;
    for ( k = 0; k < matvar->rank; k++ )
        nelems *= dims[k];

    if ( 0 == nelems || NULL == matvar->data ) {
        err = Mat_VarWriteEmpty(id, matvar, name, ClassNames[matvar->class_type]);
    } else {
        if ( *refs_id < 0 ) {
            if ( H5Lexists(id, "/#refs#", H5P_DEFAULT) ) {
                *refs_id = H5Gopen(id, "/#refs#", H5P_DEFAULT);
            } else {
                *refs_id = H5Gcreate(id, "/#refs#", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
            }
        }
        if ( *refs_id > -1 ) {
            hobj_ref_t *refs = (hobj_ref_t *)malloc((size_t)nelems * sizeof(*refs));
            if ( NULL != refs ) {
                hid_t mspace_id = H5Screate_simple(matvar->rank, dims, NULL);
                hid_t dset_id = H5Dcreate(id, name, H5T_STD_REF_OBJ, mspace_id, H5P_DEFAULT,
                                          H5P_DEFAULT, H5P_DEFAULT);

                for ( l = 0; l < nelems; l++ ) {
                    err = Mat_VarWriteRef(id, cells[l], matvar->compression, refs_id, refs + l);
                    if ( err )
                        break;
                }
                if ( MATIO_E_NO_ERROR == err ) {
                    err = Mat_H5WriteData(dset_id, H5T_STD_REF_OBJ, H5S_ALL, H5S_ALL, 0, refs);

                    if ( MATIO_E_NO_ERROR == err ) {
                        hid_t attr_id, aspace_id;
                        hid_t str_type_id = H5Tcopy(H5T_C_S1);
                        H5Tset_size(str_type_id, 4);
                        aspace_id = H5Screate(H5S_SCALAR);
                        attr_id = H5Acreate(dset_id, "MATLAB_class", str_type_id, aspace_id,
                                            H5P_DEFAULT, H5P_DEFAULT);
                        if ( 0 > H5Awrite(attr_id, str_type_id, "cell") )
                            err = MATIO_E_GENERIC_WRITE_ERROR;
                        H5Aclose(attr_id);
                        H5Sclose(aspace_id);
                        H5Tclose(str_type_id);
                    }
                }
                H5Dclose(dset_id);
                free(refs);
                H5Sclose(mspace_id);
            } else {
                err = MATIO_E_OUT_OF_MEMORY;
            }
        } else {
            err = MATIO_E_OUTPUT_BAD_DATA;
        }
    }

    return err;
}

/** @if mat_devman
 * @brief Writes a character matlab variable to the specified HDF id with the
 *        given name
 *
 * @ingroup mat_internal
 * @param id HDF id of the parent object
 * @param matvar pointer to the character variable
 * @param name Name of the HDF dataset
 * @param dims array of permuted dimensions
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWriteChar73(hid_t id, matvar_t *matvar, const char *name, hsize_t *dims)
{
    int err = MATIO_E_NO_ERROR, k;
    hsize_t nelems = 1;
    mat_uint16_t *u16 = NULL;
    hid_t h5type;

    for ( k = 0; k < matvar->rank; k++ ) {
        nelems *= dims[k];
    }

    if ( 0 == nelems || NULL == matvar->data ) {
        err = Mat_VarWriteEmpty(id, matvar, name, ClassNames[matvar->class_type]);
    } else {
        int matlab_int_decode = 2;
        hid_t mspace_id, dset_id, attr_type_id, attr_id, aspace_id;

        mspace_id = H5Screate_simple(matvar->rank, dims, NULL);
        switch ( matvar->data_type ) {
            case MAT_T_UTF32:
            case MAT_T_INT32:
            case MAT_T_UINT32:
                /* Not sure matlab will actually handle this */
                dset_id = H5Dcreate(id, name, ClassType2H5T(MAT_C_UINT32), mspace_id, H5P_DEFAULT,
                                    H5P_DEFAULT, H5P_DEFAULT);
                break;
            case MAT_T_UTF16:
            case MAT_T_UTF8:
            case MAT_T_INT16:
            case MAT_T_UINT16:
            case MAT_T_INT8:
            case MAT_T_UINT8:
                dset_id = H5Dcreate(id, name, ClassType2H5T(MAT_C_UINT16), mspace_id, H5P_DEFAULT,
                                    H5P_DEFAULT, H5P_DEFAULT);
                break;
            default:
                H5Sclose(mspace_id);
                return MATIO_E_OUTPUT_BAD_DATA;
        }
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id, strlen(ClassNames[matvar->class_type]));
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id =
            H5Acreate(dset_id, "MATLAB_class", attr_type_id, aspace_id, H5P_DEFAULT, H5P_DEFAULT);
        if ( 0 > H5Awrite(attr_id, attr_type_id, ClassNames[matvar->class_type]) )
            err = MATIO_E_GENERIC_WRITE_ERROR;
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);

        if ( MATIO_E_NO_ERROR == err ) {
            attr_type_id = H5Tcopy(H5T_NATIVE_INT);
            attr_id = H5Acreate(dset_id, "MATLAB_int_decode", attr_type_id, aspace_id, H5P_DEFAULT,
                                H5P_DEFAULT);
            if ( 0 > H5Awrite(attr_id, attr_type_id, &matlab_int_decode) )
                err = MATIO_E_GENERIC_WRITE_ERROR;
            H5Aclose(attr_id);
            H5Tclose(attr_type_id);
        }
        H5Sclose(aspace_id);

        h5type = DataType2H5T(matvar->data_type);
        if ( MATIO_E_NO_ERROR == err && matvar->data_type == MAT_T_UTF8 ) {
            /* Convert to UTF-16 */
            h5type = H5T_NATIVE_UINT16;
            u16 = (mat_uint16_t *)calloc(nelems, sizeof(mat_uint16_t));
            if ( u16 != NULL ) {
                mat_uint8_t *data = (mat_uint8_t *)matvar->data;
                size_t i, j = 0;
                for ( i = 0; i < matvar->nbytes; i++ ) {
                    const mat_uint8_t c = data[i];
                    if ( c <= 0x7F ) { /* ASCII */
                        u16[j] = (mat_uint16_t)c;
                    } else if ( c < 0xE0 && i + 1 < matvar->nbytes ) { /* Extended ASCII */
                        const mat_uint16_t _a = (mat_uint16_t)(c & 0x1F);
                        const mat_uint16_t _b = (mat_uint16_t)(data[i + 1] & 0x3F);
                        u16[j] = (_a << 6) | _b;
                        i = i + 1;
                    } else if ( (c & 0xF0) == 0xE0 && i + 2 < matvar->nbytes ) { /* BMP */
                        const mat_uint16_t _a = (mat_uint16_t)(c & 0xF);
                        const mat_uint16_t _b = (mat_uint16_t)(data[i + 1] & 0x3C) >> 2;
                        const mat_uint16_t _c = (mat_uint16_t)(data[i + 1] & 0x3);
                        const mat_uint16_t _d = (mat_uint16_t)(data[i + 2] & 0x30) >> 4;
                        const mat_uint16_t _e = (mat_uint16_t)(data[i + 2] & 0xF);
                        u16[j] = (_a << 12) | (_b << 8) | (_c << 6) | (_d << 4) | _e;
                        i = i + 2;
                    } else { /* Full UTF-8 */
                        err = MATIO_E_OPERATION_NOT_SUPPORTED;
                        break;
                    }
                    j++;
                }
            } else {
                err = MATIO_E_OUT_OF_MEMORY;
            }
        }

        if ( MATIO_E_NO_ERROR == err ) {
            void *data = matvar->data_type == MAT_T_UTF8 ? u16 : matvar->data;
            if ( 0 > H5Dwrite(dset_id, h5type, H5S_ALL, H5S_ALL, H5P_DEFAULT, (void *)data) )
                err = MATIO_E_GENERIC_WRITE_ERROR;
        }
        free(u16);
        H5Dclose(dset_id);
        H5Sclose(mspace_id);
    }

    return err;
}

static int
Mat_WriteEmptyVariable73(hid_t id, const char *name, hsize_t rank, size_t *dims)
{
    int err = MATIO_E_NO_ERROR;
    unsigned empty = 1;
    hid_t mspace_id, dset_id;

    mspace_id = H5Screate_simple(1, &rank, NULL);
    dset_id =
        H5Dcreate(id, name, H5T_NATIVE_HSIZE, mspace_id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    if ( dset_id > -1 ) {
        hid_t attr_type_id, attr_id, aspace_id;

        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id, 6);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id =
            H5Acreate(dset_id, "MATLAB_class", attr_type_id, aspace_id, H5P_DEFAULT, H5P_DEFAULT);
        if ( 0 > H5Awrite(attr_id, attr_type_id, "double") )
            err = MATIO_E_GENERIC_WRITE_ERROR;
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);

        if ( MATIO_E_NO_ERROR == err ) {
            aspace_id = H5Screate(H5S_SCALAR);
            attr_id = H5Acreate(dset_id, "MATLAB_empty", H5T_NATIVE_UINT, aspace_id, H5P_DEFAULT,
                                H5P_DEFAULT);
            if ( 0 > H5Awrite(attr_id, H5T_NATIVE_UINT, &empty) )
                err = MATIO_E_GENERIC_WRITE_ERROR;
            H5Sclose(aspace_id);
            H5Aclose(attr_id);
        }

        if ( MATIO_E_NO_ERROR == err ) {
            /* Write the dimensions as the data */
            if ( 0 > H5Dwrite(dset_id, SizeType2H5T(), H5S_ALL, H5S_ALL, H5P_DEFAULT, dims) )
                err = MATIO_E_GENERIC_WRITE_ERROR;
        }
        H5Dclose(dset_id);
    } else {
        err = MATIO_E_OUTPUT_BAD_DATA;
    }
    H5Sclose(mspace_id);

    return err;
}

/** @if mat_devman
 * @brief Writes a logical matlab variable to the specified HDF id with the
 *        given name
 *
 * @ingroup mat_internal
 * @param id HDF id of the parent object
 * @param matvar pointer to the logical variable
 * @param name Name of the HDF dataset
 * @param dims array of permuted dimensions
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWriteLogical73(hid_t id, matvar_t *matvar, const char *name, hsize_t *dims)
{
    int err = MATIO_E_NO_ERROR, k;
    hsize_t nelems = 1;
    hid_t plist;

    for ( k = 0; k < matvar->rank; k++ ) {
        nelems *= dims[k];
    }

    if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
        plist = H5Pcreate(H5P_DATASET_CREATE);
        if ( MAX_RANK >= matvar->rank ) {
            hsize_t chunk_dims[MAX_RANK];
            Mat_H5GetChunkSize(matvar->rank, dims, chunk_dims);
            H5Pset_chunk(plist, matvar->rank, chunk_dims);
        } else {
            hsize_t *chunk_dims = (hsize_t *)malloc(matvar->rank * sizeof(hsize_t));
            if ( NULL != chunk_dims ) {
                Mat_H5GetChunkSize(matvar->rank, dims, chunk_dims);
                H5Pset_chunk(plist, matvar->rank, chunk_dims);
                free(chunk_dims);
            } else {
                H5Pclose(plist);
                return MATIO_E_OUT_OF_MEMORY;
            }
        }
        H5Pset_deflate(plist, 9);
    } else {
        plist = H5P_DEFAULT;
    }

    if ( 0 == nelems || NULL == matvar->data ) {
        err = Mat_VarWriteEmpty(id, matvar, name, "logical");
    } else {
        int int_decode = 1;
        hid_t mspace_id, dset_id, attr_type_id, attr_id, aspace_id;

        mspace_id = H5Screate_simple(matvar->rank, dims, NULL);
        /* Note that MATLAB only recognizes uint8 as logical */
        dset_id = H5Dcreate(id, name, ClassType2H5T(MAT_C_UINT8), mspace_id, H5P_DEFAULT, plist,
                            H5P_DEFAULT);
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id, 7);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id =
            H5Acreate(dset_id, "MATLAB_class", attr_type_id, aspace_id, H5P_DEFAULT, H5P_DEFAULT);
        if ( 0 > H5Awrite(attr_id, attr_type_id, "logical") )
            err = MATIO_E_GENERIC_WRITE_ERROR;
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);

        if ( MATIO_E_NO_ERROR == err ) {
            /* Write the MATLAB_int_decode attribute */
            aspace_id = H5Screate(H5S_SCALAR);
            attr_id = H5Acreate(dset_id, "MATLAB_int_decode", H5T_NATIVE_INT, aspace_id,
                                H5P_DEFAULT, H5P_DEFAULT);
            if ( 0 > H5Awrite(attr_id, H5T_NATIVE_INT, &int_decode) )
                err = MATIO_E_GENERIC_WRITE_ERROR;
            H5Sclose(aspace_id);
            H5Aclose(attr_id);
        }

        if ( MATIO_E_NO_ERROR == err ) {
            if ( 0 > H5Dwrite(dset_id, DataType2H5T(matvar->data_type), H5S_ALL, H5S_ALL,
                              H5P_DEFAULT, matvar->data) )
                err = MATIO_E_GENERIC_WRITE_ERROR;
        }
        H5Dclose(dset_id);
        H5Sclose(mspace_id);
    }

    if ( H5P_DEFAULT != plist )
        H5Pclose(plist);

    return err;
}

/** @if mat_devman
 * @brief Writes a numeric matlab variable to the specified HDF id with the
 *        given name
 *
 * @ingroup mat_internal
 * @param id HDF id of the parent object
 * @param matvar pointer to the numeric variable
 * @param name Name of the HDF dataset
 * @param dims array of permuted dimensions
 * @param max_dims maximum dimensions
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWriteNumeric73(hid_t id, matvar_t *matvar, const char *name, hsize_t *dims,
                      hsize_t *max_dims)
{
    int err = MATIO_E_NO_ERROR, k;
    hsize_t nelems = 1;
    hid_t plist;

    for ( k = 0; k < matvar->rank; k++ ) {
        nelems *= dims[k];
    }

    if ( matvar->compression || NULL != max_dims ) {
        plist = H5Pcreate(H5P_DATASET_CREATE);
        if ( MAX_RANK >= matvar->rank ) {
            hsize_t chunk_dims[MAX_RANK];
            Mat_H5GetChunkSize(matvar->rank, dims, chunk_dims);
            H5Pset_chunk(plist, matvar->rank, chunk_dims);
        } else {
            hsize_t *chunk_dims = (hsize_t *)malloc(matvar->rank * sizeof(hsize_t));
            if ( NULL != chunk_dims ) {
                Mat_H5GetChunkSize(matvar->rank, dims, chunk_dims);
                H5Pset_chunk(plist, matvar->rank, chunk_dims);
                free(chunk_dims);
            } else {
                H5Pclose(plist);
                return MATIO_E_OUT_OF_MEMORY;
            }
        }
        if ( matvar->compression == MAT_COMPRESSION_ZLIB )
            H5Pset_deflate(plist, 9);
    } else {
        plist = H5P_DEFAULT;
    }

    if ( 0 == nelems || NULL == matvar->data ) {
        err = Mat_VarWriteEmpty(id, matvar, name, ClassNames[matvar->class_type]);
    } else {
        hid_t mspace_id, dset_id, attr_type_id, attr_id, aspace_id;
        hid_t h5_type = ClassType2H5T(matvar->class_type);
        hid_t h5_dtype = DataType(h5_type, matvar->isComplex);

        mspace_id = H5Screate_simple(matvar->rank, dims, max_dims);
        dset_id = H5Dcreate(id, name, h5_dtype, mspace_id, H5P_DEFAULT, plist, H5P_DEFAULT);
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id, strlen(ClassNames[matvar->class_type]));
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id =
            H5Acreate(dset_id, "MATLAB_class", attr_type_id, aspace_id, H5P_DEFAULT, H5P_DEFAULT);
        if ( 0 > H5Awrite(attr_id, attr_type_id, ClassNames[matvar->class_type]) )
            err = MATIO_E_GENERIC_WRITE_ERROR;
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);
        H5Tclose(h5_dtype);
        if ( MATIO_E_NO_ERROR == err ) {
            err = Mat_H5WriteData(dset_id, h5_type, H5S_ALL, H5S_ALL, matvar->isComplex,
                                  matvar->data);
        }
        H5Dclose(dset_id);
        H5Sclose(mspace_id);
    }

    if ( H5P_DEFAULT != plist )
        H5Pclose(plist);

    return err;
}

/** @if mat_devman
 * @brief Writes/appends a numeric matlab variable to the specified HDF id with the
 *        given name
 *
 * @ingroup mat_internal
 * @param id HDF id of the parent object
 * @param matvar pointer to the numeric variable
 * @param name Name of the HDF dataset
 * @param dims array of permuted dimensions
 * @param dim dimension to append data
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWriteAppendNumeric73(hid_t id, matvar_t *matvar, const char *name, hsize_t *dims, int dim)
{
    int err = MATIO_E_NO_ERROR, k;
    hsize_t nelems = 1;

    for ( k = 0; k < matvar->rank; k++ ) {
        nelems *= dims[k];
    }

    if ( 0 != nelems && NULL != matvar->data ) {
        if ( H5Lexists(id, matvar->name, H5P_DEFAULT) ) {
            err = Mat_H5WriteAppendData(id, ClassType2H5T(matvar->class_type), matvar->rank,
                                        matvar->name, matvar->dims, dims, dim, matvar->isComplex,
                                        matvar->data);
        } else {
            /* Create with unlimited number of dimensions */
            if ( MAX_RANK >= matvar->rank ) {
                hsize_t max_dims[MAX_RANK];
                for ( k = 0; k < matvar->rank; k++ ) {
                    max_dims[k] = H5S_UNLIMITED;
                }
                err = Mat_VarWriteNumeric73(id, matvar, name, dims, max_dims);
            } else {
                hsize_t *max_dims = (hsize_t *)malloc(matvar->rank * sizeof(hsize_t));
                if ( NULL != max_dims ) {
                    for ( k = 0; k < matvar->rank; k++ ) {
                        max_dims[k] = H5S_UNLIMITED;
                    }
                    err = Mat_VarWriteNumeric73(id, matvar, name, dims, max_dims);
                    free(max_dims);
                } else {
                    err = MATIO_E_OUT_OF_MEMORY;
                }
            }
        }
    } else {
        err = MATIO_E_OUTPUT_BAD_DATA;
    }

    return err;
}

/** @if mat_devman
 * @brief Writes a sparse matrix variable to the specified HDF id with the
 *        given name
 *
 * @ingroup mat_internal
 * @param id HDF id of the parent object
 * @param matvar pointer to the structure variable
 * @param name Name of the HDF dataset
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWriteSparse73(hid_t id, matvar_t *matvar, const char *name)
{
    int err = MATIO_E_NO_ERROR;
    hid_t sparse_id;

    sparse_id = H5Gcreate(id, name, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    if ( sparse_id < 0 ) {
        Mat_Critical("Error creating group for sparse array %s", matvar->name);
        err = MATIO_E_OUTPUT_BAD_DATA;
    } else {
        hid_t size_type_id, h5_type, h5_dtype;
        hid_t mspace_id, dset_id, attr_type_id, attr_id, aspace_id;
        mat_sparse_t *sparse;
        hsize_t nir, njc, ndata;
        mat_uint64_t sparse_attr_value;
        enum matio_classes class_type;

        sparse = (mat_sparse_t *)matvar->data;
        class_type = DataType2ClassType(matvar->data_type);
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id, matvar->isLogical ? 7 : strlen(ClassNames[class_type]));
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id =
            H5Acreate(sparse_id, "MATLAB_class", attr_type_id, aspace_id, H5P_DEFAULT, H5P_DEFAULT);
        if ( 0 > H5Awrite(attr_id, attr_type_id,
                          matvar->isLogical ? "logical" : ClassNames[class_type]) )
            err = MATIO_E_GENERIC_WRITE_ERROR;
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);

        if ( MATIO_E_NO_ERROR == err ) {
            if ( matvar->isLogical ) {
                /* Write the MATLAB_int_decode attribute */
                int int_decode = 1;
                aspace_id = H5Screate(H5S_SCALAR);
                attr_id = H5Acreate(sparse_id, "MATLAB_int_decode", H5T_NATIVE_INT, aspace_id,
                                    H5P_DEFAULT, H5P_DEFAULT);
                if ( 0 > H5Awrite(attr_id, H5T_NATIVE_INT, &int_decode) )
                    err = MATIO_E_GENERIC_WRITE_ERROR;
                H5Sclose(aspace_id);
                H5Aclose(attr_id);
            }
        }

        if ( MATIO_E_NO_ERROR == err ) {
            sparse_attr_value = matvar->dims[0];
            size_type_id = ClassType2H5T(MAT_C_UINT64);
            aspace_id = H5Screate(H5S_SCALAR);
            attr_id = H5Acreate(sparse_id, "MATLAB_sparse", size_type_id, aspace_id, H5P_DEFAULT,
                                H5P_DEFAULT);
            if ( 0 > H5Awrite(attr_id, size_type_id, &sparse_attr_value) )
                err = MATIO_E_GENERIC_WRITE_ERROR;
            H5Sclose(aspace_id);
            H5Aclose(attr_id);
        }

        if ( MATIO_E_NO_ERROR == err ) {
            ndata = sparse->ndata;
            h5_type = DataType2H5T(matvar->data_type);
            h5_dtype = DataType(h5_type, matvar->isComplex);
            mspace_id = H5Screate_simple(1, &ndata, NULL);
            dset_id = H5Dcreate(sparse_id, "data", h5_dtype, mspace_id, H5P_DEFAULT, H5P_DEFAULT,
                                H5P_DEFAULT);
            H5Tclose(h5_dtype);
            err = Mat_H5WriteData(dset_id, h5_type, H5S_ALL, H5S_ALL, matvar->isComplex,
                                  sparse->data);
            H5Dclose(dset_id);
            H5Sclose(mspace_id);
        }

        if ( MATIO_E_NO_ERROR == err ) {
            nir = sparse->nir;
            mspace_id = H5Screate_simple(1, &nir, NULL);
            dset_id = H5Dcreate(sparse_id, "ir", size_type_id, mspace_id, H5P_DEFAULT, H5P_DEFAULT,
                                H5P_DEFAULT);
            err = Mat_H5WriteData(dset_id, H5T_NATIVE_UINT, H5S_ALL, H5S_ALL, 0, sparse->ir);
            H5Dclose(dset_id);
            H5Sclose(mspace_id);
        }

        if ( MATIO_E_NO_ERROR == err ) {
            njc = sparse->njc;
            mspace_id = H5Screate_simple(1, &njc, NULL);
            dset_id = H5Dcreate(sparse_id, "jc", size_type_id, mspace_id, H5P_DEFAULT, H5P_DEFAULT,
                                H5P_DEFAULT);
            err = Mat_H5WriteData(dset_id, H5T_NATIVE_UINT, H5S_ALL, H5S_ALL, 0, sparse->jc);
            H5Dclose(dset_id);
            H5Sclose(mspace_id);
        }
        H5Gclose(sparse_id);
    }

    return err;
}

/** @if mat_devman
 * @brief Writes a structure matlab variable to the specified HDF id with the
 *        given name
 *
 * @ingroup mat_internal
 * @param id HDF id of the parent object
 * @param matvar pointer to the structure variable
 * @param name Name of the HDF dataset
 * @param refs_id pointer to the id of the /#refs# group in HDF5
 * @param dims array of permuted dimensions
 * @param max_dims maximum dimensions
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWriteStruct73(hid_t id, matvar_t *matvar, const char *name, hid_t *refs_id, hsize_t *dims,
                     hsize_t *max_dims)
{
    int err;
    hsize_t nelems;

    {
        size_t tmp = 1;
        err = Mat_MulDims(matvar, &tmp);
        nelems = (hsize_t)tmp;
    }

    if ( err || 0 == nelems || NULL == matvar->data ) {
        err = Mat_VarWriteEmpty(id, matvar, name, ClassNames[matvar->class_type]);
    } else {
        hid_t struct_id = H5Gcreate(id, name, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
        if ( struct_id < 0 ) {
            Mat_Critical("Error creating group for struct %s", name);
            err = MATIO_E_OUTPUT_BAD_DATA;
        } else {
            hid_t attr_id, aspace_id;
            hid_t str_type_id;
            matvar_t **fields = (matvar_t **)matvar->data;
            hsize_t nfields = matvar->internal->num_fields, k;

            str_type_id = H5Tcopy(H5T_C_S1);
            H5Tset_size(str_type_id, 6);
            aspace_id = H5Screate(H5S_SCALAR);
            attr_id = H5Acreate(struct_id, "MATLAB_class", str_type_id, aspace_id, H5P_DEFAULT,
                                H5P_DEFAULT);
            if ( 0 > H5Awrite(attr_id, str_type_id, "struct") )
                err = MATIO_E_GENERIC_WRITE_ERROR;
            H5Aclose(attr_id);
            H5Sclose(aspace_id);

            /* Structure with no fields */
            if ( nfields == 0 ) {
                H5Gclose(struct_id);
                H5Tclose(str_type_id);
                return err;
            }

            if ( MATIO_E_NO_ERROR == err ) {
                hvl_t *fieldnames = (hvl_t *)malloc((size_t)nfields * sizeof(*fieldnames));
                if ( NULL != fieldnames ) {
                    hid_t fieldnames_id;
                    for ( k = 0; k < nfields; k++ ) {
                        fieldnames[k].len = strlen(matvar->internal->fieldnames[k]);
                        fieldnames[k].p = matvar->internal->fieldnames[k];
                    }
                    H5Tset_size(str_type_id, 1);
                    fieldnames_id = H5Tvlen_create(str_type_id);
                    aspace_id = H5Screate_simple(1, &nfields, NULL);
                    attr_id = H5Acreate(struct_id, "MATLAB_fields", fieldnames_id, aspace_id,
                                        H5P_DEFAULT, H5P_DEFAULT);
                    if ( 0 > H5Awrite(attr_id, fieldnames_id, fieldnames) )
                        err = MATIO_E_GENERIC_WRITE_ERROR;
                    H5Aclose(attr_id);
                    H5Sclose(aspace_id);
                    H5Tclose(fieldnames_id);
                    H5Tclose(str_type_id);
                    free(fieldnames);
                } else {
                    err = MATIO_E_OUT_OF_MEMORY;
                }
            }

            if ( MATIO_E_NO_ERROR == err ) {
                if ( 1 == nelems && NULL == max_dims ) {
                    for ( k = 0; k < nfields; k++ ) {
                        if ( NULL != fields[k] )
                            fields[k]->compression = matvar->compression;
                        err = Mat_VarWriteNext73(struct_id, fields[k],
                                                 matvar->internal->fieldnames[k], refs_id);
                    }
                } else {
                    if ( *refs_id < 0 ) {
                        if ( H5Lexists(id, "/#refs#", H5P_DEFAULT) ) {
                            *refs_id = H5Gopen(id, "/#refs#", H5P_DEFAULT);
                        } else {
                            *refs_id =
                                H5Gcreate(id, "/#refs#", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
                        }
                    }
                    if ( *refs_id > -1 ) {
                        hid_t plist = H5P_DEFAULT;
                        hobj_ref_t **refs = (hobj_ref_t **)calloc((size_t)nfields, sizeof(*refs));
                        if ( NULL != refs ) {
                            hsize_t l;
                            for ( l = 0; l < nfields; l++ ) {
                                refs[l] = (hobj_ref_t *)calloc((size_t)nelems, sizeof(*refs[l]));
                                if ( NULL == refs[l] ) {
                                    err = MATIO_E_OUT_OF_MEMORY;
                                    break;
                                }
                            }

                            if ( MATIO_E_NO_ERROR == err ) {
                                for ( k = 0; k < nelems; k++ ) {
                                    for ( l = 0; l < nfields; l++ ) {
                                        err = Mat_VarWriteRef(id, fields[k * nfields + l],
                                                              matvar->compression, refs_id,
                                                              refs[l] + k);
                                        if ( err )
                                            break;
                                    }
                                    if ( err )
                                        break;
                                }
                            }

                            if ( MATIO_E_NO_ERROR == err ) {
                                if ( NULL != max_dims ) {
                                    plist = H5Pcreate(H5P_DATASET_CREATE);
                                    if ( MAX_RANK >= matvar->rank ) {
                                        hsize_t chunk_dims[MAX_RANK];
                                        Mat_H5GetChunkSize(matvar->rank, dims, chunk_dims);
                                        H5Pset_chunk(plist, matvar->rank, chunk_dims);
                                    } else {
                                        hsize_t *chunk_dims =
                                            (hsize_t *)malloc(matvar->rank * sizeof(hsize_t));
                                        if ( NULL != chunk_dims ) {
                                            Mat_H5GetChunkSize(matvar->rank, dims, chunk_dims);
                                            H5Pset_chunk(plist, matvar->rank, chunk_dims);
                                            free(chunk_dims);
                                        } else {
                                            H5Pclose(plist);
                                            plist = H5P_DEFAULT;
                                            err = MATIO_E_OUT_OF_MEMORY;
                                        }
                                    }
                                } else {
                                    plist = H5P_DEFAULT;
                                }
                            }

                            if ( MATIO_E_NO_ERROR == err ) {
                                hid_t mspace_id = H5Screate_simple(matvar->rank, dims, max_dims);
                                for ( l = 0; l < nfields; l++ ) {
                                    hid_t dset_id = H5Dcreate(
                                        struct_id, matvar->internal->fieldnames[l], H5T_STD_REF_OBJ,
                                        mspace_id, H5P_DEFAULT, plist, H5P_DEFAULT);
                                    err = Mat_H5WriteData(dset_id, H5T_STD_REF_OBJ, H5S_ALL,
                                                          H5S_ALL, 0, refs[l]);
                                    H5Dclose(dset_id);
                                    if ( err )
                                        break;
                                }
                                H5Sclose(mspace_id);
                            }
                            for ( l = 0; l < nfields; l++ )
                                free(refs[l]);
                            free(refs);
                        } else {
                            err = MATIO_E_OUT_OF_MEMORY;
                        }
                        if ( H5P_DEFAULT != plist )
                            H5Pclose(plist);
                    } else {
                        err = MATIO_E_OUTPUT_BAD_DATA;
                    }
                }
            }
            H5Gclose(struct_id);
        }
    }

    return err;
}

static int
Mat_VarWriteAppendStruct73(hid_t id, matvar_t *matvar, const char *name, hid_t *refs_id,
                           hsize_t *dims, int dim)
{
    int err = MATIO_E_NO_ERROR;
    hsize_t nelems = 1;

    {
        int k;
        for ( k = 0; k < matvar->rank; k++ ) {
            nelems *= dims[k];
        }
    }

    if ( 0 != nelems && NULL != matvar->data ) {
        if ( H5Lexists(id, name, H5P_DEFAULT) ) {
            hobj_ref_t **refs;
            hsize_t nfields = matvar->internal->num_fields;
            matvar_t **fields = (matvar_t **)matvar->data;

            if ( *refs_id <= -1 )
                return MATIO_E_OUTPUT_BAD_DATA;

            refs = (hobj_ref_t **)calloc((size_t)nfields, sizeof(*refs));
            if ( NULL != refs ) {
                hsize_t l;
                for ( l = 0; l < nfields; l++ ) {
                    refs[l] = (hobj_ref_t *)calloc((size_t)nelems, sizeof(*refs[l]));
                    if ( NULL == refs[l] ) {
                        err = MATIO_E_OUT_OF_MEMORY;
                        break;
                    }
                }

                if ( MATIO_E_NO_ERROR == err ) {
                    hsize_t k;
                    for ( k = 0; k < nelems; k++ ) {
                        for ( l = 0; l < nfields; l++ ) {
                            err = Mat_VarWriteRef(id, fields[k * nfields + l], matvar->compression,
                                                  refs_id, refs[l] + k);
                            if ( err )
                                break;
                        }
                        if ( err )
                            break;
                    }
                }

                if ( MATIO_E_NO_ERROR == err ) {
                    hid_t struct_id = H5Gopen(id, name, H5P_DEFAULT);
                    for ( l = 0; l < nfields; l++ ) {
                        err = Mat_H5WriteAppendData(struct_id, H5T_STD_REF_OBJ, matvar->rank,
                                                    matvar->internal->fieldnames[l], matvar->dims,
                                                    dims, dim, 0, refs[l]);
                        if ( err )
                            break;
                    }
                    H5Gclose(struct_id);
                }
                for ( l = 0; l < nfields; l++ )
                    free(refs[l]);
                free(refs);
            }
        } else {
            /* Create with unlimited number of dimensions */
            if ( MAX_RANK >= matvar->rank ) {
                hsize_t max_dims[MAX_RANK];
                int k;
                for ( k = 0; k < matvar->rank; k++ ) {
                    max_dims[k] = H5S_UNLIMITED;
                }
                err = Mat_VarWriteStruct73(id, matvar, name, refs_id, dims, max_dims);
            } else {
                hsize_t *max_dims = (hsize_t *)malloc(matvar->rank * sizeof(hsize_t));
                if ( NULL != max_dims ) {
                    int k;
                    for ( k = 0; k < matvar->rank; k++ ) {
                        max_dims[k] = H5S_UNLIMITED;
                    }
                    err = Mat_VarWriteStruct73(id, matvar, name, refs_id, dims, max_dims);
                    free(max_dims);
                } else {
                    err = MATIO_E_OUT_OF_MEMORY;
                }
            }
        }
    }

    return err;
}

static int
Mat_VarWriteNext73(hid_t id, matvar_t *matvar, const char *name, hid_t *refs_id)
{
    int err;

    if ( NULL == matvar ) {
        size_t dims[2] = {0, 0};
        return Mat_WriteEmptyVariable73(id, name, 2, dims);
    }

    if ( MAX_RANK >= matvar->rank ) {
        hsize_t perm_dims[MAX_RANK];
        err = Mat_VarWriteNextType73(id, matvar, name, refs_id, perm_dims);
    } else {
        hsize_t *perm_dims = (hsize_t *)malloc(matvar->rank * sizeof(hsize_t));
        if ( NULL != perm_dims ) {
            err = Mat_VarWriteNextType73(id, matvar, name, refs_id, perm_dims);
            free(perm_dims);
        } else {
            err = MATIO_E_OUT_OF_MEMORY;
        }
    }

    return err;
}

static int
Mat_VarWriteAppendNext73(hid_t id, matvar_t *matvar, const char *name, hid_t *refs_id, int dim)
{
    int err;

    if ( MAX_RANK >= matvar->rank ) {
        hsize_t perm_dims[MAX_RANK];
        err = Mat_VarWriteAppendNextType73(id, matvar, name, refs_id, perm_dims, dim);
    } else {
        hsize_t *perm_dims = (hsize_t *)malloc(matvar->rank * sizeof(hsize_t));
        if ( NULL != perm_dims ) {
            err = Mat_VarWriteAppendNextType73(id, matvar, name, refs_id, perm_dims, dim);
            free(perm_dims);
        } else {
            err = MATIO_E_OUT_OF_MEMORY;
        }
    }

    return err;
}

static int
Mat_VarWriteNextType73(hid_t id, matvar_t *matvar, const char *name, hid_t *refs_id, hsize_t *dims)
{
    int err, k;

    /* Permute dimensions */
    for ( k = 0; k < matvar->rank; k++ ) {
        dims[k] = matvar->dims[matvar->rank - k - 1];
    }

    if ( matvar->isLogical && matvar->class_type != MAT_C_SPARSE ) {
        err = Mat_VarWriteLogical73(id, matvar, name, dims);
    } else {
        switch ( matvar->class_type ) {
            case MAT_C_DOUBLE:
            case MAT_C_SINGLE:
            case MAT_C_INT64:
            case MAT_C_UINT64:
            case MAT_C_INT32:
            case MAT_C_UINT32:
            case MAT_C_INT16:
            case MAT_C_UINT16:
            case MAT_C_INT8:
            case MAT_C_UINT8:
                err = Mat_VarWriteNumeric73(id, matvar, name, dims, NULL);
                break;
            case MAT_C_CHAR:
                err = Mat_VarWriteChar73(id, matvar, name, dims);
                break;
            case MAT_C_STRUCT:
                err = Mat_VarWriteStruct73(id, matvar, name, refs_id, dims, NULL);
                break;
            case MAT_C_CELL:
                err = Mat_VarWriteCell73(id, matvar, name, refs_id, dims);
                break;
            case MAT_C_SPARSE:
                err = Mat_VarWriteSparse73(id, matvar, name);
                break;
            case MAT_C_EMPTY:
                err = Mat_WriteEmptyVariable73(id, name, matvar->rank, matvar->dims);
                break;
            case MAT_C_FUNCTION:
            case MAT_C_OBJECT:
            case MAT_C_OPAQUE:
                err = MATIO_E_OPERATION_NOT_SUPPORTED;
                break;
            default:
                err = MATIO_E_OUTPUT_BAD_DATA;
                break;
        }
    }

    return err;
}

static int
Mat_VarWriteAppendNextType73(hid_t id, matvar_t *matvar, const char *name, hid_t *refs_id,
                             hsize_t *dims, int dim)
{
    int err, k;

    /* Permute dimensions */
    for ( k = 0; k < matvar->rank; k++ ) {
        dims[k] = matvar->dims[matvar->rank - k - 1];
    }

    if ( !matvar->isLogical ) {
        switch ( matvar->class_type ) {
            case MAT_C_DOUBLE:
            case MAT_C_SINGLE:
            case MAT_C_INT64:
            case MAT_C_UINT64:
            case MAT_C_INT32:
            case MAT_C_UINT32:
            case MAT_C_INT16:
            case MAT_C_UINT16:
            case MAT_C_INT8:
            case MAT_C_UINT8:
                err = Mat_VarWriteAppendNumeric73(id, matvar, name, dims, dim);
                break;
            case MAT_C_STRUCT:
                err = Mat_VarWriteAppendStruct73(id, matvar, name, refs_id, dims, dim);
                break;
            case MAT_C_EMPTY:
            case MAT_C_CHAR:
            case MAT_C_CELL:
            case MAT_C_SPARSE:
            case MAT_C_FUNCTION:
            case MAT_C_OBJECT:
            case MAT_C_OPAQUE:
                err = Mat_VarWriteNextType73(id, matvar, name, refs_id, dims);
                break;
            default:
                err = MATIO_E_OUTPUT_BAD_DATA;
                break;
        }
    } else {
        err = MATIO_E_OPERATION_NOT_SUPPORTED;
    }

    return err;
}

/** @if mat_devman
 * @brief Creates a new Matlab MAT version 7.3 file
 *
 * Tries to create a new Matlab MAT file with the given name and optional
 * header string.  If no header string is given, the default string
 * is used containing the software, version, and date in it.  If a header
 * string is given, at most the first 116 characters is written to the file.
 * The given header string need not be the full 116 characters, but MUST be
 * NULL terminated.
 * @ingroup mat_internal
 * @param matname Name of MAT file to create
 * @param hdr_str Optional header string, NULL to use default
 * @return A pointer to the MAT file or NULL if it failed.  This is not a
 * simple FILE * and should not be used as one.
 * @endif
 */
static mat_t *
Mat_Create73(const char *matname, const char *hdr_str)
{
    FILE *fp = NULL;
    mat_int16_t endian = 0, version;
    mat_t *mat = NULL;
    size_t err;
    time_t t;
    hid_t plist_id, fid, plist_ap;

    plist_id = H5Pcreate(H5P_FILE_CREATE);
    H5Pset_userblock(plist_id, 512);
    plist_ap = H5Pcreate(H5P_FILE_ACCESS);
#if H5_VERSION_GE(1, 10, 2)
    H5Pset_libver_bounds(plist_ap, H5F_LIBVER_EARLIEST, H5F_LIBVER_V18);
#endif
    fid = H5Fcreate(matname, H5F_ACC_TRUNC, plist_id, plist_ap);
    H5Fclose(fid);
    H5Pclose(plist_id);

#if defined(_WIN32) && defined(_MSC_VER) && H5_VERSION_GE(1, 11, 6)
    {
        wchar_t *wname = utf82u(matname);
        if ( NULL != wname ) {
            fp = _wfopen(wname, L"r+b");
            free(wname);
        }
    }
#else
    fp = fopen(matname, "r+b");
#endif
    if ( !fp ) {
        H5Pclose(plist_ap);
        return NULL;
    }

    (void)fseek(fp, 0, SEEK_SET);

    mat = (mat_t *)malloc(sizeof(*mat));
    if ( mat == NULL ) {
        fclose(fp);
        H5Pclose(plist_ap);
        return NULL;
    }

    mat->fp = NULL;
    mat->header = NULL;
    mat->subsys_offset = NULL;
    mat->filename = NULL;
    mat->version = 0;
    mat->byteswap = 0;
    mat->mode = 0;
    mat->bof = 128;
    mat->next_index = 0;
    mat->num_datasets = 0;
    mat->refs_id = -1;
    mat->dir = NULL;

    t = time(NULL);
    mat->filename = Mat_strdup(matname);
    mat->mode = MAT_ACC_RDWR;
    mat->byteswap = 0;
    mat->header = (char *)malloc(128 * sizeof(char));
    mat->subsys_offset = (char *)malloc(8 * sizeof(char));
    memset(mat->header, ' ', 128);
    if ( hdr_str == NULL ) {
        err = mat_snprintf(mat->header, 116,
                           "MATLAB 7.3 MAT-file, Platform: %s, "
                           "Created by: libmatio v%d.%d.%d on %s HDF5 schema 0.5",
                           MATIO_PLATFORM, MATIO_MAJOR_VERSION, MATIO_MINOR_VERSION,
                           MATIO_RELEASE_LEVEL, ctime(&t));
    } else {
        err = mat_snprintf(mat->header, 116, "%s", hdr_str);
    }
    if ( err >= 116 )
        mat->header[115] = '\0'; /* Just to make sure it's NULL terminated */
    memset(mat->subsys_offset, ' ', 8);
    mat->version = (int)0x0200;
    endian = 0x4d49;

    version = 0x0200;

    fwrite(mat->header, 1, 116, fp);
    fwrite(mat->subsys_offset, 1, 8, fp);
    fwrite(&version, 2, 1, fp);
    fwrite(&endian, 2, 1, fp);

    fclose(fp);

    fid = H5Fopen(matname, H5F_ACC_RDWR, plist_ap);
    H5Pclose(plist_ap);

    mat->fp = malloc(sizeof(hid_t));
    *(hid_t *)mat->fp = fid;

    return mat;
}

/** @if mat_devman
 * @brief Closes a MAT file
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @retval 0 on success
 * @endif
 */
static int
Mat_Close73(mat_t *mat)
{
    int err = MATIO_E_NO_ERROR;
    if ( mat->refs_id > -1 )
        H5Gclose(mat->refs_id);
    if ( 0 > H5Fclose(*(hid_t *)mat->fp) )
        err = MATIO_E_FILESYSTEM_ERROR_ON_CLOSE;
    free(mat->fp);
    mat->fp = NULL;
    return err;
}

/** @if mat_devman
 * @brief Reads the MAT variable identified by matvar
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar MAT variable pointer
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarRead73(mat_t *mat, matvar_t *matvar)
{
    int err = MATIO_E_NO_ERROR;
    hid_t fid, dset_id, ref_id;

    if ( NULL == mat || NULL == matvar )
        return MATIO_E_BAD_ARGUMENT;
    else if ( NULL == matvar->internal->hdf5_name && 0 > matvar->internal->id )
        return MATIO_E_READ_VARIABLE_DOES_NOT_EXIST;

    fid = *(hid_t *)mat->fp;

    switch ( matvar->class_type ) {
        case MAT_C_DOUBLE:
        case MAT_C_SINGLE:
        case MAT_C_INT64:
        case MAT_C_UINT64:
        case MAT_C_INT32:
        case MAT_C_UINT32:
        case MAT_C_INT16:
        case MAT_C_UINT16:
        case MAT_C_INT8:
        case MAT_C_UINT8: {
            size_t nelems = 1;
            matvar->data_size = (int)Mat_SizeOfClass(matvar->class_type);
            err = Mat_MulDims(matvar, &nelems);
            if ( err ) {
                Mat_Critical("Integer multiplication overflow");
                return err;
            }
            err = Mul(&matvar->nbytes, nelems, matvar->data_size);
            if ( err ) {
                Mat_Critical("Integer multiplication overflow");
                return err;
            }

            if ( nelems < 1 )
                break;

            if ( NULL != matvar->internal->hdf5_name ) {
                ref_id = H5Dopen(fid, matvar->internal->hdf5_name, H5P_DEFAULT);
            } else {
                ref_id = matvar->internal->id;
                H5Iinc_ref(ref_id);
            }
            if ( 0 < matvar->internal->hdf5_ref ) {
                dset_id = H5RDEREFERENCE(ref_id, H5R_OBJECT, &matvar->internal->hdf5_ref);
            } else {
                dset_id = ref_id;
                H5Iinc_ref(dset_id);
            }

            if ( !matvar->isComplex ) {
                matvar->data = malloc(matvar->nbytes);
            } else {
                matvar->data = ComplexMalloc(matvar->nbytes);
            }
            if ( NULL != matvar->data ) {
                err = Mat_H5ReadData(dset_id, ClassType2H5T(matvar->class_type), H5S_ALL, H5S_ALL,
                                     matvar->isComplex, matvar->data);
            }
            H5Dclose(dset_id);
            H5Dclose(ref_id);
            break;
        }
        case MAT_C_CHAR: {
            size_t nelems = 1;
            matvar->data_size = (int)Mat_SizeOf(matvar->data_type);
            err = Mat_MulDims(matvar, &nelems);
            if ( err ) {
                Mat_Critical("Integer multiplication overflow");
                return err;
            }
            err = Mul(&matvar->nbytes, nelems, matvar->data_size);
            if ( err ) {
                Mat_Critical("Integer multiplication overflow");
                return err;
            }

            if ( NULL != matvar->internal->hdf5_name ) {
                dset_id = H5Dopen(fid, matvar->internal->hdf5_name, H5P_DEFAULT);
            } else {
                dset_id = matvar->internal->id;
                H5Iinc_ref(dset_id);
            }
            if ( matvar->nbytes > 0 ) {
                matvar->data = malloc(matvar->nbytes);
                if ( NULL != matvar->data ) {
                    herr_t herr = H5Dread(dset_id, DataType2H5T(matvar->data_type), H5S_ALL,
                                          H5S_ALL, H5P_DEFAULT, matvar->data);
                    if ( herr < 0 ) {
                        err = MATIO_E_GENERIC_READ_ERROR;
                    }
                } else {
                    err = MATIO_E_OUT_OF_MEMORY;
                }
            }
            H5Dclose(dset_id);
            break;
        }
        case MAT_C_STRUCT: {
            matvar_t **fields;
            size_t i, nelems_x_nfields, nelems = 1;

            if ( !matvar->internal->num_fields || NULL == matvar->data )
                break;

            err = Mat_MulDims(matvar, &nelems);
            if ( err ) {
                Mat_Critical("Integer multiplication overflow");
                return err;
            }
            err = Mul(&nelems_x_nfields, nelems, matvar->internal->num_fields);
            if ( err ) {
                Mat_Critical("Integer multiplication overflow");
                return err;
            }

            fields = (matvar_t **)matvar->data;
            for ( i = 0; i < nelems_x_nfields; i++ ) {
                if ( NULL != fields[i] && 0 < fields[i]->internal->hdf5_ref &&
                     -1 < fields[i]->internal->id ) {
                    /* Dataset of references */
                    err = Mat_H5ReadNextReferenceData(fields[i]->internal->id, fields[i], mat);
                } else {
                    err = Mat_VarRead73(mat, fields[i]);
                }
                if ( err ) {
                    break;
                }
            }
            break;
        }
        case MAT_C_CELL: {
            matvar_t **cells;
            size_t i, nelems;

            if ( NULL == matvar->data ) {
                Mat_Critical("Data is NULL for cell array %s", matvar->name);
                err = MATIO_E_FILE_FORMAT_VIOLATION;
                break;
            }
            nelems = matvar->nbytes / matvar->data_size;
            cells = (matvar_t **)matvar->data;
            for ( i = 0; i < nelems; i++ ) {
                if ( NULL != cells[i] ) {
                    err = Mat_H5ReadNextReferenceData(cells[i]->internal->id, cells[i], mat);
                }
                if ( err ) {
                    break;
                }
            }
            break;
        }
        case MAT_C_SPARSE: {
            hid_t sparse_dset_id;
            mat_sparse_t *sparse_data = (mat_sparse_t *)calloc(1, sizeof(*sparse_data));

            if ( NULL != matvar->internal->hdf5_name ) {
                dset_id = H5Gopen(fid, matvar->internal->hdf5_name, H5P_DEFAULT);
            } else {
                dset_id = matvar->internal->id;
                H5Iinc_ref(dset_id);
            }

            if ( H5Lexists(dset_id, "ir", H5P_DEFAULT) ) {
                size_t *dims;
                hsize_t nelems;
                int rank;

                sparse_dset_id = H5Dopen(dset_id, "ir", H5P_DEFAULT);
                dims = Mat_H5ReadDims(sparse_dset_id, &nelems, &rank);
                if ( NULL != dims ) {
                    size_t nbytes;
                    sparse_data->nir = (mat_uint32_t)dims[0];
                    free(dims);
                    err = Mul(&nbytes, sparse_data->nir, sizeof(mat_uint32_t));
                    if ( err ) {
                        H5Dclose(sparse_dset_id);
                        H5Gclose(dset_id);
                        free(sparse_data);
                        Mat_Critical("Integer multiplication overflow");
                        return err;
                    }
                    sparse_data->ir = (mat_uint32_t *)malloc(nbytes);
                    if ( sparse_data->ir != NULL ) {
                        herr_t herr = H5Dread(sparse_dset_id, H5T_NATIVE_UINT, H5S_ALL, H5S_ALL,
                                              H5P_DEFAULT, sparse_data->ir);
                        if ( herr < 0 ) {
                            err = MATIO_E_GENERIC_READ_ERROR;
                        }
                    } else {
                        err = MATIO_E_OUT_OF_MEMORY;
                    }
                } else {
                    err = MATIO_E_UNKNOWN_ERROR;
                }
                H5Dclose(sparse_dset_id);
                if ( err ) {
                    H5Gclose(dset_id);
                    free(sparse_data);
                    return err;
                }
            }

            if ( H5Lexists(dset_id, "jc", H5P_DEFAULT) ) {
                size_t *dims;
                hsize_t nelems;
                int rank;

                sparse_dset_id = H5Dopen(dset_id, "jc", H5P_DEFAULT);
                dims = Mat_H5ReadDims(sparse_dset_id, &nelems, &rank);
                if ( NULL != dims ) {
                    size_t nbytes;
                    sparse_data->njc = (mat_uint32_t)dims[0];
                    free(dims);
                    err = Mul(&nbytes, sparse_data->njc, sizeof(mat_uint32_t));
                    if ( err ) {
                        H5Dclose(sparse_dset_id);
                        H5Gclose(dset_id);
                        free(sparse_data);
                        Mat_Critical("Integer multiplication overflow");
                        return err;
                    }
                    sparse_data->jc = (mat_uint32_t *)malloc(nbytes);
                    if ( sparse_data->jc != NULL ) {
                        herr_t herr = H5Dread(sparse_dset_id, H5T_NATIVE_UINT, H5S_ALL, H5S_ALL,
                                              H5P_DEFAULT, sparse_data->jc);
                        if ( herr < 0 ) {
                            err = MATIO_E_GENERIC_READ_ERROR;
                        }
                    } else {
                        err = MATIO_E_OUT_OF_MEMORY;
                    }
                } else {
                    err = MATIO_E_UNKNOWN_ERROR;
                }
                H5Dclose(sparse_dset_id);
                if ( err ) {
                    H5Gclose(dset_id);
                    free(sparse_data);
                    return err;
                }
            }

            if ( H5Lexists(dset_id, "data", H5P_DEFAULT) ) {
                size_t *dims;
                hsize_t nelems;
                int rank;

                sparse_dset_id = H5Dopen(dset_id, "data", H5P_DEFAULT);
                dims = Mat_H5ReadDims(sparse_dset_id, &nelems, &rank);
                if ( NULL != dims ) {
                    size_t ndata_bytes;
                    sparse_data->nzmax = (mat_uint32_t)dims[0];
                    sparse_data->ndata = (mat_uint32_t)dims[0];
                    free(dims);
                    err = Mul(&ndata_bytes, sparse_data->nzmax, Mat_SizeOf(matvar->data_type));
                    if ( err ) {
                        H5Dclose(sparse_dset_id);
                        H5Gclose(dset_id);
                        free(sparse_data);
                        Mat_Critical("Integer multiplication overflow");
                        return err;
                    }
                    matvar->data_size = sizeof(mat_sparse_t);
                    matvar->nbytes = matvar->data_size;
                    if ( !matvar->isComplex ) {
                        sparse_data->data = malloc(ndata_bytes);
                    } else {
                        sparse_data->data = ComplexMalloc(ndata_bytes);
                    }
                    if ( NULL != sparse_data->data ) {
                        err =
                            Mat_H5ReadData(sparse_dset_id, DataType2H5T(matvar->data_type), H5S_ALL,
                                           H5S_ALL, matvar->isComplex, sparse_data->data);
                    } else {
                        err = MATIO_E_OUT_OF_MEMORY;
                    }
                }
                H5Dclose(sparse_dset_id);
            }
            H5Gclose(dset_id);
            matvar->data = sparse_data;
            break;
        }
        case MAT_C_EMPTY:
        case MAT_C_FUNCTION:
        case MAT_C_OBJECT:
        case MAT_C_OPAQUE:
            break;
        default:
            err = MATIO_E_FAIL_TO_IDENTIFY;
            break;
    }
    return err;
}

/** @if mat_devman
 * @brief Reads a slab of data from the mat variable @c matvar
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @param data pointer to store the read data in (must be of size
 *        edge[0]*...edge[rank-1]*Mat_SizeOfClass(matvar->class_type))
 * @param start index to start reading data in each dimension
 * @param stride write data every @c stride elements in each dimension
 * @param edge number of elements to read in each dimension
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarReadData73(mat_t *mat, matvar_t *matvar, void *data, int *start, int *stride, int *edge)
{
    int err = MATIO_E_NO_ERROR, k;
    hid_t fid, dset_id, ref_id, dset_space, mem_space;
    hsize_t *dset_start_stride_edge;
    hsize_t *dset_start, *dset_stride, *dset_edge;

    if ( NULL == mat || NULL == matvar || NULL == data || NULL == start || NULL == stride ||
         NULL == edge )
        return MATIO_E_BAD_ARGUMENT;
    else if ( NULL == matvar->internal->hdf5_name && 0 > matvar->internal->id )
        return MATIO_E_FAIL_TO_IDENTIFY;

    fid = *(hid_t *)mat->fp;

    dset_start_stride_edge = (hsize_t *)malloc(matvar->rank * 3 * sizeof(hsize_t));
    if ( NULL == dset_start_stride_edge ) {
        return MATIO_E_OUT_OF_MEMORY;
    }
    dset_start = &dset_start_stride_edge[0];
    dset_stride = &dset_start_stride_edge[matvar->rank];
    dset_edge = &dset_start_stride_edge[2 * matvar->rank];

    for ( k = 0; k < matvar->rank; k++ ) {
        dset_start[k] = start[matvar->rank - k - 1];
        dset_stride[k] = stride[matvar->rank - k - 1];
        dset_edge[k] = edge[matvar->rank - k - 1];
    }
    mem_space = H5Screate_simple(matvar->rank, dset_edge, NULL);

    switch ( matvar->class_type ) {
        case MAT_C_DOUBLE:
        case MAT_C_SINGLE:
        case MAT_C_INT64:
        case MAT_C_UINT64:
        case MAT_C_INT32:
        case MAT_C_UINT32:
        case MAT_C_INT16:
        case MAT_C_UINT16:
        case MAT_C_INT8:
        case MAT_C_UINT8:
            if ( NULL != matvar->internal->hdf5_name ) {
                ref_id = H5Dopen(fid, matvar->internal->hdf5_name, H5P_DEFAULT);
            } else {
                ref_id = matvar->internal->id;
                H5Iinc_ref(ref_id);
            }
            if ( 0 < matvar->internal->hdf5_ref ) {
                dset_id = H5RDEREFERENCE(ref_id, H5R_OBJECT, &matvar->internal->hdf5_ref);
            } else {
                dset_id = ref_id;
                H5Iinc_ref(dset_id);
            }

            dset_space = H5Dget_space(dset_id);
            H5Sselect_hyperslab(dset_space, H5S_SELECT_SET, dset_start, dset_stride, dset_edge,
                                NULL);
            err = Mat_H5ReadData(dset_id, ClassType2H5T(matvar->class_type), mem_space, dset_space,
                                 matvar->isComplex, data);
            H5Sclose(dset_space);
            H5Dclose(dset_id);
            H5Dclose(ref_id);
            break;
        default:
            err = MATIO_E_FAIL_TO_IDENTIFY;
            break;
    }
    H5Sclose(mem_space);
    free(dset_start_stride_edge);

    return err;
}

/** @if mat_devman
 * @brief Reads a subset of a MAT variable using a 1-D indexing
 *
 * Reads data from a MAT variable using a linear (1-D) indexing mode. The
 * variable must have been read by Mat_VarReadInfo.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @param data pointer to store the read data in (must be of size
 *        edge*Mat_SizeOfClass(matvar->class_type))
 * @param start starting index
 * @param stride stride of data
 * @param edge number of elements to read
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarReadDataLinear73(mat_t *mat, matvar_t *matvar, void *data, int start, int stride, int edge)
{
    int err = MATIO_E_NO_ERROR, k;
    hid_t fid, dset_id, dset_space, mem_space;
    hsize_t *points, dset_edge, *dimp;

    if ( NULL == mat || NULL == matvar || NULL == data )
        return MATIO_E_BAD_ARGUMENT;
    else if ( NULL == matvar->internal->hdf5_name && 0 > matvar->internal->id )
        return MATIO_E_FAIL_TO_IDENTIFY;

    fid = *(hid_t *)mat->fp;

    dset_edge = edge;
    mem_space = H5Screate_simple(1, &dset_edge, NULL);

    switch ( matvar->class_type ) {
        case MAT_C_DOUBLE:
        case MAT_C_SINGLE:
        case MAT_C_INT64:
        case MAT_C_UINT64:
        case MAT_C_INT32:
        case MAT_C_UINT32:
        case MAT_C_INT16:
        case MAT_C_UINT16:
        case MAT_C_INT8:
        case MAT_C_UINT8:
            points = (hsize_t *)malloc(matvar->rank * (size_t)dset_edge * sizeof(*points));
            if ( NULL == points ) {
                err = MATIO_E_OUT_OF_MEMORY;
                break;
            }
            dimp = (hsize_t *)malloc(matvar->rank * sizeof(hsize_t));
            if ( NULL == dimp ) {
                err = MATIO_E_OUT_OF_MEMORY;
                free(points);
                break;
            }
            dimp[0] = 1;
            for ( k = 1; k < matvar->rank; k++ )
                dimp[k] = dimp[k - 1] * matvar->dims[k - 1];
            for ( k = 0; k < edge; k++ ) {
                size_t l, coord;
                coord = (size_t)(start + k * stride);
                for ( l = matvar->rank; l--; ) {
                    size_t idx = (size_t)(coord / dimp[l]);
                    points[matvar->rank * (k + 1) - 1 - l] = idx;
                    coord -= idx * (size_t)dimp[l];
                }
            }
            free(dimp);

            if ( NULL != matvar->internal->hdf5_name ) {
                dset_id = H5Dopen(fid, matvar->internal->hdf5_name, H5P_DEFAULT);
            } else {
                dset_id = matvar->internal->id;
                H5Iinc_ref(dset_id);
            }
            dset_space = H5Dget_space(dset_id);
            H5Sselect_elements(dset_space, H5S_SELECT_SET, (size_t)dset_edge, points);
            free(points);
            err = Mat_H5ReadData(dset_id, ClassType2H5T(matvar->class_type), mem_space, dset_space,
                                 matvar->isComplex, data);
            H5Sclose(dset_space);
            H5Dclose(dset_id);
            break;
        default:
            err = MATIO_E_FAIL_TO_IDENTIFY;
            break;
    }
    H5Sclose(mem_space);

    return err;
}

/** @if mat_devman
 * @brief Reads the header information for the next MAT variable
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @return pointer to the MAT variable or NULL
 * @endif
 */
static matvar_t *
Mat_VarReadNextInfo73(mat_t *mat)
{
    hid_t id;
    hsize_t idx;
    herr_t herr;
    struct ReadNextIterData mat_data;

    if ( mat == NULL )
        return NULL;

    if ( mat->next_index >= mat->num_datasets )
        return NULL;

    id = *(hid_t *)mat->fp;
    idx = (hsize_t)mat->next_index;
    mat_data.mat = mat;
    mat_data.matvar = NULL;
    herr = H5Literate(id, H5_INDEX_NAME, H5_ITER_NATIVE, &idx, Mat_VarReadNextInfoIterate,
                      (void *)&mat_data);
    if ( herr > 0 )
        mat->next_index = (size_t)idx;
    return mat_data.matvar;
}

static herr_t
Mat_VarReadNextInfoIterate(hid_t id, const char *name, const H5L_info_t *info, void *op_data)
{
    mat_t *mat;
    H5O_INFO_T object_info;
    struct ReadNextIterData *mat_data;

    /* FIXME: follow symlinks, datatypes? */

    /* Check that this is not the /#refs# or /"#subsystem#" group */
    if ( 0 == strcmp(name, "#refs#") || 0 == strcmp(name, "#subsystem#") )
        return 0;

    object_info.type = H5O_TYPE_UNKNOWN;
    H5OGET_INFO_BY_NAME(id, name, &object_info, H5P_DEFAULT);
    if ( H5O_TYPE_DATASET != object_info.type && H5O_TYPE_GROUP != object_info.type )
        return 0;

    mat_data = (struct ReadNextIterData *)op_data;
    if ( NULL == mat_data )
        return -1;
    mat = mat_data->mat;

    switch ( object_info.type ) {
        case H5O_TYPE_DATASET: {
            int err;
            hid_t dset_id;
            matvar_t *matvar = Mat_VarCalloc();
            if ( NULL == matvar )
                return -1;

            matvar->name = Mat_strdup(name);
            if ( NULL == matvar->name ) {
                Mat_VarFree(matvar);
                return -1;
            }

            dset_id = H5Dopen(id, name, H5P_DEFAULT);
            err = Mat_H5ReadDatasetInfo(mat, matvar, dset_id);
            if ( matvar->internal->id != dset_id ) {
                /* Close dataset and increment count */
                H5Dclose(dset_id);
            }
            if ( err ) {
                Mat_VarFree(matvar);
                return -1;
            }
            mat_data->matvar = matvar;
            break;
        }
        case H5O_TYPE_GROUP: {
            int err;
            hid_t dset_id;
            matvar_t *matvar = Mat_VarCalloc();
            if ( NULL == matvar )
                return -1;

            matvar->name = Mat_strdup(name);
            if ( NULL == matvar->name ) {
                Mat_VarFree(matvar);
                return -1;
            }

            dset_id = H5Gopen(id, name, H5P_DEFAULT);
            err = Mat_H5ReadGroupInfo(mat, matvar, dset_id);
            H5Gclose(dset_id);
            if ( err ) {
                Mat_VarFree(matvar);
                return -1;
            }
            mat_data->matvar = matvar;
            break;
        }
        default:
            break;
    }

    return 1;
}

/** @if mat_devman
 * @brief Writes a matlab variable to a version 7.3 matlab file
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @param compress option to compress the variable
 *        (only works for numeric types)
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWrite73(mat_t *mat, matvar_t *matvar, int compress)
{
    hid_t id;

    if ( NULL == mat || NULL == matvar )
        return MATIO_E_BAD_ARGUMENT;

    matvar->compression = (enum matio_compression)compress;

    id = *(hid_t *)mat->fp;
    return Mat_VarWriteNext73(id, matvar, matvar->name, &(mat->refs_id));
}

/** @if mat_devman
 * @brief Writes/appends a matlab variable to a version 7.3 matlab file
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @param compress option to compress the variable
 *        (only works for numeric types)
 * @param dim dimension to append data
 *        (only works for numeric types)
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWriteAppend73(mat_t *mat, matvar_t *matvar, int compress, int dim)
{
    hid_t id;

    if ( NULL == mat || NULL == matvar )
        return MATIO_E_BAD_ARGUMENT;

    matvar->compression = (enum matio_compression)compress;

    id = *(hid_t *)mat->fp;
    return Mat_VarWriteAppendNext73(id, matvar, matvar->name, &(mat->refs_id), dim);
}

#endif

/* -------------------------------
 * ---------- matvar_cell.c
 * -------------------------------
 */

/** @brief Returns a pointer to the Cell array at a specific index
 *
 * Returns a pointer to the Cell Array Field at the given 1-relative index.
 * MAT file must be a version 5 matlab file.
 * @ingroup MAT
 * @param matvar Pointer to the Cell Array MAT variable
 * @param index linear index of cell to return
 * @return Pointer to the Cell Array Field on success, NULL on error
 */
matvar_t *
Mat_VarGetCell(matvar_t *matvar, int index)
{
    size_t nelems = 1;
    matvar_t *cell = NULL;
    int err;

    if ( matvar == NULL )
        return NULL;

    err = Mat_MulDims(matvar, &nelems);
    if ( err )
        return NULL;

    if ( 0 <= index && (size_t)index < nelems )
        cell = *((matvar_t **)matvar->data + index);

    return cell;
}

/** @brief Indexes a cell array
 *
 * Finds cells of a cell array given a start, stride, and edge for each.
 * dimension.  The cells are placed in a pointer array.  The cells should not
 * be freed, but the array of pointers should be.  If copies are needed,
 * use Mat_VarDuplicate on each cell.
 *
 * Note that this function is limited to structure arrays with a rank less than
 * 10.
 *
 * @ingroup MAT
 * @param matvar Cell Array matlab variable
 * @param start vector of length rank with 0-relative starting coordinates for
 *              each dimension.
 * @param stride vector of length rank with strides for each dimension.
 * @param edge vector of length rank with the number of elements to read in
 *              each dimension.
 * @returns an array of pointers to the cells
 */
matvar_t **
Mat_VarGetCells(matvar_t *matvar, int *start, int *stride, int *edge)
{
    int i, j, N, I;
    size_t idx[10] =
        {
            0,
        },
           cnt[10] =
               {
                   0,
               },
           dimp[10] = {
               0,
           };
    matvar_t **cells;

    if ( matvar == NULL || start == NULL || stride == NULL || edge == NULL ) {
        return NULL;
    } else if ( matvar->rank > 9 ) {
        return NULL;
    }

    dimp[0] = matvar->dims[0];
    N = edge[0];
    I = start[0];
    idx[0] = start[0];
    for ( i = 1; i < matvar->rank; i++ ) {
        idx[i] = start[i];
        dimp[i] = dimp[i - 1] * matvar->dims[i];
        N *= edge[i];
        I += start[i] * dimp[i - 1];
    }
    cells = (matvar_t **)malloc(N * sizeof(matvar_t *));
    for ( i = 0; i < N; i += edge[0] ) {
        for ( j = 0; j < edge[0]; j++ ) {
            cells[i + j] = *((matvar_t **)matvar->data + I);
            I += stride[0];
        }
        idx[0] = start[0];
        I = idx[0];
        cnt[1]++;
        idx[1] += stride[1];
        for ( j = 1; j < matvar->rank; j++ ) {
            if ( cnt[j] == (size_t)edge[j] ) {
                cnt[j] = 0;
                idx[j] = start[j];
                if ( j < matvar->rank - 1 ) {
                    cnt[j + 1]++;
                    idx[j + 1] += stride[j + 1];
                }
            }
            I += idx[j] * dimp[j - 1];
        }
    }
    return cells;
}

/** @brief Indexes a cell array
 *
 * Finds cells of a cell array given a linear indexed start, stride, and edge.
 * The cells are placed in a pointer array.  The cells themself should not
 * be freed as they are part of the original cell array, but the pointer array
 * should be.  If copies are needed, use Mat_VarDuplicate on each of the cells.
 * MAT file version must be 5.
 * @ingroup MAT
 * @param matvar Cell Array matlab variable
 * @param start starting index
 * @param stride stride
 * @param edge Number of cells to get
 * @returns an array of pointers to the cells
 */
matvar_t **
Mat_VarGetCellsLinear(matvar_t *matvar, int start, int stride, int edge)
{
    matvar_t **cells = NULL;

    if ( matvar != NULL ) {
        int i, I;
        cells = (matvar_t **)malloc(edge * sizeof(matvar_t *));
        I = start;
        for ( i = 0; i < edge; i++ ) {
            cells[i] = *((matvar_t **)matvar->data + I);
            I += stride;
        }
    }
    return cells;
}

/** @brief Sets the element of the cell array at the specific index
 *
 * Sets the element of the cell array at the given 0-relative index to @c cell.
 * @ingroup MAT
 * @param matvar Pointer to the cell array variable
 * @param index 0-relative linear index of the cell to set
 * @param cell Pointer to the cell to set
 * @return Pointer to the previous cell element, or NULL if there was no
*          previous cell element or error.
 */
matvar_t *
Mat_VarSetCell(matvar_t *matvar, int index, matvar_t *cell)
{
    size_t nelems = 1;
    matvar_t **cells, *old_cell = NULL;
    int err;

    if ( matvar == NULL || matvar->rank < 1 )
        return NULL;

    err = Mat_MulDims(matvar, &nelems);
    if ( err )
        return NULL;

    cells = (matvar_t **)matvar->data;
    if ( 0 <= index && (size_t)index < nelems ) {
        old_cell = cells[index];
        cells[index] = cell;
    }

    return old_cell;
}

/* -------------------------------
 * ---------- matvar_struct.c
 * -------------------------------
 */

/** @brief Creates a structure MATLAB variable with the given name and fields
 *
 * @ingroup MAT
 * @param name Name of the structure variable to create
 * @param rank Rank of the variable
 * @param dims array of dimensions of the variable of size rank
 * @param fields Array of @c nfields fieldnames
 * @param nfields Number of fields in the structure
 * @return Pointer to the new structure MATLAB variable on success, NULL on error
 */
matvar_t *
Mat_VarCreateStruct(const char *name, int rank, size_t *dims, const char **fields, unsigned nfields)
{
    size_t nelems = 1;
    int j;
    matvar_t *matvar;

    if ( NULL == dims )
        return NULL;

    matvar = Mat_VarCalloc();
    if ( NULL == matvar )
        return NULL;

    matvar->compression = MAT_COMPRESSION_NONE;
    if ( NULL != name )
        matvar->name = Mat_strdup(name);
    matvar->rank = rank;
    matvar->dims = (size_t *)malloc(matvar->rank * sizeof(*matvar->dims));
    for ( j = 0; j < matvar->rank; j++ ) {
        matvar->dims[j] = dims[j];
        nelems *= dims[j];
    }
    matvar->class_type = MAT_C_STRUCT;
    matvar->data_type = MAT_T_STRUCT;

    matvar->data_size = sizeof(matvar_t *);

    if ( nfields ) {
        matvar->internal->num_fields = nfields;
        matvar->internal->fieldnames =
            (char **)malloc(nfields * sizeof(*matvar->internal->fieldnames));
        if ( NULL == matvar->internal->fieldnames ) {
            Mat_VarFree(matvar);
            matvar = NULL;
        } else {
            size_t i;
            for ( i = 0; i < nfields; i++ ) {
                if ( NULL == fields[i] ) {
                    Mat_VarFree(matvar);
                    matvar = NULL;
                    break;
                } else {
                    matvar->internal->fieldnames[i] = Mat_strdup(fields[i]);
                }
            }
        }
        if ( NULL != matvar && nelems > 0 ) {
            size_t nelems_x_nfields;
            int err = Mul(&nelems_x_nfields, nelems, nfields);
            err |= Mul(&matvar->nbytes, nelems_x_nfields, matvar->data_size);
            if ( err ) {
                Mat_VarFree(matvar);
                return NULL;
            }
            matvar->data = calloc(nelems_x_nfields, matvar->data_size);
        }
    }

    return matvar;
}

/** @brief Adds a field to a structure
 *
 * Adds the given field to the structure. fields should be an array of matvar_t
 * pointers of the same size as the structure (i.e. 1 field per structure
 * element).
 * @ingroup MAT
 * @param matvar Pointer to the Structure MAT variable
 * @param fieldname Name of field to be added
 * @retval 0 on success
 */
int
Mat_VarAddStructField(matvar_t *matvar, const char *fieldname)
{
    int err;
    int cnt = 0;
    size_t i, nfields, nelems = 1;
    matvar_t **new_data, **old_data;
    char **fieldnames;

    if ( matvar == NULL || fieldname == NULL )
        return -1;

    err = Mat_MulDims(matvar, &nelems);
    if ( err )
        return -1;

    matvar->internal->num_fields++;
    nfields = matvar->internal->num_fields;
    fieldnames = (char **)realloc(matvar->internal->fieldnames,
                                  nfields * sizeof(*matvar->internal->fieldnames));
    if ( NULL == fieldnames )
        return -1;
    matvar->internal->fieldnames = fieldnames;
    matvar->internal->fieldnames[nfields - 1] = Mat_strdup(fieldname);

    {
        size_t nelems_x_nfields;
        err = Mul(&nelems_x_nfields, nelems, nfields);
        err |= Mul(&matvar->nbytes, nelems_x_nfields, sizeof(*new_data));
        if ( err ) {
            matvar->nbytes = 0;
            return -1;
        }
    }
    new_data = (matvar_t **)malloc(matvar->nbytes);
    if ( new_data == NULL ) {
        matvar->nbytes = 0;
        return -1;
    }

    old_data = (matvar_t **)matvar->data;
    for ( i = 0; i < nelems; i++ ) {
        size_t f;
        for ( f = 0; f < nfields - 1; f++ )
            new_data[cnt++] = old_data[i * (nfields - 1) + f];
        new_data[cnt++] = NULL;
    }

    free(matvar->data);
    matvar->data = new_data;

    return 0;
}

/** @brief Returns the number of fields in a structure variable
 *
 * Returns the number of fields in the given structure.
 * @ingroup MAT
 * @param matvar Structure matlab variable
 * @returns Number of fields
 */
unsigned
Mat_VarGetNumberOfFields(matvar_t *matvar)
{
    int nfields;
    if ( matvar == NULL || matvar->class_type != MAT_C_STRUCT || NULL == matvar->internal ) {
        nfields = 0;
    } else {
        nfields = matvar->internal->num_fields;
    }
    return nfields;
}

/** @brief Returns the fieldnames of a structure variable
 *
 * Returns the fieldnames for the given structure. The returned pointers are
 * internal to the structure and should not be free'd.
 * @ingroup MAT
 * @param matvar Structure matlab variable
 * @returns Array of fieldnames
 */
char *const *
Mat_VarGetStructFieldnames(const matvar_t *matvar)
{
    if ( matvar == NULL || matvar->class_type != MAT_C_STRUCT || NULL == matvar->internal ) {
        return NULL;
    } else {
        return matvar->internal->fieldnames;
    }
}

/** @brief Finds a field of a structure by the field's index
 *
 * Returns a pointer to the structure field at the given 0-relative index.
 * @ingroup MAT
 * @param matvar Pointer to the Structure MAT variable
 * @param field_index 0-relative index of the field.
 * @param index linear index of the structure array
 * @return Pointer to the structure field on success, NULL on error
 */
matvar_t *
Mat_VarGetStructFieldByIndex(matvar_t *matvar, size_t field_index, size_t index)
{
    int err;
    matvar_t *field = NULL;
    size_t nelems = 1, nfields;

    if ( matvar == NULL || matvar->class_type != MAT_C_STRUCT || matvar->data_size == 0 )
        return NULL;

    err = Mat_MulDims(matvar, &nelems);
    if ( err )
        return NULL;

    nfields = matvar->internal->num_fields;

    if ( nelems > 0 && index >= nelems ) {
        Mat_Critical("Mat_VarGetStructField: structure index out of bounds");
    } else if ( nfields > 0 ) {
        if ( field_index > nfields ) {
            Mat_Critical("Mat_VarGetStructField: field index out of bounds");
        } else {
            field = *((matvar_t **)matvar->data + index * nfields + field_index);
        }
    }

    return field;
}

/** @brief Finds a field of a structure by the field's name
 *
 * Returns a pointer to the structure field at the given 0-relative index.
 * @ingroup MAT
 * @param matvar Pointer to the Structure MAT variable
 * @param field_name Name of the structure field
 * @param index linear index of the structure array
 * @return Pointer to the structure field on success, NULL on error
 */
matvar_t *
Mat_VarGetStructFieldByName(matvar_t *matvar, const char *field_name, size_t index)
{
    int i, nfields, field_index, err;
    matvar_t *field = NULL;
    size_t nelems = 1;

    if ( matvar == NULL || matvar->class_type != MAT_C_STRUCT || matvar->data_size == 0 )
        return NULL;

    err = Mat_MulDims(matvar, &nelems);
    if ( err )
        return NULL;

    nfields = matvar->internal->num_fields;
    field_index = -1;
    for ( i = 0; i < nfields; i++ ) {
        if ( !strcmp(matvar->internal->fieldnames[i], field_name) ) {
            field_index = i;
            break;
        }
    }

    if ( index >= nelems ) {
        Mat_Critical("Mat_VarGetStructField: structure index out of bounds");
    } else if ( field_index >= 0 ) {
        field = *((matvar_t **)matvar->data + index * nfields + field_index);
    }

    return field;
}

/** @brief Finds a field of a structure
 *
 * Returns a pointer to the structure field at the given 0-relative index.
 * @ingroup MAT
 * @param matvar Pointer to the Structure MAT variable
 * @param name_or_index Name of the field, or the 1-relative index of the field
 * If the index is used, it should be the address of an integer variable whose
 * value is the index number.
 * @param opt MAT_BY_NAME if the name_or_index is the name or MAT_BY_INDEX if
 *            the index was passed.
 * @param index linear index of the structure to find the field of
 * @return Pointer to the Structure Field on success, NULL on error
 */
matvar_t *
Mat_VarGetStructField(matvar_t *matvar, void *name_or_index, int opt, int index)
{
    int err, nfields;
    matvar_t *field = NULL;
    size_t nelems = 1;

    err = Mat_MulDims(matvar, &nelems);
    nfields = matvar->internal->num_fields;
    if ( index < 0 || (nelems > 0 && (size_t)index >= nelems) )
        err = 1;
    else if ( nfields < 1 )
        err = 1;

    if ( !err && (opt == MAT_BY_INDEX) ) {
        size_t field_index = *(int *)name_or_index;
        if ( field_index > 0 )
            field = Mat_VarGetStructFieldByIndex(matvar, field_index - 1, index);
    } else if ( !err && (opt == MAT_BY_NAME) ) {
        field = Mat_VarGetStructFieldByName(matvar, (const char *)name_or_index, index);
    }

    return field;
}

/** @brief Indexes a structure
 *
 * Finds structures of a structure array given a start, stride, and edge for
 * each dimension.  The structures are placed in a new structure array.  If
 * copy_fields is non-zero, the indexed structures are copied and should be
 * freed, but if copy_fields is zero, the indexed structures are pointers to
 * the original, but should still be freed. The structures have a flag set
 * so that the structure fields are not freed.
 *
 * Note that this function is limited to structure arrays with a rank less than
 * 10.
 *
 * @ingroup MAT
 * @param matvar Structure matlab variable
 * @param start vector of length rank with 0-relative starting coordinates for
 *              each dimension.
 * @param stride vector of length rank with strides for each dimension.
 * @param edge vector of length rank with the number of elements to read in
 *              each dimension.
 * @param copy_fields 1 to copy the fields, 0 to just set pointers to them.
 * @returns A new structure array with fields indexed from @c matvar.
 */
matvar_t *
Mat_VarGetStructs(matvar_t *matvar, int *start, int *stride, int *edge, int copy_fields)
{
    size_t i, N, I, nfields, field,
        idx[10] =
            {
                0,
            },
        cnt[10] =
            {
                0,
            },
        dimp[10] = {
            0,
        };
    matvar_t **fields, *struct_slab;
    int j;

    if ( matvar == NULL || start == NULL || stride == NULL || edge == NULL ) {
        return NULL;
    } else if ( matvar->rank > 9 ) {
        return NULL;
    } else if ( matvar->class_type != MAT_C_STRUCT ) {
        return NULL;
    }

    struct_slab = Mat_VarDuplicate(matvar, 0);
    if ( !copy_fields )
        struct_slab->mem_conserve = 1;

    nfields = matvar->internal->num_fields;

    dimp[0] = matvar->dims[0];
    N = edge[0];
    I = start[0];
    struct_slab->dims[0] = edge[0];
    idx[0] = start[0];
    for ( j = 1; j < matvar->rank; j++ ) {
        idx[j] = start[j];
        dimp[j] = dimp[j - 1] * matvar->dims[j];
        N *= edge[j];
        I += start[j] * dimp[j - 1];
        struct_slab->dims[j] = edge[j];
    }
    I *= nfields;
    struct_slab->nbytes = N * nfields * sizeof(matvar_t *);
    struct_slab->data = malloc(struct_slab->nbytes);
    if ( struct_slab->data == NULL ) {
        Mat_VarFree(struct_slab);
        return NULL;
    }
    fields = (matvar_t **)struct_slab->data;
    for ( i = 0; i < N; i += edge[0] ) {
        for ( j = 0; j < edge[0]; j++ ) {
            for ( field = 0; field < nfields; field++ ) {
                if ( copy_fields )
                    fields[(i + j) * nfields + field] =
                        Mat_VarDuplicate(*((matvar_t **)matvar->data + I), 1);
                else
                    fields[(i + j) * nfields + field] = *((matvar_t **)matvar->data + I);
                I++;
            }
            I += (stride[0] - 1) * nfields;
        }
        idx[0] = start[0];
        I = idx[0];
        cnt[1]++;
        idx[1] += stride[1];
        for ( j = 1; j < matvar->rank; j++ ) {
            if ( cnt[j] == (size_t)edge[j] ) {
                cnt[j] = 0;
                idx[j] = start[j];
                if ( j < matvar->rank - 1 ) {
                    cnt[j + 1]++;
                    idx[j + 1] += stride[j + 1];
                }
            }
            I += idx[j] * dimp[j - 1];
        }
        I *= nfields;
    }
    return struct_slab;
}

/** @brief Indexes a structure
 *
 * Finds structures of a structure array given a single (linear)start, stride,
 * and edge.  The structures are placed in a new structure array.  If
 * copy_fields is non-zero, the indexed structures are copied and should be
 * freed, but if copy_fields is zero, the indexed structures are pointers to
 * the original, but should still be freed since the mem_conserve flag is set
 * so that the structures are not freed.
 * MAT file version must be 5.
 * @ingroup MAT
 * @param matvar Structure matlab variable
 * @param start starting index (0-relative)
 * @param stride stride (1 reads consecutive elements)
 * @param edge Number of elements to read
 * @param copy_fields 1 to copy the fields, 0 to just set pointers to them.
 * @returns A new structure with fields indexed from matvar
 */
matvar_t *
Mat_VarGetStructsLinear(matvar_t *matvar, int start, int stride, int edge, int copy_fields)
{
    matvar_t *struct_slab;

    if ( matvar == NULL || matvar->rank > 10 ) {
        struct_slab = NULL;
    } else {
        int i, I, field, nfields;
        matvar_t **fields;

        struct_slab = Mat_VarDuplicate(matvar, 0);
        if ( !copy_fields )
            struct_slab->mem_conserve = 1;

        nfields = matvar->internal->num_fields;

        struct_slab->nbytes = (size_t)edge * nfields * sizeof(matvar_t *);
        struct_slab->data = malloc(struct_slab->nbytes);
        if ( struct_slab->data == NULL ) {
            Mat_VarFree(struct_slab);
            return NULL;
        }
        struct_slab->dims[0] = edge;
        struct_slab->dims[1] = 1;
        fields = (matvar_t **)struct_slab->data;
        I = start * nfields;
        for ( i = 0; i < edge; i++ ) {
            if ( copy_fields ) {
                for ( field = 0; field < nfields; field++ ) {
                    fields[i * nfields + field] =
                        Mat_VarDuplicate(*((matvar_t **)matvar->data + I), 1);
                    I++;
                }
            } else {
                for ( field = 0; field < nfields; field++ ) {
                    fields[i * nfields + field] = *((matvar_t **)matvar->data + I);
                    I++;
                }
            }
            I += (stride - 1) * nfields;
        }
    }
    return struct_slab;
}

/** @brief Sets the structure field to the given variable
 *
 * Sets the structure field specified by the 0-relative field index
 * @c field_index for the given 0-relative structure index @c index to
 * @c field.
 * @ingroup MAT
 * @param matvar Pointer to the structure MAT variable
 * @param field_index 0-relative index of the field.
 * @param index linear index of the structure array
 * @param field New field variable
 * @return Pointer to the previous field (NULL if no previous field)
 */
matvar_t *
Mat_VarSetStructFieldByIndex(matvar_t *matvar, size_t field_index, size_t index, matvar_t *field)
{
    int err;
    matvar_t *old_field = NULL;
    size_t nelems = 1, nfields;

    if ( matvar == NULL || matvar->class_type != MAT_C_STRUCT || matvar->data == NULL )
        return NULL;

    err = Mat_MulDims(matvar, &nelems);
    if ( err )
        return NULL;

    nfields = matvar->internal->num_fields;

    if ( index < nelems && field_index < nfields ) {
        matvar_t **fields = (matvar_t **)matvar->data;
        old_field = fields[index * nfields + field_index];
        fields[index * nfields + field_index] = field;
        if ( NULL != field->name ) {
            free(field->name);
        }
        field->name = Mat_strdup(matvar->internal->fieldnames[field_index]);
    }

    return old_field;
}

/** @brief Sets the structure field to the given variable
 *
 * Sets the specified structure fieldname at the given 0-relative @c index to
 * @c field.
 * @ingroup MAT
 * @param matvar Pointer to the Structure MAT variable
 * @param field_name Name of the structure field
 * @param index linear index of the structure array
 * @param field New field variable
 * @return Pointer to the previous field (NULL if no previous field)
 */
matvar_t *
Mat_VarSetStructFieldByName(matvar_t *matvar, const char *field_name, size_t index, matvar_t *field)
{
    int err, i, nfields, field_index;
    matvar_t *old_field = NULL;
    size_t nelems = 1;

    if ( matvar == NULL || matvar->class_type != MAT_C_STRUCT || matvar->data == NULL )
        return NULL;

    err = Mat_MulDims(matvar, &nelems);
    if ( err )
        return NULL;

    nfields = matvar->internal->num_fields;
    field_index = -1;
    for ( i = 0; i < nfields; i++ ) {
        if ( !strcmp(matvar->internal->fieldnames[i], field_name) ) {
            field_index = i;
            break;
        }
    }

    if ( index < nelems && field_index >= 0 ) {
        matvar_t **fields = (matvar_t **)matvar->data;
        old_field = fields[index * nfields + field_index];
        fields[index * nfields + field_index] = field;
        if ( NULL != field->name ) {
            free(field->name);
        }
        field->name = Mat_strdup(matvar->internal->fieldnames[field_index]);
    }

    return old_field;
}

#endif /* NO_FILE_SYSTEM */
