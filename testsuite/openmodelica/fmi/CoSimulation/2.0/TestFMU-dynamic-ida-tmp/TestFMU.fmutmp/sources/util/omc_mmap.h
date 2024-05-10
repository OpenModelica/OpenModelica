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

#if !defined(OMC_MMAP_H_) && !defined(OMC_NO_FILESYSTEM)
#define OMC_MMAP_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "../omc_simulation_settings.h"
#include <stdio.h>

#if !defined(HAVE_MMAP) && OMC_FMI_RUNTIME
#define HAVE_MMAP 0
#endif

#if !defined(HAVE_MMAP)
#if defined(unix) || defined(__APPLE__)
#include <unistd.h>
#endif
#if _POSIX_MAPPED_FILES>0
#define HAVE_MMAP 1
#else
#define HAVE_MMAP 0
#endif
#endif

#if HAVE_MMAP
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#endif

typedef struct {
  size_t size;
  const char *data;
} omc_mmap_read_unix;

typedef struct {
  size_t size;
  char *data;
} omc_mmap_write_unix;

typedef struct {
  size_t size;
  const char *data;
} omc_mmap_read_inmemory;

typedef struct {
  size_t size;
  FILE *file;
  char *data;
} omc_mmap_write_inmemory;

omc_mmap_read_inmemory omc_mmap_open_read_inmemory(const char *filename);
omc_mmap_write_inmemory omc_mmap_open_write_inmemory(const char *filename, size_t size);
void omc_mmap_close_read_inmemory(omc_mmap_read_inmemory map);
void omc_mmap_close_write_inmemory(omc_mmap_write_inmemory map);

#if HAVE_MMAP

omc_mmap_read_unix omc_mmap_open_read_unix(const char *filename);
omc_mmap_write_unix omc_mmap_open_write_unix(const char *filename, size_t size);
void omc_mmap_close_read_unix(omc_mmap_read_unix map);
void omc_mmap_close_write_unix(omc_mmap_write_unix map);

typedef omc_mmap_read_unix omc_mmap_read;
typedef omc_mmap_write_unix omc_mmap_write;
#define omc_mmap_open_read(X) omc_mmap_open_read_unix(X);
#define omc_mmap_open_write(X,Y) omc_mmap_open_write_unix(X,Y);
#define omc_mmap_close_read(X) omc_mmap_close_read_unix(X);
#define omc_mmap_close_write(X) omc_mmap_close_write_unix(X);

#else

typedef omc_mmap_read_inmemory omc_mmap_read;
typedef omc_mmap_write_inmemory omc_mmap_write;
#define omc_mmap_open_read(X) omc_mmap_open_read_inmemory(X);
#define omc_mmap_open_write(X,Y) omc_mmap_open_write_inmemory(X,Y);
#define omc_mmap_close_read(X) omc_mmap_close_read_inmemory(X);
#define omc_mmap_close_write(X) omc_mmap_close_write_inmemory(X);

#endif

#ifdef __cplusplus
}
#endif

#endif
