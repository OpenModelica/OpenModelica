/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/** @addtogroup coreSimcontroller
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks) || defined(__TRICORE__)



#include <Core/SimController/ISimController.h>
#include <Core/SimController/SimController.h>
#include <Core/SimController/SimObjects.h>

extern "C" ISimController* createSimController(PATH library_path, PATH modelicasystem_path)
{
  return new SimController(library_path, modelicasystem_path);
}

shared_ptr<ISimObjects> createSimObjects(PATH library_path, PATH modelicasystem_path,IGlobalSettings* settings)
{
  return shared_ptr<ISimObjects>(new SimObjects(library_path, modelicasystem_path,settings));
}

#elif defined(SIMSTER_BUILD)



#include <Core/SimController/ISimController.h>
#include <Core/SimController/SimController.h>
/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_simcontroller(boost::extensions::factory_map & fm)
{
  fm.get<ISimController,int,PATH,PATH>()[1].set<SimController>();
  // fm.get<ISimData,int>()[1].set<SimData>();
}

#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Core/SimController/ISimController.h>
#include <Core/SimController/SimController.h>
#include <Core/SimController/SimObjects.h>
/*OMC factory*/
using boost::extensions::factory;
BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<ISimController,PATH,PATH> > >()
    ["SimController"].set<SimController>();
 types.get<std::map<std::string, factory<ISimObjects,PATH,PATH,IGlobalSettings* > > >()
    ["SimObjects"].set<SimObjects>();
}

#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Core/SimController/ISimController.h>
#include <Core/SimController/SimController.h>
#include <Core/SimController/SimObjects.h>
shared_ptr<ISimController> createSimController(PATH library_path, PATH modelicasystem_path)
{
  return shared_ptr<ISimController>(new SimController(library_path, modelicasystem_path));
}

shared_ptr<ISimObjects> createSimObjects(PATH library_path, PATH modelicasystem_path,IGlobalSettings* settings)
{
  return shared_ptr<ISimObjects>(new SimObjects(library_path, modelicasystem_path,settings));
}
#else
error "operating system not supported"
#endif
/** @} */ // end of coreSimcontroller
