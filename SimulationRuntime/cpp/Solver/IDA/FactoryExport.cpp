
#pragma once
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

#elif defined(OMC_BUILD)

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

#else
error "operating system not supported"
#endif



