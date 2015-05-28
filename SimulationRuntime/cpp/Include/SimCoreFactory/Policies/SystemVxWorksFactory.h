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

    boost::shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(IGlobalSettings* globalSettings)
    {
        boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory = ObjectFactory<CreationPolicy>::_factory->LoadAlgLoopSolverFactory(globalSettings);
        return algloopsolverfactory;
    }

                        //            createSystem(std::string&,      std::string&, IGlobalSettings*,                boost::shared_ptr<IAlgLoopSolverFactory>&,                     boost::shared_ptr<ISimData>&, boost::shared_ptr<ISimVars>&)
    boost::shared_ptr<IMixedSystem> createSystem(string modelLib,string modelKey, IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory, boost::shared_ptr<ISimData> simData, boost::shared_ptr<ISimVars> simVars)
    {
        boost::shared_ptr<IMixedSystem> system = ObjectFactory<CreationPolicy>::_factory->LoadSystem(globalSettings, algloopsolverfactory, simData, simVars);
        return system;
    }

    boost::shared_ptr<ISimData> createSimData()
    {
        boost::shared_ptr<ISimData> simData = ObjectFactory<CreationPolicy>::_factory->LoadSimData();
        return simData;
    }
    
    boost::shared_ptr<IMixedSystem> createModelicaSystem(PATH modelica_path, string modelKey, IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory, boost::shared_ptr<ISimData> simData, boost::shared_ptr<ISimVars> simVars)
    {
        boost::shared_ptr<IMixedSystem> system = ObjectFactory<CreationPolicy>::_factory->LoadSystem(globalSettings, algloopsolverfactory, simData, simVars);
        return system;
    }

    boost::shared_ptr<ISimVars> createSimVars(size_t dim_real,size_t dim_int,size_t dim_bool,size_t dim_pre_vars,size_t dim_z,size_t z_i)
    {
      boost::shared_ptr<ISimVars> simVars = ObjectFactory<CreationPolicy>::_factory->LoadSimVars(dim_real,dim_int,dim_bool,dim_pre_vars,dim_z,z_i);
        return simVars;
    }

    bool _use_modelica_compiler;
};
/** @} */ // end of simcorefactoriesPolicies