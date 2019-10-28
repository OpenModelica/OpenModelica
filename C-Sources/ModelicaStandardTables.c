/* ModelicaStandardTables.c - External table functions

   Copyright (C) 2013-2019, Modelica Association and contributors
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

/* Implementation of external functions for table computation
   in the Modelica Standard Library:

      Modelica.Blocks.Sources.CombiTimeTable
      Modelica.Blocks.Tables.CombiTable1D
      Modelica.Blocks.Tables.CombiTable1Ds
      Modelica.Blocks.Tables.CombiTable2D

   Release Notes:
      Aug. 03, 2019: by Thomas Beutlich
                     Added second derivatives (ticket #2901)

      Oct. 04, 2018: by Thomas Beutlich, ESI ITI GmbH
                     Fixed event detection of CombiTimeTable (ticket #2724)
                     Fixed left extrapolation of CombiTimeTable (ticket #2724)

      Jan. 03, 2018: by Thomas Beutlich, ESI ITI GmbH
                     Improved reentrancy of CombiTimeTable (ticket #2411)

      Oct. 23, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Utilized non-fatal hash insertion, called by HASH_ADD_KEYPTR
                     in function readTable (ticket #2097)

      Aug. 25, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Added support for extrapolation in CombiTable2D (ticket #1839)

      Apr. 24, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Added functions to retrieve minimum and maximum abscissa
                     values of CombiTable2D (ticket #2244)

      Apr. 15, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Added support for time event generation (independent of
                     smoothness) in CombiTimeTable (ticket #2080)

      Apr. 11, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Revised initialization of CombiTimeTable, CombiTable1D
                     and CombiTable2D (ticket #1899)
                     - Already read table in the initialization functions

      Apr. 07, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Added support for shift time (independent of start time)
                     in CombiTimeTable (ticket #1771)

      Apr. 05, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Fixed extrapolation of CombiTimeTable if simulation start
                     time equals the maximum time of the table (ticket #2233)

      Mar. 08, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Moved file I/O functions to ModelicaIO (ticket #2192)

      Feb. 25, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Added support for extrapolation in CombiTable1D (ticket #1839)
                     Added functions to retrieve minimum and maximum abscissa
                     values of CombiTable1D (ticket #2120)

      Aug. 10, 2016: by Thomas Beutlich, ESI ITI GmbH
                     Fixed event detection of CombiTimeTable for restarted
                     simulation (ticket #2040)
                     Fixed tracing time events (DEBUG_TIME_EVENTS) of CombiTimeTable
                     for negative simulation time

      Dec. 16, 2015: by Thomas Beutlich, ITI GmbH
                     Added univariate Steffen-spline interpolation (ticket #1814)

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
                     Improved error message in case of trailing numbers when parsing
                     a line of a text file (ticket #1494)

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

#include "ModelicaStandardTables.h"
#include "ModelicaIO.h"
#include "ModelicaUtilities.h"
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
#define uthash_strlen(s) key_strlen(s)
#define HASH_NONFATAL_OOM 1
#include "uthash.h"
#include "gconstructor.h"
#endif
#include <float.h>
#include <math.h>
#include <string.h>

#if !defined(NO_FILE_SYSTEM)
/* The standard way to detect POSIX is to check _POSIX_VERSION,
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
    FRITSCH_BUTLAND_MONOTONE_C1,
    STEFFEN_MONOTONE_C1,
    AKIMA_C1 = CONTINUOUS_DERIVATIVE
};

enum Extrapolation {
    HOLD_LAST_POINT = 1,
    LAST_TWO_POINTS,
    PERIODIC,
    NO_EXTRAPOLATION
};

enum TimeEvents {
    UNDEFINED = 0,
    ALWAYS,
    AT_DISCONT,
    NO_TIMEEVENTS
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

enum CleanUp {
    NO_CLEANUP = 0,
    DO_CLEANUP
};

/* ----- Internal table memory ----- */

/* 3 (of 4) 1D cubic Hermite spline coefficients (per interval) */
typedef double CubicHermite1D[3];

/* 15 (of 16) 2D cubic Hermite spline coefficients (per grid) */
typedef double CubicHermite2D[15];

/* Left and right interval indices (per interval) */
typedef size_t Interval[2];

typedef struct CombiTimeTable {
    char* key; /* Key consisting of concatenated names of file and table */
    double* table; /* Table values */
    size_t nRow; /* Number of rows of table */
    size_t nCol; /* Number of columns of table */
    size_t last; /* Last accessed row index of table */
    enum Smoothness smoothness; /* Smoothness kind */
    enum Extrapolation extrapolation; /* Extrapolation kind */
    enum TableSource source; /* Source kind */
    enum TimeEvents timeEvents; /* Kind of time event handling */
    int* cols; /* Columns of table to be interpolated */
    size_t nCols; /* Number of columns of table to be interpolated */
    double startTime; /* Start time of inter-/extrapolation */
    double shiftTime; /* Shift time of first table column */
    CubicHermite1D* spline; /* Pre-calculated cubic Hermite spline coefficients,
        only used if smoothness is AKIMA_C1 or
        FRITSCH_BUTLAND_MONOTONE_C1 or STEFFEN_MONOTONE_C1 */
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
    char* key; /* Key consisting of concatenated names of file and table */
    double* table; /* Table values */
    size_t nRow; /* Number of rows of table */
    size_t nCol; /* Number of columns of table */
    size_t last; /* Last accessed row index of table */
    enum Smoothness smoothness; /* Smoothness kind */
    enum Extrapolation extrapolation; /* Extrapolation kind */
    enum TableSource source; /* Source kind */
    int* cols; /* Columns of table to be interpolated */
    size_t nCols; /* Number of columns of table to be interpolated */
    CubicHermite1D* spline; /* Pre-calculated cubic Hermite spline coefficients,
        only used if smoothness is AKIMA_C1 or
        FRITSCH_BUTLAND_MONOTONE_C1 or STEFFEN_MONOTONE_C1 */
} CombiTable1D;

typedef struct CombiTable2D {
    char* key; /* Key consisting of concatenated names of file and table */
    double* table; /* Table values */
    size_t nRow; /* Number of rows of table */
    size_t nCol; /* Number of columns of table */
    size_t last1; /* Last accessed row index of table */
    size_t last2; /* Last accessed column index of table */
    enum Smoothness smoothness; /* Smoothness kind */
    enum Extrapolation extrapolation; /* Extrapolation kind */
    enum TableSource source; /* Source kind */
    CubicHermite2D* spline; /* Pre-calculated cubic Hermite spline coefficients,
        only used if smoothness is AKIMA_C1 */
} CombiTable2D;

/* ----- Internal constants ----- */

#if !defined(_EPSILON)
#define _EPSILON (1e-10)
#endif
#if !defined(MAX_TABLE_DIMENSIONS)
#define MAX_TABLE_DIMENSIONS (3)
#endif

/* ----- Internal shortcuts ----- */

#define IDX(i, j, n) ((i)*(n) + (j))
#define TABLE(i, j) table[IDX(i, j, nCol)]
#define TABLE_ROW0(j) table[j]
#define TABLE_COL0(i) table[(i)*nCol]

#define LINEAR(u, u0, u1, y0, y1) \
do {\
    y = (y0) + ((y1) - (y0))*((u) - (u0))/((u1) - (u0)); \
} while(0)
/*
LINEAR(u0, ...) -> y0
LINEAR(u1, ...) -> y1
*/

#define LINEAR_SLOPE(y0, dy_du, du) \
do {\
    y = (y0) + (dy_du)*(du); \
} while(0)

#define BILINEAR(u1, u2) \
do {\
    const double u10 = TABLE_COL0(last1 + 1); \
    const double u11 = TABLE_COL0(last1 + 2); \
    const double u20 = TABLE_ROW0(last2 + 1); \
    const double u21 = TABLE_ROW0(last2 + 2); \
    const double y00 = TABLE(last1 + 1, last2 + 1); \
    const double y01 = TABLE(last1 + 1, last2 + 2); \
    const double y10 = TABLE(last1 + 2, last2 + 1); \
    const double y11 = TABLE(last1 + 2, last2 + 2); \
    const double tmp = ((u2) - u20)/(u20 - u21); \
    y = y00 + tmp*(y00 - y01) + ((u1) - u10)/(u10 - u11)* \
        ((1 + tmp)*(y00 - y10) + tmp*(y11 - y01)); \
} while(0)
/*
BILINEAR(u10, u20, ...) -> y00
BILINEAR(u10, u21, ...) -> y01
BILINEAR(u11, u20, ...) -> y10
BILINEAR(u11, u21, ...) -> y11
*/

#define BILINEAR_DER(u1, u2) \
do {\
    const double u10 = TABLE_COL0(last1 + 1); \
    const double u11 = TABLE_COL0(last1 + 2); \
    const double u20 = TABLE_ROW0(last2 + 1); \
    const double u21 = TABLE_ROW0(last2 + 2); \
    const double y00 = TABLE(last1 + 1, last2 + 1); \
    const double y01 = TABLE(last1 + 1, last2 + 2); \
    const double y10 = TABLE(last1 + 2, last2 + 1); \
    const double y11 = TABLE(last1 + 2, last2 + 2); \
    der_y = der_u1*(u21*(y10 - y00) + u20*(y01 - y11) + \
        (u2)*(y00 - y01 - y10 + y11)); \
    der_y += der_u2*(u11*(y01 - y00) + u10*(y10 - y11) + \
        (u1)*(y00 - y01 - y10 + y11)); \
    der_y /= (u10 - u11); \
    der_y /= (u20 - u21); \
} while(0)

#define BILINEAR_DER2(u1, u2) \
do {\
    const double u10 = TABLE_COL0(last1 + 1); \
    const double u11 = TABLE_COL0(last1 + 2); \
    const double u20 = TABLE_ROW0(last2 + 1); \
    const double u21 = TABLE_ROW0(last2 + 2); \
    const double y00 = TABLE(last1 + 1, last2 + 1); \
    const double y01 = TABLE(last1 + 1, last2 + 2); \
    const double y10 = TABLE(last1 + 2, last2 + 1); \
    const double y11 = TABLE(last1 + 2, last2 + 2); \
    der2_y = der2_u1*(u21*(y10 - y00) + u20*(y01 - y11) + \
        (u2)*(y00 - y01 - y10 + y11)); \
    der2_y += der2_u2*(u11*(y01 - y00) + u10*(y10 - y11) + \
        (u1)*(y00 - y01 - y10 + y11)); \
    der2_y += 2*der_u1*der_u2*(y00 - y01 - y10 + y11); \
    der2_y /= (u10 - u11); \
    der2_y /= (u20 - u21); \
} while(0)

#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
typedef struct TableShare {
    char* key; /* Key consisting of concatenated names of file and table */
    size_t refCount; /* Reference counter */
    size_t nRow; /* Number of rows of table */
    size_t nCol; /* Number of columns of table */
    double* table; /* Table values */
    UT_hash_handle hh; /* Hashable structure */
} TableShare;

/* ----- Static variables ----- */

static TableShare* tableShare = NULL;
#if defined(_POSIX_) && !defined(NO_MUTEX)
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
#include <windows.h>
static CRITICAL_SECTION cs;
#ifdef G_DEFINE_CONSTRUCTOR_NEEDS_PRAGMA
#pragma G_DEFINE_CONSTRUCTOR_PRAGMA_ARGS(ModelicaStandardTables_initializeCS)
#endif
G_DEFINE_CONSTRUCTOR(ModelicaStandardTables_initializeCS)
static void ModelicaStandardTables_initializeCS(void) {
    InitializeCriticalSection(&cs);
}
#ifdef G_DEFINE_DESTRUCTOR_NEEDS_PRAGMA
#pragma G_DEFINE_DESTRUCTOR_PRAGMA_ARGS(ModelicaStandardTables_deleteCS)
#endif
G_DEFINE_DESTRUCTOR(ModelicaStandardTables_deleteCS)
static void ModelicaStandardTables_deleteCS(void) {
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

static int isValidCombiTimeTable(CombiTimeTable* tableID,
                                 _In_z_ const char* tableName, enum CleanUp cleanUp);
  /* Check, whether a CombiTimeTable is well parameterized */

static int isValidCombiTable1D(CombiTable1D* tableID,
                               _In_z_ const char* tableName, enum CleanUp cleanUp);
  /* Check, whether a CombiTable1D is well parameterized */

static int isValidCombiTable2D(CombiTable2D* tableID,
                               _In_z_ const char* tableName, enum CleanUp cleanUp);
  /* Check, whether a CombiTable2D is well parameterized */

static enum TableSource getTableSource(_In_z_ const char* fileName,
                                       _In_z_ const char* tableName) MODELICA_NONNULLATTR;
  /* Determine table source (file, model or "usertab" function) from table
     and file names
  */

static void transpose(_Inout_ double* table, size_t nRow, size_t nCol) MODELICA_NONNULLATTR;
  /* Cycle-based in-place array transposition */

#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
static size_t key_strlen(_In_z_ const char *s);
  /* Special strlen for key consisting of concatenated names of file and table */
#endif

#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
#define READ_RESULT TableShare*
#else
#define READ_RESULT double*
#endif
static READ_RESULT readTable(_In_z_ const char* fileName, _In_z_ const char* tableName,
                             _Inout_ size_t* nRow, _Inout_ size_t* nCol, int verbose,
                             int force) MODELICA_NONNULLATTR;
  /* Read a table from a text or MATLAB MAT-file

     <- RETURN: Pointer to TableShare structure or
        pointer to array (row-wise storage) of table values
  */

static CubicHermite1D* akimaSpline1DInit(_In_ const double* table, size_t nRow,
                                         size_t nCol, _In_ const int* cols,
                                         size_t nCols) MODELICA_NONNULLATTR;
  /* Calculate the coefficients for univariate cubic Hermite spline
     interpolation with the Akima slope approximation

     <- RETURN: Pointer to array of coefficients
  */

static CubicHermite1D* fritschButlandSpline1DInit(_In_ const double* table,
                                                  size_t nRow, size_t nCol,
                                                  _In_ const int* cols,
                                                  size_t nCols) MODELICA_NONNULLATTR;
  /* Calculate the coefficients for univariate cubic Hermite spline
     interpolation with the Fritsch-Butland slope approximation

     <- RETURN: Pointer to array of coefficients
  */

static CubicHermite1D* steffenSpline1DInit(_In_ const double* table,
                                           size_t nRow, size_t nCol,
                                           _In_ const int* cols,
                                           size_t nCols) MODELICA_NONNULLATTR;
  /* Calculate the coefficients for univariate cubic Hermite spline
     interpolation with the Steffen slope approximation

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

#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"
#endif

void* ModelicaStandardTables_CombiTimeTable_init(_In_z_ const char* tableName,
                                                 _In_z_ const char* fileName,
                                                 _In_ double* table, size_t nRow,
                                                 size_t nColumn,
                                                 double startTime,
                                                 _In_ int* columns,
                                                 size_t nCols, int smoothness,
                                                 int extrapolation) {
    return ModelicaStandardTables_CombiTimeTable_init2(fileName,
        tableName, table, nRow, nColumn, startTime, columns, nCols, smoothness,
        extrapolation, startTime, ALWAYS, 1 /* verbose */);
}

void* ModelicaStandardTables_CombiTimeTable_init2(_In_z_ const char* fileName,
                                                  _In_z_ const char* tableName,
                                                  _In_ double* table, size_t nRow,
                                                  size_t nColumn,
                                                  double startTime,
                                                  _In_ int* columns,
                                                  size_t nCols, int smoothness,
                                                  int extrapolation,
                                                  double shiftTime,
                                                  int timeEvents,
                                                  int verbose) {
    CombiTimeTable* tableID;
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
    TableShare* file = NULL;
    char* keyFile = NULL;
#endif
    double* tableFile = NULL;
    size_t nRowFile = 0;
    size_t nColFile = 0;
    enum TableSource source = getTableSource(fileName, tableName);

    /* Read table from file before any other heap allocation */
    if (TABLESOURCE_FILE == source) {
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
        file = readTable(fileName, tableName, &nRowFile, &nColFile, verbose, 0);
        if (NULL != file) {
            keyFile = file->key;
            tableFile = file->table;
        }
        else {
            return NULL;
        }
#else
        tableFile = readTable(fileName, tableName, &nRowFile, &nColFile, verbose, 0);
        if (NULL == tableFile) {
            return NULL;
        }
#endif
    }

    tableID = (CombiTimeTable*)calloc(1, sizeof(CombiTimeTable));
    if (NULL == tableID) {
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
        if (NULL != file) {
            MUTEX_LOCK();
            if (--file->refCount == 0) {
                ModelicaIO_freeRealTable(file->table);
                free(file->key);
                HASH_DEL(tableShare, file);
                free(file);
            }
            MUTEX_UNLOCK();
        }
#else
        if (NULL != tableFile) {
            free(tableFile);
        }
#endif
        ModelicaError("Memory allocation error\n");
        return NULL;
    }

    tableID->smoothness = (enum Smoothness)smoothness;
    tableID->extrapolation = (enum Extrapolation)extrapolation;
    tableID->timeEvents = (enum TimeEvents)timeEvents;
    tableID->nCols = nCols;
    tableID->startTime = startTime;
    tableID->shiftTime = shiftTime;
    tableID->preNextTimeEvent = -DBL_MAX;
    tableID->preNextTimeEventCalled = -DBL_MAX;
    tableID->source = source;

    switch (tableID->source) {
        case TABLESOURCE_FILE:
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
            tableID->key = keyFile;
#else
            {
                size_t lenFileName = strlen(fileName);
                tableID->key = (char*)malloc((lenFileName + strlen(tableName) + 2)*sizeof(char));
                if (NULL != tableID->key) {
                    strcpy(tableID->key, fileName);
                    strcpy(tableID->key + lenFileName + 1, tableName);
                }
            }
#endif
            tableID->nRow = nRowFile;
            tableID->nCol = nColFile;
            tableID->table = tableFile;
            break;

        case TABLESOURCE_MODEL:
            tableID->nRow = nRow;
            tableID->nCol = nColumn;
#if defined(NO_TABLE_COPY)
            tableID->table = table;
#else
            tableID->table = (double*)malloc(nRow*nColumn*sizeof(double));
            if (NULL != tableID->table) {
                memcpy(tableID->table, table, nRow*nColumn*sizeof(double));
            }
            else {
                ModelicaStandardTables_CombiTimeTable_close(tableID);
                ModelicaError("Memory allocation error\n");
                return NULL;
            }
#endif
            break;

        case TABLESOURCE_FUNCTION: {
            int colWise;
            int dim[MAX_TABLE_DIMENSIONS];
            if (usertab((char*)tableName, 0 /* Time-interpolation */, dim,
                &colWise, &tableID->table) == 0) {
                if (0 == colWise) {
                    tableID->nRow = (size_t)dim[0];
                    tableID->nCol = (size_t)dim[1];
                }
                else {
                    /* Need to transpose */
                    double* tableT = (double*)malloc(
                        (size_t)dim[0]*(size_t)dim[1]*sizeof(double));
                    if (NULL != tableT) {
                        memcpy(tableT, tableID->table,
                            (size_t)dim[0]*(size_t)dim[1]*sizeof(double));
                        tableID->table = tableT;
                        tableID->nRow = (size_t)dim[1];
                        tableID->nCol = (size_t)dim[0];
                        tableID->source = TABLESOURCE_FUNCTION_TRANSPOSE;
                        transpose(tableID->table, tableID->nRow, tableID->nCol);
                    }
                    else {
                        ModelicaStandardTables_CombiTimeTable_close(tableID);
                        ModelicaError("Memory allocation error\n");
                        return NULL;
                    }
                }
            }
            break;
        }

        case TABLESOURCE_FUNCTION_TRANSPOSE:
            /* Should not be possible to get here */
            break;

        default:
            ModelicaStandardTables_CombiTimeTable_close(tableID);
            ModelicaError("Table source error\n");
            return NULL;
    }

    if (nCols > 0) {
        tableID->cols = (int*)malloc(tableID->nCols*sizeof(int));
        if (NULL != tableID->cols) {
            memcpy(tableID->cols, columns, tableID->nCols*sizeof(int));
        }
        else {
            ModelicaStandardTables_CombiTimeTable_close(tableID);
            ModelicaError("Memory allocation error\n");
            return NULL;
        }
    }

    if (isValidCombiTimeTable(tableID, tableName, DO_CLEANUP) == 0) {
        return NULL;
    }

    if (tableID->nRow <= 2) {
        if (tableID->smoothness == AKIMA_C1 ||
            tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1 ||
            tableID->smoothness == STEFFEN_MONOTONE_C1) {
            tableID->smoothness = LINEAR_SEGMENTS;
        }
    }
    /* Initialization of the cubic Hermite spline coefficients */
    if (tableID->smoothness == AKIMA_C1) {
        tableID->spline = akimaSpline1DInit(
            (const double*)tableID->table, tableID->nRow,
            tableID->nCol, (const int*)tableID->cols, tableID->nCols);
    }
    else if (tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1) {
        tableID->spline = fritschButlandSpline1DInit(
            (const double*)tableID->table, tableID->nRow,
            tableID->nCol, (const int*)tableID->cols, tableID->nCols);
    }
    else if (tableID->smoothness == STEFFEN_MONOTONE_C1) {
        tableID->spline = steffenSpline1DInit(
            (const double*)tableID->table, tableID->nRow,
            tableID->nCol, (const int*)tableID->cols, tableID->nCols);
    }
    if (tableID->smoothness == AKIMA_C1 ||
        tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1 ||
        tableID->smoothness == STEFFEN_MONOTONE_C1) {
        if (NULL == tableID->spline) {
            ModelicaStandardTables_CombiTimeTable_close(tableID);
            ModelicaError("Memory allocation error\n");
            return NULL;
        }
    }

    return (void*)tableID;
}

void ModelicaStandardTables_CombiTimeTable_close(void* _tableID) {
    CombiTimeTable* tableID = (CombiTimeTable*)_tableID;
    if (NULL == tableID) {
        return;
    }
    if (NULL != tableID->table && tableID->source == TABLESOURCE_FILE) {
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
        if (NULL != tableID->key) {
            TableShare* file;
            MUTEX_LOCK();
            HASH_FIND_STR(tableShare, tableID->key, file);
            if (NULL != file) {
                /* Share hit */
                if (--file->refCount == 0) {
                    ModelicaIO_freeRealTable(file->table);
                    free(file->key);
                    HASH_DEL(tableShare, file);
                    free(file);
                }
            }
            MUTEX_UNLOCK();
        }
        else {
            /* Should not be possible to get here */
            free(tableID->table);
        }
#else
        if (NULL != tableID->key) {
            free(tableID->key);
        }
        free(tableID->table);
#endif
    }
    else if (NULL != tableID->table && (
#if !defined(NO_TABLE_COPY)
        tableID->source == TABLESOURCE_MODEL ||
#endif
        tableID->source == TABLESOURCE_FUNCTION_TRANSPOSE)) {
        free(tableID->table);
    }
    if (tableID->nCols > 0 && NULL != tableID->cols) {
        free(tableID->cols);
    }
    if (NULL != tableID->intervals) {
        free(tableID->intervals);
    }
    spline1DClose(&tableID->spline);
    free(tableID);
}

double ModelicaStandardTables_CombiTimeTable_getValue(void* _tableID, int iCol,
                                                      double t, double nextTimeEvent,
                                                      double preNextTimeEvent) {
    double y = 0.;
    CombiTimeTable* tableID = (CombiTimeTable*)_tableID;
    if (NULL != tableID && NULL != tableID->table && NULL != tableID->cols &&
        t >= tableID->startTime) {
        if (nextTimeEvent < DBL_MAX && nextTimeEvent == preNextTimeEvent &&
            tableID->startTime >= nextTimeEvent) {
            /* Before start time event iteration: Return zero */
            return y;
        }
        else {
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
                const double tMin = TABLE_ROW0(0);
                const double tMax = TABLE_COL0(nRow - 1);
                size_t last;
                /* Shift time */
                const double tOld = t;
                t -= tableID->shiftTime;

                /* Periodic extrapolation */
                if (tableID->extrapolation == PERIODIC) {
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
                            do {
                                t += T;
                            } while (t < tMin);
                        }
                        else if (t > tMax) {
                            do {
                                t -= T;
                            } while (t > tMax);
                        }
                        last = findRowIndex(table, nRow, nCol, tableID->last, t);
                        tableID->last = last;
                        /* Event interval correction */
                        if (last < i0) {
                            t = TABLE_COL0(i0);
                        }
                        if (last >= i1) {
                            if (tableID->eventInterval == 1) {
                                t = TABLE_COL0(i0);
                            }
                            else {
                                t = TABLE_COL0(i1);
                            }
                        }
                    }
                }
                else if (t < tMin) {
                    extrapolate = LEFT;
                }
                else if (t >= tMax) {
                    extrapolate = RIGHT;
                    /* Event handling for non-periodic extrapolation */
                    if (nextTimeEvent == preNextTimeEvent &&
                        nextTimeEvent < DBL_MAX && tOld >= nextTimeEvent) {
                        /* Before event iteration */
                        extrapolate = IN_TABLE;
                    }
                }

                if (extrapolate == IN_TABLE) {
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
                            else if (t >= tMax) {
                                last = nRow - 1;
                            }
                            else {
                                last = findRowIndex(table, nRow, nCol,
                                    tableID->last, t);
                                tableID->last = last;
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
                        case LINEAR_SEGMENTS: {
                            const double t0 = TABLE_COL0(last);
                            const double t1 = TABLE_COL0(last + 1);
                            const double y0 = TABLE(last, col);
                            const double y1 = TABLE(last + 1, col);
                            if (isNearlyEqual(t0, t1)) {
                                y = y1;
                            }
                            else {
                                LINEAR(t, t0, t1, y0, y1);
                            }
                            break;
                        }

                        case CONSTANT_SEGMENTS:
                            if (t >= TABLE_COL0(last + 1)) {
                                last++;
                            }
                            y = TABLE(last, col);
                            break;

                        case AKIMA_C1:
                        case FRITSCH_BUTLAND_MONOTONE_C1:
                        case STEFFEN_MONOTONE_C1:
                            if (NULL != tableID->spline) {
                                const double* c = tableID->spline[
                                    IDX(last, (size_t)(iCol - 1), tableID->nCols)];
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
                        case LAST_TWO_POINTS:
                            last = (extrapolate == RIGHT) ? nRow - 2 : 0;
                            switch(tableID->smoothness) {
                                case LINEAR_SEGMENTS:
                                case CONSTANT_SEGMENTS: {
                                    const double t0 = TABLE_COL0(last);
                                    const double t1 = TABLE_COL0(last + 1);
                                    const double y0 = TABLE(last, col);
                                    const double y1 = TABLE(last + 1, col);
                                    if (isNearlyEqual(t0, t1)) {
                                        y = (extrapolate == RIGHT) ? y1 : y0;
                                    }
                                    else {
                                        LINEAR(t, t0, t1, y0, y1);
                                    }
                                    break;
                                }

                                case AKIMA_C1:
                                case FRITSCH_BUTLAND_MONOTONE_C1:
                                case STEFFEN_MONOTONE_C1:
                                    if (NULL != tableID->spline) {
                                        const double* c = tableID->spline[
                                            IDX(last, (size_t)(iCol - 1), tableID->nCols)];
                                        if (extrapolate == LEFT) {
                                            LINEAR_SLOPE(TABLE(0, col), c[2], t - tMin);
                                        }
                                        else /* if (extrapolate == RIGHT) */ {
                                            const double v = tMax - TABLE_COL0(nRow - 2);
                                            LINEAR_SLOPE(TABLE(last + 1, col),
                                                (3*c[0]*v + 2*c[1])*v + c[2], t - tMax);
                                        }
                                    }
                                    break;

                                default:
                                    ModelicaError("Unknown smoothness kind\n");
                                    return y;
                            }
                            break;

                        case HOLD_LAST_POINT:
                            y = (extrapolate == RIGHT) ? TABLE(nRow - 1, col) :
                                TABLE_ROW0(col);
                            break;

                        case NO_EXTRAPOLATION:
                            ModelicaFormatError("Extrapolation error: Time "
                                "(=%lf) must be %s or equal\nthan the %s abscissa "
                                "value %s (=%lf) defined in the table.\n", tOld,
                                (extrapolate == LEFT) ? "greater" : "less",
                                (extrapolate == LEFT) ? "minimum" : "maximum",
                                (extrapolate == LEFT) ? "t_min" : "t_max",
                                (extrapolate == LEFT) ? tMin : tMax);
                            return y;

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
    if (NULL != tableID && NULL != tableID->table && NULL != tableID->cols &&
        t >= tableID->startTime) {
        if (nextTimeEvent < DBL_MAX && nextTimeEvent == preNextTimeEvent &&
            tableID->startTime >= nextTimeEvent) {
            /* Before start time event iteration: Return zero */
            return der_y;
        }
        else {
            const double* table = tableID->table;
            const size_t nRow = tableID->nRow;
            const size_t nCol = tableID->nCol;
            const size_t col = (size_t)tableID->cols[iCol - 1] - 1;

            if (nRow > 1) {
                enum PointInterval extrapolate = IN_TABLE;
                const double tMin = TABLE_ROW0(0);
                const double tMax = TABLE_COL0(nRow - 1);
                size_t last = 0;
                int haveLast = 0;
                /* Shift time */
                const double tOld = t;
                t -= tableID->shiftTime;

                /* Periodic extrapolation */
                if (tableID->extrapolation == PERIODIC) {
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
                            do {
                                t += T;
                            } while (t < tMin);
                        }
                        else if (t > tMax) {
                            do {
                                t -= T;
                            } while (t > tMax);
                        }
                        last = findRowIndex(
                            table, nRow, nCol, tableID->last, t);
                        tableID->last = last;
                        /* Event interval correction */
                        if (last < i0) {
                            t = TABLE_COL0(i0);
                        }
                        if (last >= i1) {
                            if (tableID->eventInterval == 1) {
                                t = TABLE_COL0(i0);
                            }
                            else {
                                t = TABLE_COL0(i1);
                            }
                        }
                    }
                }
                else if (t < tMin) {
                    extrapolate = LEFT;
                }
                else if (t >= tMax) {
                    extrapolate = RIGHT;
                    /* Event handling for non-periodic extrapolation */
                    if (nextTimeEvent == preNextTimeEvent &&
                        nextTimeEvent < DBL_MAX && tOld >= nextTimeEvent) {
                        /* Before event iteration */
                        extrapolate = IN_TABLE;
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
                            else if (t >= tMax) {
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

                        case CONSTANT_SEGMENTS:
                            break;

                        case AKIMA_C1:
                        case FRITSCH_BUTLAND_MONOTONE_C1:
                        case STEFFEN_MONOTONE_C1:
                            if (NULL != tableID->spline) {
                                const double* c = tableID->spline[
                                    IDX(last, (size_t)(iCol - 1), tableID->nCols)];
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
                        case LAST_TWO_POINTS:
                            last = (extrapolate == RIGHT) ? nRow - 2 : 0;
                            switch(tableID->smoothness) {
                                case LINEAR_SEGMENTS:
                                case CONSTANT_SEGMENTS: {
                                    const double t0 = TABLE_COL0(last);
                                    const double t1 = TABLE_COL0(last + 1);
                                    if (!isNearlyEqual(t0, t1)) {
                                        der_y = (TABLE(last + 1, col) - TABLE(last, col))/
                                            (t1 - t0);
                                    }
                                    break;
                                }

                                case AKIMA_C1:
                                case FRITSCH_BUTLAND_MONOTONE_C1:
                                case STEFFEN_MONOTONE_C1:
                                    if (NULL != tableID->spline) {
                                        const double* c = tableID->spline[
                                            IDX(last, (size_t)(iCol - 1), tableID->nCols)];
                                        if (extrapolate == LEFT) {
                                            der_y = c[2];
                                        }
                                        else /* if (extrapolate == RIGHT) */ {
                                            der_y = tMax - TABLE_COL0(nRow - 2);
                                            der_y = (3*c[0]*der_y + 2*c[1])*
                                                der_y + c[2];
                                        }
                                    }
                                    break;

                                default:
                                    ModelicaError("Unknown smoothness kind\n");
                                    return der_y;
                            }
                            der_y *= der_t;
                            break;

                        case HOLD_LAST_POINT:
                            break;

                        case NO_EXTRAPOLATION:
                            ModelicaFormatError("Extrapolation error: Time "
                                "(=%lf) must be %s or equal\nthan the %s abscissa "
                                "value %s (=%lf) defined in the table.\n", tOld,
                                (extrapolate == LEFT) ? "greater" : "less",
                                (extrapolate == LEFT) ? "minimum" : "maximum",
                                (extrapolate == LEFT) ? "t_min" : "t_max",
                                (extrapolate == LEFT) ? tMin : tMax);
                            return der_y;

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

double ModelicaStandardTables_CombiTimeTable_getDer2Value(void* _tableID, int iCol,
                                                         double t,
                                                         double nextTimeEvent,
                                                         double preNextTimeEvent,
                                                         double der_t,
                                                         double der2_t) {
    double der2_y = 0.;
    CombiTimeTable* tableID = (CombiTimeTable*)_tableID;
    if (NULL != tableID && NULL != tableID->table && NULL != tableID->cols &&
        t >= tableID->startTime) {
        if (nextTimeEvent < DBL_MAX && nextTimeEvent == preNextTimeEvent &&
            tableID->startTime >= nextTimeEvent) {
            /* Before start time event iteration: Return zero */
            return der2_y;
        }
        else {
            const double* table = tableID->table;
            const size_t nRow = tableID->nRow;
            const size_t nCol = tableID->nCol;
            const size_t col = (size_t)tableID->cols[iCol - 1] - 1;

            if (nRow > 1) {
                enum PointInterval extrapolate = IN_TABLE;
                const double tMin = TABLE_ROW0(0);
                const double tMax = TABLE_COL0(nRow - 1);
                size_t last = 0;
                int haveLast = 0;
                /* Shift time */
                const double tOld = t;
                t -= tableID->shiftTime;

                /* Periodic extrapolation */
                if (tableID->extrapolation == PERIODIC) {
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
                            do {
                                t += T;
                            } while (t < tMin);
                        }
                        else if (t > tMax) {
                            do {
                                t -= T;
                            } while (t > tMax);
                        }
                        last = findRowIndex(
                            table, nRow, nCol, tableID->last, t);
                        tableID->last = last;
                        /* Event interval correction */
                        if (last < i0) {
                            t = TABLE_COL0(i0);
                        }
                        if (last >= i1) {
                            if (tableID->eventInterval == 1) {
                                t = TABLE_COL0(i0);
                            }
                            else {
                                t = TABLE_COL0(i1);
                            }
                        }
                    }
                }
                else if (t < tMin) {
                    extrapolate = LEFT;
                }
                else if (t >= tMax) {
                    extrapolate = RIGHT;
                    /* Event handling for non-periodic extrapolation */
                    if (nextTimeEvent == preNextTimeEvent &&
                        nextTimeEvent < DBL_MAX && tOld >= nextTimeEvent) {
                        /* Before event iteration */
                        extrapolate = IN_TABLE;
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
                            else if (t >= tMax) {
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
                        case LINEAR_SEGMENTS: {
                            const double t0 = TABLE_COL0(last);
                            const double t1 = TABLE_COL0(last + 1);
                            if (!isNearlyEqual(t0, t1)) {
                                der2_y = (TABLE(last + 1, col) - TABLE(last, col))/
                                    (t1 - t0);
                                der2_y *= der2_t;
                            }
                            break;
                        }

                        case CONSTANT_SEGMENTS:
                            break;

                        case AKIMA_C1:
                        case FRITSCH_BUTLAND_MONOTONE_C1:
                        case STEFFEN_MONOTONE_C1:
                            if (NULL != tableID->spline) {
                                const double* c = tableID->spline[
                                    IDX(last, (size_t)(iCol - 1), tableID->nCols)];
                                t -= TABLE_COL0(last);
                                der2_y = (3*c[0]*t + 2*c[1])*t + c[2];
                                der2_y *= der2_t;
                                der2_y += (6*c[0]*t + 2*c[1])*der_t*der_t;
                            }
                            break;

                        default:
                            ModelicaError("Unknown smoothness kind\n");
                            return der2_y;
                    }
                }
                else {
                    /* Extrapolation */
                    switch (tableID->extrapolation) {
                        case LAST_TWO_POINTS:
                            last = (extrapolate == RIGHT) ? nRow - 2 : 0;
                            switch(tableID->smoothness) {
                                case LINEAR_SEGMENTS:
                                case CONSTANT_SEGMENTS: {
                                    const double t0 = TABLE_COL0(last);
                                    const double t1 = TABLE_COL0(last + 1);
                                    if (!isNearlyEqual(t0, t1)) {
                                        der2_y = (TABLE(last + 1, col) - TABLE(last, col))/
                                            (t1 - t0);
                                    }
                                    break;
                                }

                                case AKIMA_C1:
                                case FRITSCH_BUTLAND_MONOTONE_C1:
                                case STEFFEN_MONOTONE_C1:
                                    if (NULL != tableID->spline) {
                                        const double* c = tableID->spline[
                                            IDX(last, (size_t)(iCol - 1), tableID->nCols)];
                                        if (extrapolate == LEFT) {
                                            der2_y = c[2];
                                        }
                                        else /* if (extrapolate == RIGHT) */ {
                                            der2_y = tMax - TABLE_COL0(nRow - 2);
                                            der2_y = (3*c[0]*der2_y + 2*c[1])*
                                                der2_y + c[2];
                                        }
                                    }
                                    break;

                                default:
                                    ModelicaError("Unknown smoothness kind\n");
                                    return der2_y;
                            }
                            der2_y *= der2_t;
                            break;

                        case HOLD_LAST_POINT:
                            break;

                        case NO_EXTRAPOLATION:
                            ModelicaFormatError("Extrapolation error: Time "
                                "(=%lf) must be %s or equal\nthan the %s abscissa "
                                "value %s (=%lf) defined in the table.\n", tOld,
                                (extrapolate == LEFT) ? "greater" : "less",
                                (extrapolate == LEFT) ? "minimum" : "maximum",
                                (extrapolate == LEFT) ? "t_min" : "t_max",
                                (extrapolate == LEFT) ? tMin : tMax);
                            return der2_y;

                        case PERIODIC:
                            /* Should not be possible to get here */
                            break;

                        default:
                            ModelicaError("Unknown extrapolation kind\n");
                            return der2_y;
                    }
                }
            }
        }
    }
    return der2_y;
}

double ModelicaStandardTables_CombiTimeTable_minimumTime(void* _tableID) {
    double tMin = 0.;
    CombiTimeTable* tableID = (CombiTimeTable*)_tableID;
    if (NULL != tableID && NULL != tableID->table) {
        const double* table = tableID->table;
        tMin = TABLE_ROW0(0);
    }
    return tMin;
}

double ModelicaStandardTables_CombiTimeTable_maximumTime(void* _tableID) {
    double tMax = 0.;
    CombiTimeTable* tableID = (CombiTimeTable*)_tableID;
    if (NULL != tableID && NULL != tableID->table) {
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
    if (NULL != tableID && NULL != tableID->table) {
        const double* table = tableID->table;
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;

        if (tableID->nEvent > 0) {
            if (t > tableID->preNextTimeEventCalled) {
                /* Intentionally empty */
            }
            else if (t < tableID->preNextTimeEventCalled) {
                /* Force reinitialization of event interval */
                tableID->eventInterval = 0;
                /* Reset time event counter */
                tableID->nEvent = 0;
                /* Reset time event */
                tableID->preNextTimeEvent = -DBL_MAX;
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
            if (tableID->timeEvents == ALWAYS ||
                tableID->timeEvents == AT_DISCONT) {
                for (i = 0; i < nRow - 1; i++) {
                    double t0 = TABLE_COL0(i);
                    double t1 = TABLE_COL0(i + 1);
                    if (t1 > tEvent && !isNearlyEqual(t1, tMax)) {
                        int isEq = isNearlyEqual(t0, t1);
                        if ((tableID->timeEvents == ALWAYS && !isEq) ||
                            (tableID->timeEvents == AT_DISCONT && isEq)) {
                            tEvent = t1;
                            tableID->maxEvents++;
                        }
                    }
                }
            }
            /* Once again with storage of indices of event intervals */
            tableID->intervals = (Interval*)calloc(tableID->maxEvents,
                sizeof(Interval));
            if (NULL == tableID->intervals) {
                ModelicaError("Memory allocation error\n");
                return nextTimeEvent;
            }

            tEvent = TABLE_ROW0(0);
            eventInterval = 0;
            if (tableID->timeEvents == ALWAYS ||
                tableID->timeEvents == AT_DISCONT) {
                for (i = 0; i < nRow - 1 &&
                    eventInterval < tableID->maxEvents; i++) {
                    double t0 = TABLE_COL0(i);
                    double t1 = TABLE_COL0(i + 1);
                    if (tableID->timeEvents == ALWAYS) {
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
                    else /* if (tableID->timeEvents == AT_DISCONT) */ {
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
            else {
                tableID->intervals[0][1] = nRow - 1;
            }
        }

        tableID->preNextTimeEventCalled = t;
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
                size_t iStart, iEnd;

                t -= tableID->shiftTime;
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
                else if (t >= tMax) {
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
                else if (tableID->smoothness == AKIMA_C1 ||
                    tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1 ||
                    tableID->smoothness == STEFFEN_MONOTONE_C1) {
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

                if (tableID->timeEvents == ALWAYS ||
                    tableID->timeEvents == AT_DISCONT) {
                    size_t i;
                    for (i = iStart + 1; i < nRow - 1; i++) {
                        double t0 = TABLE_COL0(i);
                        if (t0 > t) {
                            double t1 = TABLE_COL0(i + 1);
                            int isEq = isNearlyEqual(t0, t1);
                            if ((tableID->timeEvents == ALWAYS && !isEq) ||
                                (tableID->timeEvents == AT_DISCONT && isEq)) {
                                nextTimeEvent = t0;
                                break;
                            }
                        }
                    }

                    for (i = 0; i < iEnd; i++) {
                        double t0 = TABLE_COL0(i);
                        double t1 = TABLE_COL0(i + 1);
                        if (t1 > tEvent && !isNearlyEqual(t1, tMax)) {
                            int isEq = isNearlyEqual(t0, t1);
                            if ((tableID->timeEvents == ALWAYS && !isEq) ||
                                (tableID->timeEvents == AT_DISCONT && isEq)) {
                                tEvent = t1;
                                tableID->eventInterval++;
                            }
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
                    nextTimeEvent += tableID->shiftTime;
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
                                tableID->shiftTime;
                            tableID->tOffset += T;
                        }
                        else {
                            size_t i = tableID->intervals[
                                tableID->eventInterval - 1][1];
                            nextTimeEvent = TABLE_COL0(i) + tableID->tOffset +
                                tableID->shiftTime;
                        }
                    }
                    else if (tableID->eventInterval <= tableID->maxEvents) {
                        size_t i = tableID->intervals[
                            tableID->eventInterval - 1][1];
                        nextTimeEvent = TABLE_COL0(i) + tableID->shiftTime;
                        /* Increment event interval */
                        tableID->eventInterval++;
                    }
                    else {
                        nextTimeEvent = DBL_MAX;
                    }
                } while (nextTimeEvent <= t);
            }
        }

        if (nextTimeEvent > tableID->preNextTimeEvent) {
            tableID->preNextTimeEvent = nextTimeEvent;
            tableID->nEvent++;
        }

#if defined(DEBUG_TIME_EVENTS)
        if (nextTimeEvent < DBL_MAX) {
            if (tableID->extrapolation == PERIODIC) {
                ModelicaFormatMessage("At time %.17lg (interval %lu of %lu): %lu. "
                    "time event at %.17lg\n", t, (unsigned long)tableID->eventInterval,
                    (unsigned long)tableID->maxEvents, (unsigned long)tableID->nEvent,
                    nextTimeEvent);
            }
            else if (tableID->eventInterval > 0) {
                ModelicaFormatMessage("At time %.17lg (interval %lu of %lu): %lu. "
                    "time event at %.17lg\n", t, (unsigned long)tableID->eventInterval - 1,
                    (unsigned long)tableID->maxEvents, (unsigned long)tableID->nEvent,
                    nextTimeEvent);
            }
            else {
                ModelicaFormatMessage("At time %.17lg: %lu. "
                    "time event at %.17lg\n", t, (unsigned long)tableID->nEvent,
                    nextTimeEvent);
            }
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
    if (NULL != tableID && tableID->source == TABLESOURCE_FILE) {
        if (force || NULL == tableID->table) {
            const char* fileName = tableID->key;
            const char* tableName = tableID->key + strlen(fileName) + 1;
#if defined(TABLE_SHARE)
            TableShare* file = readTable(fileName, tableName, &tableID->nRow,
                &tableID->nCol, verbose, force);
            if (NULL != file) {
                tableID->table = file->table;
            }
            else {
                return 0.; /* Error */
            }
#else
            if (NULL != tableID->table) {
                free(tableID->table);
            }
            tableID->table = readTable(fileName, tableName, &tableID->nRow,
                &tableID->nCol, verbose, force);
#endif
            if (NULL == tableID->table) {
                return 0.; /* Error */
            }
            if (isValidCombiTimeTable(tableID, tableName, NO_CLEANUP) == 0) {
                return 0.; /* Error */
            }
            if (tableID->nRow <= 2) {
                if (tableID->smoothness == AKIMA_C1 ||
                    tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1 ||
                    tableID->smoothness == STEFFEN_MONOTONE_C1) {
                    tableID->smoothness = LINEAR_SEGMENTS;
                }
            }
            /* Reinitialization of the cubic Hermite spline coefficients */
            if (tableID->smoothness == AKIMA_C1) {
                spline1DClose(&tableID->spline);
                tableID->spline = akimaSpline1DInit(
                    (const double*)tableID->table, tableID->nRow,
                    tableID->nCol, (const int*)tableID->cols, tableID->nCols);
            }
            else if (tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1) {
                spline1DClose(&tableID->spline);
                tableID->spline = fritschButlandSpline1DInit(
                    (const double*)tableID->table, tableID->nRow,
                    tableID->nCol, (const int*)tableID->cols, tableID->nCols);
            }
            else if (tableID->smoothness == STEFFEN_MONOTONE_C1) {
                spline1DClose(&tableID->spline);
                tableID->spline = steffenSpline1DInit(
                    (const double*)tableID->table, tableID->nRow,
                    tableID->nCol, (const int*)tableID->cols, tableID->nCols);
            }
            if (tableID->smoothness == AKIMA_C1 ||
                tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1 ||
                tableID->smoothness == STEFFEN_MONOTONE_C1) {
                if (NULL == tableID->spline) {
                    ModelicaError("Memory allocation error\n");
                    return 0.; /* Error */
                }
            }
        }
    }
#endif
    return 1.; /* Success */
}

void* ModelicaStandardTables_CombiTable1D_init(_In_z_ const char* tableName,
                                               _In_z_ const char* fileName,
                                               _In_ double* table, size_t nRow,
                                               size_t nColumn,
                                               _In_ int* columns,
                                               size_t nCols, int smoothness) {
    return ModelicaStandardTables_CombiTable1D_init2(fileName, tableName,
        table, nRow, nColumn, columns, nCols, smoothness, LAST_TWO_POINTS,
        1 /* verbose */);
}

void* ModelicaStandardTables_CombiTable1D_init2(_In_z_ const char* fileName,
                                                _In_z_ const char* tableName,
                                                _In_ double* table, size_t nRow,
                                                size_t nColumn,
                                                _In_ int* columns,
                                                size_t nCols, int smoothness,
                                                int extrapolation,
                                                int verbose) {
    CombiTable1D* tableID;
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
    TableShare* file = NULL;
    char* keyFile = NULL;
#endif
    double* tableFile = NULL;
    size_t nRowFile = 0;
    size_t nColFile = 0;
    enum TableSource source = getTableSource(fileName, tableName);

    /* Read table from file before any other heap allocation */
    if (TABLESOURCE_FILE == source) {
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
        file = readTable(fileName, tableName, &nRowFile, &nColFile, verbose, 0);
        if (NULL != file) {
            keyFile = file->key;
            tableFile = file->table;
        }
        else {
            return NULL;
        }
#else
        tableFile = readTable(fileName, tableName, &nRowFile, &nColFile, verbose, 0);
        if (NULL == tableFile) {
            return NULL;
        }
#endif
    }

    tableID = (CombiTable1D*)calloc(1, sizeof(CombiTable1D));
    if (NULL == tableID) {
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
        if (NULL != file) {
            MUTEX_LOCK();
            if (--file->refCount == 0) {
                ModelicaIO_freeRealTable(file->table);
                free(file->key);
                HASH_DEL(tableShare, file);
                free(file);
            }
            MUTEX_UNLOCK();
        }
#else
        if (NULL != tableFile) {
            free(tableFile);
        }
#endif
        ModelicaError("Memory allocation error\n");
        return NULL;
    }

    tableID->smoothness = (enum Smoothness)smoothness;
    tableID->extrapolation = (enum Extrapolation)extrapolation;
    tableID->nCols = nCols;
    tableID->source = source;

    switch (tableID->source) {
        case TABLESOURCE_FILE:
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
            tableID->key = keyFile;
#else
            {
                size_t lenFileName = strlen(fileName);
                tableID->key = (char*)malloc((lenFileName + strlen(tableName) + 2)*sizeof(char));
                if (NULL != tableID->key) {
                    strcpy(tableID->key, fileName);
                    strcpy(tableID->key + lenFileName + 1, tableName);
                }
            }
#endif
            tableID->nRow = nRowFile;
            tableID->nCol = nColFile;
            tableID->table = tableFile;
            break;

        case TABLESOURCE_MODEL:
            tableID->nRow = nRow;
            tableID->nCol = nColumn;
#if defined(NO_TABLE_COPY)
            tableID->table = table;
#else
            tableID->table = (double*)malloc(nRow*nColumn*sizeof(double));
            if (NULL != tableID->table) {
                memcpy(tableID->table, table, nRow*nColumn*sizeof(double));
            }
            else {
                ModelicaStandardTables_CombiTable1D_close(tableID);
                ModelicaError("Memory allocation error\n");
                return NULL;
            }
#endif
            break;

        case TABLESOURCE_FUNCTION: {
            int colWise;
            int dim[MAX_TABLE_DIMENSIONS];
            if (usertab((char*)tableName, 1 /* 1D-interpolation */, dim,
                &colWise, &tableID->table) == 0) {
                if (0 == colWise) {
                    tableID->nRow = (size_t)dim[0];
                    tableID->nCol = (size_t)dim[1];
                }
                else {
                    /* Need to transpose */
                    double* tableT = (double*)malloc(
                        (size_t)dim[0]*(size_t)dim[1]*sizeof(double));
                    if (NULL != tableT) {
                        memcpy(tableT, tableID->table,
                            (size_t)dim[0]*(size_t)dim[1]*sizeof(double));
                        tableID->table = tableT;
                        tableID->nRow = (size_t)dim[1];
                        tableID->nCol = (size_t)dim[0];
                        tableID->source = TABLESOURCE_FUNCTION_TRANSPOSE;
                        transpose(tableID->table, tableID->nRow, tableID->nCol);
                    }
                    else {
                        ModelicaStandardTables_CombiTable1D_close(tableID);
                        ModelicaError("Memory allocation error\n");
                        return NULL;
                    }
                }
            }
            break;
        }

        case TABLESOURCE_FUNCTION_TRANSPOSE:
            /* Should not be possible to get here */
            break;

        default:
            ModelicaStandardTables_CombiTable1D_close(tableID);
            ModelicaError("Table source error\n");
            return NULL;
    }

    if (nCols > 0) {
        tableID->cols = (int*)malloc(tableID->nCols*sizeof(int));
        if (NULL != tableID->cols) {
            memcpy(tableID->cols, columns, tableID->nCols*sizeof(int));
        }
        else {
            ModelicaStandardTables_CombiTable1D_close(tableID);
            ModelicaError("Memory allocation error\n");
            return NULL;
        }
    }

    if (isValidCombiTable1D(tableID, tableName, DO_CLEANUP) == 0) {
        return NULL;
    }

    if (tableID->nRow <= 2) {
        if (tableID->smoothness == AKIMA_C1 ||
            tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1 ||
            tableID->smoothness == STEFFEN_MONOTONE_C1) {
            tableID->smoothness = LINEAR_SEGMENTS;
        }
    }
    /* Initialization of the cubic Hermite spline coefficients */
    if (tableID->smoothness == AKIMA_C1) {
        tableID->spline = akimaSpline1DInit(
            (const double*)tableID->table, tableID->nRow,
            tableID->nCol, (const int*)tableID->cols, tableID->nCols);
    }
    else if (tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1) {
        tableID->spline = fritschButlandSpline1DInit(
            (const double*)tableID->table, tableID->nRow,
            tableID->nCol, (const int*)tableID->cols, tableID->nCols);
    }
    else if (tableID->smoothness == STEFFEN_MONOTONE_C1) {
        tableID->spline = steffenSpline1DInit(
            (const double*)tableID->table, tableID->nRow,
            tableID->nCol, (const int*)tableID->cols, tableID->nCols);
    }
    if (tableID->smoothness == AKIMA_C1 ||
        tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1 ||
        tableID->smoothness == STEFFEN_MONOTONE_C1) {
        if (NULL == tableID->spline) {
            ModelicaStandardTables_CombiTable1D_close(tableID);
            ModelicaError("Memory allocation error\n");
            return NULL;
        }
    }

    return (void*)tableID;
}

void ModelicaStandardTables_CombiTable1D_close(void* _tableID) {
    CombiTable1D* tableID = (CombiTable1D*)_tableID;
    if (NULL == tableID) {
        return;
    }
    if (NULL != tableID->table && tableID->source == TABLESOURCE_FILE) {
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
        if (NULL != tableID->key) {
            TableShare* file;
            MUTEX_LOCK();
            HASH_FIND_STR(tableShare, tableID->key, file);
            if (NULL != file) {
                /* Share hit */
                if (--file->refCount == 0) {
                    ModelicaIO_freeRealTable(file->table);
                    free(file->key);
                    HASH_DEL(tableShare, file);
                    free(file);
                }
            }
            MUTEX_UNLOCK();
        }
        else {
            /* Should not be possible to get here */
            free(tableID->table);
        }
#else
        if (NULL != tableID->key) {
            free(tableID->key);
        }
        free(tableID->table);
#endif
    }
    else if (NULL != tableID->table && (
#if !defined(NO_TABLE_COPY)
        tableID->source == TABLESOURCE_MODEL ||
#endif
        tableID->source == TABLESOURCE_FUNCTION_TRANSPOSE)) {
        free(tableID->table);
    }
    if (tableID->nCols > 0 && NULL != tableID->cols) {
        free(tableID->cols);
    }
    spline1DClose(&tableID->spline);
    free(tableID);
}

double ModelicaStandardTables_CombiTable1D_getValue(void* _tableID, int iCol,
                                                    double u) {
    double y = 0.;
    CombiTable1D* tableID = (CombiTable1D*)_tableID;
    if (NULL != tableID && NULL != tableID->table && NULL != tableID->cols) {
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
            const double uMin = TABLE_ROW0(0);
            const double uMax = TABLE_COL0(nRow - 1);
            size_t last;

            /* Periodic extrapolation */
            if (tableID->extrapolation == PERIODIC) {
                const double T = uMax - uMin;

                if (u < uMin) {
                    do {
                        u += T;
                    } while (u < uMin);
                }
                else if (u > uMax) {
                    do {
                        u -= T;
                    } while (u > uMax);
                }
                last = findRowIndex(table, nRow, nCol, tableID->last, u);
                tableID->last = last;
            }
            else if (u < uMin) {
                extrapolate = LEFT;
                last = 0;
            }
            else if (u > uMax) {
                extrapolate = RIGHT;
                last = nRow - 2;
            }
            else {
                last = findRowIndex(table, nRow, nCol, tableID->last, u);
                tableID->last = last;
            }

            if (extrapolate == IN_TABLE) {
                switch (tableID->smoothness) {
                    case LINEAR_SEGMENTS: {
                        const double u0 = TABLE_COL0(last);
                        const double u1 = TABLE_COL0(last + 1);
                        const double y0 = TABLE(last, col);
                        const double y1 = TABLE(last + 1, col);
                        LINEAR(u, u0, u1, y0, y1);
                        break;
                    }

                    case CONSTANT_SEGMENTS:
                        if (u >= TABLE_COL0(last + 1)) {
                            last++;
                        }
                        y = TABLE(last, col);
                        break;

                    case AKIMA_C1:
                    case FRITSCH_BUTLAND_MONOTONE_C1:
                    case STEFFEN_MONOTONE_C1:
                        if (NULL != tableID->spline) {
                            const double* c = tableID->spline[
                                IDX(last, (size_t)(iCol - 1), tableID->nCols)];
                            const double v = u - TABLE_COL0(last);
                            y = TABLE(last, col); /* c[3] = y0 */
                            y += ((c[0]*v + c[1])*v + c[2])*v;
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
                    case LAST_TWO_POINTS:
                        switch (tableID->smoothness) {
                            case LINEAR_SEGMENTS:
                            case CONSTANT_SEGMENTS: {
                                const double u0 = TABLE_COL0(last);
                                const double u1 = TABLE_COL0(last + 1);
                                const double y0 = TABLE(last, col);
                                const double y1 = TABLE(last + 1, col);
                                LINEAR(u, u0, u1, y0, y1);
                                break;
                            }

                            case AKIMA_C1:
                            case FRITSCH_BUTLAND_MONOTONE_C1:
                            case STEFFEN_MONOTONE_C1:
                                if (NULL != tableID->spline) {
                                    const double* c = tableID->spline[
                                        IDX(last, (size_t)(iCol - 1), tableID->nCols)];
                                    if (extrapolate == LEFT) {
                                        LINEAR_SLOPE(TABLE(0, col), c[2], u - uMin);
                                    }
                                    else /* if (extrapolate == RIGHT) */ {
                                        const double v = uMax - TABLE_COL0(nRow - 2);
                                        LINEAR_SLOPE(TABLE(nRow - 1, col),
                                            (3*c[0]*v + 2*c[1])*v + c[2], u - uMax);
                                    }
                                }
                                break;

                            default:
                                ModelicaError("Unknown smoothness kind\n");
                                return y;
                        }
                        break;

                    case HOLD_LAST_POINT:
                        y = (extrapolate == RIGHT) ? TABLE(nRow - 1, col) :
                            TABLE_ROW0(col);
                        break;

                    case NO_EXTRAPOLATION:
                        ModelicaFormatError("Extrapolation error: The value u "
                            "(=%lf) must be %s or equal\nthan the %s abscissa "
                            "value %s (=%lf) defined in the table.\n", u,
                            (extrapolate == LEFT) ? "greater" : "less",
                            (extrapolate == LEFT) ? "minimum" : "maximum",
                            (extrapolate == LEFT) ? "u_min" : "u_max",
                            (extrapolate == LEFT) ? uMin : uMax);
                        return y;

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
    return y;
}

double ModelicaStandardTables_CombiTable1D_getDerValue(void* _tableID, int iCol,
                                                       double u, double der_u) {
    double der_y = 0.;
    CombiTable1D* tableID = (CombiTable1D*)_tableID;
    if (NULL != tableID && NULL != tableID->table && NULL != tableID->cols) {
        const double* table = tableID->table;
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        const size_t col = (size_t)tableID->cols[iCol - 1] - 1;

        if (nRow > 1) {
            enum PointInterval extrapolate = IN_TABLE;
            const double uMin = TABLE_ROW0(0);
            const double uMax = TABLE_COL0(nRow - 1);
            size_t last;

            /* Periodic extrapolation */
            if (tableID->extrapolation == PERIODIC) {
                const double T = uMax - uMin;

                if (u < uMin) {
                    do {
                        u += T;
                    } while (u < uMin);
                }
                else if (u > uMax) {
                    do {
                        u -= T;
                    } while (u > uMax);
                }
                last = findRowIndex(table, nRow, nCol, tableID->last, u);
                tableID->last = last;
            }
            else if (u < uMin) {
                extrapolate = LEFT;
                last = 0;
            }
            else if (u > uMax) {
                extrapolate = RIGHT;
                last = nRow - 2;
            }
            else {
                last = findRowIndex(table, nRow, nCol, tableID->last, u);
                tableID->last = last;
            }

            if (extrapolate == IN_TABLE) {
                switch (tableID->smoothness) {
                    case LINEAR_SEGMENTS:
                        der_y = (TABLE(last + 1, col) - TABLE(last, col))/
                            (TABLE_COL0(last + 1) - TABLE_COL0(last));
                        der_y *= der_u;
                        break;

                    case CONSTANT_SEGMENTS:
                        break;

                    case AKIMA_C1:
                    case FRITSCH_BUTLAND_MONOTONE_C1:
                    case STEFFEN_MONOTONE_C1:
                        if (NULL != tableID->spline) {
                            const double* c = tableID->spline[
                                IDX(last, (size_t)(iCol - 1), tableID->nCols)];
                            const double v = u - TABLE_COL0(last);
                            der_y = (3*c[0]*v + 2*c[1])*v + c[2];
                            der_y *= der_u;
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
                    case LAST_TWO_POINTS:
                        switch (tableID->smoothness) {
                            case LINEAR_SEGMENTS:
                            case CONSTANT_SEGMENTS: {
                                const double u0 = TABLE_COL0(last);
                                const double u1 = TABLE_COL0(last + 1);
                                der_y = (TABLE(last + 1, col) - TABLE(last, col))/
                                    (u1 - u0);
                                break;
                            }

                            case AKIMA_C1:
                            case FRITSCH_BUTLAND_MONOTONE_C1:
                            case STEFFEN_MONOTONE_C1:
                                if (NULL != tableID->spline) {
                                    const double* c = tableID->spline[
                                        IDX(last, (size_t)(iCol - 1), tableID->nCols)];
                                    if (extrapolate == LEFT) {
                                        der_y = c[2];
                                    }
                                    else /* if (extrapolate == RIGHT) */ {
                                        der_y = uMax - TABLE_COL0(nRow - 2);
                                        der_y = (3*c[0]*der_y + 2*c[1])*
                                            der_y + c[2];
                                    }
                                }
                                break;

                            default:
                                ModelicaError("Unknown smoothness kind\n");
                                return der_y;
                        }
                        der_y *= der_u;
                        break;

                    case HOLD_LAST_POINT:
                        break;

                    case NO_EXTRAPOLATION:
                        ModelicaFormatError("Extrapolation error: The value u "
                            "(=%lf) must be %s or equal\nthan the %s abscissa "
                            "value %s (=%lf) defined in the table.\n", u,
                            (extrapolate == LEFT) ? "greater" : "less",
                            (extrapolate == LEFT) ? "minimum" : "maximum",
                            (extrapolate == LEFT) ? "u_min" : "u_max",
                            (extrapolate == LEFT) ? uMin : uMax);
                        return der_y;

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
    return der_y;
}

double ModelicaStandardTables_CombiTable1D_getDer2Value(void* _tableID, int iCol,
                                                       double u, double der_u,
                                                       double der2_u) {
    double der2_y = 0.;
    CombiTable1D* tableID = (CombiTable1D*)_tableID;
    if (NULL != tableID && NULL != tableID->table && NULL != tableID->cols) {
        const double* table = tableID->table;
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        const size_t col = (size_t)tableID->cols[iCol - 1] - 1;

        if (nRow > 1) {
            enum PointInterval extrapolate = IN_TABLE;
            const double uMin = TABLE_ROW0(0);
            const double uMax = TABLE_COL0(nRow - 1);
            size_t last;

            /* Periodic extrapolation */
            if (tableID->extrapolation == PERIODIC) {
                const double T = uMax - uMin;

                if (u < uMin) {
                    do {
                        u += T;
                    } while (u < uMin);
                }
                else if (u > uMax) {
                    do {
                        u -= T;
                    } while (u > uMax);
                }
                last = findRowIndex(table, nRow, nCol, tableID->last, u);
                tableID->last = last;
            }
            else if (u < uMin) {
                extrapolate = LEFT;
                last = 0;
            }
            else if (u > uMax) {
                extrapolate = RIGHT;
                last = nRow - 2;
            }
            else {
                last = findRowIndex(table, nRow, nCol, tableID->last, u);
                tableID->last = last;
            }

            if (extrapolate == IN_TABLE) {
                switch (tableID->smoothness) {
                    case LINEAR_SEGMENTS:
                        der2_y = (TABLE(last + 1, col) - TABLE(last, col))/
                            (TABLE_COL0(last + 1) - TABLE_COL0(last));
                        der2_y *= der2_u;
                        break;

                    case CONSTANT_SEGMENTS:
                        break;

                    case AKIMA_C1:
                    case FRITSCH_BUTLAND_MONOTONE_C1:
                    case STEFFEN_MONOTONE_C1:
                        if (NULL != tableID->spline) {
                            const double* c = tableID->spline[
                                IDX(last, (size_t)(iCol - 1), tableID->nCols)];
                            const double v = u - TABLE_COL0(last);
                            der2_y = (3*c[0]*v + 2*c[1])*v + c[2];
                            der2_y *= der2_u;
                            der2_y += (6*c[0]*v + 2*c[1])*der_u*der_u;
                        }
                        break;

                    default:
                        ModelicaError("Unknown smoothness kind\n");
                        return der2_y;
                }
            }
            else {
                /* Extrapolation */
                switch (tableID->extrapolation) {
                    case LAST_TWO_POINTS:
                        switch (tableID->smoothness) {
                            case LINEAR_SEGMENTS:
                            case CONSTANT_SEGMENTS: {
                                const double u0 = TABLE_COL0(last);
                                const double u1 = TABLE_COL0(last + 1);
                                der2_y = (TABLE(last + 1, col) - TABLE(last, col))/
                                    (u1 - u0);
                                break;
                            }

                            case AKIMA_C1:
                            case FRITSCH_BUTLAND_MONOTONE_C1:
                            case STEFFEN_MONOTONE_C1:
                                if (NULL != tableID->spline) {
                                    const double* c = tableID->spline[
                                        IDX(last, (size_t)(iCol - 1), tableID->nCols)];
                                    if (extrapolate == LEFT) {
                                        der2_y = c[2];
                                    }
                                    else /* if (extrapolate == RIGHT) */ {
                                        der2_y = uMax - TABLE_COL0(nRow - 2);
                                        der2_y = (3*c[0]*der2_y + 2*c[1])*
                                            der2_y + c[2];
                                    }
                                }
                                break;

                            default:
                                ModelicaError("Unknown smoothness kind\n");
                                return der2_y;
                        }
                        der2_y *= der2_u;
                        break;

                    case HOLD_LAST_POINT:
                        break;

                    case NO_EXTRAPOLATION:
                        ModelicaFormatError("Extrapolation error: The value u "
                            "(=%lf) must be %s or equal\nthan the %s abscissa "
                            "value %s (=%lf) defined in the table.\n", u,
                            (extrapolate == LEFT) ? "greater" : "less",
                            (extrapolate == LEFT) ? "minimum" : "maximum",
                            (extrapolate == LEFT) ? "u_min" : "u_max",
                            (extrapolate == LEFT) ? uMin : uMax);
                        return der2_y;

                    case PERIODIC:
                        /* Should not be possible to get here */
                        break;

                    default:
                        ModelicaError("Unknown extrapolation kind\n");
                        return der2_y;
                }
            }
        }
    }
    return der2_y;
}

double ModelicaStandardTables_CombiTable1D_minimumAbscissa(void* _tableID) {
    double uMin = 0.;
    CombiTable1D* tableID = (CombiTable1D*)_tableID;
    if (NULL != tableID && NULL != tableID->table) {
        const double* table = tableID->table;
        uMin = TABLE_ROW0(0);
    }
    return uMin;
}

double ModelicaStandardTables_CombiTable1D_maximumAbscissa(void* _tableID) {
    double uMax = 0.;
    CombiTable1D* tableID = (CombiTable1D*)_tableID;
    if (NULL != tableID && NULL != tableID->table) {
        const double* table = tableID->table;
        const size_t nCol = tableID->nCol;
        uMax = TABLE_COL0(tableID->nRow - 1);
    }
    return uMax;
}

double ModelicaStandardTables_CombiTable1D_read(void* _tableID, int force,
                                                int verbose) {
#if !defined(NO_FILE_SYSTEM)
    CombiTable1D* tableID = (CombiTable1D*)_tableID;
    if (NULL != tableID && tableID->source == TABLESOURCE_FILE) {
        if (force || NULL == tableID->table) {
            const char* fileName = tableID->key;
            const char* tableName = tableID->key + strlen(fileName) + 1;
#if defined(TABLE_SHARE)
            TableShare* file = readTable(fileName, tableName, &tableID->nRow,
                &tableID->nCol, verbose, force);
            if (NULL != file) {
                tableID->table = file->table;
            }
            else {
                return 0.; /* Error */
            }
#else
            if (NULL != tableID->table) {
                free(tableID->table);
            }
            tableID->table = readTable(fileName, tableName, &tableID->nRow,
                &tableID->nCol, verbose, force);
#endif
            if (NULL == tableID->table) {
                return 0.; /* Error */
            }
            if (isValidCombiTable1D(tableID, tableName, NO_CLEANUP) == 0) {
                return 0.; /* Error */
            }
            if (tableID->nRow <= 2) {
                if (tableID->smoothness == AKIMA_C1 ||
                    tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1 ||
                    tableID->smoothness == STEFFEN_MONOTONE_C1) {
                    tableID->smoothness = LINEAR_SEGMENTS;
                }
            }
            /* Reinitialization of the cubic Hermite spline coefficients */
            if (tableID->smoothness == AKIMA_C1) {
                spline1DClose(&tableID->spline);
                tableID->spline = akimaSpline1DInit(
                    (const double*)tableID->table, tableID->nRow,
                    tableID->nCol, (const int*)tableID->cols, tableID->nCols);
            }
            else if (tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1) {
                spline1DClose(&tableID->spline);
                tableID->spline = fritschButlandSpline1DInit(
                    (const double*)tableID->table, tableID->nRow,
                    tableID->nCol, (const int*)tableID->cols, tableID->nCols);
            }
            else if (tableID->smoothness == STEFFEN_MONOTONE_C1) {
                spline1DClose(&tableID->spline);
                tableID->spline = steffenSpline1DInit(
                    (const double*)tableID->table, tableID->nRow,
                    tableID->nCol, (const int*)tableID->cols, tableID->nCols);
            }
            if (tableID->smoothness == AKIMA_C1 ||
                tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1 ||
                tableID->smoothness == STEFFEN_MONOTONE_C1) {
                if (NULL == tableID->spline) {
                    ModelicaError("Memory allocation error\n");
                    return 0.; /* Error */
                }
            }
        }
    }
#endif
    return 1.; /* Success */
}

void* ModelicaStandardTables_CombiTable2D_init(_In_z_ const char* tableName,
                                               _In_z_ const char* fileName,
                                               _In_ double* table, size_t nRow,
                                               size_t nColumn, int smoothness) {
    return ModelicaStandardTables_CombiTable2D_init2(fileName, tableName,
        table, nRow, nColumn, smoothness, LAST_TWO_POINTS, 1 /* verbose */);
}

void* ModelicaStandardTables_CombiTable2D_init2(_In_z_ const char* fileName,
                                                _In_z_ const char* tableName,
                                                _In_ double* table, size_t nRow,
                                                size_t nColumn, int smoothness,
                                                int extrapolation,
                                                int verbose) {
    CombiTable2D* tableID;
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
    TableShare* file = NULL;
    char* keyFile = NULL;
#endif
    double* tableFile = NULL;
    size_t nRowFile = 0;
    size_t nColFile = 0;
    enum TableSource source = getTableSource(fileName, tableName);

    /* Read table from file before any other heap allocation */
    if (TABLESOURCE_FILE == source) {
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
        file = readTable(fileName, tableName, &nRowFile, &nColFile, verbose, 0);
        if (NULL != file) {
            keyFile = file->key;
            tableFile = file->table;
        }
        else {
            return NULL;
        }
#else
        tableFile = readTable(fileName, tableName, &nRowFile, &nColFile, verbose, 0);
        if (NULL == tableFile) {
            return NULL;
        }
#endif
    }

    tableID = (CombiTable2D*)calloc(1, sizeof(CombiTable2D));
    if (NULL == tableID) {
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
        if (NULL != file) {
            MUTEX_LOCK();
            if (--file->refCount == 0) {
                ModelicaIO_freeRealTable(file->table);
                free(file->key);
                HASH_DEL(tableShare, file);
                free(file);
            }
            MUTEX_UNLOCK();
        }
#else
        if (NULL != tableFile) {
            free(tableFile);
        }
#endif
        ModelicaError("Memory allocation error\n");
        return NULL;
    }

    tableID->smoothness = (enum Smoothness)smoothness;
    tableID->extrapolation = (enum Extrapolation)extrapolation;
    tableID->source = source;

    switch (tableID->source) {
        case TABLESOURCE_FILE:
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
            tableID->key = keyFile;
#else
            {
                size_t lenFileName = strlen(fileName);
                tableID->key = (char*)malloc((lenFileName + strlen(tableName) + 2)*sizeof(char));
                if (NULL != tableID->key) {
                    strcpy(tableID->key, fileName);
                    strcpy(tableID->key + lenFileName + 1, tableName);
                }
            }
#endif
            tableID->nRow = nRowFile;
            tableID->nCol = nColFile;
            tableID->table = tableFile;
            break;

        case TABLESOURCE_MODEL:
            tableID->nRow = nRow;
            tableID->nCol = nColumn;
#if defined(NO_TABLE_COPY)
            tableID->table = table;
#else
            tableID->table = (double*)malloc(nRow*nColumn*sizeof(double));
            if (NULL != tableID->table) {
                memcpy(tableID->table, table, nRow*nColumn*sizeof(double));
            }
            else {
                ModelicaStandardTables_CombiTable2D_close(tableID);
                ModelicaError("Memory allocation error\n");
                return NULL;
            }
#endif
            break;

        case TABLESOURCE_FUNCTION: {
            int colWise;
            int dim[MAX_TABLE_DIMENSIONS];
            if (usertab((char*)tableName, 2 /* 2D-interpolation */, dim,
                &colWise, &tableID->table) == 0) {
                if (0 == colWise) {
                    tableID->nRow = (size_t)dim[0];
                    tableID->nCol = (size_t)dim[1];
                }
                else {
                    /* Need to transpose */
                    double* tableT = (double*)malloc(
                        (size_t)dim[0]*(size_t)dim[1]*sizeof(double));
                    if (NULL != tableT) {
                        memcpy(tableT, tableID->table,
                            (size_t)dim[0]*(size_t)dim[1]*sizeof(double));
                        tableID->table = tableT;
                        tableID->nRow = (size_t)dim[1];
                        tableID->nCol = (size_t)dim[0];
                        tableID->source = TABLESOURCE_FUNCTION_TRANSPOSE;
                        transpose(tableID->table, tableID->nRow, tableID->nCol);
                    }
                    else {
                        ModelicaStandardTables_CombiTable2D_close(tableID);
                        ModelicaError("Memory allocation error\n");
                        return NULL;
                    }
                }
            }
            break;
        }

        case TABLESOURCE_FUNCTION_TRANSPOSE:
            /* Should not be possible to get here */
            break;

        default:
            ModelicaStandardTables_CombiTable2D_close(tableID);
            ModelicaError("Table source error\n");
            return NULL;
    }

    if (isValidCombiTable2D(tableID, tableName, DO_CLEANUP) == 0) {
        return NULL;
    }

    if (tableID->smoothness == AKIMA_C1 &&
        tableID->nRow <= 3 && tableID->nCol <= 3) {
        tableID->smoothness = LINEAR_SEGMENTS;
    }
    /* Initialization of the Akima-spline coefficients */
    if (tableID->smoothness == AKIMA_C1) {
        tableID->spline = spline2DInit((const double*)tableID->table,
            tableID->nRow, tableID->nCol);
        if (NULL == tableID->spline) {
            ModelicaStandardTables_CombiTable2D_close(tableID);
            ModelicaError("Memory allocation error\n");
            return NULL;
        }
    }

    return (void*)tableID;
}

void ModelicaStandardTables_CombiTable2D_close(void* _tableID) {
    CombiTable2D* tableID = (CombiTable2D*)_tableID;
    if (NULL == tableID) {
        return;
    }
    if (NULL != tableID->table && tableID->source == TABLESOURCE_FILE) {
#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
        if (NULL != tableID->key) {
            TableShare* file;
            MUTEX_LOCK();
            HASH_FIND_STR(tableShare, tableID->key, file);
            if (NULL != file) {
                /* Share hit */
                if (--file->refCount == 0) {
                    ModelicaIO_freeRealTable(file->table);
                    free(file->key);
                    HASH_DEL(tableShare, file);
                    free(file);
                }
            }
            MUTEX_UNLOCK();
        }
        else {
            /* Should not be possible to get here */
            free(tableID->table);
        }
#else
        if (NULL != tableID->key) {
            free(tableID->key);
        }
        free(tableID->table);
#endif
    }
    else if (NULL != tableID->table && (
#if !defined(NO_TABLE_COPY)
        tableID->source == TABLESOURCE_MODEL ||
#endif
        tableID->source == TABLESOURCE_FUNCTION_TRANSPOSE)) {
        free(tableID->table);
    }
    spline2DClose(&tableID->spline);
    free(tableID);
}

double ModelicaStandardTables_CombiTable2D_getValue(void* _tableID, double u1,
                                                    double u2) {
    double y = 0;
    CombiTable2D* tableID = (CombiTable2D*)_tableID;
    if (NULL != tableID && NULL != tableID->table) {
        const double* table = tableID->table;
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        const double u1Min = TABLE_COL0(1);
        const double u1Max = TABLE_COL0(nRow - 1);
        const double u2Min = TABLE_ROW0(1);
        const double u2Max = TABLE_ROW0(nCol - 1);

        if (nRow == 2) {
            if (nCol == 2) {
                /* Single row */
                y = TABLE(1, 1);
            }
            else if (nCol > 2) {
                enum PointInterval extrapolate2 = IN_TABLE;
                size_t last2;

                /* Periodic extrapolation */
                if (tableID->extrapolation == PERIODIC) {
                    const double T = u2Max - u2Min;

                    if (u2 < u2Min) {
                        do {
                            u2 += T;
                        } while (u2 < u2Min);
                    }
                    else if (u2 > u2Max) {
                        do {
                            u2 -= T;
                        } while (u2 > u2Max);
                    }
                    last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                        tableID->last2, u2);
                    tableID->last2 = last2;
                }
                else if (u2 < u2Min) {
                    extrapolate2 = LEFT;
                    last2 = 0;
                }
                else if (u2 > u2Max) {
                    extrapolate2 = RIGHT;
                    last2 = nCol - 3;
                }
                else {
                    last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                        tableID->last2, u2);
                    tableID->last2 = last2;
                }

                if (extrapolate2 == IN_TABLE) {
                    switch (tableID->smoothness) {
                        case LINEAR_SEGMENTS: {
                            const double u20 = TABLE_ROW0(last2 + 1);
                            const double u21 = TABLE_ROW0(last2 + 2);
                            const double y0 = TABLE(1, last2 + 1);
                            const double y1 = TABLE(1, last2 + 2);
                            LINEAR(u2, u20, u21, y0, y1);
                            break;
                        }

                        case CONSTANT_SEGMENTS:
                            if (u2 >= TABLE_ROW0(last2 + 2)) {
                                last2++;
                            }
                            y = TABLE(1, last2 + 1);
                            break;

                        case AKIMA_C1:
                            if (NULL != tableID->spline) {
                                const double* c = tableID->spline[last2];
                                const double v = u2 - TABLE_ROW0(last2 + 1);
                                y = TABLE(1, last2 + 1); /* c[3] = y0 */
                                y += ((c[0]*v + c[1])*v + c[2])*v;
                            }
                            break;

                        case FRITSCH_BUTLAND_MONOTONE_C1:
                        case STEFFEN_MONOTONE_C1:
                            ModelicaError("Bivariate monotone C1 interpolation is "
                                "not implemented\n");
                            return y;

                        default:
                            ModelicaError("Unknown smoothness kind\n");
                            return y;
                    }
                }
                else {
                    /* Extrapolation */
                    switch (tableID->extrapolation) {
                        case LAST_TWO_POINTS:
                            switch (tableID->smoothness) {
                                case LINEAR_SEGMENTS:
                                case CONSTANT_SEGMENTS: {
                                    const double u20 = TABLE_ROW0(last2 + 1);
                                    const double u21 = TABLE_ROW0(last2 + 2);
                                    const double y0 = TABLE(1, last2 + 1);
                                    const double y1 = TABLE(1, last2 + 2);
                                    LINEAR(u2, u20, u21, y0, y1);
                                    break;
                                }

                                case AKIMA_C1:
                                    if (NULL != tableID->spline) {
                                        const double* c = tableID->spline[last2];
                                        if (extrapolate2 == LEFT) {
                                            LINEAR_SLOPE(TABLE(1, 1), c[2], u2 - u2Min);
                                        }
                                        else /* if (extrapolate2 == RIGHT) */ {
                                            const double v2 = u2Max - TABLE_ROW0(nCol - 2);
                                            LINEAR_SLOPE(TABLE(1, nCol - 1), (3*c[0]*v2 +
                                                2*c[1])*v2 + c[2], u2 - u2Max);
                                        }
                                    }
                                    break;

                                case FRITSCH_BUTLAND_MONOTONE_C1:
                                case STEFFEN_MONOTONE_C1:
                                    ModelicaError("Bivariate monotone C1 interpolation is "
                                        "not implemented\n");
                                    return y;

                                default:
                                    ModelicaError("Unknown smoothness kind\n");
                                    return y;
                            }
                            break;

                        case HOLD_LAST_POINT:
                            y = (extrapolate2 == RIGHT) ? TABLE(1, nCol - 1) :
                                TABLE(1, 1);
                            break;

                        case NO_EXTRAPOLATION:
                            ModelicaFormatError("Extrapolation error: The value u2 "
                                "(=%lf) must be %s or equal\nthan the %s abscissa "
                                "value %s (=%lf) defined in the table.\n", u2,
                                (extrapolate2 == LEFT) ? "greater" : "less",
                                (extrapolate2 == LEFT) ? "minimum" : "maximum",
                                (extrapolate2 == LEFT) ? "u_min[2]" : "u_max[2]",
                                (extrapolate2 == LEFT) ? u2Min : u2Max);
                            return y;

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
        else if (nRow > 2) {
            enum PointInterval extrapolate1 = IN_TABLE;
            size_t last1;

            /* Periodic extrapolation */
            if (tableID->extrapolation == PERIODIC) {
                const double T = u1Max - u1Min;

                if (u1 < u1Min) {
                    do {
                        u1 += T;
                    } while (u1 < u1Min);
                }
                else if (u1 > u1Max) {
                    do {
                        u1 -= T;
                    } while (u1 > u1Max);
                }
                last1 = findRowIndex(&TABLE(1, 0), nRow - 1, nCol,
                    tableID->last1, u1);
                tableID->last1 = last1;
            }
            else if (u1 < u1Min) {
                extrapolate1 = LEFT;
                last1 = 0;
            }
            else if (u1 > u1Max) {
                extrapolate1 = RIGHT;
                last1 = nRow - 3;
            }
            else {
                last1 = findRowIndex(&TABLE(1, 0), nRow - 1, nCol,
                    tableID->last1, u1);
                tableID->last1 = last1;
            }
            if (nCol == 2) {
                if (extrapolate1 == IN_TABLE) {
                    switch (tableID->smoothness) {
                        case LINEAR_SEGMENTS: {
                            const double u10 = TABLE_COL0(last1 + 1);
                            const double u11 = TABLE_COL0(last1 + 2);
                            const double y0 = TABLE(last1 + 1, 1);
                            const double y1 = TABLE(last1 + 2, 1);
                            LINEAR(u1, u10, u11, y0, y1);
                            break;
                        }

                        case CONSTANT_SEGMENTS:
                            if (u1 >= TABLE_COL0(last1 + 2)) {
                                last1++;
                            }
                            y = TABLE(last1 + 1, 1);
                            break;

                        case AKIMA_C1:
                            if (NULL != tableID->spline) {
                                const double* c = tableID->spline[last1];
                                const double v = u1 - TABLE_COL0(last1 + 1);
                                y = TABLE(last1 + 1, 1); /* c[3] = y0 */
                                y += ((c[0]*v + c[1])*v + c[2])*v;
                            }
                            break;

                        case FRITSCH_BUTLAND_MONOTONE_C1:
                        case STEFFEN_MONOTONE_C1:
                            ModelicaError("Bivariate monotone C1 interpolation is "
                                "not implemented\n");
                            return y;

                        default:
                            ModelicaError("Unknown smoothness kind\n");
                            return y;
                    }
                }
                else {
                    /* Extrapolation */
                    switch (tableID->extrapolation) {
                        case LAST_TWO_POINTS:
                            switch (tableID->smoothness) {
                                case LINEAR_SEGMENTS:
                                case CONSTANT_SEGMENTS: {
                                    const double u10 = TABLE_COL0(last1 + 1);
                                    const double u11 = TABLE_COL0(last1 + 2);
                                    const double y0 = TABLE(last1 + 1, 1);
                                    const double y1 = TABLE(last1 + 2, 1);
                                    LINEAR(u1, u10, u11, y0, y1);
                                    break;
                                }

                                case AKIMA_C1:
                                    if (NULL != tableID->spline) {
                                        const double* c = tableID->spline[last1];
                                        if (extrapolate1 == LEFT) {
                                            LINEAR_SLOPE(TABLE(1, 1), c[2], u1 - u1Min);
                                        }
                                        else /* if (extrapolate1 == RIGHT) */ {
                                            const double v1 = u1Max - TABLE_COL0(nRow - 2);
                                            LINEAR_SLOPE(TABLE(nRow - 1, 1), (3*c[0]*v1 +
                                                2*c[1])*v1 + c[2], u1 - u1Max);
                                        }
                                    }
                                    break;

                                case FRITSCH_BUTLAND_MONOTONE_C1:
                                case STEFFEN_MONOTONE_C1:
                                    ModelicaError("Bivariate monotone C1 interpolation is "
                                        "not implemented\n");
                                    return y;

                                default:
                                    ModelicaError("Unknown smoothness kind\n");
                                    return y;
                            }
                            break;

                        case HOLD_LAST_POINT:
                            y = (extrapolate1 == RIGHT) ? TABLE(nRow - 1, 1) :
                                TABLE(1, 1);
                            break;

                        case NO_EXTRAPOLATION:
                            ModelicaFormatError("Extrapolation error: The value u1 "
                                "(=%lf) must be %s or equal\nthan the %s abscissa "
                                "value %s (=%lf) defined in the table.\n", u1,
                                (extrapolate1 == LEFT) ? "greater" : "less",
                                (extrapolate1 == LEFT) ? "minimum" : "maximum",
                                (extrapolate1 == LEFT) ? "u_min[1]" : "u_max[1]",
                                (extrapolate1 == LEFT) ? u1Min : u1Max);
                            return y;

                        case PERIODIC:
                            /* Should not be possible to get here */
                            break;

                        default:
                            ModelicaError("Unknown extrapolation kind\n");
                            return y;
                    }
                }
            }
            else if (nCol > 2) {
                enum PointInterval extrapolate2 = IN_TABLE;
                size_t last2;

                /* Periodic extrapolation */
                if (tableID->extrapolation == PERIODIC) {
                    const double T = u2Max - u2Min;

                    if (u2 < u2Min) {
                        do {
                            u2 += T;
                        } while (u2 < u2Min);
                    }
                    else if (u2 > u2Max) {
                        do {
                            u2 -= T;
                        } while (u2 > u2Max);
                    }
                    last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                        tableID->last2, u2);
                    tableID->last2 = last2;
                }
                else if (u2 < u2Min) {
                    extrapolate2 = LEFT;
                    last2 = 0;
                }
                else if (u2 > u2Max) {
                    extrapolate2 = RIGHT;
                    last2 = nCol - 3;
                }
                else {
                    last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                        tableID->last2, u2);
                    tableID->last2 = last2;
                }

                if (extrapolate1 == IN_TABLE) {
                    if (extrapolate2 == IN_TABLE) {
                        switch (tableID->smoothness) {
                            case LINEAR_SEGMENTS:
                                BILINEAR(u1, u2);
                                break;

                            case CONSTANT_SEGMENTS:
                                if (u1 >= TABLE_COL0(last1 + 2)) {
                                    last1++;
                                }
                                if (u2 >= TABLE_ROW0(last2 + 2)) {
                                    last2++;
                                }
                                y = TABLE(last1 + 1, last2 + 1);
                                break;

                            case AKIMA_C1:
                                if (NULL != tableID->spline) {
                                    const double* c = tableID->spline[
                                        IDX(last1, last2, nCol - 2)];
                                    double p1, p2, p3;
                                    u1 -= TABLE_COL0(last1 + 1);
                                    u2 -= TABLE_ROW0(last2 + 1);
                                    p1 = ((c[0]*u2 + c[1])*u2 + c[2])*u2 + c[3];
                                    p2 = ((c[4]*u2 + c[5])*u2 + c[6])*u2 + c[7];
                                    p3 = ((c[8]*u2 + c[9])*u2 + c[10])*u2 + c[11];
                                    y = TABLE(last1 + 1, last2 + 1); /* c[15] = y00 */
                                    y += ((c[12]*u2 + c[13])*u2 + c[14])*u2; /* p4 */
                                    y += ((p1*u1 + p2)*u1 + p3)*u1;
                                }
                                break;

                            case FRITSCH_BUTLAND_MONOTONE_C1:
                            case STEFFEN_MONOTONE_C1:
                                ModelicaError("Bivariate monotone C1 interpolation is "
                                    "not implemented\n");
                                return y;

                            default:
                                ModelicaError("Unknown smoothness kind\n");
                                return y;
                        }
                    }
                    else if (extrapolate2 == LEFT) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(last1, 0, nCol - 2)];
                                            double der_y2;
                                            u1 -= TABLE_COL0(last1 + 1);
                                            der_y2 = ((c[2]*u1 + c[6])*u1 + c[10])*u1 + c[14];
                                            y = TABLE(last1 + 1, 1); /* c[15] = y00 */
                                            y += ((c[3]*u1 + c[7])*u1 + c[11])*u1;
                                            y += der_y2*(u2 - u2Min);
                                        }
                                        break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS: {
                                        const double u10 = TABLE_COL0(last1 + 1);
                                        const double u11 = TABLE_COL0(last1 + 2);
                                        const double y00 = TABLE(last1 + 1, 1);
                                        const double y10 = TABLE(last1 + 2, 1);
                                        LINEAR(u1, u10, u11, y00, y10);
                                        break;
                                    }

                                    case CONSTANT_SEGMENTS:
                                        if (u1 >= TABLE_COL0(last1 + 2)) {
                                            last1++;
                                        }
                                        y = TABLE(last1 + 1, 1);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(last1, 0, nCol - 2)];
                                            u1 -= TABLE_COL0(last1 + 1);
                                            y = TABLE(last1 + 1, 1); /* c[15] = y00 */
                                            y += ((c[3]*u1 + c[7])*u1 + c[11])*u1;
                                        }
                                        break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return y;
                                 }
                                 break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u2 "
                                    "(=%lf) must be greater or equal\nthan the minimum abscissa "
                                    "value u_min[2] (=%lf) defined in the table.\n", u2, u2Min);
                                return y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return y;
                        }
                    }
                    else /* if (extrapolate2 == RIGHT) */ {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(last1, nCol - 3, nCol - 2)];
                                            const double v2 = u2Max - TABLE_ROW0(nCol - 2);
                                            double p1, p2, p3;
                                            double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                            double der_y2;
                                            u1 -= TABLE_COL0(last1 + 1);
                                            y = TABLE(last1 + 1, nCol - 2); /* c[15] = y00 */
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
                                            y += der_y2*(u2 - u2Max);
                                        }
                                        break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS: {
                                        const double u10 = TABLE_COL0(last1 + 1);
                                        const double u11 = TABLE_COL0(last1 + 2);
                                        const double y01 = TABLE(last1 + 1, nCol - 1);
                                        const double y11 = TABLE(last1 + 2, nCol - 1);
                                        LINEAR(u1, u10, u11, y01, y11);
                                        break;
                                    }

                                    case CONSTANT_SEGMENTS:
                                        if (u1 >= TABLE_COL0(last1 + 2)) {
                                            last1++;
                                        }
                                        y = TABLE(last1 + 1, nCol - 1);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(last1, nCol - 3, nCol - 2)];
                                            const double v2 = u2Max - TABLE_ROW0(nCol - 2);
                                            double p1, p2, p3;
                                            u1 -= TABLE_COL0(last1 + 1);
                                            y = TABLE(last1 + 1, nCol - 2); /* c[15] = y00 */
                                            p1 = ((c[0]*v2 + c[1])*v2 + c[2])*v2 + c[3];
                                            p2 = ((c[4]*v2 + c[5])*v2 + c[6])*v2 + c[7];
                                            p3 = ((c[8]*v2 + c[9])*v2 + c[10])*v2 + c[11];
                                            y += ((c[12]*v2 + c[13])*v2 + c[14])*v2; /* p4 */
                                            y += ((p1*u1 + p2)*u1 + p3)*u1;
                                        }
                                        break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return y;
                                 }
                                 break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u2 "
                                    "(=%lf) must be less or equal\nthan the maximum abscissa "
                                    "value u_max[2] (=%lf) defined in the table.\n", u2, u2Max);
                                return y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return y;
                        }
                    }
                }
                else if (extrapolate1 == LEFT) {
                    if (extrapolate2 == IN_TABLE) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(0, last2, nCol - 2)];
                                            double der_y1;
                                            u2 -= TABLE_ROW0(last2 + 1);
                                            der_y1 = ((c[8]*u2 + c[9])*u2 + c[10])*u2 + c[11];
                                            y = TABLE(1, last2 + 1); /* c[15] = y00 */
                                            y += ((c[12]*u2 + c[13])*u2 + c[14])*u2; /* p4 */
                                            y += der_y1*(u1 - u1Min);
                                        }
                                        break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS: {
                                        const double u20 = TABLE_ROW0(last2 + 1);
                                        const double u21 = TABLE_ROW0(last2 + 2);
                                        const double y00 = TABLE(1, last2 + 1);
                                        const double y01 = TABLE(1, last2 + 2);
                                        LINEAR(u2, u20, u21, y00, y01);
                                        break;
                                    }

                                    case CONSTANT_SEGMENTS:
                                        if (u2 >= TABLE_ROW0(last2 + 2)) {
                                            last2++;
                                        }
                                        y = TABLE(1, last2 + 1);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(0, last2, nCol - 2)];
                                            u2 -= TABLE_ROW0(last2 + 1);
                                            y = TABLE(1, last2 + 1); /* c[15] = y00 */
                                            y += ((c[12]*u2 + c[13])*u2 + c[14])*u2; /* p4 */
                                        }
                                        break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return y;
                                 }
                                 break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be greater or equal\nthan the minimum abscissa "
                                    "value u_min[1] (=%lf) defined in the table.\n", u1, u1Min);
                                return y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return y;
                        }
                    }
                    else if (extrapolate2 == LEFT) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(0, 0, nCol - 2)];
                                            u1 -= u1Min;
                                            u2 -= u2Min;
                                            y = TABLE(1, 1);
                                            y += c[11]*u1 + c[14]*u2 + c[10]*u1*u2;
                                        }
                                        break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                y =  TABLE(1, 1);
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be greater or equal\nthan the minimum abscissa "
                                    "value u_min[1] (=%lf) defined in the table.\n"
                                    "Extrapolation error: The value u2 (=%lf) must be greater "
                                    "or equal\nthan the minimum abscissa value u_min[2] (=%lf) "
                                    "defined in the table.\n", u1, u1Min, u2, u2Min);
                                return y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return y;
                        }
                    }
                    else /* if (extrapolate2 == RIGHT) */ {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(0, nCol - 3, nCol - 2)];
                                            const double v2 = u2Max - TABLE_ROW0(nCol - 2);
                                            double der_y1, der_y2, der_y12;
                                            u1 -= u1Min;
                                            u2 -= u2Max;
                                            der_y1 = ((c[8]*v2 + c[9])*v2 + c[10])*v2 + c[11];
                                            der_y2 =(3*c[12]*v2 + 2*c[13])*v2 + c[14];
                                            der_y12 = (3*c[8]*v2 + 2*c[9])*v2 + c[10];
                                            y = TABLE(1, nCol - 1);
                                            y += der_y1*u1 + der_y2*u2 + der_y12*u1*u2;
                                        }
                                        break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                y = TABLE(1, nCol - 1);
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be greater or equal\nthan the minimum abscissa "
                                    "value u_min[1] (=%lf) defined in the table.\n"
                                    "Extrapolation error: The value u2 (=%lf) must be less "
                                    "or equal\nthan the maximum abscissa value u_max[2] (=%lf) "
                                    "defined in the table.\n", u1, u1Min, u2, u2Max);
                                return y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return y;
                        }
                    }
                }
                else /* if (extrapolate1 == RIGHT) */ {
                    if (extrapolate2 == IN_TABLE) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(nRow - 3, last2, nCol - 2)];
                                            double p1, p2, p3;
                                            double der_y1;
                                            const double v1 = u1Max - TABLE_COL0(nRow - 2);
                                            u2 -= TABLE_ROW0(last2 + 1);
                                            p1 = ((c[0]*u2 + c[1])*u2 + c[2])*u2 + c[3];
                                            p2 = ((c[4]*u2 + c[5])*u2 + c[6])*u2 + c[7];
                                            p3 = ((c[8]*u2 + c[9])*u2 + c[10])*u2 + c[11];
                                            der_y1 = (3*p1*v1 + 2*p2)*v1 + p3;
                                            y = TABLE(nRow - 2, last2 + 1); /* c[15] = y00 */
                                            y += ((c[12]*u2 + c[13])*u2 + c[14])*u2; /* p4 */
                                            y += ((p1*v1 + p2)*v1 + p3)*v1;
                                            y += der_y1*(u1 - u1Max);
                                        }
                                        break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS: {
                                        const double u20 = TABLE_ROW0(last2 + 1);
                                        const double u21 = TABLE_ROW0(last2 + 2);
                                        const double y10 = TABLE(nRow - 1, last2 + 1);
                                        const double y11 = TABLE(nRow - 1, last2 + 2);
                                        LINEAR(u2, u20, u21, y10, y11);
                                        break;
                                    }

                                    case CONSTANT_SEGMENTS:
                                        if (u2 >= TABLE_ROW0(last2 + 2)) {
                                            last2++;
                                        }
                                        y = TABLE(nRow - 1, last2 + 1);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(nRow - 3, last2, nCol - 2)];
                                            double p1, p2, p3;
                                            const double v1 = u1Max - TABLE_COL0(nRow - 2);
                                            u2 -= TABLE_ROW0(last2 + 1);
                                            p1 = ((c[0]*u2 + c[1])*u2 + c[2])*u2 + c[3];
                                            p2 = ((c[4]*u2 + c[5])*u2 + c[6])*u2 + c[7];
                                            p3 = ((c[8]*u2 + c[9])*u2 + c[10])*u2 + c[11];
                                            y = TABLE(nRow - 2, last2 + 1); /* c[15] = y00 */
                                            y += ((c[12]*u2 + c[13])*u2 + c[14])*u2; /* p4 */
                                            y += ((p1*v1 + p2)*v1 + p3)*v1;
                                        }
                                        break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return y;
                                 }
                                 break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be less or equal\nthan the maximum abscissa "
                                    "value u_max[1] (=%lf) defined in the table.\n", u1, u1Max);
                                return y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return y;
                        }
                    }
                    else if (extrapolate2 == LEFT) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(nRow - 3 , 0, nCol - 2)];
                                            const double v1 = u1Max - TABLE_COL0(nRow - 2);
                                            double der_y1, der_y2, der_y12;
                                            u1 -= u1Max;
                                            u2 -= u2Min;
                                            der_y1 = (3*c[3]*v1 + 2*c[7])*v1 + c[11];
                                            der_y2 = ((c[2]*v1 + c[6])*v1 + c[10])*v1 + c[14];
                                            der_y12 = (3*c[2]*v1 + 2*c[6])*v1 + c[10];
                                            y = TABLE(nRow - 1, 1);
                                            y += der_y1*u1 + der_y2*u2 + der_y12*u1*u2;
                                        }
                                        break;


                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                y = TABLE(nRow - 1, 1);
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be less or equal\nthan the maximum abscissa "
                                    "value u_max[1] (=%lf) defined in the table.\n"
                                    "Extrapolation error: The value u2 (=%lf) must be greater "
                                    "or equal\nthan the minimum abscissa value u_min[2] (=%lf) "
                                    "defined in the table.\n", u1, u1Max, u2, u2Min);
                                return y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return y;
                        }
                    }
                    else /* if (extrapolate2 == RIGHT) */ {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(nRow - 3, nCol - 3, nCol - 2)];
                                            const double v1 = u1Max - TABLE_COL0(nRow - 2);
                                            const double v2 = u2Max - TABLE_ROW0(nCol - 2);
                                            double p1, p2, p3;
                                            double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                            double der_y1, der_y2, der_y12;
                                            u1 -= u1Max;
                                            u2 -= u2Max;
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
                                        break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                y = TABLE(nRow - 1, nCol - 1);
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be less or equal\nthan the maximum abscissa "
                                    "value u_max[1] (=%lf) defined in the table.\n"
                                    "Extrapolation error: The value u2 (=%lf) must be less "
                                    "or equal\nthan the maximum abscissa value u_max[2] (=%lf) "
                                    "defined in the table.\n", u1, u1Max, u2, u2Max);
                                return y;

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
    }
    return y;
}

double ModelicaStandardTables_CombiTable2D_getDerValue(void* _tableID, double u1,
                                                       double u2, double der_u1,
                                                       double der_u2) {
    double der_y = 0;
    CombiTable2D* tableID = (CombiTable2D*)_tableID;
    if (NULL != tableID && NULL != tableID->table) {
        const double* table = tableID->table;
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        const double u1Min = TABLE_COL0(1);
        const double u1Max = TABLE_COL0(nRow - 1);
        const double u2Min = TABLE_ROW0(1);
        const double u2Max = TABLE_ROW0(nCol - 1);

        if (nRow == 2) {
            if (nCol > 2) {
                enum PointInterval extrapolate2 = IN_TABLE;
                size_t last2;

                /* Periodic extrapolation */
                if (tableID->extrapolation == PERIODIC) {
                    const double T = u2Max - u2Min;

                    if (u2 < u2Min) {
                        do {
                            u2 += T;
                        } while (u2 < u2Min);
                    }
                    else if (u2 > u2Max) {
                        do {
                            u2 -= T;
                        } while (u2 > u2Max);
                    }
                    last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                        tableID->last2, u2);
                    tableID->last2 = last2;
                }
                else if (u2 < u2Min) {
                    extrapolate2 = LEFT;
                    last2 = 0;
                }
                else if (u2 > u2Max) {
                    extrapolate2 = RIGHT;
                    last2 = nCol - 3;
                }
                else {
                    last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                        tableID->last2, u2);
                    tableID->last2 = last2;
                }

                if (extrapolate2 == IN_TABLE) {
                    switch (tableID->smoothness) {
                        case LINEAR_SEGMENTS:
                            der_y = (TABLE(1, last2 + 2) - TABLE(1, last2 + 1))/
                                (TABLE_ROW0(last2 + 2) - TABLE_ROW0(last2 + 1));
                            der_y *= der_u2;
                            break;

                        case CONSTANT_SEGMENTS:
                            break;

                        case AKIMA_C1:
                            if (NULL != tableID->spline) {
                                const double* c = tableID->spline[last2];
                                const double u20 = TABLE_ROW0(last2 + 1);
                                u2 -= u20;
                                der_y = (3*c[0]*u2 + 2*c[1])*u2 + c[2];
                                der_y *= der_u2;
                            }
                            break;

                        case FRITSCH_BUTLAND_MONOTONE_C1:
                        case STEFFEN_MONOTONE_C1:
                            ModelicaError("Bivariate monotone C1 interpolation is "
                                "not implemented\n");
                            return der_y;

                        default:
                            ModelicaError("Unknown smoothness kind\n");
                            return der_y;
                    }
                }
                else {
                    /* Extrapolation */
                    switch (tableID->extrapolation) {
                        case LAST_TWO_POINTS:
                            switch (tableID->smoothness) {
                                case LINEAR_SEGMENTS:
                                case CONSTANT_SEGMENTS:
                                    der_y = (TABLE(1, last2 + 2) - TABLE(1, last2 + 1))/
                                        (TABLE_ROW0(last2 + 2) - TABLE_ROW0(last2 + 1));
                                    der_y *= der_u2;
                                    break;

                                case AKIMA_C1:
                                    if (NULL != tableID->spline) {
                                        const double* c = tableID->spline[last2];
                                        if (extrapolate2 == LEFT) {
                                            der_y = c[2];
                                        }
                                        else /* if (extrapolate2 == RIGHT) */ {
                                            const double u20 = TABLE_ROW0(last2 + 1);
                                            const double u21 = TABLE_ROW0(last2 + 2);
                                            der_y = u21 - u20;
                                            der_y = (3*c[0]*der_y + 2*c[1])*der_y + c[2];
                                        }
                                        der_y *= der_u2;
                                    }
                                    break;

                                case FRITSCH_BUTLAND_MONOTONE_C1:
                                case STEFFEN_MONOTONE_C1:
                                    ModelicaError("Bivariate monotone C1 interpolation is "
                                        "not implemented\n");
                                    return der_y;

                                default:
                                    ModelicaError("Unknown smoothness kind\n");
                                    return der_y;
                            }
                            break;

                        case HOLD_LAST_POINT:
                            break;

                        case NO_EXTRAPOLATION:
                            ModelicaFormatError("Extrapolation error: The value u2 "
                                "(=%lf) must be %s or equal\nthan the %s abscissa "
                                "value %s (=%lf) defined in the table.\n", u2,
                                (extrapolate2 == LEFT) ? "greater" : "less",
                                (extrapolate2 == LEFT) ? "minimum" : "maximum",
                                (extrapolate2 == LEFT) ? "u_min[2]" : "u_max[2]",
                                (extrapolate2 == LEFT) ? u2Min : u2Max);
                            return der_y;

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
        else if (nRow > 2) {
            enum PointInterval extrapolate1 = IN_TABLE;
            size_t last1;

            /* Periodic extrapolation */
            if (tableID->extrapolation == PERIODIC) {
                const double T = u1Max - u1Min;

                if (u1 < u1Min) {
                    do {
                        u1 += T;
                    } while (u1 < u1Min);
                }
                else if (u1 > u1Max) {
                    do {
                        u1 -= T;
                    } while (u1 > u1Max);
                }
                last1 = findRowIndex(&TABLE(1, 0), nRow - 1, nCol,
                    tableID->last1, u1);
                tableID->last1 = last1;
            }
            else if (u1 < u1Min) {
                extrapolate1 = LEFT;
                last1 = 0;
            }
            else if (u1 > u1Max) {
                extrapolate1 = RIGHT;
                last1 = nRow - 3;
            }
            else {
                last1 = findRowIndex(&TABLE(1, 0), nRow - 1, nCol,
                    tableID->last1, u1);
                tableID->last1 = last1;
            }
            if (nCol == 2) {
                if (extrapolate1 == IN_TABLE) {
                    switch (tableID->smoothness) {
                        case LINEAR_SEGMENTS:
                            der_y = (TABLE(last1 + 2, 1) - TABLE(last1 + 1, 1))/
                                (TABLE_COL0(last1 + 2) - TABLE_COL0(last1 + 1));
                            der_y *= der_u1;
                            break;

                        case CONSTANT_SEGMENTS:
                            break;

                        case AKIMA_C1:
                            if (NULL != tableID->spline) {
                                const double* c = tableID->spline[last1];
                                const double u10 = TABLE_COL0(last1 + 1);
                                u1 -= u10;
                                der_y = (3*c[0]*u1 + 2*c[1])*u1 + c[2];
                                der_y *= der_u1;
                            }
                            break;

                        case FRITSCH_BUTLAND_MONOTONE_C1:
                        case STEFFEN_MONOTONE_C1:
                            ModelicaError("Bivariate monotone C1 interpolation is "
                                "not implemented\n");
                            return der_y;

                        default:
                            ModelicaError("Unknown smoothness kind\n");
                            return der_y;
                    }
                }
                else {
                    /* Extrapolation */
                    switch (tableID->extrapolation) {
                        case LAST_TWO_POINTS:
                            switch (tableID->smoothness) {
                                case LINEAR_SEGMENTS:
                                case CONSTANT_SEGMENTS:
                                    der_y = (TABLE(last1 + 2, 1) - TABLE(last1 + 1, 1))/
                                        (TABLE_COL0(last1 + 2) - TABLE_COL0(last1 + 1));
                                    der_y *= der_u1;
                                    break;

                                case AKIMA_C1:
                                    if (NULL != tableID->spline) {
                                        const double* c = tableID->spline[last1];
                                        if (extrapolate1 == LEFT) {
                                            der_y = c[2];
                                        }
                                        else /* if (extrapolate1 == RIGHT) */ {
                                            const double u10 = TABLE_COL0(last1 + 1);
                                            const double u11 = TABLE_COL0(last1 + 2);
                                            der_y = u11 - u10;
                                            der_y = (3*c[0]*der_y + 2*c[1])*der_y + c[2];
                                        }
                                        der_y *= der_u1;
                                    }
                                    break;

                                case FRITSCH_BUTLAND_MONOTONE_C1:
                                case STEFFEN_MONOTONE_C1:
                                    ModelicaError("Bivariate monotone C1 interpolation is "
                                        "not implemented\n");
                                    return der_y;

                                default:
                                    ModelicaError("Unknown smoothness kind\n");
                                    return der_y;
                            }
                            break;

                        case HOLD_LAST_POINT:
                            break;

                        case NO_EXTRAPOLATION:
                            ModelicaFormatError("Extrapolation error: The value u1 "
                                "(=%lf) must be %s or equal\nthan the %s abscissa "
                                "value %s (=%lf) defined in the table.\n", u1,
                                (extrapolate1 == LEFT) ? "greater" : "less",
                                (extrapolate1 == LEFT) ? "minimum" : "maximum",
                                (extrapolate1 == LEFT) ? "u_min[1]" : "u_max[1]",
                                (extrapolate1 == LEFT) ? u1Min : u1Max);
                            return der_y;

                        case PERIODIC:
                            /* Should not be possible to get here */
                            break;

                        default:
                            ModelicaError("Unknown extrapolation kind\n");
                            return der_y;
                    }
                }
            }
            else if (nCol > 2) {
                enum PointInterval extrapolate2 = IN_TABLE;
                size_t last2;

                /* Periodic extrapolation */
                if (tableID->extrapolation == PERIODIC) {
                    const double T = u2Max - u2Min;

                    if (u2 < u2Min) {
                        do {
                            u2 += T;
                        } while (u2 < u2Min);
                    }
                    else if (u2 > u2Max) {
                        do {
                            u2 -= T;
                        } while (u2 > u2Max);
                    }
                    last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                        tableID->last2, u2);
                    tableID->last2 = last2;
                }
                else if (u2 < u2Min) {
                    extrapolate2 = LEFT;
                    last2 = 0;
                }
                else if (u2 > u2Max) {
                    extrapolate2 = RIGHT;
                    last2 = nCol - 3;
                }
                else {
                    last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                        tableID->last2, u2);
                    tableID->last2 = last2;
                }

                if (extrapolate1 == IN_TABLE) {
                    if (extrapolate2 == IN_TABLE) {
                        switch (tableID->smoothness) {
                            case LINEAR_SEGMENTS:
                                BILINEAR_DER(u1, u2);
                                break;

                            case CONSTANT_SEGMENTS:
                                break;

                            case AKIMA_C1:
                                if (NULL != tableID->spline) {
                                    const double* c = tableID->spline[
                                        IDX(last1, last2, nCol - 2)];
                                    double der_y1, der_y2;
                                    double p1, p2, p3;
                                    double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                    u1 -= TABLE_COL0(last1 + 1);
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
                                    der_y = der_y1*der_u1 + der_y2*der_u2;
                                 }
                                 break;

                            case FRITSCH_BUTLAND_MONOTONE_C1:
                            case STEFFEN_MONOTONE_C1:
                                ModelicaError("Bivariate monotone C1 interpolation is "
                                    "not implemented\n");
                                return der_y;

                            default:
                                ModelicaError("Unknown smoothness kind\n");
                                return der_y;
                        }
                    }
                    else if (extrapolate2 == LEFT) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(last1, 0, nCol - 2)];
                                            double der_y1, der_y2;
                                            u1 -= TABLE_COL0(last1 + 1);
                                            u2 -= u2Min;
                                            der_y1 = (3*c[3]*u1 + 2*c[7])*u1 + c[11];
                                            der_y1 += ((3*c[2]*u1 + 2*c[6])*u1 + c[10])*u2;
                                            der_y2 = ((c[2]*u1 + c[6])*u1 + c[10])*u1 + c[14];
                                            der_y = der_y1*der_u1 + der_y2*der_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u2 "
                                    "(=%lf) must be greater or equal\nthan the minimum abscissa "
                                    "value u_min[2] (=%lf) defined in the table.\n", u2, u2Min);
                                return der_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der_y;
                        }
                    }
                    else /* if (extrapolate2 == RIGHT) */ {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(last1, nCol - 3, nCol - 2)];
                                            double der_y1, der_y2;
                                            const double v2 = u2Max - TABLE_ROW0(nCol - 2);
                                            double p1, p2, p3;
                                            double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                            u1 -= TABLE_COL0(last1 + 1);
                                            u2 -= u2Max;
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
                                            der_y = der_y1*der_u1 + der_y2*der_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u2 "
                                    "(=%lf) must be less or equal\nthan the maximum abscissa "
                                    "value u_max[2] (=%lf) defined in the table.\n", u2, u2Max);
                                return der_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der_y;
                        }
                    }
                }
                else if (extrapolate1 == LEFT) {
                    if (extrapolate2 == IN_TABLE) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(0, last2, nCol - 2)];
                                            double der_y1, der_y2;
                                            u1 -= u1Min;
                                            u2 -= TABLE_ROW0(last2 + 1);
                                            der_y1 = ((c[8]*u2 + c[9])*u2 + c[10])*u2 + c[11];
                                            der_y2 = (3*c[12]*u2 + 2*c[13])*u2 + c[14];
                                            der_y2 += ((3*c[8]*u2 + 2*c[9])*u2 + c[10])*u1;
                                            der_y = der_y1*der_u1 + der_y2*der_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be greater or equal\nthan the minimum abscissa "
                                    "value u_min[1] (=%lf) defined in the table.\n", u1, u1Min);
                                return der_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der_y;
                        }
                    }
                    else if (extrapolate2 == LEFT) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(0, 0, nCol - 2)];
                                            u1 -= u1Min;
                                            u2 -= u2Min;
                                            der_y = (c[11] + c[10]*u2)*der_u1;
                                            der_y += (c[14] + c[10]*u1)*der_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be greater or equal\nthan the minimum abscissa "
                                    "value u_min[1] (=%lf) defined in the table.\n"
                                    "Extrapolation error: The value u2 (=%lf) must be greater "
                                    "or equal\nthan the minimum abscissa value u_min[2] (=%lf) "
                                    "defined in the table.\n", u1, u1Min, u2, u2Min);
                                return der_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der_y;
                        }
                    }
                    else /* if (extrapolate2 == RIGHT) */ {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(0, nCol - 3, nCol - 2)];
                                            const double v2 = u2Max - TABLE_ROW0(nCol - 2);
                                            double der_y1, der_y2, der_y12;
                                            u1 -= u1Min;
                                            u2 -= u2Max;
                                            der_y1 = ((c[8]*v2 + c[9])*v2 + c[10])*v2 + c[11];
                                            der_y2 =(3*c[12]*v2 + 2*c[13])*v2 + c[14];
                                            der_y12 = (3*c[8]*v2 + 2*c[9])*v2 + c[10];
                                            der_y = (der_y1 + der_y12*u2)*der_u1;
                                            der_y += (der_y2 + der_y12*u1)*der_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be greater or equal\nthan the minimum abscissa "
                                    "value u_min[1] (=%lf) defined in the table.\n"
                                    "Extrapolation error: The value u2 (=%lf) must be less "
                                    "or equal\nthan the maximum abscissa value u_max[2] (=%lf) "
                                    "defined in the table.\n", u1, u1Min, u2, u2Max);
                                return der_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der_y;
                        }
                    }
                }
                else /* if (extrapolate1 == RIGHT) */ {
                    if (extrapolate2 == IN_TABLE) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(nRow - 3, last2, nCol - 2)];
                                            const double v1 = u1Max - TABLE_COL0(nRow - 2);
                                            double p1, p2, p3;
                                            double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                            double der_y1, der_y2;
                                            u1 -= u1Max;
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
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be less or equal\nthan the maximum abscissa "
                                    "value u_max[1] (=%lf) defined in the table.\n", u1, u1Max);
                                return der_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der_y;
                        }
                    }
                    else if (extrapolate2 == LEFT) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(nRow - 3, 0, nCol - 2)];
                                            const double v1 = u1Max - TABLE_COL0(nRow - 2);
                                            double der_y1, der_y2, der_y12;
                                            u1 -= u1Max;
                                            u2 -= u2Min;
                                            der_y1 = (3*c[3]*v1 + 2*c[7])*v1 + c[11];
                                            der_y2 = ((c[2]*v1 + c[6])*v1 + c[10])*v1 + c[14];
                                            der_y12 = (3*c[2]*v1 + 2*c[6])*v1 + c[10];
                                            der_y = (der_y1 + der_y12*u2)*der_u1;
                                            der_y += (der_y2 + der_y12*u1)*der_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be less or equal\nthan the maximum abscissa "
                                    "value u_max[1] (=%lf) defined in the table.\n"
                                    "Extrapolation error: The value u2 (=%lf) must be greater "
                                    "or equal\nthan the minimum abscissa value u_min[2] (=%lf) "
                                    "defined in the table.\n", u1, u1Max, u2, u2Min);
                                return der_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der_y;
                        }
                    }
                    else /* if (extrapolate2 == RIGHT) */ {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(nRow - 3, nCol - 3, nCol - 2)];
                                            const double v1 = u1Max - TABLE_COL0(nRow - 2);
                                            const double v2 = u2Max - TABLE_ROW0(nCol - 2);
                                            double p1, p2, p3;
                                            double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                            double der_y1, der_y2, der_y12;
                                            u1 -= u1Max;
                                            u2 -= u2Max;
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
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be less or equal\nthan the maximum abscissa "
                                    "value u_max[1] (=%lf) defined in the table.\n"
                                    "Extrapolation error: The value u2 (=%lf) must be less "
                                    "or equal\nthan the maximum abscissa value u_max[2] (=%lf) "
                                    "defined in the table.\n", u1, u1Max, u2, u2Max);
                                return der_y;

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
    }
    return der_y;
}

double ModelicaStandardTables_CombiTable2D_getDer2Value(void* _tableID, double u1,
                                                       double u2, double der_u1,
                                                       double der_u2, double der2_u1,
                                                       double der2_u2) {
    double der2_y = 0;
    CombiTable2D* tableID = (CombiTable2D*)_tableID;
    if (NULL != tableID && NULL != tableID->table) {
        const double* table = tableID->table;
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        const double u1Min = TABLE_COL0(1);
        const double u1Max = TABLE_COL0(nRow - 1);
        const double u2Min = TABLE_ROW0(1);
        const double u2Max = TABLE_ROW0(nCol - 1);

        if (nRow == 2) {
            if (nCol > 2) {
                enum PointInterval extrapolate2 = IN_TABLE;
                size_t last2;

                /* Periodic extrapolation */
                if (tableID->extrapolation == PERIODIC) {
                    const double T = u2Max - u2Min;

                    if (u2 < u2Min) {
                        do {
                            u2 += T;
                        } while (u2 < u2Min);
                    }
                    else if (u2 > u2Max) {
                        do {
                            u2 -= T;
                        } while (u2 > u2Max);
                    }
                    last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                        tableID->last2, u2);
                    tableID->last2 = last2;
                }
                else if (u2 < u2Min) {
                    extrapolate2 = LEFT;
                    last2 = 0;
                }
                else if (u2 > u2Max) {
                    extrapolate2 = RIGHT;
                    last2 = nCol - 3;
                }
                else {
                    last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                        tableID->last2, u2);
                    tableID->last2 = last2;
                }

                if (extrapolate2 == IN_TABLE) {
                    switch (tableID->smoothness) {
                        case LINEAR_SEGMENTS:
                            der2_y = (TABLE(1, last2 + 2) - TABLE(1, last2 + 1))/
                                (TABLE_ROW0(last2 + 2) - TABLE_ROW0(last2 + 1));
                            der2_y *= der2_u2;
                            break;

                        case CONSTANT_SEGMENTS:
                            break;

                        case AKIMA_C1:
                            if (NULL != tableID->spline) {
                                const double* c = tableID->spline[last2];
                                const double u20 = TABLE_ROW0(last2 + 1);
                                u2 -= u20;
                                der2_y = (3*c[0]*u2 + 2*c[1])*u2 + c[2];
                                der2_y *= der2_u2;
                                der2_y += (6*c[0]*u2 + 2*c[1])*der_u2*der_u2;
                            }
                            break;

                        case FRITSCH_BUTLAND_MONOTONE_C1:
                        case STEFFEN_MONOTONE_C1:
                            ModelicaError("Bivariate monotone C1 interpolation is "
                                "not implemented\n");
                            return der2_y;

                        default:
                            ModelicaError("Unknown smoothness kind\n");
                            return der2_y;
                    }
                }
                else {
                    /* Extrapolation */
                    switch (tableID->extrapolation) {
                        case LAST_TWO_POINTS:
                            switch (tableID->smoothness) {
                                case LINEAR_SEGMENTS:
                                case CONSTANT_SEGMENTS:
                                    der2_y = (TABLE(1, last2 + 2) - TABLE(1, last2 + 1))/
                                        (TABLE_ROW0(last2 + 2) - TABLE_ROW0(last2 + 1));
                                    der2_y *= der2_u2;
                                    break;

                                case AKIMA_C1:
                                    if (NULL != tableID->spline) {
                                        const double* c = tableID->spline[last2];
                                        if (extrapolate2 == LEFT) {
                                            der2_y = c[2];
                                        }
                                        else /* if (extrapolate2 == RIGHT) */ {
                                            const double u20 = TABLE_ROW0(last2 + 1);
                                            const double u21 = TABLE_ROW0(last2 + 2);
                                            der2_y = u21 - u20;
                                            der2_y = (3*c[0]*der2_y + 2*c[1])*der2_y + c[2];
                                        }
                                        der2_y *= der2_u2;
                                    }
                                    break;

                                case FRITSCH_BUTLAND_MONOTONE_C1:
                                case STEFFEN_MONOTONE_C1:
                                    ModelicaError("Bivariate monotone C1 interpolation is "
                                        "not implemented\n");
                                    return der2_y;

                                default:
                                    ModelicaError("Unknown smoothness kind\n");
                                    return der2_y;
                            }
                            break;

                        case HOLD_LAST_POINT:
                            break;

                        case NO_EXTRAPOLATION:
                            ModelicaFormatError("Extrapolation error: The value u2 "
                                "(=%lf) must be %s or equal\nthan the %s abscissa "
                                "value %s (=%lf) defined in the table.\n", u2,
                                (extrapolate2 == LEFT) ? "greater" : "less",
                                (extrapolate2 == LEFT) ? "minimum" : "maximum",
                                (extrapolate2 == LEFT) ? "u_min[2]" : "u_max[2]",
                                (extrapolate2 == LEFT) ? u2Min : u2Max);
                            return der2_y;

                        case PERIODIC:
                            /* Should not be possible to get here */
                            break;

                        default:
                            ModelicaError("Unknown extrapolation kind\n");
                            return der2_y;
                    }
                }
            }
        }
        else if (nRow > 2) {
            enum PointInterval extrapolate1 = IN_TABLE;
            size_t last1;

            /* Periodic extrapolation */
            if (tableID->extrapolation == PERIODIC) {
                const double T = u1Max - u1Min;

                if (u1 < u1Min) {
                    do {
                        u1 += T;
                    } while (u1 < u1Min);
                }
                else if (u1 > u1Max) {
                    do {
                        u1 -= T;
                    } while (u1 > u1Max);
                }
                last1 = findRowIndex(&TABLE(1, 0), nRow - 1, nCol,
                    tableID->last1, u1);
                tableID->last1 = last1;
            }
            else if (u1 < u1Min) {
                extrapolate1 = LEFT;
                last1 = 0;
            }
            else if (u1 > u1Max) {
                extrapolate1 = RIGHT;
                last1 = nRow - 3;
            }
            else {
                last1 = findRowIndex(&TABLE(1, 0), nRow - 1, nCol,
                    tableID->last1, u1);
                tableID->last1 = last1;
            }
            if (nCol == 2) {
                if (extrapolate1 == IN_TABLE) {
                    switch (tableID->smoothness) {
                        case LINEAR_SEGMENTS:
                            der2_y = (TABLE(last1 + 2, 1) - TABLE(last1 + 1, 1))/
                                (TABLE_COL0(last1 + 2) - TABLE_COL0(last1 + 1));
                            der2_y *= der2_u1;
                            break;

                        case CONSTANT_SEGMENTS:
                            break;

                        case AKIMA_C1:
                            if (NULL != tableID->spline) {
                                const double* c = tableID->spline[last1];
                                const double u10 = TABLE_COL0(last1 + 1);
                                u1 -= u10;
                                der2_y = (3*c[0]*u1 + 2*c[1])*u1 + c[2];
                                der2_y *= der2_u1;
                                der2_y += (6*c[0]*u1 + 2*c[1])*der_u1*der_u1;
                            }
                            break;

                        case FRITSCH_BUTLAND_MONOTONE_C1:
                        case STEFFEN_MONOTONE_C1:
                            ModelicaError("Bivariate monotone C1 interpolation is "
                                "not implemented\n");
                            return der2_y;

                        default:
                            ModelicaError("Unknown smoothness kind\n");
                            return der2_y;
                    }
                }
                else {
                    /* Extrapolation */
                    switch (tableID->extrapolation) {
                        case LAST_TWO_POINTS:
                            switch (tableID->smoothness) {
                                case LINEAR_SEGMENTS:
                                case CONSTANT_SEGMENTS:
                                    der2_y = (TABLE(last1 + 2, 1) - TABLE(last1 + 1, 1))/
                                        (TABLE_COL0(last1 + 2) - TABLE_COL0(last1 + 1));
                                    der2_y *= der2_u1;
                                    break;

                                case AKIMA_C1:
                                    if (NULL != tableID->spline) {
                                        const double* c = tableID->spline[last1];
                                        if (extrapolate1 == LEFT) {
                                            der2_y = c[2];
                                        }
                                        else /* if (extrapolate1 == RIGHT) */ {
                                            const double u10 = TABLE_COL0(last1 + 1);
                                            const double u11 = TABLE_COL0(last1 + 2);
                                            der2_y = u11 - u10;
                                            der2_y = (3*c[0]*der2_y + 2*c[1])*der2_y + c[2];
                                        }
                                        der2_y *= der2_u1;
                                    }
                                    break;

                                case FRITSCH_BUTLAND_MONOTONE_C1:
                                case STEFFEN_MONOTONE_C1:
                                    ModelicaError("Bivariate monotone C1 interpolation is "
                                        "not implemented\n");
                                    return der2_y;

                                default:
                                    ModelicaError("Unknown smoothness kind\n");
                                    return der2_y;
                            }
                            break;

                        case HOLD_LAST_POINT:
                            break;

                        case NO_EXTRAPOLATION:
                            ModelicaFormatError("Extrapolation error: The value u1 "
                                "(=%lf) must be %s or equal\nthan the %s abscissa "
                                "value %s (=%lf) defined in the table.\n", u1,
                                (extrapolate1 == LEFT) ? "greater" : "less",
                                (extrapolate1 == LEFT) ? "minimum" : "maximum",
                                (extrapolate1 == LEFT) ? "u_min[1]" : "u_max[1]",
                                (extrapolate1 == LEFT) ? u1Min : u1Max);
                            return der2_y;

                        case PERIODIC:
                            /* Should not be possible to get here */
                            break;

                        default:
                            ModelicaError("Unknown extrapolation kind\n");
                            return der2_y;
                    }
                }
            }
            else if (nCol > 2) {
                enum PointInterval extrapolate2 = IN_TABLE;
                size_t last2;

                /* Periodic extrapolation */
                if (tableID->extrapolation == PERIODIC) {
                    const double T = u2Max - u2Min;

                    if (u2 < u2Min) {
                        do {
                            u2 += T;
                        } while (u2 < u2Min);
                    }
                    else if (u2 > u2Max) {
                        do {
                            u2 -= T;
                        } while (u2 > u2Max);
                    }
                    last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                        tableID->last2, u2);
                    tableID->last2 = last2;
                }
                else if (u2 < u2Min) {
                    extrapolate2 = LEFT;
                    last2 = 0;
                }
                else if (u2 > u2Max) {
                    extrapolate2 = RIGHT;
                    last2 = nCol - 3;
                }
                else {
                    last2 = findColIndex(&TABLE(0, 1), nCol - 1,
                        tableID->last2, u2);
                    tableID->last2 = last2;
                }

                if (extrapolate1 == IN_TABLE) {
                    if (extrapolate2 == IN_TABLE) {
                        switch (tableID->smoothness) {
                            case LINEAR_SEGMENTS:
                                BILINEAR_DER2(u1, u2);
                                break;

                            case CONSTANT_SEGMENTS:
                                break;

                            case AKIMA_C1:
                                if (NULL != tableID->spline) {
                                    const double* c = tableID->spline[
                                        IDX(last1, last2, nCol - 2)];
                                    double der_y1, der_y2, der2_y1, der2_y2;
                                    double p1, p2, p3;
                                    double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                    double d2p1_u2, d2p2_u2, d2p3_u2, d2p4_u2;
                                    u1 -= TABLE_COL0(last1 + 1);
                                    u2 -= TABLE_ROW0(last2 + 1);
                                    p1 = ((c[0]*u2 + c[1])*u2 + c[2])*u2 + c[3];
                                    p2 = ((c[4]*u2 + c[5])*u2 + c[6])*u2 + c[7];
                                    p3 = ((c[8]*u2 + c[9])*u2 + c[10])*u2 + c[11];
                                    dp1_u2 = (3*c[0]*u2 + 2*c[1])*u2 + c[2];
                                    dp2_u2 = (3*c[4]*u2 + 2*c[5])*u2 + c[6];
                                    dp3_u2 = (3*c[8]*u2 + 2*c[9])*u2 + c[10];
                                    dp4_u2 = (3*c[12]*u2 + 2*c[13])*u2 + c[14];
                                    d2p1_u2 = 6*c[0]*u2 + 2*c[1];
                                    d2p2_u2 = 6*c[4]*u2 + 2*c[5];
                                    d2p3_u2 = 6*c[8]*u2 + 2*c[9];
                                    d2p4_u2 = 6*c[12]*u2 + 2*c[13];
                                    der_y1 = (3*p1*u1 + 2*p2)*u1 + p3;
                                    der_y2 = ((dp1_u2*u1 + dp2_u2)*u1 + dp3_u2)*u1 + dp4_u2;
                                    der2_y1 = 6*p1*u1 + 2*p2;
                                    der2_y2 = ((d2p1_u2*u1 + d2p2_u2)*u1 + d2p3_u2)*u1 + d2p4_u2;
                                    der2_y = der2_y1*der_u1*der_u1 + der_y1*der2_u1;
                                    der2_y += ((6*dp1_u2*u1 + 4*dp2_u2)*u1 + 2*dp3_u2)*der_u1*der_u2;
                                    der2_y += der2_y2*der_u2*der_u2 + der_y2*der2_u2;
                                 }
                                 break;

                            case FRITSCH_BUTLAND_MONOTONE_C1:
                            case STEFFEN_MONOTONE_C1:
                                ModelicaError("Bivariate monotone C1 interpolation is "
                                    "not implemented\n");
                                return der2_y;

                            default:
                                ModelicaError("Unknown smoothness kind\n");
                                return der2_y;
                        }
                    }
                    else if (extrapolate2 == LEFT) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER2(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(last1, 0, nCol - 2)];
                                            double der_y1, der_y2, der2_y1;
                                            u1 -= TABLE_COL0(last1 + 1);
                                            u2 -= u2Min;
                                            der_y1 = (3*c[3]*u1 + 2*c[7])*u1 + c[11];
                                            der_y1 += ((3*c[2]*u1 + 2*c[6])*u1 + c[10])*u2;
                                            der_y2 = ((c[2]*u1 + c[6])*u1 + c[10])*u1 + c[14];
                                            der2_y1 = 2*(3*c[3]*u1 + c[7] + (3*c[2]*u1 + c[6]))*u2;
                                            der2_y = der2_y1*der_u1*der_u1 + der_y1*der2_u1;
                                            der2_y += 2*((3*c[2]*u1 + 2*c[6])*u1 + c[10])*der_u1*der_u2;
                                            der2_y += der_y2*der2_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der2_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der2_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u2 "
                                    "(=%lf) must be greater or equal\nthan the minimum abscissa "
                                    "value u_min[2] (=%lf) defined in the table.\n", u2, u2Min);
                                return der2_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der2_y;
                        }
                    }
                    else /* if (extrapolate2 == RIGHT) */ {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER2(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(last1, nCol - 3, nCol - 2)];
                                            double der_y1, der_y2;
                                            const double v2 = u2Max - TABLE_ROW0(nCol - 2);
                                            double p1, p2, p3;
                                            double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                            u1 -= TABLE_COL0(last1 + 1);
                                            u2 -= u2Max;
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
                                            der2_y = 2*(p2 + dp2_u2*u2 + 3*u1*(p1 + dp1_u2*u2))*der_u1*der_u1;
                                            der2_y += 2*(dp3_u2 + u1*(2*dp2_u2 + 3*dp1_u2*u1))*der_u1*der_u2;
                                            der2_y += der_y1*der2_u1 + der_y2*der2_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der2_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der2_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u2 "
                                    "(=%lf) must be less or equal\nthan the maximum abscissa "
                                    "value u_max[2] (=%lf) defined in the table.\n", u2, u2Max);
                                return der2_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der2_y;
                        }
                    }
                }
                else if (extrapolate1 == LEFT) {
                    if (extrapolate2 == IN_TABLE) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER2(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(0, last2, nCol - 2)];
                                            double der_y1, der_y2;
                                            u1 -= u1Min;
                                            u2 -= TABLE_ROW0(last2 + 1);
                                            der_y1 = ((c[8]*u2 + c[9])*u2 + c[10])*u2 + c[11];
                                            der_y2 = (3*c[12]*u2 + 2*c[13])*u2 + c[14];
                                            der_y2 += ((3*c[8]*u2 + 2*c[9])*u2 + c[10])*u1;
                                            der2_y = 2*((3*c[8]*u2 + 2*c[9])*u2 + c[10])*der_u1*der_u2;
                                            der2_y += 2*(c[13] + c[9]*u1 + 3*(c[12] + c[8]*u1)*u2)*der_u2*der_u2;
                                            der2_y += der_y1*der2_u1 + der_y2*der2_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der2_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der2_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be greater or equal\nthan the minimum abscissa "
                                    "value u_min[1] (=%lf) defined in the table.\n", u1, u1Min);
                                return der2_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der2_y;
                        }
                    }
                    else if (extrapolate2 == LEFT) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER2(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(0, 0, nCol - 2)];
                                            u1 -= u1Min;
                                            u2 -= u2Min;
                                            der2_y = 2*c[10]*der_u1*der_u2;
                                            der2_y += (c[11] + c[10]*u2)*der2_u1;
                                            der2_y += (c[14] + c[10]*u1)*der2_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der2_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der2_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be greater or equal\nthan the minimum abscissa "
                                    "value u_min[1] (=%lf) defined in the table.\n"
                                    "Extrapolation error: The value u2 (=%lf) must be greater "
                                    "or equal\nthan the minimum abscissa value u_min[2] (=%lf) "
                                    "defined in the table.\n", u1, u1Min, u2, u2Min);
                                return der2_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der2_y;
                        }
                    }
                    else /* if (extrapolate2 == RIGHT) */ {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER2(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(0, nCol - 3, nCol - 2)];
                                            const double v2 = u2Max - TABLE_ROW0(nCol - 2);
                                            double der_y1, der_y2, der_y12;
                                            u1 -= u1Min;
                                            u2 -= u2Max;
                                            der_y1 = ((c[8]*v2 + c[9])*v2 + c[10])*v2 + c[11];
                                            der_y2 =(3*c[12]*v2 + 2*c[13])*v2 + c[14];
                                            der_y12 = (3*c[8]*v2 + 2*c[9])*v2 + c[10];
                                            der2_y = 2*der_y12*der_u1*der_u2;
                                            der2_y += (der_y1 + der_y12*u2)*der2_u1;
                                            der2_y += (der_y2 + der_y12*u1)*der2_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der2_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der2_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be greater or equal\nthan the minimum abscissa "
                                    "value u_min[1] (=%lf) defined in the table.\n"
                                    "Extrapolation error: The value u2 (=%lf) must be less "
                                    "or equal\nthan the maximum abscissa value u_max[2] (=%lf) "
                                    "defined in the table.\n", u1, u1Min, u2, u2Max);
                                return der2_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der2_y;
                        }
                    }
                }
                else /* if (extrapolate1 == RIGHT) */ {
                    if (extrapolate2 == IN_TABLE) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER2(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(nRow - 3, last2, nCol - 2)];
                                            const double v1 = u1Max - TABLE_COL0(nRow - 2);
                                            double p1, p2, p3;
                                            double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                            double der_y1, der_y2;
                                            u1 -= u1Max;
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
                                            der2_y = 2*(c[10] + v1*(2*c[6] + 3*c[2]*v1) +
                                                2*(c[9] + v1*(2*c[5] + 3*c[1]*v1))*u2 +
                                                3*(c[8] + v1*(2*c[4] + 3*c[0]*v1))*u2*u2)*der_u1*der_u2;
                                            der2_y += 2*(c[13] + v1*(c[9] + v1*(c[5] + c[1]*v1)) +
                                                3*(c[12] + v1*(c[8] + v1*(c[4] + c[0]*v1)))*u2 +
                                                u1*(c[9] + v1*(2*c[5] + 3*c[1]*v1) +
                                                3*(c[8] + v1*(2*c[4] + 3*c[0]*v1))*u2))*der_u2*der_u2;
                                            der2_y += der_y1*der2_u1 + der_y2*der2_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der2_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der2_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be less or equal\nthan the maximum abscissa "
                                    "value u_max[1] (=%lf) defined in the table.\n", u1, u1Max);
                                return der2_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der2_y;
                        }
                    }
                    else if (extrapolate2 == LEFT) {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER2(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(nRow - 3, 0, nCol - 2)];
                                            const double v1 = u1Max - TABLE_COL0(nRow - 2);
                                            double der_y1, der_y2, der_y12;
                                            u1 -= u1Max;
                                            u2 -= u2Min;
                                            der_y1 = (3*c[3]*v1 + 2*c[7])*v1 + c[11];
                                            der_y2 = ((c[2]*v1 + c[6])*v1 + c[10])*v1 + c[14];
                                            der_y12 = (3*c[2]*v1 + 2*c[6])*v1 + c[10];
                                            der2_y = 2*der_y12*der_u1*der_u2;
                                            der2_y += (der_y1 + der_y12*u2)*der2_u1;
                                            der2_y += (der_y2 + der_y12*u1)*der2_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der2_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der2_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be less or equal\nthan the maximum abscissa "
                                    "value u_max[1] (=%lf) defined in the table.\n"
                                    "Extrapolation error: The value u2 (=%lf) must be greater "
                                    "or equal\nthan the minimum abscissa value u_min[2] (=%lf) "
                                    "defined in the table.\n", u1, u1Max, u2, u2Min);
                                return der2_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der2_y;
                        }
                    }
                    else /* if (extrapolate2 == RIGHT) */ {
                        switch (tableID->extrapolation) {
                            case LAST_TWO_POINTS:
                                switch (tableID->smoothness) {
                                    case LINEAR_SEGMENTS:
                                    case CONSTANT_SEGMENTS:
                                        BILINEAR_DER2(u1, u2);
                                        break;

                                    case AKIMA_C1:
                                        if (NULL != tableID->spline) {
                                            const double* c = tableID->spline[
                                                IDX(nRow - 3, nCol - 3, nCol - 2)];
                                            const double v1 = u1Max - TABLE_COL0(nRow - 2);
                                            const double v2 = u2Max - TABLE_ROW0(nCol - 2);
                                            double p1, p2, p3;
                                            double dp1_u2, dp2_u2, dp3_u2, dp4_u2;
                                            double der_y1, der_y2, der_y12;
                                            u1 -= u1Max;
                                            u2 -= u2Max;
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
                                            der2_y = 2*der_y12*der_u1*der_u2;
                                            der2_y += (der_y1 + der_y12*u2)*der2_u1;
                                            der2_y += (der_y2 + der_y12*u1)*der2_u2;
                                         }
                                         break;

                                    case FRITSCH_BUTLAND_MONOTONE_C1:
                                    case STEFFEN_MONOTONE_C1:
                                        ModelicaError("Bivariate monotone C1 interpolation is "
                                            "not implemented\n");
                                        return der2_y;

                                    default:
                                        ModelicaError("Unknown smoothness kind\n");
                                        return der2_y;
                                 }
                                 break;

                            case HOLD_LAST_POINT:
                                break;

                            case NO_EXTRAPOLATION:
                                ModelicaFormatError("Extrapolation error: The value u1 "
                                    "(=%lf) must be less or equal\nthan the maximum abscissa "
                                    "value u_max[1] (=%lf) defined in the table.\n"
                                    "Extrapolation error: The value u2 (=%lf) must be less "
                                    "or equal\nthan the maximum abscissa value u_max[2] (=%lf) "
                                    "defined in the table.\n", u1, u1Max, u2, u2Max);
                                return der2_y;

                            case PERIODIC:
                                /* Should not be possible to get here */
                                break;

                            default:
                                ModelicaError("Unknown extrapolation kind\n");
                                return der2_y;
                        }
                    }
                }
            }
        }
    }
    return der2_y;
}

void ModelicaStandardTables_CombiTable2D_minimumAbscissa(void* _tableID,
                                                         _Inout_ double* uMin) {
    CombiTable2D* tableID = (CombiTable2D*)_tableID;
    if (NULL != tableID && NULL != tableID->table) {
        const double* table = tableID->table;
        const size_t nCol = tableID->nCol;
        uMin[0] = TABLE_COL0(1);
        uMin[1] = TABLE_ROW0(1);
    }
    else {
        uMin[0] = 0.;
        uMin[1] = 0.;
    }
}

void ModelicaStandardTables_CombiTable2D_maximumAbscissa(void* _tableID,
                                                         _Inout_ double* uMax) {
    CombiTable2D* tableID = (CombiTable2D*)_tableID;
    if (NULL != tableID && NULL != tableID->table) {
        const double* table = tableID->table;
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        uMax[0] = TABLE_COL0(nRow - 1);
        uMax[1] = TABLE_ROW0(nCol - 1);
    }
    else {
        uMax[0] = 0.;
        uMax[1] = 0.;
    }
}

double ModelicaStandardTables_CombiTable2D_read(void* _tableID, int force,
                                                int verbose) {
#if !defined(NO_FILE_SYSTEM)
    CombiTable2D* tableID = (CombiTable2D*)_tableID;
    if (NULL != tableID && tableID->source == TABLESOURCE_FILE) {
        if (force || NULL == tableID->table) {
            const char* fileName = tableID->key;
            const char* tableName = tableID->key + strlen(fileName) + 1;
#if defined(TABLE_SHARE)
            TableShare* file = readTable(fileName, tableName, &tableID->nRow,
                &tableID->nCol, verbose, force);
            if (NULL != file) {
                tableID->table = file->table;
            }
            else {
                return 0.; /* Error */
            }
#else
            if (NULL != tableID->table) {
                free(tableID->table);
            }
            tableID->table = readTable(fileName, tableName, &tableID->nRow,
                &tableID->nCol, verbose, force);
#endif
            if (NULL == tableID->table) {
                return 0.; /* Error */
            }
            if (isValidCombiTable2D(tableID, tableName, NO_CLEANUP) == 0) {
                return 0.; /* Error */
            }
            if (tableID->smoothness == AKIMA_C1 &&
                tableID->nRow <= 3 && tableID->nCol <= 3) {
                tableID->smoothness = LINEAR_SEGMENTS;
            }
            /* Reinitialization of the Akima-spline coefficients */
            if (tableID->smoothness == AKIMA_C1) {
                spline2DClose(&tableID->spline);
                tableID->spline = spline2DInit((const double*)tableID->table,
                    tableID->nRow,tableID->nCol);
                if (NULL == tableID->spline) {
                    ModelicaError("Memory allocation error\n");
                    return 0.; /* Error */
                }
            }
        }
    }
#endif
    return 1.; /* Success */
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

static size_t findColIndex(_In_ const double* table, size_t nCol, size_t last,
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

static int isValidName(_In_z_ const char* name) {
    int isValid = 0;
    if (NULL != name) {
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

static int isValidCombiTimeTable(CombiTimeTable* tableID,
                                 _In_z_ const char* _tableName, enum CleanUp cleanUp) {
    int isValid = 1;
    if (NULL != tableID) {
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        const char* tableDummyName = "NoName";
        const char* tableName = _tableName[0] != '\0' ? _tableName : tableDummyName;
        size_t iCol;

        /* Check dimensions */
        if (nRow < 1 || nCol < 2) {
            if (DO_CLEANUP == cleanUp) {
                ModelicaStandardTables_CombiTimeTable_close(tableID);
            }
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
                if (DO_CLEANUP == cleanUp) {
                    ModelicaStandardTables_CombiTimeTable_close(tableID);
                }
                ModelicaFormatError("The column index %d is out of range "
                    "for table matrix \"%s(%lu,%lu)\".\n", tableID->cols[iCol],
                    tableName, (unsigned long)nRow, (unsigned long)nCol);
            }
        }

        if (NULL != tableID->table && nRow > 1) {
            const double* table = tableID->table;
            /* Check period */
            if (tableID->extrapolation == PERIODIC) {
                const double tMin = TABLE_ROW0(0);
                const double tMax = TABLE_COL0(nRow - 1);
                const double T = tMax - tMin;
                if (T <= 0) {
                    if (DO_CLEANUP == cleanUp) {
                        ModelicaStandardTables_CombiTimeTable_close(tableID);
                    }
                    ModelicaFormatError(
                        "Table matrix \"%s\" does not have a positive period/cycle "
                        "time for time interpolation with periodic "
                        "extrapolation.\n", tableName);
                    isValid = 0;
                    return isValid;
                }
            }

            /* Check, whether first column values are monotonically or strictly
               increasing */
            if (tableID->smoothness == AKIMA_C1 ||
                tableID->smoothness == FRITSCH_BUTLAND_MONOTONE_C1 ||
                tableID->smoothness == STEFFEN_MONOTONE_C1) {
                size_t i;
                for (i = 0; i < nRow - 1; i++) {
                    double t0 = TABLE_COL0(i);
                    double t1 = TABLE_COL0(i + 1);
                    if (t0 >= t1) {
                        if (DO_CLEANUP == cleanUp) {
                            ModelicaStandardTables_CombiTimeTable_close(tableID);
                        }
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
                        if (DO_CLEANUP == cleanUp) {
                            ModelicaStandardTables_CombiTimeTable_close(tableID);
                        }
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

static int isValidCombiTable1D(CombiTable1D* tableID,
                               _In_z_ const char* _tableName, enum CleanUp cleanUp) {
    int isValid = 1;
    if (NULL != tableID) {
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        const char* tableDummyName = "NoName";
        const char* tableName = _tableName[0] != '\0' ? _tableName : tableDummyName;
        size_t iCol;

        /* Check dimensions */
        if (nRow < 1 || nCol < 2) {
            if (DO_CLEANUP == cleanUp) {
                ModelicaStandardTables_CombiTable1D_close(tableID);
            }
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
                if (DO_CLEANUP == cleanUp) {
                    ModelicaStandardTables_CombiTable1D_close(tableID);
                }
                ModelicaFormatError("The column index %d is out of range "
                    "for table matrix \"%s(%lu,%lu)\".\n", tableID->cols[iCol],
                    tableName, (unsigned long)nRow, (unsigned long)nCol);
            }
        }

        if (NULL != tableID->table) {
            const double* table = tableID->table;
            size_t i;
            /* Check, whether first column values are strictly increasing */
            for (i = 0; i < nRow - 1; i++) {
                double x0 = TABLE_COL0(i);
                double x1 = TABLE_COL0(i + 1);
                if (x0 >= x1) {
                    if (DO_CLEANUP == cleanUp) {
                        ModelicaStandardTables_CombiTable1D_close(tableID);
                    }
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

static int isValidCombiTable2D(CombiTable2D* tableID,
                               _In_z_ const char* _tableName, enum CleanUp cleanUp) {
    int isValid = 1;
    if (NULL != tableID) {
        const size_t nRow = tableID->nRow;
        const size_t nCol = tableID->nCol;
        const char* tableDummyName = "NoName";
        const char* tableName = _tableName[0] != '\0' ? _tableName : tableDummyName;

        /* Check dimensions */
        if (nRow < 2 || nCol < 2) {
            if (DO_CLEANUP == cleanUp) {
                ModelicaStandardTables_CombiTable2D_close(tableID);
            }
            ModelicaFormatError(
                "Table matrix \"%s(%lu,%lu)\" does not have appropriate "
                "dimensions for 2D-interpolation.\n", tableName,
                (unsigned long)nRow, (unsigned long)nCol);
            isValid = 0;
            return isValid;
        }

        if (NULL != tableID->table) {
            const double* table = tableID->table;
            size_t i;
            /* Check, whether first column values are strictly increasing */
            for (i = 1; i < nRow - 1; i++) {
                double x0 = TABLE_COL0(i);
                double x1 = TABLE_COL0(i + 1);
                if (x0 >= x1) {
                    if (DO_CLEANUP == cleanUp) {
                        ModelicaStandardTables_CombiTable2D_close(tableID);
                    }
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
                    if (DO_CLEANUP == cleanUp) {
                        ModelicaStandardTables_CombiTable2D_close(tableID);
                    }
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

static enum TableSource getTableSource(_In_z_ const char* fileName,
                                       _In_z_ const char* tableName) {
    enum TableSource tableSource;
    int fileNameGiven = isValidName(fileName);
    int tableNameGiven = isValidName(tableName);

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

static CubicHermite1D* akimaSpline1DInit(_In_ const double* table, size_t nRow,
                                         size_t nCol, _In_ const int* cols,
                                         size_t nCols) {
  /* Reference:

     Hiroshi Akima. A new method of interpolation and smooth curve fitting
     based on local procedures. Journal of the ACM, 17(4), 589-602, Oct. 1970.
     (https://dx.doi.org/10.1145/321607.321609)
  */

    CubicHermite1D* spline = NULL;
    double* d; /* Divided differences */
    size_t col;

    /* Actually there is no need for consecutive memory */
    spline = (CubicHermite1D*)malloc((nRow - 1)*nCols*sizeof(CubicHermite1D));
    if (NULL == spline) {
        return NULL;
    }

    d = (double*)malloc((nRow + 3)*sizeof(double));
    if (NULL == d) {
        free(spline);
        return NULL;
    }

    for (col = 0; col < nCols; col++) {
        size_t i;
        double c2;

        /* Calculation of the divided differences */
        for (i = 0; i < nRow - 1; i++) {
            size_t c = (size_t)(cols[col] - 1);
            d[i + 2] = (TABLE(i + 1, c) - TABLE(i, c))/
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

static CubicHermite1D* fritschButlandSpline1DInit(_In_ const double* table,
                                                  size_t nRow, size_t nCol,
                                                  _In_ const int* cols,
                                                  size_t nCols) {
  /* Reference:

     Frederick N. Fritsch and Judy Butland. A method for constructing local
     monotone piecewise cubic interpolants. SIAM Journal on Scientific and
     Statistical Computing, 5(2), 300-304, June 1984.
     (https://dx.doi.org/10.1137/0905021)
  */

    CubicHermite1D* spline = NULL;
    double* d; /* Divided differences */
    size_t col;

    /* Actually there is no need for consecutive memory */
    spline = (CubicHermite1D*)malloc((nRow - 1)*nCols*sizeof(CubicHermite1D));
    if (NULL == spline) {
        return NULL;
    }

    d = (double*)malloc((nRow - 1)*sizeof(double));
    if (NULL == d) {
        free(spline);
        return NULL;
    }

    for (col = 0; col < nCols; col++) {
        size_t i;
        double c2;

        /* Calculation of the divided differences */
        for (i = 0; i < nRow - 1; i++) {
            size_t c = (size_t)(cols[col] - 1);
            d[i] = (TABLE(i + 1, c) - TABLE(i, c))/
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
            else if (d[i] == 0 || d[i + 1] == 0 ||
                (d[i] < 0 && d[i + 1] > 0) || (d[i] > 0 && d[i + 1] < 0)) {
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

static CubicHermite1D* steffenSpline1DInit(_In_ const double* table,
                                           size_t nRow, size_t nCol,
                                           _In_ const int* cols,
                                           size_t nCols) {
  /* Reference:

     Matthias Steffen. A simple method for monotonic interpolation in one
     dimension. Astronomy and Astrophysics, 239, 443-450, Nov. 1990.
     (https://ui.adsabs.harvard.edu/#abs/1990A&A...239..443S)
  */

    CubicHermite1D* spline = NULL;
    double* d; /* Divided differences */
    size_t col;

    /* Actually there is no need for consecutive memory */
    spline = (CubicHermite1D*)malloc((nRow - 1)*nCols*sizeof(CubicHermite1D));
    if (NULL == spline) {
        return NULL;
    }

    d = (double*)malloc((nRow - 1)*sizeof(double));
    if (NULL == d) {
        free(spline);
        return NULL;
    }

    for (col = 0; col < nCols; col++) {
        size_t i;
        double c2;

        /* Calculation of the divided differences */
        for (i = 0; i < nRow - 1; i++) {
            size_t c = (size_t)(cols[col] - 1);
            d[i] = (TABLE(i + 1, c) - TABLE(i, c))/
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
            else if (d[i] == 0 || d[i + 1] == 0 ||
                (d[i] < 0 && d[i + 1] > 0) || (d[i] > 0 && d[i + 1] < 0)) {
                c2 = 0;
            }
            else {
                const double dx_ = TABLE_COL0(i + 2) - TABLE_COL0(i + 1);
                double half_abs_c2, abs_di, abs_di1;
                c2 = (d[i]*dx_ + d[i + 1]*dx)/(dx + dx_);
                half_abs_c2 = 0.5*fabs(c2);
                abs_di = fabs(d[i]);
                abs_di1 = fabs(d[i + 1]);
                if (half_abs_c2 > abs_di || half_abs_c2 > abs_di1) {
                    const double two_a = d[i] > 0 ? 2 : -2;
                    c2 = two_a*(abs_di < abs_di1 ? abs_di : abs_di1);
                }
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
    if (NULL != spline && NULL != *spline) {
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

static CubicHermite2D* spline2DInit(_In_ const double* table, size_t nRow,
                                    size_t nCol) {
  /* Reference:

     Hiroshi Akima. A method of bivariate interpolation and smooth surface
     fitting based on local procedures. Communications of the ACM, 17(1), 18-20,
     Jan. 1974. (http://dx.doi.org/10.1145/360767.360779)
  */

#define TABLE_EX(i, j) tableEx[IDX(i, j, nCol + 3)]
    CubicHermite2D* spline = NULL;
    if (nRow == 2 /* && nCol > 3 */) {
        CubicHermite1D* spline1D;
        size_t j;
        int cols = 2;

        /* Need to transpose */
        double* tableT = (double*)malloc(2*(nCol - 1)*sizeof(double));
        if (NULL == tableT) {
            return NULL;
        }

        spline = (CubicHermite2D*)malloc((nCol - 1)*sizeof(CubicHermite2D));
        if (NULL == spline) {
            free(tableT);
            return NULL;
        }

        for (j = 1; j < nCol; j++) {
            tableT[IDX(j - 1, 0, 2)] = TABLE_ROW0(j);
            tableT[IDX(j - 1, 1, 2)] = TABLE(1, j);
        }

        spline1D = akimaSpline1DInit(tableT, nCol - 1, 2, &cols, 1);
        free(tableT);
        if (NULL == spline1D) {
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
        if (NULL == spline) {
            return NULL;
        }

        spline1D = akimaSpline1DInit(&table[2], nRow - 1, 2, &cols, 1);
        if (NULL == spline1D) {
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
        if (NULL == x) {
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
        if (NULL == y) {
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
        if (NULL == tableEx) {
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
        if (NULL == dz_dx) {
            free(tableEx);
            free(y);
            free(x);
            return NULL;
        }

        dz_dy = (double*)malloc((nRow - 1)*(nCol - 1)*sizeof(double));
        if (NULL == dz_dy) {
            free(dz_dx);
            free(tableEx);
            free(y);
            free(x);
            return NULL;
        }

        d2z_dxdy = (double*)malloc((nRow - 1)*(nCol - 1)*sizeof(double));
        if (NULL == d2z_dxdy) {
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
        if (NULL == spline) {
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
#undef TABLE_EX
}

static void spline2DClose(CubicHermite2D** spline) {
    if (NULL != spline && NULL != *spline) {
        free(*spline);
        *spline = NULL;
    }
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

/* ----- Internal I/O functions ----- */

#if defined(TABLE_SHARE) && !defined(NO_FILE_SYSTEM)
static size_t key_strlen(_In_z_ const char *s) {
    size_t len = strlen(s) + 1;
    len += strlen(s + len);
    return len;
}
#endif

static READ_RESULT readTable(_In_z_ const char* fileName, _In_z_ const char* tableName,
                             _Inout_ size_t* nRow, _Inout_ size_t* nCol, int verbose,
                             int force) {
#if !defined(NO_FILE_SYSTEM)
#if defined(TABLE_SHARE)
    TableShare* file = NULL;
#endif
    double* table = NULL;
    if (NULL != tableName && NULL != fileName && NULL != nRow && NULL != nCol) {
#if defined(TABLE_SHARE)
        size_t lenFileName = strlen(fileName);
        char* key = (char*)malloc((lenFileName + strlen(tableName) + 2)*sizeof(char));
        if (NULL != key) {
            int updateError = 0;
            strcpy(key, fileName);
            strcpy(key + lenFileName + 1, tableName);
            MUTEX_LOCK();
            HASH_FIND_STR(tableShare, key, file);
            if (NULL == file || force) {
                /* Release resources since ModelicaIO_readRealTable may fail with
                   ModelicaError
                */
                MUTEX_UNLOCK();
                free(key);
#endif
                table = ModelicaIO_readRealTable(fileName, tableName,
                    nRow, nCol, verbose);
                if (NULL == table) {
#if defined(TABLE_SHARE)
                    return file;
#else
                    return table;
#endif
                }
#if defined(TABLE_SHARE)
                /* Again allocate and set key */
                key = (char*)malloc((lenFileName + strlen(tableName) + 2) * sizeof(char));
                if (NULL == key) {
                    ModelicaIO_freeRealTable(table);
                    return file;
                }
                strcpy(key, fileName);
                strcpy(key + lenFileName + 1, tableName);
                /* Again ask for lock and search in hash table share */
                MUTEX_LOCK();
                HASH_FIND_STR(tableShare, key, file);
            }
            if (NULL == file) {
                /* Share miss -> Insert new table */
                file = (TableShare*)malloc(sizeof(TableShare));
                if (NULL != file) {
                    size_t lenKey = key_strlen(key);
                    file->key = key;
                    file->refCount = 1;
                    file->nRow = *nRow;
                    file->nCol = *nCol;
                    file->table = table;
                    HASH_ADD_KEYPTR(hh, tableShare, key, lenKey, file);
                    if (NULL == file->hh.tbl) {
                        free(key);
                        free(file);
                        ModelicaIO_freeRealTable(table);
                        MUTEX_UNLOCK();
                        return NULL;
                    }
                }
                else {
                    free(key);
                    ModelicaIO_freeRealTable(table);
                    MUTEX_UNLOCK();
                    return file;
                }
            }
            else if (force) {
                /* Share hit -> Update table share (only if not shared
                   by multiple table objects)
                */
                free(key);
                if (file->refCount == 1) {
                    ModelicaIO_freeRealTable(file->table);
                    file->nRow = *nRow;
                    file->nCol = *nCol;
                    file->table = table;
                }
                else {
                    updateError = 1;
                }
            }
            else {
                /* Share hit -> Read from table share and increment table
                   reference counter
                */
                free(key);
                if (NULL != table) {
                    ModelicaIO_freeRealTable(table);
                }
                file->refCount++;
                *nRow = file->nRow;
                *nCol = file->nCol;
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
#if defined(TABLE_SHARE)
    return file;
#else
    return table;
#endif
#else
    return NULL;
#endif /* #if !defined(NO_FILE_SYSTEM) */
}

#if defined(__clang__)
#pragma clang diagnostic pop
#endif
