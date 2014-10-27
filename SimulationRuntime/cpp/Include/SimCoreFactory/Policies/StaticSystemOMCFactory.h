#pragma once

#include <Core/System/IAlgLoopSolverFactory.h>
#include <SimCoreFactory/Policies/SystemOMCFactory.h>
#include <Core/System/AlgLoopSolverFactory.h>
#include <Core/SimController/ISimData.h>

/*
Policy class to create a OMC-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct StaticSystemOMCFactory : public SystemOMCFactory<CreationPolicy>
{
public:
  StaticSystemOMCFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
    :SystemOMCFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
  {
  }

  virtual ~StaticSystemOMCFactory()
  {
  }

  virtual boost::shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(IGlobalSettings* globalSettings)
  {
    boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory = boost::shared_ptr<IAlgLoopSolverFactory>(new AlgLoopSolverFactory(globalSettings, ObjectFactory<CreationPolicy>::_library_path, ObjectFactory<CreationPolicy>::_modelicasystem_path));
    return algloopsolverfactory;
  }

protected:
  virtual void initializeLibraries(PATH library_path, PATH modelicasystem_path, PATH config_path)
  {
  }
}; 
