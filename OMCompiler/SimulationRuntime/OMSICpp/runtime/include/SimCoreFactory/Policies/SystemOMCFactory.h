#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */

/*
Policy class to create a OMC-,  Modelica- system or AlgLoopSolver
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
#ifndef RUNTIME_STATIC_LINKING
    initializeLibraries(library_path, modelicasystem_path, config_path);
#endif
  }

  virtual ~SystemOMCFactory()
  {
    delete _system_type_map;
    ObjectFactory<CreationPolicy>::_factory->UnloadAllLibs();
  }

  virtual shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(shared_ptr<IGlobalSettings> globalSettings)
  {
    std::map<std::string, factory<IAlgLoopSolverFactory,shared_ptr<IGlobalSettings>,PATH,PATH> >::iterator iter;
    std::map<std::string, factory<IAlgLoopSolverFactory,shared_ptr<IGlobalSettings>,PATH,PATH> >& algloopsolver_factory(_system_type_map->get());
    iter = algloopsolver_factory.find("AlgLoopSolverFactory");
    if (iter ==algloopsolver_factory.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No AlgLoopSolverFactory  found");
    }
    shared_ptr<IAlgLoopSolverFactory>  algloopsolverfactory = shared_ptr<IAlgLoopSolverFactory>(iter->second.create(globalSettings,ObjectFactory<CreationPolicy>::_library_path,ObjectFactory<CreationPolicy>::_modelicasystem_path));

    return algloopsolverfactory;
  }



  virtual shared_ptr<IMixedSystem> createOSUSystem(string osu_name,shared_ptr<IGlobalSettings> globalSettings)
  {

    std::map<std::string, factory<IMixedSystem, shared_ptr<IGlobalSettings>,string > >::iterator system_iter;
    std::map<std::string, factory<IMixedSystem, shared_ptr<IGlobalSettings>,string> >& factories(_system_type_map->get());
    system_iter = factories.find("OSUSystem");
    if (system_iter == factories.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No system found");
    }

    shared_ptr<IMixedSystem> system(system_iter->second.create(globalSettings,osu_name));
    return system;
  }



  virtual shared_ptr<IMixedSystem> createSystem(string modelLib,string modelKey,shared_ptr<IGlobalSettings> globalSettings)
  {
    fs::path modelica_path = ObjectFactory<CreationPolicy>::_modelicasystem_path;
    fs::path modelica_name(modelLib);
    modelica_path/=modelica_name;
    LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(modelica_path.string(),*_system_type_map);
    if (result != LOADER_SUCCESS)
    {
      std::stringstream tmp;
      tmp << "Failed loading System library!" << std::endl << modelica_path.string();
      throw ModelicaSimulationError(MODEL_FACTORY,tmp.str());
    }

    std::map<std::string, factory<IMixedSystem, shared_ptr<IGlobalSettings> > >::iterator system_iter;
    std::map<std::string, factory<IMixedSystem, shared_ptr<IGlobalSettings> > >& factories(_system_type_map->get());
    system_iter = factories.find(modelKey);
    if (system_iter == factories.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No system found");
    }

    shared_ptr<IMixedSystem> system(system_iter->second.create(globalSettings));
    return system;
  }

   shared_ptr<IMixedSystem>  createModelicaSystem(PATH modelica_path, string modelKey, shared_ptr<IGlobalSettings> globalSettings)
  {
    throw ModelicaSimulationError(MODEL_FACTORY,"Modelica is not supported");
  }

protected:
  virtual void initializeLibraries(PATH library_path,PATH modelicasystem_path,PATH config_path)
  {
    fs::path systemfactory_path = ObjectFactory<CreationPolicy>::_library_path;
    fs::path system_name(SYSTEM_LIB);
    systemfactory_path/=system_name;

    LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(systemfactory_path.string(), *_system_type_map);
    if (result != LOADER_SUCCESS)
    {
      std::stringstream tmp;
      tmp << "Failed loading System library!" << std::endl << systemfactory_path.string();
      throw ModelicaSimulationError(MODEL_FACTORY,tmp.str());
    }

    fs::path dataexchange_path = ObjectFactory<CreationPolicy>::_library_path;
    fs::path dataexchange_name(DATAEXCHANGE_LIB);
    dataexchange_path/=dataexchange_name;

    result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(dataexchange_path.string(), *_system_type_map);
    if (result != LOADER_SUCCESS)
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading Dataexchange library!");
    }
  }

  bool _use_modelica_compiler;
  type_map* _system_type_map;
};
/** @} */ // end of simcorefactoriesPolicies
