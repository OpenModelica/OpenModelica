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

#if  defined(__MINGW32__) || defined(_MSC_VER)
#include <windows.h>
#define UPC_DA
#endif

void no_embedded_server_init(DATA *data, double tout, double step, const char *argv_0)
{
}

void no_embedded_server_deinit()
{
}

void no_embedded_server_update(double tout)
{
}

void (*embedded_server_init)(DATA *data, double tout, double step, const char *argv_0) = no_embedded_server_init;
void (*embedded_server_deinit)() = no_embedded_server_deinit;
// Tells the embedded server that a simulation step has passed; the server
// can read/write values from/to the simulator
void (*embedded_server_update)(double tout) = no_embedded_server_update;

void embedded_server_load_functions()
{
  fprintf(stderr, "embedded_server_load_functions\n");
#if defined(UPC_DA)
  const char *dllFile = "C:\\OpenModelica\\OMCompiler\\SimulationRuntime\\opc\\da\\libomopcda.dll";
  HINSTANCE dll = LoadLibrary(dllFile);
  void *funcInit, *funcDeinit, *funcUpdate;

  if (dll == NULL) {
    infoStreamPrint(LOG_DEBUG, 0, "Failed to load dll: %s\n", dllFile);
    return;
  }

  funcInit = GetProcAddress(dll, "opc_da_init");
  if (!funcInit) {
    infoStreamPrint(LOG_DEBUG, 0, "Failed to load function opc_da_init\n");
    return;
  }
  funcDeinit = GetProcAddress(dll, "opc_da_deinit");
  if (!funcDeinit) {
    infoStreamPrint(LOG_DEBUG, 0, "Failed to load function opc_da_deinit\n");
    return;
  }
  funcUpdate = GetProcAddress(dll, "opc_da_new_iteration");
  if (!funcUpdate) {
    infoStreamPrint(LOG_DEBUG, 0, "Failed to load function opc_da_new_iteration\n");
    return;
  }
  embedded_server_init = funcInit;
  embedded_server_deinit = funcDeinit;
  embedded_server_update = funcUpdate;
  infoStreamPrint(LOG_DEBUG, 0, "Using embedded server=opc_da\n");
#endif
}
