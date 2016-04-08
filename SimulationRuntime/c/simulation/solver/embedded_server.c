/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#include "embedded_server.h"

#if defined(__MINGW32__) || defined(_MSC_VER)
#include "util/omc_msvc.h"
#define UPC_DA
#define DLL_EXT ".dll"
#elif defined(__APPLE__)
#include <dlfcn.h>
#define DLL_EXT ".dylib"
#else
#include <dlfcn.h>
#define DLL_EXT ".so"
#endif

void* no_embedded_server_init(DATA *data, double tout, double step, const char *argv_0, void (*omc_real_time_sync_update)(DATA *data, double scaling))
{
  return NULL;
}

void no_embedded_server_deinit(void *handle)
{
}

void no_embedded_server_update(void *handle, double tout)
{
}

void* (*embedded_server_init)(DATA *data, double tout, double step, const char *argv_0, void (*omc_real_time_sync_update)(DATA *data, double scaling)) = no_embedded_server_init;
void (*embedded_server_deinit)(void*) = no_embedded_server_deinit;
// Tells the embedded server that a simulation step has passed; the server
// can read/write values from/to the simulator
void (*embedded_server_update)(void*, double tout) = no_embedded_server_update;

void* embedded_server_load_functions(const char *server_name)
{
  void *dll, *funcInit, *funcDeinit, *funcUpdate;
  if (NULL==server_name || 0==strcmp("none", server_name)) {
    return NULL;
  }
  if (0==strcmp("opc-ua", server_name)) {
    server_name = "libomopcua" DLL_EXT;
  } else if (0==strcmp("opc-da", server_name)) {
#if defined(UPC_DA)
    server_name = "libomopcda" DLL_EXT;
#else
    errorStreamPrint(LOG_DEBUG, 0, "OPC DA interface is not available on this platform (requires WIN32)");
    MMC_THROW();
#endif
  }
  infoStreamPrint(LOG_DEBUG, 0, "Try to load embedded server %s", server_name);
  dll = dlopen(server_name, RTLD_LAZY);

  if (dll == NULL) {
    errorStreamPrint(LOG_DEBUG, 0, "Failed to load shared object %s: %s\n", server_name, dlerror());
    MMC_THROW();
  }

  funcInit = dlsym(dll, "omc_embedded_server_init");
  if (!funcInit) {
    errorStreamPrint(LOG_DEBUG, 0, "Failed to load function opc_da_init: %s\n", dlerror());
    MMC_THROW();
  }
  funcDeinit = dlsym(dll, "omc_embedded_server_deinit");
  if (!funcDeinit) {
    errorStreamPrint(LOG_DEBUG, 0, "Failed to load function opc_da_deinit: %s\n", dlerror());
    MMC_THROW();
  }
  funcUpdate = dlsym(dll, "omc_embedded_server_update");
  if (!funcUpdate) {
    errorStreamPrint(LOG_DEBUG, 0, "Failed to load function opc_da_new_iteration: %s\n", dlerror());
    MMC_THROW();
  }
  embedded_server_init = funcInit;
  embedded_server_deinit = funcDeinit;
  embedded_server_update = funcUpdate;
  infoStreamPrint(LOG_DEBUG, 0, "Loaded embedded server");
  return dll;
}

void embedded_server_unload_functions(void *dllHandle)
{
  if (dllHandle) {
    dlclose(dllHandle);
  }
}
