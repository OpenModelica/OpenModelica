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
 * This file implements GC roots
 *
 * RCS: $Id: meta_modelica_gc_roots.c 8047 2011-03-01 10:19:49Z perost $
 *
 */

#include "openmodelica.h"
#include "meta_modelica.h"

/* create the roots structure */
mmc_GC_roots_type roots_create(size_t default_roots_size, size_t default_roots_mark_size)
{
  mmc_GC_roots_type roots = {0, 0, 0, 0};
  size_t sz = sizeof(modelica_metatype) * default_roots_size;

  roots.start = (modelica_metatype*)malloc(sz);
  if (!roots.start)
  {
    fprintf(stderr, "not enough memory (%lu) to allocate the roots array!\n", sz);
    fflush(NULL);
    assert(roots.start != 0);
  }
  /* the current index points to the start at the begining! */
  roots.current = 0;
  /* the limit points to the end of the roots array */
  roots.limit   = default_roots_size;

  roots.marks            = stack_create(default_roots_mark_size); 
  roots.rootsStackIndex  = 0;  /* set the stack element index to 0 */

  return roots;
}

/* realloc and increase the roots structure */
mmc_GC_roots_type roots_increase(mmc_GC_roots_type roots, size_t default_roots_size)
{
  size_t sz = (roots.limit + default_roots_size) * sizeof(modelica_metatype);
  size_t current = roots.current;

  /* reallocate! */
  roots.start = (modelica_metatype*)realloc(roots.start, sz);
  if (!roots.start)
  {
    fprintf(stderr, "not enough memory (%lu) to re-allocate the roots array!\n", sz);
    fflush(NULL);
    assert(roots.start != 0);
  }

  /* the current index now points to start + current size */
  roots.current = current;
  /* the limit points to the end of the roots array */
  roots.limit   += default_roots_size;

  return roots;
}

/* realloc and decrease the roots structure */
mmc_GC_roots_type roots_decrease(mmc_GC_roots_type roots, size_t default_roots_size)
{
  size_t sz = 0;
  size_t current = roots.current;
  /*
   * do not shrink roots if roots.current is less than default_roots_size
   * and 2 * default_roots_size > roots.limits
   */
  if (roots.current < default_roots_size)
  {
    return roots;
  }
  if (roots.current * 3 < roots.limit)
  {
    sz =  roots.current * 2;
  }
  else
  {
    return roots;
  }

  /* reallocate! */
  roots.start = (modelica_metatype*)realloc(roots.start, sz * sizeof(void*));
  if (!roots.start)
  {
    fprintf(stderr, "not enough memory (%lu) to re-allocate the roots array!\n", sz * sizeof(void*));
    fflush(NULL);
    assert(roots.start != 0);
  }
  /* the current index now points to start + current size */
  roots.current = current;
  /* the limit points to the end of the roots array */
  roots.limit   = sz;

  return roots;
}
