#pragma once
/*
Policy class to create a Simster-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct SystemOMCFactory : public  ObjectFactory<CreationPolicy>
{

public:
    SystemOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
    {
        _use_modelica_compiler = false;
        
        
        
        
        _system_type_map = new type_map();
        PATH systemfactory_path = ObjectFactory<CreationPolicy>::_library_path;
        PATH system_name(SYSTEM_LIB);
        systemfactory_path/=system_name;
        
        LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(systemfactory_path.string(),*_system_type_map);
        if (result != LOADER_SUCCESS)
        {
            throw std::runtime_error("Failed loading System library!");
        }
        
        PATH dataexchange_path = ObjectFactory<CreationPolicy>::_library_path;
        PATH dataexchange_name(DATAEXCHANGE_LIB);
        dataexchange_path/=dataexchange_name;
        
        result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(dataexchange_path.string(),*_system_type_map);
        if (result != LOADER_SUCCESS)
        {
            throw std::runtime_error("Failed loading Dataexchange library!");
        }
        

    }

    ~SystemOMCFactory()
    {
        delete _system_type_map;
        ObjectFactory<CreationPolicy>::_factory->UnloadAllLibs();
    }

    boost::shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(IGlobalSettings* globalSettings)
    {
        std::map<std::string, factory<IAlgLoopSolverFactory,IGlobalSettings*,PATH,PATH> >::iterator iter;
        std::map<std::string, factory<IAlgLoopSolverFactory,IGlobalSettings*,PATH,PATH> >& algloopsolver_factory(_system_type_map->get());
        iter = algloopsolver_factory.find("AlgLoopSolverFactory");
        if (iter ==algloopsolver_factory.end()) 
         {
            throw std::invalid_argument("No AlgLoopSolverFactory  found");
        }
        boost::shared_ptr<IAlgLoopSolverFactory>  algloopsolverfactory = boost::shared_ptr<IAlgLoopSolverFactory>(iter->second.create(globalSettings,ObjectFactory<CreationPolicy>::_library_path,ObjectFactory<CreationPolicy>::_modelicasystem_path));
        return algloopsolverfactory;
    }

     std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> >  createSystem(string modelKey,IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory)
    {
        PATH modelica_path = ObjectFactory<CreationPolicy>::_modelicasystem_path;
        PATH modelica_name(MODELICASYSTEM_LIB);
        modelica_path/=modelica_name;
        LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(modelica_path.string(),*_system_type_map);
        if (result != LOADER_SUCCESS)
        {
            throw std::runtime_error("Failed loading System library!");
        }
        
        std::map<std::string, factory<IMixedSystem,IGlobalSettings*,boost::shared_ptr<IAlgLoopSolverFactory>, boost::shared_ptr<ISimData> > >::iterator system_iter;
        std::map<std::string, factory<IMixedSystem,IGlobalSettings*,boost::shared_ptr<IAlgLoopSolverFactory>, boost::shared_ptr<ISimData> > >& factories(_system_type_map->get());
        system_iter = factories.find(modelKey);
        if (system_iter ==factories.end()) 
        {
            throw std::invalid_argument("No system found");
        }
       
       
        std::map<std::string, factory<ISimData> >::iterator simdata_iter;
        std::map<std::string, factory<ISimData > >& simdata_factory(_system_type_map->get());
        simdata_iter = simdata_factory.find("SimData");
        if (simdata_iter ==simdata_factory.end()) 
        {
            throw std::invalid_argument("No simdata found");
        }
        boost::shared_ptr<ISimData> simData(simdata_iter->second.create());
        boost::shared_ptr<IMixedSystem> system(system_iter->second.create(globalSettings,algloopsolverfactory,simData));
        return std::make_pair(system,simData);
    }

    std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> >  createModelicaSystem(PATH modelica_path,string modelKey, IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory)
    {
        throw std::runtime_error("Modelica is not supported");
    }
protected:
    bool _use_modelica_compiler;    
private:
    type_map* _system_type_map;


};