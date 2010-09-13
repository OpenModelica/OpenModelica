#ifndef MODELICA_TABLES_H
#define MODELICA_TABLES_H

/* Definition of interface to external functions for table computation
   in the Modelica Standard Library:

       Modelica.Blocks.Sources.CombiTimeTable
       Modelica.Blocks.Tables.CombiTable1D
       Modelica.Blocks.Tables.CombiTable1Ds
       Modelica.Blocks.Tables.CombiTable2D


   Release Notes:
      Jan. 27, 2008: by Martin Otter.
                     Implemented a first version

   Copyright (C) 2008, Modelica Association and DLR.

   The content of this file is free software; it can be redistributed
   and/or modified under the terms of the Modelica License 2, see the
   license conditions and the accompanying disclaimer in file
   Modelica/ModelicaLicense2.html or in Modelica.UsersGuide.ModelicaLicense2.
*/


/* A table can be defined in the following ways when initializing the table:

     (1) Explicitly supplied in the argument list
         (= table    is "NoName" or has only blanks AND
            fileName is "NoName" or has only blanks).

     (2) Read from a file (tableName, fileName have to be supplied).

   Tables may be linearly interpolated or the first derivative may be continuous.
   In the second case, Akima-Splines are used
   (algorithm 433 of ACM, http://portal.acm.org/citation.cfm?id=355605)
*/

extern int ModelicaTables_CombiTimeTable_init(
                      const char*   tableName,
                      const char*   fileName,
                      double const* table, int nRow, int nColumn,
                      double        startTime,
                      int           smoothness,
                      int           extrapolation);
  /* Initialize 1-dim. table where first column is time

      -> tableName : Name of table.
      -> fileName  : Name of file.
      -> table     : If tableName="NoName" or has only blanks AND
                        fileName ="NoName" or has only blanks, then
                     this pointer points to a 2-dim. array (row-wise storage)
                     in the Modelica environment that holds this matrix.
      -> nRow      : Number of rows of table
      -> nColumn   : Number of columns of table
      -> startTime : Output = offset for time < startTime
      -> smoothness: Interpolation type
                     = 1: linear
                     = 2: continuous first derivative
      <- RETURN    : ID of internal memory of table.
  */

extern void ModelicaTables_CombiTimeTable_close(int tableID);
  /* Close table and free allocated memory */


extern double ModelicaTables_CombiTimeTable_minimumTime(int tableID);
  /* Return minimum time defined in table (= table[1,1]) */


extern double ModelicaTables_CombiTimeTable_maximumTime(int tableID);
  /* Return maximum time defined in table (= table[end,1]) */


extern double ModelicaTables_CombiTimeTable_interpolate(int tableID, int icol, double u);
  /* Interpolate in table

     -> tableID: Pointer to table defined with ModelicaTables_CombiTimeTable_init
     -> icol   : Column to interpolate
     -> u      : Abscissa value (time)
     <- RETURN : Ordinate value
 */



extern int ModelicaTables_CombiTable1D_init(
                  const  char*  tableName,
                  const  char*  fileName,
                  double const* table, int nRow, int nColumn,
                  int smoothness);
  /* Initialize 1-dim. table defined by matrix, where first column
     is x-axis and further columns of matrix are interpolated

      -> tableName : Name of table.
      -> fileName  : Name of file.
      -> table     : If tableName="NoName" or has only blanks AND
                        fileName ="NoName" or has only blanks, then
                     this pointer points to a 2-dim. array (row-wise storage)
                     in the Modelica environment that holds this matrix.
      -> nRow      : Number of rows of table
      -> nColumn   : Number of columns of table
      -> smoothness: Interpolation type
                     = 1: linear
                     = 2: continuous first derivative
      <- RETURN    : ID of internal memory of table.
  */

extern void ModelicaTables_CombiTable1D_close(int tableID);
  /* Close table and free allocated memory */

extern double ModelicaTables_CombiTable1D_interpolate(int tableID, int icol, double u);
  /* Interpolate in table

     -> tableID: Pointer to table defined with ModelicaTables_CombiTable1D_init
     -> icol   : Column to interpolate
     -> u      : Abscissa value
     <- RETURN : Ordinate value
 */



extern int ModelicaTables_CombiTable2D_init(
                   const char*   tableName,
                   const char*   fileName,
                   double const* table, int nRow, int nColumn,
                   int smoothness);
  /* Initialize 2-dim. table defined by matrix, where first column
     is x-axis, first row is y-axis and the matrix elements are the
     z-values.
       table[2:end,1    ]: Values of x-axis
            [1    ,2:end]: Values of y-axis
            [2:end,2:end]: Values of z-axis

      -> tableName : Name of table.
      -> fileName  : Name of file.
      -> table     : If tableName="NoName" or has only blanks AND
                        fileName ="NoName" or has only blanks, then
                     this pointer points to a 2-dim. array (row-wise storage)
                     in the Modelica environment that holds this matrix.
      -> nRow      : Number of rows of table
      -> nColumn   : Number of columns of table
      -> smoothness: Interpolation type
                     = 1: linear
                     = 2: continuous first derivative
      <- RETURN    : ID of internal memory of table.
  */

extern void ModelicaTables_CombiTable2D_close(int tableID);
  /* Close table and free allocated memory */

extern double ModelicaTables_CombiTable2D_interpolate(int tableID, double u1, double u2);
  /* Interpolate in table

     -> tableID: Pointer to table defined with ModelicaTables_CombiTable1D_init
     -> u1     : x-axis value
     -> u2     : y-axis value
     <- RETURN : y-axis value
 */


#endif /* MODELICA_TABLES */
