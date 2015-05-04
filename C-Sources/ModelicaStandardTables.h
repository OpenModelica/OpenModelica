/* Definition of interface to external functions for table computation
   in the Modelica Standard Library:

       Modelica.Blocks.Sources.CombiTimeTable
       Modelica.Blocks.Tables.CombiTable1D
       Modelica.Blocks.Tables.CombiTable1Ds
       Modelica.Blocks.Tables.CombiTable2D


   Release Notes:
      Apr. 09, 2013: by Thomas Beutlich, ITI GmbH
                     Revised the first version

      Jan. 27, 2008: by Martin Otter, DLR
                     Implemented a first version

   Copyright (C) 2008, Modelica Association and DLR
   Copyright (C) 2013, Modelica Association, DLR and ITI GmbH
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Modelica Association nor the names of its
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

/* A table can be defined in the following ways when initializing the table:

     (1) Explicitly supplied in the argument list
         (= table    is "NoName" or has only blanks AND
            fileName is "NoName" or has only blanks).

     (2) Read from a file (tableName, fileName have to be supplied).

   Tables may be linearly interpolated or the first derivative
   may be continuous. In the latter case, Akima-Splines are used.
*/

#ifndef _MODELICASTANDARDTABLES_H_
#define _MODELICASTANDARDTABLES_H_

#include <stdlib.h>

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
void* ModelicaStandardTables_CombiTimeTable_init(const char* tableName,
                                                 const char* fileName,
                                                 double* table, size_t nRow,
                                                 size_t nColumn,
                                                 double startTime,
                                                 int* columns,
                                                 size_t nCols, int smoothness,
                                                 int extrapolation);
  /* Initialize 1-dim. table where first column is time

     -> tableName: Name of table
     -> fileName: Name of file
     -> table: If tableName="NoName" or has only blanks AND
               fileName ="NoName" or has only blanks, then
               this pointer points to a 2-dim. array (row-wise storage)
               in the Modelica environment that holds this matrix.
     -> nRow: Number of rows of table
     -> nColumn: Number of columns of table
     -> startTime: Output = offset for time < startTime
     -> columns: Columns of table to be interpolated
     -> nCols: Number of columns of table to be interpolated
     -> smoothness: Interpolation type
                    = 1: constant
                    = 2: linear
                    = 3: continuous first derivative
     -> extrapolation: Extrapolation type
                       = 1: no
                       = 2: hold first/last value
                       = 3: linear
                       = 4: periodic
     <- RETURN: Pointer to internal memory of table structure
  */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
void ModelicaStandardTables_CombiTimeTable_close(void* tableID);
  /* Close table and free allocated memory */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
double ModelicaStandardTables_CombiTimeTable_read(void* tableID, int force,
                                                  int verbose);
  /* Read table from file

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTimeTable_init
     -> force: Read only if forced or not yet read
     -> verbose: Print message that file is loading
     <- RETURN: = 1, if table was successfully read from file
  */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
double ModelicaStandardTables_CombiTimeTable_minimumTime(void* tableID);
  /* Return minimum time defined in table (= table[1,1]) */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
double ModelicaStandardTables_CombiTimeTable_maximumTime(void* tableID);
  /* Return maximum time defined in table (= table[end,1]) */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
double ModelicaStandardTables_CombiTimeTable_getValue(void* tableID,
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

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
double ModelicaStandardTables_CombiTimeTable_getDerValue(void* tableID,
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

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
double ModelicaStandardTables_CombiTimeTable_nextTimeEvent(void* tableID, double t);
  /* Return next time event in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTimeTable_init
     -> t: Abscissa value (time)
     <- RETURN: Next abscissa value > t that triggers a time event
  */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
void* ModelicaStandardTables_CombiTable1D_init(const char* tableName,
                                               const char* fileName,
                                               double* table, size_t nRow,
                                               size_t nColumn,
                                               int* columns,
                                               size_t nCols, int smoothness);
  /* Initialize 1-dim. table defined by matrix, where first column
     is x-axis and further columns of matrix are interpolated

     -> tableName: Name of table
     -> fileName: Name of file
     -> table: If tableName="NoName" or has only blanks AND
               fileName ="NoName" or has only blanks, then
               this pointer points to a 2-dim. array (row-wise storage)
               in the Modelica environment that holds this matrix.
     -> nRow: Number of rows of table
     -> nColumn: Number of columns of table
     -> startTime: Output = offset for time < startTime
     -> columns: Columns of table to be interpolated
     -> nCols: Number of columns of table to be interpolated
     -> smoothness: Interpolation type
                    = 1: constant
                    = 2: linear
                    = 3: continuous first derivative
     <- RETURN: Pointer to internal memory of table structure
  */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
void ModelicaStandardTables_CombiTable1D_close(void* tableID);
  /* Close table and free allocated memory */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
double ModelicaStandardTables_CombiTable1D_read(void* tableID, int force,
                                                int verbose);
  /* Read table from file

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTable1D_init
     -> force: Read only if forced or not yet read
     -> verbose: Print message that file is loading
     <- RETURN: = 1, if table was successfully read from file
  */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
double ModelicaStandardTables_CombiTable1D_getValue(void* tableID, int icol,
                                                    double u);
  /* Interpolate in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTable1D_init
     -> icol: Index (1-based) of column to interpolate
     -> u: Abscissa value
     <- RETURN : Ordinate value
  */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
double ModelicaStandardTables_CombiTable1D_getDerValue(void* tableID, int icol,
                                                       double u, double der_u);
  /* Interpolated derivative in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTable1D_init
     -> icol: Index (1-based) of column to interpolate
     -> u: Abscissa value
     -> der_u: Derivative of abscissa value
     <- RETURN: Derivative of ordinate value
  */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
void* ModelicaStandardTables_CombiTable2D_init(const char* tableName,
                                               const char* fileName,
                                               double* table, size_t nRow,
                                               size_t nColumn, int smoothness);
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
                    = 1: constant
                    = 2: linear
                    = 3: continuous first derivative
     <- RETURN: Pointer to internal memory of table structure
  */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
void ModelicaStandardTables_CombiTable2D_close(void* tableID);
  /* Close table and free allocated memory */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
double ModelicaStandardTables_CombiTable2D_read(void* tableID, int force,
                                                int verbose);
  /* Read table from file

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTable2D_init
     -> force: Read only if forced or not yet read
     -> verbose: Print message that file is loading
     <- RETURN: = 1, if table was successfully read from file
  */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
double ModelicaStandardTables_CombiTable2D_getValue(void* tableID, double u1,
                                                    double u2);
  /* Interpolate in table

     -> tableID: Pointer to table defined with ModelicaStandardTables_CombiTable2D_init
     -> u1: Value of first independent variable
     -> u2: Value of second independent variable
     <- RETURN : Interpolated value
  */

#if defined(__cplusplus)
extern "C"
#else
extern
#endif
double ModelicaStandardTables_CombiTable2D_getDerValue(void* tableID, double u1,
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

#endif /* _MODELICASTANDARDTABLES_H_ */
