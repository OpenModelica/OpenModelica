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

#if defined(_MSC_VER)
#include <Windows.h>
#endif

#ifdef __cplusplus
extern "C"
{
#endif

#include <ctype.h> /* for toupper */
#include <limits.h>
#include <stdlib.h>
#include "omc_msvc.h"
#include "openmodelica.h"
#include "meta_modelica.h"
#include "rml_compatibility.h"
#include "ModelicaUtilities.h"
#define ADD_METARECORD_DEFINITIONS static
#include "OpenModelicaBootstrappingHeader.h"
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

extern int System_realtimeNtick(int ix)
{
  if (ix < 0 || ix >= NUM_USER_RT_CLOCKS) MMC_THROW();
  return rt_ncall(ix);
}

extern const char* System_getRTLibs()
{
  return LDFLAGS_RT;
}

extern const char* System_getRTLibsSim()
{
  return LDFLAGS_RT_SIM;
}

extern const char* System_getCCompiler()
{
  return GC_strdup(cc);
}

extern const char* System_getCXXCompiler()
{
  return GC_strdup(cxx);
}

extern const char* System_getOMPCCompiler()
{
  return GC_strdup(omp_cc);
}

extern const char* System_getLinker()
{
  return GC_strdup(linker);
}

extern const char* System_getLDFlags()
{
  return GC_strdup(ldflags);
}

extern const char* System_getCFlags()
{
  return GC_strdup(cflags);
}

extern const char* System_getExeExt()
{
  return CONFIG_EXE_EXT;
}

extern const char* System_getDllExt()
{
  return CONFIG_DLL_EXT;
}

extern const char* System_os()
{
  return CONFIG_OS;
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
  char *cpy = GC_strdup(str);
  char *res = NULL;
#if defined(_MSC_VER)
  char drive[_MAX_DRIVE], dir[_MAX_DIR], filename[_MAX_FNAME], extension[_MAX_EXT];
  _splitpath(str, drive, dir, filename, extension);
  sprintf(cpy, "%s/%s/",drive,dir);
  res = cpy;
#else
  res = dirname(cpy);
#endif
  res = GC_strdup(res);
  return res;
}

extern const char* System_configureCommandLine()
{
  return CONFIGURE_COMMANDLINE;
}

extern const char* System_platform()
{
  return CONFIG_PLATFORM;
}

extern const char* System_pathDelimiter()
{
  return CONFIG_PATH_DELIMITER;
}

extern const char* System_groupDelimiter()
{
  return CONFIG_GROUP_DELIMITER;
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

extern int System_getHasExpandableConnectors()
{
  return hasExpandableConnectors;
}

extern void System_setHasExpandableConnectors(int b)
{
  hasExpandableConnectors = b;
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
  char *str = GC_strdup(str0);
  s=strtok(str,delimit);
  if (s == NULL) {
    return res;
  }
  res = mmc_mk_cons(mmc_mk_scon(s),res);
  while ((s=strtok(NULL,delimit))) {
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
  class_names_for_simulation = GC_strdup(class_names);
}

extern double System_getVariableValue(double _timeStamp, void* _timeValues, void* _varValues)
{
  double res;
  if (SystemImpl__getVariableValue(_timeStamp,_timeValues,_varValues,&res))
    MMC_THROW();
  return res;
}

extern void* System_getFileModificationTime(const char *fileName)
{
  struct stat attrib;   // create a file attribute structure
  double elapsedTime;    // the time elapsed as double
  int result;            // the result of the function call

  if (stat( fileName, &attrib ) != 0) {
    return mmc_mk_none();
  } else {
    return mmc_mk_some(mmc_mk_rcon(difftime(attrib.st_mtime, 0))); // the file modification time
  }
}

#if defined(__MINGW32__) || defined(_MSC_VER)
void* System_moFiles(const char *directory)
{
  void *res;
  WIN32_FIND_DATA FileData;
  BOOL more = TRUE;
  char pattern[1024];
  HANDLE sh;
  sprintf(pattern, "%s\\*.mo", directory);
  res = mmc_mk_nil();
  sh = FindFirstFile(pattern, &FileData);
  if (sh != INVALID_HANDLE_VALUE) {
    while(more) {
      if (strcmp(FileData.cFileName,"package.mo") != 0)
      {
        res = mmc_mk_cons(mmc_mk_scon(FileData.cFileName),res);
      }
      more = FindNextFile(sh, &FileData);
    }
    if (sh != INVALID_HANDLE_VALUE) FindClose(sh);
  }
  return res;
}
#else
void* System_moFiles(const char *directory)
{
  int i,count;
  void *res;
  struct dirent **files;
  select_from_dir = directory;
  count = scandir(directory, &files, file_select_mo, NULL);
  res = mmc_mk_nil();
  for (i=0; i<count; i++)
  {
    res = mmc_mk_cons(mmc_mk_scon(files[i]->d_name),res);
    free(files[i]);
  }
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

extern int System_loadLibrary(const char *name, int printDebug)
{
  int res = SystemImpl__loadLibrary(name, printDebug);
  if (res == -1) MMC_THROW();
  return res;
}

#if defined(__MINGW32__) || defined(_MSC_VER)
void* System_subDirectories(const char *directory)
{
  void *res;
  WIN32_FIND_DATA FileData;
  BOOL more = TRUE;
  char pattern[1024];
  HANDLE sh;

  sprintf(pattern, "%s\\*.*", directory);

  res = mmc_mk_nil();
  sh = FindFirstFile(pattern, &FileData);
  if (sh != INVALID_HANDLE_VALUE) {
    while(more) {
      if (strcmp(FileData.cFileName,"..") != 0 &&
        strcmp(FileData.cFileName,".") != 0 &&
        (FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0)
      {
          res = mmc_mk_cons(mmc_mk_scon(FileData.cFileName),res);
      }
      more = FindNextFile(sh, &FileData);
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
  struct dirent **files;
  select_from_dir = directory;
  count = scandir(directory, &files, file_select_directories, NULL);
  res = mmc_mk_nil();
  for (i=0; i<count; i++)
  {
    res = mmc_mk_cons(mmc_mk_scon(files[i]->d_name),res);
    free(files[i]);
  }
  return res;
}
#endif

extern const char* System_getCorbaLibs()
{
  return CONFIG_CORBALIBS;
}

extern void* System_getRuntimeLibs()
{
  return CONFIG_SYSTEMLIBS;
}

extern void* System_regex(const char* str, const char* re, int maxn, int extended, int sensitive, int *nmatch)
{
  void *res;
  int i = 0;
  void *matches[maxn];
  *nmatch = OpenModelica_regexImpl(str,re,maxn,extended,sensitive,mmc_mk_scon,(void**)&matches);
  res = mmc_mk_nil();
  for (i=maxn-1; i>=0; i--) {
    res = mmc_mk_cons(matches[i],res);
  }
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
  char *res = SystemImpl__unquoteIdentifier(str);
  if (res == NULL) return str;
  return res;
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

extern const char* System_openModelicaPlatform()
{
  return CONFIG_OPENMODELICA_SPEC_PLATFORM;
}

extern void System_getGCStatus(int *used, int *allocated)
{
  *used = -1;
  *allocated = -1;
}

extern void System_getLoadModelPath(const char *className, void *prios, void *mps, const char **dir, char **name, int *isDir)
{
  *name = NULL;
  if (SystemImpl__getLoadModelPath(className,prios,mps,dir,name,isDir)) MMC_THROW();
  char *res = strcpy(ModelicaAllocateString(strlen(*name)),*name);
  *name = res;
}

extern const char* System_getMakeCommand()
{
  return DEFAULT_MAKE;
}

extern const char* System_snprintff(const char *fmt, int len, double d)
{
  char *buf;
  if (len < 0) {
    MMC_THROW();
  }
  buf = ModelicaAllocateString(len);
  if (snprintf(buf,len,fmt,d) >= len) {
    MMC_THROW();
  }
  return buf;
}

extern const char* System_realpath(const char *path)
{
  char buf[PATH_MAX];
  if (realpath(path, buf) == NULL)
    MMC_THROW();
  return init_modelica_string(buf);
}

extern int System_fileIsNewerThan(const char *file1, const char *file2)
{
  int res = SystemImpl__fileIsNewerThan(file1, file2);
  if (res == -1)
    MMC_THROW();
  return res;
}

/* Work in progress: Threading support in OMC */
typedef struct thread_data {
  pthread_mutex_t mutex;
  void (*fn)(void*,void*);
  int fail;
  int current;
  int len;
  void **commands;
  int *status;
} thread_data;

static void* System_forkCallThread(void *in)
{
  int exitstatus = 1;
  int n;
  thread_data *data = (thread_data*) in;
  while (1) {
    pthread_mutex_lock(&data->mutex);
    n = data->current++;
    pthread_mutex_unlock(&data->mutex);
    if (data->fail || data->current > data->len) break;
    MMC_TRY_TOP()
    threadData->mmc_thread_work_exit = threadData->mmc_jumper;
    data->fn(threadData,data->commands[n]);
    exitstatus = 0;
    MMC_CATCH_TOP()
    data->status[n] = ! exitstatus;
  }
  return NULL;
}

extern void* System_forkCall(int numThreads, void *dataLst, void (*fn)(void*))
{
  int len = listLength(dataLst), i;
  void *commands[len];
  int status[len], ids[len];
  void *result = mmc_mk_nil();
  pthread_t th[numThreads];
  thread_data data;
  pthread_mutex_init(&data.mutex,NULL);
  data.fn = fn;
  data.current = 0;
  data.len = len;
  data.commands = commands;
  data.status = status;
  data.fail = 0;
  for (i=0; i<len; i++, dataLst = MMC_CDR(dataLst)) {
    commands[i] = MMC_CAR(dataLst);
  }
  numThreads = min(numThreads,len);
  for (i=0; i<numThreads; i++) {
    GC_pthread_create(&th[i],NULL,System_forkCallThread,&data);
  }
  for (i=0; i<numThreads; i++) {
    GC_pthread_join(th[i], NULL);
  }
  for (i=len-1; i>=0; i--) {
    result = mmc_mk_cons(mmc_mk_icon(status[i]), result);
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
  longjmp(threadData->mmc_thread_work_exit,1);
}

#ifdef __cplusplus
}
#endif
