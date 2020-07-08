/** @addtogroup solverCvode
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks)


#elif defined(SIMSTER_BUILD)




/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_cvode(boost::extensions::factory_map & fm)
{
    fm.get<ISolver,int,IMixedSystem*, ISolverSettings*>()[1].set<Cvode>();
    //fm.get<ISolverSettings,int, IGlobalSettings* >()[2].set<CVodeSettings>();
}

#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Solver/CVode/CVode.h>
#include <Solver/CVode/CVodeSettings.h>

    /* OMC factory */
    using boost::extensions::factory;

    BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<std::map<std::string, factory<ISolver,IMixedSystem*, ISolverSettings*> > >()
    ["cvodeSolver"].set<Cvode>();
    types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
    ["cvodeSettings"].set<CVodeSettings>();
    }
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Solver/CVode/CVodeSettings.h>
#include <Solver/CVode/CVode.h>
#include <Solver/IDA/IDASettings.h>
#include <Solver/IDA/IDA.h>

  #ifdef ENABLE_SUNDIALS_STATIC
    shared_ptr<ISolver> createCVode(IMixedSystem* system, shared_ptr<ISolverSettings> solver_settings)
    {
        shared_ptr<ISolver> cvode = shared_ptr<ISolver>(new Cvode(system,solver_settings.get()));
        return cvode;
    }
    shared_ptr<ISolverSettings> createCVodeSettings(shared_ptr<IGlobalSettings> globalSettings)
    {
         shared_ptr<ISolverSettings> cvode_settings = shared_ptr<ISolverSettings>(new CVodeSettings(globalSettings.get()));
         return cvode_settings;
    }
  #else
    shared_ptr<ISolver> createCVode(IMixedSystem* system, shared_ptr<ISolverSettings> solver_settings)
    {
      throw ModelicaSimulationError(SOLVER,"CVode was disabled during build");
    }
    shared_ptr<ISolverSettings> createCVodeSettings(shared_ptr<IGlobalSettings> globalSettings)
    {
      throw ModelicaSimulationError(SOLVER,"CVode was disabled during build");
    }
  #endif //ENABLE_SUNDIALS_STATIC

#else
error "operating system not supported"
#endif
/** @} */ // end of solverCvode

