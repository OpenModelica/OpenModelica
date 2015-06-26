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

  virtual boost::shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(IGlobalSettings* globalSettings)
  {
    std::map<std::string, factory<IAlgLoopSolverFactory,IGlobalSettings*,PATH,PATH> >::iterator iter;
    std::map<std::string, factory<IAlgLoopSolverFactory,IGlobalSettings*,PATH,PATH> >& algloopsolver_factory(_system_type_map->get());
    iter = algloopsolver_factory.find("AlgLoopSolverFactory");
    if (iter ==algloopsolver_factory.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No AlgLoopSolverFactory  found");
    }
    boost::shared_ptr<IAlgLoopSolverFactory>  algloopsolverfactory = boost::shared_ptr<IAlgLoopSolverFactory>(iter->second.create(globalSettings,ObjectFactory<CreationPolicy>::_library_path,ObjectFactory<CreationPolicy>::_modelicasystem_path));

    return algloopsolverfactory;
  }
  /*
  virtual std::pair<boost::shared_ptr<IMixedSystem>, boost::shared_ptr<ISimData> > createSystem(boost::shared_ptr<ISimData> (*createSimDataCallback)(), boost::shared_ptr<IMixedSystem> (*createSystemCallback)(IGlobalSettings*, boost::shared_ptr<IAlgLoopSolverFactory>, boost::shared_ptr<ISimData>), IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory)
  {
    boost::shared_ptr<ISimData> simData = createSimDataCallback();
    boost::shared_ptr<IMixedSystem> system = createSystemCallback(globalSettings, algloopsolverfactory, simData);
    return std::make_pair(system,simData);
  }
   */
  virtual boost::shared_ptr<ISimData> createSimData()
  {
    std::map<std::string, factory<ISimData> >::iterator simdata_iter;
    std::map<std::string, factory<ISimData > >& simdata_factory(_system_type_map->get());
    simdata_iter = simdata_factory.find("SimData");
    if (simdata_iter == simdata_factory.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No simdata found");
    }
    boost::shared_ptr<ISimData> simData(simdata_iter->second.create());
    return simData;

  }

  virtual boost::shared_ptr<ISimVars> createSimVars(size_t dim_real,size_t dim_int,size_t dim_bool,size_t dim_pre_vars,size_t dim_z,size_t z_i)
  {
    std::map<std::string, factory<ISimVars,size_t,size_t,size_t,size_t,size_t,size_t > >::iterator simvars_iter;
    std::map<std::string, factory<ISimVars,size_t,size_t,size_t,size_t,size_t,size_t > >& simvars_factory(_system_type_map->get());
    simvars_iter = simvars_factory.find("SimVars");
    if (simvars_iter == simvars_factory.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No simvars found");
    }
    boost::shared_ptr<ISimVars> simVars(simvars_iter->second.create(dim_real,dim_int,dim_bool,dim_pre_vars,dim_z,z_i));
    return simVars;

  }

  virtual boost::shared_ptr<IMixedSystem> createSystem(string modelLib,string modelKey,IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory,boost::shared_ptr<ISimData> simData,boost::shared_ptr<ISimVars> simVars)
  {
    PATH modelica_path = ObjectFactory<CreationPolicy>::_modelicasystem_path;
    PATH modelica_name(modelLib);
    modelica_path/=modelica_name;
    LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(modelica_path.string(),*_system_type_map);
    if (result != LOADER_SUCCESS)
    {
      std::stringstream tmp;
      tmp << "Failed loading System library!" << std::endl << modelica_path.string();
      throw ModelicaSimulationError(MODEL_FACTORY,tmp.str());
    }

    std::map<std::string, factory<IMixedSystem, IGlobalSettings*, boost::shared_ptr<IAlgLoopSolverFactory>, boost::shared_ptr<ISimData>, boost::shared_ptr<ISimVars> > >::iterator system_iter;
    std::map<std::string, factory<IMixedSystem, IGlobalSettings*, boost::shared_ptr<IAlgLoopSolverFactory>, boost::shared_ptr<ISimData>, boost::shared_ptr<ISimVars> > >& factories(_system_type_map->get());
    system_iter = factories.find(modelKey);
    if (system_iter == factories.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No system found");
    }

    boost::shared_ptr<IMixedSystem> system(system_iter->second.create(globalSettings,algloopsolverfactory,simData,simVars));
    return system;
  }

   boost::shared_ptr<IMixedSystem>  createModelicaSystem(PATH modelica_path, string modelKey, IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory,boost::shared_ptr<ISimData> simData,boost::shared_ptr<ISimVars> simVars)
  {
    throw ModelicaSimulationError(MODEL_FACTORY,"Modelica is not supported");
  }

protected:
  virtual void initializeLibraries(PATH library_path,PATH modelicasystem_path,PATH config_path)
  {
    PATH systemfactory_path = ObjectFactory<CreationPolicy>::_library_path;
    PATH system_name(SYSTEM_LIB);
    systemfactory_path/=system_name;

    LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(systemfactory_path.string(), *_system_type_map);
    if (result != LOADER_SUCCESS)
    {
      std::stringstream tmp;
      tmp << "Failed loading System library!" << std::endl << systemfactory_path.string();
      throw ModelicaSimulationError(MODEL_FACTORY,tmp.str());
    }

    PATH dataexchange_path = ObjectFactory<CreationPolicy>::_library_path;
    PATH dataexchange_name(DATAEXCHANGE_LIB);
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
