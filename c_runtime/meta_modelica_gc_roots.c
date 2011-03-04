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

#include "modelica.h"

/* create the roots structure */
mmc_GC_roots_type roots_create(long default_roots_size)
{
  mmc_GC_roots_type roots = {0, 0, 0, 0};
  long sz = sizeof(modelica_metatype) * default_roots_size;

  roots.start = (modelica_metatype*)malloc(sz);
  if (!roots.start)
  {
    fprintf(stderr, "not enough memory to allocate the roots array!\n");
    fflush(NULL);
    assert(roots.start != 0);
  }
  /* the current index points to the start at the begining! */
  roots.current = roots.start;
  /* the limit points to the end of the roots array */
  roots.limit   = roots.start + sz;

  return roots;
}

/* realloc the roots structure */
mmc_GC_roots_type roots_realloc(mmc_GC_roots_type roots, long default_roots_size)
{
  long sz = (roots.limit - roots.start) + sizeof(modelica_metatype) * default_roots_size;
  long current = (roots.current - roots.start);

  /* reallocate! */
  roots.start = (modelica_metatype*)realloc(roots.start, sz);
  if (!roots.start)
  {
    fprintf(stderr, "not enough memory to re-allocate the roots array!\n");
    fflush(NULL);
    assert(roots.start != 0);
  }

  /* the current index now points to start + current size */
  roots.current = roots.start + current;
  /* the limit points to the end of the roots array */
  roots.limit   = roots.start + sz;

  return roots;
}
