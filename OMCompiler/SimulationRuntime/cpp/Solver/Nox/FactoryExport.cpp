/** @addtogroup solverNox
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#if defined(OMC_BUILD)  && !defined(RUNTIME_STATIC_LINKING)
#include <NOX.H>
#include <Solver/Nox/NoxLapackInterface.h>
#include <Solver/Nox/Nox.h>
#include <Solver/Nox/NoxSettings.h>

using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<IAlgLoopSolver,INonLinSolverSettings*>,shared_ptr<INonLinearAlgLoop> > >()
    ["nox"].set<Nox>();
  types.get<std::map<std::string, factory<INonLinSolverSettings> > >()
    ["noxSettings"].set<NoxSettings>();
}
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <NOX.H>
#include <Solver/Nox/NoxLapackInterface.h>
#include <Solver/Nox/Nox.h>
#include <Solver/Nox/NoxSettings.h>
#else
error "operating system not supported"
#endif

#if defined(OMC_BUILD)  && defined(RUNTIME_STATIC_LINKING)
shared_ptr<INonLinSolverSettings> createNoxSettings()
{
 throw ModelicaSimulationError(ALGLOOP_SOLVER,"Nox was disabled during build");
}
shared_ptr<IAlgLoopSolver> createNoxSolver( shared_ptr<INonLinSolverSettings> solver_settings,shared_ptr<INonLinearAlgLoop> algLoop)
{
 throw ModelicaSimulationError(ALGLOOP_SOLVER,"Nox was disabled during build");
}
#endif
/** @} */ // end of solverNox
