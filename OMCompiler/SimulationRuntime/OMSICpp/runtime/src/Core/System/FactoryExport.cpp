/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#if defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)
#include <Core/System/FactoryExport.h>
#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/System/AlgLoopSolverFactory.h>
#include <Core/System/SimVars.h>
#include <Core/System/SimObjects.h>
#include <Core/System/OSUSystem.h>
/*OMC factory*/
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {

  types.get<std::map<std::string, factory<IAlgLoopSolverFactory,shared_ptr<IGlobalSettings>,PATH,PATH> > >()
    ["AlgLoopSolverFactory"].set<AlgLoopSolverFactory>();
  types.get<std::map<std::string, factory<ISimVars,size_t,size_t,size_t,size_t,size_t,size_t,size_t> > >()
    ["SimVars"].set<SimVars>();
  types.get<std::map<std::string, factory<ISimVars,omsi_t*> > >()
	  ["SimVars2"].set<SimVars>();
  types.get<std::map<std::string, factory<ISimObjects,PATH,PATH,shared_ptr<IGlobalSettings> > > >()
    ["SimObjects"].set<SimObjects>();
  types.get<std::map<std::string, factory<IMixedSystem,shared_ptr<IGlobalSettings>,string > > >()
    ["OSUSystem"].set<OSUSystem>();

}
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Core/System/FactoryExport.h>
#include <Core/System/AlgLoopSolverFactory.h>
#include <Core/System/SimObjects.h>
#include <Core/System/SimVars.h>
 shared_ptr<IAlgLoopSolverFactory> createStaticAlgLoopSolverFactory(shared_ptr<IGlobalSettings> globalSettings,PATH library_path,PATH modelicasystem_path)
 {
     shared_ptr<IAlgLoopSolverFactory> algloopSolverFactory = shared_ptr<IAlgLoopSolverFactory>(new AlgLoopSolverFactory(globalSettings,library_path,modelicasystem_path));
     return algloopSolverFactory;
 }
shared_ptr<ISimObjects> createSimObjects(PATH library_path, PATH modelicasystem_path,shared_ptr<IGlobalSettings> settings)
{
  return shared_ptr<ISimObjects>(new SimObjects(library_path, modelicasystem_path,settings));
}

 shared_ptr<ISimVars>  createSimVarsFunction(size_t dim_real,size_t dim_int,size_t dim_bool,size_t dim_string,size_t dim_pre_vars,size_t dim_z,size_t z_i)
 {
      shared_ptr<ISimVars>  simvars = shared_ptr<ISimVars> (new SimVars( dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_z, z_i));
      return simvars;
 }

 shared_ptr<ISimVars>  createSimVarsFunction(omsi_t* omsu)
 {
	 shared_ptr<ISimVars>  simvars = shared_ptr<ISimVars>(new SimVars(omsu));
	 return simvars;
 }

#else
error "operating system not supported"
#endif

/** @} */ // end of coreSystem


