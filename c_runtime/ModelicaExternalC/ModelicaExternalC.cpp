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
  #include <errno.h>
#else
  #include <cstdio>
  #include <cctype>
  #include <cstring>
  #include <cstdlib>
  #include <cerrno>
#endif

#if defined(_WIN32)
  #include <direct.h>
#elif defined(_BSD_SOURCE)
  #include <sys/stat.h>
  #include <sys/types.h>
  #include <unistd.h>
#endif

#include "../tables.h"

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include "../ModelicaUtilities.h"

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

const char* ModelicaStrings_substring(const char* string, int startIndex, int endIndex) {

  /* Return string1(startIndex:endIndex) if endIndex >= startIndex,
     or return string1(startIndex:startIndex), if endIndex = 0.
     An assert is triggered, if startIndex/endIndex are not valid.
  */
     char* substring;
     int len1 = strlen(string);
     int len2;

  /* Check arguments */
     if ( startIndex < 1 ) {
        ModelicaFormatError("Wrong call of Utilities.Strings.substring:\n"
                            "  startIndex = %d (has to be > 0).\n"
                            "  string     = \"%s\"\n", startIndex, string);
     } else if ( endIndex == -999 ) {
        endIndex = startIndex;
     } else if ( endIndex < startIndex ) {
        ModelicaFormatError("Wrong call of  Utilities.Strings.substring:\n"
                            "  startIndex = %d\n"
                            "  endIndex   = %d (>= startIndex required)\n"
                            "  string     = \"%s\"\n", startIndex, endIndex, string);
     } else if ( endIndex > len1 ) {
        ModelicaFormatError("Wrong call of Utilities.Strings.substring:\n"
                            "  endIndex = %d (<= %d required (=length(string)).\n"
                            "  string   = \"%s\"\n", endIndex, len1, string);
     };

  /* Allocate memory and copy string */
     len2 = endIndex - startIndex + 1;
     substring = ModelicaAllocateString(len2);
     strncpy(substring, &string[startIndex-1], len2);
     substring[len2] = '\0';
     return substring;
}


int ModelicaStrings_compare(const char* string1, const char* string2, int caseSensitive)
/* compares two strings, optionally ignoring case */
{
    int result;
    if (string1 == 0 || string2 == 0) return 2;

    if (caseSensitive) {
        result = strcmp(string1, string2);
    } else {
        while (tolower(*string1) == tolower(*string2) && *string1 != '\0') {
            string1++;
            string2++;
        }
        result = (int)(tolower(*string1)) - (int)(tolower(*string2));
    }

    if ( result < 0 ) {
        result = 1;
    } else if ( result == 0 ) {
        result = 2;
    } else {
        result = 3;
    };
    return result;
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
  return omcTableTimeTmin(tableID);
}
double ModelicaTables_CombiTimeTable_maximumTime(int tableID)
{
  return omcTableTimeTmax(tableID);
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

/* adrpo: 2010-09-10 copied from ModelicaLibrary/Modelica/Resources/C-Sources */

/* --------------------- Abstract data type for stream handles --------------------- */
/* Needs to be improved for cashing of the open files */

FILE* ModelicaStreams_openFileForReading(const char* fileName) {
   /* Open text file for reading */
      FILE* fp;

   /* Open file */
      fp = fopen(fileName, "r");
      if ( fp == NULL ) {
         ModelicaFormatError("Not possible to open file \"%s\" for reading:\n"
                             "%s\n", fileName, strerror(errno));
      }
      return fp;
}

FILE* ModelicaStreams_openFileForWriting(const char* fileName) {
   /* Open text file for writing (with append) */
      FILE* fp;

   /* Check fileName */
      if ( strlen(fileName) == 0 ) {
         ModelicaError("fileName is an empty string.\n"
                       "Opening of file is aborted\n");
      }

   /* Open file */
      fp = fopen(fileName, "a");
      if ( fp == NULL ) {
         ModelicaFormatError("Not possible to open file \"%s\" for writing:\n"
                             "%s\n", fileName, strerror(errno));
      }
      return fp;
}

/* adrpo: 2010-09-10 copied from ModelicaLibrary/Modelica/Resources/C-Sources */
/* --------------------- Modelica_Utilities.Streams ----------------------------------- */

void ModelicaInternal_print(const char* string, const char* fileName) {
  /* Write string to terminal or to file */

     if ( fileName[0] == '\0' ) {
        /* Write string to terminal */
           ModelicaMessage(string);
     } else {
        /* Write string to file */
           FILE* fp = ModelicaStreams_openFileForWriting(fileName);
           if ( fputs(string,fp) < 0 ) goto ERROR;
           if ( fputs("\n",fp)   < 0 ) goto ERROR;
           fclose(fp);
           return;

           ERROR: fclose(fp);
                  ModelicaFormatError("Error when writing string to file \"%s\":\n"
                                      "%s\n", fileName, strerror(errno));
     }
}


int ModelicaInternal_countLines(const char* fileName)
/* Get number of lines of a file */
{
    int c;
    int nLines = 0;
    int start_of_line = 1;
    /* If true, next character starts a new line. */

    FILE* fp = ModelicaStreams_openFileForReading(fileName);

    /* Count number of lines */
    while ((c = fgetc(fp)) != EOF) {
        if (start_of_line) {
            nLines++;
            start_of_line = 0;
        }
        if (c == '\n') start_of_line = 1;
    }
    fclose(fp);
    return nLines;
}

void ModelicaInternal_readFile(const char* fileName, const char* string[], size_t nLines) {
  /* Read file into string vector string[nLines] */
     FILE* fp = ModelicaStreams_openFileForReading(fileName);
     char*  line;
     int    c;
     size_t lineLen;
     size_t iLines;
     long   offset;
     size_t nc;

  /* Read data from file */
     iLines = 1;
     while ( iLines <= nLines ) {
        /* Determine length of next line */
           offset  = ftell(fp);
           lineLen = 0;
           c = fgetc(fp);
           while ( c != '\n' && c != EOF ) {
              lineLen++;
              c = fgetc(fp);
           }

        /* Allocate storage for next line */
           line = ModelicaAllocateStringWithErrorReturn(lineLen);
           if ( line == NULL ) {
              fclose(fp);
              ModelicaFormatError("Not enough memory to allocate string for reading line %i from file\n"
                                  "\"%s\".\n"
                                  "(this file contains %i lines)\n", iLines, fileName, nLines);
           }

        /* Read next line */
           if ( fseek(fp, offset, SEEK_SET != 0) ) {
              fclose(fp);
              ModelicaFormatError("Error when reading line %i from file\n\"%s\":\n"
                                  "%s\n", iLines, fileName, strerror(errno));
           };
           nc = ( iLines < nLines ? lineLen+1 : lineLen);
           if ( fread(line, sizeof(char), nc, fp) != nc ) {
              fclose(fp);
              ModelicaFormatError("Error when reading line %i from file\n\"%s\"\n",
                                  iLines, fileName);
           };
           line[lineLen] = '\0';
           string[iLines-1] = line;
           iLines++;
     }
     fclose(fp);
}


const char* ModelicaInternal_readLine(const char* fileName, int lineNumber, int* endOfFile) {
  /* Read line lineNumber from file fileName */
     FILE* fp = ModelicaStreams_openFileForReading(fileName);
     char*  line;
     int    c;
     size_t lineLen;
     size_t iLines;
     long   offset;

  /* Read upto line lineNumber-1 */
     iLines = 0;
     c = 1;
     while ( iLines != (size_t) lineNumber-1 && c != EOF ) {
        c = fgetc(fp);
        while ( c != '\n' && c != EOF ) {
           c = fgetc(fp);
        }
        iLines++;
     }
     if ( iLines != (size_t) lineNumber-1 ) goto END_OF_FILE;

  /* Determine length of line lineNumber */
     offset  = ftell(fp);
     lineLen = 0;
     c = fgetc(fp);
     while ( c != '\n' && c != EOF ) {
        lineLen++;
        c = fgetc(fp);
     }
     if ( lineLen == 0 && c == EOF ) goto END_OF_FILE;

  /* Read line lineNumber */
     line = ModelicaAllocateStringWithErrorReturn(lineLen);
     if ( line == NULL ) goto ERROR;
     if ( fseek(fp, offset, SEEK_SET != 0) ) goto ERROR;
     if ( fread(line, sizeof(char), lineLen, fp) != lineLen ) goto ERROR;
     fclose(fp);
     line[lineLen] = '\0';
     *endOfFile = 0;
     return line;

  /* End-of-File or error */
     END_OF_FILE: fclose(fp);
                  *endOfFile = 1;
                  line = ModelicaAllocateString(0);
                  return line;

     ERROR      : fclose(fp);
                  ModelicaFormatError("Error when reading line %i from file\n\"%s\":\n%s",
                                      lineNumber, fileName, strerror(errno));
                  return "";
}


#ifdef __cplusplus
} /* end extern "C" */
#endif
