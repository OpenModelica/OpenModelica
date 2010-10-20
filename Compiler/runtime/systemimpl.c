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

static modelica_integer SystemImpl__regularFileExists(const char* str)
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
  if ((FileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    ret_val = 0;
  } else {
    ret_val = 1;
  }
  FindClose(sh);
  return ret_val;
#else
  struct stat buf;
  if (stat(str, &buf)) return 0;
  return (buf.st_mode & S_IFREG);
#endif
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
static modelica_integer SystemImpl__writeFile(const char* filename, const char* data)
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

static modelica_integer SystemImpl__stringFind(const char* str, const char* searchStr)
{
  int strLen = strlen(str);
  int strSearchLen = strlen(searchStr);
  modelica_integer i,retVal=-1;

  for (i=0; i< strLen - strSearchLen+1; i++) {
    if (strncmp(&str[i],searchStr,strSearchLen) == 0) {
      retVal = i;
      break;
    }
  }
  return retVal;
}

#ifdef __cplusplus
}
#endif
