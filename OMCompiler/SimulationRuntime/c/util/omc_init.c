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

#include <stdio.h>
#include "omc_init.h"
#include "../meta/meta_modelica_segv.h"

#if !defined(OMC_NO_THREADS)
pthread_key_t mmc_thread_data_key = 0;
pthread_once_t mmc_init_once = PTHREAD_ONCE_INIT;
#else
threadData_t *OMC_MAIN_THREADDATA_NAME = 0;
#endif

void mmc_init_nogc()
{
  pthread_key_create(&mmc_thread_data_key,NULL);
#if !defined(OMC_MINIMAL_RUNTIME)
  /* Stack overflow detection is too expensive and fun for small targets
   * C-code is usually not generated for stack overflow detection anyway... */
  init_metamodelica_segv_handler();
#endif
}

#if defined(OMC_MINIMAL_RUNTIME)
void mmc_init()
{
  fprintf(stderr, "Error: called mmc_init (requesting garbage collection) when OMC was compiled with a minimal runtime system.");
  exit(1);
}
#else
#include "../gc/omc_gc.h"
void mmc_init()
{
  mmc_init_nogc();
  mmc_GC_init();
}
#endif
