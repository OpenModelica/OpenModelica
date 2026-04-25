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

/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#if defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)
#include <Core/System/FactoryExport.h>
#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/System/ExtendedSimObjects.h>
#include <Core/System/ExtendedSimVars.h>
/*OMC factory*/
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {

  types.get<std::map<std::string, factory<IExtendedSimObjects,PATH,PATH,shared_ptr<IGlobalSettings> > > >()
    ["ExtendedSimObjects"].set<ExtendedSimObjects>();
   types.get<std::map<std::string, factory<ISimVars, omsi_t*> > >()
  ["ExtendedSimVars"].set<ExtendedSimVars>();

}
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Core/System/FactoryExport.h>
#include <Core/System/ExtendedSimObjects.h>
#include <Core/System/ExtendedSimVars.h>

shared_ptr<ISimObjects> createExtendedSimObjects(PATH library_path, PATH modelicasystem_path,shared_ptr<IGlobalSettings> settings)
{
  return shared_ptr<ISimObjects>(new ExtendedSimObjects(library_path, modelicasystem_path,settings));
}

shared_ptr<ISimVars>  createExtendedSimVarsFunction(omsi_t* omsu)
{
    shared_ptr<ISimVars>  simvars = shared_ptr<ISimVars>(new ExtendedSimVars(omsu));
    return simvars;
}



#else
error
"operating system not supported"
#endif

/** @} */ // end of coreSystem
