/** @addtogroup solverEuler
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks)


#include <Solver/Euler/Euler.h>
#include <Solver/Euler/EulerSettings.h>

extern "C" ISolver* createEuler(IMixedSystem* system, ISolverSettings* settings)
{
    return new Euler(system,settings);
}

extern "C" ISolverSettings* createEulerSettings(IGlobalSettings* globalSettings)
{
    return new EulerSettings(globalSettings);
}

#elif defined(SIMSTER_BUILD)

#include <Policies/FactoryConfig.h>
#include <Solver/Euler/Euler.h>
#include <Solver/Euler/EulerSettings.h>

/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_euler(boost::extensions::factory_map & fm)
{
    fm.get<ISolver,int,IMixedSystem*, ISolverSettings*>()[1].set<Euler>();
    fm.get<ISolverSettings,int, IGlobalSettings* >()[2].set<EulerSettings>();
}

#elif defined(OMC_BUILD)


#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Solver/Euler/Euler.h>
#include <Solver/Euler/EulerSettings.h>

    /* OMC factory */
    using boost::extensions::factory;

    BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<std::map<std::string, factory<ISolver,IMixedSystem*, ISolverSettings*> > >()
    ["eulerSolver"].set<Euler>();
    types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
    ["eulerSettings"].set<EulerSettings>();
    }

#else
error "operating system not supported"
#endif

/** @} */ // end of solverEuler

