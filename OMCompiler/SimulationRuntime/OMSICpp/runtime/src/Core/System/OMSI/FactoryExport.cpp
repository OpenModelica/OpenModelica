/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#if defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)
#include <Core/System/FactoryExport.h>
#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/System/OMSUSystem.h>
/*OMC factory*/
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {

  types.get<std::map<std::string, factory<IMixedSystem,shared_ptr<IGlobalSettings>,string > > >()
    ["OMSUSystem"].set<OMSUSystem>();

}
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Core/System/FactoryExport.h>


#else
error
"operating system not supported"
#endif

/** @} */ // end of coreSystem
