/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2011, Linköpings University,
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


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "omc_config.h"

#if defined(_MSC_VER) || defined(__MINGW32__)
#else
#include <unistd.h>
#include <pwd.h>
#endif

#ifdef WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

static char* compileCommand = 0;
static char* compilePath = 0;
static char* tempDirectoryPath = 0;
static int   echo = 1; //true

extern char* _replace(char* source_str,char* search_str,char* replace_str); //Defined in systemimpl.c

static char* winPath = NULL;

#if defined(linux) || defined(__APPLE_CC__)
/* Helper function to strip /bin/... or /lib/... from the executable path of omc */
static void stripbinpath(char *omhome)
{
  char *tmp;
  do {
    assert(tmp = strrchr(omhome,'/'));
    *tmp = '\0';
  } while (strcmp(tmp+1,"bin") && strcmp(tmp+1,"lib"));
  return;
}
#endif

/* Do not free or modify the returned variable of getInstallationDirectoryPath. It's part of the environment! */
#if defined(linux)
#include <sys/stat.h>
#include <linux/limits.h>
#include <unistd.h>
const char* SettingsImpl__getInstallationDirectoryPath(void) {
  struct stat sb;
  static char omhome[PATH_MAX];
  static int init = 0;
  ssize_t r;
  /* This is bad code using hard-coded limits; but we cannot query the size of symlinks on /proc
   * because that FS is not POSIX-compliant.
   */
  if (init) {
    return omhome;
  }
  r = readlink("/proc/self/exe", omhome, sizeof(omhome)-1);
  if (r < 0) {
    perror("readlink");
    exit(EXIT_FAILURE);
  }
  assert(r < sizeof(omhome)-1);
  omhome[r] = '\0';
  stripbinpath(omhome);
  init = 1;
  return omhome;
}
#elif defined(__APPLE_CC__)

#if 1
#include <dlfcn.h>

const char* SettingsImpl__getInstallationDirectoryPath(void) {
  int ret;
  pid_t pid;
  static char *omhome;
  static int init = 0;
  if (init) {
    return omhome;
  }

  Dl_info info;
  if (!dladdr((void*) SettingsImpl__getInstallationDirectoryPath, &info)) {
    fprintf(stderr, "proc_pidpath() failed: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  } else {
    omhome = GC_strdup(info.dli_fname);
    stripbinpath(omhome);
  }
  init = 1;
  return omhome;
}

#else
/* If we do not use dylib in the future */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <libproc.h>

const char* SettingsImpl__getInstallationDirectoryPath(void) {
  int ret;
  pid_t pid;
  static char omhome[PROC_PIDPATHINFO_MAXSIZE];
  static int init = 0;
  if (init) {
    return omhome;
  }

  pid = getpid();
  ret = proc_pidpath(pid, omhome, sizeof(omhome));
  if (ret <= 0) {
    fprintf(stderr, "proc_pidpath() failed: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  } else {
    stripbinpath(omhome);
  }
  init = 1;
  return omhome;
}
#endif /* dylib */

#else /* Not linux or Apple */
const char* SettingsImpl__getInstallationDirectoryPath(void) {
  const char *path = getenv("OPENMODELICAHOME");
  int i = 0;
  if (path == NULL) {
#if defined(__MINGW32__) || defined(_MSC_VER)
    char filename[MAX_PATH];
    if (0 != GetModuleFileName(NULL, filename, MAX_PATH)) {
      path = filename;
    } else
#endif
    {
      return CONFIG_DEFAULT_OPENMODELICAHOME; // On Windows, this is NULL; on Unix it is the configured --prefix
    }
  }
#if defined(__MINGW32__) || defined(_MSC_VER)
  /* adrpo: translate this to forward slashes! */
  /* already set, set it only once! */
  if (winPath != NULL)
    return (const char*)winPath;

  /* duplicate the path */
  winPath = strdup(path);

  /* ?? not enough memory for duplication */
  if (!winPath)
    return path;

  /* convert \\ to / */
  while(winPath[i] != '\0')
  {
    if (winPath[i] == '\\') winPath[i] = '/';
    i++;
  }
  return (const char*)winPath;
#endif
  return path;
}
#endif

char* winLibPath = NULL;

char* Settings_getHomeDir(int runningTestsuite)
{
  const char *homePath = NULL;
#if !(defined(_MSC_VER) || defined(__MINGW32__))
  homePath = getenv("HOME");
  if (homePath == NULL) {
    homePath = getpwuid(getuid())->pw_dir;
  }
#else
  return "%APPDATA%";
#endif
  if (homePath == NULL || runningTestsuite) {
    return "";
  }
  return GC_strdup(homePath);
}

// Do not free the returned variable. It's malloc'ed
char* SettingsImpl__getModelicaPath(int runningTestsuite) {
  const char *path = getenv("OPENMODELICALIBRARY");
  int i = 0;
  if (path == NULL) {
    // By default, this is <omhome>/lib/omlibrary/
    const char *omhome = SettingsImpl__getInstallationDirectoryPath();
    if (omhome == NULL)
      return NULL;
    int lenOmhome = strlen(omhome);
    char *buffer;
#if !(defined(_MSC_VER) || defined(__MINGW32__))
    const char *homePath = Settings_getHomeDir(runningTestsuite);
    if (homePath == NULL || runningTestsuite) {
#endif
      buffer = (char*) malloc(lenOmhome+15);
      snprintf(buffer,lenOmhome+15,"%s/lib/omlibrary",omhome);
#if !(defined(_MSC_VER) || defined(__MINGW32__))
    } else {
      int lenHome = strlen(homePath);
      buffer = (char*) GC_malloc_atomic(lenOmhome+lenHome+41);
      snprintf(buffer,lenOmhome+lenHome+41,"%s/lib/omlibrary:%s/.openmodelica/libraries/",omhome,homePath);
    }
#endif
    return buffer;
  }

#if defined(__MINGW32__) || defined(_MSC_VER)
  /* adrpo: translate this to forward slashes! */
  /* duplicate the path */
  winLibPath = GC_strdup(path);

  /* ?? not enough memory for duplication */
  if (!winLibPath)
    return GC_strdup(path);

  /* convert \\ to / */
  while(winLibPath[i] != '\0')
  {
    if (winLibPath[i] == '\\') winLibPath[i] = '/';
    i++;
  }
  return winLibPath;
#endif

  return GC_strdup(path);
}

static const char* SettingsImpl__getCompileCommand(void)
{
  if (compileCommand == NULL) {
    // Get a default command
    const char *res = getenv("MC_DEFAULT_COMPILE_CMD");
    if (res == NULL)
      return DEFAULT_CXX;
    return res;
  }
  return compileCommand;
}

extern void SettingsImpl__setCompileCommand(const char *command)
{
  if(compileCommand)
    free(compileCommand);
  compileCommand = strdup(command);
}

static const char* SettingsImpl__getCompilePath(void)
{
  if (compilePath == NULL) {
    // Get a default command
    const char *res = getenv("MC_DEFAULT_COMPILE_PATH");
    if (res == NULL)
      return "";
    return res;
  }
  return compilePath;
}

extern void SettingsImpl__setCompilePath(const char *path) {
  if(compilePath)
    free(compilePath);
  compilePath = strdup(path);
}

static void commonSetEnvVar(const char *var, const char *value)
{
  int lenVar = strlen(var);
  int lenVal = strlen(value);
  char* command = (char*) malloc(lenVar+lenVal+2);
  assert(command != NULL);
  /* create a str of the form: <VAR>=<VALUE>*/
  snprintf(command, lenVar+lenVal+2, "%s=%s", var, value);
  command[lenVar+lenVal+1]='\0';
  /* set the env-var to created string this is useful when scripts and clients started by omc wants to use OPENMODELICAHOME*/
  assert(putenv(command) == 0); // adrpo: in Linux there is not _putenv if( _putenv(omhome) != 0)
#if defined(WIN32)
  /* Only free on windows, in Linux the environment is taking over the ownership of the ptr */
  free(command);
#endif
}

extern void SettingsImpl__setInstallationDirectoryPath(const char *value)
{
  commonSetEnvVar("OPENMODELICAHOME",value);
}

extern void SettingsImpl__setModelicaPath(const char *value)
{
  commonSetEnvVar("OPENMODELICALIBRARY",value);
}

extern void SettingsImpl__setTempDirectoryPath(const char *path)
{
  if (tempDirectoryPath)
    free(tempDirectoryPath);
  tempDirectoryPath = strdup(path);
}

extern const char* SettingsImpl__getTempDirectoryPath(void)
{
  if (tempDirectoryPath == NULL) {
  // On windows, set Temp directory path to Temp directory as returned by GetTempPath,
  // which is usually TMP or TEMP or windows catalogue.
  #ifdef WIN32
    int numChars;
    char tempDirectory[1024];
      //extract the temp path
    numChars= GetTempPath(1024, tempDirectory);
    if (numChars == 1024 || numChars == 0) {
      fprintf(stderr, "Error setting temppath in Kernel\n");
      exit(1);
    } else {
      // Must do replacement in two steps, since the _replace function can not have similar source as target.
      char *str = _replace(tempDirectory, (char*)"\\", (char*)"/");
      tempDirectoryPath = _replace(str, (char*)"/", (char*)"\\\\");
      GC_free(str);
    }
  #else
    const char* str = getenv("TMPDIR");
    if (str == NULL) {
      tempDirectoryPath = strdup("/tmp");
    } else {
      tempDirectoryPath = strdup(str);
    }
  #endif
  }
  return tempDirectoryPath;
}

#ifdef __cplusplus
}
#endif
