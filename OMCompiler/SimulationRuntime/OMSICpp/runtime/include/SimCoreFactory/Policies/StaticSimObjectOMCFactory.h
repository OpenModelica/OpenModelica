#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */


shared_ptr<ISimVars> createSimVarsFunction(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string,
                                           size_t dim_pre_vars, size_t dim_z, size_t z_i);

shared_ptr<IAlgLoopSolverFactory> createStaticAlgLoopSolverFactory(shared_ptr<IGlobalSettings> globalSettings,
                                                                   PATH library_path, PATH modelicasystem_path);


/*
Policy class to create a OMC-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct StaticSimObjectOMCFactory : public ObjectFactory<CreationPolicy>
{
public:
    StaticSimObjectOMCFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    {
    }

    virtual ~StaticSimObjectOMCFactory()
    {
    }

   
    shared_ptr<ISimVars> createSimVars(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string,
                                       size_t dim_pre_vars, size_t dim_z, size_t z_i)
    {
        return createSimVarsFunction(dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_z, z_i);
    }
   
    shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(shared_ptr<IGlobalSettings> globalSettings)
    {
        return createStaticAlgLoopSolverFactory(globalSettings, ObjectFactory<CreationPolicy>::_library_path,
                                                ObjectFactory<CreationPolicy>::_modelicasystem_path);
    }

   
};

/** @} */ // end of simcorefactoriesPolicies
