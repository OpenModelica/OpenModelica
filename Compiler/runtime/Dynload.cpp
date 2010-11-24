/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#if defined(_MSC_VER)
 #define WIN32_LEAN_AND_MEAN
 #include <Windows.h>
#endif

#include "errorext.h"
#include "meta_modelica.h"

extern "C" {

#include "systemimpl.h"
#include "rtopts.h"

static void *type_desc_to_value(type_description *desc);
static int value_to_type_desc(void *value, type_description *desc);
static int execute_function(void *in_arg, void **out_arg,
                            int (* func)(type_description *,
                                         type_description *));
static int parse_array(type_description *desc, void *arrdata, void *dimLst);


static int execute_function(void *in_arg, void **out_arg,
                            int (* func)(type_description *,
                                         type_description *))
{
  type_description arglst[RML_NUM_ARGS + 1], crashbuf[50], *arg = NULL;
  type_description crashbufretarg, retarg;
  void *v = NULL;
  int retval = 0;
  int debugFlag = check_debug_flag("dynload");
  state mem_state;

  mem_state = get_memory_state();

  if (debugFlag) { fprintf(stderr, "input parameters:\n"); fflush(stderr); }

  v = in_arg;
  arg = arglst;

  while (!listEmpty(v)) {
    void *val = RML_CAR(v);
    if (value_to_type_desc(val, arg)) {
      restore_memory_state(mem_state);
      if (debugFlag)
      {
        puttype(arg);
        fprintf(stderr, "returning from execute function due to value_to_type_desc failure!\n"); fflush(stderr);
      }
      return -1;
    }
    if (debugFlag) puttype(arg);
    ++arg;
    v = RML_CDR(v);
  }

  init_type_description(arg);
  init_type_description(&crashbufretarg);
  init_type_description(&retarg);
  init_type_description(&crashbuf[5]);

  retarg.retval = 1;

  if (debugFlag) { fprintf(stderr, "calling the function\n"); fflush(stderr); }
  
  /* call our function pointer! */
  try {
    func(arglst, &retarg);
    retval = 0;
  } catch (...) {
    retval = 1;
  }
  /* Flush all buffers for deterministic behaviour; in particular for the testsuite */
  fflush(NULL);

  /* free the type description for the input parameters! */
  arg = arglst;
  while (arg->type != TYPE_DESC_NONE) {
    free_type_description(arg);
    ++arg;
  }

  restore_memory_state(mem_state);

  if (retval) {
    *out_arg = Values__META_5fFAIL;
    return 0;
  } else {
    if (debugFlag) { fprintf(stderr, "output results:\n"); fflush(stderr); puttype(&retarg); }

    (*out_arg) = type_desc_to_value(&retarg);
    /* out_arg doesn't seem to get freed, something we can do anything about?
     * adrpo: 2009-09. it shouldn't be freed!
     */

    free_type_description(&retarg);

    if ((*out_arg) == NULL) {
      printf("Unable to parse returned values.\n");
      return -1;
    }

    return 0;
  }
}

}
