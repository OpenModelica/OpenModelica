/** @addtogroup coreSimcontroller
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#if  defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Core/SimController/ISimController.h>
#include <Core/SimController/SimController.h>
#include <Core/SimController/SimObjects.h>
/*OMC factory*/
using boost::extensions::factory;
BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<ISimController,PATH,PATH> > >()
    ["SimController"].set<SimController>();
types.get<std::map<std::string, factory<ISimController, PATH, PATH,bool> > >()
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
