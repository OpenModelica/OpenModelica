/** @addtogroup solverBroyden
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks)
#include <Solver/Broyden/Broyden.h>
#include <Solver/Broyden/BroydenSettings.h>
extern "C" IAlgLoopSolver* createBroyden(INonLinearAlgLoop* algLoop, INonLinSolverSettings* settings)
{
    return new Broyden(algLoop, settings);
}

extern "C" INonLinSolverSettings* createBroydenSettings()
{
    return new BroydenSettings();
}



#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Solver/Broyden/Broyden.h>
#include <Solver/Broyden/BroydenSettings.h>

    /* OMC factory */
    using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<IAlgLoopSolver,INonLinearAlgLoop*, INonLinSolverSettings*> > >()
    ["broyden"].set<Broyden>();
  types.get<std::map<std::string, factory<INonLinSolverSettings> > >()
    ["broydenSettings"].set<BroydenSettings>();
 }
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Solver/Broyden/Broyden.h>
#include <Solver/Broyden/BroydenSettings.h>
 shared_ptr<INonLinSolverSettings> createBroydenSettings()
 {
     shared_ptr<INonLinSolverSettings> settings = shared_ptr<INonLinSolverSettings>(new BroydenSettings());
      return settings;
 }
 shared_ptr<IAlgLoopSolver> createBroydenSolver(INonLinearAlgLoop* algLoop, shared_ptr<INonLinSolverSettings> solver_settings)
 {
     shared_ptr<IAlgLoopSolver> solver = shared_ptr<IAlgLoopSolver>(new Broyden(algLoop,solver_settings.get()));
        return solver;
 }
#else
error "operating system not supported"
#endif
/** @} */ // end of solverBroyden



