#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */

/*
Policy class to create a OMC-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct SimObjectOMCFactory : public  ObjectFactory<CreationPolicy>
{

public:
  SimObjectOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
    :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
  {
    _simobject_type_map = new type_map();
#ifndef RUNTIME_STATIC_LINKING
    initializeLibraries(library_path, modelicasystem_path, config_path);
#endif
  }

  virtual ~SimObjectOMCFactory()
  {
    delete _simobject_type_map;
    ObjectFactory<CreationPolicy>::_factory->UnloadAllLibs();
  }

  virtual shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(shared_ptr<IGlobalSettings> globalSettings)
  {
    std::map<std::string, factory<IAlgLoopSolverFactory,shared_ptr<IGlobalSettings>,PATH,PATH> >::iterator iter;
    std::map<std::string, factory<IAlgLoopSolverFactory,shared_ptr<IGlobalSettings>,PATH,PATH> >& algloopsolver_factory(_simobject_type_map->get());
    iter = algloopsolver_factory.find("AlgLoopSolverFactory");
    if (iter ==algloopsolver_factory.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No AlgLoopSolverFactory  found");
    }
    shared_ptr<IAlgLoopSolverFactory>  algloopsolverfactory = shared_ptr<IAlgLoopSolverFactory>(iter->second.create(globalSettings,ObjectFactory<CreationPolicy>::_library_path,ObjectFactory<CreationPolicy>::_modelicasystem_path));

    return algloopsolverfactory;
  }

  virtual shared_ptr<ISimData> createSimData()
  {
    std::map<std::string, factory<ISimData> >::iterator simdata_iter;
    std::map<std::string, factory<ISimData > >& simdata_factory(_simobject_type_map->get());
    simdata_iter = simdata_factory.find("SimData");
    if (simdata_iter == simdata_factory.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No simdata found");
    }
    shared_ptr<ISimData> simData(simdata_iter->second.create());
    return simData;

  }

  virtual shared_ptr<ISimVars> createSimVars(size_t dim_real,size_t dim_int,size_t dim_bool,size_t dim_string,size_t dim_pre_vars,size_t dim_z,size_t z_i)
  {
    std::map<std::string, factory<ISimVars,size_t,size_t,size_t,size_t,size_t,size_t,size_t > >::iterator simvars_iter;
    std::map<std::string, factory<ISimVars,size_t,size_t,size_t,size_t,size_t,size_t,size_t > >& simvars_factory(_simobject_type_map->get());
    simvars_iter = simvars_factory.find("SimVars");
    if (simvars_iter == simvars_factory.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No simvars found");
    }
	shared_ptr<ISimVars> simVars(simvars_iter->second.create(dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_z, z_i));
    return simVars;

  }
  virtual shared_ptr<ISimVars> createSimVars(omsi_t* omsu)
  {
	  std::map<std::string, factory<ISimVars, omsi_t*> >::iterator simvars_iter;
	  std::map<std::string, factory<ISimVars, omsi_t* > >& simvars_factory(_simobject_type_map->get());
	  simvars_iter = simvars_factory.find("SimVars2");
	  if (simvars_iter == simvars_factory.end())
	  {
		  throw ModelicaSimulationError(MODEL_FACTORY, "No simvars found");
	  }
	  shared_ptr<ISimVars> simVars(simvars_iter->second.create(omsu));
	  return simVars;

  }
  shared_ptr<IHistory> createMatFileWriter(shared_ptr<IGlobalSettings> settings,size_t dim)
  {
    std::map<std::string, factory<IHistory,shared_ptr<IGlobalSettings>,size_t > >::iterator writer_iter;
    std::map<std::string, factory<IHistory,shared_ptr<IGlobalSettings>,size_t > >& writer_factory(_simobject_type_map->get());
    writer_iter = writer_factory.find("MatFileWriter");
    if (writer_iter == writer_factory.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No MatfileWriter found");
    }
    shared_ptr<IHistory> writer(writer_iter->second.create(settings,dim));
    return writer;

  }
  shared_ptr<IHistory> createTextFileWriter(shared_ptr<IGlobalSettings> settings,size_t dim)
  {
    std::map<std::string, factory<IHistory,shared_ptr<IGlobalSettings>,size_t > >::iterator writer_iter;
    std::map<std::string, factory<IHistory,shared_ptr<IGlobalSettings>,size_t > >& writer_factory(_simobject_type_map->get());
    writer_iter = writer_factory.find("TextFileWriter");
    if (writer_iter == writer_factory.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No MatfileWriter found");
    }
    shared_ptr<IHistory> writer(writer_iter->second.create(settings,dim));
    return writer;

  }
  shared_ptr<IHistory> createBufferReaderWriter(shared_ptr<IGlobalSettings> settings,size_t dim)
  {
    std::map<std::string, factory<IHistory,shared_ptr<IGlobalSettings>,size_t > >::iterator writer_iter;
    std::map<std::string, factory<IHistory,shared_ptr<IGlobalSettings>,size_t > >& writer_factory(_simobject_type_map->get());
    writer_iter = writer_factory.find("BufferReaderWriter");
    if (writer_iter == writer_factory.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No MatfileWriter found");
    }
    shared_ptr<IHistory> writer(writer_iter->second.create(settings,dim));
    return writer;

  }
  shared_ptr<IHistory> createDefaultWriter(shared_ptr<IGlobalSettings> settings,size_t dim)
  {

    std::map<std::string, factory<IHistory,shared_ptr<IGlobalSettings>,size_t > >::iterator writer_iter;
    std::map<std::string, factory<IHistory,shared_ptr<IGlobalSettings>,size_t > >& writer_factory(_simobject_type_map->get());
    writer_iter = writer_factory.find("DefaultWriter");
    if (writer_iter == writer_factory.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"No MatfileWriter found");
    }
    shared_ptr<IHistory> writer(writer_iter->second.create(settings,dim));
    return writer;

  }


protected:
  virtual void initializeLibraries(PATH library_path,PATH modelicasystem_path,PATH config_path)
  {
    fs::path systemfactory_path = ObjectFactory<CreationPolicy>::_library_path;
    fs::path system_name(SYSTEM_LIB);
    systemfactory_path/=system_name;

    LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(systemfactory_path.string(), *_simobject_type_map);
    if (result != LOADER_SUCCESS)
    {
      std::stringstream tmp;
      tmp << "Failed loading System library!" << std::endl << systemfactory_path.string();
      throw ModelicaSimulationError(MODEL_FACTORY,tmp.str());
    }

    fs::path dataexchange_path = ObjectFactory<CreationPolicy>::_library_path;
    fs::path dataexchange_name(DATAEXCHANGE_LIB);
    dataexchange_path/=dataexchange_name;

    result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(dataexchange_path.string(), *_simobject_type_map);
    if (result != LOADER_SUCCESS)
    {
      throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading Dataexchange library!");
    }
  }


  type_map* _simobject_type_map;
};
/** @} */ // end of simcorefactoriesPolicies
