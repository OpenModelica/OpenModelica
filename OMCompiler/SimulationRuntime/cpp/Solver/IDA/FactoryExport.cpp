
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks)


#elif defined(SIMSTER_BUILD)

#include <Solver/IDA/IDA.h>


/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_ida(boost::extensions::factory_map & fm)
{
    fm.get<ISolver,int,IMixedSystem*, ISolverSettings*>()[1].set<Ida>();
    //fm.get<ISolverSettings,int, IGlobalSettings* >()[2].set<IDASettings>();
}

#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Solver/IDA/IDA.h>
#include <Solver/IDA/IDASettings.h>

    /* OMC factory */
    using boost::extensions::factory;

    BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<std::map<std::string, factory<ISolver,IMixedSystem*, ISolverSettings*> > >()
    ["idaSolver"].set<Ida>();
    types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
    ["idaSettings"].set<IDASettings>();
    }
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Solver/IDA/IDA.h>
#include <Solver/IDA/IDASettings.h>

  #ifdef ENABLE_SUNDIALS_STATIC
    shared_ptr<ISolver> createIda(IMixedSystem* system, shared_ptr<ISolverSettings> solver_settings)
    {
        shared_ptr<ISolver> ida = shared_ptr<ISolver>(new Ida(system,solver_settings.get()));
        return ida;
    }
    shared_ptr<ISolverSettings> createIdaSettings(shared_ptr<IGlobalSettings> globalSettings)
    {
         shared_ptr<ISolverSettings> ida_settings = shared_ptr<ISolverSettings>(new IDASettings(globalSettings.get()));
         return ida_settings;
    }
  #else
    shared_ptr<ISolver> createIda(IMixedSystem* system, shared_ptr<ISolverSettings> solver_settings)
    {
      throw ModelicaSimulationError(SOLVER,"IDA was disabled during build");
    }
    shared_ptr<ISolverSettings> createIdaSettings(shared_ptr<IGlobalSettings> globalSettings)
    {
      throw ModelicaSimulationError(SOLVER,"IDA was disabled during build");
    }
  #endif //ENABLE_SUNDIALS_STATIC


#else
error "operating system not supported"
#endif



