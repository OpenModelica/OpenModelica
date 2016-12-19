/** @addtogroup solverNox
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#if defined(__vxworks) || defined(__TRICORE__)
#include <NOX.H>
#include <Solver/Nox/NoxLapackInterface.h>
#include <Solver/Nox/Nox.h>
#include <Solver/Nox/NoxSettings.h>

extern "C" IAlgLoopSolver* createNox(INonLinearAlgLoop* algLoop, INonLinSolverSettings* settings)
{
    return new Nox(algLoop, settings);
}

extern "C" INonLinSolverSettings* createNoxSettings()
{
    return new NoxSettings();
}

#elif defined(SIMSTER_BUILD)

#elif defined(OMC_BUILD)  && !defined(RUNTIME_STATIC_LINKING)
#include <NOX.H>
#include <Solver/Nox/NoxLapackInterface.h>
#include <Solver/Nox/Nox.h>
#include <Solver/Nox/NoxSettings.h>

using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<IAlgLoopSolver,INonLinearAlgLoop*, INonLinSolverSettings*> > >()
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
shared_ptr<IAlgLoopSolver> createNoxSolver(INonLinearAlgLoop* algLoop, shared_ptr<INonLinSolverSettings> solver_settings)
{
 throw ModelicaSimulationError(ALGLOOP_SOLVER,"Nox was disabled during build");
}
#endif
/** @} */ // end of solverNox
