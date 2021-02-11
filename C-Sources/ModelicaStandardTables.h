/* ModelicaStandardTables.h - External table functions header

   Copyright (C) 2008-2020, Modelica Association and contributors
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

   NO_FILE_SYSTEM        : A file system is not present (e.g. on dSPACE or xPC).
   NO_MUTEX              : Pthread mutex is not present (e.g. on dSPACE)
   NO_TABLE_COPY         : Do not copy table data passed to _init functions
                           This is a potentially unsafe optimization (ticket #1143).
   TABLE_SHARE           : If NO_FILE_SYTEM is not defined then common/shared table
                           arrays are stored in a global hash table in order to
                           avoid superfluous file input access and to decrease the
                           utilized memory (tickets #1110 and #1550).
   DEBUG_TIME_EVENTS     : Trace time events of CombiTimeTable
   DUMMY_FUNCTION_USERTAB: Use a dummy function "usertab"

   Changelog:
      Dec. 22, 2020: by Thomas Beutlich
                     Added reading of CSV files (ticket #1153)

      Aug. 03, 2019: by Thomas Beutlich
                     Added second derivatives (ticket #2901)

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
                     - Removed the implementation of the read functions

      Apr. 07, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Added support for shift time (independent of start time)
                     in CombiTimeTable (ticket #1771)

      Feb. 25, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Added support for extrapolation in CombiTable1D (ticket #1839)
                     Added functions to retrieve minimum and maximum abscissa
                     values of CombiTable1D (ticket #2120)

      Oct. 27, 2015: by Thomas Beutlich, ITI GmbH
                     Added nonnull attribute/annotations (ticket #1436)

      Apr. 09, 2013: by Thomas Beutlich, ITI GmbH
                     Revised the first version

      Jan. 27, 2008: by Martin Otter, DLR
                     Implemented a first version
*/

/* A table can be defined in the following ways when initializing the table:

     (1) Explicitly supplied in the argument list
         (= table    is "NoName" or has only blanks AND
            fileName is "NoName" or has only blanks).

     (2) Read from a file (fileName, tableName have to be supplied).

   Tables may be linearly interpolated or the first derivative
   may be continuous. In the latter case, cubic Hermite splines with Akima slope
   approximation, Fritsch-Butland slope approximation (univariate only) or Steffen
   slope approximation (univariate only) are used.
*/

#ifndef MODELICA_STANDARDTABLES_H_
#define MODELICA_STANDARDTABLES_H_

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
#define _In_
#define _In_z_
#define _Inout_
#endif

MODELICA_EXPORT void* ModelicaStandardTables_CombiTimeTable_init(_In_z_ const char* tableName,
                                                 _In_z_ const char* fileName,
                                                 _In_ double* table, size_t nRow,
                                                 size_t nColumn,
                                                 double startTime,
                                                 _In_ int* columns,
                                                 size_t nCols, int smoothness,
                                                 int extrapolation) MODELICA_NONNULLATTR;
  /* Same as ModelicaStandardTables_CombiTimeTable_init2, but without shiftTime, timeEvents and
     verbose arguments
  */

MODELICA_EXPORT void* ModelicaStandardTables_CombiTimeTable_init2(_In_z_ const char* fileName,
                                                  _In_z_ const char* tableName,
                                                  _In_ double* table, size_t nRow,
                                                  size_t nColumn,
                                                  double startTime,
                                                  _In_ int* columns,
                                                  size_t nCols, int smoothness,
                                                  int extrapolation,
                                                  double shiftTime,
                                                  int timeEvents,
                                                  int verbose) MODELICA_NONNULLATTR;
  /* Same as ModelicaStandardTables_CombiTimeTable_init3, but without delimiter and nHeaderLines
     arguments
  */

MODELICA_EXPORT void* ModelicaStandardTables_CombiTimeTable_init3(_In_z_ const char* fileName,
                                                  _In_z_ const char* tableName,
                                                  _In_ double* table, size_t nRow,
                                                  size_t nColumn,
                                                  double startTime,
                                                  _In_ int* columns,
                                                  size_t nCols, int smoothness,
                                                  int extrapolation,
                                                  double shiftTime,
                                                  int timeEvents,
                                                  int verbose,
                                                  _In_z_ const char* delimiter,
                                                  int nHeaderLines) MODELICA_NONNULLATTR;
  /* Initialize 1-dim. table where first column is time

     -> fileName: Name of file
     -> tableName: Name of table
     -> table: If tableName="NoName" or has only blanks AND
               fileName ="NoName" or has only blanks, then
               this pointer points to a 2-dim. array (row-wise storage)
               in the Modelica environment that holds this matrix.
     -> nRow: Number of rows of table
     -> nColumn: Number of columns of table
     -> startTime: Start time of inter-/extrapolation
     -> columns: Columns of table to be interpolated
     -> nCols: Number of columns of table to be interpolated
     -> smoothness: Interpolation type
                    = 1: linear
                    = 2: continuous first derivative (by Akima splines)
                    = 3: constant
                    = 4: monotonicity-preserving, continuous first derivative
                         (by Fritsch-Butland splines)
                    = 5: monotonicity-preserving, continuous first derivative
                         (by Steffen splines)
     -> extrapolation: Extrapolation type
                       = 1: hold first/last value
                       = 2: linear
                       = 3: periodic
                       = 4: no
     -> shiftTime: Shift time of first table column
     -> timeEvents: Time event handling (for constant or linear interpolation)
                    = 1: always
                    = 2: at discontinuities
                    = 3: no
     -> verbose: Print message that file is loading
     -> delimiter: Column delimiter character (CSV file only)
     -> nHeaderLines: Number of header lines to ignore (CSV file only)
     <- RETURN: Pointer to internal memory of table structure
  */

MODELICA_EXPORT void ModelicaStandardTables_CombiTimeTable_close(void* tableID);
  /* Close table and free allocated memory */

MODELICA_EXPORT double ModelicaStandardTables_CombiTimeTable_minimumTime(void* tableID);
  /* Return minimum abscissa defined in table (= table[1,1]) */

MODELICA_EXPORT double ModelicaStandardTables_CombiTimeTable_maximumTime(void* tableID);
  /* Return maximum abscissa defined in table (= table[end,1]) */

MODELICA_EXPORT double ModelicaStandardTables_CombiTimeTable_getValue(void* tableID,
                                                      int icol, double t,
                                                      double nextTimeEvent,
                                                      double preNextTimeEvent);
  /* Interpolate in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTimeTable_init
     -> icol: Index (1-based) of column to interpolate
     -> t: Abscissa value (time)
     -> nextTimeEvent: Next time event (found by ModelicaStandardTables_CombiTimeTable_nextTimeEvent)
     -> preNextTimeEvent: Pre value of next time event
     <- RETURN : Ordinate value
  */

MODELICA_EXPORT double ModelicaStandardTables_CombiTimeTable_getDerValue(void* tableID,
                                                         int icol,
                                                         double t,
                                                         double nextTimeEvent,
                                                         double preNextTimeEvent,
                                                         double der_t);
  /* Interpolated derivative in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTimeTable_init
     -> icol: Index (1-based) of column to interpolate
     -> t: Abscissa value (time)
     -> nextTimeEvent: Next time event (found by ModelicaStandardTables_CombiTimeTable_nextTimeEvent)
     -> preNextTimeEvent: Pre value of next time event
     -> der_t: Derivative of abscissa value (time)
     <- RETURN: Derivative of ordinate value
  */

MODELICA_EXPORT double ModelicaStandardTables_CombiTimeTable_getDer2Value(void* tableID,
                                                         int icol,
                                                         double t,
                                                         double nextTimeEvent,
                                                         double preNextTimeEvent,
                                                         double der_t,
                                                         double der2_t);
  /* Interpolated second derivative in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTimeTable_init
     -> icol: Index (1-based) of column to interpolate
     -> t: Abscissa value (time)
     -> nextTimeEvent: Next time event (found by ModelicaStandardTables_CombiTimeTable_nextTimeEvent)
     -> preNextTimeEvent: Pre value of next time event
     -> der_t: Derivative of abscissa value (time)
     -> der2_t: Second derivative of abscissa value (time)
     <- RETURN: Second derivative of ordinate value
  */

MODELICA_EXPORT double ModelicaStandardTables_CombiTimeTable_nextTimeEvent(void* tableID, double t);
  /* Return next time event in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTimeTable_init
     -> t: Abscissa value (time)
     <- RETURN: Next abscissa value > t that triggers a time event
  */

MODELICA_EXPORT double ModelicaStandardTables_CombiTimeTable_read(void* tableID, int force,
                                                  int verbose);
  /* Empty function, kept only for backward compatibility */

MODELICA_EXPORT void* ModelicaStandardTables_CombiTable1D_init(_In_z_ const char* tableName,
                                               _In_z_ const char* fileName,
                                               _In_ double* table, size_t nRow,
                                               size_t nColumn,
                                               _In_ int* columns,
                                               size_t nCols, int smoothness) MODELICA_NONNULLATTR;
  /* Same as ModelicaStandardTables_CombiTable1D_init2, but without extrapolation and
     verbose arguments
  */

MODELICA_EXPORT void* ModelicaStandardTables_CombiTable1D_init2(_In_z_ const char* fileName,
                                                _In_z_ const char* tableName,
                                                _In_ double* table, size_t nRow,
                                                size_t nColumn,
                                                _In_ int* columns,
                                                size_t nCols, int smoothness,
                                                int extrapolation,
                                                int verbose) MODELICA_NONNULLATTR;
  /* Same as ModelicaStandardTables_CombiTable1D_init3, but without delimiter and nHeaderLines
     arguments
  */

MODELICA_EXPORT void* ModelicaStandardTables_CombiTable1D_init3(_In_z_ const char* fileName,
                                                _In_z_ const char* tableName,
                                                _In_ double* table, size_t nRow,
                                                size_t nColumn,
                                                _In_ int* columns,
                                                size_t nCols, int smoothness,
                                                int extrapolation,
                                                int verbose,
                                                _In_z_ const char* delimiter,
                                                int nHeaderLines) MODELICA_NONNULLATTR;
  /* Initialize 1-dim. table defined by matrix, where first column
     is x-axis and further columns of matrix are interpolated

     -> fileName: Name of file
     -> tableName: Name of table
     -> table: If tableName="NoName" or has only blanks AND
               fileName ="NoName" or has only blanks, then
               this pointer points to a 2-dim. array (row-wise storage)
               in the Modelica environment that holds this matrix.
     -> nRow: Number of rows of table
     -> nColumn: Number of columns of table
     -> columns: Columns of table to be interpolated
     -> nCols: Number of columns of table to be interpolated
     -> smoothness: Interpolation type
                    = 1: linear
                    = 2: continuous first derivative (by Akima splines)
                    = 3: constant
                    = 4: monotonicity-preserving, continuous first derivative
                         (by Fritsch-Butland splines)
                    = 5: monotonicity-preserving, continuous first derivative
                         (by Steffen splines)
     -> extrapolation: Extrapolation type
                       = 1: hold first/last value
                       = 2: linear
                       = 3: periodic
                       = 4: no
     -> verbose: Print message that file is loading
     -> delimiter: Column delimiter character (CSV file only)
     -> nHeaderLines: Number of header lines to ignore (CSV file only)
     <- RETURN: Pointer to internal memory of table structure
  */

MODELICA_EXPORT void ModelicaStandardTables_CombiTable1D_close(void* tableID);
  /* Close table and free allocated memory */

MODELICA_EXPORT double ModelicaStandardTables_CombiTable1D_minimumAbscissa(void* tableID);
  /* Return minimum abscissa defined in table (= table[1,1]) */

MODELICA_EXPORT double ModelicaStandardTables_CombiTable1D_maximumAbscissa(void* tableID);
  /* Return maximum abscissa defined in table (= table[end,1]) */

MODELICA_EXPORT double ModelicaStandardTables_CombiTable1D_getValue(void* tableID, int icol,
                                                    double u);
  /* Interpolate in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTable1D_init
     -> icol: Index (1-based) of column to interpolate
     -> u: Abscissa value
     <- RETURN : Ordinate value
  */

MODELICA_EXPORT double ModelicaStandardTables_CombiTable1D_getDerValue(void* tableID, int icol,
                                                       double u, double der_u);
  /* Interpolated derivative in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTable1D_init
     -> icol: Index (1-based) of column to interpolate
     -> u: Abscissa value
     -> der_u: Derivative of abscissa value
     <- RETURN: Derivative of ordinate value
  */

MODELICA_EXPORT double ModelicaStandardTables_CombiTable1D_getDer2Value(void* tableID, int icol,
                                                       double u, double der_u, double der2_u);
  /* Interpolated second derivative in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTable1D_init
     -> icol: Index (1-based) of column to interpolate
     -> u: Abscissa value
     -> der_u: Derivative of abscissa value
     -> der2_u: Second derivative of abscissa value
     <- RETURN: Second derivative of ordinate value
  */

MODELICA_EXPORT double ModelicaStandardTables_CombiTable1D_read(void* tableID, int force,
                                                int verbose);
  /* Empty function, kept only for backward compatibility */

MODELICA_EXPORT void* ModelicaStandardTables_CombiTable2D_init(_In_z_ const char* tableName,
                                               _In_z_ const char* fileName,
                                               _In_ double* table, size_t nRow,
                                               size_t nColumn, int smoothness) MODELICA_NONNULLATTR;
  /* Same as ModelicaStandardTables_CombiTable2D_init2, but without verbose argument */

MODELICA_EXPORT void* ModelicaStandardTables_CombiTable2D_init2(_In_z_ const char* fileName,
                                                _In_z_ const char* tableName,
                                                _In_ double* table, size_t nRow,
                                                size_t nColumn, int smoothness,
                                                int extrapolation,
                                                int verbose) MODELICA_NONNULLATTR;
  /* Same as ModelicaStandardTables_CombiTable2D_init3, but without delimiter and nHeaderLines
     arguments
  */

MODELICA_EXPORT void* ModelicaStandardTables_CombiTable2D_init3(_In_z_ const char* fileName,
                                                _In_z_ const char* tableName,
                                                _In_ double* table, size_t nRow,
                                                size_t nColumn, int smoothness,
                                                int extrapolation,
                                                int verbose,
                                                _In_z_ const char* delimiter,
                                                int nHeaderLines) MODELICA_NONNULLATTR;
  /* Initialize 2-dim. table defined by matrix, where first column
     is x-axis, first row is y-axis and the matrix elements are the
     z-values.
       table[2:end,1    ]: Values of x-axis
            [1    ,2:end]: Values of y-axis
            [2:end,2:end]: Values of z-axis

     -> tableName: Name of table
     -> fileName: Name of file
     -> table: If tableName="NoName" or has only blanks AND
               fileName ="NoName" or has only blanks, then
               this pointer points to a 2-dim. array (row-wise storage)
               in the Modelica environment that holds this matrix.
     -> nRow: Number of rows of table
     -> nColumn: Number of columns of table
     -> smoothness: Interpolation type
                    = 1: bilinear
                    = 2: continuous first derivative (by bivariate Akima splines)
                    = 3: bivariate constant
     -> extrapolation: Extrapolation type
                       = 1: hold first/last value
                       = 2: linear
                       = 3: periodic
                       = 4: no
     -> verbose: Print message that file is loading
     -> delimiter: Column delimiter character (CSV file only)
     -> nHeaderLines: Number of header lines to ignore (CSV file only)
     <- RETURN: Pointer to internal memory of table structure
  */

MODELICA_EXPORT void ModelicaStandardTables_CombiTable2D_close(void* tableID);
  /* Close table and free allocated memory */

MODELICA_EXPORT void ModelicaStandardTables_CombiTable2D_minimumAbscissa(void* tableID,
                                                         _Inout_ double* uMin);
  /* Get minimum abscissa defined in table (= table[2,1] and table[1,2]) */

MODELICA_EXPORT void ModelicaStandardTables_CombiTable2D_maximumAbscissa(void* tableID,
                                                         _Inout_ double* uMax);
  /* Get maximum abscissa defined in table (= table[end,1] and table[1,end]) */

MODELICA_EXPORT double ModelicaStandardTables_CombiTable2D_getValue(void* tableID, double u1,
                                                    double u2);
  /* Interpolate in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTable2D_init
     -> u1: Value of first independent variable
     -> u2: Value of second independent variable
     <- RETURN : Interpolated value
  */

MODELICA_EXPORT double ModelicaStandardTables_CombiTable2D_getDerValue(void* tableID, double u1,
                                                       double u2, double der_u1,
                                                       double der_u2);
  /* Interpolated derivative in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTable2D_init
     -> u1: Value of first independent variable
     -> u2: Value of second independent variable
     -> der_u1: Derivative value of first independent variable
     -> der_u2: Derivative value of second independent variable
     <- RETURN: Derivative of interpolated value
  */

MODELICA_EXPORT double ModelicaStandardTables_CombiTable2D_getDer2Value(void* tableID, double u1,
                                                       double u2, double der_u1,
                                                       double der_u2, double der2_u1,
                                                       double der2_u2);
  /* Interpolated second derivative in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTable2D_init
     -> u1: Value of first independent variable
     -> u2: Value of second independent variable
     -> der_u1: Derivative value of first independent variable
     -> der_u2: Derivative value of second independent variable
     -> der2_u1: Second derivative value of first independent variable
     -> der2_u2: Second derivative value of second independent variable
     <- RETURN: Second derivative of interpolated value
  */

MODELICA_EXPORT double ModelicaStandardTables_CombiTable2D_read(void* tableID, int force,
                                                int verbose);
  /* Empty function, kept only for backward compatibility */

#endif
