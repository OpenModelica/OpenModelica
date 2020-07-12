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

#if defined(OMC_BOOTSTRAPPING)
  #include "../boot/tarball-include/OpenModelicaBootstrappingHeader.h"
#else
  #include "../OpenModelicaBootstrappingHeader.h"
#endif

#if defined(_MSC_VER) || defined(__MINGW32__)
#define OMC_GROUP_DELIMITER ";"
#else
#define OMC_GROUP_DELIMITER ":"
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

static char* omc_installationPath = NULL;
static char* omc_modelicaPath = NULL;
static char* omc_userHome = NULL;

extern char* _replace(char* source_str,char* search_str,char* replace_str); //Defined in systemimpl.c

static void commonSetEnvVar(const char *var, const char *value);

/* convert to fowaard slahes in place */
char* covertToForwardSlashesInPlace(char* path) {
#if defined(__MINGW32__) || defined(__MINGW64__) || defined(_MSC_VER) /* Not linux or Apple */
  int i = 0;
  while(path[i] != '\0') {
    if (path[i] == '\\') path[i] = '/';
    i++;
  }
#endif
  return path;
}

#if !defined(OPENMODELICA_BOOTSTRAPPING_STAGE_1) && (defined(__linux__) || defined(__APPLE_CC__))
/* Helper function to strip /bin/... or /lib/... from the executable path of omc */
static void stripbinpath(char *omhome)
{
  char *tmp = NULL;
  /* adrpo: if the path does not contain "bin" or "lib" exit gracefully as otherwise the assertion will trigger */
  if (strstr(omhome, "bin") == NULL && strstr(omhome, "lib") == NULL)
  {
    fprintf(stderr, "could not deduce the OpenModelica installation directory from executable path: [%s], please set OPENMODELICAHOME", omhome);
    exit(EXIT_FAILURE);
  }

  do {
    tmp = strrchr(omhome,'/');
    assert(tmp);
    *tmp = '\0';
  } while (strcmp(tmp+1,"bin") && strcmp(tmp+1,"lib"));
  return;
}
#endif

/* Do not free or modify the returned variable of getInstallationDirectoryPath. It's part of the environment! */
#if defined(OPENMODELICA_BOOTSTRAPPING_STAGE_1) && !(defined(_MSC_VER) || defined(__MINGW32__))
const char* SettingsImpl__getInstallationDirectoryPath(void) {
  const char *path = getenv("OPENMODELICAHOME");
  return path ? path : "OPENMODELICA_BOOTSTRAPPING_STAGE_1_NO_OPENMODELICAHOME";
}
#elif defined(__linux__) || defined(__APPLE_CC__)
#include <dlfcn.h>

const char* SettingsImpl__getInstallationDirectoryPath(void) {
  int ret;
  if (omc_installationPath) {
    return omc_installationPath;
  }

  Dl_info info;
  if (!dladdr((void*) SettingsImpl__getInstallationDirectoryPath, &info)) {
    fprintf(stderr, "dladdr() failed: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  } else {
    omc_installationPath = omc_alloc_interface.malloc_strdup(info.dli_fname);
    stripbinpath(omc_installationPath);
  }
  if (!(omc_installationPath && omc_installationPath[0])) {
    fprintf(stderr, "Failed to get binary path from dladdr path: %s\n", info.dli_fname);
    exit(EXIT_FAILURE);
  }

  commonSetEnvVar("OPENMODELICAHOME", omc_installationPath);
  return omc_installationPath;
}

#elif defined(__MINGW32__) || defined(__MINGW64__) || defined(_MSC_VER) /* Not linux or Apple */

const char* SettingsImpl__getInstallationDirectoryPath(void) {
  int i = 0;
  if (omc_installationPath) {
    return omc_installationPath;
  }
  if (omc_installationPath == NULL) {
    char filename[MAX_PATH];
    if (0 != GetModuleFileName(GetModuleHandle("libOpenModelicaCompiler.dll"), filename, MAX_PATH)) {
      omc_installationPath = strdup(filename); /* duplicate the path */
      *strrchr(omc_installationPath, '\\') = '\0';
      *strrchr(omc_installationPath, '\\') = '\0';
    }
    else
    {
      return CONFIG_DEFAULT_OPENMODELICAHOME; // On Windows, this is NULL; on Unix it is the configured --prefix
    }
  }

  omc_installationPath = covertToForwardSlashesInPlace(omc_installationPath);

  commonSetEnvVar("OPENMODELICAHOME", omc_installationPath);
  return (const char*)omc_installationPath;
}

#endif

char* Settings_getHomeDir(int runningTestsuite)
{
  if (runningTestsuite) {
    return omc_alloc_interface.malloc_strdup("");
  }

  if (omc_userHome)
  {
    return omc_userHome;
  }

#if !(defined(_MSC_VER) || defined(__MINGW32__))
  omc_userHome = getenv("HOME");
  if (omc_userHome == NULL) {
    omc_userHome = getpwuid(getuid())->pw_dir;
  }
#else /* windows & mingw */
  omc_userHome = getenv("APPDATA");
  if (omc_userHome == NULL) {
    omc_userHome = getenv("HOME");
  }
#endif
  if (omc_userHome == NULL || runningTestsuite) {
    return omc_alloc_interface.malloc_strdup("");
  }
  omc_userHome = omc_alloc_interface.malloc_strdup(omc_userHome);
  return covertToForwardSlashesInPlace(omc_userHome);
}


/*
 * - if already set, use it
 * - if not set, use OPENMODELICALIBRARY
 * - if not set, get the installation path and use that
 */
char* SettingsImpl__getModelicaPath(int runningTestsuite) {
  if (omc_modelicaPath) {
    return omc_modelicaPath;
  }

  {
    /* if we are running the testsuite, use the default */
    const char *path = runningTestsuite ? NULL : getenv("OPENMODELICALIBRARY");
    if (path != NULL)
    {
        omc_modelicaPath = strdup(path);
    }
    else
    {
      /* get the install directory */
      const char *omhome = SettingsImpl__getInstallationDirectoryPath();
      if (omhome == NULL)
        return NULL;
      int lenOmhome = strlen(omhome);
      const char *homePath = Settings_getHomeDir(0);
      assert(homePath != NULL || !runningTestsuite);
      if (runningTestsuite) {
        int lenHome = strlen(homePath);
        omc_modelicaPath = (char*)malloc(lenHome+26);
        snprintf(omc_modelicaPath, lenHome+26,"%s/.openmodelica/libraries/", homePath);
      } else if (homePath == NULL) {
        omc_modelicaPath = (char*)malloc(lenOmhome+15);
        snprintf(omc_modelicaPath, lenOmhome+15,"%s/lib/omlibrary", omhome);
      } else {
        int lenHome = strlen(homePath);
        omc_modelicaPath = (char*)omc_alloc_interface.malloc_atomic(lenOmhome+lenHome+41);
        snprintf(omc_modelicaPath, lenOmhome+lenHome+41,"%s/lib/omlibrary%s%s/.openmodelica/libraries/", omhome, OMC_GROUP_DELIMITER, homePath);
      }
    }

    omc_modelicaPath = covertToForwardSlashesInPlace(omc_modelicaPath);

    if (!runningTestsuite) {
      commonSetEnvVar("OPENMODELICALIBRARY", omc_modelicaPath);
    }
  }

  return omc_modelicaPath;
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
  if (value[0] == '\0') /* clear it if is empty */
  {
    omc_installationPath = NULL;
    return;
  }
  omc_installationPath = strdup(value);
  omc_installationPath = covertToForwardSlashesInPlace(omc_installationPath);
  commonSetEnvVar("OPENMODELICAHOME", omc_installationPath);
}

extern void SettingsImpl__setModelicaPath(const char *value)
{
  if (value[0] == '\0') /* clear it if is empty */
  {
    omc_modelicaPath = NULL;
    return;
  }
  omc_modelicaPath = strdup(value);
  omc_modelicaPath = covertToForwardSlashesInPlace(omc_modelicaPath);
  commonSetEnvVar("OPENMODELICALIBRARY", omc_modelicaPath);
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
