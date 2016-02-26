/* ModelicaMatIO.c - MAT file I/O functions

   Copyright (C) 2005-2016, Christopher C. Hulbert
   Copyright (C) 2013-2016, Modelica Association and ITI GmbH
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

/*
   This file was created by concatenation of the following C source files of the
   MAT file I/O library from <http://sourceforge.net/projects/matio/>:

   endian.c
   inflate.c
   io.c
   read_data.c
   snprintf.c
   mat.c
   mat4.c
   mat5.c
   mat73.c
   matvar_cell.c
   matvar_struct.c
*/

/*
   By default v4 and v6 MAT-files are supported. The v7 and v7.3 MAT-file
   formats require additional preprocessor options and third-party libraries.
   The following #define's are available.

   NO_FILE_SYSTEM: A file system is not present (e.g. on dSPACE or xPC).
   HAVE_ZLIB=1   : Enables the support of v7 MAT-files
                   The zlib (>= v1.2.3) library is required.
   HAVE_HDF5=1   : Enables the support of v7.3 MAT-files
                   The hdf5 (>= v1.8) and szip libraries are required.
*/

#include "ModelicaUtilities.h"
#if !defined(NO_FILE_SYSTEM)
#if defined(__gnu_linux__)
#define _GNU_SOURCE 1
#elif defined(__MINGW32__) && !defined(__USE_MINGW_ANSI_STDIO)
#define __USE_MINGW_ANSI_STDIO 1
#endif
#include <stdarg.h>

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
#define EXTENDED_SPARSE 1

/* Define to 1 if you have the `asprintf' function. */
#if defined(__CYGWIN__)
#define HAVE_ASPRINTF 1
#else
#undef HAVE_ASPRINTF
#endif

/* Define to 1 if the system has the type `intmax_t'. */
#if defined(_WIN32)
#if defined(_MSC_VER) && _MSC_VER >= 1600
#define HAVE_INTMAX_T 1
#elif defined(__WATCOMC__) || defined(__MINGW32__) || defined(__CYGWIN__)
#define HAVE_INTMAX_T 1
#else
#undef HAVE_INTMAX_T
#endif
#elif defined(__GNUC__) && !defined(__VXWORKS__)
#define HAVE_INTMAX_T 1
#else
#undef HAVE_INTMAX_T
#endif

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

/* Define to 1 if you have the `localeconv' function. */
#define HAVE_LOCALECONV 1

/* Define to 1 if you have the <locale.h> header file. */
#define HAVE_LOCALE_H 1

/* Define to 1 if the system has the type `long double'. */
#if defined (_WIN32)
#if defined(__WATCOMC__) || (defined(_MSC_VER) && _MSC_VER >= 1300)
#define HAVE_LONG_DOUBLE 1
#endif
#endif
#if defined(__GNUC__)
#define HAVE_LONG_DOUBLE 1
#endif

/* Define to 1 if the system has the type `long long int'. */
#if defined (_WIN32)
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

/* Define to 1 if you have the <stdint.h> header file. */
#if defined(_WIN32)
#if defined(_MSC_VER) && _MSC_VER >= 1600
#define HAVE_STDINT_H 1
#elif defined(__WATCOMC__) || defined(__MINGW32__) || defined(__CYGWIN__)
#define HAVE_STDINT_H 1
#else
#undef HAVE_STDINT_H
#endif
#elif defined(__GNUC__) && !defined(__VXWORKS__)
#define HAVE_STDINT_H 1
#else
#undef HAVE_STDINT_H
#endif

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if `decimal_point' is member of `struct lconv'. */
#define HAVE_STRUCT_LCONV_DECIMAL_POINT 1

/* Define to 1 if `thousands_sep' is member of `struct lconv'. */
#define HAVE_STRUCT_LCONV_THOUSANDS_SEP 1

/* Define to 1 if the system has the type `uintmax_t'. */
#if defined(_WIN32)
#if defined(_MSC_VER) && _MSC_VER >= 1600
#define HAVE_UINTMAX_T 1
#elif defined(__WATCOMC__) || defined(__MINGW32__) || defined(__CYGWIN__)
#define HAVE_UINTMAX_T 1
#else
#undef HAVE_UINTMAX_T
#endif
#elif defined(__GNUC__) && !defined(__VXWORKS__)
#define HAVE_UINTMAX_T 1
#else
#undef HAVE_UINTMAX_T
#endif

/* Define to 1 if the system has the type `uintptr_t'. */
#if defined(__LCC__) || (defined(_MSC_VER) && _MSC_VER <= 1200)
#undef HAVE_UINTPTR_T
#else
#define HAVE_UINTPTR_T 1
#endif

/* Define to 1 if the system has the type `unsigned long long int'. */
#if defined (_WIN32)
#if defined(__WATCOMC__) || (defined(_MSC_VER) && _MSC_VER >= 1300)
#define HAVE_UNSIGNED_LONG_LONG_INT 1
#endif
#endif
#if defined(__GNUC__) && __STDC_VERSION__ >= 199901L
#define HAVE_UNSIGNED_LONG_LONG_INT 1
#endif

/* Define to 1 if you have the `vasprintf' function. */
#if defined(__CYGWIN__)
#define HAVE_VASPRINTF 1
#else
#undef HAVE_VASPRINTF
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

/* Define to 1 if you have a C99 compliant `vsnprintf' function. */
#if defined(STDC99)
#define HAVE_VSNPRINTF 1
#elif defined(__MINGW32__) || defined(__CYGWIN__)
#if __STDC_VERSION__ >= 199901L
#define HAVE_VSNPRINTF 1
#endif
#elif defined(__WATCOMC__)
#define HAVE_VSNPRINTF 1
#elif defined(__TURBOC__) && __TURBOC__ >= 0x550
#define HAVE_VSNPRINTF 1
#elif defined(MSDOS) && defined(__BORLANDC__) && (BORLANDC > 0x410)
#define HAVE_VSNPRINTF 1
#elif defined(_MSC_VER) && _MSC_VER >= 1900
#define HAVE_VSNPRINTF 1
#else
#undef HAVE_VSNPRINTF
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

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Z prefix */
#undef Z_PREFIX

#include "ModelicaMatIO.h"
#if HAVE_INTTYPES_H
#   define __STDC_FORMAT_MACROS
#endif
#if defined(HAVE_ZLIB)
#   include <zlib.h>
#endif
#if defined(HAVE_HDF5)
#   include <hdf5.h>
#else
#   define hobj_ref_t int
#   define hid_t int
#endif

#if defined(HAVE_ZLIB) && HAVE_ZLIB
#   define ZLIB_BYTE_PTR(a) ((Bytef *)(a))
#endif

/** @if mat_devman
 * @brief Matlab MAT File information
 *
 * Contains information about a Matlab MAT file
 * @ingroup mat_internal
 * @endif
 */
struct _mat_t {
    void *fp;               /**< File pointer for the MAT file */
    char *header;           /**< MAT File header string */
    char *subsys_offset;    /**< Offset */
    char *filename;         /**< Filename of the MAT file */
    int   version;          /**< MAT File version */
    int   byteswap;         /**< 1 if byte swapping is required, 0 otherwise */
    int   mode;             /**< Access mode */
    long  bof;              /**< Beginning of file not including any header */
    long  next_index;       /**< Index/File position of next variable to read */
    long  num_datasets;     /**< Number of datasets in the file */
    hid_t refs_id;          /**< Id of the /#refs# group in HDF5 */
};

/** @if mat_devman
 * @brief internal structure for MAT variables
 * @ingroup mat_internal
 * @endif
 */
struct matvar_internal {
    char *hdf5_name;        /**< Name */
    hobj_ref_t hdf5_ref;    /**< Reference */
    hid_t      id;          /**< Id */
    long       fpos;        /**< Offset from the beginning of the MAT file to the variable */
    long       datapos;     /**< Offset from the beginning of the MAT file to the data */
    mat_t     *fp;          /**< Pointer to the MAT file structure (mat_t) */
    unsigned   num_fields;  /**< Number of fields */
    char     **fieldnames;  /**< Pointer to fieldnames */
#if defined(HAVE_ZLIB)
    z_streamp  z;           /**< zlib compression state */
    void      *data;        /**< Inflated data array */
#endif
};

/*    snprintf.c    */
#if !HAVE_VSNPRINTF
int rpl_vsnprintf(char *, size_t, const char *, va_list);
#define mat_vsnprintf rpl_vsnprintf
#else
#define mat_vsnprintf vsnprintf
#endif  /* !HAVE_VSNPRINTF */
#if !HAVE_SNPRINTF
int rpl_snprintf(char *, size_t, const char *, ...);
#define mat_snprintf rpl_snprintf
#else
#define mat_snprintf snprintf
#endif  /* !HAVE_SNPRINTF */
#if !HAVE_VASPRINTF
int rpl_vasprintf(char **, const char *, va_list);
#define mat_vasprintf rpl_vasprintf
#else
#define mat_vasprintf vasprintf
#endif  /* !HAVE_VASPRINTF */
#if !HAVE_ASPRINTF
int rpl_asprintf(char **, const char *, ...);
#define mat_asprintf rpl_asprintf
#else
#define mat_asprintf asprintf
#endif  /* !HAVE_ASPRINTF */

/*   endian.c     */
static double        Mat_doubleSwap(double  *a);
static float         Mat_floatSwap(float   *a);
#ifdef HAVE_MATIO_INT64_T
static mat_int64_t   Mat_int64Swap(mat_int64_t  *a);
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
static mat_uint64_t  Mat_uint64Swap(mat_uint64_t *a);
#endif /* HAVE_MATIO_UINT64_T */
static mat_int32_t   Mat_int32Swap(mat_int32_t  *a);
static mat_uint32_t  Mat_uint32Swap(mat_uint32_t *a);
static mat_int16_t   Mat_int16Swap(mat_int16_t  *a);
static mat_uint16_t  Mat_uint16Swap(mat_uint16_t *a);

/* read_data.c */
static int ReadDoubleData(mat_t *mat,double  *data,enum matio_types data_type,
               int len);
static int ReadSingleData(mat_t *mat,float   *data,enum matio_types data_type,
               int len);
#ifdef HAVE_MATIO_INT64_T
static int ReadInt64Data (mat_t *mat,mat_int64_t *data,
               enum matio_types data_type,int len);
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
static int ReadUInt64Data(mat_t *mat,mat_uint64_t *data,
               enum matio_types data_type,int len);
#endif /* HAVE_MATIO_UINT64_T */
static int ReadInt32Data (mat_t *mat,mat_int32_t *data,
               enum matio_types data_type,int len);
static int ReadUInt32Data(mat_t *mat,mat_uint32_t *data,
               enum matio_types data_type,int len);
static int ReadInt16Data (mat_t *mat,mat_int16_t *data,
               enum matio_types data_type,int len);
static int ReadUInt16Data(mat_t *mat,mat_uint16_t *data,
               enum matio_types data_type,int len);
static int ReadInt8Data  (mat_t *mat,mat_int8_t  *data,
               enum matio_types data_type,int len);
static int ReadUInt8Data (mat_t *mat,mat_uint8_t  *data,
               enum matio_types data_type,int len);
static int ReadCharData  (mat_t *mat,char  *data,enum matio_types data_type,
               int len);
static int ReadDataSlab1(mat_t *mat,void *data,enum matio_classes class_type,
               enum matio_types data_type,int start,int stride,int edge);
static int ReadDataSlab2(mat_t *mat,void *data,enum matio_classes class_type,
               enum matio_types data_type,size_t *dims,int *start,int *stride,
               int *edge);
static int ReadDataSlabN(mat_t *mat,void *data,enum matio_classes class_type,
               enum matio_types data_type,int rank,size_t *dims,int *start,
               int *stride,int *edge);
#if defined(HAVE_ZLIB)
static int ReadCompressedDoubleData(mat_t *mat,z_streamp z,double  *data,
               enum matio_types data_type,int len);
static int ReadCompressedSingleData(mat_t *mat,z_streamp z,float   *data,
               enum matio_types data_type,int len);
#ifdef HAVE_MATIO_INT64_T
static int ReadCompressedInt64Data(mat_t *mat,z_streamp z,mat_int64_t *data,
               enum matio_types data_type,int len);
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
static int ReadCompressedUInt64Data(mat_t *mat,z_streamp z,mat_uint64_t *data,
               enum matio_types data_type,int len);
#endif /* HAVE_MATIO_UINT64_T */
static int ReadCompressedInt32Data(mat_t *mat,z_streamp z,mat_int32_t *data,
               enum matio_types data_type,int len);
static int ReadCompressedUInt32Data(mat_t *mat,z_streamp z,mat_uint32_t *data,
               enum matio_types data_type,int len);
static int ReadCompressedInt16Data(mat_t *mat,z_streamp z,mat_int16_t *data,
               enum matio_types data_type,int len);
static int ReadCompressedUInt16Data(mat_t *mat,z_streamp z,mat_uint16_t *data,
               enum matio_types data_type,int len);
static int ReadCompressedInt8Data(mat_t *mat,z_streamp z,mat_int8_t  *data,
               enum matio_types data_type,int len);
static int ReadCompressedUInt8Data(mat_t *mat,z_streamp z,mat_uint8_t  *data,
               enum matio_types data_type,int len);
static int ReadCompressedCharData(mat_t *mat,z_streamp z,char *data,
               enum matio_types data_type,int len);
static int ReadCompressedDataSlab1(mat_t *mat,z_streamp z,void *data,
               enum matio_classes class_type,enum matio_types data_type,
               int start,int stride,int edge);
static int ReadCompressedDataSlab2(mat_t *mat,z_streamp z,void *data,
               enum matio_classes class_type,enum matio_types data_type,
               size_t *dims,int *start,int *stride,int *edge);
static int ReadCompressedDataSlabN(mat_t *mat,z_streamp z,void *data,
               enum matio_classes class_type,enum matio_types data_type,
               int rank,size_t *dims,int *start,int *stride,int *edge);

/*   inflate.c    */
static size_t InflateSkip(mat_t *mat, z_streamp z, int nbytes);
static size_t InflateSkip2(mat_t *mat, matvar_t *matvar, int nbytes);
static size_t InflateSkipData(mat_t *mat,z_streamp z,enum matio_types data_type,int len);
static size_t InflateVarTag(mat_t *mat, matvar_t *matvar, void *buf);
static size_t InflateArrayFlags(mat_t *mat, matvar_t *matvar, void *buf);
static size_t InflateDimensions(mat_t *mat, matvar_t *matvar, void *buf);
static size_t InflateVarNameTag(mat_t *mat, matvar_t *matvar, void *buf);
static size_t InflateVarName(mat_t *mat,matvar_t *matvar,void *buf,int N);
static size_t InflateDataTag(mat_t *mat, matvar_t *matvar, void *buf);
static size_t InflateDataType(mat_t *mat, z_stream *matvar, void *buf);
static size_t InflateData(mat_t *mat, z_streamp z, void *buf, int nBytes);
static size_t InflateFieldNameLength(mat_t *mat,matvar_t *matvar,void *buf);
static size_t InflateFieldNamesTag(mat_t *mat,matvar_t *matvar,void *buf);
static size_t InflateFieldNames(mat_t *mat,matvar_t *matvar,void *buf,int nfields,
               int fieldname_length,int padding);
#endif

#endif

/** @brief swap the bytes @c a and @c b
 * @ingroup mat_internal
 */
#define swap(a,b)   a^=b;b^=a;a^=b

#ifdef HAVE_MATIO_INT64_T
/** @brief swap the bytes of a 64-bit signed integer
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static mat_int64_t
Mat_int64Swap( mat_int64_t *a )
{

    union {
        mat_int8_t    i1[8];
        mat_int64_t   i8;
    } tmp;

    tmp.i8 = *a;

    swap( tmp.i1[0], tmp.i1[7] );
    swap( tmp.i1[1], tmp.i1[6] );
    swap( tmp.i1[2], tmp.i1[5] );
    swap( tmp.i1[3], tmp.i1[4] );

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
Mat_uint64Swap( mat_uint64_t *a )
{

    union {
        mat_uint8_t    i1[8];
        mat_uint64_t   i8;
    } tmp;

    tmp.i8 = *a;

    swap( tmp.i1[0], tmp.i1[7] );
    swap( tmp.i1[1], tmp.i1[6] );
    swap( tmp.i1[2], tmp.i1[5] );
    swap( tmp.i1[3], tmp.i1[4] );

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
Mat_int32Swap( mat_int32_t *a )
{

    union {
        mat_int8_t    i1[4];
        mat_int32_t   i4;
    } tmp;

    tmp.i4 = *a;

    swap( tmp.i1[0], tmp.i1[3] );
    swap( tmp.i1[1], tmp.i1[2] );

    *a = tmp.i4;

    return *a;

}

/** @brief swap the bytes of a 32-bit unsigned integer
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static mat_uint32_t
Mat_uint32Swap( mat_uint32_t *a )
{

    union {
        mat_uint8_t    i1[4];
        mat_uint32_t   i4;
    } tmp;

    tmp.i4 = *a;

    swap( tmp.i1[0], tmp.i1[3] );
    swap( tmp.i1[1], tmp.i1[2] );

    *a = tmp.i4;

    return *a;

}

/** @brief swap the bytes of a 16-bit signed integer
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static mat_int16_t
Mat_int16Swap( mat_int16_t *a )
{

    union {
        mat_int8_t   i1[2];
        mat_int16_t  i2;
    } tmp;

    tmp.i2 = *a;

    swap( tmp.i1[0], tmp.i1[1] );

    *a = tmp.i2;
    return *a;

}

/** @brief swap the bytes of a 16-bit unsigned integer
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static mat_uint16_t
Mat_uint16Swap( mat_uint16_t *a )
{

    union {
        mat_uint8_t   i1[2];
        mat_uint16_t  i2;
    } tmp;

    tmp.i2 = *a;

    swap( tmp.i1[0], tmp.i1[1] );

    *a = tmp.i2;
    return *a;

}

/** @brief swap the bytes of a 4 byte single-precision float
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static float
Mat_floatSwap( float *a )
{

    union {
        char  i1[4];
        float r4;
    } tmp;

    tmp.r4 = *a;

    swap( tmp.i1[0], tmp.i1[3] );
    swap( tmp.i1[1], tmp.i1[2] );

    *a = tmp.r4;
    return *a;

}

/** @brief swap the bytes of a 4 or 8 byte double-precision float
 * @ingroup mat_internal
 * @param a pointer to integer to swap
 * @return the swapped integer
 */
static double
Mat_doubleSwap( double *a )
{
#ifndef SIZEOF_DOUBLE
#define SIZEOF_DOUBLE 8
#endif

    union {
        char   a[SIZEOF_DOUBLE];
        double b;
    } tmp;

    tmp.b = *a;

#if SIZEOF_DOUBLE == 4
    swap( tmp.a[0], tmp.a[3] );
    swap( tmp.a[1], tmp.a[2] );
#elif SIZEOF_DOUBLE == 8
    swap( tmp.a[0], tmp.a[7] );
    swap( tmp.a[1], tmp.a[6] );
    swap( tmp.a[2], tmp.a[5] );
    swap( tmp.a[3], tmp.a[4] );
#elif SIZEOF_DOUBLE == 16
    swap( tmp.a[0], tmp.a[15] );
    swap( tmp.a[1], tmp.a[14] );
    swap( tmp.a[2], tmp.a[13] );
    swap( tmp.a[3], tmp.a[12] );
    swap( tmp.a[4], tmp.a[11] );
    swap( tmp.a[5], tmp.a[10] );
    swap( tmp.a[6], tmp.a[9] );
    swap( tmp.a[7], tmp.a[8] );
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
#include <stdlib.h>

#if HAVE_ZLIB

/** @cond mat_devman */

/** @brief Inflate the data until @c nbytes of uncompressed data has been
 *         inflated
 *
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param z zlib compression stream
 * @param nbytes Number of uncompressed bytes to skip
 * @return Number of bytes read from the file
 */
static size_t
InflateSkip(mat_t *mat, z_streamp z, int nbytes)
{
    mat_uint8_t comp_buf[512],uncomp_buf[512];
    int    n, err, cnt = 0;
    size_t bytesread = 0;

    if ( nbytes < 1 )
        return 0;

    n = (nbytes<512) ? nbytes : 512;
    if ( !z->avail_in ) {
        z->next_in = comp_buf;
        z->avail_in += fread(comp_buf,1,n,(FILE*)mat->fp);
        bytesread   += z->avail_in;
    }
    z->avail_out = n;
    z->next_out  = uncomp_buf;
    err = inflate(z,Z_FULL_FLUSH);
    if ( err == Z_STREAM_END ) {
        return bytesread;
    } else if ( err != Z_OK ) {
        Mat_Critical("InflateSkip: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return bytesread;
    }
    if ( !z->avail_out ) {
        cnt += n;
        n = ((nbytes-cnt)<512) ? nbytes-cnt : 512;
        z->avail_out = n;
        z->next_out  = uncomp_buf;
    }
    while ( cnt < nbytes ) {
        if ( !z->avail_in ) {
            z->next_in   = comp_buf;
            z->avail_in += fread(comp_buf,1,n,(FILE*)mat->fp);
            bytesread   += z->avail_in;
        }
        err = inflate(z,Z_FULL_FLUSH);
        if ( err == Z_STREAM_END ) {
            break;
        } else if ( err != Z_OK ) {
            Mat_Critical("InflateSkip: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            break;
        }
        if ( !z->avail_out ) {
            cnt         += n;
            n            = ((nbytes-cnt)<512) ? nbytes-cnt : 512;
            z->avail_out = n;
            z->next_out  = uncomp_buf;
        }
    }

    if ( z->avail_in ) {
        long offset = -(long)z->avail_in;
        (void)fseek((FILE*)mat->fp,offset,SEEK_CUR);
        bytesread -= z->avail_in;
        z->avail_in = 0;
    }

    return bytesread;
}

/** @brief Inflate the data until @c nbytes of compressed data has been
 *         inflated
 *
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param z zlib compression stream
 * @param nbytes Number of uncompressed bytes to skip
 * @return Number of bytes read from the file
 */
static size_t
InflateSkip2(mat_t *mat, matvar_t *matvar, int nbytes)
{
    mat_uint8_t comp_buf[32],uncomp_buf[32];
    int    err, cnt = 0;
    size_t bytesread = 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
    }
    matvar->internal->z->avail_out = 1;
    matvar->internal->z->next_out = uncomp_buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateSkip2: %s - inflate returned %s",matvar->name,zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return bytesread;
    }
    if ( !matvar->internal->z->avail_out ) {
        matvar->internal->z->avail_out = 1;
        matvar->internal->z->next_out = uncomp_buf;
    }
    while ( cnt < nbytes ) {
        if ( !matvar->internal->z->avail_in ) {
            matvar->internal->z->avail_in = 1;
            matvar->internal->z->next_in = comp_buf;
            bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
            cnt++;
        }
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateSkip2: %s - inflate returned %s",matvar->name,zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            return bytesread;
        }
        if ( !matvar->internal->z->avail_out ) {
            matvar->internal->z->avail_out = 1;
            matvar->internal->z->next_out = uncomp_buf;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        (void)fseek((FILE*)mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
        bytesread -= matvar->internal->z->avail_in;
        matvar->internal->z->avail_in = 0;
    }

    return bytesread;
}

/** @brief Inflate the data until @c len elements of compressed data with data
 *         type @c data_type has been inflated
 *
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param z zlib compression stream
 * @param data_type Data type (matio_types enumerations)
 * @param len Number of elements of datatype @c data_type to skip
 * @return Number of bytes read from the file
 */
static size_t
InflateSkipData(mat_t *mat,z_streamp z,enum matio_types data_type,int len)
{
    int data_size = 0;

    if ( (mat == NULL) || (z == NULL) )
        return 0;
    else if ( len < 1 )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
            data_size = sizeof(double);
            break;
        case MAT_T_SINGLE:
            data_size = sizeof(float);
            break;
#ifdef HAVE_MATIO_INT64_T
        case MAT_T_INT64:
            data_size = sizeof(mat_int64_t);
            break;
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_T_UINT64:
            data_size = sizeof(mat_uint64_t);
            break;
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_T_INT32:
            data_size = sizeof(mat_int32_t);
            break;
        case MAT_T_UINT32:
            data_size = sizeof(mat_uint32_t);
            break;
        case MAT_T_INT16:
            data_size = sizeof(mat_int16_t);
            break;
        case MAT_T_UINT16:
            data_size = sizeof(mat_uint16_t);
            break;
        case MAT_T_UINT8:
            data_size = sizeof(mat_uint8_t);
            break;
        case MAT_T_INT8:
            data_size = sizeof(mat_int8_t);
            break;
        default:
            return 0;
    }
    InflateSkip(mat,z,len*data_size);
    return len;
}

/** @brief Inflates the variable's tag.
 *
 * @c buf must hold at least 8 bytes
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param matvar Pointer to the MAT variable
 * @param buf Pointer to store the 8-byte variable tag
 * @return Number of bytes read from the file
 */
static size_t
InflateVarTag(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    int    err;
    size_t bytesread = 0;

    if (buf == NULL)
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
    }
    matvar->internal->z->avail_out = 8;
    matvar->internal->z->next_out = (Bytef*)buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateVarTag: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateVarTag: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        (void)fseek((FILE*)mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
        bytesread -= matvar->internal->z->avail_in;
        matvar->internal->z->avail_in = 0;
    }

    return bytesread;
}

/** @brief Inflates the Array Flags Tag and the Array Flags data.
 *
 * @c buf must hold at least 16 bytes
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param matvar Pointer to the MAT variable
 * @param buf Pointer to store the 16-byte array flags tag and data
 * @return Number of bytes read from the file
 */
static size_t
InflateArrayFlags(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    int    err;
    size_t bytesread = 0;

    if (buf == NULL) return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
    }
    matvar->internal->z->avail_out = 16;
    matvar->internal->z->next_out = (Bytef*)buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateArrayFlags: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateArrayFlags: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        (void)fseek((FILE*)mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
        bytesread -= matvar->internal->z->avail_in;
        matvar->internal->z->avail_in = 0;
    }

    return bytesread;
}

/** @brief Inflates the dimensions tag and the dimensions data
 *
 * @c buf must hold at least (8+4*rank) bytes where rank is the number of
 * dimensions. If the end of the dimensions data is not aligned on an 8-byte
 * boundary, this function eats up those bytes and stores then in @c buf.
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param matvar Pointer to the MAT variable
 * @param buf Pointer to store the dimensions flag and data
 * @return Number of bytes read from the file
 */
static size_t
InflateDimensions(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    mat_int32_t tag[2];
    int    err, rank, i;
    size_t bytesread = 0;

    if ( buf == NULL )
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
    }
    matvar->internal->z->avail_out = 8;
    matvar->internal->z->next_out = (Bytef*)buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateDimensions: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateDimensions: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            return bytesread;
        }
    }
    tag[0] = *(int *)buf;
    tag[1] = *((int *)buf+1);
    if ( mat->byteswap ) {
        Mat_int32Swap(tag);
        Mat_int32Swap(tag+1);
    }
    if ( (tag[0] & 0x0000ffff) != MAT_T_INT32 ) {
        Mat_Critical("InflateDimensions: Reading dimensions expected type MAT_T_INT32");
        return bytesread;
    }
    rank = tag[1];
    if ( rank % 8 != 0 )
        i = 8-(rank %8);
    else
        i = 0;
    rank+=i;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
    }
    matvar->internal->z->avail_out = rank;
    matvar->internal->z->next_out = (Bytef*)((mat_int32_t *)buf+2);
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateDimensions: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateDimensions: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        (void)fseek((FILE*)mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
        bytesread -= matvar->internal->z->avail_in;
        matvar->internal->z->avail_in = 0;
    }

    return bytesread;
}

/** @brief Inflates the variable name tag
 *
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param matvar Pointer to the MAT variable
 * @param buf Pointer to store the variables name tag
 * @return Number of bytes read from the file
 */
static size_t
InflateVarNameTag(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    int    err;
    size_t bytesread = 0;

    if ( buf == NULL )
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
    }
    matvar->internal->z->avail_out = 8;
    matvar->internal->z->next_out = (Bytef*)buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateVarNameTag: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateVarNameTag: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        (void)fseek((FILE*)mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
        bytesread -= matvar->internal->z->avail_in;
        matvar->internal->z->avail_in = 0;
    }

    return bytesread;
}

/** @brief Inflates the variable name
 *
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param matvar Pointer to the MAT variable
 * @param buf Pointer to store the variables name
 * @param N Number of characters in the name
 * @return Number of bytes read from the file
 */
static size_t
InflateVarName(mat_t *mat, matvar_t *matvar, void *buf, int N)
{
    mat_uint8_t comp_buf[32];
    int    err;
    size_t bytesread = 0;

    if ( buf == NULL )
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
    }
    matvar->internal->z->avail_out = N;
    matvar->internal->z->next_out = (Bytef*)buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateVarName: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateVarName: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        (void)fseek((FILE*)mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
        bytesread -= matvar->internal->z->avail_in;
        matvar->internal->z->avail_in = 0;
    }

    return bytesread;
}

/** @brief Inflates the data's tag
 *
 * buf must hold at least 8 bytes
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param matvar Pointer to the MAT variable
 * @param buf Pointer to store the data tag
 * @return Number of bytes read from the file
 */
static size_t
InflateDataTag(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    int    err;
    size_t bytesread = 0;

    if ( buf == NULL )
        return 0;

   if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
    }
    matvar->internal->z->avail_out = 8;
    matvar->internal->z->next_out = (Bytef*)buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err == Z_STREAM_END ) {
        return bytesread;
    } else if ( err != Z_OK ) {
        Mat_Critical("InflateDataTag: %s - inflate returned %s",matvar->name,zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err == Z_STREAM_END ) {
            break;
        } else if ( err != Z_OK ) {
            Mat_Critical("InflateDataTag: %s - inflate returned %s",matvar->name,zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        (void)fseek((FILE*)mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
        bytesread -= matvar->internal->z->avail_in;
        matvar->internal->z->avail_in = 0;
    }

    return bytesread;
}

/** @brief Inflates the data's type
 *
 * buf must hold at least 4 bytes
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param matvar Pointer to the MAT variable
 * @param buf Pointer to store the data type
 * @return Number of bytes read from the file
 */
static size_t
InflateDataType(mat_t *mat, z_streamp z, void *buf)
{
    mat_uint8_t comp_buf[32];
    int    err;
    size_t bytesread = 0;

    if ( buf == NULL )
        return 0;

    if ( !z->avail_in ) {
        z->avail_in = 1;
        z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
    }
    z->avail_out = 4;
    z->next_out = (Bytef*)buf;
    err = inflate(z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateDataType: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return bytesread;
    }
    while ( z->avail_out && !z->avail_in ) {
        z->avail_in = 1;
        z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
        err = inflate(z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateDataType: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            return bytesread;
        }
    }

    if ( z->avail_in ) {
        (void)fseek((FILE*)mat->fp,-(int)z->avail_in,SEEK_CUR);
        bytesread -= z->avail_in;
        z->avail_in = 0;
    }

    return bytesread;
}

/** @brief Inflates the data
 *
 * buf must hold at least @c nBytes bytes
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param z zlib compression stream
 * @param buf Pointer to store the data type
 * @param nBytes Number of bytes to inflate
 * @return Number of bytes read from the file
 */
static size_t
InflateData(mat_t *mat, z_streamp z, void *buf, int nBytes)
{
    mat_uint8_t comp_buf[1024];
    int    err;
    size_t bytesread = 0;

    if ( buf == NULL )
        return 0;
    if ( nBytes < 1 ) {
        return bytesread;
    }

    if ( !z->avail_in ) {
        if ( nBytes > 1024 ) {
            z->avail_in = fread(comp_buf,1,1024,(FILE*)mat->fp);
        } else {
            z->avail_in = fread(comp_buf,1,nBytes,(FILE*)mat->fp);
        }
        bytesread += z->avail_in;
        z->next_in = comp_buf;
    }
    z->avail_out = nBytes;
    z->next_out = (Bytef*)buf;
    err = inflate(z,Z_FULL_FLUSH);
    if ( err == Z_STREAM_END ) {
        return bytesread;
    } else if ( err != Z_OK ) {
        Mat_Critical("InflateData: inflate returned %s",zError( err == Z_NEED_DICT ? Z_DATA_ERROR : err ));
        return bytesread;
    }
    while ( z->avail_out && !z->avail_in ) {
        if ( nBytes > 1024 + bytesread ) {
            z->avail_in = fread(comp_buf,1,1024,(FILE*)mat->fp);
        } else if ( nBytes < 1 + bytesread ) { /* Read a byte at a time */
            z->avail_in = fread(comp_buf,1,1,(FILE*)mat->fp);
        } else {
            z->avail_in = fread(comp_buf,1,nBytes-bytesread,(FILE*)mat->fp);
        }
        bytesread += z->avail_in;
        z->next_in = comp_buf;
        err = inflate(z,Z_FULL_FLUSH);
        if ( err == Z_STREAM_END ) {
            break;
        } else if ( err != Z_OK && err != Z_BUF_ERROR ) {
            Mat_Critical("InflateData: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            break;
        }
    }

    if ( z->avail_in ) {
        long offset = -(long)z->avail_in;
        (void)fseek((FILE*)mat->fp,offset,SEEK_CUR);
        bytesread -= z->avail_in;
        z->avail_in = 0;
    }

    return bytesread;
}

/** @brief Inflates the structure's fieldname length
 *
 * buf must hold at least 8 bytes
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param matvar Pointer to the MAT variable
 * @param buf Pointer to store the fieldname length
 * @return Number of bytes read from the file
 */
static size_t
InflateFieldNameLength(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    int    err;
    size_t bytesread = 0;

    if ( buf == NULL )
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
    }
    matvar->internal->z->avail_out = 8;
    matvar->internal->z->next_out = (Bytef*)buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateFieldNameLength: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateFieldNameLength: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        (void)fseek((FILE*)mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
        bytesread -= matvar->internal->z->avail_in;
        matvar->internal->z->avail_in = 0;
    }

    return bytesread;
}

/** @brief Inflates the structure's fieldname tag
 *
 * buf must hold at least 8 bytes
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param matvar Pointer to the MAT variable
 * @param buf Pointer to store the fieldname tag
 * @return Number of bytes read from the file
 */
static size_t
InflateFieldNamesTag(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    int    err;
    size_t bytesread = 0;

    if ( buf == NULL )
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
    }
    matvar->internal->z->avail_out = 8;
    matvar->internal->z->next_out = (Bytef*)buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateFieldNamesTag: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateFieldNamesTag: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        (void)fseek((FILE*)mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
        bytesread -= matvar->internal->z->avail_in;
        matvar->internal->z->avail_in = 0;
    }

    return bytesread;
}

/*
 * Inflates the structure's fieldname length.  buf must hold at least
 * nfields*fieldname_length bytes
 */
/** @brief Inflates the structure's fieldnames
 *
 * buf must hold at least @c nfields * @c fieldname_length bytes
 * @ingroup mat_internal
 * @param mat Pointer to the MAT file
 * @param matvar Pointer to the MAT variable
 * @param buf Pointer to store the fieldnames
 * @param nfields Number of fields
 * @param fieldname_length Maximum length in bytes of each field
 * @param padding Number of padding bytes
 * @return Number of bytes read from the file
 */
static size_t
InflateFieldNames(mat_t *mat,matvar_t *matvar,void *buf,int nfields,
                  int fieldname_length,int padding)
{
    mat_uint8_t comp_buf[32];
    int    err;
    size_t bytesread = 0;

    if ( buf == NULL )
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
    }
    matvar->internal->z->avail_out = nfields*fieldname_length+padding;
    matvar->internal->z->next_out = (Bytef*)buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateFieldNames: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,(FILE*)mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateFieldNames: inflate returned %s",zError(err == Z_NEED_DICT ? Z_DATA_ERROR : err));
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        (void)fseek((FILE*)mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
        bytesread -= matvar->internal->z->avail_in;
        matvar->internal->z->avail_in = 0;
    }

    return bytesread;
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
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#if !defined(HAVE_VA_COPY) && !defined(va_copy) && defined(HAVE___VA_COPY)
#    define va_copy(d,s) __va_copy(d,s)
#elif !defined(HAVE_VA_COPY) && !defined(va_copy)
#    define va_copy(d,s) memcpy(&(d),&(s),sizeof(va_list))
#endif

/** @brief Allocates and prints to a new string
 *
 * @ingroup mat_util
 * @param format format string
 * @param ap variable argument list
 * @return Newly allocated string with format printed to it
 */
char *
strdup_vprintf(const char* format, va_list ap)
{
    va_list ap2;
    int size;
    char* buffer;

    va_copy(ap2, ap);
    size = mat_vsnprintf(NULL, 0, format, ap2)+1;
    va_end(ap2);

    buffer = (char*)malloc(size+1);
    if ( !buffer )
        return NULL;

    mat_vsnprintf(buffer, size, format, ap);
    return buffer;
}

/** @brief Allocates and prints to a new string using printf format
 *
 * @ingroup mat_util
 * @param format format string
 * @return Pointer to resulting string, or NULL if there was an error
 */
char *
strdup_printf(const char* format, ...)
{
    char* buffer;
    va_list ap;
    va_start(ap, format);
    buffer = strdup_vprintf(format, ap);
    va_end(ap);
    return buffer;
}

/** @brief Logs a Critical message and aborts the program
 *
 * Logs an Error message and aborts
 * @ingroup mat_util
 * @param format format string identical to printf format
 * @param ... arguments to the format string
 */
void Mat_Critical(const char *format, ... )
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
Mat_Warning(const char *format, ... )
{
    va_list ap;
    va_start(ap, format);
    ModelicaVFormatMessage(format, ap);
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
    switch (data_type) {
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
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <time.h>

/*
 * --------------------------------------------------------------------------
 *    Routines to read data of any type into arrays of a specific type
 * --------------------------------------------------------------------------
 */

/** @cond mat_devman */

/** @brief Reads data of type @c data_type into a double type
 *
 * Reads from the MAT file @c len elements of data type @c data_type storing
 * them as double's in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data Pointer to store the output double values (len*sizeof(double))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadDoubleData(mat_t *mat,double *data,enum matio_types data_type,int len)
{
    int bytesread = 0, data_size = 0, i;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            data_size = sizeof(double);
            if ( mat->byteswap ) {
                bytesread += fread(data,data_size,len,(FILE*)mat->fp);
                for ( i = 0; i < len; i++ ) {
                    (void)Mat_doubleSwap(data+i);
                }
            } else {
                bytesread += fread(data,data_size,len,(FILE*)mat->fp);
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&i8,data_size,1,(FILE*)mat->fp);
                data[i] = i8;
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&ui8,data_size,1,(FILE*)mat->fp);
                data[i] = ui8;
            }
            break;
        }
        default:
            return 0;
    }
    bytesread *= data_size;
    return bytesread;
}

#if defined(HAVE_ZLIB)
/** @brief Reads data of type @c data_type into a double type
 *
 * Reads from the MAT file @c len compressed elements of data type @c data_type
 * storing them as double's in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z Pointer to the zlib stream for inflation
 * @param data Pointer to store the output double values (len*sizeof(double))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadCompressedDoubleData(mat_t *mat,z_streamp z,double *data,
    enum matio_types data_type,int len)
{
    int nBytes = 0, data_size = 0, i;
    union _buf {
#if SIZEOF_DOUBLE == 8
        double          d[128];
#elif SIZEOF_DOUBLE == 16
        double          d[64];
#endif
        float           f[256];
        mat_int32_t   i32[256];
        mat_uint32_t ui32[256];
        mat_int16_t   i16[512];
        mat_uint16_t ui16[512];
        mat_int8_t     i8[1024];
        mat_uint8_t   ui8[1024];
    } buf;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            data_size = sizeof(double);
            if ( mat->byteswap ) {
                InflateData(mat,z,data,len*data_size);
                for ( i = 0; i < len; i++ )
                    (void)Mat_doubleSwap(data+i);
            } else {
                InflateData(mat,z,data,len*data_size);
            }
            break;
        }
        case MAT_T_INT32:
        {
            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                if ( len <= 256 ){
                    InflateData(mat,z,buf.i32,len*data_size);
                    for ( i = 0; i < len; i++ )
                        data[i] = Mat_int32Swap(buf.i32+i);
                } else {
                    int j;
                    len -= 256;
                    for ( i = 0; i < len; i+=256 ) {
                        InflateData(mat,z,buf.i32,256*data_size);
                        for ( j = 0; j < 256; j++ )
                            data[i+j] = Mat_int32Swap(buf.i32+j);
                    }
                    len = len-(i-256);
                    InflateData(mat,z,buf.i32,len*data_size);
                    for ( j = 0; j < len; j++ )
                        data[i+j] = Mat_int32Swap(buf.i32+j);
                }
            } else {
                if ( len <= 256 ){
                    InflateData(mat,z,buf.i32,len*data_size);
                    for ( i = 0; i < len; i++ )
                        data[i] = buf.i32[i];
                } else {
                    int j;
                    len -= 256;
                    for ( i = 0; i < len; i+=256 ) {
                        InflateData(mat,z,buf.i32,256*data_size);
                        for ( j = 0; j < 256; j++ )
                            data[i+j] = buf.i32[j];
                    }
                    len = len-(i-256);
                    InflateData(mat,z,buf.i32,len*data_size);
                    for ( j = 0; j < len; j++ )
                        data[i+j] = buf.i32[j];
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                if ( len <= 256 ){
                    InflateData(mat,z,buf.ui32,len*data_size);
                    for ( i = 0; i < len; i++ )
                        data[i] = Mat_uint32Swap(buf.ui32+i);
                } else {
                    int j;
                    len -= 256;
                    for ( i = 0; i < len; i+=256 ) {
                        InflateData(mat,z,buf.ui32,256*data_size);
                        for ( j = 0; j < 256; j++ )
                            data[i+j] = Mat_uint32Swap(buf.ui32+j);
                    }
                    len = len-(i-256);
                    InflateData(mat,z,buf.ui32,len*data_size);
                    for ( j = 0; j < len; j++ )
                        data[i+j] = Mat_uint32Swap(buf.ui32+j);
                }
            } else {
                if ( len <= 256 ) {
                    InflateData(mat,z,buf.ui32,len*data_size);
                    for ( i = 0; i < len; i++ )
                        data[i] = buf.ui32[i];
                } else {
                    int j;
                    len -= 256;
                    for ( i = 0; i < len; i+=256 ) {
                        InflateData(mat,z,buf.ui32,256*data_size);
                        for ( j = 0; j < 256; j++ )
                            data[i+j] = buf.ui32[j];
                    }
                    len = len-(i-256);
                    InflateData(mat,z,buf.ui32,len*data_size);
                    for ( j = 0; j < len; j++ )
                        data[i+j] = buf.ui32[j];
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                if ( len <= 512 ){
                    InflateData(mat,z,buf.i16,len*data_size);
                    for ( i = 0; i < len; i++ )
                        data[i] = Mat_int16Swap(buf.i16+i);
                } else {
                    int j;
                    len -= 512;
                    for ( i = 0; i < len; i+=512 ) {
                        InflateData(mat,z,buf.i16,512*data_size);
                        for ( j = 0; j < 512; j++ )
                            data[i+j] = Mat_int16Swap(buf.i16+j);
                    }
                    len = len-(i-512);
                    InflateData(mat,z,buf.i16,len*data_size);
                    for ( j = 0; j < len; j++ )
                        data[i+j] = Mat_int16Swap(buf.i16+j);
                }
            } else {
                if ( len <= 512 ) {
                    InflateData(mat,z,buf.i16,len*data_size);
                    for ( i = 0; i < len; i++ )
                        data[i] = buf.i16[i];
                } else {
                    int j;
                    len -= 512;
                    for ( i = 0; i < len; i+=512 ) {
                        InflateData(mat,z,buf.i16,512*data_size);
                        for ( j = 0; j < 512; j++ )
                            data[i+j] = buf.i16[j];
                    }
                    len = len-(i-512);
                    InflateData(mat,z,buf.i16,len*data_size);
                    for ( j = 0; j < len; j++ )
                        data[i+j] = buf.i16[j];
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                if ( len <= 512 ){
                    InflateData(mat,z,buf.ui16,len*data_size);
                    for ( i = 0; i < len; i++ )
                        data[i] = Mat_uint16Swap(buf.ui16+i);
                } else {
                    int j;
                    len -= 512;
                    for ( i = 0; i < len; i+=512 ) {
                        InflateData(mat,z,buf.ui16,512*data_size);
                        for ( j = 0; j < 512; j++ )
                            data[i+j] = Mat_uint16Swap(buf.ui16+j);
                    }
                    len = len-(i-512);
                    InflateData(mat,z,buf.ui16,len*data_size);
                    for ( j = 0; j < len; j++ )
                        data[i+j] = Mat_uint16Swap(buf.ui16+j);
                }
            } else {
                if ( len <= 512 ) {
                    InflateData(mat,z,buf.ui16,len*data_size);
                    for ( i = 0; i < len; i++ )
                        data[i] = buf.ui16[i];
                } else {
                    int j;
                    len -= 512;
                    for ( i = 0; i < len; i+=512 ) {
                        InflateData(mat,z,buf.ui16,512*data_size);
                        for ( j = 0; j < 512; j++ )
                            data[i+j] = buf.ui16[j];
                    }
                    len = len-(i-512);
                    InflateData(mat,z,buf.ui16,len*data_size);
                    for ( j = 0; j < len; j++ )
                        data[i+j] = buf.ui16[j];
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            data_size = sizeof(mat_uint8_t);
            if ( len <= 1024 ) {
                InflateData(mat,z,buf.ui8,len*data_size);
                for ( i = 0; i < len; i++ )
                    data[i] = buf.ui8[i];
            } else {
                int j;
                len -= 1024;
                for ( i = 0; i < len; i+=1024 ) {
                    InflateData(mat,z,buf.ui8,1024*data_size);
                    for ( j = 0; j < 1024; j++ )
                        data[i+j] = buf.ui8[j];
                }
                len = len-(i-1024);
                InflateData(mat,z,buf.ui8,len*data_size);
                for ( j = 0; j < len; j++ )
                    data[i+j] = buf.ui8[j];
            }
            break;
        }
        case MAT_T_INT8:
        {
            data_size = sizeof(mat_int8_t);
            if ( len <= 1024 ) {
                InflateData(mat,z,buf.i8,len*data_size);
                for ( i = 0; i < len; i++ )
                    data[i] = buf.i8[i];
            } else {
                int j;
                len -= 1024;
                for ( i = 0; i < len; i+=1024 ) {
                    InflateData(mat,z,buf.i8,1024*data_size);
                    for ( j = 0; j < 1024; j++ )
                        data[i+j] = buf.i8[j];
                }
                len = len-(i-1024);
                InflateData(mat,z,buf.i8,len*data_size);
                for ( j = 0; j < len; j++ )
                    data[i+j] = buf.i8[j];
            }
            break;
        }
        default:
            return 0;
    }
    nBytes = len*data_size;
    return nBytes;
}
#endif

/** @brief Reads data of type @c data_type into a float type
 *
 * Reads from the MAT file @c len elements of data type @c data_type storing
 * them as float's in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data Pointer to store the output float values (len*sizeof(float))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadSingleData(mat_t *mat,float *data,enum matio_types data_type,int len)
{
    int bytesread = 0, data_size = 0, i;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&i8,data_size,1,(FILE*)mat->fp);
                data[i] = i8;
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&ui8,data_size,1,(FILE*)mat->fp);
                data[i] = ui8;
            }
            break;
        }
        default:
            return 0;
    }
    bytesread *= data_size;
    return bytesread;
}

#if defined(HAVE_ZLIB)
/** @brief Reads data of type @c data_type into a float type
 *
 * Reads from the MAT file @c len compressed elements of data type @c data_type
 * storing them as float's in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z Pointer to the zlib stream for inflation
 * @param data Pointer to store the output float values (len*sizeof(float))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadCompressedSingleData(mat_t *mat,z_streamp z,float *data,
    enum matio_types data_type,int len)
{
    int nBytes = 0, data_size = 0, i;

    if ( (mat == NULL) || (data == NULL) || (z == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,data+i,data_size);
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&ui8,data_size);
                data[i] = ui8;
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&i8,data_size);
                data[i] = i8;
            }
            break;
        }
        default:
            return 0;
    }
    nBytes = len*data_size;
    return nBytes;
}
#endif

#ifdef HAVE_MATIO_INT64_T
/** @brief Reads data of type @c data_type into a signed 64-bit integer type
 *
 * Reads from the MAT file @c len elements of data type @c data_type storing
 * them as signed 64-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data Pointer to store the output signed 64-bit integer values
 *             (len*sizeof(mat_int64_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadInt64Data(mat_t *mat,mat_int64_t *data,enum matio_types data_type,int len)
{
    int bytesread = 0, data_size = 0, i;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT64:
        {
            mat_int64_t i64;

            data_size = sizeof(mat_int64_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i64,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int64Swap(&i64);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i64,data_size,1,(FILE*)mat->fp);
                    data[i] = i64;
                }
            }
            break;
        }
#ifdef HAVE_MATIO_UINT64_T
        case MAT_T_UINT64:
        {
            mat_uint64_t ui64;

            data_size = sizeof(mat_uint64_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui64,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint64Swap(&ui64);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui64,data_size,1,(FILE*)mat->fp);
                    data[i] = ui64;
                }
            }
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&i8,data_size,1,(FILE*)mat->fp);
                data[i] = i8;
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&ui8,data_size,1,(FILE*)mat->fp);
                data[i] = ui8;
            }
            break;
        }
        default:
            return 0;
    }
    bytesread *= data_size;
    return bytesread;
}

#if defined(HAVE_ZLIB)
/** @brief Reads data of type @c data_type into a signed 64-bit integer type
 *
 * Reads from the MAT file @c len compressed elements of data type @c data_type
 * storing them as signed 64-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z Pointer to the zlib stream for inflation
 * @param data Pointer to store the output signed 64-bit integer values
 *             (len*sizeof(mat_int64_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadCompressedInt64Data(mat_t *mat,z_streamp z,mat_int64_t *data,
    enum matio_types data_type,int len)
{
    int nBytes = 0, data_size = 0, i;

    if ( (mat == NULL) || (data == NULL) || (z == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT64:
        {
            mat_int64_t i64;

            data_size = sizeof(mat_int64_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i64,data_size);
                    data[i] = Mat_int64Swap(&i64);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i64,data_size);
                    data[i] = i64;
                }
            }
            break;
        }
        case MAT_T_UINT64:
        {
            mat_uint64_t ui64;

            data_size = sizeof(mat_uint64_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui64,data_size);
                    data[i] = Mat_uint64Swap(&ui64);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui64,data_size);
                    data[i] = ui64;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&ui8,data_size);
                data[i] = ui8;
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&i8,data_size);
                data[i] = i8;
            }
            break;
        }
        default:
            return 0;
    }
    nBytes = len*data_size;
    return nBytes;
}
#endif
#endif /* HAVE_MATIO_INT64_T */

#ifdef HAVE_MATIO_UINT64_T
/** @brief Reads data of type @c data_type into an unsigned 64-bit integer type
 *
 * Reads from the MAT file @c len elements of data type @c data_type storing
 * them as unsigned 64-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data Pointer to store the output unsigned 64-bit integer values
 *             (len*sizeof(mat_uint64_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadUInt64Data(mat_t *mat,mat_uint64_t *data,enum matio_types data_type,int len)
{
    int bytesread = 0, data_size = 0, i;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = f;
                }
            }
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_T_INT64:
        {
            mat_int64_t i64;

            data_size = sizeof(mat_int64_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i64,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int64Swap(&i64);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i64,data_size,1,(FILE*)mat->fp);
                    data[i] = i64;
                }
            }
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
        case MAT_T_UINT64:
        {
            mat_uint64_t ui64;

            data_size = sizeof(mat_uint64_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui64,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint64Swap(&ui64);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui64,data_size,1,(FILE*)mat->fp);
                    data[i] = ui64;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&i8,data_size,1,(FILE*)mat->fp);
                data[i] = i8;
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&ui8,data_size,1,(FILE*)mat->fp);
                data[i] = ui8;
            }
            break;
        }
        default:
            return 0;
    }
    bytesread *= data_size;
    return bytesread;
}

#if defined(HAVE_ZLIB)
/** @brief Reads data of type @c data_type into an unsigned 64-bit integer type
 *
 * Reads from the MAT file @c len compressed elements of data type @c data_type
 * storing them as unsigned 64-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z Pointer to the zlib stream for inflation
 * @param data Pointer to store the output unsigned 64-bit integer values
 *             (len*sizeof(mat_uint64_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadCompressedUInt64Data(mat_t *mat,z_streamp z,mat_uint64_t *data,
    enum matio_types data_type,int len)
{
    int nBytes = 0, data_size = 0, i;

    if ( (mat == NULL) || (data == NULL) || (z == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT64:
        {
            mat_int64_t i64;

            data_size = sizeof(mat_int64_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i64,data_size);
                    data[i] = Mat_int64Swap(&i64);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i64,data_size);
                    data[i] = i64;
                }
            }
            break;
        }
        case MAT_T_UINT64:
        {
            mat_uint64_t ui64;

            data_size = sizeof(mat_uint64_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui64,data_size);
                    data[i] = Mat_uint64Swap(&ui64);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui64,data_size);
                    data[i] = ui64;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&ui8,data_size);
                data[i] = ui8;
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&i8,data_size);
                data[i] = i8;
            }
            break;
        }
        default:
            return 0;
    }
    nBytes = len*data_size;
    return nBytes;
}
#endif /* HAVE_ZLIB */
#endif /* HAVE_MATIO_UINT64_T */

/** @brief Reads data of type @c data_type into a signed 32-bit integer type
 *
 * Reads from the MAT file @c len elements of data type @c data_type storing
 * them as signed 32-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data Pointer to store the output signed 32-bit integer values
 *             (len*sizeof(mat_int32_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadInt32Data(mat_t *mat,mat_int32_t *data,enum matio_types data_type,int len)
{
    int bytesread = 0, data_size = 0, i;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&i8,data_size,1,(FILE*)mat->fp);
                data[i] = i8;
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&ui8,data_size,1,(FILE*)mat->fp);
                data[i] = ui8;
            }
            break;
        }
        default:
            return 0;
    }
    bytesread *= data_size;
    return bytesread;
}

#if defined(HAVE_ZLIB)
/** @brief Reads data of type @c data_type into a signed 32-bit integer type
 *
 * Reads from the MAT file @c len compressed elements of data type @c data_type
 * storing them as signed 32-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z Pointer to the zlib stream for inflation
 * @param data Pointer to store the output signed 32-bit integer values
 *             (len*sizeof(mat_int32_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadCompressedInt32Data(mat_t *mat,z_streamp z,mat_int32_t *data,
    enum matio_types data_type,int len)
{
    int nBytes = 0, data_size = 0, i;

    if ( (mat == NULL) || (data == NULL) || (z == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&ui8,data_size);
                data[i] = ui8;
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&i8,data_size);
                data[i] = i8;
            }
            break;
        }
        default:
            return 0;
    }
    nBytes = len*data_size;
    return nBytes;
}
#endif

/** @brief Reads data of type @c data_type into an unsigned 32-bit integer type
 *
 * Reads from the MAT file @c len elements of data type @c data_type storing
 * them as unsigned 32-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data Pointer to store the output unsigned 32-bit integer values
 *             (len*sizeof(mat_uint32_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadUInt32Data(mat_t *mat,mat_uint32_t *data,enum matio_types data_type,int len)
{
    int bytesread = 0, data_size = 0, i;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&i8,data_size,1,(FILE*)mat->fp);
                data[i] = i8;
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&ui8,data_size,1,(FILE*)mat->fp);
                data[i] = ui8;
            }
            break;
        }
        default:
            return 0;
    }
    bytesread *= data_size;
    return bytesread;
}

#if defined(HAVE_ZLIB)
/** @brief Reads data of type @c data_type into an unsigned 32-bit integer type
 *
 * Reads from the MAT file @c len compressed elements of data type @c data_type
 * storing them as unsigned 32-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z Pointer to the zlib stream for inflation
 * @param data Pointer to store the output unsigned 32-bit integer values
 *             (len*sizeof(mat_uint32_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadCompressedUInt32Data(mat_t *mat,z_streamp z,mat_uint32_t *data,
    enum matio_types data_type,int len)
{
    int nBytes = 0, data_size = 0, i;

    if ( (mat == NULL) || (data == NULL) || (z == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&ui8,data_size);
                data[i] = ui8;
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&i8,data_size);
                data[i] = i8;
            }
            break;
        }
        default:
            return 0;
    }
    nBytes = len*data_size;
    return nBytes;
}
#endif

/** @brief Reads data of type @c data_type into a signed 16-bit integer type
 *
 * Reads from the MAT file @c len elements of data type @c data_type storing
 * them as signed 16-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data Pointer to store the output signed 16-bit integer values
 *             (len*sizeof(mat_int16_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadInt16Data(mat_t *mat,mat_int16_t *data,enum matio_types data_type,int len)
{
    int bytesread = 0, data_size = 0, i;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&i8,data_size,1,(FILE*)mat->fp);
                data[i] = i8;
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&ui8,data_size,1,(FILE*)mat->fp);
                data[i] = ui8;
            }
            break;
        }
        default:
            return 0;
    }
    bytesread *= data_size;
    return bytesread;
}

#if defined(HAVE_ZLIB)
/** @brief Reads data of type @c data_type into a signed 16-bit integer type
 *
 * Reads from the MAT file @c len compressed elements of data type @c data_type
 * storing them as signed 16-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z Pointer to the zlib stream for inflation
 * @param data Pointer to store the output signed 16-bit integer values
 *             (len*sizeof(mat_int16_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadCompressedInt16Data(mat_t *mat,z_streamp z,mat_int16_t *data,
    enum matio_types data_type,int len)
{
    int nBytes = 0, data_size = 0, i;

    if ( (mat == NULL) || (data == NULL) || (z == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&ui8,data_size);
                data[i] = ui8;
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&i8,data_size);
                data[i] = i8;
            }
            break;
        }
        default:
            return 0;
    }
    nBytes = len*data_size;
    return nBytes;
}
#endif

/** @brief Reads data of type @c data_type into an unsigned 16-bit integer type
 *
 * Reads from the MAT file @c len elements of data type @c data_type storing
 * them as unsigned 16-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data Pointer to store the output unsigned 16-bit integer values
 *             (len*sizeof(mat_uint16_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadUInt16Data(mat_t *mat,mat_uint16_t *data,enum matio_types data_type,int len)
{
    int bytesread = 0, data_size = 0, i;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&i8,data_size,1,(FILE*)mat->fp);
                data[i] = i8;
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&ui8,data_size,1,(FILE*)mat->fp);
                data[i] = ui8;
            }
            break;
        }
        default:
            return 0;
    }
    bytesread *= data_size;
    return bytesread;
}

#if defined(HAVE_ZLIB)
/** @brief Reads data of type @c data_type into an unsigned 16-bit integer type
 *
 * Reads from the MAT file @c len compressed elements of data type @c data_type
 * storing them as unsigned 16-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z Pointer to the zlib stream for inflation
 * @param data Pointer to store the output n unsigned 16-bit integer values
 *             (len*sizeof(mat_uint16_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadCompressedUInt16Data(mat_t *mat,z_streamp z,mat_uint16_t *data,
    enum matio_types data_type,int len)
{
    int nBytes = 0, data_size = 0, i;

    if ( (mat == NULL) || (data == NULL) || (z == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&ui8,data_size);
                data[i] = ui8;
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&i8,data_size);
                data[i] = i8;
            }
            break;
        }
        default:
            return 0;
    }
    nBytes = len*data_size;
    return nBytes;
}
#endif

/** @brief Reads data of type @c data_type into a signed 8-bit integer type
 *
 * Reads from the MAT file @c len elements of data type @c data_type storing
 * them as signed 8-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data Pointer to store the output signed 8-bit integer values
 *             (len*sizeof(mat_int8_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadInt8Data(mat_t *mat,mat_int8_t *data,enum matio_types data_type,int len)
{
    int bytesread = 0, data_size = 0, i;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&i8,data_size,1,(FILE*)mat->fp);
                data[i] = i8;
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&ui8,data_size,1,(FILE*)mat->fp);
                data[i] = ui8;
            }
            break;
        }
        default:
            return 0;
    }
    bytesread *= data_size;
    return bytesread;
}

#if defined(HAVE_ZLIB)
/** @brief Reads data of type @c data_type into a signed 8-bit integer type
 *
 * Reads from the MAT file @c len compressed elements of data type @c data_type
 * storing them as signed 8-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z Pointer to the zlib stream for inflation
 * @param data Pointer to store the output signed 8-bit integer values
 *             (len*sizeof(mat_int8_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadCompressedInt8Data(mat_t *mat,z_streamp z,mat_int8_t *data,
    enum matio_types data_type,int len)
{
    int nBytes = 0, data_size = 0, i;

    if ( (mat == NULL) || (data == NULL) || (z == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&ui8,data_size);
                data[i] = ui8;
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&i8,data_size);
                data[i] = i8;
            }
            break;
        }
        default:
            return 0;
    }
    nBytes = len*data_size;
    return nBytes;
}
#endif

/** @brief Reads data of type @c data_type into an unsigned 8-bit integer type
 *
 * Reads from the MAT file @c len elements of data type @c data_type storing
 * them as unsigned 8-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data Pointer to store the output unsigned 8-bit integer values
 *             (len*sizeof(mat_uint8_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadUInt8Data(mat_t *mat,mat_uint8_t *data,enum matio_types data_type,int len)
{
    int bytesread = 0, data_size = 0, i;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,(FILE*)mat->fp);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,(FILE*)mat->fp);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,(FILE*)mat->fp);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,(FILE*)mat->fp);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,(FILE*)mat->fp);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,(FILE*)mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&i8,data_size,1,(FILE*)mat->fp);
                data[i] = i8;
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                bytesread += fread(&ui8,data_size,1,(FILE*)mat->fp);
                data[i] = ui8;
            }
            break;
        }
        default:
            return 0;
    }
    bytesread *= data_size;
    return bytesread;
}

#if defined(HAVE_ZLIB)
/** @brief Reads data of type @c data_type into an unsigned 8-bit integer type
 *
 * Reads from the MAT file @c len compressed elements of data type @c data_type
 * storing them as unsigned 8-bit integers in @c data.
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param z Pointer to the zlib stream for inflation
 * @param data Pointer to store the output 8-bit integer values
 *             (len*sizeof(mat_uint8_t))
 * @param data_type one of the @c matio_types enumerations which is the source
 *                  data type in the file
 * @param len Number of elements of type @c data_type to read from the file
 * @retval Number of bytes read from the file
 */
static int
ReadCompressedUInt8Data(mat_t *mat,z_streamp z,mat_uint8_t *data,
    enum matio_types data_type,int len)
{
    int nBytes = 0, data_size = 0, i;

    if ( (mat == NULL) || (data == NULL) || (z == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d;

            data_size = sizeof(double);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&d,data_size);
                    data[i] = d;
                }
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&f,data_size);
                    data[i] = f;
                }
            }
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32;

            data_size = sizeof(mat_int32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i32,data_size);
                    data[i] = i32;
                }
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32;

            data_size = sizeof(mat_uint32_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui32,data_size);
                    data[i] = ui32;
                }
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16;

            data_size = sizeof(mat_int16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = i16;
                }
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16;

            data_size = sizeof(mat_uint16_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&ui16,data_size);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&ui8,data_size);
                data[i] = ui8;
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            for ( i = 0; i < len; i++ ) {
                InflateData(mat,z,&i8,data_size);
                data[i] = i8;
            }
            break;
        }
        default:
            return 0;
    }
    nBytes = len*data_size;
    return nBytes;
}
#endif

#if defined(HAVE_ZLIB)
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
ReadCompressedCharData(mat_t *mat,z_streamp z,char *data,
    enum matio_types data_type,int len)
{
    int nBytes = 0, data_size = 0, i;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_UTF8:
            data_size = 1;
            for ( i = 0; i < len; i++ )
                InflateData(mat,z,data+i,data_size);
            break;
        case MAT_T_INT8:
        case MAT_T_UINT8:
            data_size = 1;
            for ( i = 0; i < len; i++ )
                InflateData(mat,z,data+i,data_size);
            break;
        case MAT_T_INT16:
        case MAT_T_UINT16:
        {
            mat_uint16_t i16;

            data_size = 2;
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = Mat_uint16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    InflateData(mat,z,&i16,data_size);
                    data[i] = i16;
                }
            }
            break;
        }
        default:
            printf("Character data not supported type: %d",data_type);
            break;
    }
    nBytes = len*data_size;
    return nBytes;
}
#endif

static int
ReadCharData(mat_t *mat,char *data,enum matio_types data_type,int len)
{
    int bytesread = 0, data_size = 0, i;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_UTF8:
            for ( i = 0; i < len; i++ )
                bytesread += fread(data+i,1,1,(FILE*)mat->fp);
            break;
        case MAT_T_INT8:
        case MAT_T_UINT8:
            for ( i = 0; i < len; i++ )
                bytesread += fread(data+i,1,1,(FILE*)mat->fp);
            break;
        case MAT_T_INT16:
        case MAT_T_UINT16:
        {
            mat_uint16_t i16;

            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,2,1,(FILE*)mat->fp);
                    data[i] = Mat_uint16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,2,1,(FILE*)mat->fp);
                    data[i] = i16;
                }
            }
            break;
        }
        default:
            printf("Character data not supported type: %d",data_type);
            break;
    }
    bytesread *= data_size;
    return bytesread;
}

/*
 *-------------------------------------------------------------------
 *  Routines to read "slabs" of data
 *-------------------------------------------------------------------
 */

#define READ_DATA_SLABN_RANK_LOOP \
    do { \
        for ( j = 1; j < rank; j++ ) { \
            cnt[j]++; \
            if ( (cnt[j] % edge[j]) == 0 ) { \
                cnt[j] = 0; \
                if ( (I % dimp[j]) != 0 ) { \
                    (void)fseek((FILE*)mat->fp,data_size*(dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j]),SEEK_CUR); \
                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j]; \
                } else if ( start[j] ) { \
                    (void)fseek((FILE*)mat->fp,data_size*(dimp[j-1]*start[j]),SEEK_CUR); \
                    I += dimp[j-1]*start[j]; \
                } \
            } else { \
                I += inc[j]; \
                (void)fseek((FILE*)mat->fp,data_size*inc[j],SEEK_CUR); \
                break; \
            } \
        } \
    } while (0)

#define READ_DATA_SLABN(ReadDataFunc) \
    do { \
        inc[0]  = stride[0]-1; \
        dimp[0] = dims[0]; \
        N       = edge[0]; \
        I       = 0; /* start[0]; */ \
        for ( i = 1; i < rank; i++ ) { \
            inc[i]  = stride[i]-1; \
            dimp[i] = dims[i-1]; \
            for ( j = i; j--; ) { \
                inc[i]  *= dims[j]; \
                dimp[i] *= dims[j+1]; \
            } \
            N *= edge[i]; \
            I += dimp[i-1]*start[i]; \
        } \
        (void)fseek((FILE*)mat->fp,I*data_size,SEEK_CUR); \
        if ( stride[0] == 1 ) { \
            for ( i = 0; i < N; i+=edge[0] ) { \
                if ( start[0] ) { \
                    (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR); \
                    I += start[0]; \
                } \
                ReadDataFunc(mat,ptr+i,data_type,edge[0]); \
                I += dims[0]-start[0]; \
                (void)fseek((FILE*)mat->fp,data_size*(dims[0]-edge[0]-start[0]), \
                    SEEK_CUR); \
                READ_DATA_SLABN_RANK_LOOP; \
            } \
        } else { \
            for ( i = 0; i < N; i+=edge[0] ) { \
                if ( start[0] ) { \
                    (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR); \
                    I += start[0]; \
                } \
                for ( j = 0; j < edge[0]; j++ ) { \
                    ReadDataFunc(mat,ptr+i+j,data_type,1); \
                    (void)fseek((FILE*)mat->fp,data_size*(stride[0]-1),SEEK_CUR); \
                    I += stride[0]; \
                } \
                I += dims[0]-edge[0]*stride[0]-start[0]; \
                (void)fseek((FILE*)mat->fp,data_size* \
                    (dims[0]-edge[0]*stride[0]-start[0]),SEEK_CUR); \
                READ_DATA_SLABN_RANK_LOOP; \
            } \
        } \
    } while (0)

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
ReadDataSlabN(mat_t *mat,void *data,enum matio_classes class_type,
    enum matio_types data_type,int rank,size_t *dims,int *start,int *stride,
    int *edge)
{
    int nBytes = 0, i, j, N, I = 0;
    int inc[10] = {0,}, cnt[10] = {0,}, dimp[10] = {0,};
    size_t data_size;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) ||
         (start == NULL) || (stride == NULL) || (edge    == NULL) ) {
        return -1;
    } else if ( rank > 10 ) {
        return -1;
    }

    data_size = Mat_SizeOf(data_type);
    switch ( class_type ) {
        case MAT_C_DOUBLE:
        {
            double *ptr = (double*)data;
            READ_DATA_SLABN(ReadDoubleData);
            break;
        }
        case MAT_C_SINGLE:
        {
            float *ptr = (float*)data;
            READ_DATA_SLABN(ReadSingleData);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
        {
            mat_int64_t *ptr = (mat_int64_t*)data;
            READ_DATA_SLABN(ReadInt64Data);
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
        {
            mat_uint64_t *ptr = (mat_uint64_t*)data;
            READ_DATA_SLABN(ReadUInt64Data);
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
        {
            mat_int32_t *ptr = (mat_int32_t*)data;
            READ_DATA_SLABN(ReadInt32Data);
            break;
        }
        case MAT_C_UINT32:
        {
            mat_uint32_t *ptr = (mat_uint32_t*)data;
            READ_DATA_SLABN(ReadUInt32Data);
            break;
        }
        case MAT_C_INT16:
        {
            mat_int16_t *ptr = (mat_int16_t*)data;
            READ_DATA_SLABN(ReadInt16Data);
            break;
        }
        case MAT_C_UINT16:
        {
            mat_uint16_t *ptr = (mat_uint16_t*)data;
            READ_DATA_SLABN(ReadUInt16Data);
            break;
        }
        case MAT_C_INT8:
        {
            mat_int8_t *ptr = (mat_int8_t*)data;
            READ_DATA_SLABN(ReadInt8Data);
            break;
        }
        case MAT_C_UINT8:
        {
            mat_uint8_t *ptr = (mat_uint8_t*)data;
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

#if defined(HAVE_ZLIB)
#define READ_COMPRESSED_DATA_SLABN_RANK_LOOP \
    do { \
        for ( j = 1; j < rank; j++ ) { \
            cnt[j]++; \
            if ( (cnt[j] % edge[j]) == 0 ) { \
                cnt[j] = 0; \
                if ( (I % dimp[j]) != 0 ) { \
                    InflateSkipData(mat,&z_copy,data_type, dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j]); \
                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j]; \
                } else if ( start[j] ) { \
                    InflateSkipData(mat,&z_copy,data_type, dimp[j-1]*start[j]); \
                    I += dimp[j-1]*start[j]; \
                } \
            } else { \
                if ( inc[j] ) { \
                    I += inc[j]; \
                    InflateSkipData(mat,&z_copy,data_type,inc[j]); \
                } \
                break; \
            } \
        } \
    } while (0)

#define READ_COMPRESSED_DATA_SLABN(ReadDataFunc) \
    do { \
        inc[0]  = stride[0]-1; \
        dimp[0] = dims[0]; \
        N       = edge[0]; \
        I       = 0; \
        for ( i = 1; i < rank; i++ ) { \
            inc[i]  = stride[i]-1; \
            dimp[i] = dims[i-1]; \
            for ( j = i; j--; ) { \
                inc[i]  *= dims[j]; \
                dimp[i] *= dims[j+1]; \
            } \
            N *= edge[i]; \
            I += dimp[i-1]*start[i]; \
        } \
        /* Skip all data to the starting indices */ \
        InflateSkipData(mat,&z_copy,data_type,I); \
        if ( stride[0] == 1 ) { \
            for ( i = 0; i < N; i+=edge[0] ) { \
                if ( start[0] ) { \
                    InflateSkipData(mat,&z_copy,data_type,start[0]); \
                    I += start[0]; \
                } \
                ReadDataFunc(mat,&z_copy,ptr+i,data_type,edge[0]); \
                InflateSkipData(mat,&z_copy,data_type,dims[0]-start[0]-edge[0]); \
                I += dims[0]-start[0]; \
                READ_COMPRESSED_DATA_SLABN_RANK_LOOP; \
            } \
        } else { \
            for ( i = 0; i < N; i+=edge[0] ) { \
                if ( start[0] ) { \
                    InflateSkipData(mat,&z_copy,data_type,start[0]); \
                    I += start[0]; \
                } \
                for ( j = 0; j < edge[0]-1; j++ ) { \
                    ReadDataFunc(mat,&z_copy,ptr+i+j,data_type,1); \
                    InflateSkipData(mat,&z_copy,data_type,(stride[0]-1)); \
                    I += stride[0]; \
                } \
                ReadDataFunc(mat,&z_copy,ptr+i+j,data_type,1); \
                I += dims[0]-(edge[0]-1)*stride[0]-start[0]; \
                InflateSkipData(mat,&z_copy,data_type,dims[0]-(edge[0]-1)*stride[0]-start[0]-1); \
                READ_COMPRESSED_DATA_SLABN_RANK_LOOP; \
            } \
        } \
    } while (0)

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
ReadCompressedDataSlabN(mat_t *mat,z_streamp z,void *data,
    enum matio_classes class_type,enum matio_types data_type,int rank,
    size_t *dims,int *start,int *stride,int *edge)
{
    int nBytes = 0, i, j, N, I = 0;
    int inc[10] = {0,}, cnt[10] = {0,}, dimp[10] = {0,};
    z_stream z_copy = {0,};

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) ||
         (start == NULL) || (stride == NULL) || (edge    == NULL) ) {
        return 1;
    } else if ( rank > 10 ) {
        return 1;
    }

    i = inflateCopy(&z_copy,z);
    switch ( class_type ) {
        case MAT_C_DOUBLE:
        {
            double *ptr = (double*)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedDoubleData);
            break;
        }
        case MAT_C_SINGLE:
        {
            float *ptr = (float*)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedSingleData);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
        {
            mat_int64_t *ptr = (mat_int64_t*)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedInt64Data);
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
        {
            mat_uint64_t *ptr = (mat_uint64_t*)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedUInt64Data);
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
        {
            mat_int32_t *ptr = (mat_int32_t*)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedInt32Data);
            break;
        }
        case MAT_C_UINT32:
        {
            mat_uint32_t *ptr = (mat_uint32_t*)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedUInt32Data);
            break;
        }
        case MAT_C_INT16:
        {
            mat_int16_t *ptr = (mat_int16_t*)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedInt16Data);
            break;
        }
        case MAT_C_UINT16:
        {
            mat_uint16_t *ptr = (mat_uint16_t*)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedUInt16Data);
            break;
        }
        case MAT_C_INT8:
        {
            mat_int8_t *ptr = (mat_int8_t*)data;
            READ_COMPRESSED_DATA_SLABN(ReadCompressedInt8Data);
            break;
        }
        case MAT_C_UINT8:
        {
            mat_uint8_t *ptr = (mat_uint8_t*)data;
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

#define READ_DATA_SLAB1(ReadDataFunc) \
    do { \
        if ( !stride ) { \
            bytesread+=ReadDataFunc(mat,ptr,data_type,edge); \
        } else { \
            for ( i = 0; i < edge; i++ ) { \
                bytesread+=ReadDataFunc(mat,ptr+i,data_type,1); \
                (void)fseek((FILE*)mat->fp,stride,SEEK_CUR); \
            } \
        } \
    } while (0)

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
ReadDataSlab1(mat_t *mat,void *data,enum matio_classes class_type,
    enum matio_types data_type,int start,int stride,int edge)
{
    int i;
    size_t data_size;
    int    bytesread = 0;

    data_size = Mat_SizeOf(data_type);
    (void)fseek((FILE*)mat->fp,start*data_size,SEEK_CUR);

    stride = data_size*(stride-1);
    switch ( class_type ) {
        case MAT_C_DOUBLE:
        {
            double *ptr = (double*)data;
            READ_DATA_SLAB1(ReadDoubleData);
            break;
        }
        case MAT_C_SINGLE:
        {
            float *ptr = (float*)data;
            READ_DATA_SLAB1(ReadSingleData);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
        {
            mat_int64_t *ptr = (mat_int64_t*)data;
            READ_DATA_SLAB1(ReadInt64Data);
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
        {
            mat_uint64_t *ptr = (mat_uint64_t*)data;
            READ_DATA_SLAB1(ReadUInt64Data);
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
        {
            mat_int32_t *ptr = (mat_int32_t*)data;
            READ_DATA_SLAB1(ReadInt32Data);
            break;
        }
        case MAT_C_UINT32:
        {
            mat_uint32_t *ptr = (mat_uint32_t*)data;
            READ_DATA_SLAB1(ReadUInt32Data);
            break;
        }
        case MAT_C_INT16:
        {
            mat_int16_t *ptr = (mat_int16_t*)data;
            READ_DATA_SLAB1(ReadInt16Data);
            break;
        }
        case MAT_C_UINT16:
        {
            mat_uint16_t *ptr = (mat_uint16_t*)data;
            READ_DATA_SLAB1(ReadUInt16Data);
            break;
        }
        case MAT_C_INT8:
        {
            mat_int8_t *ptr = (mat_int8_t*)data;
            READ_DATA_SLAB1(ReadInt8Data);
            break;
        }
        case MAT_C_UINT8:
        {
            mat_uint8_t *ptr = (mat_uint8_t*)data;
            READ_DATA_SLAB1(ReadUInt8Data);
            break;
        }
        default:
            return 0;
    }

    return bytesread;
}

#undef READ_DATA_SLAB1

#define READ_DATA_SLAB2(ReadDataFunc) \
    do { \
        /* If stride[0] is 1 and stride[1] is 1, we are reading all of the */ \
        /* data so get rid of the loops. */ \
        if ( (stride[0] == 1 && edge[0] == dims[0]) && \
             (stride[1] == 1) ) { \
            ReadDataFunc(mat,ptr,data_type,edge[0]*edge[1]); \
        } else { \
            row_stride = (stride[0]-1)*data_size; \
            col_stride = stride[1]*dims[0]*data_size; \
            pos = ftell((FILE*)mat->fp); \
            if ( pos == -1L ) { \
                Mat_Critical("Couldn't determine file position"); \
                return -1; \
            } \
            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR); \
            for ( i = 0; i < edge[1]; i++ ) { \
                pos = ftell((FILE*)mat->fp); \
                if ( pos == -1L ) { \
                    Mat_Critical("Couldn't determine file position"); \
                    return -1; \
                } \
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR); \
                for ( j = 0; j < edge[0]; j++ ) { \
                    ReadDataFunc(mat,ptr++,data_type,1); \
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR); \
                } \
                pos2 = ftell((FILE*)mat->fp); \
                if ( pos2 == -1L ) { \
                    Mat_Critical("Couldn't determine file position"); \
                    return -1; \
                } \
                pos +=col_stride-pos2; \
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR); \
            } \
        } \
    } while (0)

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
ReadDataSlab2(mat_t *mat,void *data,enum matio_classes class_type,
    enum matio_types data_type,size_t *dims,int *start,int *stride,int *edge)
{
    int nBytes = 0, data_size, i, j;
    long pos, row_stride, col_stride, pos2;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) ||
         (start == NULL) || (stride == NULL) || (edge    == NULL) ) {
        return 0;
    }

    data_size = Mat_SizeOf(data_type);

    switch ( class_type ) {
        case MAT_C_DOUBLE:
        {
            double *ptr = (double*)data;
            READ_DATA_SLAB2(ReadDoubleData);
            break;
        }
        case MAT_C_SINGLE:
        {
            float *ptr = (float*)data;
            READ_DATA_SLAB2(ReadSingleData);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
        {
            mat_int64_t *ptr = (mat_int64_t*)data;
            READ_DATA_SLAB2(ReadInt64Data);
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
        {
            mat_uint64_t *ptr = (mat_uint64_t*)data;
            READ_DATA_SLAB2(ReadUInt64Data);
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
        {
            mat_int32_t *ptr = (mat_int32_t*)data;
            READ_DATA_SLAB2(ReadInt32Data);
            break;
        }
        case MAT_C_UINT32:
        {
            mat_uint32_t *ptr = (mat_uint32_t*)data;
            READ_DATA_SLAB2(ReadUInt32Data);
            break;
        }
        case MAT_C_INT16:
        {
            mat_int16_t *ptr = (mat_int16_t*)data;
            READ_DATA_SLAB2(ReadInt16Data);
            break;
        }
        case MAT_C_UINT16:
        {
            mat_uint16_t *ptr = (mat_uint16_t*)data;
            READ_DATA_SLAB2(ReadUInt16Data);
            break;
        }
        case MAT_C_INT8:
        {
            mat_int8_t *ptr = (mat_int8_t*)data;
            READ_DATA_SLAB2(ReadInt8Data);
            break;
        }
        case MAT_C_UINT8:
        {
            mat_uint8_t *ptr = (mat_uint8_t*)data;
            READ_DATA_SLAB2(ReadUInt8Data);
            break;
        }
        default:
            nBytes = 0;
    }
    return nBytes;
}

#undef READ_DATA_SLAB2

#if defined(HAVE_ZLIB)
#define READ_COMPRESSED_DATA_SLAB1(ReadDataFunc) \
    do { \
        if ( !stride ) { \
            nBytes+=ReadDataFunc(mat,&z_copy,ptr,data_type,edge); \
        } else { \
            for ( i = 0; i < edge; i++ ) { \
                nBytes+=ReadDataFunc(mat,&z_copy,ptr+i,data_type,1); \
                InflateSkipData(mat,&z_copy,data_type,stride); \
            } \
        } \
    } while (0)

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
ReadCompressedDataSlab1(mat_t *mat,z_streamp z,void *data,
    enum matio_classes class_type,enum matio_types data_type,int start,
    int stride,int edge)
{
    int nBytes = 0, i, err;
    z_stream z_copy = {0,};

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    stride--;
    err = inflateCopy(&z_copy,z);
    InflateSkipData(mat,&z_copy,data_type,start);
    switch ( class_type ) {
        case MAT_C_DOUBLE:
        {
            double *ptr = (double*)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedDoubleData);
            break;
        }
        case MAT_C_SINGLE:
        {
            float *ptr = (float*)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedSingleData);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
        {
            mat_int64_t *ptr = (mat_int64_t*)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedInt64Data);
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
        {
            mat_uint64_t *ptr = (mat_uint64_t*)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedUInt64Data);
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
        {
            mat_int32_t *ptr = (mat_int32_t*)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedInt32Data);
            break;
        }
        case MAT_C_UINT32:
        {
            mat_uint32_t *ptr = (mat_uint32_t*)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedUInt32Data);
            break;
        }
        case MAT_C_INT16:
        {
            mat_int16_t *ptr = (mat_int16_t*)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedInt16Data);
            break;
        }
        case MAT_C_UINT16:
        {
            mat_uint16_t *ptr = (mat_uint16_t*)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedUInt16Data);
            break;
        }
        case MAT_C_INT8:
        {
            mat_int8_t *ptr = (mat_int8_t*)data;
            READ_COMPRESSED_DATA_SLAB1(ReadCompressedInt8Data);
            break;
        }
        case MAT_C_UINT8:
        {
            mat_uint8_t *ptr = (mat_uint8_t*)data;
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

#define READ_COMPRESSED_DATA_SLAB2(ReadDataFunc) \
    do {\
        row_stride = (stride[0]-1); \
        col_stride = (stride[1]-1)*dims[0]; \
        InflateSkipData(mat,&z_copy,data_type,start[1]*dims[0]); \
        /* If stride[0] is 1 and stride[1] is 1, we are reading all of the */ \
        /* data so get rid of the loops.  If stride[0] is 1 and stride[1] */ \
        /* is not 0, we are reading whole columns, so get rid of inner loop */ \
        /* to speed up the code */ \
        if ( (stride[0] == 1 && edge[0] == dims[0]) && \
             (stride[1] == 1) ) { \
            ReadDataFunc(mat,&z_copy,ptr,data_type,edge[0]*edge[1]); \
        } else if ( stride[0] == 1 ) { \
            for ( i = 0; i < edge[1]; i++ ) { \
                InflateSkipData(mat,&z_copy,data_type,start[0]); \
                ReadDataFunc(mat,&z_copy,ptr,data_type,edge[0]); \
                ptr += edge[0]; \
                pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride; \
                InflateSkipData(mat,&z_copy,data_type,pos); \
            } \
        } else { \
            for ( i = 0; i < edge[1]; i++ ) { \
                InflateSkipData(mat,&z_copy,data_type,start[0]); \
                for ( j = 0; j < edge[0]-1; j++ ) { \
                    ReadDataFunc(mat,&z_copy,ptr++,data_type,1); \
                    InflateSkipData(mat,&z_copy,data_type,row_stride); \
                } \
                ReadDataFunc(mat,&z_copy,ptr++,data_type,1); \
                pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride; \
                InflateSkipData(mat,&z_copy,data_type,pos); \
            } \
        } \
    } while (0)

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
ReadCompressedDataSlab2(mat_t *mat,z_streamp z,void *data,
    enum matio_classes class_type,enum matio_types data_type,size_t *dims,
    int *start,int *stride,int *edge)
{
    int nBytes = 0, i, j, err;
    int pos, row_stride, col_stride;
    z_stream z_copy = {0,};

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) ||
         (start == NULL) || (stride == NULL) || (edge    == NULL) ) {
        return 0;
    }

    err = inflateCopy(&z_copy,z);
    switch ( class_type ) {
        case MAT_C_DOUBLE:
        {
            double *ptr = (double*)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedDoubleData);
            break;
        }
        case MAT_C_SINGLE:
        {
            float *ptr = (float*)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedSingleData);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
        {
            mat_int64_t *ptr = (mat_int64_t*)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedInt64Data);
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
        {
            mat_uint64_t *ptr = (mat_uint64_t*)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedUInt64Data);
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
        {
            mat_int32_t *ptr = (mat_int32_t*)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedInt32Data);
            break;
        }
        case MAT_C_UINT32:
        {
            mat_uint32_t *ptr = (mat_uint32_t*)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedUInt32Data);
            break;
        }
        case MAT_C_INT16:
        {
            mat_int16_t *ptr = (mat_int16_t*)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedInt16Data);
            break;
        }
        case MAT_C_UINT16:
        {
            mat_uint16_t *ptr = (mat_uint16_t*)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedUInt16Data);
            break;
        }
        case MAT_C_INT8:
        {
            mat_int8_t *ptr = (mat_int8_t*)data;
            READ_COMPRESSED_DATA_SLAB2(ReadCompressedInt8Data);
            break;
        }
        case MAT_C_UINT8:
        {
            mat_uint8_t *ptr = (mat_uint8_t*)data;
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
 * ---------- snprintf.c
 * -------------------------------
 */
/*
 * Copyright (c) 1995 Patrick Powell.
 *
 * This code is based on code written by Patrick Powell <papowell@astart.com>.
 * It may be used for any purpose as long as this notice remains intact on all
 * source code distributions.
 */

/*
 * Copyright (c) 2008 Holger Weiss.
 *
 * This version of the code is maintained by Holger Weiss <holger@jhweiss.de>.
 * My changes to the code may freely be used, modified and/or redistributed for
 * any purpose.  It would be nice if additions and fixes to this file (including
 * trivial code cleanups) would be sent back in order to let me include them in
 * the version available at <http://www.jhweiss.de/software/snprintf.html>.
 * However, this is not a requirement for using or redistributing (possibly
 * modified) versions of this file, nor is leaving this notice intact mandatory.
 */

/*
 * History
 *
 * 2008-01-20 Holger Weiss <holger@jhweiss.de> for C99-snprintf 1.1:
 *
 *  Fixed the detection of infinite floating point values on IRIX (and
 *  possibly other systems) and applied another few minor cleanups.
 *
 * 2008-01-06 Holger Weiss <holger@jhweiss.de> for C99-snprintf 1.0:
 *
 *  Added a lot of new features, fixed many bugs, and incorporated various
 *  improvements done by Andrew Tridgell <tridge@samba.org>, Russ Allbery
 *  <rra@stanford.edu>, Hrvoje Niksic <hniksic@xemacs.org>, Damien Miller
 *  <djm@mindrot.org>, and others for the Samba, INN, Wget, and OpenSSH
 *  projects.  The additions include: support the "e", "E", "g", "G", and
 *  "F" conversion specifiers (and use conversion style "f" or "F" for the
 *  still unsupported "a" and "A" specifiers); support the "hh", "ll", "j",
 *  "t", and "z" length modifiers; support the "#" flag and the (non-C99)
 *  "'" flag; use localeconv(3) (if available) to get both the current
 *  locale's decimal point character and the separator between groups of
 *  digits; fix the handling of various corner cases of field width and
 *  precision specifications; fix various floating point conversion bugs;
 *  handle infinite and NaN floating point values; don't attempt to write to
 *  the output buffer (which may be NULL) if a size of zero was specified;
 *  check for integer overflow of the field width, precision, and return
 *  values and during the floating point conversion; use the OUTCHAR() macro
 *  instead of a function for better performance; provide asprintf(3) and
 *  vasprintf(3) functions; add new test cases.  The replacement functions
 *  have been renamed to use an "rpl_" prefix, the function calls in the
 *  main project (and in this file) must be redefined accordingly for each
 *  replacement function which is needed (by using Autoconf or other means).
 *  Various other minor improvements have been applied and the coding style
 *  was cleaned up for consistency.
 *
 * 2007-07-23 Holger Weiss <holger@jhweiss.de> for Mutt 1.5.13:
 *
 *  C99 compliant snprintf(3) and vsnprintf(3) functions return the number
 *  of characters that would have been written to a sufficiently sized
 *  buffer (excluding the '\0').  The original code simply returned the
 *  length of the resulting output string, so that's been fixed.
 *
 * 1998-03-05 Michael Elkins <me@mutt.org> for Mutt 0.90.8:
 *
 *  The original code assumed that both snprintf(3) and vsnprintf(3) were
 *  missing.  Some systems only have snprintf(3) but not vsnprintf(3), so
 *  the code is now broken down under HAVE_SNPRINTF and HAVE_VSNPRINTF.
 *
 * 1998-01-27 Thomas Roessler <roessler@does-not-exist.org> for Mutt 0.89i:
 *
 *  The PGP code was using unsigned hexadecimal formats.  Unfortunately,
 *  unsigned formats simply didn't work.
 *
 * 1997-10-22 Brandon Long <blong@fiction.net> for Mutt 0.87.1:
 *
 *  Ok, added some minimal floating point support, which means this probably
 *  requires libm on most operating systems.  Don't yet support the exponent
 *  (e,E) and sigfig (g,G).  Also, fmtint() was pretty badly broken, it just
 *  wasn't being exercised in ways which showed it, so that's been fixed.
 *  Also, formatted the code to Mutt conventions, and removed dead code left
 *  over from the original.  Also, there is now a builtin-test, run with:
 *  gcc -DTEST_SNPRINTF -o snprintf snprintf.c -lm && ./snprintf
 *
 * 2996-09-15 Brandon Long <blong@fiction.net> for Mutt 0.43:
 *
 *  This was ugly.  It is still ugly.  I opted out of floating point
 *  numbers, but the formatter understands just about everything from the
 *  normal C string format, at least as far as I can tell from the Solaris
 *  2.5 printf(3S) man page.
 */

/*
 * ToDo
 *
 * - Add wide character support.
 * - Add support for "%a" and "%A" conversions.
 * - Create test routines which predefine the expected results.  Our test cases
 *   usually expose bugs in system implementations rather than in ours :-)
 */

/*
 * Usage
 *
 * 1) The following preprocessor macros should be defined to 1 if the feature or
 *    file in question is available on the target system (by using Autoconf or
 *    other means), though basic functionality should be available as long as
 *    HAVE_STDARG_H and HAVE_STDLIB_H are defined correctly:
 *
 *      HAVE_VSNPRINTF
 *      HAVE_SNPRINTF
 *      HAVE_VASPRINTF
 *      HAVE_ASPRINTF
 *      HAVE_STDARG_H
 *      HAVE_STDDEF_H
 *      HAVE_STDINT_H
 *      HAVE_STDLIB_H
 *      HAVE_INTTYPES_H
 *      HAVE_LOCALE_H
 *      HAVE_LOCALECONV
 *      HAVE_LCONV_DECIMAL_POINT
 *      HAVE_LCONV_THOUSANDS_SEP
 *      HAVE_LONG_DOUBLE
 *      HAVE_LONG_LONG_INT
 *      HAVE_UNSIGNED_LONG_LONG_INT
 *      HAVE_INTMAX_T
 *      HAVE_UINTMAX_T
 *      HAVE_UINTPTR_T
 *      HAVE_PTRDIFF_T
 *      HAVE_VA_COPY
 *      HAVE___VA_COPY
 *
 * 2) The calls to the functions which should be replaced must be redefined
 *    throughout the project files (by using Autoconf or other means):
 *
 *      #define vsnprintf rpl_vsnprintf
 *      #define snprintf rpl_snprintf
 *      #define vasprintf rpl_vasprintf
 *      #define asprintf rpl_asprintf
 *
 * 3) The required replacement functions should be declared in some header file
 *    included throughout the project files:
 *
 *      #if HAVE_CONFIG_H
 *      #include <config.h>
 *      #endif
 *      #if HAVE_STDARG_H
 *      #include <stdarg.h>
 *      #if !HAVE_VSNPRINTF
 *      int rpl_vsnprintf(char *, size_t, const char *, va_list);
 *      #endif
 *      #if !HAVE_SNPRINTF
 *      int rpl_snprintf(char *, size_t, const char *, ...);
 *      #endif
 *      #if !HAVE_VASPRINTF
 *      int rpl_vasprintf(char **, const char *, va_list);
 *      #endif
 *      #if !HAVE_ASPRINTF
 *      int rpl_asprintf(char **, const char *, ...);
 *      #endif
 *      #endif
 *
 * Autoconf macros for handling step 1 and step 2 are available at
 * <http://www.jhweiss.de/software/snprintf.html>.
 */

#if !HAVE_SNPRINTF || !HAVE_VSNPRINTF || !HAVE_ASPRINTF || !HAVE_VASPRINTF
#include <stdio.h>  /* For NULL, size_t, vsnprintf(3), and vasprintf(3). */
#ifdef VA_START
#undef VA_START
#endif  /* defined(VA_START) */
#ifdef VA_SHIFT
#undef VA_SHIFT
#endif  /* defined(VA_SHIFT) */
#if HAVE_STDARG_H
#include <stdarg.h>
#define VA_START(ap, last) va_start(ap, last)
#define VA_SHIFT(ap, value, type) /* No-op for ANSI C. */
#else   /* Assume <varargs.h> is available. */
#include <varargs.h>
#define VA_START(ap, last) va_start(ap) /* "last" is ignored. */
#define VA_SHIFT(ap, value, type) value = va_arg(ap, type)
#endif  /* HAVE_STDARG_H */

#if !HAVE_VASPRINTF
#if HAVE_STDLIB_H
#include <stdlib.h> /* For malloc(3). */
#endif  /* HAVE_STDLIB_H */
#ifdef VA_COPY
#undef VA_COPY
#endif  /* defined(VA_COPY) */
#ifdef VA_END_COPY
#undef VA_END_COPY
#endif  /* defined(VA_END_COPY) */
#if HAVE_VA_COPY
#define VA_COPY(dest, src) va_copy(dest, src)
#define VA_END_COPY(ap) va_end(ap)
#elif HAVE___VA_COPY
#define VA_COPY(dest, src) __va_copy(dest, src)
#define VA_END_COPY(ap) va_end(ap)
#else
#define VA_COPY(dest, src) (void)mymemcpy(&dest, &src, sizeof(va_list))
#define VA_END_COPY(ap) /* No-op. */
#define NEED_MYMEMCPY 1
static void *mymemcpy(void *, void *, size_t);
#endif  /* HAVE_VA_COPY */
#endif  /* !HAVE_VASPRINTF */

#if !HAVE_VSNPRINTF
#include <errno.h>  /* For ERANGE and errno. */
#include <limits.h> /* For *_MAX. */
#if HAVE_INTTYPES_H
#include <inttypes.h>   /* For intmax_t (if not defined in <stdint.h>). */
#endif  /* HAVE_INTTYPES_H */
#if HAVE_LOCALE_H
#include <locale.h> /* For localeconv(3). */
#endif  /* HAVE_LOCALE_H */
#if HAVE_STDDEF_H
#include <stddef.h> /* For ptrdiff_t. */
#endif  /* HAVE_STDDEF_H */
#if HAVE_STDINT_H
#include <stdint.h> /* For intmax_t. */
#endif  /* HAVE_STDINT_H */

/* Support for unsigned long long int.  We may also need ULLONG_MAX. */
#ifndef ULONG_MAX   /* We may need ULONG_MAX as a fallback. */
#ifdef UINT_MAX
#define ULONG_MAX UINT_MAX
#else
#define ULONG_MAX INT_MAX
#endif  /* defined(UINT_MAX) */
#endif  /* !defined(ULONG_MAX) */
#ifdef ULLONG
#undef ULLONG
#endif  /* defined(ULLONG) */
#if HAVE_UNSIGNED_LONG_LONG_INT
#define ULLONG unsigned long long int
#ifndef ULLONG_MAX
#define ULLONG_MAX ULONG_MAX
#endif  /* !defined(ULLONG_MAX) */
#else
#define ULLONG unsigned long int
#ifdef ULLONG_MAX
#undef ULLONG_MAX
#endif  /* defined(ULLONG_MAX) */
#define ULLONG_MAX ULONG_MAX
#endif  /* HAVE_LONG_LONG_INT */

/* Support for uintmax_t.  We also need UINTMAX_MAX. */
#ifdef UINTMAX_T
#undef UINTMAX_T
#endif  /* defined(UINTMAX_T) */
#if HAVE_UINTMAX_T || defined(uintmax_t)
#define UINTMAX_T uintmax_t
#ifndef UINTMAX_MAX
#define UINTMAX_MAX ULLONG_MAX
#endif  /* !defined(UINTMAX_MAX) */
#else
#define UINTMAX_T ULLONG
#ifdef UINTMAX_MAX
#undef UINTMAX_MAX
#endif  /* defined(UINTMAX_MAX) */
#define UINTMAX_MAX ULLONG_MAX
#endif  /* HAVE_UINTMAX_T || defined(uintmax_t) */

/* Support for long double. */
#ifndef LDOUBLE
#if HAVE_LONG_DOUBLE
#define LDOUBLE long double
#else
#define LDOUBLE double
#endif  /* HAVE_LONG_DOUBLE */
#endif  /* !defined(LDOUBLE) */

/* Support for long long int. */
#ifndef LLONG
#if HAVE_LONG_LONG_INT
#define LLONG long long int
#else
#define LLONG long int
#endif  /* HAVE_LONG_LONG_INT */
#endif  /* !defined(LLONG) */

/* Support for intmax_t. */
#ifndef INTMAX_T
#if HAVE_INTMAX_T || defined(intmax_t)
#define INTMAX_T intmax_t
#else
#define INTMAX_T LLONG
#endif  /* HAVE_INTMAX_T || defined(intmax_t) */
#endif  /* !defined(INTMAX_T) */

/* Support for uintptr_t. */
#ifndef UINTPTR_T
#if HAVE_UINTPTR_T || defined(uintptr_t)
#define UINTPTR_T uintptr_t
#else
#define UINTPTR_T unsigned long int
#endif  /* HAVE_UINTPTR_T || defined(uintptr_t) */
#endif  /* !defined(UINTPTR_T) */

/* Support for ptrdiff_t. */
#ifndef PTRDIFF_T
#if HAVE_PTRDIFF_T || defined(ptrdiff_t)
#define PTRDIFF_T ptrdiff_t
#else
#define PTRDIFF_T long int
#endif  /* HAVE_PTRDIFF_T || defined(ptrdiff_t) */
#endif  /* !defined(PTRDIFF_T) */

/*
 * We need an unsigned integer type corresponding to ptrdiff_t (cf. C99:
 * 7.19.6.1, 7).  However, we'll simply use PTRDIFF_T and convert it to an
 * unsigned type if necessary.  This should work just fine in practice.
 */
#ifndef UPTRDIFF_T
#define UPTRDIFF_T PTRDIFF_T
#endif  /* !defined(UPTRDIFF_T) */

/*
 * We need a signed integer type corresponding to size_t (cf. C99: 7.19.6.1, 7).
 * However, we'll simply use size_t and convert it to a signed type if
 * necessary.  This should work just fine in practice.
 */
#ifndef SSIZE_T
#define SSIZE_T size_t
#endif  /* !defined(SSIZE_T) */

/* Either ERANGE or E2BIG should be available everywhere. */
#ifndef ERANGE
#define ERANGE E2BIG
#endif  /* !defined(ERANGE) */
#ifndef EOVERFLOW
#define EOVERFLOW ERANGE
#endif  /* !defined(EOVERFLOW) */

/*
 * Buffer size to hold the octal string representation of UINT128_MAX without
 * nul-termination ("3777777777777777777777777777777777777777777").
 */
#ifdef MAX_CONVERT_LENGTH
#undef MAX_CONVERT_LENGTH
#endif  /* defined(MAX_CONVERT_LENGTH) */
#define MAX_CONVERT_LENGTH      43

/* Format read states. */
#define PRINT_S_DEFAULT         0
#define PRINT_S_FLAGS           1
#define PRINT_S_WIDTH           2
#define PRINT_S_DOT             3
#define PRINT_S_PRECISION       4
#define PRINT_S_MOD             5
#define PRINT_S_CONV            6

/* Format flags. */
#define PRINT_F_MINUS           (1 << 0)
#define PRINT_F_PLUS            (1 << 1)
#define PRINT_F_SPACE           (1 << 2)
#define PRINT_F_NUM             (1 << 3)
#define PRINT_F_ZERO            (1 << 4)
#define PRINT_F_QUOTE           (1 << 5)
#define PRINT_F_UP              (1 << 6)
#define PRINT_F_UNSIGNED        (1 << 7)
#define PRINT_F_TYPE_G          (1 << 8)
#define PRINT_F_TYPE_E          (1 << 9)

/* Conversion flags. */
#define PRINT_C_CHAR            1
#define PRINT_C_SHORT           2
#define PRINT_C_LONG            3
#define PRINT_C_LLONG           4
#define PRINT_C_LDOUBLE         5
#define PRINT_C_SIZE            6
#define PRINT_C_PTRDIFF         7
#define PRINT_C_INTMAX          8

#ifndef MAX
#define MAX(x, y) ((x >= y) ? x : y)
#endif  /* !defined(MAX) */
#ifndef CHARTOINT
#define CHARTOINT(ch) (ch - '0')
#endif  /* !defined(CHARTOINT) */
#ifndef ISDIGIT
#define ISDIGIT(ch) ('0' <= (unsigned char)ch && (unsigned char)ch <= '9')
#endif  /* !defined(ISDIGIT) */
#ifndef ISNAN
#define ISNAN(x) (x != x)
#endif  /* !defined(ISNAN) */
#ifndef ISINF
#define ISINF(x) (x != 0.0 && x + x == x)
#endif  /* !defined(ISINF) */

#ifdef OUTCHAR
#undef OUTCHAR
#endif  /* defined(OUTCHAR) */
#define OUTCHAR(str, len, size, ch)                                          \
do {                                                                         \
    if (len + 1 < size)                                                  \
        str[len] = ch;                                               \
    (len)++;                                                             \
} while (/* CONSTCOND */ 0)

static void fmtstr(char *, size_t *, size_t, const char *, int, int, int);
static void fmtint(char *, size_t *, size_t, INTMAX_T, int, int, int, int);
static void fmtflt(char *, size_t *, size_t, LDOUBLE, int, int, int, int *);
static void printsep(char *, size_t *, size_t);
static int getnumsep(int);
static int getexponent(LDOUBLE);
static int convert(UINTMAX_T, char *, size_t, int, int);
static UINTMAX_T cast(LDOUBLE);
static UINTMAX_T myround(LDOUBLE);
static LDOUBLE mypow10(int);

int
rpl_vsnprintf(char *str, size_t size, const char *format, va_list args)
{
    LDOUBLE fvalue;
    INTMAX_T value;
    unsigned char cvalue;
    const char *strvalue;
    INTMAX_T *intmaxptr;
    PTRDIFF_T *ptrdiffptr;
    SSIZE_T *sizeptr;
    LLONG *llongptr;
    long int *longptr;
    int *intptr;
    short int *shortptr;
    signed char *charptr;
    size_t len = 0;
    int overflow = 0;
    int base = 0;
    int cflags = 0;
    int flags = 0;
    int width = 0;
    int precision = -1;
    int state = PRINT_S_DEFAULT;
    char ch = *format++;

    /*
     * C99 says: "If `n' is zero, nothing is written, and `s' may be a null
     * pointer." (7.19.6.5, 2)  We're forgiving and allow a NULL pointer
     * even if a size larger than zero was specified.  At least NetBSD's
     * snprintf(3) does the same, as well as other versions of this file.
     * (Though some of these versions will write to a non-NULL buffer even
     * if a size of zero was specified, which violates the standard.)
     */
    if (str == NULL && size != 0)
        size = 0;

    while (ch != '\0')
        switch (state) {
        case PRINT_S_DEFAULT:
            if (ch == '%')
                state = PRINT_S_FLAGS;
            else
                OUTCHAR(str, len, size, ch);
            ch = *format++;
            break;
        case PRINT_S_FLAGS:
            switch (ch) {
            case '-':
                flags |= PRINT_F_MINUS;
                ch = *format++;
                break;
            case '+':
                flags |= PRINT_F_PLUS;
                ch = *format++;
                break;
            case ' ':
                flags |= PRINT_F_SPACE;
                ch = *format++;
                break;
            case '#':
                flags |= PRINT_F_NUM;
                ch = *format++;
                break;
            case '0':
                flags |= PRINT_F_ZERO;
                ch = *format++;
                break;
            case '\'':  /* SUSv2 flag (not in C99). */
                flags |= PRINT_F_QUOTE;
                ch = *format++;
                break;
            default:
                state = PRINT_S_WIDTH;
                break;
            }
            break;
        case PRINT_S_WIDTH:
            if (ISDIGIT(ch)) {
                ch = CHARTOINT(ch);
                if (width > (INT_MAX - ch) / 10) {
                    overflow = 1;
                    goto out;
                }
                width = 10 * width + ch;
                ch = *format++;
            } else if (ch == '*') {
                /*
                 * C99 says: "A negative field width argument is
                 * taken as a `-' flag followed by a positive
                 * field width." (7.19.6.1, 5)
                 */
                if ((width = va_arg(args, int)) < 0) {
                    flags |= PRINT_F_MINUS;
                    width = -width;
                }
                ch = *format++;
                state = PRINT_S_DOT;
            } else
                state = PRINT_S_DOT;
            break;
        case PRINT_S_DOT:
            if (ch == '.') {
                state = PRINT_S_PRECISION;
                ch = *format++;
            } else
                state = PRINT_S_MOD;
            break;
        case PRINT_S_PRECISION:
            if (precision == -1)
                precision = 0;
            if (ISDIGIT(ch)) {
                ch = CHARTOINT(ch);
                if (precision > (INT_MAX - ch) / 10) {
                    overflow = 1;
                    goto out;
                }
                precision = 10 * precision + ch;
                ch = *format++;
            } else if (ch == '*') {
                /*
                 * C99 says: "A negative precision argument is
                 * taken as if the precision were omitted."
                 * (7.19.6.1, 5)
                 */
                if ((precision = va_arg(args, int)) < 0)
                    precision = -1;
                ch = *format++;
                state = PRINT_S_MOD;
            } else
                state = PRINT_S_MOD;
            break;
        case PRINT_S_MOD:
            switch (ch) {
            case 'h':
                ch = *format++;
                if (ch == 'h') {    /* It's a char. */
                    ch = *format++;
                    cflags = PRINT_C_CHAR;
                } else
                    cflags = PRINT_C_SHORT;
                break;
            case 'l':
                ch = *format++;
                if (ch == 'l') {    /* It's a long long. */
                    ch = *format++;
                    cflags = PRINT_C_LLONG;
                } else
                    cflags = PRINT_C_LONG;
                break;
            case 'L':
                cflags = PRINT_C_LDOUBLE;
                ch = *format++;
                break;
            case 'j':
                cflags = PRINT_C_INTMAX;
                ch = *format++;
                break;
            case 't':
                cflags = PRINT_C_PTRDIFF;
                ch = *format++;
                break;
            case 'z':
                cflags = PRINT_C_SIZE;
                ch = *format++;
                break;
            }
            state = PRINT_S_CONV;
            break;
        case PRINT_S_CONV:
            switch (ch) {
            case 'd':
                /* FALLTHROUGH */
            case 'i':
                switch (cflags) {
                case PRINT_C_CHAR:
                    value = (signed char)va_arg(args, int);
                    break;
                case PRINT_C_SHORT:
                    value = (short int)va_arg(args, int);
                    break;
                case PRINT_C_LONG:
                    value = va_arg(args, long int);
                    break;
                case PRINT_C_LLONG:
                    value = va_arg(args, LLONG);
                    break;
                case PRINT_C_SIZE:
                    value = va_arg(args, SSIZE_T);
                    break;
                case PRINT_C_INTMAX:
                    value = va_arg(args, INTMAX_T);
                    break;
                case PRINT_C_PTRDIFF:
                    value = va_arg(args, PTRDIFF_T);
                    break;
                default:
                    value = va_arg(args, int);
                    break;
                }
                fmtint(str, &len, size, value, 10, width,
                    precision, flags);
                break;
            case 'X':
                flags |= PRINT_F_UP;
                /* FALLTHROUGH */
            case 'x':
                base = 16;
                /* FALLTHROUGH */
            case 'o':
                if (base == 0)
                    base = 8;
                /* FALLTHROUGH */
            case 'u':
                if (base == 0)
                    base = 10;
                flags |= PRINT_F_UNSIGNED;
                switch (cflags) {
                case PRINT_C_CHAR:
                    value = (unsigned char)va_arg(args,
                        unsigned int);
                    break;
                case PRINT_C_SHORT:
                    value = (unsigned short int)va_arg(args,
                        unsigned int);
                    break;
                case PRINT_C_LONG:
                    value = va_arg(args, unsigned long int);
                    break;
                case PRINT_C_LLONG:
                    value = va_arg(args, ULLONG);
                    break;
                case PRINT_C_SIZE:
                    value = va_arg(args, size_t);
                    break;
                case PRINT_C_INTMAX:
                    value = va_arg(args, UINTMAX_T);
                    break;
                case PRINT_C_PTRDIFF:
                    value = va_arg(args, UPTRDIFF_T);
                    break;
                default:
                    value = va_arg(args, unsigned int);
                    break;
                }
                fmtint(str, &len, size, value, base, width,
                    precision, flags);
                break;
            case 'A':
                /* Not yet supported, we'll use "%F". */
                /* FALLTHROUGH */
            case 'F':
                flags |= PRINT_F_UP;
            case 'a':
                /* Not yet supported, we'll use "%f". */
                /* FALLTHROUGH */
            case 'f':
                if (cflags == PRINT_C_LDOUBLE)
                    fvalue = va_arg(args, LDOUBLE);
                else
                    fvalue = va_arg(args, double);
                fmtflt(str, &len, size, fvalue, width,
                    precision, flags, &overflow);
                if (overflow)
                    goto out;
                break;
            case 'E':
                flags |= PRINT_F_UP;
                /* FALLTHROUGH */
            case 'e':
                flags |= PRINT_F_TYPE_E;
                if (cflags == PRINT_C_LDOUBLE)
                    fvalue = va_arg(args, LDOUBLE);
                else
                    fvalue = va_arg(args, double);
                fmtflt(str, &len, size, fvalue, width,
                    precision, flags, &overflow);
                if (overflow)
                    goto out;
                break;
            case 'G':
                flags |= PRINT_F_UP;
                /* FALLTHROUGH */
            case 'g':
                flags |= PRINT_F_TYPE_G;
                if (cflags == PRINT_C_LDOUBLE)
                    fvalue = va_arg(args, LDOUBLE);
                else
                    fvalue = va_arg(args, double);
                /*
                 * If the precision is zero, it is treated as
                 * one (cf. C99: 7.19.6.1, 8).
                 */
                if (precision == 0)
                    precision = 1;
                fmtflt(str, &len, size, fvalue, width,
                    precision, flags, &overflow);
                if (overflow)
                    goto out;
                break;
            case 'c':
                cvalue = va_arg(args, int);
                OUTCHAR(str, len, size, cvalue);
                break;
            case 's':
                strvalue = va_arg(args, char *);
                fmtstr(str, &len, size, strvalue, width,
                    precision, flags);
                break;
            case 'p':
                /*
                 * C99 says: "The value of the pointer is
                 * converted to a sequence of printing
                 * characters, in an implementation-defined
                 * manner." (C99: 7.19.6.1, 8)
                 */
                if ((strvalue = (const char*)va_arg(args, void *)) == NULL)
                    /*
                     * We use the glibc format.  BSD prints
                     * "0x0", SysV "0".
                     */
                    fmtstr(str, &len, size, "(nil)", width,
                        -1, flags);
                else {
                    /*
                     * We use the BSD/glibc format.  SysV
                     * omits the "0x" prefix (which we emit
                     * using the PRINT_F_NUM flag).
                     */
                    flags |= PRINT_F_NUM;
                    flags |= PRINT_F_UNSIGNED;
                    fmtint(str, &len, size,
                        (UINTPTR_T)strvalue, 16, width,
                        precision, flags);
                }
                break;
            case 'n':
                switch (cflags) {
                case PRINT_C_CHAR:
                    charptr = va_arg(args, signed char *);
                    *charptr = len;
                    break;
                case PRINT_C_SHORT:
                    shortptr = va_arg(args, short int *);
                    *shortptr = len;
                    break;
                case PRINT_C_LONG:
                    longptr = va_arg(args, long int *);
                    *longptr = len;
                    break;
                case PRINT_C_LLONG:
                    llongptr = va_arg(args, LLONG *);
                    *llongptr = len;
                    break;
                case PRINT_C_SIZE:
                    /*
                     * C99 says that with the "z" length
                     * modifier, "a following `n' conversion
                     * specifier applies to a pointer to a
                     * signed integer type corresponding to
                     * size_t argument." (7.19.6.1, 7)
                     */
                    sizeptr = va_arg(args, SSIZE_T *);
                    *sizeptr = len;
                    break;
                case PRINT_C_INTMAX:
                    intmaxptr = va_arg(args, INTMAX_T *);
                    *intmaxptr = len;
                    break;
                case PRINT_C_PTRDIFF:
                    ptrdiffptr = va_arg(args, PTRDIFF_T *);
                    *ptrdiffptr = len;
                    break;
                default:
                    intptr = va_arg(args, int *);
                    *intptr = len;
                    break;
                }
                break;
            case '%':   /* Print a "%" character verbatim. */
                OUTCHAR(str, len, size, ch);
                break;
            default:    /* Skip other characters. */
                break;
            }
            ch = *format++;
            state = PRINT_S_DEFAULT;
            base = cflags = flags = width = 0;
            precision = -1;
            break;
        }
out:
    if (len < size)
        str[len] = '\0';
    else if (size > 0)
        str[size - 1] = '\0';

    if (overflow || len >= INT_MAX) {
        errno = overflow ? EOVERFLOW : ERANGE;
        return -1;
    }
    return (int)len;
}

static void
fmtstr(char *str, size_t *len, size_t size, const char *value, int width,
       int precision, int flags)
{
    int padlen, strln;  /* Amount to pad. */
    int noprecision = (precision == -1);

    if (value == NULL)  /* We're forgiving. */
        value = "(null)";

    /* If a precision was specified, don't read the string past it. */
    for (strln = 0; value[strln] != '\0' &&
        (noprecision || strln < precision); strln++)
        continue;

    if ((padlen = width - strln) < 0)
        padlen = 0;
    if (flags & PRINT_F_MINUS)  /* Left justify. */
        padlen = -padlen;

    while (padlen > 0) {    /* Leading spaces. */
        OUTCHAR(str, *len, size, ' ');
        padlen--;
    }
    while (*value != '\0' && (noprecision || precision-- > 0)) {
        OUTCHAR(str, *len, size, *value);
        value++;
    }
    while (padlen < 0) {    /* Trailing spaces. */
        OUTCHAR(str, *len, size, ' ');
        padlen++;
    }
}

static void
fmtint(char *str, size_t *len, size_t size, INTMAX_T value, int base, int width,
       int precision, int flags)
{
    UINTMAX_T uvalue;
    char iconvert[MAX_CONVERT_LENGTH];
    char sign = 0;
    char hexprefix = 0;
    int spadlen = 0;    /* Amount to space pad. */
    int zpadlen = 0;    /* Amount to zero pad. */
    int pos;
    int separators = (flags & PRINT_F_QUOTE);
    int noprecision = (precision == -1);

    if (flags & PRINT_F_UNSIGNED)
        uvalue = value;
    else {
        uvalue = (value >= 0) ? value : -value;
        if (value < 0)
            sign = '-';
        else if (flags & PRINT_F_PLUS)  /* Do a sign. */
            sign = '+';
        else if (flags & PRINT_F_SPACE)
            sign = ' ';
    }

    pos = convert(uvalue, iconvert, sizeof(iconvert), base,
        flags & PRINT_F_UP);

    if (flags & PRINT_F_NUM && uvalue != 0) {
        /*
         * C99 says: "The result is converted to an `alternative form'.
         * For `o' conversion, it increases the precision, if and only
         * if necessary, to force the first digit of the result to be a
         * zero (if the value and precision are both 0, a single 0 is
         * printed).  For `x' (or `X') conversion, a nonzero result has
         * `0x' (or `0X') prefixed to it." (7.19.6.1, 6)
         */
        switch (base) {
        case 8:
            if (precision <= pos)
                precision = pos + 1;
            break;
        case 16:
            hexprefix = (flags & PRINT_F_UP) ? 'X' : 'x';
            break;
        }
    }

    if (separators) /* Get the number of group separators we'll print. */
        separators = getnumsep(pos);

    zpadlen = precision - pos - separators;
    spadlen = width                         /* Minimum field width. */
        - separators                        /* Number of separators. */
        - MAX(precision, pos)               /* Number of integer digits. */
        - ((sign != 0) ? 1 : 0)             /* Will we print a sign? */
        - ((hexprefix != 0) ? 2 : 0);       /* Will we print a prefix? */

    if (zpadlen < 0)
        zpadlen = 0;
    if (spadlen < 0)
        spadlen = 0;

    /*
     * C99 says: "If the `0' and `-' flags both appear, the `0' flag is
     * ignored.  For `d', `i', `o', `u', `x', and `X' conversions, if a
     * precision is specified, the `0' flag is ignored." (7.19.6.1, 6)
     */
    if (flags & PRINT_F_MINUS)  /* Left justify. */
        spadlen = -spadlen;
    else if (flags & PRINT_F_ZERO && noprecision) {
        zpadlen += spadlen;
        spadlen = 0;
    }
    while (spadlen > 0) {   /* Leading spaces. */
        OUTCHAR(str, *len, size, ' ');
        spadlen--;
    }
    if (sign != 0)  /* Sign. */
        OUTCHAR(str, *len, size, sign);
    if (hexprefix != 0) {   /* A "0x" or "0X" prefix. */
        OUTCHAR(str, *len, size, '0');
        OUTCHAR(str, *len, size, hexprefix);
    }
    while (zpadlen > 0) {   /* Leading zeros. */
        OUTCHAR(str, *len, size, '0');
        zpadlen--;
    }
    while (pos > 0) {   /* The actual digits. */
        pos--;
        OUTCHAR(str, *len, size, iconvert[pos]);
        if (separators > 0 && pos > 0 && pos % 3 == 0)
            printsep(str, len, size);
    }
    while (spadlen < 0) {   /* Trailing spaces. */
        OUTCHAR(str, *len, size, ' ');
        spadlen++;
    }
}

static void
fmtflt(char *str, size_t *len, size_t size, LDOUBLE fvalue, int width,
       int precision, int flags, int *overflow)
{
    LDOUBLE ufvalue;
    UINTMAX_T intpart;
    UINTMAX_T fracpart;
    UINTMAX_T mask;
    const char *infnan = NULL;
    char iconvert[MAX_CONVERT_LENGTH];
    char fconvert[MAX_CONVERT_LENGTH];
    char econvert[4];   /* "e-12" (without nul-termination). */
    char esign = 0;
    char sign = 0;
    int leadfraczeros = 0;
    int exponent = 0;
    int emitpoint = 0;
    int omitzeros = 0;
    int omitcount = 0;
    int padlen = 0;
    int epos = 0;
    int fpos = 0;
    int ipos = 0;
    int separators = (flags & PRINT_F_QUOTE);
    int estyle = (flags & PRINT_F_TYPE_E);
#if HAVE_LOCALECONV && HAVE_LCONV_DECIMAL_POINT
    struct lconv *lc = localeconv();
#endif  /* HAVE_LOCALECONV && HAVE_LCONV_DECIMAL_POINT */

    /*
     * AIX' man page says the default is 0, but C99 and at least Solaris'
     * and NetBSD's man pages say the default is 6, and sprintf(3) on AIX
     * defaults to 6.
     */
    if (precision == -1)
        precision = 6;

    if (fvalue < 0.0)
        sign = '-';
    else if (flags & PRINT_F_PLUS)  /* Do a sign. */
        sign = '+';
    else if (flags & PRINT_F_SPACE)
        sign = ' ';

    if (ISNAN(fvalue))
        infnan = (flags & PRINT_F_UP) ? "NAN" : "nan";
    else if (ISINF(fvalue))
        infnan = (flags & PRINT_F_UP) ? "INF" : "inf";

    if (infnan != NULL) {
        if (sign != 0)
            iconvert[ipos++] = sign;
        while (*infnan != '\0')
            iconvert[ipos++] = *infnan++;
        fmtstr(str, len, size, iconvert, width, ipos, flags);
        return;
    }

    /* "%e" (or "%E") or "%g" (or "%G") conversion. */
    if (flags & PRINT_F_TYPE_E || flags & PRINT_F_TYPE_G) {
        if (flags & PRINT_F_TYPE_G) {
            /*
             * For "%g" (and "%G") conversions, the precision
             * specifies the number of significant digits, which
             * includes the digits in the integer part.  The
             * conversion will or will not be using "e-style" (like
             * "%e" or "%E" conversions) depending on the precision
             * and on the exponent.  However, the exponent can be
             * affected by rounding the converted value, so we'll
             * leave this decision for later.  Until then, we'll
             * assume that we're going to do an "e-style" conversion
             * (in order to get the exponent calculated).  For
             * "e-style", the precision must be decremented by one.
             */
            precision--;
            /*
             * For "%g" (and "%G") conversions, trailing zeros are
             * removed from the fractional portion of the result
             * unless the "#" flag was specified.
             */
            if (!(flags & PRINT_F_NUM))
                omitzeros = 1;
        }
        exponent = getexponent(fvalue);
        estyle = 1;
    }

again:
    /*
     * Sorry, we only support 9, 19, or 38 digits (that is, the number of
     * digits of the 32-bit, the 64-bit, or the 128-bit UINTMAX_MAX value
     * minus one) past the decimal point due to our conversion method.
     */
    switch (sizeof(UINTMAX_T)) {
    case 16:
        if (precision > 38)
            precision = 38;
        break;
    case 8:
        if (precision > 19)
            precision = 19;
        break;
    default:
        if (precision > 9)
            precision = 9;
        break;
    }

    ufvalue = (fvalue >= 0.0) ? fvalue : -fvalue;
    if (estyle) /* We want exactly one integer digit. */
        ufvalue /= mypow10(exponent);

    if ((intpart = cast(ufvalue)) == UINTMAX_MAX) {
        *overflow = 1;
        return;
    }

    /*
     * Factor of ten with the number of digits needed for the fractional
     * part.  For example, if the precision is 3, the mask will be 1000.
     */
    mask = mypow10(precision);
    /*
     * We "cheat" by converting the fractional part to integer by
     * multiplying by a factor of ten.
     */
    if ((fracpart = myround(mask * (ufvalue - intpart))) >= mask) {
        /*
         * For example, ufvalue = 2.99962, intpart = 2, and mask = 1000
         * (because precision = 3).  Now, myround(1000 * 0.99962) will
         * return 1000.  So, the integer part must be incremented by one
         * and the fractional part must be set to zero.
         */
        intpart++;
        fracpart = 0;
        if (estyle && intpart == 10) {
            /*
             * The value was rounded up to ten, but we only want one
             * integer digit if using "e-style".  So, the integer
             * part must be set to one and the exponent must be
             * incremented by one.
             */
            intpart = 1;
            exponent++;
        }
    }

    /*
     * Now that we know the real exponent, we can check whether or not to
     * use "e-style" for "%g" (and "%G") conversions.  If we don't need
     * "e-style", the precision must be adjusted and the integer and
     * fractional parts must be recalculated from the original value.
     *
     * C99 says: "Let P equal the precision if nonzero, 6 if the precision
     * is omitted, or 1 if the precision is zero.  Then, if a conversion
     * with style `E' would have an exponent of X:
     *
     * - if P > X >= -4, the conversion is with style `f' (or `F') and
     *   precision P - (X + 1).
     *
     * - otherwise, the conversion is with style `e' (or `E') and precision
     *   P - 1." (7.19.6.1, 8)
     *
     * Note that we had decremented the precision by one.
     */
    if (flags & PRINT_F_TYPE_G && estyle &&
        precision + 1 > exponent && exponent >= -4) {
        precision -= exponent;
        estyle = 0;
        goto again;
    }

    if (estyle) {
        if (exponent < 0) {
            exponent = -exponent;
            esign = '-';
        } else
            esign = '+';

        /*
         * Convert the exponent.  The sizeof(econvert) is 4.  So, the
         * econvert buffer can hold e.g. "e+99" and "e-99".  We don't
         * support an exponent which contains more than two digits.
         * Therefore, the following stores are safe.
         */
        epos = convert(exponent, econvert, 2, 10, 0);
        /*
         * C99 says: "The exponent always contains at least two digits,
         * and only as many more digits as necessary to represent the
         * exponent." (7.19.6.1, 8)
         */
        if (epos == 1)
            econvert[epos++] = '0';
        econvert[epos++] = esign;
        econvert[epos++] = (flags & PRINT_F_UP) ? 'E' : 'e';
    }

    /* Convert the integer part and the fractional part. */
    ipos = convert(intpart, iconvert, sizeof(iconvert), 10, 0);
    if (fracpart != 0)  /* convert() would return 1 if fracpart == 0. */
        fpos = convert(fracpart, fconvert, sizeof(fconvert), 10, 0);

    leadfraczeros = precision - fpos;

    if (omitzeros) {
        if (fpos > 0)   /* Omit trailing fractional part zeros. */
            while (omitcount < fpos && fconvert[omitcount] == '0')
                omitcount++;
        else {  /* The fractional part is zero, omit it completely. */
            omitcount = precision;
            leadfraczeros = 0;
        }
        precision -= omitcount;
    }

    /*
     * Print a decimal point if either the fractional part is non-zero
     * and/or the "#" flag was specified.
     */
    if (precision > 0 || flags & PRINT_F_NUM)
        emitpoint = 1;
    if (separators) /* Get the number of group separators we'll print. */
        separators = getnumsep(ipos);

    padlen = width                  /* Minimum field width. */
        - ipos                      /* Number of integer digits. */
        - epos                      /* Number of exponent characters. */
        - precision                 /* Number of fractional digits. */
        - separators                /* Number of group separators. */
        - (emitpoint ? 1 : 0)       /* Will we print a decimal point? */
        - ((sign != 0) ? 1 : 0);    /* Will we print a sign character? */

    if (padlen < 0)
        padlen = 0;

    /*
     * C99 says: "If the `0' and `-' flags both appear, the `0' flag is
     * ignored." (7.19.6.1, 6)
     */
    if (flags & PRINT_F_MINUS)  /* Left justifty. */
        padlen = -padlen;
    else if (flags & PRINT_F_ZERO && padlen > 0) {
        if (sign != 0) {    /* Sign. */
            OUTCHAR(str, *len, size, sign);
            sign = 0;
        }
        while (padlen > 0) {    /* Leading zeros. */
            OUTCHAR(str, *len, size, '0');
            padlen--;
        }
    }
    while (padlen > 0) {    /* Leading spaces. */
        OUTCHAR(str, *len, size, ' ');
        padlen--;
    }
    if (sign != 0)  /* Sign. */
        OUTCHAR(str, *len, size, sign);
    while (ipos > 0) {  /* Integer part. */
        ipos--;
        OUTCHAR(str, *len, size, iconvert[ipos]);
        if (separators > 0 && ipos > 0 && ipos % 3 == 0)
            printsep(str, len, size);
    }
    if (emitpoint) {    /* Decimal point. */
#if HAVE_LOCALECONV && HAVE_LCONV_DECIMAL_POINT
        if (lc->decimal_point != NULL && *lc->decimal_point != '\0')
            OUTCHAR(str, *len, size, *lc->decimal_point);
        else    /* We'll always print some decimal point character. */
#endif  /* HAVE_LOCALECONV && HAVE_LCONV_DECIMAL_POINT */
            OUTCHAR(str, *len, size, '.');
    }
    while (leadfraczeros > 0) { /* Leading fractional part zeros. */
        OUTCHAR(str, *len, size, '0');
        leadfraczeros--;
    }
    while (fpos > omitcount) {  /* The remaining fractional part. */
        fpos--;
        OUTCHAR(str, *len, size, fconvert[fpos]);
    }
    while (epos > 0) {  /* Exponent. */
        epos--;
        OUTCHAR(str, *len, size, econvert[epos]);
    }
    while (padlen < 0) {    /* Trailing spaces. */
        OUTCHAR(str, *len, size, ' ');
        padlen++;
    }
}

static void
printsep(char *str, size_t *len, size_t size)
{
#if HAVE_LOCALECONV && HAVE_LCONV_THOUSANDS_SEP
    struct lconv *lc = localeconv();
    int i;

    if (lc->thousands_sep != NULL)
        for (i = 0; lc->thousands_sep[i] != '\0'; i++)
            OUTCHAR(str, *len, size, lc->thousands_sep[i]);
    else
#endif  /* HAVE_LOCALECONV && HAVE_LCONV_THOUSANDS_SEP */
        OUTCHAR(str, *len, size, ',');
}

static int
getnumsep(int digits)
{
    int separators = (digits - ((digits % 3 == 0) ? 1 : 0)) / 3;
#if HAVE_LOCALECONV && HAVE_LCONV_THOUSANDS_SEP
    int strln;
    struct lconv *lc = localeconv();

    /* We support an arbitrary separator length (including zero). */
    if (lc->thousands_sep != NULL) {
        for (strln = 0; lc->thousands_sep[strln] != '\0'; strln++)
            continue;
        separators *= strln;
    }
#endif  /* HAVE_LOCALECONV && HAVE_LCONV_THOUSANDS_SEP */
    return separators;
}

static int
getexponent(LDOUBLE value)
{
    LDOUBLE tmp = (value >= 0.0) ? value : -value;
    int exponent = 0;

    /*
     * We check for 99 > exponent > -99 in order to work around possible
     * endless loops which could happen (at least) in the second loop (at
     * least) if we're called with an infinite value.  However, we checked
     * for infinity before calling this function using our ISINF() macro, so
     * this might be somewhat paranoid.
     */
    while (tmp < 1.0 && tmp > 0.0 && --exponent > -99)
        tmp *= 10;
    while (tmp >= 10.0 && ++exponent < 99)
        tmp /= 10;

    return exponent;
}

static int
convert(UINTMAX_T value, char *buf, size_t size, int base, int caps)
{
    const char *digits = caps ? "0123456789ABCDEF" : "0123456789abcdef";
    size_t pos = 0;

    /* We return an unterminated buffer with the digits in reverse order. */
    do {
        buf[pos++] = digits[value % base];
        value /= base;
    } while (value != 0 && pos < size);

    return (int)pos;
}

static UINTMAX_T
cast(LDOUBLE value)
{
    UINTMAX_T result;

    /*
     * We check for ">=" and not for ">" because if UINTMAX_MAX cannot be
     * represented exactly as an LDOUBLE value (but is less than LDBL_MAX),
     * it may be increased to the nearest higher representable value for the
     * comparison (cf. C99: 6.3.1.4, 2).  It might then equal the LDOUBLE
     * value although converting the latter to UINTMAX_T would overflow.
     */
    if (value >= UINTMAX_MAX)
        return UINTMAX_MAX;

    result = value;
    /*
     * At least on NetBSD/sparc64 3.0.2 and 4.99.30, casting long double to
     * an integer type converts e.g. 1.9 to 2 instead of 1 (which violates
     * the standard).  Sigh.
     */
    return (result <= value) ? result : result - 1;
}

static UINTMAX_T
myround(LDOUBLE value)
{
    UINTMAX_T intpart = cast(value);

    return ((value -= intpart) < 0.5) ? intpart : intpart + 1;
}

static LDOUBLE
mypow10(int exponent)
{
    LDOUBLE result = 1;

    while (exponent > 0) {
        result *= 10;
        exponent--;
    }
    while (exponent < 0) {
        result /= 10;
        exponent++;
    }
    return result;
}
#endif  /* !HAVE_VSNPRINTF */

#if !HAVE_VASPRINTF
#if NEED_MYMEMCPY
static void *
mymemcpy(void *dst, void *src, size_t len)
{
    const char *from = (const char *)src;
    char *to = (char*)dst;

    /* No need for optimization, we use this only to replace va_copy(3). */
    while (len-- > 0)
        *to++ = *from++;
    return dst;
}
#endif  /* NEED_MYMEMCPY */

int
rpl_vasprintf(char **ret, const char *format, va_list ap)
{
    size_t size;
    int len;
    va_list aq;

    VA_COPY(aq, ap);
#if !HAVE_VSNPRINTF
    len = rpl_vsnprintf(NULL, 0, format, aq);
#else
    len = vsnprintf(NULL, 0, format, aq);
#endif
    VA_END_COPY(aq);
    if (len < 0 || (*ret = (char*)malloc(size = len + 1)) == NULL)
        return -1;
#if !HAVE_VSNPRINTF
    return rpl_vsnprintf(*ret, size, format, ap);
#else
    return vsnprintf(*ret, size, format, ap);
#endif
}
#endif  /* !HAVE_VASPRINTF */

#if !HAVE_SNPRINTF
#if HAVE_STDARG_H
int
rpl_snprintf(char *str, size_t size, const char *format, ...)
#else
int
rpl_snprintf(va_alist) va_dcl
#endif  /* HAVE_STDARG_H */
{
#if !HAVE_STDARG_H
    char *str;
    size_t size;
    char *format;
#endif  /* HAVE_STDARG_H */
    va_list ap;
    int len;

    VA_START(ap, format);
    VA_SHIFT(ap, str, char *);
    VA_SHIFT(ap, size, size_t);
    VA_SHIFT(ap, format, const char *);
#if !HAVE_VSNPRINTF
    len = rpl_vsnprintf(str, size, format, ap);
#else
    len = vsnprintf(str, size, format, ap);
#endif
    va_end(ap);
    return len;
}
#endif  /* !HAVE_SNPRINTF */

#if !HAVE_ASPRINTF
#if HAVE_STDARG_H
int
rpl_asprintf(char **ret, const char *format, ...)
#else
int
rpl_asprintf(va_alist) va_dcl
#endif  /* HAVE_STDARG_H */
{
#if !HAVE_STDARG_H
    char **ret;
    char *format;
#endif  /* HAVE_STDARG_H */
    va_list ap;
    int len;

    VA_START(ap, format);
    VA_SHIFT(ap, ret, char **);
    VA_SHIFT(ap, format, const char *);
#if !HAVE_VASPRINTF
    len = rpl_vasprintf(ret, format, ap);
#else
    len = vasprintf(ret, format, ap);
#endif
    va_end(ap);
    return len;
}
#endif  /* !HAVE_ASPRINTF */
#endif  /* !HAVE_SNPRINTF || !HAVE_VSNPRINTF || !HAVE_ASPRINTF || [...] */

static char* mat_strdup(const char *s)
{
    size_t len = strlen(s) + 1;
    char *d = (char*)malloc(len);
    return d ? (char*)memcpy(d, s, len) : NULL;
}

/* -------------------------------
 * ---------- mat.c
 * -------------------------------
 */
/** @file mat.c
 * Matlab MAT version 5 file functions
 * @ingroup MAT
 */

/* FIXME: Implement Unicode support */
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <time.h>

#ifndef MAT5_H
#define MAT5_H

static size_t GetStructFieldBufSize(matvar_t *matvar);
static size_t GetCellArrayFieldBufSize(matvar_t *matvar);
#if defined(HAVE_ZLIB)
static size_t GetMatrixMaxBufSize(matvar_t *matvar);
static size_t GetEmptyMatrixMaxBufSize(const char *name,int rank);
#endif
static size_t WriteCharData(mat_t *mat, void *data, int N,enum matio_types data_type);
static size_t WriteEmptyCharData(mat_t *mat, int N, enum matio_types data_type);
static size_t WriteEmptyData(mat_t *mat,int N,enum matio_types data_type);
static size_t ReadNextCell( mat_t *mat, matvar_t *matvar );
static size_t ReadNextStructField( mat_t *mat, matvar_t *matvar );
static size_t ReadNextFunctionHandle(mat_t *mat, matvar_t *matvar);
static int WriteCellArrayFieldInfo(mat_t *mat,matvar_t *matvar);
static int WriteCellArrayField(mat_t *mat,matvar_t *matvar );
static int WriteStructField(mat_t *mat,matvar_t *matvar);
static size_t Mat_WriteEmptyVariable5(mat_t *mat,const char *name,int rank,
                  size_t *dims);
#if defined(HAVE_ZLIB)
static size_t WriteCompressedCharData(mat_t *mat,z_streamp z,void *data,int N,
                  enum matio_types data_type);
#if 0
static size_t WriteCompressedEmptyData(mat_t *mat,z_streamp z,int N,
                  enum matio_types data_type);
#endif
static size_t WriteCompressedData(mat_t *mat,z_streamp z,void *data,int N,
                  enum matio_types data_type);
static size_t WriteCompressedCellArrayField(mat_t *mat,matvar_t *matvar,
                  z_streamp z);
static size_t WriteCompressedStructField(mat_t *mat,matvar_t *matvar,
                  z_streamp z);
static size_t Mat_WriteCompressedEmptyVariable5(mat_t *mat,const char *name,
                  int rank,size_t *dims,z_streamp z);
#endif

/*   mat5.c    */
static mat_t *Mat_Create5(const char *matname,const char *hdr_str);

static matvar_t *Mat_VarReadNextInfo5( mat_t *mat );
static void      Read5(mat_t *mat, matvar_t *matvar);
static int       ReadData5(mat_t *mat,matvar_t *matvar,void *data,
                     int *start,int *stride,int *edge);
static int       Mat_VarReadDataLinear5(mat_t *mat,matvar_t *matvar,void *data,
                     int start,int stride,int edge);
static int       Mat_VarWrite5(mat_t *mat,matvar_t *matvar,int compress);
static int       WriteCharDataSlab2(mat_t *mat,void *data,enum matio_types data_type,
                     size_t *dims,int *start,int *stride,int *edge);
static int       WriteData(mat_t *mat,void *data,int N,enum matio_types data_type);
static int       WriteDataSlab2(mat_t *mat,void *data,enum matio_types data_type,
                     size_t *dims,int *start,int *stride,int *edge);
static void      WriteInfo5(mat_t *mat, matvar_t *matvar);

#endif

#ifndef MAT4_H
#define MAT4_H

static mat_t    *Mat_Create4(const char* matname);
static int       Mat_VarWrite4(mat_t *mat,matvar_t *matvar);
static void      Read4(mat_t *mat, matvar_t *matvar);
static int       ReadData4(mat_t *mat,matvar_t *matvar,void *data,
                     int *start,int *stride,int *edge);
static int       Mat_VarReadDataLinear4(mat_t *mat,matvar_t *matvar,void *data,
                     int start,int stride,int edge);
static matvar_t *Mat_VarReadNextInfo4(mat_t *mat);

#endif
#if defined(HAVE_HDF5)
#ifndef MAT73_H
#define MAT73_H

static mat_t    *Mat_Create73(const char *matname,const char *hdr_str);
static void      Mat_VarRead73(mat_t *mat,matvar_t *matvar);
static int       Mat_VarReadData73(mat_t *mat,matvar_t *matvar,void *data,
                     int *start,int *stride,int *edge);
static int       Mat_VarReadDataLinear73(mat_t *mat,matvar_t *matvar,void *data,
                     int start,int stride,int edge);
static matvar_t *Mat_VarReadNextInfo73(mat_t *mat);
static int       Mat_VarWrite73(mat_t *mat,matvar_t *matvar,int compress);

#endif
#endif

#if HAVE_INTTYPES_H
#   include <inttypes.h>
#endif
#if defined(_WIN32)
#   include <io.h>
#   define mktemp _mktemp
#endif
#if defined(_MSC_VER) || defined(__MINGW32__)
#   define SIZE_T_FMTSTR "Iu"
#elif defined(__GNUC__) && __STDC_VERSION__ < 199901L
#   define SIZE_T_FMTSTR "lu"
#else
#   define SIZE_T_FMTSTR "zu"
#endif

static void
ReadData(mat_t *mat, matvar_t *matvar)
{
    if ( mat == NULL || matvar == NULL || mat->fp == NULL )
        return;
    else if ( mat->version == MAT_FT_MAT5 )
        Read5(mat,matvar);
#if defined(HAVE_HDF5)
    else if ( mat->version == MAT_FT_MAT73 )
        Mat_VarRead73(mat,matvar);
#endif
    else if ( mat->version == MAT_FT_MAT4 )
        Read4(mat,matvar);
    return;
}

static void
Mat_PrintNumber(enum matio_types type, void *data)
{
    switch ( type ) {
        case MAT_T_DOUBLE:
            printf("%g",*(double*)data);
            break;
        case MAT_T_SINGLE:
            printf("%g",*(float*)data);
            break;
#ifdef HAVE_MATIO_INT64_T
        case MAT_T_INT64:
#if HAVE_INTTYPES_H
            printf("%" PRIi64,*(mat_int64_t*)data);
#elif defined(_MSC_VER) && _MSC_VER >= 1200
            printf("%I64i",*(mat_int64_t*)data);
#elif defined(HAVE_LONG_LONG_INT)
            printf("%lld",(long long)(*(mat_int64_t*)data));
#else
            printf("%ld",(long)(*(mat_int64_t*)data));
#endif
            break;
#endif
#ifdef HAVE_MATIO_UINT64_T
        case MAT_T_UINT64:
#if HAVE_INTTYPES_H
            printf("%" PRIu64,*(mat_uint64_t*)data);
#elif defined(_MSC_VER) && _MSC_VER >= 1200
            printf("%I64u",*(mat_uint64_t*)data);
#elif defined(HAVE_UNSIGNED_LONG_LONG_INT)
            printf("%llu",(unsigned long long)(*(mat_uint64_t*)data));
#else
            printf("%lu",(unsigned long)(*(mat_uint64_t*)data));
#endif
            break;
#endif
        case MAT_T_INT32:
            printf("%d",*(mat_int32_t*)data);
            break;
        case MAT_T_UINT32:
            printf("%u",*(mat_uint32_t*)data);
            break;
        case MAT_T_INT16:
            printf("%hd",*(mat_int16_t*)data);
            break;
        case MAT_T_UINT16:
            printf("%hu",*(mat_uint16_t*)data);
            break;
        case MAT_T_INT8:
#if defined(__GNUC__) && __STDC_VERSION__ >= 199901L
            printf("%hhd",*(mat_int8_t*)data);
#else
            printf("%hd",(mat_int16_t)(*(mat_int8_t*)data));
#endif
            break;
        case MAT_T_UINT8:
#if defined(__GNUC__) && __STDC_VERSION__ >= 199901L
            printf("%hhu",*(mat_uint8_t*)data);
#else
            printf("%hu",(mat_uint16_t)(*(mat_uint8_t*)data));
#endif
            break;
        default:
            break;
    }
}

/*
 *====================================================================
 *                 Public Functions
 *====================================================================
 */

/** @brief Get the version of the library
 *
 * Gets the version number of the library
 * @param major Pointer to store the library major version number
 * @param minor Pointer to store the library minor version number
 * @param release Pointer to store the library release version number
 */
void
Mat_GetLibraryVersion(int *major,int *minor,int *release)
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
Mat_CreateVer(const char *matname,const char *hdr_str,enum mat_ft mat_file_ver)
{
    mat_t *mat = NULL;

    switch ( mat_file_ver ) {
        case MAT_FT_MAT4:
            mat = Mat_Create4(matname);
            break;
        case MAT_FT_MAT5:
            mat = Mat_Create5(matname,hdr_str);
            break;
        case MAT_FT_MAT73:
#if defined(HAVE_HDF5)
            mat = Mat_Create73(matname,hdr_str);
#endif
            break;
        default:
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
Mat_Open(const char *matname,int mode)
{
    FILE *fp = NULL;
    mat_int16_t tmp, tmp2;
    mat_t *mat = NULL;
    size_t bytesread = 0;

    if ( (mode & 0x01) == MAT_ACC_RDONLY ) {
        fp = fopen( matname, "rb" );
        if ( !fp )
            return NULL;
    } else if ( (mode & 0x01) == MAT_ACC_RDWR ) {
        fp = fopen( matname, "r+b" );
        if ( !fp ) {
            mat = Mat_CreateVer(matname,NULL,(enum mat_ft)(mode&0xfffffffe));
            return mat;
        }
    } else {
        Mat_Critical("Invalid file open mode");
        return NULL;
    }

    mat = (mat_t*)malloc(sizeof(*mat));
    if ( NULL == mat ) {
        fclose(fp);
        Mat_Critical("Couldn't allocate memory for the MAT file");
        return NULL;
    }

    mat->fp = fp;
    mat->header        = (char*)calloc(128,sizeof(char));
    if ( NULL == mat->header ) {
        free(mat);
        fclose(fp);
        Mat_Critical("Couldn't allocate memory for the MAT file header");
        return NULL;
    }
    mat->subsys_offset = (char*)calloc(8,sizeof(char));
    if ( NULL == mat->subsys_offset ) {
        free(mat->header);
        free(mat);
        fclose(fp);
        Mat_Critical("Couldn't allocate memory for the MAT file subsys offset");
        return NULL;
    }
    mat->filename      = NULL;
    mat->byteswap      = 0;
    mat->version       = 0;
    mat->refs_id       = -1;

    bytesread += fread(mat->header,1,116,fp);
    mat->header[116] = '\0';
    bytesread += fread(mat->subsys_offset,1,8,fp);
    bytesread += 2*fread(&tmp2,2,1,fp);
    bytesread += fread(&tmp,1,2,fp);

    if ( 128 == bytesread ) {
        /* v5 and v7.3 files have at least 128 byte header */
        mat->byteswap = -1;
        if (tmp == 0x4d49)
            mat->byteswap = 0;
        else if (tmp == 0x494d) {
            mat->byteswap = 1;
            Mat_int16Swap(&tmp2);
        }

        mat->version = (int)tmp2;
        if ( (mat->version == 0x0100 || mat->version == 0x0200) &&
             -1 != mat->byteswap ) {
            mat->bof = ftell((FILE*)mat->fp);
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

        mat->header        = NULL;
        mat->subsys_offset = NULL;
        mat->fp            = fp;
        mat->version       = MAT_FT_MAT4;
        mat->byteswap      = 0;
        mat->mode          = mode;
        mat->bof           = 0;
        mat->next_index    = 0;
        mat->refs_id       = -1;

        Mat_Rewind(mat);
        var = Mat_VarReadNextInfo4(mat);
        if ( NULL == var &&
             bytesread != 0 ) { /* Accept 0 bytes files as a valid V4 file */
            /* Does not seem to be a valid V4 file */
            Mat_Close(mat);
            mat = NULL;
            Mat_Critical("\"%s\" does not seem to be a valid MAT file",matname);
        } else {
            Mat_VarFree(var);
            Mat_Rewind(mat);
        }
    }

    if ( NULL == mat )
        return mat;

    mat->filename = strdup_printf("%s",matname);
    mat->mode = mode;

    if ( mat->version == 0x0200 ) {
        fclose((FILE*)mat->fp);
#if defined(HAVE_HDF5)

        mat->fp = malloc(sizeof(hid_t));

        if ( (mode & 0x01) == MAT_ACC_RDONLY )
            *(hid_t*)mat->fp=H5Fopen(mat->filename,H5F_ACC_RDONLY,H5P_DEFAULT);
        else if ( (mode & 0x01) == MAT_ACC_RDWR )
            *(hid_t*)mat->fp=H5Fopen(mat->filename,H5F_ACC_RDWR,H5P_DEFAULT);

        if ( -1 < *(hid_t*)mat->fp ) {
            H5G_info_t group_info;
            H5Gget_info(*(hid_t*)mat->fp, &group_info);
            mat->num_datasets = group_info.nlinks;
            mat->refs_id      = -1;
        }
#else
        mat->fp = NULL;
        Mat_Close(mat);
        mat = NULL;
        Mat_Critical("No HDF5 support which is required to read the v7.3 "
                     "MAT file \"%s\"",matname);
#endif
    }

    return mat;
}

/** @brief Closes an open Matlab MAT file
 *
 * Closes the given Matlab MAT file and frees any memory with it.
 * @ingroup MAT
 * @param mat Pointer to the MAT file
 * @retval 0
 */
int
Mat_Close( mat_t *mat )
{
    if ( NULL != mat ) {
#if defined(HAVE_HDF5)
        if ( mat->version == 0x0200 ) {
            if ( mat->refs_id > -1 )
                H5Gclose(mat->refs_id);
            H5Fclose(*(hid_t*)mat->fp);
            free(mat->fp);
            mat->fp = NULL;
        }
#endif
        if ( mat->fp )
            fclose((FILE*)mat->fp);
        if ( mat->header )
            free(mat->header);
        if ( mat->subsys_offset )
            free(mat->subsys_offset);
        if ( mat->filename )
            free(mat->filename);
        free(mat);
    }
    return 0;
}

/** @brief Gets the filename for the given MAT file
 *
 * Gets the filename for the given MAT file
 * @ingroup MAT
 * @param matfp Pointer to the MAT file
 * @return MAT filename
 */
const char *
Mat_GetFilename(mat_t *matfp)
{
    const char *filename = NULL;
    if ( NULL != matfp )
        filename = matfp->filename;
    return filename;
}

/** @brief Gets the version of the given MAT file
 *
 * Gets the version of the given MAT file
 * @ingroup MAT
 * @param matfp Pointer to the MAT file
 * @return MAT file version
 */
enum mat_ft
Mat_GetVersion(mat_t *matfp)
{
    enum mat_ft file_type = MAT_FT_UNDEFINED;
    if ( NULL != matfp )
        file_type = (enum mat_ft)matfp->version;
    return file_type;
}

/** @brief Rewinds a Matlab MAT file to the first variable
 *
 * Rewinds a Matlab MAT file to the first variable
 * @ingroup MAT
 * @param mat Pointer to the MAT file
 * @retval 0 on success
 */
int
Mat_Rewind( mat_t *mat )
{
    int err = 0;

    switch ( mat->version ) {
        case MAT_FT_MAT73:
            mat->next_index = 0;
            break;
        case MAT_FT_MAT5:
            (void)fseek((FILE*)mat->fp,128L,SEEK_SET);
            break;
        case MAT_FT_MAT4:
            (void)fseek((FILE*)mat->fp,0L,SEEK_SET);
            break;
        default:
            err = -1;
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
    switch (class_type) {
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

    matvar = (matvar_t*)malloc(sizeof(*matvar));

    if ( NULL != matvar ) {
        matvar->nbytes       = 0;
        matvar->rank         = 0;
        matvar->data_type    = MAT_T_UNKNOWN;
        matvar->data_size    = 0;
        matvar->class_type   = MAT_C_EMPTY;
        matvar->isComplex    = 0;
        matvar->isGlobal     = 0;
        matvar->isLogical    = 0;
        matvar->dims         = NULL;
        matvar->name         = NULL;
        matvar->data         = NULL;
        matvar->mem_conserve = 0;
        matvar->compression  = MAT_COMPRESSION_NONE;
        matvar->internal     = (struct matvar_internal*)malloc(sizeof(*matvar->internal));
        if ( NULL == matvar->internal ) {
            free(matvar);
            matvar = NULL;
        } else {
            matvar->internal->hdf5_name = NULL;
            matvar->internal->hdf5_ref  =  0;
            matvar->internal->id        = -1;
            matvar->internal->fp = NULL;
            matvar->internal->fpos       = 0;
            matvar->internal->datapos    = 0;
            matvar->internal->fieldnames = NULL;
            matvar->internal->num_fields = 0;
#if defined(HAVE_ZLIB)
            matvar->internal->z          = NULL;
            matvar->internal->data       = NULL;
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
Mat_VarCreate(const char *name,enum matio_classes class_type,
    enum matio_types data_type,int rank,size_t *dims,void *data,int opt)
{
    size_t i, nmemb = 1, nfields = 0, data_size;
    matvar_t *matvar = NULL;

    if (dims == NULL) return NULL;

    matvar = Mat_VarCalloc();
    if ( NULL == matvar )
        return NULL;

    matvar->compression = MAT_COMPRESSION_NONE;
    matvar->isComplex   = opt & MAT_F_COMPLEX;
    matvar->isGlobal    = opt & MAT_F_GLOBAL;
    matvar->isLogical   = opt & MAT_F_LOGICAL;
    if ( name )
        matvar->name = strdup_printf("%s",name);
    matvar->rank = rank;
    matvar->dims = (size_t*)malloc(matvar->rank*sizeof(*matvar->dims));
    for ( i = 0; i < matvar->rank; i++ ) {
        matvar->dims[i] = dims[i];
        nmemb *= dims[i];
    }
    matvar->class_type = class_type;
    matvar->data_type  = data_type;
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
        case MAT_T_STRUCT:
        {
            matvar_t **fields;

            data_size = sizeof(matvar_t **);
            if ( data != NULL ) {
                fields = (matvar_t**)data;
                nfields = 0;
                while ( fields[nfields] != NULL )
                    nfields++;
                if ( nmemb )
                    nfields = nfields / nmemb;
                matvar->internal->num_fields = nfields;
                if ( nfields ) {
                    matvar->internal->fieldnames =
                        (char**)calloc(nfields,sizeof(*matvar->internal->fieldnames));
                    for ( i = 0; i < nfields; i++ )
                        matvar->internal->fieldnames[i] = mat_strdup(fields[i]->name);
                    nmemb *= nfields;
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
        matvar->nbytes    = matvar->data_size;
    } else {
        matvar->data_size = data_size;
        matvar->nbytes = nmemb*matvar->data_size;
    }
    if ( data == NULL ) {
        if ( MAT_C_CELL == matvar->class_type && nmemb > 0 )
            matvar->data = calloc(nmemb,sizeof(matvar_t*));
        else
            matvar->data = NULL;
    } else if ( opt & MAT_F_DONT_COPY_DATA ) {
        matvar->data         = data;
        matvar->mem_conserve = 1;
    } else if ( MAT_C_SPARSE == matvar->class_type ) {
        mat_sparse_t *sparse_data, *sparse_data_in;

        sparse_data_in = (mat_sparse_t*)data;
        sparse_data    = (mat_sparse_t*)malloc(sizeof(mat_sparse_t));
        if ( NULL != sparse_data ) {
            sparse_data->nzmax = sparse_data_in->nzmax;
            sparse_data->nir   = sparse_data_in->nir;
            sparse_data->njc   = sparse_data_in->njc;
            sparse_data->ndata = sparse_data_in->ndata;
            sparse_data->ir = (int*)malloc(sparse_data->nir*sizeof(*sparse_data->ir));
            if ( NULL != sparse_data->ir )
                memcpy(sparse_data->ir,sparse_data_in->ir,
                       sparse_data->nir*sizeof(*sparse_data->ir));
            sparse_data->jc = (int*)malloc(sparse_data->njc*sizeof(*sparse_data->jc));
            if ( NULL != sparse_data->jc )
                memcpy(sparse_data->jc,sparse_data_in->jc,
                       sparse_data->njc*sizeof(*sparse_data->jc));
            if ( matvar->isComplex ) {
                sparse_data->data = malloc(sizeof(mat_complex_split_t));
                if ( NULL != sparse_data->data ) {
                    mat_complex_split_t *complex_data,*complex_data_in;
                    complex_data     = (mat_complex_split_t*)sparse_data->data;
                    complex_data_in  = (mat_complex_split_t*)sparse_data_in->data;
                    complex_data->Re = malloc(sparse_data->ndata*data_size);
                    complex_data->Im = malloc(sparse_data->ndata*data_size);
                    if ( NULL != complex_data->Re )
                        memcpy(complex_data->Re,complex_data_in->Re,
                               sparse_data->ndata*data_size);
                    if ( NULL != complex_data->Im )
                        memcpy(complex_data->Im,complex_data_in->Im,
                               sparse_data->ndata*data_size);
                }
            } else {
                sparse_data->data = malloc(sparse_data->ndata*data_size);
                if ( NULL != sparse_data->data )
                    memcpy(sparse_data->data,sparse_data_in->data,
                           sparse_data->ndata*data_size);
            }
        }
        matvar->data = sparse_data;
    } else {
        if ( matvar->isComplex ) {
            matvar->data   = malloc(sizeof(mat_complex_split_t));
            if ( NULL != matvar->data && matvar->nbytes > 0 ) {
                mat_complex_split_t *complex_data    = (mat_complex_split_t*)matvar->data;
                mat_complex_split_t *complex_data_in = (mat_complex_split_t*)data;

                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);
                if ( NULL != complex_data->Re )
                    memcpy(complex_data->Re,complex_data_in->Re,matvar->nbytes);
                if ( NULL != complex_data->Im )
                    memcpy(complex_data->Im,complex_data_in->Im,matvar->nbytes);
            }
        } else if ( matvar->nbytes > 0 ) {
            matvar->data   = malloc(matvar->nbytes);
            if ( NULL != matvar->data )
                memcpy(matvar->data,data,matvar->nbytes);
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
mat_copy(const char* src, const char* dst)
{
    size_t len;
    char buf[BUFSIZ] = {'\0'};
    FILE* in;
    FILE* out;

    in = fopen(src, "rb");
    if (in == NULL) {
        Mat_Critical("Cannot open file \"%s\" for reading.", src);
        return -1;
    }

    out = fopen(dst, "wb");
    if (out == NULL) {
        fclose(in);
        Mat_Critical("Cannot open file \"%s\" for writing.", dst);
        return -1;
    }

    while ((len = fread(buf, sizeof(char), BUFSIZ, in)) > 0) {
        if (len != fwrite(buf, sizeof(char), len, out)) {
            fclose(in);
            fclose(out);
            Mat_Critical("Error writing to file \"%s\".", dst);
            return -1;
        }
    }
    fclose(in);
    fclose(out);
    return 0;
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
    int   err = 1;
    char *tmp_name;
    char temp[7] = "XXXXXX";

    if ( NULL == mat || NULL == name )
        return err;

    if ( (tmp_name = mktemp(temp)) != NULL ) {
        enum mat_ft mat_file_ver = MAT_FT_DEFAULT;
        mat_t *tmp;

        switch ( mat->version ) {
            case 0x0200:
                mat_file_ver = MAT_FT_MAT73;
                break;
            case 0x0100:
                mat_file_ver = MAT_FT_MAT5;
                break;
            case 0x0010:
                mat_file_ver = MAT_FT_MAT4;
                break;
        }

        tmp = Mat_CreateVer(tmp_name,mat->header,mat_file_ver);
        if ( tmp != NULL ) {
            matvar_t *matvar;
            while ( NULL != (matvar = Mat_VarReadNext(mat)) ) {
                if ( strcmp(matvar->name,name) )
                    Mat_VarWrite(tmp,matvar,matvar->compression);
                else
                    err = 0;
                Mat_VarFree(matvar);
            }
            Mat_Close(tmp);

            if (err == 0) {
                char *new_name = strdup_printf("%s",mat->filename);
#if defined(HAVE_HDF5)
                if ( mat_file_ver == MAT_FT_MAT73 ) {
                    if ( mat->refs_id > -1 )
                        H5Gclose(mat->refs_id);
                    H5Fclose(*(hid_t*)mat->fp);
                    free(mat->fp);
                    mat->fp = NULL;
                }
#endif
                if ( mat->fp ) {
                    fclose((FILE*)mat->fp);
                    mat->fp = NULL;
                }

                if ( (err = mat_copy(tmp_name,new_name)) == -1 ) {
                    Mat_Critical("Cannot copy file from \"%s\" to \"%s\".",
                        tmp_name, new_name);
                } else if ( (err = remove(tmp_name)) == -1 ) {
                    Mat_Critical("Cannot remove file \"%s\".",tmp_name);
                } else {
                    tmp = Mat_Open(new_name,mat->mode);
                    if ( NULL != tmp ) {
                        if ( mat->header )
                            free(mat->header);
                        if ( mat->subsys_offset )
                            free(mat->subsys_offset);
                        if ( mat->filename )
                            free(mat->filename);
                        memcpy(mat,tmp,sizeof(mat_t));
                        free(tmp);
                    } else {
                        Mat_Critical("Cannot open file \"%s\".",new_name);
                    }
                }
                free(new_name);
            } else if ( (err = remove(tmp_name)) == -1 ) {
                Mat_Critical("Cannot remove file \"%s\".",tmp_name);
            }
        }
    } else {
        Mat_Critical("Cannot create a unique file name.");
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
    int i;

    out = Mat_VarCalloc();
    if ( out == NULL )
        return NULL;

    out->nbytes       = in->nbytes;
    out->rank         = in->rank;
    out->data_type    = in->data_type;
    out->data_size    = in->data_size;
    out->class_type   = in->class_type;
    out->isComplex    = in->isComplex;
    out->isGlobal     = in->isGlobal;
    out->isLogical    = in->isLogical;
    out->mem_conserve = in->mem_conserve;
    out->compression  = in->compression;

    out->name = NULL;
    out->dims = NULL;
    out->data = NULL;

    if ( NULL != in->internal->hdf5_name )
        out->internal->hdf5_name = mat_strdup(in->internal->hdf5_name);

    out->internal->hdf5_ref = in->internal->hdf5_ref;
    out->internal->id       = in->internal->id;
    out->internal->fpos     = in->internal->fpos;
    out->internal->datapos  = in->internal->datapos;
#if defined(HAVE_ZLIB)
    out->internal->z        = NULL;
    out->internal->data     = NULL;
#endif
    out->internal->num_fields = in->internal->num_fields;
    if ( NULL != in->internal->fieldnames && in->internal->num_fields > 0 ) {
        out->internal->fieldnames = (char**)calloc(in->internal->num_fields,
                                           sizeof(*in->internal->fieldnames));
        for ( i = 0; i < in->internal->num_fields; i++ ) {
            if ( NULL != in->internal->fieldnames[i] )
                out->internal->fieldnames[i] =
                    mat_strdup(in->internal->fieldnames[i]);
        }
    }

    if (in->name != NULL && (NULL != (out->name = (char*)malloc(strlen(in->name)+1))))
        memcpy(out->name,in->name,strlen(in->name)+1);

    out->dims = (size_t*)malloc(in->rank*sizeof(*out->dims));
    if ( out->dims != NULL )
        memcpy(out->dims,in->dims,in->rank*sizeof(*out->dims));

#if defined(HAVE_ZLIB)
    if ( (in->internal->z != NULL) && (NULL != (out->internal->z = (z_streamp)malloc(sizeof(z_stream)))) )
        inflateCopy(out->internal->z,in->internal->z);
    if ( in->internal->data != NULL ) {
        if ( in->class_type == MAT_C_SPARSE ) {
            out->internal->data = malloc(sizeof(mat_sparse_t));
            if ( out->internal->data != NULL ) {
                mat_sparse_t *out_sparse = (mat_sparse_t*)out->internal->data;
                mat_sparse_t *in_sparse  = (mat_sparse_t*)in->internal->data;
                out_sparse->nzmax = in_sparse->nzmax;
                out_sparse->nir = in_sparse->nir;
                out_sparse->ir = (int*)malloc(in_sparse->nir*sizeof(int));
                if ( out_sparse->ir != NULL )
                    memcpy(out_sparse->ir, in_sparse->ir, in_sparse->nir*sizeof(int));
                out_sparse->njc = in_sparse->njc;
                out_sparse->jc = (int*)malloc(in_sparse->njc*sizeof(int));
                if ( out_sparse->jc != NULL )
                    memcpy(out_sparse->jc, in_sparse->jc, in_sparse->njc*sizeof(int));
                out_sparse->ndata = in_sparse->ndata;
                if ( out->isComplex && NULL != in_sparse->data ) {
                    out_sparse->data = malloc(sizeof(mat_complex_split_t));
                    if ( out_sparse->data != NULL ) {
                        mat_complex_split_t *out_data = (mat_complex_split_t*)out_sparse->data;
                        mat_complex_split_t *in_data  = (mat_complex_split_t*)in_sparse->data;
                        out_data->Re = malloc(
                            in_sparse->ndata*Mat_SizeOf(in->data_type));
                        if ( NULL != out_data->Re )
                            memcpy(out_data->Re,in_data->Re,
                                in_sparse->ndata*Mat_SizeOf(in->data_type));
                        out_data->Im = malloc(
                            in_sparse->ndata*Mat_SizeOf(in->data_type));
                        if ( NULL != out_data->Im )
                            memcpy(out_data->Im,in_data->Im,
                                in_sparse->ndata*Mat_SizeOf(in->data_type));
                    }
                } else if ( in_sparse->data != NULL ) {
                    out_sparse->data = malloc(in_sparse->ndata*Mat_SizeOf(in->data_type));
                    if ( NULL != out_sparse->data )
                        memcpy(out_sparse->data, in_sparse->data,
                            in_sparse->ndata*Mat_SizeOf(in->data_type));
                }
            }
        } else if ( out->isComplex ) {
            out->internal->data = malloc(sizeof(mat_complex_split_t));
            if ( out->internal->data != NULL ) {
                mat_complex_split_t *out_data = (mat_complex_split_t*)out->internal->data;
                mat_complex_split_t *in_data  = (mat_complex_split_t*)in->internal->data;
                out_data->Re = malloc(out->nbytes);
                if ( NULL != out_data->Re )
                    memcpy(out_data->Re,in_data->Re,out->nbytes);
                out_data->Im = malloc(out->nbytes);
                if ( NULL != out_data->Im )
                    memcpy(out_data->Im,in_data->Im,out->nbytes);
            }
        } else if ( NULL != (out->internal->data = malloc(in->nbytes)) ) {
            memcpy(out->internal->data, in->internal->data, in->nbytes);
        }
    }
#endif

    if ( !opt ) {
        out->data = in->data;
    } else if ( (in->data != NULL) && (in->class_type == MAT_C_STRUCT) ) {
        matvar_t **infields, **outfields;
        int nfields = 0;

        out->data = malloc(in->nbytes);
        if ( out->data != NULL && in->data_size > 0 ) {
            nfields   = in->nbytes / in->data_size;
            infields  = (matvar_t **)in->data;
            outfields = (matvar_t **)out->data;
            for ( i = 0; i < nfields; i++ ) {
                outfields[i] = Mat_VarDuplicate(infields[i],opt);
            }
        }
    } else if ( (in->data != NULL) && (in->class_type == MAT_C_CELL) ) {
        matvar_t **incells, **outcells;
        int ncells = 0;

        out->data = malloc(in->nbytes);
        if ( out->data != NULL && in->data_size > 0 ) {
            ncells   = in->nbytes / in->data_size;
            incells  = (matvar_t **)in->data;
            outcells = (matvar_t **)out->data;
            for ( i = 0; i < ncells; i++ ) {
                outcells[i] = Mat_VarDuplicate(incells[i],opt);
            }
        }
    } else if ( (in->data != NULL) && (in->class_type == MAT_C_SPARSE) ) {
        out->data = malloc(sizeof(mat_sparse_t));
        if ( out->data != NULL ) {
            mat_sparse_t *out_sparse = (mat_sparse_t*)out->data;
            mat_sparse_t *in_sparse  = (mat_sparse_t*)in->data;
            out_sparse->nzmax = in_sparse->nzmax;
            out_sparse->nir = in_sparse->nir;
            out_sparse->ir = (int*)malloc(in_sparse->nir*sizeof(int));
            if ( out_sparse->ir != NULL )
                memcpy(out_sparse->ir, in_sparse->ir, in_sparse->nir*sizeof(int));
            out_sparse->njc = in_sparse->njc;
            out_sparse->jc = (int*)malloc(in_sparse->njc*sizeof(int));
            if ( out_sparse->jc != NULL )
                memcpy(out_sparse->jc, in_sparse->jc, in_sparse->njc*sizeof(int));
            out_sparse->ndata = in_sparse->ndata;
            if ( out->isComplex && NULL != in_sparse->data ) {
                out_sparse->data = malloc(sizeof(mat_complex_split_t));
                if ( out_sparse->data != NULL ) {
                    mat_complex_split_t *out_data = (mat_complex_split_t*)out_sparse->data;
                    mat_complex_split_t *in_data  = (mat_complex_split_t*)in_sparse->data;
                    out_data->Re = malloc(in_sparse->ndata*Mat_SizeOf(in->data_type));
                    if ( NULL != out_data->Re )
                        memcpy(out_data->Re,in_data->Re,in_sparse->ndata*Mat_SizeOf(in->data_type));
                    out_data->Im = malloc(in_sparse->ndata*Mat_SizeOf(in->data_type));
                    if ( NULL != out_data->Im )
                        memcpy(out_data->Im,in_data->Im,in_sparse->ndata*Mat_SizeOf(in->data_type));
                }
            } else if ( in_sparse->data != NULL ) {
                out_sparse->data = malloc(in_sparse->ndata*Mat_SizeOf(in->data_type));
                if ( NULL != out_sparse->data )
                    memcpy(out_sparse->data, in_sparse->data, in_sparse->ndata*Mat_SizeOf(in->data_type));
            }
        }
    } else if ( in->data != NULL ) {
        if ( out->isComplex ) {
            out->data = malloc(sizeof(mat_complex_split_t));
            if ( out->data != NULL ) {
                mat_complex_split_t *out_data = (mat_complex_split_t*)out->data;
                mat_complex_split_t *in_data  = (mat_complex_split_t*)in->data;
                out_data->Re = malloc(out->nbytes);
                if ( NULL != out_data->Re )
                    memcpy(out_data->Re,in_data->Re,out->nbytes);
                out_data->Im = malloc(out->nbytes);
                if ( NULL != out_data->Im )
                    memcpy(out_data->Im,in_data->Im,out->nbytes);
            }
        } else {
            out->data = malloc(in->nbytes);
            if ( out->data != NULL )
                memcpy(out->data,in->data,in->nbytes);
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
    size_t nmemb = 0, i;
    if ( !matvar )
        return;
    if ( matvar->dims ) {
        nmemb = 1;
        for ( i = 0; i < matvar->rank; i++ )
            nmemb *= matvar->dims[i];
        free(matvar->dims);
    }
    if ( matvar->name )
        free(matvar->name);
    if ( matvar->data != NULL) {
        switch (matvar->class_type ) {
            case MAT_C_STRUCT:
                if ( !matvar->mem_conserve ) {
                    matvar_t **fields = (matvar_t**)matvar->data;
                    int nfields = matvar->internal->num_fields;
                    for ( i = 0; i < nmemb*nfields; i++ )
                        Mat_VarFree(fields[i]);

                    free(matvar->data);
                    break;
                }
            case MAT_C_CELL:
                if ( !matvar->mem_conserve ) {
                    matvar_t **cells = (matvar_t**)matvar->data;
                    for ( i = 0; i < nmemb; i++ )
                        Mat_VarFree(cells[i]);

                    free(matvar->data);
                }
                break;
            case MAT_C_SPARSE:
                if ( !matvar->mem_conserve ) {
                    mat_sparse_t *sparse;
                    sparse = (mat_sparse_t*)matvar->data;
                    if ( sparse->ir != NULL )
                        free(sparse->ir);
                    if ( sparse->jc != NULL )
                        free(sparse->jc);
                    if ( matvar->isComplex && NULL != sparse->data ) {
                        mat_complex_split_t *complex_data = (mat_complex_split_t*)sparse->data;
                        free(complex_data->Re);
                        free(complex_data->Im);
                        free(complex_data);
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
                        mat_complex_split_t *complex_data = (mat_complex_split_t*)matvar->data;
                        free(complex_data->Re);
                        free(complex_data->Im);
                        free(complex_data);
                    } else {
                        free(matvar->data);
                    }
                }
                break;
            case MAT_C_EMPTY:
            case MAT_C_OBJECT:
            case MAT_C_FUNCTION:
                break;
        }
    }

    if ( NULL != matvar->internal ) {
#if defined(HAVE_ZLIB)
        if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
            inflateEnd(matvar->internal->z);
            free(matvar->internal->z);
            if ( (matvar->internal->data != NULL) && (matvar->class_type == MAT_C_SPARSE) ) {
                mat_sparse_t *sparse;
                sparse = (mat_sparse_t*)matvar->internal->data;
                if ( sparse->ir != NULL )
                    free(sparse->ir);
                if ( sparse->jc != NULL )
                    free(sparse->jc);
                if ( matvar->isComplex && NULL != sparse->data ) {
                    mat_complex_split_t *complex_data = (mat_complex_split_t*)sparse->data;
                    free(complex_data->Re);
                    free(complex_data->Im);
                    free(complex_data);
                } else if ( sparse->data != NULL ) {
                    free(sparse->data);
                }
                free(sparse);
            }
            else if ( (matvar->internal->data != NULL) && matvar->isComplex ) {
                mat_complex_split_t *complex_data =
                    (mat_complex_split_t*)matvar->internal->data;
                free(complex_data->Re);
                free(complex_data->Im);
                free(complex_data);
            } else if ( NULL != matvar->internal->data ) {
                free(matvar->internal->data);
            }
        }
#endif
#if defined(HAVE_HDF5)
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
        if ( NULL != matvar->internal->fieldnames &&
             matvar->internal->num_fields > 0 ) {
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
    /* FIXME: Why does this cause a SEGV? */
#if 0
    memset(matvar,0,sizeof(matvar_t));
#endif
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
Mat_CalcSingleSubscript(int rank,int *dims,int *subs)
{
    int index = 0, i, j, k, err = 0;

    for ( i = 0; i < rank; i++ ) {
        k = subs[i];
        if ( k > dims[i] ) {
            err = 1;
            Mat_Critical("Mat_CalcSingleSubscript: index out of bounds");
            break;
        } else if ( k < 1 ) {
            err = 1;
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
Mat_CalcSingleSubscript2(int rank,size_t *dims,size_t *subs,size_t *index)
{
    int i, err = 0;

    for ( i = 0; i < rank; i++ ) {
        int j;
        size_t k = subs[i];
        if ( k > dims[i] ) {
            err = 1;
            Mat_Critical("Mat_CalcSingleSubscript2: index out of bounds");
            break;
        } else if ( k < 1 ) {
            err = 1;
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
Mat_CalcSubscripts(int rank,int *dims,int index)
{
    int i, j, k, *subs;
    double l;

    subs = (int*)malloc(rank*sizeof(int));
    l = index;
    for ( i = rank; i--; ) {
        k = 1;
        for ( j = i; j--; )
            k *= dims[j];
        subs[i] = floor(l / (double)k);
        l -= subs[i]*k;
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
Mat_CalcSubscripts2(int rank,size_t *dims,size_t index)
{
    int i;
    size_t *subs;
    double l;

    subs = (size_t*)malloc(rank*sizeof(size_t));
    l = (double)index;
    for ( i = rank; i--; ) {
        int j;
        size_t k = 1;
        for ( j = i; j--; )
            k *= dims[j];
        subs[i] = (size_t)floor(l / (double)k);
        l -= subs[i]*k;
        subs[i]++;
    }

    return subs;
}

/** @brief Calculates the size of a matlab variable in bytes
 *
 * @ingroup MAT
 * @param matvar matlab variable
 * @returns size of the variable in bytes
 */
size_t
Mat_VarGetSize(matvar_t *matvar)
{
    int nmemb, i;
    size_t bytes = 0;

    if ( matvar->class_type == MAT_C_STRUCT ) {
        int nfields;
        matvar_t **fields;

        nmemb = 1;
        for ( i = 0; i < matvar->rank; i++ )
            nmemb *= matvar->dims[i];
        nfields = matvar->internal->num_fields;
        if ( nmemb*nfields > 0 ) {
            fields  = (matvar_t**)matvar->data;
            if ( NULL != fields )
                for ( i = 0; i < nmemb*nfields; i++ )
                    bytes += Mat_VarGetSize(fields[i]);
        }
    } else if ( matvar->class_type == MAT_C_CELL ) {
        int ncells;
        matvar_t **cells;

        ncells = matvar->nbytes / matvar->data_size;
        cells  = (matvar_t**)matvar->data;
        if ( NULL != cells )
            for ( i = 0; i < ncells; i++ )
                bytes += Mat_VarGetSize(cells[i]);
    } else {
        nmemb = 1;
        for ( i = 0; i < matvar->rank; i++ )
            nmemb *= matvar->dims[i];
        bytes += nmemb*Mat_SizeOfClass(matvar->class_type);
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
Mat_VarPrint( matvar_t *matvar, int printdata )
{
    size_t nmemb;
    int i, j;
    const char *class_type_desc[16] = {"Undefined","Cell Array","Structure",
       "Object","Character Array","Sparse Array","Double Precision Array",
       "Single Precision Array", "8-bit, signed integer array",
       "8-bit, unsigned integer array","16-bit, signed integer array",
       "16-bit, unsigned integer array","32-bit, signed integer array",
       "32-bit, unsigned integer array","64-bit, signed integer array",
       "64-bit, unsigned integer array"};
    const char *data_type_desc[23] = {"Unknown","8-bit, signed integer",
       "8-bit, unsigned integer","16-bit, signed integer",
       "16-bit, unsigned integer","32-bit, signed integer",
       "32-bit, unsigned integer","IEEE 754 single-precision","RESERVED",
       "IEEE 754 double-precision","RESERVED","RESERVED",
       "64-bit, signed integer","64-bit, unsigned integer", "Matlab Array",
       "Compressed Data","Unicode UTF-8 Encoded Character Data",
       "Unicode UTF-16 Encoded Character Data",
       "Unicode UTF-32 Encoded Character Data","","String","Cell Array",
       "Structure"};

    if ( matvar == NULL )
        return;
    if ( matvar->name )
        printf("      Name: %s\n", matvar->name);
    printf("      Rank: %d\n", matvar->rank);
    if ( matvar->rank == 0 )
        return;
    printf("Dimensions: %" SIZE_T_FMTSTR,matvar->dims[0]);
    nmemb = matvar->dims[0];
    for ( i = 1; i < matvar->rank; i++ ) {
        printf(" x %" SIZE_T_FMTSTR,matvar->dims[i]);
        nmemb *= matvar->dims[i];
    }
    printf("\n");
    printf("Class Type: %s",class_type_desc[matvar->class_type]);
    if ( matvar->isComplex )
        printf(" (complex)");
    else if ( matvar->isLogical )
        printf(" (logical)");
    printf("\n");
    if ( matvar->data_type )
        printf(" Data Type: %s\n", data_type_desc[matvar->data_type]);

    if ( MAT_C_STRUCT == matvar->class_type ) {
        matvar_t **fields = (matvar_t **)matvar->data;
        int nfields = matvar->internal->num_fields;
        if ( nmemb*nfields > 0 ) {
            printf("Fields[%" SIZE_T_FMTSTR "] {\n", nfields*nmemb);
            for ( i = 0; i < nfields*nmemb; i++ ) {
                if ( NULL == fields[i] ) {
                    printf("      Name: %s\n      Rank: %d\n",
                           matvar->internal->fieldnames[i%nfields],0);
                } else {
                    Mat_VarPrint(fields[i],printdata);
                }
            }
            printf("}\n");
        } else {
            printf("Fields[%d] {\n", nfields);
            for ( i = 0; i < nfields; i++ )
                printf("      Name: %s\n      Rank: %d\n",
                       matvar->internal->fieldnames[i],0);
            printf("}\n");
        }
        return;
    } else if ( matvar->data == NULL || matvar->data_size < 1 ) {
        return;
    } else if ( MAT_C_CELL == matvar->class_type ) {
        matvar_t **cells = (matvar_t **)matvar->data;
        int ncells = matvar->nbytes / matvar->data_size;
        printf("{\n");
        for ( i = 0; i < ncells; i++ )
            Mat_VarPrint(cells[i],printdata);
        printf("}\n");
        return;
    } else if ( !printdata ) {
        return;
    }

    printf("{\n");

    if ( matvar->rank > 2 ) {
        printf("I can't print more than 2 dimensions\n");
    } else if ( matvar->rank == 1 && matvar->dims[0] > 15 ) {
        printf("I won't print more than 15 elements in a vector\n");
    } else if ( matvar->rank==2 ) {
        switch( matvar->class_type ) {
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
            {
                size_t stride = Mat_SizeOf(matvar->data_type);
                if ( matvar->isComplex ) {
                    mat_complex_split_t *complex_data = (mat_complex_split_t*)matvar->data;
                    char *rp = (char*)complex_data->Re;
                    char *ip = (char*)complex_data->Im;
                    for ( i = 0; i < matvar->dims[0] && i < 15; i++ ) {
                        for ( j = 0; j < matvar->dims[1] && j < 15; j++ ) {
                            size_t idx = matvar->dims[0]*j+i;
                            Mat_PrintNumber(matvar->data_type,rp+idx*stride);
                            printf(" + ");
                            Mat_PrintNumber(matvar->data_type,ip+idx*stride);
                            printf("i ");
                        }
                        if ( j < matvar->dims[1] )
                            printf("...");
                        printf("\n");
                    }
                    if ( i < matvar->dims[0] )
                        printf(".\n.\n.\n");
               } else {
                   char *data = (char*)matvar->data;
                   for ( i = 0; i < matvar->dims[0] && i < 15; i++ ) {
                        for ( j = 0; j < matvar->dims[1] && j < 15; j++ ) {
                            size_t idx = matvar->dims[0]*j+i;
                            Mat_PrintNumber(matvar->data_type,
                                            data+idx*stride);
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
            case MAT_C_CHAR:
            {
                char *data = (char*)matvar->data;
                for ( i = 0; i < matvar->dims[0]; i++ ) {
                    for ( j = 0; j < matvar->dims[1]; j++ )
                        printf("%c",data[j*matvar->dims[0]+i]);
                    printf("\n");
                }
                break;
            }
            case MAT_C_SPARSE:
            {
                mat_sparse_t *sparse;
                size_t stride = Mat_SizeOf(matvar->data_type);
#if !defined(EXTENDED_SPARSE)
                if ( MAT_T_DOUBLE != matvar->data_type )
                    break;
#endif
                sparse = (mat_sparse_t*)matvar->data;
                if ( matvar->isComplex ) {
                    mat_complex_split_t *complex_data = (mat_complex_split_t*)sparse->data;
                    char *re = (char*)complex_data->Re;
                    char *im = (char*)complex_data->Im;
                    for ( i = 0; i < sparse->njc-1; i++ ) {
                        for ( j = sparse->jc[i];
                              j < sparse->jc[i+1] && j < sparse->ndata; j++ ) {
                            printf("    (%d,%d)  ",sparse->ir[j]+1,i+1);
                            Mat_PrintNumber(matvar->data_type,re+j*stride);
                            printf(" + ");
                            Mat_PrintNumber(matvar->data_type,im+j*stride);
                            printf("i\n");
                        }
                    }
                } else {
                    char *data = (char*)sparse->data;
                    for ( i = 0; i < sparse->njc-1; i++ ) {
                        for ( j = sparse->jc[i];
                              j < sparse->jc[i+1] && j < sparse->ndata; j++ ) {
                            printf("    (%d,%d)  ",sparse->ir[j]+1,i+1);
                            Mat_PrintNumber(matvar->data_type,data+j*stride);
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
Mat_VarReadData(mat_t *mat,matvar_t *matvar,void *data,
      int *start,int *stride,int *edge)
{
    int err = 0;

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
            return -1;
    }

    switch ( mat->version ) {
        case MAT_FT_MAT73:
#if defined(HAVE_HDF5)
            err = Mat_VarReadData73(mat,matvar,data,start,stride,edge);
#else
            err = 1;
#endif
            break;
        case MAT_FT_MAT5:
            err = ReadData5(mat,matvar,data,start,stride,edge);
            break;
        case MAT_FT_MAT4:
            err = ReadData4(mat,matvar,data,start,stride,edge);
            break;
    }

    return err;
}

/** @brief Reads all the data for a matlab variable
 *
 * Allocates memory for an reads the data for a given matlab variable.
 * @ingroup MAT
 * @param mat Matlab MAT file structure pointer
 * @param matvar Variable whose data is to be read
 * @returns non-zero on error
 */
int
Mat_VarReadDataAll(mat_t *mat,matvar_t *matvar)
{
    int err = 0;

    if ( (mat == NULL) || (matvar == NULL) )
        err = 1;
    else
        ReadData(mat,matvar);

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
Mat_VarReadDataLinear(mat_t *mat,matvar_t *matvar,void *data,int start,
    int stride,int edge)
{
    int err = 0;

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
            return -1;
    }

    switch ( mat->version ) {
        case MAT_FT_MAT73:
#if defined(HAVE_HDF5)
            err = Mat_VarReadDataLinear73(mat,matvar,data,start,stride,edge);
#else
            err = 1;
#endif
            break;
        case MAT_FT_MAT5:
            err = Mat_VarReadDataLinear5(mat,matvar,data,start,stride,edge);
            break;
        case MAT_FT_MAT4:
            err = Mat_VarReadDataLinear4(mat,matvar,data,start,stride,edge);
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
Mat_VarReadNextInfo( mat_t *mat )
{
    matvar_t *matvar = NULL;
    if( mat == NULL )
        return NULL;

    switch ( mat->version ) {
        case MAT_FT_MAT5:
            matvar = Mat_VarReadNextInfo5(mat);
            break;
        case MAT_FT_MAT73:
#if defined(HAVE_HDF5)
            matvar = Mat_VarReadNextInfo73(mat);
#endif
            break;
        case MAT_FT_MAT4:
            matvar = Mat_VarReadNextInfo4(mat);
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
Mat_VarReadInfo( mat_t *mat, const char *name )
{
    long fpos;
    matvar_t *matvar = NULL;

    if ( (mat == NULL) || (name == NULL) )
        return NULL;

    if ( mat->version == MAT_FT_MAT73 ) {
        fpos = mat->next_index;
        mat->next_index = 0;
        do {
            matvar = Mat_VarReadNextInfo(mat);
            if ( matvar != NULL ) {
                if ( matvar->name == NULL || strcmp(matvar->name,name) ) {
                    Mat_VarFree(matvar);
                    matvar = NULL;
                }
            } else {
                Mat_Critical("An error occurred in reading the MAT file");
                break;
            }
        } while ( NULL == matvar && mat->next_index < mat->num_datasets );
        mat->next_index = fpos;
    } else {
        fpos = ftell((FILE*)mat->fp);
        if ( fpos != -1L ) {
            (void)fseek((FILE*)mat->fp,mat->bof,SEEK_SET);
            do {
                matvar = Mat_VarReadNextInfo(mat);
                if ( matvar != NULL ) {
                    if ( matvar->name == NULL || strcmp(matvar->name,name) ) {
                        Mat_VarFree(matvar);
                        matvar = NULL;
                    }
                } else if (!feof((FILE *)mat->fp)) {
                    Mat_Critical("An error occurred in reading the MAT file");
                    break;
                }
            } while ( NULL == matvar && !feof((FILE *)mat->fp) );
            (void)fseek((FILE*)mat->fp,fpos,SEEK_SET);
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
Mat_VarRead( mat_t *mat, const char *name )
{
    long fpos;
    matvar_t *matvar = NULL;

    if ( (mat == NULL) || (name == NULL) )
        return NULL;

    if ( MAT_FT_MAT73 != mat->version ) {
        fpos = ftell((FILE*)mat->fp);
        if ( fpos == -1L ) {
            Mat_Critical("Couldn't determine file position");
            return NULL;
        }
    } else {
        fpos = mat->next_index;
        mat->next_index = 0;
    }

    matvar = Mat_VarReadInfo(mat,name);
    if ( matvar )
        ReadData(mat,matvar);

    if ( MAT_FT_MAT73 != mat->version ) {
        (void)fseek((FILE*)mat->fp,fpos,SEEK_SET);
    } else {
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
Mat_VarReadNext( mat_t *mat )
{
    long fpos = 0;
    matvar_t *matvar = NULL;

    if ( mat->version != MAT_FT_MAT73 ) {
        if ( feof((FILE *)mat->fp) )
            return NULL;
        /* Read position so we can reset the file position if an error occurs */
        fpos = ftell((FILE*)mat->fp);
        if ( fpos == -1L ) {
            Mat_Critical("Couldn't determine file position");
            return NULL;
        }
    }
    matvar = Mat_VarReadNextInfo(mat);
    if ( matvar ) {
        ReadData(mat,matvar);
    } else if (mat->version != MAT_FT_MAT73 ) {
        (void)fseek((FILE*)mat->fp,fpos,SEEK_SET);
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
 * @retval 0 on success
 */
int
Mat_VarWriteInfo(mat_t *mat, matvar_t *matvar )
{
    int err = 0;

    if ( mat == NULL || matvar == NULL || mat->fp == NULL )
        return -1;
    else if ( mat->version == MAT_FT_MAT5 )
        WriteInfo5(mat,matvar);
    else
        err = 1;

    return err;
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
 * @retval 0 on success
 */
int
Mat_VarWriteData(mat_t *mat,matvar_t *matvar,void *data,
      int *start,int *stride,int *edge)
{
    int err = 0, k, N = 1;

    if ( mat == NULL || matvar == NULL )
        return -1;

    (void)fseek((FILE*)mat->fp,matvar->internal->datapos+8,SEEK_SET);

    if ( data == NULL ) {
        err = -1;
    } else if ( start == NULL && stride == NULL && edge == NULL ) {
        for ( k = 0; k < matvar->rank; k++ )
            N *= matvar->dims[k];
        if ( matvar->compression == MAT_COMPRESSION_NONE )
            WriteData(mat,data,N,matvar->data_type);
#if 0
        else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
            WriteCompressedData(mat,matvar->internal->z,data,N,matvar->data_type);
            (void)deflateEnd(matvar->internal->z);
            free(matvar->internal->z);
            matvar->internal->z = NULL;
        }
#endif
    } else if ( start == NULL || stride == NULL || edge == NULL ) {
        err = 1;
    } else if ( matvar->rank == 2 ) {
        if ( stride[0]*(edge[0]-1)+start[0]+1 > matvar->dims[0] ) {
            err = 1;
        } else if ( stride[1]*(edge[1]-1)+start[1]+1 > matvar->dims[1] ) {
            err = 1;
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
                    WriteDataSlab2(mat,data,matvar->data_type,matvar->dims,
                                   start,stride,edge);
                    break;
                case MAT_C_CHAR:
                    WriteCharDataSlab2(mat,data,matvar->data_type,matvar->dims,
                                   start,stride,edge);
                    break;
                default:
                    break;
            }
        }
    }

    return err;
}

/** @brief Writes the given MAT variable to a MAT file
 *
 * Writes the MAT variable information stored in matvar to the given MAT file.
 * The variable will be written to the end of the file.
 * @ingroup MAT
 * @param mat MAT file to write to
 * @param matvar MAT variable information to write
 * @param compress Whether or not to compress the data
 *        (Only valid for version 5 MAT files and variables with numeric data)
 * @retval 0 on success
 */
int
Mat_VarWrite(mat_t *mat,matvar_t *matvar,enum matio_compression compress)
{
    if ( mat == NULL || matvar == NULL )
        return -1;
    else if ( mat->version == MAT_FT_MAT4 )
        return Mat_VarWrite4(mat,matvar);
    else if ( mat->version == MAT_FT_MAT5 )
        return Mat_VarWrite5(mat,matvar,compress);
#if defined(HAVE_HDF5)
    else if ( mat->version == MAT_FT_MAT73 )
        return Mat_VarWrite73(mat,matvar,compress);
#endif

    return 1;
}

/* -------------------------------
 * ---------- mat4.c
 * -------------------------------
 */
/** @file mat4.c
 * Matlab MAT version 4 file functions
 * @ingroup MAT
 */

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <limits.h>
#if defined(__GLIBC__)
#include <endian.h>
#endif

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
Mat_Create4(const char* matname)
{
    FILE *fp = NULL;
    mat_t *mat = NULL;
    int byteswap;

#if defined(__GLIBC__)
#if (__BYTE_ORDER == __LITTLE_ENDIAN)
    byteswap = 0;
#elif (__BYTE_ORDER == __BIG_ENDIAN)
    byteswap = 1;
#else
    return NULL;
#endif
#elif defined(_BIG_ENDIAN) && !defined(_LITTLE_ENDIAN)
    byteswap = 1;
#elif defined(_LITTLE_ENDIAN) && !defined(_BIG_ENDIAN)
    byteswap = 0;
#elif defined(__sparc) || defined(__sparc__) || defined(_POWER) || defined(__powerpc__) || \
      defined(__ppc__) || defined(__hpux) || defined(_MIPSEB) || defined(_POWER) || defined(__s390__)
    byteswap = 1;
#elif defined(__i386__) || defined(__alpha__) || defined(__ia64) || defined(__ia64__) || \
      defined(_M_IX86) || defined(_M_IA64) || defined(_M_ALPHA) || defined(__amd64) || \
      defined(__amd64__) || defined(_M_AMD64) || defined(__x86_64) || defined(__x86_64__) || \
      defined(_M_X64) || defined(__bfin__)
    byteswap = 0;
#else
    return NULL;
#endif

    fp = fopen(matname,"wb");
    if ( !fp )
        return NULL;

    mat = (mat_t*)malloc(sizeof(*mat));
    if ( NULL == mat ) {
        fclose(fp);
        Mat_Critical("Couldn't allocate memory for the MAT file");
        return NULL;
    }

    mat->header        = NULL;
    mat->subsys_offset = NULL;
    mat->fp            = fp;
    mat->version       = MAT_FT_MAT4;
    mat->byteswap      = byteswap;
    mat->bof           = 0;
    mat->next_index    = 0;
    mat->refs_id       = -1;
    mat->filename      = strdup_printf("%s",matname);
    mat->mode          = 0;

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
Mat_VarWrite4(mat_t *mat,matvar_t *matvar)
{
    typedef struct {
        mat_int32_t type;
        mat_int32_t mrows;
        mat_int32_t ncols;
        mat_int32_t imagf;
        mat_int32_t namelen;
    } Fmatrix;

    mat_int32_t nmemb = 1, i;
    Fmatrix x;

    if ( NULL == mat || NULL == matvar || NULL == matvar->name || matvar->rank != 2 )
        return -1;

    /* FIXME: SEEK_END is not Guaranteed by the C standard */
    (void)fseek((FILE*)mat->fp,0,SEEK_END);         /* Always write at end of file */

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
            return 2;
    }

    if ( mat->byteswap )
        x.type += 1000;

    x.namelen = (mat_int32_t)strlen(matvar->name) + 1;

    switch ( matvar->class_type ) {
        case MAT_C_CHAR:
            x.type++;
            /* Fall through */
        case MAT_C_DOUBLE:
        case MAT_C_SINGLE:
        case MAT_C_INT32:
        case MAT_C_INT16:
        case MAT_C_UINT16:
        case MAT_C_UINT8:
            for ( i = 0; i < matvar->rank; i++ ) {
                mat_int32_t dim;
                dim = (mat_int32_t)matvar->dims[i];
                nmemb *= dim;
            }

            x.mrows = (mat_int32_t)matvar->dims[0];
            x.ncols = (mat_int32_t)matvar->dims[1];
            x.imagf = matvar->isComplex ? 1 : 0;
            fwrite(&x, sizeof(Fmatrix), 1, (FILE*)mat->fp);
            fwrite(matvar->name, sizeof(char), x.namelen, (FILE*)mat->fp);
            if (matvar->isComplex) {
                mat_complex_split_t *complex_data;

                complex_data = (mat_complex_split_t*)matvar->data;
                fwrite(complex_data->Re, matvar->data_size, nmemb, (FILE*)mat->fp);
                fwrite(complex_data->Im, matvar->data_size, nmemb, (FILE*)mat->fp);
            }
            else {
                fwrite(matvar->data, matvar->data_size, nmemb, (FILE*)mat->fp);
            }
            break;
        case MAT_C_SPARSE:
        {
            mat_sparse_t* sparse;
            double tmp;
            int i, j;
            size_t stride = Mat_SizeOf(matvar->data_type);
#if !defined(EXTENDED_SPARSE)
            if ( MAT_T_DOUBLE != matvar->data_type )
                break;
#endif

            sparse = (mat_sparse_t*)matvar->data;
            x.type += 2;
            x.mrows = sparse->njc > 0 ? sparse->jc[sparse->njc - 1] + 1 : 1;
            x.ncols = matvar->isComplex ? 4 : 3;
            x.imagf = 0;

            fwrite(&x, sizeof(Fmatrix), 1, (FILE*)mat->fp);
            fwrite(matvar->name, sizeof(char), x.namelen, (FILE*)mat->fp);

            for ( i = 0; i < sparse->njc - 1; i++ ) {
                for ( j = sparse->jc[i];
                      j < sparse->jc[i + 1] && j < sparse->ndata; j++ ) {
                    tmp = sparse->ir[j] + 1;
                    fwrite(&tmp, sizeof(double), 1, (FILE*)mat->fp);
                }
            }
            tmp = matvar->dims[0];
            fwrite(&tmp, sizeof(double), 1, (FILE*)mat->fp);
            for ( i = 0; i < sparse->njc - 1; i++ ) {
                for ( j = sparse->jc[i];
                      j < sparse->jc[i + 1] && j < sparse->ndata; j++ ) {
                    tmp = i + 1;
                    fwrite(&tmp, sizeof(double), 1, (FILE*)mat->fp);
                }
            }
            tmp = matvar->dims[1];
            fwrite(&tmp, sizeof(double), 1, (FILE*)mat->fp);
            tmp = 0.;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;
                char* re, *im;

                complex_data = (mat_complex_split_t*)sparse->data;
                re = (char*)complex_data->Re;
                im = (char*)complex_data->Im;
                for ( i = 0; i < sparse->njc - 1; i++ ) {
                    for ( j = sparse->jc[i];
                          j < sparse->jc[i + 1] && j < sparse->ndata; j++ ) {
                        fwrite(re + j*stride, stride, 1, (FILE*)mat->fp);
                    }
                }
                fwrite(&tmp, stride, 1, (FILE*)mat->fp);
                for ( i = 0; i < sparse->njc - 1; i++ ) {
                    for ( j = sparse->jc[i];
                          j < sparse->jc[i + 1] && j < sparse->ndata; j++ ) {
                        fwrite(im + j*stride, stride, 1, (FILE*)mat->fp);
                    }
                }
            } else {
                char *data = (char*)sparse->data;
                for ( i = 0; i < sparse->njc - 1; i++ ) {
                    for ( j = sparse->jc[i];
                          j < sparse->jc[i + 1] && j < sparse->ndata; j++ ) {
                        fwrite(data + j*stride, stride, 1, (FILE*)mat->fp);
                    }
                }
            }
            fwrite(&tmp, stride, 1, (FILE*)mat->fp);
            break;
        }
        default:
            break;
    }

    return 0;
}

/** @if mat_devman
 * @brief Reads the data of a version 4 MAT file variable
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar MAT variable pointer to read the data
 * @endif
 */
static void
Read4(mat_t *mat,matvar_t *matvar)
{
    unsigned int N;

    (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);

    N = matvar->dims[0]*matvar->dims[1];
    switch ( matvar->class_type ) {
        case MAT_C_DOUBLE:
            matvar->data_size = sizeof(double);
            matvar->nbytes    = N*matvar->data_size;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                complex_data = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                if ( complex_data != NULL ) {
                    complex_data->Re = malloc(matvar->nbytes);
                    complex_data->Im = malloc(matvar->nbytes);
                    matvar->data     = complex_data;
                    if ( complex_data->Re != NULL && complex_data->Im != NULL ) {
                        ReadDoubleData(mat, (double*)complex_data->Re, matvar->data_type, N);
                        ReadDoubleData(mat, (double*)complex_data->Im, matvar->data_type, N);
                    }
                }
            } else {
                matvar->data = malloc(matvar->nbytes);
                if ( matvar->data != NULL )
                    ReadDoubleData(mat, (double*)matvar->data, matvar->data_type, N);
            }
            /* Update data type to match format of matvar->data */
            matvar->data_type = MAT_T_DOUBLE;
            break;
        case MAT_C_CHAR:
            matvar->data_size = 1;
            matvar->nbytes = N;
            matvar->data = malloc(matvar->nbytes);
            if ( NULL == matvar->data )
                Mat_Critical("Memory allocation failure");
            else
                ReadUInt8Data(mat,(mat_uint8_t*)matvar->data,matvar->data_type,N);
            matvar->data_type = MAT_T_UINT8;
            break;
        case MAT_C_SPARSE:
            matvar->data_size = sizeof(mat_sparse_t);
            matvar->data      = malloc(matvar->data_size);
            if ( matvar->data == NULL )
                Mat_Critical("Memory allocation failure");
            else {
                double tmp;
                int i;
                mat_sparse_t* sparse;
                long fpos;
                enum matio_types data_type = MAT_T_DOUBLE;

                /* matvar->dims[1] either is 3 for real or 4 for complex sparse */
                matvar->isComplex = matvar->dims[1] == 4 ? 1 : 0;
                sparse = (mat_sparse_t*)matvar->data;
                sparse->nir = matvar->dims[0] - 1;
                sparse->nzmax = sparse->nir;
                sparse->ir = (mat_int32_t*)malloc(sparse->nir*sizeof(mat_int32_t));
                if ( sparse->ir != NULL ) {
                    ReadInt32Data(mat, sparse->ir, data_type, sparse->nir);
                    for ( i = 0; i < sparse->nir; i++ )
                        sparse->ir[i] = sparse->ir[i] - 1;
                } else {
                    free(matvar->data);
                    matvar->data = NULL;
                    Mat_Critical("Memory allocation failure");
                    return;
                }
                ReadDoubleData(mat, &tmp, data_type, 1);
                matvar->dims[0] = tmp;

                fpos = ftell((FILE*)mat->fp);
                if ( fpos == -1L ) {
                    free(sparse->ir);
                    free(matvar->data);
                    matvar->data = NULL;
                    Mat_Critical("Couldn't determine file position");
                    return;
                }
                (void)fseek((FILE*)mat->fp,sparse->nir*Mat_SizeOf(data_type),
                    SEEK_CUR);
                ReadDoubleData(mat, &tmp, data_type, 1);
                if ( tmp > INT_MAX-1 || tmp < 0 ) {
                    free(sparse->ir);
                    free(matvar->data);
                    matvar->data = NULL;
                    Mat_Critical("Invalid column dimension for sparse matrix");
                    return;
                }
                matvar->dims[1] = tmp < 0 ? 0 : ( tmp > INT_MAX-1 ? INT_MAX-1 : (size_t)tmp );
                (void)fseek((FILE*)mat->fp,fpos,SEEK_SET);
                if ( matvar->dims[1] > INT_MAX-1 ) {
                    free(sparse->ir);
                    free(matvar->data);
                    matvar->data = NULL;
                    Mat_Critical("Invalid column dimension for sparse matrix");
                    return;
                }
                sparse->njc = (int)matvar->dims[1] + 1;
                sparse->jc = (mat_int32_t*)malloc(sparse->njc*sizeof(mat_int32_t));
                if ( sparse->jc != NULL ) {
                    mat_int32_t *jc;
                    jc = (mat_int32_t*)malloc(sparse->nir*sizeof(mat_int32_t));
                    if ( jc != NULL ) {
                        int j = 0;
                        sparse->jc[0] = 0;
                        ReadInt32Data(mat, jc, data_type, sparse->nir);
                        for ( i = 1; i < sparse->njc-1; i++ ) {
                            while ( j < sparse->nir && jc[j] <= i )
                                j++;
                            sparse->jc[i] = j;
                        }
                        free(jc);
                        /* terminating nnz */
                        sparse->jc[sparse->njc-1] = sparse->nir;
                    } else {
                        free(sparse->jc);
                        free(sparse->ir);
                        free(matvar->data);
                        matvar->data = NULL;
                        Mat_Critical("Memory allocation failure");
                        return;
                    }
                } else {
                    free(sparse->ir);
                    free(matvar->data);
                    matvar->data = NULL;
                    Mat_Critical("Memory allocation failure");
                    return;
                }
                ReadDoubleData(mat, &tmp, data_type, 1);
                sparse->ndata = sparse->nir;
                data_type = matvar->data_type;
                if ( matvar->isComplex ) {
                    mat_complex_split_t *complex_data;

                    complex_data = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                    if ( complex_data != NULL ) {
                        complex_data->Re = malloc(sparse->ndata*Mat_SizeOf(data_type));
                        complex_data->Im = malloc(sparse->ndata*Mat_SizeOf(data_type));
                        sparse->data     = complex_data;
                        if ( complex_data->Re != NULL && complex_data->Im != NULL ) {
#if defined(EXTENDED_SPARSE)
                            switch ( data_type ) {
                                case MAT_T_DOUBLE:
                                    ReadDoubleData(mat, (double*)complex_data->Re,
                                        data_type, sparse->ndata);
                                    ReadDoubleData(mat, &tmp, data_type, 1);
                                    ReadDoubleData(mat, (double*)complex_data->Im,
                                        data_type, sparse->ndata);
                                    ReadDoubleData(mat, &tmp, data_type, 1);
                                    break;
                                case MAT_T_SINGLE:
                                {
                                    float tmp2;
                                    ReadSingleData(mat, (float*)complex_data->Re,
                                        data_type, sparse->ndata);
                                    ReadSingleData(mat, &tmp2, data_type, 1);
                                    ReadSingleData(mat, (float*)complex_data->Im,
                                        data_type, sparse->ndata);
                                    ReadSingleData(mat, &tmp2, data_type, 1);
                                    break;
                                }
                                case MAT_T_INT32:
                                {
                                    mat_int32_t tmp2;
                                    ReadInt32Data(mat, (mat_int32_t*)complex_data->Re,
                                        data_type, sparse->ndata);
                                    ReadInt32Data(mat, &tmp2, data_type, 1);
                                    ReadInt32Data(mat, (mat_int32_t*)complex_data->Im,
                                        data_type, sparse->ndata);
                                    ReadInt32Data(mat, &tmp2, data_type, 1);
                                    break;
                                }
                                case MAT_T_INT16:
                                {
                                    mat_int16_t tmp2;
                                    ReadInt16Data(mat, (mat_int16_t*)complex_data->Re,
                                        data_type, sparse->ndata);
                                    ReadInt16Data(mat, &tmp2, data_type, 1);
                                    ReadInt16Data(mat, (mat_int16_t*)complex_data->Im,
                                        data_type, sparse->ndata);
                                    ReadInt16Data(mat, &tmp2, data_type, 1);
                                    break;
                                }
                                case MAT_T_UINT16:
                                {
                                    mat_uint16_t tmp2;
                                    ReadUInt16Data(mat, (mat_uint16_t*)complex_data->Re,
                                        data_type, sparse->ndata);
                                    ReadUInt16Data(mat, &tmp2, data_type, 1);
                                    ReadUInt16Data(mat, (mat_uint16_t*)complex_data->Im,
                                        data_type, sparse->ndata);
                                    ReadUInt16Data(mat, &tmp2, data_type, 1);
                                    break;
                                }
                                case MAT_T_UINT8:
                                {
                                    mat_uint8_t tmp2;
                                    ReadUInt8Data(mat, (mat_uint8_t*)complex_data->Re,
                                        data_type, sparse->ndata);
                                    ReadUInt8Data(mat, &tmp2, data_type, 1);
                                    ReadUInt8Data(mat, (mat_uint8_t*)complex_data->Im,
                                        data_type, sparse->ndata);
                                    ReadUInt8Data(mat, &tmp2, data_type, 1);
                                    break;
                                }
                                default:
                                    free(complex_data->Re);
                                    free(complex_data->Im);
                                    free(complex_data);
                                    free(sparse->jc);
                                    free(sparse->ir);
                                    free(matvar->data);
                                    matvar->data = NULL;
                                    Mat_Critical("Read4: %d is not a supported data type for ",
                                        "extended sparse", data_type);
                                    return;
                            }
#else
                            ReadDoubleData(mat, (double*)complex_data->Re,
                                data_type, sparse->ndata);
                            ReadDoubleData(mat, &tmp, data_type, 1);
                            ReadDoubleData(mat, (double*)complex_data->Im,
                                data_type, sparse->ndata);
                            ReadDoubleData(mat, &tmp, data_type, 1);
#endif
                        }
                    }
                } else {
                    sparse->data = malloc(sparse->ndata*Mat_SizeOf(data_type));
                    if ( sparse->data != NULL ) {
#if defined(EXTENDED_SPARSE)
                        switch ( data_type ) {
                            case MAT_T_DOUBLE:
                                ReadDoubleData(mat, (double*)sparse->data,
                                    data_type, sparse->ndata);
                                ReadDoubleData(mat, &tmp, data_type, 1);
                                break;
                            case MAT_T_SINGLE:
                            {
                                float tmp2;
                                ReadSingleData(mat, (float*)sparse->data,
                                    data_type, sparse->ndata);
                                ReadSingleData(mat, &tmp2, data_type, 1);
                                break;
                            }
                            case MAT_T_INT32:
                            {
                                mat_int32_t tmp2;
                                ReadInt32Data(mat, (mat_int32_t*)sparse->data,
                                    data_type, sparse->ndata);
                                ReadInt32Data(mat, &tmp2, data_type, 1);
                                break;
                            }
                            case MAT_T_INT16:
                            {
                                mat_int16_t tmp2;
                                ReadInt16Data(mat, (mat_int16_t*)sparse->data,
                                    data_type, sparse->ndata);
                                ReadInt16Data(mat, &tmp2, data_type, 1);
                                break;
                            }
                            case MAT_T_UINT16:
                            {
                                mat_uint16_t tmp2;
                                ReadUInt16Data(mat, (mat_uint16_t*)sparse->data,
                                    data_type, sparse->ndata);
                                ReadUInt16Data(mat, &tmp2, data_type, 1);
                                break;
                            }
                            case MAT_T_UINT8:
                            {
                                mat_uint8_t tmp2;
                                ReadUInt8Data(mat, (mat_uint8_t*)sparse->data,
                                    data_type, sparse->ndata);
                                ReadUInt8Data(mat, &tmp2, data_type, 1);
                                break;
                            }
                            default:
                                free(sparse->data);
                                free(sparse->jc);
                                free(sparse->ir);
                                free(matvar->data);
                                matvar->data = NULL;
                                Mat_Critical("Read4: %d is not a supported data type for ",
                                    "extended sparse", data_type);
                                return;
                        }
#else
                        ReadDoubleData(mat, (double*)sparse->data, data_type, sparse->ndata);
                        ReadDoubleData(mat, &tmp, data_type, 1);
#endif
                    } else {
                        free(sparse->jc);
                        free(sparse->ir);
                        free(matvar->data);
                        matvar->data = NULL;
                        Mat_Critical("Memory allocation failure");
                        return;
                    }
                }
                break;
            }
        default:
            Mat_Critical("MAT V4 data type error");
            return;
    }

    return;
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
ReadData4(mat_t *mat,matvar_t *matvar,void *data,
      int *start,int *stride,int *edge)
{
    int err = 0;
    enum matio_classes class_type = MAT_C_EMPTY;

    (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);

    switch( matvar->data_type ) {
        case MAT_T_DOUBLE:
            class_type = MAT_C_DOUBLE;
            break;
        case MAT_T_SINGLE:
            class_type = MAT_C_SINGLE;
            break;
        case MAT_T_INT32:
            class_type = MAT_C_INT32;
            break;
        case MAT_T_INT16:
            class_type = MAT_C_INT16;
            break;
        case MAT_T_UINT16:
            class_type = MAT_C_UINT16;
            break;
        case MAT_T_UINT8:
            class_type = MAT_C_UINT8;
            break;
        default:
            return 1;
    }

    if ( matvar->rank == 2 ) {
        if ( stride[0]*(edge[0]-1)+start[0]+1 > matvar->dims[0] )
            err = 1;
        else if ( stride[1]*(edge[1]-1)+start[1]+1 > matvar->dims[1] )
            err = 1;
        if ( matvar->isComplex ) {
            mat_complex_split_t *cdata = (mat_complex_split_t*)data;
            long nbytes = edge[0]*edge[1]*Mat_SizeOf(matvar->data_type);

            ReadDataSlab2(mat,cdata->Re,class_type,matvar->data_type,
                    matvar->dims,start,stride,edge);
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos+nbytes,SEEK_SET);
            ReadDataSlab2(mat,cdata->Im,class_type,
                matvar->data_type,matvar->dims,start,stride,edge);
        } else {
            ReadDataSlab2(mat,data,class_type,matvar->data_type,
                    matvar->dims,start,stride,edge);
        }
    } else if ( matvar->isComplex ) {
        int i;
        mat_complex_split_t *cdata = (mat_complex_split_t*)data;
        long nbytes = Mat_SizeOf(matvar->data_type);

        for ( i = 0; i < matvar->rank; i++ )
            nbytes *= edge[i];

        ReadDataSlabN(mat,cdata->Re,class_type,matvar->data_type,
            matvar->rank,matvar->dims,start,stride,edge);
        (void)fseek((FILE*)mat->fp,matvar->internal->datapos+nbytes,SEEK_SET);
        ReadDataSlabN(mat,cdata->Im,class_type,matvar->data_type,
            matvar->rank,matvar->dims,start,stride,edge);
    } else {
        ReadDataSlabN(mat,data,class_type,matvar->data_type,
            matvar->rank,matvar->dims,start,stride,edge);
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
Mat_VarReadDataLinear4(mat_t *mat,matvar_t *matvar,void *data,int start,
                       int stride,int edge)
{
    size_t i, nmemb = 1;
    int err = 0;

    (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);

    matvar->data_size = Mat_SizeOf(matvar->data_type);

    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];

    if ( stride*(edge-1)+start+1 > nmemb ) {
        return 1;
    }
    if ( matvar->isComplex ) {
            mat_complex_split_t *complex_data = (mat_complex_split_t*)data;
            long nbytes = nmemb*matvar->data_size;

            ReadDataSlab1(mat,complex_data->Re,matvar->class_type,
                          matvar->data_type,start,stride,edge);
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos+nbytes,SEEK_SET);
            ReadDataSlab1(mat,complex_data->Im,matvar->class_type,
                          matvar->data_type,start,stride,edge);
    } else {
        ReadDataSlab1(mat,data,matvar->class_type,matvar->data_type,start,
                      stride,edge);
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
    int       tmp,M,O,data_type,class_type;
    long      nBytes;
    size_t    err;
    matvar_t *matvar = NULL;
    union {
        mat_uint32_t u;
        mat_uint8_t  c[4];
    } endian;

    if ( mat == NULL || mat->fp == NULL )
        return NULL;
    else if ( NULL == (matvar = Mat_VarCalloc()) )
        return NULL;

    matvar->internal->fp   = mat;
    matvar->internal->fpos = ftell((FILE*)mat->fp);
    if ( matvar->internal->fpos == -1L ) {
        Mat_VarFree(matvar);
        Mat_Critical("Couldn't determine file position");
        return NULL;
    }

    err = fread(&tmp,sizeof(int),1,(FILE*)mat->fp);
    if ( !err ) {
        Mat_VarFree(matvar);
        return NULL;
    }

    endian.u = 0x01020304;

    /* See if MOPT may need byteswapping */
    if ( tmp < 0 || tmp > 4052 ) {
        if ( Mat_int32Swap(&tmp) > 4052 ) {
            Mat_VarFree(matvar);
            return NULL;
        }
    }

    M = floor(tmp / 1000.0);
    tmp -= M*1000;
    O = floor(tmp / 100.0);
    tmp -= O*100;
    data_type = floor(tmp / 10.0);
    tmp -= data_type*10;
    class_type = floor(tmp / 1.0);

    switch ( M ) {
        case 0:
            /* IEEE little endian */
            mat->byteswap = (endian.c[0] != 4);
            break;
        case 1:
            /* IEEE big endian */
            mat->byteswap = (endian.c[0] != 1);
            break;
        default:
            /* VAX, Cray, or bogus */
            Mat_VarFree(matvar);
            return NULL;
    }
    /* O must be zero */
    if ( 0 != O ) {
        Mat_VarFree(matvar);
        return NULL;
    }
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
    matvar->dims = (size_t*)malloc(2*sizeof(*matvar->dims));
    if ( NULL == matvar->dims ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    err = fread(&tmp,sizeof(int),1,(FILE*)mat->fp);
    if ( mat->byteswap )
        Mat_int32Swap(&tmp);
    matvar->dims[0] = tmp;
    if ( !err ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    err = fread(&tmp,sizeof(int),1,(FILE*)mat->fp);
    if ( mat->byteswap )
        Mat_int32Swap(&tmp);
    matvar->dims[1] = tmp;
    if ( !err ) {
        Mat_VarFree(matvar);
        return NULL;
    }

    err = fread(&(matvar->isComplex),sizeof(int),1,(FILE*)mat->fp);
    if ( !err ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    err = fread(&tmp,sizeof(int),1,(FILE*)mat->fp);
    if ( !err ) {
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
    matvar->name = (char*)malloc(tmp);
    if ( NULL == matvar->name ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    err = fread(matvar->name,1,tmp,(FILE*)mat->fp);
    if ( !err ) {
        Mat_VarFree(matvar);
        return NULL;
    }

    matvar->internal->datapos = ftell((FILE*)mat->fp);
    if ( matvar->internal->datapos == -1L ) {
        Mat_VarFree(matvar);
        Mat_Critical("Couldn't determine file position");
        return NULL;
    }
    nBytes = matvar->dims[0]*matvar->dims[1]*Mat_SizeOf(matvar->data_type);
    if ( matvar->isComplex )
        nBytes *= 2;
    (void)fseek((FILE*)mat->fp,nBytes,SEEK_CUR);

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
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <time.h>

/** Get type from tag */
#define TYPE_FROM_TAG(a)          (enum matio_types)((a) & 0x000000ff)
/** Get class from array flag */
#define CLASS_FROM_ARRAY_FLAGS(a) (enum matio_classes)((a) & 0x000000ff)
/** Class type mask */
#define CLASS_TYPE_MASK           0x000000ff

static mat_complex_split_t null_complex_data = {NULL,NULL};

/*
 * -------------------------------------------------------------
 *   Private Functions
 * -------------------------------------------------------------
 */

/** @brief determines the number of bytes needed to store the given struct field
 *
 * @ingroup mat_internal
 * @param matvar field of a structure
 * @return the number of bytes needed to store the struct field
 */
static size_t
GetStructFieldBufSize(matvar_t *matvar)
{
    size_t nBytes = 0, data_bytes = 0;
    size_t tag_size = 8, array_flags_size = 8;
    int    nmemb = 1, i;

    if ( matvar == NULL )
        return nBytes;

    /* Add the Array Flags tag and space to the number of bytes */
    nBytes += tag_size + array_flags_size;

    /* In a struct field, the name is just a tag with 0 bytes */
    nBytes += tag_size;

    /* Add rank and dimensions, padded to an 8 byte block */
    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];
    if ( matvar->rank % 2 )
        nBytes += tag_size + matvar->rank*4 + 4;
    else
        nBytes += tag_size + matvar->rank*4;

    switch ( matvar->class_type ) {
    case MAT_C_STRUCT:
    {
        matvar_t **fields = (matvar_t**)matvar->data;
        int i, nfields = 0;
        size_t maxlen = 0;

        nfields = matvar->internal->num_fields;
        for ( i = 0; i < nfields; i++ ) {
            char *fieldname = matvar->internal->fieldnames[i];
            if ( NULL != fieldname && strlen(fieldname) > maxlen )
                maxlen = strlen(fieldname);
        }
        maxlen++;
        while ( nfields*maxlen % 8 != 0 )
            maxlen++;

        nBytes += tag_size + tag_size + maxlen*nfields;

        /* FIXME: Add bytes for the fieldnames */
        if ( NULL != fields && nfields > 0 ) {
            for ( i = 0; i < nfields*nmemb; i++ )
                nBytes += tag_size + GetStructFieldBufSize(fields[i]);
        }
        break;
    }
    case MAT_C_CELL:
    {
        matvar_t **cells = (matvar_t**)matvar->data;
        int i, ncells;

        if ( matvar->nbytes == 0 || matvar->data_size == 0 )
            break;

        ncells = matvar->nbytes / matvar->data_size;

        if ( NULL != cells && ncells > 0 ) {
            for ( i = 0; i < ncells; i++ )
                nBytes += tag_size + GetCellArrayFieldBufSize(cells[i]);
        }
        break;
    }
    case MAT_C_SPARSE:
    {
        mat_sparse_t *sparse = (mat_sparse_t*)matvar->data;

        data_bytes = sparse->nir*sizeof(mat_int32_t);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;

        data_bytes = sparse->njc*sizeof(mat_int32_t);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;

        data_bytes = sparse->ndata*Mat_SizeOf(matvar->data_type);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;

        if ( matvar->isComplex )
            nBytes += tag_size + data_bytes;

        break;
    }
    case MAT_C_CHAR:
        if ( MAT_T_UINT8 == matvar->data_type ||
             MAT_T_INT8 == matvar->data_type )
            data_bytes = nmemb*Mat_SizeOf(MAT_T_UINT16);
        else
            data_bytes = nmemb*Mat_SizeOf(matvar->data_type);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;
        if ( matvar->isComplex )
            nBytes += tag_size + data_bytes;
        break;
    default:
        data_bytes = nmemb*Mat_SizeOf(matvar->data_type);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;
        if ( matvar->isComplex )
            nBytes += tag_size + data_bytes;
    } /* switch ( matvar->class_type ) */

    return nBytes;
}

/** @brief determines the number of bytes needed to store the cell array element
 *
 * @ingroup mat_internal
 * @param matvar MAT variable
 * @return the number of bytes needed to store the variable
 */
static size_t
GetCellArrayFieldBufSize(matvar_t *matvar)
{
    size_t nBytes = 0, data_bytes;
    size_t tag_size = 8, array_flags_size = 8;
    int    nmemb = 1, i;

    if ( matvar == NULL )
        return nBytes;

    /* Add the Array Flags tag and space to the number of bytes */
    nBytes += tag_size + array_flags_size;

    /* In an element of a cell array, the name is just a tag with 0 bytes */
    nBytes += tag_size;

    /* Add rank and dimensions, padded to an 8 byte block */
    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];
    if ( matvar->rank % 2 )
        nBytes += tag_size + matvar->rank*4 + 4;
    else
        nBytes += tag_size + matvar->rank*4;

    switch ( matvar->class_type ) {
    case MAT_C_STRUCT:
    {
        matvar_t **fields = (matvar_t**)matvar->data;
        int i, nfields = 0;
        size_t maxlen = 0;

        nfields = matvar->internal->num_fields;
        for ( i = 0; i < nfields; i++ ) {
            char *fieldname = matvar->internal->fieldnames[i];
            if ( NULL != fieldname && strlen(fieldname) > maxlen )
                maxlen = strlen(fieldname);
        }
        maxlen++;
        while ( nfields*maxlen % 8 != 0 )
            maxlen++;

        nBytes += tag_size + tag_size + maxlen*nfields;

        if ( NULL != fields && nfields > 0 ) {
            for ( i = 0; i < nfields*nmemb; i++ )
                nBytes += tag_size + GetStructFieldBufSize(fields[i]);
        }
        break;
    }
    case MAT_C_CELL:
    {
        matvar_t **cells = (matvar_t**)matvar->data;
        int i, ncells;

        if ( matvar->nbytes == 0 || matvar->data_size == 0 )
            break;

        ncells = matvar->nbytes / matvar->data_size;

        if ( NULL != cells && ncells > 0 ) {
            for ( i = 0; i < ncells; i++ )
                nBytes += tag_size + GetCellArrayFieldBufSize(cells[i]);
        }
        break;
    }
    case MAT_C_SPARSE:
    {
        mat_sparse_t *sparse = (mat_sparse_t*)matvar->data;

        data_bytes = sparse->nir*sizeof(mat_int32_t);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;

        data_bytes = sparse->njc*sizeof(mat_int32_t);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;

        data_bytes = sparse->ndata*Mat_SizeOf(matvar->data_type);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;

        if ( matvar->isComplex )
            nBytes += tag_size + data_bytes;
        break;
    }
    case MAT_C_CHAR:
        if ( MAT_T_UINT8 == matvar->data_type ||
            MAT_T_INT8 == matvar->data_type )
            data_bytes = nmemb*Mat_SizeOf(MAT_T_UINT16);
        else
            data_bytes = nmemb*Mat_SizeOf(matvar->data_type);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;
        if ( matvar->isComplex )
            nBytes += tag_size + data_bytes;
        break;
    default:
        data_bytes = nmemb*Mat_SizeOf(matvar->data_type);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;
        if ( matvar->isComplex )
            nBytes += tag_size + data_bytes;
    } /* switch ( matvar->class_type ) */

    return nBytes;
}

#if defined(HAVE_ZLIB)
/** @brief determines the number of bytes needed to store the given variable
 *
 * @ingroup mat_internal
 * @param matvar MAT variable
 * @return the number of bytes needed to store the variable
 */
static size_t
GetEmptyMatrixMaxBufSize(const char *name,int rank)
{
    size_t nBytes = 0, len;
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
        if ( len % 8 )
            len = len + (8 - len % 8);
        nBytes += tag_size + len;
    }

    /* Add rank and dimensions, padded to an 8 byte block */
    if ( rank % 2 )
        nBytes += tag_size + rank*4 + 4;
    else
        nBytes += tag_size + rank*4;

    /* Data tag */
    nBytes += tag_size;

    return nBytes;
}

/** @brief determines the number of bytes needed to store the given variable
 *
 * @ingroup mat_internal
 * @param matvar MAT variable
 * @return the number of bytes needed to store the variable
 */
static size_t
GetMatrixMaxBufSize(matvar_t *matvar)
{
    size_t nBytes = 0, len, data_bytes;
    size_t tag_size = 8, array_flags_size = 8;
    int    nmemb = 1, i;

    if ( matvar == NULL )
        return nBytes;

    /* Add the Array Flags tag and space to the number of bytes */
    nBytes += tag_size + array_flags_size;

    /* Get size of variable name, pad it to an 8 byte block, and add it to nBytes */
    if ( NULL != matvar->name )
        len = strlen(matvar->name);
    else
        len=4;

    if ( len <= 4 ) {
        nBytes += tag_size;
    } else {
        if ( len % 8 )
            len = len + (8 - len % 8);
        nBytes += tag_size + len;
    }

    /* Add rank and dimensions, padded to an 8 byte block */
    for ( i = 0, len = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];
    if ( matvar->rank % 2 )
        nBytes += tag_size + matvar->rank*4 + 4;
    else
        nBytes += tag_size + matvar->rank*4;

    switch ( matvar->class_type ) {
    case MAT_C_STRUCT:
    {
        matvar_t **fields = (matvar_t**)matvar->data;
        int i, nfields = 0;
        size_t maxlen = 0;

        nfields = matvar->internal->num_fields;
        for ( i = 0; i < nfields; i++ ) {
            char *fieldname = matvar->internal->fieldnames[i];
            if ( NULL != fieldname && strlen(fieldname) > maxlen )
                maxlen = strlen(fieldname);
        }
        maxlen++;
        while ( nfields*maxlen % 8 != 0 )
            maxlen++;

        nBytes += tag_size + tag_size + maxlen*nfields;

        /* FIXME: Add bytes for the fieldnames */
        if ( NULL != fields && nfields > 0 ) {
            for ( i = 0; i < nfields*nmemb; i++ )
                nBytes += tag_size + GetStructFieldBufSize(fields[i]);
        }
        break;
    }
    case MAT_C_CELL:
    {
        matvar_t **cells = (matvar_t**)matvar->data;
        int i, ncells;

        if ( matvar->nbytes == 0 || matvar->data_size == 0 )
            break;

        ncells = matvar->nbytes / matvar->data_size;

        if ( NULL != cells && ncells > 0 ) {
            for ( i = 0; i < ncells; i++ )
                nBytes += tag_size + GetCellArrayFieldBufSize(cells[i]);
        }
        break;
    }
    case MAT_C_SPARSE:
    {
        mat_sparse_t *sparse = (mat_sparse_t*)matvar->data;

        data_bytes = sparse->nir*sizeof(mat_int32_t);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;

        data_bytes = sparse->njc*sizeof(mat_int32_t);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;

        data_bytes = sparse->ndata*Mat_SizeOf(matvar->data_type);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;

        if ( matvar->isComplex )
            nBytes += tag_size + data_bytes;

        break;
    }
    case MAT_C_CHAR:
        if ( MAT_T_UINT8 == matvar->data_type ||
            MAT_T_INT8 == matvar->data_type )
            data_bytes = nmemb*Mat_SizeOf(MAT_T_UINT16);
        else
            data_bytes = nmemb*Mat_SizeOf(matvar->data_type);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;
        if ( matvar->isComplex )
            nBytes += tag_size + data_bytes;
        break;
    default:
        data_bytes = nmemb*Mat_SizeOf(matvar->data_type);
        if ( data_bytes % 8 )
            data_bytes += (8 - (data_bytes % 8));
        nBytes += tag_size + data_bytes;
        if ( matvar->isComplex )
            nBytes += tag_size + data_bytes;
    } /* switch ( matvar->class_type ) */

    return nBytes;
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
Mat_Create5(const char *matname,const char *hdr_str)
{
    FILE *fp = NULL;
    mat_int16_t endian = 0, version;
    mat_t *mat = NULL;
    size_t err;
    time_t t;

    fp = fopen(matname,"wb");
    if ( !fp )
        return NULL;

    mat = (mat_t*)malloc(sizeof(*mat));
    if ( mat == NULL ) {
        fclose(fp);
        return NULL;
    }

    mat->fp            = NULL;
    mat->header        = NULL;
    mat->subsys_offset = NULL;
    mat->filename      = NULL;
    mat->version       = 0;
    mat->byteswap      = 0;
    mat->mode          = 0;
    mat->bof           = 0;
    mat->next_index    = 0;

    t = time(NULL);
    mat->fp       = fp;
    mat->filename = strdup_printf("%s",matname);
    mat->mode     = MAT_ACC_RDWR;
    mat->byteswap = 0;
    mat->header   = (char*)malloc(128*sizeof(char));
    mat->subsys_offset = (char*)malloc(8*sizeof(char));
    memset(mat->header,' ',128);
    if ( hdr_str == NULL ) {
        err = mat_snprintf(mat->header,116,"MATLAB 5.0 MAT-file, Platform: %s, "
                "Created by: libmatio v%d.%d.%d on %s", MATIO_PLATFORM,
                MATIO_MAJOR_VERSION, MATIO_MINOR_VERSION, MATIO_RELEASE_LEVEL,
                ctime(&t));
    } else {
        err = mat_snprintf(mat->header,116,"%s",hdr_str);
    }
    if ( err >= 116 )
        mat->header[115] = '\0'; /* Just to make sure it's NULL terminated */
    memset(mat->subsys_offset,' ',8);
    mat->version = (int)0x0100;
    endian = 0x4d49;

    version = 0x0100;

    err = fwrite(mat->header,1,116,(FILE*)mat->fp);
    err = fwrite(mat->subsys_offset,1,8,(FILE*)mat->fp);
    err = fwrite(&version,2,1,(FILE*)mat->fp);
    err = fwrite(&endian,2,1,(FILE*)mat->fp);

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
WriteCharData(mat_t *mat, void *data, int N,enum matio_types data_type)
{
    int nBytes = 0, i;
    size_t byteswritten = 0;
    mat_int8_t pad1 = 0;

    switch ( data_type ) {
        case MAT_T_UINT16:
        {
            nBytes = N*2;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            if ( NULL != data && N > 0 )
                fwrite(data,2,N,(FILE*)mat->fp);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_INT8:
        case MAT_T_UINT8:
        {
            mat_uint8_t *ptr;
            mat_uint16_t c;

            /* Matlab can't read MAT_C_CHAR as uint8, needs uint16 */
            nBytes = N*2;
            data_type = MAT_T_UINT16;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            ptr = (mat_uint8_t*)data;
            if ( NULL == ptr )
                break;
            for ( i = 0; i < N; i++ ) {
                c = (mat_uint16_t)*(char *)ptr;
                fwrite(&c,2,1,(FILE*)mat->fp);
                ptr++;
            }
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_UTF8:
        {
            mat_uint8_t *ptr;

            nBytes = N;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            ptr = (mat_uint8_t*)data;
            if ( NULL != ptr && nBytes > 0 )
                fwrite(ptr,1,nBytes,(FILE*)mat->fp);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_UNKNOWN:
        {
            /* Sometimes empty char data will have MAT_T_UNKNOWN, so just write
             * a data tag
             */
            nBytes = N*2;
            data_type = MAT_T_UINT16;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            break;
        }
        default:
            break;
    }
    byteswritten+=nBytes;
    return byteswritten;
}

#if defined(HAVE_ZLIB)
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
WriteCompressedCharData(mat_t *mat,z_streamp z,void *data,int N,
    enum matio_types data_type)
{
    int data_size, data_tag[2], byteswritten = 0;
    int buf_size = 1024, i;
    mat_uint8_t   buf[1024], pad[8] = {0,};

    if ((mat == NULL) || (mat->fp == NULL))
        return 0;

    switch ( data_type ) {
        case MAT_T_UINT16:
        {
            data_size = 2;
            data_tag[0] = MAT_T_UINT16;
            data_tag[1] = N*data_size;
            z->next_in  = ZLIB_BYTE_PTR(data_tag);
            z->avail_in = 8;
            do {
                z->next_out  = buf;
                z->avail_out = buf_size;
                deflate(z,Z_NO_FLUSH);
                byteswritten += fwrite(buf,1,buf_size-z->avail_out,(FILE*)mat->fp);
            } while ( z->avail_out == 0 );

            /* exit early if this is a empty data */
            if ( NULL == data || N < 1 )
                break;

            z->next_in  = (Bytef*)data;
            z->avail_in = data_size*N;
            do {
                z->next_out  = buf;
                z->avail_out = buf_size;
                deflate(z,Z_NO_FLUSH);
                byteswritten += fwrite(buf,1,buf_size-z->avail_out,(FILE*)mat->fp);
            } while ( z->avail_out == 0 );
            /* Add/Compress padding to pad to 8-byte boundary */
            if ( N*data_size % 8 ) {
                z->next_in  = pad;
                z->avail_in = 8 - (N*data_size % 8);
                do {
                    z->next_out  = buf;
                    z->avail_out = buf_size;
                    deflate(z,Z_NO_FLUSH);
                    byteswritten += fwrite(buf,1,buf_size-z->avail_out,(FILE*)mat->fp);
                } while ( z->avail_out == 0 );
            }
            break;
        }
        case MAT_T_INT8:
        case MAT_T_UINT8:
        {
            mat_uint8_t *ptr;
            mat_uint16_t c;

            /* Matlab can't read MAT_C_CHAR as uint8, needs uint16 */
            data_size   = 2;
            data_tag[0] = MAT_T_UINT16;
            data_tag[1] = N*data_size;
            z->next_in  = ZLIB_BYTE_PTR(data_tag);
            z->avail_in = 8;
            do {
                z->next_out  = buf;
                z->avail_out = buf_size;
                deflate(z,Z_NO_FLUSH);
                byteswritten += fwrite(buf,1,buf_size-z->avail_out,(FILE*)mat->fp);
            } while ( z->avail_out == 0 );

            /* exit early if this is a empty data */
            if ( NULL == data || N < 1 )
                break;

            z->next_in  = (Bytef*)data;
            z->avail_in = data_size*N;
            ptr = (mat_uint8_t*)data;
            for ( i = 0; i < N; i++ ) {
                c = (mat_uint16_t)*(char *)ptr;
                z->next_in  = ZLIB_BYTE_PTR(&c);
                z->avail_in = 2;
                do {
                    z->next_out  = buf;
                    z->avail_out = buf_size;
                    deflate(z,Z_NO_FLUSH);
                    byteswritten += fwrite(buf,1,buf_size-z->avail_out,(FILE*)mat->fp);
                } while ( z->avail_out == 0 );
                ptr++;
            }
            /* Add/Compress padding to pad to 8-byte boundary */
            if ( N*data_size % 8 ) {
                z->next_in  = pad;
                z->avail_in = 8 - (N*data_size % 8);
                do {
                    z->next_out  = buf;
                    z->avail_out = buf_size;
                    deflate(z,Z_NO_FLUSH);
                    byteswritten += fwrite(buf,1,buf_size-z->avail_out,(FILE*)mat->fp);
                } while ( z->avail_out == 0 );
            }
            break;
        }
        case MAT_T_UTF8:
        {
            data_size = 1;
            data_tag[0] = MAT_T_UTF8;
            data_tag[1] = N*data_size;
            z->next_in  = ZLIB_BYTE_PTR(data_tag);
            z->avail_in = 8;
            do {
                z->next_out  = buf;
                z->avail_out = buf_size;
                deflate(z,Z_NO_FLUSH);
                byteswritten += fwrite(buf,1,buf_size-z->avail_out,(FILE*)mat->fp);
            } while ( z->avail_out == 0 );

            /* exit early if this is a empty data */
            if ( NULL == data || N < 1 )
                break;

            z->next_in  = (Bytef*)data;
            z->avail_in = data_size*N;
            do {
                z->next_out  = buf;
                z->avail_out = buf_size;
                deflate(z,Z_NO_FLUSH);
                byteswritten += fwrite(buf,1,buf_size-z->avail_out,(FILE*)mat->fp);
            } while ( z->avail_out == 0 );
            /* Add/Compress padding to pad to 8-byte boundary */
            if ( N*data_size % 8 ) {
                z->next_in  = pad;
                z->avail_in = 8 - (N*data_size % 8);
                do {
                    z->next_out  = buf;
                    z->avail_out = buf_size;
                    deflate(z,Z_NO_FLUSH);
                    byteswritten += fwrite(buf,1,buf_size-z->avail_out,(FILE*)mat->fp);
                } while ( z->avail_out == 0 );
            }
            break;
        }
        case MAT_T_UNKNOWN:
        {
            /* Sometimes empty char data will have MAT_T_UNKNOWN, so just write
             * a data tag
             */
            data_size = 2;
            data_tag[0] = MAT_T_UINT16;
            data_tag[1] = N*data_size;
            z->next_in  = ZLIB_BYTE_PTR(data_tag);
            z->avail_in = 8;
            do {
                z->next_out  = buf;
                z->avail_out = buf_size;
                deflate(z,Z_NO_FLUSH);
                byteswritten += fwrite(buf,1,buf_size-z->avail_out,(FILE*)mat->fp);
            } while ( z->avail_out == 0 );
        }
        default:
            break;
    }
    return byteswritten;
}
#endif

/** @if mat_devman
 * @brief Writes empty characters to the MAT file
 *
 * This function uses the knowledge that the data is part of a character class
 * to avoid some pitfalls with Matlab listed below.
 *   @li Matlab character data cannot be unsigned 8-bit integers, it needs at
 *       least unsigned 16-bit integers
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param data character data to write
 * @param N Number of elements to write
 * @param data_type character data type (enum matio_types)
 * @return number of bytes written
 * @endif
 */
static size_t
WriteEmptyCharData(mat_t *mat, int N, enum matio_types data_type)
{
    int nBytes = 0, i;
    size_t byteswritten = 0;
    mat_int8_t pad1 = 0;

    switch ( data_type ) {
        case MAT_T_UINT8:
        case MAT_T_INT8:
            data_type = MAT_T_UINT16;
            /* Fall through: Matlab MAT_C_CHAR needs uint16 */
        case MAT_T_UINT16:
        {
            mat_uint16_t u16 = 0;
            nBytes = N*sizeof(mat_uint16_t);
            fwrite(&data_type,sizeof(mat_int32_t),1,(FILE*)mat->fp);
            fwrite(&nBytes,sizeof(mat_int32_t),1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&u16,sizeof(mat_uint16_t),1,(FILE*)mat->fp);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_UTF8:
        {
            mat_uint8_t u8 = 0;
            nBytes = N;
            fwrite(&data_type,sizeof(mat_int32_t),1,(FILE*)mat->fp);
            fwrite(&nBytes,sizeof(mat_int32_t),1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&u8,sizeof(mat_uint8_t),1,(FILE*)mat->fp);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,(FILE*)mat->fp);
            break;
        }
        default:
            break;
    }
    byteswritten+=nBytes;
    return byteswritten;
}

/** @if mat_devman
 * @brief Writes the data tags and empty data to the file
 *
 * Writes the data tags and empty data to the file to save space for the
 * variable when the actual data is written
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param N number of elements to write
 * @param data_type data type to write
 * @return Number of bytes written
 * @endif
 */
static size_t
WriteEmptyData(mat_t *mat,int N,enum matio_types data_type)
{
    int nBytes = 0, data_size, i;

    if ( (mat == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double d = 0.0;

            data_size = sizeof(double);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&d,data_size,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_SINGLE:
        {
            float f = 0.0;

            data_size = sizeof(float);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&f,data_size,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8 = 0;

            data_size = sizeof(mat_int8_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i8,data_size,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8 = 0;

            data_size = sizeof(mat_uint8_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui8,data_size,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16 = 0;

            data_size = sizeof(mat_int16_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i16,data_size,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16 = 0;

            data_size = sizeof(mat_uint16_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui16,data_size,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32 = 0;

            data_size = sizeof(mat_int32_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i32,data_size,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32 = 0;

            data_size = sizeof(mat_uint32_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui32,data_size,1,(FILE*)mat->fp);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_T_INT64:
        {
            mat_int64_t i64 = 0;

            data_size = sizeof(mat_int64_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i64,data_size,1,(FILE*)mat->fp);
            break;
        }
#endif
#ifdef HAVE_MATIO_UINT64_T
        case MAT_T_UINT64:
        {
            mat_uint64_t ui64 = 0;

            data_size = sizeof(mat_uint64_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui64,data_size,1,(FILE*)mat->fp);
            break;
        }
#endif
        default:
            nBytes = 0;
    }
    return nBytes;
}

#if defined(HAVE_ZLIB)
#if 0
static size_t
WriteCompressedEmptyData(mat_t *mat,z_streamp z,int N,
    enum matio_types data_type)
{
    int nBytes = 0, data_size, i;
    size_t byteswritten = 0;

    if ( (mat == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            mat_uint32_t uncomp_buf[32] = {0,};
            mat_uint32_t comp_buf[32] = {0,};
            double data_uncomp_buf[4] = {0.0,};

            data_size = sizeof(double);
            nBytes = N*data_size;
            uncomp_buf[0] = data_type;
            uncomp_buf[1] = 0;
            z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
            z->avail_in = 8;
            do {
                z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                z->avail_out = 32*sizeof(*comp_buf);
                deflate(z,Z_NO_FLUSH);
                byteswritten += fwrite(comp_buf,1,32*sizeof(*comp_buf)-z->avail_out,(FILE*)mat->fp);
            } while ( z->avail_out == 0 );
            for ( i = 0; i < N; i++ ) {
                z->next_in  = ZLIB_BYTE_PTR(data_uncomp_buf);
                z->avail_in = 8;
                do {
                    z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                    z->avail_out = 32*sizeof(*comp_buf);
                    deflate(z,Z_NO_FLUSH);
                    byteswritten += fwrite(comp_buf,32*sizeof(*comp_buf)-z->avail_out,1,(FILE*)mat->fp);
                } while ( z->avail_out == 0 );
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f = 0.0;

            data_size = sizeof(float);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&f,data_size,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8 = 0;

            data_size = sizeof(mat_int8_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i8,data_size,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8 = 0;

            data_size = sizeof(mat_uint8_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui8,data_size,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16 = 0;

            data_size = sizeof(mat_int16_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i16,data_size,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16 = 0;

            data_size = sizeof(mat_uint16_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui16,data_size,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32 = 0;

            data_size = sizeof(mat_int32_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i32,data_size,1,(FILE*)mat->fp);
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32 = 0;

            data_size = sizeof(mat_uint32_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui32,data_size,1,(FILE*)mat->fp);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_T_INT64:
        {
            mat_int64_t i64 = 0;

            data_size = sizeof(mat_int64_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i64,data_size,1,(FILE*)mat->fp);
            break;
        }
#endif
#ifdef HAVE_MATIO_UINT64_T
        case MAT_T_UINT64:
        {
            mat_uint64_t ui64 = 0;

            data_size = sizeof(mat_uint64_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,(FILE*)mat->fp);
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui64,data_size,1,(FILE*)mat->fp);
            break;
        }
#endif
        default:
            nBytes = 0;
    }
    return byteswritten;
}
#endif
#endif

/** @if mat_devman
 * @param Writes a 2-D slab of data to the MAT file
 *
 * @ingroup mat_internal
 * @fixme should return the number of bytes written, but currently returns 0
 * @param mat MAT file pointer
 * @param data pointer to the slab of data
 * @param data_type data type of the data (enum matio_types)
 * @param dims dimensions of the dataset
 * @param start index to start writing the data in each dimension
 * @param stride write data every @c stride elements
 * @param edge number of elements to write in each dimension
 * @return number of byteswritten, or -1 on error
 * @endif
 */
static int
WriteDataSlab2(mat_t *mat,void *data,enum matio_types data_type,size_t *dims,
    int *start,int *stride,int *edge)
{
    int nBytes = 0, data_size, i, j;
    long pos, row_stride, col_stride, pos2;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) ||
         (start == NULL) || (stride == NULL) || (edge    == NULL) ) {
        return 0;
    }

    switch ( data_type ) {
        case MAT_T_DOUBLE:
        {
            double *ptr;

            data_size = sizeof(double);
            ptr = (double *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell((FILE*)mat->fp);
                if ( pos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,(FILE*)mat->fp);
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR);
                }
                pos2 = ftell((FILE*)mat->fp);
                if ( pos2 == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                pos +=col_stride-pos2;
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float *ptr;

            data_size = sizeof(float);
            ptr = (float *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell((FILE*)mat->fp);
                if ( pos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,(FILE*)mat->fp);
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR);
                }
                pos2 = ftell((FILE*)mat->fp);
                if ( pos2 == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                pos +=col_stride-pos2;
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR);
            }
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_T_INT64:
        {
            mat_int64_t *ptr;

            data_size = sizeof(mat_int64_t);
            ptr = (mat_int64_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell((FILE*)mat->fp);
                if ( pos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,(FILE*)mat->fp);
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR);
                }
                pos2 = ftell((FILE*)mat->fp);
                if ( pos2 == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                pos +=col_stride-pos2;
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR);
            }
            break;
        }
#endif
#ifdef HAVE_MATIO_UINT64_T
        case MAT_T_UINT64:
        {
            mat_uint64_t *ptr;

            data_size = sizeof(mat_uint64_t);
            ptr = (mat_uint64_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell((FILE*)mat->fp);
                if ( pos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,(FILE*)mat->fp);
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR);
                }
                pos2 = ftell((FILE*)mat->fp);
                if ( pos2 == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                pos +=col_stride-pos2;
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR);
            }
            break;
        }
#endif
        case MAT_T_INT32:
        {
            mat_int32_t *ptr;

            data_size = sizeof(mat_int32_t);
            ptr = (mat_int32_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell((FILE*)mat->fp);
                if ( pos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,(FILE*)mat->fp);
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR);
                }
                pos2 = ftell((FILE*)mat->fp);
                if ( pos2 == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                pos +=col_stride-pos2;
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t *ptr;

            data_size = sizeof(mat_uint32_t);
            ptr = (mat_uint32_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell((FILE*)mat->fp);
                if ( pos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,(FILE*)mat->fp);
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR);
                }
                pos2 = ftell((FILE*)mat->fp);
                if ( pos2 == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                pos +=col_stride-pos2;
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t *ptr;

            data_size = sizeof(mat_int16_t);
            ptr = (mat_int16_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell((FILE*)mat->fp);
                if ( pos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,(FILE*)mat->fp);
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR);
                }
                pos2 = ftell((FILE*)mat->fp);
                if ( pos2 == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                pos +=col_stride-pos2;
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t *ptr;

            data_size = sizeof(mat_uint16_t);
            ptr = (mat_uint16_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell((FILE*)mat->fp);
                if ( pos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,(FILE*)mat->fp);
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR);
                }
                pos2 = ftell((FILE*)mat->fp);
                if ( pos2 == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                pos +=col_stride-pos2;
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t *ptr;

            data_size = sizeof(mat_int8_t);
            ptr = (mat_int8_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell((FILE*)mat->fp);
                if ( pos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,(FILE*)mat->fp);
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR);
                }
                pos2 = ftell((FILE*)mat->fp);
                if ( pos2 == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                pos +=col_stride-pos2;
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t *ptr;

            data_size = sizeof(mat_uint8_t);
            ptr = (mat_uint8_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell((FILE*)mat->fp);
                if ( pos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,(FILE*)mat->fp);
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR);
                }
                pos2 = ftell((FILE*)mat->fp);
                if ( pos2 == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                pos +=col_stride-pos2;
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        default:
            nBytes = 0;
    }
    return nBytes;
}

/** @if mat_devman
 * @param Writes a 2-D slab of character data to the MAT file
 *
 * This function uses the knowledge that the data is part of a character class
 * to avoid some pitfalls with Matlab listed below.
 *   @li Matlab character data cannot be unsigned 8-bit integers, it needs at
 *       least unsigned 16-bit integers
 * @ingroup mat_internal
 * @fixme should return the number of bytes written, but currently returns 0
 * @param mat MAT file pointer
 * @param data pointer to the slab of data
 * @param data_type data type of the data (enum matio_types)
 * @param dims dimensions of the dataset
 * @param start index to start writing the data in each dimension
 * @param stride write data every @c stride elements
 * @param edge number of elements to write in each dimension
 * @return number of byteswritten, or -1 on error
 * @endif
 */
static int
WriteCharDataSlab2(mat_t *mat,void *data,enum matio_types data_type,
    size_t *dims,int *start,int *stride,int *edge)
{
    int nBytes = 0, data_size, i, j;
    long pos, row_stride, col_stride, pos2;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) ||
         (start == NULL) || (stride == NULL) || (edge    == NULL) ) {
        return 0;
    }

    switch ( data_type ) {
        case MAT_T_UINT16:
        {
            mat_uint16_t *ptr;

            data_size = sizeof(mat_uint16_t);
            ptr = (mat_uint16_t*)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell((FILE*)mat->fp);
                if ( pos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,(FILE*)mat->fp);
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR);
                }
                pos2 = ftell((FILE*)mat->fp);
                if ( pos2 == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                pos +=col_stride-pos2;
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_T_INT8:
        case MAT_T_UINT8:
        {
            /* Matlab can't read MAT_C_CHAR as uint8, needs uint16 */
            mat_uint8_t *ptr;
            mat_uint16_t c;

            data_size = sizeof(mat_uint16_t);
            ptr = (mat_uint8_t*)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell((FILE*)mat->fp);
                if ( pos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++,ptr++ ) {
                    c = *ptr;
                    fwrite(&c,data_size,1,(FILE*)mat->fp);
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR);
                }
                pos2 = ftell((FILE*)mat->fp);
                if ( pos2 == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                pos +=col_stride-pos2;
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_T_UTF8:
        {
            mat_uint8_t *ptr;

            data_size = sizeof(mat_uint8_t);
            ptr = (mat_uint8_t*)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            (void)fseek((FILE*)mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell((FILE*)mat->fp);
                if ( pos == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                (void)fseek((FILE*)mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++,ptr++ ) {
                    fwrite(ptr,data_size,1,(FILE*)mat->fp);
                    (void)fseek((FILE*)mat->fp,row_stride,SEEK_CUR);
                }
                pos2 = ftell((FILE*)mat->fp);
                if ( pos2 == -1L ) {
                    Mat_Critical("Couldn't determine file position");
                    return -1;
                }
                pos +=col_stride-pos2;
                (void)fseek((FILE*)mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        default:
            nBytes = 0;
    }
    return nBytes;
}

/** @brief Writes the data buffer to the file
 *
 * @param mat MAT file pointer
 * @param data pointer to the data to write
 * @param N number of elements to write
 * @param data_type data type of the data
 * @return number of bytes written
 */
static int
WriteData(mat_t *mat,void *data,int N,enum matio_types data_type)
{
    int nBytes = 0, data_size;

    if ((mat == NULL) || (mat->fp == NULL) )
        return 0;

    data_size = Mat_SizeOf(data_type);
    nBytes    = N*data_size;
    fwrite(&data_type,4,1,(FILE*)mat->fp);
    fwrite(&nBytes,4,1,(FILE*)mat->fp);

    if ( data != NULL && N > 0 )
        fwrite(data,data_size,N,(FILE*)mat->fp);

    return nBytes;
}

#if defined(HAVE_ZLIB)
/* Compresses the data buffer and writes it to the file */
static size_t
WriteCompressedData(mat_t *mat,z_streamp z,void *data,int N,
    enum matio_types data_type)
{
    int nBytes = 0, data_size, data_tag[2], byteswritten = 0;
    int buf_size = 1024;
    mat_uint8_t   buf[1024], pad[8] = {0,};

    if ((mat == NULL) || (mat->fp == NULL))
        return 0;

    data_size = Mat_SizeOf(data_type);

    data_tag[0] = data_type;
    data_tag[1] = data_size*N;
    z->next_in  = ZLIB_BYTE_PTR(data_tag);
    z->avail_in = 8;
    do {
        z->next_out  = buf;
        z->avail_out = buf_size;
        deflate(z,Z_NO_FLUSH);
        byteswritten += fwrite(buf,1,buf_size-z->avail_out,(FILE*)mat->fp);
    } while ( z->avail_out == 0 );

    /* exit early if this is a empty data */
    if ( NULL == data || N < 1 )
        return byteswritten;

    z->next_in  = (Bytef*)data;
    z->avail_in = N*data_size;
    do {
        z->next_out  = buf;
        z->avail_out = buf_size;
        deflate(z,Z_NO_FLUSH);
        byteswritten += fwrite(buf,1,buf_size-z->avail_out,(FILE*)mat->fp);
    } while ( z->avail_out == 0 );
    /* Add/Compress padding to pad to 8-byte boundary */
    if ( N*data_size % 8 ) {
        z->next_in  = pad;
        z->avail_in = 8 - (N*data_size % 8);
        do {
            z->next_out  = buf;
            z->avail_out = buf_size;
            deflate(z,Z_NO_FLUSH);
            byteswritten += fwrite(buf,1,buf_size-z->avail_out,(FILE*)mat->fp);
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
ReadNextCell( mat_t *mat, matvar_t *matvar )
{
    size_t bytesread = 0;
    int ncells, i;
    matvar_t **cells = NULL;

    ncells = 1;
    for ( i = 0; i < matvar->rank; i++ )
        ncells *= matvar->dims[i];
    matvar->data_size = sizeof(matvar_t *);
    matvar->nbytes    = ncells*matvar->data_size;
    matvar->data      = malloc(matvar->nbytes);
    if ( !matvar->data ) {
        Mat_Critical("Couldn't allocate memory for %s->data",matvar->name);
        return bytesread;
    }
    cells = (matvar_t **)matvar->data;

    if ( matvar->compression ) {
#if defined(HAVE_ZLIB)
        mat_uint32_t uncomp_buf[16] = {0,};
        int      nbytes;
        mat_uint32_t array_flags;
        int err;

        for ( i = 0; i < ncells; i++ ) {
            cells[i] = Mat_VarCalloc();
            if ( NULL == cells[i] ) {
                Mat_Critical("Couldn't allocate memory for cell %d", i);
                continue;
            }

            cells[i]->internal->fpos = ftell((FILE*)mat->fp);
            if ( cells[i]->internal->fpos == -1L ) {
                Mat_Critical("Couldn't determine file position");
                continue;
            } else {
                cells[i]->internal->fpos -= matvar->internal->z->avail_in;
            }

            /* Read variable tag for cell */
            uncomp_buf[0] = 0;
            uncomp_buf[1] = 0;
            bytesread += InflateVarTag(mat,matvar,uncomp_buf);
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf+1);
            }
            nbytes = uncomp_buf[1];
            if ( !nbytes ) {
                /* empty cell */
                continue;
            } else if ( uncomp_buf[0] != MAT_T_MATRIX ) {
                Mat_VarFree(cells[i]);
                cells[i] = NULL;
                Mat_Critical("cells[%d], Uncompressed type not MAT_T_MATRIX",i);
                break;
            }
            cells[i]->compression = MAT_COMPRESSION_ZLIB;
            bytesread += InflateArrayFlags(mat,matvar,uncomp_buf);
            nbytes -= 16;
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf+1);
                (void)Mat_uint32Swap(uncomp_buf+2);
                (void)Mat_uint32Swap(uncomp_buf+3);
            }
            /* Array Flags */
            if ( uncomp_buf[0] == MAT_T_UINT32 ) {
               array_flags = uncomp_buf[2];
               cells[i]->class_type  = CLASS_FROM_ARRAY_FLAGS(array_flags);
               cells[i]->isComplex   = (array_flags & MAT_F_COMPLEX);
               cells[i]->isGlobal    = (array_flags & MAT_F_GLOBAL);
               cells[i]->isLogical   = (array_flags & MAT_F_LOGICAL);
               if ( cells[i]->class_type == MAT_C_SPARSE ) {
                   /* Need to find a more appropriate place to store nzmax */
                   cells[i]->nbytes      = uncomp_buf[3];
               }
            } else {
                Mat_Critical("Expected MAT_T_UINT32 for Array Tags, got %d",
                               uncomp_buf[0]);
                bytesread+=InflateSkip(mat,matvar->internal->z,nbytes);
            }
            bytesread += InflateDimensions(mat,matvar,uncomp_buf);
            nbytes -= 8;
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf+1);
            }
            /* Rank and Dimension */
            if ( uncomp_buf[0] == MAT_T_INT32 ) {
                int j = 0;

                cells[i]->rank = uncomp_buf[1];
                nbytes -= cells[i]->rank;
                cells[i]->rank /= 4;
                cells[i]->dims = (size_t*)malloc(cells[i]->rank*sizeof(*cells[i]->dims));
                if ( mat->byteswap ) {
                    for ( j = 0; j < cells[i]->rank; j++ )
                        cells[i]->dims[j] = Mat_uint32Swap(uncomp_buf+2+j);
                } else {
                    for ( j = 0; j < cells[i]->rank; j++ )
                        cells[i]->dims[j] = uncomp_buf[2+j];
                }
                if ( cells[i]->rank % 2 != 0 )
                    nbytes -= 4;
            }
            bytesread += InflateVarNameTag(mat,matvar,uncomp_buf);
            nbytes -= 8;
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf+1);
            }
            /* Handle cell elements written with a variable name */
            if ( uncomp_buf[1] > 0 ) {
                /* Name of variable */
                int len = 0;
                if ( uncomp_buf[0] == MAT_T_INT8 ) {    /* Name not in tag */
                    len = uncomp_buf[1];

                    if ( len % 8 > 0 )
                        len = len+(8-(len % 8));
                    cells[i]->name = (char*)malloc(len+1);
                    /* Inflate variable name */
                    bytesread += InflateVarName(mat,matvar,cells[i]->name,len);
                    cells[i]->name[len] = '\0';
                    nbytes -= len;
                } else if ( ((uncomp_buf[0] & 0x0000ffff) == MAT_T_INT8) &&
                           ((uncomp_buf[0] & 0xffff0000) != 0x00) ) {
                    /* Name packed in tag */
                    len = (uncomp_buf[0] & 0xffff0000) >> 16;
                    cells[i]->name = (char*)malloc(len+1);
                    memcpy(cells[i]->name,uncomp_buf+1,len);
                    cells[i]->name[len] = '\0';
                }
            }
            cells[i]->internal->z = (z_streamp)calloc(1,sizeof(z_stream));
            if ( cells[i]->internal->z != NULL ) {
                err = inflateCopy(cells[i]->internal->z,matvar->internal->z);
                if ( err == Z_OK ) {
                    cells[i]->internal->datapos = ftell((FILE*)mat->fp);
                    if ( cells[i]->internal->datapos != -1L ) {
                        cells[i]->internal->datapos -= matvar->internal->z->avail_in;
                        if ( cells[i]->class_type == MAT_C_STRUCT )
                            bytesread+=ReadNextStructField(mat,cells[i]);
                        else if ( cells[i]->class_type == MAT_C_CELL )
                            bytesread+=ReadNextCell(mat,cells[i]);
                        else if ( nbytes <= (1 << MAX_WBITS) ) {
                            /* Memory optimization: Read data if less in size
                               than the zlib inflate state (approximately) */
                            cells[i]->internal->fp = mat;
                            Read5(mat,cells[i]);
                            cells[i]->internal->data = cells[i]->data;
                            cells[i]->data = NULL;
                        }
                        (void)fseek((FILE*)mat->fp,cells[i]->internal->datapos,SEEK_SET);
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
                    Mat_Critical("inflateCopy returned error %s",zError(err));
                }
            } else {
                Mat_Critical("Couldn't allocate memory");
            }
            bytesread+=InflateSkip(mat,matvar->internal->z,nbytes);
        }
#else
        Mat_Critical("Not compiled with zlib support");
#endif

    } else {
        mat_uint32_t buf[16];
        int      nbytes,nBytes;
        mat_uint32_t array_flags;

        for ( i = 0; i < ncells; i++ ) {
            int cell_bytes_read,name_len;
            cells[i] = Mat_VarCalloc();
            if ( !cells[i] ) {
                Mat_Critical("Couldn't allocate memory for cell %d", i);
                continue;
            }

            cells[i]->internal->fpos = ftell((FILE*)mat->fp);
            if ( cells[i]->internal->fpos == -1L ) {
                Mat_Critical("Couldn't determine file position");
                continue;
            }

            /* Read variable tag for cell */
            cell_bytes_read = fread(buf,4,2,(FILE*)mat->fp);

            /* Empty cells at the end of a file may cause an EOF */
            if ( !cell_bytes_read )
                continue;
            bytesread += cell_bytes_read;
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(buf);
                (void)Mat_uint32Swap(buf+1);
            }
            nBytes = buf[1];
            if ( !nBytes ) {
                /* empty cell */
                continue;
            } else if ( buf[0] != MAT_T_MATRIX ) {
                Mat_VarFree(cells[i]);
                cells[i] = NULL;
                Mat_Critical("cells[%d] not MAT_T_MATRIX, fpos = %ld",i,
                    ftell((FILE*)mat->fp));
                break;
            }
            cells[i]->compression = MAT_COMPRESSION_NONE;
#if defined(HAVE_ZLIB)
            cells[i]->internal->z = NULL;
#endif

            /* Read Array Flags and The Dimensions Tag */
            bytesread += fread(buf,4,6,(FILE*)mat->fp);
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(buf);
                (void)Mat_uint32Swap(buf+1);
                (void)Mat_uint32Swap(buf+2);
                (void)Mat_uint32Swap(buf+3);
                (void)Mat_uint32Swap(buf+4);
                (void)Mat_uint32Swap(buf+5);
            }
            nBytes-=24;
            /* Array Flags */
            if ( buf[0] == MAT_T_UINT32 ) {
               array_flags = buf[2];
               cells[i]->class_type  = CLASS_FROM_ARRAY_FLAGS(array_flags);
               cells[i]->isComplex   = (array_flags & MAT_F_COMPLEX);
               cells[i]->isGlobal    = (array_flags & MAT_F_GLOBAL);
               cells[i]->isLogical   = (array_flags & MAT_F_LOGICAL);
               if ( cells[i]->class_type == MAT_C_SPARSE ) {
                   /* Need to find a more appropriate place to store nzmax */
                   cells[i]->nbytes      = buf[3];
               }
            }
            /* Rank and Dimension */
            if ( buf[4] == MAT_T_INT32 ) {
                int j;
                nbytes = buf[5];
                nBytes-=nbytes;

                cells[i]->rank = nbytes / 4;
                cells[i]->dims = (size_t*)malloc(cells[i]->rank*sizeof(*cells[i]->dims));

                /* Assumes rank <= 16 */
                if ( cells[i]->rank % 2 != 0 ) {
                    bytesread+=fread(buf,4,cells[i]->rank+1,(FILE*)mat->fp);
                    nBytes-=4;
                } else
                    bytesread+=fread(buf,4,cells[i]->rank,(FILE*)mat->fp);

                if ( mat->byteswap ) {
                    for ( j = 0; j < cells[i]->rank; j++ )
                        cells[i]->dims[j] = Mat_uint32Swap(buf+j);
                } else {
                    for ( j = 0; j < cells[i]->rank; j++ )
                        cells[i]->dims[j] = buf[j];
                }
            }
            /* Variable Name Tag */
            bytesread+=fread(buf,1,8,(FILE*)mat->fp);
            nBytes-=8;
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(buf);
                (void)Mat_uint32Swap(buf+1);
            }
            name_len = 0;
            if ( buf[1] > 0 ) {
                /* Name of variable */
                if ( buf[0] == MAT_T_INT8 ) {    /* Name not in tag */
                    name_len = buf[1];
                    if ( name_len % 8 > 0 )
                        name_len = name_len+(8-(name_len % 8));
                    nBytes -= name_len;
                    (void)fseek((FILE*)mat->fp,name_len,SEEK_CUR);
                }
            }
            cells[i]->internal->datapos = ftell((FILE*)mat->fp);
            if ( cells[i]->internal->datapos != -1L ) {
                if ( cells[i]->class_type == MAT_C_STRUCT )
                    bytesread+=ReadNextStructField(mat,cells[i]);
                if ( cells[i]->class_type == MAT_C_CELL )
                    bytesread+=ReadNextCell(mat,cells[i]);
                (void)fseek((FILE*)mat->fp,cells[i]->internal->datapos+nBytes,SEEK_SET);
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
ReadNextStructField( mat_t *mat, matvar_t *matvar )
{
    int fieldname_size,nfields, nmemb = 1, i;
    size_t bytesread = 0;
    matvar_t **fields = NULL;

    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];

    if ( matvar->compression ) {
#if defined(HAVE_ZLIB)
        char    *ptr;
        mat_uint32_t uncomp_buf[16] = {0,};
        int      nbytes, j;
        mat_uint32_t array_flags;
        int err;

        /* Inflate Field name length */
        bytesread += InflateFieldNameLength(mat,matvar,uncomp_buf);
        if ( mat->byteswap ) {
            (void)Mat_uint32Swap(uncomp_buf);
            (void)Mat_uint32Swap(uncomp_buf+1);
        }
        if ( (uncomp_buf[0] & 0x0000ffff) == MAT_T_INT32 ) {
            fieldname_size = uncomp_buf[1];
        } else {
            Mat_Warning("Error getting fieldname size");
            return bytesread;
        }

        bytesread += InflateFieldNamesTag(mat,matvar,uncomp_buf);
        if ( mat->byteswap ) {
            (void)Mat_uint32Swap(uncomp_buf);
            (void)Mat_uint32Swap(uncomp_buf+1);
        }
        nfields = uncomp_buf[1];
        nfields = nfields / fieldname_size;
        matvar->data_size = sizeof(matvar_t *);

        if ( nfields*fieldname_size % 8 != 0 )
            i = 8-(nfields*fieldname_size % 8);
        else
            i = 0;
        if ( nfields ) {
            ptr = (char*)malloc(nfields*fieldname_size+i);
            bytesread += InflateFieldNames(mat,matvar,ptr,nfields,fieldname_size,i);
            matvar->internal->num_fields = nfields;
            matvar->internal->fieldnames =
                (char**)calloc(nfields,sizeof(*matvar->internal->fieldnames));
            for ( i = 0; i < nfields; i++ ) {
                matvar->internal->fieldnames[i] = (char*)malloc(fieldname_size);
                memcpy(matvar->internal->fieldnames[i],ptr+i*fieldname_size,
                       fieldname_size);
                matvar->internal->fieldnames[i][fieldname_size-1] = '\0';
            }
            free(ptr);
        } else {
            matvar->internal->num_fields = 0;
            matvar->internal->fieldnames = NULL;
        }

        matvar->nbytes = nmemb*nfields*matvar->data_size;
        if ( !matvar->nbytes )
            return bytesread;

        matvar->data = malloc(matvar->nbytes);
        if ( !matvar->data )
            return bytesread;

        fields = (matvar_t**)matvar->data;
        for ( i = 0; i < nmemb; i++ ) {
            for ( j = 0; j < nfields; j++ ) {
                fields[i*nfields+j] = Mat_VarCalloc();
                fields[i*nfields+j]->name = mat_strdup(matvar->internal->fieldnames[j]);
            }
        }

        for ( i = 0; i < nmemb*nfields; i++ ) {
            fields[i]->internal->fpos = ftell((FILE*)mat->fp);
            if ( fields[i]->internal->fpos == -1L ) {
                Mat_Critical("Couldn't determine file position");
                continue;
            } else {
                fields[i]->internal->fpos -= matvar->internal->z->avail_in;
            }
            /* Read variable tag for struct field */
            bytesread += InflateVarTag(mat,matvar,uncomp_buf);
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf+1);
            }
            nbytes = uncomp_buf[1];
            if ( uncomp_buf[0] != MAT_T_MATRIX ) {
                Mat_VarFree(fields[i]);
                fields[i] = NULL;
                Mat_Critical("fields[%d], Uncompressed type not MAT_T_MATRIX",i);
                continue;
            } else if ( nbytes == 0 ) {
                fields[i]->rank = 0;
                continue;
            }
            fields[i]->compression = MAT_COMPRESSION_ZLIB;
            bytesread += InflateArrayFlags(mat,matvar,uncomp_buf);
            nbytes -= 16;
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf+1);
                (void)Mat_uint32Swap(uncomp_buf+2);
                (void)Mat_uint32Swap(uncomp_buf+3);
            }
            /* Array Flags */
            if ( uncomp_buf[0] == MAT_T_UINT32 ) {
               array_flags = uncomp_buf[2];
               fields[i]->class_type  = CLASS_FROM_ARRAY_FLAGS(array_flags);
               fields[i]->isComplex   = (array_flags & MAT_F_COMPLEX);
               fields[i]->isGlobal    = (array_flags & MAT_F_GLOBAL);
               fields[i]->isLogical   = (array_flags & MAT_F_LOGICAL);
               if ( fields[i]->class_type == MAT_C_SPARSE ) {
                   /* Need to find a more appropriate place to store nzmax */
                   fields[i]->nbytes      = uncomp_buf[3];
               }
            } else {
                Mat_Critical("Expected MAT_T_UINT32 for Array Tags, got %d",
                    uncomp_buf[0]);
                bytesread+=InflateSkip(mat,matvar->internal->z,nbytes);
            }
            bytesread += InflateDimensions(mat,matvar,uncomp_buf);
            nbytes -= 8;
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf+1);
            }
            /* Rank and Dimension */
            if ( uncomp_buf[0] == MAT_T_INT32 ) {
                int j = 0;

                fields[i]->rank = uncomp_buf[1];
                nbytes -= fields[i]->rank;
                fields[i]->rank /= 4;
                fields[i]->dims = (size_t*)malloc(fields[i]->rank*
                                         sizeof(*fields[i]->dims));
                if ( mat->byteswap ) {
                    for ( j = 0; j < fields[i]->rank; j++ )
                        fields[i]->dims[j] = Mat_uint32Swap(uncomp_buf+2+j);
                } else {
                    for ( j = 0; j < fields[i]->rank; j++ )
                        fields[i]->dims[j] = uncomp_buf[2+j];
                }
                if ( fields[i]->rank % 2 != 0 )
                    nbytes -= 4;
            }
            bytesread += InflateVarNameTag(mat,matvar,uncomp_buf);
            nbytes -= 8;
            fields[i]->internal->z = (z_streamp)calloc(1,sizeof(z_stream));
            if ( fields[i]->internal->z != NULL ) {
                err = inflateCopy(fields[i]->internal->z,matvar->internal->z);
                if ( err == Z_OK ) {
                    fields[i]->internal->datapos = ftell((FILE*)mat->fp);
                    if ( fields[i]->internal->datapos != -1L ) {
                        fields[i]->internal->datapos -= matvar->internal->z->avail_in;
                        if ( fields[i]->class_type == MAT_C_STRUCT )
                            bytesread+=ReadNextStructField(mat,fields[i]);
                        else if ( fields[i]->class_type == MAT_C_CELL )
                            bytesread+=ReadNextCell(mat,fields[i]);
                        else if ( nbytes <= (1 << MAX_WBITS) ) {
                            /* Memory optimization: Read data if less in size
                               than the zlib inflate state (approximately) */
                            fields[i]->internal->fp = mat;
                            Read5(mat,fields[i]);
                            fields[i]->internal->data = fields[i]->data;
                            fields[i]->data = NULL;
                        }
                        (void)fseek((FILE*)mat->fp,fields[i]->internal->datapos,SEEK_SET);
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
                    Mat_Critical("inflateCopy returned error %s",zError(err));
                }
            } else {
                Mat_Critical("Couldn't allocate memory");
            }
            bytesread+=InflateSkip(mat,matvar->internal->z,nbytes);
        }
#else
        Mat_Critical("Not compiled with zlib support");
#endif
    } else {
        mat_uint32_t buf[16] = {0,};
        int      nbytes,nBytes,j;
        mat_uint32_t array_flags;

        bytesread+=fread(buf,4,2,(FILE*)mat->fp);
        if ( mat->byteswap ) {
            (void)Mat_uint32Swap(buf);
            (void)Mat_uint32Swap(buf+1);
        }
        if ( (buf[0] & 0x0000ffff) == MAT_T_INT32 ) {
            fieldname_size = buf[1];
        } else {
            Mat_Warning("Error getting fieldname size");
            return bytesread;
        }
        bytesread+=fread(buf,4,2,(FILE*)mat->fp);
        if ( mat->byteswap ) {
            (void)Mat_uint32Swap(buf);
            (void)Mat_uint32Swap(buf+1);
        }
        nfields = buf[1];
        nfields = nfields / fieldname_size;
        matvar->data_size = sizeof(matvar_t *);

        if ( nfields ) {
            matvar->internal->num_fields = nfields;
            matvar->internal->fieldnames =
                (char**)calloc(nfields,sizeof(*matvar->internal->fieldnames));
            for ( i = 0; i < nfields; i++ ) {
                matvar->internal->fieldnames[i] = (char*)malloc(fieldname_size);
                bytesread+=fread(matvar->internal->fieldnames[i],1,fieldname_size,(FILE*)mat->fp);
                matvar->internal->fieldnames[i][fieldname_size-1] = '\0';
            }
        } else {
            matvar->internal->num_fields = 0;
            matvar->internal->fieldnames = NULL;
        }

        if ( (nfields*fieldname_size) % 8 ) {
            (void)fseek((FILE*)mat->fp,8-((nfields*fieldname_size) % 8),SEEK_CUR);
            bytesread+=8-((nfields*fieldname_size) % 8);
        }

        matvar->nbytes = nmemb*nfields*matvar->data_size;
        if ( !matvar->nbytes )
            return bytesread;

        matvar->data = malloc(matvar->nbytes);
        if ( !matvar->data )
            return bytesread;

        fields = (matvar_t**)matvar->data;
        for ( i = 0; i < nmemb; i++ ) {
            for ( j = 0; j < nfields; j++ ) {
                fields[i*nfields+j] = Mat_VarCalloc();
                fields[i*nfields+j]->name = mat_strdup(matvar->internal->fieldnames[j]);
            }
        }

        for ( i = 0; i < nmemb*nfields; i++ ) {

            fields[i]->internal->fpos = ftell((FILE*)mat->fp);
            if ( fields[i]->internal->fpos == -1L ) {
                Mat_Critical("Couldn't determine file position");
                continue;
            }

            /* Read variable tag for struct field */
            bytesread += fread(buf,4,2,(FILE*)mat->fp);
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(buf);
                (void)Mat_uint32Swap(buf+1);
            }
            nBytes = buf[1];
            if ( buf[0] != MAT_T_MATRIX ) {
                Mat_VarFree(fields[i]);
                fields[i] = NULL;
                Mat_Critical("fields[%d] not MAT_T_MATRIX, fpos = %ld",i,
                    ftell((FILE*)mat->fp));
                return bytesread;
            } else if ( nBytes == 0 ) {
                fields[i]->rank = 0;
                continue;
            }
            fields[i]->compression = MAT_COMPRESSION_NONE;
#if defined(HAVE_ZLIB)
            fields[i]->internal->z = NULL;
#endif

            /* Read Array Flags and The Dimensions Tag */
            bytesread += fread(buf,4,6,(FILE*)mat->fp);
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(buf);
                (void)Mat_uint32Swap(buf+1);
                (void)Mat_uint32Swap(buf+2);
                (void)Mat_uint32Swap(buf+3);
                (void)Mat_uint32Swap(buf+4);
                (void)Mat_uint32Swap(buf+5);
            }
            nBytes-=24;
            /* Array Flags */
            if ( buf[0] == MAT_T_UINT32 ) {
               array_flags = buf[2];
               fields[i]->class_type  = CLASS_FROM_ARRAY_FLAGS(array_flags);
               fields[i]->isComplex   = (array_flags & MAT_F_COMPLEX);
               fields[i]->isGlobal    = (array_flags & MAT_F_GLOBAL);
               fields[i]->isLogical   = (array_flags & MAT_F_LOGICAL);
               if ( fields[i]->class_type == MAT_C_SPARSE ) {
                   /* Need to find a more appropriate place to store nzmax */
                   fields[i]->nbytes      = buf[3];
               }
            }
            /* Rank and Dimension */
            if ( buf[4] == MAT_T_INT32 ) {
                int j;

                nbytes = buf[5];
                nBytes-=nbytes;

                fields[i]->rank = nbytes / 4;
                fields[i]->dims = (size_t*)malloc(fields[i]->rank*
                                         sizeof(*fields[i]->dims));

                /* Assumes rank <= 16 */
                if ( fields[i]->rank % 2 != 0 ) {
                    bytesread+=fread(buf,4,fields[i]->rank+1,(FILE*)mat->fp);
                    nBytes-=4;
                } else
                    bytesread+=fread(buf,4,fields[i]->rank,(FILE*)mat->fp);

                if ( mat->byteswap ) {
                    for ( j = 0; j < fields[i]->rank; j++ )
                        fields[i]->dims[j] = Mat_uint32Swap(buf+j);
                } else {
                    for ( j = 0; j < fields[i]->rank; j++ )
                        fields[i]->dims[j] = buf[j];
                }
            }
            /* Variable Name Tag */
            bytesread+=fread(buf,1,8,(FILE*)mat->fp);
            nBytes-=8;
            fields[i]->internal->datapos = ftell((FILE*)mat->fp);
            if ( fields[i]->internal->datapos != -1L ) {
                if ( fields[i]->class_type == MAT_C_STRUCT )
                    bytesread+=ReadNextStructField(mat,fields[i]);
                else if ( fields[i]->class_type == MAT_C_CELL )
                    bytesread+=ReadNextCell(mat,fields[i]);
                (void)fseek((FILE*)mat->fp,fields[i]->internal->datapos+nBytes,SEEK_SET);
            } else {
                Mat_Critical("Couldn't determine file position");
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
    int nfunctions = 1, i;
    size_t bytesread = 0;
    matvar_t **functions = NULL;

    for ( i = 0; i < matvar->rank; i++ )
        nfunctions *= matvar->dims[i];

    matvar->data = malloc(nfunctions*sizeof(matvar_t *));
    if ( matvar->data != NULL ) {
        matvar->data_size = sizeof(matvar_t *);
        matvar->nbytes    = nfunctions*matvar->data_size;
        functions = (matvar_t**)matvar->data;
        for ( i = 0; i < nfunctions; i++ )
            functions[i] = Mat_VarReadNextInfo(mat);
    } else {
        bytesread = 0;
        matvar->data_size = 0;
        matvar->nbytes    = 0;
    }

    return bytesread;
}

/** @brief Writes the header and blank data for a cell array
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @return number of bytes written
 */
static int
WriteCellArrayFieldInfo(mat_t *mat,matvar_t *matvar)
{
    mat_uint32_t array_flags = 0x0;
    mat_int16_t  array_name_type = MAT_T_INT8;
    int      array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int      array_flags_size = 8, pad4 = 0, matrix_type = MAT_T_MATRIX;
    mat_int8_t   pad1 = 0;
    int      nBytes, i, nmemb = 1;
    long     start = 0, end = 0;

    if ((matvar == NULL) || (mat == NULL))
        return 0;

#if 0
    nBytes = GetMatrixMaxBufSize(matvar);
#endif

    fwrite(&matrix_type,4,1,(FILE*)mat->fp);
    fwrite(&pad4,4,1,(FILE*)mat->fp);
    start = ftell((FILE*)mat->fp);

    /* Array Flags */
    array_flags = matvar->class_type & CLASS_TYPE_MASK;
    if ( matvar->isComplex )
        array_flags |= MAT_F_COMPLEX;
    if ( matvar->isGlobal )
        array_flags |= MAT_F_GLOBAL;
    if ( matvar->isLogical )
        array_flags |= MAT_F_LOGICAL;

    if ( mat->byteswap )
        array_flags = Mat_int32Swap((mat_int32_t*)&array_flags);
    fwrite(&array_flags_type,4,1,(FILE*)mat->fp);
    fwrite(&array_flags_size,4,1,(FILE*)mat->fp);
    fwrite(&array_flags,4,1,(FILE*)mat->fp);
    fwrite(&pad4,4,1,(FILE*)mat->fp);
    /* Rank and Dimension */
    nBytes = matvar->rank * 4;
    fwrite(&dims_array_type,4,1,(FILE*)mat->fp);
    fwrite(&nBytes,4,1,(FILE*)mat->fp);
    for ( i = 0; i < matvar->rank; i++ ) {
        mat_int32_t dim;
        dim = matvar->dims[i];
        nmemb *= dim;
        fwrite(&dim,4,1,(FILE*)mat->fp);
    }
    if ( matvar->rank % 2 != 0 )
        fwrite(&pad4,4,1,(FILE*)mat->fp);
    /* Name of variable */
    if ( !matvar->name ) {
        fwrite(&array_name_type,2,1,(FILE*)mat->fp);
        fwrite(&pad1,1,1,(FILE*)mat->fp);
        fwrite(&pad1,1,1,(FILE*)mat->fp);
        fwrite(&pad4,4,1,(FILE*)mat->fp);
    } else if ( strlen(matvar->name) <= 4 ) {
        mat_int16_t array_name_len = (mat_int16_t)strlen(matvar->name);
        mat_int8_t  pad1 = 0;
        fwrite(&array_name_type,2,1,(FILE*)mat->fp);
        fwrite(&array_name_len,2,1,(FILE*)mat->fp);
        fwrite(matvar->name,1,array_name_len,(FILE*)mat->fp);
        for ( i = array_name_len; i < 4; i++ )
            fwrite(&pad1,1,1,(FILE*)mat->fp);
    } else {
        mat_int32_t array_name_len = (mat_int32_t)strlen(matvar->name);
        mat_int8_t  pad1 = 0;

        fwrite(&array_name_type,2,1,(FILE*)mat->fp);
        fwrite(&pad1,1,1,(FILE*)mat->fp);
        fwrite(&pad1,1,1,(FILE*)mat->fp);
        fwrite(&array_name_len,4,1,(FILE*)mat->fp);
        fwrite(matvar->name,1,array_name_len,(FILE*)mat->fp);
        if ( array_name_len % 8 )
            for ( i = array_name_len % 8; i < 8; i++ )
                fwrite(&pad1,1,1,(FILE*)mat->fp);
    }

    matvar->internal->datapos = ftell((FILE*)mat->fp);
    if ( matvar->internal->datapos == -1L ) {
        Mat_Critical("Couldn't determine file position");
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
        case MAT_C_UINT8:
            nBytes = WriteEmptyData(mat,nmemb,matvar->data_type);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,(FILE*)mat->fp);
            if ( matvar->isComplex ) {
                nBytes = WriteEmptyData(mat,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
            }
            break;
        case MAT_C_CHAR:
        {
            WriteEmptyCharData(mat,nmemb,matvar->data_type);
            break;
        }
        case MAT_C_CELL:
        {
            int        ncells;
            matvar_t **cells = (matvar_t **)matvar->data;

            /* Check for an empty cell array */
            if ( matvar->nbytes == 0 || matvar->data_size == 0 ||
                 matvar->data   == NULL )
                break;
            ncells  = matvar->nbytes / matvar->data_size;

            for ( i = 0; i < ncells; i++ )
                WriteCellArrayFieldInfo(mat,cells[i]);
            break;
        }
        /* FIXME: Structures */
        case MAT_C_STRUCT:
        case MAT_C_SPARSE:
        case MAT_C_FUNCTION:
        case MAT_C_OBJECT:
        case MAT_C_EMPTY:
            break;
    }
    end = ftell((FILE*)mat->fp);
    if ( start != -1L && end != -1L ) {
        nBytes = (int)(end-start);
        (void)fseek((FILE*)mat->fp,(long)-(nBytes+4),SEEK_CUR);
        fwrite(&nBytes,4,1,(FILE*)mat->fp);
        (void)fseek((FILE*)mat->fp,end,SEEK_SET);
    } else {
        Mat_Critical("Couldn't determine file position");
    }
    return 0;
}

/** @brief Writes the header and data for an element of a cell array
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @retval 0 on success
 */
static int
WriteCellArrayField(mat_t *mat,matvar_t *matvar )
{
    mat_uint32_t array_flags = 0x0;
    mat_int16_t  array_name_type = MAT_T_INT8,fieldname_type = MAT_T_INT32,fieldname_data_size=4;
    int      array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int      array_flags_size = 8, pad4 = 0, matrix_type = MAT_T_MATRIX;
    mat_int8_t   pad1 = 0;
    int      nBytes, i, nmemb = 1, nzmax = 0;
    long     start = 0, end = 0;

    if ((matvar == NULL) || (mat == NULL))
        return 1;

#if 0
    nBytes = GetMatrixMaxBufSize(matvar);
#endif

    fwrite(&matrix_type,4,1,(FILE*)mat->fp);
    fwrite(&pad4,4,1,(FILE*)mat->fp);
    start = ftell((FILE*)mat->fp);

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
        array_flags = Mat_int32Swap((mat_int32_t*)&array_flags);
    fwrite(&array_flags_type,4,1,(FILE*)mat->fp);
    fwrite(&array_flags_size,4,1,(FILE*)mat->fp);
    fwrite(&array_flags,4,1,(FILE*)mat->fp);
    fwrite(&nzmax,4,1,(FILE*)mat->fp);
    /* Rank and Dimension */
    nBytes = matvar->rank * 4;
    fwrite(&dims_array_type,4,1,(FILE*)mat->fp);
    fwrite(&nBytes,4,1,(FILE*)mat->fp);
    for ( i = 0; i < matvar->rank; i++ ) {
        mat_int32_t dim;
        dim = matvar->dims[i];
        nmemb *= dim;
        fwrite(&dim,4,1,(FILE*)mat->fp);
    }
    if ( matvar->rank % 2 != 0 )
        fwrite(&pad4,4,1,(FILE*)mat->fp);
    /* Name of variable */
    if ( !matvar->name ) {
        fwrite(&array_name_type,2,1,(FILE*)mat->fp);
        fwrite(&pad1,1,1,(FILE*)mat->fp);
        fwrite(&pad1,1,1,(FILE*)mat->fp);
        fwrite(&pad4,4,1,(FILE*)mat->fp);
    } else if ( strlen(matvar->name) <= 4 ) {
        mat_int16_t array_name_len = (mat_int16_t)strlen(matvar->name);
        mat_int8_t  pad1 = 0;
        fwrite(&array_name_type,2,1,(FILE*)mat->fp);
        fwrite(&array_name_len,2,1,(FILE*)mat->fp);
        fwrite(matvar->name,1,array_name_len,(FILE*)mat->fp);
        for ( i = array_name_len; i < 4; i++ )
            fwrite(&pad1,1,1,(FILE*)mat->fp);
    } else {
        mat_int32_t array_name_len = (mat_int32_t)strlen(matvar->name);
        mat_int8_t  pad1 = 0;

        fwrite(&array_name_type,2,1,(FILE*)mat->fp);
        fwrite(&pad1,1,1,(FILE*)mat->fp);
        fwrite(&pad1,1,1,(FILE*)mat->fp);
        fwrite(&array_name_len,4,1,(FILE*)mat->fp);
        fwrite(matvar->name,1,array_name_len,(FILE*)mat->fp);
        if ( array_name_len % 8 )
            for ( i = array_name_len % 8; i < 8; i++ )
                fwrite(&pad1,1,1,(FILE*)mat->fp);
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
        case MAT_C_UINT8:
        {
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)matvar->data;

                if ( NULL == matvar->data )
                    complex_data = &null_complex_data;

                nBytes=WriteData(mat,complex_data->Re,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
                nBytes=WriteData(mat,complex_data->Im,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
            } else {
                nBytes = WriteData(mat,matvar->data,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
            }
            break;
        }
        case MAT_C_CHAR:
            WriteCharData(mat,matvar->data,nmemb,matvar->data_type);
            break;
        case MAT_C_CELL:
        {
            int        ncells;
            matvar_t **cells = (matvar_t **)matvar->data;

            /* Check for an empty cell array */
            if ( matvar->nbytes == 0 || matvar->data_size == 0 ||
                 matvar->data   == NULL )
                break;
            ncells  = matvar->nbytes / matvar->data_size;

            for ( i = 0; i < ncells; i++ )
                WriteCellArrayField(mat,cells[i]);
            break;
        }
        case MAT_C_STRUCT:
        {
            char  *padzero;
            int    fieldname_size, nfields;
            size_t maxlen = 0;
            matvar_t **fields = (matvar_t **)matvar->data;
            unsigned fieldname;

            nfields = matvar->internal->num_fields;

            for ( i = 0; i < nfields; i++ ) {
                size_t len = strlen(matvar->internal->fieldnames[i]);
                if ( len > maxlen )
                    maxlen = len;
            }
            maxlen++;
            fieldname_size = maxlen;
            while ( nfields*fieldname_size % 8 != 0 )
                fieldname_size++;
#if 0
            fwrite(&fieldname_type,2,1,(FILE*)mat->fp);
            fwrite(&fieldname_data_size,2,1,(FILE*)mat->fp);
#else
            fieldname = (fieldname_data_size<<16) | fieldname_type;
            fwrite(&fieldname,4,1,(FILE*)mat->fp);
#endif
            fwrite(&fieldname_size,4,1,(FILE*)mat->fp);
            fwrite(&array_name_type,2,1,(FILE*)mat->fp);
            fwrite(&pad1,1,1,(FILE*)mat->fp);
            fwrite(&pad1,1,1,(FILE*)mat->fp);
            nBytes = nfields*fieldname_size;
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            padzero = (char*)calloc(fieldname_size,1);
            for ( i = 0; i < nfields; i++ ) {
                size_t len = strlen(matvar->internal->fieldnames[i]);
                fwrite(matvar->internal->fieldnames[i],1,len,(FILE*)mat->fp);
                fwrite(padzero,1,fieldname_size-len,(FILE*)mat->fp);
            }
            free(padzero);
            for ( i = 0; i < nmemb*nfields; i++ )
                WriteStructField(mat,fields[i]);
            break;
        }
        case MAT_C_SPARSE:
        {
            mat_sparse_t *sparse = (mat_sparse_t*)matvar->data;

            nBytes = WriteData(mat,sparse->ir,sparse->nir,MAT_T_INT32);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,(FILE*)mat->fp);
            nBytes = WriteData(mat,sparse->jc,sparse->njc,MAT_T_INT32);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,(FILE*)mat->fp);
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)sparse->data;
                nBytes = WriteData(mat,complex_data->Re,sparse->ndata,
                                   matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
                nBytes = WriteData(mat,complex_data->Im,sparse->ndata,
                                   matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
            } else {
                nBytes = WriteData(mat,sparse->data,sparse->ndata,
                                   matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
            }
        }
        case MAT_C_FUNCTION:
        case MAT_C_OBJECT:
        case MAT_C_EMPTY:
            break;
    }
    end = ftell((FILE*)mat->fp);
    if ( start != -1L && end != -1L ) {
        nBytes = (int)(end-start);
        (void)fseek((FILE*)mat->fp,(long)-(nBytes+4),SEEK_CUR);
        fwrite(&nBytes,4,1,(FILE*)mat->fp);
        (void)fseek((FILE*)mat->fp,end,SEEK_SET);
    } else {
        Mat_Critical("Couldn't determine file position");
    }
    return 0;
}

#if defined(HAVE_ZLIB)
/** @brief Writes the header and data for a field of a compressed cell array
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @return number of bytes written to the MAT file
 */
static size_t
WriteCompressedCellArrayField(mat_t *mat,matvar_t *matvar,z_streamp z)
{
    mat_uint32_t array_flags = 0x0;
    mat_int16_t  array_name_type     = MAT_T_INT8;
    mat_int16_t  fieldname_type      = MAT_T_INT32;
    mat_int16_t  fieldname_data_size = 4;
    int      array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int      array_flags_size = 8, pad4 = 0;
    int      nBytes, i, nmemb = 1, nzmax = 0;
    long     start = 0;

    mat_uint32_t comp_buf[512];
    mat_uint32_t uncomp_buf[512] = {0,};
    int buf_size = 512;
    size_t byteswritten = 0;

    if ( NULL == matvar || NULL == mat || NULL == z)
        return 0;

    start = ftell((FILE*)mat->fp);

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

    uncomp_buf[0] = MAT_T_MATRIX;
    uncomp_buf[1] = (int)GetCellArrayFieldBufSize(matvar);
    z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = 8;
    do {
        z->next_out  = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size*sizeof(*comp_buf);
        deflate(z,Z_NO_FLUSH);
        byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-z->avail_out,
            (FILE*)mat->fp);
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
        nmemb *= dim;
        uncomp_buf[6+i] = dim;
    }
    if ( matvar->rank % 2 != 0 ) {
        uncomp_buf[6+i] = pad4;
        i++;
    }

    z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = (6+i)*sizeof(*uncomp_buf);
    do {
        z->next_out  = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size*sizeof(*comp_buf);
        deflate(z,Z_NO_FLUSH);
        byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-z->avail_out,
            (FILE*)mat->fp);
    } while ( z->avail_out == 0 );
    /* Name of variable */
    uncomp_buf[0] = array_name_type;
    uncomp_buf[1] = 0;
    z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = 8;
    do {
        z->next_out  = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size*sizeof(*comp_buf);
        deflate(z,Z_NO_FLUSH);
        byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-z->avail_out,
            (FILE*)mat->fp);
    } while ( z->avail_out == 0 );

    matvar->internal->datapos = ftell((FILE*)mat->fp);
    if ( matvar->internal->datapos == -1L ) {
        Mat_Critical("Couldn't determine file position");
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
        case MAT_C_UINT8:
        {
            /* WriteCompressedData makes sure uncompressed data is aligned
             * on an 8-byte boundary */
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)matvar->data;

                if ( NULL == matvar->data )
                    complex_data = &null_complex_data;

                byteswritten += WriteCompressedData(mat,z,
                    complex_data->Re,nmemb,matvar->data_type);
                byteswritten += WriteCompressedData(mat,z,
                    complex_data->Im,nmemb,matvar->data_type);
            } else {
                byteswritten += WriteCompressedData(mat,z,
                    matvar->data,nmemb,matvar->data_type);
            }
            break;
        }
        case MAT_C_CHAR:
        {
            byteswritten += WriteCompressedCharData(mat,z,matvar->data,
                nmemb,matvar->data_type);
            break;
        }
        case MAT_C_CELL:
        {
            int        ncells;
            matvar_t **cells = (matvar_t **)matvar->data;

            /* Check for an empty cell array */
            if ( matvar->nbytes == 0 || matvar->data_size == 0 ||
                 matvar->data   == NULL )
                break;
            ncells  = matvar->nbytes / matvar->data_size;
            for ( i = 0; i < ncells; i++ )
                WriteCompressedCellArrayField(mat,cells[i],z);
            break;
        }
        case MAT_C_STRUCT:
        {
            unsigned char *padzero;
            int        fieldname_size, nfields;
            size_t     maxlen = 0;
            mat_int32_t array_name_type = MAT_T_INT8;
            matvar_t **fields = (matvar_t **)matvar->data;

            nfields = matvar->internal->num_fields;
            /* Check for a structure with no fields */
            if ( nfields < 1 ) {
                fieldname_size = 1;
                uncomp_buf[0] = (fieldname_data_size << 16) |
                                 fieldname_type;
                uncomp_buf[1] = fieldname_size;
                uncomp_buf[2] = array_name_type;
                uncomp_buf[3] = 0;
                z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
                z->avail_in = 16;
                do {
                    z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                    z->avail_out = buf_size*sizeof(*comp_buf);
                    deflate(z,Z_NO_FLUSH);
                    byteswritten += fwrite(comp_buf,1,buf_size*
                        sizeof(*comp_buf)-z->avail_out,(FILE*)mat->fp);
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
            while ( nfields*fieldname_size % 8 != 0 )
                fieldname_size++;
            uncomp_buf[0] = (fieldname_data_size << 16) | fieldname_type;
            uncomp_buf[1] = fieldname_size;
            uncomp_buf[2] = array_name_type;
            uncomp_buf[3] = nfields*fieldname_size;

            padzero = (unsigned char*)calloc(fieldname_size,1);
            z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
            z->avail_in = 16;
            do {
                z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                z->avail_out = buf_size*sizeof(*comp_buf);
                deflate(z,Z_NO_FLUSH);
                byteswritten += fwrite(comp_buf,1,
                    buf_size*sizeof(*comp_buf)-z->avail_out,(FILE*)mat->fp);
            } while ( z->avail_out == 0 );
            for ( i = 0; i < nfields; i++ ) {
                memset(padzero,'\0',fieldname_size);
                memcpy(padzero,matvar->internal->fieldnames[i],
                    strlen(matvar->internal->fieldnames[i]));
                z->next_in  = ZLIB_BYTE_PTR(padzero);
                z->avail_in = fieldname_size;
                do {
                    z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                    z->avail_out = buf_size*sizeof(*comp_buf);
                    deflate(z,Z_NO_FLUSH);
                    byteswritten += fwrite(comp_buf,1,
                        buf_size*sizeof(*comp_buf)-z->avail_out,(FILE*)mat->fp);
                } while ( z->avail_out == 0 );
            }
            free(padzero);
            for ( i = 0; i < nmemb*nfields; i++ )
                byteswritten +=
                    WriteCompressedStructField(mat,fields[i],z);
            break;
        }
        case MAT_C_SPARSE:
        {
            mat_sparse_t *sparse = (mat_sparse_t*)matvar->data;

            byteswritten += WriteCompressedData(mat,z,sparse->ir,
                sparse->nir,MAT_T_INT32);
            byteswritten += WriteCompressedData(mat,z,sparse->jc,
                sparse->njc,MAT_T_INT32);
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)sparse->data;
                byteswritten += WriteCompressedData(mat,z,
                    complex_data->Re,sparse->ndata,matvar->data_type);
                byteswritten += WriteCompressedData(mat,z,
                    complex_data->Im,sparse->ndata,matvar->data_type);
            } else {
                byteswritten += WriteCompressedData(mat,z,
                    sparse->data,sparse->ndata,matvar->data_type);
            }
            break;
        }
        case MAT_C_FUNCTION:
        case MAT_C_OBJECT:
        case MAT_C_EMPTY:
            break;
    }
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
WriteStructField(mat_t *mat,matvar_t *matvar)
{
    mat_uint32_t array_flags = 0x0;
    mat_int16_t  fieldname_type = MAT_T_INT32,fieldname_data_size=4;
    mat_int32_t  array_name_type = MAT_T_INT8;
    int      array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int      array_flags_size = 8, pad4 = 0, matrix_type = MAT_T_MATRIX;
    mat_int8_t   pad1 = 0;
    int      nBytes, i, nmemb = 1, nzmax = 0;
    long     start = 0, end = 0;

    if ( mat == NULL )
        return 1;

    if ( NULL == matvar ) {
        size_t dims[2] = {0,0};
        Mat_WriteEmptyVariable5(mat, NULL, 2, dims);
        return 0;
    }

    fwrite(&matrix_type,4,1,(FILE*)mat->fp);
    fwrite(&pad4,4,1,(FILE*)mat->fp);
    start = ftell((FILE*)mat->fp);

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
        array_flags = Mat_int32Swap((mat_int32_t*)&array_flags);
    fwrite(&array_flags_type,4,1,(FILE*)mat->fp);
    fwrite(&array_flags_size,4,1,(FILE*)mat->fp);
    fwrite(&array_flags,4,1,(FILE*)mat->fp);
    fwrite(&nzmax,4,1,(FILE*)mat->fp);
    /* Rank and Dimension */
    nBytes = matvar->rank * 4;
    fwrite(&dims_array_type,4,1,(FILE*)mat->fp);
    fwrite(&nBytes,4,1,(FILE*)mat->fp);
    for ( i = 0; i < matvar->rank; i++ ) {
        mat_int32_t dim;
        dim = matvar->dims[i];
        nmemb *= dim;
        fwrite(&dim,4,1,(FILE*)mat->fp);
    }
    if ( matvar->rank % 2 != 0 )
        fwrite(&pad4,4,1,(FILE*)mat->fp);

    /* Name of variable */
    fwrite(&array_name_type,4,1,(FILE*)mat->fp);
    fwrite(&pad4,4,1,(FILE*)mat->fp);

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
        {
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)matvar->data;

                if ( NULL == matvar->data )
                    complex_data = &null_complex_data;

                nBytes=WriteData(mat,complex_data->Re,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
                nBytes=WriteData(mat,complex_data->Im,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
            } else {
                nBytes=WriteData(mat,matvar->data,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
            }
            break;
        }
        case MAT_C_CHAR:
            nBytes=WriteCharData(mat,matvar->data,nmemb,matvar->data_type);
            break;
        case MAT_C_CELL:
        {
            int        ncells;
            matvar_t **cells = (matvar_t **)matvar->data;

            /* Check for an empty cell array */
            if ( matvar->nbytes == 0 || matvar->data_size == 0 ||
                 matvar->data   == NULL )
                break;
            ncells  = matvar->nbytes / matvar->data_size;

            for ( i = 0; i < ncells; i++ )
                WriteCellArrayField(mat,cells[i]);
            break;
        }
        case MAT_C_STRUCT:
        {
            char  *padzero;
            int    fieldname_size, nfields = 0;
            size_t maxlen = 0;
            matvar_t **fields = (matvar_t **)matvar->data;
            unsigned fieldname;

            /* nmemb*matvar->data_size can be zero when saving a struct that
             * contains an empty struct in one of its fields
             * (e.g. x.y = struct('z', {})). If it's zero, we would divide
             * by zero.
             */
            nfields = matvar->internal->num_fields;

            for ( i = 0; i < nfields; i++ ) {
                size_t len = strlen(matvar->internal->fieldnames[i]);
                if ( len > maxlen )
                    maxlen = len;
            }
            maxlen++;
            fieldname_size = maxlen;
            while ( nfields*fieldname_size % 8 != 0 )
                fieldname_size++;
#if 0
            fwrite(&fieldname_type,2,1,(FILE*)mat->fp);
            fwrite(&fieldname_data_size,2,1,(FILE*)mat->fp);
#else
            fieldname = (fieldname_data_size<<16) | fieldname_type;
            fwrite(&fieldname,4,1,(FILE*)mat->fp);
#endif
            fwrite(&fieldname_size,4,1,(FILE*)mat->fp);
            fwrite(&array_name_type,4,1,(FILE*)mat->fp);
            nBytes = nfields*fieldname_size;
            fwrite(&nBytes,4,1,(FILE*)mat->fp);
            padzero = (char*)calloc(fieldname_size,1);
            for ( i = 0; i < nfields; i++ ) {
                size_t len = strlen(matvar->internal->fieldnames[i]);
                fwrite(matvar->internal->fieldnames[i],1,len,(FILE*)mat->fp);
                fwrite(padzero,1,fieldname_size-len,(FILE*)mat->fp);
            }
            free(padzero);
            for ( i = 0; i < nmemb*nfields; i++ )
                WriteStructField(mat,fields[i]);
            break;
        }
        case MAT_C_SPARSE:
        {
            mat_sparse_t *sparse = (mat_sparse_t*)matvar->data;

            nBytes = WriteData(mat,sparse->ir,sparse->nir,MAT_T_INT32);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,(FILE*)mat->fp);
            nBytes = WriteData(mat,sparse->jc,sparse->njc,MAT_T_INT32);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,(FILE*)mat->fp);
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)sparse->data;
                nBytes = WriteData(mat,complex_data->Re,sparse->ndata,
                                   matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
                nBytes = WriteData(mat,complex_data->Im,sparse->ndata,
                                   matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
            } else {
                nBytes = WriteData(mat,sparse->data,sparse->ndata,
                                   matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
            }
        }
        case MAT_C_FUNCTION:
        case MAT_C_OBJECT:
        case MAT_C_EMPTY:
            break;
    }
    end = ftell((FILE*)mat->fp);
    if ( start != -1L && end != -1L ) {
        nBytes = (int)(end-start);
        (void)fseek((FILE*)mat->fp,(long)-(nBytes+4),SEEK_CUR);
        fwrite(&nBytes,4,1,(FILE*)mat->fp);
        (void)fseek((FILE*)mat->fp,end,SEEK_SET);
    } else {
        Mat_Critical("Couldn't determine file position");
    }
    return 0;
}

#if defined(HAVE_ZLIB)
/** @brief Writes the header and data for a field of a compressed struct array
 *
 * @ingroup mat_internal
 * @fixme Currently does not work for cell arrays or sparse data
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @return number of bytes written to the MAT file
 */
static size_t
WriteCompressedStructField(mat_t *mat,matvar_t *matvar,z_streamp z)
{
    mat_uint32_t array_flags = 0x0;
    mat_int16_t  array_name_type     = MAT_T_INT8;
    mat_int16_t  fieldname_type      = MAT_T_INT32;
    mat_int16_t  fieldname_data_size = 4;
    int      array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int      array_flags_size = 8, pad4 = 0;
    int      nBytes, i, nmemb = 1, nzmax = 0;
    long     start = 0;

    mat_uint32_t comp_buf[512];
    mat_uint32_t uncomp_buf[512] = {0,};
    int buf_size = 512;
    size_t byteswritten = 0;

    if ( NULL == mat || NULL == z)
        return 1;

    if ( NULL == matvar ) {
        size_t dims[2] = {0,0};
        byteswritten = Mat_WriteCompressedEmptyVariable5(mat, NULL, 2, dims, z);
        return byteswritten;
    }
    start = ftell((FILE*)mat->fp);

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

    uncomp_buf[0] = MAT_T_MATRIX;
    uncomp_buf[1] = (int)GetStructFieldBufSize(matvar);
    z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = 8;
    do {
        z->next_out  = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size*sizeof(*comp_buf);
        deflate(z,Z_NO_FLUSH);
        byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-z->avail_out,
            (FILE*)mat->fp);
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
        nmemb *= dim;
        uncomp_buf[6+i] = dim;
    }
    if ( matvar->rank % 2 != 0 ) {
        uncomp_buf[6+i] = pad4;
        i++;
    }

    z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = (6+i)*sizeof(*uncomp_buf);
    do {
        z->next_out  = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size*sizeof(*comp_buf);
        deflate(z,Z_NO_FLUSH);
        byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-z->avail_out,
            (FILE*)mat->fp);
    } while ( z->avail_out == 0 );
    /* Name of variable */
    uncomp_buf[0] = array_name_type;
    uncomp_buf[1] = 0;
    z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = 8;
    do {
        z->next_out  = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size*sizeof(*comp_buf);
        deflate(z,Z_NO_FLUSH);
        byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-z->avail_out,
            (FILE*)mat->fp);
    } while ( z->avail_out == 0 );

    matvar->internal->datapos = ftell((FILE*)mat->fp);
    if ( matvar->internal->datapos == -1L ) {
        Mat_Critical("Couldn't determine file position");
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
        case MAT_C_UINT8:
        {
            /* WriteCompressedData makes sure uncompressed data is aligned
             * on an 8-byte boundary */
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)matvar->data;

                if ( NULL == matvar->data )
                    complex_data = &null_complex_data;

                byteswritten += WriteCompressedData(mat,z,
                    complex_data->Re,nmemb,matvar->data_type);
                byteswritten += WriteCompressedData(mat,z,
                    complex_data->Im,nmemb,matvar->data_type);
            } else {
                byteswritten += WriteCompressedData(mat,z,
                    matvar->data,nmemb,matvar->data_type);
            }
            break;
        }
        case MAT_C_CHAR:
        {
            byteswritten += WriteCompressedCharData(mat,z,matvar->data,
                nmemb,matvar->data_type);
            break;
        }
        case MAT_C_CELL:
        {
            int        ncells;
            matvar_t **cells = (matvar_t **)matvar->data;

            /* Check for an empty cell array */
            if ( matvar->nbytes == 0 || matvar->data_size == 0 ||
                 matvar->data   == NULL )
                break;
            ncells  = matvar->nbytes / matvar->data_size;
            for ( i = 0; i < ncells; i++ )
                WriteCompressedCellArrayField(mat,cells[i],z);
            break;
        }
        case MAT_C_STRUCT:
        {
            unsigned char *padzero;
            int        fieldname_size, nfields;
            size_t     maxlen = 0;
            mat_int32_t array_name_type = MAT_T_INT8;
            matvar_t **fields = (matvar_t **)matvar->data;

            nfields = matvar->internal->num_fields;
            /* Check for a structure with no fields */
            if ( nfields < 1 ) {
                fieldname_size = 1;
                uncomp_buf[0] = (fieldname_data_size << 16) |
                                 fieldname_type;
                uncomp_buf[1] = fieldname_size;
                uncomp_buf[2] = array_name_type;
                uncomp_buf[3] = 0;
                z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
                z->avail_in = 16;
                do {
                    z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                    z->avail_out = buf_size*sizeof(*comp_buf);
                    deflate(z,Z_NO_FLUSH);
                    byteswritten += fwrite(comp_buf,1,buf_size*
                        sizeof(*comp_buf)-z->avail_out,(FILE*)mat->fp);
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
            while ( nfields*fieldname_size % 8 != 0 )
                fieldname_size++;
            uncomp_buf[0] = (fieldname_data_size << 16) | fieldname_type;
            uncomp_buf[1] = fieldname_size;
            uncomp_buf[2] = array_name_type;
            uncomp_buf[3] = nfields*fieldname_size;

            padzero = (unsigned char*)calloc(fieldname_size,1);
            z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
            z->avail_in = 16;
            do {
                z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                z->avail_out = buf_size*sizeof(*comp_buf);
                deflate(z,Z_NO_FLUSH);
                byteswritten += fwrite(comp_buf,1,
                    buf_size*sizeof(*comp_buf)-z->avail_out,(FILE*)mat->fp);
            } while ( z->avail_out == 0 );
            for ( i = 0; i < nfields; i++ ) {
                size_t len = strlen(matvar->internal->fieldnames[i]);
                memset(padzero,'\0',fieldname_size);
                memcpy(padzero,matvar->internal->fieldnames[i],len);
                z->next_in  = ZLIB_BYTE_PTR(padzero);
                z->avail_in = fieldname_size;
                do {
                    z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                    z->avail_out = buf_size*sizeof(*comp_buf);
                    deflate(z,Z_NO_FLUSH);
                    byteswritten += fwrite(comp_buf,1,
                        buf_size*sizeof(*comp_buf)-z->avail_out,(FILE*)mat->fp);
                } while ( z->avail_out == 0 );
            }
            free(padzero);
            for ( i = 0; i < nmemb*nfields; i++ )
                byteswritten +=
                    WriteCompressedStructField(mat,fields[i],z);
            break;
        }
        case MAT_C_SPARSE:
        {
            mat_sparse_t *sparse = (mat_sparse_t*)matvar->data;

            byteswritten += WriteCompressedData(mat,z,sparse->ir,
                sparse->nir,MAT_T_INT32);
            byteswritten += WriteCompressedData(mat,z,sparse->jc,
                sparse->njc,MAT_T_INT32);
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)sparse->data;
                byteswritten += WriteCompressedData(mat,z,
                    complex_data->Re,sparse->ndata,matvar->data_type);
                byteswritten += WriteCompressedData(mat,z,
                    complex_data->Im,sparse->ndata,matvar->data_type);
            } else {
                byteswritten += WriteCompressedData(mat,z,
                    sparse->data,sparse->ndata,matvar->data_type);
            }
            break;
        }
        case MAT_C_FUNCTION:
        case MAT_C_OBJECT:
        case MAT_C_EMPTY:
            break;
    }

    return byteswritten;
}
#endif

static size_t
Mat_WriteEmptyVariable5(mat_t *mat,const char *name,int rank,size_t *dims)
{
    mat_uint32_t array_flags = 0x0;
    mat_int32_t  array_name_type = MAT_T_INT8, matrix_type = MAT_T_MATRIX;
    int          array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int          array_flags_size = 8, pad4 = 0, nBytes, i, nmemb = 1;
    mat_int8_t   pad1 = 0;
    size_t       byteswritten = 0;
    long         start = 0, end = 0;

    fwrite(&matrix_type,4,1,(FILE*)mat->fp);
    fwrite(&pad4,4,1,(FILE*)mat->fp);
    start = ftell((FILE*)mat->fp);

    /* Array Flags */
    array_flags = MAT_C_DOUBLE;

    if ( mat->byteswap )
        array_flags = Mat_int32Swap((mat_int32_t*)&array_flags);
    byteswritten += fwrite(&array_flags_type,4,1,(FILE*)mat->fp);
    byteswritten += fwrite(&array_flags_size,4,1,(FILE*)mat->fp);
    byteswritten += fwrite(&array_flags,4,1,(FILE*)mat->fp);
    byteswritten += fwrite(&pad4,4,1,(FILE*)mat->fp);
    /* Rank and Dimension */
    nBytes = rank * 4;
    byteswritten += fwrite(&dims_array_type,4,1,(FILE*)mat->fp);
    byteswritten += fwrite(&nBytes,4,1,(FILE*)mat->fp);
    for ( i = 0; i < rank; i++ ) {
        mat_int32_t dim;
        dim = dims[i];
        nmemb *= dim;
        byteswritten += fwrite(&dim,4,1,(FILE*)mat->fp);
    }
    if ( rank % 2 != 0 )
        byteswritten += fwrite(&pad4,4,1,(FILE*)mat->fp);

    if ( NULL == name ) {
        /* Name of variable */
        byteswritten += fwrite(&array_name_type,4,1,(FILE*)mat->fp);
        byteswritten += fwrite(&pad4,4,1,(FILE*)mat->fp);
    } else {
        mat_int32_t  array_name_type = MAT_T_INT8;
        mat_int32_t  array_name_len   = strlen(name);
        /* Name of variable */
        if ( array_name_len <= 4 ) {
            mat_int8_t  pad1 = 0;
            array_name_type = (array_name_len << 16) | array_name_type;
            byteswritten += fwrite(&array_name_type,4,1,(FILE*)mat->fp);
            byteswritten += fwrite(name,1,array_name_len,(FILE*)mat->fp);
            for ( i = array_name_len; i < 4; i++ )
                byteswritten += fwrite(&pad1,1,1,(FILE*)mat->fp);
        } else {
            byteswritten += fwrite(&array_name_type,4,1,(FILE*)mat->fp);
            byteswritten += fwrite(&array_name_len,4,1,(FILE*)mat->fp);
            byteswritten += fwrite(name,1,array_name_len,(FILE*)mat->fp);
            if ( array_name_len % 8 )
                for ( i = array_name_len % 8; i < 8; i++ )
                    byteswritten += fwrite(&pad1,1,1,(FILE*)mat->fp);
        }
    }

    nBytes = WriteData(mat,NULL,0,MAT_T_DOUBLE);
    byteswritten += nBytes;
    if ( nBytes % 8 )
        for ( i = nBytes % 8; i < 8; i++ )
            byteswritten += fwrite(&pad1,1,1,(FILE*)mat->fp);

    end = ftell((FILE*)mat->fp);
    if ( start != -1L && end != -1L ) {
        nBytes = (int)(end-start);
        (void)fseek((FILE*)mat->fp,(long)-(nBytes+4),SEEK_CUR);
        fwrite(&nBytes,4,1,(FILE*)mat->fp);
        (void)fseek((FILE*)mat->fp,end,SEEK_SET);
    } else {
        Mat_Critical("Couldn't determine file position");
    }

    return byteswritten;
}

#if defined(HAVE_ZLIB)
static size_t
Mat_WriteCompressedEmptyVariable5(mat_t *mat,const char *name,int rank,
                                  size_t *dims,z_streamp z)
{
    mat_uint32_t array_flags = 0x0;
    mat_int16_t  array_name_type     = MAT_T_INT8;
    int      array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int      array_flags_size = 8, pad4 = 0;
    int      nBytes, i, nmemb = 1;

    mat_uint32_t comp_buf[512];
    mat_uint32_t uncomp_buf[512] = {0,};
    int buf_size = 512;
    size_t byteswritten = 0, buf_size_bytes;

    if ( NULL == mat || NULL == z)
        return 1;

    buf_size_bytes = buf_size*sizeof(*comp_buf);

    /* Array Flags */
    array_flags = MAT_C_DOUBLE;

    uncomp_buf[0] = MAT_T_MATRIX;
    uncomp_buf[1] = (int)GetEmptyMatrixMaxBufSize(name,rank);
    z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = 8;
    do {
        z->next_out  = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size_bytes;
        deflate(z,Z_NO_FLUSH);
        byteswritten += fwrite(comp_buf,1,buf_size_bytes-z->avail_out,(FILE*)mat->fp);
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
        nmemb *= dim;
        uncomp_buf[6+i] = dim;
    }
    if ( rank % 2 != 0 ) {
        uncomp_buf[6+i] = pad4;
        i++;
    }

    z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_in = (6+i)*sizeof(*uncomp_buf);
    do {
        z->next_out  = ZLIB_BYTE_PTR(comp_buf);
        z->avail_out = buf_size_bytes;
        deflate(z,Z_NO_FLUSH);
        byteswritten += fwrite(comp_buf,1,buf_size_bytes-z->avail_out,(FILE*)mat->fp);
    } while ( z->avail_out == 0 );
    /* Name of variable */
    if ( NULL == name ) {
        uncomp_buf[0] = array_name_type;
        uncomp_buf[1] = 0;
        z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
        z->avail_in = 8;
        do {
            z->next_out  = ZLIB_BYTE_PTR(comp_buf);
            z->avail_out = buf_size_bytes;
            deflate(z,Z_NO_FLUSH);
            byteswritten += fwrite(comp_buf,1,buf_size_bytes-z->avail_out,(FILE*)mat->fp);
        } while ( z->avail_out == 0 );
    } else {
        if ( strlen(name) <= 4 ) {
            mat_int16_t array_name_len = (mat_int16_t)strlen(name);
            mat_int16_t array_name_type = MAT_T_INT8;

            memset(uncomp_buf,0,8);
            uncomp_buf[0] = (array_name_len << 16) | array_name_type;
            memcpy(uncomp_buf+1,name,array_name_len);
            if ( array_name_len % 4 )
                array_name_len += 4-(array_name_len % 4);

            z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
            z->avail_in = 8;
            do {
                z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                z->avail_out = buf_size_bytes;
                deflate(z,Z_NO_FLUSH);
                byteswritten += fwrite(comp_buf,1,buf_size_bytes-z->avail_out,
                    (FILE*)mat->fp);
            } while ( z->avail_out == 0 );
        } else {
            mat_int32_t array_name_len = (mat_int32_t)strlen(name);
            mat_int32_t array_name_type = MAT_T_INT8;

            memset(uncomp_buf,0,buf_size*sizeof(*uncomp_buf));
            uncomp_buf[0] = array_name_type;
            uncomp_buf[1] = array_name_len;
            memcpy(uncomp_buf+2,name,array_name_len);
            if ( array_name_len % 8 )
                array_name_len += 8-(array_name_len % 8);
            z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
            z->avail_in = 8+array_name_len;
            do {
                z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                z->avail_out = buf_size_bytes;
                deflate(z,Z_NO_FLUSH);
                byteswritten += fwrite(comp_buf,1,buf_size_bytes-z->avail_out,
                    (FILE*)mat->fp);
            } while ( z->avail_out == 0 );
        }
    }

    byteswritten += WriteCompressedData(mat,z,NULL,0,MAT_T_DOUBLE);
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
 * @endif
 */
void
Mat_VarReadNumeric5(mat_t *mat,matvar_t *matvar,void *data,size_t N)
{
    int nBytes = 0, data_in_tag = 0;
    enum matio_types packed_type = MAT_T_UNKNOWN;
    mat_uint32_t tag[2];

    if ( matvar->compression ) {
#if defined(HAVE_ZLIB)
        matvar->internal->z->avail_in = 0;
        InflateDataType(mat,matvar->internal->z,tag);
        if ( mat->byteswap )
            (void)Mat_uint32Swap(tag);

        packed_type = TYPE_FROM_TAG(tag[0]);
        if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
            data_in_tag = 1;
            nBytes = (tag[0] & 0xffff0000) >> 16;
        } else {
            data_in_tag = 0;
            InflateDataType(mat,matvar->internal->z,tag+1);
            if ( mat->byteswap )
                (void)Mat_uint32Swap(tag+1);
            nBytes = tag[1];
        }
#endif
    } else {
        size_t bytesread = fread(tag,4,1,(FILE*)mat->fp);
        if ( mat->byteswap )
            (void)Mat_uint32Swap(tag);
        packed_type = TYPE_FROM_TAG(tag[0]);
        if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
            data_in_tag = 1;
            nBytes = (tag[0] & 0xffff0000) >> 16;
        } else {
            data_in_tag = 0;
            bytesread += fread(tag+1,4,1,(FILE*)mat->fp);
            if ( mat->byteswap )
                (void)Mat_uint32Swap(tag+1);
            nBytes = tag[1];
        }
    }
    if ( nBytes == 0 ) {
        matvar->nbytes = 0;
        return;
    }

    if ( matvar->compression == MAT_COMPRESSION_NONE) {
        switch ( matvar->class_type ) {
            case MAT_C_DOUBLE:
                nBytes = ReadDoubleData(mat,(double*)data,packed_type,N);
                break;
            case MAT_C_SINGLE:
                nBytes = ReadSingleData(mat,(float*)data,packed_type,N);
                break;
            case MAT_C_INT64:
#ifdef HAVE_MATIO_INT64_T
                nBytes = ReadInt64Data(mat,(mat_int64_t*)data,packed_type,N);
#endif
                break;
            case MAT_C_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                nBytes = ReadUInt64Data(mat,(mat_uint64_t*)data,packed_type,N);
#endif
                break;
            case MAT_C_INT32:
                nBytes = ReadInt32Data(mat,(mat_int32_t*)data,packed_type,N);
                break;
            case MAT_C_UINT32:
                nBytes = ReadUInt32Data(mat,(mat_uint32_t*)data,packed_type,N);
                break;
            case MAT_C_INT16:
                nBytes = ReadInt16Data(mat,(mat_int16_t*)data,packed_type,N);
                break;
            case MAT_C_UINT16:
                nBytes = ReadUInt16Data(mat,(mat_uint16_t*)data,packed_type,N);
                break;
            case MAT_C_INT8:
                nBytes = ReadInt8Data(mat,(mat_int8_t*)data,packed_type,N);
                break;
            case MAT_C_UINT8:
                nBytes = ReadUInt8Data(mat,(mat_uint8_t*)data,packed_type,N);
                break;
            default:
                break;
        }
        /*
         * If the data was in the tag we started on a 4-byte
         * boundary so add 4 to make it an 8-byte
         */
        if ( data_in_tag )
            nBytes+=4;
        if ( (nBytes % 8) != 0 )
            (void)fseek((FILE*)mat->fp,8-(nBytes % 8),SEEK_CUR);
#if defined(HAVE_ZLIB)
    } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
        switch ( matvar->class_type ) {
            case MAT_C_DOUBLE:
                nBytes = ReadCompressedDoubleData(mat,matvar->internal->z,(double*)data,
                                                  packed_type,N);
                break;
            case MAT_C_SINGLE:
                nBytes = ReadCompressedSingleData(mat,matvar->internal->z,(float*)data,
                                                  packed_type,N);
                break;
            case MAT_C_INT64:
#ifdef HAVE_MATIO_INT64_T
                nBytes = ReadCompressedInt64Data(mat,matvar->internal->z,(mat_int64_t*)data,
                                                 packed_type,N);
#endif
                break;
            case MAT_C_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                nBytes = ReadCompressedUInt64Data(mat,matvar->internal->z,(mat_uint64_t*)data,
                                                  packed_type,N);
#endif
                break;
            case MAT_C_INT32:
                nBytes = ReadCompressedInt32Data(mat,matvar->internal->z,(mat_int32_t*)data,
                                                 packed_type,N);
                break;
            case MAT_C_UINT32:
                nBytes = ReadCompressedUInt32Data(mat,matvar->internal->z,(mat_uint32_t*)data,
                                                  packed_type,N);
                break;
            case MAT_C_INT16:
                nBytes = ReadCompressedInt16Data(mat,matvar->internal->z,(mat_int16_t*)data,
                                                 packed_type,N);
                break;
            case MAT_C_UINT16:
                nBytes = ReadCompressedUInt16Data(mat,matvar->internal->z,(mat_uint16_t*)data,
                                                  packed_type,N);
                break;
            case MAT_C_INT8:
                nBytes = ReadCompressedInt8Data(mat,matvar->internal->z,(mat_int8_t*)data,
                                                packed_type,N);
                break;
            case MAT_C_UINT8:
                nBytes = ReadCompressedUInt8Data(mat,matvar->internal->z,(mat_uint8_t*)data,
                                                 packed_type,N);
                break;
            default:
                break;
        }
        /*
         * If the data was in the tag we started on a 4-byte
         * boundary so add 4 to make it an 8-byte
         */
        if ( data_in_tag )
            nBytes+=4;
        if ( (nBytes % 8) != 0 )
            InflateSkip(mat,matvar->internal->z,8-(nBytes % 8));
#endif
    }
}

/** @if mat_devman
 * @brief Reads the data of a version 5 MAT variable
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar MAT variable pointer to read the data
 * @endif
 */
static void
Read5(mat_t *mat, matvar_t *matvar)
{
    int nBytes = 0, len = 1, i, byteswap, data_in_tag = 0;
    enum matio_types packed_type = MAT_T_UNKNOWN;
    long fpos;
    mat_uint32_t tag[2];
    size_t bytesread = 0;

    if ( matvar == NULL )
        return;
    else if ( matvar->rank == 0 )        /* An empty data set */
        return;
#if defined(HAVE_ZLIB)
    else if ( NULL != matvar->internal->data ) {
        /* Data already read in ReadNextStructField or ReadNextCell */
        matvar->data = matvar->internal->data;
        matvar->internal->data = NULL;
        return;
    }
#endif
    fpos = ftell((FILE*)mat->fp);
    if ( fpos == -1L ) {
        Mat_Critical("Couldn't determine file position");
        return;
    }
    len = 1;
    byteswap = mat->byteswap;
    for ( i = 0; i < matvar->rank; i++ )
        len *= matvar->dims[i];
    switch ( matvar->class_type ) {
        case MAT_C_EMPTY:
            matvar->nbytes = 0;
            matvar->data_size = sizeof(double);
            matvar->data_type = MAT_T_DOUBLE;
            matvar->class_type = MAT_C_EMPTY;
            matvar->rank = 2;
            matvar->dims = (size_t*)malloc(matvar->rank*sizeof(*(matvar->dims)));
            matvar->dims[0] = 0;
            matvar->dims[1] = 0;
            break;
        case MAT_C_DOUBLE:
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(double);
            matvar->data_type = MAT_T_DOUBLE;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                if ( NULL == complex_data ) {
                    Mat_Critical("Failed to allocate %d bytes",sizeof(*complex_data));
                    break;
                }
                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);
                if ( NULL == complex_data->Re || NULL == complex_data->Im ) {
                    if ( NULL != complex_data->Re )
                        free(complex_data->Re);
                    if ( NULL != complex_data->Im )
                        free(complex_data->Im);
                    free(complex_data);
                    Mat_Critical("Failed to allocate %d bytes",2*matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,complex_data->Re,len);
                Mat_VarReadNumeric5(mat,matvar,complex_data->Im,len);
                matvar->data = complex_data;
            } else {
                matvar->nbytes = len*matvar->data_size;
                matvar->data   = malloc(matvar->nbytes);
                if ( !matvar->data ) {
                    Mat_Critical("Failed to allocate %d bytes",matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,matvar->data,len);
            }
            break;
        case MAT_C_SINGLE:
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(float);
            matvar->data_type = MAT_T_SINGLE;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                if ( NULL == complex_data ) {
                    Mat_Critical("Failed to allocate %d bytes",sizeof(*complex_data));
                    break;
                }
                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);
                if ( NULL == complex_data->Re || NULL == complex_data->Im ) {
                    if ( NULL != complex_data->Re )
                        free(complex_data->Re);
                    if ( NULL != complex_data->Im )
                        free(complex_data->Im);
                    free(complex_data);
                    Mat_Critical("Failed to allocate %d bytes",2*matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,complex_data->Re,len);
                Mat_VarReadNumeric5(mat,matvar,complex_data->Im,len);
                matvar->data = complex_data;
            } else {
                matvar->nbytes = len*matvar->data_size;
                matvar->data   = malloc(matvar->nbytes);
                if ( !matvar->data ) {
                    Mat_Critical("Failed to allocate %d bytes",matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,matvar->data,len);
            }
            break;
        case MAT_C_INT64:
#ifdef HAVE_MATIO_INT64_T
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_int64_t);
            matvar->data_type = MAT_T_INT64;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                if ( NULL == complex_data ) {
                    Mat_Critical("Failed to allocate %d bytes",sizeof(*complex_data));
                    break;
                }
                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);
                if ( NULL == complex_data->Re || NULL == complex_data->Im ) {
                    if ( NULL != complex_data->Re )
                        free(complex_data->Re);
                    if ( NULL != complex_data->Im )
                        free(complex_data->Im);
                    free(complex_data);
                    Mat_Critical("Failed to allocate %d bytes",2*matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,complex_data->Re,len);
                Mat_VarReadNumeric5(mat,matvar,complex_data->Im,len);
                matvar->data = complex_data;
            } else {
                matvar->nbytes = len*matvar->data_size;
                matvar->data   = malloc(matvar->nbytes);
                if ( !matvar->data ) {
                    Mat_Critical("Failed to allocate %d bytes",matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,matvar->data,len);
            }
#endif
            break;
        case MAT_C_UINT64:
#ifdef HAVE_MATIO_UINT64_T
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_uint64_t);
            matvar->data_type = MAT_T_UINT64;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                if ( NULL == complex_data ) {
                    Mat_Critical("Failed to allocate %d bytes",sizeof(*complex_data));
                    break;
                }
                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);
                if ( NULL == complex_data->Re || NULL == complex_data->Im ) {
                    if ( NULL != complex_data->Re )
                        free(complex_data->Re);
                    if ( NULL != complex_data->Im )
                        free(complex_data->Im);
                    free(complex_data);
                    Mat_Critical("Failed to allocate %d bytes",2*matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,complex_data->Re,len);
                Mat_VarReadNumeric5(mat,matvar,complex_data->Im,len);
                matvar->data = complex_data;
            } else {
                matvar->nbytes = len*matvar->data_size;
                matvar->data   = malloc(matvar->nbytes);
                if ( !matvar->data ) {
                    Mat_Critical("Failed to allocate %d bytes",matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,matvar->data,len);
            }
#endif
            break;
        case MAT_C_INT32:
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_int32_t);
            matvar->data_type = MAT_T_INT32;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                if ( NULL == complex_data ) {
                    Mat_Critical("Failed to allocate %d bytes",sizeof(*complex_data));
                    break;
                }
                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);
                if ( NULL == complex_data->Re || NULL == complex_data->Im ) {
                    if ( NULL != complex_data->Re )
                        free(complex_data->Re);
                    if ( NULL != complex_data->Im )
                        free(complex_data->Im);
                    free(complex_data);
                    Mat_Critical("Failed to allocate %d bytes",2*matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,complex_data->Re,len);
                Mat_VarReadNumeric5(mat,matvar,complex_data->Im,len);
                matvar->data = complex_data;
            } else {
                matvar->nbytes = len*matvar->data_size;
                matvar->data   = malloc(matvar->nbytes);
                if ( !matvar->data ) {
                    Mat_Critical("Failed to allocate %d bytes",matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,matvar->data,len);
            }
            break;
        case MAT_C_UINT32:
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_uint32_t);
            matvar->data_type = MAT_T_UINT32;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                if ( NULL == complex_data ) {
                    Mat_Critical("Failed to allocate %d bytes",sizeof(*complex_data));
                    break;
                }
                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);
                if ( NULL == complex_data->Re || NULL == complex_data->Im ) {
                    if ( NULL != complex_data->Re )
                        free(complex_data->Re);
                    if ( NULL != complex_data->Im )
                        free(complex_data->Im);
                    free(complex_data);
                    Mat_Critical("Failed to allocate %d bytes",2*matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,complex_data->Re,len);
                Mat_VarReadNumeric5(mat,matvar,complex_data->Im,len);
                matvar->data = complex_data;
            } else {
                matvar->nbytes = len*matvar->data_size;
                matvar->data   = malloc(matvar->nbytes);
                if ( !matvar->data ) {
                    Mat_Critical("Failed to allocate %d bytes",matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,matvar->data,len);
            }
            break;
        case MAT_C_INT16:
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_int16_t);
            matvar->data_type = MAT_T_INT16;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                if ( NULL == complex_data ) {
                    Mat_Critical("Failed to allocate %d bytes",sizeof(*complex_data));
                    break;
                }
                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);
                if ( NULL == complex_data->Re || NULL == complex_data->Im ) {
                    if ( NULL != complex_data->Re )
                        free(complex_data->Re);
                    if ( NULL != complex_data->Im )
                        free(complex_data->Im);
                    free(complex_data);
                    Mat_Critical("Failed to allocate %d bytes",2*matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,complex_data->Re,len);
                Mat_VarReadNumeric5(mat,matvar,complex_data->Im,len);
                matvar->data = complex_data;
            } else {
                matvar->nbytes = len*matvar->data_size;
                matvar->data   = malloc(matvar->nbytes);
                if ( !matvar->data ) {
                    Mat_Critical("Failed to allocate %d bytes",matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,matvar->data,len);
            }
            break;
        case MAT_C_UINT16:
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_uint16_t);
            matvar->data_type = MAT_T_UINT16;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                if ( NULL == complex_data ) {
                    Mat_Critical("Failed to allocate %d bytes",sizeof(*complex_data));
                    break;
                }
                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);
                if ( NULL == complex_data->Re || NULL == complex_data->Im ) {
                    if ( NULL != complex_data->Re )
                        free(complex_data->Re);
                    if ( NULL != complex_data->Im )
                        free(complex_data->Im);
                    free(complex_data);
                    Mat_Critical("Failed to allocate %d bytes",2*matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,complex_data->Re,len);
                Mat_VarReadNumeric5(mat,matvar,complex_data->Im,len);
                matvar->data = complex_data;
            } else {
                matvar->nbytes = len*matvar->data_size;
                matvar->data   = malloc(matvar->nbytes);
                if ( !matvar->data ) {
                    Mat_Critical("Failed to allocate %d bytes",matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,matvar->data,len);
            }
            break;
        case MAT_C_INT8:
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_int8_t);
            matvar->data_type = MAT_T_INT8;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                if ( NULL == complex_data ) {
                    Mat_Critical("Failed to allocate %d bytes",sizeof(*complex_data));
                    break;
                }
                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);
                if ( NULL == complex_data->Re || NULL == complex_data->Im ) {
                    if ( NULL != complex_data->Re )
                        free(complex_data->Re);
                    if ( NULL != complex_data->Im )
                        free(complex_data->Im);
                    free(complex_data);
                    Mat_Critical("Failed to allocate %d bytes",2*matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,complex_data->Re,len);
                Mat_VarReadNumeric5(mat,matvar,complex_data->Im,len);
                matvar->data = complex_data;
            } else {
                matvar->nbytes = len*matvar->data_size;
                matvar->data   = malloc(matvar->nbytes);
                if ( !matvar->data ) {
                    Mat_Critical("Failed to allocate %d bytes",matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,matvar->data,len);
            }
            break;
        case MAT_C_UINT8:
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_uint8_t);
            matvar->data_type = MAT_T_UINT8;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                if ( NULL == complex_data ) {
                    Mat_Critical("Failed to allocate %d bytes",sizeof(*complex_data));
                    break;
                }
                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);
                if ( NULL == complex_data->Re || NULL == complex_data->Im ) {
                    if ( NULL != complex_data->Re )
                        free(complex_data->Re);
                    if ( NULL != complex_data->Im )
                        free(complex_data->Im);
                    free(complex_data);
                    Mat_Critical("Failed to allocate %d bytes",2*matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,complex_data->Re,len);
                Mat_VarReadNumeric5(mat,matvar,complex_data->Im,len);
                matvar->data = complex_data;
            } else {
                matvar->nbytes = len*matvar->data_size;
                matvar->data   = malloc(matvar->nbytes);
                if ( !matvar->data ) {
                    Mat_Critical("Failed to allocate %d bytes",matvar->nbytes);
                    break;
                }
                Mat_VarReadNumeric5(mat,matvar,matvar->data,len);
            }
            break;
        case MAT_C_CHAR:
            if ( matvar->compression ) {
#if defined(HAVE_ZLIB)
                (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);

                matvar->internal->z->avail_in = 0;
                InflateDataType(mat,matvar->internal->z,tag);
                if ( byteswap )
                    (void)Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    nBytes = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    InflateDataType(mat,matvar->internal->z,tag+1);
                    if ( byteswap )
                        (void)Mat_uint32Swap(tag+1);
                    nBytes = tag[1];
                }
#endif
            } else {
                (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
                bytesread += fread(tag,4,1,(FILE*)mat->fp);
                if ( byteswap )
                    (void)Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    nBytes = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    bytesread += fread(tag+1,4,1,(FILE*)mat->fp);
                    if ( byteswap )
                        (void)Mat_uint32Swap(tag+1);
                    nBytes = tag[1];
                }
            }
            if ( nBytes == 0 ) {
                matvar->nbytes = 0;
                matvar->data   = calloc(0,1);
                break;
            }
            matvar->data_size = sizeof(char);
            /* FIXME: */
            matvar->data_type = MAT_T_UINT8;
            matvar->nbytes = len*matvar->data_size;
            matvar->data   = calloc(matvar->nbytes+1,1);
            if ( !matvar->data ) {
                Mat_Critical("Failed to allocate %d bytes",matvar->nbytes);
                break;
            }
            if ( matvar->compression == MAT_COMPRESSION_NONE) {
                nBytes = ReadCharData(mat,(char*)matvar->data,packed_type,len);
                    /*
                     * If the data was in the tag we started on a 4-byte
                     * boundary so add 4 to make it an 8-byte
                     */
                    if ( data_in_tag )
                        nBytes+=4;
                if ( (nBytes % 8) != 0 )
                    (void)fseek((FILE*)mat->fp,8-(nBytes % 8),SEEK_CUR);
#if defined(HAVE_ZLIB)
            } else if ( matvar->compression == MAT_COMPRESSION_ZLIB) {
                nBytes = ReadCompressedCharData(mat,matvar->internal->z,
                             (char*)matvar->data,packed_type,len);
                    /*
                     * If the data was in the tag we started on a 4-byte
                     * boundary so add 4 to make it an 8-byte
                     */
                    if ( data_in_tag )
                        nBytes+=4;
                if ( (nBytes % 8) != 0 )
                    InflateSkip(mat,matvar->internal->z,8-(nBytes % 8));
#endif
            }
            break;
        case MAT_C_STRUCT:
        {
            matvar_t **fields;
            int nfields = 0;

            matvar->data_type = MAT_T_STRUCT;
            if ( !matvar->nbytes || !matvar->data_size || NULL == matvar->data )
                break;
            nfields = matvar->internal->num_fields;
            fields = (matvar_t **)matvar->data;
            for ( i = 0; i < len*nfields; i++ ) {
                fields[i]->internal->fp = mat;
                Read5(mat,fields[i]);
            }
            break;
        }
        case MAT_C_CELL:
        {
            matvar_t **cells;

            if ( !matvar->data ) {
                Mat_Critical("Data is NULL for Cell Array %s",matvar->name);
                break;
            }
            cells = (matvar_t **)matvar->data;
            for ( i = 0; i < len; i++ ) {
                cells[i]->internal->fp = mat;
                Read5(mat,cells[i]);
            }
            /* FIXME: */
            matvar->data_type = MAT_T_CELL;
            break;
        }
        case MAT_C_SPARSE:
        {
            int N = 0;
            mat_sparse_t *data;

            matvar->data_size = sizeof(mat_sparse_t);
            matvar->data      = malloc(matvar->data_size);
            if ( matvar->data == NULL ) {
                Mat_Critical("ReadData: Allocation of data pointer failed");
                break;
            }
            data = (mat_sparse_t*)matvar->data;
            data->nzmax  = matvar->nbytes;
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
            /*  Read ir    */
            if ( matvar->compression ) {
#if defined(HAVE_ZLIB)
                matvar->internal->z->avail_in = 0;
                InflateDataType(mat,matvar->internal->z,tag);
                if ( mat->byteswap )
                    (void)Mat_uint32Swap(tag);

                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    N = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    (void)ReadCompressedInt32Data(mat,matvar->internal->z,
                             (mat_int32_t*)&N,MAT_T_INT32,1);
                }
#endif
            } else {
                bytesread += fread(tag,4,1,(FILE*)mat->fp);
                if ( mat->byteswap )
                    (void)Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    N = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    bytesread += fread(&N,4,1,(FILE*)mat->fp);
                    if ( mat->byteswap )
                        Mat_int32Swap(&N);
                }
            }
            data->nir = N / 4;
            data->ir = (mat_int32_t*)malloc(data->nir*sizeof(mat_int32_t));
            if ( data->ir != NULL ) {
                if ( matvar->compression == MAT_COMPRESSION_NONE) {
                    nBytes = ReadInt32Data(mat,data->ir,packed_type,data->nir);
                    /*
                     * If the data was in the tag we started on a 4-byte
                     * boundary so add 4 to make it an 8-byte
                     */
                    if ( data_in_tag )
                        nBytes+=4;
                    if ( (nBytes % 8) != 0 )
                        (void)fseek((FILE*)mat->fp,8-(nBytes % 8),SEEK_CUR);
#if defined(HAVE_ZLIB)
                } else if ( matvar->compression == MAT_COMPRESSION_ZLIB) {
                    nBytes = ReadCompressedInt32Data(mat,matvar->internal->z,
                                 data->ir,packed_type,data->nir);
                    /*
                     * If the data was in the tag we started on a 4-byte
                     * boundary so add 4 to make it an 8-byte
                     */
                    if ( data_in_tag )
                        nBytes+=4;
                    if ( (nBytes % 8) != 0 )
                        InflateSkip(mat,matvar->internal->z,8-(nBytes % 8));
#endif
                }
            } else {
                Mat_Critical("ReadData: Allocation of ir pointer failed");
                break;
            }
            /*  Read jc    */
            if ( matvar->compression ) {
#if defined(HAVE_ZLIB)
                matvar->internal->z->avail_in = 0;
                InflateDataType(mat,matvar->internal->z,tag);
                if ( mat->byteswap )
                    Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    N = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    (void)ReadCompressedInt32Data(mat,matvar->internal->z,
                             (mat_int32_t*)&N,MAT_T_INT32,1);
                }
#endif
            } else {
                bytesread += fread(tag,4,1,(FILE*)mat->fp);
                if ( mat->byteswap )
                    Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    N = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    bytesread += fread(&N,4,1,(FILE*)mat->fp);
                    if ( mat->byteswap )
                        Mat_int32Swap(&N);
                }
            }
            data->njc = N / 4;
            data->jc = (mat_int32_t*)malloc(data->njc*sizeof(mat_int32_t));
            if ( data->jc != NULL ) {
                if ( matvar->compression == MAT_COMPRESSION_NONE) {
                    nBytes = ReadInt32Data(mat,data->jc,packed_type,data->njc);
                    /*
                     * If the data was in the tag we started on a 4-byte
                     * boundary so add 4 to make it an 8-byte
                     */
                    if ( data_in_tag )
                        nBytes+=4;
                    if ( (nBytes % 8) != 0 )
                        (void)fseek((FILE*)mat->fp,8-(nBytes % 8),SEEK_CUR);
#if defined(HAVE_ZLIB)
                } else if ( matvar->compression == MAT_COMPRESSION_ZLIB) {
                    nBytes = ReadCompressedInt32Data(mat,matvar->internal->z,
                                 data->jc,packed_type,data->njc);
                    /*
                     * If the data was in the tag we started on a 4-byte
                     * boundary so add 4 to make it an 8-byte
                     */
                    if ( data_in_tag )
                        nBytes+=4;
                    if ( (nBytes % 8) != 0 )
                        InflateSkip(mat,matvar->internal->z,8-(nBytes % 8));
#endif
                }
            } else {
                Mat_Critical("ReadData: Allocation of jc pointer failed");
                break;
            }
            /*  Read data    */
            if ( matvar->compression ) {
#if defined(HAVE_ZLIB)
                matvar->internal->z->avail_in = 0;
                InflateDataType(mat,matvar->internal->z,tag);
                if ( mat->byteswap )
                    Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    N = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    (void)ReadCompressedInt32Data(mat,matvar->internal->z,
                             (mat_int32_t*)&N,MAT_T_INT32,1);
                }
#endif
            } else {
                bytesread += fread(tag,4,1,(FILE*)mat->fp);
                if ( mat->byteswap )
                    Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    N = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    bytesread += fread(&N,4,1,(FILE*)mat->fp);
                    if ( mat->byteswap )
                        Mat_int32Swap(&N);
                }
            }
            if ( matvar->isLogical && packed_type == MAT_T_DOUBLE ) {
                /* For some reason, MAT says the data type is a double,
                 * but it appears to be written as 8-bit integer.
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
                data->ndata = N / s_type;
            }
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                complex_data = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                if ( NULL == complex_data ) {
                    Mat_Critical("Failed to allocate %d bytes",sizeof(*complex_data));
                    break;
                }
                complex_data->Re = malloc(data->ndata*
                                          Mat_SizeOf(matvar->data_type));
                complex_data->Im = malloc(data->ndata*
                                          Mat_SizeOf(matvar->data_type));
                if ( NULL == complex_data->Re || NULL == complex_data->Im ) {
                    if ( NULL != complex_data->Re )
                        free(complex_data->Re);
                    if ( NULL != complex_data->Im )
                        free(complex_data->Im);
                    free(complex_data);
                    Mat_Critical("Failed to allocate %d bytes",
                                 data->ndata* Mat_SizeOf(matvar->data_type));
                    break;
                }
                if ( matvar->compression == MAT_COMPRESSION_NONE) {
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadDoubleData(mat,(double*)complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadSingleData(mat,(float*)complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadInt64Data(mat,(mat_int64_t*)complex_data->Re,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadUInt64Data(mat,(mat_uint64_t*)complex_data->Re,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadInt32Data(mat,(mat_int32_t*)complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadUInt32Data(mat,(mat_uint32_t*)complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadInt16Data(mat,(mat_int16_t*)complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadUInt16Data(mat,(mat_uint16_t*)complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadInt8Data(mat,(mat_int8_t*)complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadUInt8Data(mat,(mat_uint8_t*)complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        default:
                            break;
                    }
#else
                    nBytes = ReadDoubleData(mat,complex_data->Re,
                                 packed_type,data->ndata);
#endif
                    if ( data_in_tag )
                        nBytes+=4;
                    if ( (nBytes % 8) != 0 )
                        (void)fseek((FILE*)mat->fp,8-(nBytes % 8),SEEK_CUR);

                    /* Complex Data Tag */
                    bytesread += fread(tag,4,1,(FILE*)mat->fp);
                    if ( byteswap )
                        (void)Mat_uint32Swap(tag);
                    packed_type = TYPE_FROM_TAG(tag[0]);
                    if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                        data_in_tag = 1;
                        nBytes = (tag[0] & 0xffff0000) >> 16;
                    } else {
                        data_in_tag = 0;
                        bytesread += fread(tag+1,4,1,(FILE*)mat->fp);
                        if ( byteswap )
                            (void)Mat_uint32Swap(tag+1);
                        nBytes = tag[1];
                    }
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadDoubleData(mat,(double*)complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadSingleData(mat,(float*)complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadInt64Data(mat,(mat_int64_t*)complex_data->Im,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadUInt64Data(mat,(mat_uint64_t*)complex_data->Im,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadInt32Data(mat,(mat_int32_t*)complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadUInt32Data(mat,(mat_uint32_t*)complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadInt16Data(mat,(mat_int16_t*)complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadUInt16Data(mat,(mat_uint16_t*)complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadInt8Data(mat,(mat_int8_t*)complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadUInt8Data(mat,(mat_uint8_t*)complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        default:
                            break;
                    }
#else /* EXTENDED_SPARSE */
                    nBytes = ReadDoubleData(mat,complex_data->Im,
                                 packed_type,data->ndata);
#endif /* EXTENDED_SPARSE */
                    if ( data_in_tag )
                        nBytes+=4;
                    if ( (nBytes % 8) != 0 )
                        (void)fseek((FILE*)mat->fp,8-(nBytes % 8),SEEK_CUR);
#if defined(HAVE_ZLIB)
                } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadCompressedDoubleData(mat,matvar->internal->z,
                                 (double*)complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadCompressedSingleData(mat,matvar->internal->z,
                                 (float*)complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadCompressedInt64Data(mat,
                                matvar->internal->z,(mat_int64_t*)complex_data->Re,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadCompressedUInt64Data(mat,
                                matvar->internal->z,(mat_uint64_t*)complex_data->Re,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadCompressedInt32Data(mat,matvar->internal->z,
                                 (mat_int32_t*)complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadCompressedUInt32Data(mat,matvar->internal->z,
                                 (mat_uint32_t*)complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadCompressedInt16Data(mat,matvar->internal->z,
                                 (mat_int16_t*)complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadCompressedUInt16Data(mat,matvar->internal->z,
                                 (mat_uint16_t*)complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadCompressedInt8Data(mat,matvar->internal->z,
                                 (mat_int8_t*)complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadCompressedUInt8Data(mat,matvar->internal->z,
                                 (mat_uint8_t*)complex_data->Re,packed_type,data->ndata);
                            break;
                        default:
                            break;
                    }
#else    /* EXTENDED_SPARSE */
                    nBytes = ReadCompressedDoubleData(mat,matvar->internal->z,
                                 (double*)complex_data->Re,packed_type,data->ndata);
#endif    /* EXTENDED_SPARSE */
                    if ( data_in_tag )
                        nBytes+=4;
                    if ( (nBytes % 8) != 0 )
                        InflateSkip(mat,matvar->internal->z,8-(nBytes % 8));

                    /* Complex Data Tag */
                    InflateDataType(mat,matvar->internal->z,tag);
                    if ( byteswap )
                        (void)Mat_uint32Swap(tag);

                    packed_type = TYPE_FROM_TAG(tag[0]);
                    if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                        data_in_tag = 1;
                        nBytes = (tag[0] & 0xffff0000) >> 16;
                    } else {
                        data_in_tag = 0;
                        InflateDataType(mat,matvar->internal->z,tag+1);
                        if ( byteswap )
                            (void)Mat_uint32Swap(tag+1);
                        nBytes = tag[1];
                    }
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadCompressedDoubleData(mat,matvar->internal->z,
                                 (double*)complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadCompressedSingleData(mat,matvar->internal->z,
                                 (float*)complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadCompressedInt64Data(mat,
                                matvar->internal->z,(mat_int64_t*)complex_data->Im,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadCompressedUInt64Data(mat,
                                matvar->internal->z,(mat_uint64_t*)complex_data->Im,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadCompressedInt32Data(mat,matvar->internal->z,
                                 (mat_int32_t*)complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadCompressedUInt32Data(mat,matvar->internal->z,
                                 (mat_uint32_t*)complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadCompressedInt16Data(mat,matvar->internal->z,
                                 (mat_int16_t*)complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadCompressedUInt16Data(mat,matvar->internal->z,
                                 (mat_uint16_t*)complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadCompressedInt8Data(mat,matvar->internal->z,
                                 (mat_int8_t*)complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadCompressedUInt8Data(mat,matvar->internal->z,
                                 (mat_uint8_t*)complex_data->Im,packed_type,data->ndata);
                            break;
                        default:
                            break;
                    }
#else    /* EXTENDED_SPARSE */
                    nBytes = ReadCompressedDoubleData(mat,matvar->internal->z,
                                 (double*)complex_data->Im,packed_type,data->ndata);
#endif    /* EXTENDED_SPARSE */
                    if ( data_in_tag )
                        nBytes+=4;
                    if ( (nBytes % 8) != 0 )
                        InflateSkip(mat,matvar->internal->z,8-(nBytes % 8));
#endif    /* HAVE_ZLIB */
                }
                data->data = complex_data;
            } else { /* isComplex */
                data->data = malloc(data->ndata*Mat_SizeOf(matvar->data_type));
                if ( data->data == NULL ) {
                    Mat_Critical("Failed to allocate %d bytes",
                                 data->ndata*Mat_SizeOf(MAT_T_DOUBLE));
                    break;
                }
                if ( matvar->compression == MAT_COMPRESSION_NONE) {
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadDoubleData(mat,(double*)data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadSingleData(mat,(float*)data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadInt64Data(mat,(mat_int64_t*)data->data,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadUInt64Data(mat,(mat_uint64_t*)data->data,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadInt32Data(mat,(mat_int32_t*)data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadUInt32Data(mat,(mat_uint32_t*)data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadInt16Data(mat,(mat_int16_t*)data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadUInt16Data(mat,(mat_uint16_t*)data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadInt8Data(mat,(mat_int8_t*)data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadUInt8Data(mat,(mat_uint8_t*)data->data,
                                packed_type,data->ndata);
                            break;
                        default:
                            break;
                    }
#else
                    nBytes = ReadDoubleData(mat,(double*)data->data,packed_type,
                                 data->ndata);
#endif
                    if ( data_in_tag )
                        nBytes+=4;
                    if ( (nBytes % 8) != 0 )
                        (void)fseek((FILE*)mat->fp,8-(nBytes % 8),SEEK_CUR);
#if defined(HAVE_ZLIB)
                } else if ( matvar->compression == MAT_COMPRESSION_ZLIB) {
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadCompressedDoubleData(mat,matvar->internal->z,
                                 (double*)data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadCompressedSingleData(mat,matvar->internal->z,
                                 (float*)data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadCompressedInt64Data(mat,
                                matvar->internal->z,(mat_int64_t*)data->data,packed_type,
                                data->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadCompressedUInt64Data(mat,
                                matvar->internal->z,(mat_uint64_t*)data->data,packed_type,
                                data->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadCompressedInt32Data(mat,matvar->internal->z,
                                 (mat_int32_t*)data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadCompressedUInt32Data(mat,matvar->internal->z,
                                 (mat_uint32_t*)data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadCompressedInt16Data(mat,matvar->internal->z,
                                 (mat_int16_t*)data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadCompressedUInt16Data(mat,matvar->internal->z,
                                 (mat_uint16_t*)data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadCompressedInt8Data(mat,matvar->internal->z,
                                 (mat_int8_t*)data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadCompressedUInt8Data(mat,matvar->internal->z,
                                 (mat_uint8_t*)data->data,packed_type,data->ndata);
                            break;
                        default:
                            break;
                    }
#else   /* EXTENDED_SPARSE */
                    nBytes = ReadCompressedDoubleData(mat,matvar->internal->z,
                                 (double*)data->data,packed_type,data->ndata);
#endif   /* EXTENDED_SPARSE */
                    if ( data_in_tag )
                        nBytes+=4;
                    if ( (nBytes % 8) != 0 )
                        InflateSkip(mat,matvar->internal->z,8-(nBytes % 8));
#endif   /* HAVE_ZLIB */
                }
            }
            break;
        }
        case MAT_C_FUNCTION:
        {
            matvar_t **functions;
            int nfunctions = 0;

            if ( !matvar->nbytes || !matvar->data_size )
                break;
            nfunctions = matvar->nbytes / matvar->data_size;
            functions = (matvar_t **)matvar->data;
            if ( NULL != functions ) {
                for ( i = 0; i < nfunctions; i++ ) {
                    functions[i]->internal->fp = mat;
                    Read5(mat,functions[i]);
                }
            }
            /* FIXME: */
            matvar->data_type = MAT_T_FUNCTION;
            break;
        }
        default:
            Mat_Critical("Read5: %d is not a supported class", matvar->class_type);
    }
    (void)fseek((FILE*)mat->fp,fpos,SEEK_SET);

    return;
}

#if defined(HAVE_ZLIB)
#define GET_DATA_SLABN_RANK_LOOP \
    do { \
        for ( j = 1; j < rank; j++ ) { \
            cnt[j]++; \
            if ( (cnt[j] % edge[j]) == 0 ) { \
                cnt[j] = 0; \
                if ( (I % dimp[j]) != 0 ) { \
                    ptr_in += dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]; \
                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j]; \
                } else if ( start[j] ) { \
                    ptr_in += dimp[j-1]*start[j]; \
                    I += dimp[j-1]*start[j]; \
                } \
            } else { \
                I += inc[j]; \
                ptr_in += inc[j]; \
                break; \
            } \
        } \
    } while (0)

#define GET_DATA_SLAB2 \
    do { \
        ptr_in += start[1]*dims[0] + start[0]; \
        for ( i = 0; i < edge[1]; i++ ) { \
            for ( j = 0; j < edge[0]; j++ ) \
                memcpy(ptr++, ptr_in+j*stride[0], data_size); \
            ptr_in += stride[1]*dims[0]; \
        } \
    } while (0)

#define GET_DATA_SLABN \
    do { \
        inc[0]  = stride[0]-1; \
        dimp[0] = dims[0]; \
        N       = edge[0]; \
        I       = 0; /* start[0]; */ \
        for ( i = 1; i < rank; i++ ) { \
            inc[i]  = stride[i]-1; \
            dimp[i] = dims[i-1]; \
            for ( j = i; j--; ) { \
                inc[i]  *= dims[j]; \
                dimp[i] *= dims[j+1]; \
            } \
            N *= edge[i]; \
            I += dimp[i-1]*start[i]; \
        } \
        ptr_in += I; \
        if ( stride[0] == 1 ) { \
            for ( i = 0; i < N; i+=edge[0] ) { \
                if ( start[0] ) { \
                    ptr_in += start[0]; \
                    I += start[0]; \
                } \
                memcpy(ptr+i, ptr_in, edge[0]*data_size); \
                I += dims[0]-start[0]; \
                ptr_in += dims[0]-start[0]; \
                GET_DATA_SLABN_RANK_LOOP; \
            } \
        } else { \
            for ( i = 0; i < N; i+=edge[0] ) { \
                if ( start[0] ) { \
                    ptr_in += start[0]; \
                    I += start[0]; \
                } \
                for ( j = 0; j < edge[0]; j++ ) { \
                    memcpy(ptr+i+j, ptr_in, data_size); \
                    ptr_in += stride[0]; \
                    I += stride[0]; \
                } \
                I += dims[0]-edge[0]*stride[0]-start[0]; \
                ptr_in += dims[0]-edge[0]*stride[0]-start[0]; \
                GET_DATA_SLABN_RANK_LOOP; \
            } \
        } \
    } while (0)

static int
GetDataSlab(void *data_in, void *data_out, enum matio_classes class_type,
    enum matio_types data_type, size_t *dims, int *start, int *stride, int *edge,
    int rank, size_t nbytes)
{
    int err = 0;
    int data_size = Mat_SizeOf(data_type);

    if ( rank == 2 ) {
        if ( stride[0]*(edge[0]-1)+start[0]+1 > dims[0] )
            err = 1;
        else if ( stride[1]*(edge[1]-1)+start[1]+1 > dims[1] )
            err = 1;
        else if ( (stride[0] == 1 && edge[0] == dims[0]) &&
                  (stride[1] == 1) )
            memcpy(data_out, data_in, nbytes);
        else {
            int i, j;

            switch ( class_type ) {
                case MAT_C_DOUBLE:
                {
                    double *ptr = (double *)data_out;
                    double *ptr_in = (double *)data_in;
                    GET_DATA_SLAB2;
                    break;
                }
                case MAT_C_SINGLE:
                {
                    float *ptr = (float *)data_out;
                    float *ptr_in = (float *)data_in;
                    GET_DATA_SLAB2;
                    break;
                }
#ifdef HAVE_MATIO_INT64_T
                case MAT_C_INT64:
                {
                    mat_int64_t *ptr = (mat_int64_t *)data_out;
                    mat_int64_t *ptr_in = (mat_int64_t *)data_in;
                    GET_DATA_SLAB2;
                    break;
                }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
                case MAT_C_UINT64:
                {
                    mat_uint64_t *ptr = (mat_uint64_t *)data_out;
                    mat_uint64_t *ptr_in = (mat_uint64_t *)data_in;
                    GET_DATA_SLAB2;
                    break;
                }
#endif /* HAVE_MATIO_UINT64_T */
                case MAT_C_INT32:
                {
                    mat_int32_t *ptr = (mat_int32_t *)data_out;
                    mat_int32_t *ptr_in = (mat_int32_t *)data_in;
                    GET_DATA_SLAB2;
                    break;
                }
                case MAT_C_UINT32:
                {
                    mat_uint32_t *ptr = (mat_uint32_t *)data_out;
                    mat_uint32_t *ptr_in = (mat_uint32_t *)data_in;
                    GET_DATA_SLAB2;
                    break;
                }
                case MAT_C_INT16:
                {
                    mat_int16_t *ptr = (mat_int16_t *)data_out;
                    mat_int16_t *ptr_in = (mat_int16_t *)data_in;
                    GET_DATA_SLAB2;
                    break;
                }
                case MAT_C_UINT16:
                {
                    mat_uint16_t *ptr = (mat_uint16_t *)data_out;
                    mat_uint16_t *ptr_in = (mat_uint16_t *)data_in;
                    GET_DATA_SLAB2;
                    break;
                }
                case MAT_C_INT8:
                {
                    mat_int8_t *ptr = (mat_int8_t *)data_out;
                    mat_int8_t *ptr_in = (mat_int8_t *)data_in;
                    GET_DATA_SLAB2;
                    break;
                }
                case MAT_C_UINT8:
                {
                    mat_uint8_t *ptr = (mat_uint8_t *)data_out;
                    mat_uint8_t *ptr_in = (mat_uint8_t *)data_in;
                    GET_DATA_SLAB2;
                    break;
                }
                default:
                    err = 1;
                    break;
            }
        }
    } else {
        int nBytes = 0, i, j, N, I = 0;
        int inc[10] = {0,}, cnt[10] = {0,}, dimp[10] = {0,};

        switch ( class_type ) {
            case MAT_C_DOUBLE:
            {
                double *ptr = (double *)data_out;
                double *ptr_in = (double *)data_in;
                GET_DATA_SLABN;
                break;
            }
            case MAT_C_SINGLE:
            {
                float *ptr = (float *)data_out;
                float *ptr_in = (float *)data_in;
                GET_DATA_SLABN;
                break;
            }
#ifdef HAVE_MATIO_INT64_T
            case MAT_C_INT64:
            {
                mat_int64_t *ptr = (mat_int64_t *)data_out;
                mat_int64_t *ptr_in = (mat_int64_t *)data_in;
                GET_DATA_SLABN;
                break;
            }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
            case MAT_C_UINT64:
            {
                mat_uint64_t *ptr = (mat_uint64_t *)data_out;
                mat_uint64_t *ptr_in = (mat_uint64_t *)data_in;
                GET_DATA_SLABN;
                break;
            }
#endif /* HAVE_MATIO_UINT64_T */
            case MAT_C_INT32:
            {
                mat_int32_t *ptr = (mat_int32_t *)data_out;
                mat_int32_t *ptr_in = (mat_int32_t *)data_in;
                GET_DATA_SLABN;
                break;
            }
            case MAT_C_UINT32:
            {
                mat_uint32_t *ptr = (mat_uint32_t *)data_out;
                mat_uint32_t *ptr_in = (mat_uint32_t *)data_in;
                GET_DATA_SLABN;
                break;
            }
            case MAT_C_INT16:
            {
                mat_int16_t *ptr = (mat_int16_t *)data_out;
                mat_int16_t *ptr_in = (mat_int16_t *)data_in;
                GET_DATA_SLABN;
                break;
            }
            case MAT_C_UINT16:
            {
                mat_uint16_t *ptr = (mat_uint16_t *)data_out;
                mat_uint16_t *ptr_in = (mat_uint16_t *)data_in;
                GET_DATA_SLABN;
                break;
            }
            case MAT_C_INT8:
            {
                mat_int8_t *ptr = (mat_int8_t *)data_out;
                mat_int8_t *ptr_in = (mat_int8_t *)data_in;
                GET_DATA_SLABN;
                break;
            }
            case MAT_C_UINT8:
            {
                mat_uint8_t *ptr = (mat_uint8_t *)data_out;
                mat_uint8_t *ptr_in = (mat_uint8_t *)data_in;
                GET_DATA_SLABN;
                break;
            }
            default:
                err = 1;
                break;
        }
    }
    return err;
}

#undef GET_DATA_SLABN
#undef GET_DATA_SLAB2
#undef GET_DATA_SLABN_RANK_LOOP

#define GET_DATA_LINEAR \
    do { \
        ptr_in += start; \
        if ( !stride ) { \
            memcpy(ptr, ptr_in, edge*data_size); \
        } else { \
            int i; \
            for ( i = 0; i < edge; i++ ) \
                memcpy(ptr++, ptr_in+i*stride, data_size); \
        } \
    } while (0)

static int
GetDataLinear(void *data_in, void *data_out, enum matio_classes class_type,
    enum matio_types data_type, int start, int stride, int edge)
{
    int err = 0;
    int data_size = Mat_SizeOf(data_type);

    switch ( class_type ) {
        case MAT_C_DOUBLE:
        {
            double *ptr = (double *)data_out;
            double *ptr_in = (double*)data_in;
            GET_DATA_LINEAR;
            break;
        }
        case MAT_C_SINGLE:
        {
            float *ptr = (float *)data_out;
            float *ptr_in = (float*)data_in;
            GET_DATA_LINEAR;
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
        {
            mat_int64_t *ptr = (mat_int64_t *)data_out;
            mat_int64_t *ptr_in = (mat_int64_t*)data_in;
            GET_DATA_LINEAR;
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
        {
            mat_uint64_t *ptr = (mat_uint64_t *)data_out;
            mat_uint64_t *ptr_in = (mat_uint64_t*)data_in;
            GET_DATA_LINEAR;
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
        {
            mat_int32_t *ptr = (mat_int32_t *)data_out;
            mat_int32_t *ptr_in = (mat_int32_t*)data_in;
            GET_DATA_LINEAR;
            break;
        }
        case MAT_C_UINT32:
        {
            mat_uint32_t *ptr = (mat_uint32_t *)data_out;
            mat_uint32_t *ptr_in = (mat_uint32_t*)data_in;
            GET_DATA_LINEAR;
            break;
        }
        case MAT_C_INT16:
        {
            mat_int16_t *ptr = (mat_int16_t *)data_out;
            mat_int16_t *ptr_in = (mat_int16_t*)data_in;
            GET_DATA_LINEAR;
            break;
        }
        case MAT_C_UINT16:
        {
            mat_uint16_t *ptr = (mat_uint16_t *)data_out;
            mat_uint16_t *ptr_in = (mat_uint16_t*)data_in;
            GET_DATA_LINEAR;
            break;
        }
        case MAT_C_INT8:
        {
            mat_int8_t *ptr = (mat_int8_t *)data_out;
            mat_int8_t *ptr_in = (mat_int8_t*)data_in;
            GET_DATA_LINEAR;
            break;
        }
        case MAT_C_UINT8:
        {
            mat_uint8_t *ptr = (mat_uint8_t *)data_out;
            mat_uint8_t *ptr_in = (mat_uint8_t*)data_in;
            GET_DATA_LINEAR;
            break;
        }
        default:
            err = 1;
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
ReadData5(mat_t *mat,matvar_t *matvar,void *data,
    int *start,int *stride,int *edge)
{
    int err = 0,real_bytes = 0;
    mat_int32_t tag[2];
    size_t bytesread = 0;
#if defined(HAVE_ZLIB)
    z_stream z;
#endif

    (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
    if ( matvar->compression == MAT_COMPRESSION_NONE ) {
        bytesread += fread(tag,4,2,(FILE*)mat->fp);
        if ( mat->byteswap ) {
            Mat_int32Swap(tag);
            Mat_int32Swap(tag+1);
        }
        matvar->data_type = TYPE_FROM_TAG(tag[0]);
        if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
            (void)fseek((FILE*)mat->fp,-4,SEEK_CUR);
            real_bytes = 4+(tag[0] >> 16);
        } else {
            real_bytes = 8+tag[1];
        }
#if defined(HAVE_ZLIB)
    } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
        if ( NULL != matvar->internal->data ) {
            /* Data already read in ReadNextStructField or ReadNextCell */
            if ( matvar->isComplex ) {
                mat_complex_split_t *ci, *co;

                co = (mat_complex_split_t*)data;
                ci = (mat_complex_split_t*)matvar->internal->data;
                err = GetDataSlab(ci->Re, co->Re, matvar->class_type,
                    matvar->data_type, matvar->dims, start, stride, edge,
                    matvar->rank, matvar->nbytes);
                if ( err == 0 )
                    err = GetDataSlab(ci->Im, co->Im, matvar->class_type,
                        matvar->data_type, matvar->dims, start, stride, edge,
                        matvar->rank, matvar->nbytes);
                return err;
            } else {
                return GetDataSlab(matvar->internal->data, data, matvar->class_type,
                    matvar->data_type, matvar->dims, start, stride, edge,
                    matvar->rank, matvar->nbytes);
            }
        }

        err = inflateCopy(&z,matvar->internal->z);
        if ( err != Z_OK ) {
            Mat_Critical("inflateCopy returned error %s",zError(err));
            return -1;
        }
        z.avail_in = 0;
        InflateDataType(mat,&z,tag);
        if ( mat->byteswap ) {
            Mat_int32Swap(tag);
        }
        matvar->data_type = TYPE_FROM_TAG(tag[0]);
        if ( !(tag[0] & 0xffff0000) ) {/* Data is NOT packed in the tag */
            /* We're cheating, but InflateDataType just inflates 4 bytes */
            InflateDataType(mat,&z,tag+1);
            if ( mat->byteswap ) {
                Mat_int32Swap(tag+1);
            }
            real_bytes = 8+tag[1];
        } else {
            real_bytes = 4+(tag[0] >> 16);
        }
#endif
    }
    if ( real_bytes % 8 )
        real_bytes += (8-(real_bytes % 8));

    if ( matvar->rank == 2 ) {
        if ( stride[0]*(edge[0]-1)+start[0]+1 > matvar->dims[0] )
            err = 1;
        else if ( stride[1]*(edge[1]-1)+start[1]+1 > matvar->dims[1] )
            err = 1;
        else if ( matvar->compression == MAT_COMPRESSION_NONE ) {
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)data;

                ReadDataSlab2(mat,complex_data->Re,matvar->class_type,
                    matvar->data_type,matvar->dims,start,stride,edge);
                (void)fseek((FILE*)mat->fp,matvar->internal->datapos+real_bytes,SEEK_SET);
                bytesread += fread(tag,4,2,(FILE*)mat->fp);
                if ( mat->byteswap ) {
                    Mat_int32Swap(tag);
                    Mat_int32Swap(tag+1);
                }
                matvar->data_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
                    (void)fseek((FILE*)mat->fp,-4,SEEK_CUR);
                }
                ReadDataSlab2(mat,complex_data->Im,matvar->class_type,
                              matvar->data_type,matvar->dims,start,stride,edge);
            } else {
                ReadDataSlab2(mat,data,matvar->class_type,
                    matvar->data_type,matvar->dims,start,stride,edge);
            }
        }
#if defined(HAVE_ZLIB)
        else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)data;

                ReadCompressedDataSlab2(mat,&z,complex_data->Re,
                    matvar->class_type,matvar->data_type,matvar->dims,
                    start,stride,edge);

                (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);

                /* Reset zlib knowledge to before reading real tag */
                inflateEnd(&z);
                err = inflateCopy(&z,matvar->internal->z);
                if ( err != Z_OK ) {
                    Mat_Critical("inflateCopy returned error %s",zError(err));
                }
                InflateSkip(mat,&z,real_bytes);
                z.avail_in = 0;
                InflateDataType(mat,&z,tag);
                if ( mat->byteswap ) {
                    Mat_int32Swap(tag);
                }
                matvar->data_type = TYPE_FROM_TAG(tag[0]);
                if ( !(tag[0] & 0xffff0000) ) {/*Data is NOT packed in the tag*/
                    InflateSkip(mat,&z,4);
                }
                ReadCompressedDataSlab2(mat,&z,complex_data->Im,
                    matvar->class_type,matvar->data_type,matvar->dims,
                    start,stride,edge);
            } else {
                ReadCompressedDataSlab2(mat,&z,data,matvar->class_type,
                    matvar->data_type,matvar->dims,start,stride,edge);
            }
            inflateEnd(&z);
        }
#endif
    } else {
        if ( matvar->compression == MAT_COMPRESSION_NONE ) {
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)data;

                ReadDataSlabN(mat,complex_data->Re,matvar->class_type,
                    matvar->data_type,matvar->rank,matvar->dims,
                    start,stride,edge);

                (void)fseek((FILE*)mat->fp,matvar->internal->datapos+real_bytes,SEEK_SET);
                bytesread += fread(tag,4,2,(FILE*)mat->fp);
                if ( mat->byteswap ) {
                    Mat_int32Swap(tag);
                    Mat_int32Swap(tag+1);
                }
                matvar->data_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
                    (void)fseek((FILE*)mat->fp,-4,SEEK_CUR);
                }
                ReadDataSlabN(mat,complex_data->Im,matvar->class_type,
                    matvar->data_type,matvar->rank,matvar->dims,
                    start,stride,edge);
            } else {
                ReadDataSlabN(mat,data,matvar->class_type,matvar->data_type,
                    matvar->rank,matvar->dims,start,stride,edge);
            }
        }
#if defined(HAVE_ZLIB)
        else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)data;

                ReadCompressedDataSlabN(mat,&z,complex_data->Re,
                    matvar->class_type,matvar->data_type,matvar->rank,
                    matvar->dims,start,stride,edge);

                (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
                /* Reset zlib knowledge to before reading real tag */
                inflateEnd(&z);
                err = inflateCopy(&z,matvar->internal->z);
                if ( err != Z_OK ) {
                    Mat_Critical("inflateCopy returned error %s",zError(err));
                }
                InflateSkip(mat,&z,real_bytes);
                z.avail_in = 0;
                InflateDataType(mat,&z,tag);
                if ( mat->byteswap ) {
                    Mat_int32Swap(tag);
                }
                matvar->data_type = TYPE_FROM_TAG(tag[0]);
                if ( !(tag[0] & 0xffff0000) ) {/*Data is NOT packed in the tag*/
                    InflateSkip(mat,&z,4);
                }
                ReadCompressedDataSlabN(mat,&z,complex_data->Im,
                    matvar->class_type,matvar->data_type,matvar->rank,
                    matvar->dims,start,stride,edge);
            } else {
                ReadCompressedDataSlabN(mat,&z,data,matvar->class_type,
                    matvar->data_type,matvar->rank,matvar->dims,
                    start,stride,edge);
            }
            inflateEnd(&z);
        }
#endif
    }
    if ( err )
        return err;

    switch ( matvar->class_type ) {
        case MAT_C_DOUBLE:
            matvar->data_type = MAT_T_DOUBLE;
            matvar->data_size = sizeof(double);
            break;
        case MAT_C_SINGLE:
            matvar->data_type = MAT_T_SINGLE;
            matvar->data_size = sizeof(float);
            break;
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
            matvar->data_type = MAT_T_INT64;
            matvar->data_size = sizeof(mat_int64_t);
            break;
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
            matvar->data_type = MAT_T_UINT64;
            matvar->data_size = sizeof(mat_uint64_t);
            break;
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
            matvar->data_type = MAT_T_INT32;
            matvar->data_size = sizeof(mat_int32_t);
            break;
        case MAT_C_UINT32:
            matvar->data_type = MAT_T_UINT32;
            matvar->data_size = sizeof(mat_uint32_t);
            break;
        case MAT_C_INT16:
            matvar->data_type = MAT_T_INT16;
            matvar->data_size = sizeof(mat_int16_t);
            break;
        case MAT_C_UINT16:
            matvar->data_type = MAT_T_UINT16;
            matvar->data_size = sizeof(mat_uint16_t);
            break;
        case MAT_C_INT8:
            matvar->data_type = MAT_T_INT8;
            matvar->data_size = sizeof(mat_int8_t);
            break;
        case MAT_C_UINT8:
            matvar->data_type = MAT_T_UINT8;
            matvar->data_size = sizeof(mat_uint8_t);
            break;
        default:
            break;
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
Mat_VarReadDataLinear5(mat_t *mat,matvar_t *matvar,void *data,int start,
                      int stride,int edge)
{
    int err = 0, nmemb = 1, i, real_bytes = 0;
    mat_int32_t tag[2];
    size_t bytesread = 0;
#if defined(HAVE_ZLIB)
    z_stream z;
#endif

    if ( mat->version == MAT_FT_MAT4 )
        return -1;
    (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);
    if ( matvar->compression == MAT_COMPRESSION_NONE ) {
        bytesread += fread(tag,4,2,(FILE*)mat->fp);
        if ( mat->byteswap ) {
            Mat_int32Swap(tag);
            Mat_int32Swap(tag+1);
        }
        matvar->data_type = (enum matio_types)(tag[0] & 0x000000ff);
        if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
            (void)fseek((FILE*)mat->fp,-4,SEEK_CUR);
            real_bytes = 4+(tag[0] >> 16);
        } else {
            real_bytes = 8+tag[1];
        }
#if defined(HAVE_ZLIB)
    } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
        if ( NULL != matvar->internal->data ) {
            /* Data already read in ReadNextStructField or ReadNextCell */
            if ( matvar->isComplex ) {
                mat_complex_split_t *ci, *co;

                co = (mat_complex_split_t*)data;
                ci = (mat_complex_split_t*)matvar->internal->data;
                err = GetDataLinear(ci->Re, co->Re, matvar->class_type,
                    matvar->data_type, start, stride, edge);
                if ( err == 0 )
                    err = GetDataLinear(ci->Im, co->Im, matvar->class_type,
                        matvar->data_type, start, stride, edge);
                return err;
            } else {
                return GetDataLinear(matvar->internal->data, data, matvar->class_type,
                    matvar->data_type, start, stride, edge);
            }
        }

        matvar->internal->z->avail_in = 0;
        err = inflateCopy(&z,matvar->internal->z);
        if ( err != Z_OK ) {
            Mat_Critical("inflateCopy returned error %s",zError(err));
            return -1;
        }
        InflateDataType(mat,&z,tag);
        if ( mat->byteswap ) {
            Mat_int32Swap(tag);
            Mat_int32Swap(tag+1);
        }
        matvar->data_type = (enum matio_types)(tag[0] & 0x000000ff);
        if ( !(tag[0] & 0xffff0000) ) {/* Data is NOT packed in the tag */
            /* We're cheating, but InflateDataType just inflates 4 bytes */
            InflateDataType(mat,&z,tag+1);
            if ( mat->byteswap ) {
                Mat_int32Swap(tag+1);
            }
            real_bytes = 8+tag[1];
        } else {
            real_bytes = 4+(tag[0] >> 16);
        }
#endif
    }
    if ( real_bytes % 8 )
        real_bytes += (8-(real_bytes % 8));

    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];

    if ( stride*(edge-1)+start+1 > nmemb ) {
        err = 1;
    } else if ( matvar->compression == MAT_COMPRESSION_NONE ) {
        if ( matvar->isComplex ) {
            mat_complex_split_t *complex_data = (mat_complex_split_t*)data;

            ReadDataSlab1(mat,complex_data->Re,matvar->class_type,
                          matvar->data_type,start,stride,edge);
            (void)fseek((FILE*)mat->fp,matvar->internal->datapos+real_bytes,SEEK_SET);
            bytesread += fread(tag,4,2,(FILE*)mat->fp);
            if ( mat->byteswap ) {
                Mat_int32Swap(tag);
                Mat_int32Swap(tag+1);
            }
            matvar->data_type = (enum matio_types)(tag[0] & 0x000000ff);
            if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
                (void)fseek((FILE*)mat->fp,-4,SEEK_CUR);
            }
            ReadDataSlab1(mat,complex_data->Im,matvar->class_type,
                          matvar->data_type,start,stride,edge);
        } else {
            ReadDataSlab1(mat,data,matvar->class_type,
                          matvar->data_type,start,stride,edge);
        }
#if defined(HAVE_ZLIB)
    } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
        if ( matvar->isComplex ) {
            mat_complex_split_t *complex_data = (mat_complex_split_t*)data;

            ReadCompressedDataSlab1(mat,&z,complex_data->Re,
                matvar->class_type,matvar->data_type,start,stride,edge);

            (void)fseek((FILE*)mat->fp,matvar->internal->datapos,SEEK_SET);

            /* Reset zlib knowledge to before reading real tag */
            inflateEnd(&z);
            err = inflateCopy(&z,matvar->internal->z);
            if ( err != Z_OK ) {
                Mat_Critical("inflateCopy returned error %s",zError(err));
            }
            InflateSkip(mat,&z,real_bytes);
            z.avail_in = 0;
            InflateDataType(mat,&z,tag);
            if ( mat->byteswap ) {
                Mat_int32Swap(tag);
            }
            matvar->data_type = (enum matio_types)(tag[0] & 0x000000ff);
            if ( !(tag[0] & 0xffff0000) ) {/*Data is NOT packed in the tag*/
                InflateSkip(mat,&z,4);
            }
            ReadCompressedDataSlab1(mat,&z,complex_data->Im,
                matvar->class_type,matvar->data_type,start,stride,edge);
        } else {
            ReadCompressedDataSlab1(mat,&z,data,matvar->class_type,
                matvar->data_type,start,stride,edge);
        }
        inflateEnd(&z);
#endif
    }

    switch(matvar->class_type) {
        case MAT_C_DOUBLE:
            matvar->data_type = MAT_T_DOUBLE;
            matvar->data_size = sizeof(double);
            break;
        case MAT_C_SINGLE:
            matvar->data_type = MAT_T_SINGLE;
            matvar->data_size = sizeof(float);
            break;
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
            matvar->data_type = MAT_T_INT64;
            matvar->data_size = sizeof(mat_int64_t);
            break;
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
            matvar->data_type = MAT_T_UINT64;
            matvar->data_size = sizeof(mat_uint64_t);
            break;
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
            matvar->data_type = MAT_T_INT32;
            matvar->data_size = sizeof(mat_int32_t);
            break;
        case MAT_C_UINT32:
            matvar->data_type = MAT_T_UINT32;
            matvar->data_size = sizeof(mat_uint32_t);
            break;
        case MAT_C_INT16:
            matvar->data_type = MAT_T_INT16;
            matvar->data_size = sizeof(mat_int16_t);
            break;
        case MAT_C_UINT16:
            matvar->data_type = MAT_T_UINT16;
            matvar->data_size = sizeof(mat_uint16_t);
            break;
        case MAT_C_INT8:
            matvar->data_type = MAT_T_INT8;
            matvar->data_size = sizeof(mat_int8_t);
            break;
        case MAT_C_UINT8:
            matvar->data_type = MAT_T_UINT8;
            matvar->data_size = sizeof(mat_uint8_t);
            break;
        default:
            break;
    }

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
Mat_VarWrite5(mat_t *mat,matvar_t *matvar,int compress)
{
    mat_uint32_t array_flags = 0x0;
    mat_int16_t  fieldname_type = MAT_T_INT32,fieldname_data_size=4;
    mat_int8_t  pad1 = 0;
    int      array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int      array_flags_size = 8, pad4 = 0, matrix_type = MAT_T_MATRIX;
    int      nBytes, i, nmemb = 1,nzmax = 0;
    long     start = 0, end = 0;

    if ( NULL == mat )
        return -1;

    /* FIXME: SEEK_END is not Guaranteed by the C standard */
    (void)fseek((FILE*)mat->fp,0,SEEK_END);         /* Always write at end of file */

    if ( NULL == matvar || NULL == matvar->name )
        return -1;

#if !defined(HAVE_ZLIB)
    compress = MAT_COMPRESSION_NONE;
#endif

    if ( compress == MAT_COMPRESSION_NONE ) {
        fwrite(&matrix_type,4,1,(FILE*)mat->fp);
        fwrite(&pad4,4,1,(FILE*)mat->fp);
        start = ftell((FILE*)mat->fp);

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

        fwrite(&array_flags_type,4,1,(FILE*)mat->fp);
        fwrite(&array_flags_size,4,1,(FILE*)mat->fp);
        fwrite(&array_flags,4,1,(FILE*)mat->fp);
        fwrite(&nzmax,4,1,(FILE*)mat->fp);
        /* Rank and Dimension */
        nBytes = matvar->rank * 4;
        fwrite(&dims_array_type,4,1,(FILE*)mat->fp);
        fwrite(&nBytes,4,1,(FILE*)mat->fp);
        for ( i = 0; i < matvar->rank; i++ ) {
            mat_int32_t dim;
            dim = matvar->dims[i];
            nmemb *= dim;
            fwrite(&dim,4,1,(FILE*)mat->fp);
        }
        if ( matvar->rank % 2 != 0 )
            fwrite(&pad4,4,1,(FILE*)mat->fp);
        /* Name of variable */
        if ( strlen(matvar->name) <= 4 ) {
            mat_int32_t  array_name_type = MAT_T_INT8;
            mat_int32_t array_name_len   = strlen(matvar->name);
            mat_int8_t  pad1 = 0;
#if 0
            fwrite(&array_name_type,2,1,(FILE*)mat->fp);
            fwrite(&array_name_len,2,1,(FILE*)mat->fp);
#else
            array_name_type = (array_name_len << 16) | array_name_type;
            fwrite(&array_name_type,4,1,(FILE*)mat->fp);
#endif
            fwrite(matvar->name,1,array_name_len,(FILE*)mat->fp);
            for ( i = array_name_len; i < 4; i++ )
                fwrite(&pad1,1,1,(FILE*)mat->fp);
        } else {
            mat_int32_t array_name_type = MAT_T_INT8;
            mat_int32_t array_name_len  = (mat_int32_t)strlen(matvar->name);
            mat_int8_t  pad1 = 0;

            fwrite(&array_name_type,4,1,(FILE*)mat->fp);
            fwrite(&array_name_len,4,1,(FILE*)mat->fp);
            fwrite(matvar->name,1,array_name_len,(FILE*)mat->fp);
            if ( array_name_len % 8 )
                for ( i = array_name_len % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,(FILE*)mat->fp);
        }

        matvar->internal->datapos = ftell((FILE*)mat->fp);
        if ( matvar->internal->datapos == -1L ) {
            Mat_Critical("Couldn't determine file position");
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
            case MAT_C_UINT8:
            {
                if ( matvar->isComplex ) {
                    mat_complex_split_t *complex_data = (mat_complex_split_t*)matvar->data;

                    if ( NULL == complex_data )
                        complex_data = &null_complex_data;

                    nBytes = WriteData(mat,complex_data->Re,nmemb,
                        matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,(FILE*)mat->fp);
                    nBytes = WriteData(mat,complex_data->Im,nmemb,
                        matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,(FILE*)mat->fp);
                } else {
                    nBytes=WriteData(mat,matvar->data,nmemb,matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,(FILE*)mat->fp);
                }
                break;
            }
            case MAT_C_CHAR:
            {
                WriteCharData(mat,matvar->data,nmemb,matvar->data_type);
                break;
            }
            case MAT_C_CELL:
            {
                int        ncells;
                matvar_t **cells = (matvar_t **)matvar->data;

                /* Check for an empty cell array */
                if ( matvar->nbytes == 0 || matvar->data_size == 0 ||
                     matvar->data   == NULL )
                    break;
                ncells  = matvar->nbytes / matvar->data_size;
                for ( i = 0; i < ncells; i++ )
                    WriteCellArrayField(mat,cells[i]);
                break;
            }
            case MAT_C_STRUCT:
            {
                char      *padzero;
                int        fieldname_size, nfields;
                size_t     maxlen = 0;
                matvar_t **fields = (matvar_t **)matvar->data;
                mat_int32_t array_name_type = MAT_T_INT8;
                unsigned   fieldname;

                nfields = matvar->internal->num_fields;
                /* Check for a structure with no fields */
                if ( nfields < 1 ) {
#if 0
                    fwrite(&fieldname_type,2,1,(FILE*)mat->fp);
                    fwrite(&fieldname_data_size,2,1,(FILE*)mat->fp);
#else
                    fieldname = (fieldname_data_size<<16) | fieldname_type;
                    fwrite(&fieldname,4,1,(FILE*)mat->fp);
#endif
                    fieldname_size = 1;
                    fwrite(&fieldname_size,4,1,(FILE*)mat->fp);
                    fwrite(&array_name_type,4,1,(FILE*)mat->fp);
                    nBytes = 0;
                    fwrite(&nBytes,4,1,(FILE*)mat->fp);
                    break;
                }

                for ( i = 0; i < nfields; i++ ) {
                    size_t len = strlen(matvar->internal->fieldnames[i]);
                    if ( len > maxlen )
                        maxlen = len;
                }
                maxlen++;
                fieldname_size = maxlen;
                while ( nfields*fieldname_size % 8 != 0 )
                    fieldname_size++;
#if 0
                fwrite(&fieldname_type,2,1,(FILE*)mat->fp);
                fwrite(&fieldname_data_size,2,1,(FILE*)mat->fp);
#else
                fieldname = (fieldname_data_size<<16) | fieldname_type;
                fwrite(&fieldname,4,1,(FILE*)mat->fp);
#endif
                fwrite(&fieldname_size,4,1,(FILE*)mat->fp);
                fwrite(&array_name_type,4,1,(FILE*)mat->fp);
                nBytes = nfields*fieldname_size;
                fwrite(&nBytes,4,1,(FILE*)mat->fp);
                padzero = (char*)calloc(fieldname_size,1);
                for ( i = 0; i < nfields; i++ ) {
                    size_t len = strlen(matvar->internal->fieldnames[i]);
                    fwrite(matvar->internal->fieldnames[i],1,len,(FILE*)mat->fp);
                    fwrite(padzero,1,fieldname_size-len,(FILE*)mat->fp);
                }
                free(padzero);
                for ( i = 0; i < nmemb*nfields; i++ )
                    WriteStructField(mat,fields[i]);
                break;
            }
            case MAT_C_SPARSE:
            {
                mat_sparse_t *sparse = (mat_sparse_t*)matvar->data;

                nBytes = WriteData(mat,sparse->ir,sparse->nir,MAT_T_INT32);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
                nBytes = WriteData(mat,sparse->jc,sparse->njc,MAT_T_INT32);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
                if ( matvar->isComplex ) {
                    mat_complex_split_t *complex_data = (mat_complex_split_t*)sparse->data;
                    nBytes = WriteData(mat,complex_data->Re,sparse->ndata,
                        matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,(FILE*)mat->fp);
                    nBytes = WriteData(mat,complex_data->Im,sparse->ndata,
                        matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,(FILE*)mat->fp);
                } else {
                    nBytes = WriteData(mat,sparse->data,sparse->ndata,matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,(FILE*)mat->fp);
                }
            }
            case MAT_C_EMPTY:
            case MAT_C_FUNCTION:
            case MAT_C_OBJECT:
                break;
        }
#if defined(HAVE_ZLIB)
    } else if ( compress == MAT_COMPRESSION_ZLIB ) {
        mat_uint32_t comp_buf[512];
        mat_uint32_t uncomp_buf[512] = {0,};
        int buf_size = 512, err;
        size_t byteswritten = 0;

        if (matvar->internal->z != NULL) {
            inflateEnd(matvar->internal->z);
            free(matvar->internal->z);
        }
        matvar->internal->z = (z_streamp)calloc(1,sizeof(*matvar->internal->z));
        err = deflateInit(matvar->internal->z,Z_DEFAULT_COMPRESSION);
        if ( err != Z_OK ) {
            free(matvar->internal->z);
            matvar->internal->z = NULL;
            Mat_Critical("deflateInit returned %s",zError(err));
            return -1;
        }

        matrix_type = MAT_T_COMPRESSED;
        fwrite(&matrix_type,4,1,(FILE*)mat->fp);
        fwrite(&pad4,4,1,(FILE*)mat->fp);
        start = ftell((FILE*)mat->fp);

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

        uncomp_buf[0] = MAT_T_MATRIX;
        uncomp_buf[1] = (int)GetMatrixMaxBufSize(matvar);
        matvar->internal->z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
        matvar->internal->z->avail_in = 8;
        do {
            matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
            matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
            deflate(matvar->internal->z,Z_NO_FLUSH);
            byteswritten += fwrite(comp_buf,1,
                buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,(FILE*)mat->fp);
        } while ( matvar->internal->z->avail_out == 0 );
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
            nmemb *= dim;
            uncomp_buf[6+i] = dim;
        }
        if ( matvar->rank % 2 != 0 ) {
            uncomp_buf[6+i] = pad4;
            i++;
        }

        matvar->internal->z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
        matvar->internal->z->avail_in = (6+i)*sizeof(*uncomp_buf);
        do {
            matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
            matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
            deflate(matvar->internal->z,Z_NO_FLUSH);
            byteswritten += fwrite(comp_buf,1,
                buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,(FILE*)mat->fp);
        } while ( matvar->internal->z->avail_out == 0 );
        /* Name of variable */
        if ( strlen(matvar->name) <= 4 ) {
            mat_int16_t array_name_len = (mat_int16_t)strlen(matvar->name);
            mat_int16_t array_name_type = MAT_T_INT8;

            memset(uncomp_buf,0,8);
            uncomp_buf[0] = (array_name_len << 16) | array_name_type;
            memcpy(uncomp_buf+1,matvar->name,array_name_len);
            if ( array_name_len % 4 )
                array_name_len += 4-(array_name_len % 4);

            matvar->internal->z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
            matvar->internal->z->avail_in = 8;
            do {
                matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
                deflate(matvar->internal->z,Z_NO_FLUSH);
                byteswritten += fwrite(comp_buf,1,
                    buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,(FILE*)mat->fp);
            } while ( matvar->internal->z->avail_out == 0 );
        } else {
            mat_int32_t array_name_len = (mat_int32_t)strlen(matvar->name);
            mat_int32_t array_name_type = MAT_T_INT8;

            memset(uncomp_buf,0,buf_size*sizeof(*uncomp_buf));
            uncomp_buf[0] = array_name_type;
            uncomp_buf[1] = array_name_len;
            memcpy(uncomp_buf+2,matvar->name,array_name_len);
            if ( array_name_len % 8 )
                array_name_len += 8-(array_name_len % 8);
            matvar->internal->z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
            matvar->internal->z->avail_in = 8+array_name_len;
            do {
                matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
                deflate(matvar->internal->z,Z_NO_FLUSH);
                byteswritten += fwrite(comp_buf,1,
                    buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,(FILE*)mat->fp);
            } while ( matvar->internal->z->avail_out == 0 );
        }
        matvar->internal->datapos = ftell((FILE*)mat->fp);
        if ( matvar->internal->datapos == -1L ) {
            Mat_Critical("Couldn't determine file position");
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
            case MAT_C_UINT8:
            {
                /* WriteCompressedData makes sure uncompressed data is aligned
                 * on an 8-byte boundary */
                if ( matvar->isComplex ) {
                    mat_complex_split_t *complex_data = (mat_complex_split_t*)matvar->data;

                    if ( NULL == matvar->data )
                        complex_data = &null_complex_data;

                    byteswritten += WriteCompressedData(mat,matvar->internal->z,
                        complex_data->Re,nmemb,matvar->data_type);
                    byteswritten += WriteCompressedData(mat,matvar->internal->z,
                        complex_data->Im,nmemb,matvar->data_type);
                } else {
                    byteswritten += WriteCompressedData(mat,matvar->internal->z,
                        matvar->data,nmemb,matvar->data_type);
                }
                break;
            }
            case MAT_C_CHAR:
            {
                byteswritten += WriteCompressedCharData(mat,matvar->internal->z,
                    matvar->data,nmemb,matvar->data_type);
                break;
            }
            case MAT_C_CELL:
            {
                int        ncells;
                matvar_t **cells = (matvar_t **)matvar->data;

                /* Check for an empty cell array */
                if ( matvar->nbytes == 0 || matvar->data_size == 0 ||
                     matvar->data   == NULL )
                    break;
                ncells  = matvar->nbytes / matvar->data_size;
                for ( i = 0; i < ncells; i++ )
                    WriteCompressedCellArrayField(mat,cells[i],matvar->internal->z);
                break;
            }
            case MAT_C_STRUCT:
            {
                unsigned char *padzero;
                int        fieldname_size, nfields;
                size_t     maxlen = 0;
                mat_int32_t array_name_type = MAT_T_INT8;
                matvar_t **fields = (matvar_t **)matvar->data;

                nfields = matvar->internal->num_fields;
                /* Check for a structure with no fields */
                if ( nfields < 1 ) {
                    fieldname_size = 1;
                    uncomp_buf[0] = (fieldname_data_size << 16) |
                                     fieldname_type;
                    uncomp_buf[1] = fieldname_size;
                    uncomp_buf[2] = array_name_type;
                    uncomp_buf[3] = 0;
                    matvar->internal->z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
                    matvar->internal->z->avail_in = 16;
                    do {
                        matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                        matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
                        deflate(matvar->internal->z,Z_NO_FLUSH);
                        byteswritten += fwrite(comp_buf,1,buf_size*
                            sizeof(*comp_buf)-matvar->internal->z->avail_out,(FILE*)mat->fp);
                    } while ( matvar->internal->z->avail_out == 0 );
                    break;
                }

                for ( i = 0; i < nfields; i++ ) {
                    size_t len = strlen(matvar->internal->fieldnames[i]);
                    if ( len > maxlen )
                        maxlen = len;
                }
                maxlen++;
                fieldname_size = maxlen;
                while ( nfields*fieldname_size % 8 != 0 )
                    fieldname_size++;
                uncomp_buf[0] = (fieldname_data_size << 16) | fieldname_type;
                uncomp_buf[1] = fieldname_size;
                uncomp_buf[2] = array_name_type;
                uncomp_buf[3] = nfields*fieldname_size;

                padzero = (unsigned char*)calloc(fieldname_size,1);
                matvar->internal->z->next_in  = ZLIB_BYTE_PTR(uncomp_buf);
                matvar->internal->z->avail_in = 16;
                do {
                    matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                    matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
                    deflate(matvar->internal->z,Z_NO_FLUSH);
                    byteswritten += fwrite(comp_buf,1,
                        buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,(FILE*)mat->fp);
                } while ( matvar->internal->z->avail_out == 0 );
                for ( i = 0; i < nfields; i++ ) {
                    size_t len = strlen(matvar->internal->fieldnames[i]);
                    memset(padzero,'\0',fieldname_size);
                    memcpy(padzero,matvar->internal->fieldnames[i],len);
                    matvar->internal->z->next_in  = ZLIB_BYTE_PTR(padzero);
                    matvar->internal->z->avail_in = fieldname_size;
                    do {
                        matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                        matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
                        deflate(matvar->internal->z,Z_NO_FLUSH);
                        byteswritten += fwrite(comp_buf,1,
                            buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,
                            (FILE*)mat->fp);
                    } while ( matvar->internal->z->avail_out == 0 );
                }
                free(padzero);
                for ( i = 0; i < nmemb*nfields; i++ )
                    byteswritten +=
                        WriteCompressedStructField(mat,fields[i],matvar->internal->z);
                break;
            }
            case MAT_C_SPARSE:
            {
                mat_sparse_t *sparse = (mat_sparse_t*)matvar->data;

                byteswritten += WriteCompressedData(mat,matvar->internal->z,sparse->ir,
                    sparse->nir,MAT_T_INT32);
                byteswritten += WriteCompressedData(mat,matvar->internal->z,sparse->jc,
                    sparse->njc,MAT_T_INT32);
                if ( matvar->isComplex ) {
                    mat_complex_split_t *complex_data = (mat_complex_split_t*)sparse->data;
                    byteswritten += WriteCompressedData(mat,matvar->internal->z,
                        complex_data->Re,sparse->ndata,matvar->data_type);
                    byteswritten += WriteCompressedData(mat,matvar->internal->z,
                        complex_data->Im,sparse->ndata,matvar->data_type);
                } else {
                    byteswritten += WriteCompressedData(mat,matvar->internal->z,
                        sparse->data,sparse->ndata,matvar->data_type);
                }
                break;
            }
            case MAT_C_EMPTY:
            case MAT_C_FUNCTION:
            case MAT_C_OBJECT:
                break;
        }
        matvar->internal->z->next_in  = NULL;
        matvar->internal->z->avail_in = 0;
        do {
            matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
            matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
            err = deflate(matvar->internal->z,Z_FINISH);
            byteswritten += fwrite(comp_buf,1,
                buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,(FILE*)mat->fp);
        } while ( err != Z_STREAM_END && matvar->internal->z->avail_out == 0 );
        /* End the compression and set to NULL so Mat_VarFree doesn't try
         * to free matvar->internal->z with inflateEnd
         */
#if 0
        if ( byteswritten % 8 )
            for ( i = 0; i < 8-(byteswritten % 8); i++ )
                fwrite(&pad1,1,1,(FILE*)mat->fp);
#endif
        (void)deflateEnd(matvar->internal->z);
        free(matvar->internal->z);
        matvar->internal->z = NULL;
#endif
    }
    end = ftell((FILE*)mat->fp);
    if ( start != -1L && end != -1L ) {
        nBytes = (int)(end-start);
        (void)fseek((FILE*)mat->fp,(long)-(nBytes+4),SEEK_CUR);
        fwrite(&nBytes,4,1,(FILE*)mat->fp);
        (void)fseek((FILE*)mat->fp,end,SEEK_SET);
    } else {
        Mat_Critical("Couldn't determine file position");
    }

    return 0;
}

/** @if mat_devman
 * @brief Writes the variable information and empty data
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar pointer to the mat variable
 * @endif
 */
static void
WriteInfo5(mat_t *mat, matvar_t *matvar)
{
    mat_uint32_t array_flags = 0x0;
    mat_int16_t  fieldname_type = MAT_T_INT32,fieldname_data_size=4;
    mat_int8_t  pad1 = 0;
    int      array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int      array_flags_size = 8, pad4 = 0, matrix_type = MAT_T_MATRIX;
    int      nBytes, i, nmemb = 1,nzmax = 0;
    long     start = 0, end = 0;

    /* FIXME: SEEK_END is not Guaranteed by the C standard */
    (void)fseek((FILE*)mat->fp,0,SEEK_END);         /* Always write at end of file */

    if ( matvar->compression == MAT_COMPRESSION_NONE ) {
        fwrite(&matrix_type,4,1,(FILE*)mat->fp);
        fwrite(&pad4,4,1,(FILE*)mat->fp);
        start = ftell((FILE*)mat->fp);

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

        fwrite(&array_flags_type,4,1,(FILE*)mat->fp);
        fwrite(&array_flags_size,4,1,(FILE*)mat->fp);
        fwrite(&array_flags,4,1,(FILE*)mat->fp);
        fwrite(&nzmax,4,1,(FILE*)mat->fp);
        /* Rank and Dimension */
        nBytes = matvar->rank * 4;
        fwrite(&dims_array_type,4,1,(FILE*)mat->fp);
        fwrite(&nBytes,4,1,(FILE*)mat->fp);
        for ( i = 0; i < matvar->rank; i++ ) {
            mat_int32_t dim;
            dim = matvar->dims[i];
            nmemb *= dim;
            fwrite(&dim,4,1,(FILE*)mat->fp);
        }
        if ( matvar->rank % 2 != 0 )
            fwrite(&pad4,4,1,(FILE*)mat->fp);
        /* Name of variable */
        if ( strlen(matvar->name) <= 4 ) {
            mat_int16_t array_name_len = (mat_int16_t)strlen(matvar->name);
            mat_int8_t  pad1 = 0;
            mat_int16_t array_name_type = MAT_T_INT8;
            fwrite(&array_name_type,2,1,(FILE*)mat->fp);
            fwrite(&array_name_len,2,1,(FILE*)mat->fp);
            fwrite(matvar->name,1,array_name_len,(FILE*)mat->fp);
            for ( i = array_name_len; i < 4; i++ )
                fwrite(&pad1,1,1,(FILE*)mat->fp);
        } else {
            mat_int32_t array_name_len = (mat_int32_t)strlen(matvar->name);
            mat_int8_t  pad1 = 0;
            mat_int32_t  array_name_type = MAT_T_INT8;

            fwrite(&array_name_type,4,1,(FILE*)mat->fp);
            fwrite(&array_name_len,4,1,(FILE*)mat->fp);
            fwrite(matvar->name,1,array_name_len,(FILE*)mat->fp);
            if ( array_name_len % 8 )
                for ( i = array_name_len % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,(FILE*)mat->fp);
        }

        matvar->internal->datapos = ftell((FILE*)mat->fp);
        if ( matvar->internal->datapos == -1L ) {
            Mat_Critical("Couldn't determine file position");
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
            case MAT_C_UINT8:
                nBytes = WriteEmptyData(mat,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
                if ( matvar->isComplex ) {
                    nBytes = WriteEmptyData(mat,nmemb,matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,(FILE*)mat->fp);
                }
                break;
            case MAT_C_CHAR:
            {
                WriteEmptyCharData(mat,nmemb,matvar->data_type);
                break;
            }
            case MAT_C_CELL:
            {
                int        ncells;
                matvar_t **cells = (matvar_t **)matvar->data;

                /* Check for an empty cell array */
                if ( matvar->nbytes == 0 || matvar->data_size == 0 ||
                     matvar->data   == NULL )
                    break;
                ncells  = matvar->nbytes / matvar->data_size;

                for ( i = 0; i < ncells; i++ )
                    WriteCellArrayFieldInfo(mat,cells[i]);
                break;
            }
            case MAT_C_STRUCT:
            {
                char *padzero;
                int maxlen = 0, fieldname_size;
                int nfields = matvar->internal->num_fields;
                matvar_t **fields = (matvar_t **)matvar->data;
                mat_int32_t  array_name_type = MAT_T_INT8;
                unsigned fieldname;

                for ( i = 0; i < nfields; i++ ) {
                    size_t len = strlen(matvar->internal->fieldnames[i]);
                    if ( len > maxlen )
                        maxlen = len;
                }
                maxlen++;
                fieldname_size = maxlen;
                while ( nfields*fieldname_size % 8 != 0 )
                    fieldname_size++;
#if 0
                fwrite(&fieldname_type,2,1,(FILE*)mat->fp);
                fwrite(&fieldname_data_size,2,1,(FILE*)mat->fp);
#else
                fieldname = (fieldname_data_size<<16) | fieldname_type;
                fwrite(&fieldname,4,1,(FILE*)mat->fp);
#endif
                fwrite(&fieldname_size,4,1,(FILE*)mat->fp);
                fwrite(&array_name_type,4,1,(FILE*)mat->fp);
                nBytes = nfields*fieldname_size;
                fwrite(&nBytes,4,1,(FILE*)mat->fp);
                padzero = (char*)calloc(fieldname_size,1);
                for ( i = 0; i < nfields; i++ ) {
                    size_t len = strlen(matvar->internal->fieldnames[i]);
                    fwrite(matvar->internal->fieldnames[i],1,len,(FILE*)mat->fp);
                    fwrite(padzero,1,fieldname_size-len,(FILE*)mat->fp);
                }
                free(padzero);
                for ( i = 0; i < nfields; i++ )
                    WriteInfo5(mat,fields[i]);
                break;
            }
            case MAT_C_SPARSE:
            case MAT_C_EMPTY:
            case MAT_C_FUNCTION:
            case MAT_C_OBJECT:
                break;
        }
    /* Does not work.
     * Can write empty data, but how to go back and add the real data?
     */
#if 0
    } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
#if defined(HAVE_ZLIB)
        mat_uint32_t comp_buf[512];
        mat_uint32_t uncomp_buf[512] = {0,};
        int buf_size = 512, err;
        size_t byteswritten = 0;

        matvar->internal->z = (z_streamp)calloc(1,sizeof(*matvar->internal->z));
        err = deflateInit(matvar->internal->z,Z_DEFAULT_COMPRESSION);
        if ( err != Z_OK ) {
            free(matvar->internal->z);
            matvar->internal->z = NULL;
            Mat_Critical("deflateInit returned %s",zError(err));
            return;
        }

        matrix_type = MAT_T_COMPRESSED;
        fwrite(&matrix_type,4,1,(FILE*)mat->fp);
        fwrite(&pad4,4,1,(FILE*)mat->fp);
        start = ftell((FILE*)mat->fp);

        /* Array Flags */
        array_flags = matvar->class_type & MAT_F_CLASS_T;
        if ( matvar->isComplex )
            array_flags |= MAT_F_COMPLEX;
        if ( matvar->isGlobal )
            array_flags |= MAT_F_GLOBAL;
        if ( matvar->isLogical )
            array_flags |= MAT_F_LOGICAL;

        uncomp_buf[0] = MAT_T_MATRIX;
        uncomp_buf[1] = 448;
        matvar->internal->z->next_in  = uncomp_buf;
        matvar->internal->z->avail_in = 8;
        do {
            matvar->internal->z->next_out  = comp_buf;
            matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
            deflate(matvar->internal->z,Z_NO_FLUSH);
            byteswritten += fwrite(comp_buf,1,
                buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,
                (FILE*)mat->fp);
        } while ( matvar->internal->z->avail_out == 0 );
        uncomp_buf[0] = array_flags_type;
        uncomp_buf[1] = array_flags_size;
        uncomp_buf[2] = array_flags;
        uncomp_buf[3] = 0;
        /* Rank and Dimension */
        nBytes = matvar->rank * 4;
        uncomp_buf[4] = dims_array_type;
        uncomp_buf[5] = nBytes;
        for ( i = 0; i < matvar->rank; i++ ) {
            mat_int32_t dim;
            dim = matvar->dims[i];
            nmemb *= dim;
            uncomp_buf[6+i] = dim;
        }
        if ( matvar->rank % 2 != 0 )
            uncomp_buf[6+i] = pad4;

        matvar->internal->z->next_in  = uncomp_buf;
        matvar->internal->z->avail_in = (6+i)*sizeof(*uncomp_buf);
        do {
            matvar->internal->z->next_out  = comp_buf;
            matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
            deflate(matvar->internal->z,Z_NO_FLUSH);
            byteswritten += fwrite(comp_buf,1,
                buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,
                (FILE*)mat->fp);
        } while ( matvar->internal->z->avail_out == 0 );
        /* Name of variable */
        if ( strlen(matvar->name) <= 4 ) {
#if 0
            mat_int16_t array_name_len = (mat_int16_t)strlen(matvar->name);
            mat_int8_t  pad1 = 0;

            uncomp_buf[0] = (array_name_type << 16) | array_name_len;
            memcpy(uncomp_buf+1,matvar->name,array_name_len);

            matvar->internal->z->next_in  = uncomp_buf;
            matvar->internal->z->avail_in = 8;
            do {
                matvar->internal->z->next_out  = comp_buf;
                matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
                deflate(matvar->internal->z,Z_NO_FLUSH);
                byteswritten += fwrite(comp_buf,1,
                    buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,
                    (FILE*)mat->fp);
            } while ( matvar->internal->z->avail_out == 0 );
        } else {
#endif
            mat_int32_t array_name_len = (mat_int32_t)strlen(matvar->name);

            memset(uncomp_buf,0,buf_size*sizeof(*uncomp_buf));
            uncomp_buf[0] = array_name_type;
            uncomp_buf[1] = array_name_len;
            memcpy(uncomp_buf+2,matvar->name,array_name_len);
            if ( array_name_len % 8 )
                array_name_len += array_name_len % 8;
            matvar->internal->z->next_in   = uncomp_buf;
            matvar->internal->z->avail_in  = 8+array_name_len;
            do {
                matvar->internal->z->next_out  = comp_buf;
                matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
                deflate(matvar->internal->z,Z_NO_FLUSH);
                byteswritten += fwrite(comp_buf,1,
                    buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,(FILE*)mat->fp);
            } while ( matvar->internal->z->avail_out == 0 );
        }
        matvar->internal->datapos = ftell((FILE*)mat->fp);
        if ( matvar->internal->datapos == -1L ) {
            Mat_Critical("Couldn't determine file position");
        }
        deflateCopy(&z_save,matvar->internal->z);
        switch ( matvar->class_type ) {
            case MAT_C_DOUBLE:
            case MAT_C_SINGLE:
            case MAT_C_INT32:
            case MAT_C_UINT32:
            case MAT_C_INT16:
            case MAT_C_UINT16:
            case MAT_C_INT8:
            case MAT_C_UINT8:
                byteswritten += WriteCompressedEmptyData(mat,matvar->internal->z,nmemb,matvar->data_type);
#if 0
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,(FILE*)mat->fp);
                if ( matvar->isComplex ) {
                    nBytes = WriteEmptyData(mat,nmemb,matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,(FILE*)mat->fp);
                }
#endif
                break;
        }
        matvar->internal->z->next_in  = NULL;
        matvar->internal->z->avail_in = 0;
        do {
            matvar->internal->z->next_out  = comp_buf;
            matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
            err = deflate(matvar->internal->z,Z_FINISH);
            byteswritten += fwrite(comp_buf,1,
                buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,(FILE*)mat->fp);
        } while ( err != Z_STREAM_END && matvar->internal->z->avail_out == 0 );
        if ( byteswritten % 8 )
            for ( i = byteswritten % 8; i < 8; i++ )
                fwrite(&pad1,1,1,(FILE*)mat->fp);
        Mat_Critical("deflate with Z_FINISH returned %s, byteswritten = %u",zError(err),byteswritten);
#if 1
        (void)deflateEnd(matvar->internal->z);
        free(matvar->internal->z);
        matvar->internal->z = NULL;
#else
        memcpy(matvar->internal->z,&z_save,sizeof(*matvar->internal->z));
#endif
#endif
#endif
    }
    end = ftell((FILE*)mat->fp);
    if ( start != -1L && end != -1L ) {
        nBytes = (int)(end-start);
        (void)fseek((FILE*)mat->fp,(long)-(nBytes+4),SEEK_CUR);
        fwrite(&nBytes,4,1,(FILE*)mat->fp);
        (void)fseek((FILE*)mat->fp,end,SEEK_SET);
    } else {
        Mat_Critical("Couldn't determine file position");
    }
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
Mat_VarReadNextInfo5( mat_t *mat )
{
    int err, data_type, nBytes, i;
    long fpos;
    matvar_t *matvar = NULL;
    mat_uint32_t array_flags;

    if( mat == NULL )
        return NULL;

    fpos = ftell((FILE*)mat->fp);
    if ( fpos == -1L ) {
        Mat_Critical("Couldn't determine file position");
        return NULL;
    }
    err = fread(&data_type,4,1,(FILE*)mat->fp);
    if ( err == 0 )
        return NULL;
    err = fread(&nBytes,4,1,(FILE*)mat->fp);
    if ( mat->byteswap ) {
        Mat_int32Swap(&data_type);
        Mat_int32Swap(&nBytes);
    }
    switch ( data_type ) {
        case MAT_T_COMPRESSED:
        {
#if defined(HAVE_ZLIB)
            mat_uint32_t uncomp_buf[16] = {0,};
            int      nbytes;
            long     bytesread = 0;

            matvar               = Mat_VarCalloc();
            matvar->name         = NULL;
            matvar->data         = NULL;
            matvar->dims         = NULL;
            matvar->nbytes       = 0;
            matvar->data_type    = MAT_T_UNKNOWN;
            matvar->class_type   = MAT_C_EMPTY;
            matvar->data_size    = 0;
            matvar->mem_conserve = 0;
            matvar->compression  = MAT_COMPRESSION_ZLIB;

            matvar->internal->fp = mat;
            matvar->internal->fpos = fpos;
            matvar->internal->z = (z_streamp)calloc(1,sizeof(z_stream));
            err = inflateInit(matvar->internal->z);
            if ( err != Z_OK ) {
                Mat_VarFree(matvar);
                matvar = NULL;
                Mat_Critical("inflateInit returned %s",zError(err));
                break;
            }

            /* Read Variable tag */
            bytesread += InflateVarTag(mat,matvar,uncomp_buf);
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf+1);
            }
            nbytes = uncomp_buf[1];
            if ( uncomp_buf[0] != MAT_T_MATRIX ) {
                (void)fseek((FILE*)mat->fp,nBytes-bytesread,SEEK_CUR);
                Mat_VarFree(matvar);
                matvar = NULL;
                Mat_Critical("Uncompressed type not MAT_T_MATRIX");
                break;
            }
            /* Inflate Array Flags */
            bytesread += InflateArrayFlags(mat,matvar,uncomp_buf);
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf+2);
                (void)Mat_uint32Swap(uncomp_buf+3);
            }
            /* Array Flags */
            if ( uncomp_buf[0] == MAT_T_UINT32 ) {
               array_flags = uncomp_buf[2];
               matvar->class_type  = CLASS_FROM_ARRAY_FLAGS(array_flags);
               matvar->isComplex   = (array_flags & MAT_F_COMPLEX);
               matvar->isGlobal    = (array_flags & MAT_F_GLOBAL);
               matvar->isLogical   = (array_flags & MAT_F_LOGICAL);
               if ( matvar->class_type == MAT_C_SPARSE ) {
                   /* Need to find a more appropriate place to store nzmax */
                   matvar->nbytes      = uncomp_buf[3];
               }
            }
            /* Inflate Dimensions */
            bytesread += InflateDimensions(mat,matvar,uncomp_buf);
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(uncomp_buf);
                (void)Mat_uint32Swap(uncomp_buf+1);
            }
            /* Rank and Dimension */
            if ( uncomp_buf[0] == MAT_T_INT32 ) {
                nbytes = uncomp_buf[1];
                matvar->rank = nbytes / 4;
                matvar->dims = (size_t*)malloc(matvar->rank*sizeof(*matvar->dims));
                if ( mat->byteswap ) {
                    for ( i = 0; i < matvar->rank; i++ )
                        matvar->dims[i] = Mat_uint32Swap(&(uncomp_buf[2+i]));
                } else {
                    for ( i = 0; i < matvar->rank; i++ )
                        matvar->dims[i] = uncomp_buf[2+i];
                }
            }
            /* Inflate variable name tag */
            bytesread += InflateVarNameTag(mat,matvar,uncomp_buf);
            if ( mat->byteswap )
                (void)Mat_uint32Swap(uncomp_buf);
            /* Name of variable */
            if ( uncomp_buf[0] == MAT_T_INT8 ) {    /* Name not in tag */
                int len;
                if ( mat->byteswap )
                    len = Mat_uint32Swap(uncomp_buf+1);
                else
                    len = uncomp_buf[1];

                if ( len % 8 == 0 )
                    i = len;
                else
                    i = len+(8-(len % 8));
                matvar->name = (char*)malloc(i+1);
                /* Inflate variable name */
                bytesread += InflateVarName(mat,matvar,matvar->name,i);
                matvar->name[len] = '\0';
            } else if ( ((uncomp_buf[0] & 0x0000ffff) == MAT_T_INT8) &&
                        ((uncomp_buf[0] & 0xffff0000) != 0x00) ) {
                /* Name packed in tag */
                int len;
                len = (uncomp_buf[0] & 0xffff0000) >> 16;
                matvar->name = (char*)malloc(len+1);
                memcpy(matvar->name,uncomp_buf+1,len);
                matvar->name[len] = '\0';
            }
            if ( matvar->class_type == MAT_C_STRUCT )
                (void)ReadNextStructField(mat,matvar);
            else if ( matvar->class_type == MAT_C_CELL )
                (void)ReadNextCell(mat,matvar);
            (void)fseek((FILE*)mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
            matvar->internal->datapos = ftell((FILE*)mat->fp);
            if ( matvar->internal->datapos == -1L ) {
                Mat_Critical("Couldn't determine file position");
            }
            (void)fseek((FILE*)mat->fp,nBytes+8+fpos,SEEK_SET);
            break;
#else
            Mat_Critical("Compressed variable found in \"%s\", but matio was "
                         "built without zlib support",mat->filename);
            (void)fseek((FILE*)mat->fp,nBytes+8+fpos,SEEK_SET);
            return NULL;
#endif
        }
        case MAT_T_MATRIX:
        {
            int      nbytes;
            mat_uint32_t buf[32];
            size_t   bytesread = 0;

            matvar = Mat_VarCalloc();
            matvar->internal->fpos = fpos;
            matvar->internal->fp   = mat;

            /* Read Array Flags and The Dimensions Tag */
            bytesread += fread(buf,4,6,(FILE*)mat->fp);
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(buf);
                (void)Mat_uint32Swap(buf+1);
                (void)Mat_uint32Swap(buf+2);
                (void)Mat_uint32Swap(buf+3);
                (void)Mat_uint32Swap(buf+4);
                (void)Mat_uint32Swap(buf+5);
            }
            /* Array Flags */
            if ( buf[0] == MAT_T_UINT32 ) {
               array_flags = buf[2];
               matvar->class_type  = CLASS_FROM_ARRAY_FLAGS(array_flags);
               matvar->isComplex   = (array_flags & MAT_F_COMPLEX);
               matvar->isGlobal    = (array_flags & MAT_F_GLOBAL);
               matvar->isLogical   = (array_flags & MAT_F_LOGICAL);
               if ( matvar->class_type == MAT_C_SPARSE ) {
                   /* Need to find a more appropriate place to store nzmax */
                   matvar->nbytes      = buf[3];
               }
            }
            /* Rank and Dimension */
            if ( buf[4] == MAT_T_INT32 ) {
                nbytes = buf[5];

                matvar->rank = nbytes / 4;
                matvar->dims = (size_t*)malloc(matvar->rank*sizeof(*matvar->dims));

                /* Assumes rank <= 16 */
                if ( matvar->rank % 2 != 0 )
                    bytesread+=fread(buf,4,matvar->rank+1,(FILE*)mat->fp);
                else
                    bytesread+=fread(buf,4,matvar->rank,(FILE*)mat->fp);

                if ( mat->byteswap ) {
                    for ( i = 0; i < matvar->rank; i++ )
                        matvar->dims[i] = Mat_uint32Swap(buf+i);
                } else {
                    for ( i = 0; i < matvar->rank; i++ )
                        matvar->dims[i] = buf[i];
                }
            }
            /* Variable Name Tag */
            bytesread+=fread(buf,4,2,(FILE*)mat->fp);
            if ( mat->byteswap )
                (void)Mat_uint32Swap(buf);
            /* Name of variable */
            if ( buf[0] == MAT_T_INT8 ) {    /* Name not in tag */
                int len;

                if ( mat->byteswap )
                    len = Mat_uint32Swap(buf+1);
                else
                    len = buf[1];
                if ( len % 8 == 0 )
                    i = len;
                else
                    i = len+(8-(len % 8));
                bytesread+=fread(buf,1,i,(FILE*)mat->fp);

                matvar->name = (char*)malloc(len+1);
                memcpy(matvar->name,buf,len);
                matvar->name[len] = '\0';
            } else if ( ((buf[0] & 0x0000ffff) == MAT_T_INT8) &&
                        ((buf[0] & 0xffff0000) != 0x00) ) {
                /* Name packed in the tag */
                int len;

                len = (buf[0] & 0xffff0000) >> 16;
                matvar->name = (char*)malloc(len+1);
                memcpy(matvar->name,buf+1,len);
                matvar->name[len] = '\0';
            }
            if ( matvar->class_type == MAT_C_STRUCT )
                (void)ReadNextStructField(mat,matvar);
            else if ( matvar->class_type == MAT_C_CELL )
                (void)ReadNextCell(mat,matvar);
            else if ( matvar->class_type == MAT_C_FUNCTION )
                (void)ReadNextFunctionHandle(mat,matvar);
            matvar->internal->datapos = ftell((FILE*)mat->fp);
            if ( matvar->internal->datapos == -1L ) {
                Mat_Critical("Couldn't determine file position");
            }
            (void)fseek((FILE*)mat->fp,nBytes+8+fpos,SEEK_SET);
            break;
        }
        default:
            Mat_Critical("Not possible to read compressed v7 MAT file \"%s\"",
                mat->filename);
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

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <time.h>

#if defined(HAVE_HDF5)

static const char *Mat_class_names[] = {
    "",
    "cell",
    "struct",
    "object",
    "char",
    "sparse",
    "double",
    "single",
    "int8",
    "uint8",
    "int16",
    "uint16",
    "int32",
    "uint32",
    "int64",
    "uint64",
    "function"
};

struct mat_read_next_iter_data {
    mat_t *mat;
    matvar_t *matvar;
};

struct h5_read_group_info_iter_data {
    hsize_t nfields;
    matvar_t *matvar;
};

/*===========================================================================
 *  Private functions
 *===========================================================================
 */
static enum matio_classes Mat_class_str_to_id(const char *name);
static hid_t  Mat_class_type_to_hid_t(enum matio_classes class_type);
static hid_t  Mat_data_type_to_hid_t(enum matio_types data_type);
static hid_t  Mat_dims_type_to_hid_t(void);
static void   Mat_H5GetChunkSize(size_t rank,hsize_t *dims,hsize_t *chunk_dims);
static void   Mat_H5ReadClassType(matvar_t *matvar,hid_t dset_id);
static void   Mat_H5ReadDatasetInfo(mat_t *mat,matvar_t *matvar,hid_t dset_id);
static void   Mat_H5ReadGroupInfo(mat_t *mat,matvar_t *matvar,hid_t dset_id);
static void   Mat_H5ReadNextReferenceInfo(hid_t ref_id,matvar_t *matvar,mat_t *mat);
static void   Mat_H5ReadNextReferenceData(hid_t ref_id,matvar_t *matvar,mat_t *mat);
static int    Mat_VarWriteCell73(hid_t id,matvar_t *matvar,const char *name,
                                 hid_t *refs_id);
static int    Mat_VarWriteChar73(hid_t id,matvar_t *matvar,const char *name);
static int    Mat_WriteEmptyVariable73(hid_t id,const char *name,hsize_t rank,
                                       size_t *dims);
static int    Mat_VarWriteNumeric73(hid_t id,matvar_t *matvar,const char *name);
static int    Mat_VarWriteStruct73(hid_t id,matvar_t *matvar,const char *name,
                                   hid_t *refs_id);
static int    Mat_VarWriteNext73(hid_t id,matvar_t *matvar,const char *name,
                                 hid_t *refs_id);
static herr_t Mat_VarReadNextInfoIterate(hid_t id, const char *name,
                                         const H5L_info_t *info, void *op_data);
static herr_t Mat_H5ReadGroupInfoIterate(hid_t dset_id, const char *name,
                                         const H5L_info_t *info, void *op_data);

static enum matio_classes
Mat_class_str_to_id(const char *name)
{
    enum matio_classes id = MAT_C_EMPTY;
    if ( NULL != name ) {
        int k;
        for ( k = 1; k < 17; k++ ) {
            if ( !strcmp(name,Mat_class_names[k]) ) {
                id = (enum matio_classes)k;
                break;
            }
        }
    }
    return id;
}

static enum matio_types
Mat_ClassToType73(enum matio_classes class_type)
{
    enum matio_types type;
    switch ( class_type ) {
        case MAT_C_DOUBLE:
            type = MAT_T_DOUBLE;
            break;
        case MAT_C_SINGLE:
            type = MAT_T_SINGLE;
            break;
        case MAT_C_INT64:
            type = MAT_T_INT64;
            break;
        case MAT_C_UINT64:
            type = MAT_T_UINT64;
            break;
        case MAT_C_INT32:
            type = MAT_T_INT32;
            break;
        case MAT_C_UINT32:
            type = MAT_T_UINT32;
            break;
        case MAT_C_INT16:
            type = MAT_T_INT16;
            break;
        case MAT_C_UINT16:
            type = MAT_T_UINT16;
            break;
        case MAT_C_INT8:
            type = MAT_T_INT8;
            break;
        case MAT_C_CHAR:
            type = MAT_T_UINT8;
            break;
        case MAT_C_UINT8:
            type = MAT_T_UINT8;
            break;
        case MAT_C_CELL:
            type = MAT_T_CELL;
            break;
        case MAT_C_STRUCT:
            type = MAT_T_STRUCT;
            break;
        default:
            type = MAT_T_UNKNOWN;
            break;
    }

    return type;
}

static enum matio_classes
Mat_TypeToClass73(enum matio_types type)
{
    enum matio_classes class_type = MAT_C_EMPTY;
    switch ( type ) {
        case MAT_T_DOUBLE:
            class_type = MAT_C_DOUBLE;
            break;
        case MAT_T_SINGLE:
            class_type = MAT_C_SINGLE;
            break;
        case MAT_T_INT64:
            class_type = MAT_C_INT64;
            break;
        case MAT_T_UINT64:
            class_type = MAT_C_UINT64;
            break;
        case MAT_T_INT32:
            class_type = MAT_C_INT32;
            break;
        case MAT_T_UINT32:
            class_type = MAT_C_UINT32;
            break;
        case MAT_T_INT16:
            class_type = MAT_C_INT16;
            break;
        case MAT_T_UINT16:
            class_type = MAT_C_UINT16;
            break;
        case MAT_T_INT8:
            class_type = MAT_C_INT8;
            break;
        case MAT_T_UINT8:
            class_type = MAT_C_UINT8;
            break;
        default:
            class_type = MAT_C_EMPTY;
            break;
    }

    return class_type;
}

static hid_t
Mat_class_type_to_hid_t(enum matio_classes class_type)
{
    switch ( class_type ) {
        case MAT_C_DOUBLE:
            return H5T_NATIVE_DOUBLE;
        case MAT_C_SINGLE:
            return H5T_NATIVE_FLOAT;
        case MAT_C_INT64:
            if ( CHAR_BIT*sizeof(long long) == 64 )
                return H5T_NATIVE_LLONG;
            else if ( CHAR_BIT*sizeof(long) == 64 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT*sizeof(int) == 64 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT*sizeof(short) == 64 )
                return H5T_NATIVE_SHORT;
            else
                return -1;
        case MAT_C_UINT64:
            if ( CHAR_BIT*sizeof(long long) == 64 )
                return H5T_NATIVE_ULLONG;
            else if ( CHAR_BIT*sizeof(long) == 64 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT*sizeof(int) == 64 )
                return H5T_NATIVE_UINT;
            if ( CHAR_BIT*sizeof(short) == 64 )
                return H5T_NATIVE_USHORT;
            else
                return -1;
        case MAT_C_INT32:
            if ( CHAR_BIT*sizeof(int) == 32 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT*sizeof(short) == 32 )
                return H5T_NATIVE_SHORT;
            else if ( CHAR_BIT*sizeof(long) == 32 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT*sizeof(long long) == 32 )
                return H5T_NATIVE_LLONG;
            else if ( CHAR_BIT == 32 )
                return H5T_NATIVE_SCHAR;
            else
                return -1;
        case MAT_C_UINT32:
            if ( CHAR_BIT*sizeof(int) == 32 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT*sizeof(short) == 32 )
                return H5T_NATIVE_USHORT;
            else if ( CHAR_BIT*sizeof(long) == 32 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT*sizeof(long long) == 32 )
                return H5T_NATIVE_ULLONG;
            else if ( CHAR_BIT == 32 )
                return H5T_NATIVE_UCHAR;
            else
                return -1;
        case MAT_C_INT16:
            if ( CHAR_BIT*sizeof(short) == 16 )
                return H5T_NATIVE_SHORT;
            else if ( CHAR_BIT*sizeof(int) == 16 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT*sizeof(long) == 16 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT*sizeof(long long) == 16 )
                return H5T_NATIVE_LLONG;
            else if ( CHAR_BIT == 16 )
                return H5T_NATIVE_SCHAR;
            else
                return -1;
        case MAT_C_UINT16:
            if ( CHAR_BIT*sizeof(short) == 16 )
                return H5T_NATIVE_USHORT;
            else if ( CHAR_BIT*sizeof(int) == 16 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT*sizeof(long) == 16 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT*sizeof(long long) == 16 )
                return H5T_NATIVE_ULLONG;
            else if ( CHAR_BIT == 16 )
                return H5T_NATIVE_UCHAR;
            else
                return -1;
        case MAT_C_INT8:
            if ( CHAR_BIT == 8 )
                return H5T_NATIVE_SCHAR;
            else if ( CHAR_BIT*sizeof(short) == 8 )
                return H5T_NATIVE_SHORT;
            else if ( CHAR_BIT*sizeof(int) == 8 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT*sizeof(long) == 8 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT*sizeof(long long) == 8 )
                return H5T_NATIVE_LLONG;
            else
                return -1;
        case MAT_C_UINT8:
            if ( CHAR_BIT == 8 )
                return H5T_NATIVE_UCHAR;
            else if ( CHAR_BIT*sizeof(short) == 8 )
                return H5T_NATIVE_USHORT;
            else if ( CHAR_BIT*sizeof(int) == 8 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT*sizeof(long) == 8 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT*sizeof(long long) == 8 )
                return H5T_NATIVE_ULLONG;
            else
                return -1;
        default:
            return -1;
    }
}

static hid_t
Mat_data_type_to_hid_t(enum matio_types data_type)
{
    switch ( data_type ) {
        case MAT_T_DOUBLE:
            return H5T_NATIVE_DOUBLE;
        case MAT_T_SINGLE:
            return H5T_NATIVE_FLOAT;
        case MAT_T_INT64:
            if ( CHAR_BIT*sizeof(long long) == 64 )
                return H5T_NATIVE_LLONG;
            else if ( CHAR_BIT*sizeof(long) == 64 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT*sizeof(int) == 64 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT*sizeof(short) == 64 )
                return H5T_NATIVE_SHORT;
            else
                return -1;
        case MAT_T_UINT64:
            if ( CHAR_BIT*sizeof(long long) == 64 )
                return H5T_NATIVE_ULLONG;
            else if ( CHAR_BIT*sizeof(long) == 64 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT*sizeof(int) == 64 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT*sizeof(short) == 64 )
                return H5T_NATIVE_USHORT;
            else
                return -1;
        case MAT_T_INT32:
            if ( CHAR_BIT*sizeof(int) == 32 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT*sizeof(short) == 32 )
                return H5T_NATIVE_SHORT;
            else if ( CHAR_BIT*sizeof(long) == 32 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT*sizeof(long long) == 32 )
                return H5T_NATIVE_LLONG;
            else if ( CHAR_BIT == 32 )
                return H5T_NATIVE_SCHAR;
            else
                return -1;
        case MAT_T_UINT32:
            if ( CHAR_BIT*sizeof(int) == 32 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT*sizeof(short) == 32 )
                return H5T_NATIVE_USHORT;
            else if ( CHAR_BIT*sizeof(long) == 32 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT*sizeof(long long) == 32 )
                return H5T_NATIVE_ULLONG;
            else if ( CHAR_BIT == 32 )
                return H5T_NATIVE_UCHAR;
            else
                return -1;
        case MAT_T_INT16:
            if ( CHAR_BIT*sizeof(short) == 16 )
                return H5T_NATIVE_SHORT;
            else if ( CHAR_BIT*sizeof(int) == 16 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT*sizeof(long) == 16 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT*sizeof(long long) == 16 )
                return H5T_NATIVE_LLONG;
            else if ( CHAR_BIT == 16 )
                return H5T_NATIVE_SCHAR;
            else
                return -1;
        case MAT_T_UINT16:
            if ( CHAR_BIT*sizeof(short) == 16 )
                return H5T_NATIVE_USHORT;
            else if ( CHAR_BIT*sizeof(int) == 16 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT*sizeof(long) == 16 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT*sizeof(long long) == 16 )
                return H5T_NATIVE_ULLONG;
            else if ( CHAR_BIT == 16 )
                return H5T_NATIVE_UCHAR;
            else
                return -1;
        case MAT_T_INT8:
            if ( CHAR_BIT == 8 )
                return H5T_NATIVE_SCHAR;
            else if ( CHAR_BIT*sizeof(short) == 8 )
                return H5T_NATIVE_SHORT;
            else if ( CHAR_BIT*sizeof(int) == 8 )
                return H5T_NATIVE_INT;
            else if ( CHAR_BIT*sizeof(long) == 8 )
                return H5T_NATIVE_LONG;
            else if ( CHAR_BIT*sizeof(long long) == 8 )
                return H5T_NATIVE_LLONG;
            else
                return -1;
        case MAT_T_UINT8:
            if ( CHAR_BIT == 8 )
                return H5T_NATIVE_UCHAR;
            else if ( CHAR_BIT*sizeof(short) == 8 )
                return H5T_NATIVE_USHORT;
            else if ( CHAR_BIT*sizeof(int) == 8 )
                return H5T_NATIVE_UINT;
            else if ( CHAR_BIT*sizeof(long) == 8 )
                return H5T_NATIVE_ULONG;
            else if ( CHAR_BIT*sizeof(long long) == 8 )
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
Mat_dims_type_to_hid_t(void)
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

static void
Mat_H5GetChunkSize(size_t rank,hsize_t *dims,hsize_t *chunk_dims)
{
    hsize_t  i, j, chunk_size = 1;

    for ( i = 0; i < rank; i++ ) {
        chunk_dims[i] = 1;
        for ( j = 4096/chunk_size; j > 1; j >>= 1 ) {
            if ( dims[i] >= j ) {
                chunk_dims[i] = j;
                break;
            }
        }
        chunk_size *= chunk_dims[i];
    }
}

static void
Mat_H5ReadClassType(matvar_t *matvar,hid_t dset_id)
{
    hid_t attr_id, type_id;
    attr_id = H5Aopen_by_name(dset_id,".","MATLAB_class",H5P_DEFAULT,H5P_DEFAULT);
    type_id  = H5Aget_type(attr_id);
    if ( H5T_STRING == H5Tget_class(type_id) ) {
        char *class_str = (char*)calloc(H5Tget_size(type_id)+1,1);
        if ( NULL != class_str ) {
            hid_t class_id = H5Tcopy(H5T_C_S1);
            H5Tset_size(class_id,H5Tget_size(type_id));
            H5Aread(attr_id,class_id,class_str);
            H5Tclose(class_id);
            matvar->class_type = Mat_class_str_to_id(class_str);
            if ( MAT_C_EMPTY == matvar->class_type ) {
                /* Check if this is a logical variable */
                if ( !strcmp(class_str, "logical") ) {
                    int int_decode = 0;
                    hid_t attr_id2;
                    matvar->isLogical = MAT_F_LOGICAL;
                    if ( H5Aexists_by_name(dset_id,".","MATLAB_int_decode",H5P_DEFAULT) ) {
                        attr_id2 = H5Aopen_by_name(dset_id,".","MATLAB_int_decode",H5P_DEFAULT,H5P_DEFAULT);
                        /* FIXME: Check that dataspace is scalar */
                        H5Aread(attr_id2,H5T_NATIVE_INT,&int_decode);
                        H5Aclose(attr_id2);
                    }
                    switch (int_decode) {
                        case 1:
                            matvar->class_type = MAT_C_UINT8;
                            break;
                        case 2:
                            matvar->class_type = MAT_C_UINT16;
                            break;
                        case 4:
                            matvar->class_type = MAT_C_UINT32;
                            break;
                        default:
                            break;
                    }
                }
            }

            matvar->data_type  = Mat_ClassToType73(matvar->class_type);
            free(class_str);
        }
    }
    H5Tclose(type_id);
    H5Aclose(attr_id);
}

static void
Mat_H5ReadDatasetInfo(mat_t *mat,matvar_t *matvar,hid_t dset_id)
{
    ssize_t  name_len;
    /* FIXME */
    hsize_t  dims[10];
    hid_t   attr_id,type_id,space_id;

#if 0
    matvar->fp = mat;
    name_len = H5Gget_objname_by_idx(fid,mat->next_index,NULL,0);
    matvar->name = malloc(1+name_len);
    if ( matvar->name ) {
        name_len = H5Gget_objname_by_idx(fid,mat->next_index,
                                         matvar->name,1+name_len);
        matvar->name[name_len] = '\0';
    }
    dset_id = H5Dopen(fid,matvar->name);
#endif

    /* Get the HDF5 name of the variable */
    name_len = H5Iget_name(dset_id,NULL,0);
    if ( name_len > 0 ) {
        matvar->internal->hdf5_name = (char*)malloc(name_len+1);
        (void)H5Iget_name(dset_id,matvar->internal->hdf5_name,name_len+1);
    } else {
        /* Can not get an internal name, so leave the identifier open */
        matvar->internal->id = dset_id;
    }

    space_id     = H5Dget_space(dset_id);
    matvar->rank = H5Sget_simple_extent_ndims(space_id);
    matvar->dims = (size_t*)malloc(matvar->rank*sizeof(*matvar->dims));
    if ( NULL != matvar->dims ) {
        int k;
        H5Sget_simple_extent_dims(space_id,dims,NULL);
        for ( k = 0; k < matvar->rank; k++ )
            matvar->dims[k] = dims[matvar->rank - k - 1];
        H5Sclose(space_id);
    } else {
        H5Sclose(space_id);
        Mat_Critical("Error allocating memory for matvar->dims");
        return;
    }

    Mat_H5ReadClassType(matvar, dset_id);

    if ( H5Aexists_by_name(dset_id,".","MATLAB_global",H5P_DEFAULT) ) {
        attr_id = H5Aopen_by_name(dset_id,".","MATLAB_global",H5P_DEFAULT,H5P_DEFAULT);
        /* FIXME: Check that dataspace is scalar */
        H5Aread(attr_id,H5T_NATIVE_INT,&matvar->isGlobal);
        H5Aclose(attr_id);
    }

    /* Check for attribute that indicates an empty array */
    if ( H5Aexists_by_name(dset_id,".","MATLAB_empty",H5P_DEFAULT) ) {
        int empty = 0;
        attr_id = H5Aopen_by_name(dset_id,".","MATLAB_empty",H5P_DEFAULT,H5P_DEFAULT);
        /* FIXME: Check that dataspace is scalar */
        H5Aread(attr_id,H5T_NATIVE_INT,&empty);
        H5Aclose(attr_id);
        if ( empty ) {
            matvar->rank = matvar->dims[0];
            free(matvar->dims);
            matvar->dims = (size_t*)calloc(matvar->rank,sizeof(*matvar->dims));
            H5Dread(dset_id,Mat_dims_type_to_hid_t(),H5S_ALL,H5S_ALL,
                    H5P_DEFAULT,matvar->dims);
        }
    }

    /* Test if dataset type is compound and if so if it's complex */
    type_id = H5Dget_type(dset_id);
    if ( H5T_COMPOUND == H5Tget_class(type_id) ) {
        /* FIXME: Any more checks? */
        matvar->isComplex = MAT_F_COMPLEX;
    }
    H5Tclose(type_id);

    /* If the dataset is a cell array read the info of the cells */
    if ( MAT_C_CELL == matvar->class_type ) {
        matvar_t **cells;
        int i,ncells = 1;
        hobj_ref_t *ref_ids;

        for ( i = 0; i < matvar->rank; i++ )
            ncells *= matvar->dims[i];
        matvar->data_size = sizeof(matvar_t**);
        matvar->nbytes    = ncells*matvar->data_size;
        matvar->data      = malloc(matvar->nbytes);
        cells = (matvar_t**)matvar->data;

        if ( ncells ) {
            ref_ids = (hobj_ref_t*)malloc(ncells*sizeof(*ref_ids));
            H5Dread(dset_id,H5T_STD_REF_OBJ,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                    ref_ids);
            for ( i = 0; i < ncells; i++ ) {
                hid_t ref_id;
                cells[i] = Mat_VarCalloc();
                cells[i]->internal->hdf5_ref = ref_ids[i];
                /* Closing of ref_id is done in Mat_H5ReadNextReferenceInfo */
                ref_id = H5Rdereference(dset_id,H5R_OBJECT,ref_ids+i);
                cells[i]->internal->id = ref_id;
                cells[i]->internal->fp = matvar->internal->fp;
                Mat_H5ReadNextReferenceInfo(ref_id,cells[i],mat);
            }
            free(ref_ids);
        }
    } else if ( MAT_C_STRUCT == matvar->class_type ) {
        /* Empty structures can be a dataset */

        /* Check if the structure defines its fields in MATLAB_fields */
        if ( H5Aexists_by_name(dset_id,".","MATLAB_fields",H5P_DEFAULT) ) {
            int      i;
            hid_t    field_id;
            hsize_t  nfields;
            hvl_t   *fieldnames_vl;

            attr_id = H5Aopen_by_name(dset_id,".","MATLAB_fields",H5P_DEFAULT,H5P_DEFAULT);
            space_id = H5Aget_space(attr_id);
            (void)H5Sget_simple_extent_dims(space_id,&nfields,NULL);
            field_id = H5Aget_type(attr_id);
            fieldnames_vl = (hvl_t*)malloc(nfields*sizeof(*fieldnames_vl));
            H5Aread(attr_id,field_id,fieldnames_vl);

            matvar->internal->num_fields = nfields;
            matvar->internal->fieldnames =
                (char**)calloc(nfields,sizeof(*matvar->internal->fieldnames));
            for ( i = 0; i < nfields; i++ ) {
                matvar->internal->fieldnames[i] =
                    (char*)calloc(fieldnames_vl[i].len+1,1);
                memcpy(matvar->internal->fieldnames[i],fieldnames_vl[i].p,
                    fieldnames_vl[i].len);
            }

            H5Dvlen_reclaim(field_id,space_id,H5P_DEFAULT,
                            fieldnames_vl);
            H5Sclose(space_id);
            H5Tclose(field_id);
            H5Aclose(attr_id);
            free(fieldnames_vl);
        }
    }
}

static void
Mat_H5ReadGroupInfo(mat_t *mat,matvar_t *matvar,hid_t dset_id)
{
    ssize_t  name_len;
    int      k, fields_are_variables = 1;
    /* FIXME */
    hsize_t  dims[10],nfields=0,numel;
    hid_t   attr_id,type_id,space_id,field_id,field_type_id;
    matvar_t **fields;
    H5O_type_t obj_type;

#if 0
    matvar->fp = mat;
    name_len = H5Gget_objname_by_idx(fid,mat->next_index,NULL,0);
    matvar->name = malloc(1+name_len);
    if ( matvar->name ) {
        name_len = H5Gget_objname_by_idx(fid,mat->next_index,
                                         matvar->name,1+name_len);
        matvar->name[name_len] = '\0';
    }
    dset_id = H5Gopen(fid,matvar->name);
#endif

    /* Get the HDF5 name of the variable */
    name_len = H5Iget_name(dset_id,NULL,0);
    if ( name_len > 0 ) {
        matvar->internal->hdf5_name = (char*)malloc(name_len+1);
        (void)H5Iget_name(dset_id,matvar->internal->hdf5_name,name_len+1);
    } else {
        /* Can not get an internal name, so leave the identifier open */
        matvar->internal->id = dset_id;
    }

    Mat_H5ReadClassType(matvar,dset_id);

    /* Check if the variable is global */
    if ( H5Aexists_by_name(dset_id,".","MATLAB_global",H5P_DEFAULT) ) {
        attr_id = H5Aopen_by_name(dset_id,".","MATLAB_global",H5P_DEFAULT,H5P_DEFAULT);
        /* FIXME: Check that dataspace is scalar */
        H5Aread(attr_id,H5T_NATIVE_INT,&matvar->isGlobal);
        H5Aclose(attr_id);
    }

    /* Check if the variable is sparse */
    if ( H5Aexists_by_name(dset_id,".","MATLAB_sparse",H5P_DEFAULT) ) {
        hid_t sparse_dset_id;
        unsigned nrows = 0;

        attr_id = H5Aopen_by_name(dset_id,".","MATLAB_sparse",H5P_DEFAULT,H5P_DEFAULT);
        H5Aread(attr_id,H5T_NATIVE_UINT,&nrows);
        H5Aclose(attr_id);

        matvar->class_type = MAT_C_SPARSE;

        matvar->rank = 2;
        matvar->dims = (size_t*)malloc(matvar->rank*sizeof(*matvar->dims));
        if (matvar->dims == NULL) {
            Mat_Critical("Error allocating memory for matvar->dims");
            return;
        }
        matvar->dims[0] = nrows;

        if ( H5Lexists(dset_id,"jc",H5P_DEFAULT) ) {
            sparse_dset_id = H5Dopen(dset_id,"jc",H5P_DEFAULT);
            space_id = H5Dget_space(sparse_dset_id);
            (void)H5Sget_simple_extent_dims(space_id,dims,NULL);
            matvar->dims[1] = dims[0] - 1;
            H5Sclose(space_id);
            H5Dclose(sparse_dset_id);
        }

        /* Test if dataset type is compound and if so if it's complex */
        if ( H5Lexists(dset_id,"data",H5P_DEFAULT) ) {
            sparse_dset_id = H5Dopen(dset_id,"data",H5P_DEFAULT);
            type_id = H5Dget_type(sparse_dset_id);
            if ( H5T_COMPOUND == H5Tget_class(type_id) ) {
                /* FIXME: Any more checks? */
                matvar->isComplex = MAT_F_COMPLEX;
            }
            H5Tclose(type_id);
            H5Dclose(sparse_dset_id);
        }
        return;
    }

    /* Check if the structure defines its fields in MATLAB_fields */
    if ( H5Aexists_by_name(dset_id,".","MATLAB_fields",H5P_DEFAULT) ) {
        hvl_t     *fieldnames_vl;
        attr_id = H5Aopen_by_name(dset_id,".","MATLAB_fields",H5P_DEFAULT,H5P_DEFAULT);
        space_id = H5Aget_space(attr_id);
        (void)H5Sget_simple_extent_dims(space_id,&nfields,NULL);
        field_id = H5Aget_type(attr_id);
        fieldnames_vl = (hvl_t*)malloc(nfields*sizeof(*fieldnames_vl));
        H5Aread(attr_id,field_id,fieldnames_vl);

        matvar->internal->num_fields = nfields;
        matvar->internal->fieldnames =
            (char**)malloc(nfields*sizeof(*matvar->internal->fieldnames));
        for ( k = 0; k < nfields; k++ ) {
            matvar->internal->fieldnames[k] = (char*)calloc(fieldnames_vl[k].len+1,1);
            memcpy(matvar->internal->fieldnames[k],fieldnames_vl[k].p,
                   fieldnames_vl[k].len);
        }

        H5Dvlen_reclaim(field_id,space_id,H5P_DEFAULT,fieldnames_vl);
        H5Sclose(space_id);
        H5Tclose(field_id);
        H5Aclose(attr_id);
        free(fieldnames_vl);
    } else {
        H5G_info_t group_info;
        matvar->internal->num_fields = 0;
        H5Gget_info(dset_id, &group_info);
        if ( group_info.nlinks > 0 ) {
            struct h5_read_group_info_iter_data group_data = {0};
            herr_t herr;

            /* First iteration to retrieve number of relevant links */
            herr = H5Literate_by_name(dset_id, matvar->name, H5_INDEX_NAME, H5_ITER_NATIVE,
                NULL, Mat_H5ReadGroupInfoIterate, (void *)&group_data, H5P_DEFAULT);
            if ( herr > 0 && group_data.nfields > 0 ) {
                matvar->internal->fieldnames =
                    (char**)calloc(group_data.nfields,sizeof(*matvar->internal->fieldnames));
                group_data.nfields = 0;
                group_data.matvar = matvar;
                if ( matvar->internal->fieldnames != NULL ) {
                    /* Second iteration to fill fieldnames */
                    H5Literate_by_name(dset_id, matvar->name, H5_INDEX_NAME, H5_ITER_NATIVE,
                        NULL, Mat_H5ReadGroupInfoIterate, (void *)&group_data, H5P_DEFAULT);
                }
                matvar->internal->num_fields = (unsigned)group_data.nfields;
            }
        }
    }

    if ( matvar->internal->num_fields > 0 ) {
        H5O_info_t object_info;
        H5Oget_info_by_name(dset_id, matvar->internal->fieldnames[0], &object_info, H5P_DEFAULT);
        obj_type = object_info.type;
    } else {
        obj_type = H5O_TYPE_UNKNOWN;
    }
    if ( obj_type == H5O_TYPE_DATASET ) {
        field_id = H5Dopen(dset_id,matvar->internal->fieldnames[0],H5P_DEFAULT);
        field_type_id = H5Dget_type(field_id);
        if ( H5T_REFERENCE == H5Tget_class(field_type_id) ) {
            /* Check if the field has the MATLAB_class attribute. If so, it
             * means the structure is a scalar. Otherwise, the dimensions of
             * the field dataset is the dimensions of the structure
             */
            if ( H5Aexists_by_name(field_id,".","MATLAB_class",H5P_DEFAULT) ) {
                attr_id = H5Aopen_by_name(field_id,".","MATLAB_class",H5P_DEFAULT,H5P_DEFAULT);
                H5Aclose(attr_id);
                matvar->rank    = 2;
                matvar->dims    = (size_t*)malloc(2*sizeof(*matvar->dims));
                if (matvar->dims == NULL) {
                    H5Tclose(field_type_id);
                    H5Dclose(field_id);
                    Mat_Critical("Error allocating memory for matvar->dims");
                    return;
                }
                matvar->dims[0] = 1;
                matvar->dims[1] = 1;
                numel = 1;
            } else {
                space_id     = H5Dget_space(field_id);
                matvar->rank = H5Sget_simple_extent_ndims(space_id);
                matvar->dims = (size_t*)malloc(matvar->rank*sizeof(*matvar->dims));
                if (matvar->dims == NULL) {
                    H5Tclose(field_type_id);
                    H5Dclose(field_id);
                    H5Sclose(space_id);
                    Mat_Critical("Error allocating memory for matvar->dims");
                    return;
                }
                (void)H5Sget_simple_extent_dims(space_id,dims,NULL);
                numel = 1;
                for ( k = 0; k < matvar->rank; k++ ) {
                    matvar->dims[k] = dims[matvar->rank - k - 1];
                    numel *= matvar->dims[k];
                }
                H5Sclose(space_id);
                fields_are_variables = 0;
            }
        } else {
            /* Structure should be a scalar */
            matvar->rank    = 2;
            matvar->dims    = (size_t*)malloc(2*sizeof(*matvar->dims));
            if (matvar->dims == NULL) {
                H5Tclose(field_type_id);
                H5Dclose(field_id);
                Mat_Critical("Error allocating memory for matvar->dims");
                return;
            }
            matvar->dims[0] = 1;
            matvar->dims[1] = 1;
            numel = 1;
        }
        H5Tclose(field_type_id);
        H5Dclose(field_id);
    } else {
        /* Structure should be a scalar */
        numel = 1;
        matvar->rank    = 2;
        matvar->dims    = (size_t*)malloc(2*sizeof(*matvar->dims));
        if (matvar->dims == NULL) {
            Mat_Critical("Error allocating memory for matvar->dims");
            return;
        }
        matvar->dims[0] = 1;
        matvar->dims[1] = 1;
    }

    if ( numel < 1 || nfields < 1 )
        return;

    fields = (matvar_t**)malloc(nfields*numel*sizeof(*fields));
    matvar->data = fields;
    matvar->data_size = sizeof(*fields);
    matvar->nbytes    = nfields*numel*matvar->data_size;
    if ( NULL != fields ) {
        for ( k = 0; k < nfields; k++ ) {
            int l;
            H5O_info_t object_info;
            fields[k] = NULL;
            H5Oget_info_by_name(dset_id, matvar->internal->fieldnames[k], &object_info, H5P_DEFAULT);
            if ( object_info.type == H5O_TYPE_DATASET ) {
                field_id = H5Dopen(dset_id,matvar->internal->fieldnames[k],
                                   H5P_DEFAULT);
                if ( !fields_are_variables ) {
                    hobj_ref_t *ref_ids = (hobj_ref_t*)malloc(numel*sizeof(*ref_ids));
                    H5Dread(field_id,H5T_STD_REF_OBJ,H5S_ALL,H5S_ALL,
                            H5P_DEFAULT,ref_ids);
                    for ( l = 0; l < numel; l++ ) {
                        hid_t ref_id;
                        fields[l*nfields+k] = Mat_VarCalloc();
                        fields[l*nfields+k]->name =
                            mat_strdup(matvar->internal->fieldnames[k]);
                        fields[l*nfields+k]->internal->hdf5_ref=ref_ids[l];
                        /* Get the HDF5 name of the variable */
                        name_len = H5Iget_name(field_id,NULL,0);
                        if ( name_len > 0 ) {
                            fields[l*nfields+k]->internal->hdf5_name =
                                (char*)malloc(name_len+1);
                            (void)H5Iget_name(field_id,
                                fields[l*nfields+k]->internal->hdf5_name,
                                name_len+1);
                        }
                        /* Closing of ref_id is done in
                         * Mat_H5ReadNextReferenceInfo
                         */
                        ref_id = H5Rdereference(field_id,H5R_OBJECT,
                                                ref_ids+l);
                        fields[l*nfields+k]->internal->id=ref_id;
                        Mat_H5ReadNextReferenceInfo(ref_id,fields[l*nfields+k],mat);
                    }
                    free(ref_ids);
                } else {
                    fields[k] = Mat_VarCalloc();
                    fields[k]->internal->fp   = mat;
                    fields[k]->name =
                        mat_strdup(matvar->internal->fieldnames[k]);
                    Mat_H5ReadDatasetInfo(mat,fields[k],field_id);
                }
                H5Dclose(field_id);
            } else if ( object_info.type == H5O_TYPE_GROUP ) {
                field_id = H5Gopen(dset_id,matvar->internal->fieldnames[k],
                                   H5P_DEFAULT);
                if ( -1 < field_id ) {
                    fields[k] = Mat_VarCalloc();
                    fields[k]->internal->fp   = mat;
                    fields[k]->name = mat_strdup(matvar->internal->fieldnames[k]);
                    Mat_H5ReadGroupInfo(mat,fields[k],field_id);
                    H5Gclose(field_id);
                }
            }
        }
    }
}

static herr_t
Mat_H5ReadGroupInfoIterate(hid_t dset_id, const char *name, const H5L_info_t *info, void *op_data)
{
    matvar_t  *matvar;
    H5O_info_t object_info;
    struct h5_read_group_info_iter_data *group_data;

    /* FIXME: follow symlinks, datatypes? */

    H5Oget_info_by_name(dset_id, name, &object_info, H5P_DEFAULT);
    if ( H5O_TYPE_DATASET != object_info.type && H5O_TYPE_GROUP != object_info.type )
        return 0;

    group_data = (struct h5_read_group_info_iter_data *)op_data;
    if ( group_data == NULL )
        return -1;
    matvar = group_data->matvar;

    switch ( object_info.type ) {
        case H5O_TYPE_DATASET:
        {
            if ( matvar != NULL ) {
                matvar->internal->fieldnames[group_data->nfields] =
                    (char*)calloc(strlen(name)+1,sizeof(char));
                strcpy(matvar->internal->fieldnames[group_data->nfields], name);
            }
            group_data->nfields++;
            break;
        }
        case H5O_TYPE_GROUP:
        {
            /* Check that this is not the /#refs# group */
            if ( 0 == strcmp(name,"#refs#") )
                return 0;
            if ( matvar != NULL ) {
                matvar->internal->fieldnames[group_data->nfields] =
                    (char*)calloc(strlen(name)+1,sizeof(char));
                strcpy(matvar->internal->fieldnames[group_data->nfields], name);
            }
            group_data->nfields++;
            break;
        }
        default:
            break;
    }
    return 0;
}

static void
Mat_H5ReadNextReferenceInfo(hid_t ref_id,matvar_t *matvar,mat_t *mat)
{
    if( ref_id < 0 || matvar == NULL)
        return;

    switch ( H5Iget_type(ref_id) ) {
        case H5I_DATASET:
        {
            /* FIXME */
            hsize_t  dims[10];
            hid_t   attr_id,type_id,dset_id,space_id;

            /* matvar->fp = mat; */
            dset_id = ref_id;

#if 0
            /* Get the HDF5 name of the variable */
            name_len = H5Iget_name(dset_id,NULL,0);
            matvar->hdf5_name = malloc(name_len+1);
            (void)H5Iget_name(dset_id,matvar->hdf5_name,name_len);
            printf("%s\n",matvar->hdf5_name);
#endif

            /* Get the rank and dimensions of the data */
            space_id = H5Dget_space(dset_id);
            matvar->rank = H5Sget_simple_extent_ndims(space_id);
            matvar->dims = (size_t*)malloc(matvar->rank*sizeof(*matvar->dims));
            if ( NULL == matvar->dims ) {
                H5Sclose(space_id);
                break;
            } else {
                int k;
                H5Sget_simple_extent_dims(space_id,dims,NULL);
                for ( k = 0; k < matvar->rank; k++ )
                    matvar->dims[k] = dims[matvar->rank - k - 1];
            }
            H5Sclose(space_id);

            Mat_H5ReadClassType(matvar,dset_id);

            if ( H5Aexists_by_name(dset_id,".","MATLAB_global",H5P_DEFAULT) ) {
                attr_id = H5Aopen_by_name(dset_id,".","MATLAB_global",H5P_DEFAULT,H5P_DEFAULT);
                /* FIXME: Check that dataspace is scalar */
                H5Aread(attr_id,H5T_NATIVE_INT,&matvar->isGlobal);
                H5Aclose(attr_id);
            }

            /* Check for attribute that indicates an empty array */
            if ( H5Aexists_by_name(dset_id,".","MATLAB_empty",H5P_DEFAULT) ) {
                int empty = 0;
                attr_id = H5Aopen_by_name(dset_id,".","MATLAB_empty",H5P_DEFAULT,H5P_DEFAULT);
                /* FIXME: Check that dataspace is scalar */
                H5Aread(attr_id,H5T_NATIVE_INT,&empty);
                H5Aclose(attr_id);
                if ( empty ) {
                    matvar->rank = matvar->dims[0];
                    free(matvar->dims);
                    matvar->dims = (size_t*)calloc(matvar->rank,sizeof(*matvar->dims));
                    H5Dread(dset_id,Mat_dims_type_to_hid_t(),H5S_ALL,H5S_ALL,
                            H5P_DEFAULT,matvar->dims);
                }
            }

            /* Test if dataset type is compound and if so if it's complex */
            type_id = H5Dget_type(dset_id);
            if ( H5T_COMPOUND == H5Tget_class(type_id) ) {
                /* FIXME: Any more checks? */
                matvar->isComplex = MAT_F_COMPLEX;
            }
            H5Tclose(type_id);

            /* If the dataset is a cell array read the info of the cells */
            if ( MAT_C_CELL == matvar->class_type ) {
                matvar_t **cells;
                int i,ncells = 1;

                for ( i = 0; i < matvar->rank; i++ )
                    ncells *= matvar->dims[i];
                matvar->data_size = sizeof(matvar_t**);
                matvar->nbytes    = ncells*matvar->data_size;
                matvar->data      = malloc(matvar->nbytes);
                cells = (matvar_t**)matvar->data;

                if ( ncells > 0 ) {
                    hobj_ref_t *ref_ids;
                    ref_ids = (hobj_ref_t*)malloc(ncells*sizeof(*ref_ids));
                    H5Dread(dset_id,H5T_STD_REF_OBJ,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                            ref_ids);
                    for ( i = 0; i < ncells; i++ ) {
                        hid_t ref_id;
                        cells[i] = Mat_VarCalloc();
                        cells[i]->internal->hdf5_ref = ref_ids[i];
                        /* Closing of ref_id is done in Mat_H5ReadNextReferenceInfo */
                        ref_id = H5Rdereference(dset_id,H5R_OBJECT,ref_ids+i);
                        cells[i]->internal->id=ref_id;
                        cells[i]->internal->fp=matvar->internal->fp;
                        Mat_H5ReadNextReferenceInfo(ref_id,cells[i],mat);
                    }
                    free(ref_ids);
                }
            } else if ( MAT_C_STRUCT == matvar->class_type ) {
                /* Empty structures can be a dataset */

                /* Check if the structure defines its fields in MATLAB_fields */
                if ( H5Aexists_by_name(dset_id,".","MATLAB_fields",H5P_DEFAULT) ) {
                    int      i;
                    hid_t    field_id;
                    hsize_t  nfields;
                    hvl_t   *fieldnames_vl;

                    attr_id = H5Aopen_by_name(dset_id,".","MATLAB_fields",H5P_DEFAULT,H5P_DEFAULT);
                    space_id = H5Aget_space(attr_id);
                    (void)H5Sget_simple_extent_dims(space_id,&nfields,NULL);
                    field_id = H5Aget_type(attr_id);
                    fieldnames_vl = (hvl_t*)malloc(nfields*sizeof(*fieldnames_vl));
                    H5Aread(attr_id,field_id,fieldnames_vl);

                    matvar->internal->num_fields = nfields;
                    matvar->internal->fieldnames =
                        (char**)malloc(nfields*sizeof(*matvar->internal->fieldnames));
                    for ( i = 0; i < nfields; i++ ) {
                        matvar->internal->fieldnames[i] =
                            (char*)calloc(fieldnames_vl[i].len+1,1);
                        memcpy(matvar->internal->fieldnames[i],
                               fieldnames_vl[i].p,fieldnames_vl[i].len);
                    }

                    H5Dvlen_reclaim(field_id,space_id,H5P_DEFAULT,
                        fieldnames_vl);
                    H5Sclose(space_id);
                    H5Tclose(field_id);
                    H5Aclose(attr_id);
                    free(fieldnames_vl);
                }
            }

            if ( matvar->internal->id != dset_id ) {
                /* Close dataset and increment count */
                H5Dclose(dset_id);
            }

            /*H5Dclose(dset_id);*/
            break;
        }
        case H5I_GROUP:
        {
            Mat_H5ReadGroupInfo(mat,matvar,ref_id);
            break;
        }
        default:
            break;
    }
    return;
}

static void
Mat_H5ReadNextReferenceData(hid_t ref_id,matvar_t *matvar,mat_t *mat)
{
    int k;
    size_t numel;
    hid_t  dset_id;

    if( ref_id < 0 || matvar == NULL)
        return;

    /* If the datatype with references is a cell, we've already read info into
     * the variable data, so just loop over each cell element and call
     * Mat_H5ReadNextReferenceData on it.
     */
    if ( MAT_C_CELL == matvar->class_type ) {
        matvar_t **cells = (matvar_t**)matvar->data;
        numel = 1;
        for ( k = 0; k < matvar->rank; k++ )
            numel *= matvar->dims[k];
        for ( k = 0; k < numel; k++ )
            Mat_H5ReadNextReferenceData(cells[k]->internal->id,cells[k],mat);
        return;
    }

    switch ( H5Iget_type(ref_id) ) {
        case H5I_DATASET:
        {
            hid_t data_type_id;
            numel = 1;
            for ( k = 0; k < matvar->rank; k++ )
                numel *= matvar->dims[k];

            if ( MAT_C_CHAR == matvar->class_type ) {
                matvar->data_type = MAT_T_UINT8;
                matvar->data_size = Mat_SizeOf(MAT_T_UINT8);
                data_type_id      = Mat_data_type_to_hid_t(MAT_T_UINT8);
            } else if ( MAT_C_STRUCT == matvar->class_type ) {
                /* Empty structure array */
                break;
            } else {
                matvar->data_size = Mat_SizeOfClass(matvar->class_type);
                data_type_id      = Mat_class_type_to_hid_t(matvar->class_type);
            }
            matvar->nbytes    = numel*matvar->data_size;

            if ( matvar->nbytes < 1 ) {
                H5Dclose(ref_id);
                break;
            }

            dset_id = ref_id;

            if ( !matvar->isComplex ) {
                matvar->data      = malloc(matvar->nbytes);
                if ( NULL != matvar->data ) {
                    H5Dread(dset_id,data_type_id,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                            matvar->data);
                }
            } else {
                mat_complex_split_t *complex_data;
                hid_t h5_complex_base,h5_complex;

                complex_data     = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);

                h5_complex_base = data_type_id;
                h5_complex      = H5Tcreate(H5T_COMPOUND,
                                            H5Tget_size(h5_complex_base));
                H5Tinsert(h5_complex,"real",0,h5_complex_base);
                H5Dread(dset_id,h5_complex,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                        complex_data->Re);
                H5Tclose(h5_complex);

                h5_complex      = H5Tcreate(H5T_COMPOUND,
                                            H5Tget_size(h5_complex_base));
                H5Tinsert(h5_complex,"imag",0,h5_complex_base);
                H5Dread(dset_id,h5_complex,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                        complex_data->Im);
                H5Tclose(h5_complex);
                matvar->data = complex_data;
            }
            H5Dclose(dset_id);
            break;
        }
        case H5I_GROUP:
        {
            matvar_t **fields;
            int i,nfields = 0;

            if ( MAT_C_SPARSE == matvar->class_type ) {
                Mat_VarRead73(mat,matvar);
            } else {
                if ( !matvar->nbytes || !matvar->data_size || NULL == matvar->data )
                    break;
                nfields = matvar->nbytes / matvar->data_size;
                fields  = (matvar_t**)matvar->data;
                for ( i = 0; i < nfields; i++ ) {
                    if (  0 < fields[i]->internal->hdf5_ref &&
                         -1 < fields[i]->internal->id ) {
                        /* Dataset of references */
                        Mat_H5ReadNextReferenceData(fields[i]->internal->id,fields[i],mat);
                    } else {
                        Mat_VarRead73(mat,fields[i]);
                    }
                }
            }
            break;
        }
        default:
            break;
    }
    return;
}

/** @if mat_devman
 * @brief Writes a cell array matlab variable to the specified HDF id with the
 *        given name
 *
 * @ingroup mat_internal
 * @param id HDF id of the parent object
 * @param matvar pointer to the cell array variable
 * @param name Name of the HDF dataset
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWriteCell73(hid_t id,matvar_t *matvar,const char *name,hid_t *refs_id)
{
    unsigned   k;
    hid_t      str_type_id,mspace_id,dset_id,attr_type_id,attr_id,aspace_id;
    hsize_t    nmemb;
    matvar_t **cells;
    int        is_ref, err = -1;
    char       id_name[128] = {'\0',};
    hsize_t    perm_dims[10];

    cells = (matvar_t**)matvar->data;
    nmemb = matvar->dims[0];
    for ( k = 1; k < matvar->rank; k++ )
        nmemb *= matvar->dims[k];

    if ( 0 == nmemb || NULL == matvar->data ) {
        hsize_t rank = matvar->rank;
        unsigned empty = 1;
        mspace_id = H5Screate_simple(1,&rank,NULL);
        dset_id = H5Dcreate(id,name,H5T_NATIVE_HSIZE,mspace_id,
                            H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id,
                    strlen(Mat_class_names[matvar->class_type])+1);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_class",attr_type_id,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,attr_type_id,
                 Mat_class_names[matvar->class_type]);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);
        /* Write the empty attribute */
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_empty",H5T_NATIVE_UINT,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,H5T_NATIVE_UINT,&empty);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        /* Write the dimensions as the data */
        H5Dwrite(dset_id,Mat_dims_type_to_hid_t(),H5S_ALL,H5S_ALL,
                 H5P_DEFAULT,matvar->dims);
        H5Dclose(dset_id);
        H5Sclose(mspace_id);

        err = 0;
    } else {
        (void)H5Iget_name(id,id_name,127);
        is_ref = !strcmp(id_name,"/#refs#");
        if ( *refs_id < 0 ) {
            if ( H5Lexists(id,"/#refs#",H5P_DEFAULT) ) {
                *refs_id = H5Gopen(id,"/#refs#",H5P_DEFAULT);
            } else {
                *refs_id = H5Gcreate(id,"/#refs#",H5P_DEFAULT,
                                     H5P_DEFAULT,H5P_DEFAULT);
            }
        }
        if ( *refs_id > -1 ) {
            char        obj_name[64];
            hobj_ref_t *refs;

            for ( k = 0; k < matvar->rank; k++ )
                perm_dims[k] = matvar->dims[matvar->rank-k-1];

            refs = (hobj_ref_t*)malloc(nmemb*sizeof(*refs));
            mspace_id=H5Screate_simple(matvar->rank,perm_dims,NULL);
            dset_id = H5Dcreate(id,name,H5T_STD_REF_OBJ,mspace_id,
                                H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);

            for ( k = 0; k < nmemb; k++ ) {
                H5G_info_t group_info;
                H5Gget_info(*refs_id, &group_info);
                sprintf(obj_name,"%lld",group_info.nlinks);
                if ( NULL != cells[k] )
                    cells[k]->compression = matvar->compression;
                Mat_VarWriteNext73(*refs_id,cells[k],obj_name,refs_id);
                sprintf(obj_name,"/#refs#/%lld",group_info.nlinks);
                H5Rcreate(refs+k,id,obj_name,H5R_OBJECT,-1);
            }

            H5Dwrite(dset_id,H5T_STD_REF_OBJ,H5S_ALL,H5S_ALL,
                     H5P_DEFAULT,refs);

            str_type_id = H5Tcopy(H5T_C_S1);
            H5Tset_size(str_type_id,7);
            aspace_id = H5Screate(H5S_SCALAR);
            attr_id = H5Acreate(dset_id,"MATLAB_class",str_type_id,
                                aspace_id,H5P_DEFAULT,H5P_DEFAULT);
            H5Awrite(attr_id,str_type_id,"cell");
            H5Aclose(attr_id);
            H5Sclose(aspace_id);
            H5Tclose(str_type_id);
            H5Dclose(dset_id);
            free(refs);
            H5Sclose(mspace_id);

            err = 0;
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
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWriteChar73(hid_t id,matvar_t *matvar,const char *name)
{
    int err = -1;
    unsigned long k,numel;
    hid_t mspace_id,dset_id,attr_type_id,attr_id,aspace_id;
    hsize_t perm_dims[10];

    numel = 1;
    for ( k = 0; k < matvar->rank; k++ ) {
        perm_dims[k] = matvar->dims[matvar->rank-k-1];
        numel *= perm_dims[k];
    }

    if ( 0 == numel || NULL == matvar->data ) {
        hsize_t rank = matvar->rank;
        unsigned empty = 1;
        mspace_id = H5Screate_simple(1,&rank,NULL);
        dset_id = H5Dcreate(id,name,H5T_NATIVE_HSIZE,mspace_id,
                            H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id,
                    strlen(Mat_class_names[matvar->class_type])+1);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_class",attr_type_id,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,attr_type_id,
                 Mat_class_names[matvar->class_type]);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);
        /* Write the empty attribute */
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_empty",H5T_NATIVE_UINT,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,H5T_NATIVE_UINT,&empty);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        /* Write the dimensions as the data */
        H5Dwrite(dset_id,Mat_dims_type_to_hid_t(),H5S_ALL,H5S_ALL,
                 H5P_DEFAULT,matvar->dims);
        H5Dclose(dset_id);
        H5Sclose(mspace_id);
        err = 0;
    } else {
        int matlab_int_decode = 2;

        mspace_id = H5Screate_simple(matvar->rank,perm_dims,NULL);
        switch ( matvar->data_type ) {
            case MAT_T_UTF32:
            case MAT_T_INT32:
            case MAT_T_UINT32:
                /* Not sure matlab will actually handle this */
                dset_id = H5Dcreate(id,name,
                                    Mat_class_type_to_hid_t(MAT_C_UINT32),
                                    mspace_id,H5P_DEFAULT,H5P_DEFAULT,
                                    H5P_DEFAULT);
                break;
            case MAT_T_UTF16:
            case MAT_T_UTF8:
            case MAT_T_INT16:
            case MAT_T_UINT16:
            case MAT_T_INT8:
            case MAT_T_UINT8:
                dset_id = H5Dcreate(id,name,
                                    Mat_class_type_to_hid_t(MAT_C_UINT16),
                                    mspace_id,H5P_DEFAULT,H5P_DEFAULT,
                                    H5P_DEFAULT);
                break;
            default:
                H5Sclose(mspace_id);
                return err;
        }
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id,
                    strlen(Mat_class_names[matvar->class_type])+1);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_class",attr_type_id,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,attr_type_id,Mat_class_names[matvar->class_type]);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);

        attr_type_id = H5Tcopy(H5T_NATIVE_INT);
        attr_id = H5Acreate(dset_id,"MATLAB_int_decode",attr_type_id,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,attr_type_id,&matlab_int_decode);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);
        H5Sclose(aspace_id);

        H5Dwrite(dset_id,Mat_data_type_to_hid_t(matvar->data_type),
                 H5S_ALL,H5S_ALL,H5P_DEFAULT,matvar->data);
        H5Dclose(dset_id);
        H5Sclose(mspace_id);
        err = 0;
    }

    return err;
}

static int
Mat_WriteEmptyVariable73(hid_t id,const char *name,hsize_t rank,size_t *dims)
{
    int err = -1;
    unsigned empty = 1;
    hid_t mspace_id,dset_id,attr_type_id,attr_id,aspace_id;

    mspace_id = H5Screate_simple(1,&rank,NULL);
    dset_id = H5Dcreate(id,name,H5T_NATIVE_HSIZE,mspace_id,
                        H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);
    if ( dset_id > -1 ) {
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id,7);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_class",attr_type_id,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,attr_type_id,"double");
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);

        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_empty",H5T_NATIVE_UINT,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,H5T_NATIVE_UINT,&empty);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);

        /* Write the dimensions as the data */
        H5Dwrite(dset_id,Mat_dims_type_to_hid_t(),H5S_ALL,H5S_ALL,
                 H5P_DEFAULT,dims);
        err = 0;
        H5Dclose(dset_id);
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
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWriteLogical73(hid_t id,matvar_t *matvar,const char *name)
{
    int err = -1;
    unsigned long k,numel;
    hid_t mspace_id,dset_id,attr_type_id,attr_id,aspace_id,plist;
    hsize_t perm_dims[10];
    herr_t herr;
    int int_decode = 1;

    numel = 1;
    for ( k = 0; k < matvar->rank; k++ ) {
        perm_dims[k] = matvar->dims[matvar->rank-k-1];
        numel *= perm_dims[k];
    }

    if ( matvar->compression ) {
        hsize_t chunk_dims[10];
        Mat_H5GetChunkSize(matvar->rank, perm_dims,chunk_dims);
        plist = H5Pcreate(H5P_DATASET_CREATE);
        herr = H5Pset_chunk(plist, matvar->rank, chunk_dims);
        herr = H5Pset_deflate(plist, 9);
    } else {
        plist = H5P_DEFAULT;
    }

    if ( 0 == numel || NULL == matvar->data ) {
        hsize_t rank = matvar->rank;
        unsigned empty = 1;
        mspace_id = H5Screate_simple(1,&rank,NULL);

        dset_id = H5Dcreate(id,name,H5T_NATIVE_HSIZE,mspace_id,
                            H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id,7);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_class",attr_type_id,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,attr_type_id,"logical");
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);
        /* Write the MATLAB_int_decode attribute */
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_int_decode",H5T_NATIVE_INT,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,H5T_NATIVE_INT,&int_decode);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        /* Write the empty attribute */
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_empty",H5T_NATIVE_UINT,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,H5T_NATIVE_UINT,&empty);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        /* Write the dimensions as the data */
        H5Dwrite(dset_id,Mat_dims_type_to_hid_t(),H5S_ALL,H5S_ALL,
                 H5P_DEFAULT,matvar->dims);
        H5Dclose(dset_id);
        H5Sclose(mspace_id);
        err = 0;
    } else {
        mspace_id = H5Screate_simple(matvar->rank,perm_dims,NULL);
        /* Note that MATLAB only recognizes uint8 as logical */
        dset_id = H5Dcreate(id,name,
                            Mat_class_type_to_hid_t(MAT_C_UINT8),
                            mspace_id,H5P_DEFAULT,plist,H5P_DEFAULT);
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id,7);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_class",attr_type_id,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,attr_type_id,"logical");
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);
        /* Write the MATLAB_int_decode attribute */
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_int_decode",H5T_NATIVE_INT,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,H5T_NATIVE_INT,&int_decode);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);

        H5Dwrite(dset_id,Mat_data_type_to_hid_t(matvar->data_type),
                 H5S_ALL,H5S_ALL,H5P_DEFAULT,matvar->data);
        H5Dclose(dset_id);
        H5Sclose(mspace_id);
        err = 0;
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
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWriteNumeric73(hid_t id,matvar_t *matvar,const char *name)
{
    int err = -1;
    unsigned long k,numel;
    hid_t mspace_id,dset_id,attr_type_id,attr_id,aspace_id,plist;
    hsize_t perm_dims[10];
    herr_t herr;

    numel = 1;
    for ( k = 0; k < matvar->rank; k++ ) {
        perm_dims[k] = matvar->dims[matvar->rank-k-1];
        numel *= perm_dims[k];
    }

    if ( matvar->compression ) {
        hsize_t chunk_dims[10];
        Mat_H5GetChunkSize(matvar->rank, perm_dims,chunk_dims);
        plist = H5Pcreate(H5P_DATASET_CREATE);
        herr = H5Pset_chunk(plist, matvar->rank, chunk_dims);
        herr = H5Pset_deflate(plist, 9);
    } else {
        plist = H5P_DEFAULT;
    }

    if ( 0 == numel || NULL == matvar->data ) {
        hsize_t rank = matvar->rank;
        unsigned empty = 1;
        mspace_id = H5Screate_simple(1,&rank,NULL);

        dset_id = H5Dcreate(id,name,H5T_NATIVE_HSIZE,mspace_id,
                            H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id,
                    strlen(Mat_class_names[matvar->class_type])+1);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_class",attr_type_id,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,attr_type_id,
                 Mat_class_names[matvar->class_type]);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);
        /* Write the empty attribute */
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_empty",H5T_NATIVE_UINT,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,H5T_NATIVE_UINT,&empty);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        /* Write the dimensions as the data */
        H5Dwrite(dset_id,Mat_dims_type_to_hid_t(),H5S_ALL,H5S_ALL,
                 H5P_DEFAULT,matvar->dims);
        H5Dclose(dset_id);
        H5Sclose(mspace_id);
        err = 0;
    } else if ( matvar->isComplex ) {
        hid_t h5_complex,h5_complex_base;

        h5_complex_base = Mat_class_type_to_hid_t(matvar->class_type);
        h5_complex      = H5Tcreate(H5T_COMPOUND,
                                    2*H5Tget_size(h5_complex_base));
        H5Tinsert(h5_complex,"real",0,h5_complex_base);
        H5Tinsert(h5_complex,"imag",H5Tget_size(h5_complex_base),
                  h5_complex_base);
        mspace_id = H5Screate_simple(matvar->rank,perm_dims,NULL);
        dset_id = H5Dcreate(id,name,h5_complex,mspace_id,H5P_DEFAULT,
                            plist,H5P_DEFAULT);
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id,
                    strlen(Mat_class_names[matvar->class_type])+1);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_class",attr_type_id,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,attr_type_id,
                 Mat_class_names[matvar->class_type]);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);
        H5Tclose(h5_complex);

        /* Write real part of dataset */
        h5_complex = H5Tcreate(H5T_COMPOUND,
                               H5Tget_size(h5_complex_base));
        H5Tinsert(h5_complex,"real",0,h5_complex_base);
        H5Dwrite(dset_id,h5_complex,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                 ((mat_complex_split_t*)matvar->data)->Re);
        H5Tclose(h5_complex);

        /* Write imaginary part of dataset */
        h5_complex      = H5Tcreate(H5T_COMPOUND,
                                    H5Tget_size(h5_complex_base));
        H5Tinsert(h5_complex,"imag",0,h5_complex_base);
        H5Dwrite(dset_id,h5_complex,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                 ((mat_complex_split_t*)matvar->data)->Im);
        H5Tclose(h5_complex);
        H5Dclose(dset_id);
        H5Sclose(mspace_id);
        err = 0;
    } else { /* matvar->isComplex */
        mspace_id = H5Screate_simple(matvar->rank,perm_dims,NULL);
        dset_id = H5Dcreate(id,name,
                            Mat_class_type_to_hid_t(matvar->class_type),
                            mspace_id,H5P_DEFAULT,plist,H5P_DEFAULT);
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id,
                    strlen(Mat_class_names[matvar->class_type])+1);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_class",attr_type_id,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,attr_type_id,
                 Mat_class_names[matvar->class_type]);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);
        H5Dwrite(dset_id,Mat_data_type_to_hid_t(matvar->data_type),
                 H5S_ALL,H5S_ALL,H5P_DEFAULT,matvar->data);
        H5Dclose(dset_id);
        H5Sclose(mspace_id);
        err = 0;
    }

    if ( H5P_DEFAULT != plist )
        H5Pclose(plist);

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
Mat_VarWriteSparse73(hid_t id,matvar_t *matvar,const char *name)
{
    int err = -1;
    unsigned k;
    hid_t      sparse_id,mspace_id,dset_id,attr_type_id,attr_id,aspace_id;
    hsize_t    nmemb;
    hsize_t    perm_dims[10];

    nmemb = matvar->dims[0];
    for ( k = 1; k < matvar->rank; k++ )
        nmemb *= matvar->dims[k];

    sparse_id = H5Gcreate(id,name,H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);
    if ( sparse_id < 0 ) {
        Mat_Critical("Error creating group for sparse array %s",
                     matvar->name);
    } else {
        hid_t size_type_id,data_type_id;
        mat_sparse_t *sparse;
        hsize_t rank, nir, njc, ndata;
        mat_uint64_t sparse_attr_value;
        enum matio_classes class_type;

        sparse = (mat_sparse_t*)matvar->data;
        rank = matvar->rank;

        class_type = Mat_TypeToClass73(matvar->data_type);
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id,
                    strlen(Mat_class_names[class_type])+1);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(sparse_id,"MATLAB_class",attr_type_id,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,attr_type_id,
                 Mat_class_names[class_type]);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);

        sparse_attr_value = matvar->dims[0];
        size_type_id = Mat_class_type_to_hid_t(MAT_C_UINT64);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(sparse_id,"MATLAB_sparse",size_type_id,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,size_type_id,&sparse_attr_value);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);

        ndata = sparse->ndata;
        data_type_id = Mat_data_type_to_hid_t(matvar->data_type);
        if ( matvar->isComplex ) {
            hid_t h5_complex;
            mat_complex_split_t *complex_data;

            complex_data = (mat_complex_split_t*)sparse->data;

            /* Create dataset datatype as compound with real and
             * imaginary fields
             */
            h5_complex      = H5Tcreate(H5T_COMPOUND,
                                        2*H5Tget_size(data_type_id));
            H5Tinsert(h5_complex,"real",0,data_type_id);
            H5Tinsert(h5_complex,"imag",H5Tget_size(data_type_id),
                      data_type_id);

            /* Create dataset */
            perm_dims[0] = ndata;
            mspace_id = H5Screate_simple(1,perm_dims,NULL);
            dset_id = H5Dcreate(sparse_id,"data",h5_complex,mspace_id,
                                H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);
            H5Tclose(h5_complex);

            /* Write real part of dataset */
            h5_complex = H5Tcreate(H5T_COMPOUND,
                                   H5Tget_size(data_type_id));
            H5Tinsert(h5_complex,"real",0,data_type_id);
            H5Dwrite(dset_id,h5_complex,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                     complex_data->Re);
            H5Tclose(h5_complex);

            /* Write imaginary part of dataset */
            h5_complex      = H5Tcreate(H5T_COMPOUND,H5Tget_size(data_type_id));
            H5Tinsert(h5_complex,"imag",0,data_type_id);
            H5Dwrite(dset_id,h5_complex,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                     complex_data->Im);
            H5Tclose(h5_complex);
            H5Dclose(dset_id);
            H5Sclose(mspace_id);
        } else { /* if ( matvar->isComplex ) */
            mspace_id = H5Screate_simple(1,&ndata,NULL);
            dset_id = H5Dcreate(sparse_id,"data",data_type_id,mspace_id,
                                H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);
            H5Dwrite(dset_id,data_type_id,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                     sparse->data);
            H5Dclose(dset_id);
            H5Sclose(mspace_id);
        }

        nir = sparse->nir;
        mspace_id = H5Screate_simple(1,&nir,NULL);
        dset_id = H5Dcreate(sparse_id,"ir",size_type_id,mspace_id,
                            H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);
        H5Dwrite(dset_id,H5T_NATIVE_INT,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                 sparse->ir);
        H5Dclose(dset_id);
        H5Sclose(mspace_id);

        njc = sparse->njc;
        mspace_id = H5Screate_simple(1,&njc,NULL);
        dset_id = H5Dcreate(sparse_id,"jc",size_type_id,mspace_id,
                            H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);
        H5Dwrite(dset_id,H5T_NATIVE_INT,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                 sparse->jc);
        H5Dclose(dset_id);
        H5Sclose(mspace_id);
        H5Gclose(sparse_id);
        err = 0;
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
 * @retval 0 on success
 * @endif
 */
static int
Mat_VarWriteStruct73(hid_t id,matvar_t *matvar,const char *name,hid_t *refs_id)
{
    int err = -1;
    unsigned   k;
    hid_t      mspace_id,dset_id,attr_type_id,attr_id,aspace_id;
    hid_t      struct_id,str_type_id,fieldnames_id;
    hsize_t    nfields,nmemb;
    matvar_t **fields;
    hvl_t     *fieldnames;
    char       id_name[128] = {'\0',};
    int        is_ref;
    hsize_t    perm_dims[10];

    nmemb = 1;
    for ( k = 0; k < matvar->rank; k++ )
        nmemb *= matvar->dims[k];

    if ( 0 == nmemb || NULL == matvar->data ) {
        hsize_t rank = matvar->rank;
        unsigned empty = 1;
        mspace_id = H5Screate_simple(1,&rank,NULL);
        dset_id = H5Dcreate(id,name,H5T_NATIVE_HSIZE,mspace_id,
                            H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);
        attr_type_id = H5Tcopy(H5T_C_S1);
        H5Tset_size(attr_type_id,
                    strlen(Mat_class_names[matvar->class_type])+1);
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_class",attr_type_id,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,attr_type_id,
                 Mat_class_names[matvar->class_type]);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);
        H5Tclose(attr_type_id);
        /* Write the empty attribute */
        aspace_id = H5Screate(H5S_SCALAR);
        attr_id = H5Acreate(dset_id,"MATLAB_empty",H5T_NATIVE_UINT,
                            aspace_id,H5P_DEFAULT,H5P_DEFAULT);
        H5Awrite(attr_id,H5T_NATIVE_UINT,&empty);
        H5Sclose(aspace_id);
        H5Aclose(attr_id);

        nfields = matvar->internal->num_fields;
        if ( nfields ) {
            str_type_id = H5Tcopy(H5T_C_S1);
            fieldnames = (hvl_t*)malloc(nfields*sizeof(*fieldnames));
            fields     = (matvar_t**)matvar->data;
            for ( k = 0; k < nfields; k++ ) {
                fieldnames[k].len =
                strlen(matvar->internal->fieldnames[k]);
                fieldnames[k].p   = matvar->internal->fieldnames[k];
            }
            H5Tset_size(str_type_id,1);
            fieldnames_id = H5Tvlen_create(str_type_id);
            aspace_id     = H5Screate_simple(1,&nfields,NULL);
            attr_id = H5Acreate(dset_id,"MATLAB_fields",fieldnames_id,
                                aspace_id,H5P_DEFAULT,H5P_DEFAULT);
            H5Awrite(attr_id,fieldnames_id,fieldnames);
            H5Aclose(attr_id);
            H5Sclose(aspace_id);
            H5Tclose(fieldnames_id);
            H5Tclose(str_type_id);
            free(fieldnames);
        }

        /* Write the dimensions as the data */
        H5Dwrite(dset_id,Mat_dims_type_to_hid_t(),H5S_ALL,H5S_ALL,
                 H5P_DEFAULT,matvar->dims);
        H5Dclose(dset_id);
        H5Sclose(mspace_id);
    } else {
        (void)H5Iget_name(id,id_name,127);
        is_ref = !strcmp(id_name,"/#refs#");
        struct_id = H5Gcreate(id,name,H5P_DEFAULT,H5P_DEFAULT,
                              H5P_DEFAULT);
        if ( struct_id < 0 ) {
            Mat_Critical("Error creating group for struct %s",name);
        } else {
            str_type_id = H5Tcopy(H5T_C_S1);
            H5Tset_size(str_type_id,7);
            aspace_id = H5Screate(H5S_SCALAR);
            attr_id = H5Acreate(struct_id,"MATLAB_class",str_type_id,
                                aspace_id,H5P_DEFAULT,H5P_DEFAULT);
            H5Awrite(attr_id,str_type_id,"struct");
            H5Aclose(attr_id);
            H5Sclose(aspace_id);

            nfields = matvar->internal->num_fields;

            /* Structure with no fields */
            if ( nfields == 0 ) {
                H5Gclose(struct_id);
                H5Tclose(str_type_id);
                return 0;
            }

            fieldnames = (hvl_t*)malloc(nfields*sizeof(*fieldnames));
            fields     = (matvar_t**)matvar->data;
            for ( k = 0; k < nfields; k++ ) {
                fieldnames[k].len =
                strlen(matvar->internal->fieldnames[k]);
                fieldnames[k].p   = matvar->internal->fieldnames[k];
            }
            H5Tset_size(str_type_id,1);
            fieldnames_id = H5Tvlen_create(str_type_id);
            aspace_id     = H5Screate_simple(1,&nfields,NULL);
            attr_id = H5Acreate(struct_id,"MATLAB_fields",fieldnames_id,
                                aspace_id,H5P_DEFAULT,H5P_DEFAULT);
            H5Awrite(attr_id,fieldnames_id,fieldnames);
            H5Aclose(attr_id);
            H5Sclose(aspace_id);
            H5Tclose(fieldnames_id);
            H5Tclose(str_type_id);
            free(fieldnames);

            if ( 1 == nmemb ) {
                for ( k = 0; k < nfields; k++ ) {
                    if ( NULL != fields[k] )
                        fields[k]->compression = matvar->compression;
                    Mat_VarWriteNext73(struct_id,fields[k],
                        matvar->internal->fieldnames[k],refs_id);
                }
            } else {
                if ( *refs_id < 0 ) {
                    if ( H5Lexists(id,"/#refs#",H5P_DEFAULT) ) {
                        *refs_id = H5Gopen(id,"/#refs#",H5P_DEFAULT);
                    } else {
                        *refs_id = H5Gcreate(id,"/#refs#",H5P_DEFAULT,
                                             H5P_DEFAULT,H5P_DEFAULT);
                    }
                }
                if ( *refs_id > -1 ) {
                    char name[64];
                    hobj_ref_t **refs;
                    int l;

                    refs = (hobj_ref_t**)malloc(nfields*sizeof(*refs));
                    for ( l = 0; l < nfields; l++ )
                        refs[l] = (hobj_ref_t*)malloc(nmemb*sizeof(*refs[l]));

                    for ( k = 0; k < nmemb; k++ ) {
                        for ( l = 0; l < nfields; l++ ) {
                            H5G_info_t group_info;
                            H5Gget_info(*refs_id, &group_info);
                            sprintf(name,"%lld",group_info.nlinks);
                            if ( NULL != fields[k*nfields+l] )
                                fields[k*nfields+l]->compression =
                                    matvar->compression;
                            Mat_VarWriteNext73(*refs_id,fields[k*nfields+l],
                                name,refs_id);
                            sprintf(name,"/#refs#/%lld",group_info.nlinks);
                            H5Rcreate(refs[l]+k,id,name,H5R_OBJECT,-1);
                        }
                    }

                    for ( k = 0; k < matvar->rank; k++ )
                        perm_dims[k] = matvar->dims[matvar->rank-k-1];
                    mspace_id=H5Screate_simple(matvar->rank,perm_dims,NULL);
                    for ( l = 0; l < nfields; l++ ) {
                        dset_id = H5Dcreate(struct_id,
                                            matvar->internal->fieldnames[l],
                                            H5T_STD_REF_OBJ,mspace_id,
                                            H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);
                        H5Dwrite(dset_id,H5T_STD_REF_OBJ,H5S_ALL,
                                 H5S_ALL,H5P_DEFAULT,refs[l]);
                        H5Dclose(dset_id);
                        free(refs[l]);
                    }
                    free(refs);
                    H5Sclose(mspace_id);
                }
            }
        }
        H5Gclose(struct_id);
    }
    return err;
}

static int
Mat_VarWriteNext73(hid_t id,matvar_t *matvar,const char *name,hid_t *refs_id)
{
    int err = -1;
    if ( NULL == matvar ) {
        size_t dims[2] = {0,0};
        return Mat_WriteEmptyVariable73(id,name,2,dims);
    } else if ( matvar->isLogical ) {
        return Mat_VarWriteLogical73(id,matvar,name);
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
        case MAT_C_UINT8:
            err = Mat_VarWriteNumeric73(id,matvar,name);
            break;
        case MAT_C_CHAR:
            err = Mat_VarWriteChar73(id,matvar,name);
            break;
        case MAT_C_STRUCT:
            err = Mat_VarWriteStruct73(id,matvar,name,refs_id);
            break;
        case MAT_C_CELL:
            err = Mat_VarWriteCell73(id,matvar,name,refs_id);
            break;
        case MAT_C_SPARSE:
            err = Mat_VarWriteSparse73(id,matvar,name);
            break;
        case MAT_C_EMPTY:
        case MAT_C_FUNCTION:
        case MAT_C_OBJECT:
            break;
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
mat_t *
Mat_Create73(const char *matname,const char *hdr_str)
{
    FILE *fp = NULL;
    mat_int16_t endian = 0, version;
    mat_t *mat = NULL;
    size_t err;
    time_t t;
    hid_t plist_id,fid;

    plist_id = H5Pcreate(H5P_FILE_CREATE);
    H5Pset_userblock(plist_id,512);
    fid = H5Fcreate(matname,H5F_ACC_TRUNC,plist_id,H5P_DEFAULT);
    H5Fclose(fid);
    H5Pclose(plist_id);

    fp = fopen(matname,"r+b");
    if ( !fp )
        return NULL;

    (void)fseek(fp,0,SEEK_SET);

    mat = (mat_t*)malloc(sizeof(*mat));
    if ( mat == NULL ) {
        fclose(fp);
        return NULL;
    }

    mat->fp               = NULL;
    mat->header           = NULL;
    mat->subsys_offset    = NULL;
    mat->filename         = NULL;
    mat->version          = 0;
    mat->byteswap         = 0;
    mat->mode             = 0;
    mat->bof              = 0;
    mat->next_index       = 0;
    mat->refs_id          = -1;

    t = time(NULL);
    mat->filename = strdup_printf("%s",matname);
    mat->mode     = MAT_ACC_RDWR;
    mat->byteswap = 0;
    mat->header   = (char*)malloc(128*sizeof(char));
    mat->subsys_offset = (char*)malloc(8*sizeof(char));
    memset(mat->header,' ',128);
    if ( hdr_str == NULL ) {
        err = mat_snprintf(mat->header,116,"MATLAB 7.3 MAT-file, Platform: %s, "
                "Created by: libmatio v%d.%d.%d on %s HDF5 schema 0.5",
                MATIO_PLATFORM, MATIO_MAJOR_VERSION, MATIO_MINOR_VERSION,
                MATIO_RELEASE_LEVEL, ctime(&t));
    } else {
        err = mat_snprintf(mat->header,116,"%s",hdr_str);
    }
    if ( err >= 116 )
        mat->header[115] = '\0'; /* Just to make sure it's NULL terminated */
    memset(mat->subsys_offset,' ',8);
    mat->version = (int)0x0200;
    endian = 0x4d49;

    version = 0x0200;

    err = fwrite(mat->header,1,116,fp);
    err = fwrite(mat->subsys_offset,1,8,fp);
    err = fwrite(&version,2,1,fp);
    err = fwrite(&endian,2,1,fp);

    fclose(fp);

    fid = H5Fopen(matname,H5F_ACC_RDWR,H5P_DEFAULT);

    mat->fp = malloc(sizeof(hid_t));
    *(hid_t*)mat->fp = fid;

    return mat;
}

/** @if mat_devman
 * @brief Reads the MAT variable identified by matvar
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @param matvar MAT variable pointer
 * @endif
 */
void
Mat_VarRead73(mat_t *mat,matvar_t *matvar)
{
    int k;
    size_t numel;
    hid_t fid,dset_id,ref_id;

    if ( NULL == mat || NULL == matvar )
        return;
    else if (NULL == matvar->internal->hdf5_name && 0 > matvar->internal->id)
        return;

    fid = *(hid_t*)mat->fp;

    switch (matvar->class_type) {
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
            numel = 1;
            for ( k = 0; k < matvar->rank; k++ )
                numel *= matvar->dims[k];
            matvar->data_size = Mat_SizeOfClass(matvar->class_type);
            matvar->nbytes    = numel*matvar->data_size;

            if ( numel < 1 )
                break;

            if ( NULL != matvar->internal->hdf5_name ) {
                ref_id = H5Dopen(fid,matvar->internal->hdf5_name,H5P_DEFAULT);
            } else {
                ref_id = matvar->internal->id;
                H5Iinc_ref(ref_id);
            }
            if ( 0 < matvar->internal->hdf5_ref ) {
                dset_id = H5Rdereference(ref_id,H5R_OBJECT,&matvar->internal->hdf5_ref);
            } else {
                dset_id = ref_id;
                H5Iinc_ref(dset_id);
            }

            if ( !matvar->isComplex ) {
                matvar->data     = malloc(matvar->nbytes);
                if ( NULL != matvar->data ) {
                    H5Dread(dset_id,Mat_class_type_to_hid_t(matvar->class_type),
                            H5S_ALL,H5S_ALL,H5P_DEFAULT,matvar->data);
                }
            } else {
                mat_complex_split_t *complex_data;
                hid_t h5_complex_base,h5_complex;

                complex_data     = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);

                h5_complex_base = Mat_class_type_to_hid_t(matvar->class_type);
                h5_complex      = H5Tcreate(H5T_COMPOUND,
                                            H5Tget_size(h5_complex_base));
                H5Tinsert(h5_complex,"real",0,h5_complex_base);
                H5Dread(dset_id,h5_complex,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                        complex_data->Re);
                H5Tclose(h5_complex);

                h5_complex      = H5Tcreate(H5T_COMPOUND,
                                            H5Tget_size(h5_complex_base));
                H5Tinsert(h5_complex,"imag",0,h5_complex_base);
                H5Dread(dset_id,h5_complex,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                        complex_data->Im);
                H5Tclose(h5_complex);
                matvar->data = complex_data;
            }
            H5Dclose(dset_id);
            H5Dclose(ref_id);
            break;
        case MAT_C_CHAR:
            numel = 1;
            for ( k = 0; k < matvar->rank; k++ )
                numel *= matvar->dims[k];
            matvar->data_type = MAT_T_UINT8;
            matvar->data_size = 1;
            matvar->nbytes    = numel*matvar->data_size;

            if ( NULL != matvar->internal->hdf5_name ) {
                dset_id = H5Dopen(fid,matvar->internal->hdf5_name,H5P_DEFAULT);
            } else {
                dset_id = matvar->internal->id;
                H5Iinc_ref(dset_id);
            }
            matvar->data = malloc(matvar->nbytes);
            if ( NULL != matvar->data ) {
                H5Dread(dset_id,Mat_data_type_to_hid_t(matvar->data_type),
                        H5S_ALL,H5S_ALL,H5P_DEFAULT,matvar->data);
            }
            break;
        case MAT_C_STRUCT:
        {
            matvar_t **fields;
            int i,nfields = 0;

            if ( !matvar->internal->num_fields || NULL == matvar->data )
                break;
            numel = 1;
            for ( k = 0; k < matvar->rank; k++ )
                numel *= matvar->dims[k];
            nfields = matvar->internal->num_fields;
            fields  = (matvar_t**)matvar->data;
            for ( i = 0; i < nfields*numel; i++ ) {
                if (  0 < fields[i]->internal->hdf5_ref &&
                     -1 < fields[i]->internal->id ) {
                    /* Dataset of references */
                    Mat_H5ReadNextReferenceData(fields[i]->internal->id,fields[i],mat);
                } else {
                    Mat_VarRead73(mat,fields[i]);
                }
            }
            break;
        }
        case MAT_C_CELL:
        {
            matvar_t **cells;
            int i,ncells = 0;

            if ( NULL != matvar->internal->hdf5_name ) {
                dset_id = H5Dopen(fid,matvar->internal->hdf5_name,H5P_DEFAULT);
            } else {
                dset_id = matvar->internal->id;
                H5Iinc_ref(dset_id);
            }

            ncells = matvar->nbytes / matvar->data_size;
            cells  = (matvar_t**)matvar->data;

            for ( i = 0; i < ncells; i++ )
                Mat_H5ReadNextReferenceData(cells[i]->internal->id,cells[i],mat);
            break;
        }
        case MAT_C_SPARSE:
        {
            hid_t sparse_dset_id, space_id;
            hsize_t dims[2] = {0,};
            mat_sparse_t *sparse_data = (mat_sparse_t *)calloc(1,
                sizeof(*sparse_data));

            if ( NULL != matvar->internal->hdf5_name ) {
                dset_id = H5Gopen(fid,matvar->internal->hdf5_name,H5P_DEFAULT);
            } else {
                dset_id = matvar->internal->id;
                H5Iinc_ref(dset_id);
            }

            if ( H5Lexists(dset_id,"ir",H5P_DEFAULT) ) {
                sparse_dset_id = H5Dopen(dset_id,"ir",H5P_DEFAULT);
                space_id = H5Dget_space(sparse_dset_id);
                H5Sget_simple_extent_dims(space_id,dims,NULL);
                sparse_data->nir = dims[0];
                sparse_data->ir = (int*)malloc(sparse_data->nir*
                                         sizeof(*sparse_data->ir));
                H5Dread(sparse_dset_id,H5T_NATIVE_INT,
                        H5S_ALL,H5S_ALL,H5P_DEFAULT,sparse_data->ir);
                H5Sclose(space_id);
                H5Dclose(sparse_dset_id);
            }

            if ( H5Lexists(dset_id,"jc",H5P_DEFAULT) ) {
                sparse_dset_id = H5Dopen(dset_id,"jc",H5P_DEFAULT);
                space_id = H5Dget_space(sparse_dset_id);
                H5Sget_simple_extent_dims(space_id,dims,NULL);
                sparse_data->njc = dims[0];
                sparse_data->jc = (int*)malloc(sparse_data->njc*
                                         sizeof(*sparse_data->jc));
                H5Dread(sparse_dset_id,H5T_NATIVE_INT,
                        H5S_ALL,H5S_ALL,H5P_DEFAULT,sparse_data->jc);
                H5Sclose(space_id);
                H5Dclose(sparse_dset_id);
            }

            if ( H5Lexists(dset_id,"data",H5P_DEFAULT) ) {
                size_t ndata_bytes;
                sparse_dset_id = H5Dopen(dset_id,"data",H5P_DEFAULT);
                space_id = H5Dget_space(sparse_dset_id);
                H5Sget_simple_extent_dims(space_id,dims,NULL);
                sparse_data->nzmax = dims[0];
                sparse_data->ndata = dims[0];
                matvar->data_size  = sizeof(mat_sparse_t);
                matvar->nbytes     = matvar->data_size;

                ndata_bytes = sparse_data->nzmax*Mat_SizeOf(matvar->data_type);
                if ( !matvar->isComplex ) {
                    sparse_data->data  = malloc(ndata_bytes);
                    if ( NULL != sparse_data->data ) {
                        H5Dread(sparse_dset_id,
                                Mat_data_type_to_hid_t(matvar->data_type),
                                H5S_ALL,H5S_ALL,H5P_DEFAULT,sparse_data->data);
                    }
                } else {
                    mat_complex_split_t *complex_data;
                    hid_t h5_complex_base,h5_complex;

                    complex_data     = (mat_complex_split_t*)malloc(sizeof(*complex_data));
                    complex_data->Re = malloc(ndata_bytes);
                    complex_data->Im = malloc(ndata_bytes);

                    h5_complex_base = Mat_data_type_to_hid_t(matvar->data_type);
                    h5_complex      = H5Tcreate(H5T_COMPOUND,
                                                H5Tget_size(h5_complex_base));
                    H5Tinsert(h5_complex,"real",0,h5_complex_base);
                    H5Dread(sparse_dset_id,h5_complex,H5S_ALL,H5S_ALL,
                            H5P_DEFAULT,complex_data->Re);
                    H5Tclose(h5_complex);

                    h5_complex      = H5Tcreate(H5T_COMPOUND,
                                                H5Tget_size(h5_complex_base));
                    H5Tinsert(h5_complex,"imag",0,h5_complex_base);
                    H5Dread(sparse_dset_id,h5_complex,H5S_ALL,H5S_ALL,
                            H5P_DEFAULT,complex_data->Im);
                    H5Tclose(h5_complex);
                    sparse_data->data = complex_data;
                }
                H5Sclose(space_id);
                H5Dclose(sparse_dset_id);
            }
            H5Gclose(dset_id);
            matvar->data = sparse_data;
            break;
        }
        case MAT_C_EMPTY:
        case MAT_C_FUNCTION:
        case MAT_C_OBJECT:
            break;
    }
}

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
int
Mat_VarReadData73(mat_t *mat,matvar_t *matvar,void *data,
          int *start,int *stride,int *edge)
{
    int err = -1;
    int k;
    hid_t fid,dset_id,ref_id,dset_space,mem_space;
    hsize_t dset_start[10],dset_stride[10],dset_edge[10];

    if ( NULL == mat || NULL == matvar || NULL == data || NULL == start ||
         NULL == stride || NULL == edge )
        return err;
    else if (NULL == matvar->internal->hdf5_name && 0 > matvar->internal->id)
        return err;

    fid = *(hid_t*)mat->fp;

    for ( k = 0; k < matvar->rank; k++ ) {
        dset_start[k]  = start[matvar->rank-k-1];
        dset_stride[k] = stride[matvar->rank-k-1];
        dset_edge[k]   = edge[matvar->rank-k-1];
    }
    mem_space = H5Screate_simple(matvar->rank, dset_edge, NULL);

    switch (matvar->class_type) {
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
                ref_id = H5Dopen(fid,matvar->internal->hdf5_name,H5P_DEFAULT);
            } else {
                ref_id = matvar->internal->id;
                H5Iinc_ref(ref_id);
            }
            if ( 0 < matvar->internal->hdf5_ref ) {
                dset_id = H5Rdereference(ref_id,H5R_OBJECT,&matvar->internal->hdf5_ref);
            } else {
                dset_id = ref_id;
                H5Iinc_ref(dset_id);
            }

            dset_space = H5Dget_space(dset_id);
            H5Sselect_hyperslab(dset_space, H5S_SELECT_SET, dset_start,
                                dset_stride, dset_edge, NULL);

            if ( !matvar->isComplex ) {
                H5Dread(dset_id,Mat_class_type_to_hid_t(matvar->class_type),
                        mem_space,dset_space,H5P_DEFAULT,data);
            } else {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)data;
                hid_t h5_complex_base,h5_complex;

                h5_complex_base = Mat_class_type_to_hid_t(matvar->class_type);
                h5_complex      = H5Tcreate(H5T_COMPOUND,
                                            H5Tget_size(h5_complex_base));
                H5Tinsert(h5_complex,"real",0,h5_complex_base);
                H5Dread(dset_id,h5_complex,mem_space,dset_space,H5P_DEFAULT,
                        complex_data->Re);
                H5Tclose(h5_complex);

                h5_complex      = H5Tcreate(H5T_COMPOUND,
                                            H5Tget_size(h5_complex_base));
                H5Tinsert(h5_complex,"imag",0,h5_complex_base);
                H5Dread(dset_id,h5_complex,mem_space,dset_space,H5P_DEFAULT,
                        complex_data->Im);
                H5Tclose(h5_complex);
            }
            H5Sclose(dset_space);
            H5Dclose(dset_id);
            H5Dclose(ref_id);
            err = 0;
            break;
        default:
            break;
    }
    H5Sclose(mem_space);

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
 *             edge*Mat_SizeOfClass(matvar->class_type))
 * @param start starting index
 * @param stride stride of data
 * @param edge number of elements to read
 * @retval 0 on success
 * @endif
 */
int
Mat_VarReadDataLinear73(mat_t *mat,matvar_t *matvar,void *data,
    int start,int stride,int edge)
{
    int err = -1;
    hid_t fid,dset_id,dset_space,mem_space;
    hsize_t dset_start,dset_stride,dset_edge;
    hsize_t *points, k, dimp[10];

    if ( NULL == mat || NULL == matvar || NULL == data )
        return err;
    else if (NULL == matvar->internal->hdf5_name && 0 > matvar->internal->id)
        return err;

    fid = *(hid_t*)mat->fp;

    dset_start  = start;
    dset_stride = stride;
    dset_edge   = edge;
    mem_space = H5Screate_simple(1, &dset_edge, NULL);

    switch (matvar->class_type) {
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
                dset_id = H5Dopen(fid,matvar->internal->hdf5_name,H5P_DEFAULT);
            } else {
                dset_id = matvar->internal->id;
                H5Iinc_ref(dset_id);
            }

            points = (hsize_t*)malloc(matvar->rank*dset_edge*sizeof(*points));
            if ( NULL == points ) {
                err = -2;
                break;
            }
            dimp[0] = 1;
            for ( k = 1; k < matvar->rank; k++ )
                dimp[k] = dimp[k-1]*matvar->dims[k-1];
            for ( k = 0; k < dset_edge; k++ ) {
                size_t l, coord, idx;
                coord = start + k*stride;
                for ( l = matvar->rank; l--; ) {
                    idx = coord / dimp[l];
                    points[matvar->rank*(k+1)-1-l] = idx;
                    coord -= idx*dimp[l];
                }
            }
            dset_space = H5Dget_space(dset_id);
            H5Sselect_elements(dset_space,H5S_SELECT_SET,dset_edge,points);

            if ( !matvar->isComplex ) {
                H5Dread(dset_id,Mat_class_type_to_hid_t(matvar->class_type),
                        mem_space,dset_space,H5P_DEFAULT,data);
            } else {
                mat_complex_split_t *complex_data = (mat_complex_split_t*)data;
                hid_t h5_complex_base,h5_complex;

                h5_complex_base = Mat_class_type_to_hid_t(matvar->class_type);
                h5_complex      = H5Tcreate(H5T_COMPOUND,
                                            H5Tget_size(h5_complex_base));
                H5Tinsert(h5_complex,"real",0,h5_complex_base);
                H5Dread(dset_id,h5_complex,mem_space,dset_space,H5P_DEFAULT,
                        complex_data->Re);
                H5Tclose(h5_complex);

                h5_complex      = H5Tcreate(H5T_COMPOUND,
                                            H5Tget_size(h5_complex_base));
                H5Tinsert(h5_complex,"imag",0,h5_complex_base);
                H5Dread(dset_id,h5_complex,mem_space,dset_space,H5P_DEFAULT,
                        complex_data->Im);
                H5Tclose(h5_complex);
            }
            H5Sclose(dset_space);
            H5Dclose(dset_id);
            free(points);
            err = 0;
            break;
        default:
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
matvar_t *
Mat_VarReadNextInfo73( mat_t *mat )
{
    hid_t   fid;
    hsize_t idx;
    herr_t  herr;
    struct mat_read_next_iter_data mat_data;

    if( mat == NULL )
        return NULL;

    if ( mat->next_index >= mat->num_datasets )
        return NULL;

    fid = *(hid_t*)mat->fp;
    idx = (hsize_t)mat->next_index;
    mat_data.mat = mat;
    mat_data.matvar = NULL;
    herr = H5Literate(fid, H5_INDEX_NAME, H5_ITER_NATIVE, &idx, Mat_VarReadNextInfoIterate, (void*)&mat_data);
    if ( herr > 0 )
        mat->next_index = (long)idx;
    return mat_data.matvar;
}

static herr_t
Mat_VarReadNextInfoIterate(hid_t fid, const char *name, const H5L_info_t *info, void *op_data)
{
    mat_t *mat;
    matvar_t *matvar;
    H5O_info_t object_info;
    struct mat_read_next_iter_data *mat_data;

    /* FIXME: follow symlinks, datatypes? */

    /* Check that this is not the /#refs# group */
    if ( 0 == strcmp(name, "#refs#") )
        return 0;

    H5Oget_info_by_name(fid, name, &object_info, H5P_DEFAULT);
    if ( H5O_TYPE_DATASET != object_info.type && H5O_TYPE_GROUP != object_info.type )
        return 0;

    mat_data = (struct mat_read_next_iter_data *)op_data;
    if (mat_data == NULL )
        return -1;
    mat = mat_data->mat;
    matvar = mat_data->matvar;

    if ( NULL == (matvar = Mat_VarCalloc()) )
        return -1;

    matvar->internal->fp = mat;
    matvar->name = (char*)malloc(1 + strlen(name));
    if ( matvar->name == NULL ) {
        Mat_VarFree(matvar);
        return -1;
    }
    strcpy(matvar->name, name);

    switch ( object_info.type ) {
        case H5O_TYPE_DATASET:
        {
            ssize_t     name_len;
            /* FIXME */
            hsize_t  dims[10];
            hid_t   attr_id,type_id,dset_id,space_id;

            dset_id = H5Dopen(fid,matvar->name,H5P_DEFAULT);

            /* Get the HDF5 name of the variable */
            name_len = H5Iget_name(dset_id,NULL,0);
            if ( name_len > 0 ) {
                matvar->internal->hdf5_name = (char*)malloc(name_len+1);
                (void)H5Iget_name(dset_id,matvar->internal->hdf5_name,
                                  name_len+1);
            } else {
                /* Can not get an internal name, so leave the identifier open */
                matvar->internal->id = dset_id;
            }

            space_id = H5Dget_space(dset_id);
            matvar->rank = H5Sget_simple_extent_ndims(space_id);
            matvar->dims = (size_t*)malloc(matvar->rank*sizeof(*matvar->dims));
            if ( NULL != matvar->dims ) {
                int k;
                H5Sget_simple_extent_dims(space_id,dims,NULL);
                for ( k = 0; k < matvar->rank; k++ )
                    matvar->dims[k] = dims[matvar->rank - k - 1];
            } else {
                H5Sclose(space_id);
                Mat_VarFree(matvar);
                Mat_Critical("Error allocating memory for matvar->dims");
                return -1;
            }
            H5Sclose(space_id);

            Mat_H5ReadClassType(matvar,dset_id);

            if ( H5Aexists_by_name(dset_id,".","MATLAB_global",H5P_DEFAULT) ) {
                attr_id = H5Aopen_by_name(dset_id,".","MATLAB_global",H5P_DEFAULT,H5P_DEFAULT);
                /* FIXME: Check that dataspace is scalar */
                H5Aread(attr_id,H5T_NATIVE_INT,&matvar->isGlobal);
                H5Aclose(attr_id);
            }

            /* Check for attribute that indicates an empty array */
            if ( H5Aexists_by_name(dset_id,".","MATLAB_empty",H5P_DEFAULT) ) {
                int empty = 0;
                attr_id = H5Aopen_by_name(dset_id,".","MATLAB_empty",H5P_DEFAULT,H5P_DEFAULT);
                /* FIXME: Check that dataspace is scalar */
                H5Aread(attr_id,H5T_NATIVE_INT,&empty);
                H5Aclose(attr_id);
                if ( empty ) {
                    matvar->rank = matvar->dims[0];
                    free(matvar->dims);
                    matvar->dims = (size_t*)calloc(matvar->rank,sizeof(*matvar->dims));
                    H5Dread(dset_id,Mat_dims_type_to_hid_t(),H5S_ALL,H5S_ALL,
                            H5P_DEFAULT,matvar->dims);
                }
            }

            /* Test if dataset type is compound and if so if it's complex */
            type_id = H5Dget_type(dset_id);
            if ( H5T_COMPOUND == H5Tget_class(type_id) ) {
                /* FIXME: Any more checks? */
                matvar->isComplex = MAT_F_COMPLEX;
            }
            H5Tclose(type_id);

            /* If the dataset is a cell array read the info of the cells */
            if ( MAT_C_CELL == matvar->class_type ) {
                matvar_t **cells;
                int i,ncells = 1;
                hobj_ref_t *ref_ids;

                for ( i = 0; i < matvar->rank; i++ )
                    ncells *= matvar->dims[i];
                matvar->data_size = sizeof(matvar_t**);
                matvar->nbytes    = ncells*matvar->data_size;
                matvar->data      = malloc(matvar->nbytes);
                cells = (matvar_t**)matvar->data;

                if ( ncells ) {
                    ref_ids = (hobj_ref_t*)malloc(ncells*sizeof(*ref_ids));
                    H5Dread(dset_id,H5T_STD_REF_OBJ,H5S_ALL,H5S_ALL,H5P_DEFAULT,
                            ref_ids);
                    for ( i = 0; i < ncells; i++ ) {
                        hid_t ref_id;
                        cells[i] = Mat_VarCalloc();
                        cells[i]->internal->hdf5_ref = ref_ids[i];
                        /* Closing of ref_id is done in
                         * Mat_H5ReadNextReferenceInfo
                         */
                        ref_id = H5Rdereference(dset_id,H5R_OBJECT,ref_ids+i);
                        cells[i]->internal->id=ref_id;
                        cells[i]->internal->fp=matvar->internal->fp;
                        Mat_H5ReadNextReferenceInfo(ref_id,cells[i],mat);
                    }
                    free(ref_ids);
                }
            } else if ( MAT_C_STRUCT == matvar->class_type ) {
                /* Empty structures can be a dataset */

                /* Check if the structure defines its fields in MATLAB_fields */
                if ( H5Aexists_by_name(dset_id,".","MATLAB_fields",H5P_DEFAULT) ) {
                    int      i;
                    hid_t    field_id;
                    hsize_t  nfields;
                    hvl_t   *fieldnames_vl;

                    attr_id = H5Aopen_by_name(dset_id,".","MATLAB_fields",H5P_DEFAULT,H5P_DEFAULT);
                    space_id = H5Aget_space(attr_id);
                    (void)H5Sget_simple_extent_dims(space_id,&nfields,NULL);
                    field_id = H5Aget_type(attr_id);
                    fieldnames_vl = (hvl_t*)malloc(nfields*sizeof(*fieldnames_vl));
                    H5Aread(attr_id,field_id,fieldnames_vl);

                    matvar->internal->num_fields = nfields;
                    matvar->internal->fieldnames =
                        (char**)calloc(nfields,sizeof(*matvar->internal->fieldnames));
                    for ( i = 0; i < nfields; i++ ) {
                        matvar->internal->fieldnames[i] =
                            (char*)calloc(fieldnames_vl[i].len+1,1);
                        memcpy(matvar->internal->fieldnames[i],fieldnames_vl[i].p,
                               fieldnames_vl[i].len);
                    }

                    H5Dvlen_reclaim(field_id,space_id,H5P_DEFAULT,fieldnames_vl);
                    H5Sclose(space_id);
                    H5Tclose(field_id);
                    H5Aclose(attr_id);
                    free(fieldnames_vl);
                }
            }

            if ( matvar->internal->id != dset_id ) {
                /* Close dataset and increment count */
                H5Dclose(dset_id);
            }
            mat_data->matvar = matvar;
            break;
        }
        case H5O_TYPE_GROUP:
        {
            hid_t dset_id;

            dset_id = H5Gopen(fid,matvar->name,H5P_DEFAULT);

            Mat_H5ReadGroupInfo(mat,matvar,dset_id);
            H5Gclose(dset_id);
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
 *                 (only works for numeric types)
 * @retval 0 on success
 * @endif
 */
int
Mat_VarWrite73(mat_t *mat,matvar_t *matvar,int compress)
{
    hid_t id;

    if ( NULL == mat || NULL == matvar )
        return -1;

    matvar->compression = (enum matio_compression)compress;

    id = *(hid_t*)mat->fp;
    return Mat_VarWriteNext73(id,matvar,matvar->name,&(mat->refs_id));
}

#endif

/* -------------------------------
 * ---------- matvar_cell.c
 * -------------------------------
 */

#include <stdlib.h>
#include <string.h>

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
Mat_VarGetCell(matvar_t *matvar,int index)
{
    int       nmemb = 1, i;
    matvar_t *cell = NULL;

    if ( matvar == NULL )
        return NULL;

    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];

    if ( index < nmemb )
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
Mat_VarGetCells(matvar_t *matvar,int *start,int *stride,int *edge)
{
    int i, j, N, I;
    size_t idx[10] = {0,}, cnt[10] = {0,}, dimp[10] = {0,};
    matvar_t **cells;

    if ( (matvar == NULL) || (start == NULL) || (stride == NULL) ||
        (edge == NULL) ) {
        return NULL;
    } else if ( matvar->rank > 9 ) {
        return NULL;
    }

    dimp[0] = matvar->dims[0];
    N = edge[0];
    I = start[0];
    idx[0] = start[0];
    for ( i = 1; i < matvar->rank; i++ ) {
        idx[i]  = start[i];
        dimp[i] = dimp[i-1]*matvar->dims[i];
        N *= edge[i];
        I += start[i]*dimp[i-1];
    }
    cells = (matvar_t**)malloc(N*sizeof(matvar_t *));
    for ( i = 0; i < N; i+=edge[0] ) {
        for ( j = 0; j < edge[0]; j++ ) {
            cells[i+j] = *((matvar_t **)matvar->data + I);
            I += stride[0];
        }
        idx[0] = start[0];
        I = idx[0];
        cnt[1]++;
        idx[1] += stride[1];
        for ( j = 1; j < matvar->rank; j++ ) {
            if ( cnt[j] == edge[j] ) {
                cnt[j] = 0;
                idx[j] = start[j];
                cnt[j+1]++;
                idx[j+1] += stride[j+1];
            }
            I += idx[j]*dimp[j-1];
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
Mat_VarGetCellsLinear(matvar_t *matvar,int start,int stride,int edge)
{
    int i, I;
    matvar_t **cells = NULL;

    if ( matvar != NULL ) {
        cells = (matvar_t**)malloc(edge*sizeof(matvar_t *));
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
Mat_VarSetCell(matvar_t *matvar,int index,matvar_t *cell)
{
    int nmemb = 1, i;
    matvar_t **cells, *old_cell = NULL;

    if ( matvar == NULL || matvar->rank < 1 )
        return NULL;

    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];

    cells = (matvar_t**)matvar->data;
    if ( index < nmemb ) {
        old_cell = cells[index];
        cells[index] = cell;
    }

    return old_cell;
}

/* -------------------------------
 * ---------- matvar_struct.c
 * -------------------------------
 */

#include <stdlib.h>
#include <string.h>

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
Mat_VarCreateStruct(const char *name,int rank,size_t *dims,const char **fields,
    unsigned nfields)
{
    int i, nmemb = 1;
    matvar_t *matvar;

    if ( NULL == dims )
        return NULL;

    matvar = Mat_VarCalloc();
    if ( NULL == matvar )
        return NULL;

    matvar->compression = MAT_COMPRESSION_NONE;
    if ( NULL != name )
        matvar->name = mat_strdup(name);
    matvar->rank = rank;
    matvar->dims = (size_t*)malloc(matvar->rank*sizeof(*matvar->dims));
    for ( i = 0; i < matvar->rank; i++ ) {
        matvar->dims[i] = dims[i];
        nmemb *= dims[i];
    }
    matvar->class_type = MAT_C_STRUCT;
    matvar->data_type  = MAT_T_STRUCT;

    matvar->data_size = sizeof(matvar_t *);

    if ( nfields ) {
        matvar->internal->num_fields = nfields;
        matvar->internal->fieldnames =
            (char**)malloc(nfields*sizeof(*matvar->internal->fieldnames));
        if ( NULL == matvar->internal->fieldnames ) {
            Mat_VarFree(matvar);
            matvar = NULL;
        } else {
            for ( i = 0; i < nfields; i++ ) {
                if ( NULL == fields[i] ) {
                    Mat_VarFree(matvar);
                    matvar = NULL;
                    break;
                } else {
                    matvar->internal->fieldnames[i] = mat_strdup(fields[i]);
                }
            }
        }
        if ( NULL != matvar && nmemb > 0 && nfields > 0 ) {
            matvar_t **field_vars;
            matvar->nbytes = nmemb*nfields*matvar->data_size;
            matvar->data = malloc(matvar->nbytes);
            field_vars = (matvar_t**)matvar->data;
            for ( i = 0; i < nfields*nmemb; i++ )
                field_vars[i] = NULL;
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
Mat_VarAddStructField(matvar_t *matvar,const char *fieldname)
{
    int       i, f, nfields, nmemb, cnt = 0;
    matvar_t **new_data, **old_data;

    if ( matvar == NULL || fieldname == NULL )
        return -1;
    nmemb = 1;
    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];

    nfields = matvar->internal->num_fields+1;
    matvar->internal->num_fields = nfields;
    matvar->internal->fieldnames =
    (char**)realloc(matvar->internal->fieldnames,
            nfields*sizeof(*matvar->internal->fieldnames));
    matvar->internal->fieldnames[nfields-1] = mat_strdup(fieldname);

    new_data = (matvar_t**)malloc(nfields*nmemb*sizeof(*new_data));
    if ( new_data == NULL )
        return -1;

    old_data = (matvar_t**)matvar->data;
    for ( i = 0; i < nmemb; i++ ) {
        for ( f = 0; f < nfields-1; f++ )
            new_data[cnt++] = old_data[i*(nfields-1)+f];
        new_data[cnt++] = NULL;
    }

    free(matvar->data);
    matvar->data = new_data;
    matvar->nbytes = nfields*nmemb*sizeof(*new_data);

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
    if ( matvar == NULL || matvar->class_type != MAT_C_STRUCT   ||
        NULL == matvar->internal ) {
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
char * const *
Mat_VarGetStructFieldnames(const matvar_t *matvar)
{
    if ( matvar == NULL || matvar->class_type != MAT_C_STRUCT   ||
        NULL == matvar->internal ) {
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
Mat_VarGetStructFieldByIndex(matvar_t *matvar,size_t field_index,size_t index)
{
    int       i, nfields;
    matvar_t *field = NULL;
    size_t nmemb;

    if ( matvar == NULL || matvar->class_type != MAT_C_STRUCT   ||
        matvar->data_size == 0 )
        return field;

    nmemb = 1;
    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];

    nfields = matvar->internal->num_fields;

    if ( nmemb > 0 && index >= nmemb ) {
        Mat_Critical("Mat_VarGetStructField: structure index out of bounds");
    } else if ( nfields > 0 ) {
        if ( field_index > nfields ) {
            Mat_Critical("Mat_VarGetStructField: field index out of bounds");
        } else {
            field = *((matvar_t **)matvar->data+index*nfields+field_index);
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
Mat_VarGetStructFieldByName(matvar_t *matvar,const char *field_name,
                            size_t index)
{
    int       i, nfields, field_index;
    matvar_t *field = NULL;
    size_t nmemb;

    if ( matvar == NULL || matvar->class_type != MAT_C_STRUCT   ||
        matvar->data_size == 0 )
        return field;

    nmemb = 1;
    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];

    nfields = matvar->internal->num_fields;
    field_index = -1;
    for ( i = 0; i < nfields; i++ ) {
        if ( !strcmp(matvar->internal->fieldnames[i],field_name) ) {
            field_index = i;
            break;
        }
    }

    if ( index >= nmemb ) {
        Mat_Critical("Mat_VarGetStructField: structure index out of bounds");
    } else if ( field_index >= 0 ) {
        field = *((matvar_t **)matvar->data+index*nfields+field_index);
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
Mat_VarGetStructField(matvar_t *matvar,void *name_or_index,int opt,int index)
{
    int       i, err = 0, nfields, nmemb;
    matvar_t *field = NULL;

    nmemb = 1;
    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];

    nfields = matvar->internal->num_fields;

    if ( index < 0 || (nmemb > 0 && index >= nmemb ))
        err = 1;
    else if ( nfields < 1 )
        err = 1;

    if ( !err && (opt == MAT_BY_INDEX) ) {
        size_t field_index = *(int *)name_or_index;
        if ( field_index > 0 )
            field = Mat_VarGetStructFieldByIndex(matvar,field_index-1,index);
    } else if ( !err && (opt == MAT_BY_NAME) ) {
        field = Mat_VarGetStructFieldByName(matvar,(const char*)name_or_index,index);
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
Mat_VarGetStructs(matvar_t *matvar,int *start,int *stride,int *edge,
    int copy_fields)
{
    size_t i,j,N,I,nfields,field,idx[10] = {0,},cnt[10] = {0,},dimp[10] = {0,};
    matvar_t **fields, *struct_slab;

    if ( (matvar == NULL) || (start == NULL) || (stride == NULL) ||
         (edge == NULL) ) {
        return NULL;
    } else if ( matvar->rank > 9 ) {
        return NULL;
    } else if ( matvar->class_type != MAT_C_STRUCT ) {
        return NULL;
    }

    struct_slab = Mat_VarDuplicate(matvar,0);
    if ( !copy_fields )
        struct_slab->mem_conserve = 1;

    nfields = matvar->internal->num_fields;

    dimp[0] = matvar->dims[0];
    N = edge[0];
    I = start[0];
    struct_slab->dims[0] = edge[0];
    idx[0] = start[0];
    for ( i = 1; i < matvar->rank; i++ ) {
        idx[i]  = start[i];
        dimp[i] = dimp[i-1]*matvar->dims[i];
        N *= edge[i];
        I += start[i]*dimp[i-1];
        struct_slab->dims[i] = edge[i];
    }
    I *= nfields;
    struct_slab->nbytes    = N*nfields*sizeof(matvar_t *);
    struct_slab->data = malloc(struct_slab->nbytes);
    if ( struct_slab->data == NULL ) {
        Mat_VarFree(struct_slab);
        return NULL;
    }
    fields = (matvar_t**)struct_slab->data;
    for ( i = 0; i < N; i+=edge[0] ) {
        for ( j = 0; j < edge[0]; j++ ) {
            for ( field = 0; field < nfields; field++ ) {
                if ( copy_fields )
                    fields[(i+j)*nfields+field] =
                         Mat_VarDuplicate(*((matvar_t **)matvar->data + I),1);
                else
                    fields[(i+j)*nfields+field] =
                        *((matvar_t **)matvar->data + I);
                I++;
            }
            if ( stride != 0 )
                I += (stride[0]-1)*nfields;
        }
        idx[0] = start[0];
        I = idx[0];
        cnt[1]++;
        idx[1] += stride[1];
        for ( j = 1; j < matvar->rank; j++ ) {
            if ( cnt[j] == edge[j] ) {
                cnt[j] = 0;
                idx[j] = start[j];
                cnt[j+1]++;
                idx[j+1] += stride[j+1];
            }
            I += idx[j]*dimp[j-1];
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
 * MAT File version must be 5.
 * @ingroup MAT
 * @param matvar Structure matlab variable
 * @param start starting index (0-relative)
 * @param stride stride (1 reads consecutive elements)
 * @param edge Number of elements to read
 * @param copy_fields 1 to copy the fields, 0 to just set pointers to them.
 * @returns A new structure with fields indexed from matvar
 */
matvar_t *
Mat_VarGetStructsLinear(matvar_t *matvar,int start,int stride,int edge,
    int copy_fields)
{
    int i, I, field, nfields;
    matvar_t *struct_slab, **fields;

    /* FIXME: Check allocations */
    if ( matvar == NULL || matvar->rank > 10 ) {
       struct_slab = NULL;
    } else {

        struct_slab = Mat_VarDuplicate(matvar,0);
        if ( !copy_fields )
            struct_slab->mem_conserve = 1;

        nfields = matvar->internal->num_fields;

        struct_slab->nbytes = edge*nfields*sizeof(matvar_t *);
        struct_slab->data = malloc(struct_slab->nbytes);
        struct_slab->dims[0] = edge;
        struct_slab->dims[1] = 1;
        fields = (matvar_t**)struct_slab->data;
        I = start*nfields;
        for ( i = 0; i < edge; i++ ) {
            if ( copy_fields ) {
                for ( field = 0; field < nfields; field++ ) {
                    fields[i*nfields+field] =
                        Mat_VarDuplicate(*((matvar_t **)matvar->data+I),1);
                    I++;
                }
            } else {
                for ( field = 0; field < nfields; field++ ) {
                    fields[i*nfields+field] = *((matvar_t **)matvar->data + I);
                    I++;
                }
            }
            I += (stride-1)*nfields;
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
Mat_VarSetStructFieldByIndex(matvar_t *matvar,size_t field_index,size_t index,
    matvar_t *field)
{
    int       i, nfields;
    matvar_t *old_field = NULL;
    size_t nmemb;

    if ( matvar == NULL || matvar->class_type != MAT_C_STRUCT ||
        matvar->data == NULL )
        return old_field;

    nmemb = 1;
    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];

    nfields = matvar->internal->num_fields;

    if ( index < nmemb && field_index < nfields ) {
        matvar_t **fields = (matvar_t**)matvar->data;
        old_field = fields[index*nfields+field_index];
        fields[index*nfields+field_index] = field;
        if ( NULL != field->name ) {
            free(field->name);
        }
        field->name = mat_strdup(matvar->internal->fieldnames[field_index]);
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
Mat_VarSetStructFieldByName(matvar_t *matvar,const char *field_name,
    size_t index,matvar_t *field)
{
    int       i, nfields, field_index;
    matvar_t *old_field = NULL;
    size_t nmemb;

    if ( matvar == NULL || matvar->class_type != MAT_C_STRUCT ||
         matvar->data == NULL )
        return old_field;

    nmemb = 1;
    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];

    nfields = matvar->internal->num_fields;
    field_index = -1;
    for ( i = 0; i < nfields; i++ ) {
        if ( !strcmp(matvar->internal->fieldnames[i],field_name) ) {
            field_index = i;
            break;
        }
    }

    if ( index < nmemb && field_index >= 0 ) {
        matvar_t **fields = (matvar_t**)matvar->data;
        old_field = fields[index*nfields+field_index];
        fields[index*nfields+field_index] = field;
        if ( NULL != field->name ) {
            free(field->name);
        }
        field->name = mat_strdup(matvar->internal->fieldnames[field_index]);
    }

    return old_field;
}

#endif /* NO_FILE_SYSTEM */
