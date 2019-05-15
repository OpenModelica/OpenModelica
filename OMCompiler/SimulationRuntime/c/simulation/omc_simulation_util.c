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


#include "omc_simulation_util.h"
#include "../simulation_data.h"
#include "../util/utility.h"

extern modelica_string OpenModelica_fmuLoadResource(threadData_t *threadData, modelica_string path)
{
  DATA *data = (DATA*) threadData->localRoots[LOCAL_ROOT_SIMULATION_DATA];
  const char *resourcesDir=data->modelData->resourcesDir;
  return OpenModelica_uriToFilename_impl(threadData, path, resourcesDir);
}

extern const char* OpenModelica_parseFmuResourcePath(const char *path)
{
  if (0==strncmp(path, "file:", 5)) {
    path+=5;
    /* Ignore all / except the first one */
    while (path[0]=='/' && path[1]=='/') {
      path++;
    }
#if defined(__MINGW32__) || defined(_MSC_VER)
    if (strchr(path,':')) {
      while (path[0]=='/') {
        path++;
      }
    }
#endif
    return path;
  }
  return NULL;
}
