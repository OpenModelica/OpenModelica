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
#include "settingsimpl.h"
#include "f2c.h"

#if defined(_MSC_VER) /* no iconv for VS! */

typedef void* iconv_t;
#define iconv_open(tocode, fromcode)  (0)
#define iconv_close(cd) (0)
#define iconv(cd,  inbuf, inbytesleft, outbuf, outbytesleft) (0)

#else /* real compilers */

#include "iconv.h"

#endif


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

#include <sys/types.h>
#if defined(_MSC_VER)
  #include <win32_dirent.h>
  #define PATH_MAX MAX_PATH
#else
  #include <dirent.h>
#endif

char *realpath(const char *path, char resolved_path[PATH_MAX]);

#else
/* includes/defines specific for LINUX/OS X */
#include <ctype.h>
#include <dirent.h>
#include <sys/ioctl.h>
#include <sys/param.h> /* MAXPATHLEN */
#include <sys/unistd.h>
#include <sys/wait.h> /* only available in Linux, not windows */
#include <unistd.h>
#include <dlfcn.h>
#include <stdlib.h>

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

static const char def_cc[]     = DEFAULT_CC;
static const char def_cxx[]    = DEFAULT_CXX;
static const char def_linker[] = DEFAULT_LINKER;
static const char def_cflags[] = DEFAULT_CFLAGS;
static const char def_ldflags[]= DEFAULT_LDFLAGS;

static char *cc     = (char *)def_cc;
static char *cxx    = (char *)def_cxx;
static char *linker = (char *)def_linker;
static char *cflags = (char *)def_cflags;
static char *ldflags= (char *)def_ldflags;

static int hasExpandableConnectors = 0;
static int hasInnerOuterDefinitions = 0;
static int hasStreamConnectors = 0;
static int isPartialInstantiation = 0;
static int usesCardinality = 1;
static char* class_names_for_simulation = NULL;
static const char *select_from_dir = NULL;

/*
 * Common implementations
 */

static int str_contain_char(const char* chars, const char chr)
{
  int i = 0;
  while(chars[i] != '\0') {
    if(chr == chars[i]) {
      return 1;
    }
    i++;
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
    if((str_contain_char(filterChars,buf[i]))) {
      if(buf[i]=='.') {
        if(str_contain_char(numeric,preChar) || (( i < slen+1) && str_contain_char(numeric,buf[i+1])) ) {
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
  if ((cc != NULL) && (cc != def_cc)) {
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
  if ((cxx != NULL) && (cxx != def_cxx)) {
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
  if ((linker != NULL) && (linker != def_linker)) {
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
  if ((cflags != NULL) && (cflags != def_cflags)) {
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
  if ((ldflags != NULL) && (ldflags != def_ldflags)) {
    free(ldflags);
  }
  ldflags = (char*)malloc(len+1);
  if (ldflags == NULL) return -1;
  memcpy(ldflags,str,len+1);
  return 0;
}

extern char* SystemImpl__pwd()
{
  char buf[MAXPATHLEN];
#if defined(__MINGW32__) || defined(_MSC_VER)
  char* buf2;
  LPTSTR bufPtr=buf;
  DWORD bufLen = MAXPATHLEN;
  if (!GetCurrentDirectory(bufLen,bufPtr)) {
    fprintf(stderr, "System.pwd failed\n");
    return NULL;
  }

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

extern int SystemImpl__regularFileExists(const char* str)
{
#if defined(_MSC_VER)
  int ret_val;
  void *res;
  WIN32_FIND_DATA FileData;
  HANDLE sh;

  sh = FindFirstFile(str, &FileData);

  if (sh == INVALID_HANDLE_VALUE) {
    if (strlen(str) >= MAXPATHLEN)
    {
      const char *c_tokens[1]={str};
      c_add_message(85, /* error opening file */
        ErrorType_scripting,
        ErrorLevel_error,
        gettext("Error opening file: %s."),
        c_tokens,
        1);
    }
    return 0;
  }
  FindClose(sh);
  return ((FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0);
#else
  struct stat buf;
  /* adrpo: TODO: check if str leads to a path > PATH_MAX, maybe use realpath impl. from below */
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
      gettext("Error opening file: %s."),
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
      gettext("File too large to fit into a MetaModelica string: %s."),
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
      gettext("Error writing to file %s."),
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
      gettext("Error writing to file %s."),
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

/* returns 0 on success */
int SystemImpl__appendFile(const char* filename, const char *data)
{
  FILE *file = NULL;
  file = fopen(filename, "a");

  if(file == NULL) {
    const char *c_tokens[1] = {filename};
    c_add_message(21, /* WRITING_FILE_ERROR */
      ErrorType_scripting, ErrorLevel_error,
      gettext("Error appending to file %s."),
      c_tokens,
      1);
    return 1;
  }

  fwrite(data, strlen(data), 1, file);
  fflush(file);
  fclose(file);
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
    str2 = trimStep(str+length-1, chars_to_be_removed, -1);
  else
    str2 = str;
  //fprintf(stderr, "trim right '%s'\n", str2);
  length = str2 - str + 1;
  res = (char*) malloc(length+1);
  strncpy(res,str,length);
  res[length] = '\0';
  return res;
}

void* SystemImpl__trimChar(const char* str, char char_to_be_trimmed)
{
  int start_pos = 0;
  char* res;

  while(str[start_pos] == char_to_be_trimmed) {
    start_pos++;
  }
  if(str[start_pos] != '\0') {
    void *rmlRes;
    int end_pos = strlen(str) - 1;

    while(str[end_pos] == char_to_be_trimmed) {
      end_pos--;
    }
    res = (char*)malloc(end_pos - start_pos +2);
    strncpy(res,&str[start_pos],end_pos - start_pos+1);
    res[end_pos - start_pos+1] = '\0';
    rmlRes = (void*) mk_scon(res);
    free(res);
    return rmlRes;
  } else {
    return mk_scon("");
  }
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
    c_add_message(-1,ErrorType_scripting,ErrorLevel_error,gettext("system(%s) failed: %s"),tokens,2);
    return -1;
  } else {

    if (waitpid(pID, &status, 0) == -1) {
      const char *tokens[2] = {strerror(errno),str};
      c_add_message(-1,ErrorType_scripting,ErrorLevel_error, gettext("system(%s) failed: %s"),tokens,2);
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

void* SystemImpl__systemCallParallel(void *lst)
{
  void *tmp = lst;
  int sz = 0, i;
  char **calls;
  int *results;
  while (RML_NILHDR != RML_GETHDR(tmp)) {
    sz++;
    tmp = RML_CDR(tmp);
  }
  if (sz == 0) return mk_nil();
  calls = (char**) malloc(sz*sizeof(char*));
  assert(calls);
  results = (int*) malloc(sz*sizeof(int));
  assert(results);
  tmp = lst;
  sz = 0;
  while (RML_NILHDR != RML_GETHDR(tmp)) {
    calls[sz++] = RML_STRINGDATA(RML_CAR(tmp));
    tmp = RML_CDR(tmp);
  }
#pragma omp parallel for private(i) schedule(dynamic)
  for (i=0; i<sz; i++) {
    /* fprintf(stderr, "Starting call %s\n", calls[i]); */
    results[i] = system(calls[i]);
    /* fprintf(stderr, "Finished call %s=%d\n", calls[i], results[i]); */
  }
  free(calls);
  free(results);
  tmp = mk_nil();
  for (i=sz-1; i>=0; i--) {
    tmp = mk_cons(mk_icon(results[i]),tmp);
  }
  return tmp;
}

int SystemImpl__spawnCall(const char* path, const char* str)
{
  int ret_val = -1;
  const int debug = 0;
  if (debug) {
    fprintf(stderr, "System.spawnCall: %s\n", str); fflush(NULL);
  }

  fflush(NULL); /* flush output so the testsuite is deterministic */
#if defined(__MINGW32__) || defined(_MSC_VER)
  ret_val = spawnl(P_DETACH, path, str, "", NULL);
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
    c_add_message(-1,ErrorType_scripting,ErrorLevel_error,gettext("system(%s) failed: %s"),tokens,2);
    return -1;
  }
  ret_val = 0;
#endif
  fflush(NULL); /* flush output so the testsuite is deterministic */

  if (debug) {
    fprintf(stderr, "System.spawnCall: returned\n"); fflush(NULL);
  }

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
  int res,numCount;
  FILE * file = NULL;
  struct stat statstr;
  res = stat(filename, &statstr);

  if(res!=0) {
    const char *c_tokens[1]={filename};
    c_add_message(85, /* ERROR_OPENING_FILE */
      ErrorType_scripting,
      ErrorLevel_error,
      gettext("Error opening file %s."),
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
  char* ptr;
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
    c_add_message(-1, ErrorType_runtime,ErrorLevel_error, gettext("OMC unable to load `%s': %s.\n"), ctokens, 2);
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
    *cur = lookupTbl[c/16];
    cur++;
    *cur = lookupTbl[c%16];
    cur++;
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
      c_add_message(-1,ErrorType_scripting,ErrorLevel_error,gettext("Modelica URI lacks classname: %s"),msg,1);
      return 1;
    }
    return 0;
  } else if (0 == strncasecmp(uri, fileUri, strlen(fileUri))) {
    *scheme = fileUri;
    decodeUri(uri+strlen(fileUri),name,path);
    if (!**path) {
      msg[0] = uri;
      c_add_message(-1,ErrorType_scripting,ErrorLevel_error,gettext("File URI has no path: %s"),msg,1);
      return 1;
    } else if (**name) {
      msg[0] = uri;
      c_add_message(-1,ErrorType_scripting,ErrorLevel_error,gettext("File URI using hostnames is not supported: %s"),msg,1);
      return 1;
    }
    return 0;
  }
  c_add_message(-1,ErrorType_scripting,ErrorLevel_error,gettext("Unknown uri: %s"),&uri,1);
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

#define MODELICAPATH_LEVELS 6
typedef struct {
  const char *dir;
  char *file;
  long version[MODELICAPATH_LEVELS];
  char *versionExtra;
  int fileIsDir;
} modelicaPathEntry;

void splitVersion(const char *version, long *versionNum, char **versionExtra)
{
  const char *buf = version;
  char *next;
  long l;
  int cont,i=0,len;
  memset(versionNum,0,sizeof(long)*MODELICAPATH_LEVELS);
  do {
    /* fprintf(stderr, "look versionNum %s\n", buf); */
    l = strtol(buf,&next,10);
    cont = buf != next && l >= 0;
    if (cont) {
      versionNum[i] = l;
      /* fprintf(stderr, "versionNum %lx\n", *versionNum); */
      if (*next == '.') next++;
    }
    buf = next;
  } while (cont && ++i < MODELICAPATH_LEVELS);
  if (*buf == ' ') buf++;
  *versionExtra = strdup(buf);
  len = strlen(*versionExtra);
  /* fprintf(stderr, "have len %ld versionExtra %s\n", len, *versionExtra); */
  if (len >= 2 && 0==strcmp("mo", *versionExtra+len-2)) {
    (*versionExtra)[len-2] = '\0';
  }
}

static int regularFileExistsInDirectory(const char *dir1, const char *dir2, const char *file)
{
  char *str;
  int res;
  str = (char*) malloc(strlen(dir1) + strlen(dir2) + strlen(file) + 3);
  sprintf(str,"%s/%s/%s", dir1, dir2, file);
  res = SystemImpl__regularFileExists(str);
  free(str);
  return res;
}

static modelicaPathEntry* getAllModelicaPaths(const char *name, size_t nlen, void *mps, int *numMatches)
{
  int i = 0;
  *numMatches = 0;
  modelicaPathEntry* res;
  void *save_mps = mps;
  while (RML_NILHDR != RML_GETHDR(mps)) {
    const char *mp = RML_STRINGDATA(RML_CAR(mps));
    DIR *dir = opendir(mp);
    struct dirent *ent;
    mps = RML_CDR(mps);
    if (!dir) continue;
    while ((ent = readdir(dir))) {
      if (0 == strncmp(name, ent->d_name, nlen) && (ent->d_name[nlen] == '\0' || ent->d_name[nlen] == ' ' || ent->d_name[nlen] == '.')) {
        int entlen,mightbedir;
#ifdef DT_DIR
        mightbedir = (ent->d_type==DT_DIR || ent->d_type==DT_UNKNOWN || ent->d_type==DT_LNK);
#else
        mightbedir = 1;
#endif
        if (mightbedir && regularFileExistsInDirectory(mp,ent->d_name,"package.mo")) {
          /* fprintf(stderr, "found match %d %s\n", *numMatches, ent->d_name); */
          (*numMatches)++;
          continue;
        }
        entlen = strlen(ent->d_name);
        if (entlen > 3 && 0==strcmp(ent->d_name+entlen-3,".mo") && regularFileExistsInDirectory(mp,"",ent->d_name)) {
          /* fprintf(stderr, "found match %d %s\n", *numMatches, ent->d_name); */
          (*numMatches)++;
        }
      }
    }
    closedir(dir);
  }
  /* fprintf(stderr, "numMatches: %ld\n", *numMatches); */
  /*** NOTE: Doing the same thing again. It is very important the same (number of) entries are match as in the loop above ***/
  res = (modelicaPathEntry*) malloc(*numMatches*sizeof(modelicaPathEntry));
  mps = save_mps;
  while (RML_NILHDR != RML_GETHDR(mps)) {
    const char *mp = RML_STRINGDATA(RML_CAR(mps));
    DIR *dir = opendir(mp);
    struct dirent *ent;
    mps = RML_CDR(mps);
    if (!dir) continue;
    while ((ent = readdir(dir))) {
      if (0 == strncmp(name, ent->d_name, nlen) && (ent->d_name[nlen] == '\0' || ent->d_name[nlen] == ' ' || ent->d_name[nlen] == '.')) {
        int entlen,ok=0,maybeDir;
#ifdef DT_DIR
        maybeDir = (ent->d_type==DT_DIR || ent->d_type==DT_UNKNOWN || ent->d_type==DT_LNK);
#else
        maybeDir = 1;
#endif
        if (maybeDir && regularFileExistsInDirectory(mp,ent->d_name,"package.mo")) {
          ok=1;
          res[i].fileIsDir=1;
          /* fprintf(stderr, "found dir match: %ld %s - ok=%d\n", i, ent->d_name, ok); */
        }
        entlen = strlen(ent->d_name);
        if (!ok && entlen > 3 && 0==strcmp(ent->d_name+entlen-3,".mo") && regularFileExistsInDirectory(mp,"",ent->d_name)) {
          /* fprintf(stderr, "found match file: %ld %s - ok=%d\n", i, ent->d_name, ok); */
          res[i].fileIsDir=0;
          ok=1;
        }
        if (!ok)
          continue;
        res[i].dir = mp;
        res[i].file = strdup(ent->d_name);
        if (res[i].file[nlen] == ' ') {
          splitVersion(res[i].file+nlen+1, res[i].version, &res[i].versionExtra);
        } else {
          memset(res[i].version,0,sizeof(long)*MODELICAPATH_LEVELS);
          res[i].versionExtra = strdup("");
        }
        assert(i<*numMatches);
        i++;
      }
    }
    closedir(dir);
  }
  return res;
}

static void freeAllModelicaPaths(modelicaPathEntry *entries, int numEntries)
{
  int i;
  for (i=0; i<numEntries; i++) {
    free(entries[i].file);
    free(entries[i].versionExtra);
  }
  free(entries);
}

static int modelicaPathEntryVersionEqual(long *ver1, long *ver2, int numToTest)
{
  int i;
  for (i=0; i<numToTest; i++) {
    if (ver1[i] != ver2[i]) return 0;
  }
  return 1;
}

static int modelicaPathEntryVersionGreater(long *ver1, long *ver2, int numToTest)
{
  int i;
  for (i=0; i<numToTest; i++) {
    if (ver1[i] > ver2[i]) return 1;
    if (ver1[i] < ver2[i]) return 0;
  }
  return 1;
}

static int getLoadModelPathFromSingleTarget(const char *searchTarget, modelicaPathEntry *entries, int numEntries, const char **outDir, char **outName, int *isDir)
{
  int i, j, foundIndex = -1;
  long version[MODELICAPATH_LEVELS] = {0}, foundVersion[MODELICAPATH_LEVELS] = {0};
  char *versionExtra;
  splitVersion(searchTarget,version,&versionExtra);
  /* fprintf(stderr, "expected %ld.%ld.%ld.%ld %s\n", version[0], version[1], version[2], version[3], versionExtra); */
  if (version > 0 && !*versionExtra) {
    /* Makes us load 3.2.1 if 3.2.0.0 is not available.
     * Note that all 4 levels are present and 3.2 is equivalent to 3.2.0.0
     * Search one additional level for each time we fail.
     */
    for (j=MODELICAPATH_LEVELS; j>0; j--) {
      for (i=0; i<numEntries; i++) {
        /* fprintf(stderr, "entry %s/%s\n", entries[i].dir, entries[i].file);
         fprintf(stderr, "expected %ld.%ld.%ld.%ld %s\n", entries[i].version[0], entries[i].version[1], entries[i].version[2], entries[i].version[3], entries[i].versionExtra); */

        if (modelicaPathEntryVersionEqual(entries[i].version,version,j) && (j==MODELICAPATH_LEVELS || modelicaPathEntryVersionGreater(entries[i].version,version,j+1)) && entries[i].versionExtra[0] == '\0') {
          if (modelicaPathEntryVersionGreater(entries[i].version,foundVersion,MODELICAPATH_LEVELS)) {
            memcpy(foundVersion,entries[i].version,sizeof(long)*MODELICAPATH_LEVELS);
            foundIndex = i;
          }
        }
      }
      if (foundIndex >= 0) {
        *outDir = entries[foundIndex].dir;
        *outName = entries[foundIndex].file;
        *isDir = entries[foundIndex].fileIsDir;
        free(versionExtra);
        return 0;
      }
    }
  }
  if (*versionExtra) {
    /* fprintf(stderr, "Look for version %lx versionExtra: %s\n", version, versionExtra); */
    for (i=0; i<numEntries; i++) {
      /* fprintf(stderr, "entry %s/%s\n", entries[i].dir, entries[i].file);
      fprintf(stderr, "is %ld.%ld.%ld.%ld %s\n", entries[i].version[0], entries[i].version[1], entries[i].version[2], entries[i].version[3], entries[i].versionExtra); */
      if (modelicaPathEntryVersionEqual(entries[i].version,version,MODELICAPATH_LEVELS) && 0==strncmp(entries[i].versionExtra,versionExtra,strlen(versionExtra))) {
        *outDir = entries[i].dir;
        *outName = entries[i].file;
        *isDir = entries[i].fileIsDir;
        free(versionExtra);
        return 0;
      }
    }
  }
  free(versionExtra);
  return 1;
}

static int getLoadModelPathFromDefaultTarget(const char *name, modelicaPathEntry *entries, int numEntries, const char **outDir, char **outName, int *isDir)
{
  const char *foundExtra = 0;
  long foundVersion[MODELICAPATH_LEVELS] = {-1,-1,-1,0};
  int i,foundIndex = -1;

  /* Look for best release version */
  for (i=0; i<numEntries; i++) {
    if (modelicaPathEntryVersionGreater(entries[i].version,foundVersion,MODELICAPATH_LEVELS) && entries[i].versionExtra[0] == '\0') {
      memcpy(foundVersion,entries[i].version,sizeof(long)*MODELICAPATH_LEVELS);
      foundIndex = i;
    }
  }
  /* Look for best pre-release/named version */
  if (foundIndex == -1) {
    for (i=0; i<numEntries; i++) {
      if (modelicaPathEntryVersionGreater(entries[i].version,foundVersion,MODELICAPATH_LEVELS) || (entries[i].version == foundVersion && strcmp(entries[i].versionExtra,foundExtra) > 0)) {
        memcpy(foundVersion,entries[i].version,sizeof(long)*MODELICAPATH_LEVELS);
        foundExtra = entries[i].versionExtra;
        foundIndex = i;
      }
    }
  }
  if (foundIndex >= 0) {
    *outDir = entries[foundIndex].dir;
    *outName = entries[foundIndex].file;
    *isDir = entries[foundIndex].fileIsDir;
    return 0;
  }
  return 1;
}

int SystemImpl__getLoadModelPath(const char *name, void *prios, void *mps, const char **outDir, char **outName, int *isDir)
{
  int numEntries,res=1;
  size_t nameLen = strlen(name);
  modelicaPathEntry *entries = getAllModelicaPaths(name, nameLen, mps, &numEntries);
  while (RML_NILHDR != RML_GETHDR(prios)) {
    const char *prio = RML_STRINGDATA(RML_CAR(prios));
    if (0==strcmp("default",prio)) {
      if (!getLoadModelPathFromDefaultTarget(name,entries,numEntries,outDir,outName,isDir)) {
        res = 0;
        break;
      }
    } else {
      if (!getLoadModelPathFromSingleTarget(prio,entries,numEntries,outDir,outName,isDir)) {
        res = 0;
        break;
      }
    }
    prios = RML_CDR(prios);
  }
  /* fprintf(stderr, "result: %d %s %s %d", res, *outDir, *outName, *isDir); */
  *outName = *outName ? strdup(*outName) : 0;
  freeAllModelicaPaths(entries,numEntries);
  return res;
}

#define MAX_TMP_TICK 16
static modelica_integer tmp_tick_no[MAX_TMP_TICK] = {0};
static modelica_integer parfor_tick_no = 0;

extern int SystemImpl_tmpTick()
{
  return tmp_tick_no[0]++;
}

extern void SystemImpl_tmpTickReset(int start)
{
  tmp_tick_no[0] = start;
}

extern int SystemImpl_parForTick()
{
  return parfor_tick_no++;
}

extern void SystemImpl_parForTickReset(int start)
{
  parfor_tick_no = start;
}

extern int SystemImpl_tmpTickIndex(int index)
{
  assert(index < MAX_TMP_TICK && index >= 0);
  /* fprintf(stderr, "tmpTickIndex %d => %d\n", index, tmp_tick_no[index]); */
  return tmp_tick_no[index]++;
}

extern int SystemImpl_tmpTickIndexReserve(int index, int reserve)
{
  int tmp = tmp_tick_no[index];
  tmp_tick_no[index] += reserve;
  assert(index < MAX_TMP_TICK && index >= 0);
  /* fprintf(stderr, "tmpTickIndex %d => %d\n", index, tmp_tick_no[index]); */
  return tmp;
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
    c_add_message(-1,ErrorType_scripting,ErrorLevel_error,gettext("freopen(%s,%s,%s) failed: %s"),tokens,4);
    return 0;
  }
  return 1;
}

static char* SystemImpl__iconv__ascii(const char * str)
{
  static char *buf = 0;
  static int buflen = 0;
  char *in_str,*res;
  size_t sz,out_sz;
  iconv_t ic;
  int i;
  sz = strlen(str);
  if (buflen < sz) {
    if (buf) free(buf);
    buf = (char*)malloc(sz);
    if (!buf) {
      buflen = 0;
      return (char*) "";
    }
    buflen = sz;
  }
  *buf = 0;
  for (i=0; i<sz; i++)
    buf[i] = str[i] & 0x80 ? '?' : str[i];
  return buf;
}

extern char* SystemImpl__iconv(const char * str, const char *from, const char *to, int printError)
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
    char *ignore = SystemImpl__iconv__ascii(str);
    const char *tokens[4] = {strerror(errno),from,to,ignore};
    if (printError) c_add_message(-1,ErrorType_scripting,ErrorLevel_error,gettext("iconv(\"%s\",to=\"%s\",from=\"%s\") failed: %s"),tokens,4);
    return (char*) "";
  }
  in_str = (char*) str;
  out_sz = buflen-1;
  res = buf;
  count = iconv(ic,&in_str,&sz,&res,&out_sz);
  iconv_close(ic);
  if (count == -1) {
    char *ignore = SystemImpl__iconv__ascii(str);
    const char *tokens[4] = {strerror(errno),from,to,ignore};
    if (printError) c_add_message(-1,ErrorType_scripting,ErrorLevel_error,gettext("iconv(\"%s\",to=\"%s\",from=\"%s\") failed: %s"),tokens,4);
    return (char*) "";
  }
  buf[(buflen-1)-out_sz] = 0;
  if (strlen(buf) != (buflen-1)-out_sz) {
    if (printError) c_add_message(-1,ErrorType_scripting,ErrorLevel_error,gettext("iconv(to=%s) failed because the character set output null bytes in the middle of the string."),&to,1);
    return (char*) "";
  }
  return buf;
}

#include <tinymt64.h>

static tinymt64_t system_random_seed = {{0,0},0,0,0};

/* NOTES: Randomness provided by random() is guaranteed to be uniform
 * (high and low bits are the same).
 * rand() does not produce good results and should be avoided. */
static void seed(void)
{
  static int init = 0;
  if (!init) {
  /* Skip /dev/random stuff since we want this predictable */
    // set parameters
    system_random_seed.mat1 = 0x8f7011ee;
    system_random_seed.mat2 = 0xfc78ff1f;
    system_random_seed.tmat = 0x3793fdff;
    tinymt64_init(&system_random_seed,1);
    init = 1;
  }
}

/* Returns a value (0,1] */
double SystemImpl__realRand()
{
  seed();
  return tinymt64_generate_double(&system_random_seed);
}

/* Returns an integer (0,n] (i.e. the highest value is n-1) */
int SystemImpl__intRand(int n)
{
  seed();
  return omc_tinymt64_generate_fast_int_range(&system_random_seed, n);
}

char* alloc_locale_str(const char *locale, int llen, const char *suffix, int slen)
{
  char *loc = (char*)malloc(sizeof(char) * (llen + slen + 1));
  assert(loc != NULL);
  strncpy(loc, locale, llen);
  strncpy(loc + llen, suffix, slen + 1);
  return loc;
}

void SystemImpl__gettextInit(const char *locale)
{
#if defined(_MSC_VER)
#else
  const char *omhome = SettingsImpl__getInstallationDirectoryPath();
  char *localedir,*clocale;
  int omlen;
#if defined(__MINGW32__)
  if (*locale) {
    char environment[strlen(locale)+9];
    strcpy(environment, "LANGUAGE=");
    putenv(strcat(environment, locale));
  } else {
    LCID userLocaleId = GetUserDefaultLCID();
    int localeBufferSize = GetLocaleInfo(userLocaleId, LOCALE_SISO639LANGNAME, NULL, 0);
    char userLocaleStr[localeBufferSize];
    GetLocaleInfo(userLocaleId, LOCALE_SISO639LANGNAME, userLocaleStr, localeBufferSize);
    char environment[localeBufferSize+9];
    strcpy(environment, "LANGUAGE=");
    putenv(strcat(environment, userLocaleStr));
  }
#else
  /* We might get sent sv_SE when only sv_SE.utf8 exists, etc */
  int locale_len = strlen(locale);
  char *locale2 = alloc_locale_str(locale, locale_len, ".utf8", 5);
  char *locale3 = alloc_locale_str(locale, locale_len, ".UTF-8", 6);
  char *old_ctype_default = setlocale(LC_CTYPE, "");
  if (!old_ctype_default)
    old_ctype_default = "UTF-8";
  char *old_ctype = strdup(old_ctype_default);
  int old_ctype_is_utf8 = strcmp(nl_langinfo(CODESET), "UTF-8") == 0;

  int res = *locale == 0 ? setlocale(LC_MESSAGES, "") && setlocale(LC_CTYPE, ""):
    (setlocale(LC_MESSAGES, locale3) && setlocale(LC_CTYPE, locale3))  ||
    (setlocale(LC_MESSAGES, locale2) && setlocale(LC_CTYPE, locale2)) ||
    (setlocale(LC_MESSAGES, locale) && setlocale(LC_CTYPE, locale));
  if (!res) {
    fprintf(stderr, gettext("Warning: Failed to set locale: '%s'\n"), locale);
  }
  free(locale2);
  free(locale3);
  clocale = setlocale(LC_CTYPE, NULL);
  int have_utf8 = strcmp(nl_langinfo(CODESET), "UTF-8") == 0;
  /* We succesfully forced a new non-system locale; let's clear some variables */
  if (*locale) {
    unsetenv("LANG");
    unsetenv("LANGUAGE");
  }
  /* Try to make sure we force UTF-8; else gettext will fail */
  if (have_utf8)
     setlocale(LC_CTYPE, clocale);
  else if (old_ctype_is_utf8)
    setlocale(LC_CTYPE, old_ctype);
  else if (!(strstr(clocale, "UTF-8") || strstr(clocale, "UTF8") ||
             strstr(clocale, "utf-8") || strstr(clocale, "utf8")) &&
            !(setlocale(LC_CTYPE, "C.UTF-8") ||
              setlocale(LC_CTYPE, "en_US.UTF-8") ||
              setlocale(LC_CTYPE, "en_GB.UTF-8") ||
              setlocale(LC_CTYPE, "UTF-8"))) {
    fprintf(stderr, gettext("Warning: Failed to set LC_CTYPE to UTF-8 using the chosen locale and C.UTF-8. OpenModelica assumes all input and output it makes is in UTF-8 so you might have some issues.\n"));
  }
  free(old_ctype);
#endif /* __MINGW32__ */
  if(omhome == NULL)
  {
  fprintf(stderr, "Warning: environment variable OPENMODELICAHOME is not set. Cannot load locale.\n");
  return;
  }
  omlen = strlen(omhome);
  localedir = (char*) malloc(omlen + 25);
  sprintf(localedir, "%s/share/locale", omhome);
  bindtextdomain ("openmodelica", localedir);
  textdomain ("openmodelica");
  free(localedir);
#endif /* _MSC_VER */
}

const char* SystemImpl__gettext(const char *msgid)
{
#if defined(_MSC_VER)
  return msgid;
#else
  return gettext(msgid);
#endif
}


#if defined(__MINGW32__) || defined(_MSC_VER)

#ifdef __MINGW32__

char *realpath(const char *path, char resolved_path[PATH_MAX])
{
  if (!_fullpath(resolved_path, path, PATH_MAX))
  {
    const char *c_tokens[0]={};
    const char* fmt = "System.realpath failed on %s with errno: %d";
    char* msg = (char*)malloc(strlen(path) + strlen(fmt) + 10);
    sprintf(msg, fmt, path, errno);
    c_add_message(6000,
      ErrorType_scripting,
      ErrorLevel_warning,
      msg,
      c_tokens,
      0);
    resolved_path = (char*)path;
  }
  return resolved_path;
}

#else

/*
realpath() Win32 implementation, supports non standard glibc extension
This file has no copyright assigned and is placed in the Public Domain.
Written by Nach M. S. September 8, 2005
*/

#include <windows.h>
#include <stdlib.h>
#include <limits.h>
#include <errno.h>
#include <sys/stat.h>

char *realpath(const char *path, char resolved_path[PATH_MAX])
{
  char *return_path = 0;

  if (path) //Else EINVAL
  {
    if (resolved_path)
    {
      return_path = resolved_path;
    }
    else
    {
      //Non standard extension that glibc uses
      return_path = (char*)malloc(PATH_MAX);
    }

    if (return_path) //Else EINVAL
    {
      //This is a Win32 API function similar to what realpath() is supposed to do
      size_t size = GetFullPathNameA(path, PATH_MAX, return_path, 0);

      //GetFullPathNameA() returns a size larger than buffer if buffer is too small
      if (size > PATH_MAX)
      {
        if (return_path != resolved_path) //Malloc'd buffer - Unstandard extension retry
        {
          size_t new_size;

          free(return_path);
          return_path = (char*)malloc(size);

          if (return_path)
          {
            new_size = GetFullPathNameA(path, size, return_path, 0); //Try again

            if (new_size > size) //If it's still too large, we have a problem, don't try again
            {
              free(return_path);
              return_path = 0;
              errno = ENAMETOOLONG;
            }
            else
            {
              size = new_size;
            }
          }
          else
          {
            //I wasn't sure what to return here, but the standard does say to return EINVAL
            //if resolved_path is null, and in this case we couldn't malloc large enough buffer
            errno = EINVAL;
          }
        }
        else //resolved_path buffer isn't big enough
        {
          return_path = 0;
          errno = ENAMETOOLONG;
        }
      }

      //GetFullPathNameA() returns 0 if some path resolve problem occured
      if (!size)
      {
        if (return_path != resolved_path) //Malloc'd buffer
        {
          free(return_path);
        }

        return_path = 0;

        //Convert MS errors into standard errors
        switch (GetLastError())
        {
          case ERROR_FILE_NOT_FOUND:
            errno = ENOENT;
            break;

          case ERROR_PATH_NOT_FOUND: case ERROR_INVALID_DRIVE:
            errno = ENOTDIR;
            break;

          case ERROR_ACCESS_DENIED:
            errno = EACCES;
            break;

          default: //Unknown Error
            errno = EIO;
            break;
        }
      }

      //If we get to here with a valid return_path, we're still doing good
      if (return_path)
      {
        struct stat stat_buffer;

        //Make sure path exists, stat() returns 0 on success
        if (stat(return_path, &stat_buffer))
        {
          if (return_path != resolved_path)
          {
            free(return_path);
          }

          return_path = 0;
          //stat() will set the correct errno for us
        }
        //else we succeeded!
      }
    }
    else
    {
      errno = EINVAL;
    }
  }
  else
  {
    errno = EINVAL;
  }

  if (return_path == NULL)
  {
    const char *c_tokens[0]={};
    const char* fmt = "System.realpath failed on %s with errno: %d";
    char* msg = (char*)malloc(strlen(path) + strlen(fmt) + 10);
    sprintf(msg, fmt, path, errno);
    c_add_message(6000,
      ErrorType_scripting,
      ErrorLevel_warning,
      msg,
      c_tokens,
      0);
    resolved_path = (char*)path;
    return_path = (char*)path;
  }

  return return_path;
}
#endif /* mingw */

#endif /* mingw and msvc */

int System_getTerminalWidth()
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  return 80;
#else
  struct winsize w;
  ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);
  return w.ws_col ? w.ws_col : 80;
#endif
}

#include "simulation_options.h"

char* System_getSimulationHelpText(int detailed)
{
  static char buf[8192];
  int i;
  const char **desc = detailed ? FLAG_DETAILED_DESC : FLAG_DESC;
  char *cur = buf;
  *cur = 0;
  for(i=1; i<FLAG_MAX; ++i)
  {
    if (FLAG_TYPE[i] == FLAG_TYPE_FLAG) {
      cur += snprintf(cur, 8191-(buf-cur), "<-%s>\n  %s\n", FLAG_NAME[i], desc[i]);
    } else if (FLAG_TYPE[i] == FLAG_TYPE_OPTION) {
      cur += snprintf(cur, 8191-(buf-cur), "<-%s=value> or <-%s value>\n  %s\n", FLAG_NAME[i], FLAG_NAME[i], desc[i]);
    } else {
      cur += snprintf(cur, 8191-(buf-cur), "[unknown flag-type] <-%s>\n", FLAG_NAME[i]);
    }
  }
  *cur = 0;
  return buf;
}

int SystemImpl__fileIsNewerThan(const char *file1, const char *file2)
{
#if defined(_MSC_VER)
  WIN32_FIND_DATA FileData;
  HANDLE sh1,sh2;
  FILETIME ftWrite1, ftWrite2;

  sh1 = FindFirstFile(file1, &FileData);
  if (sh1 == INVALID_HANDLE_VALUE) {
    return -1;
  }
  sh2 = FindFirstFile(file2, &FileData);
  if (sh2 == INVALID_HANDLE_VALUE) {
    FindClose(sh1);
    return -1;
  }
  if (!(GetFileTime(sh1, NULL, NULL, &ftWrite1) && GetFileTime(sh2, NULL, NULL, &ftWrite2))) {
    FindClose(sh1);
    FindClose(sh2);
    return -1;
  }
  FindClose(sh1);
  FindClose(sh2);
  return ((LARGE_INTEGER*)&ftWrite1)->QuadPart - ((LARGE_INTEGER*)&ftWrite2)->QuadPart > 0 ? 1 : 0;
#else
  struct stat buf1, buf2;
  if (stat(file1, &buf1)) {
    const char *c_tokens[2]={strerror(errno),file1};
    c_add_message(85,
        ErrorType_scripting,
        ErrorLevel_error,
        gettext("Could not access file %s: %s."),
        c_tokens,
        2);
    return -1;
  }
  if (stat(file2, &buf2)) {
    const char *c_tokens[2]={strerror(errno),file2};
    c_add_message(85,
        ErrorType_scripting,
        ErrorLevel_error,
        gettext("Could not access file %s: %s."),
        c_tokens,
        2);
    return -1;
  }
  return difftime(buf1.st_mtime, buf2.st_mtime) > 0 ? 1 : 0;
#endif
}

#ifdef WITH_HWLOC
#include <hwloc.h>
#endif

int System_numProcessors()
{
#ifdef WITH_HWLOC
  hwloc_topology_t topology;
  hwloc_topology_init(&topology);
  hwloc_topology_load(topology);
  int depth = hwloc_get_type_depth(topology, HWLOC_OBJ_CORE);
  if(depth != HWLOC_TYPE_DEPTH_UNKNOWN) {
    int res = hwloc_get_nbobjs_by_depth(topology, depth);
    hwloc_topology_destroy(topology);
    return res;
  }
#endif
#if defined(_MSC_VER)
  SYSTEM_INFO sysinfo;
  GetSystemInfo( &sysinfo );
  return sysinfo.dwNumberOfProcessors;
#else
  return max(sysconf(_SC_NPROCESSORS_ONLN), 1);
#endif
}

#ifdef __cplusplus
}
#endif
