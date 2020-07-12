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
#include "is_utf8.h"

/*
 * Common includes
 */
#if !defined(_MSC_VER)
#include <libgen.h>
#include <dirent.h>
#include <unistd.h>
#endif

#include "meta/meta_modelica.h"
#include <limits.h>
#include "ModelicaUtilities.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

#include "util/rtclock.h"
#include "omc_config.h"
#include "errorext.h"
#include "settingsimpl.h"
#include "printimpl.h"

#if defined(_MSC_VER) /* no iconv for VS! */

typedef void* iconv_t;
#define iconv_open(tocode, fromcode)  (0)
#define iconv_close(cd) (0)
#define iconv(cd,  inbuf, inbytesleft, outbuf, outbytesleft) (0)

#else /* real compilers */

#include "iconv.h"

#endif


#if defined(__MINGW32__) || defined(_MSC_VER)
#include <rpc.h>
#define getFunctionPointerFromDLL  GetProcAddress
#define FreeLibraryFromHandle !FreeLibrary

#else /* *nix / Mac */

#include <signal.h>

#define getFunctionPointerFromDLL dlsym
#define FreeLibraryFromHandle dlclose
#define GetLastError(X) 1L
#include <fcntl.h>

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

#else
/* includes/defines specific for LINUX/OS X */
#include <ctype.h>
#include <dirent.h>
#include <sys/ioctl.h>
#include <sys/param.h> /* MAXPATHLEN */
#include <sys/unistd.h>
#include <sys/wait.h> /* only available in Linux, not windows */
#include <unistd.h>
#include <stdlib.h>
#include <spawn.h>

#include <dlfcn.h>
extern char **environ;

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

static inline modelica_integer alloc_ptr(void);
static inline void free_ptr(modelica_integer index);
static void free_library(modelica_ptr_t lib, modelica_integer printDebug);
static void free_function(modelica_ptr_t func);

static const char def_cc[]     = DEFAULT_CC;
static const char def_cxx[]    = DEFAULT_CXX;
static const char def_ompcc[]  = DEFAULT_OMPCC;
static const char def_linker[] = DEFAULT_LINKER;
static const char def_cflags[] = DEFAULT_CFLAGS;
static const char def_ldflags[]= DEFAULT_LDFLAGS;

static char *cc     = (char *)def_cc;
static char *cxx    = (char *)def_cxx;
static char *omp_cc = (char *)def_ompcc;
static char *linker = (char *)def_linker;
static char *cflags = (char *)def_cflags;
static char *ldflags= (char *)def_ldflags;

/* TODO! FIXME!
 * we need to move these to threadData if we are to run things in parallel in OMC!
 */
static int hasExpandableConnectors = 0;
static int hasOverconstrainedConnectors = 0;
static int hasInnerOuterDefinitions = 0;
static int hasStreamConnectors = 0;
static int isPartialInstantiation = 0;
static int usesCardinality = 1;
static char* class_names_for_simulation = NULL;
static const char *select_from_dir = NULL;

/*
 * Common implementations
 */

static inline int intMax(int a, int b)
{
  return a > b ? a : b;
}

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
  char preChar;
  char filterChars[] = "0123456789.\0";
  char numeric[] = "0123456789\0";
  slen = strlen(buf);
  preChar = '\0';
  for(i=0;i<slen;++i) {
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
  cc = omc_alloc_interface.malloc_strdup(str);
  if (cc == NULL) return -1;
  return 0;
}

extern int SystemImpl__setCXXCompiler(const char *str)
{
  cxx = omc_alloc_interface.malloc_strdup(str);
  if (cxx == NULL) return -1;
  return 0;
}

extern int SystemImpl__setLinker(const char *str)
{
  linker = omc_alloc_interface.malloc_strdup(str);
  if (linker == NULL) return -1;
  return 0;
}

extern int SystemImpl__setCFlags(const char *str)
{
  cflags = omc_alloc_interface.malloc_strdup(str);
  if (cflags == NULL) return -1;
  return 0;
}

extern int SystemImpl__setLDFlags(const char *str)
{
  ldflags = omc_alloc_interface.malloc_strdup(str);
  if (ldflags == NULL) return -1;
  return 0;
}

#if defined(__MINGW32__) || defined(_MSC_VER)
/* Make sure windows paths use frontslash and not backslash */
void SystemImpl__toWindowsSeperators(char* buffer, int bufferLength)
{
  int i;
  for (i=0; i<bufferLength && buffer[i]; i++) {
    if (buffer[i] == '\\') buffer[i] = '/';
  }
}
#endif

int SystemImpl__chdir(const char* path)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  MULTIBYTE_TO_WIDECHAR_LENGTH(path, unicodePathLength);
  MULTIBYTE_TO_WIDECHAR_VAR(path, unicodePath, unicodePathLength);

  if (!SetCurrentDirectoryW(unicodePath)) {
    MULTIBYTE_OR_WIDECHAR_VAR_FREE(unicodePath);
    c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("SetCurrentDirectoryW failed."),NULL,0);
    return -1;
  }
  MULTIBYTE_OR_WIDECHAR_VAR_FREE(unicodePath);
  return 0;
#else
  if (chdir(path) != 0) {
    c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("chdir failed."),NULL,0);
    return -1;
  }
  return 0;
#endif
}

extern char* SystemImpl__pwd(void)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  DWORD bufLen = 0;
  bufLen = GetCurrentDirectoryW(bufLen, 0);
  if (!bufLen) {
    c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("GetCurrentDirectoryW failed."),NULL,0);
    return NULL;
  }

  WCHAR unicodePath[bufLen];
  if (!GetCurrentDirectoryW(bufLen, unicodePath)) {
    c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("GetCurrentDirectoryW failed."),NULL,0);
    return NULL;
  }
  WIDECHAR_TO_MULTIBYTE_LENGTH(unicodePath, bufferLength);
  WIDECHAR_TO_MULTIBYTE_VAR(unicodePath, buffer, bufferLength);
  SystemImpl__toWindowsSeperators(buffer, bufferLength);
  char *res = omc_alloc_interface.malloc_strdup(buffer);
  MULTIBYTE_OR_WIDECHAR_VAR_FREE(buffer);
  return res;
#else
  char buf[MAXPATHLEN];
  if (NULL == getcwd(buf,MAXPATHLEN)) {
    c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("System.pwd failed."),NULL,0);
    return NULL;
  }
  return omc_alloc_interface.malloc_strdup(buf);
#endif
}

extern int SystemImpl__regularFileExists(const char* str)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  WIN32_FIND_DATAW FileData;
  HANDLE sh;

  MULTIBYTE_TO_WIDECHAR_LENGTH(str, unicodeFilenameLength);
  MULTIBYTE_TO_WIDECHAR_VAR(str, unicodeFilename, unicodeFilenameLength);

  sh = FindFirstFileW(unicodeFilename, &FileData);

  MULTIBYTE_OR_WIDECHAR_VAR_FREE(unicodeFilename);

  if (sh == INVALID_HANDLE_VALUE) {
    if (strlen(str) >= MAXPATHLEN)
    {
      const char *c_tokens[1]={str};
      c_add_message(NULL,85, /* error opening file */
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
  f = omc_fopen(str, "a");
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
#if defined(__MINGW32__) || defined(_MSC_VER)
  struct _stat statstr;
#else
  struct stat statstr;
#endif
  res = omc_stat(filename, &statstr);

  if (res != 0) {
    const char *c_tokens[2]={strerror(errno),filename};
    c_add_message(NULL,85, /* ERROR_OPENING_FILE */
      ErrorType_scripting,
      ErrorLevel_error,
      gettext("Error opening file: %s: %s."),
      c_tokens,
      2);
    MMC_THROW();
  }

  /* adrpo: if size is larger than the max string, return a different string */
#if !(defined(_LP64) || defined(_LLP64) || defined(_WIN64) || defined(__MINGW64__))
  if (statstr.st_size > (pow((double)2, (double)22) * 4)) {
    const char *c_tokens[1]={filename};
    c_add_message(NULL,85, /* ERROR_OPENING_FILE */
      ErrorType_scripting,
      ErrorLevel_error,
      gettext("File too large to fit into a MetaModelica string: %s."),
      c_tokens,
      1);
    MMC_THROW();
  }
#endif

  file = omc_fopen(filename,"rb");
  if (file == NULL) {
    const char *c_tokens[2]={strerror(errno),filename};
    c_add_message(NULL, 85, /* ERROR_OPENING_FILE */
      ErrorType_scripting,
      ErrorLevel_error,
      gettext("Error opening file: %s (its size is known, but failed to open it): %s"),
      c_tokens,
      2);
    MMC_THROW();
  }
  buf = (char*) omc_alloc_interface.malloc_atomic(statstr.st_size+1);

  if( (res = fread(buf, sizeof(char), statstr.st_size, file)) != statstr.st_size) {
    const char *c_tokens[2]={strerror(errno),filename};
    c_add_message(NULL,85, /* ERROR_OPENING_FILE */
      ErrorType_scripting,
      ErrorLevel_error,
      gettext("Failed to read the entire file: %s: %s"),
      c_tokens,
      2);
    fclose(file);
    MMC_THROW();
  }
  buf[statstr.st_size] = '\0';
  fclose(file);
  return buf;
}

/* returns 0 on success */
int SystemImpl__removeFile(const char* filename)
{
  return omc_unlink(filename);
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
  int len = strlen(data); /* MMC_HDRSTRLEN(MMC_GETHDR(rmlA1)); */
#if defined(__APPLE_CC__)||defined(__MINGW32__)||defined(__MINGW64__)
  SystemImpl__removeFile(filename);
#endif
  /* adrpo: 2010-09-22 open the file in BINARY mode as otherwise \r\n becomes \r\r\n! */
  file = omc_fopen(filename,fileOpenMode);
  if (file == NULL) {
    const char *c_tokens[1]={filename};
    c_add_message(NULL,21, /* WRITING_FILE_ERROR */
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
    c_add_message(NULL,21, /* WRITING_FILE_ERROR */
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
    c_add_message(NULL,21, /* WRITING_FILE_ERROR */
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
  res = (char*) omc_alloc_interface.malloc_atomic(length+1);
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
    res = (char*)omc_alloc_interface.malloc_atomic(end_pos - start_pos +2);
    strncpy(res,&str[start_pos],end_pos - start_pos+1);
    res[end_pos - start_pos+1] = '\0';
    rmlRes = (void*) mmc_mk_scon(res);
    return rmlRes;
  } else {
    return mmc_mk_scon("");
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

#if defined(__MINGW32__) || defined(_MSC_VER)
int runProcess(const char* cmd)
{
  STARTUPINFOW si;
  PROCESS_INFORMATION pi;
  char *c = "cmd /c";
  char *command = (char *)omc_alloc_interface.malloc_atomic(strlen(cmd) + strlen(c) + 4);
  DWORD exitCode = 1;

  ZeroMemory(&si, sizeof(si));
  si.cb = sizeof(si);
  ZeroMemory(&pi, sizeof(pi));


  sprintf(command, "%s \"%s\"", c, cmd);

  /* fprintf(stderr, "%s\n", command); fflush(NULL); */

  MULTIBYTE_TO_WIDECHAR_LENGTH(command, unicodeCommandLength);
  MULTIBYTE_TO_WIDECHAR_VAR(command, unicodeCommand, unicodeCommandLength);

  if (CreateProcessW(NULL, unicodeCommand, NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi))
  {
    WaitForSingleObject(pi.hProcess, INFINITE);
    // Get the exit code.
    GetExitCodeProcess(pi.hProcess, &exitCode);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
  }
  MULTIBYTE_OR_WIDECHAR_VAR_FREE(unicodeCommand);
  GC_free(command);
  return (int)exitCode;
}
#endif

int SystemImpl__systemCall(const char* str, const char* outFile)
{
  int status = -1,ret_val = -1;
  const int debug = 0;
  if (debug) {
    fprintf(stderr, "System.systemCall: %s\n", str); fflush(NULL);
  }

  fflush(NULL); /* flush output so the testsuite is deterministic */
#if defined(__MINGW32__) || defined(_MSC_VER)
  if (*outFile) {
    char *command = (char *)omc_alloc_interface.malloc_atomic(strlen(str) + strlen(outFile) + 12);
    sprintf(command, "%s >> \"%s\" 2>&1", str, outFile);
    status = runProcess(command);
    GC_free((void*)command);
  } else {
    status = runProcess(str);
  }
#else
  pid_t pID = vfork();
  if (pID == 0) { // child
    if (*outFile) {
      /* redirect stdout, stderr in the fork'ed process */
      int fd = open(outFile, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);
      if (fd < 0) {
        _exit(1);
      }
      dup2(fd, 1);
      dup2(fd, 2);
#if defined(__APPLE_CC__)
      /* OSX likes to not redirect the Segmentation Fault: messages unless the command is in a subshell */
      char command[strlen(str)+3];
      sprintf(command, "(%s)", str);
      execl("/bin/sh", "/bin/sh", "-c", command, NULL);
#else
      execl("/bin/sh", "/bin/sh", "-c", str, NULL);
#endif
    } else {
      execl("/bin/sh", "/bin/sh", "-c", str, NULL);
    }
    if (debug) {
      fprintf(stderr, "System.systemCall: execl failed %s\n", strerror(errno));
      fflush(NULL);
    }
    _exit(1);
  } else if (pID < 0) {
    const char *tokens[2] = {strerror(errno),str};
    c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("system(%s) failed: %s"),tokens,2);
    return -1;
  } else {

    while (waitpid(pID, &status, 0) == -1) {
      if (errno == EINTR) {
        continue;
      } else {
        const char *tokens[2] = {strerror(errno),str};
        c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error, gettext("system(%s) failed: %s"),tokens,2);
        break;
      }
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

char* System_popen(threadData_t *threadData, const char* command, int *status)
{
  int ret_val = -1;
  const int debug = 0;
  if (debug) {
    fprintf(stderr, "System.popen: %s\n", command); fflush(NULL);
  }

#if defined(__MINGW32__) || defined(_MSC_VER)
  *status = 1;
  return "Windows does not have popen";
#else
  FILE *pipe = popen(command, "r");
  if (pipe == NULL) {
    *status = 1;
    return "popen returned NULL";
  }
  long handle = Print_saveAndClearBuf(threadData);
  char buf[4096];
  while (fgets(buf, 4096, pipe) != NULL){
    Print_printBuf(threadData, buf);
  }

  if (debug) {
    fprintf(stderr, "System.pipe: returned\n"); fflush(NULL);
  }

  char *res = omc_alloc_interface.malloc_strdup(-1 == pclose(pipe) ? strerror(errno) : Print_getString(threadData));
  Print_restoreBuf(threadData, handle);

  if (debug) {
    fprintf(stderr, "System.systemCall: returned value: %d\n", ret_val); fflush(NULL);
  }

  return res;
#endif
}

#if WITH_HWLOC==1
#include <hwloc.h>
#endif

int System_numProcessors(void)
{
#if WITH_HWLOC==1
  hwloc_topology_t topology;
  if (0==hwloc_topology_init(&topology) && 0==hwloc_topology_load(topology)) {
    int depth = hwloc_get_type_depth(topology, HWLOC_OBJ_CORE);
    if(depth != HWLOC_TYPE_DEPTH_UNKNOWN) {
      int res = hwloc_get_nbobjs_by_depth(topology, depth);
      hwloc_topology_destroy(topology);
      return intMax(res,1);
    }
  }
#endif
#if defined(__MINGW32__) || defined(_MSC_VER)
  SYSTEM_INFO sysinfo;
  GetSystemInfo( &sysinfo );
  return intMax(sysinfo.dwNumberOfProcessors, 1);
#else
  return intMax(sysconf(_SC_NPROCESSORS_ONLN), 1);
#endif
}

struct systemCallWorkerThreadArgs {
  pthread_mutex_t *mutex;
  int *current;
  int size;
  char **calls;
  int *results;
};

static void* systemCallWorkerThread(void *argVoid)
{
  struct systemCallWorkerThreadArgs *arg = (struct systemCallWorkerThreadArgs *) argVoid;
  while (1) {
    int i;
    pthread_mutex_lock(arg->mutex);
    i = (*arg->current);
    *arg->current+=1;
    pthread_mutex_unlock(arg->mutex);
    if (i >= arg->size) break;
    arg->results[i] = SystemImpl__systemCall(arg->calls[i],"");
  };
  return NULL;
}

void* SystemImpl__systemCallParallel(void *lst, int numThreads)
{
  void *tmp = lst;
  int sz = 0, i = 0;
  char **calls;
  int *results;
  while (MMC_NILHDR != MMC_GETHDR(tmp)) {
    sz++;
    tmp = MMC_CDR(tmp);
  }
  if (sz == 0) return mmc_mk_nil();
  calls = (char**) omc_alloc_interface.malloc(sz*sizeof(char*));
  assert(calls);
  results = (int*) omc_alloc_interface.malloc_atomic(sz*sizeof(int));
  assert(results);
  tmp = lst;
  if (numThreads > sz) {
    numThreads = sz;
  }
  sz=0;
  while (MMC_NILHDR != MMC_GETHDR(tmp)) {
    calls[sz++] = MMC_STRINGDATA(MMC_CAR(tmp));
    tmp = MMC_CDR(tmp);
  }
  if (sz == 1) {
    results[i] = SystemImpl__systemCall(calls[0],"");
  } else {
    int index = 0;
    pthread_mutex_t mutex;
    struct systemCallWorkerThreadArgs args = {&mutex,&index,sz,calls,results};
    pthread_t *th = NULL;
    pthread_mutex_init(&mutex,NULL);
    th = omc_alloc_interface.malloc(sizeof(pthread_t)*numThreads);
    /* Last element is NULL from GC_malloc */
    for (i=0; i<numThreads; i++) {
      GC_pthread_create(&th[i],NULL,systemCallWorkerThread,&args);
    }
    for (i=0; i<numThreads; i++) {
      GC_pthread_join(th[i], NULL);
    }
    GC_free(th);
    pthread_mutex_destroy(&mutex);
  }
  GC_free(calls);
  tmp = mmc_mk_nil();
  for (i=sz-1; i>=0; i--) {
    tmp = mmc_mk_cons(mmc_mk_icon(results[i]),tmp);
  }
  GC_free(results);
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
  pid_t pid;
  int status;
  const char * argv[4] = {"/bin/sh","-c",str,NULL};
  ret_val = (0 == posix_spawn(&pid, "/bin/sh", NULL, NULL, (char * const *) argv, environ));
#endif
  fflush(NULL); /* flush output so the testsuite is deterministic */

  if (debug) {
    fprintf(stderr, "System.spawnCall: returned value: %d\n", ret_val); fflush(NULL);
  }

  return ret_val;
}

int SystemImpl__plotCallBackDefined(threadData_t *threadData)
{
  if (threadData->plotClassPointer && threadData->plotCB) {
    return 1;
  } else {
    return 0;
  }
}

void SystemImpl__plotCallBack(threadData_t *threadData, int externalWindow, const char* filename, const char* title, const char* grid, const char* plotType,
                              const char* logX, const char* logY, const char* xLabel, const char* yLabel, const char* x1, const char* x2, const char* y1,
                              const char* y2, const char* curveWidth, const char* curveStyle, const char* legendPosition, const char* footer, const char* autoScale,
                              const char* variables)
{
  if (threadData->plotClassPointer && threadData->plotCB) {
    PlotCallback pcb = threadData->plotCB;
    pcb(threadData->plotClassPointer, externalWindow, filename, title, grid, plotType, logX, logY, xLabel, yLabel, x1, x2, y1, y2, curveWidth, curveStyle,
        legendPosition, footer, autoScale, variables);
  }
}

extern double SystemImpl__time(void)
{
  clock_t cl = clock();
  return (double)cl / (double)CLOCKS_PER_SEC;
}

extern int SystemImpl__directoryExists(const char *str)
{
  /* if the string is NULL return 0 */
  if (!str) return 0;
#if defined(__MINGW32__) || defined(_MSC_VER)
  WIN32_FIND_DATA FileData;
  HANDLE sh;
  char* path = strdup(str);
  int last = strlen(path)-1;
  /* adrpo: RTFM! the path cannot end in a slash??!! https://msdn.microsoft.com/en-us/library/windows/desktop/aa364418(v=vs.85).aspx */
  if (last > 0 && (path[last] == '\\' || path[last] == '/')) path[last] = '\0';
  sh = FindFirstFile(path, &FileData);
  free(path);
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

extern int SystemImpl__createDirectory(const char *str)
{
  int rv;

#if defined(__MINGW32__) || defined(_MSC_VER)
  rv = mkdir(str);
#else
  rv = mkdir(str, S_IRWXU);
#endif
  if (rv == -1)
  {
    return 0;
  }
  else
  {
    return 1;
  }
}

extern int SystemImpl__copyFile(const char *str_1, const char *str_2)
{
  int rv = 1;
  size_t n;
  char buf[8192];
  FILE *source, *target;

  source = fopen(str_1, "r");
  if (source==0) {
    const char *msg[2] = {strerror(errno), str_1};
    c_add_message(NULL,85,
      ErrorType_scripting,
      ErrorLevel_error,
      gettext("Error opening file for reading %s: %s"),
      msg,
      2);
    return 0;
  }
  target = fopen(str_2, "w");
  if (target==0) {
    const char *msg[2] = {strerror(errno), str_2};
    c_add_message(NULL,85,
      ErrorType_scripting,
      ErrorLevel_error,
      gettext("Error opening file for writing %s: %s"),
      msg,
      2);
    fclose(source);
    return 0;
  }

  while ( n = fread(buf, 1, 8192, source) ) {
    if (n != fwrite(buf, 1, n, target)) {
      rv = 0;
      break;
    }
  }
  if (rv == 0) {
    const char *msg[3] = {strerror(errno), str_2, str_1};
    c_add_message(NULL,85,
      ErrorType_scripting,
      ErrorLevel_error,
      gettext("Error copying file contents %s to %s: %s"),
      msg,
      3);
  }
  if (!feof(source)) {
    rv = 0;
  }

  fclose(source);
  fclose(target);
  return rv;
}

static char * SystemImpl__NextDir(const char * path)
{
  char * res = NULL;

#if defined(__MINGW32__) || defined(_MSC_VER)
  res = strchr(path, '\\');
#endif
  if (res == NULL)
  {
    res = strchr(path, '/');
  }
  if (res != NULL)
  {
      res++;
  }
  return res;
}

static int SystemImpl__removeDirectoryItem(const char *path)
{
  int retval;
  DIR * d = opendir(path);

  if (d != NULL)
  {
    struct dirent * p;
    size_t path_len = strlen(path);

    retval = 0;
    while ((retval == 0) && (p = readdir(d)))
    {
      int r2 = -1;
      char * buf;
      size_t len;

      /* Do not recurse on "." and ".." */
      if ((p->d_name[0] == '.') && ( (p->d_name[1] == 0) || ((p->d_name[1] == '.') && (p->d_name[2] == 0))))
      {
        continue;
      }

      len = path_len + strlen(p->d_name) + 2;
      buf = (char *)omc_alloc_interface.malloc_atomic(len);
      if (buf != NULL)
      {
        struct stat statbuf;

        snprintf(buf, len, "%s/%s", path, p->d_name);
        if (stat(buf, &statbuf) == 0)
        {
          if (S_ISDIR(statbuf.st_mode))
          {
            r2 = 0==SystemImpl__removeDirectory(buf);
          }
          else
          {
            r2 = unlink(buf);
          }
        }
      }
      retval = r2;
    }
    closedir(d);

    if (retval == 0)
    {
      /* if everything is ok, then dir should be empty now */
      retval = rmdir(path);
    }
  }
  else
  {
    /* Could not open path as dir, try to handle as file */
    retval = unlink(path);
  }

  return retval;
}

extern int SystemImpl__removeDirectory(const char *path)
{
  int retval = -1;
  char * wild = strchr(path, '*');

  if (wild == NULL)
  {
    retval = SystemImpl__removeDirectoryItem(path);
  }
  else
  {
    /* [ basepath '/' ] [pat_pre] '*' [pat_post] [ '/' sub ] */
    /* replace first wildcard item */
    char * basepath;
    char * ctmp = NULL;
    const char * str = path;
    DIR * d;
    char * pattern;
    char * pat_pre = NULL;
    char * pat_post = NULL;
    char * sub = NULL;
    size_t len_sub = 0;

    do
    {
      char * res = SystemImpl__NextDir(str);

      if (res == NULL)
      {
        /* basepath is finally found */
        pattern = omc_alloc_interface.malloc_strdup(str);
        break;
      }
      else
      {
        if (res <= wild)
        {
          /* found new constituent of basepath */
          ctmp = res;
          str = res;
        }
        else
        {
          /* basepath is finally found */
          pattern = omc_alloc_interface.malloc_strdup(str);
          sub = res;
          len_sub = strlen(sub);
          break;
        }
      }
    } while(1);

    /* prepare basepath */
    if (ctmp == NULL) {
      basepath = ".";
    } else {
      size_t len = ctmp-path;
      basepath = (char *)omc_alloc_interface.malloc_atomic(len);
      strncpy(basepath, path, len);
      basepath[len-1] = 0;
    }

    /* prepare pattern */
    ctmp = SystemImpl__NextDir(pattern);
    if (ctmp != NULL)
    {
        ctmp--;
        *ctmp = 0;
    }
    pat_pre = pattern;
    pat_post = strchr(pattern, '*');
    *pat_post = 0;
    pat_post++;

    d = opendir(basepath);
    if (d != NULL)
    {
      struct dirent * p;

      size_t len_base = strlen(basepath);
      size_t len_pre = strlen(pat_pre);
      size_t len_post = strlen(pat_post);

      while ((p = readdir(d)) != NULL)
      {
        size_t len;

        /* Do not recurse on "." and ".." */
        if ((p->d_name[0] == '.') && ( (p->d_name[1] == 0) || ((p->d_name[1] == '.') && (p->d_name[2] == 0))))
        {
          continue;
        }

        len = strlen(p->d_name);
        if ((len >= (len_pre+len_post)) && (strncmp(p->d_name, pat_pre, len_pre) == 0))
        {
          if (strcmp(p->d_name+(len-len_post), pat_post) == 0)
          {
            /* pre and post pattern do match */
            struct stat statbuf;
            char * newdir = (char *)omc_alloc_interface.malloc_atomic(len_base+len+len_sub+3);

            strcpy(newdir, basepath);
            strcat(newdir, "/");
            strcat(newdir, p->d_name);
            if (stat(newdir, &statbuf) == 0)
            {
              if (S_ISDIR(statbuf.st_mode))
              {
                if (sub != NULL)
                {
                  strcat(newdir, "/");
                  strcat(newdir, sub);
                }
                SystemImpl__removeDirectory(newdir);
              }
              else
              {
                if (sub == NULL)
                {
                  unlink(newdir);
                }
                else
                {
                  /* we have more paths, but this is no directory, skip */
                }
              }
            }
          }
        }
      }
      closedir(d);
      retval = 0;
    }
    else
    {
      retval = -1;
    }
  }

  return retval==0;
}

extern const char* SystemImpl__readFileNoNumeric(const char* filename)
{
  char* buf, *bufRes;
  int res,numCount;
  FILE * file = NULL;
#if defined(__MINGW32__) || defined(_MSC_VER)
  struct _stat statstr;
#else
  struct stat statstr;
#endif
  res = omc_stat(filename, &statstr);

  if(res!=0) {
    const char *c_tokens[1]={filename};
    c_add_message(NULL,85, /* ERROR_OPENING_FILE */
      ErrorType_scripting,
      ErrorLevel_error,
      gettext("Error opening file %s."),
      c_tokens,
      1);
    return "No such file";
  }

  file = omc_fopen(filename,"rb");
  buf = (char*) omc_alloc_interface.malloc_atomic(statstr.st_size+1);
  bufRes = (char*) omc_alloc_interface.malloc_atomic((statstr.st_size+70)*sizeof(char));
  if( (res = fread(buf, sizeof(char), statstr.st_size, file)) != statstr.st_size) {
    fclose(file);
    return "Failed while reading file";
  }
  buf[statstr.st_size] = '\0';
  numCount = filterString(buf,bufRes);
  fclose(file);
  sprintf(bufRes,"%s\nFilter count from number domain: %d",bufRes,numCount);
  return bufRes;
}

extern double SystemImpl__getCurrentTime(void)
{
  time_t t;
  time( &t );
  return difftime(t, 0); // the current time
}

#if !defined(__MINGW32__) && !defined(_MSC_VER)

typedef const struct dirent* direntry;

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

static int file_select_moc(direntry entry)
{
  char* ptr;
  if ((strcmp(entry->d_name, ".") == 0) ||
      (strcmp(entry->d_name, "..") == 0) ||
      (strcmp(entry->d_name, "package.moc") == 0)) {
    return (0);
  } else {
    ptr = (char*)rindex(entry->d_name, '.');
    if ((ptr != NULL) &&
  ((strcmp(ptr, ".moc") == 0))) {
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
  char *temp = (char*)omc_alloc_interface.malloc_atomic(strlen(envname)+strlen(envvalue)+2);
  sprintf(temp,"%s=%s", envname, envvalue);
  res = _putenv(temp);
  return res;
}
#endif

#if defined(WITH_LIBUUID)
#include <uuid/uuid.h>
#endif

// Do not free the result
static const char* SystemImpl__getUUIDStr(void)
{
  static char uuidStr[37] = "8c4e810f-3df3-4a00-8276-176fa3c9f9e0";
#if defined(__MINGW32__) || defined(_MSC_VER)
  unsigned char *tmp;
  UUID uuid;
  if (UuidCreate(&uuid) == RPC_S_OK)
    UuidToString(&uuid, &tmp);
  tmp[36] = '\0';
  memcpy(uuidStr, strlwr((char*)tmp), 36);
  RpcStringFree(&tmp);
#elif defined(WITH_LIBUUID)
  uuid_t uu;
  uuid_generate(uu);
  uuid_unparse_lower(uu, uuidStr);
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
  const char* ctokens[2];
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
    LPVOID lpMsgBuf;
    FormatMessage(
            FORMAT_MESSAGE_ALLOCATE_BUFFER |
            FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS,
            NULL,
            GetLastError(),
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            (LPTSTR) &lpMsgBuf,
            0, NULL );
    ctokens[0] = lpMsgBuf;
    ctokens[1] = libname;
    c_add_message(NULL,-1, ErrorType_runtime,ErrorLevel_error, gettext("OMC unable to load `%s': %s.\n"), ctokens, 2);
    LocalFree(lpMsgBuf);
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
  snprintf(libname, MAXPATHLEN, "./%s" CONFIG_DLL_EXT, str);
#if defined(RTLD_DEEPBIND)
  h = dlopen(libname, RTLD_LOCAL | RTLD_NOW | RTLD_DEEPBIND);
#else
  h = dlopen(libname, RTLD_LOCAL | RTLD_NOW);
#endif
  if (h == NULL) {
    ctokens[0] = dlerror();
    ctokens[1] = libname;
    c_add_message(NULL,-1, ErrorType_runtime,ErrorLevel_error, gettext("OMC unable to load `%s': %s.\n"), ctokens, 2);
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

static inline modelica_integer alloc_ptr(void)
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

int SystemImpl__lookupFunction(int libIndex, const char *str)
{
  modelica_ptr_t lib = NULL, func = NULL;
  function_t funcptr;
  int funcIndex;

  lib = lookup_ptr(libIndex);

  if (lib == NULL)
    return -1;

  funcptr =  (int (*)(threadData_t*, type_description*, type_description*)) getFunctionPointerFromDLL(lib->data.lib, str);

  if (funcptr == NULL) {
    fprintf(stderr, "Unable to find `%s': %lu.\n", str, GetLastError());
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
  if (printDebug) { fprintf(stderr, "LIB UNLOAD handle[%" PRINT_MMC_UINT_T "].\n", (mmc_uint_t) lib->data.lib); fflush(stderr); }
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
  lookup_ptr(func->data.func.lib);
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

  for(; MMC_GETHDR(timeValues) == MMC_CONSHDR && valueFound == 0; timeValues = MMC_CDR(timeValues), varValues = MMC_CDR(varValues)) {
    nowValue   = mmc_prim_get_real(MMC_CAR(varValues));
    nowTime   =  mmc_prim_get_real(MMC_CAR(timeValues));

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
  res = (char*) omc_alloc_interface.malloc_atomic(len2+1);
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


static int compute_sanitized_string_size(const char* str) {
  int i, count;

  for (i=0, count=0; str[i]; i++, count++) {
    // Each non-alphanum character needs two more char for its
    // escape + two hex representation
    if (!isalnum(str[i])) {
      count += 2;
    }
  }

  return count;
}

static char* sanitize_string(const char* src, char* dst) {
  const char lookupTbl[] = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

  int i;
  while (*src) {
    unsigned char c = *src++;
    if (isalnum(c)) {
      *dst = c;
      dst++;
    } else {
      *dst++ = '_';
      *dst++ = lookupTbl[c/16];
      *dst++ = lookupTbl[c%16];
    }
  }

  return dst;
}

// This function does not assume the input is actually a quoted string e.g 'gb' or 'ab[!%'
//
extern char* System_sanitizeQuotedIdentifier(const char* str)
{
  char *res,*cur;

  const char openquote[]="_omcQ";
  const int qsize = sizeof(openquote) - 1;

  // Each non-alphanum character needs one more char for its
  // two char ascii representation.
  int nrchars_needed = compute_sanitized_string_size(str) + qsize;

  res = (char*) omc_alloc_interface.malloc_atomic((nrchars_needed+1) * sizeof(char));

  cur = res;
  cur += sprintf(cur, "%s", openquote);
  cur = sanitize_string(str, cur);
  *cur = '\0';

  assert((cur == res + nrchars_needed) && "Allocated memory does not exactly fit the unquoted string output");

  return res;
}

extern char* SystemImpl__unquoteIdentifier(char* str)
{

  if (str[0] == '\'') {
    return System_sanitizeQuotedIdentifier(str);
  }

#if !defined(OPENMODELICA_BOOTSTRAPPING_STAGE_1)
  if (strstr(str, "$")) {
    return System_sanitizeQuotedIdentifier(str);
  }
#endif

  return str;
}

#define TIMER_MAX_STACK  1000
static double timerIntervalTime = 0;
static double timerCummulatedTime = 0;
static double timerTime = 0;
static long int timerStackIdx = 0;
static double timerStack[TIMER_MAX_STACK] = {0};

static void pushTimerStack(void)
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

static void popTimerStack(void)
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
  *name = (char*) omc_alloc_interface.malloc_atomic(len - lenPath + 2);
  decodeUri2(src,*name,'/');
  *path = (char*) omc_alloc_interface.malloc_atomic(lenPath+2);
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
      c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("Modelica URI lacks classname: %s"),msg,1);
      return 1;
    }
    return 0;
  } else if (0 == strncasecmp(uri, fileUri, strlen(fileUri))) {
    *scheme = fileUri;
    decodeUri(uri+strlen(fileUri),name,path);
    if (!**path) {
      msg[0] = uri;
      c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("File URI has no path: %s"),msg,1);
      return 1;
    } else if (**name) {
      msg[0] = uri;
      c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("File URI using hostnames is not supported: %s"),msg,1);
      return 1;
    }
    return 0;
  }
  c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("Unknown uri: %s"),&uri,1);
  return 1;
}

#ifdef NO_LAPACK
int SystemImpl__dgesv(void *lA, void *lB, void **res)
{
  MMC_THROW();
}
#else
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
  while (MMC_NILHDR != MMC_GETHDR(tmp)) {
    sz++;
    tmp = MMC_CDR(tmp);
  }
  A = (double*) omc_alloc_interface.malloc_atomic(sz*sz*sizeof(double));
  assert(A != NULL);
  B = (double*) omc_alloc_interface.malloc_atomic(sz*sizeof(double));
  assert(B != NULL);
  for (i=0; i<sz; i++) {
    tmp = MMC_CAR(lA);
    for (j=0; j<sz; j++) {
      A[j*sz+i] = mmc_prim_get_real(MMC_CAR(tmp));
      tmp = MMC_CDR(tmp);
    }
    B[i] = mmc_prim_get_real(MMC_CAR(lB));
    lA = MMC_CDR(lA);
    lB = MMC_CDR(lB);
  }
  ipiv = (integer*) omc_alloc_interface.malloc_atomic(sz*sizeof(integer));
  memset(ipiv,0,sz*sizeof(integer));
  assert(ipiv != 0);
  lda = sz;
  ldb = sz;
  dgesv_(&sz,&nrhs,A,&lda,ipiv,B,&ldb,&info);

  tmp = mmc_mk_nil();
  while (sz--) {
    tmp = mmc_mk_cons(mmc_mk_rcon(B[sz]),tmp);
  }
  *res = tmp;
  return info;
}
#endif

#ifdef NO_LPLIB
int SystemImpl__lpsolve55(void *lA, void *lB, void *ix, void **res)
{
  c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("Not compiled with lpsolve support"),NULL,0);
  MMC_THROW();
}
#else

#include CONFIG_LPSOLVEINC

int SystemImpl__lpsolve55(void *lA, void *lB, void *ix, void **res)
{
  int i = 0, j = 0, info, sz = 0;
  void *tmp = lB;
  lprec *lp;
  double inf,*vres;

  while (MMC_NILHDR != MMC_GETHDR(tmp)) {
    sz++;
    tmp = MMC_CDR(tmp);
  }
  vres = (double*)omc_alloc_interface.malloc_atomic(sz*sizeof(double));
  memset(vres,0,sz*sizeof(double));
  lp = make_lp(sz, sz);
  set_verbose(lp, 1);
  inf = get_infinite(lp);

  for (i=0; i<sz; i++) {
    set_lowbo(lp, i+1, -inf);
    set_constr_type(lp, i+1, EQ);
    tmp = MMC_CAR(lA);
    for (j=0; j<sz; j++) {
      set_mat(lp, i+1, j+1, mmc_prim_get_real(MMC_CAR(tmp)));
      tmp = MMC_CDR(tmp);
    }
    set_rh(lp, i+1, mmc_prim_get_real(MMC_CAR(lB)));
    lA = MMC_CDR(lA);
    lB = MMC_CDR(lB);
  }
  while (MMC_NILHDR != MMC_GETHDR(ix)) {
    if (MMC_UNTAGFIXNUM(MMC_CAR(ix)) != -1) set_int(lp, MMC_UNTAGFIXNUM(MMC_CAR(ix)), 1);
    ix = MMC_CDR(ix);
  }
  info=solve(lp);
  //print_lp(lp);
  if (info==0 || info==1) get_ptr_variables(lp,&vres);
  *res = mmc_mk_nil();
  while (sz--) {
    *res = mmc_mk_cons(mmc_mk_rcon(vres[sz]),*res);
  }
  delete_lp(lp);
  return info;
}
#endif

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
  *versionExtra = omc_alloc_interface.malloc_strdup(buf);
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
  str = (char*) omc_alloc_interface.malloc_atomic(strlen(dir1) + strlen(dir2) + strlen(file) + 3);
  sprintf(str,"%s/%s/%s", dir1, dir2, file);
  res = SystemImpl__regularFileExists(str);
  return res;
}

static modelicaPathEntry* getAllModelicaPaths(const char *name, size_t nlen, void *mps, int *numMatches)
{
  int i = 0;
  modelicaPathEntry* res;
  void *save_mps = mps;
  *numMatches = 0;
  while (MMC_NILHDR != MMC_GETHDR(mps)) {
    const char *mp = MMC_STRINGDATA(MMC_CAR(mps));
    DIR *dir = opendir(mp);
    struct dirent *ent;
    mps = MMC_CDR(mps);
    if (!dir) continue;
    while ((ent = readdir(dir))) {
      if (0 == strncmp(name, ent->d_name, nlen) && (ent->d_name[nlen] == '\0' || ent->d_name[nlen] == ' ' || ent->d_name[nlen] == '.')) {
        int entlen,mightbedir;
#ifdef DT_DIR
        mightbedir = (ent->d_type==DT_DIR || ent->d_type==DT_UNKNOWN || ent->d_type==DT_LNK);
#else
        mightbedir = 1;
#endif
        if (mightbedir && (regularFileExistsInDirectory(mp,ent->d_name,"package.mo") || regularFileExistsInDirectory(mp,ent->d_name,"package.moc"))) {
          /* fprintf(stderr, "found match %d %s\n", *numMatches, ent->d_name); */
          (*numMatches)++;
          continue;
        }
        entlen = strlen(ent->d_name);
        if (((entlen > 3 && 0==strcmp(ent->d_name+entlen-3,".mo")) || (entlen > 4 && 0==strcmp(ent->d_name+entlen-4,".moc"))) && regularFileExistsInDirectory(mp,"",ent->d_name)) {
          /* fprintf(stderr, "found match %d %s\n", *numMatches, ent->d_name); */
          (*numMatches)++;
        }
      }
    }
    closedir(dir);
  }
  /* fprintf(stderr, "numMatches: %ld\n", *numMatches); */
  /*** NOTE: Doing the same thing again. It is very important the same (number of) entries are match as in the loop above ***/
  res = (modelicaPathEntry*) omc_alloc_interface.malloc(*numMatches*sizeof(modelicaPathEntry));
  mps = save_mps;
  while (MMC_NILHDR != MMC_GETHDR(mps)) {
    const char *mp = MMC_STRINGDATA(MMC_CAR(mps));
    DIR *dir = opendir(mp);
    struct dirent *ent;
    mps = MMC_CDR(mps);
    if (!dir) continue;
    while ((ent = readdir(dir))) {
      if (0 == strncmp(name, ent->d_name, nlen) && (ent->d_name[nlen] == '\0' || ent->d_name[nlen] == ' ' || ent->d_name[nlen] == '.')) {
        int entlen,ok=0,maybeDir;
#ifdef DT_DIR
        maybeDir = (ent->d_type==DT_DIR || ent->d_type==DT_UNKNOWN || ent->d_type==DT_LNK);
#else
        maybeDir = 1;
#endif
        if (maybeDir && (regularFileExistsInDirectory(mp,ent->d_name,"package.mo") || regularFileExistsInDirectory(mp,ent->d_name,"package.moc"))) {
          ok=1;
          res[i].fileIsDir=1;
          /* fprintf(stderr, "found dir match: %ld %s - ok=%d\n", i, ent->d_name, ok); */
        }
        entlen = strlen(ent->d_name);
        if (!ok && ((entlen > 3 && 0==strcmp(ent->d_name+entlen-3,".mo")) || (entlen > 4 && 0==strcmp(ent->d_name+entlen-4,".moc"))) && regularFileExistsInDirectory(mp,"",ent->d_name)) {
          /* fprintf(stderr, "found match file: %ld %s - ok=%d\n", i, ent->d_name, ok); */
          res[i].fileIsDir=0;
          ok=1;
        }
        if (!ok)
          continue;
        res[i].dir = mp;
        res[i].file = omc_alloc_interface.malloc_strdup(ent->d_name);
        if (res[i].file[nlen] == ' ') {
          splitVersion(res[i].file+nlen+1, res[i].version, &res[i].versionExtra);
        } else {
          memset(res[i].version,0,sizeof(long)*MODELICAPATH_LEVELS);
          res[i].versionExtra = "";
        }
        assert(i<*numMatches);
        i++;
      }
    }
    closedir(dir);
  }
  return res;
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

static int getLoadModelPathFromSingleTarget(const char *searchTarget, modelicaPathEntry *entries, int numEntries, int exactVersion, const char **outDir, char **outName, int *isDir)
{
  int i, j, foundIndex = -1;
  long version[MODELICAPATH_LEVELS] = {0}, foundVersion[MODELICAPATH_LEVELS] = {0};
  char *versionExtra;
  splitVersion(searchTarget,version,&versionExtra);
  /* fprintf(stderr, "expected %ld.%ld.%ld.%ld %s ; exact=%d\n", version[0], version[1], version[2], version[3], versionExtra, exactVersion); */
  if (version > 0 && !*versionExtra) {
    /* Makes us load 3.2.1 if 3.2.0.0 is not available.
     * Note that all 4 levels are present and 3.2 is equivalent to 3.2.0.0
     * Search one additional level for each time we fail.
     */
    for (j=MODELICAPATH_LEVELS; j>=(exactVersion ? MODELICAPATH_LEVELS : 0); j--) {
      for (i=0; i<numEntries; i++) {
        /* fprintf(stderr, "entry %s/%s\n", entries[i].dir, entries[i].file);
         fprintf(stderr, "expected %ld.%ld.%ld.%ld %s\n", entries[i].version[0], entries[i].version[1], entries[i].version[2], entries[i].version[3], entries[i].versionExtra); */

        if (modelicaPathEntryVersionEqual(entries[i].version,version,j)
            && (j==MODELICAPATH_LEVELS || modelicaPathEntryVersionGreater(entries[i].version,version,MODELICAPATH_LEVELS))
            && (entries[i].versionExtra[0] == '\0' || entries[i].versionExtra[0] == '+' || entries[i].versionExtra[0] == '-')) {
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
        return 0;
      }
    }
  }
  return 1;
}

static int getLoadModelPathFromDefaultTarget(const char *name, modelicaPathEntry *entries, int numEntries, const char **outDir, char **outName, int *isDir)
{
  const char *foundExtra = 0;
  long foundVersion[MODELICAPATH_LEVELS] = {-1,-1,-1,0};
  int i,foundIndex = -1;

  /* Look for best release version */
  for (i=0; i<numEntries; i++) {
    if (modelicaPathEntryVersionGreater(entries[i].version,foundVersion,MODELICAPATH_LEVELS) && (entries[i].versionExtra[0] == '\0' || entries[i].versionExtra[0] == '+' || entries[i].versionExtra[0] == '-')) {
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

int System_getLoadModelPath(const char *name, void *prios, void *mps, int exactVersion, const char **outDir, char **outName, int *isDir)
{
  int numEntries,res=1;
  size_t nameLen = strlen(name);
  modelicaPathEntry *entries = getAllModelicaPaths(name, nameLen, mps, &numEntries);
  *outName = NULL;
  while (MMC_NILHDR != MMC_GETHDR(prios)) {
    const char *prio = MMC_STRINGDATA(MMC_CAR(prios));
    if (0==strcmp("default",prio)) {
      if (!getLoadModelPathFromDefaultTarget(name,entries,numEntries,outDir,outName,isDir)) {
        res = 0;
        break;
      }
    } else {
      if (!getLoadModelPathFromSingleTarget(prio,entries,numEntries,exactVersion,outDir,outName,isDir)) {
        res = 0;
        break;
      }
    }
    prios = MMC_CDR(prios);
  }
  if (NULL == *outName) {
    MMC_THROW();
  }
  /* fprintf(stderr, "result: %d %s %s %d", res, *outDir, *outName, *isDir); */
  return res;
}

#define MAX_TMP_TICK 50

typedef struct systemMoData {
  int tmp_tick_no[MAX_TMP_TICK];
  int tmp_tick_max_no[MAX_TMP_TICK];
} systemMoData;

pthread_once_t system_once_create_key = PTHREAD_ONCE_INIT;
pthread_key_t systemMoKey;

static void free_system_mo(void *data)
{
  systemMoData *members = (systemMoData*) data;
  if (data == NULL) return;
  free(members);
}

static void make_key(void)
{
  pthread_key_create(&systemMoKey,free_system_mo);
}

static systemMoData* getSystemMoData(threadData_t *threadData)
{
  systemMoData *res;
  if (threadData && threadData->localRoots[LOCAL_ROOT_SYSTEM_MO]) {
    return (systemMoData*) threadData->localRoots[LOCAL_ROOT_SYSTEM_MO];
  }
  pthread_once(&system_once_create_key,make_key);
  res = (systemMoData*) pthread_getspecific(systemMoKey);
  if (res != NULL) return res;
  /* We use malloc instead of new because when we do dynamic loading of functions, C++ objects in TLS might be free'd upon return to the main process. */
  res = (systemMoData*) calloc(1,sizeof(systemMoData));
  pthread_setspecific(systemMoKey,res);
  if (threadData) {
    /* Still use pthreads API to free the buffer on thread exit even though we pass this thing around
     * We could change this to storing the free function in MMC_CATCH_TOP, but this might be faster if we pool threads
     */
    threadData->localRoots[LOCAL_ROOT_SYSTEM_MO] = res;
  }
  return res;
}

extern int SystemImpl_tmpTickIndex(threadData_t *threadData, int index)
{
  systemMoData *data = getSystemMoData(threadData);
  int res = data->tmp_tick_no[index];
  assert(index < MAX_TMP_TICK && index >= 0);
  data->tmp_tick_no[index] += 1;
  data->tmp_tick_max_no[index] = intMax(data->tmp_tick_no[index],data->tmp_tick_max_no[index]);
  return res;
}

extern int SystemImpl_tmpTickIndexReserve(threadData_t *threadData, int index, int reserve)
{
  systemMoData *data = getSystemMoData(threadData);
  int res = data->tmp_tick_no[index];
  assert(index < MAX_TMP_TICK && index >= 0);
  data->tmp_tick_no[index] += reserve;
  data->tmp_tick_max_no[index] = intMax(data->tmp_tick_no[index],data->tmp_tick_max_no[index]);
  return res;
}

extern void SystemImpl_tmpTickResetIndex(threadData_t *threadData, int start, int index)
{
  systemMoData *data = getSystemMoData(threadData);
  assert(index < MAX_TMP_TICK && index >= 0);
  /* fprintf(stderr, "tmpTickResetIndex %d => %d\n", index, start); */
  data->tmp_tick_no[index] = start;
  data->tmp_tick_max_no[index] = start;
}

extern void SystemImpl_tmpTickSetIndex(threadData_t *threadData, int start, int index)
{
  systemMoData *data = getSystemMoData(threadData);
  assert(index < MAX_TMP_TICK && index >= 0);
  /* fprintf(stderr, "tmpTickResetIndex %d => %d\n", index, start); */
  data->tmp_tick_no[index] = start;
  data->tmp_tick_max_no[index] = intMax(start,data->tmp_tick_max_no[index]);
}

/* If you use negative reserve or set, the maximum can be different from the tick */
extern int SystemImpl_tmpTickMaximum(threadData_t *threadData, int index)
{
  systemMoData *data = getSystemMoData(threadData);
  assert(index < MAX_TMP_TICK && index >= 0);
  return data->tmp_tick_max_no[index];
}

#if defined(OPENMODELICA_BOOTSTRAPPING_STAGE_1)
extern int SystemImpl_tmpTick(threadData_t *threadData)
{
  int res = SystemImpl_tmpTickIndex(threadData,0);
  return res;
}
#endif

extern void SystemImpl_tmpTickReset(threadData_t *threadData, int start)
{
  SystemImpl_tmpTickResetIndex(threadData,start,0);
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
    c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("freopen(%s,%s,%s) failed: %s"),tokens,4);
    return 0;
  }
  return 1;
}

const char* SystemImpl__iconv__ascii(const char * str)
{
  char *buf = 0;
  size_t sz;
  int i;
  sz = strlen(str);
  buf = omc_alloc_interface.malloc_atomic(sz+1);
  *buf = 0;
  for (i=0; i<=sz; i++)
    buf[i] = str[i] & 0x80 ? '?' : str[i];
  return buf;
}

static int isUtf8Encoding(const char *str)
{
  return strcasecmp(str, "UTF-8") || strcasecmp(str, "UTF8");
}

extern const char* SystemImpl__iconv(const char * str, const char *from, const char *to, int printError)
{
  char *in_str,*res=NULL;
  size_t sz,out_sz,buflen;
  iconv_t ic;
  int count;
  char *buf;
  sz = strlen(str);
  if (isUtf8Encoding(from) && isUtf8Encoding(to))
  {
    is_utf8((unsigned char*)str, sz, &res, &count);
    if (res==NULL) {
      /* Converting from UTF-8 to UTF-8 and the sequence is already UTF-8... */
      return str;
    }
    /* Converting from UTF-8, but is not valid UTF-8. Just quit early. */
    if (printError) {
      const char *ignore = SystemImpl__iconv__ascii(str);
      const char *tokens[4] = {res,from,to,ignore};
      c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("iconv(\"%s\",from=\"%s\",to=\"%s\") failed: %s"),tokens,4);
      omc_alloc_interface.free_uncollectable((char*)ignore);
    }
    return (const char*) "";
  }
  buflen = sz*4;
  /* fprintf(stderr,"iconv(%s,to=%s,%s) of size %d, buflen %d\n",str,to,from,sz,buflen); */
  ic = iconv_open(to, from);
  if (ic == (iconv_t) -1) {
    if (printError) {
      const char *ignore = SystemImpl__iconv__ascii(str);
      const char *tokens[4] = {strerror(errno),from,to,ignore};
      c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("iconv(\"%s\",to=\"%s\",from=\"%s\") failed: %s"),tokens,4);
      omc_alloc_interface.free_uncollectable((char*)ignore);
    }
    return (const char*) "";
  }
  buf = (char*) omc_alloc_interface.malloc_atomic(buflen);
  if (0 == buf) {
    if (printError) {
      /* Make the error message small so we perhaps have a chance to recover */
      c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("iconv() ran out of memory"),NULL,0);
    }
    return (const char*) "";
  }
  *buf = 0;
  in_str = (char*) str;
  out_sz = buflen-1;
  res = buf;
  count = iconv(ic,&in_str,&sz,&res,&out_sz);
  iconv_close(ic);
  if (count == -1) {
    if (printError) {
      const char *ignore = SystemImpl__iconv__ascii(str);
      const char *tokens[4] = {strerror(errno),from,to,ignore};
      c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("iconv(\"%s\",to=\"%s\",from=\"%s\") failed: %s"),tokens,4);
      omc_alloc_interface.free_uncollectable((char*)ignore);
    }
    omc_alloc_interface.free_uncollectable(buf);
    return (const char*) "";
  }
  buf[(buflen-1)-out_sz] = 0;
  if (strlen(buf) != (buflen-1)-out_sz) {
    if (printError) c_add_message(NULL,-1,ErrorType_scripting,ErrorLevel_error,gettext("iconv(to=%s) failed because the character set output null bytes in the middle of the string."),&to,1);
    omc_alloc_interface.free_uncollectable(buf);
    return (const char*) "";
  }
  if (!strcmp(from, to) && !strcmp(str, buf))
  {
    omc_alloc_interface.free_uncollectable(buf);
    return (const char*)str;
  }
  return buf;
}

#include "util/tinymt64.h"

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
double SystemImpl__realRand(void)
{
  seed();
  return tinymt64_generate_double(&system_random_seed);
}

/* Returns an integer [0,n) using the C function rand() */
int SystemImpl__intRandom(int n)
{
  return rand() % n;
}

char* alloc_locale_str(const char *locale, int llen, const char *suffix, int slen)
{
  char *loc = (char*)omc_alloc_interface.malloc_atomic(sizeof(char) * (llen + slen + 1));
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
  char *old_ctype = omc_alloc_interface.malloc_strdup(old_ctype_default);
  int old_ctype_is_utf8 = strcmp(nl_langinfo(CODESET), "UTF-8") == 0;

  int res =
    (*locale == 0 && setlocale(LC_MESSAGES, "") && setlocale(LC_CTYPE, "")) ||
    (*locale != 0 && setlocale(LC_MESSAGES, locale3) && setlocale(LC_CTYPE, locale3))  ||
    (*locale != 0 && setlocale(LC_MESSAGES, locale2) && setlocale(LC_CTYPE, locale2)) ||
    (*locale != 0 && setlocale(LC_MESSAGES, locale) && setlocale(LC_CTYPE, locale));
  if (!res && *locale) {
    fprintf(stderr, gettext("Warning: Failed to set locale: '%s'\n"), locale);
  }
  if (!setlocale(LC_NUMERIC, "C")) {
    fputs(gettext("Warning: Failed to set LC_NUMERIC to C locale\n"), stderr);
  }
  clocale = setlocale(LC_CTYPE, NULL);
  int have_utf8 = strcmp(nl_langinfo(CODESET), "UTF-8") == 0;
  /* We succesfully forced a new non-system locale; let's clear some variables */
  if (*locale) {
    unsetenv("LANG");
    unsetenv("LANGUAGE");
    unsetenv("LC_ALL");
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
#endif /* __MINGW32__ */
  if(omhome == NULL)
  {
  fprintf(stderr, "Warning: environment variable OPENMODELICAHOME is not set. Cannot load locale.\n");
  return;
  }
  omlen = strlen(omhome);
  localedir = (char*) omc_alloc_interface.malloc_atomic(omlen + 25);
  sprintf(localedir, "%s/share/locale", omhome);
  bindtextdomain ("openmodelica", localedir);
  textdomain ("openmodelica");
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


int System_getTerminalWidth(void)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  return 80;
#else
  struct winsize w;
  ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);
  return w.ws_col ? w.ws_col : 80;
#endif
}

#include "util/simulation_options.h"

#define SB_SIZE 8192*4
#define SB_SIZE_MINUS_ONE (SB_SIZE-1)

/* snprintf check negative size */
static size_t check_nonnegative(long sz)
{
  if (sz < 0) {
    fprintf(stderr, "%s:%d got negative size: %ld, which should not happen\n", __FILE__, __LINE__, sz);
    exit(EXIT_FAILURE);
  }
  return sz;
}

#define CHECK_NONNEGATIVE_BUFFER() check_nonnegative((long)SB_SIZE_MINUS_ONE-(cur-buf))

char* System_getSimulationHelpTextSphinx(int detailed, int sphinx)
{
  static char buf[SB_SIZE];
  int i,j;
  const char **desc = detailed ? FLAG_DETAILED_DESC : FLAG_DESC;
  char *cur = buf;
  *cur = 0;
  for(i=1; i<FLAG_MAX; ++i)
  {
    if (sphinx) {
      cur += snprintf(cur, CHECK_NONNEGATIVE_BUFFER(), "\n.. _simflag-%s :\n\n", FLAG_NAME[i]);
    }
    if (FLAG_TYPE[i] == FLAG_TYPE_FLAG) {
      if (sphinx) {
        cur += snprintf(cur, CHECK_NONNEGATIVE_BUFFER(), ":ref:`-%s <simflag-%s>`\n%s\n", FLAG_NAME[i], FLAG_NAME[i], desc[i]);
      } else {
        cur += snprintf(cur, CHECK_NONNEGATIVE_BUFFER(), "<-%s>\n%s\n", FLAG_NAME[i], desc[i]);
      }
    } else if (FLAG_TYPE[i] == FLAG_TYPE_OPTION) {
      int numExtraFlags=0;
      int firstExtraFlag=1;
      const char **flagName;
      const char **flagDesc;
      if (sphinx) {
        cur += snprintf(cur, CHECK_NONNEGATIVE_BUFFER(), ":ref:`-%s=value <simflag-%s>` *or* -%s value \n%s\n", FLAG_NAME[i], FLAG_NAME[i], FLAG_NAME[i], desc[i]);
      } else {
        cur += snprintf(cur, CHECK_NONNEGATIVE_BUFFER(), "<-%s=value> or <-%s value>\n%s\n", FLAG_NAME[i], FLAG_NAME[i], desc[i]);
      }

      switch(i) {

      case FLAG_IDA_LS:
        numExtraFlags = IDA_LS_MAX;
        flagName = IDA_LS_METHOD;
        flagDesc = IDA_LS_METHOD_DESC;
        break;

      case FLAG_IIM:
        numExtraFlags = IIM_MAX;
        flagName = INIT_METHOD_NAME;
        flagDesc = INIT_METHOD_DESC;
        break;

      case FLAG_JACOBIAN:
        numExtraFlags = JAC_MAX;
        flagName = JACOBIAN_METHOD;
        flagDesc = JACOBIAN_METHOD_DESC;
        break;

      case FLAG_LS:
        numExtraFlags = LS_MAX;
        flagName = LS_NAME;
        flagDesc = LS_DESC;
        break;

      case FLAG_LSS:
        numExtraFlags = LSS_MAX;
        flagName = LSS_NAME;
        flagDesc = LSS_DESC;
        break;

      case FLAG_LV:
        firstExtraFlag=firstOMCErrorStream;
        numExtraFlags = SIM_LOG_MAX;
        flagName = LOG_STREAM_NAME;
        flagDesc = LOG_STREAM_DESC;
        break;

      case FLAG_NEWTON_STRATEGY:
        numExtraFlags = NEWTON_MAX;
        flagName = NEWTONSTRATEGY_NAME;
        flagDesc = NEWTONSTRATEGY_DESC;
        break;

      case FLAG_NLS:
        numExtraFlags = NLS_MAX;
        flagName = NLS_NAME;
        flagDesc = NLS_DESC;
        break;

      case FLAG_NLS_LS:
        numExtraFlags = NLS_LS_MAX;
        flagName = NLS_LS_METHOD;
        flagDesc = NLS_LS_METHOD_DESC;
        break;


      case FLAG_S:
        numExtraFlags = S_MAX;
        flagName = NULL;
        flagDesc = SOLVER_METHOD_DESC;
        break;
      }

      if (numExtraFlags) {
        cur += snprintf(cur, CHECK_NONNEGATIVE_BUFFER(), "\n");
        if (flagName) {
          for (j=firstExtraFlag; j<numExtraFlags; j++) {
            cur += snprintf(cur, CHECK_NONNEGATIVE_BUFFER(), "  * %s (%s)\n", flagName[j], flagDesc[j]);
          }
        } else {
          for (j=firstExtraFlag; j<numExtraFlags; j++) {
            cur += snprintf(cur, CHECK_NONNEGATIVE_BUFFER(), "  * %s\n", flagDesc[j]);
          }
        }
      }

    } else {
      cur += snprintf(cur, CHECK_NONNEGATIVE_BUFFER(), "[unknown flag-type] <-%s>\n", FLAG_NAME[i]);
    }
  }
  *cur = 0;
  return buf;
}

/* TODO: Remove me with new tarball */
char* System_getSimulationHelpText(int detailed)
{
  return System_getSimulationHelpTextSphinx(detailed, 0);
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
    c_add_message(NULL,85,
        ErrorType_scripting,
        ErrorLevel_error,
        gettext("Could not access file %s: %s."),
        c_tokens,
        2);
    return -1;
  }
  if (stat(file2, &buf2)) {
    const char *c_tokens[2]={strerror(errno),file2};
    c_add_message(NULL,85,
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

void SystemImpl__initGarbageCollector(void)
{
  static int init=0;
  if (!init) {
    GC_init();
    GC_register_displacement(0);
#ifdef RML_STYLE_TAGPTR
    GC_register_displacement(3);
#endif
    GC_set_force_unmap_on_gcollect(1);
    init=1;
  }
}

int SystemImpl__fileContentsEqual(const char *file1, const char *file2)
{
  char buf1[8192],buf2[8192];
  FILE *f1,*f2;
  int i1,i2,totalread=0,error=0;
#if !defined(_MSC_VER)
  struct stat stbuf1;
  struct stat stbuf2;
  if (stat(file1, &stbuf1)) return 0;
  if (stat(file2, &stbuf2)) return 0;
  if (stbuf1.st_size != stbuf2.st_size) return 0;
#endif
  f1 = fopen(file1,"rb");
  if (f1 == NULL) {
    return 0;
  }
  f2 = fopen(file2,"rb");
  if (f2 == NULL) {
    fclose(f1);
    return 0;
  }
  do {
    i1 = fread(buf1,1,8192,f1);
    i2 = fread(buf2,1,8192,f2);
    if (i1 != i2 || strncmp(buf1,buf2,i1)) {
      error = 1;
    }
    totalread += i1;
  } while(i1 != 0 && error == 0);
  fclose(f1);
  fclose(f2);
  return !error;
}

int SystemImpl__rename(const char *source, const char *dest)
{
#if defined(__MINGW32__) || defined(_MSC_VER)
  return MoveFileEx(source, dest, MOVEFILE_REPLACE_EXISTING);
#endif
  return 0==rename(source,dest);
}

char* SystemImpl__ctime(double time)
{
  char buf[64] = {0}; /* needs to be >=26 char */
  time_t t = (time_t) time;
  return omc_alloc_interface.malloc_strdup(ctime_r(&t,buf));
}

#if defined(__MINGW32__)
/*
 * strtok_r implementation
 */
static char *omc_strtok_r(char *str, const char *delim, char **saveptr)
{
  char *token;
  if (!str && !(str = *saveptr))
  {
     return NULL;
  }
  str += strspn(str, delim);
  if (!*str) {
    *saveptr = NULL;
    return NULL;
  }
  token = str++;
  str += strcspn(str, delim);
  if (*str) {
    *str = 0;
    *saveptr = str+1;
  } else {
    *saveptr = NULL;
  }

  return token;
}

#define strtok_r omc_strtok_r

#endif /* defined(__MINGW32__) */

int SystemImpl__stat(const char *filename, double *size, double *mtime)
{
  struct stat stats;
  if (0 != stat(filename, &stats)) {
    *size = 0;
    *mtime = 0;
    return 0;
  }
  *size = stats.st_size;
  *mtime = stats.st_mtime;
  return 1;
}

#if defined(__MINGW32__) || defined(_MSC_VER)

int SystemImpl__alarm(int seconds)
{
  return alarm(seconds);
}

#else

static int default_alarm_action_set = 0;
static struct sigaction default_alarm_action;

static void alarm_handler(int signo, siginfo_t *si, void *ptr)
{
  assert(signo == SIGALRM);
  kill(-getpid(), SIGALRM);
  sigaction(SIGALRM, &default_alarm_action, 0);
}

int SystemImpl__alarm(int seconds)
{
  if (default_alarm_action_set == 0) {
    struct sigaction sa = {
      .sa_sigaction = alarm_handler,
      .sa_flags = SA_SIGINFO
    };
    sigaction(SIGALRM, &sa, NULL);
    default_alarm_action_set = 1;
  }
  return alarm(seconds);
}

#endif

int SystemImpl__covertTextFileToCLiteral(const char *textFile, const char *outFile, const char* target)
{
  FILE *fin;
  FILE *fout = NULL;
  int result = 0, n, i, j, k, isMSVC = !strcmp(target, "msvc");
  char buffer[512];
  char obuffer[1024];
  fin = fopen(textFile, "r");
  if (!fin) {
    goto done;
  }
  errno = 0;
#if defined(__APPLE_CC__)||defined(__MINGW32__)||defined(__MINGW64__)
  unlink(outFile);
#endif
  fout = fopen(outFile, "w");
  if (!fout) {
    const char *c_token[1]={strerror(errno)};
    c_add_message(NULL,85,
        ErrorType_scripting,
        ErrorLevel_error,
        gettext("SystemImpl__covertTextFileToCLiteral failed: %s. Maybe the total file name is too long."),
        c_token,
        1);
    goto done;
  }

  if (isMSVC) /* handle joke compilers */
  {
    fputc('{', fout);
    fputc('\n', fout);
    do {
      n = fread(buffer,1,511,fin);
      j = 0;
      /* adrpo: encode each char */
      for (i=0; i<n; i++) {
      fputc('\'', fout);

        switch (buffer[i]) {
        case '\n':
          fputc('\\', fout);
          fputc('n', fout);
          break;
        case '\r':
          fputc('\\', fout);
          fputc('r', fout);
          break;
        case '\\':
          fputc('\\', fout);
          fputc('\\', fout);
          break;
    case '"':
          fputc('\\', fout);
          fputc('\"', fout);
          break;
    case '\'':
          fputc('\\', fout);
          fputc('\'', fout);
          break;
        default:
          fputc(buffer[i], fout);
        }
        fputc('\'', fout);
        fputc(',', fout);
      }
      fputc('\n', fout);
    } while (!feof(fin));

    fputc('\'', fout); fputc('\\', fout); fputc('0', fout); fputc('\'', fout); fputc('\n', fout);
    fputc('}', fout);
  }
  else /* handle real compilers */
  {
    fputc('\"', fout);
    do {
      n = fread(buffer,1,511,fin);
      j = 0;
      for (i=0; i<n; i++) {
        switch (buffer[i]) {
        case '\n':
          obuffer[j++] = '\\';
          obuffer[j++] = 'n';
          break;
        case '\r':
          obuffer[j++] = '\\';
          obuffer[j++] = 'r';
          break;
        case '\\':
          obuffer[j++] = '\\';
          obuffer[j++] = '\\';
          break;
        case '"':
          obuffer[j++] = '\\';
          obuffer[j++] = '"';
          break;
        default:
          obuffer[j++] = buffer[i];
        }
      }
      if (j!=fwrite(obuffer,1,j,fout)) {
        fprintf(stderr, "failed to write\n");
        return 1;
      }
    } while (!feof(fin));
    fputc('\"', fout);
  }

  result = 1;

done:
  if (fin) {
    fclose(fin);
  }
  if (fout) {
    fclose(fout);
  }
  return result;
}

void SystemImpl__dladdr(void *symbol, const char **file, const char **name)
{
#if defined(_MSC_VER)
  *file = "dladdr failed";
  *name = "not available on Windows";
#else /* mingw & Linux */
  Dl_info info;
  void *ptr = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(symbol), 1)));
  if (0 == dladdr(ptr, &info)) {
    *file = "dladdr failed";
    *name = "";
  } else {
    *file = info.dli_fname ? omc_alloc_interface.malloc_strdup(info.dli_fname) : "(null)";
    *name = info.dli_sname ? omc_alloc_interface.malloc_strdup(info.dli_sname) : "(null)";
  }
#endif
}

const char* SystemImpl__createTemporaryDirectory(const char *templatePrefix)
{
  char *template = (char*) omc_alloc_interface.malloc_atomic(strlen(templatePrefix) + 7);
  const char *c_tokens[2];
  sprintf(template, "%sXXXXXX", templatePrefix);
  if (template==mkdtemp(template)) {
    return template;
  }
  GC_free(template);
  c_tokens[0]=strerror(errno);
  c_tokens[1]=templatePrefix;
  c_add_message(NULL,85, /* ERROR_OPENING_FILE */
    ErrorType_scripting,
    ErrorLevel_error,
    gettext("Error creating temporary directory %s: %s."),
    c_tokens,
    2);
  MMC_THROW();
}

#if defined(OMC_GENERATE_RELOCATABLE_CODE)
static void addDLError(const char *msg, const char *fileName)
{
  const char *err[2] = {dlerror(),fileName};
  c_add_message(NULL, 85,
  ErrorType_scripting,
  ErrorLevel_error,
  msg,
  err,
  2
  );
}

int SystemImpl__relocateFunctions(const char *fileName, void *names)
{
  void *localHandle,*remoteHandle;
  remoteHandle = dlopen(fileName, RTLD_NOW | RTLD_GLOBAL | RTLD_NODELETE);
  if (!remoteHandle) {
    addDLError(gettext("Error opening library %s: %s."), fileName);
    return 0;
  }
  localHandle = dlopen(NULL, RTLD_NOW);
  if (!localHandle) {
    addDLError(gettext("Error opening library %s: %s."), fileName);
    return 0;
  }
  int length = listLength(names);
  void **localSyms[length], *remoteSyms[length];
  for (int i=0; i<length; i++) {
    void *tpl = MMC_CAR(names);
    const char *local = MMC_STRINGDATA(MMC_CAR(tpl));
    const char *remote = MMC_STRINGDATA(MMC_CDR(tpl));

    remoteSyms[i] = dlsym(remoteHandle, remote);
    if (remoteSyms[i]==0) {
      addDLError(gettext("Error opening library %s: %s."), fileName);
    }
    localSyms[i] = (void**) dlsym(localHandle, local);
    if (localSyms[i]==0) {
      addDLError(gettext("Error opening library %s: %s."), fileName);
    }

    names = MMC_CDR(names);
  }
  /* All loaded fine. Now relocate all the symbols. */
  for (int i=0; i<length; i++) {
    *localSyms[i] = remoteSyms[i];
  }
  return 1;
}
#else
int SystemImpl__relocateFunctions(const char *fileName, void *names)
{
  c_add_message(NULL, 85,
  ErrorType_scripting,
  ErrorLevel_error,
  gettext("OMC not compiled with support for relocatable functions."),
  NULL,
  0
  );
  return 0;
}
#endif

#ifdef __cplusplus
}
#endif
