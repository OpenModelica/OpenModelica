
#pragma once
#include "Modelica.h"
#if defined(__vxworks)


#elif defined(SIMSTER_BUILD)

#include "CVode.h"


/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_kinsol(boost::extensions::factory_map & fm)
{
    fm.get<IAlgLoopSolver,int,IAlgLoop*, INonLinSolverSettings*>()[1].set<Kinsol>();
    fm.get<INonLinSolverSettings,int >()[2].set<KinsolSettings>();
}

#elif defined(OMC_BUILD)

#include "Kinsol.h"
#include "KinsolSettings.h"


using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<IAlgLoopSolver,IAlgLoop*, INonLinSolverSettings*> > >()
    ["kinsol"].set<Kinsol>();
  types.get<std::map<std::string, factory<INonLinSolverSettings> > >()
    ["kinsolSettings"].set<KinsolSettings>();
 }


#else
error "operating system not supported"
#endif



