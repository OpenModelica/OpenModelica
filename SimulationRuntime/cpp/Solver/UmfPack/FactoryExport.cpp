
#pragma once
#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
#if defined(__vxworks)


#elif defined(OMC_BUILD)

#include <Solver/UmfPack/UmfPack.h>
#include <Solver/UmfPack/UmfPackSettings.h>

    /* OMC factory */
    using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<IAlgLoopSolver,IAlgLoop*, ILinSolverSettings*> > >()
    ["umfpack"].set<UmfPack>();
  types.get<std::map<std::string, factory<ILinSolverSettings> > >()
    ["umfpackSettings"].set<UmfPackSettings>();
 }

#else
error "operating system not supported"
#endif



