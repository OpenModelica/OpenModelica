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
 * External function which are lined with library ModelicaExternalC 
 * in Modelica Standard Library
 */
#ifndef __cplusplus
  #include <string.h>
  #include <stdlib.h>
  #include <stdio.h>
#else
  #include <cstring>
  #include <cstdlib>
  #include <cstdio>
#endif
#if defined(_WIN32)
  #include <direct.h>
#elif defined(_BSD_SOURCE)
  #include <sys/stat.h>
  #include <sys/types.h>
  #include <unistd.h>
#endif
#include "tables.h"

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

// package Utilities.System
const char* ModelicaInternal_getcwd(int zero)
{
  fprintf(stderr,"ModelicaInternal_getcwd() not in implemented in OpenModelica.");
/*
#ifdef _BSD_SOURCE
  char* buf = malloc(1024);
  if (buf == NULL) return NULL;
  return getcwd(buf,1024);
#endif
  return NULL;
*/
}
void ModelicaInternal_chdir(const char* directory)
{
  fprintf(stderr,"ModelicaInternal_chdir() not in implemented in OpenModelica.");
/*
#ifdef _BSD_SOURCE
  chdir(directory);
#endif
*/
}
void ModelicaInternal_getenv(const char* name, int convertToSlash, const char** content, int* exist)
{
  fprintf(stderr,"ModelicaInternal_getenv() not in implemented in OpenModelica.");
/*
  *content = getenv(name);
  *exist = (*content != NULL);
#if defined(_WIN32)
  if (convertToSlash && *content) {
  }
#endif
*/
}
void ModelicaInternal_setenv(const char* name, const char* content, int convertFromSlash)
{
  fprintf(stderr,"ModelicaInternal_setenv() not in implemented in OpenModelica.");
/*
#if defined(_WIN32)
  if (convertFromSlash && content) {
    size_t len = strlen(content);
    char *s = malloc(strlen);
    if (s != NULL) {
      size_t i;
      for(i = 0; i <len; ++i)
	s[i] = (content[i] == '\\' ? '/' : content[i]);
      setenv(name,s,1);
      return;
    }
  }
#endif
  setenv(name,content,1);
*/
}
//int system(const char* string); // not needed -- same as in standard C library
void ModelicaInternal_exit(int status)
{
  fprintf(stderr,"ModelicaInternal_exit() not in implemented in OpenModelica.");
/*
  exit(status);
*/
}

// package Utilities.Strings
int ModelicaStrings_length(const char* string)
{
  return strlen(string);
}
const char* ModelicaStrings_substring(const char* string, int startIndex, int endIndex)
{
  fprintf(stderr,"ModelicaStrings_substring not in implemented in OpenModelica.");
  return NULL;
/*
  if (endIndex <= strlen(string)) {
    size_t sublen = endIndex-startIndex+1;
    char *s = malloc(sublen+1);
    strncpy(s,string+(startIndex-1),sublen);
    s[sublen] = '\0';
  }
  return s;
*/
}
int ModelicaStrings_compare(const char* string1, const char* string2, int caseSensitive)
{
  fprintf(stderr,"ModelicaStrings_compare not in implemented in OpenModelica.");
/*
  return (caseSensitive?strcmp(string1,string2):strcasecmp(string1,string2));
*/
}
void ModelicaStrings_scanReal(const char* string, int startIndex, int _unsigned, int* nextIndex, double* number)
{
  fprintf(stderr,"ModelicaStrings_scanReal() not in implemented in OpenModelica.");
/*
  // we trust that 'string' is null-terminated
  *nextIndex = startIndex;
  while(isspace(string[*nextIndex])) ++(*nextIndex);
  if (string[*nextIndex] == '+' || string[*nextIndex] == '-') {
    if (_unsigned) {
      *nextIndex = startIndex;
      *number == 0.0;
      return;
    } else ++(*nextIndex);
  }
  if (!isdigit(string[*nextIndex])) {
    *nextIndex = startIndex;
    *number == 0.0;
  }
  do {
    ++(*nextIndex);
  } while(isdigit(string[*nextIndex]));
  if (string[*nextIndex] == '.') {
    ++(*nextIndex);
    while(isdigit(string[*nextIndex])) ++(*nextIndex);
  }
  if (string[*nextIndex] == 'e' || string[*nextIndex] == 'E') {
    ++(*nextIndex);
    if (string[*nextIndex] == '+' || string[*nextIndex] == '-') 
      ++(*nextIndex);
    while(isdigit(string[*nextIndex])) ++(*nextIndex);
  }
  // do the conversion
  *number = atof(string);
*/
}

void ModelicaStrings_scanInteger(const char* string, int startIndex, int _unsigned, int* nextIndex, int* number)
{
  fprintf(stderr,"ModelicaStrings_scanInteger() not in implemented in OpenModelica.");
/*
 // we trust that 'string' is null-terminated
  *nextIndex = startIndex;
  while(isspace(string[*nextIndex])) ++(*nextIndex);
  if (string[*nextIndex] == '+' || string[*nextIndex] == '-') {
    if (_unsigned) {
      *nextIndex = startIndex;
      *number == 0.0;
      return;
    } else ++(*nextIndex);
  }
  if (!isdigit(string[*nextIndex])) {
    *nextIndex = startIndex;
    *number == 0.0;
  }
  do {
    ++(*nextIndex);
  } while(isdigit(string[*nextIndex]));
  // must not be real number
  switch(string[*nextIndex]) {
  case '.':
  case 'e':
  case 'E':
    *nextIndex = startIndex;
    *number = 0.0;
    return;
  default:
  }
  // do the conversion
  *number = atoi(string);
*/
}
void ModelicaStrings_scanString(const char* string, int startIndex, int* nextIndex, const char** string2)
{
  fprintf(stderr,"ModelicaStrings_scanString() not in implemented in OpenModelica.");
/*
  int len, index = startIndex;
  while(isspace(string[index])) ++index;

  *nextIndex = index;
  if (string[index] == '\"') {
    int escaped = 0;
    do {
      ++index;
      escaped = string[index] == '\\';
      if (string[index] == '\0') goto _fail;
    } while(!escaped && string[index] != '\"');
    len = index-*nextIndex;
    *string2 = malloc(len +1);
    if (*string2 == NULL) goto _fail;
    strncpy(*string2,string+(*nextIndex),len);
    (*string2)[len] = '\0';
    *nextIndex = index;
  } else goto _fail;

  _fail:
    *nextIndex = startIndex;
    *string2 = malloc(1);
    if (*string2) **string2 = '\0';
*/
}
void ModelicaStrings_scanIdentifier(const char* string, int startIndex, int* nextIndex, const char** identifier)
{
  fprintf(stderr,"ModelicaStrings_scanIdentifier() not in implemented in OpenModelica.");
  /*
  int len, index = startIndex;
  while(isspace(string[index])) ++index;

  *nextIndex = index;
  if (!isalpha(string[index])) {
    *nextIndex = startIndex;
    return;
  }
  do {
    ++index;
  } while(isalnum(string[index]) || string[index] == '_');

  len = index-*nextIndex;
  *identifier = malloc(len +1);
  if (*identifier == NULL) goto _fail;
  strncpy(*identifier,string+(*nextIndex),len);
  (*identifier)[len] = '\0';
  *nextIndex = index;

 _fail:
  *nextIndex = startIndex;
  *identifier = malloc(1);
  if (*identifier) **identifier = '\0';
  */
}
int ModelicaStrings_skipWhiteSpace(const char* string, int startIndex)
{
  fprintf(stderr,"ModelicaStrings_skipWhiteSpace() not in implemented in OpenModelica.");
  return 0;
  /*
  while(isspace(string[startIndex])) ++startIndex;
  return (startIndex);
  */
}

// package Utilities.Streams
void ModelicaInternal_print(const char* string, const char* fileName);
const char* ModelicaInternal_readLine(const char* fileName, int lineNumber, int* endOfFile); // ???
int ModelicaInternal_countLines(const char* fileName)
{
  fprintf(stderr,"ModelicaInternal_countLines() not in implemented in OpenModelica.");
  return 0;
}
//void ModelicaError(const char* string); // already in ModelicaUtilities.{h,c}
void ModelicaStreams_closeFile(const char* fileName)
{
  fprintf(stderr,"ModelicaInternal_closeFile() not in implemented in OpenModelica.");
}

// package Utilites.FileSystem
void ModelicaInternal_mkdir(const char* directoryName)
{
  fprintf(stderr,"ModelicaInternal_mkdir() not in implemented in OpenModelica.");
/*
#ifdef _WIN32
  mkdir(directoryName);
#else
  mkdir(directoryName,0777);
#endif
*/
}
void ModelicaInternal_rmdir(const char* directoryName)
{
  fprintf(stderr,"ModelicaInternal_rmdir() not in implemented in OpenModelica.");
}
int ModelicaInternal_stat(const char* name)
{
  fprintf(stderr,"ModelicaInternal_stat() not in implemented in OpenModelica.");
  return 0;
}
void ModelicaInternal_rename(const char* oldName, const char* newName)
{
  fprintf(stderr,"ModelicaInternal_rename() not in implemented in OpenModelica.");
}
void ModelicaInternal_removeFile(const char* fileName)
{
  fprintf(stderr,"ModelicaInternal_removeFile() not in implemented in OpenModelica.");
}
void ModelicaInternal_copyFile(const char* fromName, const char* toName)
{
  fprintf(stderr,"ModelicaInternal_copyFile() not in implemented in OpenModelica.");
}
void ModelicaInternal_readDirectory(const char* directory, int nNames, const char*** names) {
  fprintf(stderr,"ModelicaInternal_readDirectory() not in implemented in OpenModelica.");
}
int ModelicaInternal_getNumberOfFiles(const char* directory)
{
  fprintf(stderr,"ModelicaInternal_getNumberOfFiles() not in implemented in OpenModelica.");
  return 0;
}
const char* ModelicaInternal_fullPathName(const char* name)
{
  fprintf(stderr,"ModelicaInternal_fullPathName() not in implemented in OpenModelica.");
}
const char* ModelicaInternal_temporaryFileName(int zero)
{
  fprintf(stderr,"ModelicaInternal_temporaryFileName() not in implemented in OpenModelica.");
  return NULL;
}

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
int ModelicaTables_CombiTimeTable_init(const char* tableName, const char *fileName, double *table, size_t table_size1, size_t table_size2, double startTime, int smoothness, int extrapolation)
{
  return omcTableTimeIni(startTime, startTime, smoothness, extrapolation,
			 tableName, fileName, table, table_size1, table_size2, 0);
}
double ModelicaTables_CombiTimeTable_interpolate(int tableID, int icol, double timeIn)
{
  return omcTableTimeIpo(tableID,icol,timeIn);
}
double ModelicaTables_CombiTimeTable_minimumTime(int tableID)
{
  return omcTableTimeTmax(tableID);
}
double ModelicaTables_CombiTimeTable_maximumTime(int tableID)
{
  return omcTableTimeTmin(tableID);
}

int ModelicaTables_CombiTable1D_init(const char* tableName, const char* fileName, double* table, size_t table_size1, size_t table_size2, int smoothness)
{
  return omcTableTimeIni(0.0, 0.0, smoothness, 0, tableName, fileName,
			 table, table_size1, table_size2, 0);
}
double ModelicaTables_CombiTable1D_interpolate(int tableID, int icol, double u)
{
  return omcTableTimeIpo(tableID, icol, u);
}

int ModelicaTables_CombiTable2D_init(const char* tableName, const char* fileName, double* table, size_t table_size1, size_t table_size2, int smoothness)
{
  return omcTable2DIni(0,tableName,fileName,table,table_size1,table_size2,0);
}
double ModelicaTables_CombiTable2D_interpolate(int tableID, double u1, double u2)
{
  return omcTable2DIpo(tableID,u1,u2);
}

#ifdef __cplusplus
} /* end extern "C" */
#endif
