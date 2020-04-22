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
