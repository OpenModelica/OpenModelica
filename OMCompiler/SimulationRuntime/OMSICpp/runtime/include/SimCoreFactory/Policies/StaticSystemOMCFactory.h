#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */

shared_ptr<ISimData> createSimDataFunction();
shared_ptr<ISimVars> createSimVarsFunction(size_t dim_real,size_t dim_int,size_t dim_bool,size_t dim_string,size_t dim_pre_vars,size_t dim_z,size_t z_i);
shared_ptr<IMixedSystem> createSystemFunction(shared_ptr<IGlobalSettings> globalSettings);
shared_ptr<IAlgLoopSolverFactory> createStaticAlgLoopSolverFactory(shared_ptr<IGlobalSettings> globalSettings,PATH library_path,PATH modelicasystem_path);
/*
Policy class to create a OMC-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct StaticSystemOMCFactory: public  ObjectFactory<CreationPolicy>
{
public:
  StaticSystemOMCFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
    :ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
  {
      _use_modelica_compiler = false;
  }

  virtual ~StaticSystemOMCFactory()
  {
  }
  virtual shared_ptr<IMixedSystem> createOSUSystem(string osu_name,shared_ptr<IGlobalSettings> globalSettings)
  {
      throw ModelicaSimulationError(MODEL_FACTORY,"OSU System is not supported");
  }
  shared_ptr<IMixedSystem> createSystem(string modelLib,string modelKey,shared_ptr<IGlobalSettings> globalSettings)
  {
     return createSystemFunction(globalSettings);
  }
   shared_ptr<IMixedSystem>  createModelicaSystem(PATH modelica_path, string modelKey, shared_ptr<IGlobalSettings> globalSettings)
  {
    throw ModelicaSimulationError(MODEL_FACTORY,"Modelica is not supported");
  }
   bool _use_modelica_compiler;
};
/** @} */ // end of simcorefactoriesPolicies
