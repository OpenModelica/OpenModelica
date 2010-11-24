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

/*
 * Common includes
 */
#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Platform specific includes and defines
 */
#if defined(__MINGW32__) || defined(_MSC_VER)
/* includes/defines specific for Windows*/
#include <assert.h>
#include <direct.h>

#define MAXPATHLEN MAX_PATH
#define S_IFLNK  0120000  /* symbolic link */

#include <rpc.h>
#else

/* includes/defines specific for LINUX/OS X */
#include <ctype.h>
#include <dirent.h>
#include <sys/param.h> /* MAXPATHLEN */
#include <sys/unistd.h>
#include <sys/wait.h> /* only available in Linux, not windows */
#include <unistd.h>
#include <dlfcn.h>

/* MacOS malloc.h is in sys */
#ifndef __APPLE_CC__
#include <malloc.h>
#else
#define HAVE_SCANDIR
#include <sys/malloc.h>
#endif

#ifndef _IFDIR
# ifdef S_IFDIR
#  define _IFDIR S_IFDIR
# else
#  error "Neither _IFDIR nor S_IFDIR is defined."
# endif
#endif
#endif

#include "rtclock.h"
#include "systemimpl.h"
#include "config.h"
#include "rtopts.h"
#include "errorext.h"

#define MAX_PTR_INDEX 10000
static struct modelica_ptr_s ptr_vector[MAX_PTR_INDEX];
static modelica_integer last_ptr_index = -1;

static inline modelica_integer alloc_ptr();
static inline void free_ptr(modelica_integer index);
static void free_library(modelica_ptr_t lib);
static void free_function(modelica_ptr_t func);

static char *cc     = (char*) DEFAULT_CC;
static char *cxx    = (char*) DEFAULT_CXX;
static char *linker = (char*) DEFAULT_LINKER;
static char *cflags = (char*) DEFAULT_CFLAGS;
static char *ldflags= (char*) DEFAULT_LDFLAGS;

static int hasExpandableConnector = 0;
static int hasInnerOuterDefinitions = 0;
static char* class_names_for_simulation = NULL;
static const char *select_from_dir = NULL;

/*
 * Common implementations
 */

static int stringContains(char *str,char c)
{
  int i;
  for(i=0;i<strlen(str);++i)
    if(str[i]==c){
      //printf(" (#%d / %d)contained '%c' ('%c', __%s__)\t",i,strlen(str),str[i],c,str);
      return 1;
    }
  return 0;
}

static int filterString(char* buf,char* bufRes)
{
  int res,i,bufPointer = 0,slen,isNumeric=0,numericEncounter=0;
  char preChar,cc;
  char filterChars[] = "0123456789.\0";
  char numeric[] = "0123456789\0";
  slen = strlen(buf);
  preChar = '\0';
  for(i=0;i<slen;++i) {
    cc = buf[i];
    if((stringContains(filterChars,buf[i]))) {
      if(buf[i]=='.') {
        if(stringContains(numeric,preChar) || (( i < slen+1) && stringContains(numeric,buf[i+1])) ) {
          if(isNumeric == 0) {isNumeric=1; numericEncounter++;}
          //printf("skipping_1: '%c'\n",buf[i]);
        } else {
          bufRes[bufPointer++] = buf[i];
          isNumeric=0;
        }
      } else {
        if(isNumeric == 0){isNumeric=1;numericEncounter++;}
        //printf("skipping_2: '%c'\n",buf[i]);
      }
    } else {
      bufRes[bufPointer++] = buf[i];
      isNumeric=0;
    }
    preChar = buf[i];
    //isNumeric=0;
  }
  bufRes[bufPointer++] = '\0';
  return numericEncounter;
}

extern int SystemImpl__setCCompiler(const char *str)
{
  size_t len = strlen(str);
  if (cc != NULL && cc != DEFAULT_CC) {
    free(cc);
  }
  cc = (char*)malloc(len+1);
  if (cc == NULL) return -1;
  memcpy(cc,str,len+1);
  return 0;
}

extern int SystemImpl__setCXXCompiler(const char *str)
{
  size_t len = strlen(str);
  if (cxx != NULL && cxx != DEFAULT_CXX) {
    free(cxx);
  }
  cxx = (char*)malloc(len+1);
  if (cxx == NULL) return -1;
  memcpy(cxx,str,len+1);
  return 0;
}

extern int SystemImpl__setLinker(const char *str)
{
  size_t len = strlen(str);
  if (linker != NULL && linker != DEFAULT_LINKER) {
    free(linker);
  }
  linker = (char*)malloc(len+1);
  if (linker == NULL) return -1;
  memcpy(linker,str,len+1);
  return 0;
}

extern int SystemImpl__setCFlags(const char *str)
{
  size_t len = strlen(str);
  if (cflags != NULL && cflags != DEFAULT_CFLAGS) {
    free(cflags);
  }
  cflags = (char*)malloc(len+1);
  if (cflags == NULL) return -1;
  memcpy(cflags,str,len+1);
  return 0;
}

extern int SystemImpl__setLDFlags(const char *str)
{
  size_t len = strlen(str);
  if (ldflags != NULL && ldflags != DEFAULT_LDFLAGS) {
    free(ldflags);
  }
  ldflags = (char*)malloc(len+1);
  if (ldflags == NULL) return -1;
  memcpy(ldflags,str,len+1);
  return 0;
}

extern int SystemImpl__regularFileExists(const char* str)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  int ret_val;
  void *res;
  WIN32_FIND_DATA FileData;
  HANDLE sh;

  sh = FindFirstFile(str, &FileData);
  if (sh == INVALID_HANDLE_VALUE) {
    return 0;
  }
  FindClose(sh);
  return ((FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0);
#else
  struct stat buf;
  if (stat(str, &buf)) return 0;
  return (buf.st_mode & S_IFREG) != 0;
#endif
}

extern int SystemImpl__regularFileWritable(const char* str)
{
  FILE *f;
  if (!SystemImpl__regularFileExists(str))
    return 0;
  f = fopen(str, "a");
  if (f == NULL)
    return 0;
  fclose(f);
  return 1;
}

static char* SystemImpl__readFile(const char* filename)
{
  char* buf;
  int res;
  FILE * file = NULL;
  struct stat statstr;
  res = stat(filename, &statstr);

  if(res!=0)
  {
    const char *c_tokens[1]={filename};
    c_add_message(85, /* ERROR_OPENING_FILE */
      "SCRIPTING",
      "ERROR",
      "Error opening file %s.",
      c_tokens,
      1);
    return strdup("No such file");
  }

  file = fopen(filename,"rb");
  buf = (char*) malloc(statstr.st_size+1);

  if( (res = fread(buf, sizeof(char), statstr.st_size, file)) != statstr.st_size)
  {
    free(buf);
    return strdup("Failed while reading file");
  }
  buf[statstr.st_size] = '\0';
  fclose(file);
  return buf;
}

/* returns 0 on success */
int SystemImpl__writeFile(const char* filename, const char* data)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  const char *fileOpenMode = "wt"; /* on Windows do translation so that \n becomes \r\n */
#else
  const char *fileOpenMode = "wb";  /* on Unixes don't bother, do it binary mode */
#endif
  FILE * file = NULL;
  int len = strlen(data); /* RML_HDRSTRLEN(RML_GETHDR(rmlA1)); */
  int x = 0;
  /* adrpo: 2010-09-22 open the file in BINARY mode as otherwise \r\n becomes \r\r\n! */
  file = fopen(filename,fileOpenMode);
  if (file == NULL) {
    const char *c_tokens[1]={filename};
    c_add_message(21, /* WRITING_FILE_ERROR */
      "SCRIPTING",
      "ERROR",
      "Error writing to file %s.",
      c_tokens,
      1);
    return 1;
  }
  /* nothing to write to file! just close it and return */
  if (len == 0)
  {
    fclose(file);
    return 0;
  }
  /*  write 1 element of size len to file and check for errors */
  if (1 != fwrite(data, len, 1, file))
  {
    const char *c_tokens[1]={filename};
    c_add_message(21, /* WRITING_FILE_ERROR */
      "SCRIPTING",
      "ERROR",
      "Error writing to file %s.",
      c_tokens,
      1);
    fclose(file);
    return 1;
  }
  fflush(file);
  fclose(file);
  return 0;
}

static int str_contain_char( const char* chars, const char chr)
{
  int length_of_chars = strlen(chars);
  int i;
  for(i = 0; i < length_of_chars; i++)
    {
      if(chr == chars[i])
        return 1;
    }
  return 0;
}

// Trim left (step -1) or right (step +1)
static const char* trimStep(const char* str, const char* chars_to_be_removed, int step)
{
  while ( *str && str_contain_char(chars_to_be_removed,*str) ) {
    str += step;
  }
  return str;
}

static char* SystemImpl__trim(const char* str, const char* chars_to_be_removed)
{
  int length;
  char *res;
  const char *str2;
  
  //fprintf(stderr, "trimming '%s' with '%s'\n", str, chars_to_be_removed);
  str = trimStep(str, chars_to_be_removed, 1);
  //fprintf(stderr, "trim left '%s'\n", str);
  length = strlen(str);
  if (length) // It is safe to go backwards in the string because we know there is at least 1 char that stops it
    str2 = trimStep(str+length, chars_to_be_removed, -1);
  else
    str2 = str;
  //fprintf(stderr, "trim right '%s'\n", str2);
  length = str2 - str;
  res = (char*) malloc(length+1);
  strncpy(res,str,length);
  res[length] = '\0';
  return res;
}

static const char* SystemImpl__basename(const char *str)
{
  const char* res = NULL;
#if defined(__MINGW32__) || defined(_MSC_VER)
  res = strrchr(str, '\\');
#endif
  if (res == NULL) { res = strrchr(str, '/'); }
  if (res == NULL) { res = str; } else { ++res; }
  return res;
}

void SystemImpl__enableSendData(int enable)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  if(enable)
    _putenv("enableSendData=1");
  else
    _putenv("enableSendData=0");
#else
  if(enable)
    setenv("enableSendData", "1", 1 /* overwrite */);
  else
    setenv("enableSendData", "0", 1 /* overwrite */);
#endif
}

void SystemImpl__setDataPort(int port)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  char* dataport = (char*) malloc(25);
  sprintf(dataport,"sendDataPort=%d", port);
  _putenv(dataport);
  free(dataport);
#else
  char* p = (char*) malloc(10);
  sprintf(p, "%d", port);
  setenv("sendDataPort", p, 1 /* overwrite */);
  free(p);
#endif
  //setDataPort(port);
}

int SystemImpl__systemCall(const char* str)
{
  int status = -1,ret_val = -1;

  /*if (rml_trace_enabled)
  {
    fprintf(stderr, "System.systemCall: %s\n", str); fflush(stderr);
  }*/

  status = system(str);

#if defined(__MINGW32__) || defined(_MSC_VER)
  ret_val = status;
#else
  if (WIFEXITED(status)) /* Did the process exit normally? */
    ret_val = WEXITSTATUS(status); /* Fetch the actual exit status */
  else
    ret_val = -1;
#endif

  /*if (rml_trace_enabled)
  {
    fprintf(stderr, "System.systemCall: returned value: %d\n", ret_val); fflush(stderr);
  }*/
  return ret_val;
}

double SystemImpl__time()
{
  clock_t cl = clock();
  return (double)cl / (double)CLOCKS_PER_SEC;
}

extern char* SystemImpl__pwd()
{
  char buf[MAXPATHLEN];
#if defined(__MINGW32__) || defined(_MSC_VER)
  char* buf2;
  LPTSTR bufPtr=buf;
  DWORD bufLen = MAXPATHLEN;
  GetCurrentDirectory(bufLen,bufPtr);

  /* Make sure windows paths use fronslash and not backslash */
  return _replace(buf,"\\","/"); // free this result later
#else
  if (NULL == getcwd(buf,MAXPATHLEN)) {
    fprintf(stderr, "System.pwd failed\n");
    return NULL;
  }
  return strdup(buf); // to mimic Windows behaviour
#endif
}

extern int SystemImpl__directoryExists(const char *str)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  WIN32_FIND_DATA FileData;
  HANDLE sh;
  sh = FindFirstFile(str, &FileData);
  if (sh == INVALID_HANDLE_VALUE)
    return 0;
  FindClose(sh);
  return (FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
#else
  struct stat buf;
  if (stat(str, &buf))
    return 0;
  return (buf.st_mode & S_IFDIR) != 0;
#endif
}

char* SystemImpl__readFileNoNumeric(const char* filename)
{
  char* buf, *bufRes;
  int res,i,bufPointer = 0,numCount;
  FILE * file = NULL;
  struct stat statstr;
  res = stat(filename, &statstr);

  if(res!=0) {
    const char *c_tokens[1]={filename};
    c_add_message(85, /* ERROR_OPENING_FILE */
      "SCRIPTING",
      "ERROR",
      "Error opening file %s.",
      c_tokens,
      1);
    return strdup("No such file");
  }

  file = fopen(filename,"rb");
  buf = (char*) malloc(statstr.st_size+1);
  bufRes = (char*) malloc((statstr.st_size+70)*sizeof(char));
  if( (res = fread(buf, sizeof(char), statstr.st_size, file)) != statstr.st_size) {
    free(buf);
    free(bufRes);
    return strdup("Failed while reading file");
  }
  buf[statstr.st_size] = '\0';
  numCount = filterString(buf,bufRes);
  fclose(file);
  sprintf(bufRes,"%s\nFilter count from number domain: %d",bufRes,numCount);
  free(buf);
  return bufRes;
}

double SystemImpl__getCurrentTime()
{
  time_t t;
  double elapsedTime;             // the time elapsed as double
  time( &t );
  return difftime(t, 0); // the current time
}

#if !defined(__MINGW32__) && !defined(_MSC_VER)

#ifdef __APPLE_CC__
typedef struct dirent* direntry;
#else
typedef const struct dirent* direntry;
#endif

static int file_select_mo(direntry entry)
{
  char fileName[MAXPATHLEN];
  int res; char* ptr;
  struct stat fileStatus;
  if ((strcmp(entry->d_name, ".") == 0) ||
      (strcmp(entry->d_name, "..") == 0) ||
      (strcmp(entry->d_name, "package.mo") == 0)) {
    return (0);
  } else {
    ptr = (char*)rindex(entry->d_name, '.');
    if ((ptr != NULL) &&
  ((strcmp(ptr, ".mo") == 0))) {
      return (1);
    } else {
      return (0);
    }
  }
}

#endif

#if defined(__MINGW32__) || defined(_MSC_VER)
int setenv(const char* envname, const char* envvalue, int overwrite)
{
  int res;
  char *temp = (char*)malloc(strlen(envname)+strlen(envvalue)+2);
  sprintf(temp,"%s=%s", envname, envvalue);
  res = _putenv(temp);
  free(temp);
  return res;
}
#endif

// Do not free the result
static const char* SystemImpl__getUUIDStr()
{
  static char uuidStr[37] = "8c4e810f-3df3-4a00-8276-176fa3c9f9e0";
#if defined(USE_WIN32_UUID)
  unsigned char *tmp;
  UUID uuid;
  if (UuidCreate(&uuid) == RPC_S_OK)
  	UuidToString(&uuid, &tmp);
  tmp[36] = '\0';
  memcpy(uuidStr, strlwr((char*)tmp), 36);
  RpcStringFree(&tmp);
#endif
  return uuidStr;
}

#if defined(__MINGW32__) || defined(_MSC_VER)
int SystemImpl__loadLibrary(const char *str)
{
  char libname[MAXPATHLEN];
  char currentDirectory[MAXPATHLEN];
  DWORD bufLen = MAXPATHLEN;
  modelica_ptr_t lib = NULL;
  modelica_integer libIndex;
  HMODULE h;
  /* adrpo: use BACKSLASH here as specified here: http://msdn.microsoft.com/en-us/library/ms684175(VS.85).aspx */
  GetCurrentDirectory(bufLen,currentDirectory);
#if defined(_MSC_VER)
  _snprintf(libname, MAXPATHLEN, "%s\\%s.dll", currentDirectory, str);
#else
  snprintf(libname, MAXPATHLEN, "%s\\%s.dll", currentDirectory, str);
#endif

  h = LoadLibrary(libname);
  if (h == NULL) {
    //fprintf(stderr, "Unable to load '%s': %lu.\n", libname, GetLastError());
    fflush(stderr);
    return -1;
  }
  libIndex = alloc_ptr();
  if (libIndex < 0) {
    //fprintf(stderr, "Error loading library %s!\n", libname); fflush(stderr);
    FreeLibrary(h);
    h = NULL;
    return -1;
  }
  lib = lookup_ptr(libIndex); // lib->cnt = 1
  lib->data.lib = h;
  if (check_debug_flag("dynload")) { fprintf(stderr, "LIB LOAD name[%s] index[%d] handle[%lu].\n", libname, libIndex, h); fflush(stderr); }
  return libIndex;
}

#else
int SystemImpl__loadLibrary(const char *str)
{
  char libname[MAXPATHLEN];
  modelica_ptr_t lib = NULL;
  modelica_integer libIndex;
  void *h;
  const char* ctokens[2];
  snprintf(libname, MAXPATHLEN, "./%s.so", str);
  h = dlopen(libname, RTLD_LOCAL | RTLD_NOW);
  if (h == NULL) {
    ctokens[0] = dlerror();
    ctokens[1] = libname;
    c_add_message(-1, "RUNTIME", "ERROR", "OMC unable to load `%s': %s.\n", ctokens, 2);
    return -1;
  }
  libIndex = alloc_ptr();
  if (libIndex < 0) {
    fprintf(stderr, "Error loading library %s!\n", libname); fflush(stderr);
    dlclose(h);
    return -1;
  }
  lib = lookup_ptr(libIndex);
  lib->data.lib = h;
  if (check_debug_flag("dynload"))
  {
    fprintf(stderr, "LIB LOAD [%s].\n", libname, lib->cnt, libIndex, h); fflush(stderr);
  }
  return libIndex;
}
#endif

static inline modelica_integer alloc_ptr()
{
  const modelica_integer start = last_ptr_index;
  modelica_integer index;
  index = start;
  for (;;) {
    ++index;
    if (index >= MAX_PTR_INDEX)
      index = 0;
    if (index == start)
      return -1;
    if (ptr_vector[index].cnt == 0)
      break;
  }
  ptr_vector[index].cnt = 1;
  return index;
}

modelica_ptr_t lookup_ptr(modelica_integer index)
{
  assert(index < MAX_PTR_INDEX);
  return ptr_vector + index;
}

static inline void free_ptr(modelica_integer index)
{
  assert(index < MAX_PTR_INDEX);
  ptr_vector[index].cnt = 0;
  memset(&(ptr_vector[index].data), 0, sizeof(ptr_vector[index].data));
}

#if !defined(__MINGW32__) && !defined(_MSC_VER)

int file_select_directories(direntry entry)
{
  char fileName[MAXPATHLEN];
  int res;
  struct stat fileStatus;
  if ((strcmp(entry->d_name, ".") == 0) ||
      (strcmp(entry->d_name, "..") == 0)) {
    return (0);
  } else {
    sprintf(fileName,"%s/%s",select_from_dir,entry->d_name);
    res = stat(fileName,&fileStatus);
    if (res!=0) return 0;
    if ((fileStatus.st_mode & _IFDIR))
      return (1);
    else
      return (0);
  }
}

#endif

extern int SystemImpl__lookupFunction(int libIndex, const char *str)
{
  modelica_ptr_t lib = NULL, func = NULL;
  function_t funcptr;
  int funcIndex;

  lib = lookup_ptr(libIndex);

  if (lib == NULL)
    return -1;

#if defined(__MINGW32__) || defined(_MSC_VER)
  funcptr = (void*)GetProcAddress(lib->data.lib, str);
#else
  funcptr = (int (*)(type_description*, type_description*)) dlsym(lib->data.lib, str);
#endif

  if (funcptr == NULL) {
    /*fprintf(stderr, "Unable to find `%s': %lu.\n", str, GetLastError());*/
    return -1;
  }

  funcIndex = alloc_ptr();
  func = lookup_ptr(funcIndex);
  func->data.func.handle = funcptr;
  func->data.func.lib = libIndex;
  ++(lib->cnt); // lib->cnt = 2
  /* fprintf(stderr, "LOOKUP LIB index[%d]/count[%d]/handle[%lu] function %s[%d].\n", libIndex, lib->cnt, lib->data.lib, str, funcIndex); fflush(stderr); */
  return funcIndex;
}

#ifdef __cplusplus
}
#endif

