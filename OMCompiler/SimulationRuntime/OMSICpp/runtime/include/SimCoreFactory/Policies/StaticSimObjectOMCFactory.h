#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */

shared_ptr<ISimData> createSimDataFunction();
shared_ptr<ISimVars> createSimVarsFunction(size_t dim_real,size_t dim_int,size_t dim_bool,size_t dim_string,size_t dim_pre_vars,size_t dim_z,size_t z_i);
shared_ptr<ISimVars> createSimVarsFunction(omsi_t* omsu);
shared_ptr<IAlgLoopSolverFactory> createStaticAlgLoopSolverFactory(shared_ptr<IGlobalSettings> globalSettings,PATH library_path,PATH modelicasystem_path);

shared_ptr<IHistory> createMatFileWriterFactory(shared_ptr<IGlobalSettings> globalSettings,size_t dim);
shared_ptr<IHistory> createTextFileWriterFactory(shared_ptr<IGlobalSettings> globalSettings,size_t dim);
shared_ptr<IHistory> createBufferReaderWriterFactory(shared_ptr<IGlobalSettings> globalSettings,size_t dim);
shared_ptr<IHistory> createDefaultWriterFactory(shared_ptr<IGlobalSettings> globalSettings,size_t dim);
/*
Policy class to create a OMC-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct StaticSimObjectOMCFactory: public  ObjectFactory<CreationPolicy>
{
public:
  StaticSimObjectOMCFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
    :ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
  {

  }

  virtual ~StaticSimObjectOMCFactory()
  {
  }

  shared_ptr<ISimData> createSimData()
  {
    return createSimDataFunction();
  }

  shared_ptr<ISimVars> createSimVars(size_t dim_real,size_t dim_int,size_t dim_bool,size_t dim_string,size_t dim_pre_vars,size_t dim_z,size_t z_i)
  {
    return createSimVarsFunction(dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_z, z_i);
  }
  shared_ptr<ISimVars> createSimVars(omsi_t* omsu)
  {
	  return createSimVarsFunction(omsu);
  }

  shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(shared_ptr<IGlobalSettings> globalSettings)
  {
    return createStaticAlgLoopSolverFactory(globalSettings,ObjectFactory<CreationPolicy>::_library_path,ObjectFactory<CreationPolicy>::_modelicasystem_path);
  }
 shared_ptr<IHistory> createMatFileWriter(shared_ptr<IGlobalSettings> settings,size_t dim)
  {

    shared_ptr<IHistory> writer = createMatFileWriterFactory(settings,dim);
    return writer;

  }
  shared_ptr<IHistory> createTextFileWriter(shared_ptr<IGlobalSettings> settings,size_t dim)
  {

    shared_ptr<IHistory> writer = createTextFileWriterFactory(settings,dim);
    return writer;

  }
  shared_ptr<IHistory> createBufferReaderWriter(shared_ptr<IGlobalSettings> settings,size_t dim)
  {

    shared_ptr<IHistory> writer = createBufferReaderWriterFactory(settings,dim);
    return writer;

  }
  shared_ptr<IHistory> createDefaultWriter(shared_ptr<IGlobalSettings> settings,size_t dim)
  {

    shared_ptr<IHistory> writer = createDefaultWriterFactory(settings,dim);
    return writer;

  }


};
/** @} */ // end of simcorefactoriesPolicies
