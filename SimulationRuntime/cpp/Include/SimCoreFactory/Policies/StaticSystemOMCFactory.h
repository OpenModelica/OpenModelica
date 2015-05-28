#pragma once
/** @addtogroup simcorefactoriesPolicies
 *  
 *  @{
 */
/*includes removed for static linking not needed any more
#include <Core/System/IAlgLoopSolverFactory.h>
#include <SimCoreFactory/Policies/SystemOMCFactory.h>
#include <Core/System/AlgLoopSolverFactory.h>
#include <Core/SimController/ISimData.h>
*/
boost::shared_ptr<IMixedSystem>  createModelicaSystem(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory,boost::shared_ptr<ISimData> simData,boost::shared_ptr<ISimVars> simVars);
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
    return ObjectFactory<CreationPolicy>::_factory->createAlgLoopSolverFactory(globalSettings);
  }
  
  boost::shared_ptr<IMixedSystem> createSystem(string modelLib,string modelKey,IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory,boost::shared_ptr<ISimData> simData,boost::shared_ptr<ISimVars> simVars)
  {
     return createModelicaSystem(globalSettings,algloopsolverfactory,simData,simVars);
  }
  
protected:
  virtual void initializeLibraries(PATH library_path, PATH modelicasystem_path, PATH config_path)
  {
  }
}; 
/** @} */ // end of simcorefactoriesPolicies