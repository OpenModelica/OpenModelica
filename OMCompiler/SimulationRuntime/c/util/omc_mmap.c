/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#if !defined(OMC_NO_FILESYSTEM)

#include "omc_mmap.h"
#include "omc_error.h"
#include "omc_file.h"
#include <string.h>
#include <errno.h>

#ifdef __cplusplus
extern "C" {
#endif

#if HAVE_MMAP

omc_mmap_read_unix omc_mmap_open_read_unix(const char *fileName)
{
  struct stat s;
  omc_mmap_read_unix res = {0};
  int fd = open(fileName, O_RDONLY);
  if (fd < 0) {
    throwStreamPrint(NULL, "Failed to open file %s for reading: %s\n", fileName, strerror(errno));
  }
  if (fstat(fd, &s) < 0) {
    close(fd);
    throwStreamPrint(NULL, "fstat %s failed: %s\n", fileName, strerror(errno));
  }
  res.size = s.st_size;
  res.data = (const char*) mmap(0, res.size, PROT_READ, MAP_SHARED, fd, 0);
  close(fd);
  if (res.data == MAP_FAILED) {
    throwStreamPrint(NULL, "mmap(file=\"%s\",fd=%d,size=%ld kB) failed: %s\n", fileName, fd, (long) s.st_size, strerror(errno));
  }
  return res;
}

omc_mmap_write_unix omc_mmap_open_write_unix(const char *fileName, size_t size)
{
  omc_mmap_write_unix res = {0};
  int fd = open(fileName, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
  if (fd < 0) {
    throwStreamPrint(NULL, "Failed to open file %s for reading: %s\n", fileName, strerror(errno));
  }
  if (size == 0) {
    struct stat s;
    if (fstat(fd, &s) < 0) {
      close(fd);
      throwStreamPrint(NULL, "fstat %s failed: %s\n", fileName, strerror(errno));
    }
    res.size = s.st_size;
  } else {
    res.size = size;
    lseek(fd, size, SEEK_SET);
  }
  res.data = res.size == 0 ? NULL : (char*) mmap(0, res.size, PROT_WRITE, MAP_SHARED, fd, 0);
  close(fd);
  if (res.data == MAP_FAILED) {
    throwStreamPrint(NULL, "mmap(file=\"%s\",fd=%d,size=%ld kB) failed: %s\n", fileName, fd, (long) res.size, strerror(errno));
  }
  return res;
}

void omc_mmap_close_read_unix(omc_mmap_read_unix map)
{
  munmap((void*)map.data, map.size);
}

void omc_mmap_close_write_unix(omc_mmap_write_unix map)
{
  munmap((void*)map.data, map.size);
}

#endif /* HAVE_MMAP */

static FILE* omc_mmap_common(const char *fileName, const char *mode, size_t *size, char **data)
{
  FILE *file = omc_fopen(fileName, mode);
  size_t fileSize;
  if (!file) {
    throwStreamPrint(NULL, "Failed to open file %s for reading: %s\n", fileName, strerror(errno));
  }
  fseek(file, 0, SEEK_END);
  fileSize = ftell(file);
  rewind(file);
  if (*size == 0) {
    *size = fileSize;
  }
  if (*size > fileSize) {
    *data = (char*) calloc(*size,1);
  } else {
    *data = (char*) malloc(*size);
  }

  omc_fread(*data, (*size > fileSize ? fileSize : *size), 1, file, 0);

  return file;
}

omc_mmap_read_inmemory omc_mmap_open_read_inmemory(const char *fileName)
{
  omc_mmap_read_inmemory res = {0};
  res.size = 0;
  fclose(omc_mmap_common(fileName, "rb", &res.size, (char**)&res.data));
  return res;
}

omc_mmap_write_inmemory omc_mmap_open_write_inmemory(const char *fileName, size_t size)
{
  omc_mmap_write_inmemory res = {0};
  res.size = size;
  res.file = omc_mmap_common(fileName, "rb+", &res.size, &res.data);
  return res;
}

void omc_mmap_close_read_inmemory(omc_mmap_read_inmemory map)
{
  free((void*)map.data);
}

void omc_mmap_close_write_inmemory(omc_mmap_write_inmemory map)
{
  rewind(map.file);
  if (1 != fwrite(map.data, map.size, 1, map.file)) {
    free(map.data);
    throwStreamPrint(NULL, "Failed to write back to file");
  }
  free((void*)map.data);
}


#ifdef __cplusplus
}
#endif

#endif /* OMC_NO_FILESYSTEM */
