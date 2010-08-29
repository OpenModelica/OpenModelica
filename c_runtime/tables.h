/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * tables-h
 * Author : PA
 *
 * This file contain declarations for table interpolation functions used by
 * Modelica.Blocks.Source.CombiTable. The are the equivalent implementation of Dymolas
 * functions dymTableTimeIni2, etc.
 *
 */

#ifndef _OMC_TAPLES_H
#define _OMC_TAPLES_H

#ifdef __cplusplus
extern "C"
{
#endif

int omcTableTimeIni(double timeIn, double startTime,int ipoType,int expoType,
		    const char *tableName, const char* fileName, double *table,
		    int tableDim1,int tableDim2,int colWise);

double omcTableTimeIpo(int tableID, int icol, double timeIn);

double omcTableTimeTmax(int tableID);

double omcTableTimeTmin(int tableID);



int omcTable2DIni(int ipoType,const char *tableName,const char* fileName, 
		  double *table, int tableDim1,int tableDim2,int colWise);

double omcTable2DIpo(int tableID,double u1_, double u2_);


#ifdef __cplusplus
} //end extern "C"
#endif /* __cplusplus */

#endif
