/** @addtogroup solverNewton
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks)


#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Solver/Newton/Newton.h>
#include <Solver/Newton/NewtonSettings.h>

    /* OMC factory */
    using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<IAlgLoopSolver,IAlgLoop*, INonLinSolverSettings*> > >()
    ["newton"].set<Newton>();
  types.get<std::map<std::string, factory<INonLinSolverSettings> > >()
    ["newtonSettings"].set<NewtonSettings>();
 }
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Solver/Newton/Newton.h>
#include <Solver/Newton/NewtonSettings.h>
 boost::shared_ptr<INonLinSolverSettings> createNewtonSettings()
 {
     boost::shared_ptr<INonLinSolverSettings> settings = boost::shared_ptr<INonLinSolverSettings>(new NewtonSettings());
      return settings;
 }
 boost::shared_ptr<IAlgLoopSolver> createNewtonSolver(IAlgLoop* algLoop, boost::shared_ptr<INonLinSolverSettings> solver_settings)
 {
     boost::shared_ptr<IAlgLoopSolver> solver = boost::shared_ptr<IAlgLoopSolver>(new Newton(algLoop,solver_settings.get()));
        return solver;
 }
#else
error "operating system not supported"
#endif
/** @} */ // end of solverNewton



