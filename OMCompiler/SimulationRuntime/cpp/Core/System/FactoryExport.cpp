/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks) || defined(__TRICORE__)


#include <SimCoreFactory/VxWorksFactory/VxWorksFactory.h>
#include <Core/System/AlgLoopSolverFactory.h>

extern "C" IAlgLoopSolverFactory* createAlgLoopSolverFactoryFunction(IGlobalSettings* globalSettings,PATH library_path,PATH modelicasystem_path)
//shared_ptr<IAlgLoopSolverFactory>   createAlgLoopSolverFactoryFunction(IGlobalSettings* globalSettings,PATH library_path,PATH modelicasystem_path)
{
    //shared_ptr<IAlgLoopSolverFactory> algloopSolverFactory = shared_ptr<IAlgLoopSolverFactory>(new AlgLoopSolverFactory(globalSettings,library_path,modelicasystem_path));
    //return algloopSolverFactory;
  return new AlgLoopSolverFactory(globalSettings,library_path,modelicasystem_path);
}

#elif defined(SIMSTER_BUILD)

#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/System/AlgLoopSolverFactory.h>

/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_system(boost::extensions::factory_map & fm)
{
  fm.get<IAlgLoopSolverFactory,int,IGlobalSettings*,PATH,PATH>()[1].set<AlgLoopSolverFactory>();
}

#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Core/System/FactoryExport.h>
#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/System/AlgLoopSolverFactory.h>
#include <Core/System/SimVars.h>
/*OMC factory*/
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {

  types.get<std::map<std::string, factory<IAlgLoopSolverFactory,IGlobalSettings*,PATH,PATH> > >()
    ["AlgLoopSolverFactory"].set<AlgLoopSolverFactory>();
  types.get<std::map<std::string, factory<ISimVars,size_t,size_t,size_t,size_t,size_t,size_t,size_t> > >()
    ["SimVars"].set<SimVars>();
}
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)

#include <Core/System/FactoryExport.h>
#include <Core/System/AlgLoopSolverFactory.h>
 shared_ptr<IAlgLoopSolverFactory> createStaticAlgLoopSolverFactory(IGlobalSettings* globalSettings,PATH library_path,PATH modelicasystem_path)
 {
     shared_ptr<IAlgLoopSolverFactory> algloopSolverFactory = shared_ptr<IAlgLoopSolverFactory>(new AlgLoopSolverFactory(globalSettings,library_path,modelicasystem_path));
     return algloopSolverFactory;
 }
#else
error "operating system not supported"
#endif

/** @} */ // end of coreSystem


