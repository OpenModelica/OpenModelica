/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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
 * from LinkÃ¶pings University, either from the above address,
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

#include "modelica.h"

char* _replace(const char* source_str,
               const char* search_str,
               const char* replace_str);

typedef int (*function_t)(type_description*, type_description*);

#if defined(__MINGW32__) || defined(_MSC_VER)
 #define WIN32_LEAN_AND_MEAN
 #include <Windows.h>
struct modelica_ptr_s {
  union {
    struct {
      function_t handle;
      modelica_integer lib;
    } func;
    HMODULE lib;
  } data;
  int cnt; // not unsigned as 0-1 would be a huge number if you call freeLibrary several times!
};
#else
struct modelica_ptr_s {
  union {
    struct {
      function_t handle;
      modelica_integer lib;
    } func;
    void *lib;
  } data;
  unsigned int cnt;
};
#endif

typedef struct modelica_ptr_s *modelica_ptr_t;
modelica_ptr_t lookup_ptr(modelica_integer index);


