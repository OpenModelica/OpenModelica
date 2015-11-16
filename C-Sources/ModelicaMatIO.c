/*
 * Copyright (C) 2005-2013 Christopher C. Hulbert
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY CHRISTOPHER C. HULBERT ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL CHRISTOPHER C. HULBERT OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
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

/* Have asprintf */
#if defined(__CYGWIN__)
#define HAVE_ASPRINTF 1
#else
#undef HAVE_ASPRINTF
#endif

/* Have long long / long double */
#if defined (_WIN32)
#if defined(__WATCOMC__) || (defined(_MSC_VER) && _MSC_VER >= 1300)
#define HAVE_LONG_LONG 1
#define HAVE_LONG_DOUBLE 1
#endif
#endif
#if defined(__GNUC__)
#if !defined(HAVE_LONG_LONG)
#define HAVE_LONG_LONG 1
#endif
#if !defined(HAVE_LONG_DOUBLE)
#define HAVE_LONG_DOUBLE 1
#endif
#endif

/* Have snprintf */
#if defined(__LCC__) || (defined(_MSC_VER) && _MSC_VER < 1400)
#undef HAVE_SNPRINTF
#else
#define HAVE_SNPRINTF 1
#endif

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#undef HAVE_STRINGS_H

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Have vasprintf */
#if defined(__CYGWIN__)
#define HAVE_VASPRINTF 1
#else
#undef HAVE_VASPRINTF
#endif

/* Have va_copy */
#if defined(__GNUC__) && __STDC_VERSION__ >= 199901L
#define HAVE_VA_COPY 1
#elif defined(_MSC_VER) && _MSC_VER >= 1800
#define HAVE_VA_COPY 1
#elif defined(__WATCOMC__)
#define HAVE_VA_COPY 1
#else
#undef HAVE_VA_COPY
#endif

/* Have vsnprintf */
#if defined(STDC99)
#define HAVE_VSNPRINTF 1
#if !defined(HAVE_C99_VSNPRINTF)
#define HAVE_C99_VSNPRINTF 1
#endif
#elif defined(__MINGW32__) || defined(__CYGWIN__)
#define HAVE_VSNPRINTF 1
#if !defined(HAVE_C99_VSNPRINTF) && __STDC_VERSION__ >= 199901L
#define HAVE_C99_VSNPRINTF 1
#endif
#elif defined(__WATCOMC__)
#define HAVE_VSNPRINTF 1
#if !defined(HAVE_C99_VSNPRINTF)
#define HAVE_C99_VSNPRINTF 1
#endif
#elif defined(__TURBOC__) && __TURBOC__ >= 0x550
#define HAVE_VSNPRINTF 1
#if !defined(HAVE_C99_VSNPRINTF)
#define HAVE_C99_VSNPRINTF 1
#endif
#elif defined(MSDOS) && defined(__BORLANDC__) && (BORLANDC > 0x410)
#define HAVE_VSNPRINTF 1
#if !defined(HAVE_C99_VSNPRINTF)
#define HAVE_C99_VSNPRINTF 1
#endif
#elif defined(_MSC_VER) && _MSC_VER >= 1400
#define HAVE_VSNPRINTF 1
#if !defined(HAVE_C99_VSNPRINTF)
#define HAVE_C99_VSNPRINTF 1
#endif
#else
#undef HAVE_VSNPRINTF
#endif

/* Have __va_copy */
#if defined(__GNUC__)
#define HAVE___VA_COPY 1
#elif defined(__WATCOMC__)
#define HAVE___VA_COPY 1
#else
#undef HAVE___VA_COPY
#endif

/* Platform */
#define MATIO_PLATFORM "UNKNOWN"

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Define to 1 if you have the ctype.h header file. */
#define HAVE_CTYPE_H 1

/* Z prefix */
#undef Z_PREFIX
#include "ModelicaMatIO.h"
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
    char *subsys_offset;    /**< offset */
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
    char *hdf5_name;
    hobj_ref_t hdf5_ref;
    hid_t      id;
    long  fpos;         /**< Offset from the beginning of the MAT file to the variable */
    long  datapos;      /**< Offset from the beginning of the MAT file to the data */
     mat_t    *fp;      /**< Pointer to the MAT file structure (mat_t) */
    unsigned num_fields;
    char **fieldnames;
#if defined(HAVE_ZLIB)
    z_stream *z;        /**< zlib compression state */
#endif
};

/*    snprintf.c    */
EXTERN int mat_snprintf(char *str,size_t count,const char *fmt,...);
EXTERN int mat_asprintf(char **ptr,const char *format, ...);
EXTERN int mat_vsnprintf(char *str,size_t count,const char *fmt,va_list args);
EXTERN int mat_vasprintf(char **ptr,const char *format,va_list ap);

/*   endian.c     */
EXTERN double        Mat_doubleSwap(double  *a);
EXTERN float         Mat_floatSwap(float   *a);
#ifdef HAVE_MATIO_INT64_T
EXTERN mat_int64_t   Mat_int64Swap(mat_int64_t  *a);
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
EXTERN mat_uint64_t  Mat_uint64Swap(mat_uint64_t *a);
#endif /* HAVE_MATIO_UINT64_T */
EXTERN mat_int32_t   Mat_int32Swap(mat_int32_t  *a);
EXTERN mat_uint32_t  Mat_uint32Swap(mat_uint32_t *a);
EXTERN mat_int16_t   Mat_int16Swap(mat_int16_t  *a);
EXTERN mat_uint16_t  Mat_uint16Swap(mat_uint16_t *a);

/* read_data.c */
EXTERN int ReadDoubleData(mat_t *mat,double  *data,enum matio_types data_type,
               int len);
EXTERN int ReadSingleData(mat_t *mat,float   *data,enum matio_types data_type,
               int len);
#ifdef HAVE_MATIO_INT64_T
EXTERN int ReadInt64Data (mat_t *mat,mat_int64_t *data,
               enum matio_types data_type,int len);
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
EXTERN int ReadUInt64Data(mat_t *mat,mat_uint64_t *data,
               enum matio_types data_type,int len);
#endif /* HAVE_MATIO_UINT64_T */
EXTERN int ReadInt32Data (mat_t *mat,mat_int32_t *data,
               enum matio_types data_type,int len);
EXTERN int ReadUInt32Data(mat_t *mat,mat_uint32_t *data,
               enum matio_types data_type,int len);
EXTERN int ReadInt16Data (mat_t *mat,mat_int16_t *data,
               enum matio_types data_type,int len);
EXTERN int ReadUInt16Data(mat_t *mat,mat_uint16_t *data,
               enum matio_types data_type,int len);
EXTERN int ReadInt8Data  (mat_t *mat,mat_int8_t  *data,
               enum matio_types data_type,int len);
EXTERN int ReadUInt8Data (mat_t *mat,mat_uint8_t  *data,
               enum matio_types data_type,int len);
EXTERN int ReadCharData  (mat_t *mat,char  *data,enum matio_types data_type,
               int len);
EXTERN int ReadDataSlab1(mat_t *mat,void *data,enum matio_classes class_type,
               enum matio_types data_type,int start,int stride,int edge);
EXTERN int ReadDataSlab2(mat_t *mat,void *data,enum matio_classes class_type,
               enum matio_types data_type,size_t *dims,int *start,int *stride,
               int *edge);
EXTERN int ReadDataSlabN(mat_t *mat,void *data,enum matio_classes class_type,
               enum matio_types data_type,int rank,size_t *dims,int *start,
               int *stride,int *edge);
#if defined(HAVE_ZLIB)
EXTERN int ReadCompressedDoubleData(mat_t *mat,z_stream *z,double  *data,
               enum matio_types data_type,int len);
EXTERN int ReadCompressedSingleData(mat_t *mat,z_stream *z,float   *data,
               enum matio_types data_type,int len);
#ifdef HAVE_MATIO_INT64_T
EXTERN int ReadCompressedInt64Data(mat_t *mat,z_stream *z,mat_int64_t *data,
               enum matio_types data_type,int len);
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
EXTERN int ReadCompressedUInt64Data(mat_t *mat,z_stream *z,mat_uint64_t *data,
               enum matio_types data_type,int len);
#endif /* HAVE_MATIO_UINT64_T */
EXTERN int ReadCompressedInt32Data(mat_t *mat,z_stream *z,mat_int32_t *data,
               enum matio_types data_type,int len);
EXTERN int ReadCompressedUInt32Data(mat_t *mat,z_stream *z,mat_uint32_t *data,
               enum matio_types data_type,int len);
EXTERN int ReadCompressedInt16Data(mat_t *mat,z_stream *z,mat_int16_t *data,
               enum matio_types data_type,int len);
EXTERN int ReadCompressedUInt16Data(mat_t *mat,z_stream *z,mat_uint16_t *data,
               enum matio_types data_type,int len);
EXTERN int ReadCompressedInt8Data(mat_t *mat,z_stream *z,mat_int8_t  *data,
               enum matio_types data_type,int len);
EXTERN int ReadCompressedUInt8Data(mat_t *mat,z_stream *z,mat_uint8_t  *data,
               enum matio_types data_type,int len);
EXTERN int ReadCompressedCharData(mat_t *mat,z_stream *z,char *data,
               enum matio_types data_type,int len);
EXTERN int ReadCompressedDataSlab1(mat_t *mat,z_stream *z,void *data,
               enum matio_classes class_type,enum matio_types data_type,
               int start,int stride,int edge);
EXTERN int ReadCompressedDataSlab2(mat_t *mat,z_stream *z,void *data,
               enum matio_classes class_type,enum matio_types data_type,
               size_t *dims,int *start,int *stride,int *edge);
EXTERN int ReadCompressedDataSlabN(mat_t *mat,z_stream *z,void *data,
               enum matio_classes class_type,enum matio_types data_type,
               int rank,size_t *dims,int *start,int *stride,int *edge);

/*   inflate.c    */
EXTERN int InflateSkip(mat_t *mat, z_stream *z, int nbytes);
EXTERN int InflateSkip2(mat_t *mat, matvar_t *matvar, int nbytes);
EXTERN int InflateSkipData(mat_t *mat,z_stream *z,enum matio_types data_type,int len);
EXTERN int InflateVarTag(mat_t *mat, matvar_t *matvar, void *buf);
EXTERN int InflateArrayFlags(mat_t *mat, matvar_t *matvar, void *buf);
EXTERN int InflateDimensions(mat_t *mat, matvar_t *matvar, void *buf);
EXTERN int InflateVarNameTag(mat_t *mat, matvar_t *matvar, void *buf);
EXTERN int InflateVarName(mat_t *mat,matvar_t *matvar,void *buf,int N);
EXTERN int InflateDataTag(mat_t *mat, matvar_t *matvar, void *buf);
EXTERN int InflateDataType(mat_t *mat, z_stream *matvar, void *buf);
EXTERN int InflateData(mat_t *mat, z_stream *z, void *buf, int nBytes);
EXTERN int InflateFieldNameLength(mat_t *mat,matvar_t *matvar,void *buf);
EXTERN int InflateFieldNamesTag(mat_t *mat,matvar_t *matvar,void *buf);
EXTERN int InflateFieldNames(mat_t *mat,matvar_t *matvar,void *buf,int nfields,
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
mat_int64_t
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
mat_uint64_t
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
mat_int32_t
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
mat_uint32_t
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
mat_int16_t
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
mat_uint16_t
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
float
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
double
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
int
InflateSkip(mat_t *mat, z_stream *z, int nbytes)
{
    mat_uint8_t comp_buf[512],uncomp_buf[512];
    int     bytesread = 0, n,err, cnt = 0;

    if ( nbytes < 1 )
        return 0;

    n = (nbytes<512) ? nbytes : 512;
    if ( !z->avail_in ) {
        z->next_in = comp_buf;
        z->avail_in += fread(comp_buf,1,n,mat->fp);
        bytesread   += z->avail_in;
    }
    z->avail_out = n;
    z->next_out  = uncomp_buf;
    err = inflate(z,Z_FULL_FLUSH);
    if ( err == Z_STREAM_END ) {
        return bytesread;
    } else if ( err != Z_OK ) {
        Mat_Critical("InflateSkip: inflate returned %d",err);
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
            z->avail_in += fread(comp_buf,1,n,mat->fp);
            bytesread   += z->avail_in;
        }
        err = inflate(z,Z_FULL_FLUSH);
        if ( err == Z_STREAM_END ) {
            break;
        } else if ( err != Z_OK ) {
            Mat_Critical("InflateSkip: inflate returned %d",err);
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
        fseek(mat->fp,offset,SEEK_CUR);
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
int
InflateSkip2(mat_t *mat, matvar_t *matvar, int nbytes)
{
    mat_uint8_t comp_buf[32],uncomp_buf[32];
    int     bytesread = 0, err, cnt = 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
    }
    matvar->internal->z->avail_out = 1;
    matvar->internal->z->next_out = uncomp_buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateSkip2: %s - inflate returned %d",matvar->name,err);
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
            bytesread += fread(comp_buf,1,1,mat->fp);
            cnt++;
        }
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateSkip2: %s - inflate returned %d",matvar->name,err);
            return bytesread;
        }
        if ( !matvar->internal->z->avail_out ) {
            matvar->internal->z->avail_out = 1;
            matvar->internal->z->next_out = uncomp_buf;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        fseek(mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
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
int
InflateSkipData(mat_t *mat,z_stream *z,enum matio_types data_type,int len)
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
int
InflateVarTag(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    int     bytesread = 0, err;

    if (buf == NULL)
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
    }
    matvar->internal->z->avail_out = 8;
    matvar->internal->z->next_out = buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateVarTag: inflate returned %d",err);
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateVarTag: inflate returned %d",err);
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        fseek(mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
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
int
InflateArrayFlags(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    int     bytesread = 0, err;

    if (buf == NULL) return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
    }
    matvar->internal->z->avail_out = 16;
    matvar->internal->z->next_out = buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateArrayFlags: inflate returned %d",err);
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateArrayFlags: inflate returned %d",err);
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        fseek(mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
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
int
InflateDimensions(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    mat_int32_t tag[2];
    int     bytesread = 0, err, rank, i;

    if ( buf == NULL )
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
    }
    matvar->internal->z->avail_out = 8;
    matvar->internal->z->next_out = buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateDimensions: inflate returned %d",err);
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateDimensions: inflate returned %d",err);
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
        bytesread += fread(comp_buf,1,1,mat->fp);
    }
    matvar->internal->z->avail_out = rank;
    matvar->internal->z->next_out = (void *)((mat_int32_t *)buf+2);
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateDimensions: inflate returned %d",err);
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateDimensions: inflate returned %d",err);
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        fseek(mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
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
int
InflateVarNameTag(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    int     bytesread = 0, err;

    if ( buf == NULL )
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
    }
    matvar->internal->z->avail_out = 8;
    matvar->internal->z->next_out = buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateVarNameTag: inflate returned %d",err);
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateVarNameTag: inflate returned %d",err);
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        fseek(mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
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
int
InflateVarName(mat_t *mat, matvar_t *matvar, void *buf, int N)
{
    mat_uint8_t comp_buf[32];
    int     bytesread = 0, err;

    if ( buf == NULL )
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
    }
    matvar->internal->z->avail_out = N;
    matvar->internal->z->next_out = buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateVarName: inflate returned %d",err);
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateVarName: inflate returned %d",err);
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        fseek(mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
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
int
InflateDataTag(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    int     bytesread = 0, err;

    if ( buf == NULL )
        return 0;

   if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
    }
    matvar->internal->z->avail_out = 8;
    matvar->internal->z->next_out = buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err == Z_STREAM_END ) {
        return bytesread;
    } else if ( err != Z_OK ) {
        Mat_Critical("InflateDataTag: %s - inflate returned %d",matvar->name,err);
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err == Z_STREAM_END ) {
            break;
        } else if ( err != Z_OK ) {
            Mat_Critical("InflateDataTag: %s - inflate returned %d",matvar->name,err);
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        fseek(mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
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
int
InflateDataType(mat_t *mat, z_stream *z, void *buf)
{
    mat_uint8_t comp_buf[32];
    int     bytesread = 0, err;

    if ( buf == NULL )
        return 0;

    if ( !z->avail_in ) {
        z->avail_in = 1;
        z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
    }
    z->avail_out = 4;
    z->next_out = buf;
    err = inflate(z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateDataType: inflate returned %d",err);
        return bytesread;
    }
    while ( z->avail_out && !z->avail_in ) {
        z->avail_in = 1;
        z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
        err = inflate(z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateDataType: inflate returned %d",err);
            return bytesread;
        }
    }

    if ( z->avail_in ) {
        fseek(mat->fp,-(int)z->avail_in,SEEK_CUR);
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
int
InflateData(mat_t *mat, z_stream *z, void *buf, int nBytes)
{
    mat_uint8_t comp_buf[1024];
    int     bytesread = 0, err;

    if ( buf == NULL )
        return 0;
    if ( nBytes < 1 ) {
        Mat_Critical("InflateData: nBytes must be > 0");
        return bytesread;
    }

    if ( !z->avail_in ) {
        if ( nBytes > 1024 ) {
            z->avail_in = fread(comp_buf,1,1024,mat->fp);
            bytesread += z->avail_in;
            z->next_in = comp_buf;
        } else {
            z->avail_in = fread(comp_buf,1,nBytes,mat->fp);
            bytesread  += z->avail_in;
            z->next_in  = comp_buf;
        }
    }
    z->avail_out = nBytes;
    z->next_out = buf;
    err = inflate(z,Z_FULL_FLUSH);
    if ( err == Z_STREAM_END ) {
        return bytesread;
    } else if ( err != Z_OK ) {
        Mat_Critical("InflateData: inflate returned %d",err);
        return bytesread;
    }
    while ( z->avail_out && !z->avail_in ) {
        if ( (nBytes-bytesread) > 1024 ) {
            z->avail_in = fread(comp_buf,1,1024,mat->fp);
            bytesread += z->avail_in;
            z->next_in = comp_buf;
        } else if ( (nBytes-bytesread) < 1 ) { /* Read a byte at a time */
            z->avail_in = fread(comp_buf,1,1,mat->fp);
            bytesread  += z->avail_in;
            z->next_in  = comp_buf;
        } else {
            z->avail_in = fread(comp_buf,1,nBytes-bytesread,mat->fp);
            bytesread  += z->avail_in;
            z->next_in  = comp_buf;
        }
        err = inflate(z,Z_FULL_FLUSH);
        if ( err == Z_STREAM_END ) {
            break;
        } else if ( err != Z_OK && err != Z_BUF_ERROR ) {
            Mat_Critical("InflateData: inflate returned %d",err);
            break;
        }
    }

    if ( z->avail_in ) {
        long offset = -(long)z->avail_in;
        fseek(mat->fp,offset,SEEK_CUR);
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
int
InflateFieldNameLength(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    int     bytesread = 0, err;

    if ( buf == NULL )
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
    }
    matvar->internal->z->avail_out = 8;
    matvar->internal->z->next_out = buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateFieldNameLength: inflate returned %d",err);
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateFieldNameLength: inflate returned %d",err);
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        fseek(mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
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
int
InflateFieldNamesTag(mat_t *mat, matvar_t *matvar, void *buf)
{
    mat_uint8_t comp_buf[32];
    int     bytesread = 0, err;

    if ( buf == NULL )
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
    }
    matvar->internal->z->avail_out = 8;
    matvar->internal->z->next_out = buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateFieldNamesTag: inflate returned %d",err);
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateFieldNamesTag: inflate returned %d",err);
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        fseek(mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
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
int
InflateFieldNames(mat_t *mat,matvar_t *matvar,void *buf,int nfields,
                  int fieldname_length,int padding)
{
    mat_uint8_t comp_buf[32];
    int     bytesread = 0, err;

    if ( buf == NULL )
        return 0;

    if ( !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
    }
    matvar->internal->z->avail_out = nfields*fieldname_length+padding;
    matvar->internal->z->next_out = buf;
    err = inflate(matvar->internal->z,Z_NO_FLUSH);
    if ( err != Z_OK ) {
        Mat_Critical("InflateFieldNames: inflate returned %d",err);
        return bytesread;
    }
    while ( matvar->internal->z->avail_out && !matvar->internal->z->avail_in ) {
        matvar->internal->z->avail_in = 1;
        matvar->internal->z->next_in = comp_buf;
        bytesread += fread(comp_buf,1,1,mat->fp);
        err = inflate(matvar->internal->z,Z_NO_FLUSH);
        if ( err != Z_OK ) {
            Mat_Critical("InflateFieldNames: inflate returned %d",err);
            return bytesread;
        }
    }

    if ( matvar->internal->z->avail_in ) {
        fseek(mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
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
#if !defined(HAVE_VSNPRINTF) && !defined(vsnprintf)
#    define vsnprintf mat_vsnprintf
     EXTERN int vsnprintf(char *,size_t,const char *,va_list);
#endif
#if !defined(HAVE_SNPRINTF) && !defined(snprintf)
#    define snprintf mat_snprintf
     EXTERN int snprintf(char *str,size_t size,const char *format,...);
#endif
#if !defined(HAVE_VASPRINTF) && !defined(vasprintf)
#    define vasprintf mat_vasprintf
#endif
#if !defined(HAVE_ASPRINTF) && !defined(asprintf)
#    define asprintf mat_asprintf
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
  size = vsnprintf(NULL, 0, format, ap2)+1;
  va_end(ap2);

  buffer = malloc(size+1);
  if ( !buffer )
      return NULL;

  vsnprintf(buffer, size, format, ap);
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
#if defined(HAVE_ZLIB)
#   include <zlib.h>
#endif

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
int
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
                bytesread += fread(data,data_size,len,mat->fp);
                for ( i = 0; i < len; i++ ) {
                    (void)Mat_doubleSwap(data+i);
                }
            } else {
                bytesread += fread(data,data_size,len,mat->fp);
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f;

            data_size = sizeof(float);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,mat->fp);
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
                    bytesread += fread(&i32,data_size,1,mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,mat->fp);
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
                    bytesread += fread(&ui32,data_size,1,mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,mat->fp);
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
                    bytesread += fread(&i16,data_size,1,mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,mat->fp);
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
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
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
int
ReadCompressedDoubleData(mat_t *mat,z_stream *z,double *data,
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
int
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
                    bytesread += fread(&d,data_size,1,mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,mat->fp);
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
                    bytesread += fread(&f,data_size,1,mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,mat->fp);
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
                    bytesread += fread(&i32,data_size,1,mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,mat->fp);
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
                    bytesread += fread(&ui32,data_size,1,mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,mat->fp);
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
                    bytesread += fread(&i16,data_size,1,mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,mat->fp);
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
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
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
int
ReadCompressedSingleData(mat_t *mat,z_stream *z,float *data,
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
int
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
                    bytesread += fread(&d,data_size,1,mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,mat->fp);
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
                    bytesread += fread(&f,data_size,1,mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,mat->fp);
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
                    bytesread += fread(&i64,data_size,1,mat->fp);
                    data[i] = Mat_int64Swap(&i64);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i64,data_size,1,mat->fp);
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
                    bytesread += fread(&ui64,data_size,1,mat->fp);
                    data[i] = Mat_uint64Swap(&ui64);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui64,data_size,1,mat->fp);
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
                    bytesread += fread(&i32,data_size,1,mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,mat->fp);
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
                    bytesread += fread(&ui32,data_size,1,mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,mat->fp);
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
                    bytesread += fread(&i16,data_size,1,mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,mat->fp);
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
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
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
int
ReadCompressedInt64Data(mat_t *mat,z_stream *z,mat_int64_t *data,
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
int
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
                    bytesread += fread(&d,data_size,1,mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,mat->fp);
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
                    bytesread += fread(&f,data_size,1,mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,mat->fp);
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
                    bytesread += fread(&i64,data_size,1,mat->fp);
                    data[i] = Mat_int64Swap(&i64);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i64,data_size,1,mat->fp);
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
                    bytesread += fread(&ui64,data_size,1,mat->fp);
                    data[i] = Mat_uint64Swap(&ui64);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui64,data_size,1,mat->fp);
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
                    bytesread += fread(&i32,data_size,1,mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,mat->fp);
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
                    bytesread += fread(&ui32,data_size,1,mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,mat->fp);
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
                    bytesread += fread(&i16,data_size,1,mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,mat->fp);
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
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
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
int
ReadCompressedUInt64Data(mat_t *mat,z_stream *z,mat_uint64_t *data,
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
int
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
                    bytesread += fread(&d,data_size,1,mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,mat->fp);
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
                    bytesread += fread(&f,data_size,1,mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,mat->fp);
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
                    bytesread += fread(&i32,data_size,1,mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,mat->fp);
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
                    bytesread += fread(&ui32,data_size,1,mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,mat->fp);
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
                    bytesread += fread(&i16,data_size,1,mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,mat->fp);
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
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
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
int
ReadCompressedInt32Data(mat_t *mat,z_stream *z,mat_int32_t *data,
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
int
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
                    bytesread += fread(&d,data_size,1,mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,mat->fp);
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
                    bytesread += fread(&f,data_size,1,mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,mat->fp);
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
                    bytesread += fread(&i32,data_size,1,mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,mat->fp);
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
                    bytesread += fread(&ui32,data_size,1,mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,mat->fp);
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
                    bytesread += fread(&i16,data_size,1,mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,mat->fp);
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
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
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
int
ReadCompressedUInt32Data(mat_t *mat,z_stream *z,mat_uint32_t *data,
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
int
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
                    bytesread += fread(&d,data_size,1,mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,mat->fp);
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
                    bytesread += fread(&f,data_size,1,mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,mat->fp);
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
                    bytesread += fread(&i32,data_size,1,mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,mat->fp);
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
                    bytesread += fread(&ui32,data_size,1,mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,mat->fp);
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
                    bytesread += fread(&i16,data_size,1,mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,mat->fp);
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
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
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
int
ReadCompressedInt16Data(mat_t *mat,z_stream *z,mat_int16_t *data,
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
int
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
                    bytesread += fread(&d,data_size,1,mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,mat->fp);
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
                    bytesread += fread(&f,data_size,1,mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,mat->fp);
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
                    bytesread += fread(&i32,data_size,1,mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,mat->fp);
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
                    bytesread += fread(&ui32,data_size,1,mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,mat->fp);
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
                    bytesread += fread(&i16,data_size,1,mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,mat->fp);
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
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
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
int
ReadCompressedUInt16Data(mat_t *mat,z_stream *z,mat_uint16_t *data,
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
int
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
                    bytesread += fread(&d,data_size,1,mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,mat->fp);
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
                    bytesread += fread(&f,data_size,1,mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,mat->fp);
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
                    bytesread += fread(&i32,data_size,1,mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,mat->fp);
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
                    bytesread += fread(&ui32,data_size,1,mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,mat->fp);
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
                    bytesread += fread(&i16,data_size,1,mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,mat->fp);
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
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
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
int
ReadCompressedInt8Data(mat_t *mat,z_stream *z,mat_int8_t *data,
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
int
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
                    bytesread += fread(&d,data_size,1,mat->fp);
                    data[i] = Mat_doubleSwap(&d);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&d,data_size,1,mat->fp);
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
                    bytesread += fread(&f,data_size,1,mat->fp);
                    data[i] = Mat_floatSwap(&f);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&f,data_size,1,mat->fp);
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
                    bytesread += fread(&i32,data_size,1,mat->fp);
                    data[i] = Mat_int32Swap(&i32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i32,data_size,1,mat->fp);
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
                    bytesread += fread(&ui32,data_size,1,mat->fp);
                    data[i] = Mat_uint32Swap(&ui32);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui32,data_size,1,mat->fp);
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
                    bytesread += fread(&i16,data_size,1,mat->fp);
                    data[i] = Mat_int16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,data_size,1,mat->fp);
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
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = Mat_uint16Swap(&ui16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui16,data_size,1,mat->fp);
                    data[i] = ui16;
                }
            }
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8;

            data_size = sizeof(mat_int8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i8,data_size,1,mat->fp);
                    data[i] = i8;
                }
            }
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8;

            data_size = sizeof(mat_uint8_t);
            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&ui8,data_size,1,mat->fp);
                    data[i] = ui8;
                }
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
int
ReadCompressedUInt8Data(mat_t *mat,z_stream *z,mat_uint8_t *data,
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
int
ReadCompressedCharData(mat_t *mat,z_stream *z,char *data,
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

int
ReadCharData(mat_t *mat,char *data,enum matio_types data_type,int len)
{
    int bytesread = 0, data_size = 0, i;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) )
        return 0;

    switch ( data_type ) {
        case MAT_T_UTF8:
            for ( i = 0; i < len; i++ )
                bytesread += fread(data+i,1,1,mat->fp);
            break;
        case MAT_T_INT8:
        case MAT_T_UINT8:
            for ( i = 0; i < len; i++ )
                bytesread += fread(data+i,1,1,mat->fp);
            break;
        case MAT_T_INT16:
        case MAT_T_UINT16:
        {
            mat_uint16_t i16;

            if ( mat->byteswap ) {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,2,1,mat->fp);
                    data[i] = Mat_uint16Swap(&i16);
                }
            } else {
                for ( i = 0; i < len; i++ ) {
                    bytesread += fread(&i16,2,1,mat->fp);
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
int
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
            double *ptr = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0; /* start[0]; */
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            fseek(mat->fp,I*data_size,SEEK_CUR);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    ReadDoubleData(mat,ptr+i,data_type,edge[0]);
                    I += dims[0]-start[0];
                    fseek(mat->fp,data_size*(dims[0]-edge[0]-start[0]),
                          SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j])+
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]; j++ ) {
                        ReadDoubleData(mat,ptr+i+j,data_type,1);
                        fseek(mat->fp,data_size*(stride[0]-1),SEEK_CUR);
                        I += stride[0];
                    }
                    I += dims[0]-edge[0]*stride[0]-start[0];
                    fseek(mat->fp,data_size*
                          (dims[0]-edge[0]*stride[0]-start[0]),SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j]) +
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            }
            break;
        }
        case MAT_C_SINGLE:
        {
            float *ptr = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0; /* start[0]; */
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            fseek(mat->fp,I*data_size,SEEK_CUR);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    ReadSingleData(mat,ptr+i,data_type,edge[0]);
                    I += dims[0]-start[0];
                    fseek(mat->fp,data_size*(dims[0]-edge[0]-start[0]),
                          SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j])+
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]; j++ ) {
                        ReadSingleData(mat,ptr+i+j,data_type,1);
                        fseek(mat->fp,data_size*(stride[0]-1),SEEK_CUR);
                        I += stride[0];
                    }
                    I += dims[0]-edge[0]*stride[0]-start[0];
                    fseek(mat->fp,data_size*
                          (dims[0]-edge[0]*stride[0]-start[0]),SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j]) +
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            }
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
        {
            mat_int64_t *ptr = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0; /* start[0]; */
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            fseek(mat->fp,I*data_size,SEEK_CUR);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    ReadInt64Data(mat,ptr+i,data_type,edge[0]);
                    I += dims[0]-start[0];
                    fseek(mat->fp,data_size*(dims[0]-edge[0]-start[0]),
                          SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j])+
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]; j++ ) {
                        ReadInt64Data(mat,ptr+i+j,data_type,1);
                        fseek(mat->fp,data_size*(stride[0]-1),SEEK_CUR);
                        I += stride[0];
                    }
                    I += dims[0]-edge[0]*stride[0]-start[0];
                    fseek(mat->fp,data_size*
                          (dims[0]-edge[0]*stride[0]-start[0]),SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j]) +
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            }
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
        {
            mat_uint64_t *ptr = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0; /* start[0]; */
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            fseek(mat->fp,I*data_size,SEEK_CUR);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    ReadUInt64Data(mat,ptr+i,data_type,edge[0]);
                    I += dims[0]-start[0];
                    fseek(mat->fp,data_size*(dims[0]-edge[0]-start[0]),
                          SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j])+
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]; j++ ) {
                        ReadUInt64Data(mat,ptr+i+j,data_type,1);
                        fseek(mat->fp,data_size*(stride[0]-1),SEEK_CUR);
                        I += stride[0];
                    }
                    I += dims[0]-edge[0]*stride[0]-start[0];
                    fseek(mat->fp,data_size*
                          (dims[0]-edge[0]*stride[0]-start[0]),SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j]) +
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            }
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
        {
            mat_int32_t *ptr = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0; /* start[0]; */
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            fseek(mat->fp,I*data_size,SEEK_CUR);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    ReadInt32Data(mat,ptr+i,data_type,edge[0]);
                    I += dims[0]-start[0];
                    fseek(mat->fp,data_size*(dims[0]-edge[0]-start[0]),
                          SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j])+
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]; j++ ) {
                        ReadInt32Data(mat,ptr+i+j,data_type,1);
                        fseek(mat->fp,data_size*(stride[0]-1),SEEK_CUR);
                        I += stride[0];
                    }
                    I += dims[0]-edge[0]*stride[0]-start[0];
                    fseek(mat->fp,data_size*
                          (dims[0]-edge[0]*stride[0]-start[0]),SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j]) +
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            }
            break;
        }
        case MAT_C_UINT32:
        {
            mat_uint32_t *ptr = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0; /* start[0]; */
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            fseek(mat->fp,I*data_size,SEEK_CUR);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    ReadUInt32Data(mat,ptr+i,data_type,edge[0]);
                    I += dims[0]-start[0];
                    fseek(mat->fp,data_size*(dims[0]-edge[0]-start[0]),
                          SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j])+
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]; j++ ) {
                        ReadUInt32Data(mat,ptr+i+j,data_type,1);
                        fseek(mat->fp,data_size*(stride[0]-1),SEEK_CUR);
                        I += stride[0];
                    }
                    I += dims[0]-edge[0]*stride[0]-start[0];
                    fseek(mat->fp,data_size*
                          (dims[0]-edge[0]*stride[0]-start[0]),SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j]) +
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            }
            break;
        }
        case MAT_C_INT16:
        {
            mat_int16_t *ptr = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0; /* start[0]; */
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            fseek(mat->fp,I*data_size,SEEK_CUR);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    ReadInt16Data(mat,ptr+i,data_type,edge[0]);
                    I += dims[0]-start[0];
                    fseek(mat->fp,data_size*(dims[0]-edge[0]-start[0]),
                          SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j])+
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]; j++ ) {
                        ReadInt16Data(mat,ptr+i+j,data_type,1);
                        fseek(mat->fp,data_size*(stride[0]-1),SEEK_CUR);
                        I += stride[0];
                    }
                    I += dims[0]-edge[0]*stride[0]-start[0];
                    fseek(mat->fp,data_size*
                          (dims[0]-edge[0]*stride[0]-start[0]),SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j]) +
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            }
            break;
        }
        case MAT_C_UINT16:
        {
            mat_uint16_t *ptr = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0; /* start[0]; */
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            fseek(mat->fp,I*data_size,SEEK_CUR);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    ReadUInt16Data(mat,ptr+i,data_type,edge[0]);
                    I += dims[0]-start[0];
                    fseek(mat->fp,data_size*(dims[0]-edge[0]-start[0]),
                          SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j])+
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]; j++ ) {
                        ReadUInt16Data(mat,ptr+i+j,data_type,1);
                        fseek(mat->fp,data_size*(stride[0]-1),SEEK_CUR);
                        I += stride[0];
                    }
                    I += dims[0]-edge[0]*stride[0]-start[0];
                    fseek(mat->fp,data_size*
                          (dims[0]-edge[0]*stride[0]-start[0]),SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j]) +
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            }
            break;
        }
        case MAT_C_INT8:
        {
            mat_int8_t *ptr = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0; /* start[0]; */
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            fseek(mat->fp,I*data_size,SEEK_CUR);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    ReadInt8Data(mat,ptr+i,data_type,edge[0]);
                    I += dims[0]-start[0];
                    fseek(mat->fp,data_size*(dims[0]-edge[0]-start[0]),
                          SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j])+
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]; j++ ) {
                        ReadInt8Data(mat,ptr+i+j,data_type,1);
                        fseek(mat->fp,data_size*(stride[0]-1),SEEK_CUR);
                        I += stride[0];
                    }
                    I += dims[0]-edge[0]*stride[0]-start[0];
                    fseek(mat->fp,data_size*
                          (dims[0]-edge[0]*stride[0]-start[0]),SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j]) +
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            }
            break;
        }
        case MAT_C_UINT8:
        {
            mat_uint8_t *ptr = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0; /* start[0]; */
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            fseek(mat->fp,I*data_size,SEEK_CUR);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    ReadUInt8Data(mat,ptr+i,data_type,edge[0]);
                    I += dims[0]-start[0];
                    fseek(mat->fp,data_size*(dims[0]-edge[0]-start[0]),
                          SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j])+
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]; j++ ) {
                        ReadUInt8Data(mat,ptr+i+j,data_type,1);
                        fseek(mat->fp,data_size*(stride[0]-1),SEEK_CUR);
                        I += stride[0];
                    }
                    I += dims[0]-edge[0]*stride[0]-start[0];
                    fseek(mat->fp,data_size*
                          (dims[0]-edge[0]*stride[0]-start[0]),SEEK_CUR);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                fseek(mat->fp,data_size*
                                      (dimp[j]-(I % dimp[j]) +
                                       dimp[j-1]*start[j]),SEEK_CUR);
                                I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                            } else if ( start[j] ) {
                                fseek(mat->fp,data_size*(dimp[j-1]*start[j]),
                                      SEEK_CUR);
                                I += dimp[j-1]*start[j];
                            }
                        } else {
                            I += inc[j];
                            fseek(mat->fp,data_size*inc[j],SEEK_CUR);
                            break;
                        }
                    }
                }
            }
            break;
        }
        default:
            nBytes = 0;
    }
    return nBytes;
}

#if defined(HAVE_ZLIB)
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
int
ReadCompressedDataSlabN(mat_t *mat,z_stream *z,void *data,
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
            double *ptr;

            ptr     = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0;
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            /* Skip all data to the starting indeces */
            InflateSkipData(mat,&z_copy,data_type,I);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    ReadCompressedDoubleData(mat,&z_copy,ptr+i,data_type,edge[0]);
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-start[0]-edge[0]);
                    I += dims[0]-start[0];
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]-1; j++ ) {
                        ReadCompressedDoubleData(mat,&z_copy,ptr+i+j,data_type,1);
                        InflateSkipData(mat,&z_copy,data_type,(stride[0]-1));
                        I += stride[0];
                    }
                    ReadCompressedDoubleData(mat,&z_copy,ptr+i+j,data_type,1);
                    I += dims[0]-(edge[0]-1)*stride[0]-start[0];
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-(edge[0]-1)*stride[0]-start[0]-1);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
#if 0
                        I += dims[0]-edge[0]*stride[0]-start[0];
                        InflateSkipData(mat,&z_copy,data_type,
                              dims[0]-edge[0]*stride[0]-start[0]);
#endif
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            }
            break;
        }
        case MAT_C_SINGLE:
        {
            float *ptr;

            ptr     = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0;
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            /* Skip all data to the starting indeces */
            InflateSkipData(mat,&z_copy,data_type,I);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    ReadCompressedSingleData(mat,&z_copy,ptr+i,data_type,edge[0]);
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-start[0]-edge[0]);
                    I += dims[0]-start[0];
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]-1; j++ ) {
                        ReadCompressedSingleData(mat,&z_copy,ptr+i+j,data_type,1);
                        InflateSkipData(mat,&z_copy,data_type,(stride[0]-1));
                        I += stride[0];
                    }
                    ReadCompressedSingleData(mat,&z_copy,ptr+i+j,data_type,1);
                    I += dims[0]-(edge[0]-1)*stride[0]-start[0];
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-(edge[0]-1)*stride[0]-start[0]-1);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            }
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
        {
            mat_int64_t *ptr;

            ptr     = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0;
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            /* Skip all data to the starting indeces */
            InflateSkipData(mat,&z_copy,data_type,I);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    ReadCompressedInt64Data(mat,&z_copy,ptr+i,data_type,edge[0]);
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-start[0]-edge[0]);
                    I += dims[0]-start[0];
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]-1; j++ ) {
                        ReadCompressedInt64Data(mat,&z_copy,ptr+i+j,data_type,1);
                        InflateSkipData(mat,&z_copy,data_type,(stride[0]-1));
                        I += stride[0];
                    }
                    ReadCompressedInt64Data(mat,&z_copy,ptr+i+j,data_type,1);
                    I += dims[0]-(edge[0]-1)*stride[0]-start[0];
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-(edge[0]-1)*stride[0]-start[0]-1);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            }
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
        {
            mat_uint64_t *ptr;

            ptr     = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0;
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            /* Skip all data to the starting indeces */
            InflateSkipData(mat,&z_copy,data_type,I);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    ReadCompressedUInt64Data(mat,&z_copy,ptr+i,data_type,edge[0]);
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-start[0]-edge[0]);
                    I += dims[0]-start[0];
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]-1; j++ ) {
                        ReadCompressedUInt64Data(mat,&z_copy,ptr+i+j,data_type,1);
                        InflateSkipData(mat,&z_copy,data_type,(stride[0]-1));
                        I += stride[0];
                    }
                    ReadCompressedUInt64Data(mat,&z_copy,ptr+i+j,data_type,1);
                    I += dims[0]-(edge[0]-1)*stride[0]-start[0];
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-(edge[0]-1)*stride[0]-start[0]-1);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            }
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
        {
            mat_int32_t *ptr;

            ptr     = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0;
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            /* Skip all data to the starting indeces */
            InflateSkipData(mat,&z_copy,data_type,I);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    ReadCompressedInt32Data(mat,&z_copy,ptr+i,data_type,edge[0]);
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-start[0]-edge[0]);
                    I += dims[0]-start[0];
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]-1; j++ ) {
                        ReadCompressedInt32Data(mat,&z_copy,ptr+i+j,data_type,1);
                        InflateSkipData(mat,&z_copy,data_type,(stride[0]-1));
                        I += stride[0];
                    }
                    ReadCompressedInt32Data(mat,&z_copy,ptr+i+j,data_type,1);
                    I += dims[0]-(edge[0]-1)*stride[0]-start[0];
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-(edge[0]-1)*stride[0]-start[0]-1);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            }
            break;
        }
        case MAT_C_UINT32:
        {
            mat_uint32_t *ptr;

            ptr     = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0;
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            /* Skip all data to the starting indeces */
            InflateSkipData(mat,&z_copy,data_type,I);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    ReadCompressedUInt32Data(mat,&z_copy,ptr+i,data_type,edge[0]);
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-start[0]-edge[0]);
                    I += dims[0]-start[0];
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]-1; j++ ) {
                        ReadCompressedUInt32Data(mat,&z_copy,ptr+i+j,data_type,1);
                        InflateSkipData(mat,&z_copy,data_type,(stride[0]-1));
                        I += stride[0];
                    }
                    ReadCompressedUInt32Data(mat,&z_copy,ptr+i+j,data_type,1);
                    I += dims[0]-(edge[0]-1)*stride[0]-start[0];
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-(edge[0]-1)*stride[0]-start[0]-1);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            }
            break;
        }
        case MAT_C_INT16:
        {
            mat_int16_t *ptr;

            ptr     = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0;
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            /* Skip all data to the starting indeces */
            InflateSkipData(mat,&z_copy,data_type,I);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    ReadCompressedInt16Data(mat,&z_copy,ptr+i,data_type,edge[0]);
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-start[0]-edge[0]);
                    I += dims[0]-start[0];
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]-1; j++ ) {
                        ReadCompressedInt16Data(mat,&z_copy,ptr+i+j,data_type,1);
                        InflateSkipData(mat,&z_copy,data_type,(stride[0]-1));
                        I += stride[0];
                    }
                    ReadCompressedInt16Data(mat,&z_copy,ptr+i+j,data_type,1);
                    I += dims[0]-(edge[0]-1)*stride[0]-start[0];
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-(edge[0]-1)*stride[0]-start[0]-1);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            }
            break;
        }
        case MAT_C_UINT16:
        {
            mat_uint16_t *ptr;

            ptr     = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0;
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            /* Skip all data to the starting indeces */
            InflateSkipData(mat,&z_copy,data_type,I);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    ReadCompressedUInt16Data(mat,&z_copy,ptr+i,data_type,edge[0]);
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-start[0]-edge[0]);
                    I += dims[0]-start[0];
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]-1; j++ ) {
                        ReadCompressedUInt16Data(mat,&z_copy,ptr+i+j,data_type,1);
                        InflateSkipData(mat,&z_copy,data_type,(stride[0]-1));
                        I += stride[0];
                    }
                    ReadCompressedUInt16Data(mat,&z_copy,ptr+i+j,data_type,1);
                    I += dims[0]-(edge[0]-1)*stride[0]-start[0];
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-(edge[0]-1)*stride[0]-start[0]-1);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            }
            break;
        }
        case MAT_C_INT8:
        {
            mat_int8_t *ptr;

            ptr     = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0;
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            /* Skip all data to the starting indeces */
            InflateSkipData(mat,&z_copy,data_type,I);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    ReadCompressedInt8Data(mat,&z_copy,ptr+i,data_type,edge[0]);
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-start[0]-edge[0]);
                    I += dims[0]-start[0];
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]-1; j++ ) {
                        ReadCompressedInt8Data(mat,&z_copy,ptr+i+j,data_type,1);
                        InflateSkipData(mat,&z_copy,data_type,(stride[0]-1));
                        I += stride[0];
                    }
                    ReadCompressedInt8Data(mat,&z_copy,ptr+i+j,data_type,1);
                    I += dims[0]-(edge[0]-1)*stride[0]-start[0];
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-(edge[0]-1)*stride[0]-start[0]-1);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            }
            break;
        }
        case MAT_C_UINT8:
        {
            mat_uint8_t *ptr;

            ptr     = data;
            inc[0]  = stride[0]-1;
            dimp[0] = dims[0];
            N       = edge[0];
            I       = 0;
            for ( i = 1; i < rank; i++ ) {
                inc[i]  = stride[i]-1;
                dimp[i] = dims[i-1];
                for ( j = i; j--; ) {
                    inc[i]  *= dims[j];
                    dimp[i] *= dims[j+1];
                }
                N *= edge[i];
                I += dimp[i-1]*start[i];
            }
            /* Skip all data to the starting indeces */
            InflateSkipData(mat,&z_copy,data_type,I);
            if ( stride[0] == 1 ) {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    ReadCompressedUInt8Data(mat,&z_copy,ptr+i,data_type,edge[0]);
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-start[0]-edge[0]);
                    I += dims[0]-start[0];
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            } else {
                for ( i = 0; i < N; i+=edge[0] ) {
                    if ( start[0] ) {
                        InflateSkipData(mat,&z_copy,data_type,start[0]);
                        I += start[0];
                    }
                    for ( j = 0; j < edge[0]-1; j++ ) {
                        ReadCompressedUInt8Data(mat,&z_copy,ptr+i+j,data_type,1);
                        InflateSkipData(mat,&z_copy,data_type,(stride[0]-1));
                        I += stride[0];
                    }
                    ReadCompressedUInt8Data(mat,&z_copy,ptr+i+j,data_type,1);
                    I += dims[0]-(edge[0]-1)*stride[0]-start[0];
                    InflateSkipData(mat,&z_copy,data_type,dims[0]-(edge[0]-1)*stride[0]-start[0]-1);
                    for ( j = 1; j < rank; j++ ) {
                        cnt[j]++;
                        if ( (cnt[j] % edge[j]) == 0 ) {
                            cnt[j] = 0;
                            if ( (I % dimp[j]) != 0 ) {
                                InflateSkipData(mat,&z_copy,data_type,
                                      dimp[j]-(I % dimp[j])+dimp[j-1]*start[j]);
                                    I += dimp[j]-(I % dimp[j]) + dimp[j-1]*start[j];
                                } else if ( start[j] ) {
                                    InflateSkipData(mat,&z_copy,data_type,
                                        dimp[j-1]*start[j]);
                                    I += dimp[j-1]*start[j];
                                }
                        } else {
                            if ( inc[j] ) {
                                I += inc[j];
                                InflateSkipData(mat,&z_copy,data_type,inc[j]);
                            }
                            break;
                        }
                    }
                }
            }
            break;
        }
        default:
            nBytes = 0;
    }
    inflateEnd(&z_copy);
    return nBytes;
}
#endif

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
 * @return Number of bytes read from the file
 */
int
ReadDataSlab1(mat_t *mat,void *data,enum matio_classes class_type,
    enum matio_types data_type,int start,int stride,int edge)
{
    int i;
    size_t data_size;
    int    bytesread = 0;

    data_size = Mat_SizeOf(data_type);
    fseek(mat->fp,start*data_size,SEEK_CUR);

    stride = data_size*(stride-1);
    switch(class_type) {
        case MAT_C_DOUBLE:
            if ( !stride ) {
                bytesread+=ReadDoubleData(mat,data,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    bytesread+=ReadDoubleData(mat,(double*)data+i,data_type,1);
                    fseek(mat->fp,stride,SEEK_CUR);
                }
            }
            break;
        case MAT_C_SINGLE:
            if ( !stride ) {
                bytesread+=ReadSingleData(mat,data,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    bytesread+=ReadSingleData(mat,(float*)data+i,data_type,1);
                    fseek(mat->fp,stride,SEEK_CUR);
                }
            }
            break;
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
            if ( !stride ) {
                bytesread+=ReadInt64Data(mat,data,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    bytesread+=ReadInt64Data(mat,(mat_int64_t*)data+i,data_type,1);
                    fseek(mat->fp,stride,SEEK_CUR);
                }
            }
            break;
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
            if ( !stride ) {
                bytesread+=ReadUInt64Data(mat,data,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    bytesread+=ReadUInt64Data(mat,(mat_uint64_t*)data+i,data_type,1);
                    fseek(mat->fp,stride,SEEK_CUR);
                }
            }
            break;
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
            if ( !stride ) {
                bytesread+=ReadInt32Data(mat,data,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    bytesread+=ReadInt32Data(mat,(mat_int32_t*)data+i,data_type,1);
                    fseek(mat->fp,stride,SEEK_CUR);
                }
            }
            break;
        case MAT_C_UINT32:
            if ( !stride ) {
                bytesread+=ReadUInt32Data(mat,data,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    bytesread+=ReadUInt32Data(mat,(mat_uint32_t*)data+i,data_type,1);
                    fseek(mat->fp,stride,SEEK_CUR);
                }
            }
            break;
        case MAT_C_INT16:
            if ( !stride ) {
                bytesread+=ReadInt16Data(mat,data,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    bytesread+=ReadInt16Data(mat,(mat_int16_t*)data+i,data_type,1);
                    fseek(mat->fp,stride,SEEK_CUR);
                }
            }
            break;
        case MAT_C_UINT16:
            if ( !stride ) {
                bytesread+=ReadUInt16Data(mat,data,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    bytesread+=ReadUInt16Data(mat,(mat_uint16_t*)data+i,data_type,1);
                    fseek(mat->fp,stride,SEEK_CUR);
                }
            }
            break;
        case MAT_C_INT8:
            if ( !stride ) {
                bytesread+=ReadInt8Data(mat,data,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    bytesread+=ReadInt8Data(mat,(mat_int8_t*)data+i,data_type,1);
                    fseek(mat->fp,stride,SEEK_CUR);
                }
            }
            break;
        case MAT_C_UINT8:
            if ( !stride ) {
                bytesread+=ReadUInt8Data(mat,data,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    bytesread+=ReadUInt8Data(mat,(mat_uint8_t*)data+i,data_type,1);
                    fseek(mat->fp,stride,SEEK_CUR);
                }
            }
            break;
        default:
            return 0;
    }

    return bytesread;
}

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
int
ReadDataSlab2(mat_t *mat,void *data,enum matio_classes class_type,
    enum matio_types data_type,size_t *dims,int *start,int *stride,int *edge)
{
    int nBytes = 0, data_size, i, j;
    long pos, row_stride, col_stride;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) ||
         (start == NULL) || (stride == NULL) || (edge    == NULL) ) {
        return 0;
    }

    data_size = Mat_SizeOf(data_type);

    switch ( class_type ) {
        case MAT_C_DOUBLE:
        {
            double *ptr;

            ptr = (double *)data;
            /* If stride[0] is 1 and stride[1] is 1, we are reading all of the
             * data so get rid of the loops.
             */
            if ( (stride[0] == 1 && edge[0] == dims[0]) &&
                 (stride[1] == 1) ) {
                ReadDoubleData(mat,ptr,data_type,edge[0]*edge[1]);
            } else {
                row_stride = (stride[0]-1)*data_size;
                col_stride = stride[1]*dims[0]*data_size;
                pos = ftell(mat->fp);
                fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
                for ( i = 0; i < edge[1]; i++ ) {
                    pos = ftell(mat->fp);
                    fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                    for ( j = 0; j < edge[0]; j++ ) {
                        ReadDoubleData(mat,ptr++,data_type,1);
                        fseek(mat->fp,row_stride,SEEK_CUR);
                    }
                    pos = pos+col_stride-ftell(mat->fp);
                    fseek(mat->fp,pos,SEEK_CUR);
                }
            }
            break;
        }
        case MAT_C_SINGLE:
        {
            float *ptr;

            ptr = (float *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;
            pos = ftell(mat->fp);
            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    ReadSingleData(mat,ptr++,data_type,1);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
            }
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
        {
            mat_int64_t *ptr;

            ptr = (mat_int64_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;
            pos = ftell(mat->fp);
            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    ReadInt64Data(mat,ptr++,data_type,1);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
            }
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
        {
            mat_uint64_t *ptr;

            ptr = (mat_uint64_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;
            pos = ftell(mat->fp);
            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    ReadUInt64Data(mat,ptr++,data_type,1);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
            }
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
        {
            mat_int32_t *ptr;

            ptr = (mat_int32_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;
            pos = ftell(mat->fp);
            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    ReadInt32Data(mat,ptr++,data_type,1);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_C_UINT32:
        {
            mat_uint32_t *ptr;

            ptr = (mat_uint32_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;
            pos = ftell(mat->fp);
            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    ReadUInt32Data(mat,ptr++,data_type,1);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_C_INT16:
        {
            mat_int16_t *ptr;

            ptr = (mat_int16_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;
            pos = ftell(mat->fp);
            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    ReadInt16Data(mat,ptr++,data_type,1);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_C_UINT16:
        {
            mat_uint16_t *ptr;

            ptr = (mat_uint16_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;
            pos = ftell(mat->fp);
            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    ReadUInt16Data(mat,ptr++,data_type,1);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_C_INT8:
        {
            mat_int8_t *ptr;

            ptr = (mat_int8_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;
            pos = ftell(mat->fp);
            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    ReadInt8Data(mat,ptr++,data_type,1);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_C_UINT8:
        {
            mat_uint8_t *ptr;

            ptr = (mat_uint8_t *)data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;
            pos = ftell(mat->fp);
            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    ReadUInt8Data(mat,ptr++,data_type,1);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        default:
            nBytes = 0;
    }
    return nBytes;
}

#if defined(HAVE_ZLIB)
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
int
ReadCompressedDataSlab1(mat_t *mat,z_stream *z,void *data,
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
            double *ptr = data;
            if ( !stride ) {
                nBytes+=ReadCompressedDoubleData(mat,&z_copy,ptr,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    nBytes+=ReadCompressedDoubleData(mat,&z_copy,ptr+i,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride);
                }
            }
            break;
        }
        case MAT_C_SINGLE:
        {
            float *ptr = data;
            if ( !stride ) {
                nBytes+=ReadCompressedSingleData(mat,&z_copy,ptr,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    nBytes+=ReadCompressedSingleData(mat,&z_copy,ptr+i,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride);
                }
            }
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
        {
            mat_int64_t *ptr = data;
            if ( !stride ) {
                nBytes+=ReadCompressedInt64Data(mat,&z_copy,ptr,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    nBytes+=ReadCompressedInt64Data(mat,&z_copy,ptr+i,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride);
                }
            }
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
        {
            mat_uint64_t *ptr = data;
            if ( !stride ) {
                nBytes+=ReadCompressedUInt64Data(mat,&z_copy,ptr,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    nBytes+=ReadCompressedUInt64Data(mat,&z_copy,ptr+i,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride);
                }
            }
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
        {
            mat_int32_t *ptr = data;
            if ( !stride ) {
                nBytes+=ReadCompressedInt32Data(mat,&z_copy,ptr,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    nBytes+=ReadCompressedInt32Data(mat,&z_copy,ptr+i,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride);
                }
            }
            break;
        }
        case MAT_C_UINT32:
        {
            mat_uint32_t *ptr = data;
            if ( !stride ) {
                nBytes+=ReadCompressedUInt32Data(mat,&z_copy,ptr,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    nBytes+=ReadCompressedUInt32Data(mat,&z_copy,ptr+i,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride);
                }
            }
            break;
        }
        case MAT_C_INT16:
        {
            mat_int16_t *ptr = data;
            if ( !stride ) {
                nBytes+=ReadCompressedInt16Data(mat,&z_copy,ptr,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    nBytes+=ReadCompressedInt16Data(mat,&z_copy,ptr+i,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride);
                }
            }
            break;
        }
        case MAT_C_UINT16:
        {
            mat_uint16_t *ptr = data;
            if ( !stride ) {
                nBytes+=ReadCompressedUInt16Data(mat,&z_copy,ptr,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    nBytes+=ReadCompressedUInt16Data(mat,&z_copy,ptr+i,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride);
                }
            }
            break;
        }
        case MAT_C_INT8:
        {
            mat_int8_t *ptr = data;
            if ( !stride ) {
                nBytes+=ReadCompressedInt8Data(mat,&z_copy,ptr,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    nBytes+=ReadCompressedInt8Data(mat,&z_copy,ptr+i,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride);
                }
            }
            break;
        }
        case MAT_C_UINT8:
        {
            mat_uint8_t *ptr = data;
            if ( !stride ) {
                nBytes+=ReadCompressedUInt8Data(mat,&z_copy,ptr,data_type,edge);
            } else {
                for ( i = 0; i < edge; i++ ) {
                    nBytes+=ReadCompressedUInt8Data(mat,&z_copy,ptr+i,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride);
                }
            }
            break;
        }
        default:
            break;
    }
    inflateEnd(&z_copy);
    return nBytes;
}

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
int
ReadCompressedDataSlab2(mat_t *mat,z_stream *z,void *data,
    enum matio_classes class_type,enum matio_types data_type,size_t *dims,
    int *start,int *stride,int *edge)
{
    int nBytes = 0, data_size, i, j, err;
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
            double *ptr;

            data_size = sizeof(double);
            ptr = data;
            row_stride = (stride[0]-1);
            col_stride = (stride[1]-1)*dims[0];
            InflateSkipData(mat,&z_copy,data_type,start[1]*dims[0]);
            /* If stride[0] is 1 and stride[1] is 1, we are reading all of the
             * data so get rid of the loops.  If stride[0] is 1 and stride[1]
             * is not 0, we are reading whole columns, so get rid of inner loop
             * to speed up the code
             */
            if ( (stride[0] == 1 && edge[0] == dims[0]) &&
                 (stride[1] == 1) ) {
                ReadCompressedDoubleData(mat,&z_copy,ptr,data_type,
                                         edge[0]*edge[1]);
            } else if ( stride[0] == 1 ) {
                for ( i = 0; i < edge[1]; i++ ) {
                    InflateSkipData(mat,&z_copy,data_type,start[0]);
                    ReadCompressedDoubleData(mat,&z_copy,ptr,data_type,edge[0]);
                    ptr += edge[0];
                    pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride;
                    InflateSkipData(mat,&z_copy,data_type,pos);
                }
            } else {
                for ( i = 0; i < edge[1]; i++ ) {
                    InflateSkipData(mat,&z_copy,data_type,start[0]);
                    for ( j = 0; j < edge[0]-1; j++ ) {
                        ReadCompressedDoubleData(mat,&z_copy,ptr++,data_type,1);
                        InflateSkipData(mat,&z_copy,data_type,stride[0]-1);
                    }
                    ReadCompressedDoubleData(mat,&z_copy,ptr++,data_type,1);
                    pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride;
                    InflateSkipData(mat,&z_copy,data_type,pos);
                }
            }
            break;
        }
        case MAT_C_SINGLE:
        {
            float *ptr;

            data_size = sizeof(float);
            ptr = data;
            row_stride = (stride[0]-1);
            col_stride = (stride[1]-1)*dims[0];
            InflateSkipData(mat,&z_copy,data_type,start[1]*dims[0]);
            for ( i = 0; i < edge[1]; i++ ) {
                InflateSkipData(mat,&z_copy,data_type,start[0]);
                for ( j = 0; j < edge[0]-1; j++ ) {
                    ReadCompressedSingleData(mat,&z_copy,ptr++,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride[0]-1);
                }
                ReadCompressedSingleData(mat,&z_copy,ptr++,data_type,1);
                pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride;
                InflateSkipData(mat,&z_copy,data_type,pos);
            }
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_C_INT64:
        {
            mat_int64_t *ptr;

            data_size = sizeof(mat_int64_t);
            ptr = data;
            row_stride = (stride[0]-1);
            col_stride = (stride[1]-1)*dims[0];
            InflateSkipData(mat,&z_copy,data_type,start[1]*dims[0]);
            for ( i = 0; i < edge[1]; i++ ) {
                InflateSkipData(mat,&z_copy,data_type,start[0]);
                for ( j = 0; j < edge[0]-1; j++ ) {
                    ReadCompressedInt64Data(mat,&z_copy,ptr++,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride[0]-1);
                }
                ReadCompressedInt64Data(mat,&z_copy,ptr++,data_type,1);
                pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride;
                InflateSkipData(mat,&z_copy,data_type,pos);
            }
            break;
        }
#endif /* HAVE_MATIO_INT64_T */
#ifdef HAVE_MATIO_UINT64_T
        case MAT_C_UINT64:
        {
            mat_uint64_t *ptr;

            data_size = sizeof(mat_uint64_t);
            ptr = data;
            row_stride = (stride[0]-1);
            col_stride = (stride[1]-1)*dims[0];
            InflateSkipData(mat,&z_copy,data_type,start[1]*dims[0]);
            for ( i = 0; i < edge[1]; i++ ) {
                InflateSkipData(mat,&z_copy,data_type,start[0]);
                for ( j = 0; j < edge[0]-1; j++ ) {
                    ReadCompressedUInt64Data(mat,&z_copy,ptr++,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride[0]-1);
                }
                ReadCompressedUInt64Data(mat,&z_copy,ptr++,data_type,1);
                pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride;
                InflateSkipData(mat,&z_copy,data_type,pos);
            }
            break;
        }
#endif /* HAVE_MATIO_UINT64_T */
        case MAT_C_INT32:
        {
            mat_int32_t *ptr;

            data_size = sizeof(mat_int32_t);
            ptr = data;
            row_stride = (stride[0]-1);
            col_stride = (stride[1]-1)*dims[0];
            InflateSkipData(mat,&z_copy,data_type,start[1]*dims[0]);
            for ( i = 0; i < edge[1]; i++ ) {
                InflateSkipData(mat,&z_copy,data_type,start[0]);
                for ( j = 0; j < edge[0]-1; j++ ) {
                    ReadCompressedInt32Data(mat,&z_copy,ptr++,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride[0]-1);
                }
                ReadCompressedInt32Data(mat,&z_copy,ptr++,data_type,1);
                pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride;
                InflateSkipData(mat,&z_copy,data_type,pos);
            }
            break;
        }
        case MAT_C_UINT32:
        {
            mat_uint32_t *ptr;

            data_size = sizeof(mat_uint32_t);
            ptr = data;
            row_stride = (stride[0]-1);
            col_stride = (stride[1]-1)*dims[0];
            InflateSkipData(mat,&z_copy,data_type,start[1]*dims[0]);
            for ( i = 0; i < edge[1]; i++ ) {
                InflateSkipData(mat,&z_copy,data_type,start[0]);
                for ( j = 0; j < edge[0]-1; j++ ) {
                    ReadCompressedUInt32Data(mat,&z_copy,ptr++,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride[0]-1);
                }
                ReadCompressedUInt32Data(mat,&z_copy,ptr++,data_type,1);
                pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride;
                InflateSkipData(mat,&z_copy,data_type,pos);
            }
            break;
        }
        case MAT_C_INT16:
        {
            mat_int16_t *ptr;

            data_size = sizeof(mat_int16_t);
            ptr = data;
            row_stride = (stride[0]-1);
            col_stride = (stride[1]-1)*dims[0];
            InflateSkipData(mat,&z_copy,data_type,start[1]*dims[0]);
            for ( i = 0; i < edge[1]; i++ ) {
                InflateSkipData(mat,&z_copy,data_type,start[0]);
                for ( j = 0; j < edge[0]-1; j++ ) {
                    ReadCompressedInt16Data(mat,&z_copy,ptr++,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride[0]-1);
                }
                ReadCompressedInt16Data(mat,&z_copy,ptr++,data_type,1);
                pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride;
                InflateSkipData(mat,&z_copy,data_type,pos);
            }
            break;
        }
        case MAT_C_UINT16:
        {
            mat_uint16_t *ptr;

            data_size = sizeof(mat_uint16_t);
            ptr = data;
            row_stride = (stride[0]-1);
            col_stride = (stride[1]-1)*dims[0];
            InflateSkipData(mat,&z_copy,data_type,start[1]*dims[0]);
            for ( i = 0; i < edge[1]; i++ ) {
                InflateSkipData(mat,&z_copy,data_type,start[0]);
                for ( j = 0; j < edge[0]-1; j++ ) {
                    ReadCompressedUInt16Data(mat,&z_copy,ptr++,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride[0]-1);
                }
                ReadCompressedUInt16Data(mat,&z_copy,ptr++,data_type,1);
                pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride;
                InflateSkipData(mat,&z_copy,data_type,pos);
            }
            break;
        }
        case MAT_C_INT8:
        {
            mat_int8_t *ptr;

            data_size = sizeof(mat_int8_t);
            ptr = data;
            row_stride = (stride[0]-1);
            col_stride = (stride[1]-1)*dims[0];
            InflateSkipData(mat,&z_copy,data_type,start[1]*dims[0]);
            for ( i = 0; i < edge[1]; i++ ) {
                InflateSkipData(mat,&z_copy,data_type,start[0]);
                for ( j = 0; j < edge[0]-1; j++ ) {
                    ReadCompressedInt8Data(mat,&z_copy,ptr++,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride[0]-1);
                }
                ReadCompressedInt8Data(mat,&z_copy,ptr++,data_type,1);
                pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride;
                InflateSkipData(mat,&z_copy,data_type,pos);
            }
            break;
        }
        case MAT_C_UINT8:
        {
            mat_uint8_t *ptr;

            data_size = sizeof(mat_uint8_t);
            ptr = data;
            row_stride = (stride[0]-1);
            col_stride = (stride[1]-1)*dims[0];
            InflateSkipData(mat,&z_copy,data_type,start[1]*dims[0]);
            for ( i = 0; i < edge[1]; i++ ) {
                InflateSkipData(mat,&z_copy,data_type,start[0]);
                for ( j = 0; j < edge[0]-1; j++ ) {
                    ReadCompressedUInt8Data(mat,&z_copy,ptr++,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride[0]-1);
                }
                ReadCompressedUInt8Data(mat,&z_copy,ptr++,data_type,1);
                pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride;
                InflateSkipData(mat,&z_copy,data_type,pos);
            }
            break;
        }
        case MAT_C_CHAR:
        {
            char *ptr;

            data_size = 1;
            ptr = data;
            row_stride = (stride[0]-1);
            col_stride = (stride[1]-1)*dims[0];
            InflateSkipData(mat,&z_copy,data_type,start[1]*dims[0]);
            for ( i = 0; i < edge[1]; i++ ) {
                InflateSkipData(mat,&z_copy,data_type,start[0]);
                for ( j = 0; j < edge[0]-1; j++ ) {
                    ReadCompressedCharData(mat,&z_copy,ptr++,data_type,1);
                    InflateSkipData(mat,&z_copy,data_type,stride[0]-1);
                }
                ReadCompressedCharData(mat,&z_copy,ptr++,data_type,1);
                pos = dims[0]-(edge[0]-1)*stride[0]-1-start[0] + col_stride;
                InflateSkipData(mat,&z_copy,data_type,pos);
            }
            break;
        }
        default:
            nBytes = 0;
    }
    inflateEnd(&z_copy);
    return nBytes;
}
#endif

/** @endcond */
/* -------------------------------
 * ---------- snprintf.c
 * -------------------------------
 */
/*
 * Copyright Patrick Powell 1995
 * This code is based on code written by Patrick Powell (papowell@astart.com)
 * It may be used for any purpose as long as this notice remains intact
 * on all source code distributions
 */

/*=============================================================
 * Original:
 * Patrick Powell Tue Apr 11 09:48:21 PDT 1995
 * A bombproof version of doprnt (dopr) included.
 * Sigh.  This sort of thing is always nasty do deal with.  Note that
 * the version here does not include floating point...
 *
 * snprintf() is used instead of sprintf() as it does limit checks
 * for string length.  This covers a nasty loophole.
 *
 * The other functions are there to prevent NULL pointers from
 * causing nast effects.
 *
 * More Recently:
 *  Brandon Long <blong@fiction.net> 9/15/96 for mutt 0.43
 *  This was ugly.  It is still ugly.  I opted out of floating point
 *  numbers, but the formatter understands just about everything
 *  from the normal C string format, at least as far as I can tell from
 *  the Solaris 2.5 printf(3S) man page.
 *
 *  Brandon Long <blong@fiction.net> 10/22/97 for mutt 0.87.1
 *    Ok, added some minimal floating point support, which means this
 *    probably requires libm on most operating systems.  Don't yet
 *    support the exponent (e,E) and sigfig (g,G).  Also, fmtint()
 *    was pretty badly broken, it just wasn't being exercised in ways
 *    which showed it, so that's been fixed.  Also, formated the code
 *    to mutt conventions, and removed dead code left over from the
 *    original.  Also, there is now a builtin-test, just compile with:
 *           gcc -DTEST_SNPRINTF -o snprintf snprintf.c -lm
 *    and run snprintf for results.
 *
 *  Thomas Roessler <roessler@guug.de> 01/27/98 for mutt 0.89i
 *    The PGP code was using unsigned hexadecimal formats.
 *    Unfortunately, unsigned formats simply didn't work.
 *
 *  Michael Elkins <me@cs.hmc.edu> 03/05/98 for mutt 0.90.8
 *    The original code assumed that both snprintf() and vsnprintf() were
 *    missing.  Some systems only have snprintf() but not vsnprintf(), so
 *    the code is now broken down under HAVE_SNPRINTF and HAVE_VSNPRINTF.
 *
 *  Andrew Tridgell (tridge@samba.org) Oct 1998
 *    fixed handling of %.0f
 *    added test for HAVE_LONG_DOUBLE
 *
 * tridge@samba.org, idra@samba.org, April 2001
 *    got rid of fcvt code (twas buggy and made testing harder)
 *    added C99 semantics
 *
 * date: 2002/12/19 19:56:31;  author: herb;  state: Exp;  lines: +2 -0
 * actually print args for %g and %e
 *
 * date: 2002/06/03 13:37:52;  author: jmcd;  state: Exp;  lines: +8 -0
 * Since includes.h isn't included here, VA_COPY has to be defined here.  I don't
 * see any include file that is guaranteed to be here, so I'm defining it
 * locally.  Fixes AIX and Solaris builds.
 *
 * date: 2002/06/03 03:07:24;  author: tridge;  state: Exp;  lines: +5 -13
 * put the ifdef for HAVE_VA_COPY in one place rather than in lots of
 * functions
 *
 * date: 2002/05/17 14:51:22;  author: jmcd;  state: Exp;  lines: +21 -4
 * Fix usage of va_list passed as an arg.  Use __va_copy before using it
 * when it exists.
 *
 * date: 2002/04/16 22:38:04;  author: idra;  state: Exp;  lines: +20 -14
 * Fix incorrect zpadlen handling in fmtfp.
 * Thanks to Ollie Oldham <ollie.oldham@metro-optix.com> for spotting it.
 * few mods to make it easier to compile the tests.
 * addedd the "Ollie" test to the floating point ones.
 *
 * Martin Pool (mbp@samba.org) April 2003
 *    Remove NO_CONFIG_H so that the test case can be built within a source
 *    tree with less trouble.
 *    Remove unnecessary SAFE_FREE() definition.
 *
 * Martin Pool (mbp@samba.org) May 2003
 *    Put in a prototype for dummy_snprintf() to quiet compiler warnings.
 *
 *    Move #endif to make sure VA_COPY, LDOUBLE, etc are defined even
 *    if the C library has some snprintf functions already.
 =============================================================*/

#if defined(HAVE_STRING_H) || defined(STDC_HEADERS)
#include <string.h>
#endif

#if defined(HAVE_STRINGS_H)
#include <strings.h>
#endif
#if defined(HAVE_CTYPE_H) || defined(STDC_HEADERS)
#include <ctype.h>
#endif
#include <sys/types.h>
#include <stdarg.h>
#if defined(HAVE_STDLIB_H) || defined(STDC_HEADERS)
#include <stdlib.h>
#endif
#include <stdio.h>

#ifdef HAVE_LONG_DOUBLE
#define LDOUBLE long double
#else
#define LDOUBLE double
#endif

#ifdef HAVE_LONG_LONG
#define LLONG long long
#else
#define LLONG long
#endif

#ifndef VA_COPY
#ifdef HAVE_VA_COPY
#define VA_COPY(dest, src) va_copy(dest, src)
#else
#ifdef HAVE___VA_COPY
#define VA_COPY(dest, src) __va_copy(dest, src)
#else
#define VA_COPY(dest, src) (dest) = (src)
#endif
#endif

/*
 * dopr(): poor man's version of doprintf
 */

/* format read states */
#define DP_S_DEFAULT 0
#define DP_S_FLAGS   1
#define DP_S_MIN     2
#define DP_S_DOT     3
#define DP_S_MAX     4
#define DP_S_MOD     5
#define DP_S_CONV    6
#define DP_S_DONE    7

/* format flags - Bits */
#define DP_F_MINUS      (1 << 0)
#define DP_F_PLUS       (1 << 1)
#define DP_F_SPACE      (1 << 2)
#define DP_F_NUM        (1 << 3)
#define DP_F_ZERO       (1 << 4)
#define DP_F_UP         (1 << 5)
#define DP_F_UNSIGNED   (1 << 6)

/* Conversion Flags */
#define DP_C_SHORT   1
#define DP_C_LONG    2
#define DP_C_LDOUBLE 3
#define DP_C_LLONG   4

#define char_to_int(p) ((p)- '0')
#ifndef MAX
#define MAX(p,q) (((p) >= (q)) ? (p) : (q))
#endif

/* yes this really must be a ||. Don't muck with this (tridge) */
#if !defined(HAVE_VSNPRINTF) || !defined(HAVE_C99_VSNPRINTF)
static size_t dopr(char *buffer, size_t maxlen, const char *format,
                    va_list args_in);
static void fmtstr(char *buffer, size_t *currlen, size_t maxlen,
                    char *value, int flags, int min, int max);
static void fmtint(char *buffer, size_t *currlen, size_t maxlen,
                    long value, int base, int min, int max, int flags);
static void fmtfp(char *buffer, size_t *currlen, size_t maxlen,
                   LDOUBLE fvalue, int min, int max, int flags);
static void dopr_outch(char *buffer, size_t *currlen, size_t maxlen, char c);

static size_t dopr(char *buffer, size_t maxlen, const char *format, va_list args_in)
{
    char ch;
    LLONG value;
    LDOUBLE fvalue;
    char *strvalue;
    int min;
    int max;
    int state;
    int flags;
    int cflags;
    size_t currlen;
    va_list args;

    VA_COPY(args, args_in);

    state = DP_S_DEFAULT;
    currlen = flags = cflags = min = 0;
    max = -1;
    ch = *format++;

    while (state != DP_S_DONE) {
        if (ch == '\0')
            state = DP_S_DONE;

        switch(state) {
        case DP_S_DEFAULT:
            if (ch == '%')
                state = DP_S_FLAGS;
            else
                dopr_outch (buffer, &currlen, maxlen, ch);
            ch = *format++;
            break;
        case DP_S_FLAGS:
            switch (ch) {
            case '-':
                flags |= DP_F_MINUS;
                ch = *format++;
                break;
            case '+':
                flags |= DP_F_PLUS;
                ch = *format++;
                break;
            case ' ':
                flags |= DP_F_SPACE;
                ch = *format++;
                break;
            case '#':
                flags |= DP_F_NUM;
                ch = *format++;
                break;
            case '0':
                flags |= DP_F_ZERO;
                ch = *format++;
                break;
            default:
                state = DP_S_MIN;
                break;
            }
            break;
        case DP_S_MIN:
            if (isdigit((unsigned char)ch)) {
                min = 10*min + char_to_int (ch);
                ch = *format++;
            } else if (ch == '*') {
                min = va_arg (args, int);
                ch = *format++;
                state = DP_S_DOT;
            } else {
                state = DP_S_DOT;
            }
            break;
        case DP_S_DOT:
            if (ch == '.') {
                state = DP_S_MAX;
                ch = *format++;
            } else {
                state = DP_S_MOD;
            }
            break;
        case DP_S_MAX:
            if (isdigit((unsigned char)ch)) {
                if (max < 0)
                    max = 0;
                max = 10*max + char_to_int (ch);
                ch = *format++;
            } else if (ch == '*') {
                max = va_arg (args, int);
                ch = *format++;
                state = DP_S_MOD;
            } else {
                state = DP_S_MOD;
            }
            break;
        case DP_S_MOD:
            switch (ch) {
            case 'h':
                cflags = DP_C_SHORT;
                ch = *format++;
                break;
            case 'l':
                cflags = DP_C_LONG;
                ch = *format++;
                if (ch == 'l') {        /* It's a long long */
                    cflags = DP_C_LLONG;
                    ch = *format++;
                }
                break;
            case 'L':
                cflags = DP_C_LDOUBLE;
                ch = *format++;
                break;
            default:
                break;
            }
            state = DP_S_CONV;
            break;
        case DP_S_CONV:
            switch (ch) {
            case 'd':
            case 'i':
                if (cflags == DP_C_SHORT)
                    value = va_arg (args, int);
                else if (cflags == DP_C_LONG)
                    value = va_arg (args, long int);
                else if (cflags == DP_C_LLONG)
                    value = va_arg (args, LLONG);
                else
                    value = va_arg (args, int);
                fmtint (buffer, &currlen, maxlen, value, 10, min, max, flags);
                break;
            case 'o':
                flags |= DP_F_UNSIGNED;
                if (cflags == DP_C_SHORT)
                    value = va_arg (args, unsigned int);
                else if (cflags == DP_C_LONG)
                    value = (long)va_arg (args, unsigned long int);
                else if (cflags == DP_C_LLONG)
                    value = (long)va_arg (args, unsigned LLONG);
                else
                    value = (long)va_arg (args, unsigned int);
                fmtint (buffer, &currlen, maxlen, value, 8, min, max, flags);
                break;
            case 'u':
                flags |= DP_F_UNSIGNED;
                if (cflags == DP_C_SHORT)
                    value = va_arg (args, unsigned int);
                else if (cflags == DP_C_LONG)
                    value = (long)va_arg (args, unsigned long int);
                else if (cflags == DP_C_LLONG)
                    value = (LLONG)va_arg (args, unsigned LLONG);
                else
                    value = (long)va_arg (args, unsigned int);
                fmtint (buffer, &currlen, maxlen, value, 10, min, max, flags);
                break;
            case 'X':
                flags |= DP_F_UP;
            case 'x':
                flags |= DP_F_UNSIGNED;
                if (cflags == DP_C_SHORT)
                    value = va_arg (args, unsigned int);
                else if (cflags == DP_C_LONG)
                    value = (long)va_arg (args, unsigned long int);
                else if (cflags == DP_C_LLONG)
                    value = (LLONG)va_arg (args, unsigned LLONG);
                else
                    value = (long)va_arg (args, unsigned int);
                fmtint (buffer, &currlen, maxlen, value, 16, min, max, flags);
                break;
            case 'f':
                if (cflags == DP_C_LDOUBLE)
                    fvalue = va_arg (args, LDOUBLE);
                else
                    fvalue = va_arg (args, double);
                /* um, floating point? */
                fmtfp (buffer, &currlen, maxlen, fvalue, min, max, flags);
                break;
            case 'E':
                flags |= DP_F_UP;
            case 'e':
                if (cflags == DP_C_LDOUBLE)
                    fvalue = va_arg (args, LDOUBLE);
                else
                    fvalue = va_arg (args, double);
                fmtfp (buffer, &currlen, maxlen, fvalue, min, max, flags);
                break;
            case 'G':
                flags |= DP_F_UP;
            case 'g':
                if (cflags == DP_C_LDOUBLE)
                    fvalue = va_arg (args, LDOUBLE);
                else
                    fvalue = va_arg (args, double);
                fmtfp (buffer, &currlen, maxlen, fvalue, min, max, flags);
                break;
            case 'c':
                dopr_outch (buffer, &currlen, maxlen, (char)va_arg (args, int));
                break;
            case 's':
                strvalue = va_arg (args, char *);
                if (!strvalue) strvalue = "(NULL)";
                if (max == -1) {
                    max = strlen(strvalue);
                }
                if (min > 0 && max >= 0 && min > max) max = min;
                fmtstr (buffer, &currlen, maxlen, strvalue, flags, min, max);
                break;
            case 'p':
                strvalue = va_arg (args, void *);
                fmtint (buffer, &currlen, maxlen, (long) strvalue, 16, min, max, flags);
                break;
            case 'n':
                if (cflags == DP_C_SHORT) {
                    short int *num;
                    num = va_arg (args, short int *);
                    *num = currlen;
                } else if (cflags == DP_C_LONG) {
                    long int *num;
                    num = va_arg (args, long int *);
                    *num = (long int)currlen;
                } else if (cflags == DP_C_LLONG) {
                    LLONG *num;
                    num = va_arg (args, LLONG *);
                    *num = (LLONG)currlen;
                } else {
                    int *num;
                    num = va_arg (args, int *);
                    *num = currlen;
                }
                break;
            case '%':
                dopr_outch (buffer, &currlen, maxlen, ch);
                break;
            case 'w':
                /* not supported yet, treat as next char */
                ch = *format++;
                break;
            default:
                /* Unknown, skip */
                break;
            }
            ch = *format++;
            state = DP_S_DEFAULT;
            flags = cflags = min = 0;
            max = -1;
            break;
        case DP_S_DONE:
            break;
        default:
            /* hmm? */
            break; /* some picky compilers need this */
        }
    }
    if (maxlen != 0) {
        if (currlen < maxlen - 1)
            buffer[currlen] = '\0';
        else if (maxlen > 0)
            buffer[maxlen - 1] = '\0';
    }

    return currlen;
}

static void fmtstr(char *buffer, size_t *currlen, size_t maxlen,
                    char *value, int flags, int min, int max)
{
    int padlen, strln;     /* amount to pad */
    int cnt = 0;

#ifdef DEBUG_SNPRINTF
    printf("fmtstr min=%d max=%d s=[%s]\n", min, max, value);
#endif
    if (value == 0) {
        value = "<NULL>";
    }

    for (strln = 0; value[strln]; ++strln); /* strlen */
    padlen = min - strln;
    if (padlen < 0)
        padlen = 0;
    if (flags & DP_F_MINUS)
        padlen = -padlen; /* Left Justify */

    while ((padlen > 0) && (cnt < max)) {
        dopr_outch (buffer, currlen, maxlen, ' ');
        --padlen;
        ++cnt;
    }
    while (*value && (cnt < max)) {
        dopr_outch (buffer, currlen, maxlen, *value++);
        ++cnt;
    }
    while ((padlen < 0) && (cnt < max)) {
        dopr_outch (buffer, currlen, maxlen, ' ');
        ++padlen;
        ++cnt;
    }
}

/* Have to handle DP_F_NUM (ie 0x and 0 alternates) */

static void fmtint(char *buffer, size_t *currlen, size_t maxlen,
                    long value, int base, int min, int max, int flags)
{
    int signvalue = 0;
    unsigned long uvalue;
    char convert[20];
    int place = 0;
    int spadlen = 0; /* amount to space pad */
    int zpadlen = 0; /* amount to zero pad */
    int caps = 0;

    if (max < 0)
        max = 0;

    uvalue = value;

    if(!(flags & DP_F_UNSIGNED)) {
        if( value < 0 ) {
            signvalue = '-';
            uvalue = -value;
        } else {
            if (flags & DP_F_PLUS)  /* Do a sign (+/i) */
                signvalue = '+';
            else if (flags & DP_F_SPACE)
                signvalue = ' ';
        }
    }

    if (flags & DP_F_UP) caps = 1; /* Should characters be upper case? */

    do {
        convert[place++] =
            (caps? "0123456789ABCDEF":"0123456789abcdef")
            [uvalue % (unsigned)base  ];
        uvalue = (uvalue / (unsigned)base );
    } while(uvalue && (place < 20));
    if (place == 20) place--;
    convert[place] = 0;

    zpadlen = max - place;
    spadlen = min - MAX (max, place) - (signvalue ? 1 : 0);
    if (zpadlen < 0) zpadlen = 0;
    if (spadlen < 0) spadlen = 0;
    if (flags & DP_F_ZERO) {
        zpadlen = MAX(zpadlen, spadlen);
        spadlen = 0;
    }
    if (flags & DP_F_MINUS)
        spadlen = -spadlen; /* Left Justifty */

#ifdef DEBUG_SNPRINTF
    printf("zpad: %d, spad: %d, min: %d, max: %d, place: %d\n",
           zpadlen, spadlen, min, max, place);
#endif

    /* Spaces */
    while (spadlen > 0) {
        dopr_outch (buffer, currlen, maxlen, ' ');
        --spadlen;
    }

    /* Sign */
    if (signvalue)
        dopr_outch (buffer, currlen, maxlen, (char)signvalue);

    /* Zeros */
    if (zpadlen > 0) {
        while (zpadlen > 0) {
            dopr_outch (buffer, currlen, maxlen, '0');
            --zpadlen;
        }
    }

    /* Digits */
    while (place > 0)
        dopr_outch (buffer, currlen, maxlen, convert[--place]);

    /* Left Justified spaces */
    while (spadlen < 0) {
        dopr_outch (buffer, currlen, maxlen, ' ');
        ++spadlen;
    }
}

static LDOUBLE abs_val(LDOUBLE value)
{
    LDOUBLE result = value;

    if (value < 0)
        result = -value;

    return result;
}

static LDOUBLE POW10(int exp)
{
    LDOUBLE result = 1;

    while (exp) {
        result *= 10;
        exp--;
    }

    return result;
}

static LLONG ROUND(LDOUBLE value)
{
    LLONG intpart;

    intpart = (LLONG)value;
    value = value - intpart;
    if (value >= 0.5) intpart++;

    return intpart;
}

/* a replacement for modf that doesn't need the math library. Should
   be portable, but slow */
static double my_modf(double x0, double *iptr)
{
    int i;
    long l;
    double x = x0;
    double f = 1.0;

    for (i=0;i<100;i++) {
        l = (long)x;
        if (l <= (x+1) && l >= (x-1)) break;
        x *= 0.1;
        f *= 10.0;
    }

    if (i == 100) {
        /* yikes! the number is beyond what we can handle. What do we do? */
        (*iptr) = 0;
        return 0;
    }

    if (i != 0) {
        double i2;
        double ret;

        ret = my_modf(x0-l*f, &i2);
        (*iptr) = l*f + i2;
        return ret;
    }

    (*iptr) = l;
    return x - (*iptr);
}


static void fmtfp (char *buffer, size_t *currlen, size_t maxlen,
                   LDOUBLE fvalue, int min, int max, int flags)
{
    int signvalue = 0;
    double ufvalue;
    char iconvert[311];
    char fconvert[311];
    int iplace = 0;
    int fplace = 0;
    int padlen = 0; /* amount to pad */
    int zpadlen = 0;
    int caps = 0;
    int idx;
    double intpart;
    double fracpart;
    double temp;

    /*
     * AIX manpage says the default is 0, but Solaris says the default
     * is 6, and sprintf on AIX defaults to 6
     */
    if (max < 0)
        max = 6;

    ufvalue = abs_val (fvalue);

    if (fvalue < 0) {
        signvalue = '-';
    } else {
        if (flags & DP_F_PLUS) { /* Do a sign (+/i) */
            signvalue = '+';
        } else {
            if (flags & DP_F_SPACE)
                signvalue = ' ';
        }
    }

#if 0
    if (flags & DP_F_UP) caps = 1; /* Should characters be upper case? */
#endif

#if 0
     if (max == 0) ufvalue += 0.5; /* if max = 0 we must round */
#endif

    /*
     * Sorry, we only support 16 digits past the decimal because of our
     * conversion method
     */
    if (max > 16)
        max = 16;

    /* We "cheat" by converting the fractional part to integer by
     * multiplying by a factor of 10
     */

    temp = ufvalue;
    my_modf(temp, &intpart);

    fracpart = ROUND((POW10(max)) * (ufvalue - intpart));

    if (fracpart >= POW10(max)) {
        intpart++;
        fracpart -= POW10(max);
    }

    /* Convert integer part */
    do {
        temp = intpart*0.1;
        my_modf(temp, &intpart);
        idx = (int) ((temp -intpart +0.05)* 10.0);
        /* idx = (int) (((double)(temp*0.1) -intpart +0.05) *10.0); */
        /* printf ("%llf, %f, %x\n", temp, intpart, idx); */
        iconvert[iplace++] =
            (caps? "0123456789ABCDEF":"0123456789abcdef")[idx];
    } while (intpart && (iplace < 311));
    if (iplace == 311) iplace--;
    iconvert[iplace] = 0;

    /* Convert fractional part */
    if (fracpart)
    {
        do {
            temp = fracpart*0.1;
            my_modf(temp, &fracpart);
            idx = (int) ((temp -fracpart +0.05)* 10.0);
            /* idx = (int) ((((temp/10) -fracpart) +0.05) *10); */
            /* printf ("%lf, %lf, %ld\n", temp, fracpart, idx ); */
            fconvert[fplace++] =
            (caps? "0123456789ABCDEF":"0123456789abcdef")[idx];
        } while(fracpart && (fplace < 311));
        if (fplace == 311) fplace--;
    }
    fconvert[fplace] = 0;

    /* -1 for decimal point, another -1 if we are printing a sign */
    padlen = min - iplace - max - 1 - ((signvalue) ? 1 : 0);
    zpadlen = max - fplace;
    if (zpadlen < 0) zpadlen = 0;
    if (padlen < 0)
        padlen = 0;
    if (flags & DP_F_MINUS)
        padlen = -padlen; /* Left Justifty */

    if ((flags & DP_F_ZERO) && (padlen > 0)) {
        if (signvalue) {
            dopr_outch (buffer, currlen, maxlen, (char)signvalue);
            --padlen;
            signvalue = 0;
        }
        while (padlen > 0) {
            dopr_outch (buffer, currlen, maxlen, '0');
            --padlen;
        }
    }
    while (padlen > 0) {
        dopr_outch (buffer, currlen, maxlen, ' ');
        --padlen;
    }
    if (signvalue)
        dopr_outch (buffer, currlen, maxlen, (char)signvalue);

    while (iplace > 0)
        dopr_outch (buffer, currlen, maxlen, iconvert[--iplace]);

#ifdef DEBUG_SNPRINTF
    printf("fmtfp: fplace=%d zpadlen=%d\n", fplace, zpadlen);
#endif

    /*
     * Decimal point.  This should probably use locale to find the correct
     * char to print out.
     */
    if (max > 0) {
        dopr_outch (buffer, currlen, maxlen, '.');

        while (zpadlen > 0) {
            dopr_outch (buffer, currlen, maxlen, '0');
            --zpadlen;
        }

        while (fplace > 0)
            dopr_outch (buffer, currlen, maxlen, fconvert[--fplace]);
    }

    while (padlen < 0) {
        dopr_outch (buffer, currlen, maxlen, ' ');
        ++padlen;
    }
}

static void dopr_outch(char *buffer, size_t *currlen, size_t maxlen, char c)
{
    if (*currlen < maxlen) {
        buffer[(*currlen)] = c;
    }
    (*currlen)++;
}

int mat_vsnprintf(char *str, size_t count, const char *fmt, va_list args)
{
    return dopr(str, count, fmt, args);
}
#else
int mat_vsnprintf(char *str, size_t count, const char *fmt, va_list args)
{
    return vsnprintf(str, count, fmt, args);
}
#endif

int mat_snprintf(char *str,size_t count,const char *fmt,...)
{
    size_t ret;
    va_list ap;

    va_start(ap, fmt);
    ret = mat_vsnprintf(str, count, fmt, ap);
    va_end(ap);
    return ret;
}
#endif

#ifndef HAVE_VASPRINTF
int mat_vasprintf(char **ptr, const char *format, va_list ap)
{
    int ret;
    va_list ap2;

    VA_COPY(ap2, ap);

    ret = mat_vsnprintf(NULL, 0, format, ap2);
    if (ret <= 0) return ret;

    (*ptr) = (char *)malloc(ret+1);
    if (!*ptr) return -1;

    VA_COPY(ap2, ap);

    ret = mat_vsnprintf(*ptr, ret+1, format, ap2);

    return ret;
}
#else
int mat_vasprintf(char **ptr, const char *format, va_list ap)
{
    return vasprintf(ptr,format,ap);
}
#endif

int mat_asprintf(char **ptr, const char *format, ...)
{
    va_list ap;
    int ret;

    *ptr = NULL;
    va_start(ap, format);
    ret = mat_vasprintf(ptr, format, ap);
    va_end(ap);

    return ret;
}

static char* mat_strdup(const char *s)
{
    size_t len = strlen(s) + 1;
    char *d = malloc(len);
    return d ? memcpy(d, s, len) : NULL;
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
static int WriteEmptyCharData(mat_t *mat, int N, enum matio_types data_type);
static int WriteEmptyData(mat_t *mat,int N,enum matio_types data_type);
static int ReadNextCell( mat_t *mat, matvar_t *matvar );
static int ReadNextStructField( mat_t *mat, matvar_t *matvar );
static int ReadNextFunctionHandle(mat_t *mat, matvar_t *matvar);
static int WriteCellArrayFieldInfo(mat_t *mat,matvar_t *matvar);
static int WriteCellArrayField(mat_t *mat,matvar_t *matvar );
static int WriteStructField(mat_t *mat,matvar_t *matvar);
static size_t Mat_WriteEmptyVariable5(mat_t *mat,const char *name,int rank,
                  size_t *dims);
#if defined(HAVE_ZLIB)
static size_t WriteCompressedCharData(mat_t *mat,z_stream *z,void *data,int N,
                  enum matio_types data_type);
static int    WriteCompressedEmptyData(mat_t *mat,z_stream *z,int N,
                  enum matio_types data_type);
static size_t WriteCompressedData(mat_t *mat,z_stream *z,void *data,int N,
                  enum matio_types data_type);
static size_t WriteCompressedCellArrayField(mat_t *mat,matvar_t *matvar,
                  z_stream *z);
static size_t WriteCompressedStructField(mat_t *mat,matvar_t *matvar,
                  z_stream *z);
static size_t Mat_WriteCompressedEmptyVariable5(mat_t *mat,const char *name,
                  int rank,size_t *dims,z_stream *z);
#endif

/*   mat5.c    */
EXTERN mat_t *Mat_Create5(const char *matname,const char *hdr_str);

matvar_t *Mat_VarReadNextInfo5( mat_t *mat );
void      Read5(mat_t *mat, matvar_t *matvar);
int       ReadData5(mat_t *mat,matvar_t *matvar,void *data,
              int *start,int *stride,int *edge);
int       Mat_VarReadDataLinear5(mat_t *mat,matvar_t *matvar,void *data,
              int start,int stride,int edge);
int       Mat_VarWrite5(mat_t *mat,matvar_t *matvar,int compress);
int       WriteCharDataSlab2(mat_t *mat,void *data,enum matio_types data_type,
              size_t *dims,int *start,int *stride,int *edge);
int       WriteData(mat_t *mat,void *data,int N,enum matio_types data_type);
int       WriteDataSlab2(mat_t *mat,void *data,enum matio_types data_type,
              size_t *dims,int *start,int *stride,int *edge);
void      WriteInfo5(mat_t *mat, matvar_t *matvar);

#endif

#ifndef MAT4_H
#define MAT4_H

EXTERN mat_t *Mat_Create4(const char* matname);
int  Mat_VarWrite4(mat_t *mat,matvar_t *matvar);
void Read4(mat_t *mat, matvar_t *matvar);
int  ReadData4(mat_t *mat,matvar_t *matvar,void *data,
         int *start,int *stride,int *edge);
int  Mat_VarReadDataLinear4(mat_t *mat,matvar_t *matvar,void *data,int start,
         int stride,int edge);

matvar_t *Mat_VarReadNextInfo4(mat_t *mat);

#endif
#if defined(HAVE_HDF5)
#ifndef MAT73_H
#define MAT73_H

#include <hdf5.h>

EXTERN mat_t    *Mat_Create73(const char *matname,const char *hdr_str);

EXTERN void      Mat_VarPrint73(matvar_t *matvar,int printdata);
EXTERN void      Mat_VarRead73(mat_t *mat,matvar_t *matvar);
EXTERN int       Mat_VarReadData73(mat_t *mat,matvar_t *matvar,void *data,
                     int *start,int *stride,int *edge);
EXTERN int       Mat_VarReadDataLinear73(mat_t *mat,matvar_t *matvar,void *data,
                     int start,int stride,int edge);
EXTERN matvar_t *Mat_VarReadNextInfo73(mat_t *mat);
EXTERN int       Mat_VarWrite73(mat_t *mat,matvar_t *matvar,int compress);

#endif
#endif

#if defined(_WIN32)
#include <io.h>
#endif
#if defined(_MSC_VER)
#define SIZE_T_FMTSTR "Iu"
#else
#define SIZE_T_FMTSTR "zu"
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
#ifdef HAVE_LONG_LONG
            printf("%lld",(long long)(*(mat_int64_t*)data));
#else
            printf("%lld",*(mat_int64_t*)data);
#endif
            break;
#endif
#ifdef HAVE_MATIO_UINT64_T
        case MAT_T_UINT64:
#ifdef HAVE_LONG_LONG
            printf("%llu",(unsigned long long)(*(mat_uint64_t*)data));
#else
            printf("%llu",*(mat_uint64_t*)data);
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
            printf("%hhd",*(mat_int8_t*)data);
            break;
        case MAT_T_UINT8:
            printf("%hhu",*(mat_uint8_t*)data);
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
 * @param major Pointer to store the library major version number
 * @param major Pointer to store the library major version number
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
            mat = Mat_CreateVer(matname,NULL,mode&0xfffffffe);
            return mat;
        }
    } else {
        Mat_Critical("Invalid file open mode");
        return NULL;
    }

    mat = malloc(sizeof(*mat));
    if ( NULL == mat ) {
        fclose(fp);
        Mat_Critical("Couldn't allocate memory for the MAT file");
        return NULL;
    }

    mat->fp = fp;
    mat->header        = calloc(128,1);
    mat->subsys_offset = calloc(8,1);
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
            mat->bof = ftell(mat->fp);
            mat->next_index    = 0;
        } else {
            mat->version = 0;
        }
    }

    if ( 0 == mat->version ) {
        /* Maybe a V4 MAT file */
        matvar_t *var;
        if ( NULL != mat->header )
            free(mat->header);
        if ( NULL != mat->subsys_offset )
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
        fclose(mat->fp);
#if defined(HAVE_HDF5)

        mat->fp = malloc(sizeof(hid_t));

        if ( (mode & 0x01) == MAT_ACC_RDONLY )
            *(hid_t*)mat->fp=H5Fopen(mat->filename,H5F_ACC_RDONLY,H5P_DEFAULT);
        else if ( (mode & 0x01) == MAT_ACC_RDWR )
            *(hid_t*)mat->fp=H5Fopen(mat->filename,H5F_ACC_RDWR,H5P_DEFAULT);

        if ( -1 < *(hid_t*)mat->fp ) {
            hsize_t num_objs;
            H5Gget_num_objs(*(hid_t*)mat->fp,&num_objs);
            mat->num_datasets = num_objs;
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
            fclose(mat->fp);
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
 * @param mat Pointer to the MAT file
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
 * @param mat Pointer to the MAT file
 * @return MAT file version
 */
enum mat_ft
Mat_GetVersion(mat_t *matfp)
{
    enum mat_ft file_type = 0;
    if ( NULL != matfp )
        file_type = matfp->version;
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
    switch ( mat->version ) {
        case MAT_FT_MAT73:
            mat->next_index = 0;
            break;
        case MAT_FT_MAT5:
            fseek(mat->fp,128L,SEEK_SET);
            break;
        case MAT_FT_MAT4:
            fseek(mat->fp,0L,SEEK_SET);
            break;
        default:
            return -1;
    }
    return 0;
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

    matvar = malloc(sizeof(*matvar));

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
        matvar->compression  = 0;
        matvar->internal     = malloc(sizeof(*matvar->internal));
        if ( NULL == matvar->internal ) {
            free(matvar);
            matvar = NULL;
        } else {
            matvar->internal->hdf5_name = NULL;
            matvar->internal->hdf5_ref  =  0;
            matvar->internal->id        = -1;
            matvar->internal->fp = NULL;
            matvar->internal->fpos         = 0;
            matvar->internal->datapos      = 0;
            matvar->internal->fieldnames   = NULL;
            matvar->internal->num_fields   = 0;
#if defined(HAVE_ZLIB)
            matvar->internal->z         = NULL;
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
    matvar->dims = malloc(matvar->rank*sizeof(*matvar->dims));
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
                fields = data;
                nfields = 0;
                while ( fields[nfields] != NULL )
                    nfields++;
                if ( nmemb )
                    nfields = nfields / nmemb;
                matvar->internal->num_fields = nfields;
                if ( nfields ) {
                    matvar->internal->fieldnames =
                        calloc(nfields,sizeof(*matvar->internal->fieldnames));
                    for ( i = 0; i < nfields; i++ )
                        matvar->internal->fieldnames[i] = mat_strdup(fields[i]->name);
                    nmemb *= nfields;
                }
            }
            break;
        }
        default:
            Mat_VarFree(matvar);
            matvar = NULL;
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

        sparse_data_in = data;
        sparse_data    = malloc(sizeof(mat_sparse_t));
        if ( NULL != sparse_data ) {
            sparse_data->nzmax = sparse_data_in->nzmax;
            sparse_data->nir   = sparse_data_in->nir;
            sparse_data->njc   = sparse_data_in->njc;
            sparse_data->ndata = sparse_data_in->ndata;
            sparse_data->ir = malloc(sparse_data->nir*sizeof(*sparse_data->ir));
            if ( NULL != sparse_data->ir )
                memcpy(sparse_data->ir,sparse_data_in->ir,
                       sparse_data->nir*sizeof(*sparse_data->ir));
            sparse_data->jc = malloc(sparse_data->njc*sizeof(*sparse_data->jc));
            if ( NULL != sparse_data->jc )
                memcpy(sparse_data->jc,sparse_data_in->jc,
                       sparse_data->njc*sizeof(*sparse_data->jc));
            if ( matvar->isComplex ) {
                sparse_data->data = malloc(sizeof(mat_complex_split_t));
                if ( NULL != sparse_data->data ) {
                    mat_complex_split_t *complex_data,*complex_data_in;
                    complex_data     = sparse_data->data;
                    complex_data_in  = sparse_data_in->data;
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
                mat_complex_split_t *complex_data    = matvar->data;
                mat_complex_split_t *complex_data_in = data;

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

static int mat_rename(const char* src, const char* dst)
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
    remove(src);
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
    enum mat_ft mat_file_ver = MAT_FT_DEFAULT;
    char *tmp_name, *new_name;
    mat_t *tmp;
    matvar_t *matvar;
#if defined(_WIN32)
    char template[10] = "matXXXXXX";
#else
    char *temp;
#endif

    if ( NULL == mat || NULL == name )
        return err;

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

#if defined(_WIN32)
    tmp_name = _mktemp(template);
#else
    temp     = NULL;
    tmp_name = tmpnam(temp);
#endif
    if (tmp_name != NULL) {
        tmp = Mat_CreateVer(tmp_name,mat->header,mat_file_ver);
        if ( tmp != NULL ) {
            while ( NULL != (matvar = Mat_VarReadNext(mat)) ) {
                if ( strcmp(matvar->name,name) )
                    Mat_VarWrite(tmp,matvar,MAT_COMPRESSION_NONE);
                else
                    err = 0;
                Mat_VarFree(matvar);
            }
            /* FIXME: Memory leak */
            new_name = strdup_printf("%s",mat->filename);
            fclose(mat->fp);

            if ( (err = remove(new_name)) == -1 ) {
                Mat_Critical("remove of %s failed",new_name);
            } else if ( !Mat_Close(tmp) && (err=mat_rename(tmp_name,new_name))==-1) {
                Mat_Critical("rename failed oldname=%s,newname=%s",tmp_name,
                    new_name);
            } else {
                tmp = Mat_Open(new_name,mat->mode);
                if ( NULL != tmp )
                    memcpy(mat,tmp,sizeof(mat_t));
            }
            free(tmp);
            free(new_name);
        }
    }
    else {
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
#endif
    out->internal->num_fields = in->internal->num_fields;
    if ( NULL != in->internal->fieldnames && in->internal->num_fields > 0 ) {
        out->internal->fieldnames = calloc(in->internal->num_fields,
                                           sizeof(*in->internal->fieldnames));
        for ( i = 0; i < in->internal->num_fields; i++ ) {
            if ( NULL != in->internal->fieldnames[i] )
                out->internal->fieldnames[i] =
                    mat_strdup(in->internal->fieldnames[i]);
        }
    }

    if (in->name != NULL && (NULL != (out->name = malloc(strlen(in->name)+1))))
        memcpy(out->name,in->name,strlen(in->name)+1);

    out->dims = malloc(in->rank*sizeof(*out->dims));
    if ( out->dims != NULL )
        memcpy(out->dims,in->dims,in->rank*sizeof(*out->dims));
#if defined(HAVE_ZLIB)
    if ( (in->internal->z != NULL) && (NULL != (out->internal->z = malloc(sizeof(z_stream)))) )
        inflateCopy(out->internal->z,in->internal->z);
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
    } else if ( in->data != NULL ) {
        if ( out->isComplex ) {
            out->data = malloc(sizeof(mat_complex_split_t));
            if ( out->data != NULL ) {
                mat_complex_split_t *out_data = out->data;
                mat_complex_split_t *in_data  = in->data;
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
                if ( !matvar->mem_conserve && NULL != matvar->data ) {
                    matvar_t **fields = matvar->data;
                    int nfields = matvar->internal->num_fields;
                    for ( i = 0; i < nmemb*nfields; i++ )
                        Mat_VarFree(fields[i]);

                    free(matvar->data);
                    break;
                }
            case MAT_C_CELL:
                if ( !matvar->mem_conserve && NULL != matvar->data ) {
                    matvar_t **cells = matvar->data;
                    for ( i = 0; i < nmemb; i++ )
                        Mat_VarFree(cells[i]);

                    free(matvar->data);
                }
                break;
            case MAT_C_SPARSE:
                if ( !matvar->mem_conserve ) {
                    mat_sparse_t *sparse;
                    sparse = matvar->data;
                    if ( sparse->ir != NULL )
                        free(sparse->ir);
                    if ( sparse->jc != NULL )
                        free(sparse->jc);
                    if ( matvar->isComplex && NULL != sparse->data ) {
                        mat_complex_split_t *complex_data = sparse->data;
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
                if ( !matvar->mem_conserve && NULL != matvar->data ) {
                    if ( matvar->isComplex ) {
                        mat_complex_split_t *complex_data = matvar->data;
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

void
Mat_VarFree2(matvar_t *matvar)
{
    if ( !matvar )
        return;
    if ( matvar->dims )
        free(matvar->dims);
    if ( matvar->name )
        free(matvar->name);
    if ( (matvar->data != NULL) && (matvar->class_type == MAT_C_STRUCT ||
          matvar->class_type == MAT_C_CELL) && matvar->data_size > 0 ) {
        int i;
        matvar_t **fields = (matvar_t **)matvar->data;
        int nfields = matvar->nbytes / matvar->data_size;
        for ( i = 0; i < nfields; i++ )
            Mat_VarFree(fields[i]);
        free(matvar->data);
    } else if ( (matvar->data != NULL) && (!matvar->mem_conserve) &&
                (matvar->class_type == MAT_C_SPARSE) ) {
        mat_sparse_t *sparse;
        sparse = matvar->data;
        if ( sparse->ir != NULL )
            free(sparse->ir);
        if ( sparse->jc != NULL )
            free(sparse->jc);
        if ( sparse->data != NULL )
            free(sparse->data);
        free(sparse);
    } else {
        if ( matvar->data && !matvar->mem_conserve )
            free(matvar->data);
    }
#if defined(HAVE_ZLIB)
    if ( matvar->compression == MAT_COMPRESSION_ZLIB )
        inflateEnd(matvar->internal->z);
#endif
    /* FIXME: Why does this cause a SEGV? */
#if 0
    memset(matvar,0,sizeof(matvar_t));
#endif
}

/** @brief Calculate a single subscript from a set of subscript values
 *
 * Calculates a single linear subscript (0-relative) given a 1-relative
 * subscript for each dimension.  The calculation uses the formula below where
 * index is the linear index, s is an array of length RANK where each element
 * is the subscript for the correspondind dimension, D is an array whose
 * elements are the dimensions of the variable.
 * \f[
 *   index = \sum\limits_{k=0}^{RANK-1} [(s_k - 1) \prod\limits_{l=0}^{k} D_l ]
 * \f]
 * @ingroup MAT
 * @param rank Rank of the variable
 * @param dims dimensions of the variable
 * @param subs Dimension subscripts
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
 * @param dims dimensions of the variable
 * @param index linear index
 * @return Array of dimension subscripts
 */
int *
Mat_CalcSubscripts(int rank,int *dims,int index)
{
    int i, j, k, *subs;
    double l;

    subs = malloc(rank*sizeof(int));
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
        /* This is really nmemb*nfields, but we'll get a
         * more accurate count of the bytes by loopoing over all of them
         */
        nfields = matvar->internal->num_fields;
        fields  = matvar->data;
        for ( i = 0; i < nfields; i++ )
            bytes += Mat_VarGetSize(fields[i]);
    } else if ( matvar->class_type == MAT_C_CELL ) {
        int ncells;
        matvar_t **cells;

        ncells = matvar->nbytes / matvar->data_size;
        cells  = matvar->data;
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
                    mat_complex_split_t *complex_data = matvar->data;
                    char *rp = complex_data->Re;
                    char *ip = complex_data->Im;
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
                   char *data = matvar->data;
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
                char *data = matvar->data;
                if ( !printdata )
                    break;
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
                sparse = matvar->data;
                if ( matvar->isComplex ) {
                    mat_complex_split_t *complex_data = sparse->data;
                    char *re,*im;
                    re = complex_data->Re;
                    im = complex_data->Im;
                    for ( i = 0; i < sparse->njc-1; i++ ) {
                        for (j = sparse->jc[i];
                             j<sparse->jc[i+1] && j<sparse->ndata;j++ ) {
                            printf("    (%d,%d)  ",sparse->ir[j]+1,i+1);
                            Mat_PrintNumber(matvar->data_type,re+j*stride);
                            printf(" + ");
                            Mat_PrintNumber(matvar->data_type,im+j*stride);
                            printf("i\n");
                        }
                    }
                } else {
                    char *data;
                    data = sparse->data;
                    for ( i = 0; i < sparse->njc-1; i++ ) {
                        for (j = sparse->jc[i];
                             j<sparse->jc[i+1] && j<sparse->ndata;j++ ){
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
 * @param start array of starting indeces
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
    matvar_t *matvar = NULL;

    if ( (mat == NULL) || (name == NULL) )
        return NULL;

    if ( mat->version == MAT_FT_MAT73 ) {
        do {
            matvar = Mat_VarReadNextInfo(mat);
            if ( matvar != NULL ) {
                if ( !matvar->name ) {
                    Mat_VarFree(matvar);
                    matvar = NULL;
                } else if ( strcmp(matvar->name,name) ) {
                    Mat_VarFree(matvar);
                    matvar = NULL;
                }
            } else {
                Mat_Critical("An error occurred in reading the MAT file");
                break;
            }
        } while ( NULL == matvar && mat->next_index < mat->num_datasets);
    } else {
        long fpos = ftell(mat->fp);
        fseek(mat->fp,mat->bof,SEEK_SET);
        do {
            matvar = Mat_VarReadNextInfo(mat);
            if ( matvar != NULL ) {
                if ( !matvar->name ) {
                    Mat_VarFree(matvar);
                    matvar = NULL;
                } else if ( strcmp(matvar->name,name) ) {
                    Mat_VarFree(matvar);
                    matvar = NULL;
                }
            } else if (!feof((FILE *)mat->fp)) {
                Mat_Critical("An error occurred in reading the MAT file");
                break;
            }
        } while ( !matvar && !feof((FILE *)mat->fp) );

        fseek(mat->fp,fpos,SEEK_SET);
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
    long  fpos = 0;
    matvar_t *matvar = NULL;;

    if ( (mat == NULL) || (name == NULL) )
        return NULL;

    if ( MAT_FT_MAT73 != mat->version )
        fpos = ftell(mat->fp);

    matvar = Mat_VarReadInfo(mat,name);
    if ( matvar )
        ReadData(mat,matvar);

    if ( MAT_FT_MAT73 != mat->version )
        fseek(mat->fp,fpos,SEEK_SET);
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
        fpos = ftell(mat->fp);
    }
    matvar = Mat_VarReadNextInfo(mat);
    if ( matvar )
        ReadData(mat,matvar);
    else if (mat->version != MAT_FT_MAT73 )
        fseek(mat->fp,fpos,SEEK_SET);
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
    if ( mat == NULL || matvar == NULL || mat->fp == NULL )
        return -1;
    else if ( mat->version != MAT_FT_MAT4 )
        WriteInfo5(mat,matvar);
#if 0
    else if ( mat->version == MAT_FT_MAT4 )
        WriteInfo4(mat,matvar);
#endif

    return 0;
}

/** @brief Writes the given data to the MAT variable
 *
 * Writes data to a MAT variable.  The variable must have previously been
 * written with Mat_VarWriteInfo.
 * @ingroup MAT
 * @param mat MAT file to write to
 * @param matvar MAT variable information to write
 * @param data pointer to the data to write
 * @param start array of starting indeces
 * @param stride stride of data
 * @param edge array specifying the number to read in each direction
 * @retval 0 on success
 */
int
Mat_VarWriteData(mat_t *mat,matvar_t *matvar,void *data,
      int *start,int *stride,int *edge)
{
    int err = 0, k, N = 1;

    fseek(mat->fp,matvar->internal->datapos+8,SEEK_SET);

    if ( mat == NULL || matvar == NULL || data == NULL ) {
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
#include <stdio.h>
#include <math.h>

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
mat_t *
Mat_Create4(const char* matname)
{
    FILE *fp = NULL;
    mat_t *mat = NULL;

    fp = fopen(matname,"wb");
    if ( !fp )
        return NULL;

    mat = malloc(sizeof(*mat));
    if ( NULL == mat ) {
        fclose(fp);
        Mat_Critical("Couldn't allocate memory for the MAT file");
        return NULL;
    }

    mat->header        = NULL;
    mat->subsys_offset = NULL;
    mat->fp            = fp;
    mat->version       = MAT_FT_MAT4;
    mat->byteswap      = 0;
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
int
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
    mat_complex_split_t *complex_data = NULL;
    Fmatrix x;

    if ( NULL == mat || NULL == matvar || NULL == matvar->name || matvar->rank != 2 )
        return -1;

    if (matvar->isComplex) {
        mat_complex_split_t *complex_data = matvar->data;
        if ( NULL == complex_data )
            return 1;
    }

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

    for ( i = 0; i < matvar->rank; i++ ) {
        mat_int32_t dim;
        dim = (mat_int32_t)matvar->dims[i];
        nmemb *= dim;
    }

    /* FIXME: SEEK_END is not Guaranteed by the C standard */
    fseek(mat->fp,0,SEEK_END);         /* Always write at end of file */

    if (mat->byteswap)
        x.type += 1000;
    x.mrows = (mat_int32_t)matvar->dims[0];
    x.ncols = (mat_int32_t)matvar->dims[1];
    x.imagf = matvar->isComplex ? 1 : 0;
    x.namelen = (mat_int32_t)strlen(matvar->name) + 1;
    fwrite(&x, sizeof(Fmatrix), 1, mat->fp);
    fwrite(matvar->name, sizeof(char), x.namelen, mat->fp);
    if (matvar->isComplex) {
        fwrite(complex_data->Re, matvar->data_size, nmemb, mat->fp);
        fwrite(complex_data->Im, matvar->data_size, nmemb, mat->fp);
    }
    else {
        fwrite(matvar->data, matvar->data_size, nmemb, mat->fp);
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
void
Read4(mat_t *mat,matvar_t *matvar)
{
    unsigned int N;
    if ( fseek(mat->fp,matvar->internal->datapos,SEEK_SET) )
        return;

    N = matvar->dims[0]*matvar->dims[1];
    switch ( matvar->class_type ) {
        case MAT_C_DOUBLE:
            matvar->data_size = sizeof(double);
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes   = N*sizeof(double);
                complex_data     = malloc(sizeof(*complex_data));
                complex_data->Re = malloc(matvar->nbytes);
                complex_data->Im = malloc(matvar->nbytes);
                matvar->data     = complex_data;
                if ( complex_data != NULL &&
                    complex_data->Re != NULL && complex_data->Im != NULL ) {
                    ReadDoubleData(mat, complex_data->Re, matvar->data_type, N);
                    ReadDoubleData(mat, complex_data->Im, matvar->data_type, N);
                }
            } else {
                matvar->nbytes = N*sizeof(double);
                matvar->data   = malloc(matvar->nbytes);
                if ( matvar->data != NULL )
                    ReadDoubleData(mat, matvar->data, matvar->data_type, N);
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
                ReadUInt8Data(mat,matvar->data,matvar->data_type,N);
            matvar->data_type = MAT_T_UINT8;
            break;
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
int
ReadData4(mat_t *mat,matvar_t *matvar,void *data,
      int *start,int *stride,int *edge)
{
    int err = 0;
    enum matio_classes class_type = MAT_C_EMPTY;

    fseek(mat->fp,matvar->internal->datapos,SEEK_SET);

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
            mat_complex_split_t *cdata = data;
            long nbytes = edge[0]*edge[1]*Mat_SizeOf(matvar->data_type);

            ReadDataSlab2(mat,cdata->Re,class_type,matvar->data_type,
                    matvar->dims,start,stride,edge);
            fseek(mat->fp,matvar->internal->datapos+nbytes,SEEK_SET);
            ReadDataSlab2(mat,cdata->Im,class_type,
                matvar->data_type,matvar->dims,start,stride,edge);
        } else {
            ReadDataSlab2(mat,data,class_type,matvar->data_type,
                    matvar->dims,start,stride,edge);
        }
    } else {
        if ( matvar->isComplex ) {
            int i;
            mat_complex_split_t *cdata = data;
            long nbytes = Mat_SizeOf(matvar->data_type);

            for ( i = 0; i < matvar->rank; i++ )
                nbytes *= edge[i];

            ReadDataSlabN(mat,cdata->Re,class_type,matvar->data_type,
                matvar->rank,matvar->dims,start,stride,edge);
            fseek(mat->fp,matvar->internal->datapos+nbytes,SEEK_SET);
            ReadDataSlab2(mat,cdata->Im,class_type,
                matvar->data_type,matvar->dims,start,stride,edge);
        } else {
            ReadDataSlabN(mat,data,class_type,matvar->data_type,
                matvar->rank,matvar->dims,start,stride,edge);
        }
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
int
Mat_VarReadDataLinear4(mat_t *mat,matvar_t *matvar,void *data,int start,
                       int stride,int edge)
{
    size_t i, nmemb = 1;
    int err = 0;

    fseek(mat->fp,matvar->internal->datapos,SEEK_SET);

    matvar->data_size = Mat_SizeOf(matvar->data_type);

    for ( i = 0; i < matvar->rank; i++ )
        nmemb *= matvar->dims[i];

    if ( stride*(edge-1)+start+1 > nmemb ) {
        return 1;
    }
    if ( matvar->isComplex ) {
            mat_complex_split_t *complex_data = data;
            long nbytes = nmemb*matvar->data_size;

            ReadDataSlab1(mat,complex_data->Re,matvar->class_type,
                          matvar->data_type,start,stride,edge);
            fseek(mat->fp,matvar->internal->datapos+nbytes,SEEK_SET);
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
 * @retuen pointer to the MAT variable or NULL
 * @endif
 */
matvar_t *
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
    matvar->internal->fpos = ftell(mat->fp);

    err = fread(&tmp,sizeof(int),1,mat->fp);
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
    class_type = floor(tmp);

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
    matvar->dims = malloc(2*sizeof(*matvar->dims));
    if ( NULL == matvar->dims ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    err = fread(&tmp,sizeof(int),1,mat->fp);
    if ( mat->byteswap )
        Mat_int32Swap(&tmp);
    matvar->dims[0] = tmp;
    if ( !err ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    err = fread(&tmp,sizeof(int),1,mat->fp);
    if ( mat->byteswap )
        Mat_int32Swap(&tmp);
    matvar->dims[1] = tmp;
    if ( !err ) {
        Mat_VarFree(matvar);
        return NULL;
    }

    err = fread(&(matvar->isComplex),sizeof(int),1,mat->fp);
    if ( !err ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    err = fread(&tmp,sizeof(int),1,mat->fp);
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
    matvar->name = malloc(tmp);
    if ( NULL == matvar->name ) {
        Mat_VarFree(matvar);
        return NULL;
    }
    err = fread(matvar->name,1,tmp,mat->fp);
    if ( !err ) {
        Mat_VarFree(matvar);
        return NULL;
    }

    matvar->internal->datapos = ftell(mat->fp);
    nBytes = matvar->dims[0]*matvar->dims[1]*Mat_SizeOf(matvar->data_type);
    if ( matvar->isComplex )
        nBytes *= 2;
    fseek(mat->fp,nBytes,SEEK_CUR);

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

#define TYPE_FROM_TAG(a)          (enum matio_types)((a) & 0x000000ff)
#define CLASS_FROM_ARRAY_FLAGS(a) (enum matio_classes)((a) & 0x000000ff)
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
        matvar_t **fields = matvar->data;
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
        matvar_t **cells = matvar->data;
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
        mat_sparse_t *sparse = matvar->data;

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
        matvar_t **fields = matvar->data;
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
        matvar_t **cells = matvar->data;
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
        mat_sparse_t *sparse = matvar->data;

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
        matvar_t **fields = matvar->data;
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
        matvar_t **cells = matvar->data;
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
        mat_sparse_t *sparse = matvar->data;

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
mat_t *
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

    mat = malloc(sizeof(*mat));
    if ( !mat ) {
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

    t = time(NULL);
    mat->fp = fp;
    mat->filename = strdup_printf("%s",matname);
    mat->mode     = MAT_ACC_RDWR;
    mat->byteswap = 0;
    mat->header   = calloc(1,128);
    mat->subsys_offset = calloc(1,16);
    memset(mat->header,' ',128);
    if ( hdr_str == NULL ) {
        err = mat_snprintf(mat->header,116,"MATLAB 5.0 MAT-file, Platform: %s, "
                "Created by: libmatio v%d.%d.%d on %s", MATIO_PLATFORM,
                MATIO_MAJOR_VERSION, MATIO_MINOR_VERSION, MATIO_RELEASE_LEVEL,
                ctime(&t));
        mat->header[115] = '\0';    /* Just to make sure it's NULL terminated */    } else {
        err = mat_snprintf(mat->header,116,"%s",hdr_str);
    }
    mat->header[err] = ' ';
    mat_snprintf(mat->subsys_offset,15,"            ");
    mat->version = (int)0x0100;
    endian = 0x4d49;

    version = 0x0100;

    err = fwrite(mat->header,1,116,mat->fp);
    err = fwrite(mat->subsys_offset,1,8,mat->fp);
    err = fwrite(&version,2,1,mat->fp);
    err = fwrite(&endian,2,1,mat->fp);

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
int
WriteCharData(mat_t *mat, void *data, int N,enum matio_types data_type)
{
    int nBytes = 0, bytesread = 0, i;
    mat_int8_t pad1 = 0;

    switch ( data_type ) {
        case MAT_T_UINT16:
        {
            nBytes = N*2;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            if ( NULL != data && N > 0 )
                fwrite(data,2,N,mat->fp);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,mat->fp);
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
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            ptr = data;
            if ( NULL == ptr )
                break;
            for ( i = 0; i < N; i++ ) {
                c = (mat_uint16_t)*(char *)ptr;
                fwrite(&c,2,1,mat->fp);
                ptr++;
            }
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,mat->fp);
            break;
        }
        case MAT_T_UTF8:
        {
            mat_uint8_t *ptr;

            nBytes = N;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            ptr = data;
            if ( NULL != ptr && nBytes > 0 )
                fwrite(ptr,1,nBytes,mat->fp);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,mat->fp);
            break;
        }
        default:
            break;
    }
    bytesread+=nBytes;
    return bytesread;
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
WriteCompressedCharData(mat_t *mat,z_stream *z,void *data,int N,
    enum matio_types data_type)
{
    int data_size, data_tag[2], err, byteswritten = 0;
    int buf_size = 1024, i;
    mat_uint8_t   buf[1024], pad[8] = {0,};

    if ((mat == NULL) || (mat->fp == NULL))
        return 0;

    switch ( data_type ) {
        case MAT_T_UINT16:
        {
            data_size = 2;
            data_tag[0]  = MAT_T_UINT16;
            data_tag[1]  = N*data_size;
            z->next_in   = ZLIB_BYTE_PTR(data_tag);
            z->avail_in  = 8;
            z->next_out  = buf;
            z->avail_out = buf_size;
            err = deflate(z,Z_PARTIAL_FLUSH);
            byteswritten += fwrite(buf,1,buf_size-z->avail_out,mat->fp);

            /* exit early if this is a empty data */
            if ( NULL == data || N < 1 )
                break;

            z->next_in   = data;
            z->avail_in  = data_size*N;
            do {
                z->next_out  = buf;
                z->avail_out = buf_size;
                err = deflate(z,Z_PARTIAL_FLUSH);
                byteswritten += fwrite(buf,1,buf_size-z->avail_out,mat->fp);
            } while ( z->avail_out == 0 );
            /* Add/Compress padding to pad to 8-byte boundary */
            if ( N*data_size % 8 ) {
                z->next_in   = pad;
                z->avail_in  = 8 - (N*data_size % 8);
                z->next_out  = buf;
                z->avail_out = buf_size;
                err = deflate(z,Z_PARTIAL_FLUSH);
                byteswritten += fwrite(buf,1,buf_size-z->avail_out,mat->fp);
            }
            break;
        }
        case MAT_T_INT8:
        case MAT_T_UINT8:
        {
            mat_uint8_t *ptr;
            mat_uint16_t c;

            /* Matlab can't read MAT_C_CHAR as uint8, needs uint16 */
            data_size    = 2;
            data_tag[0]  = MAT_T_UINT16;
            data_tag[1]  = N*data_size;
            z->next_in   = ZLIB_BYTE_PTR(data_tag);
            z->avail_in  = 8;
            z->next_out  = buf;
            z->avail_out = buf_size;
            err = deflate(z,Z_PARTIAL_FLUSH);
            byteswritten += fwrite(buf,1,buf_size-z->avail_out,mat->fp);

            /* exit early if this is a empty data */
            if ( NULL == data || N < 1 )
                break;

            z->next_in   = data;
            z->avail_in  = data_size*N;
            ptr = data;
            for ( i = 0; i < N; i++ ) {
                c = (mat_uint16_t)*(char *)ptr;
                z->next_in   = ZLIB_BYTE_PTR(&c);
                z->avail_in  = 2;
                z->next_out  = buf;
                z->avail_out = buf_size;
                err = deflate(z,Z_PARTIAL_FLUSH);
                byteswritten += fwrite(buf,1,buf_size-z->avail_out,mat->fp);
                ptr++;
            }
            /* Add/Compress padding to pad to 8-byte boundary */
            if ( N*data_size % 8 ) {
                z->next_in   = pad;
                z->avail_in  = 8 - (N*data_size % 8);
                z->next_out  = buf;
                z->avail_out = buf_size;
                err = deflate(z,Z_PARTIAL_FLUSH);
                byteswritten += fwrite(buf,1,buf_size-z->avail_out,mat->fp);
            }
            break;
        }
        case MAT_T_UTF8:
        {
            data_size = 1;
            data_tag[0]  = MAT_T_UTF8;
            data_tag[1]  = N*data_size;
            z->next_in   = ZLIB_BYTE_PTR(data_tag);
            z->avail_in  = 8;
            z->next_out  = buf;
            z->avail_out = buf_size;
            err = deflate(z,Z_PARTIAL_FLUSH);
            byteswritten += fwrite(buf,1,buf_size-z->avail_out,mat->fp);

            /* exit early if this is a empty data */
            if ( NULL == data || N < 1 )
                break;

            z->next_in   = data;
            z->avail_in  = data_size*N;
            do {
                z->next_out  = buf;
                z->avail_out = buf_size;
                err = deflate(z,Z_PARTIAL_FLUSH);
                byteswritten += fwrite(buf,1,buf_size-z->avail_out,mat->fp);
            } while ( z->avail_out == 0 );
            /* Add/Compress padding to pad to 8-byte boundary */
            if ( N*data_size % 8 ) {
                z->next_in   = pad;
                z->avail_in  = 8 - (N*data_size % 8);
                z->next_out  = buf;
                z->avail_out = buf_size;
                err = deflate(z,Z_PARTIAL_FLUSH);
                byteswritten += fwrite(buf,1,buf_size-z->avail_out,mat->fp);
            }
            break;
        }
        case MAT_T_UNKNOWN:
        {
            /* Sometimes empty char data will have MAT_T_UNKNOWN, so just write
             * a data tag
             */
            data_size = 2;
            data_tag[0]  = MAT_T_UINT16;
            data_tag[1]  = N*data_size;
            z->next_in   = ZLIB_BYTE_PTR(data_tag);
            z->avail_in  = 8;
            z->next_out  = buf;
            z->avail_out = buf_size;
            err = deflate(z,Z_PARTIAL_FLUSH);
            byteswritten += fwrite(buf,1,buf_size-z->avail_out,mat->fp);
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
static int
WriteEmptyCharData(mat_t *mat, int N, enum matio_types data_type)
{
    int nBytes = 0, bytesread = 0, i;
    mat_int8_t pad1 = 0;

    switch ( data_type ) {
        case MAT_T_UINT8: /* Matlab MAT_C_CHAR needs uint16 */
        case MAT_T_INT8:  /* Matlab MAT_C_CHAR needs uint16 */
            data_type = MAT_T_UINT16;
        case MAT_T_UINT16:
        {
            mat_uint16_t u16 = 0;
            nBytes = N*sizeof(mat_uint16_t);
            fwrite(&data_type,sizeof(mat_int32_t),1,mat->fp);
            fwrite(&nBytes,sizeof(mat_int32_t),1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&u16,sizeof(mat_uint16_t),1,mat->fp);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,mat->fp);
            break;
        }
        case MAT_T_UTF8:
        {
            mat_uint8_t u8 = 0;
            nBytes = N;
            fwrite(&data_type,sizeof(mat_int32_t),1,mat->fp);
            fwrite(&nBytes,sizeof(mat_int32_t),1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&u8,sizeof(mat_uint8_t),1,mat->fp);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,mat->fp);
            break;
        }
        default:
            break;
    }
    bytesread+=nBytes;
    return bytesread;
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
static int
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
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&d,data_size,1,mat->fp);
            break;
        }
        case MAT_T_SINGLE:
        {
            float f = 0.0;

            data_size = sizeof(float);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&f,data_size,1,mat->fp);
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8 = 0;

            data_size = sizeof(mat_int8_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i8,data_size,1,mat->fp);
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8 = 0;

            data_size = sizeof(mat_uint8_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui8,data_size,1,mat->fp);
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16 = 0;

            data_size = sizeof(mat_int16_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i16,data_size,1,mat->fp);
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16 = 0;

            data_size = sizeof(mat_uint16_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui16,data_size,1,mat->fp);
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32 = 0;

            data_size = sizeof(mat_int32_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i32,data_size,1,mat->fp);
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32 = 0;

            data_size = sizeof(mat_uint32_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui32,data_size,1,mat->fp);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_T_INT64:
        {
            mat_int64_t i64 = 0;

            data_size = sizeof(mat_int64_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i64,data_size,1,mat->fp);
            break;
        }
#endif
#ifdef HAVE_MATIO_UINT64_T
        case MAT_T_UINT64:
        {
            mat_uint64_t ui64 = 0;

            data_size = sizeof(mat_uint64_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui64,data_size,1,mat->fp);
            break;
        }
#endif
        default:
            nBytes = 0;
    }
    return nBytes;
}

#if defined(HAVE_ZLIB)
static int
WriteCompressedEmptyData(mat_t *mat,z_stream *z,int N,
    enum matio_types data_type)
{
    int nBytes = 0, data_size, i, err, byteswritten = 0;

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
            z->next_out  = ZLIB_BYTE_PTR(comp_buf);
            z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
            z->avail_out = 32*sizeof(*comp_buf);
            z->avail_in  = 8;
            err = deflate(z,Z_PARTIAL_FLUSH);
            byteswritten += fwrite(comp_buf,1,32*sizeof(*comp_buf)-z->avail_out,mat->fp);
            for ( i = 0; i < N; i++ ) {
                z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                z->next_in   = ZLIB_BYTE_PTR(data_uncomp_buf);
                z->avail_out = 32*sizeof(*comp_buf);
                z->avail_in  = 8;
                err = deflate(z,Z_PARTIAL_FLUSH);
                byteswritten += fwrite(comp_buf,32*sizeof(*comp_buf)-z->avail_out,1,mat->fp);
            }
            break;
        }
        case MAT_T_SINGLE:
        {
            float f = 0.0;

            data_size = sizeof(float);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&f,data_size,1,mat->fp);
            break;
        }
        case MAT_T_INT8:
        {
            mat_int8_t i8 = 0;

            data_size = sizeof(mat_int8_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i8,data_size,1,mat->fp);
            break;
        }
        case MAT_T_UINT8:
        {
            mat_uint8_t ui8 = 0;

            data_size = sizeof(mat_uint8_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui8,data_size,1,mat->fp);
            break;
        }
        case MAT_T_INT16:
        {
            mat_int16_t i16 = 0;

            data_size = sizeof(mat_int16_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i16,data_size,1,mat->fp);
            break;
        }
        case MAT_T_UINT16:
        {
            mat_uint16_t ui16 = 0;

            data_size = sizeof(mat_uint16_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui16,data_size,1,mat->fp);
            break;
        }
        case MAT_T_INT32:
        {
            mat_int32_t i32 = 0;

            data_size = sizeof(mat_int32_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i32,data_size,1,mat->fp);
            break;
        }
        case MAT_T_UINT32:
        {
            mat_uint32_t ui32 = 0;

            data_size = sizeof(mat_uint32_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui32,data_size,1,mat->fp);
            break;
        }
#ifdef HAVE_MATIO_INT64_T
        case MAT_T_INT64:
        {
            mat_int64_t i64 = 0;

            data_size = sizeof(mat_int64_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&i64,data_size,1,mat->fp);
            break;
        }
#endif
#ifdef HAVE_MATIO_UINT64_T
        case MAT_T_UINT64:
        {
            mat_uint64_t ui64 = 0;

            data_size = sizeof(mat_uint64_t);
            nBytes = N*data_size;
            fwrite(&data_type,4,1,mat->fp);
            fwrite(&nBytes,4,1,mat->fp);
            for ( i = 0; i < N; i++ )
                fwrite(&ui64,data_size,1,mat->fp);
            break;
        }
#endif
        default:
            nBytes = 0;
    }
    return byteswritten;
}
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
 * @return number of byteswritten
 * @endif
 */
int
WriteDataSlab2(mat_t *mat,void *data,enum matio_types data_type,size_t *dims,
    int *start,int *stride,int *edge)
{
    int nBytes = 0, data_size, i, j;
    long pos, row_stride, col_stride;

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

            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,mat->fp);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
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

            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,mat->fp);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
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

            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,mat->fp);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
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

            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,mat->fp);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
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

            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,mat->fp);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
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

            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,mat->fp);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
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

            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,mat->fp);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
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

            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,mat->fp);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
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

            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,mat->fp);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
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

            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,mat->fp);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
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
 * @return number of byteswritten
 * @endif
 */
int
WriteCharDataSlab2(mat_t *mat,void *data,enum matio_types data_type,
    size_t *dims,int *start,int *stride,int *edge)
{
    int nBytes = 0, data_size, i, j;
    long pos, row_stride, col_stride;

    if ( (mat   == NULL) || (data   == NULL) || (mat->fp == NULL) ||
         (start == NULL) || (stride == NULL) || (edge    == NULL) ) {
        return 0;
    }

    switch ( data_type ) {
        case MAT_T_UINT16:
        {
            mat_uint16_t *ptr;

            data_size = sizeof(mat_uint16_t);
            ptr = data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++ ) {
                    fwrite(ptr++,data_size,1,mat->fp);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
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
            ptr = data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++,ptr++ ) {
                    c = *ptr;
                    fwrite(&c,data_size,1,mat->fp);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
            }
            break;
        }
        case MAT_T_UTF8:
        {
            mat_uint8_t *ptr;

            data_size = sizeof(mat_uint8_t);
            ptr = data;
            row_stride = (stride[0]-1)*data_size;
            col_stride = stride[1]*dims[0]*data_size;

            fseek(mat->fp,start[1]*dims[0]*data_size,SEEK_CUR);
            for ( i = 0; i < edge[1]; i++ ) {
                pos = ftell(mat->fp);
                fseek(mat->fp,start[0]*data_size,SEEK_CUR);
                for ( j = 0; j < edge[0]; j++,ptr++ ) {
                    fwrite(ptr,data_size,1,mat->fp);
                    fseek(mat->fp,row_stride,SEEK_CUR);
                }
                pos = pos+col_stride-ftell(mat->fp);
                fseek(mat->fp,pos,SEEK_CUR);
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
int
WriteData(mat_t *mat,void *data,int N,enum matio_types data_type)
{
    int nBytes = 0, data_size;

    if ((mat == NULL) || (mat->fp == NULL) )
        return 0;

    data_size = Mat_SizeOf(data_type);
    nBytes    = N*data_size;
    fwrite(&data_type,4,1,mat->fp);
    fwrite(&nBytes,4,1,mat->fp);

    if ( data != NULL && N > 0 )
        fwrite(data,data_size,N,mat->fp);

    return nBytes;
}

#if defined(HAVE_ZLIB)
/* Compresses the data buffer and writes it to the file */
static size_t
WriteCompressedData(mat_t *mat,z_stream *z,void *data,int N,
    enum matio_types data_type)
{
    int nBytes = 0, data_size, data_tag[2], err, byteswritten = 0;
    int buf_size = 1024;
    mat_uint8_t   buf[1024], pad[8] = {0,};

    if ((mat == NULL) || (mat->fp == NULL))
        return 0;

    data_size = Mat_SizeOf(data_type);

    data_tag[0]  = data_type;
    data_tag[1]  = data_size*N;
    z->next_in   = ZLIB_BYTE_PTR(data_tag);
    z->avail_in  = 8;
    z->next_out  = buf;
    z->avail_out = buf_size;
    err = deflate(z,Z_PARTIAL_FLUSH);
    byteswritten += fwrite(buf,1,buf_size-z->avail_out,mat->fp);

    /* exit early if this is a empty data */
    if ( NULL == data || N < 1 )
        return byteswritten;

    z->next_in   = data;
    z->avail_in  = N*data_size;
    do {
        z->next_out  = buf;
        z->avail_out = buf_size;
        err = deflate(z,Z_PARTIAL_FLUSH);
        byteswritten += fwrite(buf,1,buf_size-z->avail_out,mat->fp);
    } while ( z->avail_out == 0 );
    /* Add/Compress padding to pad to 8-byte boundary */
    if ( N*data_size % 8 ) {
        z->next_in   = pad;
        z->avail_in  = 8 - (N*data_size % 8);
        z->next_out  = buf;
        z->avail_out = buf_size;
        err = deflate(z,Z_PARTIAL_FLUSH);
        byteswritten += fwrite(buf,1,buf_size-z->avail_out,mat->fp);
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
static int
ReadNextCell( mat_t *mat, matvar_t *matvar )
{
    int ncells, bytesread = 0, i;
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

            cells[i]->internal->fpos = ftell(mat->fp)-matvar->internal->z->avail_in;

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
            cells[i]->compression = 1;
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
                cells[i]->dims = malloc(cells[i]->rank*sizeof(*cells[i]->dims));
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
                    cells[i]->name = malloc(len+1);
                    /* Inflate variable name */
                    bytesread += InflateVarName(mat,matvar,cells[i]->name,len);
                    cells[i]->name[len] = '\0';
                    nbytes -= len;
                } else if ( ((uncomp_buf[0] & 0x0000ffff) == MAT_T_INT8) &&
                           ((uncomp_buf[0] & 0xffff0000) != 0x00) ) {
                    /* Name packed in tag */
                    len = (uncomp_buf[0] & 0xffff0000) >> 16;
                    cells[i]->name = malloc(len+1);
                    memcpy(cells[i]->name,uncomp_buf+1,len);
                    cells[i]->name[len] = '\0';
                }
            }
            cells[i]->internal->z = calloc(1,sizeof(z_stream));
            err = inflateCopy(cells[i]->internal->z,matvar->internal->z);
            if ( err != Z_OK )
                Mat_Critical("inflateCopy returned error %d",err);
            cells[i]->internal->datapos = ftell(mat->fp)-matvar->internal->z->avail_in;
            if ( cells[i]->class_type == MAT_C_STRUCT )
                bytesread+=ReadNextStructField(mat,cells[i]);
            else if ( cells[i]->class_type == MAT_C_CELL )
                bytesread+=ReadNextCell(mat,cells[i]);
            fseek(mat->fp,cells[i]->internal->datapos,SEEK_SET);
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

            cells[i]->internal->fpos = ftell(mat->fp);

            /* Read variable tag for cell */
            cell_bytes_read = fread(buf,4,2,mat->fp);

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
                Mat_Critical("cells[%d] not MAT_T_MATRIX, fpos = %ld",i,ftell(mat->fp));
                break;
            }
            cells[i]->compression = 0;
#if defined(HAVE_ZLIB)
            cells[i]->internal->z = NULL;
#endif

            /* Read Array Flags and The Dimensions Tag */
            bytesread  += fread(buf,4,6,mat->fp);
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
                cells[i]->dims = malloc(cells[i]->rank*sizeof(*cells[i]->dims));

                /* Assumes rank <= 16 */
                if ( cells[i]->rank % 2 != 0 ) {
                    bytesread+=fread(buf,4,cells[i]->rank+1,mat->fp);
                    nBytes-=4;
                } else
                    bytesread+=fread(buf,4,cells[i]->rank,mat->fp);

                if ( mat->byteswap ) {
                    for ( j = 0; j < cells[i]->rank; j++ )
                        cells[i]->dims[j] = Mat_uint32Swap(buf+j);
                } else {
                    for ( j = 0; j < cells[i]->rank; j++ )
                        cells[i]->dims[j] = buf[j];
                }
            }
            /* Variable Name Tag */
            bytesread+=fread(buf,1,8,mat->fp);
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
                    fseek(mat->fp,name_len,SEEK_CUR);
                }
            }
            cells[i]->internal->datapos = ftell(mat->fp);
            if ( cells[i]->class_type == MAT_C_STRUCT )
                bytesread+=ReadNextStructField(mat,cells[i]);
            if ( cells[i]->class_type == MAT_C_CELL )
                bytesread+=ReadNextCell(mat,cells[i]);
            fseek(mat->fp,cells[i]->internal->datapos+nBytes,SEEK_SET);
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
static int
ReadNextStructField( mat_t *mat, matvar_t *matvar )
{
    int fieldname_size,nfields, bytesread = 0, nmemb = 1, i;
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
            ptr = malloc(nfields*fieldname_size+i);
            bytesread += InflateFieldNames(mat,matvar,ptr,nfields,fieldname_size,i);
            matvar->internal->num_fields = nfields;
            matvar->internal->fieldnames =
                calloc(nfields,sizeof(*matvar->internal->fieldnames));
            for ( i = 0; i < nfields; i++ ) {
                matvar->internal->fieldnames[i] = malloc(fieldname_size);
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

        fields = matvar->data;
        for ( i = 0; i < nmemb; i++ ) {
            for ( j = 0; j < nfields; j++ ) {
                fields[i*nfields+j] = Mat_VarCalloc();
                fields[i*nfields+j]->name = mat_strdup(matvar->internal->fieldnames[j]);
            }
        }

        for ( i = 0; i < nmemb*nfields; i++ ) {
            fields[i]->internal->fpos = ftell(mat->fp)-matvar->internal->z->avail_in;
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
                fields[i]->dims = malloc(fields[i]->rank*
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
            fields[i]->internal->z = calloc(1,sizeof(z_stream));
            err = inflateCopy(fields[i]->internal->z,matvar->internal->z);
            if ( err != Z_OK ) {
                Mat_Critical("inflateCopy returned error %d",err);
            }
            fields[i]->internal->datapos = ftell(mat->fp)-matvar->internal->z->avail_in;
            if ( fields[i]->class_type == MAT_C_STRUCT )
                bytesread+=ReadNextStructField(mat,fields[i]);
            else if ( fields[i]->class_type == MAT_C_CELL )
                bytesread+=ReadNextCell(mat,fields[i]);
            fseek(mat->fp,fields[i]->internal->datapos,SEEK_SET);
            bytesread+=InflateSkip(mat,matvar->internal->z,nbytes);
        }
#else
        Mat_Critical("Not compiled with zlib support");
#endif
    } else {
        mat_uint32_t buf[16] = {0,};
        int      nbytes,nBytes,j;
        mat_uint32_t array_flags;

        bytesread+=fread(buf,4,2,mat->fp);
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
        bytesread+=fread(buf,4,2,mat->fp);
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
                calloc(nfields,sizeof(*matvar->internal->fieldnames));
            for ( i = 0; i < nfields; i++ ) {
                matvar->internal->fieldnames[i] = malloc(fieldname_size);
                bytesread+=fread(matvar->internal->fieldnames[i],1,fieldname_size,mat->fp);
                matvar->internal->fieldnames[i][fieldname_size-1] = '\0';
            }
        } else {
            matvar->internal->num_fields = 0;
            matvar->internal->fieldnames = NULL;
        }

        if ( (nfields*fieldname_size) % 8 ) {
            fseek(mat->fp,8-((nfields*fieldname_size) % 8),SEEK_CUR);
            bytesread+=8-((nfields*fieldname_size) % 8);
        }

        matvar->nbytes = nmemb*nfields*matvar->data_size;
        if ( !matvar->nbytes )
            return bytesread;

        matvar->data = malloc(matvar->nbytes);
        if ( !matvar->data )
            return bytesread;

        fields = matvar->data;
        for ( i = 0; i < nmemb; i++ ) {
            for ( j = 0; j < nfields; j++ ) {
                fields[i*nfields+j] = Mat_VarCalloc();
                fields[i*nfields+j]->name = mat_strdup(matvar->internal->fieldnames[j]);
            }
        }

        for ( i = 0; i < nmemb*nfields; i++ ) {

            fields[i]->internal->fpos = ftell(mat->fp);

            /* Read variable tag for struct field */
            bytesread += fread(buf,4,2,mat->fp);
            if ( mat->byteswap ) {
                (void)Mat_uint32Swap(buf);
                (void)Mat_uint32Swap(buf+1);
            }
            nBytes = buf[1];
            if ( buf[0] != MAT_T_MATRIX ) {
                Mat_VarFree(fields[i]);
                fields[i] = NULL;
                Mat_Critical("fields[%d] not MAT_T_MATRIX, fpos = %ld",i,ftell(mat->fp));
                return bytesread;
            } else if ( nBytes == 0 ) {
                fields[i]->rank = 0;
                continue;
            }
            fields[i]->compression = 0;
#if defined(HAVE_ZLIB)
            fields[i]->internal->z = NULL;
#endif

            /* Read Array Flags and The Dimensions Tag */
            bytesread  += fread(buf,4,6,mat->fp);
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
                fields[i]->dims = malloc(fields[i]->rank*
                                         sizeof(*fields[i]->dims));

                /* Assumes rank <= 16 */
                if ( fields[i]->rank % 2 != 0 ) {
                    bytesread+=fread(buf,4,fields[i]->rank+1,mat->fp);
                    nBytes-=4;
                } else
                    bytesread+=fread(buf,4,fields[i]->rank,mat->fp);

                if ( mat->byteswap ) {
                    for ( j = 0; j < fields[i]->rank; j++ )
                        fields[i]->dims[j] = Mat_uint32Swap(buf+j);
                } else {
                    for ( j = 0; j < fields[i]->rank; j++ )
                        fields[i]->dims[j] = buf[j];
                }
            }
            /* Variable Name Tag */
            bytesread+=fread(buf,1,8,mat->fp);
            nBytes-=8;
            fields[i]->internal->datapos = ftell(mat->fp);
            if ( fields[i]->class_type == MAT_C_STRUCT )
                bytesread+=ReadNextStructField(mat,fields[i]);
            else if ( fields[i]->class_type == MAT_C_CELL )
                bytesread+=ReadNextCell(mat,fields[i]);
            fseek(mat->fp,fields[i]->internal->datapos+nBytes,SEEK_SET);
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
static int
ReadNextFunctionHandle(mat_t *mat, matvar_t *matvar)
{
    int nfunctions = 1, bytesread = 0, i;
    matvar_t **functions = NULL;

    for ( i = 0; i < matvar->rank; i++ )
        nfunctions *= matvar->dims[i];

    matvar->data = malloc(nfunctions*sizeof(matvar_t *));
    if ( matvar->data != NULL ) {
        matvar->data_size = sizeof(matvar_t *);
        matvar->nbytes    = nfunctions*matvar->data_size;
        functions = matvar->data;
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

    fwrite(&matrix_type,4,1,mat->fp);
    fwrite(&pad4,4,1,mat->fp);
    start = ftell(mat->fp);

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
    fwrite(&array_flags_type,4,1,mat->fp);
    fwrite(&array_flags_size,4,1,mat->fp);
    fwrite(&array_flags,4,1,mat->fp);
    fwrite(&pad4,4,1,mat->fp);
    /* Rank and Dimension */
    nBytes = matvar->rank * 4;
    fwrite(&dims_array_type,4,1,mat->fp);
    fwrite(&nBytes,4,1,mat->fp);
    for ( i = 0; i < matvar->rank; i++ ) {
        mat_int32_t dim;
        dim = matvar->dims[i];
        nmemb *= dim;
        fwrite(&dim,4,1,mat->fp);
    }
    if ( matvar->rank % 2 != 0 )
        fwrite(&pad4,4,1,mat->fp);
    /* Name of variable */
    if ( !matvar->name ) {
        fwrite(&array_name_type,2,1,mat->fp);
        fwrite(&pad1,1,1,mat->fp);
        fwrite(&pad1,1,1,mat->fp);
        fwrite(&pad4,4,1,mat->fp);
    } else if ( strlen(matvar->name) <= 4 ) {
        mat_int16_t array_name_len = (mat_int16_t)strlen(matvar->name);
        mat_int8_t  pad1 = 0;
        fwrite(&array_name_type,2,1,mat->fp);
        fwrite(&array_name_len,2,1,mat->fp);
        fwrite(matvar->name,1,array_name_len,mat->fp);
        for ( i = array_name_len; i < 4; i++ )
            fwrite(&pad1,1,1,mat->fp);
    } else {
        mat_int32_t array_name_len = (mat_int32_t)strlen(matvar->name);
        mat_int8_t  pad1 = 0;

        fwrite(&array_name_type,2,1,mat->fp);
        fwrite(&pad1,1,1,mat->fp);
        fwrite(&pad1,1,1,mat->fp);
        fwrite(&array_name_len,4,1,mat->fp);
        fwrite(matvar->name,1,array_name_len,mat->fp);
        if ( array_name_len % 8 )
            for ( i = array_name_len % 8; i < 8; i++ )
                fwrite(&pad1,1,1,mat->fp);
    }

    matvar->internal->datapos = ftell(mat->fp);
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
                    fwrite(&pad1,1,1,mat->fp);
            if ( matvar->isComplex ) {
                nBytes = WriteEmptyData(mat,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
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
    end = ftell(mat->fp);
    nBytes = (int)(end-start);
    fseek(mat->fp,(long)-(nBytes+4),SEEK_CUR);
    fwrite(&nBytes,4,1,mat->fp);
    fseek(mat->fp,end,SEEK_SET);
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

    fwrite(&matrix_type,4,1,mat->fp);
    fwrite(&pad4,4,1,mat->fp);
    start = ftell(mat->fp);

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
    fwrite(&array_flags_type,4,1,mat->fp);
    fwrite(&array_flags_size,4,1,mat->fp);
    fwrite(&array_flags,4,1,mat->fp);
    fwrite(&nzmax,4,1,mat->fp);
    /* Rank and Dimension */
    nBytes = matvar->rank * 4;
    fwrite(&dims_array_type,4,1,mat->fp);
    fwrite(&nBytes,4,1,mat->fp);
    for ( i = 0; i < matvar->rank; i++ ) {
        mat_int32_t dim;
        dim = matvar->dims[i];
        nmemb *= dim;
        fwrite(&dim,4,1,mat->fp);
    }
    if ( matvar->rank % 2 != 0 )
        fwrite(&pad4,4,1,mat->fp);
    /* Name of variable */
    if ( !matvar->name ) {
        fwrite(&array_name_type,2,1,mat->fp);
        fwrite(&pad1,1,1,mat->fp);
        fwrite(&pad1,1,1,mat->fp);
        fwrite(&pad4,4,1,mat->fp);
    } else if ( strlen(matvar->name) <= 4 ) {
        mat_int16_t array_name_len = (mat_int16_t)strlen(matvar->name);
        mat_int8_t  pad1 = 0;
        fwrite(&array_name_type,2,1,mat->fp);
        fwrite(&array_name_len,2,1,mat->fp);
        fwrite(matvar->name,1,array_name_len,mat->fp);
        for ( i = array_name_len; i < 4; i++ )
            fwrite(&pad1,1,1,mat->fp);
    } else {
        mat_int32_t array_name_len = (mat_int32_t)strlen(matvar->name);
        mat_int8_t  pad1 = 0;

        fwrite(&array_name_type,2,1,mat->fp);
        fwrite(&pad1,1,1,mat->fp);
        fwrite(&pad1,1,1,mat->fp);
        fwrite(&array_name_len,4,1,mat->fp);
        fwrite(matvar->name,1,array_name_len,mat->fp);
        if ( array_name_len % 8 )
            for ( i = array_name_len % 8; i < 8; i++ )
                fwrite(&pad1,1,1,mat->fp);
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
                mat_complex_split_t *complex_data = matvar->data;

                if ( NULL == matvar->data )
                    complex_data = &null_complex_data;

                nBytes=WriteData(mat,complex_data->Re,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
                nBytes=WriteData(mat,complex_data->Im,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
            } else {
                nBytes = WriteData(mat,matvar->data,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
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
            fwrite(&fieldname_type,2,1,mat->fp);
            fwrite(&fieldname_data_size,2,1,mat->fp);
#else
            fieldname = (fieldname_data_size<<16) | fieldname_type;
            fwrite(&fieldname,4,1,mat->fp);
#endif
            fwrite(&fieldname_size,4,1,mat->fp);
            fwrite(&array_name_type,2,1,mat->fp);
            fwrite(&pad1,1,1,mat->fp);
            fwrite(&pad1,1,1,mat->fp);
            nBytes = nfields*fieldname_size;
            fwrite(&nBytes,4,1,mat->fp);
            padzero = calloc(fieldname_size,1);
            for ( i = 0; i < nfields; i++ ) {
                size_t len = strlen(matvar->internal->fieldnames[i]);
                fwrite(matvar->internal->fieldnames[i],1,len,mat->fp);
                fwrite(padzero,1,fieldname_size-len,mat->fp);
            }
            free(padzero);
            for ( i = 0; i < nmemb*nfields; i++ )
                WriteStructField(mat,fields[i]);
            break;
        }
        case MAT_C_SPARSE:
        {
            mat_sparse_t *sparse = matvar->data;

            nBytes = WriteData(mat,sparse->ir,sparse->nir,MAT_T_INT32);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,mat->fp);
            nBytes = WriteData(mat,sparse->jc,sparse->njc,MAT_T_INT32);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,mat->fp);
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = sparse->data;
                nBytes = WriteData(mat,complex_data->Re,sparse->ndata,
                                   matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
                nBytes = WriteData(mat,complex_data->Im,sparse->ndata,
                                   matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
            } else {
                nBytes = WriteData(mat,sparse->data,sparse->ndata,
                                   matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
            }
        }
        case MAT_C_FUNCTION:
        case MAT_C_OBJECT:
        case MAT_C_EMPTY:
            break;
    }
    end = ftell(mat->fp);
    nBytes = (int)(end-start);
    fseek(mat->fp,(long)-(nBytes+4),SEEK_CUR);
    fwrite(&nBytes,4,1,mat->fp);
    fseek(mat->fp,end,SEEK_SET);
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
WriteCompressedCellArrayField(mat_t *mat,matvar_t *matvar,z_stream *z)
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
    int buf_size = 512, err;
    size_t byteswritten = 0;

    if ( NULL == matvar || NULL == mat || NULL == z)
        return 0;

    start = ftell(mat->fp);

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
    z->next_out  = ZLIB_BYTE_PTR(comp_buf);
    z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_out = buf_size*sizeof(*comp_buf);
    z->avail_in  = 8;
    err = deflate(z,Z_PARTIAL_FLUSH);
    byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-z->avail_out,
        mat->fp);
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

    z->next_out  = ZLIB_BYTE_PTR(comp_buf);
    z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_out = buf_size*sizeof(*comp_buf);
    z->avail_in  = (6+i)*sizeof(*uncomp_buf);
    err = deflate(z,Z_PARTIAL_FLUSH);
    byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-z->avail_out,
        mat->fp);
    /* Name of variable */
    uncomp_buf[0] = array_name_type;
    uncomp_buf[1] = 0;
    z->next_out  = ZLIB_BYTE_PTR(comp_buf);
    z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_out = buf_size*sizeof(*comp_buf);
    z->avail_in  = 8;
    err = deflate(z,Z_PARTIAL_FLUSH);
    byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-z->avail_out,
        mat->fp);

    matvar->internal->datapos = ftell(mat->fp);
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
                mat_complex_split_t *complex_data = matvar->data;

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

            /* Check for a structure with no fields */
            if ( matvar->nbytes == 0 || matvar->data_size == 0 ||
                 matvar->data   == NULL ) {
                fieldname_size = 1;
                uncomp_buf[0] = (fieldname_data_size << 16) |
                                 fieldname_type;
                uncomp_buf[1] = 1;
                uncomp_buf[2] = array_name_type;
                uncomp_buf[3] = 0;
                z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
                z->avail_out = buf_size*sizeof(*comp_buf);
                z->avail_in  = 16;
                err = deflate(z,Z_PARTIAL_FLUSH);
                byteswritten += fwrite(comp_buf,1,buf_size*
                    sizeof(*comp_buf)-z->avail_out,mat->fp);
                break;
            }

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
            uncomp_buf[0] = (fieldname_data_size << 16) | fieldname_type;
            uncomp_buf[1] = fieldname_size;
            uncomp_buf[2] = array_name_type;
            uncomp_buf[3] = nfields*fieldname_size;

            padzero = calloc(fieldname_size,1);
            z->next_out  = ZLIB_BYTE_PTR(comp_buf);
            z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
            z->avail_out = buf_size*sizeof(*comp_buf);
            z->avail_in  = 16;
            err = deflate(z,Z_PARTIAL_FLUSH);
            byteswritten += fwrite(comp_buf,1,
                    buf_size*sizeof(*comp_buf)-z->avail_out,mat->fp);
            for ( i = 0; i < nfields; i++ ) {
                memset(padzero,'\0',fieldname_size);
                memcpy(padzero,matvar->internal->fieldnames[i],
                       strlen(matvar->internal->fieldnames[i]));
                z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                z->next_in   = ZLIB_BYTE_PTR(padzero);
                z->avail_out = buf_size*sizeof(*comp_buf);
                z->avail_in  = fieldname_size;
                err = deflate(z,Z_PARTIAL_FLUSH);
                byteswritten += fwrite(comp_buf,1,
                        buf_size*sizeof(*comp_buf)-z->avail_out,mat->fp);
            }
            free(padzero);
            for ( i = 0; i < nmemb*nfields; i++ )
                byteswritten +=
                    WriteCompressedStructField(mat,fields[i],z);
            break;
        }
        case MAT_C_SPARSE:
        {
            mat_sparse_t *sparse = matvar->data;

            byteswritten += WriteCompressedData(mat,z,sparse->ir,
                sparse->nir,MAT_T_INT32);
            byteswritten += WriteCompressedData(mat,z,sparse->jc,
                sparse->njc,MAT_T_INT32);
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = sparse->data;
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

    fwrite(&matrix_type,4,1,mat->fp);
    fwrite(&pad4,4,1,mat->fp);
    start = ftell(mat->fp);

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
    fwrite(&array_flags_type,4,1,mat->fp);
    fwrite(&array_flags_size,4,1,mat->fp);
    fwrite(&array_flags,4,1,mat->fp);
    fwrite(&nzmax,4,1,mat->fp);
    /* Rank and Dimension */
    nBytes = matvar->rank * 4;
    fwrite(&dims_array_type,4,1,mat->fp);
    fwrite(&nBytes,4,1,mat->fp);
    for ( i = 0; i < matvar->rank; i++ ) {
        mat_int32_t dim;
        dim = matvar->dims[i];
        nmemb *= dim;
        fwrite(&dim,4,1,mat->fp);
    }
    if ( matvar->rank % 2 != 0 )
        fwrite(&pad4,4,1,mat->fp);

    /* Name of variable */
    fwrite(&array_name_type,4,1,mat->fp);
    fwrite(&pad4,4,1,mat->fp);

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
                mat_complex_split_t *complex_data = matvar->data;

                if ( NULL == matvar->data )
                    complex_data = &null_complex_data;

                nBytes=WriteData(mat,complex_data->Re,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
                nBytes=WriteData(mat,complex_data->Im,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
            } else {
                nBytes=WriteData(mat,matvar->data,nmemb,matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
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
            fwrite(&fieldname_type,2,1,mat->fp);
            fwrite(&fieldname_data_size,2,1,mat->fp);
#else
            fieldname = (fieldname_data_size<<16) | fieldname_type;
            fwrite(&fieldname,4,1,mat->fp);
#endif
            fwrite(&fieldname_size,4,1,mat->fp);
            fwrite(&array_name_type,4,1,mat->fp);
            nBytes = nfields*fieldname_size;
            fwrite(&nBytes,4,1,mat->fp);
            padzero = calloc(fieldname_size,1);
            for ( i = 0; i < nfields; i++ ) {
                size_t len = strlen(matvar->internal->fieldnames[i]);
                fwrite(matvar->internal->fieldnames[i],1,len,mat->fp);
                fwrite(padzero,1,fieldname_size-len,mat->fp);
            }
            free(padzero);
            for ( i = 0; i < nmemb*nfields; i++ )
                WriteStructField(mat,fields[i]);
            break;
        }
        case MAT_C_SPARSE:
        {
            mat_sparse_t *sparse = matvar->data;

            nBytes = WriteData(mat,sparse->ir,sparse->nir,MAT_T_INT32);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,mat->fp);
            nBytes = WriteData(mat,sparse->jc,sparse->njc,MAT_T_INT32);
            if ( nBytes % 8 )
                for ( i = nBytes % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,mat->fp);
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = sparse->data;
                nBytes = WriteData(mat,complex_data->Re,sparse->ndata,
                                   matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
                nBytes = WriteData(mat,complex_data->Im,sparse->ndata,
                                   matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
            } else {
                nBytes = WriteData(mat,sparse->data,sparse->ndata,
                                   matvar->data_type);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
            }
        }
        case MAT_C_FUNCTION:
        case MAT_C_OBJECT:
        case MAT_C_EMPTY:
            break;
    }
    end = ftell(mat->fp);
    nBytes = (int)(end-start);
    fseek(mat->fp,(long)-(nBytes+4),SEEK_CUR);
    fwrite(&nBytes,4,1,mat->fp);
    fseek(mat->fp,end,SEEK_SET);
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
WriteCompressedStructField(mat_t *mat,matvar_t *matvar,z_stream *z)
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
    int buf_size = 512, err;
    size_t byteswritten = 0;

    if ( NULL == mat || NULL == z)
        return 1;

    if ( NULL == matvar ) {
        size_t dims[2] = {0,0};
        byteswritten = Mat_WriteCompressedEmptyVariable5(mat, NULL, 2, dims, z);
        return byteswritten;
    }
    start = ftell(mat->fp);

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
    z->next_out  = ZLIB_BYTE_PTR(comp_buf);
    z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_out = buf_size*sizeof(*comp_buf);
    z->avail_in  = 8;
    err = deflate(z,Z_PARTIAL_FLUSH);
    byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-z->avail_out,
        mat->fp);
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

    z->next_out  = ZLIB_BYTE_PTR(comp_buf);
    z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_out = buf_size*sizeof(*comp_buf);
    z->avail_in  = (6+i)*sizeof(*uncomp_buf);
    err = deflate(z,Z_PARTIAL_FLUSH);
    byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-z->avail_out,
        mat->fp);
    /* Name of variable */
    uncomp_buf[0] = array_name_type;
    uncomp_buf[1] = 0;
    z->next_out  = ZLIB_BYTE_PTR(comp_buf);
    z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_out = buf_size*sizeof(*comp_buf);
    z->avail_in  = 8;
    err = deflate(z,Z_PARTIAL_FLUSH);
    byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-z->avail_out,
        mat->fp);

    matvar->internal->datapos = ftell(mat->fp);
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
                mat_complex_split_t *complex_data = matvar->data;

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
                uncomp_buf[1] = 1;
                uncomp_buf[2] = array_name_type;
                uncomp_buf[3] = 0;
                z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
                z->avail_out = buf_size*sizeof(*comp_buf);
                z->avail_in  = 16;
                err = deflate(z,Z_PARTIAL_FLUSH);
                byteswritten += fwrite(comp_buf,1,buf_size*
                    sizeof(*comp_buf)-z->avail_out,mat->fp);
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

            padzero = calloc(fieldname_size,1);
            z->next_out  = ZLIB_BYTE_PTR(comp_buf);
            z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
            z->avail_out = buf_size*sizeof(*comp_buf);
            z->avail_in  = 16;
            err = deflate(z,Z_PARTIAL_FLUSH);
            byteswritten += fwrite(comp_buf,1,
                    buf_size*sizeof(*comp_buf)-z->avail_out,mat->fp);
            for ( i = 0; i < nfields; i++ ) {
                size_t len = strlen(matvar->internal->fieldnames[i]);
                memset(padzero,'\0',fieldname_size);
                memcpy(padzero,matvar->internal->fieldnames[i],len);
                z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                z->next_in   = ZLIB_BYTE_PTR(padzero);
                z->avail_out = buf_size*sizeof(*comp_buf);
                z->avail_in  = fieldname_size;
                err = deflate(z,Z_PARTIAL_FLUSH);
                byteswritten += fwrite(comp_buf,1,
                        buf_size*sizeof(*comp_buf)-z->avail_out,mat->fp);
            }
            free(padzero);
            for ( i = 0; i < nmemb*nfields; i++ )
                byteswritten +=
                    WriteCompressedStructField(mat,fields[i],z);
            break;
        }
        case MAT_C_SPARSE:
        {
            mat_sparse_t *sparse = matvar->data;

            byteswritten += WriteCompressedData(mat,z,sparse->ir,
                sparse->nir,MAT_T_INT32);
            byteswritten += WriteCompressedData(mat,z,sparse->jc,
                sparse->njc,MAT_T_INT32);
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = sparse->data;
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

    fwrite(&matrix_type,4,1,mat->fp);
    fwrite(&pad4,4,1,mat->fp);

    start = ftell(mat->fp);
    /* Array Flags */
    array_flags = MAT_C_DOUBLE;

    if ( mat->byteswap )
        array_flags = Mat_int32Swap((mat_int32_t*)&array_flags);
    byteswritten += fwrite(&array_flags_type,4,1,mat->fp);
    byteswritten += fwrite(&array_flags_size,4,1,mat->fp);
    byteswritten += fwrite(&array_flags,4,1,mat->fp);
    byteswritten += fwrite(&pad4,4,1,mat->fp);
    /* Rank and Dimension */
    nBytes = rank * 4;
    byteswritten += fwrite(&dims_array_type,4,1,mat->fp);
    byteswritten += fwrite(&nBytes,4,1,mat->fp);
    for ( i = 0; i < rank; i++ ) {
        mat_int32_t dim;
        dim = dims[i];
        nmemb *= dim;
        byteswritten += fwrite(&dim,4,1,mat->fp);
    }
    if ( rank % 2 != 0 )
        byteswritten += fwrite(&pad4,4,1,mat->fp);

    if ( NULL == name ) {
        /* Name of variable */
        byteswritten += fwrite(&array_name_type,4,1,mat->fp);
        byteswritten += fwrite(&pad4,4,1,mat->fp);
    } else {
        mat_int32_t  array_name_type = MAT_T_INT8;
        mat_int32_t  array_name_len   = strlen(name);
        /* Name of variable */
        if ( array_name_len <= 4 ) {
            mat_int8_t  pad1 = 0;
            array_name_type = (array_name_len << 16) | array_name_type;
            byteswritten += fwrite(&array_name_type,4,1,mat->fp);
            byteswritten += fwrite(name,1,array_name_len,mat->fp);
            for ( i = array_name_len; i < 4; i++ )
                byteswritten += fwrite(&pad1,1,1,mat->fp);
        } else {
            byteswritten += fwrite(&array_name_type,4,1,mat->fp);
            byteswritten += fwrite(&array_name_len,4,1,mat->fp);
            byteswritten += fwrite(name,1,array_name_len,mat->fp);
            if ( array_name_len % 8 )
                for ( i = array_name_len % 8; i < 8; i++ )
                    byteswritten += fwrite(&pad1,1,1,mat->fp);
        }
    }

    nBytes = WriteData(mat,NULL,0,MAT_T_DOUBLE);
    byteswritten += nBytes;
    if ( nBytes % 8 )
        for ( i = nBytes % 8; i < 8; i++ )
            byteswritten += fwrite(&pad1,1,1,mat->fp);

    end = ftell(mat->fp);
    nBytes = (int)(end-start);
    fseek(mat->fp,(long)-(nBytes+4),SEEK_CUR);
    fwrite(&nBytes,4,1,mat->fp);
    fseek(mat->fp,end,SEEK_SET);

    return byteswritten;
}

#if defined(HAVE_ZLIB)
static size_t
Mat_WriteCompressedEmptyVariable5(mat_t *mat,const char *name,int rank,
                                  size_t *dims,z_stream *z)
{
    mat_uint32_t array_flags = 0x0;
    mat_int16_t  array_name_type     = MAT_T_INT8;
    int      array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int      array_flags_size = 8, pad4 = 0;
    int      nBytes, i, nmemb = 1;

    mat_uint32_t comp_buf[512];
    mat_uint32_t uncomp_buf[512] = {0,};
    int buf_size = 512, err;
    size_t byteswritten = 0, buf_size_bytes;

    if ( NULL == mat || NULL == z)
        return 1;

    buf_size_bytes = buf_size*sizeof(*comp_buf);

    /* Array Flags */
    array_flags = MAT_C_DOUBLE;

    uncomp_buf[0] = MAT_T_MATRIX;
    uncomp_buf[1] = (int)GetEmptyMatrixMaxBufSize(name,rank);
    z->next_out  = ZLIB_BYTE_PTR(comp_buf);
    z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_out = buf_size_bytes;
    z->avail_in  = 8;
    err = deflate(z,Z_PARTIAL_FLUSH);
    byteswritten += fwrite(comp_buf,1,buf_size_bytes-z->avail_out,mat->fp);
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

    z->next_out  = ZLIB_BYTE_PTR(comp_buf);
    z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
    z->avail_out = buf_size_bytes;
    z->avail_in  = (6+i)*sizeof(*uncomp_buf);
    err = deflate(z,Z_PARTIAL_FLUSH);
    byteswritten += fwrite(comp_buf,1,buf_size_bytes-z->avail_out,mat->fp);
    /* Name of variable */
    if ( NULL == name ) {
        uncomp_buf[0] = array_name_type;
        uncomp_buf[1] = 0;
        z->next_out  = ZLIB_BYTE_PTR(comp_buf);
        z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
        z->avail_out = buf_size_bytes;
        z->avail_in  = 8;
        err = deflate(z,Z_PARTIAL_FLUSH);
        byteswritten += fwrite(comp_buf,1,buf_size_bytes-z->avail_out,mat->fp);
    } else {
        if ( strlen(name) <= 4 ) {
            mat_int16_t array_name_len = (mat_int16_t)strlen(name);
            mat_int16_t array_name_type = MAT_T_INT8;

            memset(uncomp_buf,0,8);
            uncomp_buf[0] = (array_name_len << 16) | array_name_type;
            memcpy(uncomp_buf+1,name,array_name_len);
            if ( array_name_len % 4 )
                array_name_len += 4-(array_name_len % 4);

            z->next_out  = ZLIB_BYTE_PTR(comp_buf);
            z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
            z->avail_out = buf_size_bytes;
            z->avail_in  = 8;
            err = deflate(z,Z_PARTIAL_FLUSH);
            byteswritten += fwrite(comp_buf,1,buf_size_bytes-z->avail_out,
                                   mat->fp);
        } else {
            mat_int32_t array_name_len = (mat_int32_t)strlen(name);
            mat_int32_t array_name_type = MAT_T_INT8;

            memset(uncomp_buf,0,buf_size*sizeof(*uncomp_buf));
            uncomp_buf[0] = array_name_type;
            uncomp_buf[1] = array_name_len;
            memcpy(uncomp_buf+2,name,array_name_len);
            if ( array_name_len % 8 )
                array_name_len += 8-(array_name_len % 8);
            z->next_out  = ZLIB_BYTE_PTR(comp_buf);
            z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
            z->avail_out = buf_size_bytes;
            z->avail_in  = 8+array_name_len;
            err = deflate(z,Z_PARTIAL_FLUSH);
            byteswritten += fwrite(comp_buf,1,buf_size_bytes-z->avail_out,
                                   mat->fp);
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
        size_t bytesread = fread(tag,4,1,mat->fp);
        if ( mat->byteswap )
            (void)Mat_uint32Swap(tag);
        packed_type = TYPE_FROM_TAG(tag[0]);
        if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
            data_in_tag = 1;
            nBytes = (tag[0] & 0xffff0000) >> 16;
        } else {
            data_in_tag = 0;
            bytesread = fread(tag+1,4,1,mat->fp);
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
                nBytes = ReadDoubleData(mat,data,packed_type,N);
                break;
            case MAT_C_SINGLE:
                nBytes = ReadSingleData(mat,data,packed_type,N);
                break;
            case MAT_C_INT64:
#ifdef HAVE_MATIO_INT64_T
                nBytes = ReadInt64Data(mat,data,packed_type,N);
#endif
                break;
            case MAT_C_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                nBytes = ReadUInt64Data(mat,data,packed_type,N);
#endif
                break;
            case MAT_C_INT32:
                nBytes = ReadInt32Data(mat,data,packed_type,N);
                break;
            case MAT_C_UINT32:
                nBytes = ReadUInt32Data(mat,data,packed_type,N);
                break;
            case MAT_C_INT16:
                nBytes = ReadInt16Data(mat,data,packed_type,N);
                break;
            case MAT_C_UINT16:
                nBytes = ReadUInt16Data(mat,data,packed_type,N);
                break;
            case MAT_C_INT8:
                nBytes = ReadInt8Data(mat,data,packed_type,N);
                break;
            case MAT_C_UINT8:
                nBytes = ReadUInt8Data(mat,data,packed_type,N);
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
            fseek(mat->fp,8-(nBytes % 8),SEEK_CUR);
#if defined(HAVE_ZLIB)
    } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
        switch ( matvar->class_type ) {
            case MAT_C_DOUBLE:
                nBytes = ReadCompressedDoubleData(mat,matvar->internal->z,data,
                                                  packed_type,N);
                break;
            case MAT_C_SINGLE:
                nBytes = ReadCompressedSingleData(mat,matvar->internal->z,data,
                                                  packed_type,N);
                break;
            case MAT_C_INT64:
#ifdef HAVE_MATIO_INT64_T
                nBytes = ReadCompressedInt64Data(mat,matvar->internal->z,data,
                                                 packed_type,N);
#endif
                break;
            case MAT_C_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                nBytes = ReadCompressedUInt64Data(mat,matvar->internal->z,data,
                                                  packed_type,N);
#endif
                break;
            case MAT_C_INT32:
                nBytes = ReadCompressedInt32Data(mat,matvar->internal->z,data,
                                                 packed_type,N);
                break;
            case MAT_C_UINT32:
                nBytes = ReadCompressedUInt32Data(mat,matvar->internal->z,data,
                                                  packed_type,N);
                break;
            case MAT_C_INT16:
                nBytes = ReadCompressedInt16Data(mat,matvar->internal->z,data,
                                                 packed_type,N);
                break;
            case MAT_C_UINT16:
                nBytes = ReadCompressedUInt16Data(mat,matvar->internal->z,data,
                                                  packed_type,N);
                break;
            case MAT_C_INT8:
                nBytes = ReadCompressedInt8Data(mat,matvar->internal->z,data,
                                                packed_type,N);
                break;
            case MAT_C_UINT8:
                nBytes = ReadCompressedUInt8Data(mat,matvar->internal->z,data,
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
void
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

    fpos = ftell(mat->fp);
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
            matvar->dims = malloc(matvar->rank*sizeof(*(matvar->dims)));
            matvar->dims[0] = 0;
            matvar->dims[1] = 0;
            break;
        case MAT_C_DOUBLE:
            fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(double);
            matvar->data_type = MAT_T_DOUBLE;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = malloc(sizeof(*complex_data));
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
            fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(float);
            matvar->data_type = MAT_T_SINGLE;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = malloc(sizeof(*complex_data));
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
            fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_int64_t);
            matvar->data_type = MAT_T_INT64;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = malloc(sizeof(*complex_data));
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
            fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_uint64_t);
            matvar->data_type = MAT_T_UINT64;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = malloc(sizeof(*complex_data));
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
            fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_int32_t);
            matvar->data_type = MAT_T_INT32;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = malloc(sizeof(*complex_data));
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
            fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_uint32_t);
            matvar->data_type = MAT_T_UINT32;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = malloc(sizeof(*complex_data));
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
            fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_int16_t);
            matvar->data_type = MAT_T_INT16;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = malloc(sizeof(*complex_data));
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
            fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_uint16_t);
            matvar->data_type = MAT_T_UINT16;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = malloc(sizeof(*complex_data));
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
            fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_int8_t);
            matvar->data_type = MAT_T_INT8;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = malloc(sizeof(*complex_data));
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
            fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
            matvar->data_size = sizeof(mat_uint8_t);
            matvar->data_type = MAT_T_UINT8;
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                matvar->nbytes = len*matvar->data_size;
                complex_data = malloc(sizeof(*complex_data));
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
                fseek(mat->fp,matvar->internal->datapos,SEEK_SET);

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
                fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
                bytesread = fread(tag,4,1,mat->fp);
                if ( byteswap )
                    (void)Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    nBytes = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    bytesread = fread(tag+1,4,1,mat->fp);
                    if ( byteswap )
                        (void)Mat_uint32Swap(tag+1);
                    nBytes = tag[1];
                }
            }
            if ( nBytes == 0 ) {
                matvar->nbytes = 0;
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
                    fseek(mat->fp,8-(nBytes % 8),SEEK_CUR);
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
            data = matvar->data;
            data->nzmax  = matvar->nbytes;
            fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
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
                bytesread = fread(tag,4,1,mat->fp);
                if ( mat->byteswap )
                    (void)Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    N = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    bytesread = fread(&N,4,1,mat->fp);
                    if ( mat->byteswap )
                        Mat_int32Swap(&N);
                }
            }
            data->nir = N / 4;
            data->ir = malloc(data->nir*sizeof(mat_int32_t));
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
                        fseek(mat->fp,8-(nBytes % 8),SEEK_CUR);
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
                bytesread = fread(tag,4,1,mat->fp);
                if ( mat->byteswap )
                    Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    N = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    bytesread = fread(&N,4,1,mat->fp);
                    if ( mat->byteswap )
                        Mat_int32Swap(&N);
                }
            }
            data->njc = N / 4;
            data->jc = malloc(data->njc*sizeof(mat_int32_t));
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
                        fseek(mat->fp,8-(nBytes % 8),SEEK_CUR);
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
                bytesread = fread(tag,4,1,mat->fp);
                if ( mat->byteswap )
                    Mat_uint32Swap(tag);
                packed_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                    data_in_tag = 1;
                    N = (tag[0] & 0xffff0000) >> 16;
                } else {
                    data_in_tag = 0;
                    bytesread = fread(&N,4,1,mat->fp);
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
            data->ndata = N / Mat_SizeOf(packed_type);
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data;

                complex_data = malloc(sizeof(*complex_data));
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
                            nBytes = ReadDoubleData(mat,complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadSingleData(mat,complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadInt64Data(mat,complex_data->Re,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadUInt64Data(mat,complex_data->Re,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadInt32Data(mat,complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadInt32Data(mat,complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadInt16Data(mat,complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadInt16Data(mat,complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadInt8Data(mat,complex_data->Re,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadInt8Data(mat,complex_data->Re,
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
                        fseek(mat->fp,8-(nBytes % 8),SEEK_CUR);

                    /* Complex Data Tag */
                    bytesread = fread(tag,4,1,mat->fp);
                    if ( byteswap )
                        (void)Mat_uint32Swap(tag);
                    packed_type = TYPE_FROM_TAG(tag[0]);
                    if ( tag[0] & 0xffff0000 ) { /* Data is in the tag */
                        data_in_tag = 1;
                        nBytes = (tag[0] & 0xffff0000) >> 16;
                    } else {
                        data_in_tag = 0;
                        bytesread = fread(tag+1,4,1,mat->fp);
                        if ( byteswap )
                            (void)Mat_uint32Swap(tag+1);
                        nBytes = tag[1];
                    }
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadDoubleData(mat,complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadSingleData(mat,complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadInt64Data(mat,complex_data->Im,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadUInt64Data(mat,complex_data->Im,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadInt32Data(mat,complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadUInt32Data(mat,complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadInt16Data(mat,complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadUInt16Data(mat,complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadInt8Data(mat,complex_data->Im,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadUInt8Data(mat,complex_data->Im,
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
                        fseek(mat->fp,8-(nBytes % 8),SEEK_CUR);
#if defined(HAVE_ZLIB)
                } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadCompressedDoubleData(mat,matvar->internal->z,
                                 complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadCompressedSingleData(mat,matvar->internal->z,
                                 complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadCompressedInt64Data(mat,
                                matvar->internal->z,complex_data->Re,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadCompressedUInt64Data(mat,
                                matvar->internal->z,complex_data->Re,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadCompressedInt32Data(mat,matvar->internal->z,
                                 complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadCompressedInt32Data(mat,matvar->internal->z,
                                 complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadCompressedInt16Data(mat,matvar->internal->z,
                                 complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadCompressedInt16Data(mat,matvar->internal->z,
                                 complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadCompressedInt8Data(mat,matvar->internal->z,
                                 complex_data->Re,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadCompressedInt8Data(mat,matvar->internal->z,
                                 complex_data->Re,packed_type,data->ndata);
                            break;
                        default:
                            break;
                    }
#else    /* EXTENDED_SPARSE */
                    nBytes = ReadCompressedDoubleData(mat,matvar->internal->z,
                                 complex_data->Re,packed_type,data->ndata);
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
                                 complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadCompressedSingleData(mat,matvar->internal->z,
                                 complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadCompressedInt64Data(mat,
                                matvar->internal->z,complex_data->Im,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadCompressedUInt64Data(mat,
                                matvar->internal->z,complex_data->Im,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadCompressedInt32Data(mat,matvar->internal->z,
                                 complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadCompressedUInt32Data(mat,matvar->internal->z,
                                 complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadCompressedInt16Data(mat,matvar->internal->z,
                                 complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadCompressedUInt16Data(mat,matvar->internal->z,
                                 complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadCompressedInt8Data(mat,matvar->internal->z,
                                 complex_data->Im,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadCompressedUInt8Data(mat,matvar->internal->z,
                                 complex_data->Im,packed_type,data->ndata);
                            break;
                        default:
                            break;
                    }
#else    /* EXTENDED_SPARSE */
                    nBytes = ReadCompressedDoubleData(mat,matvar->internal->z,
                                 complex_data->Im,packed_type,data->ndata);
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
                            nBytes = ReadDoubleData(mat,data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadSingleData(mat,data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadInt64Data(mat,data->data,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadUInt64Data(mat,data->data,
                                packed_type,data->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadInt32Data(mat,data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadInt32Data(mat,data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadInt16Data(mat,data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadInt16Data(mat,data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadInt8Data(mat,data->data,
                                packed_type,data->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadInt8Data(mat,data->data,
                                packed_type,data->ndata);
                            break;
                        default:
                            break;
                    }
#else
                    nBytes = ReadDoubleData(mat,data->data,packed_type,
                                 data->ndata);
#endif
                    if ( data_in_tag )
                        nBytes+=4;
                    if ( (nBytes % 8) != 0 )
                        fseek(mat->fp,8-(nBytes % 8),SEEK_CUR);
#if defined(HAVE_ZLIB)
                } else if ( matvar->compression == MAT_COMPRESSION_ZLIB) {
#if defined(EXTENDED_SPARSE)
                    switch ( matvar->data_type ) {
                        case MAT_T_DOUBLE:
                            nBytes = ReadCompressedDoubleData(mat,matvar->internal->z,
                                 data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_SINGLE:
                            nBytes = ReadCompressedSingleData(mat,matvar->internal->z,
                                 data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_INT64:
#ifdef HAVE_MATIO_INT64_T
                            nBytes = ReadCompressedInt64Data(mat,
                                matvar->internal->z,data->data,packed_type,
                                data->ndata);
#endif
                            break;
                        case MAT_T_UINT64:
#ifdef HAVE_MATIO_UINT64_T
                            nBytes = ReadCompressedUInt64Data(mat,
                                matvar->internal->z,data->data,packed_type,
                                data->ndata);
#endif
                            break;
                        case MAT_T_INT32:
                            nBytes = ReadCompressedInt32Data(mat,matvar->internal->z,
                                 data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT32:
                            nBytes = ReadCompressedInt32Data(mat,matvar->internal->z,
                                 data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_INT16:
                            nBytes = ReadCompressedInt16Data(mat,matvar->internal->z,
                                 data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT16:
                            nBytes = ReadCompressedInt16Data(mat,matvar->internal->z,
                                 data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_INT8:
                            nBytes = ReadCompressedInt8Data(mat,matvar->internal->z,
                                 data->data,packed_type,data->ndata);
                            break;
                        case MAT_T_UINT8:
                            nBytes = ReadCompressedInt8Data(mat,matvar->internal->z,
                                 data->data,packed_type,data->ndata);
                            break;
                        default:
                            break;
                    }
#else   /* EXTENDED_SPARSE */
                    nBytes = ReadCompressedDoubleData(mat,matvar->internal->z,
                                 data->data,packed_type,data->ndata);
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
            for ( i = 0; i < nfunctions; i++ ) {
                functions[i]->internal->fp = mat;
                Read5(mat,functions[i]);
            }
            /* FIXME: */
            matvar->data_type = MAT_T_FUNCTION;
            break;
        }
        default:
            Mat_Critical("Read5: %d is not a supported Class", matvar->class_type);
    }
    fseek(mat->fp,fpos,SEEK_SET);

    return;
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
ReadData5(mat_t *mat,matvar_t *matvar,void *data,
    int *start,int *stride,int *edge)
{
    int err = 0,real_bytes = 0;
    mat_int32_t tag[2];
    size_t bytesread = 0;
#if defined(HAVE_ZLIB)
    z_stream z;
#endif

    fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
    if ( matvar->compression == MAT_COMPRESSION_NONE ) {
        bytesread = fread(tag,4,2,mat->fp);
        if ( mat->byteswap ) {
            Mat_int32Swap(tag);
            Mat_int32Swap(tag+1);
        }
        matvar->data_type = TYPE_FROM_TAG(tag[0]);
        if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
            fseek(mat->fp,-4,SEEK_CUR);
            real_bytes = 4+(tag[0] >> 16);
        } else {
            real_bytes = 8+tag[1];
        }
#if defined(HAVE_ZLIB)
    } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
        err = inflateCopy(&z,matvar->internal->z);
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
                mat_complex_split_t *complex_data = data;

                ReadDataSlab2(mat,complex_data->Re,matvar->class_type,
                    matvar->data_type,matvar->dims,start,stride,edge);
                fseek(mat->fp,matvar->internal->datapos+real_bytes,SEEK_SET);
                bytesread = fread(tag,4,2,mat->fp);
                if ( mat->byteswap ) {
                    Mat_int32Swap(tag);
                    Mat_int32Swap(tag+1);
                }
                matvar->data_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
                    fseek(mat->fp,-4,SEEK_CUR);
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
                mat_complex_split_t *complex_data = data;

                ReadCompressedDataSlab2(mat,&z,complex_data->Re,
                    matvar->class_type,matvar->data_type,matvar->dims,
                    start,stride,edge);

                fseek(mat->fp,matvar->internal->datapos,SEEK_SET);

                /* Reset zlib knowledge to before reading real tag */
                inflateEnd(&z);
                err = inflateCopy(&z,matvar->internal->z);
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
                inflateEnd(&z);
            } else {
                ReadCompressedDataSlab2(mat,&z,data,matvar->class_type,
                    matvar->data_type,matvar->dims,start,stride,edge);
            }
        }
#endif
    } else {
        if ( matvar->compression == MAT_COMPRESSION_NONE ) {
            if ( matvar->isComplex ) {
                mat_complex_split_t *complex_data = data;

                ReadDataSlabN(mat,complex_data->Re,matvar->class_type,
                    matvar->data_type,matvar->rank,matvar->dims,
                    start,stride,edge);

                fseek(mat->fp,matvar->internal->datapos+real_bytes,SEEK_SET);
                bytesread = fread(tag,4,2,mat->fp);
                if ( mat->byteswap ) {
                    Mat_int32Swap(tag);
                    Mat_int32Swap(tag+1);
                }
                matvar->data_type = TYPE_FROM_TAG(tag[0]);
                if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
                    fseek(mat->fp,-4,SEEK_CUR);
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
                mat_complex_split_t *complex_data = data;

                ReadCompressedDataSlabN(mat,&z,complex_data->Re,
                    matvar->class_type,matvar->data_type,matvar->rank,
                    matvar->dims,start,stride,edge);

                fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
                /* Reset zlib knowledge to before reading real tag */
                inflateEnd(&z);
                err = inflateCopy(&z,matvar->internal->z);
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
                inflateEnd(&z);
            } else {
                ReadCompressedDataSlabN(mat,&z,data,matvar->class_type,
                    matvar->data_type,matvar->rank,matvar->dims,
                    start,stride,edge);
            }
        }
#endif
    }
    if ( err )
        return err;

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
    fseek(mat->fp,matvar->internal->datapos,SEEK_SET);
    if ( matvar->compression == MAT_COMPRESSION_NONE ) {
        bytesread = fread(tag,4,2,mat->fp);
        if ( mat->byteswap ) {
            Mat_int32Swap(tag);
            Mat_int32Swap(tag+1);
        }
        matvar->data_type = tag[0] & 0x000000ff;
        if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
            fseek(mat->fp,-4,SEEK_CUR);
            real_bytes = 4+(tag[0] >> 16);
        } else {
            real_bytes = 8+tag[1];
        }
#if defined(HAVE_ZLIB)
    } else if ( matvar->compression == MAT_COMPRESSION_ZLIB ) {
        matvar->internal->z->avail_in = 0;
        err = inflateCopy(&z,matvar->internal->z);
        InflateDataType(mat,&z,tag);
        if ( mat->byteswap ) {
            Mat_int32Swap(tag);
            Mat_int32Swap(tag+1);
        }
        matvar->data_type = tag[0] & 0x000000ff;
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
            mat_complex_split_t *complex_data = data;

            ReadDataSlab1(mat,complex_data->Re,matvar->class_type,
                          matvar->data_type,start,stride,edge);
            fseek(mat->fp,matvar->internal->datapos+real_bytes,SEEK_SET);
            bytesread = fread(tag,4,2,mat->fp);
            if ( mat->byteswap ) {
                Mat_int32Swap(tag);
                Mat_int32Swap(tag+1);
            }
            matvar->data_type = tag[0] & 0x000000ff;
            if ( tag[0] & 0xffff0000 ) { /* Data is packed in the tag */
                fseek(mat->fp,-4,SEEK_CUR);
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
            mat_complex_split_t *complex_data = data;

            ReadCompressedDataSlab1(mat,&z,complex_data->Re,
                matvar->class_type,matvar->data_type,start,stride,edge);

            fseek(mat->fp,matvar->internal->datapos,SEEK_SET);

            /* Reset zlib knowledge to before reading real tag */
            inflateEnd(&z);
            err = inflateCopy(&z,matvar->internal->z);
            InflateSkip(mat,&z,real_bytes);
            z.avail_in = 0;
            InflateDataType(mat,&z,tag);
            if ( mat->byteswap ) {
                Mat_int32Swap(tag);
            }
            matvar->data_type = tag[0] & 0x000000ff;
            if ( !(tag[0] & 0xffff0000) ) {/*Data is NOT packed in the tag*/
                InflateSkip(mat,&z,4);
            }
            ReadCompressedDataSlab1(mat,&z,complex_data->Im,
                matvar->class_type,matvar->data_type,start,stride,edge);
            inflateEnd(&z);
        } else {
            ReadCompressedDataSlab1(mat,&z,data,matvar->class_type,
                                    matvar->data_type,start,stride,edge);
            inflateEnd(&z);
        }
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
int
Mat_VarWrite5(mat_t *mat,matvar_t *matvar,int compress)
{
    mat_uint32_t array_flags = 0x0;
    mat_int16_t  fieldname_type = MAT_T_INT32,fieldname_data_size=4;
    mat_int8_t  pad1 = 0;
    int      array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int      array_flags_size = 8, pad4 = 0, matrix_type = MAT_T_MATRIX;
    int      nBytes, i, nmemb = 1,nzmax = 0;
    long     start = 0, end = 0;

    /* FIXME: SEEK_END is not Guaranteed by the C standard */
    fseek(mat->fp,0,SEEK_END);         /* Always write at end of file */

#if !defined(HAVE_ZLIB)
    compress = MAT_COMPRESSION_NONE;
#endif

    if ( NULL == mat || NULL == matvar || NULL == matvar->name )
        return -1;

    if ( compress == MAT_COMPRESSION_NONE ) {
        fwrite(&matrix_type,4,1,mat->fp);
        fwrite(&pad4,4,1,mat->fp);
        start = ftell(mat->fp);

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

        fwrite(&array_flags_type,4,1,mat->fp);
        fwrite(&array_flags_size,4,1,mat->fp);
        fwrite(&array_flags,4,1,mat->fp);
        fwrite(&nzmax,4,1,mat->fp);
        /* Rank and Dimension */
        nBytes = matvar->rank * 4;
        fwrite(&dims_array_type,4,1,mat->fp);
        fwrite(&nBytes,4,1,mat->fp);
        for ( i = 0; i < matvar->rank; i++ ) {
            mat_int32_t dim;
            dim = matvar->dims[i];
            nmemb *= dim;
            fwrite(&dim,4,1,mat->fp);
        }
        if ( matvar->rank % 2 != 0 )
            fwrite(&pad4,4,1,mat->fp);
        /* Name of variable */
        if ( strlen(matvar->name) <= 4 ) {
            mat_int32_t  array_name_type = MAT_T_INT8;
            mat_int32_t array_name_len   = strlen(matvar->name);
            mat_int8_t  pad1 = 0;
#if 0
            fwrite(&array_name_type,2,1,mat->fp);
            fwrite(&array_name_len,2,1,mat->fp);
#else
            array_name_type = (array_name_len << 16) | array_name_type;
            fwrite(&array_name_type,4,1,mat->fp);
#endif
            fwrite(matvar->name,1,array_name_len,mat->fp);
            for ( i = array_name_len; i < 4; i++ )
                fwrite(&pad1,1,1,mat->fp);
        } else {
            mat_int32_t array_name_type = MAT_T_INT8;
            mat_int32_t array_name_len  = (mat_int32_t)strlen(matvar->name);
            mat_int8_t  pad1 = 0;

            fwrite(&array_name_type,4,1,mat->fp);
            fwrite(&array_name_len,4,1,mat->fp);
            fwrite(matvar->name,1,array_name_len,mat->fp);
            if ( array_name_len % 8 )
                for ( i = array_name_len % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,mat->fp);
        }

        matvar->internal->datapos = ftell(mat->fp);
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
                    mat_complex_split_t *complex_data = matvar->data;

                    if ( NULL == complex_data )
                        complex_data = &null_complex_data;

                    nBytes = WriteData(mat,complex_data->Re,nmemb,
                        matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,mat->fp);
                    nBytes = WriteData(mat,complex_data->Im,nmemb,
                        matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,mat->fp);
                } else {
                    nBytes=WriteData(mat,matvar->data,nmemb,matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,mat->fp);
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

                /* Check for a structure with no fields */
                if ( matvar->internal->num_fields < 1 ) {
#if 0
                    fwrite(&fieldname_type,2,1,mat->fp);
                    fwrite(&fieldname_data_size,2,1,mat->fp);
#else
                    fieldname = (fieldname_data_size<<16) | fieldname_type;
                    fwrite(&fieldname,4,1,mat->fp);
#endif
                    fieldname_size = 1;
                    fwrite(&fieldname_size,4,1,mat->fp);
                    fwrite(&array_name_type,4,1,mat->fp);
                    nBytes = 0;
                    fwrite(&nBytes,4,1,mat->fp);
                    break;
                }
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
                fwrite(&fieldname_type,2,1,mat->fp);
                fwrite(&fieldname_data_size,2,1,mat->fp);
#else
                fieldname = (fieldname_data_size<<16) | fieldname_type;
                fwrite(&fieldname,4,1,mat->fp);
#endif
                fwrite(&fieldname_size,4,1,mat->fp);
                fwrite(&array_name_type,4,1,mat->fp);
                nBytes = nfields*fieldname_size;
                fwrite(&nBytes,4,1,mat->fp);
                padzero = calloc(fieldname_size,1);
                for ( i = 0; i < nfields; i++ ) {
                    size_t len = strlen(matvar->internal->fieldnames[i]);
                    fwrite(matvar->internal->fieldnames[i],1,len,mat->fp);
                    fwrite(padzero,1,fieldname_size-len,mat->fp);
                }
                free(padzero);
                for ( i = 0; i < nmemb*nfields; i++ )
                    WriteStructField(mat,fields[i]);
                break;
            }
            case MAT_C_SPARSE:
            {
                mat_sparse_t *sparse = matvar->data;

                nBytes = WriteData(mat,sparse->ir,sparse->nir,MAT_T_INT32);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
                nBytes = WriteData(mat,sparse->jc,sparse->njc,MAT_T_INT32);
                if ( nBytes % 8 )
                    for ( i = nBytes % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
                if ( matvar->isComplex ) {
                    mat_complex_split_t *complex_data = sparse->data;
                    nBytes = WriteData(mat,complex_data->Re,sparse->ndata,
                        matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,mat->fp);
                    nBytes = WriteData(mat,complex_data->Im,sparse->ndata,
                        matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,mat->fp);
                } else {
                    nBytes = WriteData(mat,sparse->data,sparse->ndata,matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,mat->fp);
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

        matvar->internal->z         = calloc(1,sizeof(*matvar->internal->z));
        matvar->internal->z->zalloc = Z_NULL;
        matvar->internal->z->zfree  = Z_NULL;
        err = deflateInit(matvar->internal->z,Z_DEFAULT_COMPRESSION);

        matrix_type = MAT_T_COMPRESSED;
        fwrite(&matrix_type,4,1,mat->fp);
        fwrite(&pad4,4,1,mat->fp);
        start = ftell(mat->fp);

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
        matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
        matvar->internal->z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
        matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
        matvar->internal->z->avail_in  = 8;
        err = deflate(matvar->internal->z,Z_PARTIAL_FLUSH);
        byteswritten += fwrite(comp_buf,1,
            buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,mat->fp);
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

        matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
        matvar->internal->z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
        matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
        matvar->internal->z->avail_in  = (6+i)*sizeof(*uncomp_buf);
        err = deflate(matvar->internal->z,Z_PARTIAL_FLUSH);
        byteswritten += fwrite(comp_buf,1,
                buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,mat->fp);
        /* Name of variable */
        if ( strlen(matvar->name) <= 4 ) {
            mat_int16_t array_name_len = (mat_int16_t)strlen(matvar->name);
            mat_int16_t array_name_type = MAT_T_INT8;

            memset(uncomp_buf,0,8);
            uncomp_buf[0] = (array_name_len << 16) | array_name_type;
            memcpy(uncomp_buf+1,matvar->name,array_name_len);
            if ( array_name_len % 4 )
                array_name_len += 4-(array_name_len % 4);

            matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
            matvar->internal->z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
            matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
            matvar->internal->z->avail_in  = 8;
            err = deflate(matvar->internal->z,Z_PARTIAL_FLUSH);
            byteswritten += fwrite(comp_buf,1,
                    buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,mat->fp);
        } else {
            mat_int32_t array_name_len = (mat_int32_t)strlen(matvar->name);
            mat_int32_t array_name_type = MAT_T_INT8;

            memset(uncomp_buf,0,buf_size*sizeof(*uncomp_buf));
            uncomp_buf[0] = array_name_type;
            uncomp_buf[1] = array_name_len;
            memcpy(uncomp_buf+2,matvar->name,array_name_len);
            if ( array_name_len % 8 )
                array_name_len += 8-(array_name_len % 8);
            matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
            matvar->internal->z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
            matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
            matvar->internal->z->avail_in  = 8+array_name_len;
            err = deflate(matvar->internal->z,Z_PARTIAL_FLUSH);
            byteswritten += fwrite(comp_buf,1,
                    buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,mat->fp);
        }
        matvar->internal->datapos = ftell(mat->fp);
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
                    mat_complex_split_t *complex_data = matvar->data;

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

                /* Check for a structure with no fields */
                if ( matvar->internal->num_fields < 1 ) {
                    fieldname_size = 1;
                    uncomp_buf[0] = (fieldname_data_size << 16) |
                                     fieldname_type;
                    uncomp_buf[1] = 1;
                    uncomp_buf[2] = array_name_type;
                    uncomp_buf[3] = 0;
                    matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                    matvar->internal->z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
                    matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
                    matvar->internal->z->avail_in  = 16;
                    err = deflate(matvar->internal->z,Z_PARTIAL_FLUSH);
                    byteswritten += fwrite(comp_buf,1,buf_size*
                        sizeof(*comp_buf)-matvar->internal->z->avail_out,mat->fp);
                    break;
                }
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
                uncomp_buf[0] = (fieldname_data_size << 16) | fieldname_type;
                uncomp_buf[1] = fieldname_size;
                uncomp_buf[2] = array_name_type;
                uncomp_buf[3] = nfields*fieldname_size;

                padzero = calloc(fieldname_size,1);
                matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                matvar->internal->z->next_in   = ZLIB_BYTE_PTR(uncomp_buf);
                matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
                matvar->internal->z->avail_in  = 16;
                err = deflate(matvar->internal->z,Z_PARTIAL_FLUSH);
                byteswritten += fwrite(comp_buf,1,
                    buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,mat->fp);
                for ( i = 0; i < nfields; i++ ) {
                    size_t len = strlen(matvar->internal->fieldnames[i]);
                    memset(padzero,'\0',fieldname_size);
                    memcpy(padzero,matvar->internal->fieldnames[i],len);
                    matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
                    matvar->internal->z->next_in   = ZLIB_BYTE_PTR(padzero);
                    matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
                    matvar->internal->z->avail_in  = fieldname_size;
                    err = deflate(matvar->internal->z,Z_PARTIAL_FLUSH);
                    byteswritten += fwrite(comp_buf,1,
                            buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,
                            mat->fp);
                }
                free(padzero);
                for ( i = 0; i < nmemb*nfields; i++ )
                    byteswritten +=
                        WriteCompressedStructField(mat,fields[i],matvar->internal->z);
                break;
            }
            case MAT_C_SPARSE:
            {
                mat_sparse_t *sparse = matvar->data;

                byteswritten += WriteCompressedData(mat,matvar->internal->z,sparse->ir,
                    sparse->nir,MAT_T_INT32);
                byteswritten += WriteCompressedData(mat,matvar->internal->z,sparse->jc,
                    sparse->njc,MAT_T_INT32);
                if ( matvar->isComplex ) {
                    mat_complex_split_t *complex_data = sparse->data;
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
        matvar->internal->z->avail_in  = 0;
        matvar->internal->z->next_in   = NULL;
        matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
        matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);

        err = deflate(matvar->internal->z,Z_FINISH);
        byteswritten += fwrite(comp_buf,1,
            buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,mat->fp);
        while ( err != Z_STREAM_END && !matvar->internal->z->avail_out ) {
            matvar->internal->z->next_out  = ZLIB_BYTE_PTR(comp_buf);
            matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);

            err = deflate(matvar->internal->z,Z_FINISH);
            byteswritten += fwrite(comp_buf,1,
                buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,mat->fp);
        }
        /* End the compression and set to NULL so Mat_VarFree doesn't try
         * to free matvar->internal->z with inflateEnd
         */
#if 0
        if ( byteswritten % 8 )
            for ( i = 0; i < 8-(byteswritten % 8); i++ )
                fwrite(&pad1,1,1,mat->fp);
#endif
        err = deflateEnd(matvar->internal->z);
        free(matvar->internal->z);
        matvar->internal->z = NULL;
#endif
    }
    end = ftell(mat->fp);
    nBytes = (int)(end-start);
    fseek(mat->fp,(long)-(nBytes+4),SEEK_CUR);
    fwrite(&nBytes,4,1,mat->fp);
    fseek(mat->fp,end,SEEK_SET);

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
void
WriteInfo5(mat_t *mat, matvar_t *matvar)
{
    mat_uint32_t array_flags = 0x0;
    mat_int16_t  fieldname_type = MAT_T_INT32,fieldname_data_size=4;
    mat_int8_t  pad1 = 0;
    int      array_flags_type = MAT_T_UINT32, dims_array_type = MAT_T_INT32;
    int      array_flags_size = 8, pad4 = 0, matrix_type = MAT_T_MATRIX;
    int      nBytes, i, nmemb = 1,nzmax;
    long     start = 0, end = 0;

    /* FIXME: SEEK_END is not Guaranteed by the C standard */
    fseek(mat->fp,0,SEEK_END);         /* Always write at end of file */


    if ( matvar->compression == MAT_COMPRESSION_NONE ) {
        fwrite(&matrix_type,4,1,mat->fp);
        fwrite(&pad4,4,1,mat->fp);
        start = ftell(mat->fp);

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

        fwrite(&array_flags_type,4,1,mat->fp);
        fwrite(&array_flags_size,4,1,mat->fp);
        fwrite(&array_flags,4,1,mat->fp);
        fwrite(&nzmax,4,1,mat->fp);
        /* Rank and Dimension */
        nBytes = matvar->rank * 4;
        fwrite(&dims_array_type,4,1,mat->fp);
        fwrite(&nBytes,4,1,mat->fp);
        for ( i = 0; i < matvar->rank; i++ ) {
            mat_int32_t dim;
            dim = matvar->dims[i];
            nmemb *= dim;
            fwrite(&dim,4,1,mat->fp);
        }
        if ( matvar->rank % 2 != 0 )
            fwrite(&pad4,4,1,mat->fp);
        /* Name of variable */
        if ( strlen(matvar->name) <= 4 ) {
            mat_int16_t array_name_len = (mat_int16_t)strlen(matvar->name);
            mat_int8_t  pad1 = 0;
            mat_int16_t array_name_type = MAT_T_INT8;
            fwrite(&array_name_type,2,1,mat->fp);
            fwrite(&array_name_len,2,1,mat->fp);
            fwrite(matvar->name,1,array_name_len,mat->fp);
            for ( i = array_name_len; i < 4; i++ )
                fwrite(&pad1,1,1,mat->fp);
        } else {
            mat_int32_t array_name_len = (mat_int32_t)strlen(matvar->name);
            mat_int8_t  pad1 = 0;
            mat_int32_t  array_name_type = MAT_T_INT8;

            fwrite(&array_name_type,4,1,mat->fp);
            fwrite(&array_name_len,4,1,mat->fp);
            fwrite(matvar->name,1,array_name_len,mat->fp);
            if ( array_name_len % 8 )
                for ( i = array_name_len % 8; i < 8; i++ )
                    fwrite(&pad1,1,1,mat->fp);
        }

        matvar->internal->datapos = ftell(mat->fp);
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
                        fwrite(&pad1,1,1,mat->fp);
                if ( matvar->isComplex ) {
                    nBytes = WriteEmptyData(mat,nmemb,matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,mat->fp);
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
                fwrite(&fieldname_type,2,1,mat->fp);
                fwrite(&fieldname_data_size,2,1,mat->fp);
#else
                fieldname = (fieldname_data_size<<16) | fieldname_type;
                fwrite(&fieldname,4,1,mat->fp);
#endif
                fwrite(&fieldname_size,4,1,mat->fp);
                fwrite(&array_name_type,4,1,mat->fp);
                nBytes = nfields*fieldname_size;
                fwrite(&nBytes,4,1,mat->fp);
                padzero = calloc(fieldname_size,1);
                for ( i = 0; i < nfields; i++ ) {
                    size_t len = strlen(matvar->internal->fieldnames[i]);
                    fwrite(matvar->internal->fieldnames[i],1,len,mat->fp);
                    fwrite(padzero,1,fieldname_size-len,mat->fp);
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

        matvar->internal->z         = malloc(sizeof(*matvar->internal->z));
        matvar->internal->z->zalloc = Z_NULL;
        matvar->internal->z->zfree  = Z_NULL;
        err = deflateInit(matvar->internal->z,Z_DEFAULT_COMPRESSION);

        matrix_type = MAT_T_COMPRESSED;
        fwrite(&matrix_type,4,1,mat->fp);
        fwrite(&pad4,4,1,mat->fp);
        start = ftell(mat->fp);

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
        matvar->internal->z->next_out  = comp_buf;
        matvar->internal->z->next_in   = uncomp_buf;
        matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
        matvar->internal->z->avail_in  = 8;
        err = deflate(matvar->internal->z,Z_SYNC_FLUSH);
        byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,mat->fp);
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

        matvar->internal->z->next_out  = comp_buf;
        matvar->internal->z->next_in   = uncomp_buf;
        matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
        matvar->internal->z->avail_in  = (6+i)*sizeof(*uncomp_buf);
        err = deflate(matvar->internal->z,Z_PARTIAL_FLUSH);
        byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,mat->fp);
        /* Name of variable */
        if ( strlen(matvar->name) <= 4 ) {
#if 0
            mat_int16_t array_name_len = (mat_int16_t)strlen(matvar->name);
            mat_int8_t  pad1 = 0;

            uncomp_buf[0] = (array_name_type << 16) | array_name_len;
            memcpy(uncomp_buf+1,matvar->name,array_name_len);

            matvar->internal->z->next_out  = comp_buf;
            matvar->internal->z->next_in   = uncomp_buf;
            matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
            matvar->internal->z->avail_in  = 8;
            err = deflate(matvar->internal->z,Z_PARTIAL_FLUSH);
            byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,mat->fp);
        } else {
#endif
            mat_int32_t array_name_len = (mat_int32_t)strlen(matvar->name);

            memset(uncomp_buf,0,buf_size*sizeof(*uncomp_buf));
            uncomp_buf[0] = array_name_type;
            uncomp_buf[1] = array_name_len;
            memcpy(uncomp_buf+2,matvar->name,array_name_len);
            if ( array_name_len % 8 )
                array_name_len += array_name_len % 8;
            matvar->internal->z->next_out  = comp_buf;
            matvar->internal->z->next_in   = uncomp_buf;
            matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
            matvar->internal->z->avail_in  = 8+array_name_len;
            err = deflate(matvar->internal->z,Z_FULL_FLUSH);
            byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,mat->fp);
        }
        matvar->internal->datapos = ftell(mat->fp);
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
                        fwrite(&pad1,1,1,mat->fp);
                if ( matvar->isComplex ) {
                    nBytes = WriteEmptyData(mat,nmemb,matvar->data_type);
                    if ( nBytes % 8 )
                        for ( i = nBytes % 8; i < 8; i++ )
                            fwrite(&pad1,1,1,mat->fp);
                }
#endif
                break;
        }
        matvar->internal->z->next_out  = comp_buf;
        matvar->internal->z->next_in   = NULL;
        matvar->internal->z->avail_out = buf_size*sizeof(*comp_buf);
        matvar->internal->z->avail_in  = 0;

        err = deflate(matvar->internal->z,Z_FINISH);
        byteswritten += fwrite(comp_buf,1,buf_size*sizeof(*comp_buf)-matvar->internal->z->avail_out,mat->fp);
                if ( byteswritten % 8 )
                    for ( i = byteswritten % 8; i < 8; i++ )
                        fwrite(&pad1,1,1,mat->fp);
        fprintf(stderr,"deflate Z_FINISH: err = %d,byteswritten = %u\n",err,byteswritten);

        err = deflateEnd(matvar->internal->z);
        fprintf(stderr,"deflateEnd: err = %d\n",err);
#if 1
        err = deflateEnd(matvar->internal->z);
        free(matvar->internal->z);
        matvar->internal->z = NULL;
#else
        memcpy(matvar->internal->z,&z_save,sizeof(*matvar->internal->z));
#endif
#endif
#endif
    }
    end = ftell(mat->fp);
    nBytes = (int)(end-start);
    fseek(mat->fp,(long)-(nBytes+4),SEEK_CUR);
    fwrite(&nBytes,4,1,mat->fp);
    fseek(mat->fp,end,SEEK_SET);
}

/** @if mat_devman
 * @brief Reads the header information for the next MAT variable
 *
 * @ingroup mat_internal
 * @param mat MAT file pointer
 * @retuen pointer to the MAT variable or NULL
 * @endif
 */
matvar_t *
Mat_VarReadNextInfo5( mat_t *mat )
{
    int err, data_type, nBytes, i;
    long fpos;
    matvar_t *matvar = NULL;
    mat_uint32_t array_flags;

    if( mat == NULL )
        return NULL;

    fpos = ftell(mat->fp);
    err = fread(&data_type,4,1,mat->fp);
    if ( !err )
        return NULL;
    err = fread(&nBytes,4,1,mat->fp);
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
            matvar->compression  = 1;

            matvar->internal->fp = mat;
            matvar->internal->fpos         = fpos;
            matvar->internal->z = calloc(1,sizeof(z_stream));
            matvar->internal->z->zalloc    = NULL;
            matvar->internal->z->zfree     = NULL;
            matvar->internal->z->opaque    = NULL;
            matvar->internal->z->next_in   = NULL;
            matvar->internal->z->next_out  = NULL;
            matvar->internal->z->avail_in  = 0;
            matvar->internal->z->avail_out = 0;
            err = inflateInit(matvar->internal->z);
            if ( err != Z_OK ) {
                Mat_VarFree(matvar);
                matvar = NULL;
                Mat_Critical("inflateInit2 returned %d",err);
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
                fseek(mat->fp,nBytes-bytesread,SEEK_CUR);
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
                matvar->dims = malloc(matvar->rank*sizeof(*matvar->dims));
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
                matvar->name = malloc(i+1);
                /* Inflate variable name */
                bytesread += InflateVarName(mat,matvar,matvar->name,i);
                matvar->name[len] = '\0';
            } else if ( ((uncomp_buf[0] & 0x0000ffff) == MAT_T_INT8) &&
                        ((uncomp_buf[0] & 0xffff0000) != 0x00) ) {
                /* Name packed in tag */
                int len;
                len = (uncomp_buf[0] & 0xffff0000) >> 16;
                matvar->name = malloc(len+1);
                memcpy(matvar->name,uncomp_buf+1,len);
                matvar->name[len] = '\0';
            }
            if ( matvar->class_type == MAT_C_STRUCT )
                ReadNextStructField(mat,matvar);
            else if ( matvar->class_type == MAT_C_CELL )
                ReadNextCell(mat,matvar);
            fseek(mat->fp,-(int)matvar->internal->z->avail_in,SEEK_CUR);
            matvar->internal->datapos = ftell(mat->fp);
            fseek(mat->fp,nBytes+8+fpos,SEEK_SET);
            break;
#else
            Mat_Critical("Compressed variable found in \"%s\", but %s was "
                         "built without zlib support",mat->filename,__FILE__);
            fseek(mat->fp,nBytes+8+fpos,SEEK_SET);
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
            bytesread  += fread(buf,4,6,mat->fp);
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
                matvar->dims = malloc(matvar->rank*sizeof(*matvar->dims));

                /* Assumes rank <= 16 */
                if ( matvar->rank % 2 != 0 )
                    bytesread+=fread(buf,4,matvar->rank+1,mat->fp);
                else
                    bytesread+=fread(buf,4,matvar->rank,mat->fp);

                if ( mat->byteswap ) {
                    for ( i = 0; i < matvar->rank; i++ )
                        matvar->dims[i] = Mat_uint32Swap(buf+i);
                } else {
                    for ( i = 0; i < matvar->rank; i++ )
                        matvar->dims[i] = buf[i];
                }
            }
            /* Variable Name Tag */
            bytesread+=fread(buf,4,2,mat->fp);
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
                bytesread+=fread(buf,1,i,mat->fp);

                matvar->name = malloc(len+1);
                memcpy(matvar->name,buf,len);
                matvar->name[len] = '\0';
            } else if ( ((buf[0] & 0x0000ffff) == MAT_T_INT8) &&
                        ((buf[0] & 0xffff0000) != 0x00) ) {
                /* Name packed in the tag */
                int len;

                len = (buf[0] & 0xffff0000) >> 16;
                matvar->name = malloc(len+1);
                memcpy(matvar->name,buf+1,len);
                matvar->name[len] = '\0';
            }
            if ( matvar->class_type == MAT_C_STRUCT )
                (void)ReadNextStructField(mat,matvar);
            else if ( matvar->class_type == MAT_C_CELL )
                (void)ReadNextCell(mat,matvar);
            else if ( matvar->class_type == MAT_C_FUNCTION )
                (void)ReadNextFunctionHandle(mat,matvar);
            matvar->internal->datapos = ftell(mat->fp);
            fseek(mat->fp,nBytes+8+fpos,SEEK_SET);
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

#include <hdf5.h>

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

/*===========================================================================
 *  Private functions
 *===========================================================================
 */
static enum matio_classes Mat_class_str_to_id(const char *name);
static hid_t Mat_class_type_to_hid_t(enum matio_classes class_type);
static hid_t Mat_data_type_to_hid_t(enum matio_types data_type);
static hid_t Mat_dims_type_to_hid_t(void);
static void  Mat_H5GetChunkSize(size_t rank,hsize_t *dims,hsize_t *chunk_dims);
static void  Mat_H5ReadClassType(matvar_t *matvar,hid_t dset_id);
static void  Mat_H5ReadDatasetInfo(mat_t *mat,matvar_t *matvar,hid_t dset_id);
static void  Mat_H5ReadGroupInfo(mat_t *mat,matvar_t *matvar,hid_t dset_id);
static void  Mat_H5ReadNextReferenceInfo(hid_t ref_id,matvar_t *matvar,mat_t *mat);
static void  Mat_H5ReadNextReferenceData(hid_t ref_id,matvar_t *matvar,mat_t *mat);
static int   Mat_VarWriteCell73(hid_t id,matvar_t *matvar,const char *name,
                                hid_t *refs_id);
static int   Mat_VarWriteChar73(hid_t id,matvar_t *matvar,const char *name);
static int   Mat_WriteEmptyVariable73(hid_t id,const char *name,hsize_t rank,
                 size_t *dims);
static int   Mat_VarWriteNumeric73(hid_t id,matvar_t *matvar,const char *name);
static int   Mat_VarWriteStruct73(hid_t id,matvar_t *matvar,const char *name,
                                  hid_t *refs_id);
static int   Mat_VarWriteNext73(hid_t id,matvar_t *matvar,const char *name,
                                hid_t *refs_id);

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
    attr_id = H5Aopen_name(dset_id,"MATLAB_class");
    type_id  = H5Aget_type(attr_id);
    if ( H5T_STRING == H5Tget_class(type_id) ) {
        char *class_str = calloc(H5Tget_size(type_id)+1,1);
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
                    attr_id2 = H5Aopen_name(dset_id,"MATLAB_int_decode");
                    /* FIXME: Check that dataspace is scalar */
                    if ( -1 < attr_id2 ) {
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
    H5E_auto_t efunc;
    void       *client_data;

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
        matvar->internal->hdf5_name = malloc(name_len+1);
        (void)H5Iget_name(dset_id,matvar->internal->hdf5_name,name_len+1);
    } else {
        /* Can not get an internal name, so leave the identifier open */
        matvar->internal->id = dset_id;
    }

    space_id     = H5Dget_space(dset_id);
    matvar->rank = H5Sget_simple_extent_ndims(space_id);
    matvar->dims = malloc(matvar->rank*sizeof(*matvar->dims));
    if ( NULL != matvar->dims ) {
        int k;
        H5Sget_simple_extent_dims(space_id,dims,NULL);
        for ( k = 0; k < matvar->rank; k++ )
            matvar->dims[k] = dims[matvar->rank - k - 1];
    }
    H5Sclose(space_id);

    Mat_H5ReadClassType(matvar, dset_id);

    /* Turn off error printing so testing for attributes doesn't print
     * error stacks
     */
    H5Eget_auto(H5E_DEFAULT,&efunc,&client_data);
    H5Eset_auto(H5E_DEFAULT,(H5E_auto_t)0,NULL);

    attr_id = H5Aopen_name(dset_id,"MATLAB_global");
    /* FIXME: Check that dataspace is scalar */
    if ( -1 < attr_id ) {
        H5Aread(attr_id,H5T_NATIVE_INT,&matvar->isGlobal);
        H5Aclose(attr_id);
    }

    /* Check for attribute that indicates an empty array */
    attr_id = H5Aopen_name(dset_id,"MATLAB_empty");
    /* FIXME: Check that dataspace is scalar */
    if ( -1 < attr_id ) {
        int empty = 0;
        H5Aread(attr_id,H5T_NATIVE_INT,&empty);
        H5Aclose(attr_id);
        if ( empty ) {
            matvar->rank = matvar->dims[0];
            matvar->dims = calloc(matvar->rank,sizeof(*matvar->dims));
            H5Dread(dset_id,Mat_dims_type_to_hid_t(),H5S_ALL,H5S_ALL,
                    H5P_DEFAULT,matvar->dims);
        }
    }

    H5Eset_auto(H5E_DEFAULT,efunc,client_data);

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
        cells  = matvar->data;

        if ( ncells ) {
            ref_ids = malloc(ncells*sizeof(*ref_ids));
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

        /* Turn off error printing so testing for attributes doesn't print
         * error stacks
         */
        H5Eget_auto(H5E_DEFAULT,&efunc,&client_data);
        H5Eset_auto(H5E_DEFAULT,(H5E_auto_t)0,NULL);
        /* Check if the structure defines its fields in MATLAB_fields */
        attr_id = H5Aopen_name(dset_id,"MATLAB_fields");
        if ( -1 < attr_id ) {
            int      i;
            hid_t    field_id;
            hsize_t  nfields;
            hvl_t   *fieldnames_vl;

            space_id = H5Aget_space(attr_id);
            (void)H5Sget_simple_extent_dims(space_id,&nfields,NULL);
            field_id = H5Aget_type(attr_id);
            fieldnames_vl = malloc(nfields*sizeof(*fieldnames_vl));
            H5Aread(attr_id,field_id,fieldnames_vl);

            matvar->internal->num_fields = nfields;
            matvar->internal->fieldnames =
            calloc(nfields,sizeof(*matvar->internal->fieldnames));
            for ( i = 0; i < nfields; i++ ) {
                matvar->internal->fieldnames[i] =
                calloc(fieldnames_vl[i].len+1,1);
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
        H5Eset_auto(H5E_DEFAULT,efunc,client_data);
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
    H5E_auto_t efunc;
    void       *client_data;

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
        matvar->internal->hdf5_name = malloc(name_len+1);
        (void)H5Iget_name(dset_id,matvar->internal->hdf5_name,name_len+1);
    } else {
        /* Can not get an internal name, so leave the identifier open */
        matvar->internal->id = dset_id;
    }

    Mat_H5ReadClassType(matvar,dset_id);

    /* Turn off error printing so testing for attributes doesn't print
     * error stacks
     */
    H5Eget_auto(H5E_DEFAULT,&efunc,&client_data);
    H5Eset_auto(H5E_DEFAULT,(H5E_auto_t)0,NULL);

    /* Check if the variable is global */
    attr_id = H5Aopen_name(dset_id,"MATLAB_global");
    /* FIXME: Check that dataspace is scalar */
    if ( -1 < attr_id ) {
        H5Aread(attr_id,H5T_NATIVE_INT,&matvar->isGlobal);
        H5Aclose(attr_id);
    }

    /* Check if the variable is sparse */
    attr_id = H5Aopen_name(dset_id,"MATLAB_sparse");
    if ( -1 < attr_id ) {
        hid_t sparse_dset_id;
        unsigned nrows = 0;

        H5Eset_auto(H5E_DEFAULT,efunc,client_data);

        H5Aread(attr_id,H5T_NATIVE_UINT,&nrows);
        H5Aclose(attr_id);

        matvar->class_type = MAT_C_SPARSE;

        matvar->rank = 2;
        matvar->dims = malloc(matvar->rank*sizeof(*matvar->dims));
        matvar->dims[0] = nrows;

        sparse_dset_id = H5Dopen(dset_id,"jc",H5P_DEFAULT);
        if ( -1 < sparse_dset_id ) {
            space_id = H5Dget_space(sparse_dset_id);
            (void)H5Sget_simple_extent_dims(space_id,dims,NULL);
            matvar->dims[1] = dims[0] - 1;
        }

        /* Test if dataset type is compound and if so if it's complex */
        sparse_dset_id = H5Dopen(dset_id,"data",H5P_DEFAULT);
        if ( -1 < sparse_dset_id ) {
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
    attr_id = H5Aopen_name(dset_id,"MATLAB_fields");
    if ( -1 < attr_id ) {
        hvl_t     *fieldnames_vl;
        space_id = H5Aget_space(attr_id);
        (void)H5Sget_simple_extent_dims(space_id,&nfields,NULL);
        field_id = H5Aget_type(attr_id);
        fieldnames_vl = malloc(nfields*sizeof(*fieldnames_vl));
        H5Aread(attr_id,field_id,fieldnames_vl);

        matvar->internal->num_fields = nfields;
        matvar->internal->fieldnames =
            malloc(nfields*sizeof(*matvar->internal->fieldnames));
        for ( k = 0; k < nfields; k++ ) {
            matvar->internal->fieldnames[k] = calloc(fieldnames_vl[k].len+1,1);
            memcpy(matvar->internal->fieldnames[k],fieldnames_vl[k].p,
                   fieldnames_vl[k].len);
        }

        H5Dvlen_reclaim(field_id,space_id,H5P_DEFAULT,fieldnames_vl);
        H5Sclose(space_id);
        H5Tclose(field_id);
        H5Aclose(attr_id);
        free(fieldnames_vl);
    } else {
        hsize_t next_index = 0,num_objs  = 0;
        int     obj_type;
        H5Gget_num_objs(dset_id,&num_objs);
        if ( num_objs > 0 ) {
            matvar->internal->fieldnames =
                calloc(num_objs,sizeof(*matvar->internal->fieldnames));
            /* FIXME: follow symlinks, datatypes? */
            while ( next_index < num_objs ) {
                obj_type = H5Gget_objtype_by_idx(dset_id,next_index);
                switch ( obj_type ) {
                    case H5G_DATASET:
                    {
                        int len;
                        len = H5Gget_objname_by_idx(dset_id,next_index,NULL,0);
                        matvar->internal->fieldnames[nfields] =
                            calloc(len+1,sizeof(**matvar->internal->fieldnames));
                        H5Gget_objname_by_idx(dset_id,next_index,
                            matvar->internal->fieldnames[nfields],len+1);
                        nfields++;
                        break;
                    }
                    case H5G_GROUP:
                    {
                        /* Check that this is not the /#refs# group */
                        char name[128] = {0,};
                        (void)H5Gget_objname_by_idx(dset_id,next_index,name,127);
                        if ( strcmp(name,"#refs#") ) {
                            int len;
                            len = H5Gget_objname_by_idx(dset_id,next_index,NULL,0);
                            matvar->internal->fieldnames[nfields] =
                                calloc(len+1,1);
                            H5Gget_objname_by_idx(dset_id,next_index,
                                matvar->internal->fieldnames[nfields],len+1);
                            nfields++;
                        }
                        break;
                    }
                }
                next_index++;
            }
            matvar->internal->num_fields = nfields;
        }
    }

    if ( matvar->internal->num_fields > 0 &&
         -1 < (field_id = H5Dopen(dset_id,matvar->internal->fieldnames[0],
                                  H5P_DEFAULT)) ) {
        field_type_id = H5Dget_type(field_id);
        if ( H5T_REFERENCE == H5Tget_class(field_type_id) ) {
            /* Check if the field has the MATLAB_class attribute. If so, it
             * means the structure is a scalar. Otherwise, the dimensions of
             * the field dataset is the dimensions of the structure
             */
            /* Turn off error printing so testing for attributes doesn't print
             * error stacks
             */
            H5Eget_auto(H5E_DEFAULT,&efunc,&client_data);
            H5Eset_auto(H5E_DEFAULT,(H5E_auto_t)0,NULL);
            attr_id = H5Aopen_name(field_id,"MATLAB_class");
            H5Eset_auto(H5E_DEFAULT,efunc,client_data);
            if ( -1 < attr_id ) {
                H5Aclose(attr_id);
                matvar->rank    = 2;
                matvar->dims    = malloc(2*sizeof(*matvar->dims));
                matvar->dims[0] = 1;
                matvar->dims[1] = 1;
                numel = 1;
            } else {
                space_id        = H5Dget_space(field_id);
                matvar->rank    = H5Sget_simple_extent_ndims(space_id);
                matvar->dims    = malloc(matvar->rank*sizeof(*matvar->dims));
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
            matvar->dims    = malloc(2*sizeof(*matvar->dims));
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
        matvar->dims    = malloc(2*sizeof(*matvar->dims));
        matvar->dims[0] = 1;
        matvar->dims[1] = 1;
    }

    if ( !nfields ) {
        H5Eset_auto(H5E_DEFAULT,efunc,client_data);
        return;
    }

    H5Eset_auto(H5E_DEFAULT,efunc,client_data);
    if ( numel < 1 || nfields < 1 )
        return;

    fields = malloc(nfields*numel*sizeof(*fields));
    matvar->data = fields;
    matvar->data_size = sizeof(*fields);
    matvar->nbytes    = nfields*numel*matvar->data_size;
    if ( NULL != fields ) {
        for ( k = 0; k < nfields; k++ ) {
            int l;
            fields[k] = NULL;
            field_id = H5Dopen(dset_id,matvar->internal->fieldnames[k],
                               H5P_DEFAULT);
            if ( -1 < field_id ) {
                if ( !fields_are_variables ) {
                    hobj_ref_t *ref_ids = malloc(numel*sizeof(*ref_ids));
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
                                malloc(name_len+1);
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
            } else {
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

static void
Mat_H5ReadNextReferenceInfo(hid_t ref_id,matvar_t *matvar,mat_t *mat)
{
    H5E_auto_t  efunc;
    void       *client_data;

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
            matvar->dims = malloc(matvar->rank*sizeof(*matvar->dims));
            if ( NULL == matvar->dims ) {
                break;
            } else {
                int k;
                H5Sget_simple_extent_dims(space_id,dims,NULL);
                for ( k = 0; k < matvar->rank; k++ )
                    matvar->dims[k] = dims[matvar->rank - k - 1];
            }
            H5Sclose(space_id);

            Mat_H5ReadClassType(matvar,dset_id);

            /* Turn off error printing so testing for attributes doesn't print
             * error stacks
             */
            H5Eget_auto(H5E_DEFAULT,&efunc,&client_data);
            H5Eset_auto(H5E_DEFAULT,(H5E_auto_t)0,NULL);

            attr_id = H5Aopen_name(dset_id,"MATLAB_global");
            /* FIXME: Check that dataspace is scalar */
            if ( -1 < attr_id ) {
                H5Aread(attr_id,H5T_NATIVE_INT,&matvar->isGlobal);
                H5Aclose(attr_id);
            }

            /* Check for attribute that indicates an empty array */
            attr_id = H5Aopen_name(dset_id,"MATLAB_empty");
            /* FIXME: Check that dataspace is scalar */
            if ( -1 < attr_id ) {
                int empty = 0;
                H5Aread(attr_id,H5T_NATIVE_INT,&empty);
                H5Aclose(attr_id);
                if ( empty ) {
                    matvar->rank = matvar->dims[0];
                    free(matvar->dims);
                    matvar->dims = calloc(matvar->rank,sizeof(*matvar->dims));
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

            /* If the dataset is a cell array read theinfo of the cells */
            if ( MAT_C_CELL == matvar->class_type ) {
                matvar_t **cells;
                int i,ncells = 1;
                hobj_ref_t *ref_ids;

                for ( i = 0; i < matvar->rank; i++ )
                    ncells *= matvar->dims[i];
                matvar->data_size = sizeof(matvar_t**);
                matvar->nbytes    = ncells*matvar->data_size;
                matvar->data      = malloc(matvar->nbytes);
                cells  = matvar->data;

                ref_ids = malloc(ncells*sizeof(*ref_ids));
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
            } else if ( MAT_C_STRUCT == matvar->class_type ) {
                /* Empty structures can be a dataset */

                /* Turn off error printing so testing for attributes doesn't print
                 * error stacks
                 */
                H5Eget_auto(H5E_DEFAULT,&efunc,&client_data);
                H5Eset_auto(H5E_DEFAULT,(H5E_auto_t)0,NULL);
                /* Check if the structure defines its fields in MATLAB_fields */
                attr_id = H5Aopen_name(dset_id,"MATLAB_fields");
                if ( -1 < attr_id ) {
                    int      i;
                    hid_t    field_id;
                    hsize_t  nfields;
                    hvl_t   *fieldnames_vl;

                    space_id = H5Aget_space(attr_id);
                    (void)H5Sget_simple_extent_dims(space_id,&nfields,NULL);
                    field_id = H5Aget_type(attr_id);
                    fieldnames_vl = malloc(nfields*sizeof(*fieldnames_vl));
                    H5Aread(attr_id,field_id,fieldnames_vl);

                    matvar->internal->num_fields = nfields;
                    matvar->internal->fieldnames =
                        malloc(nfields*sizeof(*matvar->internal->fieldnames));
                    for ( i = 0; i < nfields; i++ ) {
                        matvar->internal->fieldnames[i] =
                            calloc(fieldnames_vl[i].len+1,1);
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
                H5Eset_auto(H5E_DEFAULT,efunc,client_data);
            }

            if ( matvar->internal->id != dset_id ) {
                /* Close dataset and increment count */
                H5Dclose(dset_id);
            }

            H5Eset_auto(H5E_DEFAULT,efunc,client_data);
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
        matvar_t **cells = matvar->data;
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

                complex_data     = malloc(sizeof(*complex_data));
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
                fields  = matvar->data;
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
    H5E_auto_t efunc;
    void       *client_data;
    int        is_ref, err = -1;
    char       id_name[128] = {'\0',};
    hsize_t    perm_dims[10];

    cells = matvar->data;
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
            /* Turn off error-checking so we don't get messages if opening
             * group /#refs# fails
             */
            H5Eget_auto(H5E_DEFAULT,&efunc,&client_data);
            H5Eset_auto(H5E_DEFAULT,(H5E_auto_t)0,NULL);
            *refs_id = H5Gopen(id,"/#refs#",H5P_DEFAULT);
            if ( *refs_id < 0 )
                *refs_id = H5Gcreate(id,"/#refs#",H5P_DEFAULT,
                                     H5P_DEFAULT,H5P_DEFAULT);
            H5Eset_auto(H5E_DEFAULT,efunc,client_data);
        }

        if ( *refs_id > -1 ) {
            char        obj_name[64];
            hobj_ref_t *refs;
            hsize_t     num_obj;

            for ( k = 0; k < matvar->rank; k++ )
                perm_dims[k] = matvar->dims[matvar->rank-k-1];

            refs = malloc(nmemb*sizeof(*refs));
            mspace_id=H5Screate_simple(matvar->rank,perm_dims,NULL);
            dset_id = H5Dcreate(id,name,H5T_STD_REF_OBJ,mspace_id,
                                H5P_DEFAULT,H5P_DEFAULT,H5P_DEFAULT);

            for ( k = 0; k < nmemb; k++ ) {
                (void)H5Gget_num_objs(*refs_id,&num_obj);
                sprintf(obj_name,"%lld",num_obj);
                if ( NULL != cells[k] )
                    cells[k]->compression = matvar->compression;
                Mat_VarWriteNext73(*refs_id,cells[k],obj_name,refs_id);
                sprintf(obj_name,"/#refs#/%lld",num_obj);
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
    }
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

        sparse = matvar->data;
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
        mspace_id = H5Screate_simple(1,&ndata,NULL);
        data_type_id = Mat_data_type_to_hid_t(matvar->data_type);
        if ( matvar->isComplex ) {
            hid_t h5_complex;
            mat_complex_split_t *complex_data;

            complex_data = sparse->data;

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
            fieldnames = malloc(nfields*sizeof(*fieldnames));
            fields     = matvar->data;
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

            nfields = matvar->internal->num_fields;

            /* Structure with no fields */
            if ( nfields == 0 ) {
                H5Gclose(struct_id);
                return 0;
            }

            fieldnames = malloc(nfields*sizeof(*fieldnames));
            fields     = matvar->data;
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
                    H5E_auto_t  efunc;
                    void       *client_data;
                    /* Silence errors if /#refs does not exist */
                    H5Eget_auto(H5E_DEFAULT,&efunc,&client_data);
                    H5Eset_auto(H5E_DEFAULT,(H5E_auto_t)0,NULL);
                    *refs_id = H5Gopen(id,"/#refs#",H5P_DEFAULT);
                    H5Eset_auto(H5E_DEFAULT,efunc,client_data);

                    /* If could not open /#refs#, try to create it */
                    if ( *refs_id < 0 )
                        *refs_id = H5Gcreate(id,"/#refs#",H5P_DEFAULT,
                                             H5P_DEFAULT,H5P_DEFAULT);
                }
                if ( *refs_id > -1 ) {
                    char name[64];
                    hobj_ref_t **refs;
                    hsize_t      num_obj;
                    int l;

                    refs = malloc(nfields*sizeof(*refs));
                    for ( l = 0; l < nfields; l++ )
                        refs[l] = malloc(nmemb*sizeof(*refs[l]));

                    for ( k = 0; k < nmemb; k++ ) {
                        for ( l = 0; l < nfields; l++ ) {
                            (void)H5Gget_num_objs(*refs_id,&num_obj);
                            sprintf(name,"%lld",num_obj);
                            fields[k*nfields+l]->compression =
                                matvar->compression;
                            Mat_VarWriteNext73(*refs_id,fields[k*nfields+l],
                                name,refs_id);
                            sprintf(name,"/#refs#/%lld",num_obj);
                            H5Rcreate(refs[l]+k,id,name,
                                      H5R_OBJECT,-1);
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

    fseek(fp,0,SEEK_SET);

    mat = malloc(sizeof(*mat));
    if ( !mat ) {
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
    mat->header   = calloc(1,128);
    mat->subsys_offset = calloc(1,16);
    memset(mat->header,' ',128);
    if ( hdr_str == NULL ) {
        err = mat_snprintf(mat->header,116,"MATLAB 7.0 MAT-file, Platform: %s,"
                "Created by: libmatio v%d.%d.%d on %s HDF5 schema 0.5",
                MATIO_PLATFORM,MATIO_MAJOR_VERSION,MATIO_MINOR_VERSION,
                MATIO_RELEASE_LEVEL,ctime(&t));
        mat->header[115] = '\0';    /* Just to make sure it's NULL terminated */    } else {
        err = mat_snprintf(mat->header,116,"%s",hdr_str);
    }
    mat->header[err] = ' ';
    mat_snprintf(mat->subsys_offset,15,"            ");
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
    hid_t fid,dset_id;

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

            if ( NULL != matvar->internal->hdf5_name ) {
                dset_id = H5Dopen(fid,matvar->internal->hdf5_name,H5P_DEFAULT);
            } else {
                dset_id = matvar->internal->id;
                H5Iinc_ref(dset_id);
            }

            if ( numel < 1 ) {
                H5Dclose(dset_id);
                break;
            }

            if ( !matvar->isComplex ) {
                matvar->data      = malloc(matvar->nbytes);
                if ( NULL != matvar->data ) {
                    H5Dread(dset_id,Mat_class_type_to_hid_t(matvar->class_type),
                            H5S_ALL,H5S_ALL,H5P_DEFAULT,matvar->data);
                }
            } else {
                mat_complex_split_t *complex_data;
                hid_t h5_complex_base,h5_complex;

                complex_data     = malloc(sizeof(*complex_data));
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
            fields  = matvar->data;
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
            cells  = matvar->data;

            for ( i = 0; i < ncells; i++ )
                Mat_H5ReadNextReferenceData(cells[i]->internal->id,cells[i],mat);
            break;
        }
        case MAT_C_SPARSE:
        {
            hid_t sparse_dset_id, space_id;
            hsize_t dims[2] = {0,};
            struct mat_sparse_t *sparse_data = calloc(1,sizeof(*sparse_data));

            if ( NULL != matvar->internal->hdf5_name ) {
                dset_id = H5Gopen(fid,matvar->internal->hdf5_name,H5P_DEFAULT);
            } else {
                dset_id = matvar->internal->id;
                H5Iinc_ref(dset_id);
            }

            sparse_dset_id = H5Dopen(dset_id,"ir",H5P_DEFAULT);
            if ( -1 < sparse_dset_id ) {
                space_id = H5Dget_space(sparse_dset_id);
                H5Sget_simple_extent_dims(space_id,dims,NULL);
                sparse_data->nir = dims[0];
                sparse_data->ir = malloc(sparse_data->nir*
                                         sizeof(*sparse_data->ir));
                H5Dread(sparse_dset_id,H5T_NATIVE_INT,
                        H5S_ALL,H5S_ALL,H5P_DEFAULT,sparse_data->ir);
                H5Sclose(space_id);
                H5Dclose(sparse_dset_id);
            }

            sparse_dset_id = H5Dopen(dset_id,"jc",H5P_DEFAULT);
            if ( -1 < sparse_dset_id ) {
                space_id = H5Dget_space(sparse_dset_id);
                H5Sget_simple_extent_dims(space_id,dims,NULL);
                sparse_data->njc = dims[0];
                sparse_data->jc = malloc(sparse_data->njc*
                                         sizeof(*sparse_data->jc));
                H5Dread(sparse_dset_id,H5T_NATIVE_INT,
                        H5S_ALL,H5S_ALL,H5P_DEFAULT,sparse_data->jc);
                H5Sclose(space_id);
                H5Dclose(sparse_dset_id);
            }

            sparse_dset_id = H5Dopen(dset_id,"data",H5P_DEFAULT);
            if ( -1 < sparse_dset_id ) {
                size_t ndata_bytes;
                space_id = H5Dget_space(sparse_dset_id);
                H5Sget_simple_extent_dims(space_id,dims,NULL);
                sparse_data->nzmax = dims[0];
                sparse_data->ndata = dims[0];
                matvar->data_size  = sizeof(struct mat_sparse_t);
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

                    complex_data     = malloc(sizeof(*complex_data));
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
    hid_t fid,dset_id,dset_space,mem_space;
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
                dset_id = H5Dopen(fid,matvar->internal->hdf5_name,H5P_DEFAULT);
            } else {
                dset_id = matvar->internal->id;
                H5Iinc_ref(dset_id);
            }

            dset_space = H5Dget_space(dset_id);
            H5Sselect_hyperslab(dset_space, H5S_SELECT_SET, dset_start,
                                dset_stride, dset_edge, NULL);

            if ( !matvar->isComplex ) {
                H5Dread(dset_id,Mat_class_type_to_hid_t(matvar->class_type),
                        mem_space,dset_space,H5P_DEFAULT,data);
            } else {
                mat_complex_split_t *complex_data = data;
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
            err = 0;
            break;
        default:
            break;
    }

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

            points = malloc(matvar->rank*dset_edge*sizeof(*points));
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
                H5Eprint(H5E_DEFAULT,stdout);
            } else {
                mat_complex_split_t *complex_data = data;
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
    hid_t       fid;
    hsize_t     num_objs;
    H5E_auto_t  efunc;
    void       *client_data;
    matvar_t   *matvar;

    if( mat == NULL )
        return NULL;

    fid = *(hid_t*)mat->fp;
    H5Gget_num_objs(fid,&num_objs);
    /* FIXME: follow symlinks, datatypes? */
    while ( mat->next_index < num_objs ) {
        if ( H5G_DATASET == H5Gget_objtype_by_idx(fid,mat->next_index) ) {
            break;
        } else if ( H5G_GROUP == H5Gget_objtype_by_idx(fid,mat->next_index) ) {
            /* Check that this is not the /#refs# group */
            char name[128] = {0,};
            (void)H5Gget_objname_by_idx(fid,mat->next_index,name,127);
            if ( strcmp(name,"#refs#") )
                break;
            else
                mat->next_index++;
        } else {
            mat->next_index++;
        }
    }

    if ( mat->next_index >= num_objs )
        return NULL;
    else if ( NULL == (matvar = Mat_VarCalloc()) )
        return NULL;

    switch ( H5Gget_objtype_by_idx(fid,mat->next_index) ) {
        case H5G_DATASET:
        {
            ssize_t  name_len;
            /* FIXME */
            hsize_t  dims[10];
            hid_t   attr_id,type_id,dset_id,space_id;

            matvar->internal->fp = mat;
            name_len = H5Gget_objname_by_idx(fid,mat->next_index,NULL,0);
            matvar->name = malloc(1+name_len);
            if ( matvar->name ) {
                name_len = H5Gget_objname_by_idx(fid,mat->next_index,
                                                 matvar->name,1+name_len);
                matvar->name[name_len] = '\0';
            }
            dset_id = H5Dopen(fid,matvar->name,H5P_DEFAULT);

            /* Get the HDF5 name of the variable */
            name_len = H5Iget_name(dset_id,NULL,0);
            if ( name_len > 0 ) {
                matvar->internal->hdf5_name = malloc(name_len+1);
                (void)H5Iget_name(dset_id,matvar->internal->hdf5_name,
                                  name_len+1);
            } else {
                /* Can not get an internal name, so leave the identifier open */
                matvar->internal->id = dset_id;
            }

            space_id = H5Dget_space(dset_id);
            matvar->rank = H5Sget_simple_extent_ndims(space_id);
            matvar->dims = malloc(matvar->rank*sizeof(*matvar->dims));
            if ( NULL != matvar->dims ) {
                int k;
                H5Sget_simple_extent_dims(space_id,dims,NULL);
                for ( k = 0; k < matvar->rank; k++ )
                    matvar->dims[k] = dims[matvar->rank - k - 1];
            }
            H5Sclose(space_id);

            Mat_H5ReadClassType(matvar,dset_id);

            /* Turn off error printing so testing for attributes doesn't print
             * error stacks
             */
            H5Eget_auto(H5E_DEFAULT,&efunc,&client_data);
            H5Eset_auto(H5E_DEFAULT,(H5E_auto_t)0,NULL);

            attr_id = H5Aopen_name(dset_id,"MATLAB_global");
            /* FIXME: Check that dataspace is scalar */
            if ( -1 < attr_id ) {
                H5Aread(attr_id,H5T_NATIVE_INT,&matvar->isGlobal);
                H5Aclose(attr_id);
            }

            /* Check for attribute that indicates an empty array */
            attr_id = H5Aopen_name(dset_id,"MATLAB_empty");
            /* FIXME: Check that dataspace is scalar */
            if ( -1 < attr_id ) {
                int empty = 0;
                H5Aread(attr_id,H5T_NATIVE_INT,&empty);
                H5Aclose(attr_id);
                if ( empty ) {
                    matvar->rank = matvar->dims[0];
                    free(matvar->dims);
                    matvar->dims = calloc(matvar->rank,sizeof(*matvar->dims));
                    H5Dread(dset_id,Mat_dims_type_to_hid_t(),H5S_ALL,H5S_ALL,
                            H5P_DEFAULT,matvar->dims);
                }
            }

            H5Eset_auto(H5E_DEFAULT,efunc,client_data);

            /* Test if dataset type is compound and if so if it's complex */
            type_id = H5Dget_type(dset_id);
            if ( H5T_COMPOUND == H5Tget_class(type_id) ) {
                /* FIXME: Any more checks? */
                matvar->isComplex = MAT_F_COMPLEX;
            }
            H5Tclose(type_id);

            /* If the dataset is a cell array read theinfo of the cells */
            if ( MAT_C_CELL == matvar->class_type ) {
                matvar_t **cells;
                int i,ncells = 1;
                hobj_ref_t *ref_ids;

                for ( i = 0; i < matvar->rank; i++ )
                    ncells *= matvar->dims[i];
                matvar->data_size = sizeof(matvar_t**);
                matvar->nbytes    = ncells*matvar->data_size;
                matvar->data      = malloc(matvar->nbytes);
                cells  = matvar->data;

                if ( ncells ) {
                    ref_ids = malloc(ncells*sizeof(*ref_ids));
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

                /* Turn off error printing so testing for attributes doesn't print
                 * error stacks
                 */
                H5Eget_auto(H5E_DEFAULT,&efunc,&client_data);
                H5Eset_auto(H5E_DEFAULT,(H5E_auto_t)0,NULL);
                /* Check if the structure defines its fields in MATLAB_fields */
                attr_id = H5Aopen_name(dset_id,"MATLAB_fields");
                if ( -1 < attr_id ) {
                    int      i;
                    hid_t    field_id;
                    hsize_t  nfields;
                    hvl_t   *fieldnames_vl;

                    space_id = H5Aget_space(attr_id);
                    (void)H5Sget_simple_extent_dims(space_id,&nfields,NULL);
                    field_id = H5Aget_type(attr_id);
                    fieldnames_vl = malloc(nfields*sizeof(*fieldnames_vl));
                    H5Aread(attr_id,field_id,fieldnames_vl);

                    matvar->internal->num_fields = nfields;
                    matvar->internal->fieldnames =
                        calloc(nfields,sizeof(*matvar->internal->fieldnames));
                    for ( i = 0; i < nfields; i++ ) {
                        matvar->internal->fieldnames[i] =
                            calloc(fieldnames_vl[i].len+1,1);
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
                H5Eset_auto(H5E_DEFAULT,efunc,client_data);
            }

            if ( matvar->internal->id != dset_id ) {
                /* Close dataset and increment count */
                H5Dclose(dset_id);
            }
            mat->next_index++;
            break;
        }
        case H5G_GROUP:
        {
            ssize_t name_len;
            hid_t   dset_id;

            matvar->internal->fp = mat;
            name_len = H5Gget_objname_by_idx(fid,mat->next_index,NULL,0);
            matvar->name = malloc(1+name_len);
            if ( matvar->name ) {
                name_len = H5Gget_objname_by_idx(fid,mat->next_index,
                                                 matvar->name,1+name_len);
                matvar->name[name_len] = '\0';
            }
            dset_id = H5Gopen(fid,matvar->name,H5P_DEFAULT);

            Mat_H5ReadGroupInfo(mat,matvar,dset_id);
            H5Gclose(dset_id);
            mat->next_index++;
            break;
        }
        default:
            break;
    }
    return matvar;
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

    matvar->compression = compress;

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
    cells = malloc(N*sizeof(matvar_t *));
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
        cells = malloc(edge*sizeof(matvar_t *));
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

    cells = matvar->data;
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
 * @param matvar Pointer to store the new structure MATLAB variable
 * @return @c MATIO_SUCCESS if successful, or an error value (See
 *          @ref enum matio_error_t).
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
    matvar->dims = malloc(matvar->rank*sizeof(*matvar->dims));
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
            malloc(nfields*sizeof(*matvar->internal->fieldnames));
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
 * @param fields Array of fields to be added
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
    realloc(matvar->internal->fieldnames,
            nfields*sizeof(*matvar->internal->fieldnames));
    matvar->internal->fieldnames[nfields-1] = mat_strdup(fieldname);

    new_data = malloc(nfields*nmemb*sizeof(*new_data));
    if ( new_data == NULL )
        return -1;

    old_data = matvar->data;
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
 * @param name Name of the structure field
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
        field = Mat_VarGetStructFieldByName(matvar,name_or_index,index);
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
    fields = struct_slab->data;
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
        fields = struct_slab->data;
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
        matvar_t **fields = matvar->data;
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
        matvar_t **fields = matvar->data;
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
