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

#include "omc_msvc.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#if defined(__MINGW32__) || defined(_MSC_VER)
int asprintf(char **strp, const char *fmt, ...) {
  int len;
  va_list ap;
  va_start(ap, fmt);

  len = vsnprintf(NULL, 0, fmt, ap);
  *strp = malloc(len+1);
  len = vsnprintf(*strp, len+1, fmt, ap);

  va_end(ap);
  return len;
}
#endif

#if defined(__MINGW32__) || defined(_MSC_VER)
#include <stdlib.h>
#include <string.h>
char *realpath(const char *path, char *resolved_path) {
  char buffer[_MAX_PATH];
  if ( _fullpath(resolved_path ? resolved_path : buffer, path, _MAX_PATH ) != NULL ) {
    return resolved_path ? resolved_path : strdup(buffer);
  } else {
    return NULL;
  }
}
#endif
