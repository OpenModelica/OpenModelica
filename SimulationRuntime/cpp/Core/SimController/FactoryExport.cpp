/** @addtogroup coreSimcontroller
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks) || defined(__TRICORE__)



#include <Core/SimController/SimController.h>

extern "C" ISimController* createSimController(PATH library_path, PATH modelicasystem_path)
{
  return new SimController(library_path, modelicasystem_path);
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

#elif defined(OMC_BUILD)



#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/SimController/ISimController.h>
#include <Core/SimController/SimController.h>

/*OMC factory*/
using boost::extensions::factory;
BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<ISimController,PATH,PATH> > >()
    ["SimController"].set<SimController>();

}

#else
error "operating system not supported"
#endif
/** @} */ // end of coreSimcontroller