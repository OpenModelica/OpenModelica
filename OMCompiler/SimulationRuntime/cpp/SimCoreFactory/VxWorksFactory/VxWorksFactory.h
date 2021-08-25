#pragma once
/** @defgroup simcorefactoryVxworks SimCoreFactory.VxWorks
 *  Object factory for the Vxworks target
 *  @{
 */
#include <Core/SimController/ISimController.h>
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <SimCoreFactory/Policies/FactoryConfig.h>
/*
class ISimController;
*/

class VxWorksFactory
{
public:
    VxWorksFactory(string library_path, string modelicasystem_path);
    ~VxWorksFactory();
    shared_ptr<ISimController> LoadSimController();
    shared_ptr<ISettingsFactory> LoadSettingsFactory();
    shared_ptr<IAlgLoopSolverFactory> LoadAlgLoopSolverFactory(IGlobalSettings*);
    shared_ptr<ISolver> LoadSolver(IMixedSystem* system, string solver_name, shared_ptr<ISolverSettings> solver_settings);
    shared_ptr<IMixedSystem> LoadSystem(IGlobalSettings*,shared_ptr<ISimObjects> simObjects);
    shared_ptr<ISimData> LoadSimData();
    shared_ptr<ISimVars> LoadSimVars(size_t dim_real,size_t dim_int,size_t dim_bool, size_t dim_string, size_t dim_pre_vars,size_t dim_z,size_t z_i);


    shared_ptr<ISolverSettings> LoadSolverSettings(string solver_name, shared_ptr<IGlobalSettings>);
    shared_ptr<IAlgLoopSolver> LoadAlgLoopSolver(INonLinearAlgLoop* algLoop, string solver_name, shared_ptr<INonLinSolverSettings> solver_settings);
    shared_ptr<INonLinSolverSettings> LoadAlgLoopSolverSettings(string solver_name);

private:
    string _library_path;
    string _modelicasystem_path;
};
/** @} */ // end of simcorefactoryVxworks
