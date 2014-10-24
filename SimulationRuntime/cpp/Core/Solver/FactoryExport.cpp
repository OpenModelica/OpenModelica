#if defined(__vxworks) || defined(__TRICORE__)

#include <SimCoreFactory/Policies/FactoryConfig.h>

#elif defined(OMC_BUILD)

#include <Core/Modelica.h>
#include <SimCoreFactory/Policies/FactoryConfig.h>
#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/Solver/FactoryExport.h>

#include <Core/Solver/SolverDefaultImplementation.h>
#include <Core/Solver/SolverSettings.h>


/* OMC factory*/
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<SolverDefaultImplementation,IMixedSystem*, ISolverSettings*> > >()
    ["DefaultsolverImpl"].set<SolverDefaultImplementation>();
  types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
    ["SolverSettings"].set<SolverSettings>();
}
#elif defined(SIMSTER_BUILD)
#include <Core/Modelica.h>
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


