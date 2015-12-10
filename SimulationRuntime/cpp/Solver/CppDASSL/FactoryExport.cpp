
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(__vxworks)


#elif defined(SIMSTER_BUILD)

#include <Solver/CppDASSL/CppDASSL.h>


/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_cppdassl(boost::extensions::factory_map & fm)
{
    fm.get<ISolver,int,IMixedSystem*, ISolverSettings*>()[1].set<CppDASSL>();
    //fm.get<ISolverSettings,int, IGlobalSettings* >()[2].set<PeerSettings>();
}

#elif defined(OMC_BUILD)

#include <Solver/CppDASSL/CppDASSL.h>
#include <Solver/CppDASSL/CppDASSLSettings.h>

    /* OMC factory */
    using boost::extensions::factory;

    BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<std::map<std::string, factory<ISolver,IMixedSystem*, ISolverSettings*> > >()
    ["cppdasslSolver"].set<CppDASSL>();
    types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
    ["cppdasslSettings"].set<CppDASSLSettings>();
    }

#else
error "operating system not supported"
#endif



