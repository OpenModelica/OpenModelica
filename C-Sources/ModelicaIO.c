/* ModelicaIO.c - Array I/O functions

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

#if !defined(MODELICA_EXPORT)
  #define MODELICA_EXPORT
#endif

#include <stdlib.h>
#include <string.h>
#include "ModelicaUtilities.h"

#ifdef NO_FILE_SYSTEM
static void ModelicaNotExistError(const char* name) {
  /* Print error message if a function is not implemented */
    ModelicaFormatError("C-Function \"%s\" is called "
        "but is not implemented for the actual environment "
        "(e.g., because there is no file system available on the machine "
        "as for dSPACE or xPC systems)\n", name);
}

MODELICA_EXPORT void ModelicaIO_readMatrixSizes(const char* fileName,
    const char* varName, int* dim) {
    ModelicaNotExistError("ModelicaIO_readMatrixSizes"); }
MODELICA_EXPORT void ModelicaIO_readRealMatrix(const char* fileName,
    const char* varName, double* a, size_t m, size_t n, int verbose) {
    ModelicaNotExistError("ModelicaIO_readRealMatrix"); }
MODELICA_EXPORT int ModelicaIO_writeRealMatrix(const char* fileName,
    const char* varName, double* a, size_t m, size_t n, int append, const char* version) {
    ModelicaNotExistError("ModelicaIO_writeRealMatrix"); return 0; }
#else

#include <stdio.h>
#include "ModelicaIO.h"
#include "ModelicaMatIO.h"

static void transpose(double* table, size_t nRow, size_t nCol) {
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

MODELICA_EXPORT void ModelicaIO_readMatrixSizes(const char* fileName,
    const char* varName, int* dim) {
    mat_t* mat;
    matvar_t* matvar;
    matvar_t* matvarRoot;
    char* varNameCopy;
    char* token;

    varNameCopy = (char*)malloc((strlen(varName) + 1)*sizeof(char));
    if (varNameCopy != NULL) {
        strcpy(varNameCopy, varName);
    }
    else {
        dim[0] = 0;
        dim[1] = 0;
        ModelicaError("Memory allocation error\n");
        return;
    }

    mat = Mat_Open(fileName, (int)MAT_ACC_RDONLY);
    if (mat == NULL) {
        dim[0] = 0;
        dim[1] = 0;
        free(varNameCopy);
        ModelicaFormatError("Not possible to open file \"%s\": "
            "No such file or directory\n", fileName);
        return;
    }

    token = strtok(varNameCopy, ".");
    matvarRoot = Mat_VarReadInfo(mat, token == NULL ? varName : token);
    if (matvarRoot == NULL) {
        dim[0] = 0;
        dim[1] = 0;
        free(varNameCopy);
        (void)Mat_Close(mat);
        ModelicaFormatError(
            "Variable \"%s\" not found on file \"%s\".\n",
            token == NULL ? varName : token, fileName);
        return;
    }

    matvar = matvarRoot;
    token = strtok(NULL, ".");
    /* Get field while matvar is of struct class and of 1x1 size */
    while (token != NULL && matvar != NULL &&
        matvar->class_type == MAT_C_STRUCT && matvar->rank == 2 &&
        matvar->dims[0] == 1 && matvar->dims[1] == 1) {
        matvar = Mat_VarGetStructField(matvar, (void*)token, MAT_BY_NAME, 0);
        token = strtok(NULL, ".");
    }
    free(varNameCopy);

    if (matvar == NULL) {
        Mat_VarFree(matvarRoot);
        (void)Mat_Close(mat);
        ModelicaFormatError(
            "Matrix \"%s\" not found on file \"%s\".\n", varName, fileName);
        return;
    }

    /* Check if matvar is a matrix */
    if (matvar->rank != 2) {
        dim[0] = 0;
        dim[1] = 0;
        Mat_VarFree(matvarRoot);
        (void)Mat_Close(mat);
        ModelicaFormatError(
            "Array \"%s\" has not the required rank 2.\n", varName);
        return;
    }

    dim[0] = (int)matvar->dims[0];
    dim[1] = (int)matvar->dims[1];

    Mat_VarFree(matvarRoot);
    (void)Mat_Close(mat);
}

MODELICA_EXPORT void ModelicaIO_readRealMatrix(const char* fileName,
    const char* varName, double* a, size_t m, size_t n, int verbose) {
    mat_t* mat;
    matvar_t* matvar;
    matvar_t* matvarRoot;
    size_t nRow, nCol;
    int tableReadError = 0;
    char* varNameCopy;
    char* token;

    if (verbose == 1) {
        /* Print info message, that matrix / file is loading */
        ModelicaFormatMessage("... loading \"%s\" from \"%s\"\n",
            varName, fileName);
    }

    varNameCopy = (char*)malloc((strlen(varName) + 1)*sizeof(char));
    if (varNameCopy != NULL) {
        strcpy(varNameCopy, varName);
    }
    else {
        ModelicaError("Memory allocation error\n");
        return;
    }

    mat = Mat_Open(fileName, (int)MAT_ACC_RDONLY);
    if (mat == NULL) {
        free(varNameCopy);
        ModelicaFormatError("Not possible to open file \"%s\": "
            "No such file or directory\n", fileName);
        return;
    }

    token = strtok(varNameCopy, ".");
    matvarRoot = Mat_VarReadInfo(mat, token == NULL ? varName : token);
    if (matvarRoot == NULL) {
        free(varNameCopy);
        (void)Mat_Close(mat);
        ModelicaFormatError(
            "Variable \"%s\" not found on file \"%s\".\n",
            token == NULL ? varName : token, fileName);
        return;
    }

    matvar = matvarRoot;
    token = strtok(NULL, ".");
    /* Get field while matvar is of struct class and of 1x1 size */
    while (token != NULL && matvar != NULL &&
        matvar->class_type == MAT_C_STRUCT && matvar->rank == 2 &&
        matvar->dims[0] == 1 && matvar->dims[1] == 1) {
        matvar = Mat_VarGetStructField(matvar, (void*)token, MAT_BY_NAME, 0);
        token = strtok(NULL, ".");
    }
    free(varNameCopy);

    if (matvar == NULL) {
        Mat_VarFree(matvarRoot);
        (void)Mat_Close(mat);
        ModelicaFormatError(
            "Matrix \"%s\" not found on file \"%s\".\n", varName, fileName);
        return;
    }

    /* Check if matvar is a matrix */
    if (matvar->rank != 2) {
        Mat_VarFree(matvarRoot);
        (void)Mat_Close(mat);
        ModelicaFormatError(
            "Array \"%s\" has not the required rank 2.\n", varName);
        return;
    }

    /* Check if matvar is of double precision class (and thus non-sparse) */
    if (matvar->class_type != MAT_C_DOUBLE) {
        Mat_VarFree(matvarRoot);
        (void)Mat_Close(mat);
        ModelicaFormatError("2D array \"%s\" has not the required "
            "double precision class.\n", varName);
        return;
    }

    /* Check if matvar is purely real-valued */
    if (matvar->isComplex) {
        Mat_VarFree(matvarRoot);
        (void)Mat_Close(mat);
        ModelicaFormatError("2D array \"%s\" must not be complex.\n",
            varName);
        return;
    }

    nRow = matvar->dims[0];
    nCol = matvar->dims[1];

    /* Check if number of rows matches */
    if (m != nRow) {
        Mat_VarFree(matvarRoot);
        (void)Mat_Close(mat);
        ModelicaFormatError(
            "Cannot read %lu rows of array \"%s(%lu,%lu)\" "
            "from file \"%s\"\n", (unsigned long)m, varName,
            (unsigned long)nRow, (unsigned long)nCol, fileName);
        return;
    }

    /* Check if number of columns matches */
    if (n != nCol) {
        Mat_VarFree(matvarRoot);
        (void)Mat_Close(mat);
        ModelicaFormatError(
            "Cannot read %lu columns of array \"%s(%lu,%lu)\" "
            "from file \"%s\"\n", (unsigned long)n, varName,
            (unsigned long)nRow, (unsigned long)nCol, fileName);
        return;
    }

    tableReadError = Mat_VarReadDataAll(mat, matvar);
    if (tableReadError == 0) {
        matvar->mem_conserve = 1;
        a = (double*)matvar->data;
    }

    Mat_VarFree(matvarRoot);
    (void)Mat_Close(mat);

    if (tableReadError == 0) {
        /* Array is stored column-wise -> need to transpose */
        transpose(a, nRow, nCol);
    }
    else {
        ModelicaFormatError(
            "Error when reading numeric data of matrix \"%s(%lu,%lu)\" "
            "from file \"%s\"\n", varName, (unsigned long)nRow,
            (unsigned long)nCol, fileName);
        return;
    }
}

MODELICA_EXPORT int ModelicaIO_writeRealMatrix(const char* fileName,
    const char* varName, double* a, size_t m, size_t n, int append, const char* version) {
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

    if ( append == 0 ) {
        mat = Mat_CreateVer(fileName, NULL, matv);
        if (mat == NULL) {
           ModelicaFormatError("Not possible to newly create file \"%s\"\n(maybe version 7.3 not supported)\n", fileName);
           return 0;
        }
    } else {
        mat = Mat_Open(fileName, (int)MAT_ACC_RDWR | matv);
        if (mat == NULL) {
           ModelicaFormatError("Not possible to open file \"%s\"\n", fileName);
           return 0;
        }
    }

    /* MAT file array is stored column-wise -> need to transpose */
    aT = (double*)malloc(m*n*sizeof(double));
    if (aT == NULL) {
        (void)Mat_Close(mat);
        ModelicaError("Memory allocation error\n");
        return 0;
    }
    memcpy(aT, a, m*n*sizeof(double));
    transpose(aT, n, m);

    if (append != 0) {
        (void)Mat_VarDelete(mat, varName);
    }

    dims[0] = m;
    dims[1] = n;
    matvar = Mat_VarCreate(varName, MAT_C_DOUBLE, MAT_T_DOUBLE, 2, dims, aT, MAT_F_DONT_COPY_DATA);
    status = Mat_VarWrite(mat, matvar, matc);
    Mat_VarFree(matvar);
    (void)Mat_Close(mat);
    free(aT);
    if (status != 0) {
        ModelicaFormatError("Cannot write variable \"%s\" to \"%s\"\n", varName, fileName);
        return 0;
    }
    return 1;
}

#endif
