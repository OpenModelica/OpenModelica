/* ModelicaIO.c - Array I/O functions

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

/* Definition of interface to external functions for array I/O
   in the Modelica Standard Library:

      Modelica.Utilities.Streams.readMatrixSize
      Modelica.Utilities.Streams.readRealMatrix
      Modelica.Utilities.Streams.writeRealMatrix

   Changelog:
      July 08, 2020: by Thomas Beutlich
                     Improved error message if reading text file with zero bytes
                     (ticket #3603)

      Jan. 15, 2018: by Thomas Beutlich, ESI ITI GmbH
                     Added support to ignore UTF-8 BOM if reading text file
                     (ticket #2404)

      Apr. 12, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Improved error messages if reading struct arrays from
                     MATLAB MAT-file fails (ticket #2105)

      Mar. 08, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Added ModelicaIO_readRealTable from ModelicaStandardTables
                     (ticket #2192)

      Feb. 07, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Added support for reading integer and single-precision
                     variable classes of MATLAB MAT-files (ticket #2106)

      Jan. 31, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Added diagnostic message for (supported) partial read of table
                     from a text file (ticket #2151)

      Jan. 07, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Replaced strtok by re-entrant string tokenize function
                     (ticket #1153)

      Nov. 23, 2016: by Martin Sjoelund, SICS East Swedish ICT AB
                     Added NO_LOCALE define flag, in case the OS does
                     not have this (for example when using GCC compiler,
                     but not libc). Also added autoconf detection for
                     this flag, NO_PID, NO_TIME, and NO_FILE_SYSTEM

      Nov. 21, 2016: by Thomas Beutlich, ESI ITI GmbH
                     Fixed error handling if a variable cannot be found in a
                     MATLAB MAT-file (ticket #2119)

      Mar. 03, 2016: by Thomas Beutlich, ITI GmbH and Martin Otter, DLR
                     Implemented a first version (ticket #1856)
*/

#if defined(__gnu_linux__) && !defined(NO_FILE_SYSTEM)
#define _GNU_SOURCE 1
#endif

#include "ModelicaIO.h"
#include <string.h>
#include "ModelicaUtilities.h"

#ifdef NO_FILE_SYSTEM
MODELICA_NORETURN static void ModelicaNotExistError(const char* name) MODELICA_NORETURNATTR;
static void ModelicaNotExistError(const char* name) {
  /* Print error message if a function is not implemented */
    ModelicaFormatError("C-Function \"%s\" is called "
        "but is not implemented for the actual environment "
        "(e.g., because there is no file system available on the machine "
        "as for dSPACE or xPC systems)\n", name);
}

void ModelicaIO_readMatrixSizes(_In_z_ const char* fileName,
    _In_z_ const char* matrixName, _Out_ int* dim) {
    ModelicaNotExistError("ModelicaIO_readMatrixSizes"); }
void ModelicaIO_readRealMatrix(_In_z_ const char* fileName,
    _In_z_ const char* matrixName, _Out_ double* matrix, size_t m, size_t n,
    int verbose) {
    ModelicaNotExistError("ModelicaIO_readRealMatrix"); }
int ModelicaIO_writeRealMatrix(_In_z_ const char* fileName,
    _In_z_ const char* matrixName, _In_ double* matrix, size_t m, size_t n,
    int append, _In_z_ const char* version) {
    ModelicaNotExistError("ModelicaIO_writeRealMatrix"); return 0; }
double* ModelicaIO_readRealTable(_In_z_ const char* fileName,
    _In_z_ const char* matrixName, _Out_ size_t* m, _Out_ size_t* n,
    int verbose) {
    ModelicaNotExistError("ModelicaIO_readRealTable"); return NULL; }
#else

#include <stdio.h>
#if !defined(NO_LOCALE)
#include <locale.h>
#endif
#include "ModelicaMatIO.h"

/* The standard way to detect POSIX is to check _POSIX_VERSION,
 * which is defined in <unistd.h>
 */
#if defined(__unix__) || defined(__linux__) || defined(__APPLE_CC__)
#include <unistd.h>
#endif
#if !defined(_POSIX_) && defined(_POSIX_VERSION)
#define _POSIX_ 1
#endif

/* Use re-entrant string tokenize function if available */
#if defined(_POSIX_)
#elif defined(_MSC_VER) && _MSC_VER >= 1400
#define strtok_r(str, delim, saveptr) strtok_s((str), (delim), (saveptr))
#else
#define strtok_r(str, delim, saveptr) strtok((str), (delim))
#endif

#if !defined(LINE_BUFFER_LENGTH)
#define LINE_BUFFER_LENGTH (64)
#endif
#if !defined(MATLAB_NAME_LENGTH_MAX)
#define MATLAB_NAME_LENGTH_MAX (64)
#endif

typedef struct MatIO {
    mat_t* mat; /* Pointer to MAT-file */
    matvar_t* matvar; /* Pointer to MAT-file variable for data */
    matvar_t* matvarRoot; /* Pointer to MAT-file variable for free */
} MatIO;

static double* readMatTable(_In_z_ const char* fileName, _In_z_ const char* tableName,
                            _Out_ size_t* m, _Out_ size_t* n) MODELICA_NONNULLATTR;
  /* Read a table from a MATLAB MAT-file using MatIO functions

     <- RETURN: Pointer to array (row-wise storage) of table values
  */

static void readMatIO(_In_z_ const char* fileName, _In_z_ const char* matrixName,
                      _Inout_ MatIO* matio);
  /* Read a variable from a MATLAB MAT-file using MatIO functions */

static void readRealMatIO(_In_z_ const char* fileName, _In_z_ const char* matrixName,
                          _Inout_ MatIO* matio);
  /* Read a real variable from a MATLAB MAT-file using MatIO functions */

static double* readTxtTable(_In_z_ const char* fileName, _In_z_ const char* tableName,
                            _Out_ size_t* m, _Out_ size_t* n) MODELICA_NONNULLATTR;
  /* Read a table from a text file

     <- RETURN: Pointer to array (row-wise storage) of table values
  */

static int readLine(_In_ char** buf, _In_ int* bufLen, _In_ FILE* fp) MODELICA_NONNULLATTR;
  /* Read line (of unknown and arbitrary length) from a text file */

static int IsNumber(char* token);
  /*  Check, whether a token represents a floating-point number */

static void transpose(_Inout_ double* table, size_t nRow, size_t nCol) MODELICA_NONNULLATTR;
  /* Cycle-based in-place array transposition */

#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"
#endif

void ModelicaIO_readMatrixSizes(_In_z_ const char* fileName,
                                _In_z_ const char* matrixName,
                                _Out_ int* dim) {
    MatIO matio = {NULL, NULL, NULL};

    dim[0] = 0;
    dim[1] = 0;

    readRealMatIO(fileName, matrixName, &matio);
    if (NULL != matio.matvar) {
        matvar_t* matvar = matio.matvar;

        dim[0] = (int)matvar->dims[0];
        dim[1] = (int)matvar->dims[1];
    }

    Mat_VarFree(matio.matvarRoot);
    (void)Mat_Close(matio.mat);
}

void ModelicaIO_readRealMatrix(_In_z_ const char* fileName,
                               _In_z_ const char* matrixName,
                               _Inout_ double* matrix, size_t m, size_t n,
                               int verbose) {
    MatIO matio = {NULL, NULL, NULL};
    int readError = 0;

    if (verbose == 1) {
        /* Print info message, that matrix / file is loading */
        ModelicaFormatMessage("... loading \"%s\" from \"%s\"\n",
            matrixName, fileName);
    }

    readRealMatIO(fileName, matrixName, &matio);
    if (NULL != matio.matvar) {
        matvar_t* matvar = matio.matvar;

        /* Check if number of rows matches */
        if (m != matvar->dims[0]) {
            Mat_VarFree(matio.matvarRoot);
            (void)Mat_Close(matio.mat);
            ModelicaFormatError(
                "Cannot read %lu rows of array \"%s(%lu,%lu)\" "
                "from file \"%s\"\n", (unsigned long)m, matrixName,
                (unsigned long)matvar->dims[0], (unsigned long)matvar->dims[1],
                fileName);
            return;
        }

        /* Check if number of columns matches */
        if (n != matvar->dims[1]) {
            Mat_VarFree(matio.matvarRoot);
            (void)Mat_Close(matio.mat);
            ModelicaFormatError(
                "Cannot read %lu columns of array \"%s(%lu,%lu)\" "
                "from file \"%s\"\n", (unsigned long)n, matrixName,
                (unsigned long)matvar->dims[0], (unsigned long)matvar->dims[1],
                fileName);
            return;
        }

        {
            int start[2] = {0, 0};
            int stride[2] = {1, 1};
            int edge[2];
            edge[0] = (int)matvar->dims[0];
            edge[1] = (int)matvar->dims[1];
            readError = Mat_VarReadData(matio.mat, matvar, matrix, start, stride, edge);
        }
    }

    Mat_VarFree(matio.matvarRoot);
    (void)Mat_Close(matio.mat);

    if (readError == 0 && NULL != matrix) {
        /* Array is stored column-wise -> need to transpose */
        transpose(matrix, m, n);
    }
    else {
        ModelicaFormatError(
            "Error when reading numeric data of matrix \"%s(%lu,%lu)\" "
            "from file \"%s\"\n", matrixName, (unsigned long)m,
            (unsigned long)n, fileName);
    }
}

int ModelicaIO_writeRealMatrix(_In_z_ const char* fileName,
                               _In_z_ const char* matrixName,
                               _In_ double* matrix, size_t m, size_t n,
                               int append,
                               _In_z_ const char* version) {
    int status;
    mat_t* mat;
    matvar_t* matvar;
    size_t dims[2];
    double* aT;
    enum mat_ft matv;
    enum matio_compression matc;

    if ((0 != strcmp(version, "4")) && (0 != strcmp(version, "6")) && (0 != strcmp(version, "7")) && (0 != strcmp(version, "7.3"))) {
        ModelicaFormatError("Invalid version %s for file \"%s\"\n", version, fileName);
        return 0;
    }
    if (0 == strcmp(version, "4")) {
        matv = MAT_FT_MAT4;
        matc = MAT_COMPRESSION_NONE;
    }
    else if (0 == strcmp(version, "7.3")) {
        matv = MAT_FT_MAT73;
        matc = MAT_COMPRESSION_ZLIB;
    }
    else if (0 == strcmp(version, "7")) {
        matv = MAT_FT_MAT5;
        matc = MAT_COMPRESSION_ZLIB;
    }
    else {
        matv = MAT_FT_MAT5;
        matc = MAT_COMPRESSION_NONE;
    }

    if (append == 0) {
        mat = Mat_CreateVer(fileName, NULL, matv);
        if (NULL == mat) {
            ModelicaFormatError("Not possible to newly create file \"%s\"\n(maybe version 7.3 not supported)\n", fileName);
            return 0;
        }
    } else {
        mat = Mat_Open(fileName, (int)MAT_ACC_RDWR | matv);
        if (NULL == mat) {
            ModelicaFormatError("Not possible to open file \"%s\"\n", fileName);
            return 0;
        }
    }

    /* MAT file array is stored column-wise -> need to transpose */
    aT = (double*)malloc(m*n*sizeof(double));
    if (NULL == aT) {
        (void)Mat_Close(mat);
        ModelicaError("Memory allocation error\n");
        return 0;
    }
    memcpy(aT, matrix, m*n*sizeof(double));
    transpose(aT, n, m);

    if (append != 0) {
        (void)Mat_VarDelete(mat, matrixName);
    }

    dims[0] = m;
    dims[1] = n;
    matvar = Mat_VarCreate(matrixName, MAT_C_DOUBLE, MAT_T_DOUBLE, 2, dims, aT, MAT_F_DONT_COPY_DATA);
    status = Mat_VarWrite(mat, matvar, matc);
    Mat_VarFree(matvar);
    (void)Mat_Close(mat);
    free(aT);
    if (status != 0) {
        ModelicaFormatError("Cannot write variable \"%s\" to \"%s\"\n", matrixName, fileName);
        return 0;
    }
    return 1;
}

double* ModelicaIO_readRealTable(_In_z_ const char* fileName,
                                 _In_z_ const char* tableName,
                                 _Out_ size_t* m, _Out_ size_t* n,
                                 int verbose) {
    double* table = NULL;
    const char* ext;
    int isMatExt = 0;

    /* Table file can be either text or binary MATLAB MAT-file */
    ext = strrchr(fileName, '.');
    if (NULL != ext) {
        if (0 == strncmp(ext, ".mat", 4) ||
            0 == strncmp(ext, ".MAT", 4)) {
            isMatExt = 1;
        }
    }

    if (verbose == 1) {
        /* Print info message, that table / file is loading */
        ModelicaFormatMessage("... loading \"%s\" from \"%s\"\n",
            tableName, fileName);
    }

    if (isMatExt == 1) {
        table = readMatTable(fileName, tableName, m, n);
    }
    else {
        table = readTxtTable(fileName, tableName, m, n);
    }
    return table;
}

void ModelicaIO_freeRealTable(double* table) {
    free(table);
}

static double* readMatTable(_In_z_ const char* fileName, _In_z_ const char* tableName,
                            _Out_ size_t* m, _Out_ size_t* n) {
    double* table = NULL;
    MatIO matio = {NULL, NULL, NULL};
    int readError = 0;

    *m = 0;
    *n = 0;

    readRealMatIO(fileName, tableName, &matio);
    if (NULL != matio.matvar) {
        matvar_t* matvar = matio.matvar;

        table = (double*)malloc(matvar->dims[0]*matvar->dims[1]*sizeof(double));
        if (NULL == table) {
            Mat_VarFree(matio.matvarRoot);
            (void)Mat_Close(matio.mat);
            ModelicaError("Memory allocation error\n");
            return NULL;
        }

        {
            int start[2] = {0, 0};
            int stride[2] = {1, 1};
            int edge[2];
            edge[0] = (int)matvar->dims[0];
            edge[1] = (int)matvar->dims[1];
            readError = Mat_VarReadData(matio.mat, matvar, table, start, stride, edge);
            *m = matvar->dims[0];
            *n = matvar->dims[1];
        }
    }

    Mat_VarFree(matio.matvarRoot);
    (void)Mat_Close(matio.mat);

    if (readError == 0 && NULL != table) {
        /* Array is stored column-wise -> need to transpose */
        transpose(table, *m, *n);
    }
    else {
        size_t dim[2];

        dim[0] = *m;
        dim[1] = *n;
        *m = 0;
        *n = 0;
        free(table);
        table = NULL;
        ModelicaFormatError(
            "Error when reading numeric data of matrix \"%s(%lu,%lu)\" "
            "from file \"%s\"\n", tableName, (unsigned long)dim[0],
            (unsigned long)dim[1], fileName);
    }
    return table;
}

static void readMatIO(_In_z_ const char* fileName,
                      _In_z_ const char* matrixName, _Inout_ MatIO* matio) {
    mat_t* mat;
    matvar_t* matvar;
    matvar_t* matvarRoot;
    char* matrixNameCopy;
    char* token;
#if defined(_POSIX_) || (defined(_MSC_VER) && _MSC_VER >= 1400)
    char* nextToken = NULL;
#endif
    char* prevToken;
    int err = 0;

    mat = Mat_Open(fileName, (int)MAT_ACC_RDONLY);
    if (NULL == mat) {
        ModelicaFormatError("Not possible to open file \"%s\": "
            "No such file or directory\n", fileName);
        return;
    }

    matrixNameCopy = (char*)malloc((strlen(matrixName) + 1) * sizeof(char));
    if (NULL != matrixNameCopy) {
        strcpy(matrixNameCopy, matrixName);
    }
    else {
        (void)Mat_Close(mat);
        ModelicaError("Memory allocation error\n");
        return;
    }

    token = strtok_r(matrixNameCopy, ".", &nextToken);
    matvarRoot = Mat_VarReadInfo(mat, NULL == token ? matrixName : token);
    if (NULL == matvarRoot) {
        (void)Mat_Close(mat);
        if (NULL == token) {
            free(matrixNameCopy);
            ModelicaFormatError(
                "Variable \"%s\" not found on file \"%s\".\n",
                matrixName, fileName);
        }
        else {
            char matrixNameBuf[MATLAB_NAME_LENGTH_MAX];
            char dots[4];
            if (strlen(token) > MATLAB_NAME_LENGTH_MAX - 1) {
                strncpy(matrixNameBuf, token, MATLAB_NAME_LENGTH_MAX - 1);
                matrixNameBuf[MATLAB_NAME_LENGTH_MAX - 1] = '\0';
                strcpy(dots, "...");
            }
            else {
                strcpy(matrixNameBuf, token);
                dots[0] = '\0';
            }
            free(matrixNameCopy);
            ModelicaFormatError(
                "Variable \"%s%s\" not found on file \"%s\".\n",
                matrixNameBuf, dots, fileName);
        }
        return;
    }

    matvar = matvarRoot;
    prevToken = token;
    token = strtok_r(NULL, ".", &nextToken);
    /* Get field while matvar is of struct class and of 1x1 size */
    while (NULL != token && NULL != matvar) {
        if (matvar->class_type == MAT_C_STRUCT && matvar->rank == 2 &&
            matvar->dims[0] == 1 && matvar->dims[1] == 1) {
            matvar = Mat_VarGetStructField(matvar, (void*)token, MAT_BY_NAME, 0);
            token = strtok_r(NULL, ".", &nextToken);
        }
        else if (matvar->class_type != MAT_C_STRUCT) {
            err = 1;
            matvar = NULL;
            break;
        }
        else if (matvar->rank != 2) {
            err = 2;
            matvar = NULL;
            break;
        }
        else if (matvar->dims[0] != 1 || matvar->dims[2] != 1) {
            err = 3;
            matvar = NULL;
            break;
        }
    }

    if (NULL == matvar) {
        Mat_VarFree(matvarRoot);
        (void)Mat_Close(mat);
        if (NULL != token) {
            char matrixNameBuf[MATLAB_NAME_LENGTH_MAX];
            char dots[4];
            if (strlen(prevToken) > MATLAB_NAME_LENGTH_MAX - 1) {
                strncpy(matrixNameBuf, prevToken, MATLAB_NAME_LENGTH_MAX - 1);
                matrixNameBuf[MATLAB_NAME_LENGTH_MAX - 1] = '\0';
                strcpy(dots, "...");
            }
            else {
                strcpy(matrixNameBuf, prevToken);
                dots[0] = '\0';
            }
            free(matrixNameCopy);
            if (1 == err) {
                ModelicaFormatError(
                    "Variable \"%s%s\" of \"%s\" is not a struct array.\n",
                    matrixNameBuf, dots, matrixName);
            }
            else if (2 == err) {
                ModelicaFormatError(
                    "Variable \"%s%s\" of \"%s\" is not a struct array "
                    "of rank 2.\n",  matrixNameBuf, dots, matrixName);
            }
            else if (3 == err) {
                ModelicaFormatError(
                    "Variable \"%s%s\" of \"%s\" is not a 1x1 struct array.\n",
                    matrixNameBuf, dots, matrixName);
            }
        }
        else {
            free(matrixNameCopy);
            ModelicaFormatError(
                "Variable \"%s\" not found on file \"%s\".\n", matrixName, fileName);
        }
        return;
    }
    free(matrixNameCopy);

    /* Check if matvar is a matrix */
    if (matvar->rank != 2) {
        Mat_VarFree(matvarRoot);
        (void)Mat_Close(mat);
        ModelicaFormatError(
            "Variable \"%s\" is not of rank 2.\n", matrixName);
        return;
    }

    /* Set output fields for MatIO structure */
    matio->mat = mat;
    matio->matvar = matvar;
    matio->matvarRoot = matvarRoot;
}

static void readRealMatIO(_In_z_ const char* fileName,
                          _In_z_ const char* matrixName, _Inout_ MatIO* matio) {
    readMatIO(fileName, matrixName, matio);
    if (NULL != matio->matvar) {
        matvar_t* matvar = matio->matvar;

        /* Check if variable class of matvar is numeric (and thus non-sparse) */
        if (matvar->class_type != MAT_C_DOUBLE && matvar->class_type != MAT_C_SINGLE &&
            matvar->class_type != MAT_C_INT8 && matvar->class_type != MAT_C_UINT8 &&
            matvar->class_type != MAT_C_INT16 && matvar->class_type != MAT_C_UINT16 &&
            matvar->class_type != MAT_C_INT32 && matvar->class_type != MAT_C_UINT32 &&
            matvar->class_type != MAT_C_INT64 && matvar->class_type != MAT_C_UINT64) {
            Mat_VarFree(matio->matvarRoot);
            (void)Mat_Close(matio->mat);
            ModelicaFormatError("Matrix \"%s\" is not a "
                "numeric array.\n", matrixName);
            return;
        }
        matvar->class_type = MAT_C_DOUBLE;

        /* Check if matvar is purely real-valued */
        if (matvar->isComplex) {
            Mat_VarFree(matio->matvarRoot);
            (void)Mat_Close(matio->mat);
            ModelicaFormatError("Matrix \"%s\" must not be complex.\n",
                matrixName);
            return;
        }
    }
}

static int IsNumber(char* token) {
    int foundExponentSign = 0;
    int foundExponent = 0;
    int foundDec = 0;
    int foundDigit = 0;
    int isNumber = 1;
    int k;

    if (token[0] == '-' || token[0] == '+') {
        k = 1;
    }
    else {
        k = 0;
    }
    while (token[k] != '\0') {
        if (token[k] >= '0' && token[k] <= '9') {
            k++;
            foundDigit++;
        }
        else if (token[k] == '.' && foundDec == 0 &&
            foundExponent == 0 && foundExponentSign == 0) {
            foundDec = 1;
            k++;
        }
        else if ((token[k] == 'e' || token[k] == 'E') &&
            foundExponent == 0 && foundDigit > 0) {
            foundExponent = 1;
            foundDigit = 0;
            k++;
        }
        else if ((token[k] == '-' || token[k] == '+') &&
            foundExponent == 1 && foundExponentSign == 0) {
            foundExponentSign = 1;
            k++;
        }
        else {
            isNumber = 0;
            break;
        }
    }
    return isNumber && foundDigit > 0;
}

static double* readTxtTable(_In_z_ const char* fileName, _In_z_ const char* tableName,
                            _Out_ size_t* m, _Out_ size_t* n) {
#define DELIM_TABLE_HEADER " \t(,)\r"
#define DELIM_TABLE_NUMBER " \t,;\r"
    double* table = NULL;
    char* buf;
    char* header;
    int bufLen = LINE_BUFFER_LENGTH;
    FILE* fp;
    int foundTable = 0;
    int readError;
    unsigned long nRow = 0;
    unsigned long nCol = 0;
    unsigned long lineNo = 1;
    const unsigned char txtHeader[2] = { 0x23,0x31 };
    const unsigned char utf8BOM[3] = { 0xef,0xbb,0xbf };
#if defined(NO_LOCALE)
    const char * const dec = ".";
#elif defined(_MSC_VER) && _MSC_VER >= 1400
    _locale_t loc;
#elif defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3)
    locale_t loc;
#else
    char* dec;
#endif

    fp = fopen(fileName, "r");
    if (NULL == fp) {
        ModelicaFormatError("Not possible to open file \"%s\": "
            "No such file or directory\n", fileName);
        return NULL;
    }

    buf = (char*)calloc(LINE_BUFFER_LENGTH, sizeof(char));
    if (NULL == buf) {
        fclose(fp);
        ModelicaError("Memory allocation error\n");
        return NULL;
    }

    /* Read file header */
    if ((readError = readLine(&buf, &bufLen, fp)) == EOF) {
        free(buf);
        fclose(fp);
        if (readError < 0) {
            ModelicaFormatError(
                "Error reading first line from file \"%s\": "
                "End-Of-File reached.\n", fileName);
        }
        return NULL;
    }

    header = buf;
    /* Ignore optional UTF-8 BOM */
    if (0 == memcmp(buf, utf8BOM, sizeof(utf8BOM)))
    {
        header += sizeof(utf8BOM);
    }

    /* Expected file header format: "#1" */
    if (0 != memcmp(header, txtHeader, sizeof(txtHeader))) {
        size_t len = strlen(header);
        fclose(fp);
        if (len == 0) {
            free(buf);
            ModelicaFormatError(
                "Error reading format and version information in first "
                "line of file \"%s\": \"#1\" expected.\n", fileName);
        }
        else if (len == 1) {
            char c0 = header[0];
            free(buf);
            ModelicaFormatError(
                "Error reading format and version information in first "
                "line of file \"%s\": \"#1\" expected, but \"0x%02x\" found.\n",
                fileName, (int)(c0 & 0xff));
        }
        else {
            char c0 = header[0];
            char c1 = header[1];
            free(buf);
            ModelicaFormatError(
                "Error reading format and version information in first "
                "line of file \"%s\": \"#1\" expected, but \"0x%02x0x%02x\" "
                "found.\n", fileName, (int)(c0 & 0xff), (int)(c1 & 0xff));
        }
        return NULL;
    }

#if defined(NO_LOCALE)
#elif defined(_MSC_VER) && _MSC_VER >= 1400
    loc = _create_locale(LC_NUMERIC, "C");
#elif defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3)
    loc = newlocale(LC_NUMERIC, "C", NULL);
#else
    dec = localeconv()->decimal_point;
#endif

    /* Loop over lines of file */
    while (readLine(&buf, &bufLen, fp) == 0) {
        char* token;
        char* endptr;
#if defined(_POSIX_) || (defined(_MSC_VER) && _MSC_VER >= 1400)
        char* nextToken = NULL;
#endif

        lineNo++;
        /* Expected table header format: "dataType tableName(nRow,nCol)" */
        token = strtok_r(buf, DELIM_TABLE_HEADER, &nextToken);
        if (NULL == token) {
            continue;
        }
        if ((0 != strcmp(token, "double")) && (0 != strcmp(token, "float"))) {
            continue;
        }
        token = strtok_r(NULL, DELIM_TABLE_HEADER, &nextToken);
        if (NULL == token) {
            continue;
        }
        if (0 == strcmp(token, tableName)) {
            foundTable = 1;
        }
        else {
            continue;
        }
        token = strtok_r(NULL, DELIM_TABLE_HEADER, &nextToken);
        if (NULL == token) {
            continue;
        }
#if !defined(NO_LOCALE) && (defined(_MSC_VER) && _MSC_VER >= 1400)
        nRow = (unsigned long)_strtol_l(token, &endptr, 10, loc);
#elif !defined(NO_LOCALE) && (defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3))
        nRow = (unsigned long)strtol_l(token, &endptr, 10, loc);
#else
        nRow = (unsigned long)strtol(token, &endptr, 10);
#endif
        if (*endptr != 0) {
            continue;
        }
        token = strtok_r(NULL, DELIM_TABLE_HEADER, &nextToken);
        if (NULL == token) {
            continue;
        }
#if !defined(NO_LOCALE) && (defined(_MSC_VER) && _MSC_VER >= 1400)
        nCol = (unsigned long)_strtol_l(token, &endptr, 10, loc);
#elif !defined(NO_LOCALE) && (defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3))
        nCol = (unsigned long)strtol_l(token, &endptr, 10, loc);
#else
        nCol = (unsigned long)strtol(token, &endptr, 10);
#endif
        if (*endptr != 0) {
            continue;
        }

        { /* foundTable == 1 */
            size_t i = 0;
            size_t j = 0;

            table = (double*)malloc(nRow*nCol*sizeof(double));
            if (NULL == table) {
                *m = 0;
                *n = 0;
                free(buf);
                fclose(fp);
#if defined(NO_LOCALE)
#elif defined(_MSC_VER) && _MSC_VER >= 1400
                _free_locale(loc);
#elif defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3)
                freelocale(loc);
#endif
                ModelicaError("Memory allocation error\n");
                return table;
            }

            /* Loop over rows and store table row-wise */
            while (readError == 0 && i < nRow) {
                int k = 0;

                lineNo++;
                if ((readError = readLine(&buf, &bufLen, fp)) != 0) {
                    break;
                }
                /* Ignore leading white space */
                while (k < bufLen - 1) {
                    if (buf[k] != ' ' && buf[k] != '\t') {
                        break;
                    }
                    k++;
                }
                if (buf[k] == '\0' || buf[k] == '#') {
                    /* Skip empty or comment line */
                    continue;
                }
#if defined(_POSIX_) || (defined(_MSC_VER) && _MSC_VER >= 1400)
                nextToken = NULL;
#endif
                token = strtok_r(&buf[k], DELIM_TABLE_NUMBER, &nextToken);
                while (NULL != token && i < nRow && j < nCol) {
                    if (token[0] == '#') {
                        /* Skip trailing comment line */
                        break;
                    }
#if !defined(NO_LOCALE) && (defined(_MSC_VER) && _MSC_VER >= 1400)
                    table[i*nCol + j] = _strtod_l(token, &endptr, loc);
                    if (*endptr != 0) {
                        readError = 1;
                    }
#elif !defined(NO_LOCALE) && (defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3))
                    table[i*nCol + j] = strtod_l(token, &endptr, loc);
                    if (*endptr != 0) {
                        readError = 1;
                    }
#else
                    if (*dec == '.') {
                        table[i*nCol + j] = strtod(token, &endptr);
                    }
                    else if (NULL == strchr(token, '.')) {
                        table[i*nCol + j] = strtod(token, &endptr);
                    }
                    else {
                        char* token2 = (char*)malloc(
                            (strlen(token) + 1)*sizeof(char));
                        if (NULL != token2) {
                            char* p;
                            strcpy(token2, token);
                            p = strchr(token2, '.');
                            *p = *dec;
                            table[i*nCol + j] = strtod(token2, &endptr);
                            if (*endptr != 0) {
                                readError = 1;
                            }
                            free(token2);
                        }
                        else {
                            *m = 0;
                            *n = 0;
                            free(buf);
                            fclose(fp);
                            readError = 1;
                            ModelicaError("Memory allocation error\n");
                            break;
                        }
                    }
#endif
                    if (++j == nCol) {
                        i++; /* Increment row index */
                        j = 0; /* Reset column index */
                    }
                    if (readError == 0) {
                        token = strtok_r(NULL, DELIM_TABLE_NUMBER, &nextToken);
                        continue;
                    }
                    else {
                        break;
                    }
                }
                /* Check for trailing non-comment character */
                if (NULL != token && token[0] != '#') {
                    readError = 1;
                    /* Check for trailing number (on same line) */
                    if (i == nRow && 1 == IsNumber(token)) {
                        readError = 2;
                    }
                    break;
                }
                /* Extra check for partial table read */
                else if (NULL == token && 0 == readError && i == nRow) {
                    unsigned long lineNoPartial = lineNo;
                    int tableReadPartial = 0;
                    while (readLine(&buf, &bufLen, fp) == 0) {
                        k = 0;
                        lineNoPartial++;
                        /* Ignore leading white space */
                        while (k < bufLen - 1) {
                            if (buf[k] != ' ' && buf[k] != '\t') {
                                break;
                            }
                            k++;
                        }
                        if (buf[k] == '\0' || buf[k] == '#') {
                            /* Skip empty or comment line */
                            continue;
                        }
#if defined(_POSIX_) || (defined(_MSC_VER) && _MSC_VER >= 1400)
                        nextToken = NULL;
#endif
                        token = strtok_r(&buf[k], DELIM_TABLE_NUMBER, &nextToken);
                        if (NULL != token) {
                            if (1 == IsNumber(token)) {
                                tableReadPartial = 1;
                            }
                            /* Else, it is not a number: No further check
                               is performed, if legal or not
                            */
                        }
                        break;
                    }
                    if (1 == tableReadPartial) {
                        ModelicaFormatWarning(
                            "The table dimensions of matrix \"%s(%lu,%lu)\" from file "
                            "\"%s\" do not match the actual table size (line %lu).\n",
                            tableName, nRow, nCol, fileName, lineNoPartial);
                    }
                    break;
                }
            }
            break;
        }
    }

    free(buf);
    fclose(fp);
#if defined(NO_LOCALE)
#elif defined(_MSC_VER) && _MSC_VER >= 1400
    _free_locale(loc);
#elif defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3)
    freelocale(loc);
#endif
    if (foundTable == 0) {
        ModelicaFormatError(
            "Table matrix \"%s\" not found on file \"%s\".\n",
            tableName, fileName);
        return table;
    }

    if (readError == 0) {
        *m = (size_t)nRow;
        *n = (size_t)nCol;
    }
    else {
        free(table);
        table = NULL;
        *m = 0;
        *n = 0;
        if (readError == EOF) {
            ModelicaFormatError(
                "End-of-file reached when reading numeric data of matrix "
                "\"%s(%lu,%lu)\" from file \"%s\"\n", tableName, nRow,
                nCol, fileName);
        }
        else if (readError == 2) {
            ModelicaFormatError(
                "The table dimensions of matrix \"%s(%lu,%lu)\" from file "
                "\"%s\" do not match the actual table size (line %lu).\n",
                tableName, nRow, nCol, fileName, lineNo);
        }
        else {
            ModelicaFormatError(
                "Error in line %lu when reading numeric data of matrix "
                "\"%s(%lu,%lu)\" from file \"%s\"\n", lineNo, tableName,
                nRow, nCol, fileName);
        }
    }
    return table;
#undef DELIM_TABLE_HEADER
#undef DELIM_TABLE_NUMBER
}

static int readLine(_In_ char** buf, _In_ int* bufLen, _In_ FILE* fp) {
    char* offset;
    int oldBufLen;

    if (fgets(*buf, *bufLen, fp) == NULL) {
        return EOF;
    }

    do {
        char* p;
        char* tmp;

        if ((p = strchr(*buf, '\n')) != NULL) {
            *p = '\0';
            return 0;
        }
        if ((p = memchr(*buf, 0, (size_t)(*bufLen - 1))) != NULL) {
            return 1;
        }

        oldBufLen = *bufLen;
        *bufLen *= 2;
        tmp = (char*)realloc(*buf, (size_t)*bufLen);
        if (NULL == tmp) {
            fclose(fp);
            free(*buf);
            ModelicaError("Memory allocation error\n");
            return 1;
        }
        *buf = tmp;
        offset = &((*buf)[oldBufLen - 1]);

    } while (fgets(offset, oldBufLen + 1, fp));

    return 0;
}

static void transpose(_Inout_ double* table, size_t nRow, size_t nCol) {
  /* Reference:

     Cycle-based in-place array transposition
     (http://en.wikipedia.org/wiki/In-place_matrix_transposition#Non-square_matrices:_Following_the_cycles)
  */

    size_t i;
    for (i = 1; i < nRow*nCol - 1; i++) {
        size_t x = nRow*(i % nCol) + i/nCol; /* predecessor of i in the cycle */
        /* Continue if cycle is of length one or predecessor already was visited */
        if (x <= i) {
            continue;
        }
        /* Continue if cycle already was visited */
        while (x > i) {
            x = nRow*(x % nCol) + x/nCol;
        }
        if (x < i) {
            continue;
        }
        {
            double tmp = table[i];
            size_t s = i; /* start index in the cycle */
            x = nRow*(i % nCol) + i/nCol; /* predecessor of i in the cycle */
            while (x != i) {
                table[s] = table[x];
                s = x;
                x = nRow*(x % nCol) + x/nCol;
            }
            table[s] = tmp;
        }
    }
}

#if defined(__clang__)
#pragma clang diagnostic pop
#endif

#endif
