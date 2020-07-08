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
