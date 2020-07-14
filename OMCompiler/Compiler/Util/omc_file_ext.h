/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef __OMC_FILE_H
#define __OMC_FILE_H

#include <stdio.h>
#include <gc.h>
#include <errno.h>
#include "ModelicaUtilities.h"

typedef struct {
  FILE* file /* the file */;
  mmc_sint_t cnt /* reference count */;
  const char* name /* the file name */;
} __OMC_FILE;

enum escape_t {
  None=1,
  C,
  JSON,
  XML
};

enum whence_t {
  OMC_SEEK_SET=1,
  OMC_SEEK_CURRENT,
  OMC_SEEK_END
};


static inline void* om_file_new(void *fromID)
{
  if (0==fromID) {
    __OMC_FILE *res = (__OMC_FILE*) GC_malloc(sizeof(__OMC_FILE));
    res->file = NULL;
    res->cnt = 0;
    res->name = "[no open file]";
#if defined(__OMC_FILE_DEBUG)
    fprintf(stderr,"File.constructor: new %s\n", res->name); fflush(NULL);
#endif
    return res;
  } else {
    ((__OMC_FILE*)fromID)->cnt++; /* Increase reference count */
#if defined(__OMC_FILE_DEBUG)
    fprintf(stderr,"File.constructor: fromID: %s, %ld %p\n", ((__OMC_FILE*)fromID)->name, (long) ((__OMC_FILE*)fromID)->cnt, fromID); fflush(NULL);
#endif
    return fromID;
  }
}

static inline void om_file_free(__OMC_FILE *file)
{
  if (file->cnt /* reference count */) {
    file->cnt--;
    return;
  }
#if defined(__OMC_FILE_DEBUG)
  fprintf(stderr,"File.destructor: close:%s,%p,%p\n",file->name, file->file, file); fflush(NULL);
#endif
  fclose(file->file);
  file->file = 0;
  file->name = "[closed]";
  GC_free(file);
}

static inline void om_file_open(__OMC_FILE *file, const char *filename, int mode)
{
  if (file->file) {
#if defined(__OMC_FILE_DEBUG)
    fprintf(stderr,"File.open: close :%s,%p,%p\n",file->name, file->file, file); fflush(NULL);
#endif
    fclose(file->file);
  }
#if defined(__APPLE_CC__)||defined(__MINGW32__)||defined(__MINGW64__)
  if (mode == 1) {
    file->file = fopen(filename, "rb");
  } else {
    unlink(filename);
    file->file = fopen(filename, "wb");
  }
#else
  file->file = fopen(filename, mode == 1 ? "rb" : "wb");
#endif
  file->name = filename;
#if defined(__OMC_FILE_DEBUG)
  fprintf(stderr,"File.open: f:%s,%p,%p\n",file->name,file->file,file); fflush(NULL);
#endif
  if (0 == file->file) {
    ModelicaFormatError("File.open: Failed to open file %s with mode %d: %s\n", filename, mode, strerror(errno));
  }
}

static inline void om_file_write(__OMC_FILE *file,const char *data)
{
  if (!file->file) {
    ModelicaFormatError("File.write: Failed to write to file: %s (not open)", file->name);
  }
  if (EOF == fputs(data, file->file)) {
    ModelicaFormatError("File.write: Failed to write to file: %s error: %s\n", file->name, strerror(errno));
  }
}

static inline void om_file_write_int(__OMC_FILE *file, int data, const char *format)
{
  if (!file->file) {
    ModelicaFormatError("File.writeInt: Failed to write to file: %s (not open)", file->name);
  }
  if (EOF == fprintf(file->file, format, data)) {
    ModelicaFormatError("File.writeInt: Failed to write to file: %s error: %s\n", file->name, strerror(errno));
  }
}

static inline void om_file_write_real(__OMC_FILE *file, double data, const char *format)
{
  if (!file->file) {
    ModelicaFormatError("File.writeReal: Failed to write to file: %s (not open)", file->name);
  }
  if (EOF == fprintf(file->file, format, data)) {
    ModelicaFormatError("File.writeReal: Failed to write to file: %s error: %s\n", file->name, strerror(errno));
  }
}

#define OMC_ERROR_WRITE() ModelicaFormatError("File.writeEscape: Failed to write to file %s: %s error: %s\n", file->name, file->file, strerror(errno))

static inline void om_file_write_escape(__OMC_FILE *file, const char *data, enum escape_t escape)
{
  if (!file->file) {
    ModelicaFormatError("File.writeEscape: Failed to write to file: %s (not open)", file->name);
  }
  switch (escape) {
  case None:
    if (EOF == fputs(data, file->file)) {
      ModelicaFormatError("File.writeEscape: Failed to write to file: %s error: %s\n", file->name, strerror(errno));
    }
    break;
  case C:
    while (*data) {
      if (*data == '\n') {
        if (fputs("\\n", file->file) < 0) OMC_ERROR_WRITE();
      } else if (*data == '"') {
        if (fputs("\\\"", file->file) < 0) OMC_ERROR_WRITE();
      } else {
        if (putc(*data, file->file) < 0) OMC_ERROR_WRITE();
      }
      data++;
    }
    break;
  case JSON:
    while (*data) {
      switch (*data) {
      case '"': if (fputs("\\\"", file->file) < 0) OMC_ERROR_WRITE();break;
      case '\\': if (fputs("\\\\", file->file) < 0) OMC_ERROR_WRITE();break;
      case '\n': if (fputs("\\n", file->file) < 0) OMC_ERROR_WRITE();break;
      case '\b': if (fputs("\\b", file->file) < 0) OMC_ERROR_WRITE();break;
      case '\f': if (fputs("\\f", file->file) < 0) OMC_ERROR_WRITE();break;
      case '\r': if (fputs("\\r", file->file) < 0) OMC_ERROR_WRITE();break;
      case '\t': if (fputs("\\t", file->file) < 0) OMC_ERROR_WRITE();break;
      default:
        if (*data < ' ') { /* Escape other control characters */
          if (fprintf(file->file, "\\u%04x",*data) < 0) OMC_ERROR_WRITE();
        } else {
          if (putc(*data, file->file) < 0) OMC_ERROR_WRITE();
        }
      }
      data++;
    }
    break;
  case XML:
    while (*data) {
      switch (*data) {
      case '<': if (fputs("&lt;", file->file) < 0) OMC_ERROR_WRITE();break;
      case '>': if (fputs("&gt;", file->file) < 0) OMC_ERROR_WRITE();break;
      case '"': if (fputs("&#34;", file->file) < 0) OMC_ERROR_WRITE();break;
      case '&': if (fputs("&amp;", file->file) < 0) OMC_ERROR_WRITE();break;
      case '\'': if (fputs("&#39;", file->file) < 0) OMC_ERROR_WRITE();break;
      default:
        if (putc(*data, file->file) < 0) OMC_ERROR_WRITE();
      }
      data++;
    }
    break;
  default:
    ModelicaFormatError("File.writeEscape: No such escape enumeration: %d\n", escape);
  }
}

static inline int om_file_seek(__OMC_FILE *file, int offset, enum whence_t whence)
{
  if (!file->file) {
    return 0;
  }
  return 0 == fseek(file->file, offset, whence == OMC_SEEK_SET ? SEEK_SET : whence == OMC_SEEK_CURRENT ? SEEK_CUR : SEEK_END);
}

static inline int om_file_tell(__OMC_FILE *file)
{
  if (!file->file) {
    return -1;
  }
  return ftell(file->file);
}

static inline void* om_file_get_filename(__OMC_FILE *file)
{
#if defined(__OMC_FILE_DEBUG)
  fprintf(stderr,"File.getFilename: %s, %p %p\n", file->name, file->file, file); fflush(NULL);
#endif
  return mmc_mk_scon(file->name);
}

static inline void* om_file_no_reference()
{
  return 0;
}

static inline void* om_file_get_reference(__OMC_FILE *file)
{
#if defined(__OMC_FILE_DEBUG)
  fprintf(stderr,"File.getReference: %s, %p %p\n", file->name, file->file, file); fflush(NULL);
#endif
  file->cnt++;
  return file;
}

static inline void* om_file_release_reference(__OMC_FILE *file)
{
  file->cnt--;
  return file;
}

#endif /* __OMC_FILE_H */
