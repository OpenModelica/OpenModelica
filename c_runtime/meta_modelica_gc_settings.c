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
 * This file implements GC statistics
 *
 * RCS: $Id: meta_modelica_gc_settings.c 8047 2011-03-01 10:19:49Z perost $
 *
 */

#include "modelica.h"

mmc_GC_settings_type mmc_GC_settings_default = 
{
  MMC_GC_NUMBER_OF_PAGES,
  MMC_GC_PAGES_SIZE_INITIAL,
  MMC_GC_PAGE_SIZE,
  MMC_GC_FREE_SLOTS_SIZE_INITIAL,
  MMC_GC_ROOTS_SIZE_INITIAL,
  MMC_GC_ROOTS_MARKS_SIZE_INITIAL,
  MMC_GC_NUMBER_OF_MARK_THREADS, 
  MMC_GC_NUMBER_OF_SWEEP_THREADS
};

/* create the settings */
mmc_GC_settings_type settings_create(
  size_t    number_of_pages,
  size_t    pages_size,
  size_t    page_size,
  size_t    free_slots_size,
  size_t    roots_size,
  size_t    roots_marks_size,
  size_t    number_of_mark_threads,
  size_t    number_of_sweep_threads)
{
  mmc_GC_settings_type settings = {0};
  
  settings.number_of_pages = number_of_pages;
  settings.pages_size = pages_size;
  settings.page_size = page_size;
  settings.free_slots_size = free_slots_size;
  settings.roots_size = roots_size;
  settings.roots_marks_size = roots_marks_size;
  settings.number_of_mark_threads = number_of_mark_threads;
  settings.number_of_sweep_threads = number_of_sweep_threads;
  return settings;
}


