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

#include "systemimpl.c"

extern "C" {

extern int System__regularFileExists(const char* str)
{
  fprintf(stderr, "NYI: %s\n", __FUNCTION__);
  return SystemImpl__regularFileExists(str);
}

extern void writeFile(const char* filename, const char* data)
{
  fprintf(stderr, "NYI: %s\n", __FUNCTION__);
  if (SystemImpl__writeFile(filename, data))
    throw 1;
}

extern char* System__readFile(const char* filename)
{
  fprintf(stderr, "NYI: %s\n", __FUNCTION__);
  return SystemImpl__readFile(filename);
}

extern const char* System__stringReplace(const char* str, const char* source, const char* target)
{
  char* res = _replace(str,source,target);
  if (res == NULL)
    throw 1;
  return res;
}

extern int System__stringFind(const char* str, const char* searchStr)
{
  return SystemImpl__stringFind(str, searchStr);
}

}
