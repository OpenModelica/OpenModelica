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


extern "C" {

#include "modelica.h"
#include "rml_compatibility.h"
#include "OpenModelicaBootstrappingHeader.h"
#include "Dynload.cpp"

extern void* DynLoad_executeFunction(int _inFuncHandle, void* _inValLst)
{
  modelica_ptr_t func = NULL;
  int retval = -1;
  void *retarg = NULL;
  func = lookup_ptr(_inFuncHandle);
  if (func == NULL) MMC_THROW();

  retval = execute_function(_inValLst, &retarg, func->data.func.handle);
  if (retval) MMC_THROW();
  return retarg;
}

extern void* _Absyn_pathString2(void*,void*);
static const char* path_to_name(void* path, char del)
{
  char delStr[2] = {del,'\0'};
  return strdup(MMC_STRINGDATA(_Absyn_pathString2(path, mmc_mk_scon(delStr))));
}

}
