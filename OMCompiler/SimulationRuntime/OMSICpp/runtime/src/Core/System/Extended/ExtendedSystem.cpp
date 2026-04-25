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


#include <Core/System/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#include <Core/System/ExtendedSystem.h>
#include <Core/System/ExtendedSimObjects.h>



ExtendedSystem::ExtendedSystem(shared_ptr<IGlobalSettings> globalSettings, string modelName,
                                                         size_t dim_real, size_t dim_int, size_t dim_bool,
                                                         size_t dim_string, size_t dim_pre_vars, size_t dim_z,
                                                         size_t z_i)
    :SystemDefaultImplementation(globalSettings, modelName, dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_z, z_i)
     , _omsu(NULL)
     
{
    _simObjects = shared_ptr<ISimObjects>(new ExtendedSimObjects(globalSettings->getRuntimeLibrarypath(),
        globalSettings->getRuntimeLibrarypath(), globalSettings));
   _simObjects->LoadSimVars(_modelName, dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_z, z_i);
      __z = _simObjects->getSimVars(modelName)->getStateVector();
    __zDot = _simObjects->getSimVars(modelName)->getDerStateVector();
}


ExtendedSystem::ExtendedSystem(shared_ptr<IGlobalSettings> globalSettings, string modelName,
                                                         omsi_t* omsu)
    : SystemDefaultImplementation(globalSettings, modelName)
      , _omsu(omsu)
{
   
    _simObjects = shared_ptr<ISimObjects>(new ExtendedSimObjects(globalSettings->getRuntimeLibrarypath(),
                                                         globalSettings->getRuntimeLibrarypath(), globalSettings));
    (dynamic_pointer_cast<IExtendedSimObjects>(_simObjects))->LoadSimVars(_modelName, _omsu);
  
    
}

ExtendedSystem::ExtendedSystem(shared_ptr<IGlobalSettings> globalSettings)
    :SystemDefaultImplementation(globalSettings)
{
 
    _simObjects = shared_ptr<ISimObjects>(new ExtendedSimObjects(globalSettings->getRuntimeLibrarypath(),
        globalSettings->getRuntimeLibrarypath(), globalSettings));
}

ExtendedSystem::ExtendedSystem(ExtendedSystem& instance)
    :SystemDefaultImplementation(instance)
{
}

shared_ptr<ISimData> ExtendedSystem::getSimData()
{
   
    return (dynamic_pointer_cast<IExtendedSimObjects>(_simObjects))->getSimData(_modelName);
   
   
}


ExtendedSystem::~ExtendedSystem()
{
   
}




/** @} */ // end of coreSystem

