
/*
   The content of this file is free software; it can be redistributed
   and/or modified under the terms of the Modelica License 2, see the
   license conditions and the accompanying disclaimer in file
   Modelica/ModelicaLicense2.html or in Modelica.UsersGuide.ModelicaLicense2.
*/

#include "ModelicaTables.h"
#include "tables.h"

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */


int ModelicaTables_CombiTimeTable_init(const char* tableName, const char* fileName,
                                        double const *table, int nRow, int nColumn,
                                        double startTime, int smoothness,
                                        int extrapolation) 
{
  return omcTableTimeIni(startTime, startTime, smoothness, extrapolation, 
			 tableName, fileName, table, nRow, nColumn, 0);
}

void ModelicaTables_CombiTimeTable_close(int tableID)
{
  ;
};

double ModelicaTables_CombiTimeTable_interpolate(int tableID, int icol, double u)
{
  return omcTableTimeIpo(tableID,icol,u);
}

double ModelicaTables_CombiTimeTable_minimumTime(int tableID) 
{
  return omcTableTimeTmin(tableID);
}

double ModelicaTables_CombiTimeTable_maximumTime(int tableID) 
{
  return omcTableTimeTmax(tableID);
}






int ModelicaTables_CombiTable1D_init(const char* tableName, const char* fileName,
                                       double const *table, int nRow, int nColumn,
                                       int smoothness)
{
  return omcTableTimeIni(0.0, 0.0, smoothness, 0, tableName, fileName,
			 table, nRow, nColumn, 0);
}

void ModelicaTables_CombiTable1D_close(int tableID) 
{
  ;
};

double ModelicaTables_CombiTable1D_interpolate(int tableID, int icol, double u) {
  return omcTableTimeIpo(tableID,icol,u);
}






int ModelicaTables_CombiTable2D_init(const char* tableName, const char* fileName,
                                       double const *table, int nRow, int nColumn,
                                       int smoothness)
{
  return omcTable2DIni(0,tableName,fileName,table,nRow,nColumn,0);
}

void ModelicaTables_CombiTable2D_close(int tableID)
{
  ;
};

double ModelicaTables_CombiTable2D_interpolate(int tableID, double u1, double u2)
{
  return omcTable2DIpo(tableID, u1, u2);
}

#ifdef __cplusplus
}
#endif /* __cplusplus */
