/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * Adrian Pop [Adrian.Pop@liu.se]
 * This file implements GC settings 
 *
 * RCS: $Id: meta_modelica_gc_settings.h 8047 2011-03-01 10:19:49Z perost $
 *
 */


#ifndef META_MODELICA_GC_SETTINGS_H_
#define META_MODELICA_GC_SETTINGS_H_

#include "modelica.h"

#if defined(__cplusplus)
extern "C" {
#endif

/* defaults */

#define MMC_GC_NUMBER_OF_MARK_THREADS  6
#define MMC_GC_NUMBER_OF_SWEEP_THREADS 6

#define MMC_GC_PAGE_SIZE           64*1024*1024  /* default page size 160MB chunks, can be changed */
#define MMC_GC_NUMBER_OF_PAGES                1  /* default number of pages at start */
#define MMC_GC_PAGES_SIZE_INITIAL          1024  /* default size for pages array at start, realloc on full */

#define MMC_GC_FREE_SIZES                     1  /* small object with size until max 101 */
#define MMC_GC_FREE_SLOTS_SIZE_INITIAL        1  /* for big objects */

#define MMC_GC_ROOTS_SIZE_INITIAL        8*1024  /* initial size of roots, reallocate on full */
#define MMC_GC_ROOTS_MARKS_SIZE_INITIAL  8*1024  /* initial size of roots marks, reallocate on full */

struct mmc_GC_settings_type
{
  size_t    number_of_pages;  /* the initial number of pages */
  size_t    pages_size;       /* the default pages array size */
  size_t    page_size;        /* the default page size */
  size_t    free_slots_size;  /* the default free slots array size */
  size_t    roots_size;       /* the default size of the array of roots */
  size_t    roots_marks_size; /* the default size of marks in the array of roots */
  size_t    number_of_mark_threads;  /* the initial number of mark threads */
  size_t    number_of_sweep_threads; /* the initial number of sweep threads */
};
typedef struct mmc_GC_settings_type mmc_GC_settings_type;

extern mmc_GC_settings_type mmc_GC_settings_default;

/* create the settings */
mmc_GC_settings_type settings_create(
  size_t    number_of_pages,
  size_t    pages_size,
  size_t    page_size,
  size_t    free_slots_size,
  size_t    roots_size,
  size_t    roots_marks_size,
  size_t    number_of_mark_threads,
  size_t    number_of_sweep_threads);

#if defined(__cplusplus)
}
#endif

#endif /* #define META_MODELICA_GC_SETTINGS_H_ */

