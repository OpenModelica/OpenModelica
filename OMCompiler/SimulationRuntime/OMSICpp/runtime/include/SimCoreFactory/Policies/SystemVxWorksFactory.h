#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
/*
Policy class to create a Simster-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct SystemVxWorksFactory : public ObjectFactory<CreationPolicy>
{
public:
    SystemVxWorksFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    {
        _use_modelica_compiler = false;
    }

    ~SystemVxWorksFactory()
    {
    }

    shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(IGlobalSettings* globalSettings)
    {
        shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory = ObjectFactory<CreationPolicy>::_factory->LoadAlgLoopSolverFactory(globalSettings);
        return algloopsolverfactory;
    }


    shared_ptr<IMixedSystem> createSystem(string modelLib,string modelKey, IGlobalSettings* globalSettings)
    {
        shared_ptr<IMixedSystem> system = ObjectFactory<CreationPolicy>::_factory->LoadSystem(globalSettings);
        return system;
    }

    shared_ptr<ISimData> createSimData()
    {
        shared_ptr<ISimData> simData = ObjectFactory<CreationPolicy>::_factory->LoadSimData();
        return simData;
    }

    shared_ptr<IMixedSystem> createModelicaSystem(PATH modelica_path, string modelKey, IGlobalSettings* globalSettings)
    {
        shared_ptr<IMixedSystem> system = ObjectFactory<CreationPolicy>::_factory->LoadSystem(globalSettings);
        return system;
    }

    shared_ptr<ISimVars> createSimVars(size_t dim_real,size_t dim_int,size_t dim_bool,size_t dim_string,size_t dim_pre_vars,size_t dim_z,size_t z_i)
    {
      shared_ptr<ISimVars> simVars = ObjectFactory<CreationPolicy>::_factory->LoadSimVars(dim_real,dim_int,dim_bool,dim_string,dim_pre_vars,dim_z,z_i);
        return simVars;
    }

    bool _use_modelica_compiler;
};
/** @} */ // end of simcorefactoriesPolicies