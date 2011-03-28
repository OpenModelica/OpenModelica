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

extern "C" {

#include "modelica.h"
#include "rml_compatibility.h"
#include "systemimpl.c"


extern void System_writeFile(const char* filename, const char* data)
{
  if (SystemImpl__writeFile(filename, data))
    MMC_THROW();
}

extern int System_removeFile(const char* filename)
{
  return SystemImpl__removeFile(filename);
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
  return strdup(found);
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

static modelica_integer tmp_tick_no = 0;

extern int System_tmpTick()
{
  return tmp_tick_no++;
}

extern void System_tmpTickReset(int start)
{
  tmp_tick_no = start;
}

extern const char* System_getSendDataLibs()
{
  return LDFLAGS_SENDDATA;
}

extern const char* System_getCCompiler()
{
  return strdup(cc);
}

extern const char* System_getCXXCompiler()
{
  return strdup(cxx);
}

extern const char* System_getLinker()
{
  return strdup(linker);
}

extern const char* System_getLDFlags()
{
  return strdup(ldflags);
}

extern const char* System_getCFlags()
{
  return strdup(cflags);
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

extern const char* System_basename(const char* str)
{
  return strdup(SystemImpl__basename(str));
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


extern void* System_strtok(const char *str0, const char *delimit)
{
  char *s;
  void *res = mmc_mk_nil();
  char *str = strdup(str0);
  s=strtok(str,delimit);
  if (s == NULL)
  {
    free(str);
    MMC_THROW();
  }
  res = mmc_mk_cons(mmc_mk_scon(s),res);
  while (s=strtok(NULL,delimit))
  {
    res = mmc_mk_cons(mmc_mk_scon(s),res);
  }
  free(str);
  return listReverse(res);
}

extern char* System_substring(const char *inStr, int start, int stop)
{
  static char* substring = NULL; // This function is not re-entrant... Note that the result will be overwritten at each call to substring...
  char* str = strdup(inStr);
  int startIndex = start;
  int stopIndex = stop;
  int len1 = strlen(str);
  int len2 = 0;
  void *res = NULL;

  /* Check arguments */
  if ( startIndex < 1 )
  {
    free(str);
    MMC_THROW();
  }
  if ( stopIndex == -999 )
  {
    stopIndex = startIndex;
  } else if ( stopIndex < startIndex ) {
    free(str);
    MMC_THROW();
  } else if ( stopIndex > len1 ) {
    free(str);
    MMC_THROW();
  }

  /* Allocate memory and copy string */
  if (substring) free(substring);
  len2 = stopIndex - startIndex + 1;
  substring = (char*)malloc(len2);
  strncpy(substring, &str[startIndex-1], len2);
  substring[len2] = '\0';

  return substring;
}

const char* System_getClassnamesForSimulation()
{
  if(class_names_for_simulation)
    return strdup(class_names_for_simulation);
  else
    return "{}";
}

void System_setClassnamesForSimulation(const char *class_names)
{
  if(class_names_for_simulation)
    free(class_names_for_simulation);
  class_names_for_simulation = strdup(class_names);
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

extern void System_freeFunction(int _inFuncHandle)
{
  if (SystemImpl__freeFunction(_inFuncHandle)) MMC_THROW();
}

extern void System_freeLibrary(int _inLibHandle)
{
  if (SystemImpl__freeLibrary(_inLibHandle)) MMC_THROW();
}

extern int System_getHasSendDataSupport()
{
#ifdef CONFIG_WITH_SENDDATA
  return 1;
#else
  return 0;
#endif
}

extern void System_sendData(const char* _data, const char* _title, const char* _xLabel, const char* _yLabel, const char* _interpolation, int _legend, int _grid, int _logX, int _logY, int _points, const char* _range)
{
#ifdef CONFIG_WITH_SENDDATA
  emulateStreamData(_data, _title, _xLabel, _yLabel , _interpolation, _legend, _grid, _logX, _logY, _points, _range);
#else
  addSendDataError("System.sendData");
  throw 1;
#endif
}

extern void System_sendData2(const char* _info, const char* _data, int _port)
{
#ifdef CONFIG_WITH_SENDDATA
  emulateStreamData2(_info, _data, _port);
#else
  addSendDataError("System.sendData2");
  throw 1;
#endif
}

extern int System_userIsRoot()
{
  return CONFIG_USER_IS_ROOT;
}

extern const char* System_readEnv(const char *envname)
{
  char *envvalue = getenv(envname);
  if (envvalue == NULL) MMC_THROW();
  return strdup(envvalue);
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
  return strdup(SystemImpl__getUUIDStr());
}

extern int System_loadLibrary(const char *name)
{
  int res = SystemImpl__loadLibrary(name);
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

extern void* System_regex(const char* str, const char* re, int maxn, int extended, int sensitive, int *nmatch)
{
  *nmatch = 0;
  void *res = SystemImpl__regex(str,re,maxn,extended,sensitive,nmatch);
  if (res==NULL) MMC_THROW();
  return res;
}

extern char* System_escapedString(char* str)
{
  char *res = SystemImpl__escapedString(str);
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

}
