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

#ifdef __cplusplus
extern "C" {
#endif

#include "systemimpl.h"

/*
 * Common includes
 */
#if !defined(_MSC_VER)
#include <libgen.h>
#include <regex.h>
#endif

#include "meta_modelica.h"
#include <limits.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <math.h>

#include "rtclock.h"
#include "config.h"
#include "errorext.h"
#include "iconv.h"

#if defined(__MINGW32__) || defined(_MSC_VER)
#define getFunctionPointerFromDLL  GetProcAddress
#define FreeLibraryFromHandle !FreeLibrary
#else
#define getFunctionPointerFromDLL dlsym
#define FreeLibraryFromHandle dlclose
#define GetLastError(X) 1L
#endif

/*
 * Platform specific includes and defines
 */
#if defined(__MINGW32__) || defined(_MSC_VER)
/* includes/defines specific for Windows*/
#include <assert.h>
#include <direct.h>
#include <process.h>

#define MAXPATHLEN MAX_PATH
#define S_IFLNK  0120000  /* symbolic link */

#if defined(__MINGW32__) || defined(_MSC_VER) /* include dirent for MINGW */
#include <sys/types.h>
#include <dirent.h>
#endif

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
#include <sys/malloc.h>
#endif

#define HAVE_SCANDIR

#ifndef _IFDIR
# ifdef S_IFDIR
#  define _IFDIR S_IFDIR
# else
#  error "Neither _IFDIR nor S_IFDIR is defined."
# endif
#endif
#endif

#if defined(_MSC_VER)
#define strncasecmp strnicmp
#endif

#define MAX_PTR_INDEX 10000
static struct modelica_ptr_s ptr_vector[MAX_PTR_INDEX];
static modelica_integer last_ptr_index = -1;

static inline modelica_integer alloc_ptr();
static inline void free_ptr(modelica_integer index);
static void free_library(modelica_ptr_t lib, modelica_integer printDebug);
static void free_function(modelica_ptr_t func);

static char *cc     = (char*) DEFAULT_CC;
static char *cxx    = (char*) DEFAULT_CXX;
static char *linker = (char*) DEFAULT_LINKER;
static char *cflags = (char*) DEFAULT_CFLAGS;
static char *ldflags= (char*) DEFAULT_LDFLAGS;

static int hasExpandableConnectors = 0;
static int hasInnerOuterDefinitions = 0;
static int hasStreamConnectors = 0;
static int isPartialInstantiation = 0;
static int usesCardinality = 1;
static char* class_names_for_simulation = NULL;
static const char *select_from_dir = NULL;

#ifdef CONFIG_WITH_SENDDATA
// SendData crap
void emulateStreamData(const char* data, const char*, const char*, const char*, const char*, int, int, int, int, int, const char*);
void emulateStreamData2(const char*, const char*, int);
#endif

/*
 * Common implementations
 */

static int stringContains(char *str,char c)
{
  unsigned int i;
  for(i=0;i<strlen(str);++i)
    if(str[i]==c){
      //printf(" (#%d / %d)contained '%c' ('%c', __%s__)\t",i,strlen(str),str[i],c,str);
      return 1;
    }
  return 0;
}

static int filterString(char* buf,char* bufRes)
{
  int i,bufPointer = 0,slen,isNumeric=0,numericEncounter=0;
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
      ErrorType_scripting,
      ErrorLevel_error,
      "Error opening file: %s.",
      c_tokens,
      1);
    return strdup("No such file");
  }

  /* adrpo: if size is larger than the max string, return a different string */
#ifndef _LP64
  if (statstr.st_size > (pow((double)2, (double)22) * 4))
  {
    const char *c_tokens[1]={filename};
    c_add_message(85, /* ERROR_OPENING_FILE */
      ErrorType_scripting,
      ErrorLevel_error,
      "File too large to fit into a MetaModelica string: %s.",
      c_tokens,
      1);
    fclose(file);
    return strdup("File too large");
  }
#endif

  file = fopen(filename,"rb");
  buf = (char*) malloc(statstr.st_size+1);

  if( (res = fread(buf, sizeof(char), statstr.st_size, file)) != statstr.st_size)
  {
    free(buf);
    fclose(file);
    return strdup("Failed while reading file");
  }
  buf[statstr.st_size] = '\0';
  fclose(file);
  return buf;
}

/* returns 0 on success */
int SystemImpl__removeFile(const char* filename)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  return _unlink(filename);
#else /* unix */
  return unlink(filename);
#endif
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
  /* adrpo: 2010-09-22 open the file in BINARY mode as otherwise \r\n becomes \r\r\n! */
  file = fopen(filename,fileOpenMode);
  if (file == NULL) {
    const char *c_tokens[1]={filename};
    c_add_message(21, /* WRITING_FILE_ERROR */
      ErrorType_scripting,
      ErrorLevel_error,
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
      ErrorType_scripting,
      ErrorLevel_error,
      "Error writing to file %s.",
      c_tokens,
      1);
    fclose(file);
    return 1;
  }
  if (fflush(file) != 0)
  {
    fprintf(stderr, "System.writeFile: error flushing file: %s!\n", filename);
  }
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

const char* SystemImpl__basename(const char *str)
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
  const int debug = 0;
  if (debug) {
    fprintf(stderr, "System.systemCall: %s\n", str); fflush(NULL);
  }

  fflush(NULL); /* flush output so the testsuite is deterministic */
#if defined(__MINGW32__) || defined(_MSC_VER)
  status = system(str);
#else
  pid_t pID = vfork();
  if (pID == 0) { // child
    execl("/bin/sh", "/bin/sh", "-c", str, NULL);
    if (debug) {
      fprintf(stderr, "System.systemCall: execl failed %s\n", strerror(errno));
      fflush(NULL);
    }
    _exit(1);
  } else if (pID < 0) {
    const char *tokens[2] = {strerror(errno),str};
    c_add_message(-1,ErrorType_scripting,ErrorLevel_error,"system(%s) failed: %s",tokens,2);
    return -1;
  } else {
    
    if (waitpid(pID, &status, 0) == -1) {
      const char *tokens[2] = {strerror(errno),str};
      c_add_message(-1,ErrorType_scripting,ErrorLevel_error,"system(%s) failed: %s",tokens,2);
    }
  }
#endif
  fflush(NULL); /* flush output so the testsuite is deterministic */

  if (debug) {
    fprintf(stderr, "System.systemCall: returned\n"); fflush(NULL);
  }

#if defined(__MINGW32__) || defined(_MSC_VER)
  ret_val = status;
#else
  if (WIFEXITED(status)) /* Did the process exit normally? */
    ret_val = WEXITSTATUS(status); /* Fetch the actual exit status */
  else
    ret_val = -1;
#endif
  
  if (debug) {
    fprintf(stderr, "System.systemCall: returned value: %d\n", ret_val); fflush(NULL);
  }
  
  return ret_val;
}

int SystemImpl__spawnCall(const char* path, const char* str)
{
  int status = -1,ret_val = -1;
  const int debug = 0;
  if (debug) {
    fprintf(stderr, "System.spawnCall: %s\n", str); fflush(NULL);
  }

  fflush(NULL); /* flush output so the testsuite is deterministic */
#if defined(__MINGW32__) || defined(_MSC_VER)
  status = spawnl(P_DETACH, path, str, "", NULL);
#else
  pid_t pID = vfork();
  if (pID == 0) { // child
    execl("/bin/sh", "/bin/sh", "-c", str, NULL);
    if (debug) {
      fprintf(stderr, "System.spawnCall: execl failed %s\n", strerror(errno));
      fflush(NULL);
    }
    _exit(1);
  } else if (pID < 0) {
    const char *tokens[2] = {strerror(errno),str};
    c_add_message(-1,ErrorType_scripting,ErrorLevel_error,"system(%s) failed: %s",tokens,2);
    return -1;
  }
#endif
  fflush(NULL); /* flush output so the testsuite is deterministic */

  if (debug) {
    fprintf(stderr, "System.spawnCall: returned\n"); fflush(NULL);
  }

#if defined(__MINGW32__) || defined(_MSC_VER)
  ret_val = status;
#else
  ret_val = 0;
#endif

  if (debug) {
    fprintf(stderr, "System.spawnCall: returned value: %d\n", ret_val); fflush(NULL);
  }

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
  int res,bufPointer = 0,numCount;
  FILE * file = NULL;
  struct stat statstr;
  res = stat(filename, &statstr);

  if(res!=0) {
    const char *c_tokens[1]={filename};
    c_add_message(85, /* ERROR_OPENING_FILE */
      ErrorType_scripting,
      ErrorLevel_error,
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

typedef void (*mmc_GC_function_set_gc_state)(mmc_GC_state_type*);

#if defined(__MINGW32__) || defined(_MSC_VER)
int SystemImpl__loadLibrary(const char *str, int printDebug)
{
  char libname[MAXPATHLEN];
  char currentDirectory[MAXPATHLEN];
  DWORD bufLen = MAXPATHLEN;
  modelica_ptr_t lib = NULL;
  modelica_integer libIndex;
  HMODULE h;
  mmc_GC_function_set_gc_state mmc_GC_set_state_lib_function = NULL;
  /* adrpo: use BACKSLASH here as specified here: http://msdn.microsoft.com/en-us/library/ms684175(VS.85).aspx */
  GetCurrentDirectory(bufLen,currentDirectory);
#if defined(_MSC_VER)
  _snprintf(libname, MAXPATHLEN, "%s\\%s.dll", currentDirectory, str);
#else
  snprintf(libname, MAXPATHLEN, "%s\\%s.dll", currentDirectory, str);
#endif

  h = LoadLibrary(libname);
  if (h == NULL) {
    fprintf(stderr, "Unable to load '%s': %lu.\n", libname, GetLastError());
    fflush(stderr);
    return -1;
  }

  /* adrpo, pass the mmc_GC_state pointer from the current process!
  mmc_GC_set_state_lib_function = (mmc_GC_function_set_gc_state)getFunctionPointerFromDLL(h, "mmc_GC_set_state");
  if (mmc_GC_set_state_lib_function == NULL) {
    fprintf(stderr, "Unable to get pointer for mmc_GC_set_state in  %s!\n", libname);
    fflush(stderr);
    return -1;
  }
  mmc_GC_set_state_lib_function(mmc_GC_state);
  */

  libIndex = alloc_ptr();
  if (libIndex < 0) {
    //fprintf(stderr, "Error loading library %s!\n", libname); fflush(stderr);
    FreeLibrary(h);
    h = NULL;
    return -1;
  }
  lib = lookup_ptr(libIndex); // lib->cnt = 1
  lib->data.lib = h;
  if (printDebug) { fprintf(stderr, "LIB LOAD name[%s] index[%d] handle[%lu].\n", libname, libIndex, h); fflush(stderr); }
  return libIndex;
}

#else
int SystemImpl__loadLibrary(const char *str, int printDebug)
{
  char libname[MAXPATHLEN];
  modelica_ptr_t lib = NULL;
  modelica_integer libIndex;
  void *h = NULL;
  mmc_GC_function_set_gc_state mmc_GC_set_state_lib_function = NULL;
  const char* ctokens[2];
  snprintf(libname, MAXPATHLEN, "./%s.so", str);
  h = dlopen(libname, RTLD_LOCAL | RTLD_NOW);
  if (h == NULL) {
    ctokens[0] = dlerror();
    ctokens[1] = libname;
    c_add_message(-1, ErrorType_runtime,ErrorLevel_error, "OMC unable to load `%s': %s.\n", ctokens, 2);
    return -1;
  }

  /* adrpo, pass the mmc_GC_state pointer from the current process!
  mmc_GC_set_state_lib_function = (mmc_GC_function_set_gc_state)getFunctionPointerFromDLL(h, "mmc_GC_set_state");
  if (mmc_GC_set_state_lib_function == NULL) {
    fprintf(stderr, "Unable to get pointer for mmc_GC_set_state in  %s!\n", libname);
    fflush(stderr);
    return -1;
  }
  mmc_GC_set_state_lib_function(mmc_GC_state);
  */

  libIndex = alloc_ptr();
  if (libIndex < 0) {
    fprintf(stderr, "Error loading library %s!\n", libname); fflush(stderr);
    dlclose(h);
    return -1;
  }
  lib = lookup_ptr(libIndex);
  lib->data.lib = h;
  if (printDebug)
  {
    fprintf(stderr, "LIB LOAD [%s].\n", libname); fflush(stderr);
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

  funcptr =  (int (*)(type_description*, type_description*)) getFunctionPointerFromDLL(lib->data.lib, str);

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

static int SystemImpl__freeFunction(int funcIndex, int printDebug)
{
  modelica_ptr_t func = NULL, lib = NULL;

  //fprintf(stderr,"freeFunction(%d,%d)\n", funcIndex, printDebug);

  func = lookup_ptr(funcIndex);

  //fprintf(stderr,"freeFunction(%d,%d) lookup: func: %p\n", func);

  if (func == NULL) return 1;

  lib = lookup_ptr(func->data.func.lib);

  //fprintf(stderr,"freeFunction(%d,%d) lookup: lib %p\n", lib);

  if (lib == NULL) {
    free_function(func);
    free_ptr(funcIndex);
    return 1;
  }


  if (lib->cnt <= 1) {
    free_library(lib, printDebug);
    free_ptr(func->data.func.lib);
    // fprintf(stderr, "library count %u, after unloading!\n", lib->cnt); fflush(stderr);
  } else {
    --(lib->cnt);
    // fprintf(stderr, "library count %u, no unloading!\n", lib->cnt); fflush(stderr);
  }

  free_function(func);
  free_ptr(funcIndex);
  return 0;
}

static int SystemImpl__freeLibrary(int libIndex, int printDebug)
{
  modelica_ptr_t lib = NULL;

  lib = lookup_ptr(libIndex);

  if (lib == NULL) return 1;

  if (lib->cnt <= 1) {
    free_library(lib, printDebug);
    free_ptr(libIndex);
    /* fprintf(stderr, "LIB UNLOAD index[%d]/count[%d]/handle[%ul].\n", libIndex, lib->cnt, lib->data.lib); fflush(stderr); */
  } else {
    --(lib->cnt);
    /* fprintf(stderr, "LIB *NO* UNLOAD index[%d]/count[%d]/handle[%ul].\n", libIndex, lib->cnt, lib->data.lib); fflush(stderr); */
  }
  return 0;
}

static void free_library(modelica_ptr_t lib, modelica_integer printDebug)
{
  if (printDebug) { fprintf(stderr, "LIB UNLOAD handle[%lu].\n", (unsigned long) lib->data.lib); fflush(stderr); }
  if (FreeLibraryFromHandle(lib->data.lib))
  {
    fprintf(stderr,"System.freeLibrary error code: %lu while unloading dll.\n", GetLastError());
    fflush(stderr);
  }
  lib->data.lib = NULL;
}

static void free_function(modelica_ptr_t func)
{
  /* noop */
  modelica_ptr_t lib = NULL;
  lib = lookup_ptr(func->data.func.lib);
  /* fprintf(stderr, "FUNCTION FREE LIB index[%d]/count[%d]/handle[%ul].\n", (lib-ptr_vector),((modelica_ptr_t)(lib-ptr_vector))->cnt, lib->data.lib); fflush(stderr); */
}

static int SystemImpl__getVariableValue(double timeStamp, void* timeValues, void *varValues, double *returnValue)
{
  // values to find the correct range
  double preValue   = 0.0;
  double preTime   = 0.0;
  double nowValue   = 0.0;
  double nowTime   = 0.0;

  // linjear interpolation data
  double timedif       = 0.0;
  double valuedif      = 0.0;
  double valueSlope      = 0.0;
  double timeDifTimeStamp  = 0.0;

  // break loop and return value
  int valueFound = 0;

  for(; RML_GETHDR(timeValues) == RML_CONSHDR && valueFound == 0; timeValues = RML_CDR(timeValues), varValues = RML_CDR(varValues)) {
    nowValue   = rml_prim_get_real(RML_CAR(varValues));
    nowTime   =  rml_prim_get_real(RML_CAR(timeValues));

    if(timeStamp == nowTime){
      valueFound   = 1;
      *returnValue = nowValue;
    } else if (timeStamp >= preTime && timeStamp <= nowTime) { // need to do interpolation
      valueFound       = 1;
      timedif          = nowTime - preTime;
      valuedif         = nowValue - preValue;
      valueSlope       = valuedif / timedif;
      timeDifTimeStamp = timeStamp - preTime;
      *returnValue     = preValue + (valueSlope*timeDifTimeStamp);
    } else {
      preValue  = nowValue;
      preTime   = nowTime;
    }
  }

  if(valueFound == 0){
    // value could not be found in the dataset, what do we do?
    printf("\n WARNING: timestamp(%f) outside simulation timeline \n", timeStamp);
    return 1;
  }
  return 0;
}

static void addSendDataError(const char* functionName)
{
    c_add_message(156, /* WITHOUT_SENDDATA */
      ErrorType_scripting,
      ErrorLevel_error,
      "%s failed because OpenModelica was configured without sendData support.",
      &functionName,
      1);
}

/* If the Modelica string is used as a C string literal, this
 * calculates the string length of that string. */
extern int SystemImpl__unescapedStringLength(const char* str)
{
  int i=0;
  while (*str) {
    if (str[0] == '\\') {
      switch (str[1]) {
      case '\'':
      case '"':
      case '?':
      case '\\':
      case 'a':
      case 'b':
      case 'f':
      case 'n':
      case 'r':
      case 't':
      case 'v':
        str++; break;
      }
    }
    i++;
    str++;
  }
  return i;
}

extern char* SystemImpl__unescapedString(const char* str)
{
  int len1,len2;
  char *res;
  int i=0;
  len1 = strlen(str);
  len2 = SystemImpl__unescapedStringLength(str);
  if (len1 == len2) return NULL;
  res = (char*) malloc(len2+1);
  while (*str) {
    res[i] = str[0];
    if (str[0] == '\\') {
      switch (str[1]) {
      case '\'':
        str++; res[i]='\''; break;
      case '"':
        str++; res[i]='\"'; break;
      case '?':
        str++; res[i]='\?'; break;
      case '\\':
        str++; res[i]='\\'; break;
      case 'a':
        str++; res[i]='\a'; break;
      case 'b':
        str++; res[i]='\b'; break;
      case 'f':
        str++; res[i]='\f'; break;
      case 'n':
        str++; res[i]='\n'; break;
      case 'r':
        str++; res[i]='\r'; break;
      case 't':
        str++; res[i]='\t'; break;
      case 'v':
        str++; res[i]='\v'; break;
      }
    }
    i++;
    str++;
  }
  res[i] = '\0';
  return res;
}

extern int SystemImpl__escapedStringLength(const char* str)
{
  int i=0;
  while (*str) {
    switch (*str) {
      case '"':
      case '\\':
      case '\a':
      case '\b':
      case '\f':
      case '\v': i++;
      default: i++;
    }
    str++;
  }
  return i;
}

extern char* SystemImpl__escapedString(const char* str)
{
  int len1,len2;
  char *res;
  int i=0;
  len1 = strlen(str);
  len2 = SystemImpl__escapedStringLength(str);
  if (len1 == len2) return NULL;
  res = (char*) malloc(len2+1);
  while (*str) {
    switch (*str) {
      case '"': res[i++] = '\\'; res[i++] = '"'; break;
      case '\\': res[i++] = '\\'; res[i++] = '\\'; break;
      case '\a': res[i++] = '\\'; res[i++] = 'a'; break;
      case '\b': res[i++] = '\\'; res[i++] = 'b'; break;
      case '\f': res[i++] = '\\'; res[i++] = 'f'; break;
      case '\v': res[i++] = '\\'; res[i++] = 'v'; break;
      default: res[i++] = *str;
    }
    str++;
  }
  res[i] = '\0';
  return res;
}

extern void* SystemImpl__regex(const char* str, const char* re, int maxn, int extended, int sensitive, int *nmatch)
{
  void *lst = mk_nil();
#if !defined(_MSC_VER) /* crap compiler doesn't have regex */
  char *dup;
  regex_t myregex;
  regmatch_t matches[maxn];
  int i,rc,res;
  int flags = (extended ? REG_EXTENDED : 0) | (sensitive ? REG_ICASE : 0) | (maxn ? 0 : REG_NOSUB);
  memset(&myregex, 1, sizeof(regex_t));
  rc = regcomp(&myregex, re, flags);
  lst = mk_nil();
  if (rc) {
    char err_buf[2048] = {0};
    int len = 0;
    len += snprintf(err_buf+len,2040-len,"Failed to compile regular expression: %s with error: ", re);
    len += regerror(rc, &myregex, err_buf+len, 2048-len);
    len += snprintf(err_buf+len,2040-len,".");
    len += snprintf(err_buf+len,2040-len,".");
    c_add_message(-1, ErrorType_scripting,ErrorLevel_error, err_buf, NULL, 0);
    regfree(&myregex);
    return NULL;
  }
  res = regexec(&myregex, str, maxn, matches, 0);
  lst = mk_nil();
  *nmatch = 0;
  if (!maxn)
    (*nmatch)+= res == 0 ? 1 : 0;
  else {
    if (maxn) {
      dup = strdup(str);
      for (i=maxn-1; i>=0; i--) {
        if (!res && matches[i].rm_so != -1) {
          memcpy(dup, str + matches[i].rm_so, matches[i].rm_eo - matches[i].rm_so);
          dup[matches[i].rm_eo - matches[i].rm_so] = '\0';
          lst = mk_cons(mk_scon(dup),lst);
          (*nmatch)++;
        } else {
          lst = mk_cons(mk_scon(""),lst);
        }
      }
      free(dup);
    }
  }
  
  regfree(&myregex);
#endif /* !defined(_MSC_VER) crap compiler doesn't have regex */
  return lst;
}

char* SystemImpl__unquoteIdentifier(const char* str)
{
  const char lookupTbl[] = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};
  char *res,*cur;
  int len,i;
  const int offset = 10;
  const char _omcQuot[]="_omcQuot_";
  if (*str != '\'') return NULL;
  len = strlen(str)-2;
  res = (char*) malloc(2*len+offset+64);
  cur = res;
  cur += sprintf(cur,"%s",_omcQuot);
  for (i=0; i<len; i++) {
    unsigned char c = str[i+1];
    cur += sprintf(cur,"%c",lookupTbl[c/16]);
    cur += sprintf(cur,"%c",lookupTbl[c%16]);
  }
  *cur = '\0';
  return res;
}

#define TIMER_MAX_STACK  1000
static double timerIntervalTime = 0;
static double timerCummulatedTime = 0;
static double timerTime = 0;
static long int timerStackIdx = 0;
static double timerStack[TIMER_MAX_STACK] = {0};

static void pushTimerStack()
{
  if (timerStackIdx < TIMER_MAX_STACK)
  {
    timerStack[timerStackIdx] = rt_tock(RT_CLOCK_SPECIAL_STOPWATCH);
    /* increase the stack */
    timerStackIdx++;
  }
  else
  {
    fprintf(stderr, "System.pushStartTime -> timerStack overflow %ld\n", timerStackIdx);
  }
}

static void popTimerStack()
{
  if (timerStackIdx >= 1)
  {
    /* how much time passed since we last called startTime? */
    timerIntervalTime = rt_tock(RT_CLOCK_SPECIAL_STOPWATCH) - timerStack[timerStackIdx-1];
    timerCummulatedTime += timerIntervalTime;
    /* decrease the stack */
    timerStackIdx--;
  }
  else
  {
    fprintf(stderr, "System.popStartTime -> timerStack underflow %ld\n", timerStackIdx);
  }
}

static void decodeUri2(const char *src, char *dest, int breakCh)
{
  char *tmp = dest;
  while (*src) {
    if (*src == '+') *(tmp++) = ' ';
    else if (*src == '%' && src[1]) {
      char buf[3];
      int i;
      buf[0] = src[1];
      buf[1] = src[2];
      buf[2] = '\0';
      errno = 0;
      i = strtol(buf,NULL,16);
      if (errno) {
        *(tmp++) = *src;
        errno = 0;
      } else {
        *(tmp++) = i;
        *tmp = 0;
        src += 2;
      }
    } else if (*src == breakCh) {
      break;
    } else *(tmp++) = *src;
    src++;
  }
  *tmp = '\0';
}

static void decodeUri(const char *src, char **name, char **path)
{
  const char *srcPath = strchr(src,'/');
  const char *srcName = src;
  int len = strlen(src);
  int lenPath = srcPath ? strlen(srcPath+1) : 0;
  *name = (char*) malloc(len - lenPath + 2);
  decodeUri2(src,*name,'/');
  *path = (char*) malloc(lenPath+2);
  **path = '\0';
  if (srcPath == NULL) {
    return;
  }
  decodeUri2(srcPath,*path,-1);
}

static int SystemImpl__uriToClassAndPath(const char *uri, const char **scheme, char **name, char **path)
{
  const char *modelicaUri = "modelica://";
  const char *fileUri = "file://";
  const char *msg[2];
  *scheme = NULL;
  *name = NULL;
  *path = NULL;
  if (0 == strncasecmp(uri, modelicaUri, strlen(modelicaUri))) {
    *scheme = modelicaUri;
    decodeUri(uri+strlen(modelicaUri),name,path);
    if (!**name) {
      msg[0] = uri;
      c_add_message(-1,ErrorType_scripting,ErrorLevel_error,"Modelica URI lacks classname: %s",msg,1);
      return 1;
    }
    return 0;
  } else if (0 == strncasecmp(uri, fileUri, strlen(fileUri))) {
    *scheme = fileUri;
    decodeUri(uri+strlen(fileUri),name,path);
    if (!**path) {
      msg[0] = uri;
      c_add_message(-1,ErrorType_scripting,ErrorLevel_error,"File URI has no path: %s",msg,1);
      return 1;
    } else if (**name) {
      msg[0] = uri;
      c_add_message(-1,ErrorType_scripting,ErrorLevel_error,"File URI using hostnames is not supported: %s",msg,1);
      return 1;
    }
    return 0;
  }
  c_add_message(-1,ErrorType_scripting,ErrorLevel_error,"Unknown uri: %s",&uri,1);
  return 1;
}

/* adrpo 2011-06-23
 * extern definition to dgesv_ from -llapack
 * as we do not link with -lsim and the one
 * in matrix.h got renamed to _omc_dgesv_ to
 * avoid name clashes!
 */
extern int dgesv_(integer *n, integer *nrhs, doublereal *a, integer *lda, integer *ipiv, doublereal *b, integer *ldb, integer *info);

int SystemImpl__dgesv(void *lA, void *lB, void **res)
{
  integer sz = 0, i = 0, j = 0;
  void *tmp = lB;
  double *A,*B;
  integer *ipiv;
  integer info = 0,nrhs=1,lda,ldb;
  while (RML_NILHDR != RML_GETHDR(tmp)) {
    sz++;
    tmp = RML_CDR(tmp);
  }
  A = (double*) malloc(sz*sz*sizeof(double));
  assert(A != NULL);
  B = (double*) malloc(sz*sizeof(double));
  assert(B != NULL);
  for (i=0; i<sz; i++) {
    tmp = RML_CAR(lA);
    for (j=0; j<sz; j++) {
      A[j*sz+i] = rml_prim_get_real(RML_CAR(tmp));
      tmp = RML_CDR(tmp);
    }
    B[i] = rml_prim_get_real(RML_CAR(lB));
    lA = RML_CDR(lA);
    lB = RML_CDR(lB);
  }
  ipiv = (integer*) calloc(sz,sizeof(integer));
  assert(ipiv != 0);
  lda = sz;
  ldb = sz;
  dgesv_(&sz,&nrhs,A,&lda,ipiv,B,&ldb,&info);

  tmp = mk_nil();
  while (sz--) {
    tmp = mk_cons(mk_rcon(B[sz]),tmp);
  }
  free(A);
  free(B);
  free(ipiv);
  *res = tmp;
  return info;
}

#include CONFIG_LPSOLVEINC

int SystemImpl__lpsolve55(void *lA, void *lB, void *ix, void **res)
{
  int i = 0, j = 0, info, sz = 0;
  void *tmp = lB;
  lprec *lp;
  double inf,*vres;
  
  while (RML_NILHDR != RML_GETHDR(tmp)) {
    sz++;
    tmp = RML_CDR(tmp);
  }
  vres = (double*)calloc(sz,sizeof(double));
  lp = make_lp(sz, sz);
  set_verbose(lp, 1);
  inf = get_infinite(lp);

  for (i=0; i<sz; i++) {
    set_lowbo(lp, i+1, -inf);
    set_constr_type(lp, i+1, EQ);
    tmp = RML_CAR(lA);
    for (j=0; j<sz; j++) {
      set_mat(lp, i+1, j+1, rml_prim_get_real(RML_CAR(tmp)));
      tmp = RML_CDR(tmp);
    }
    set_rh(lp, i+1, rml_prim_get_real(RML_CAR(lB)));
    lA = RML_CDR(lA);
    lB = RML_CDR(lB);
  }
  while (RML_NILHDR != RML_GETHDR(ix)) {
    if (RML_UNTAGFIXNUM(RML_CAR(ix)) != -1) set_int(lp, RML_UNTAGFIXNUM(RML_CAR(ix)), 1);
    ix = RML_CDR(ix);
  }
  info=solve(lp);
  //print_lp(lp);
  if (info==0 || info==1) get_ptr_variables(lp,&vres);
  *res = mk_nil();
  while (sz--) {
    *res = mk_cons(mk_rcon(vres[sz]),*res);
  }
  delete_lp(lp);
  return info;
}

static int getPrio(const char *ver, size_t versionLen)
{
  if (!ver) return 0;
  int status = 0;
  while (*ver && versionLen) {
    if (*ver >= '0' && *ver <= '9') status = 1;
    else if (status == 1 && *ver == '.') status = 2;
    else if (status == 1 && *ver == ' ') return 2;
    else return 3;
    ver++;
    versionLen--;
  }
  /* TODO: Handle pre-release, release, non-release */
  return 1;
}

int SystemImpl__getLoadModelPath(const char *name, void *prios, void *mps, const char **outDir, char **outName, int *isDir)
{
  size_t nlen = strlen(name);
  int outPrio = INT_MAX;
  int defaultPrio = INT_MAX;
  char *defaultVersion = NULL;
  while (RML_NILHDR != RML_GETHDR(mps)) {
    const char *mp = RML_STRINGDATA(RML_CAR(mps));
    DIR *dir = opendir(mp);
    struct dirent *ent;
    mps = RML_CDR(mps);
    if (!dir) continue;
    while ((ent = readdir(dir))) {
      if (0 == strncmp(name, ent->d_name, nlen)) {
        const char *version;
        int prio = 0, cIsDir = 1;
        void *priosWork = prios;
        size_t versionLen = 0;
        /* Check if file is dir or mo-file; and if it has a version-string or not */
        if (ent->d_name[nlen] == ' ') {
          version = ent->d_name+nlen+1;
          versionLen = strlen(version);
          if (versionLen >= 3 && version[versionLen-3] == '.' && version[versionLen-2] == 'm' && version[versionLen-1] == 'o') {
            if (versionLen == 3) version = NULL;
            cIsDir = 0;
            versionLen -= 3;
          }
        } else if (ent->d_name[nlen] == '\0') {
          version = NULL;
        } else if (0 == strcmp(ent->d_name+nlen,".mo")) {
          version = NULL;
          cIsDir = 0;
        } else {
          continue;
        }
        /* Check if this file has higher priority than the last found match */
        while (RML_NILHDR != RML_GETHDR(priosWork)) {
          if (prio > outPrio) break;
          const char *cverPrio = RML_STRINGDATA(RML_CAR(priosWork));
          priosWork = RML_CDR(priosWork);
          /* fprintf(stderr, "'%s' '%s' %d\n", cverPrio, version, versionLen); */
          if (0 == strcmp("default",cverPrio)) {
            /* Search for an appropriate version of the library */
            outPrio = prio;
            prio = getPrio(version,versionLen);
            /* Force preferred version MSL 3.1 / MS 1.0 */
            if (prio == 1 && 0 == strcmp("Modelica",name) && 0 == strcmp(version,"3.1")) prio = -1;
            if (prio == 1 && 0 == strcmp("ModelicaServices",name) && 0 == strcmp(version,"1.0")) prio = -1;
            /* TODO: Use something better than strcmp. We need natural sort for all cases... */
            if (prio < defaultPrio || (prio == defaultPrio && version && defaultVersion && (strcmp(version, defaultVersion) > 0))) {
              defaultPrio = prio;
              *outDir = mp;
              if (*outName) free(*outName);
              if (defaultVersion) free(defaultVersion);
              *outName = strdup(ent->d_name);
              defaultVersion = version ? strdup(version) : NULL;
              *isDir = cIsDir;
            }
            break;
          } else if (version && 0 == strncmp(version,cverPrio,versionLen)) {
            outPrio = prio;
            *outDir = mp;
            if (*outName) free(*outName);
            *outName = strdup(ent->d_name);
            *isDir = cIsDir;
          }
          prio++;
        } /* prios loop */
      } /* strcmp */
    } /* readdir loop */
    closedir(dir);
  }
  if (defaultVersion) free(defaultVersion);
  /* if (*outName) fprintf(stderr, "Found version: %s\n", *outName); */
  return outPrio == INT_MAX;
}

#define MAX_TMP_TICK 16
static modelica_integer tmp_tick_no[MAX_TMP_TICK] = {0};

extern int SystemImpl_tmpTick()
{
  return tmp_tick_no[0]++;
}

extern void SystemImpl_tmpTickReset(int start)
{
  tmp_tick_no[0] = start;
}

extern int SystemImpl_tmpTickIndex(int index)
{
  assert(index < MAX_TMP_TICK && index >= 0);
  /* fprintf(stderr, "tmpTickIndex %d => %d\n", index, tmp_tick_no[index]); */
  return tmp_tick_no[index]++;
}

extern void SystemImpl_tmpTickResetIndex(int start, int index)
{
  assert(index < MAX_TMP_TICK && index >= 0);
  /* fprintf(stderr, "tmpTickResetIndex %d => %d\n", index, start); */
  tmp_tick_no[index] = start;
}

extern int SystemImpl__reopenStandardStream(int id,const char *filename)
{
  FILE *file;
  const char* mode;
  const char* streamName;
  switch (id) {
  case 0: file=stdin;mode="r";streamName="stdin";break;
  case 1: file=stdout;mode="w";streamName="stdout";break;
  case 2: file=stderr;mode="w";streamName="stderr";break;
  default: return 0;
  }
  file = freopen(filename,mode,file);
  if (file==NULL) {
    const char *tokens[4] = {strerror(errno),streamName,mode,filename};
    c_add_message(-1,ErrorType_scripting,ErrorLevel_error,"freopen(%s,%s,%s) failed: %s",tokens,4);
    return 0;
  }
  return 1;
}

extern char* SystemImpl__iconv(const char * str, const char *from, const char *to)
{
  static char *buf = 0;
  static int buflen = 0;
  char *in_str,*res;
  size_t sz,out_sz;
  iconv_t ic;
  int count;
  sz = strlen(str);
  if (buflen < sz*4) {
    if (buf) free(buf);
    buf = (char*)malloc(sz*8);
    if (!buf) {
      buflen = 0;
      return (char*) "";
    }
    buflen = sz*8;
  }
  *buf = 0;
  /* fprintf(stderr,"iconv(%s,to=%s,%s) of size %d, buflen %d\n",str,to,from,sz,buflen); */
  ic = iconv_open(to, from);
  if (ic == (iconv_t) -1) {
    const char *tokens[4] = {strerror(errno),from,to,str};
    c_add_message(-1,ErrorType_scripting,ErrorLevel_error,"iconv(\"%s\",to=\"%s\",from=\"%s\") failed: %s",tokens,4);
    return buf;
  }
  in_str = (char*) str;
  out_sz = buflen-1;
  res = buf;
  count = iconv(ic,&in_str,&sz,&res,&out_sz);
  iconv_close(ic);
  if (count == -1) {
    const char *tokens[4] = {strerror(errno),from,to,str};
    c_add_message(-1,ErrorType_scripting,ErrorLevel_error,"iconv(\"%s\",to=\"%s\",from=\"%s\") failed: %s",tokens,4);
    return (char*) "";
  }
  buf[(buflen-1)-out_sz] = 0;
  if (strlen(buf) != (buflen-1)-out_sz) {
    const char *tokens[1] = {to};
    c_add_message(-1,ErrorType_scripting,ErrorLevel_error,"iconv(to=%s) failed because the character set output null bytes in the middle of the string.",&to,1);
    return (char*) "";
  }
  return buf;
}

#ifdef __cplusplus
}
#endif

