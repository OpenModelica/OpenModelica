#pragma once

#if defined(__vxworks)

  #include "Modelica.h"
 #include <System/AlgLoopSolverFactory.h>
  extern "C" IAlgLoopSolverFactory* createAlgLoopSolverFactory(IGlobalSettings* globalSettings,PATH library_path,PATH modelicasystem_path)
  {
     return new AlgLoopSolverFactory(globalSettings,library_path,modelicasystem_path);
  }

#elif defined(SIMSTER_BUILD)
#include "Modelica.h"
#include <SimCoreFactory/Policies/FactoryConfig.h>
#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include "FactoryExport.h"
#include "ModelicaSystem.h"
#include "AlgLoopSolverFactory.h"

/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_system(boost::extensions::factory_map & fm)
{
    fm.get<IAlgLoopSolverFactory,int,IGlobalSettings*,PATH,PATH>()[1].set<AlgLoopSolverFactory>();

}



#elif defined(OMC_BUILD)
#include "Modelica.h"
#include <SimCoreFactory/Policies/FactoryConfig.h>
#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include "FactoryExport.h"
#include <System/AlgLoopSolverFactory.h>


/*OMC factory*/
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {

   types.get<std::map<std::string, factory<IAlgLoopSolverFactory,IGlobalSettings*,PATH,PATH> > >()
    ["AlgLoopSolverFactory"].set<AlgLoopSolverFactory>();
}

#else
    error "operating system not supported"
#endif




