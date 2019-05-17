#pragma once
/** @addtogroup simcorefactoryOMCFactory
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <SimCoreFactory/OMCFactory/OMCFactory.h>

shared_ptr<ISimController> createSim(PATH library_path, PATH modelicasystem_path);

/**
 * Specialize OMCFactory for the creation of a statically linked simulator
 */
class StaticOMCFactory : public OMCFactory
{
  public:
    StaticOMCFactory()
      : OMCFactory() {}
    StaticOMCFactory(PATH library_path, PATH modelicasystem_path)
      : OMCFactory(library_path, modelicasystem_path) {}
    virtual shared_ptr<ISimController> createSimController()
    {
      return createSim("", "");
    }
    virtual shared_ptr<ISimController> loadSimControllerLib(PATH simcontroller_path, type_map simcontroller_type_map)
    {
      return createSim(_library_path, _modelicasystem_path);//(new SimController(_library_path,_modelicasystem_path));
    }
};
/** @} */ // end of simcorefactoryOMCFactory
