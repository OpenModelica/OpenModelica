#pragma once

#if defined(__vxworks)
        
  #include "stdafx.h"
 #include <System/AlgLoopSolverFactory.h>
  extern "C" IAlgLoopSolverFactory* createAlgLoopSolverFactory(IGlobalSettings* globalSettings,PATH library_path,PATH modelicasystem_path)
  {
     return new AlgLoopSolverFactory(globalSettings,library_path,modelicasystem_path);
  }

#elif defined(SIMSTER_BUILD)
#include "stdafx.h"
#include "FactoryExport.h"
#include "ModelicaSystem.h"
#include "AlgLoopSolverFactory.h"

/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_system(boost::extensions::factory_map & fm)
{
    fm.get<IAlgLoopSolverFactory,int,IGlobalSettings*,PATH,PATH>()[1].set<AlgLoopSolverFactory>();
    
}

extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_modelica(boost::extensions::factory_map & fm)
{
    
    fm.get<IMixedSystem,int,IGlobalSettings*,boost::shared_ptr<IAlgLoopSolverFactory>,boost::shared_ptr<ISimData> >()[2].set<Modelica>();
}

#elif defined(OMC_BUILD)
#include "stdafx.h"
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


           
