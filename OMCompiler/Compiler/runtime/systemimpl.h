/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
#ifndef __SYSTEMIMPL_H
#define __SYSTEMIMPL_H

#include "openmodelica.h"
#include "omc_config.h"

extern const char* System_modelicaPlatform();
extern const char* System_dirname(const char* str);
extern const char* System_realpath(const char *path);
extern const char* System_stringReplace(const char* str, const char* source, const char* target);
char* _replace(const char* source_str,
               const char* search_str,
               const char* replace_str);

typedef int (*function_t)(threadData_t*, type_description*, type_description*);

#if defined(_MSC_VER) || defined(NO_GETTEXT) /* no gettext for VS! */
#define gettext(str) str
#else
#include <locale.h>
#include <libintl.h>
#if !defined(__MINGW32__)
#include <langinfo.h>
#endif
#endif

#if defined(__MINGW32__) || defined(_MSC_VER)
#define NOMINMAX
#include <windows.h>
struct modelica_ptr_s {
  union {
    struct {
      function_t handle;
      modelica_integer lib;
    } func;
    HMODULE lib;
  } data;
  int cnt; // not unsigned as 0-1 would be a huge number if you call freeLibrary several times!
};
#else
struct modelica_ptr_s {
  union {
    struct {
      function_t handle;
      modelica_integer lib;
    } func;
    void *lib;
  } data;
  unsigned int cnt;
};
#endif

typedef struct modelica_ptr_s *modelica_ptr_t;
extern modelica_ptr_t lookup_ptr(modelica_integer index);

extern int SystemImpl__setCCompiler(const char *str);
extern int SystemImpl__setCXXCompiler(const char *str);
extern int SystemImpl__setLinker(const char *str);
extern int SystemImpl__setCFlags(const char *str);
extern int SystemImpl__setLDFlags(const char *str);
extern char* SystemImpl__pwd(void);
extern int SystemImpl__regularFileExists(const char* str);
extern int SystemImpl__removeFile(const char* filename);
extern const char* SystemImpl__basename(const char *str);
extern int SystemImpl__systemCall(const char* str, const char* outFile);
extern void* SystemImpl__systemCallParallel(void *lst, int numThreads);
extern int SystemImpl__spawnCall(const char* path, const char* str);
extern int SystemImpl__plotCallBackDefined(threadData_t *threadData);
extern void SystemImpl__plotCallBack(threadData_t *threadData, int externalWindow, const char* filename, const char* title, const char* grid, const char* plotType,
                                     const char* logX, const char* logY, const char* xLabel, const char* yLabel, const char* x1, const char* x2, const char* y1,
                                     const char* y2, const char* curveWidth, const char* curveStyle, const char* legendPosition, const char* footer,
                                     const char* autoScale, const char* variables);
extern double SystemImpl__time(void);
extern int SystemImpl__directoryExists(const char* str);
extern int SystemImpl__copyFile(const char* str_1, const char* str_2);
extern int SystemImpl__createDirectory(const char *str);
extern int SystemImpl__removeDirectory(const char *str);
extern const char* SystemImpl__readFileNoNumeric(const char* filename);
extern double SystemImpl__getCurrentTime(void);
extern int SystemImpl__unescapedStringLength(const char* str);
extern const char* SystemImpl__iconv(const char * str, const char *from, const char *to, int printError);
extern const char* SystemImpl__iconv__ascii(const char * str);
extern void SystemImpl__initGarbageCollector(void);
extern int SystemImpl__regularFileWritable(const char* str);

#endif //__SYSTEMIMPL_H
