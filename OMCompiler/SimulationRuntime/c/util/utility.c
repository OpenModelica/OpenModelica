/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */


#include "../ModelicaUtilities.h"
#include "utility.h"
#include "modelica_string.h"
#include "omc_file.h"
#include "../simulation_data.h"
#include "../simulation/options.h"
#include <string.h>
#include <errno.h>

modelica_real real_int_pow(threadData_t *threadData, modelica_real base, modelica_integer n)
{
  modelica_real result = 1.0;
  modelica_integer m = n < 0;
  FILE_INFO info = omc_dummyFileInfo;
  if(m)
  {
    if(base == 0.0)
      omc_assert(threadData, info, "Model error. 0^(%i) is not defined", n);
    n = -n;
  }
  while(n != 0)
  {
    if((n % 2) != 0)
    {
      result *= base;
      n--;
    }
    base *= base;
    n /= 2;
  }
  return m ? (1 / result) : result;
}

#if !defined(OMC_MINIMAL_RUNTIME)

#include <regex.h>
#include "../meta/meta_modelica.h"

extern int OpenModelica_regexImpl(const char* str, const char* re, const int maxn, int extended, int ignoreCase, void*(*mystrdup)(const char*), void **outMatches)
{
  regex_t myregex;
  int nmatch=0,i,rc,res;
  int flags = (extended ? REG_EXTENDED : 0) | (ignoreCase ? REG_ICASE : 0) | (maxn ? 0 : REG_NOSUB);
#if !defined(_MSC_VER)
  regmatch_t matches[maxn < 1 ? 1 : maxn];
#else
  /* Stupid compiler */
  regmatch_t *matches;
  matches = (regmatch_t*)malloc(maxn*sizeof(regmatch_t));
  assert(matches != NULL);
#endif
  memset(&myregex, 1, sizeof(regex_t));
  rc = regcomp(&myregex, re, flags);
  if (rc && maxn == 0) {
#if defined(_MSC_VER)
    free(matches);
#endif
    return 0;
  }
  if (rc) {
    char err_buf[2048] = {0};
    int len = 0;
    len += snprintf(err_buf+len,2040-len,"Failed to compile regular expression: %s with error: ", re);
    regerror(rc, &myregex, err_buf+len, 2048-len);
    regfree(&myregex);
    if (maxn) {
      outMatches[0] = mystrdup(err_buf);
      for (i=1; i<maxn; i++)
        outMatches[i] = mystrdup("");
    }
#if defined(_MSC_VER)
    free(matches);
#endif
    return 0;
  }
  res = regexec(&myregex, str, maxn, matches, 0);
  if (!maxn)
    nmatch += res == 0 ? 1 : 0;
  else if (maxn) {
    char *dup = strdup(str);
    for (i=0; i<maxn; i++) {
      if (!res && matches[i].rm_so != -1) {
        memcpy(dup, str + matches[i].rm_so, matches[i].rm_eo - matches[i].rm_so);
        dup[matches[i].rm_eo - matches[i].rm_so] = '\0';
        outMatches[nmatch++] = mystrdup(dup);
      }
    }
    for (i=nmatch; i<maxn; i++) {
      outMatches[i] = mystrdup("");
    }
    free(dup);
  }

  regfree(&myregex);
#if defined(_MSC_VER)
  free(matches);
#endif
  return nmatch;
}

static char* Modelica_strdup(const char *str)
{
  char *res = ModelicaAllocateString(strlen(str));
  strcpy(res, str);
  return res;
}

extern int OpenModelica_regex(const char* str, const char* re, int maxn, int extended, int sensitive, const char **outMatches)
{
  return OpenModelica_regexImpl(str,re,maxn,extended,sensitive,(void*(*)(const char*)) Modelica_strdup,(void**)outMatches);
}

#endif /* OMC_MINIMAL_RUNTIME */

/* TODO: What is the ifdef for filesystem availability? */

void OpenModelica_updateUriMapping(threadData_t *threadData, void *namesAndDirs)
{
  int i;
  threadData->localRoots[LOCAL_ROOT_URI_LOOKUP] = namesAndDirs; /* This should keep the names from being garbage collected */
}

#include <sys/stat.h>

#if defined(_MSC_VER)
#define stat _stat
#else
#include <unistd.h>
#endif

static const char *PATH_NOT_IN_FMU_RESOURCES = "Returning path (%s) not in the resources directory. The FMU might not work as expected if you send it to a different system";

/* if uri starts with X:\ or X:/ */
static int hasDriveLetter(const char* uri)
{
  return strlen(uri) > 2 &&
         ((uri[0] >= 'A' && uri[0] <= 'Z') || (uri[0] >= 'a' && uri[0] <= 'z')) &&
         uri[1]==':' && (uri[2] == '/' || uri[2] == '\\');
}

static modelica_string uriToFilenameRegularPaths(modelica_string uri_om, const char *uri, char buf[PATH_MAX], const char *origUri, const char *resourcesDir)
{
  FILE_INFO info = omc_dummyFileInfo;
  omc_stat_t stat_buf;
  size_t len, i, j = 0;
  int uriExists = 0==omc_stat(uri, &stat_buf);
  if (resourcesDir) {
    if (strlen(resourcesDir)+strlen(uri)+2 < PATH_MAX) {
      if (hasDriveLetter(uri)) {
        sprintf(buf, "%s/", resourcesDir);
        len = strlen(buf);
        for (i = 0; i < strlen(uri); i++)
          if (uri[i] != ':')
          {
              buf[len+j] = (uri[i] == '\\') ? '/' : uri[i];
              j++;
          }
        buf[len+j]='\0';
      } else {
        sprintf(buf, "%s/%s", resourcesDir, uri);
      }
      if (!uriExists || 0==omc_stat(buf, &stat_buf)) {
        /* The path with resources prepended either exists or the path without resources does not exist
         * So re-run uriToFilenameRegularPaths with resourcesDir prepended to the URI
         */
        char newbuf[PATH_MAX];
        return uriToFilenameRegularPaths(NULL, buf, newbuf, origUri, NULL);
      }
    } else {
      omc_assert_warning(info, "Path longer than PATH_MAX: %s/%s", resourcesDir, uri);
    }
  }
  if (uriExists) {
    if (resourcesDir) {
      omc_assert_warning(info, PATH_NOT_IN_FMU_RESOURCES, uri);
    }
    /* This is a file, directory, etc. Can't use open to check this. */
    if (0==realpath(uri, buf)) {
      /* Unexpected; we know the file exists, but realpath failed. Just return the URI */
      omc_assert_warning(info, "realpath failed for existing path %s: %s", uri, strerror(errno));
      return uri_om ? uri_om : mmc_mk_scon(uri);
    }
    /* Use the realpath result */
    if (S_ISDIR(stat_buf.st_mode)) {
      /* Make directories end with a / if the original URI ends with a / */
      len = strlen(buf);
      if (buf[len-1]!='/' && origUri[strlen(origUri)-1]=='/') {
        if (len+1 >= PATH_MAX) {
          /* Can't fit the path; just return the original URI */
          omc_assert_warning(info, "Path longer than PATH_MAX: %s/, returning %s", buf, buf);
          return uri_om ? uri_om : mmc_mk_scon(uri);
        }
        strcpy(buf+len, "/");
      }
    }
    return (0==strcmp(uri, buf) && uri_om) ? uri_om : mmc_mk_scon(buf);
  }

  if (uri[0]=='/' || hasDriveLetter(uri)) {
    /* Absolute path */
    return uri_om ? uri_om : mmc_mk_scon(uri);
  }
  if (0==realpath("./", buf)) {
    /* Failed to resolve ./ */
    omc_assert_warning(info, "realpath failed to resolve ./");
    return uri_om ? uri_om : mmc_mk_scon(uri);
  }
  len = strlen(buf);
  if (len+strlen(uri)+1 >= PATH_MAX) {
    /* Can't fit the path; just return the original URI */
    omc_assert_warning(info, "Path longer than PATH_MAX: %s/%s, returning %s", buf, uri, uri);
    return uri_om ? uri_om : mmc_mk_scon(uri);
  }
  /* Copy the rest of the URI onto the buffer */
  if (buf[len-1]!='/') {
    buf[len++]='/';
  }
  strcpy(buf+len, uri);
  return mmc_mk_scon(buf);
}

static int findString(const void *name, const void *entry)
{
  return strcmp((const char *)name, MMC_STRINGDATA(((void**)entry)[0]));
}

static modelica_string lookupDirectoryFromName(const char *name, void *nameDirArray)
{
  size_t len;
  void **strs;
  void **obj;
  assert(0!=nameDirArray);
  len = MMC_HDRSLOTS(MMC_GETHDR(nameDirArray));
  strs = MMC_STRUCTDATA(nameDirArray);
  obj=bsearch(name, strs, len/2, 2*sizeof(void*), findString);
  if (obj==NULL) {
    return NULL;
  }
  return obj[1];
}

static void getIdent(const char *str, char *this, const char **next)
{
  while (*str != 0 && *str != '.' && *str != '/') {
    *(this++) = *(str++);
  }
  *this = '\0';
  *next = str;
}

extern modelica_string OpenModelica_uriToFilename_impl(threadData_t *threadData, modelica_string uri_om, const char *resourcesDir)
{
#if defined(_MSC_VER)
#define strncasecmp _strnicmp
#endif

  FILE_INFO info = omc_dummyFileInfo;
  char buf[PATH_MAX];
  const char *uri = MMC_STRINGDATA(uri_om);
  modelica_string dir;
  if (0==strncasecmp(uri, "modelica://", 11)) {
    omc_stat_t stat_buf;
    uri += 11;
    getIdent(uri, buf, &uri);
    if (0 == *buf) {
      omc_assert(threadData, info, "Malformed URI (couldn't get a class name): %s", MMC_STRINGDATA(uri_om));
      MMC_THROW();
    }
    dir = lookupDirectoryFromName(buf, threadData->localRoots[LOCAL_ROOT_URI_LOOKUP]);
    if (dir==NULL || MMC_STRLEN(dir)==0) {
      omc_assert(threadData, info, "Failed to lookup URI (is the package loaded?) %s", MMC_STRINGDATA(uri_om));
      MMC_THROW();
    }
    if (resourcesDir) {
      if (MMC_STRLEN(dir)+2+strlen(resourcesDir) >= PATH_MAX) {
        omc_assert_warning(info, "Path longer than PATH_MAX: %s/%s, ignoring the resourcesDir", MMC_STRINGDATA(dir), resourcesDir);
      } else {
        int dirExists = 0==omc_stat(MMC_STRINGDATA(dir), &stat_buf);
        sprintf(buf, "%s/%s", MMC_STRINGDATA(dir), resourcesDir);
        if (!dirExists || 0==omc_stat(buf, &stat_buf)) {
          dir = mmc_mk_scon(buf);
        } else {
          omc_assert_warning(info, PATH_NOT_IN_FMU_RESOURCES, MMC_STRINGDATA(dir));
        }
      }
    }
    /* We found where the package is stored */
    while (1) {
      if (*uri == '.') {
        uri++;
      } else {
        break;
      }
      getIdent(uri, buf, &uri);
      if (0 == *buf) {
        if (*uri == '.') {
          omc_assert(threadData, info, "Malformed URI (double dot in class name): %s", MMC_STRINGDATA(uri_om));
          MMC_THROW();
        }
        break; /* / or end of string */
      }
      if (MMC_STRLEN(dir)+strlen(buf)+1 >= PATH_MAX) {
        omc_assert(threadData, info, "Failed to resolve URI; path longer than PATH_MAX(%d): %s", PATH_MAX, MMC_STRINGDATA(uri_om));
        MMC_THROW();
      }
      /* Move the found ident last in the path */
      strcpy(buf+MMC_STRLEN(dir)+1, buf);
      /* Copy the old directory in there */
      strcpy(buf, MMC_STRINGDATA(dir));
      buf[MMC_STRLEN(dir)]='/';
      if (!(0==omc_stat(buf, &stat_buf) && S_ISDIR(stat_buf.st_mode))) {
        break;
      }
      dir = mmc_mk_scon(buf);
    }
    while (*uri && *(uri++) != '/') /* Ignore */;
    if (0 == strlen(uri)) {
      /* realpath, etc */
      return uriToFilenameRegularPaths(dir, MMC_STRINGDATA(dir), buf, MMC_STRINGDATA(uri_om), NULL);
    }
    if (MMC_STRLEN(dir)+strlen(uri-1) >= PATH_MAX) {
      return mmc_emptystring;
    }
    strcpy(buf, MMC_STRINGDATA(dir));
    strcpy(buf+MMC_STRLEN(dir), uri-1);
    dir = mmc_mk_scon(buf);
    return uriToFilenameRegularPaths(dir, MMC_STRINGDATA(dir), buf, MMC_STRINGDATA(uri_om), NULL);
  }
  if (0==strncasecmp(uri, "file://", 7)) {
    return uriToFilenameRegularPaths(NULL, uri+7, buf, MMC_STRINGDATA(uri_om), resourcesDir);
  }
  if (strstr(uri, "://")) {
    omc_assert(threadData, info, "Unknown URI schema: %s", MMC_STRINGDATA(uri_om));
    MMC_THROW();
  }
  return uriToFilenameRegularPaths(uri_om, uri, buf, MMC_STRINGDATA(uri_om), resourcesDir);
}

/* TODO: Remove this function after @sjoelund is done prototyping */
extern void uriToFilename(threadData_t *threadData)
{
  abort();
}

