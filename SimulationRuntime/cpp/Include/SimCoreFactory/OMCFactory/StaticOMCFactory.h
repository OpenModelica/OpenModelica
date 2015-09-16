#pragma once
/** @addtogroup simcorefactoryOMCFactory
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

boost::shared_ptr<ISimController> createSimController(PATH library_path, PATH modelicasystem_path);

class StaticOMCFactory : public OMCFactory
{
  public:
    StaticOMCFactory() : OMCFactory() {}
    StaticOMCFactory(PATH library_path, PATH modelicasystem_path) : OMCFactory(library_path, modelicasystem_path) {};
    virtual ~StaticOMCFactory() {}

    void UnloadAllLibs() {}
    LOADERRESULT LoadLibrary(string libName, type_map& current_map)
    {
      return LOADER_SUCCESS;
    }

    LOADERRESULT UnloadLibrary(shared_library lib)
    {
      return LOADER_SUCCESS;
    }

    virtual boost::shared_ptr<ISimController> loadSimControllerLib(PATH simcontroller_path, type_map simcontroller_type_map)
    {
      return createSimController(_library_path, _modelicasystem_path);//(new SimController(_library_path,_modelicasystem_path));
    }
};
/** @} */ // end of simcorefactoryOMCFactory
