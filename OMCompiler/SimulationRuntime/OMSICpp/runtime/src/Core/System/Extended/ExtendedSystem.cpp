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

