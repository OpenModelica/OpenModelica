/*
  Copyright (c) 2010 ,
  Cloud Wu . All rights reserved.

  http://www.codingnow.com

  Use, modification and distribution are subject to the "New BSD License"
  as listed at <url: http://www.opensource.org/licenses/bsd-license.php >.
*/

#ifndef BACKTRACE_H
#define BACKTRACE_H

#ifdef QT_NO_DEBUG

#define GCC_VERSION (__GNUC__ * 10000 \
                     + __GNUC_MINOR__ * 100 \
		     + __GNUC_PATCHLEVEL__)

#ifdef WIN32
#ifdef __cplusplus
extern "C" {
#endif

#include <windows.h>
#include <excpt.h>
#include <imagehlp.h>
#if defined(__MINGW32__) && ((GCC_VERSION > 40900) || defined(__clang__))
#define PACKAGE OMEdit
#include <binutils/bfd.h>
#else
#include <bfd.h>
#endif
#include <psapi.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdbool.h>

#define BUFFER_MAX (16*1024)

struct bfd_ctx {
  bfd * handle;
  asymbol ** symbol;
};

struct bfd_set {
  char * name;
  struct bfd_ctx * bc;
  struct bfd_set *next;
};

struct find_info {
  asymbol **symbol;
  bfd_vma counter;
  const char *file;
  const char *func;
  unsigned line;
};

struct output_buffer {
  char * buf;
  size_t sz;
  size_t ptr;
};

void output_init(struct output_buffer *ob, char * buf, size_t sz);
void output_print(struct output_buffer *ob, const char * format, ...);
void _backtrace(struct output_buffer *ob, struct bfd_set *set, int depth , LPCONTEXT context);
void release_set(struct bfd_set *set);

#ifdef __cplusplus
} /* extern "C" */
#endif
#endif // #ifdef WIN32
#endif // #ifdef QT_NO_DEBUG
#endif // BACKTRACE_H
