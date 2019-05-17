#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
/*
Policy class to create a Simster-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct SystemBodasFactory : public ObjectFactory<CreationPolicy>
{
public:
    SystemBodasFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    {
        _use_modelica_compiler = false;
    }

    ~SystemBodasFactory()
    {
    }

    shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(IGlobalSettings* globalSettings)
    {
        shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory = ObjectFactory<CreationPolicy>::_factory->LoadAlgLoopSolverFactory(globalSettings);
        return algloopsolverfactory;
    }

    shared_ptr<ISimData> createSimData()
    {
        shared_ptr<ISimData> simData = ObjectFactory<CreationPolicy>::_factory->LoadSimData();
        return simData;
    }

    shared_ptr<IMixedSystem> createSystem(string modelLib, string modelKey, IGlobalSettings* globalSettings,shared_ptr<ISimObjects> simObjects)
    {
        shared_ptr<IMixedSystem> system = ObjectFactory<CreationPolicy>::_factory->LoadSystem(globalSettings,simObjects);
        return system;
    }

    shared_ptr<IMixedSystem> createModelicaSystem(string modelLib, string modelKey, IGlobalSettings* globalSettings)
    {
        shared_ptr<IMixedSystem> system = ObjectFactory<CreationPolicy>::_factory->LoadSystem(globalSettings);
        return system;
    }

    bool _use_modelica_compiler;
};
/** @} */ // end of simcorefactoriesPolicies