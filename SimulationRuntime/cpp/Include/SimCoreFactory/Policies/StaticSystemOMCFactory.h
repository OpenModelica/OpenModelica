#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */

boost::shared_ptr<ISimData> createSimDataFunction();
boost::shared_ptr<ISimVars> createSimVarsFunction(size_t dim_real,size_t dim_int,size_t dim_bool,size_t dim_pre_vars,size_t dim_z,size_t z_i);
boost::shared_ptr<IMixedSystem> createSystemFunction(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory,boost::shared_ptr<ISimData> simData,boost::shared_ptr<ISimVars> simVars);

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

  virtual boost::shared_ptr<ISimData> createSimData()
  {
    return createSimDataFunction();
  }

  virtual boost::shared_ptr<ISimVars> createSimVars(size_t dim_real,size_t dim_int,size_t dim_bool,size_t dim_pre_vars,size_t dim_z,size_t z_i)
  {
    return createSimVarsFunction(dim_real, dim_int, dim_bool, dim_pre_vars, dim_z, z_i);
  }

  virtual boost::shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(IGlobalSettings* globalSettings)
  {
    return ObjectFactory<CreationPolicy>::_factory->createAlgLoopSolverFactory(globalSettings);
  }

  boost::shared_ptr<IMixedSystem> createSystem(string modelLib,string modelKey,IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory,boost::shared_ptr<ISimData> simData,boost::shared_ptr<ISimVars> simVars)
  {
     return createSystemFunction(globalSettings,algloopsolverfactory,simData,simVars);
  }
};
/** @} */ // end of simcorefactoriesPolicies
