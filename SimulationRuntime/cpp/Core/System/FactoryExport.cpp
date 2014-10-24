#pragma once

#if defined(__vxworks) || defined(__TRICORE__)

#include <Core/Modelica.h>
#include <SimCoreFactory/Policies/FactoryConfig.h>
#include <Core/System/AlgLoopSolverFactory.h>
extern "C" IAlgLoopSolverFactory* createAlgLoopSolverFactory(IGlobalSettings* globalSettings,PATH library_path,PATH modelicasystem_path)
{
  return new AlgLoopSolverFactory(globalSettings,library_path,modelicasystem_path);
}

#elif defined(SIMSTER_BUILD)

#include <Core/Modelica.h>
#include <SimCoreFactory/Policies/FactoryConfig.h>
#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/System/FactoryExport.h>
#include <Core/System/AlgLoopSolverFactory.h>

/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_system(boost::extensions::factory_map & fm)
{
  fm.get<IAlgLoopSolverFactory,int,IGlobalSettings*,PATH,PATH>()[1].set<AlgLoopSolverFactory>();
}

#elif defined(OMC_BUILD)

#include <Core/Modelica.h>
#include <SimCoreFactory/Policies/FactoryConfig.h>
#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/System/FactoryExport.h>
#include <Core/System/AlgLoopSolverFactory.h>

/*OMC factory*/
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {

  types.get<std::map<std::string, factory<IAlgLoopSolverFactory,IGlobalSettings*,PATH,PATH> > >()
    ["AlgLoopSolverFactory"].set<AlgLoopSolverFactory>();
}

#else
error "operating system not supported"
#endif




