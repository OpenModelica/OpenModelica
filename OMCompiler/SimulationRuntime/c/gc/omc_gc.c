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


/*
 * Adrian Pop [Adrian.Pop@liu.se]
 * This file defines the MetaModelica garbage collector (GC) interface
 * We use Boehm GC mark-and-sweep collector.
 *
 *
 */

#include "../omc_simulation_settings.h"
#include "omc_gc.h"
#include "../util/omc_error.h"
#include "../util/omc_file.h"
#include "../util/omc_init.h"

static mmc_GC_state_type x_mmc_GC_state = {0};
mmc_GC_state_type *mmc_GC_state = &x_mmc_GC_state;

#if defined(OMC_RECORD_ALLOC_WORDS)
#include <stdlib.h>
#include <stdio.h>
#include "util/uthash.h"
#include <sys/types.h>
#include <unistd.h>

typedef struct {
  const char *pos; /* key */
  size_t count;
  UT_hash_handle hh;
} word_ht;

static const char *curPos="<nofile>:0";
static word_ht *table=NULL;
static size_t totalAlloc=0;
static void print_words()
{
  word_ht *entry, *tmp;
  pid_t pid = getpid();
  char str[50];
  sprintf(str, "omc-memory.%d.txt", pid);
  FILE *fout = omc_fopen(str, "w");
  HASH_ITER(hh, table, entry, tmp) {
    fprintf(fout, "%ld: %s\n", (long) entry->count, entry->pos);
  }
  fprintf(fout, "%ld: Total alloc\n", (long) totalAlloc);
  fclose(fout);
  printf("*** Printed memory consumption to file: %s\n", str);
}

void mmc_record_alloc_words(size_t n)
{
  static int init=0;
  word_ht *entry;
  totalAlloc += n;
  if (!init) {
    init=1;
    atexit(print_words);
  }
  HASH_FIND_STR(table, curPos, entry);
  if (entry) {
    entry->count += n;
    return;
  }
  entry = malloc(sizeof(word_ht));
  entry->pos = curPos;
  entry->count = n;
  HASH_ADD_KEYPTR( hh, table, entry->pos, strlen(entry->pos), entry);
}
void mmc_set_current_pos(const char *pos)
{
  curPos = pos;
}
#endif
void mmc_do_out_of_memory()
{
  threadData_t *threadData = (threadData_t*)pthread_getspecific(mmc_thread_data_key);
  FILE_INFO info = omc_dummyFileInfo;
#if (defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME))
  omc_assert(threadData, info, "Out of memory!");
#else
  omc_assert_warning(info, "Out of memory! Faking a stack overflow.");
  mmc_do_stackoverflow(threadData);
#endif
  abort();  // Silence invalid noreturn warning. This is never reached.
}

#if !(defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME))
/* Work-around for Boehm GC not exposing the maximum heap size */
static size_t max_heap_size = 0;
void omc_GC_set_max_heap_size(size_t sz)
{
  max_heap_size = sz;
  GC_set_max_heap_size(sz);
}
size_t omc_GC_get_max_heap_size()
{
  return max_heap_size;
}
#endif
