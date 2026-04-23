/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#if !defined(_MSC_VER)
extern "C" {
#include "openmodelica.h"
#include "meta/meta_modelica.h"

#define ADD_METARECORD_DEFINITIONS static
#if defined(OMC_BOOTSTRAPPING)
  #include "../boot/tarball-include/OpenModelicaBootstrappingHeader.h"
#else
  #include "../OpenModelicaBootstrappingHeader.h"
#endif
}

#include "TaskGraphResultsCmp.cpp"
#else
#include "meta/meta_modelica.h"
#include "errorext.h"
#define TASKGRAPH_VS() c_add_message(NULL, -1, ErrorType_scripting, ErrorLevel_error, "TaskGraphResults not supported on Visual Studio.", NULL, 0);MMC_THROW();
#endif

extern "C" {
void* TaskGraphResults_checkTaskGraph(const char *filename,const char *reffilename)
{
#if defined(_MSC_VER)
  TASKGRAPH_VS();
#else
  return TaskGraphResultsCmp_checkTaskGraph(filename,reffilename);
#endif
}

void* TaskGraphResults_checkCodeGraph(const char *filename,const char *reffilename)
{
#if defined(_MSC_VER)
  TASKGRAPH_VS();
#else
  return TaskGraphResultsCmp_checkCodeGraph(filename,reffilename);
#endif
}

}

