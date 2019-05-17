/** @addtogroup coreSolver
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks) || defined(__TRICORE__)



#elif defined(OMC_BUILD)



#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/Solver/FactoryExport.h>

#include <Core/Solver/SolverDefaultImplementation.h>
#include <Core/Solver/SolverSettings.h>

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, boost::extensions::factory<SolverDefaultImplementation,IMixedSystem*, ISolverSettings*> > >()
    ["DefaultsolverImpl"].set<SolverDefaultImplementation>();
  types.get<std::map<std::string, boost::extensions::factory<ISolverSettings, IGlobalSettings* > > >()
    ["SolverSettings"].set<SolverSettings>();
}

#elif defined(SIMSTER_BUILD)


#include <Core/Solver/FactoryExport.h>
#include <Core/Solver/SolverDefaultImplementation.h>
#include <Core/Solver/SolverSettings.h>

/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_solver(boost::extensions::factory_map & fm)
{
  fm.get<SolverDefaultImplementation,int,IMixedSystem*, ISolverSettings*>()[1].set<SolverDefaultImplementation>();
  fm.get<ISolverSettings,int, IGlobalSettings* >()[1].set<SolverSettings>();
}

#else
error "operating system not supported"
#endif

 /** @} */ // end of coreSolver
