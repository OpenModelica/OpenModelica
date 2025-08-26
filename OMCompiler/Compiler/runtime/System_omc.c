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

#if defined(_MSC_VER) || defined(__MINGW32__)
 #include <windows.h>
#endif

#ifdef __cplusplus
extern "C"
{
#endif

#if (defined(__linux__) || defined(__FreeBSD__)) && !defined(_GNU_SOURCE)
#define _GNU_SOURCE 1
#endif

#include <ctype.h> /* for toupper */
#include <limits.h>
#include <stdlib.h>
#include "util/omc_msvc.h"
#include "util/omc_file.h"
#include "openmodelica.h"
#include "meta/meta_modelica.h"
#include "ModelicaUtilities.h"

#define ADD_METARECORD_DEFINITIONS static
#if defined(OMC_BOOTSTRAPPING)
  #include "../boot/tarball-include/OpenModelicaBootstrappingHeader.h"
#else
  #include "../OpenModelicaBootstrappingHeader.h"
#endif

#include "systemimpl.c"

extern void System_writeFile(const char* filename, const char* data)
{
  if (SystemImpl__writeFile(filename, data))
    MMC_THROW();
}

extern void System_appendFile(const char *filename, const char *data)
{
  if (SystemImpl__appendFile(filename, data))
    MMC_THROW();
}

extern char* System_readFile(const char* filename)
{
  return SystemImpl__readFile(filename);
}

extern const char* System_stringReplace(const char* str, const char* source, const char* target)
{
  char* res = _replace(str,source,target);
  if (res == NULL)
    MMC_THROW();
  return res;
}

extern const char* System_makeC89Identifier(const char* str)
{
  int i=0, len=strlen(str);
  char *res = omc_alloc_interface.malloc_strdup(str);
  if (!((res[0]>='a' && res[0]<='z') || (res[0]>='A' && res[0]<='Z'))) {
    res[0] = '_';
  }
  for (i=1; i<len; i++) {
    if (!((res[i]>='a' && res[i]<='z') || (res[i]>='A' && res[i]<='Z') || (res[i]>='0' && res[i]<='9'))) {
      res[i] = '_';
    }
  }
  return res;
}

extern int System_stringFind(const char* str, const char* searchStr)
{
  const char *found = strstr(str, searchStr);
  if (found == NULL)
    return -1;
  else
    return found-str;
}

extern const char* System_stringFindString(const char* str, const char* searchStr)
{
  const char *found = strstr(str, searchStr);
  if (found == NULL)
    MMC_THROW();
  return strcpy(ModelicaAllocateString(strlen(found)), found);
}

extern void System_realtimeTick(int ix)
{
  if (ix < 0 || ix >= NUM_USER_RT_CLOCKS) MMC_THROW();
  rt_tick(ix);
}

extern double System_realtimeTock(int ix)
{
  if (ix < 0 || ix >= NUM_USER_RT_CLOCKS) MMC_THROW();
  return rt_tock(ix);
}

extern void System_realtimeClear(int ix)
{
  if (ix < 0 || ix >= NUM_USER_RT_CLOCKS) MMC_THROW();
  rt_clear(ix);
}

extern double System_realtimeAccumulate(int ix)
{
  if (ix < 0 || ix >= NUM_USER_RT_CLOCKS) MMC_THROW();
  return rt_accumulate(ix);
}

extern double System_realtimeAccumulated(int ix)
{
  if (ix < 0 || ix >= NUM_USER_RT_CLOCKS) MMC_THROW();
  return rt_accumulated(ix);
}

extern int System_realtimeNtick(int ix)
{
  if (ix < 0 || ix >= NUM_USER_RT_CLOCKS) MMC_THROW();
  return rt_ncall(ix);
}

extern const char* System_getCCompiler()
{
  return cc;
}

extern const char* System_getCXXCompiler()
{
  return cxx;
}

extern const char* System_getOMPCCompiler()
{
  return omp_cc;
}

extern const char* System_getLinker()
{
  return linker;
}

extern const char* System_getLDFlags()
{
  return ldflags;
}

extern const char* System_getCFlags()
{
  return cflags;
}

extern const char* System_trim(const char* str, const char* chars_to_remove)
{
  return SystemImpl__trim(str,chars_to_remove);
}

extern const char* System_trimWhitespace(const char* str)
{
  return SystemImpl__trim(str," \f\n\r\t\v");
}

extern const char* System_trimChar(const char* str, const char* char_to_remove)
{
  if (!char_to_remove[0] || char_to_remove[1])
    MMC_THROW();
  return MMC_STRINGDATA(SystemImpl__trimChar(str,*char_to_remove));
}

extern const char* System_basename(const char* str)
{
  const char *res = SystemImpl__basename(str);
  return strcpy(ModelicaAllocateString(strlen(res)), res);
}

extern const char* System_dirname(const char* str)
{
  char *cpy = omc_alloc_interface.malloc_strdup(str);
  char *res = NULL;
#if defined(_MSC_VER)
  char drive[_MAX_DRIVE], dir[_MAX_DIR], filename[_MAX_FNAME], extension[_MAX_EXT];
  _splitpath(str, drive, dir, filename, extension);
  sprintf(cpy, "%s/%s/",drive,dir);
  res = cpy;
#else
  res = dirname(cpy);
#endif
  return res;
}

extern int System_strncmp(const char *str1, const char *str2, int len)
{
  int res= strncmp(str1,str2,len);
  /* adrpo: 2010-10-07, return -1, 0, +1 so we can pattern match on it directly! */
  if      (res>0) res =  1;
  else if (res<0) res = -1;
  return res;
}

extern int System_strcmp(const char *str1, const char *str2)
{
  int res = strcmp(str1,str2);
  /* adrpo: 2010-10-07, return -1, 0, +1 so we can pattern match on it directly! */
  if      (res>0) res =  1;
  else if (res<0) res = -1;
  return res;
}

extern int System_strcmp_offset(const char *str1, int offset1, int length1, const char *str2, int offset2, int length2)
{
  int n = length1 > length2 ? length1 : length2;
  int res = strncmp(str1+offset1-1, str2+offset2-1, n);
  if (res>0) res = 1;
  else if (res<0) res = -1;
  return res;
}

extern int System_getHasExpandableConnectors()
{
  return hasExpandableConnectors;
}

extern void System_setHasExpandableConnectors(int b)
{
  hasExpandableConnectors = b;
}

extern int System_getHasOverconstrainedConnectors()
{
  return hasOverconstrainedConnectors;
}

extern void System_setHasOverconstrainedConnectors(int b)
{
  hasOverconstrainedConnectors = b;
}

extern int System_getPartialInstantiation()
{
  return isPartialInstantiation;
}

extern void System_setPartialInstantiation(int b)
{
  isPartialInstantiation = b;
}

extern int System_getHasInnerOuterDefinitions()
{
  return hasInnerOuterDefinitions;
}

extern void System_setHasInnerOuterDefinitions(int b)
{
  hasInnerOuterDefinitions = b;
}

extern int System_getHasStreamConnectors()
{
  return hasStreamConnectors;
}

extern void System_setHasStreamConnectors(int b)
{
  hasStreamConnectors = b;
}

extern int System_getUsesCardinality()
{
  return usesCardinality;
}

extern void System_setUsesCardinality(int b)
{
  usesCardinality = b;
}

extern void* System_strtok(const char *str0, const char *delimit)
{
  char *s;
  void *res = mmc_mk_nil();
  char *str = omc_alloc_interface.malloc_strdup(str0);
  char *saveptr;
  s=strtok_r(str,delimit,&saveptr);
  if (s == NULL) {
    return res;
  }
  res = mmc_mk_cons(mmc_mk_scon(s),res);
  while ((s=strtok_r(NULL,delimit,&saveptr))) {
    res = mmc_mk_cons(mmc_mk_scon(s),res);
  }
  return listReverse(res);
}

extern char* System_substring(const char *str, int start, int stop)
{
  char* substring = NULL;
  int startIndex = start;
  int stopIndex = stop;
  int len1 = strlen(str);
  int len2 = 0;
  void *res = NULL;

  /* Check arguments */
  if ( startIndex < 1 )
  {
    MMC_THROW();
  }
  if ( stopIndex == -999 )
  {
    stopIndex = startIndex;
  } else if ( stopIndex < startIndex ) {
    MMC_THROW();
  } else if ( stopIndex > len1 ) {
    MMC_THROW();
  }

  /* Allocate memory and copy string */
  len2 = stopIndex - startIndex + 1;
  substring = (char*)ModelicaAllocateString(len2);
  strncpy(substring, &str[startIndex-1], len2);
  substring[len2] = '\0';

  return substring;
}

extern char* System_toupper(const char *str)
{
  int i;
  char* strToUpper = strcpy(ModelicaAllocateString(strlen(str)),str);
  for (i = 0; i < strlen(strToUpper); i++)
  {
    strToUpper[i] = toupper(strToUpper[i]);
  }
  return strToUpper;
}

extern char* System_tolower(const char *str)
{
  int i;
  char* strToLower = strcpy(ModelicaAllocateString(strlen(str)),str);
  for (i = 0; i < strlen(strToLower); i++)
  {
    strToLower[i] = tolower(strToLower[i]);
  }
  return strToLower;
}

const char* System_getClassnamesForSimulation()
{
  if(class_names_for_simulation)
    return strcpy(ModelicaAllocateString(strlen(class_names_for_simulation)),class_names_for_simulation);
  else
    return "{}";
}

void System_setClassnamesForSimulation(const char *class_names)
{
  class_names_for_simulation = omc_alloc_interface.malloc_strdup(class_names);
}

extern double System_getVariableValue(double _timeStamp, void* _timeValues, void* _varValues)
{
  double res = 0;
  if (SystemImpl__getVariableValue(_timeStamp,_timeValues,_varValues,&res))
    MMC_THROW();
  return res;
}

extern void* System_getFileModificationTime(const char *fileName)
{
  omc_stat_t attrib;
  double elapsedTime;    // the time elapsed as double
  int result;            // the result of the function call

  if (omc_stat( fileName, &attrib ) != 0) {
    return mmc_mk_none();
  } else {
    return mmc_mk_some(mmc_mk_rcon(difftime(attrib.st_mtime, 0))); // the file modification time
  }
}

#if defined(__MINGW32__) || defined(_MSC_VER)
/**
 * @brief Scan directory for package files with given pattern except for packageName.
 *
 * @param directory     Directory to search in
 * @param pattern       Pattern to search for, e.g. "*.mo" or "*.moc".
 * @param packageName   Name of packages, e.g. "package.mo" or "package.moc"
 * @return void*        List of file names matching pattern.
 */
void* omc_scanDirForPackagePattern(const char* directory, const char* pattern, const wchar_t* packageName)
{
  void *res;
  WIN32_FIND_DATAW FileData;
  BOOL more = TRUE;
  HANDLE sh;
  char pattern_mb[1024];

  // TODO: Use longabspath for path longer than MAX_PATH
  //wchar_t* unicodeAbsDirectory = longabspath(directory);
  sprintf(pattern_mb, "%s\\%s", directory, pattern);

  wchar_t* pattern_uc = omc_multibyte_to_wchar_str(pattern_mb);
  sh = FindFirstFileW(pattern_uc, &FileData);
  free(pattern_uc);

  res = mmc_mk_nil();
  if (sh != INVALID_HANDLE_VALUE) {
    while(more) {
      if (wcscmp(FileData.cFileName, packageName) != 0)
      {
        char* file_name_mb = omc_wchar_to_multibyte_str(FileData.cFileName);
        res = mmc_mk_cons(mmc_mk_scon(file_name_mb),res);
        free(file_name_mb);
      }
      more = FindNextFileW(sh, &FileData);
    }
    if (sh != INVALID_HANDLE_VALUE) FindClose(sh);
  }


  return res;
}
#endif

/**
 * @brief Scan directory for .mo files excluding package.mo.
 *
 * @param directory   Directory to search in.
 * @return void*      List of file names.
 */
void* System_moFiles(const char *directory)
#if defined(__MINGW32__) || defined(_MSC_VER)
{
  return omc_scanDirForPackagePattern(directory, "*.mo", L"package.mo");
}
#else
{
  int i,count;
  void *res;
  struct dirent **files = NULL;
  select_from_dir = directory;
  count = scandir(directory, &files, file_select_mo, NULL);
  res = mmc_mk_nil();
  for (i=0; i<count; i++)
  {
    res = mmc_mk_cons(mmc_mk_scon(files[i]->d_name),res);
    free(files[i]);
  }
  free(files);
  return res;
}
#endif

/**
 * @brief Scan directory for .moc files excluding package.moc.
 *
 * @param directory   Directory to search in.
 * @return void*      List of file names.
 */
void* System_mocFiles(const char *directory)
#if defined(__MINGW32__) || defined(_MSC_VER)
{
  return omc_scanDirForPackagePattern(directory, "*.moc", L"package.moc");
}
#else
{
  int i,count;
  void *res;
  struct dirent **files = NULL;
  select_from_dir = directory;
  count = scandir(directory, &files, file_select_moc, NULL);
  res = mmc_mk_nil();
  for (i=0; i<count; i++)
  {
    res = mmc_mk_cons(mmc_mk_scon(files[i]->d_name),res);
    free(files[i]);
  }
  free(files);
  return res;
}
#endif

extern int System_lookupFunction(int _inLibHandle, const char* _inFunc)
{
  int res = SystemImpl__lookupFunction(_inLibHandle, _inFunc);
  if (res == -1) MMC_THROW();
  return res;
}

extern void System_freeFunction(int _inFuncHandle, int printDebug)
{
  if (SystemImpl__freeFunction(_inFuncHandle, printDebug)) MMC_THROW();
}

extern void System_freeLibrary(int _inLibHandle, int printDebug)
{
  if (SystemImpl__freeLibrary(_inLibHandle, printDebug)) MMC_THROW();
}

extern int System_userIsRoot()
{
  return CONFIG_USER_IS_ROOT;
}

extern int System_getuid()
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  return 0;
#else
  return getuid();
#endif
}

extern const char* System_readEnv(const char *envname)
{
  char *envvalue = getenv(envname);
  if (envvalue == NULL) MMC_THROW();
  return strcpy(ModelicaAllocateString(strlen(envvalue)),envvalue);
}

extern void System_getCurrentDateTime(int* sec, int* min, int* hour, int* mday, int* mon, int* year)
{
  time_t t;
  struct tm* localTime;
  time( &t );
  localTime = localtime(&t);
  *sec = localTime->tm_sec;
  *min = localTime->tm_min;
  *hour = localTime->tm_hour;
  *mday = localTime->tm_mday;
  *mon = localTime->tm_mon + 1;
  *year = localTime->tm_year + 1900;
}

extern const char* System_getUUIDStr()
{
  const char *res =  SystemImpl__getUUIDStr();
  return strcpy(ModelicaAllocateString(strlen(res)),res);
}

extern int System_loadLibrary(const char *name, int relativePath, int printDebug)
{
  int res = SystemImpl__loadLibrary(name, relativePath, printDebug);
  if (res == -1) MMC_THROW();
  return res;
}

#if defined(__MINGW32__) || defined(_MSC_VER)
void* System_subDirectories(const char *directory)
{
  void *res;
  WIN32_FIND_DATAW FileData;
  BOOL more = TRUE;
  char pattern_mb[1024];
  HANDLE sh;

  sprintf(pattern_mb, "%s\\*.*", directory);

  wchar_t* pattern_uc = omc_multibyte_to_wchar_str(pattern_mb);
  sh = FindFirstFileW(pattern_uc, &FileData);
  free(pattern_uc);

  res = mmc_mk_nil();
  if (sh != INVALID_HANDLE_VALUE) {
    while(more) {
      if (wcscmp(FileData.cFileName,L"..") != 0 &&
        wcscmp(FileData.cFileName,L".") != 0 &&
        (FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0)
      {
        char* dir_name_mb = omc_wchar_to_multibyte_str(FileData.cFileName);
        res = mmc_mk_cons(mmc_mk_scon(dir_name_mb),res);
        free(dir_name_mb);

      }
      more = FindNextFileW(sh, &FileData);
    }
    if (sh != INVALID_HANDLE_VALUE) FindClose(sh);
  }
  return res;
}
#else
void* System_subDirectories(const char *directory)
{
  int i,count;
  void *res;
  struct dirent **files = NULL;
  select_from_dir = directory;
  count = scandir(directory, &files, file_select_directories, NULL);
  res = mmc_mk_nil();
  for (i=0; i<count; i++)
  {
    res = mmc_mk_cons(mmc_mk_scon(files[i]->d_name),res);
    free(files[i]);
  }
  free(files);
  return res;
}
#endif

extern void* System_regex(const char* str, const char* re, int maxn, int extended, int sensitive, int *nmatch)
{
  void *res;
  int i = 0;
  void **matches = omc_alloc_interface.malloc(sizeof(void*)*maxn);
  *nmatch = OpenModelica_regexImpl(str,re,maxn,extended,sensitive,mmc_mk_scon,(void**)matches);
  res = mmc_mk_nil();
  for (i=maxn-1; i>=0; i--) {
    res = mmc_mk_cons(matches[i],res);
  }

  GC_free(matches);
  return res;
}

extern char* System_escapedString(char* str, int nl)
{
  char *res = omc__escapedString(str,nl);
  if (res == NULL) return str;
  return res;
}

extern char* System_unescapedString(char* str)
{
  char *res = SystemImpl__unescapedString(str);
  if (res == NULL) return str;
  return res;
}

extern char* System_unquoteIdentifier(char *str)
{
  return SystemImpl__unquoteIdentifier(str);
}

extern char* System_getCurrentTimeStr()
{
  time_t t;
  struct tm* localTime;
  char * dateStr;
  time( &t );
  localTime = localtime(&t);
  dateStr = asctime(localTime);
  if (dateStr)
    return dateStr;
  MMC_THROW();
}

void System_resetTimer()
{
  /* reset the timer */
  timerIntervalTime = 0;
  timerCummulatedTime = 0;
  timerTime = 0;
  timerStackIdx = 0;
}

void System_startTimer()
{
  /* start the timer if not already started */
  if (!timerStackIdx)
  {
    rt_tick(RT_CLOCK_SPECIAL_STOPWATCH);
  }
  pushTimerStack();
}

void System_stopTimer()
{
  popTimerStack();
}

double System_getTimerElapsedTime()
{
  /* get the cummulated timer time */
  return rt_tock(RT_CLOCK_SPECIAL_STOPWATCH) - timerStack[0];
}

double System_getTimerIntervalTime()
{
  return timerIntervalTime;
}

double System_getTimerCummulatedTime()
{
  return timerCummulatedTime;
}

int System_getTimerStackIndex()
{
  return timerStackIdx;
}

extern void System_uriToClassAndPath(const char *uri, const char **scheme, char **name, char **path)
{
  int res = SystemImpl__uriToClassAndPath(uri, scheme, name, path);
  // TODO: Fix memory leak by using the external interface
  if (res) MMC_THROW();
}

extern const char* System_modelicaPlatform()
{
  return CONFIG_MODELICA_SPEC_PLATFORM;
}

/**
 * @brief Returns platform OpenModelica is compiled for.
 *
 * Returns CONFIG_OPENMODELICA_SPEC_PLATFORM defined in omc_config.h
 *
 * @return const char* platform specifier
 */
extern const char* System_openModelicaPlatform()
{
  return CONFIG_OPENMODELICA_SPEC_PLATFORM;
}

/**
 * @brief Returns the alternative platform OpenModelica is compiled for.
 *
 * Returns CONFIG_OPENMODELICA_SPEC_PLATFORM_ALTERNATIVE defined in omc_config.h
 *
 * @return const char* platform specifier
 */
extern const char* System_openModelicaPlatformAlternative()
{
  return CONFIG_OPENMODELICA_SPEC_PLATFORM_ALTERNATIVE;
}


extern const char* System_gccDumpMachine()
{
  return CONFIG_GCC_DUMPMACHINE;
}

extern const char* System_gccVersion()
{
  return CONFIG_GCC_VERSION;
}

extern void System_getGCStatus(double *used, double *allocated)
{
  *allocated = GC_get_heap_size();
  *used = *allocated - GC_get_free_bytes();
}

extern const char* System_snprintff(const char *fmt, int len, double d)
{
  char *buf;
  if (len < 0) {
    MMC_THROW();
  }
  buf = ModelicaAllocateString(len);

  int str_len = snprintf(buf, len + 1, fmt, d);

  if (str_len < 0) {
    fprintf(stderr, "System_snprintff: Encoding error.\n");
    MMC_THROW();
  }

  if (str_len > len) {
    fprintf(stderr, "System_snprintff: The formatted string would have length %d but the buffer only has room for %d characters.\n", str_len, len);
    MMC_THROW();
  }

  return buf;
}

extern const char* System_sprintff(const char *fmt, double d)
{
  char *buf;
  const int len = 20;
  buf = ModelicaAllocateString(len);

  int str_len = snprintf(buf, len + 1, fmt, d);

  if (str_len < 0) {
    fprintf(stderr, "System_sprintff: Encoding error.\n");
    MMC_THROW();
  }

  if (str_len > len) {
    buf = ModelicaAllocateString(str_len);
    snprintf(buf, str_len + 1, fmt, d);
  }

  return buf;
}

extern const char* System_realpath(const char *path)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  wchar_t* unicodePath = omc_multibyte_to_wchar_str(path);

  DWORD bufLen = 0;
  bufLen = GetFullPathNameW(unicodePath, bufLen, NULL, NULL);
  if (!bufLen) {
    fprintf(stderr, "GetFullPathNameW failed. %lu\n", GetLastError());
    MMC_THROW();
  }

  wchar_t* unicodeFullPath = (wchar_t*) omc_alloc_interface.malloc_atomic(sizeof(wchar_t) * bufLen);
  int success = GetFullPathNameW(unicodePath, bufLen, unicodeFullPath, NULL);
  free(unicodePath);

  if (!success) {
    fprintf(stderr, "GetFullPathNameW failed. %lu\n", GetLastError());
    MMC_THROW();
  }

  char* buffer = omc_wchar_to_multibyte_str(unicodeFullPath);
  // This seems like it is an overkill. If all we need is the length then strlen on the 'buffer' above should suffice.
  // I am leaving it like this for now since this was what was being done by the macro WIDECHAR_TO_MULTIBYTE_LENGTH
  int bufferLength = WideCharToMultiByte(CP_UTF8, 0, unicodeFullPath, -1, NULL, 0, NULL, NULL);
  SystemImpl__toWindowsSeperators(buffer, bufferLength);
  char *res = omc_alloc_interface.malloc_strdup(buffer);
  free(buffer);

  GC_free(unicodeFullPath);
  return res;
#else
  char buf[PATH_MAX];
  if (realpath(path, buf) == NULL) {
    fprintf(stderr, "System_realpath failed.\n");
    switch (errno)
    {
    case EACCES:
      fprintf(stderr, "Read or search permission was denied for a component of the path prefix.\n");
      break;
    case EINVAL:
      fprintf(stderr, "path is NULL.\n");
      break;
    case EIO:
      fprintf(stderr, "An I/O error occurred while reading from the filesystem.\n");
      break;
    case ELOOP:
      fprintf(stderr, "Too many symbolic links were encountered in translating the pathname.\n");
      break;
    case ENAMETOOLONG:
      fprintf(stderr, "A component of a pathname exceeded %u characters, or an entire pathname exceeded %u characters.\n", NAME_MAX, PATH_MAX);
      break;
    case ENOENT:
      fprintf(stderr, "The named file does not exist.\n");
      break;
    case ENOMEM:
      fprintf(stderr, "Out of memory.\n");
      break;
    case ENOTDIR:
      fprintf(stderr, "A component of the path prefix is not a directory.\n");
      break;
    default:
      break;
    }
    MMC_THROW();
  }
  return omc_alloc_interface.malloc_strdup(buf);
#endif
}

extern int System_fileIsNewerThan(const char *file1, const char *file2)
{
  int res = SystemImpl__fileIsNewerThan(file1, file2);
  if (res == -1)
    MMC_THROW();
  return res;
}

typedef void* voidp;

/* Work in progress: Threading support in OMC */
typedef struct thread_data {
  pthread_mutex_t mutex;
  modelica_metatype (*fn)(threadData_t*,modelica_metatype);
  int fail;
  int current;
  int len;
  void **commands;
  void **status;
  threadData_t *parent;
} thread_data;

static void* System_launchParallelTasksThread(void *in)
{
  int exitstatus = 1;
  int n;
  thread_data *data = (thread_data*) in;
  while (1) {
    int fail = 1;
    pthread_mutex_lock(&data->mutex);
    n = data->current++;
    pthread_mutex_unlock(&data->mutex);
    if (data->fail || n >= data->len) break;
    MMC_TRY_TOP()
    threadData->parent = data->parent;
    threadData->mmc_thread_work_exit = threadData->mmc_jumper;
    data->status[n] = data->fn(threadData,data->commands[n]);
    fail = 0;
    MMC_CATCH_TOP()
    if (fail) {
      data->fail = 1;
    }
  }
  return NULL;
}

static void* System_launchParallelTasksSerial(threadData_t *threadData, void *dataLst, modelica_metatype (*fn)(threadData_t *,modelica_metatype))
{
  void *result = mmc_mk_nil();
  while (!listEmpty(dataLst)) {
    result = mmc_mk_cons(fn(threadData, MMC_CAR(dataLst)),result);
    dataLst = MMC_CDR(dataLst);
  }
  return listReverse(dataLst);
}

extern void* System_launchParallelTasks(threadData_t *threadData, int numThreads, void *dataLst, modelica_metatype (*fn)(threadData_t *,modelica_metatype))
{
  int i;
  size_t len = listLength(dataLst);
  void *result = mmc_mk_nil();
  thread_data data = {0};
  int isInteger = 0;
  pthread_attr_t* attr_addr = NULL;

  void **commands = (void**) omc_alloc_interface.malloc(sizeof(void*)*len);
  void **status = (void**) omc_alloc_interface.malloc(sizeof(void*)*len);
  pthread_t *th = (pthread_t*) omc_alloc_interface.malloc(sizeof(pthread_t)*numThreads);

#if defined(__MINGW32__)
  pthread_attr_t attr;
  attr_addr = &attr;
  if (pthread_attr_init(attr_addr))
  {
    const char *tok[1] = {strerror(errno)};
    data.fail = 1;
    c_add_message(NULL,5999,
      ErrorType_scripting,
      ErrorLevel_internal,
      gettext("System.launchParallelTasks: failed to initialize the pthread attributes: %s"),
      tok,
      1);
    MMC_THROW_INTERNAL();
  }

  /* adrpo: set thread stack size on Windows to 4MB */
  /* try to set a stack size of 4MB, if not then 2MB, if not then 1MB, if not then fail */
  /* Rely on left to right Short Circuit Evaluation, i.e, shorts on the first true. */
  if (pthread_attr_setstacksize(attr_addr, 4194304) ||
      pthread_attr_setstacksize(attr_addr, 2097152) ||
      pthread_attr_setstacksize(attr_addr, 1048576))
  {
        const char *tok[1] = {strerror(errno)};
        data.fail = 1;
        c_add_message(NULL,5999,
          ErrorType_scripting,
          ErrorLevel_internal,
          gettext("System.launchParallelTasks: failed to set the pthread stack size to 1MB: %s"),
          tok,
          1);
        MMC_THROW_INTERNAL();
  }
#endif

  if (len == 0) {
    return mmc_mk_nil();
  } else if (numThreads == 1 || len == 1) {
    return System_launchParallelTasksSerial(threadData,dataLst,fn);
  }

  /* Make sure we get nothing unexpected here */
  memset(commands, 0, len*sizeof(void*));
  memset(status, 0, len*sizeof(void*));
  memset(th, 0, numThreads*sizeof(pthread_t));

  pthread_mutex_init(&data.mutex,NULL);
  data.fn = fn;
  data.current = 0;
  data.len = len;
  data.commands = commands;
  data.status = status;
  data.fail = 0;
  data.parent = threadData;
  for (i=0; i<len; i++, dataLst = MMC_CDR(dataLst)) {
    commands[i] = MMC_CAR(dataLst);
    status[i] = 0; /* just in case */
  }
  numThreads = numThreads > len ? len : numThreads;
  unsigned int live_threads = 0;
  for (i=0; i < numThreads; i++) {
    if (GC_pthread_create(&th[i], attr_addr, System_launchParallelTasksThread,&data)) {
      /* GC_pthread_create failed. We need to join already created threads though... */
      const char *tok[1] = {strerror(errno)};
      data.fail = 1;
      c_add_message(NULL,5999,
        ErrorType_scripting,
        ErrorLevel_internal,
        gettext("System.launchParallelTasks: Failed to create thread: %s"),
        tok,
        1);
      break;
    }
    live_threads++;
  }

#if defined(__MINGW32__)
  pthread_attr_destroy(attr_addr);
#endif

  for (i=0; i < live_threads; i++) {
    if (GC_pthread_join(th[i], NULL)) {
      const char *tok[1] = {strerror(errno)};
      data.fail = 1;
      c_add_message(NULL,5999,
        ErrorType_scripting,
        ErrorLevel_internal,
        gettext("System.launchParallelTasks: Failed to join thread: %s"),
        tok,
        1);
    }
  }
  if (data.fail) {
    MMC_THROW_INTERNAL();
  }
  if (data.current < len) {
    c_add_message(NULL,5999,
      ErrorType_scripting,
      ErrorLevel_internal,
      gettext("System.launchParallelTasks: We seem to have executed fewer tasks than expected."),
      NULL,
      0);
    MMC_THROW_INTERNAL();
  }
  isInteger = MMC_IS_INTEGER(status[0]);
  for (i=len-1; i>=0; i--) {
    if (isInteger != MMC_IS_INTEGER(status[i])) {
      c_add_message(NULL,5999,
        ErrorType_scripting,
        ErrorLevel_internal,
        gettext("System.launchParallelTasks: Got mismatched results types. Was there a thread synchronization error?"),
        NULL,
        0);
      MMC_THROW_INTERNAL();
    }
    result = mmc_mk_cons(status[i], result);
  }
  return result;
}

void System_initGarbageCollector(void)
{
  SystemImpl__initGarbageCollector();
}

void System_threadFail(threadData_t *threadData)
{
  if (0 == threadData->mmc_thread_work_exit) {
    fprintf(stderr, "System_threadFail called in something that is not a worker thread!\nThe application will now exit!\n");
    abort();
  }
  longjmp(*threadData->mmc_thread_work_exit,1);
}

/* TODO: Remove once we make a new tarball */
int System_isRML()
{
  return 0;
}

extern void* System_splitOnNewline(const char *str, int includeDelimiter)
{
  const char *start = str;
  const char *current = start;
  size_t sz;
  void *lst = mmc_mk_nil();

  while (*current != '\0') {
    // Split on \n and \r\n.
    if (*current == '\n' || (*current == '\r' && *(current + 1) == '\n')) {
      sz = current - start;

      // Save the string up to the newline.
      if (sz > 0) {
        lst = mmc_mk_cons(mmc_mk_scon_n(start, sz), lst);
      }

      // Is the newline one character (\n) or two (\r\n)?
      if (*current == '\r' && *(current + 1) == '\n') {
        sz = 2;
      } else {
        sz = 1;
      }

      // Save the newline if includeDelimiter = true.
      if (includeDelimiter) {
        lst = mmc_mk_cons(mmc_mk_scon_n(current, sz), lst);
      }

      // Move to the next character after the newline.
      current += sz;
      start = current;
    } else {
      ++current;
    }
  }

  // Save the rest of the string if there's anything left.
  if (current != start) {
    lst = mmc_mk_cons(mmc_mk_scon_n(start, current - start), lst);
  }

  return listReverse(lst);
}

extern void* System_strtokIncludingDelimiters(const char *str0, const char *delimit)
{
  char* str = (char*)str0;
  mmc_uint_t len = strlen(str);
  char* cp = NULL;
  char *d = (char*)delimit;
  mmc_uint_t dlen = strlen(d);
  void *lst = mmc_mk_nil();
  void *slst = mmc_mk_nil();
  char* s = str;
  char* stmp;
  mmc_uint_t start = 0, end = 0;
  /* len + 3 in pos signifies that there is no delimiter in the string */
  mmc_uint_t pos = len + 3;

  /* fail if delimiter is bigger than string */
  if (dlen > len)
  {
     MMC_THROW();
  }

  /* add 0 to the list! */
  lst = mmc_mk_cons(mmc_mk_icon(0), lst);

  /* find the first delimiter */
  while ((cp = strstr(s, d)) != NULL)
  {
    s = cp + dlen;
    pos = (cp - str);
    /* check if the position is already in the list */
    /* in the list add only the end */
    if (pos == MMC_UNTAGFIXNUM(MMC_CAR(lst)))
    {
      lst = mmc_mk_cons(mmc_mk_icon((mmc_sint_t)(void*)(pos+dlen)), lst);
    }
    else /* not in the list, add both */
    {
      lst = mmc_mk_cons(mmc_mk_icon(pos), lst);
      lst = mmc_mk_cons(mmc_mk_icon((mmc_sint_t)(void*)(pos+dlen)), lst);
    }
  }
  /* this means it was not found in the entire string */
  if (pos == (len + 3))
  {
    /* return the empty list */
    return slst;
  }

  /* add len to the list! */
  if ((len) != MMC_UNTAGFIXNUM(MMC_CAR(lst)))
  {
    lst = mmc_mk_cons(mmc_mk_icon(len), lst);
  }

  /*
   * BIG NOTE! the list of indexes is reversed, it starts closer to len!
   */
  /* now we walk the list and build the string list */
  while( MMC_GETHDR(lst) == MMC_CONSHDR )
  {
    end = MMC_UNTAGFIXNUM(MMC_CAR(lst));
    lst = MMC_CDR(lst);
    /* break if we reached the last in the list */
    if (MMC_GETHDR(lst) == MMC_NILHDR)
    {
      break;
    }
    start = MMC_UNTAGFIXNUM(MMC_CAR(lst));
    /* create stmp */
    pos = end - start;
    stmp = (char*)malloc((pos+1) * sizeof(char));
    strncpy(stmp, str + start, pos);
    stmp[pos] = '\0';
    slst = mmc_mk_cons(mmc_mk_scon(stmp), slst);
    free(stmp);
  }
  return slst;
}

#ifdef __cplusplus
}
#endif
