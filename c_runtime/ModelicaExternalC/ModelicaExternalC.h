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
#ifndef _MODELICAEXTERNALC_H_
#define _MODELICAEXTERNALC_H_

//
// External function which are lined with library ModelicaExternalC 
// in Modelica Standard Library
//

// package Utilities.System
const char* ModelicaInternal_getcwd(int zero); // ???
void ModelicaInternal_chdir(const char* directory);
void ModelicaInternal_getenv(const char* name, int convertToSlash, const char** content, int* exist);
void ModelicaInternal_setenv(const char* name, const char* content, int convertFromSlash);
//int system(const char* string); // not needed -- same as in standard C library
void ModelicaInternal_exit(int status);

// package Utilities.Strings
int ModelicaStrings_length(const char* string);
const char* ModelicaStrings_substring(const char* string, int startIndex, int endIndex); // ???
int ModelicaStrings_compare(const char* string1, const char* string2, int caseSensitive);
void ModelicaStrings_scanReal(const char* string, int startIndex, int _unsigned, int* nextIndex, double* number);
void ModelicaStrings_scanInteger(const char* string, int startIndex, int _unsigned, int* nextIndex, int* number);
void ModelicaStrings_scanString(const char* string, int startIndex, int* nextIndex, const char** string2);
void ModelicaStrings_scanIdentifier(const char* string, int startIndex, int* nextIndex, const char** identifier);
int ModelicaStrings_skipWhiteSpace(const char* string, int startIndex);

// package Utilities.Streams
void ModelicaInternal_print(const char* string, const char* fileName);
const char* ModelicaInternal_readLine(const char* fileName, int lineNumber, int* endOfFile); // ???
int ModelicaInternal_countLines(const char* fileName);
void ModelicaError(const char* string);
void ModelicaStreams_closeFile(const char* fileName);

// package Utilites.FileSystem
void ModelicaInternal_mkdir(const char* directoryName);
void ModelicaInternal_rmdir(const char* directoryName);
int ModelicaInternal_stat(const char* name);
void ModelicaInternal_rename(const char* oldName, const char* newName);
void ModelicaInternal_removeFile(const char* fileName);
void ModelicaInternal_copyFile(const char* fromName, const char* toName);
void ModelicaInternal_readDirectory(const char* directory, int nNames, const char*** names); // ???
int ModelicaInternal_getNumberOfFiles(const char* directory);
const char* ModelicaInternal_fullPathName(const char* name); // ???
const char* ModelicaInternal_temporaryFileName(int zero);

// package Math (all functions available in <math.h>)
//double sin(double u);
//double cos(double u);
//double tan(double u);
//double asin(double u);
//double acos(double u);
//double atan(double u);
//double atan2(double u1,double u2);
//double sinh(double u);
//double cosh(double u);
//double tanh(double u);
//double exp(double u);
//double log(double u);
//double log10(double u);

// package Blocks.Sources and Blocks.Tables
int ModelicaTables_CombiTable1D_init(const char* tableName, const char* fileName, double* table, size_t table_size1, size_t table_size2, int smoothness);
double ModelicaTables_CombiTable1D_interpolate(int tableID, int icol, double u);
double ModelicaTables_CombiTimeTable_minimumTime(int tableID);
double ModelicaTables_CombiTimeTable_maximumTime(int tableID);


int ModelicaTables_CombiTable2D_init(const char* tableName, const char* fileName, double* table, size_t table_size1, size_t table_size2, int smoothness);
double ModelicaTables_CombiTable2D_interpolate(int tableID, double u1, double u2);


#endif /* _MODELICAEXTERNALC_H_ */
