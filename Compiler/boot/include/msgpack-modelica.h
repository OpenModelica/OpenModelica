/*
Copyright (c) 2014, Martin Sjölund
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef __MSGPACK_MODELICA_H
#define __MSGPACK_MODELICA_H

/* You can specify -DHAVE_MMAP=0 or -DHAVE_MMAP=1 to enable/disable the mmap implementation
 * Else we auto-detect mmap using _POSIX_MAPPED_FILES in unistd.h
 */
#if !defined(HAVE_MMAP)
#if defined(unix)
#include <unistd.h>
#endif
#if _POSIX_MAPPED_FILES>0
#define HAVE_MMAP 1
#else
#define HAVE_MMAP 0
#endif
#endif

#include <msgpack.h>
#include <stdio.h>
#include <errno.h>
#include <ModelicaUtilities.h>

#if HAVE_MMAP
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#endif



typedef struct {
  msgpack_unpacked msg;
  int fd;
  void *ptr;
  size_t size;
} s_deserializer;

typedef struct {
  FILE *fout;
  int isStringBuffer;
  char *str;
  size_t size;
} s_stream;

static inline int msgpack_modelica_pack_map(void *packer, int len)
{
  return msgpack_pack_map(packer,len);
}

static inline void* msgpack_modelica_packer_new_sbuffer(void *sbuffer)
{
  return msgpack_packer_new(sbuffer, msgpack_sbuffer_write);
}

static inline int msgpack_modelica_pack_array(void *packer, int len)
{
  return msgpack_pack_array(packer,len);
}

static inline int msgpack_modelica_pack_string(void* packer, const char *str)
{
  size_t len = strlen(str);
  if (msgpack_pack_raw(packer,len)) {
    return 1;
  }
  return msgpack_pack_raw_body(packer,str,len);
}

static inline void omc_sbuffer_to_file(void *ptr, const char *file)
{
  msgpack_sbuffer* buffer = (msgpack_sbuffer*) ptr;
  FILE *fout = fopen(file, "w");
  if (!fout) {
    ModelicaFormatError("Failed to open file %s for writing\n", file);
  }
  if (1 != fwrite(buffer->data, buffer->size, 1, fout)) {
    ModelicaFormatError("Failed to write to file %s\n", file);
  }
  fclose(fout);
}

static inline int omc_sbuffer_position(void *ptr)
{
  msgpack_sbuffer* buffer = (msgpack_sbuffer*) ptr;
  return buffer->size;
}

static void unpack_print(FILE *fout, const void *ptr, size_t size) {
  size_t off = 0;
  msgpack_unpacked msg;
  msgpack_unpacked_init(&msg);
  while (msgpack_unpack_next(&msg, ptr, size, &off)) {
    msgpack_object root = msg.data;
    msgpack_object_print(fout,root);
    fputc('\n',fout);
  }
  msgpack_unpacked_destroy(&msg);
}

static void* msgpack_modelica_new_deserialiser(const char *file)
{
  s_deserializer *deserializer = (s_deserializer*) malloc(sizeof(s_deserializer));
  char *mapped;
  /* The msgpack api uses raw data, and  mmap is nice if we want to use random access in the file */
#if HAVE_MMAP
  struct stat s;
  int fd;
  fd = open(file, O_RDONLY);
  if (fd < 0) {
    ModelicaFormatError("Failed to open file %s for reading: %s\n", file, strerror(errno));
  }
  if (fstat(fd, &s) < 0) {
    close(fd);
    ModelicaFormatError("fstat %s failed: %s\n", file, strerror(errno));
  }
  mapped = mmap(0, s.st_size, PROT_READ, MAP_SHARED, fd, 0);
  if (mapped == MAP_FAILED) {
    close(fd);
    ModelicaFormatError("mmap(file=\"%s\",fd=%d,size=%ld) failed: %s\n", file, fd, (long) s.st_size, strerror(errno));
  }
  deserializer->fd = fd;
  deserializer->size = s.st_size;
#else
  size_t sz;
  FILE *fin = fopen(file, "r");
  fseek(fin, 0, SEEK_END);
  sz = ftell(fin);
  fseek(fin, 0, SEEK_SET);
  mapped = malloc(sz + 1);
  if (1 != fread(mapped, sz, 1, fin)) {
    free(mapped);
    fclose(fin);
    ModelicaFormatError("Failed to read contents of size %ld in %s\n", (long) sz, file);
  }
  fclose(fin);
  mapped[sz] = 0;
  deserializer->fd = -1;
  deserializer->size = sz;
#endif
  msgpack_unpacked_init(&deserializer->msg);
  deserializer->ptr = mapped;
  return deserializer;
}

static inline void msgpack_modelica_free_deserialiser(void *ptr)
{
  s_deserializer *deserializer = (s_deserializer*) ptr;
  msgpack_unpacked_destroy(&deserializer->msg);
#if HAVE_MMAP
  munmap(deserializer->ptr, deserializer->size);
  close(deserializer->fd);
#else
  free(deserializer->ptr);
#endif
  free(ptr);
}

static inline int msgpack_modelica_unpack_next(void *ptr, int offset, int *newoffset)
{
  s_deserializer *deserializer = (s_deserializer*) ptr;
  size_t off = offset;
  int res = msgpack_unpack_next(&deserializer->msg, deserializer->ptr, deserializer->size, &off);
  *newoffset = off;
  return res;
}

static int msgpack_modelica_unpack_int(void *ptr, int offset, int *newoffset, int *success)
{
  s_deserializer *deserializer = (s_deserializer*) ptr;
  size_t off = offset;
  *success = msgpack_unpack_next(&deserializer->msg, deserializer->ptr, deserializer->size, &off);
  if (!*success) {
    ModelicaError("Failed to unpack object\n");
  }
  *newoffset = off;
  if (deserializer->msg.data.type == MSGPACK_OBJECT_POSITIVE_INTEGER) {
    return deserializer->msg.data.via.u64;
  } else if (deserializer->msg.data.type == MSGPACK_OBJECT_NEGATIVE_INTEGER) {
    return deserializer->msg.data.via.i64;
  } else {
    ModelicaError("Object is not of integer type\n");
  }
}

static const char* msgpack_modelica_unpack_string(void *ptr, int offset, int *newoffset, int *success)
{
  s_deserializer *deserializer = (s_deserializer*) ptr;
  size_t off = offset;
  *success = msgpack_unpack_next(&deserializer->msg, deserializer->ptr, deserializer->size, &off);
  if (!*success) {
    ModelicaError("Failed to unpack object\n");
  }
  *newoffset = off;
  if (deserializer->msg.data.type == MSGPACK_OBJECT_RAW) {
    size_t sz = deserializer->msg.data.via.raw.size;
    char *res = ModelicaAllocateString(sz);
    memcpy(res, deserializer->msg.data.via.raw.ptr, sz);
    return res;
  } else {
    ModelicaError("Object is not of integer type\n");
  }
}

static inline int msgpack_modelica_get_unpacked_int(void *ptr)
{
  s_deserializer *deserializer = (s_deserializer*) ptr;
  return deserializer->msg.data.via.i64;
}

static int msgpack_modelica_unpack_next_to_stream(void *ptr1, void *ptr2, int offset, int *newoffset)
{
  s_deserializer *deserializer = (s_deserializer*) ptr1;
  s_stream *st = (s_stream *) ptr2;
  size_t off = offset;
  if (msgpack_unpack_next(&deserializer->msg, deserializer->ptr, deserializer->size, &off)) {
    msgpack_object root = deserializer->msg.data;
    msgpack_object_print(st->fout,root);
    *newoffset = off;
    return 1;
  } else {
    *newoffset = off;
    return 0;
  }
}

static void* msgpack_modelica_new_stream(const char *filename)
{
  s_stream *st = (s_stream *) malloc(sizeof(s_stream));
  st->str = 0;
  st->size = 0;
  st->isStringBuffer = 0 == *filename;
  if (st->isStringBuffer) {
#if HAVE_OPEN_MEMSTREAM
    st->fout = open_memstream(&st->str,&st->size);
#else
    ModelicaError("String streams are not implemented for this platform\n");
#endif
  } else {
    st->fout = fopen(filename, "wb");
  }
  if (!st->fout) {
    free(st);
    ModelicaFormatError("msgpack_modelica_new_stream(%s) failed\n", filename);
  }
  return st;
}

static inline void msgpack_modelica_free_stream(void *ptr)
{
  s_stream *st = (s_stream *) ptr;
  fclose(st->fout);
  free(st->str);
  free(st);
}

static char* msgpack_modelica_stream_get(void *ptr)
{
#if HAVE_OPEN_MEMSTREAM
  char *res;
  s_stream *st = (s_stream *) ptr;
  if (!st->isStringBuffer) {
    ModelicaError("Cannot get stream contents for file streams.\n");
  }
  fclose(st->fout);
  res = ModelicaAllocateStringWithErrorReturn(st->size);
  memcpy(res,st->str,st->size);
  free(st->str);
  if (!res) {
    ModelicaError("Failed to allocate memory for stream\n");
  }
  st->str = 0;
  st->size = 0;
  st->fout = open_memstream(&st->str,&st->size);
  return res;
#else
  ModelicaError("String streams are not implemented for this platform\n");
#endif
}

static inline void msgpack_modelica_stream_append(void *ptr, const char *str)
{
  s_stream *st = (s_stream *) ptr;
  fputs(str, st->fout);
}

#endif
