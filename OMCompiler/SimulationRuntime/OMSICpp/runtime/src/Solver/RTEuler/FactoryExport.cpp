/** @addtogroup solverCvode
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks)

#include <Solver/RTEuler/RTEuler.h>
#include <Solver/RTEuler/RTEulerSettings.h>

extern "C" ISolver* createRTEuler(IMixedSystem* system, ISolverSettings* settings)
{
    return new RTEuler(system,settings);
}

extern "C" ISolverSettings* createRTEulerSettings(IGlobalSettings* globalSettings)
{
    return new RTEulerSettings(globalSettings);
}

#elif defined(__TRICORE__)

#include "stdafx.h"
#include "RTEuler.h"
#include "RTEulerSettings.h"

extern "C" ISolver* createRTEuler(IMixedSystem* system, ISolverSettings* settings)
{
    return new RTEuler(system,settings);
}

extern "C" ISolverSettings* createRTEulerSettings(IGlobalSettings* globalSettings)
{
    return new RTEulerSettings(globalSettings);
}


#elif defined(SIMSTER_BUILD)

#include "Euler.h"
#include "EulerSettings.h"

/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_euler(boost::extensions::factory_map & fm)
{
    fm.get<ISolver,int,IMixedSystem*, ISolverSettings*>()[1].set<Euler>();
    fm.get<ISolverSettings,int, IGlobalSettings* >()[2].set<EulerSettings>();
}

#elif defined(OMC_BUILD)

#include <Solver/RTEuler/RTEuler.h>
#include <Solver/RTEuler/RTEulerSettings.h>

    /* OMC factory */
    using boost::extensions::factory;

    BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<std::map<std::string, factory<ISolver,IMixedSystem*, ISolverSettings*> > >()
    ["RTEulerSolver"].set<RTEuler>();
    types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
    ["RTEulerSettings"].set<RTEulerSettings>();
    }

#else
error "operating system not supported"
#endif
/** @} */ // end of solverRteuler



