/* ModelicaStandardTable.c - External table functions

   Copyright (C) 2013-2015, Modelica Association, DLR and ITI GmbH
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

/* Implementation of external functions for table computation
   in the Modelica Standard Library:

      Modelica.Blocks.Sources.CombiTimeTable
      Modelica.Blocks.Tables.CombiTable1D
      Modelica.Blocks.Tables.CombiTable1Ds
      Modelica.Blocks.Tables.CombiTable2D

   The following #define's are available.

   NO_FILE_SYSTEM        : A file system is not present (e.g. on dSPACE or xPC).
   DEBUG_TIME_EVENTS     : Trace time events of CombiTimeTable
   DUMMY_FUNCTION_USERTAB: Use a dummy function "usertab"
   NO_TABLE_COPY         : Do not copy table data passed to _init functions
                           This is a potentially unsafe optimization (ticket #1143).
   TABLE_SHARE           : If NO_FILE_SYTEM is not defined then common/shared table
                           arrays are stored in a global hash table in order to
                           avoid superfluous file input access and to decrease the
                           utilized memory (tickets #1110 and #1550).

   Release Notes:
      Nov. 25, 2015: by Thomas Beutlich, ITI GmbH
                     Added support of struct variables of MATLAB MAT-files
                     (ticket #1840)

      Nov. 16, 2015: by Thomas Beutlich, ITI GmbH
                     Fixed support of 2x3 and 3x2 2D tables with spline
                     interpolation (ticket #1820)

      Nov. 03, 2015: by Thomas Beutlich, ITI GmbH
                     Added range checks for column indices of CombiTimeTable and
                     CombiTable1D (ticket #1816)

      Aug. 31, 2015: by Thomas Beutlich, ITI GmbH
                     Fixed event detection of CombiTimeTable when using a fixed time
                     step integrator with a step size greater than the event
                     resolution of the table (ticket #1768)

      May 11, 2015:  by Thomas Beutlich, ITI GmbH
                     Added univariate Fritsch-Butland-spline interpolation
                     (ticket #1717)

      Apr. 16, 2015: by Thomas Beutlich, ITI GmbH
                     Fixed event detection of CombiTimeTable with scaled time
                     (ticket #1627)

      Mar. 18, 2015: by Thomas Beutlich, ITI GmbH
                     Fixed poor performance of readMatTable for MATLAB MAT-files with
                     compressed array streams and large (> 1e5) number of rows
                     (ticket #1682)

      Jan. 02, 2015: by Thomas Beutlich, ITI GmbH
                     Fixed event detection of CombiTimeTable with non-zero start time
                     (ticket #1619)

      Aug. 22, 2014: by Thomas Beutlich, ITI GmbH
                     Fixed multi-threaded access of common/shared table arrays
                     (ticket #1556)

      Aug. 07, 2014: by Thomas Beutlich, ITI GmbH
                     Added pure C implementation of common/shared table arrays
                     (ticket #1550)

      May 21, 2014:  by Thomas Beutlich, ITI GmbH
                     Fixed bivariate Akima-spline extrapolation (ticket #1465)

      Oct. 17, 2013: by Thomas Beutlich, ITI GmbH
                     Added support of 2D tables that actually degrade to 1D tables
                     (ticket #1307)

      Sep. 05, 2013: by Thomas Beutlich, ITI GmbH
                     Fixed ANSI-C compliance (ticket #1263)
                     Fixed reading table files with Windows line endings on Linux
                     (ticket #1264)

      Apr. 09, 2013: by Thomas Beutlich, ITI GmbH
                     Implemented a first version
*/

#if defined(__gnu_linux__) && !defined(NO_FILE_SYSTEM)
#define _GNU_SOURCE 1
#endif
#include "ModelicaStandardTables.h"
#include "ModelicaUtilities.h"
#if !defined(NO_FILE_SYSTEM)
#include <stdio.h>
#include <locale.h>
#include "ModelicaMatIO.h"
#if defined(TABLE_SHARE)
#define uthash_fatal(msg) ModelicaFormatMessage("Error: %s\n", msg); break
#include "uthash.h"
#include "gconstructor.h"
#endif
#endif
#include <float.h>
#include <math.h>
#include <string.h>

#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
/* The standard way to detect posix is to check _POSIX_VERSION,
 * which is defined in <unistd.h>
 */
#if defined(__unix__) || defined(__linux__) || defined(__APPLE_CC__)
#include <unistd.h>
#endif
#if !defined(_POSIX_) && defined(_POSIX_VERSION)
#define _POSIX_ 1
#endif
#endif

/* ----- Interface enumerations ----- */

enum Smoothness {
    LINEAR_SEGMENTS = 1,
    CONTINUOUS_DERIVATIVE,
    CONSTANT_SEGMENTS,
    MONOTONE_CONTINUOUS_DERIVATIVE
};

enum Extrapolation {
    HOLD_LAST_POINT = 1,
    LAST_TWO_POINTS,
    PERIODIC,
    NO_EXTRAPOLATION
};

/* ----- Internal enumerations ----- */

enum PointInterval {
    LEFT = -1,
    IN_TABLE = 0,
    RIGHT = 1
};

enum TableSource {
    TABLESOURCE_MODEL = 1,
    TABLESOURCE_FILE,
    TABLESOURCE_FUNCTION,
    TABLESOURCE_FUNCTION_TRANSPOSE
};

/* ----- Internal table memory ----- */

/* 3 (of 4) 1D cubic Hermite spline coefficients (per interval) */
typedef double CubicHermite1D[3];

/* 15 (of 16) 2D cubic Hermite spline coefficients (per grid) */
typedef double CubicHermite2D[15];

/* Left and right interval indices (per interval) */
typedef size_t Interval[2];

typedef struct CombiTimeTable {
    char* fileName; /* Name of table file */
    char* tableName; /* Name of table */
    double* table; /* Table values */
    size_t nRow; /* Number of rows of table */
    size_t nCol; /* Number of columns of table */
    size_t last; /* Last accessed row index of table */
    enum Smoothness smoothness; /* Smoothness kind */
    enum Extrapolation extrapolation; /* Extrapolation kind */
    enum TableSource source; /* Source kind */
    int* cols; /* Columns of table to be interpolated */
    size_t nCols; /* Number of columns of table to be interpolated */
    double startTime; /* Start time of interpolation */
    CubicHermite1D* spline; /* Pre-calculated cubic Hermite spline coefficients,
        only used if smoothness is CONTINUOUS_DERIVATIVE or
        MONOTONE_CONTINUOUS_DERIVATIVE */
    size_t nEvent; /* Time event counter, discrete */
    double preNextTimeEvent; /* Time of previous time event, discrete */
    double preNextTimeEventCalled; /* Time of previous call of
        ModelicaStandardTables_CombiTimeTable_nextTimeEvent, discrete */
    size_t maxEvents; /* Maximum number of time events (per period/cycle) */
    size_t eventInterval; /* Event interval marker, discrete,
        In case of periodic extrapolation this is the current event interval,
        otherwise it is the next event interval. */
    double tOffset; /* Time offset, calculated by floor function, discrete,
        only used if extrapolation is PERIODIC */
    Interval* intervals; /* Event interval indices */
} CombiTimeTable;

typedef struct CombiTable1D {
    char* fileName; /* Name of table file */
    char* tableName; /* Name of table */
    double* table; /* Table values */
    size_t nRow; /* Number of rows of table */
    size_t nCol; /* Number of columns of table */
    size_t last; /* Last accessed row index of table */
    enum Smoothness smoothness; /* Smoothness kind */
    enum TableSource source; /* Source kind */
    int* cols; /* Columns of table to be interpolated */
    size_t nCols; /* Number of columns of table to be interpolated */
    CubicHermite1D* spline; /* Pre-calculated cubic Hermite spline coefficients,
        only used if smoothness is CONTINUOUS_DERIVATIVE or
        MONOTONE_CONTINUOUS_DERIVATIVE */
} CombiTable1D;

typedef struct CombiTable2D {
    char* fileName; /* Name of table file */
    char* tableName; /* Name of table */
    double* table; /* Table values */
    size_t nRow; /* Number of rows of table */
    size_t nCol; /* Number of columns of table */
    size_t last1; /* Last accessed row index of table */
    size_t last2; /* Last accessed column index of table */
    enum Smoothness smoothness; /* Smoothness kind */
    enum TableSource source; /* Source kind */
    CubicHermite2D* spline; /* Pre-calculated cubic Hermite spline coefficients,
        only used if smoothness is CONTINUOUS_DERIVATIVE */
} CombiTable2D;

/* ----- Internal constants ----- */

#define _EPSILON (1e-10)
#define MAX_TABLE_DIMENSIONS (3)
#define LINE_BUFFER_LENGTH (64)

/* ----- Internal shortcuts ----- */

#define IDX(i, j, n) ((i)*(n) + (j))
#define TABLE(i, j) table[IDX(i, j, nCol)]
#define TABLE_ROW0(j) table[j]
#define TABLE_COL0(i) table[(i)*nCol]

#define LINEAR(u, u0, u1, y0, y1) \
    y = (y0) + ((y1) - (y0))*((u) - (u0))/((u1) - (u0));
/*
LINEAR(u0, ...) -> y0
LINEAR(u1, ...) -> y1
*/

#define LINEAR_SLOPE(y0, dy_du, du) ((y0) + (dy_du)*(du))

#define BILINEAR(u1, u2, u10, u11, u20, u21, y00, y01, y10, y11) {\
    const double tmp = ((u2) - (u20))/((u20) - (u21)); \
    y = (y00) + tmp*((y00) - (y01)) + ((u1) - (u10))/((u10) - (u11))* \
        ((1 + tmp)*((y00) - (y10)) + tmp*((y11) - (y01))); \
}
/*
BILINEAR(u10, u20, ...) -> y00
BILINEAR(u10, u21, ...) -> y01
BILINEAR(u11, u20, ...) -> y10
BILINEAR(u11, u21, ...) -> y11
*/

#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
typedef struct TableShare {
    char* key; /* Key consisting of concatenated names of table and file */
    size_t refCount; /* Reference counter */
    size_t nRow; /* Number of rows of table */
    size_t nCol; /* Number of columns of table */
    double* table; /* Table values */
    UT_hash_handle hh; /* Hashable structure */
} TableShare;

/* ----- Static variables ----- */

static TableShare* tableShare = NULL;
#if defined(_POSIX_)
#include <pthread.h>
#if defined(G_HAS_CONSTRUCTORS)
static pthread_mutex_t m;
G_DEFINE_CONSTRUCTOR(initializeMutex)
static void initializeMutex(void) {
    if (pthread_mutex_init(&m, NULL) != 0) {
        ModelicaError("Initialization of mutex failed\n");
    }
}
G_DEFINE_DESTRUCTOR(destroyMutex)
static void destroyMutex(void) {
    if (pthread_mutex_destroy(&m) != 0) {
        ModelicaError("Destruction of mutex failed\n");
    }
}
#else
static pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;
#endif
#define MUTEX_LOCK() pthread_mutex_lock(&m)
#define MUTEX_UNLOCK() pthread_mutex_unlock(&m)
#elif defined(_WIN32) && defined(G_HAS_CONSTRUCTORS)
#if !defined(WIN32_LEAN_AND_MEAN)
#define WIN32_LEAN_AND_MEAN
#endif
#include <Windows.h>
static CRITICAL_SECTION cs;
#ifdef G_DEFINE_CONSTRUCTOR_NEEDS_PRAGMA
#pragma G_DEFINE_CONSTRUCTOR_PRAGMA_ARGS(initializeCS)
#endif
G_DEFINE_CONSTRUCTOR(initializeCS)
static void initializeCS(void) {
    InitializeCriticalSection(&cs);
}
#ifdef G_DEFINE_DESTRUCTOR_NEEDS_PRAGMA
#pragma G_DEFINE_DESTRUCTOR_PRAGMA_ARGS(deleteCS)
#endif
G_DEFINE_DESTRUCTOR(deleteCS)
static void deleteCS(void) {
    DeleteCriticalSection(&cs);
}
#define MUTEX_LOCK() EnterCriticalSection(&cs)
#define MUTEX_UNLOCK() LeaveCriticalSection(&cs)
#else
#define MUTEX_LOCK()
#define MUTEX_UNLOCK()
#endif
#endif

/* ----- Function declarations ----- */

extern int usertab(char* tableName, int nipo, int dim[], int* colWise,
            double** table);
  /* Define tables by statically storing them in function usertab.
     This function can be adapted by the user to his/her needs.

     -> tableName: Name of table
     -> nipo : = 0: time-table required (time interpolation)
               = 1: 1D-table required
               = 2: 2D-table required
     <- dim: Actual values of dimensions
     <- colWise: = 0: table stored row-wise    (row_1, row_2, ..., row_n)
                 = 1: table stored column-wise (column_1, column_2, ...)
     <- table: Pointer to vector containing a matrix with dimensions "dim"
     <- RETURN: = 0: No error
                = 1: An error occurred. An error message is printed from usertab.
  */

static int isNearlyEqual(double x, double y);
  /* Compare two floating-point numbers by threshold _EPSILON */

static size_t findRowIndex(const double* table, size_t nRow, size_t nCol,
    size_t last, double x);
  /* Find the row index i using binary search such that
      * i + 1 < nRow
      * table[i*nCol] <= x
      * table[(i + 1)*nCol] > x for i + 2 < nRow
  */

static size_t findColIndex(_In_ const double* table, size_t nCol, size_t last,
                           double x) MODELICA_NONNULLATTR;
  /* Same as findRowIndex but works on rows */

static int isValidName(_In_z_ const char* name) MODELICA_NONNULLATTR;
  /* Check, whether a file or table name is valid */

static int isValidCombiTimeTable(const CombiTimeTable* tableID);
  /* Check, whether a CombiTimeTable is well parameterized */

static int isValidCombiTable1D(const CombiTable1D* tableID);
  /* Check, whether a CombiTable1D is well parameterized */

static int isValidCombiTable2D(const CombiTable2D* tableID);
  /* Check, whether a CombiTable2D is well parameterized */

static enum TableSource getTableSource(_In_z_ const char *tableName,
                                       _In_z_ const char *fileName) MODELICA_NONNULLATTR;
  /* Determine table source (file, model or "usertab" function) from table
     and file names
  */

static void transpose(_Inout_ double* table, size_t nRow, size_t nCol) MODELICA_NONNULLATTR;
  /* Cycle-based in-place array transposition */

#if !defined(NO_FILE_SYSTEM)
static double* readTable(_In_z_ const char* tableName, _In_z_ const char* fileName,
                         _Inout_ size_t* nRow, _Inout_ size_t* nCol, int verbose,
                         int force) MODELICA_NONNULLATTR;
  /* Read a table from an ASCII text or MATLAB MAT-file

     <- RETURN: Pointer to array (row-wise storage) of table values
  */

static double* readMatTable(_In_z_ const char* tableName, _In_z_ const char* fileName,
                            _Inout_ size_t* nRow, _Inout_ size_t* nCol) MODELICA_NONNULLATTR;
  /* Read a table from a MATLAB MAT-file using MatIO functions

     <- RETURN: Pointer to array (row-wise storage) of table values
  */

static double* readTxtTable(_In_z_ const char* tableName, _In_z_ const char* fileName,
                            _Inout_ size_t* nRow, _Inout_ size_t* nCol) MODELICA_NONNULLATTR;
  /* Read a table from an ASCII text file

     <- RETURN: Pointer to array (row-wise storage) of table values
  */

static int readLine(_In_ char** buf, _In_ int* bufLen, _In_ FILE* fp) MODELICA_NONNULLATTR;
  /* Read line (of unknown and arbitrary length) from an ASCII text file */
#endif /* #if !defined(NO_FILE_SYSTEM) */

static CubicHermite1D* fritschButlandSpline1DInit(_In_ const double* table,
                                                  size_t nRow, size_t nCol,
                                                  _In_ const int* cols,
                                                  size_t nCols) MODELICA_NONNULLATTR;
  /* Calculate the coefficients for univariate cubic Hermite spline
     interpolation with the Fritsch-Butland slope approximation

     <- RETURN: Pointer to array of coefficients
  */

static CubicHermite1D* akimaSpline1DInit(_In_ const double* table, size_t nRow,
                                         size_t nCol, _In_ const int* cols,
                                         size_t nCols) MODELICA_NONNULLATTR;
  /* Calculate the coefficients for univariate cubic Hermite spline
     interpolation with the Akima slope approximation

     <- RETURN: Pointer to array of coefficients
  */

static void spline1DClose(CubicHermite1D** spline);
  /* Free allocated memory of the 1D cubic Hermite spline coefficients */

static CubicHermite2D* spline2DInit(_In_ const double* table, size_t nRow,
                                    size_t nCol) MODELICA_NONNULLATTR;
  /* Calculate the coefficients for bivariate cubic Hermite spline
     interpolation with the Akima algorithm

     <- RETURN: Pointer to array of coefficients
  */

static void spline2DClose(CubicHermite2D** spline);
  /* Free allocated memory of the 2D cubic Hermite spline coefficients */

/* ----- Interface functions ----- */

void* ModelicaStandardTables_CombiTimeTable_init(const char* tableName,
                                                 const char* fileName,
                                                 double* table,
                                                 size_t nRow, size_t nColumn,
                                                 double startTime, int* cols,
                                                 size_t nCols, int smoothness,
                                                 int extrapolation) {
    CombiTimeTable* tableID = (CombiTimeTable*)calloc(1, sizeof(CombiTimeTable));
    if (tableID != NULL) {
        tableID->smoothness = (enum Smoothness)smoothness;
        tableID->extrapolation = (enum Extrapolation)extrapolation;
        tableID->nCols = nCols;
        if (nCols > 0) {
            tableID->cols = (int*)malloc(tableID->nCols*sizeof(int));
            if (tableID->cols != NULL) {
                memcpy(tableID->cols, cols, tableID->nCols*sizeof(int));
            }
            else {
                free(tableID);
                ModelicaError("Memory allocation error\n");
                return NULL;
            }
        }
        tableID->startTime = startTime;
        tableID->source = getTableSource(tableName, fileName);

        switch (tableID->source) {
            case TABLESOURCE_FILE:
                tableID->tableName = (char*)malloc((strlen(tableName) + 1)*sizeof(char));
                if (tableID->tableName != NULL) {
                    strcpy(tableID->tableName, tableName);
                }
                else {
                    if (nCols > 0) {
                        free(tableID->cols);
                    }
                    free(tableID);
                    ModelicaError("Memory allocation error\n");
                    return NULL;
                }
                tableID->fileName = (char*)malloc((strlen(fileName) + 1)*sizeof(char));
                if (tableID->fileName != NULL) {
                    strcpy(tableID->fileName, fileName);
                }
                else {
                    free(tableID->tableName);
                    if (nCols > 0) {
                        free(tableID->cols);
                    }
                    free(tableID);
                    ModelicaError("Memory allocation error\n");
                    return NULL;
                }
                break;

            case TABLESOURCE_MODEL:
                tableID->nRow = nRow;
                tableID->nCol = nColumn;
                tableID->table = table;
                if (isValidCombiTimeTable((const CombiTimeTable*)tableID)) {
                    if (tableID->nRow <= 2) {
                        if (tableID->smoothness == CONTINUOUS_DERIVATIVE ||
                            tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                            tableID->smoothness = LINEAR_SEGMENTS;
                        }
                    }
                    if (tableID->smoothness == CONTINUOUS_DERIVATIVE) {
                        /* Initialization of the cubic Hermite spline coefficients */
                        tableID->spline = akimaSpline1DInit(table,
                            tableID->nRow, tableID->nCol, (const int*)cols,
                            tableID->nCols);
                        if (tableID->spline == NULL) {
                            if (nCols > 0) {
                                free(tableID->cols);
                            }
                            free(tableID);
                            ModelicaError("Memory allocation error\n");
                            return NULL;
                        }
                    }
                    else if (tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                        /* Initialization of the cubic Hermite spline coefficients */
                        tableID->spline = fritschButlandSpline1DInit(table,
                            tableID->nRow, tableID->nCol, (const int*)cols,
                            tableID->nCols);
                        if (tableID->spline == NULL) {
                            if (nCols > 0) {
                                free(tableID->cols);
                            }
                            free(tableID);
                            ModelicaError("Memory allocation error\n");
                            return NULL;
                        }
                    }
#if !defined(NO_TABLE_COPY)
                    tableID->table = (double*)malloc(
                        tableID->nRow*tableID->nCol*sizeof(double));
                    if (tableID->table != NULL) {
                        memcpy(tableID->table, table, tableID->nRow*
                            tableID->nCol*sizeof(double));
                    }
                    else {
                        if (nCols > 0) {
                            free(tableID->cols);
                        }
                        spline1DClose(&tableID->spline);
                        free(tableID);
                        ModelicaError("Memory allocation error\n");
                        return NULL;
                    }
#endif
                }
                else {
                    tableID->table = NULL;
                }
                break;

            case TABLESOURCE_FUNCTION: {
                int colWise;
                int dim[MAX_TABLE_DIMENSIONS];
                if (usertab((char*)tableName, 0 /* Time-interpolation */, dim,
                    &colWise, &tableID->table) == 0) {
                    if (colWise == 0) {
                        tableID->nRow = (size_t)dim[0];
                        tableID->nCol = (size_t)dim[1];
                    }
                    else {
                        /* Need to transpose */
                        double* tableT = (double*)malloc(dim[0]*dim[1]*sizeof(double));
                        if (tableT != NULL) {
                            memcpy(tableT, tableID->table, dim[0]*dim[1]*sizeof(double));
                            tableID->table = tableT;
                            tableID->nRow = (size_t)dim[1];
                            tableID->nCol = (size_t)dim[0];
                            tableID->source = TABLESOURCE_FUNCTION_TRANSPOSE;
                            transpose(tableID->table, tableID->nRow, tableID->nCol);
                        }
                        else {
                            if (nCols > 0) {
                                free(tableID->cols);
                            }
                            free(tableID);
                            ModelicaError("Memory allocation error\n");
                            return NULL;
                        }
                    }
                    if (isValidCombiTimeTable((const CombiTimeTable*)tableID)) {
                        if (tableID->nRow <= 2) {
                            if (tableID->smoothness == CONTINUOUS_DERIVATIVE ||
                                tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                                tableID->smoothness = LINEAR_SEGMENTS;
                            }
                        }
                        if (tableID->smoothness == CONTINUOUS_DERIVATIVE) {
                            /* Initialization of the cubic Hermite spline coefficients */
                            tableID->spline = akimaSpline1DInit(table,
                                tableID->nRow, tableID->nCol, (const int*)cols,
                                tableID->nCols);
                            if (tableID->spline == NULL) {
                                if (nCols > 0) {
                                    free(tableID->cols);
                                }
                                if (tableID->source == TABLESOURCE_FUNCTION_TRANSPOSE) {
                                    free(tableID->table);
                                }
                                free(tableID);
                                ModelicaError("Memory allocation error\n");
                                return NULL;
                            }
                        }
                        else if (tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                            /* Initialization of the cubic Hermite spline coefficients */
                            tableID->spline = fritschButlandSpline1DInit(table,
                                tableID->nRow, tableID->nCol, (const int*)cols,
                                tableID->nCols);
                            if (tableID->spline == NULL) {
                                if (nCols > 0) {
                                    free(tableID->cols);
                                }
                                if (tableID->source == TABLESOURCE_FUNCTION_TRANSPOSE) {
                                    free(tableID->table);
                                }
                                free(tableID);
                                ModelicaError("Memory allocation error\n");
                                return NULL;
                            }
                        }
                    }
                }
                break;
            }

            case TABLESOURCE_FUNCTION_TRANSPOSE:
                /* Should not be possible to get here */
                break;

            default:
                if (nCols > 0) {
                    free(tableID->cols);
                }
                free(tableID);
                ModelicaError("Table source error\n");
                return NULL;
        }
    }
    else {
        ModelicaError("Memory allocation error\n");
    }
    return (void*)tableID;
}

void ModelicaStandardTables_CombiTimeTable_close(void* _tableID) {
    CombiTimeTable* tableID = (CombiTimeTable*)_tableID;
    if (tableID != NULL) {
        if (tableID->table != NULL && tableID->source == TABLESOURCE_FILE) {
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
            if (tableID->tableName != NULL && tableID->fileName != NULL) {
                char* key = malloc((strlen(tableID->tableName) +
                    strlen(tableID->fileName) + 2)*sizeof(char));
                if (key != NULL) {
                    TableShare *iter;
                    strcpy(key, tableID->tableName);
                    strcat(key, "|");
                    strcat(key, tableID->fileName);
                    MUTEX_LOCK();
                    HASH_FIND_STR(tableShare, key, iter);
                    if (iter != NULL) {
                        /* Share hit */
                        if (--iter->refCount == 0) {
                            free(iter->table);
                            free(iter->key);
                            HASH_DEL(tableShare, iter);
                            free(iter);
                        }
                    }
                    MUTEX_UNLOCK();
                    free(key);
                }
            }
            else {
                /* Should not be possible to get here */
                free(tableID->table);
            }
#else
            free(tableID->table);
#endif
            tableID->table = NULL;
        }
        else if (tableID->table != NULL && (
#if !defined(NO_TABLE_COPY)
            tableID->source == TABLESOURCE_MODEL ||
#endif
            tableID->source == TABLESOURCE_FUNCTION_TRANSPOSE)) {
            free(tableID->table);
            tableID->table = NULL;
        }
        if (tableID->nCols > 0 && tableID->cols != NULL) {
            free(tableID->cols);
            tableID->cols = NULL;
        }
        if (tableID->tableName != NULL) {
            free(tableID->tableName);
            tableID->tableName = NULL;
        }
        if (tableID->fileName != NULL) {
            free(tableID->fileName);
            tableID->fileName = NULL;
        }
        if (tableID->intervals != NULL) {
            free(tableID->intervals);
            tableID->intervals = NULL;
        }
        spline1DClose(&tableID->spline);
        free(tableID);
    }
}

double ModelicaStandardTables_CombiTimeTable_getValue(void* _tableID, int iCol,
                                                      double t, double nextTimeEvent,
                                                      double preNextTimeEvent) {
    double y = 0.;
    CombiTimeTable* tableID = (CombiTimeTable*)_tableID;
    if (tableID != NULL && tableID->table != NULL && tableID->cols != NULL) {
        /* Shift time by start time */
        const double tOld = t;
        t -= tableID->startTime;

        if (t >= 0 && nextTimeEvent < DBL_MAX &&
            nextTimeEvent == preNextTimeEvent &&
            tableID->startTime >= nextTimeEvent) {
            /* Before start time event iteration: Return zero */
            return 0.;
        }
        else if (t >= 0) {
            const double* table = tableID->table;
            const size_t nRow = tableID->nRow;
            const size_t nCol = tableID->nCol;
            const size_t col = (size_t)tableID->cols[iCol - 1] - 1;

            if (nRow == 1) {
                /* Single row */
                y = TABLE_ROW0(col);
            }
            else {
                enum PointInterval extrapolate = IN_TABLE;

                /* Periodic extrapolation */
                if (tableID->extrapolation == PERIODIC) {
                    const double tMin = TABLE_ROW0(0);
                    const double tMax = TABLE_COL0(nRow - 1);
                    const double T = tMax - tMin;
                    /* Event handling for periodic extrapolation */
                    if (nextTimeEvent == preNextTimeEvent &&
                        tOld >= nextTimeEvent) {
                        /* Before event iteration: Return previous
                           interval value */
                        size_t i;
                        if (tableID->smoothness == CONSTANT_SEGMENTS) {
                            i = tableID->intervals[
                                tableID->eventInterval - 1][0];
                        }
                        else {
                            i = tableID->intervals[
                                tableID->eventInterval - 1][1];
                        }
                        y = TABLE(i, col);
                        return y;
                    }
                    else if (nextTimeEvent > preNextTimeEvent &&
                        tOld >= preNextTimeEvent &&
                        tableID->startTime < preNextTimeEvent) {
                        /* In regular (= not start time) event iteration:
                           Return left interval value */
                        size_t i = tableID->intervals[
                            tableID->eventInterval - 1][0];
                        y = TABLE(i, col);
                        return y;
                    }
                    else {
                        /* After event iteration */
                        const size_t i0 = tableID->intervals[
                            tableID->eventInterval - 1][0];
                        const size_t i1 = tableID->intervals[
                            tableID->eventInterval - 1][1];

                        t -= tableID->tOffset;
                        if (t < tMin) {
                            t += T;
                        }
                        else if (t > tMax) {
                            t -= T;
                        }
                        tableID->last = findRowIndex(
                            table, nRow, nCol, tableID->last, t);
                        /* Event interval correction */
                        if (tableID->last < i0) {
                            t = TABLE_COL0(i0);
                        }
                        if (tableID->last >= i1) {
                            if (tableID->eventInterval == 1) {
                                t = TABLE_COL0(i0);
                            }
                            else {
                                t = TABLE_COL0(i1);
                            }
                        }
                    }
                }
                else if (t < TABLE_ROW0(0)) {
                    extrapolate = LEFT;
                }
                else if (t >= TABLE_COL0(nRow - 1)) {
                    extrapolate = RIGHT;
                    if (tableID->extrapolation != PERIODIC) {
                        /* Event handling for non-periodic extrapolation */
                        if (nextTimeEvent == preNextTimeEvent &&
                            nextTimeEvent < DBL_MAX && tOld >= nextTimeEvent) {
                            /* Before event iteration */
                            extrapolate = IN_TABLE;
                        }
                    }
                }

                if (extrapolate == IN_TABLE) {
                    size_t last;
                    if (tableID->extrapolation == PERIODIC) {
                        last = findRowIndex(table, nRow, nCol,
                            tableID->last, t);
                    }
                    else {
                        /* Event handling for non-periodic extrapolation */
                        if (nextTimeEvent == preNextTimeEvent &&
                            nextTimeEvent < DBL_MAX && tOld >= nextTimeEvent) {
                            /* Before event iteration: Return previous
                               interval value */
                            if (tableID->eventInterval == 1) {
                                last = 0;
                            }
                            else if (tableID->smoothness == CONSTANT_SEGMENTS) {
                                last = tableID->intervals[
                                    tableID->eventInterval - 2][0];
                            }
                            else if (tableID->smoothness == LINEAR_SEGMENTS) {
                                last = tableID->intervals[
                                    tableID->eventInterval - 2][1];
                            }
                            else if (t >= TABLE_COL0(nRow - 1)) {
                                last = nRow - 1;
                            }
                            else {
                                last = findRowIndex(table, nRow, nCol,
                                    tableID->last, t);
                            }
                            y = TABLE(last, col);
                            return y;
                        }
                        else {
                            last = findRowIndex(table, nRow, nCol,
                                tableID->last, t);
                            if (tableID->eventInterval > 1) {
                                const size_t i0 = tableID->intervals[
                                    tableID->eventInterval - 2][0];
                                const size_t i1 = tableID->intervals[
                                    tableID->eventInterval - 2][1];

                                /* Event interval correction */
                                if (last < i0) {
                                    last = i0;
                                }
                                if (last >= i1) {
                                    last = i0;
                                }
                            }
                        }
                    }
                    tableID->last = last;

                    /* Interpolation */
                    switch (tableID->smoothness) {
                        case CONSTANT_SEGMENTS:
                            if (t >= TABLE_COL0(last + 1)) {
                                last += 1;
                            }
                            y = TABLE(last, col);
                            break;

                        case LINEAR_SEGMENTS: {
                            const double t0 = TABLE_COL0(last);
                            const double t1 = TABLE_COL0(last + 1);
                            const double y0 = TABLE(last, col);
                            const double y1 = TABLE(last + 1, col);
                            if (isNearlyEqual(t0, t1)) {
                                y = y1;
                            }
                            else {
                                LINEAR(t, t0, t1, y0, y1)
                            }
                            break;
                        }

                        case CONTINUOUS_DERIVATIVE:
                        case MONOTONE_CONTINUOUS_DERIVATIVE:
                            if (tableID->spline != NULL) {
                                const double* c = tableID->spline[
                                    IDX(last, iCol - 1, tableID->nCols)];
                                t -= TABLE_COL0(last);
                                y = TABLE(last, col); /* c[3] = y0 */
                                y += ((c[0]*t + c[1])*t + c[2])*t;
                            }
                            break;

                        default:
                            ModelicaError("Unknown smoothness kind\n");
                            return y;
                    }
                }
                else {
                    /* Extrapolation */
                    switch (tableID->extrapolation) {
                        case NO_EXTRAPOLATION:
                            ModelicaError("Extrapolation error\n");
                            return y;

                        case HOLD_LAST_POINT:
                            y = (extrapolate == RIGHT) ? TABLE(nRow - 1, col) :
                                TABLE_ROW0(col);
                            break;

                        case LAST_TWO_POINTS: {
                            const size_t last =
                                (extrapolate == RIGHT) ? nRow - 2 : 0;
                            const double t0 = TABLE_COL0(last);
                            const double y0 = TABLE(last, col);

                            if (tableID->smoothness == CONTINUOUS_DERIVATIVE ||
                                tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                                if (tableID->spline != NULL) {
                                    const double* c = tableID->spline[
                                        IDX(last, iCol - 1, tableID->nCols)];
                                    if (extrapolate == LEFT) {
                                        y = LINEAR_SLOPE(y0, c[2], t - t0);
                                    }
                                    else /* if (extrapolate == RIGHT) */ {
                                        const double t1 = TABLE_COL0(last + 1);
                                        const double v = t1 - t0;
                                        y = LINEAR_SLOPE(TABLE(last + 1, col),
                                            (3*c[0]*v + 2*c[1])*v + c[2],
                                            t - t1);
                                    }
                                }
                            }
                            else {
                                const double t1 = TABLE_COL0(last + 1);
                                const double y1 = TABLE(last + 1, col);
                                if (isNearlyEqual(t0, t1)) {
                                    y = y1;
                                }
                                else {
                                    LINEAR(t, t0, t1, y0, y1)
                                }
                            }
                            break;
                        }

                        case PERIODIC:
                            /* Should not be possible to get here */
                            break;

                        default:
                            ModelicaError("Unknown extrapolation kind\n");
                            return y;
                    }
                }
            }
        }
    }
    return y;
}

double ModelicaStandardTables_CombiTimeTable_getDerValue(void* _tableID, int iCol,
                                                         double t,
                                                         double nextTimeEvent,
                                                         double preNextTimeEvent,
                                                         double der_t) {
    double der_y = 0.;
    CombiTimeTable* tableID = (CombiTimeTable*)_tableID;
    if (tableID != NULL && tableID->table != NULL && tableID->cols != NULL) {
        /* Shift time by start time */
        const double tOld = t;
        t -= tableID->startTime;

        if (t >= 0 && nextTimeEvent < DBL_MAX &&
            nextTimeEvent == preNextTimeEvent &&
            tableID->startTime >= nextTimeEvent) {
            /* Before start time event iteration: Return zero */
            return 0.;
        }
        else if (t >= 0) {
            const double* table = tableID->table;
            const size_t nRow = tableID->nRow;
            const size_t nCol = tableID->nCol;
            const size_t col = (size_t)tableID->cols[iCol - 1] - 1;

            if (nRow > 1) {
                enum PointInterval extrapolate = IN_TABLE;
                size_t last = 0;
                int haveLast = 0;

                /* Periodic extrapolation */
                if (tableID->extrapolation == PERIODIC) {
                    const double tMin = TABLE_ROW0(0);
                    const double tMax = TABLE_COL0(nRow - 1);
                    const double T = tMax - tMin;
                    /* Event handling for periodic extrapolation */
                    if (nextTimeEvent == preNextTimeEvent &&
                        tOld >= nextTimeEvent) {
                        /* Before event iteration: Return previous
                           interval value */
                        last = tableID->intervals[
                            tableID->eventInterval - 1][1] - 1;
                        haveLast = 1;
                    }
                    else if (nextTimeEvent > preNextTimeEvent &&
                        tOld >= preNextTimeEvent &&
                        tableID->startTime < preNextTimeEvent) {
                        /* In regular (= not start time) event iteration:
                           Return left interval value */
                        last = tableID->intervals[
                            tableID->eventInterval - 1][0];
                        haveLast = 1;
                    }
                    else {
                        /* After event iteration */
                        const size_t i0 = tableID->intervals[
                            tableID->eventInterval - 1][0];
                        const size_t i1 = tableID->intervals[
                            tableID->eventInterval - 1][1];

                        t -= tableID->tOffset;
                        if (t < tMin) {
                            t += T;
                        }
                        else if (t > tMax) {
                            t -= T;
                        }
                        tableID->last = findRowIndex(
                            table, nRow, nCol, tableID->last, t);
                        /* Event interval correction */
                        if (tableID->last < i0) {
                            t = TABLE_COL0(i0);
                        }
                        if (tableID->last >= i1) {
                            if (tableID->eventInterval == 1) {
                                t = TABLE_COL0(i0);
                            }
                            else {
                                t = TABLE_COL0(i1);
                            }
                        }
                    }
                }
                else if (t < TABLE_ROW0(0)) {
                    extrapolate = LEFT;
                }
                else if (t >= TABLE_COL0(nRow - 1)) {
                    extrapolate = RIGHT;
                    if (tableID->extrapolation != PERIODIC) {
                        /* Event handling for non-periodic extrapolation */
                        if (nextTimeEvent == preNextTimeEvent &&
                            nextTimeEvent < DBL_MAX && tOld >= nextTimeEvent) {
                            /* Before event iteration */
                            extrapolate = IN_TABLE;
                        }
                    }
                }

                if (extrapolate == IN_TABLE) {
                    if (tableID->extrapolation != PERIODIC) {
                        /* Event handling for non-periodic extrapolation */
                        if (nextTimeEvent == preNextTimeEvent &&
                            nextTimeEvent < DBL_MAX && tOld >= nextTimeEvent) {
                            /* Before event iteration */
                            if (tableID->eventInterval == 1) {
                                last = 0;
                                extrapolate = LEFT;
                            }
                            else if (tableID->smoothness == CONSTANT_SEGMENTS) {
                                last = tableID->intervals[
                                    tableID->eventInterval - 2][0];
                            }
                            else if (tableID->smoothness == LINEAR_SEGMENTS) {
                                last = tableID->intervals[
                                    tableID->eventInterval - 2][1];
                            }
                            else if (t >= TABLE_COL0(nRow - 1)) {
                                last = nRow - 1;
                            }
                            else {
                                last = findRowIndex(table, nRow, nCol,
                                    tableID->last, t);
                                tableID->last = last;
                            }
                            if (last > 0 && extrapolate == IN_TABLE) {
                                last--;
                            }
                            haveLast = 1;
                        }
                    }

                    if (!haveLast) {
                        last = findRowIndex(table, nRow, nCol, tableID->last, t);
                        tableID->last = last;
                    }

                    if (tableID->extrapolation != PERIODIC &&
                        tableID->eventInterval > 1) {
                        const size_t i0 = tableID->intervals[
                            tableID->eventInterval - 2][0];
                        const size_t i1 = tableID->intervals[
                            tableID->eventInterval - 2][1];

                       if (last < i0) {
                            last = i0;
                        }
                        if (last >= i1) {
                            last = i0;
                        }
                    }
                }

                if (extrapolate == IN_TABLE) {
                    /* Interpolation */
                    switch (tableID->smoothness) {
                        case CONSTANT_SEGMENTS:
                            break;

                        case LINEAR_SEGMENTS: {
                            const double t0 = TABLE_COL0(last);
                            const double t1 = TABLE_COL0(last + 1);
                            if (!isNearlyEqual(t0, t1)) {
                                der_y = (TABLE(last + 1, col) - TABLE(last, col))/
                                    (t1 - t0);
                                der_y *= der_t;
                            }
                            break;
                        }

                        case CONTINUOUS_DERIVATIVE:
                        case MONOTONE_CONTINUOUS_DERIVATIVE:
                            if (tableID->spline != NULL) {
                                const double* c = tableID->spline[
                                    IDX(last, iCol - 1, tableID->nCols)];
                                t -= TABLE_COL0(last);
                                der_y = (3*c[0]*t + 2*c[1])*t + c[2];
                                der_y *= der_t;
                            }
                            break;

                        default:
                            ModelicaError("Unknown smoothness kind\n");
                            return der_y;
                    }
                }
                else {
                    /* Extrapolation */
                    switch (tableID->extrapolation) {
                        case NO_EXTRAPOLATION:
                            ModelicaError("Extrapolation error\n");
                            return der_y;

                        case HOLD_LAST_POINT:
                            break;

                        case LAST_TWO_POINTS:
                            last = (extrapolate == RIGHT) ? nRow - 2 : 0;

                            if (tableID->smoothness == CONTINUOUS_DERIVATIVE ||
                                tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                                if(tableID->spline) {
                                    const double* c = tableID->spline[
                                        IDX(last, iCol - 1, tableID->nCols)];
                                    if (extrapolate == LEFT) {
                                        der_y = c[2];
                                    }
                                    else /* if (extrapolate == RIGHT) */ {
                                        der_y = TABLE_COL0(last + 1) -
                                            TABLE_COL0(last); /* = (t1 - t0) */
                                        der_y = (3*c[0]*der_y + 2*c[1])*
                                            der_y + c[2];
                                    }
                                }
                            }
                            else {
                                const double t0 = TABLE_COL0(last);
                                const double t1 = TABLE_COL0(last + 1);
                                if (!isNearlyEqual(t0, t1)) {
                                    der_y = (TABLE(last + 1, col) - TABLE(last, col))/
                                        (t1 - t0);
                                }
                            }
                            der_y *= der_t;
                            break;

                        case PERIODIC:
                            /* Should not be possible to get here */
                            break;

                        default:
                            ModelicaError("Unknown extrapolation kind\n");
                            return der_y;
                    }
                }
            }
        }
    }
    return der_y;
}

double ModelicaStandardTables_CombiTimeTable_minimumTime(void* _tableID) {
    double tMin = 0.;
    CombiTimeTable* tableID = (CombiTimeTable*)_tableID;
    if (tableID != NULL && tableID->table != NULL) {
        const double* table = tableID->table;
        tMin = TABLE_ROW0(0);
    }
    return tMin;
}

double ModelicaStandardTables_CombiTimeTable_maximumTime(void* _tableID) {
    double tMax = 0.;
    CombiTimeTable* tableID = (CombiTimeTable*)_tableID;
    if (tableID != NULL && tableID->table != NULL) {
        const double* table = tableID->table;
        const size_t nCol = tableID->nCol;
        tMax = TABLE_COL0(tableID->nRow - 1);
    }
    return tMax;
}

double ModelicaStandardTables_CombiTimeTable_nextTimeEvent(void* _tableID,
                                                           double t) {
    double nextTimeEvent = DBL_MAX;
    CombiTimeTable* tableID = (CombiTimeTable*)_tableID;
    if (tableID != NULL && tableID->table != NULL) {
        const double* table = tableID->table;
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;

        if (tableID->nEvent > 0) {
            if (t > tableID->preNextTimeEventCalled) {
                tableID->preNextTimeEventCalled = t;
            }
            else {
                return tableID->preNextTimeEvent;
            }
        }
        else {
            /* Determine maximum number of time events (per period) */
            double tEvent = TABLE_ROW0(0);
            const double tMax = TABLE_COL0(nRow - 1);
            size_t i, eventInterval;

            /* There is at least one time event at the interval boundaries */
            tableID->maxEvents = 1;
            for (i = 0; i < nRow - 1; i++) {
                double t0 = TABLE_COL0(i);
                double t1 = TABLE_COL0(i + 1);
                if (t1 > tEvent && !isNearlyEqual(t1, tMax)) {
                    if (tableID->smoothness == CONSTANT_SEGMENTS) {
                        if (!isNearlyEqual(t0, t1)) {
                            tEvent = t1;
                            tableID->maxEvents++;
                        }
                    }
                    else if (isNearlyEqual(t0, t1)) {
                        tEvent = t1;
                        tableID->maxEvents++;
                    }
                }
            }
            /* Once again with storage of indices of event intervals */
            tableID->intervals = (Interval*)calloc(tableID->maxEvents,
                sizeof(Interval));
            if (tableID->intervals == NULL) {
                ModelicaError("Memory allocation error\n");
                return nextTimeEvent;
            }

            tEvent = TABLE_ROW0(0);
            eventInterval = 0;
            if (tableID->smoothness == CONSTANT_SEGMENTS) {
                for (i = 0; i < nRow - 1 &&
                    eventInterval < tableID->maxEvents; i++) {
                    double t0 = TABLE_COL0(i);
                    double t1 = TABLE_COL0(i + 1);
                    if (t1 > tEvent) {
                        if (!isNearlyEqual(t0, t1)) {
                            tEvent = t1;
                            tableID->intervals[eventInterval][0] = i;
                            tableID->intervals[eventInterval][1] = i + 1;
                            eventInterval++;
                        }
                        else {
                            tableID->intervals[eventInterval][0] = i + 1;
                        }
                    }
                    else {
                        tableID->intervals[eventInterval][1] = i + 1;
                    }
                }
            }
            else {
                for (i = 0; i < nRow - 1 &&
                    eventInterval < tableID->maxEvents; i++) {
                    double t0 = TABLE_COL0(i);
                    double t1 = TABLE_COL0(i + 1);
                    if (t1 > tEvent) {
                        if (isNearlyEqual(t0, t1)) {
                            tEvent = t1;
                            tableID->intervals[eventInterval][1] = i;
                            eventInterval++;
                            if (eventInterval < tableID->maxEvents) {
                                tableID->intervals[eventInterval][0] = i + 1;
                            }
                        }
                        else {
                            tableID->intervals[eventInterval][1] = i + 1;
                        }
                    }
                    else {
                        tableID->intervals[eventInterval][0] = i + 1;
                    }
                }
            }
        }

        if (t < tableID->startTime) {
            nextTimeEvent = tableID->startTime;
        }
        else if (nRow > 1) {
            const double tMin = TABLE_ROW0(0);
            const double tMax = TABLE_COL0(nRow - 1);
            const double T = tMax - tMin;
            if (tableID->eventInterval == 0) {
                /* Initialization of event interval */
#if defined(DEBUG_TIME_EVENTS)
                const double tOld = t;
#endif
                double tEvent = tMin;
                size_t i, iStart, iEnd;

                t -= tableID->startTime;
                if (tableID->extrapolation == PERIODIC) {
                    /* Initialization of offset time */
                    tableID->tOffset = floor((t - tMin)/T)*T;
                    t -= tableID->tOffset;
                    if (t < tMin) {
                        t += T;
                    }
                    else if (t > tMax) {
                        t -= T;
                    }
                    iStart = findRowIndex(table, nRow, nCol, tableID->last,
                        t + _EPSILON*T);
                    nextTimeEvent = tMax;
                    tableID->eventInterval = 1;
                    iEnd = iStart < (nRow - 1) ? iStart : (nRow - 1);
                }
                else if (t > tMax) {
                    iStart = nRow - 1;
                    tableID->eventInterval = tableID->maxEvents + 1;
                    iEnd = 0;
                }
                else if (t < tMin) {
                    iStart = nRow - 1;
                    nextTimeEvent = tMin;
                    tableID->eventInterval = 1;
                    iEnd = 0;
                }
                else if (tableID->smoothness == CONTINUOUS_DERIVATIVE ||
                    tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                    iStart = nRow - 1;
                    nextTimeEvent = tMax;
                    iEnd = 0;
                }
                else {
                    iStart = findRowIndex(table, nRow, nCol, tableID->last,
                        t + _EPSILON*T);
                    nextTimeEvent = tMax;
                    tableID->eventInterval = 2;
                    iEnd = iStart < (nRow - 1) ? iStart : (nRow - 1);
                }

                for (i = iStart + 1; i < nRow - 1; i++) {
                    double t0 = TABLE_COL0(i);
                    double t1 = TABLE_COL0(i + 1);
                    if (t0 > t) {
                        if (tableID->smoothness == CONSTANT_SEGMENTS) {
                            nextTimeEvent = t0;
                            break;
                        }
                        else if (isNearlyEqual(t0, t1)) {
                            nextTimeEvent = t0;
                            break;
                        }
                    }
                }

                for (i = 0; i < iEnd; i++) {
                    double t0 = TABLE_COL0(i);
                    double t1 = TABLE_COL0(i + 1);
                    if (t1 > tEvent && !isNearlyEqual(t1, tMax)) {
                        if (tableID->smoothness == CONSTANT_SEGMENTS) {
                            if (!isNearlyEqual(t0, t1)) {
                                tEvent = t1;
                                tableID->eventInterval++;
                            }
                        }
                        else if (isNearlyEqual(t0, t1)) {
                            tEvent = t1;
                            tableID->eventInterval++;
                        }
                    }
                }

                if (tableID->extrapolation == PERIODIC) {
                    nextTimeEvent += tableID->tOffset;
                    if (tableID->eventInterval == tableID->maxEvents) {
                        tableID->tOffset += T;
                    }
                }
#if defined(DEBUG_TIME_EVENTS)
                t = tOld;
#endif
                if (nextTimeEvent < DBL_MAX) {
                    nextTimeEvent += tableID->startTime;
                }
            }
            else {
                do {
                    if (tableID->extrapolation == PERIODIC) {
                        /* Increment event interval */
                        tableID->eventInterval =
                            1 + tableID->eventInterval % tableID->maxEvents;
                        if (tableID->eventInterval == tableID->maxEvents) {
                            nextTimeEvent = tMax + tableID->tOffset +
                                tableID->startTime;
                            tableID->tOffset += T;
                        }
                        else {
                            size_t i = tableID->intervals[
                                tableID->eventInterval - 1][1];
                            nextTimeEvent = TABLE_COL0(i) + tableID->tOffset +
                                tableID->startTime;
                        }
                    }
                    else if (tableID->eventInterval <= tableID->maxEvents) {
                        size_t i = tableID->intervals[
                            tableID->eventInterval - 1][1];
                        nextTimeEvent = TABLE_COL0(i) + tableID->startTime;
                        /* Increment event interval */
                        tableID->eventInterval++;
                    }
                    else {
                        nextTimeEvent = DBL_MAX;
                    }
                } while (nextTimeEvent < t);
            }
        }

        if (nextTimeEvent > tableID->preNextTimeEvent) {
            tableID->preNextTimeEvent = nextTimeEvent;
            tableID->nEvent++;
        }

#if defined(DEBUG_TIME_EVENTS)
        if (nextTimeEvent < DBL_MAX) {
            ModelicaFormatMessage("At time %.17lg: %lu. time event at %.17lg\n", t,
                (unsigned long)tableID->nEvent, nextTimeEvent);
        }
        else {
            ModelicaFormatMessage("No more time events for time > %.17lg\n", t);
        }
#endif
    }
    else {
        /* Should not be possible to get here */
        ModelicaError(
            "No table data available for detection of time events\n");
        return nextTimeEvent;
    }

    return nextTimeEvent;
}

double ModelicaStandardTables_CombiTimeTable_read(void* _tableID, int force,
                                                  int verbose) {
#if !defined(NO_FILE_SYSTEM)
    CombiTimeTable* tableID = (CombiTimeTable*)_tableID;
    if (tableID != NULL && tableID->source == TABLESOURCE_FILE) {
        if (force || tableID->table == NULL) {
#if !defined(TABLE_SHARE)
            if (tableID->table != NULL) {
                free(tableID->table);
            }
#endif
            tableID->table = readTable(tableID->tableName,
                tableID->fileName, &tableID->nRow, &tableID->nCol,
                verbose, force);
            if (tableID->table == NULL) {
                return 0.; /* Error */
            }
            if (!isValidCombiTimeTable((const CombiTimeTable*)tableID)) {
                return 0.; /* Error */
            }
            if (tableID->nRow <= 2) {
                if (tableID->smoothness == CONTINUOUS_DERIVATIVE ||
                    tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                    tableID->smoothness = LINEAR_SEGMENTS;
                }
            }
            if (tableID->smoothness == CONTINUOUS_DERIVATIVE) {
                /* Reinitialization of the cubic Hermite spline coefficients */
                spline1DClose(&tableID->spline);
                tableID->spline = akimaSpline1DInit(
                    (const double*)tableID->table, tableID->nRow,
                    tableID->nCol, (const int*)tableID->cols, tableID->nCols);
                if (tableID->spline == NULL) {
                    ModelicaError("Memory allocation error\n");
                    return 0.; /* Error */
                }
            }
            else if (tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                /* Reinitialization of the cubic Hermite spline coefficients */
                spline1DClose(&tableID->spline);
                tableID->spline = fritschButlandSpline1DInit(
                    (const double*)tableID->table, tableID->nRow,
                    tableID->nCol, (const int*)tableID->cols, tableID->nCols);
                if (tableID->spline == NULL) {
                    ModelicaError("Memory allocation error\n");
                    return 0.; /* Error */
                }
            }
        }
    }
#endif
    return 1.; /* Success */
}

void* ModelicaStandardTables_CombiTable1D_init(const char* tableName,
                                               const char* fileName,
                                               double* table, size_t nRow,
                                               size_t nColumn, int* cols,
                                               size_t nCols, int smoothness) {
    CombiTable1D* tableID = (CombiTable1D*)calloc(1, sizeof(CombiTable1D));
    if (tableID != NULL) {
        tableID->smoothness = (enum Smoothness)smoothness;
        tableID->nCols = nCols;
        if (nCols > 0) {
            tableID->cols = (int*)malloc(tableID->nCols*sizeof(int));
            if (tableID->cols != NULL) {
                memcpy(tableID->cols, cols, tableID->nCols*sizeof(int));
            }
            else {
                free(tableID);
                ModelicaError("Memory allocation error\n");
                return NULL;
            }
        }
        tableID->source = getTableSource(tableName, fileName);

        switch (tableID->source) {
            case TABLESOURCE_FILE:
                tableID->tableName = (char*)malloc(
                    (strlen(tableName) + 1)*sizeof(char));
                if (tableID->tableName != NULL) {
                    strcpy(tableID->tableName, tableName);
                }
                else {
                    if (nCols > 0) {
                        free(tableID->cols);
                    }
                    free(tableID);
                    ModelicaError("Memory allocation error\n");
                    return NULL;
                }
                tableID->fileName = (char*)malloc(
                    (strlen(fileName) + 1)*sizeof(char));
                if (tableID->fileName != NULL) {
                    strcpy(tableID->fileName, fileName);
                }
                else {
                    free(tableID->tableName);
                    if (nCols > 0) {
                        free(tableID->cols);
                    }
                    free(tableID);
                    ModelicaError("Memory allocation error\n");
                    return NULL;
                }
                break;

            case TABLESOURCE_MODEL:
                tableID->nRow = nRow;
                tableID->nCol = nColumn;
                tableID->table = table;
                if (isValidCombiTable1D((const CombiTable1D*)tableID)) {
                    if (tableID->nRow <= 2) {
                        if (tableID->smoothness == CONTINUOUS_DERIVATIVE ||
                            tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                            tableID->smoothness = LINEAR_SEGMENTS;
                        }
                    }
                    if (tableID->smoothness == CONTINUOUS_DERIVATIVE) {
                        /* Initialization of the cubic Hermite spline coefficients */
                        tableID->spline = akimaSpline1DInit(table,
                            tableID->nRow, tableID->nCol, (const int*)cols,
                            tableID->nCols);
                        if (tableID->spline == NULL) {
                            if (nCols > 0) {
                                free(tableID->cols);
                            }
                            free(tableID);
                            ModelicaError("Memory allocation error\n");
                            return NULL;
                        }
                    }
                    else if (tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                        /* Initialization of the cubic Hermite spline coefficients */
                        tableID->spline = fritschButlandSpline1DInit(table,
                            tableID->nRow, tableID->nCol, (const int*)cols,
                            tableID->nCols);
                        if (tableID->spline == NULL) {
                            if (nCols > 0) {
                                free(tableID->cols);
                            }
                            free(tableID);
                            ModelicaError("Memory allocation error\n");
                            return NULL;
                        }
                    }
#if !defined(NO_TABLE_COPY)
                    tableID->table = (double*)malloc(
                        tableID->nRow*tableID->nCol*sizeof(double));
                    if (tableID->table != NULL) {
                        memcpy(tableID->table, table, tableID->nRow*
                            tableID->nCol*sizeof(double));
                    }
                    else {
                        if (nCols > 0) {
                            free(tableID->cols);
                        }
                        spline1DClose(&tableID->spline);
                        free(tableID);
                        ModelicaError("Memory allocation error\n");
                        return NULL;
                    }
#endif
                }
                else {
                    tableID->table = NULL;
                }
                break;

            case TABLESOURCE_FUNCTION: {
                int colWise;
                int dim[MAX_TABLE_DIMENSIONS];
                if (usertab((char*)tableName, 1 /* 1D-interpolation */, dim,
                    &colWise, &tableID->table) == 0) {
                    if (colWise == 0) {
                        tableID->nRow = (size_t)dim[0];
                        tableID->nCol = (size_t)dim[1];
                    }
                    else {
                        /* Need to transpose */
                        double* tableT = (double*)malloc(dim[0]*dim[1]*sizeof(double));
                        if (tableT != NULL) {
                            memcpy(tableT, tableID->table, dim[0]*dim[1]*sizeof(double));
                            tableID->table = tableT;
                            tableID->nRow = (size_t)dim[1];
                            tableID->nCol = (size_t)dim[0];
                            tableID->source = TABLESOURCE_FUNCTION_TRANSPOSE;
                            transpose(tableID->table, tableID->nRow, tableID->nCol);
                        }
                        else {
                            if (nCols > 0) {
                                free(tableID->cols);
                            }
                            free(tableID);
                            ModelicaError("Memory allocation error\n");
                            return NULL;
                        }
                    }
                    if (isValidCombiTable1D((const CombiTable1D*)tableID)) {
                        if (tableID->nRow <= 2) {
                            if (tableID->smoothness == CONTINUOUS_DERIVATIVE ||
                                tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                                tableID->smoothness = LINEAR_SEGMENTS;
                            }
                        }
                        if (tableID->smoothness == CONTINUOUS_DERIVATIVE) {
                            /* Initialization of the cubic Hermite spline coefficients */
                            tableID->spline = akimaSpline1DInit(table,
                                tableID->nRow, tableID->nCol, (const int*)cols,
                                tableID->nCols);
                            if (tableID->spline == NULL) {
                                if (nCols > 0) {
                                    free(tableID->cols);
                                }
                                if (tableID->source == TABLESOURCE_FUNCTION_TRANSPOSE) {
                                    free(tableID->table);
                                }
                                free(tableID);
                                ModelicaError("Memory allocation error\n");
                                return NULL;
                            }
                        }
                        else if (tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                            /* Initialization of the cubic Hermite spline coefficients */
                            tableID->spline = fritschButlandSpline1DInit(table,
                                tableID->nRow, tableID->nCol, (const int*)cols,
                                tableID->nCols);
                            if (tableID->spline == NULL) {
                                if (nCols > 0) {
                                    free(tableID->cols);
                                }
                                if (tableID->source == TABLESOURCE_FUNCTION_TRANSPOSE) {
                                    free(tableID->table);
                                }
                                free(tableID);
                                ModelicaError("Memory allocation error\n");
                                return NULL;
                            }
                        }
                    }
                }
                break;
            }

            case TABLESOURCE_FUNCTION_TRANSPOSE:
                /* Should not be possible to get here */
                break;

            default:
                if (nCols > 0) {
                    free(tableID->cols);
                }
                free(tableID);
                ModelicaError("Table source error\n");
                return NULL;
        }
    }
    else {
        ModelicaError("Memory allocation error\n");
    }
    return (void*)tableID;
}

void ModelicaStandardTables_CombiTable1D_close(void* _tableID) {
    CombiTable1D* tableID = (CombiTable1D*)_tableID;
    if (tableID != NULL) {
        if (tableID->table != NULL && tableID->source == TABLESOURCE_FILE) {
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
            if (tableID->tableName != NULL && tableID->fileName != NULL) {
                char* key = malloc((strlen(tableID->tableName) +
                    strlen(tableID->fileName) + 2)*sizeof(char));
                if (key != NULL) {
                    TableShare *iter;
                    strcpy(key, tableID->tableName);
                    strcat(key, "|");
                    strcat(key, tableID->fileName);
                    MUTEX_LOCK();
                    HASH_FIND_STR(tableShare, key, iter);
                    if (iter != NULL) {
                        /* Share hit */
                        if (--iter->refCount == 0) {
                            free(iter->table);
                            free(iter->key);
                            HASH_DEL(tableShare, iter);
                            free(iter);
                        }
                    }
                    MUTEX_UNLOCK();
                    free(key);
                }
            }
            else {
                /* Should not be possible to get here */
                free(tableID->table);
            }
#else
            free(tableID->table);
#endif
            tableID->table = NULL;
        }
        else if (tableID->table != NULL && (
#if !defined(NO_TABLE_COPY)
            tableID->source == TABLESOURCE_MODEL ||
#endif
            tableID->source == TABLESOURCE_FUNCTION_TRANSPOSE)) {
            free(tableID->table);
            tableID->table = NULL;
        }
        if (tableID->nCols > 0 && tableID->cols != NULL) {
            free(tableID->cols);
            tableID->cols = NULL;
        }
        if (tableID->tableName != NULL) {
            free(tableID->tableName);
            tableID->tableName = NULL;
        }
        if (tableID->fileName != NULL) {
            free(tableID->fileName);
            tableID->fileName = NULL;
        }
        spline1DClose(&tableID->spline);
        free(tableID);
    }
}

double ModelicaStandardTables_CombiTable1D_getValue(void* _tableID, int iCol,
                                                    double u) {
    double y = 0.;
    CombiTable1D* tableID = (CombiTable1D*)_tableID;
    if (tableID != NULL && tableID->table != NULL && tableID->cols != NULL) {
        const double* table = tableID->table;
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        const size_t col = (size_t)tableID->cols[iCol - 1] - 1;

        if (nRow == 1) {
            /* Single row */
            y = TABLE_ROW0(col);
        }
        else {
            enum PointInterval extrapolate = IN_TABLE;
            size_t last;

            if (u < TABLE_ROW0(0)) {
                extrapolate = LEFT;
                last = 0;
            }
            else if (u > TABLE_COL0(nRow - 1)) {
                extrapolate = RIGHT;
                last = nRow - 2;
            }
            else {
                last = findRowIndex(table, nRow, nCol, tableID->last, u);
                tableID->last = last;
            }

            switch (tableID->smoothness) {
                case CONSTANT_SEGMENTS:
                    if (extrapolate == IN_TABLE) {
                        if (u >= TABLE_COL0(last + 1)) {
                            last += 1;
                        }
                        y = TABLE(last, col);
                        break;
                    }
                    /* Fall through: linear extrapolation */
                case LINEAR_SEGMENTS: {
                    const double u0 = TABLE_COL0(last);
                    const double u1 = TABLE_COL0(last + 1);
                    const double y0 = TABLE(last, col);
                    const double y1 = TABLE(last + 1, col);
                    LINEAR(u, u0, u1, y0, y1)
                    break;
                }

                case CONTINUOUS_DERIVATIVE:
                case MONOTONE_CONTINUOUS_DERIVATIVE:
                    if (tableID->spline != NULL) {
                        const double* c = tableID->spline[
                            IDX(last, iCol - 1, tableID->nCols)];
                        const double u0 = TABLE_COL0(last);
                        if (extrapolate == IN_TABLE) {
                            const double v = u - u0;
                            y = TABLE(last, col); /* c[3] = y0 */
                            y += ((c[0]*v + c[1])*v + c[2])*v;
                        }
                        else if (extrapolate == LEFT) {
                            y = LINEAR_SLOPE(TABLE(last, col), c[2], u - u0);
                        }
                        else /* if (extrapolate == RIGHT) */ {
                            const double u1 = TABLE_COL0(last + 1);
                            const double v = u1 - u0;
                            y = LINEAR_SLOPE(TABLE(last + 1, col),
                               (3*c[0]*v + 2*c[1])*v + c[2], u - u1);
                        }
                    }
                    break;

                default:
                    ModelicaError("Unknown smoothness kind\n");
                    return y;
            }
        }
    }
    return y;
}

double ModelicaStandardTables_CombiTable1D_getDerValue(void* _tableID, int iCol,
                                                       double u, double der_u) {
    double der_y = 0.;
    CombiTable1D* tableID = (CombiTable1D*)_tableID;
    if (tableID != NULL && tableID->table != NULL && tableID->cols != NULL) {
        const double* table = tableID->table;
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        const size_t col = (size_t)tableID->cols[iCol - 1] - 1;

        if (nRow > 1) {
            enum PointInterval extrapolate = IN_TABLE;
            size_t last;

            if (u < TABLE_ROW0(0)) {
                extrapolate = LEFT;
                last = 0;
            }
            else if (u > TABLE_COL0(nRow - 1)) {
                extrapolate = RIGHT;
                last = nRow - 2;
            }
            else {
                last = findRowIndex(table, nRow, nCol, tableID->last, u);
                tableID->last = last;
            }

            switch (tableID->smoothness) {
                case CONSTANT_SEGMENTS:
                    if (extrapolate == IN_TABLE) {
                        break;
                    }
                    /* Fall through: linear extrapolation */
                case LINEAR_SEGMENTS:
                    der_y = (TABLE(last + 1, col) - TABLE(last, col))/
                        (TABLE_COL0(last + 1) - TABLE_COL0(last));
                    der_y *= der_u;
                    break;

                case CONTINUOUS_DERIVATIVE:
                case MONOTONE_CONTINUOUS_DERIVATIVE:
                    if (tableID->spline != NULL) {
                        const double* c = tableID->spline[
                            IDX(last, iCol - 1, tableID->nCols)];
                        if (extrapolate == IN_TABLE) {
                            const double v = u - TABLE_COL0(last);
                            der_y = (3*c[0]*v + 2*c[1])*v + c[2];
                        }
                        else if (extrapolate == LEFT) {
                            der_y = c[2];
                        }
                        else /* if (extrapolate == RIGHT) */ {
                            const double v = TABLE_COL0(last + 1) -
                                TABLE_COL0(last);
                            der_y = (3*c[0]*v + 2*c[1])*v + c[2];
                        }
                        der_y *= der_u;
                    }
                    break;

                default:
                    ModelicaError("Unknown smoothness kind\n");
                    return der_y;
            }
        }
    }
    return der_y;
}

double ModelicaStandardTables_CombiTable1D_read(void* _tableID, int force,
                                                int verbose) {
#if !defined(NO_FILE_SYSTEM)
    CombiTable1D* tableID = (CombiTable1D*)_tableID;
    if (tableID != NULL && tableID->source == TABLESOURCE_FILE) {
        if (force || tableID->table == NULL) {
#if !defined(TABLE_SHARE)
            if (tableID->table != NULL) {
                free(tableID->table);
            }
#endif
            tableID->table = readTable(tableID->tableName,
                tableID->fileName, &tableID->nRow, &tableID->nCol,
                verbose, force);
            if (tableID->table == NULL) {
                return 0.; /* Error */
            }
            if (!isValidCombiTable1D((const CombiTable1D*)tableID)) {
                return 0.; /* Error */
            }
            if (tableID->nRow <= 2) {
                if (tableID->smoothness == CONTINUOUS_DERIVATIVE ||
                    tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                    tableID->smoothness = LINEAR_SEGMENTS;
                }
            }
            if (tableID->smoothness == CONTINUOUS_DERIVATIVE) {
                /* Reinitialization of the cubic Hermite spline coefficients */
                spline1DClose(&tableID->spline);
                tableID->spline = akimaSpline1DInit(
                    (const double*)tableID->table, tableID->nRow,
                    tableID->nCol, (const int*)tableID->cols, tableID->nCols);
                if (tableID->spline == NULL) {
                    ModelicaError("Memory allocation error\n");
                    return 0.; /* Error */
                }
            }
            else if (tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                /* Reinitialization of the cubic Hermite spline coefficients */
                spline1DClose(&tableID->spline);
                tableID->spline = fritschButlandSpline1DInit(
                    (const double*)tableID->table, tableID->nRow,
                    tableID->nCol, (const int*)tableID->cols, tableID->nCols);
                if (tableID->spline == NULL) {
                    ModelicaError("Memory allocation error\n");
                    return 0.; /* Error */
                }
            }
        }
    }
#endif
    return 1.; /* Success */
}

void* ModelicaStandardTables_CombiTable2D_init(const char* tableName,
                                               const char* fileName,
                                               double* table, size_t nRow,
                                               size_t nColumn, int smoothness) {
    CombiTable2D* tableID = (CombiTable2D*)calloc(1, sizeof(CombiTable2D));
    if (tableID != NULL) {
        tableID->smoothness = (enum Smoothness)smoothness;
        tableID->source = getTableSource(tableName, fileName);

        switch (tableID->source) {
            case TABLESOURCE_FILE:
                tableID->tableName = (char*)malloc(
                    (strlen(tableName) + 1)*sizeof(char));
                if (tableID->tableName != NULL) {
                    strcpy(tableID->tableName, tableName);
                }
                else {
                    free(tableID);
                    ModelicaError("Memory allocation error\n");
                    return NULL;
                }
                tableID->fileName = (char*)malloc((strlen(fileName) + 1)*sizeof(char));
                if (tableID->fileName != NULL) {
                    strcpy(tableID->fileName, fileName);
                }
                else {
                    free(tableID->tableName);
                    free(tableID);
                    ModelicaError("Memory allocation error\n");
                    return NULL;
                }
                break;

            case TABLESOURCE_MODEL:
                tableID->nRow = nRow;
                tableID->nCol = nColumn;
                tableID->table = table;
                if (isValidCombiTable2D((const CombiTable2D*)tableID)) {
                    if (tableID->smoothness == CONTINUOUS_DERIVATIVE &&
                        tableID->nRow <= 3 && tableID->nCol <= 3) {
                        tableID->smoothness = LINEAR_SEGMENTS;
                    }
                    if (tableID->smoothness == CONTINUOUS_DERIVATIVE) {
                        /* Initialization of the Akima-spline coefficients */
                        tableID->spline = spline2DInit(table, tableID->nRow,
                            tableID->nCol);
                        if (tableID->spline == NULL) {
                            free(tableID);
                            ModelicaError("Memory allocation error\n");
                            return NULL;
                        }
                    }
#if !defined(NO_TABLE_COPY)
                    tableID->table = (double*)malloc(
                        tableID->nRow*tableID->nCol*sizeof(double));
                    if (tableID->table != NULL) {
                        memcpy(tableID->table, table, tableID->nRow*
                            tableID->nCol*sizeof(double));
                    }
                    else {
                        spline2DClose(&tableID->spline);
                        free(tableID);
                        ModelicaError("Memory allocation error\n");
                        return NULL;
                    }
#endif
                }
                else {
                    tableID->table = NULL;
                }
                break;

            case TABLESOURCE_FUNCTION: {
                int colWise;
                int dim[MAX_TABLE_DIMENSIONS];
                if (usertab((char*)tableName, 2 /* 2D-interpolation */, dim,
                    &colWise, &tableID->table) == 0) {
                    if (colWise == 0) {
                        tableID->nRow = (size_t)dim[0];
                        tableID->nCol = (size_t)dim[1];
                    }
                    else {
                        /* Need to transpose */
                        double* tableT = (double*)malloc(dim[0]*dim[1]*sizeof(double));
                        if (tableT != NULL) {
                            memcpy(tableT, tableID->table, dim[0]*dim[1]*sizeof(double));
                            tableID->table = tableT;
                            tableID->nRow = (size_t)dim[1];
                            tableID->nCol = (size_t)dim[0];
                            tableID->source = TABLESOURCE_FUNCTION_TRANSPOSE;
                            transpose(tableID->table, tableID->nRow, tableID->nCol);
                        }
                        else {
                            free(tableID);
                            ModelicaError("Memory allocation error\n");
                            return NULL;
                        }
                    }
                    if (isValidCombiTable2D((const CombiTable2D*)tableID)) {
                        if (tableID->smoothness == CONTINUOUS_DERIVATIVE &&
                            tableID->nRow <= 3 && tableID->nCol <= 3) {
                            tableID->smoothness = LINEAR_SEGMENTS;
                        }
                        if (tableID->smoothness == CONTINUOUS_DERIVATIVE) {
                            /* Initialization of the Akima-spline coefficients */
                            tableID->spline = spline2DInit(tableID->table,
                                tableID->nRow, tableID->nCol);
                            if (tableID->spline == NULL) {
                                if (tableID->source == TABLESOURCE_FUNCTION_TRANSPOSE) {
                                    free(tableID->table);
                                }
                                free(tableID);
                                ModelicaError("Memory allocation error\n");
                                return NULL;
                            }
                        }
                    }
                }
                break;
            }

            case TABLESOURCE_FUNCTION_TRANSPOSE:
                /* Should not be possible to get here */
                break;

            default:
                free(tableID);
                ModelicaError("Table source error\n");
                return NULL;
        }
    }
    else {
        ModelicaError("Memory allocation error\n");
    }
    return (void*)tableID;
}

void ModelicaStandardTables_CombiTable2D_close(void* _tableID) {
    CombiTable2D* tableID = (CombiTable2D*)_tableID;
    if (tableID != NULL) {
        if (tableID->table != NULL && tableID->source == TABLESOURCE_FILE) {
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
            if (tableID->tableName != NULL && tableID->fileName != NULL) {
                char* key = malloc((strlen(tableID->tableName) +
                    strlen(tableID->fileName) + 2)*sizeof(char));
                if (key != NULL) {
                    TableShare *iter;
                    strcpy(key, tableID->tableName);
                    strcat(key, "|");
                    strcat(key, tableID->fileName);
                    MUTEX_LOCK();
                    HASH_FIND_STR(tableShare, key, iter);
                    if (iter != NULL) {
                        /* Share hit */
                        if (--iter->refCount == 0) {
                            free(iter->table);
                            free(iter->key);
                            HASH_DEL(tableShare, iter);
                            free(iter);
                        }
                    }
                    MUTEX_UNLOCK();
                    free(key);
                }
            }
            else {
                /* Should not be possible to get here */
                free(tableID->table);
            }
#else
            free(tableID->table);
#endif
            tableID->table = NULL;
        }
        else if (tableID->table != NULL && (
#if !defined(NO_TABLE_COPY)
            tableID->source == TABLESOURCE_MODEL ||
#endif
            tableID->source == TABLESOURCE_FUNCTION_TRANSPOSE)) {
            free(tableID->table);
            tableID->table = NULL;
        }
        if (tableID->tableName != NULL) {
            free(tableID->tableName);
            tableID->tableName = NULL;
        }
        if (tableID->fileName != NULL) {
            free(tableID->fileName);
            tableID->fileName = NULL;
        }
        spline2DClose(&tableID->spline);
        free(tableID);
    }
}

double ModelicaStandardTables_CombiTable2D_read(void* _tableID, int force,
                                                int verbose) {
#if !defined(NO_FILE_SYSTEM)
    CombiTable2D* tableID = (CombiTable2D*)_tableID;
    if (tableID != NULL && tableID->source == TABLESOURCE_FILE) {
        if (force || tableID->table == NULL) {
#if !defined(TABLE_SHARE)
            if (tableID->table != NULL) {
                free(tableID->table);
            }
#endif
            tableID->table = readTable(tableID->tableName,
                tableID->fileName, &tableID->nRow, &tableID->nCol,
                verbose, force);
            if (tableID->table == NULL) {
                return 0.; /* Error */
            }
            if (!isValidCombiTable2D((const CombiTable2D*)tableID)) {
                return 0.; /* Error */
            }
            if (tableID->smoothness == CONTINUOUS_DERIVATIVE &&
                tableID->nRow <= 3 && tableID->nCol <= 3) {
                tableID->smoothness = LINEAR_SEGMENTS;
            }
            if (tableID->smoothness == CONTINUOUS_DERIVATIVE) {
                /* Reinitialization of the Akima-spline coefficients */
                spline2DClose(&tableID->spline);
                tableID->spline = spline2DInit(tableID->table, tableID->nRow,
                    tableID->nCol);
                if (tableID->spline == NULL) {
                    ModelicaError("Memory allocation error\n");
                    return 0.; /* Error */
                }
            }
        }
    }
#endif
    return 1.; /* Success */
}

double ModelicaStandardTables_CombiTable2D_getValue(void* _tableID, double u1,
                                                    double u2) {
    double y = 0;
    CombiTable2D* tableID = (CombiTable2D*)_tableID;
    if (tableID != NULL && tableID->table != NULL) {
        const double* table = tableID->table;
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;

        if (nRow == 2 && nCol == 2) {
            /* Single row */
            y = TABLE(1, 1);
        }
        else if (nRow == 2 && nCol > 2) {
            enum PointInterval extrapolate2 = IN_TABLE;
            size_t last2;

            if (u2 < TABLE_ROW0(1)) {
                extrapolate2 = LEFT;
                last2 = 0;
            }
            else if (u2 > TABLE_ROW0(nCol - 1)) {
                extrapolate2 = RIGHT;
                last2 = nCol - 3;
            }
            else {
                last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                    tableID->last2, u2);
                tableID->last2 = last2;
            }

            switch (tableID->smoothness) {
                case CONSTANT_SEGMENTS:
                    if (extrapolate2 == IN_TABLE) {
                        if (u2 >= TABLE_ROW0(last2 + 2)) {
                            last2 += 1;
                        }
                        y = TABLE(1, last2 + 1);
                        break;
                    }
                    /* Fall through: linear extrapolation */
                case LINEAR_SEGMENTS: {
                    const double u20 = TABLE_ROW0(last2 + 1);
                    const double u21 = TABLE_ROW0(last2 + 2);
                    const double y0 = TABLE(1, last2 + 1);
                    const double y1 = TABLE(1, last2 + 2);
                    LINEAR(u2, u20, u21, y0, y1)
                    break;
                }

                case CONTINUOUS_DERIVATIVE:
                    if (tableID->spline != NULL) {
                        const double* c = tableID->spline[last2];
                        const double u20 = TABLE_ROW0(last2 + 1);
                        if (extrapolate2 == IN_TABLE) {
                            u2 -= u20;
                            y = TABLE(1, last2 + 1); /* c[3] = y0 */
                            y += ((c[0]*u2 + c[1])*u2 + c[2])*u2;
                        }
                        else if (extrapolate2 == LEFT) {
                            y = LINEAR_SLOPE(TABLE(1, last2 + 1), c[2],
                                u2 - u20);
                        }
                        else /* if (extrapolate2 == RIGHT) */ {
                            const double u21 = TABLE_ROW0(last2 + 2);
                            const double v2 = u21 - u20;
                            y = LINEAR_SLOPE(TABLE(1, last2 + 2), (3*c[0]*v2 +
                                2*c[1])*v2 + c[2], u2 - u21);
                        }
                    }
                    break;

                case MONOTONE_CONTINUOUS_DERIVATIVE:
                    ModelicaError("Bivariate monotone interpolation is "
                        "not implemented\n");
                    return y;

                default:
                    ModelicaError("Unknown smoothness kind\n");
                    return y;
            }
        }
        else if (nRow > 2 && nCol == 2) {
            enum PointInterval extrapolate1 = IN_TABLE;
            size_t last1;

            if (u1 < TABLE_COL0(1)) {
                extrapolate1 = LEFT;
                last1 = 0;
            }
            else if (u1 > TABLE_COL0(nRow - 1)) {
                extrapolate1 = RIGHT;
                last1 = nRow - 3;
            }
            else {
                last1 = findRowIndex(&TABLE(1, 0), nRow - 1, nCol,
                    tableID->last1, u1);
                tableID->last1 = last1;
            }

            switch (tableID->smoothness) {
                case CONSTANT_SEGMENTS:
                    if (extrapolate1 == IN_TABLE) {
                        if (u1 >= TABLE_COL0(last1 + 2)) {
                            last1 += 1;
                        }
                        y = TABLE(last1 + 1, 1);
                        break;
                    }
                    /* Fall through: linear extrapolation */
                case LINEAR_SEGMENTS: {
                    const double u10 = TABLE_COL0(last1 + 1);
                    const double u11 = TABLE_COL0(last1 + 2);
                    const double y0 = TABLE(last1 + 1, 1);
                    const double y1 = TABLE(last1 + 2, 1);
                    LINEAR(u1, u10, u11, y0, y1)
                    break;
                }

                case CONTINUOUS_DERIVATIVE:
                    if (tableID->spline != NULL) {
                        const double* c = tableID->spline[last1];
                        const double u10 = TABLE_COL0(last1 + 1);
                        if (extrapolate1 == IN_TABLE) {
                            u1 -= u10;
                            y = TABLE(last1 + 1, 1); /* c[3] = y0 */
                            y += ((c[0]*u1 + c[1])*u1 + c[2])*u1;
                        }
                        else if (extrapolate1 == LEFT) {
                            y = LINEAR_SLOPE(TABLE(last1 + 1, 1), c[2],
                                u1 - u10);
                        }
                        else /* if (extrapolate1 == RIGHT) */ {
                            const double u11 = TABLE_COL0(last1 + 2);
                            const double v1 = u11 - u10;
                            y = LINEAR_SLOPE(TABLE(last1 + 2, 1), (3*c[0]*v1 +
                                2*c[1])*v1 + c[2], u1 - u11);
                        }
                    }
                    break;

                case MONOTONE_CONTINUOUS_DERIVATIVE:
                    ModelicaError("Bivariate monotone interpolation is "
                        "not implemented\n");
                    return y;

                default:
                    ModelicaError("Unknown smoothness kind\n");
                    return y;
            }
        }
        else if (nRow > 2 && nCol > 2) {
            enum PointInterval extrapolate1 = IN_TABLE;
            enum PointInterval extrapolate2 = IN_TABLE;
            size_t last1, last2;

            if (u1 < TABLE_COL0(1)) {
                extrapolate1 = LEFT;
                last1 = 0;
            }
            else if (u1 > TABLE_COL0(nRow - 1)) {
                extrapolate1 = RIGHT;
                last1 = nRow - 3;
            }
            else {
                last1 = findRowIndex(&TABLE(1, 0), nRow - 1, nCol,
                    tableID->last1, u1);
                tableID->last1 = last1;
            }

            if (u2 < TABLE_ROW0(1)) {
                extrapolate2 = LEFT;
                last2 = 0;
            }
            else if (u2 > TABLE_ROW0(nCol - 1)) {
                extrapolate2 = RIGHT;
                last2 = nCol - 3;
            }
            else {
                last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                    tableID->last2, u2);
                tableID->last2 = last2;
            }

            switch (tableID->smoothness) {
                case  CONSTANT_SEGMENTS:
                    if (extrapolate1 == IN_TABLE && extrapolate2 == IN_TABLE) {
                        if (u1 >= TABLE_COL0(last1 + 2)) {
                            last1 += 1;
                        }
                        if (u2 >= TABLE_ROW0(last2 + 2)) {
                            last2 += 1;
                        }
                        y = TABLE(last1 + 1, last2 + 1);
                        break;
                    }
                    /* Fall through: bilinear extrapolation */
                case LINEAR_SEGMENTS: {
                    const double u10 = TABLE_COL0(last1 + 1);
                    const double u11 = TABLE_COL0(last1 + 2);
                    const double u20 = TABLE_ROW0(last2 + 1);
                    const double u21 = TABLE_ROW0(last2 + 2);
                    const double y00 = TABLE(last1 + 1, last2 + 1);
                    const double y01 = TABLE(last1 + 1, last2 + 2);
                    const double y10 = TABLE(last1 + 2, last2 + 1);
                    const double y11 = TABLE(last1 + 2, last2 + 2);
                    BILINEAR(u1, u2,
                        u10, u11, u20, u21, y00, y01, y10, y11)
                    break;
                }

                case CONTINUOUS_DERIVATIVE:
                    if (tableID->spline != NULL) {
                        const double* c = tableID->spline[
                            IDX(last1, last2, nCol - 2)];
                        if (extrapolate1 == IN_TABLE) {
                            u1 -= TABLE_COL0(last1 + 1);
                            y = TABLE(last1 + 1, last2 + 1); /* c[15] = y00 */
                            if (extrapolate2 == IN_TABLE) {
                                double p1, p2, p3;
                                u2 -= TABLE_ROW0(last2 + 1);
                                p1 = ((c[0]*u2 + c[1])*u2 + c[2])*u2 + c[3];
                                p2 = ((c[4]*u2 + c[5])*u2 + c[6])*u2 + c[7];
                                p3 = ((c[8]*u2 + c[9])*u2 + c[10])*u2 + c[11];
                                y += ((c[12]*u2 + c[13])*u2 + c[14])*u2; /* p4 */
                                y += ((p1*u1 + p2)*u1 + p3)*u1;
                            }
                            else if (extrapolate2 == LEFT) {
                                double der_y2;
                                u2 -= TABLE_ROW0(1);
                                der_y2 = ((c[2]*u1 + c[6])*u1 + c[10])*u1 + c[14];
                                y += ((c[3]*u1 + c[7])*u1 + c[11])*u1;
                                y += der_y2*u2;
                            }
                            else /* if (extrapolate2 == RIGHT) */ {
                                const double v2 = TABLE_ROW0(nCol - 1) -
                                    TABLE_ROW0(nCol - 2);
                                double p1, p2, p3;
                                double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                double der_y2;
                                u2 -= TABLE_ROW0(nCol - 1);
                                p1 = ((c[0]*v2 + c[1])*v2 + c[2])*v2 + c[3];
                                p2 = ((c[4]*v2 + c[5])*v2 + c[6])*v2 + c[7];
                                p3 = ((c[8]*v2 + c[9])*v2 + c[10])*v2 + c[11];
                                dp1_u2 = (3*c[0]*v2 + 2*c[1])*v2 + c[2];
                                dp2_u2 = (3*c[4]*v2 + 2*c[5])*v2 + c[6];
                                dp3_u2 = (3*c[8]*v2 + 2*c[9])*v2 + c[10];
                                dp4_u2 = (3*c[12]*v2 + 2*c[13])*v2 + c[14];
                                der_y2 = ((dp1_u2*u1 + dp2_u2)*u1 + dp3_u2)*u1 + dp4_u2;
                                y += ((c[12]*v2 + c[13])*v2 + c[14])*v2; /* p4 */
                                y += ((p1*u1 + p2)*u1 + p3)*u1;
                                y += der_y2*u2;
                            }
                        }
                        else if (extrapolate1 == LEFT) {
                            u1 -= TABLE_COL0(1);
                            if (extrapolate2 == IN_TABLE) {
                                double der_y1;
                                u2 -= TABLE_ROW0(last2 + 1);
                                der_y1 = ((c[8]*u2 + c[9])*u2 + c[10])*u2 + c[11];
                                y = TABLE(last1 + 1, last2 + 1); /* c[15] = y00 */
                                y += ((c[12]*u2 + c[13])*u2 + c[14])*u2; /* p4 */
                                y += der_y1*u1;
                            }
                            else if (extrapolate2 == LEFT) {
                                double der_y1, der_y2, der_y12;
                                u2 -= TABLE_ROW0(1);
                                der_y1 = c[11];
                                der_y2 = c[14];
                                der_y12 = c[10];
                                y = TABLE(1, 1);
                                y += der_y1*u1 + der_y2*u2 + der_y12*u1*u2;
                            }
                            else /* if (extrapolate2 == RIGHT) */ {
                                const double v2 = TABLE_ROW0(nCol - 1) -
                                    TABLE_ROW0(nCol - 2);
                                double der_y1, der_y2, der_y12;
                                u2 -= TABLE_ROW0(nCol - 1);
                                der_y1 = ((c[8]*v2 + c[9])*v2 + c[10])*v2 + c[11];
                                der_y2 =(3*c[12]*v2 + 2*c[13])*v2 + c[14];
                                der_y12 = (3*c[8]*v2 + 2*c[9])*v2 + c[10];
                                y = TABLE(1, nCol - 1);
                                y += der_y1*u1 + der_y2*u2 + der_y12*u1*u2;
                            }
                        }
                        else /* if (extrapolate1 == RIGHT) */ {
                            const double v1 = TABLE_COL0(nRow - 1) -
                                TABLE_COL0(nRow - 2);
                            u1 -= TABLE_COL0(nRow - 1);
                            if (extrapolate2 == IN_TABLE) {
                                double p1, p2, p3;
                                double der_y1;
                                u2 -= TABLE_ROW0(last2 + 1);
                                p1 = ((c[0]*u2 + c[1])*u2 + c[2])*u2 + c[3];
                                p2 = ((c[4]*u2 + c[5])*u2 + c[6])*u2 + c[7];
                                p3 = ((c[8]*u2 + c[9])*u2 + c[10])*u2 + c[11];
                                der_y1 = (3*p1*v1 + 2*p2)*v1 + p3;
                                y = TABLE(last1 + 1, last2 + 1); /* c[15] = y00 */
                                y += ((c[12]*u2 + c[13])*u2 + c[14])*u2; /* p4 */
                                y += ((p1*v1 + p2)*v1 + p3)*v1;
                                y += der_y1*u1;
                            }
                            else if (extrapolate2 == LEFT) {
                                double der_y1, der_y2, der_y12;
                                u2 -= TABLE_ROW0(1);
                                der_y1 = (3*c[3]*v1 + 2*c[7])*v1 + c[11];
                                der_y2 = ((c[2]*v1 + c[6])*v1 + c[10])*v1 + c[14];
                                der_y12 = (3*c[2]*v1 + 2*c[6])*v1 + c[10];
                                y = TABLE(nRow - 1, 1);
                                y += der_y1*u1 + der_y2*u2 + der_y12*u1*u2;
                            }
                            else /* if (extrapolate2 == RIGHT) */ {
                                const double v2 = TABLE_ROW0(nCol - 1) -
                                    TABLE_ROW0(nCol - 2);
                                double p1, p2, p3;
                                double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                double der_y1, der_y2, der_y12;
                                u2 -= TABLE_ROW0(nCol - 1);
                                p1 = ((c[0]*v2 + c[1])*v2 + c[2])*v2 + c[3];
                                p2 = ((c[4]*v2 + c[5])*v2 + c[6])*v2 + c[7];
                                p3 = ((c[8]*v2 + c[9])*v2 + c[10])*v2 + c[11];
                                dp1_u2 = (3*c[0]*v2 + 2*c[1])*v2 + c[2];
                                dp2_u2 = (3*c[4]*v2 + 2*c[5])*v2 + c[6];
                                dp3_u2 = (3*c[8]*v2 + 2*c[9])*v2 + c[10];
                                dp4_u2 = (3*c[12]*v2 + 2*c[13])*v2 + c[14];
                                der_y1 = (3*p1*v1 + 2*p2)*v1 + p3;
                                der_y2 = ((dp1_u2*v1 + dp2_u2)*v1 + dp3_u2)*v1 + dp4_u2;
                                der_y12 = (3*dp1_u2*v1 + 2*dp2_u2)*v1 + dp3_u2;
                                y = TABLE(nRow - 1, nCol - 1);
                                y += der_y1*u1 + der_y2*u2 + der_y12*u1*u2;
                            }
                        }
                    }
                    break;

                case MONOTONE_CONTINUOUS_DERIVATIVE:
                    ModelicaError("Bivariate monotone interpolation is "
                        "not implemented\n");
                    return y;

                default:
                    ModelicaError("Unknown smoothness kind\n");
                    return y;
            }
        }
    }
    return y;
}

double ModelicaStandardTables_CombiTable2D_getDerValue(void* _tableID, double u1,
                                                       double u2, double der_u1,
                                                       double der_u2) {
    double der_y = 0;
    CombiTable2D* tableID = (CombiTable2D*)_tableID;
    if (tableID != NULL && tableID->table != NULL) {
        const double* table = tableID->table;
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;

        if (nRow == 2 && nCol == 2) {
        }
        else if (nRow == 2 && nCol > 2) {
            enum PointInterval extrapolate2 = IN_TABLE;
            size_t last2;

            if (u2 < TABLE_ROW0(1)) {
                extrapolate2 = LEFT;
                last2 = 0;
            }
            else if (u2 > TABLE_ROW0(nCol - 1)) {
                extrapolate2 = RIGHT;
                last2 = nCol - 3;
            }
            else {
                last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                    tableID->last2, u2);
                tableID->last2 = last2;
            }

            switch (tableID->smoothness) {
                case CONSTANT_SEGMENTS:
                    if (extrapolate2 == IN_TABLE) {
                        break;
                    }
                    /* Fall through: linear extrapolation */
                case LINEAR_SEGMENTS: {
                    der_y = (TABLE(1, last2 + 2) - TABLE(1, last2 + 1))/
                        (TABLE_ROW0(last2 + 2) - TABLE_ROW0(last2 + 1));
                    der_y *= der_u2;
                    break;
                }

                case CONTINUOUS_DERIVATIVE:
                    if (tableID->spline != NULL) {
                        const double* c = tableID->spline[last2];
                        const double u20 = TABLE_ROW0(last2 + 1);
                        if (extrapolate2 == IN_TABLE) {
                            u2 -= u20;
                            der_y = (3*c[0]*u2 + 2*c[1])*u2 + c[2];
                        }
                        else if (extrapolate2 == LEFT) {
                            der_y = c[2];
                        }
                        else /* if (extrapolate2 == RIGHT) */ {
                            const double u21 = TABLE_ROW0(last2 + 2);
                            der_y = u21 - u20;
                            der_y = (3*c[0]*der_y + 2*c[1])*der_y + c[2];
                        }
                        der_y *= der_u2;
                    }
                    break;

                case MONOTONE_CONTINUOUS_DERIVATIVE:
                    ModelicaError("Bivariate monotone interpolation is "
                        "not implemented\n");
                    return der_y;

                default:
                    ModelicaError("Unknown smoothness kind\n");
                    return der_y;
            }
        }
        else if (nRow > 2 && nCol == 2) {
            enum PointInterval extrapolate1 = IN_TABLE;
            size_t last1;

            if (u1 < TABLE_COL0(1)) {
                extrapolate1 = LEFT;
                last1 = 0;
            }
            else if (u1 > TABLE_COL0(nRow - 1)) {
                extrapolate1 = RIGHT;
                last1 = nRow - 3;
            }
            else {
                last1 = findRowIndex(&TABLE(1, 0), nRow - 1, nCol,
                    tableID->last1, u1);
                tableID->last1 = last1;
            }

            switch (tableID->smoothness) {
                case CONSTANT_SEGMENTS:
                    if (extrapolate1 == IN_TABLE) {
                        break;
                    }
                    /* Fall through: linear extrapolation */
                case LINEAR_SEGMENTS: {
                    der_y = (TABLE(last1 + 2, 1) - TABLE(last1 + 1, 1))/
                        (TABLE_COL0(last1 + 2) - TABLE_COL0(last1 + 1));
                    der_y *= der_u1;
                    break;
                }

                case CONTINUOUS_DERIVATIVE:
                    if (tableID->spline != NULL) {
                        const double* c = tableID->spline[last1];
                        const double u10 = TABLE_COL0(last1 + 1);
                        if (extrapolate1 == IN_TABLE) {
                            u1 -= u10;
                            der_y = (3*c[0]*u1 + 2*c[1])*u1 + c[2];
                        }
                        else if (extrapolate1 == LEFT) {
                            der_y = c[2];
                        }
                        else /* if (extrapolate1 == RIGHT) */ {
                            const double u11 = TABLE_COL0(last1 + 2);
                            der_y = u11 - u10;
                            der_y = (3*c[0]*der_y + 2*c[1])*der_y + c[2];
                        }
                        der_y *= der_u1;
                    }
                    break;

                case MONOTONE_CONTINUOUS_DERIVATIVE:
                    ModelicaError("Bivariate monotone interpolation is "
                        "not implemented\n");
                    return der_y;

                default:
                    ModelicaError("Unknown smoothness kind\n");
                    return der_y;
            }
        }
        else if (nRow > 2 && nCol > 2) {
            enum PointInterval extrapolate1 = IN_TABLE;
            enum PointInterval extrapolate2 = IN_TABLE;
            size_t last1, last2;

            if (u1 < TABLE_COL0(1)) {
                extrapolate1 = LEFT;
                last1 = 0;
            }
            else if (u1 > TABLE_COL0(nRow - 1)) {
                extrapolate1 = RIGHT;
                last1 = nRow - 3;
            }
            else {
                last1 = findRowIndex(&TABLE(1, 0), nRow - 1, nCol,
                    tableID->last1, u1);
                tableID->last1 = last1;
            }

            if (u2 < TABLE_ROW0(1)) {
                extrapolate2 = LEFT;
                last2 = 0;
            }
            else if (u2 > TABLE_ROW0(nCol - 1)) {
                extrapolate2 = RIGHT;
                last2 = nCol - 3;
            }
            else {
                last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                    tableID->last2, u2);
                tableID->last2 = last2;
            }

            switch (tableID->smoothness) {
                case CONSTANT_SEGMENTS:
                    if (extrapolate1 == IN_TABLE && extrapolate2 == IN_TABLE) {
                        break;
                    }
                    /* Fall through: bilinear extrapolation */
                case LINEAR_SEGMENTS: {
                    const double u10 = TABLE_COL0(last1 + 1);
                    const double u11 = TABLE_COL0(last1 + 2);
                    const double u20 = TABLE_ROW0(last2 + 1);
                    const double u21 = TABLE_ROW0(last2 + 2);
                    const double y00 = TABLE(last1 + 1, last2 + 1);
                    const double y01 = TABLE(last1 + 1, last2 + 2);
                    const double y10 = TABLE(last1 + 2, last2 + 1);
                    const double y11 = TABLE(last1 + 2, last2 + 2);
                    der_y = (u21*(y10 - y00) + u20*(y01 - y11) +
                        u2*(y00 - y01 - y10 + y11))*der_u1;
                    der_y += (u11*(y01 - y00) + u10*(y10 - y11) +
                        u1*(y00 - y01 - y10 + y11))*der_u2;
                    der_y /= (u10 - u11);
                    der_y /= (u20 - u21);
                }

                case CONTINUOUS_DERIVATIVE:
                    if (tableID->spline != NULL) {
                        const double* c = tableID->spline[
                            IDX(last1, last2, nCol - 2)];
                        if (extrapolate1 == IN_TABLE) {
                            double der_y1, der_y2;
                            u1 -= TABLE_COL0(last1 + 1);
                            if (extrapolate2 == IN_TABLE) {
                                double p1, p2, p3;
                                double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                u2 -= TABLE_ROW0(last2 + 1);
                                p1 = ((c[0]*u2 + c[1])*u2 + c[2])*u2 + c[3];
                                p2 = ((c[4]*u2 + c[5])*u2 + c[6])*u2 + c[7];
                                p3 = ((c[8]*u2 + c[9])*u2 + c[10])*u2 + c[11];
                                dp1_u2 = (3*c[0]*u2 + 2*c[1])*u2 + c[2];
                                dp2_u2 = (3*c[4]*u2 + 2*c[5])*u2 + c[6];
                                dp3_u2 = (3*c[8]*u2 + 2*c[9])*u2 + c[10];
                                dp4_u2 = (3*c[12]*u2 + 2*c[13])*u2 + c[14];
                                der_y1 = (3*p1*u1 + 2*p2)*u1 + p3;
                                der_y2 = ((dp1_u2*u1 + dp2_u2)*u1 + dp3_u2)*u1 + dp4_u2;
                            }
                            else if (extrapolate2 == LEFT) {
                                u2 -= TABLE_ROW0(1);
                                der_y1 = (3*c[3]*u1 + 2*c[7])*u1 + c[11];
                                der_y1 += ((3*c[2]*u1 + 2*c[6])*u1 + c[10])*u2;
                                der_y2 = ((c[2]*u1 + c[6])*u1 + c[10])*u1 + c[14];
                            }
                            else /* if (extrapolate2 == RIGHT) */ {
                                const double v2 = TABLE_ROW0(nCol - 1) -
                                    TABLE_ROW0(nCol - 2);
                                double p1, p2, p3;
                                double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                u2 -= TABLE_ROW0(nCol - 1);
                                p1 = ((c[0]*v2 + c[1])*v2 + c[2])*v2 + c[3];
                                p2 = ((c[4]*v2 + c[5])*v2 + c[6])*v2 + c[7];
                                p3 = ((c[8]*v2 + c[9])*v2 + c[10])*v2 + c[11];
                                dp1_u2 = (3*c[0]*v2 + 2*c[1])*v2 + c[2];
                                dp2_u2 = (3*c[4]*v2 + 2*c[5])*v2 + c[6];
                                dp3_u2 = (3*c[8]*v2 + 2*c[9])*v2 + c[10];
                                dp4_u2 = (3*c[12]*v2 + 2*c[13])*v2 + c[14];
                                der_y1 = (3*p1*u1 + 2*p2)*u1 + p3;
                                der_y1 += ((3*dp1_u2*u1 + 2*dp2_u2)*u1 + dp3_u2)*u2;
                                der_y2 = ((dp1_u2*u1 + dp2_u2)*u1 + dp3_u2)*u1 + dp4_u2;
                            }
                            der_y = der_y1*der_u1 + der_y2*der_u2;
                        }
                        else if (extrapolate1 == LEFT) {
                            u1 -= TABLE_COL0(1);
                            if (extrapolate2 == IN_TABLE) {
                                double der_y1, der_y2;
                                u2 -= TABLE_ROW0(last2 + 1);
                                der_y1 = ((c[8]*u2 + c[9])*u2 + c[10])*u2 + c[11];
                                der_y2 = (3*c[12]*u2 + 2*c[13])*u2 + c[14];
                                der_y2 += ((3*c[8]*u2 + 2*c[9])*u2 + c[10])*u1;
                                der_y = der_y1*der_u1 + der_y2*der_u2;
                            }
                            else if (extrapolate2 == LEFT) {
                                double der_y1, der_y2, der_y12;
                                u2 -= TABLE_ROW0(1);
                                der_y1 = c[11];
                                der_y2 = c[14];
                                der_y12 = c[10];
                                der_y = (der_y1 + der_y12*u2)*der_u1;
                                der_y += (der_y2 + der_y12*u1)*der_u2;
                            }
                            else /* if (extrapolate2 == RIGHT) */ {
                                const double v2 = TABLE_ROW0(nCol - 1) -
                                    TABLE_ROW0(nCol - 2);
                                double der_y1, der_y2, der_y12;
                                u2 -= TABLE_ROW0(nCol - 1);
                                der_y1 = ((c[8]*v2 + c[9])*v2 + c[10])*v2 + c[11];
                                der_y2 =(3*c[12]*v2 + 2*c[13])*v2 + c[14];
                                der_y12 = (3*c[8]*v2 + 2*c[9])*v2 + c[10];
                                der_y = (der_y1 + der_y12*u2)*der_u1;
                                der_y += (der_y2 + der_y12*u1)*der_u2;
                            }
                        }
                        else /* if (extrapolate1 == RIGHT) */ {
                            const double v1 = TABLE_COL0(nRow - 1) -
                                TABLE_COL0(nRow - 2);
                            u1 -= TABLE_COL0(nRow - 1);
                            if (extrapolate2 == IN_TABLE) {
                                double p1, p2, p3;
                                double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                double der_y1, der_y2;
                                u2 -= TABLE_ROW0(last2 + 1);
                                p1 = ((c[0]*u2 + c[1])*u2 + c[2])*u2 + c[3];
                                p2 = ((c[4]*u2 + c[5])*u2 + c[6])*u2 + c[7];
                                p3 = ((c[8]*u2 + c[9])*u2 + c[10])*u2 + c[11];
                                dp1_u2 = (3*c[0]*u2 + 2*c[1])*u2 + c[2];
                                dp2_u2 = (3*c[4]*u2 + 2*c[5])*u2 + c[6];
                                dp3_u2 = (3*c[8]*u2 + 2*c[9])*u2 + c[10];
                                dp4_u2 = (3*c[12]*u2 + 2*c[13])*u2 + c[14];
                                der_y1 = (3*p1*v1 + 2*p2)*v1 + p3;
                                der_y2 = ((dp1_u2*v1 + dp2_u2)*v1 + dp3_u2)*v1 + dp4_u2;
                                der_y2 += ((3*dp1_u2*v1 + 2*dp2_u2)*v1 + dp3_u2)*u1;
                                der_y = der_y1*der_u1 + der_y2*der_u2;
                            }
                            else if (extrapolate2 == LEFT) {
                                double der_y1, der_y2, der_y12;
                                u2 -= TABLE_ROW0(1);
                                der_y1 = (3*c[3]*v1 + 2*c[7])*v1 + c[11];
                                der_y2 = ((c[2]*v1 + c[6])*v1 + c[10])*v1 + c[14];
                                der_y12 = (3*c[2]*v1 + 2*c[6])*v1 + c[10];
                                der_y = (der_y1 + der_y12*u2)*der_u1;
                                der_y += (der_y2 + der_y12*u1)*der_u2;
                            }
                            else /* if (extrapolate2 == RIGHT) */ {
                                const double v2 = TABLE_ROW0(nCol - 1) -
                                    TABLE_ROW0(nCol - 2);
                                double p1, p2, p3;
                                double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                double der_y1, der_y2, der_y12;
                                u2 -= TABLE_ROW0(nCol - 1);
                                p1 = ((c[0]*v2 + c[1])*v2 + c[2])*v2 + c[3];
                                p2 = ((c[4]*v2 + c[5])*v2 + c[6])*v2 + c[7];
                                p3 = ((c[8]*v2 + c[9])*v2 + c[10])*v2 + c[11];
                                dp1_u2 = (3*c[0]*v2 + 2*c[1])*v2 + c[2];
                                dp2_u2 = (3*c[4]*v2 + 2*c[5])*v2 + c[6];
                                dp3_u2 = (3*c[8]*v2 + 2*c[9])*v2 + c[10];
                                dp4_u2 = (3*c[12]*v2 + 2*c[13])*v2 + c[14];
                                der_y1 = (3*p1*v1 + 2*p2)*v1 + p3;
                                der_y2 = ((dp1_u2*v1 + dp2_u2)*v1 + dp3_u2)*v1 + dp4_u2;
                                der_y12 = (3*dp1_u2*v1 + 2*dp2_u2)*v1 + dp3_u2;
                                der_y = (der_y1 + der_y12*u2)*der_u1;
                                der_y += (der_y2 + der_y12*u1)*der_u2;
                            }
                        }
                    }
                    break;

                case MONOTONE_CONTINUOUS_DERIVATIVE:
                    ModelicaError("Bivariate monotone interpolation is "
                        "not implemented\n");
                    return der_y;

                default:
                    ModelicaError("Unknown smoothness kind\n");
                    return der_y;
            }
        }
    }
    return der_y;
}

/* ----- Internal functions ----- */

static int isNearlyEqual(double x, double y) {
    const double fx = fabs(x);
    const double fy = fabs(y);
    double cmp = fx > fy ? fx : fy;
    if (cmp < _EPSILON) {
        cmp = _EPSILON;
    }
    cmp *= _EPSILON;
    return fabs(y - x) < cmp;
}

static size_t findRowIndex(const double* table, size_t nRow, size_t nCol,
                           size_t last, double x) {
    size_t i0 = 0;
    size_t i1 = nRow - 1;
    if (x < TABLE_COL0(last)) {
        i1 = last;
    }
    else if (x >= TABLE_COL0(last + 1)) {
        i0 = last;
    }
    else {
        return last;
    }

    /* Binary search */
    while (i1 > i0 + 1) {
        const size_t i = (i0 + i1)/2;
        if (x < TABLE_COL0(i)) {
            i1 = i;
        }
        else {
            i0 = i;
        }
    }
    return i0;
}

static size_t findColIndex(const double* table, size_t nCol, size_t last,
                           double x) {
    size_t i0 = 0;
    size_t i1 = nCol - 1;
    if (x < TABLE_ROW0(last)) {
        i1 = last;
    }
    else if (x >= TABLE_ROW0(last + 1)) {
        i0 = last;
    }
    else {
        return last;
    }

    /* Binary search */
    while (i1 > i0 + 1) {
        const size_t i = (i0 + i1)/2;
        if (x < TABLE_ROW0(i)) {
            i1 = i;
        }
        else {
            i0 = i;
        }
    }
    return i0;
}

/* ----- Internal check functions ----- */

static int isValidName(const char* name) {
    int isValid = 0;
    if (name != NULL) {
        if (strcmp(name, "NoName") != 0) {
            size_t i;
            size_t len = strlen(name);
            for (i = 0; i < len; i++) {
                if (name[i] != ' ') {
                    isValid = 1;
                    break;
                }
            }
        }
    }
    return isValid;
}

static int isValidCombiTimeTable(const CombiTimeTable* tableID) {
    int isValid = 1;
    if (tableID != NULL) {
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        const char* tableName;
        const char* tableDummyName = "NoName";
        size_t iCol;

        if (tableID->source == TABLESOURCE_MODEL) {
            tableName = tableDummyName;
        }
        else {
            tableName = tableID->tableName;
        }

        /* Check dimensions */
        if (nRow < 1 || nCol < 2) {
            ModelicaFormatError(
                "Table matrix \"%s(%lu,%lu)\" does not have appropriate "
                "dimensions for time interpolation.\n", tableName,
                (unsigned long)nRow, (unsigned long)nCol);
            isValid = 0;
            return isValid;
        }

        /* Check column indices */
        for (iCol = 0; iCol < tableID->nCols; ++iCol) {
            const size_t col = (size_t)tableID->cols[iCol];
            if (col < 1 || col > tableID->nCol) {
                ModelicaFormatError("The column index %d is out of range "
                    "for table matrix \"%s(%lu,%lu)\".\n", tableID->cols[iCol],
                    tableName, (unsigned long)nRow, (unsigned long)nCol);
            }
        }

        if (tableID->table != NULL && nRow > 1) {
            const double* table = tableID->table;
            /* Check period */
            if (tableID->extrapolation == PERIODIC) {
                const double tMin = TABLE_ROW0(0);
                const double tMax = TABLE_COL0(nRow - 1);
                const double T = tMax - tMin;
                if (T <= 0) {
                    ModelicaFormatError(
                        "Table matrix \"%s\" does not have a positive period/cylce "
                        "time for time interpolation with periodic "
                        "extrapolation.\n", tableName);
                    isValid = 0;
                    return isValid;
                }
            }

            /* Check, whether first column values are monotonically or strictly
               increasing */
            if (tableID->smoothness == CONTINUOUS_DERIVATIVE ||
                tableID->smoothness == MONOTONE_CONTINUOUS_DERIVATIVE) {
                size_t i;
                for (i = 0; i < nRow - 1; i++) {
                    double t0 = TABLE_COL0(i);
                    double t1 = TABLE_COL0(i + 1);
                    if (t0 >= t1) {
                        ModelicaFormatError(
                            "The values of the first column of table \"%s(%lu,%lu)\" "
                            "are not strictly increasing because %s(%lu,1) (=%lf) "
                            ">= %s(%lu,1) (=%lf).\n", tableName, (unsigned long)nRow,
                            (unsigned long)nCol, tableName, (unsigned long)i + 1, t0,
                            tableName, (unsigned long)i + 2, t1);
                        isValid = 0;
                        return isValid;
                    }
                }
            }
            else {
                size_t i;
                for (i = 0; i < nRow - 1; i++) {
                    double t0 = TABLE_COL0(i);
                    double t1 = TABLE_COL0(i + 1);
                    if (t0 > t1) {
                        ModelicaFormatError(
                            "The values of the first column of table \"%s(%lu,%lu)\" "
                            "are not monotonically increasing because %s(%lu,1) "
                            "(=%lf) > %s(%lu,1) (=%lf).\n", tableName,
                            (unsigned long)nRow, (unsigned long)nCol, tableName,
                            (unsigned long)i + 1, t0, tableName, (unsigned long)i +
                            2, t1);
                        isValid = 0;
                        return isValid;
                    }
                }
            }
        }
    }

    return isValid;
}

static int isValidCombiTable1D(const CombiTable1D* tableID) {
    int isValid = 1;
    if (tableID != NULL) {
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        const char* tableName;
        const char* tableDummyName = "NoName";
        size_t iCol;

        if (tableID->source == TABLESOURCE_MODEL) {
            tableName = tableDummyName;
        }
        else {
            tableName = tableID->tableName;
        }

        /* Check dimensions */
        if (nRow < 1 || nCol < 2) {
            ModelicaFormatError(
                "Table matrix \"%s(%lu,%lu)\" does not have appropriate "
                "dimensions for 1D-interpolation.\n", tableName,
                (unsigned long)nRow, (unsigned long)nCol);
            isValid = 0;
            return isValid;
        }

        /* Check column indices */
        for (iCol = 0; iCol < tableID->nCols; ++iCol) {
            const size_t col = (size_t)tableID->cols[iCol];
            if (col < 1 || col > tableID->nCol) {
                ModelicaFormatError("The column index %d is out of range "
                    "for table matrix \"%s(%lu,%lu)\".\n", tableID->cols[iCol],
                    tableName, (unsigned long)nRow, (unsigned long)nCol);
            }
        }

        if (tableID->table != NULL) {
            const double* table = tableID->table;
            size_t i;
            /* Check, whether first column values are strictly increasing */
            for (i = 0; i < nRow - 1; i++) {
                double x0 = TABLE_COL0(i);
                double x1 = TABLE_COL0(i + 1);
                if (x0 >= x1) {
                    ModelicaFormatError(
                        "The values of the first column of table \"%s(%lu,%lu)\" are "
                        "not strictly increasing because %s(%lu,1) (=%lf) >= "
                        "%s(%lu,1) (=%lf).\n", tableName, (unsigned long)nRow,
                        (unsigned long)nCol, tableName, (unsigned long)i + 1, x0,
                        tableName, (unsigned long)i + 2, x1);
                    isValid = 0;
                    return isValid;
                }
            }
        }
    }

    return isValid;
}

static int isValidCombiTable2D(const CombiTable2D* tableID) {
    int isValid = 1;
    if (tableID != NULL) {
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        const char* tableName;
        const char* tableDummyName = "NoName";

        if (tableID->source == TABLESOURCE_MODEL) {
            tableName = tableDummyName;
        }
        else {
            tableName = tableID->tableName;
        }

        /* Check dimensions */
        if (nRow < 2 || nCol < 2) {
            ModelicaFormatError(
                "Table matrix \"%s(%lu,%lu)\" does not have appropriate "
                "dimensions for 2D-interpolation.\n", tableName,
                (unsigned long)nRow, (unsigned long)nCol);
            isValid = 0;
            return isValid;
        }

        if (tableID->table != NULL) {
            const double* table = tableID->table;
            size_t i;
            /* Check, whether first column values are strictly increasing */
            for (i = 1; i < nRow - 1; i++) {
                double x0 = TABLE_COL0(i);
                double x1 = TABLE_COL0(i + 1);
                if (x0 >= x1) {
                    ModelicaFormatError(
                        "The values of the first column of table \"%s(%lu,%lu)\" are "
                        "not strictly increasing because %s(%lu,1) (=%lf) >= "
                        "%s(%lu,1) (=%lf).\n", tableName, (unsigned long)nRow,
                        (unsigned long)nCol, tableName, (unsigned long)i + 1,
                        x0, tableName, (unsigned long)i + 2, x1);
                    isValid = 0;
                    return isValid;
                }
            }

            /* Check, whether first row values are strictly increasing */
            for (i = 1; i < nCol - 1; i++) {
                double y0 = TABLE_ROW0(i);
                double y1 = TABLE_ROW0(i + 1);
                if (y0 >= y1) {
                    ModelicaFormatError(
                        "The values of the first row of table \"%s(%lu,%lu)\" are "
                        "not strictly increasing because %s(1,%lu) (=%lf) >= "
                        "%s(1,%lu) (=%lf).\n", tableName, (unsigned long)nRow,
                        (unsigned long)nCol, tableName, (unsigned long)i + 1,
                        y0, tableName, (unsigned long)i + 2, y1);
                    isValid = 0;
                    return isValid;
                }
            }
        }
    }

    return isValid;
}

static enum TableSource getTableSource(const char *tableName,
                                       const char *fileName) {
    enum TableSource tableSource;
    int tableNameGiven = isValidName(tableName);
    int fileNameGiven = isValidName(fileName);

    /* Determine in which way the table values are defined */
    if (tableNameGiven == 0) {
        /* No table name is given */
        if (fileNameGiven != 0) {
            ModelicaFormatError(
                "The file name for a table (= \"%s\") is defined, "
                "but not the corresponding table name.\n", fileName);
        }
        tableSource = TABLESOURCE_MODEL;
    }
    else {
        /* A table name is given */
#if defined(NO_FILE_SYSTEM)
        if (fileNameGiven != 0) {
            ModelicaFormatError(
                "The file name (= \"%s\") for a table (= \"%s\") is defined. "
                "Since Modelica is used in an environment where storage cannot "
                "be allocated (#define NO_FILE_SYSTEM), tables cannot be read "
                "from file.\n", fileName, tableName);
        }
        tableSource = TABLESOURCE_FUNCTION;
#else
        tableSource =
            fileNameGiven == 0 ? TABLESOURCE_FUNCTION : TABLESOURCE_FILE;
#endif
    }
    return tableSource;
}

/* ----- Internal univariate spline functions ---- */

static CubicHermite1D* akimaSpline1DInit(const double* table, size_t nRow,
                                         size_t nCol, const int* cols,
                                         size_t nCols) {
  /* Reference:

     Hiroshi Akima. A new method of interpolation and smooth curve fitting
     based on local procedures. Journal of the ACM, 17(4), 589-602, Oct. 1970.
     (http://dx.doi.org/10.1145/321607.321609)
  */

    CubicHermite1D* spline = NULL;
    double* d; /* Divided differences */
    size_t col;

    /* Actually there is no need for consecutive memory */
    spline = (CubicHermite1D*)malloc((nRow - 1)*nCols*sizeof(CubicHermite1D));
    if (spline == NULL) {
        return NULL;
    }

    d = (double*)malloc((nRow + 3)*sizeof(double));
    if (d == NULL) {
        free(spline);
        return NULL;
    }

    for (col = 0; col < nCols; col++) {
        size_t i;
        double c2;

        /* Calculation of the divided differences */
        for (i = 0; i < nRow - 1; i++) {
            d[i + 2] =
                (TABLE(i + 1, cols[col] - 1) - TABLE(i, cols[col] - 1))/
                (TABLE_COL0(i + 1) - TABLE_COL0(i));
        }

        /* Extrapolation using non-periodic boundary conditions */
        d[0] = 3*d[2] - 2*d[3];
        d[1] = 2*d[2] - d[3];
        d[nRow + 1] = 2*d[nRow] - d[nRow - 1];
        d[nRow + 2] = 3*d[nRow] - 2*d[nRow - 1];

        /* Initialization of the left boundary slope */
        c2 = fabs(d[3] - d[2]) + fabs(d[1] - d[0]);
        if (c2 > 0) {
            const double a = fabs(d[1] - d[0])/c2;
            c2 = (1 - a)*d[1] + a*d[2];
        }
        else {
            c2 = 0.5*d[1] + 0.5*d[2];
        }

        /* Calculation of the 3(4) coefficients per interval */
        for (i = 0; i < nRow - 1; i++) {
            const double dx = TABLE_COL0(i + 1) - TABLE_COL0(i);
            double* c = spline[IDX(i, col, nCols)];

            c[2] = c2;
            c2 = fabs(d[i + 4] - d[i + 3]) + fabs(d[i + 2] - d[i + 1]);
            if (c2 > 0) {
                const double a = fabs(d[i + 2] - d[i + 1])/c2;
                c2 = (1 - a)*d[i + 2] + a*d[i + 3];
            }
            else {
                c2 = 0.5*d[i + 2] + 0.5*d[i + 3];
            }
            c[1] = (3*d[i + 2] - 2*c[2] - c2)/dx;
            c[0] = (c[2] + c2 - 2*d[i + 2])/(dx*dx);
            /* No need to store the absolute term y0 */
            /* c[3] = TABLE(i, cols[col] - 1); */
        }
    }

    free(d);
    return spline;
}

static CubicHermite1D* fritschButlandSpline1DInit(const double* table,
                                                  size_t nRow, size_t nCol,
                                                  const int* cols,
                                                  size_t nCols) {
  /* Reference:

     Frederick N. Fritsch and Judy Butland. A method for constructing local
     monotone piecewise cubic interpolants. SIAM Journal on Scientific and
     Statistical Computing, 5(2), 300-304, June 1984.
     (http://dx.doi.org/10.1137/0905021)
  */

    CubicHermite1D* spline = NULL;
    double* d; /* Divided differences */
    size_t col;

    /* Actually there is no need for consecutive memory */
    spline = (CubicHermite1D*)malloc((nRow - 1)*nCols*sizeof(CubicHermite1D));
    if (spline == NULL) {
        return NULL;
    }

    d = (double*)malloc((nRow - 1)*sizeof(double));
    if (d == NULL) {
        free(spline);
        return NULL;
    }

    for (col = 0; col < nCols; col++) {
        size_t i;
        double c2;

        /* Calculation of the divided differences */
        for (i = 0; i < nRow - 1; i++) {
            d[i] =
                (TABLE(i + 1, cols[col] - 1) - TABLE(i, cols[col] - 1))/
                (TABLE_COL0(i + 1) - TABLE_COL0(i));
        }

        /* Initialization of the left boundary slope */
        c2 = d[0];

        /* Calculation of the 3(4) coefficients per interval */
        for (i = 0; i < nRow - 1; i++) {
            const double dx = TABLE_COL0(i + 1) - TABLE_COL0(i);
            double* c = spline[IDX(i, col, nCols)];

            c[2] = c2;
            if (i == nRow - 2) {
                c2 = d[nRow - 2];
            }
            else if (d[i]*d[i + 1] <= 0) {
                c2 = 0;
            }
            else {
                const double dx_ = TABLE_COL0(i + 2) - TABLE_COL0(i + 1);
                c2 = 3*(dx + dx_)/((dx + 2*dx_)/d[i] + (dx_ + 2*dx)/d[i + 1]);
            }
            c[1] = (3*d[i] - 2*c[2] - c2)/dx;
            c[0] = (c[2] + c2 - 2*d[i])/(dx*dx);
            /* No need to store the absolute term y0 */
            /* c[3] = TABLE(i, cols[col] - 1); */
        }
    }

    free(d);
    return spline;
}

static void spline1DClose(CubicHermite1D** spline) {
    if (spline != NULL && *spline != NULL) {
        free(*spline);
        *spline = NULL;
    }
}

/* ----- Internal bivariate spline functions ---- */

static void spline1DExtrapolateLeft(double x1, double x2, double x3, double x4,
                                    double x5, double* y1, double* y2,
                                    double y3, double y4, double y5) {
    const double a = x4 - x5;
    const double b = x3 - x4;
    const double c = x2 - x3;

    if (a == 0. || b == 0. || c == 0.) {
        *y2 = y3;
        *y1 = y3;
    }
    else {
        const double d = x1 - x2;
        const double e = y4 - y5;
        const double f = y3 - y4;
        *y2 = c*(2*f/b - e/a) + y3;
        *y1 = *y2 + d*((*y2 - y3)/c + f/b - e/a);
    }
}

static void spline1DExtrapolateRight(double x1, double x2, double x3, double x4,
                                     double x5, double y1, double y2, double y3,
                                     double* y4, double* y5) {
    const double a = x2 - x1;
    const double b = x3 - x2;
    const double c = x4 - x3;

    if (a == 0. || b == 0. || c == 0.) {
        *y4 = y3;
        *y5 = y3;
    }
    else {
        const double d = x5 - x4;
        const double e = y2 - y1;
        const double f = y3 - y2;
        *y4 = c*(2*f/b - e/a) + y3;
        *y5 = *y4 + d*((*y4 - y3)/c + f/b - e/a);
    }
}

#define TABLE_EX(i, j) tableEx[IDX(i, j, nCol + 3)]

static CubicHermite2D* spline2DInit(const double* table, size_t nRow, size_t nCol) {
  /* Reference:

     Hiroshi Akima. A method of bivariate interpolation and smooth surface
     fitting based on local procedures. Communications of the ACM, 17(1), 18-20,
     Jan. 1974. (http://dx.doi.org/10.1145/360767.360779)
  */

    CubicHermite2D* spline = NULL;
    if (nRow == 2 /* && nCol > 3 */) {
        CubicHermite1D* spline1D;
        size_t j;
        int cols = 2;

        /* Need to transpose */
        double* tableT = (double*)malloc(2*(nCol - 1)*sizeof(double));
        if (tableT == NULL) {
            return NULL;
        }

        spline = (CubicHermite2D*)malloc((nCol - 1)*sizeof(CubicHermite2D));
        if (spline == NULL) {
            free(tableT);
            return NULL;
        }

        for (j = 1; j < nCol; j++) {
            tableT[IDX(j - 1, 0, 2)] = TABLE_ROW0(j);
            tableT[IDX(j - 1, 1, 2)] = TABLE(1, j);
        }

        spline1D = akimaSpline1DInit(tableT, nCol - 1, 2, &cols, 1);
        free(tableT);
        if (spline1D == NULL) {
            free(spline);
            return NULL;
        }
        /* Copy coefficients */
        for (j = 0; j < nCol - 1; j++) {
            const double* c1 = spline1D[j];
            double* c2 = spline[j];
            c2[0] = c1[0];
            c2[1] = c1[1];
            c2[2] = c1[2];
        }
        spline1DClose(&spline1D);
    }
    else if (/*nRow > 3 && */ nCol == 2) {
        CubicHermite1D* spline1D;
        size_t i;
        int cols = 2;

        spline = (CubicHermite2D*)malloc((nRow - 1)*sizeof(CubicHermite2D));
        if (spline == NULL) {
            return NULL;
        }

        spline1D = akimaSpline1DInit(&table[2], nRow - 1, 2, &cols, 1);
        if (spline1D == NULL) {
            free(spline);
            return NULL;
        }
        /* Copy coefficients */
        for (i = 0; i < nRow - 1; i++) {
            const double* c1 = spline1D[i];
            double* c2 = spline[i];
            c2[0] = c1[0];
            c2[1] = c1[1];
            c2[2] = c1[2];
        }
        spline1DClose(&spline1D);
    }
    else /* if (nRow > 2 && nCol > 2) */ {
        size_t i, j;
        double* dz_dx;
        double* dz_dy;
        double* d2z_dxdy;
        double* tableEx;
        double* x;
        double* y;

        /* This is not the most memory efficient implementation since the table
           memory is temporarily doubled for the sake of a clean calculation of
           the partial derivatives without special consideration of the boundary
           regions.
        */

        /* Copy of x coordinates with extrapolated boundary coordinates */
        x = (double*)malloc((nRow + 3)*sizeof(double));
        if (x == NULL) {
            return NULL;
        }
        if (nRow == 3) {
            /* Linear extrapolation */
            x[0] = 3*TABLE_COL0(1) - 2*TABLE_COL0(2);
            x[1] = 2*TABLE_COL0(1) - TABLE_COL0(2);
            x[2] = TABLE_COL0(1);
            x[3] = TABLE_COL0(2);
            x[4] = 2*TABLE_COL0(2) - TABLE_COL0(1);
            x[5] = 3*TABLE_COL0(2) - 2*TABLE_COL0(1);
        }
        else {
            x[0] = 2*TABLE_COL0(1) - TABLE_COL0(3);
            x[1] = TABLE_COL0(1) + TABLE_COL0(2) - TABLE_COL0(3);
            for (i = 1; i < nRow; i++) {
                x[i + 1] = TABLE_COL0(i);
            }
            x[nRow + 1] = TABLE_COL0(nRow - 1) +
                TABLE_COL0(nRow - 2) - TABLE_COL0(nRow - 3);
            x[nRow + 2] = 2*TABLE_COL0(nRow - 1) - TABLE_COL0(nRow - 3);
        }

        /* Copy of y coordinates with extrapolated boundary coordinates */
        y = (double*)malloc((nCol + 3)*sizeof(double));
        if (y == NULL) {
            free(x);
            return NULL;
        }
        if (nCol == 3) {
            /* Linear extrapolation */
            y[0] = 3*TABLE_ROW0(1) - 2*TABLE_ROW0(2);
            y[1] = 2*TABLE_ROW0(1) - TABLE_ROW0(2);
            y[2] = TABLE_ROW0(1);
            y[3] = TABLE_ROW0(2);
            y[4] = 2*TABLE_ROW0(2) - TABLE_ROW0(1);
            y[5] = 3*TABLE_ROW0(2) - 2*TABLE_ROW0(1);
        }
        else {
            y[0] = 2*TABLE_ROW0(1) - TABLE_ROW0(3);
            y[1] = TABLE_ROW0(1) + TABLE_ROW0(2) - TABLE_ROW0(3);
            memcpy(&y[2], &TABLE_ROW0(1), (nCol - 1)*sizeof(double));
            y[nCol + 1] = TABLE_ROW0(nCol - 1) +
                TABLE_ROW0(nCol - 2) - TABLE_ROW0(nCol - 3);
            y[nCol + 2] = 2*TABLE_ROW0(nCol - 1) - TABLE_ROW0(nCol - 3);
        }

        /* Copy of table with extrapolated boundary values */
        tableEx = (double*)malloc((nRow + 3)*(nCol + 3)*sizeof(double));
        if (tableEx == NULL) {
            free(y);
            free(x);
            return NULL;
        }
        for (i = 1; i < nRow; i++) {
            /* Copy table row */
            memcpy(&TABLE_EX(i + 1, 2), &TABLE(i, 1), (nCol - 1)*sizeof(double));
        }
        if (nCol == 3) {
            /* Linear extrapolation in y direction */
            for (i = 1; i < nRow; i++) {
                TABLE_EX(i + 1, 0) = 3*TABLE(i, 1) - 2*TABLE(i, 2);
                TABLE_EX(i + 1, 1) = 2*TABLE(i, 1) - TABLE(i, 2);
                TABLE_EX(i + 1, 4) = 2*TABLE(i, 2) - TABLE(i, 1);
                TABLE_EX(i + 1, 5) = 3*TABLE(i, 2) - 2*TABLE(i, 1);
            }
        }
        else {
            for (i = 1; i < nRow; i++) {
                /* Extrapolate table data in y direction */
                spline1DExtrapolateLeft(y[0], y[1], y[2], y[3], y[4],
                    &TABLE_EX(i + 1, 0), &TABLE_EX(i + 1, 1), TABLE_EX(i + 1, 2),
                    TABLE_EX(i + 1, 3), TABLE_EX(i + 1, 4));
                spline1DExtrapolateRight(y[nCol - 2], y[nCol - 1], y[nCol],
                    y[nCol + 1], y[nCol + 2], TABLE_EX(i + 1, nCol - 2),
                    TABLE_EX(i + 1, nCol - 1), TABLE_EX(i + 1, nCol),
                    &TABLE_EX(i + 1, nCol + 1), &TABLE_EX(i + 1, nCol + 2));
            }
        }
        if (nRow == 3) {
            /* Linear extrapolation in x direction */
            for (j = 0; j < nCol + 3; j++) {
                TABLE_EX(0, j) = 3*TABLE_EX(2, j) - 2*TABLE_EX(3, j);
                TABLE_EX(1, j) = 2*TABLE_EX(2, j) - TABLE_EX(3, j);
                TABLE_EX(4, j) = 2*TABLE_EX(3, j) - TABLE_EX(2, j);
                TABLE_EX(5, j) = 3*TABLE_EX(3, j) - 2*TABLE_EX(2, j);
            }
        }
        else {
            for (j = 0; j < nCol + 3; j++) {
                /* Extrapolate table data in x direction */
                spline1DExtrapolateLeft(x[0], x[1], x[2], x[3], x[4],
                    &TABLE_EX(0, j), &TABLE_EX(1, j), TABLE_EX(2, j),
                    TABLE_EX(3, j), TABLE_EX(4, j));
                spline1DExtrapolateRight(x[nRow - 2], x[nRow - 1], x[nRow],
                    x[nRow + 1], x[nRow + 2], TABLE_EX(nRow - 2, j),
                    TABLE_EX(nRow - 1, j), TABLE_EX(nRow, j),
                    &TABLE_EX(nRow + 1, j), &TABLE_EX(nRow + 2, j));
            }
        }

        dz_dx = (double*)malloc((nRow - 1)*(nCol - 1)*sizeof(double));
        if (dz_dx == NULL) {
            free(tableEx);
            free(y);
            free(x);
            return NULL;
        }

        dz_dy = (double*)malloc((nRow - 1)*(nCol - 1)*sizeof(double));
        if (dz_dy == NULL) {
            free(dz_dx);
            free(tableEx);
            free(y);
            free(x);
            return NULL;
        }

        d2z_dxdy = (double*)malloc((nRow - 1)*(nCol - 1)*sizeof(double));
        if (d2z_dxdy == NULL) {
            free(dz_dy);
            free(dz_dx);
            free(tableEx);
            free(y);
            free(x);
            return NULL;
        }

        /* Calculation of the partial derivatives */
        for (i = 2; i < nRow + 1; i++) {
            for (j = 2; j < nCol + 1; j++) {
                /* Divided differences */
                double d31, d32, d33, d34, d22, d23, d42, d43;
                /* Weights */
                double wx2, wx3, wy2, wy3;

                /* Partial derivatives in x direction */
                d31 = (TABLE_EX(i - 1, j) - TABLE_EX(i - 2, j))/
                    (x[i - 1] - x[i - 2]); /* = c13 */
                d32 = (TABLE_EX(i, j) - TABLE_EX(i - 1, j))/
                    (x[i] - x[i - 1]); /* = c23 */
                d33 = (TABLE_EX(i + 1, j) - TABLE_EX(i, j))/
                    (x[i + 1] - x[i]); /* = c33 */
                d34 = (TABLE_EX(i + 2, j) - TABLE_EX(i + 1, j))/
                    (x[i + 2] - x[i + 1]); /* = c43 */
                if (d31 == d32 && d33 == d34) {
                    wx2 = 0.;
                    wx3 = 0.;
                    dz_dx[IDX(i - 2, j - 2, nCol - 1)] = 0.5*d32 + 0.5*d33;
                }
                else {
                    wx2 = fabs(d34 - d33);
                    wx3 = fabs(d32 - d31);
                    dz_dx[IDX(i - 2, j - 2, nCol - 1)] = (wx2*d32 + wx3*d33)/
                        (wx2 + wx3);
                }

                /* Partial derivatives in y direction */
                d31 = (TABLE_EX(i, j - 1) - TABLE_EX(i, j - 2))/
                    (y[j - 1] - y[j - 2]);
                d32 = (TABLE_EX(i, j) - TABLE_EX(i, j - 1))/
                    (y[j] - y[j - 1]);
                d33 = (TABLE_EX(i, j + 1) - TABLE_EX(i, j))/
                    (y[j + 1] - y[j]);
                d34 = (TABLE_EX(i, j + 2) - TABLE_EX(i, j + 1))/
                    (y[j + 2] - y[j + 1]);
                if (d31 == d32 && d33 == d34) {
                    wy2 = 0.;
                    wy3 = 0.;
                    dz_dy[IDX(i - 2, j - 2, nCol - 1)] = 0.5*d32 + 0.5*d33;
                }
                else {
                    wy2 = fabs(d34 - d33);
                    wy3 = fabs(d32 - d31);
                    dz_dy[IDX(i - 2, j - 2, nCol - 1)] = (wy2*d32 + wy3*d33)/
                        (wy2 + wy3);
                }

                /* Partial cross derivatives */
                d22 = (TABLE_EX(i - 1, j) - TABLE_EX(i - 1, j - 1))/
                    (y[j] - y[j - 1]);
                d23 = (TABLE_EX(i - 1, j + 1) - TABLE_EX(i - 1, j))/
                    (y[j + 1] - y[j]);
                d42 = (TABLE_EX(i + 1, j) - TABLE_EX(i + 1, j - 1))/
                    (y[j] - y[j - 1]);
                d43 = (TABLE_EX(i + 1, j + 1) - TABLE_EX(i + 1, j))/
                    (y[j + 1] - y[j]);
                d22 = (d32 - d22)/(x[i] - x[i - 1]); /* = e22 */
                d23 = (d33 - d23)/(x[i] - x[i - 1]); /* = e23 */
                d32 = (d42 - d32)/(x[i + 1] - x[i]); /* = e32 */
                d33 = (d43 - d33)/(x[i + 1] - x[i]); /* = e33 */
                if (wx2 == 0. && wx3 == 0.) {
                    wx2 = 1.;
                    wx3 = 1.;
                }
                if (wy2 == 0. && wy3 == 0.) {
                    wy2 = 1.;
                    wy3 = 1.;
                }
                d2z_dxdy[IDX(i - 2, j - 2, nCol - 1)] =
                    (wx2*(wy2*d22 + wy3*d23) + wx3*(wy2*d32 + wy3*d33))/
                    ((wx2 + wx3)*(wy2 + wy3));
            }
        }

        free(tableEx);
        free(y);
        free(x);

        /* Actually there is no need for consecutive memory */
        spline = (CubicHermite2D*)malloc((nRow - 2)*(nCol - 2)*sizeof(CubicHermite2D));
        if (spline == NULL) {
            free(dz_dx);
            free(dz_dy);
            free(d2z_dxdy);
            return NULL;
        }

        /* Calculation of the 15(16) coefficients per grid */
        for (i = 0; i < nRow - 2; i++) {
            const double dx = TABLE_COL0(i + 2) - TABLE_COL0(i + 1);
            const double dx_2 = dx*dx;
            const double dx_3 = dx_2*dx;
            for (j = 0; j < nCol - 2; j++) {
                const double z00 = TABLE(i + 1, j + 1);
                const double z01 = TABLE(i + 1, j + 2);
                const double z10 = TABLE(i + 2, j + 1);
                const double z11 = TABLE(i + 2, j + 2);
                const double dy = TABLE_ROW0(j + 2) - TABLE_ROW0(j + 1);
                const double dy_2 = dy*dy;
                const double dy_3 = dy_2*dy;
                double zx00, zx01, zx10, zx11;
                double zy00, zy01, zy10, zy11;
                double zxy00, zxy01, zxy10, zxy11;
                double t1, t2, t3, t4, t5, t6, t7, t8, t9;
                double t10, t11, t12, t13, t14;
                double* c = spline[IDX(i, j, nCol - 2)];

                c[11] = dz_dx[IDX(i, j, nCol - 1)];
                zx00 = c[11]*dx;
                zx01 = dz_dx[IDX(i, j + 1, nCol - 1)]*dx;
                zx10 = dz_dx[IDX(i + 1, j, nCol - 1)]*dx;
                zx11 = dz_dx[IDX(i + 1, j + 1, nCol - 1)]*dx;
                c[14] = dz_dy[IDX(i, j, nCol - 1)];
                zy00 = c[14]*dy;
                zy01 = dz_dy[IDX(i, j + 1, nCol - 1)]*dy;
                zy10 = dz_dy[IDX(i + 1, j, nCol - 1)]*dy;
                zy11 = dz_dy[IDX(i + 1, j + 1, nCol - 1)]*dy;
                c[10] = d2z_dxdy[IDX(i, j, nCol - 1)];
                zxy00 = c[10]*dx*dy;
                zxy01 = d2z_dxdy[IDX(i, j + 1, nCol - 1)]*dx*dy;
                zxy10 = d2z_dxdy[IDX(i + 1, j, nCol - 1)]*dx*dy;
                zxy11 = d2z_dxdy[IDX(i + 1, j + 1, nCol - 1)]*dx*dy;
                t1 = z00 - z10;
                t2 = zx00 + zx10;
                t3 = zy00 - zy10;
                t4 = zy11 - zy01;
                t5 = zxy00 + zxy10;
                t6 = zxy11 + zxy01;
                t7 = 2*zx00 + zx10;
                t8 = 2*zxy00 + zxy10;
                t9 = zxy11 + 2*zxy01;
                t10 = zx00 - zx01;
                t11 = z00 - z01;
                t12 = t1 + (z11 - z01);
                t13 = t3 - t4;
                t4 = 2*t3 - t4;
                t14 = 2*t12 + (t2 - (zx11 + zx01));
                t12 = 3*t12 + (t7 - (zx11 + 2*zx01));
                c[0] = (2*t14 + (2*t13 + (t5 + t6)))/(dx_3*dy_3);
                c[1] = -(3*t14 + (2*t4 + (2*t5 + t6)))/(dx_3*dy_2);
                c[2] = (2*t3 + t5)/(dx_3*dy);
                c[3] = (2*t1 + t2)/dx_3;
                c[4] = -(2*t12 + (3*t13 + (t8 + t9)))/(dx_2*dy_3);
                c[5] = (3*t12 + (3*t4 + (2*t8 + t9)))/(dx_2*dy_2);
                c[6] = -(3*t3 + t8)/(dx_2*dy);
                c[7] = -(3*t1 + t7)/dx_2;
                c[8] = (2*t10 + (zxy00 + zxy01))/(dx*dy_3);
                c[9] = -(3*t10 + (2*zxy00 + zxy01))/(dx*dy_2);
                c[12] = (2*t11 + (zy00 + zy01))/dy_3;
                c[13] = -(3*t11 + (2*zy00 + zy01))/dy_2;
                /* No need to store the absolute term z00 */
                /* c[15] = z00; */
            }
        }

        free(dz_dx);
        free(dz_dy);
        free(d2z_dxdy);
    }
    return spline;
}

#undef TABLE_EX

static void spline2DClose(CubicHermite2D** spline) {
    if (spline != NULL && *spline != NULL) {
        free(*spline);
        *spline = NULL;
    }
}

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

/* ----- Internal I/O functions ----- */

#if !defined(NO_FILE_SYSTEM)
static double* readTable(const char* tableName, const char* fileName,
                         size_t* nRow, size_t* nCol, int verbose, int force) {
    double* table = NULL;
    if (tableName != NULL && fileName != NULL && nRow != NULL && nCol != NULL) {
#if defined(TABLE_SHARE)
        char* key = malloc((strlen(tableName) +
            strlen(fileName) + 2)*sizeof(char));
        if (key != NULL) {
            int updateError = 0;
            TableShare *iter;
            strcpy(key, tableName);
            strcat(key, "|");
            strcat(key, fileName);
            MUTEX_LOCK();
            HASH_FIND_STR(tableShare, key, iter);
            if (iter == NULL || force) {
#endif
                const char* ext;
                int isMatExt = 0;

                /* Table file can be either ASCII text or binary MATLAB MAT-file */
                ext = strrchr(fileName, '.');
                if (ext != NULL) {
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

#if defined(TABLE_SHARE)
                /* Release lock since readMatTable/readTxtTable may fail with
                   ModelicaError
                */
                MUTEX_UNLOCK();
#endif
                if (isMatExt) {
                    table = readMatTable(tableName, fileName, nRow, nCol);
                }
                else {
                    table = readTxtTable(tableName, fileName, nRow, nCol);
                }
                if (table == NULL) {
                    return table;
                }
#if defined(TABLE_SHARE)
                /* Again ask for lock and search in hash table share */
                MUTEX_LOCK();
                HASH_FIND_STR(tableShare, key, iter);
            }
            if (iter == NULL) {
                /* Share miss -> Insert new table */
                iter = malloc(sizeof(TableShare));
                if (iter != NULL) {
                    iter->key = key;
                    iter->refCount = 1;
                    iter->nRow = *nRow;
                    iter->nCol = *nCol;
                    iter->table = table;
                    HASH_ADD_KEYPTR(hh, tableShare, key, strlen(key), iter);
                }
            }
            else if (force) {
                /* Share hit -> Update table share (only if not shared
                   by multiple table objects)
                */
                if (iter->refCount == 1) {
                    free(iter->table);
                    iter->nRow = *nRow;
                    iter->nCol = *nCol;
                    iter->table = table;
                }
                else {
                    updateError = 1;
                }
            }
            else {
                /* Share hit -> Read from table share and increment table
                   reference counter
                */
                if (table != NULL) {
                    free(table);
                }
                iter->refCount++;
                table = iter->table;
                *nRow = iter->nRow;
                *nCol = iter->nCol;
            }
            MUTEX_UNLOCK();
            if (updateError == 1) {
                ModelicaFormatError("Not possible to update shared "
                    "table \"%s\" from \"%s\": File and table name "
                    "must be unique.\n", tableName, fileName);
            }
        }
#endif
    }
    return table;
}

static double* readMatTable(const char* tableName, const char* fileName,
                            size_t* _nRow, size_t* _nCol) {
    double* table = NULL;
    if (tableName != NULL && fileName != NULL && _nRow != NULL && _nCol != NULL) {
        mat_t* mat;
        matvar_t* matvar;
        matvar_t* matvarRoot;
        size_t nRow, nCol;
        int tableReadError = 0;
        char* tableNameCopy;
        char* token;

        tableNameCopy = (char*)malloc((strlen(tableName) + 1)*sizeof(char));
        if (tableNameCopy != NULL) {
            strcpy(tableNameCopy, tableName);
        }
        else {
            ModelicaError("Memory allocation error\n");
            return NULL;
        }

        mat = Mat_Open(fileName, (int)MAT_ACC_RDONLY);
        if (mat == NULL) {
            free(tableNameCopy);
            ModelicaFormatError("Not possible to open file \"%s\": "
                "No such file or directory\n", fileName);
            return NULL;
        }

        token = strtok(tableNameCopy, ".");
        matvarRoot = Mat_VarReadInfo(mat, token == NULL ? tableName : token);
        if (matvarRoot == NULL) {
            free(tableNameCopy);
            (void)Mat_Close(mat);
            ModelicaFormatError(
                "Table matrix \"%s\" not found on file \"%s\".\n", tableName,
                fileName);
            return NULL;
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
        free(tableNameCopy);

        /* Check if matvar is a matrix */
        if (matvar->rank != 2) {
            Mat_VarFree(matvarRoot);
            (void)Mat_Close(mat);
            ModelicaFormatError(
                "Table array \"%s\" has not the required rank 2.\n", tableName);
            return NULL;
        }

        /* Check if matvar is of double precision class (and thus non-sparse) */
        if (matvar->class_type != MAT_C_DOUBLE) {
            Mat_VarFree(matvarRoot);
            (void)Mat_Close(mat);
            ModelicaFormatError("Table matrix \"%s\" has not the required "
                "double precision class.\n", tableName);
            return NULL;
        }

        /* Check if matvar is purely real-valued */
        if (matvar->isComplex) {
            Mat_VarFree(matvarRoot);
            (void)Mat_Close(mat);
            ModelicaFormatError("Table matrix \"%s\" must not be complex.\n",
                tableName);
            return NULL;
        }

        table = (double*)malloc(matvar->dims[0]*matvar->dims[1]*sizeof(double));
        if (table == NULL) {
            Mat_VarFree(matvarRoot);
            (void)Mat_Close(mat);
            ModelicaError("Memory allocation error\n");
            return NULL;
        }

        nRow = matvar->dims[0];
        nCol = matvar->dims[1];
        {
            int start[2] = {0, 0};
            int stride[2] = {1, 1};
            int edge[2];
            edge[0] = (int)nRow;
            edge[1] = (int)nCol;
            tableReadError = Mat_VarReadData(mat, matvar, table, start, stride, edge);
        }

        Mat_VarFree(matvarRoot);
        (void)Mat_Close(mat);

        if (tableReadError == 0) {
            /* Array is stored column-wise -> need to transpose */
            transpose(table, nRow, nCol);
            *_nRow = nRow;
            *_nCol = nCol;
        }
        else {
            free(table);
            *_nRow = 0;
            *_nCol = 0;
            ModelicaFormatError(
                "Error when reading numeric data of matrix \"%s(%lu,%lu)\" "
                "from file \"%s\"\n", tableName, (unsigned long)nRow,
                (unsigned long)nCol, fileName);
            return NULL;
        }
    }
    return table;
}

#define DELIM_TABLE_HEADER " \t(,)\r"
#define DELIM_TABLE_NUMBER " \t,;\r"

static double* readTxtTable(const char* tableName, const char* fileName,
                            size_t* _nRow, size_t* _nCol) {
    double* table = NULL;
    if (tableName != NULL && fileName != NULL && _nRow != NULL && _nCol != NULL) {
        char* buf;
        int bufLen = LINE_BUFFER_LENGTH;
        FILE* fp;
        int foundTable = 0;
        int tableReadError;
        unsigned long nRow = 0;
        unsigned long nCol = 0;
        unsigned long lineNo = 1;
#if defined(_MSC_VER) && _MSC_VER >= 1400
        _locale_t loc;
#elif defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3)
        locale_t loc;
#else
        char* dec;
#endif

        fp = fopen(fileName, "r");
        if (fp == NULL) {
            ModelicaFormatError("Not possible to open file \"%s\": "
                "No such file or directory\n", fileName);
            return NULL;
        }

        buf = (char*)malloc(LINE_BUFFER_LENGTH*sizeof(char));
        if (buf == NULL) {
            fclose(fp);
            ModelicaError("Memory allocation error\n");
            return NULL;
        }

        /* Read file header */
        if ((tableReadError = readLine(&buf, &bufLen, fp)) != 0) {
            free(buf);
            fclose(fp);
            if (tableReadError < 0) {
                ModelicaFormatError(
                    "Error reading first line from file \"%s\": "
                    "End-Of-File reached.\n", fileName);
            }
            return NULL;
        }

        /* Expected file header format: "#1" */
        if (0 != strncmp(buf, "#1", 2)) {
            size_t len = strlen(buf);
            fclose(fp);
            if (len == 0) {
                free(buf);
                ModelicaFormatError(
                    "Error reading format and version information in first "
                    "line of file \"%s\": \"#1\" expected.\n", fileName);
            }
            else if (len == 1) {
                char c0 = buf[0];
                free(buf);
                ModelicaFormatError(
                    "Error reading format and version information in first "
                    "line of file \"%s\": \"#1\" expected, but \"%c\" found.\n",
                    fileName, c0);
            }
            else {
                char c0 = buf[0];
                char c1 = buf[1];
                free(buf);
                ModelicaFormatError(
                    "Error reading format and version information in first "
                    "line of file \"%s\": \"#1\" expected, but \"%c%c\" "
                    "found.\n", fileName, c0, c1);
            }
            return NULL;
        }

#if defined(_MSC_VER) && _MSC_VER >= 1400
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

            lineNo++;
            /* Expected table header format: "dataType tableName(nRow,nCol)" */
            token = strtok(buf, DELIM_TABLE_HEADER);
            if (token == NULL) {
                continue;
            }
            if ((0 != strcmp(token, "double")) && (0 != strcmp(token, "float"))) {
                continue;
            }
            token = strtok(NULL, DELIM_TABLE_HEADER);
            if (token == NULL) {
                continue;
            }
            if (0 == strcmp(token, tableName)) {
                foundTable = 1;
            }
            else {
                continue;
            }
            token = strtok(NULL, DELIM_TABLE_HEADER);
            if (token == NULL) {
                continue;
            }
#if defined(_MSC_VER) && _MSC_VER >= 1400
            nRow = (unsigned long)_strtol_l(token, &endptr, 10, loc);
#elif defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3)
            nRow = (unsigned long)strtol_l(token, &endptr, 10, loc);
#else
            nRow = (unsigned long)strtol(token, &endptr, 10);
#endif
            if (*endptr != 0) {
                continue;
            }
            token = strtok(NULL, DELIM_TABLE_HEADER);
            if (token == NULL) {
                continue;
            }
#if defined(_MSC_VER) && _MSC_VER >= 1400
            nCol = (unsigned long)_strtol_l(token, &endptr, 10, loc);
#elif defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3)
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
                if (table == NULL) {
                    *_nRow = 0;
                    *_nCol = 0;
                    free(buf);
                    fclose(fp);
#if defined(_MSC_VER) && _MSC_VER >= 1400
                    _free_locale(loc);
#elif defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3)
                    freelocale(loc);
#endif
                    ModelicaError("Memory allocation error\n");
                    return table;
                }

                /* Loop over rows and store table row-wise */
                while (tableReadError == 0 && i < nRow) {
                    int k = 0;

                    lineNo++;
                    if ((tableReadError = readLine(&buf, &bufLen, fp)) != 0) {
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
                    token = strtok(&buf[k], DELIM_TABLE_NUMBER);
                    while (token != NULL && i < nRow && j < nCol) {
                        if (token[0] == '#') {
                            /* Skip trailing comment line */
                            break;
                        }
#if defined(_MSC_VER) && _MSC_VER >= 1400
                        TABLE(i, j) = _strtod_l(token, &endptr, loc);
                        if (*endptr != 0) {
                            tableReadError = 1;
                        }
#elif defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3)
                        TABLE(i, j) = strtod_l(token, &endptr, loc);
                        if (*endptr != 0) {
                            tableReadError = 1;
                        }
#else
                        if (*dec == '.') {
                            TABLE(i, j) = strtod(token, &endptr);
                        }
                        else if (NULL == strchr(token, '.')) {
                            TABLE(i, j) = strtod(token, &endptr);
                        }
                        else {
                            char* token2 = (char*)malloc(
                                (strlen(token) + 1)*sizeof(char));
                            if (token2 != NULL) {
                                char* p;
                                strcpy(token2, token);
                                p = strchr(token2, '.');
                                *p = *dec;
                                TABLE(i, j) = strtod(token2, &endptr);
                                if (*endptr != 0) {
                                    tableReadError = 1;
                                }
                                free(token2);
                            }
                            else {
                                *_nRow = 0;
                                *_nCol = 0;
                                free(buf);
                                fclose(fp);
                                tableReadError = 1;
                                ModelicaError("Memory allocation error\n");
                                break;
                            }
                        }
#endif
                        if (++j == nCol) {
                            i++; /* Increment row index */
                            j = 0; /* Reset column index */
                        }
                        if (tableReadError == 0) {
                            token = strtok(NULL, DELIM_TABLE_NUMBER);
                            continue;
                        }
                        else {
                            break;
                        }
                    }
                    /* Check for trailing non-comment character */
                    if (token != NULL && token[0] != '#') {
                        /* Check for trailing number */
                        if (i == nRow) {
                            int foundExponentSign = 0;
                            int foundExponent = 0;
                            int foundDec = 0;
                            tableReadError = 2;
                            if (token[0] == '+' || token[0] == '-') {
                                k = 1;
                            }
                            else {
                                k = 0;
                            }
                            while (token[k] != '\0') {
                                if (token[k] >= '0' && token[k] <= '9') {
                                    k++;
                                }
                                else if (token[k] == '.' && foundDec == 0 &&
                                    foundExponent == 0 && foundExponentSign == 0) {
                                    foundDec = 1;
                                    k++;
                                }
                                else if ((token[k] == 'e' || token[k] == 'E') &&
                                    foundExponent == 0) {
                                    foundExponent = 1;
                                    k++;
                                }
                                else if ((token[k] == '+' || token[k] == '-') &&
                                    foundExponent == 1 && foundExponentSign == 0) {
                                    foundExponentSign = 1;
                                    k++;
                                }
                                else {
                                    tableReadError = 1;
                                    break;
                                }
                            }
                        }
                        else {
                            tableReadError = 1;
                        }
                        break;
                    }
                }
                break;
            }
        }

        free(buf);
        fclose(fp);
#if defined(_MSC_VER) && _MSC_VER >= 1400
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

        if (tableReadError == 0) {
            *_nRow = (size_t)nRow;
            *_nCol = (size_t)nCol;
        }
        else {
            free(table);
            table = NULL;
            *_nRow = 0;
            *_nCol = 0;
            if (tableReadError == EOF) {
                ModelicaFormatError(
                    "End-of-file reached when reading numeric data of matrix "
                    "\"%s(%lu,%lu)\" from file \"%s\"\n", tableName, nRow,
                    nCol, fileName);
            }
            else if (tableReadError == 2) {
                ModelicaFormatError(
                    "The table dimensions of matrix \"%s(%lu,%lu)\" from file "
                    "\"%s\" do not match the actual table size.\n", tableName,
                    nRow, nCol, fileName);
            }
            else {
                ModelicaFormatError(
                    "Error in line %lu when reading numeric data of matrix "
                    "\"%s(%lu,%lu)\" from file \"%s\"\n", lineNo, tableName,
                    nRow, nCol, fileName);
            }
        }
    }
    return table;
}

#undef DELIM_TABLE_HEADER
#undef DELIM_TABLE_NUMBER

static int readLine(char** buf, int* bufLen, FILE* fp) {
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

        oldBufLen = *bufLen;
        *bufLen *= 2;
        tmp = (char*)realloc(*buf, (size_t)*bufLen);
        if (tmp == NULL) {
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
#endif /* #if !defined(NO_FILE_SYSTEM) */

#if defined(DUMMY_FUNCTION_USERTAB)
int usertab(char* tableName, int nipo, int dim[], int* colWise,
            double** table) {
    ModelicaError("Function \"usertab\" is not implemented\n");
    return 1; /* Error */
}
#endif /* #if defined(DUMMY_FUNCTION_USERTAB) */
