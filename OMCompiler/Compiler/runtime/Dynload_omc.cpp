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

#if defined(_MSC_VER) || defined(__MINGW32__)
 #define WIN32_LEAN_AND_MEAN
 #include <windows.h>
#endif

#include "openmodelica.h"
#include "meta/meta_modelica.h"

#define ADD_METARECORD_DEFINITIONS static
#if defined(OMC_BOOTSTRAPPING)
  #include "../boot/tarball-include/OpenModelicaBootstrappingHeader.h"
#else
  #include "../OpenModelicaBootstrappingHeader.h"
#endif

#include "Dynload.cpp"
#include "ModelicaUtilities.h"

extern void* DynLoad_executeFunction(threadData_t*  threadData, int _inFuncHandle, void* _inValLst, int _inPrintDebug)
{
  modelica_ptr_t func = NULL;
  int retval = -1;
  void *retarg = NULL;
  func = lookup_ptr(_inFuncHandle);
  if (func == NULL) MMC_THROW();

  retval = execute_function(threadData, _inValLst, &retarg, func->data.func.handle, _inPrintDebug);
  if (retval) MMC_THROW();
  return retarg;
}

#if !defined(OMC_GENERATE_RELOCATABLE_CODE)
extern void* omc_AbsynUtil_pathString(threadData_t*,void*,void*,int,int);
#else
extern void* (*omc_AbsynUtil_pathString)(threadData_t*,void*,void*,int,int);
#endif

static const char* path_to_name(void* path, char del)
{
  threadData_t *threadData = (threadData_t *) pthread_getspecific(mmc_thread_data_key);
  char delStr[2] = {del,'\0'};
  return MMC_STRINGDATA(omc_AbsynUtil_pathString(threadData, path, mmc_mk_scon(delStr), 0, 0));
}

}
