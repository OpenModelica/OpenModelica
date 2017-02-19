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

encapsulated package File

class File
  extends ExternalObject;
  function constructor
    input Option<Integer> fromID = NONE() "If we should restore from another pointer. Note: Option<Integer> is an opaque pointer, not an actual Option.";
    input String filename = "[none]";
    input Boolean  makeNew = true;
    output File file;
  external "C" file=om_file_new(fromID, makeNew, filename) annotation(Include="
#ifndef __OMC_FILE_NEW
#define __OMC_FILE_NEW
#include <stdio.h>
#include <gc.h>

#ifndef __OMC_FILE_STRUCT
#define __OMC_FILE_STRUCT
typedef struct {
  FILE* file /* the file */;
  mmc_sint_t cnt /* reference count */;
  char* name /* the file name */;
} __OMC_FILE;
#endif

static inline void* om_file_new(void *fromID, modelica_boolean makeNew, const char *filename)
{
  if (makeNew) {
    __OMC_FILE *res = (__OMC_FILE*) GC_malloc(sizeof(__OMC_FILE));
    res->file = NULL;
    res->cnt = 0;
    res->name = filename;
#if __OMC_FILE_DEBUG
    fprintf(stderr,\"File.constructor: new: %s, %p\\n\", res->name, res); fflush(NULL);
#endif
    return res;
  } else {
    ((__OMC_FILE*)fromID)->cnt++; /* Increase reference count */
#if __OMC_FILE_DEBUG
    fprintf(stderr,\"File.constructor: fromID: %s, %d %p\\n\", ((__OMC_FILE*)fromID)->name, ((__OMC_FILE*)fromID)->cnt, fromID); fflush(NULL);
#endif
    return fromID;
  }
}
#endif
");
  end constructor;

  function destructor
    input File file;
  external "C" om_file_free(file) annotation(Include="
#ifndef __OMC_FILE_FREE
#define __OMC_FILE_FREE
#include <stdio.h>

#ifndef __OMC_FILE_STRUCT
#define __OMC_FILE_STRUCT
typedef struct {
  FILE* file /* the file */;
  mmc_sint_t cnt /* reference count */;
  char* name /* the file name */;
} __OMC_FILE;
#endif

static inline void om_file_free(__OMC_FILE *file)
{
  if (file->cnt /* reference count */) {
    file->cnt--;
    return;
  }
#if __OMC_FILE_DEBUG
  fprintf(stderr,\"File.destructor: close:%s,%p,%p\\n\",file->name, file->file, file); fflush(NULL);
#endif
  fclose(file->file);
  file->file = 0;
  GC_free(file);
}
#endif
");
  end destructor;
end File;

type Mode = enumeration(Read,Write);

function open
  input File file;
  input String filename;
  input Mode mode = Mode.Read;
external "C" om_file_open(file,filename,mode) annotation(Include="
#ifndef __OMC_FILE_OPEN
#define __OMC_FILE_OPEN
#include <stdio.h>
#include <errno.h>
#include \"ModelicaUtilities.h\"

#ifndef __OMC_FILE_STRUCT
#define __OMC_FILE_STRUCT
typedef struct {
  FILE* file /* the file */;
  mmc_sint_t cnt /* reference count */;
  char* name /* the file name */;
} __OMC_FILE;
#endif

static inline void om_file_open(__OMC_FILE *file, const char *filename, int mode)
{
  if (file->file) {
#if __OMC_FILE_DEBUG
    fprintf(stderr,\"File.open: close :%s,%p,%p\\n\",file->name, file->file, file); fflush(NULL);
#endif
    fclose(file->file);
  }
  file->file = fopen(filename, mode == 1 ? \"rb\" : \"wb\");
  file->name = filename;
#if __OMC_FILE_DEBUG
  fprintf(stderr,\"File.open: f:%s,%p,%p\\n\",file->name,file->file,file); fflush(NULL);
#endif
  if (0 == file->file) {
    ModelicaFormatError(\"File.open: Failed to open file %s with mode %d: %s\\n\", filename, mode, strerror(errno));
  }
}
#endif
");
end open;

function write
  input File file;
  input String data;
external "C" om_file_write(file,data) annotation(Include="
#ifndef __OMC_FILE_WRITE
#define __OMC_FILE_WRITE
#include <stdio.h>
#include <errno.h>
#include \"ModelicaUtilities.h\"

#ifndef __OMC_FILE_STRUCT
#define __OMC_FILE_STRUCT
typedef struct {
  FILE* file /* the file */;
  mmc_sint_t cnt /* reference count */;
  char* name /* the file name */;
} __OMC_FILE;
#endif

static inline void om_file_write(__OMC_FILE *file,const char *data)
{
  if (!file->file) {
    ModelicaFormatError(\"File.write: Failed to write to file: %s (not open)\", file->name);
  }
  if (EOF == fputs(data, file->file)) {
    ModelicaFormatError(\"File.write: Failed to write to file: %s error: %s\\n\", file->name, strerror(errno));
  }
}
#endif
");
end write;

function writeInt
  input File file;
  input Integer data;
  input String format="%d";
external "C" om_file_write_int(file,data,format) annotation(Include="
#ifndef __OMC_FILE_WRITE_INT
#define __OMC_FILE_WRITE_INT
#include <stdio.h>
#include <errno.h>
#include \"ModelicaUtilities.h\"

#ifndef __OMC_FILE_STRUCT
#define __OMC_FILE_STRUCT
typedef struct {
  FILE* file /* the file */;
  mmc_sint_t cnt /* reference count */;
  char* name /* the file name */;
} __OMC_FILE;
#endif

static inline void om_file_write_int(__OMC_FILE *file, int data, const char *format)
{
  if (!file->file) {
    ModelicaFormatError(\"File.writeInt: Failed to write to file: %s (not open)\", file->name);
  }
  if (EOF == fprintf(file->file, format, data)) {
    ModelicaFormatError(\"File.writeInt: Failed to write to file: %s error: %s\\n\", file->name, strerror(errno));
  }
}
#endif
");
end writeInt;

function writeReal
  input File file;
  input Real data;
  input String format="%.15g";
external "C" om_file_write_real(file,data,format) annotation(Include="
#ifndef __OMC_FILE_WRITE_REAL
#define __OMC_FILE_WRITE_REAL
#include <stdio.h>
#include <errno.h>
#include \"ModelicaUtilities.h\"

#ifndef __OMC_FILE_STRUCT
#define __OMC_FILE_STRUCT
typedef struct {
  FILE* file /* the file */;
  mmc_sint_t cnt /* reference count */;
  char* name /* the file name */;
} __OMC_FILE;
#endif

static inline void om_file_write_real(__OMC_FILE *file, double data, const char *format)
{
  if (!file->file) {
    ModelicaFormatError(\"File.writeReal: Failed to write to file: %s (not open)\", file->name);
  }
  if (EOF == fprintf(file->file, format, data)) {
    ModelicaFormatError(\"File.writeReal: Failed to write to file: %s error: %s\\n\", file->name, strerror(errno));
  }
}
#endif
");
end writeReal;

type Escape = enumeration(None "No escape string",
                          C "Escapes C strings (minimally): \\n and \"",
                          JSON "Escapes JSON strings (quotes and control characters)",
                          XML "Escapes strings to XML text");

function writeEscape
  input File file;
  input String data;
  input Escape escape;
external "C" om_file_write_escape(file,data,escape) annotation(Include="
#ifndef __OMC_FILE_WRITE_ESCAPE
#define __OMC_FILE_WRITE_ESCAPE
#include <stdio.h>
#include <errno.h>
#include \"ModelicaUtilities.h\"

#ifndef __OMC_FILE_STRUCT
#define __OMC_FILE_STRUCT
typedef struct {
  FILE* file /* the file */;
  mmc_sint_t cnt /* reference count */;
  char* name /* the file name */;
} __OMC_FILE;
#endif

enum escape_t {
  None=1,
  C,
  JSON,
  XML
};
#define ERROR_WRITE() ModelicaFormatError(\"File.writeEscape: Failed to write to file: %s error: %s\\n\", file->file, strerror(errno))

static inline void om_file_write_escape(__OMC_FILE *file, const char *data, enum escape_t escape)
{
  if (!file->file) {
    ModelicaFormatError(\"File.writeEscape: Failed to write to file: %s (not open)\", file->name);
  }
  switch (escape) {
  case None:
    if (EOF == fputs(data, file->file)) {
      ModelicaFormatError(\"File.writeEscape: Failed to write to file: %s error: %s\\n\", file->name, strerror(errno));
    }
    break;
  case C:
    while (*data) {
      if (*data == '\\n') {
        if (fputs(\"\\\\n\", file->file) < 0) ERROR_WRITE();
      } else if (*data == '\"') {
        if (fputs(\"\\\\\\\"\", file->file) < 0) ERROR_WRITE();
      } else {
        if (putc(*data, file->file) < 0) ERROR_WRITE();
      }
      data++;
    }
    break;
  case JSON:
    while (*data) {
      switch (*data) {
      case '\\\"': if (fputs(\"\\\\\\\"\", file->file) < 0) ERROR_WRITE();break;
      case '\\\\': if (fputs(\"\\\\\\\\\", file->file) < 0) ERROR_WRITE();break;
      case '\\n': if (fputs(\"\\\\n\", file->file) < 0) ERROR_WRITE();break;
      case '\\b': if (fputs(\"\\\\b\", file->file) < 0) ERROR_WRITE();break;
      case '\\f': if (fputs(\"\\\\f\", file->file) < 0) ERROR_WRITE();break;
      case '\\r': if (fputs(\"\\\\r\", file->file) < 0) ERROR_WRITE();break;
      case '\\t': if (fputs(\"\\\\t\", file->file) < 0) ERROR_WRITE();break;
      default:
        if (*data < ' ') { /* Escape other control characters */
          if (fprintf(file->file, \"\\\\u%04x\",*data) < 0) ERROR_WRITE();
        } else {
          if (putc(*data, file->file) < 0) ERROR_WRITE();
        }
      }
      data++;
    }
    break;
  case XML:
    while (*data) {
      switch (*data) {
      case '<': if (fputs(\"&lt;\", file->file) < 0) ERROR_WRITE();break;
      case '>': if (fputs(\"&gt;\", file->file) < 0) ERROR_WRITE();break;
      case '\"': if (fputs(\"&#34;\", file->file) < 0) ERROR_WRITE();break;
      case '&': if (fputs(\"&amp;\", file->file) < 0) ERROR_WRITE();break;
      case '\\'': if (fputs(\"&#39;\", file->file) < 0) ERROR_WRITE();break;
      default:
        if (putc(*data, file->file) < 0) ERROR_WRITE();
      }
      data++;
    }
    break;
  default:
    ModelicaFormatError(\"File.writeEscape: No such escape enumeration: %d\\n\", escape);
  }
}
#endif
");
end writeEscape;

type Whence = enumeration(Set "SEEK_SET 0=start of file",Current "SEEK_CUR 0=current byte",End "SEEK_END 0=end of file");

function seek
  input File file;
  input Integer offset;
  input Whence whence = Whence.Set;
  output Boolean success;
external "C" success = om_file_seek(file,offset,whence) annotation(Include="
#ifndef __OMC_FILE_SEEK
#define __OMC_FILE_SEEK
#include <stdio.h>
#include \"ModelicaUtilities.h\"
enum whence_t {
  OMC_SEEK_SET=1,
  OMC_SEEK_CURRENT,
  OMC_SEEK_END
};

#ifndef __OMC_FILE_STRUCT
#define __OMC_FILE_STRUCT
typedef struct {
  FILE* file /* the file */;
  mmc_sint_t cnt /* reference count */;
  char* name /* the file name */;
} __OMC_FILE;
#endif

static inline int om_file_seek(__OMC_FILE *file, int offset, enum whence_t whence)
{
  if (!file->file) {
    return 0;
  }
  return 0 == fseek(file->file, offset, whence == OMC_SEEK_SET ? SEEK_SET : whence == OMC_SEEK_CURRENT ? OMC_SEEK_CURRENT : SEEK_END);
}
#endif
");
end seek;

function tell
  input File file;
  output Integer pos;
external "C" pos = om_file_tell(file) annotation(Include="
#ifndef __OMC_FILE_TELL
#define __OMC_FILE_TELL
#include <stdio.h>

#ifndef __OMC_FILE_STRUCT
#define __OMC_FILE_STRUCT
typedef struct {
  FILE* file /* the file */;
  mmc_sint_t cnt /* reference count */;
  char* name /* the file name */;
} __OMC_FILE;
#endif

static inline int om_file_tell(__OMC_FILE *file)
{
  if (!file->file) {
    return -1;
  }
  return ftell(file->file);
}
#endif
");
end tell;

function getFilename
  input Option<Integer> file;
  output String fileName;
external "C" fileName = om_file_get_filename(file) annotation(Include="
#ifndef __OMC_FILE_FILENAME
#define __OMC_FILE_FILENAME
#include <stdio.h>

#ifndef __OMC_FILE_STRUCT
#define __OMC_FILE_STRUCT
typedef struct {
  FILE* file /* the file */;
  mmc_sint_t cnt /* reference count */;
  char* name /* the file name */;
} __OMC_FILE;
#endif

static inline void* om_file_get_filename(__OMC_FILE *file)
{
#if __OMC_FILE_DEBUG
  fprintf(stderr,\"File.getFilename: %s, %p %p\\n\", file->name, file->file, file); fflush(NULL);
#endif
  return mmc_mk_scon(file->name);
}
#endif
");
end getFilename;

function getReference
  input File file;
  output Option<Integer> reference;
external "C" reference = om_file_get_reference(file) annotation(Include="
#ifndef __OMC_FILE_REFERENCE
#define __OMC_FILE_REFERENCE
#include <stdio.h>

#ifndef __OMC_FILE_STRUCT
#define __OMC_FILE_STRUCT
typedef struct {
  FILE* file /* the file */;
  mmc_sint_t cnt /* reference count */;
  char* name /* the file name */;
} __OMC_FILE;
#endif

static inline void* om_file_get_reference(__OMC_FILE *file)
{
#if __OMC_FILE_DEBUG
  fprintf(stderr,\"File.getReference: %s, %p %p\\n\", file->name, file->file, file); fflush(NULL);
#endif
  file->cnt++;
  return file;
}
#endif
");
end getReference;

function releaseReference
  input File file;
external "C" om_file_release_reference(file) annotation(Include="
#ifndef __OMC_FILE_RELEASE_REFERENCE
#define __OMC_FILE_RELEASE_REFERENCE
#include <stdio.h>

#ifndef __OMC_FILE_STRUCT
#define __OMC_FILE_STRUCT
typedef struct {
  FILE* file /* the file */;
  mmc_sint_t cnt /* reference count */;
  char* name /* the file name */;
} __OMC_FILE;
#endif

static inline void* om_file_release_reference(__OMC_FILE *file)
{
  file->cnt--;
  return file;
}
#endif
");
end releaseReference;

function writeSpace
  input File file;
  input Integer n;
algorithm
  for i in 1:n loop
    File.write(file, " ");
  end for;
end writeSpace;

package Examples

  model WriteToFile
    File file = File();
  initial algorithm
    open(file,"abc.txt",Mode.Write);
    write(file,"def.fafaf\n");
    writeEscape(file,"xx<def.\"\nfaf>af\n",escape=Escape.JSON);
  annotation(experiment(StopTime=0));
  end WriteToFile;

end Examples;

annotation(__OpenModelica_Interface="util");
end File;
