#pragma once
/*
Policy class to create a Simster-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct SystemVxWorksFactory : public  ObjectFactory<CreationPolicy>
{

public:
    SystemVxWorksFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
    {
        _use_modelica_compiler = false;
    }

    ~SystemVxWorksFactory()
    {
    }

    boost::shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(IGlobalSettings* globalSettings)
    {

        boost::shared_ptr<IAlgLoopSolverFactory>  algloopsolverfactory = ObjectFactory<CreationPolicy>::_factory->LoadAlgLoopSolverFactory(globalSettings);
        return algloopsolverfactory;
    }

    boost::shared_ptr<ISimData> createSimData()
    {

      boost::shared_ptr<ISimData> simData = ObjectFactory<CreationPolicy>::_factory->LoadSimData();
      return simData;

    }

    boost::shared_ptr<IMixedSystem> createSystem(string modelLib,string modelKey,IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory,boost::shared_ptr<ISimData> simData)
    {
        boost::shared_ptr<IMixedSystem> system = ObjectFactory<CreationPolicy>::_factory->LoadSystem(globalSettings,algloopsolverfactory, simData);

        return system;
    }

    boost::shared_ptr<IMixedSystem>  createModelicaSystem(PATH modelica_path, string modelKey, IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory,boost::shared_ptr<ISimData> simData)
     {
       throw ModelicaSimulationError(MODEL_FACTORY,"Modelica is not supported");
     }

    bool _use_modelica_compiler;
};
