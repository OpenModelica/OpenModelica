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

/** @addtogroup coreSimulationSettings
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks) || defined(__TRICORE__)



#include <Core/SimulationSettings/Factory.h>

extern "C" ISettingsFactory* createSettingsFactory(PATH library_path, PATH modelicasystem_path)
{
  return new SettingsFactory(library_path, library_path, modelicasystem_path);
}

#elif defined(SIMSTER_BUILD)


#include <Core/SimulationSettings/Factory.h>

/*Simster factory */
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_simulation_settings(boost::extensions::factory_map & fm)
{

  fm.get<ISettingsFactory,int,PATH,PATH,PATH>()[1].set<SettingsFactory>();
}

#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)



#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/SimulationSettings/Factory.h>

/*OMC facory*/
using boost::extensions::factory;
BOOST_EXTENSION_TYPE_MAP_FUNCTION {

  types.get<std::map<std::string, boost::extensions::factory<ISettingsFactory,PATH,PATH,PATH> > >()
    ["SettingsFactory"].set<SettingsFactory>();
}
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Core/SimulationSettings/Factory.h>
shared_ptr<ISettingsFactory> createFactory(PATH libraries_path, PATH config_path, PATH modelicasystem_path)
{
    shared_ptr<ISettingsFactory> setttingsFactory =  shared_ptr<ISettingsFactory>(new SettingsFactory(libraries_path,config_path,modelicasystem_path));
    return setttingsFactory;
}

#else
error "operating system not supported"
#endif
/** @} */ // end of coreSimulationSettings
