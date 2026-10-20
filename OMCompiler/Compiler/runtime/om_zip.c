/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#if !defined(_MSC_VER)
#include <dirent.h>
#else
#include "toni_ronnko_dirent.h"
#endif
/* minizip-ng's compat zip.h does not include zlib.h, which provides uLong. */
#include <zlib.h>
#include <zip.h>
#include "util/omc_str_utils.h"
#include "util/omc_file.h"
#include "errorext.h"
#include "systemimpl.h"

#define READ_SIZE 8192

static int compareNames(const void *a, const void *b)
{
  return strcmp(*(const char **) a, *(const char **) b);
}

static int openEntry(zipFile zf, const char *zipFileName, const char *name, const omc_stat_t *st)
{
  zip_fileinfo zi;
  struct tm *t;
  time_t mtime = st->st_mtime;
  int versionMadeBy = 0;
  memset(&zi, 0, sizeof(zi));
  t = localtime(&mtime);
  if (t) {
    zi.tmz_date.tm_sec = t->tm_sec;
    zi.tmz_date.tm_min = t->tm_min;
    zi.tmz_date.tm_hour = t->tm_hour;
    zi.tmz_date.tm_mday = t->tm_mday;
    zi.tmz_date.tm_mon = t->tm_mon;
    zi.tmz_date.tm_year = t->tm_year;
  }
#if defined(_WIN32)
  zi.external_fa = S_ISDIR(st->st_mode) ? 0x10 : 0;
#else
  /* Unix permissions in the high half, as made by Info-ZIP on Unix. */
  versionMadeBy = (3 << 8) | 20;
  zi.external_fa = ((unsigned long) (st->st_mode & 0xFFFF) << 16) | (S_ISDIR(st->st_mode) ? 0x10 : 0);
#endif
  if (zipOpenNewFileInZip4_64(zf, name, &zi, NULL, 0, NULL, 0, NULL,
                              S_ISDIR(st->st_mode) ? 0 : Z_DEFLATED, Z_DEFAULT_COMPRESSION, 0,
                              -MAX_WBITS, 8, Z_DEFAULT_STRATEGY, NULL, 0,
                              versionMadeBy, 0, st->st_size >= 0xffffffff) != ZIP_OK) {
    const char *msgs[2] = {name, zipFileName};
    c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, "minizip failed to add %s to %s", msgs, 2);
    return 0;
  }
  return 1;
}

static int addFile(zipFile zf, const char *zipFileName, const char *path, const char *name, const omc_stat_t *st)
{
  char buffer[READ_SIZE];
  size_t n;
  int ok = 1;
  FILE *fin = omc_fopen(path, "rb");
  if (fin == NULL) {
    c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, "Failed to open file: %s", &path, 1);
    return 0;
  }
  if (!openEntry(zf, zipFileName, name, st)) {
    fclose(fin);
    return 0;
  }
  while (ok && (n = fread(buffer, 1, READ_SIZE, fin)) > 0) {
    ok = zipWriteInFileInZip(zf, buffer, (unsigned) n) == ZIP_OK;
  }
  if (ok && ferror(fin)) {
    const char *msgs[2] = {strerror(errno), path};
    c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, "Failed to read %s: %s", msgs, 2);
    ok = 0;
  } else if (!ok) {
    c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, "minizip failed to write to %s", &zipFileName, 1);
  }
  fclose(fin);
  return (zipCloseFileInZip(zf) == ZIP_OK) && ok;
}

static int addPath(zipFile zf, const char *zipFileName, const char *path, const char *name)
{
  omc_stat_t st;
  DIR *d;
  struct dirent *p;
  char **names = NULL;
  size_t count = 0, capacity = 0, i;
  int ok = 1;

  if (omc_stat(path, &st) != 0) {
    c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, "Failed to open file: %s", &path, 1);
    return 0;
  }
  if (!S_ISDIR(st.st_mode)) {
    return addFile(zf, zipFileName, path, name, &st);
  }
  if (*name) {
    const char *dirName = NULL;
    GC_asprintf(&dirName, "%s/", name);
    if (!openEntry(zf, zipFileName, dirName, &st) || zipCloseFileInZip(zf) != ZIP_OK) {
      return 0;
    }
  }
  d = opendir(path);
  if (d == NULL) {
    c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, "Failed to open directory: %s", &path, 1);
    return 0;
  }
  while ((p = readdir(d)) != NULL) {
    if (0 == strcmp(p->d_name, ".") || 0 == strcmp(p->d_name, "..")) {
      continue;
    }
    if (count == capacity) {
      capacity = capacity ? 2 * capacity : 16;
      names = (char **) realloc(names, capacity * sizeof(char *));
    }
    names[count++] = strdup(p->d_name);
  }
  closedir(d);
  /* Sorted, so that the archive does not depend on the order readdir returns. */
  qsort(names, count, sizeof(char *), compareNames);
  for (i = 0; i < count; i++) {
    if (ok) {
      const char *childPath = NULL, *childName = NULL;
      GC_asprintf(&childPath, "%s/%s", path, names[i]);
      GC_asprintf(&childName, "%s%s%s", name, *name ? "/" : "", names[i]);
      ok = addPath(zf, zipFileName, childPath, childName);
    }
    free(names[i]);
  }
  free(names);
  return ok;
}

int om_zip(const char *zipFileName, const char *path, const char *entryName)
{
  int ok;
  zipFile zf = zipOpen64(zipFileName, APPEND_STATUS_CREATE);
  if (zf == NULL) {
    c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, "Failed to open file for writing %s", &zipFileName, 1);
    return 0;
  }
  ok = addPath(zf, zipFileName, path, entryName);
  if (zipClose(zf, NULL) != ZIP_OK && ok) {
    c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, "minizip failed to write to %s", &zipFileName, 1);
    ok = 0;
  }
  if (!ok) {
    omc_unlink(zipFileName);
  }
  return ok;
}
