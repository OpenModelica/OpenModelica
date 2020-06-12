#pragma once
/** @defgroup simcorefactoryBodas SimCoreFactory.BodasFactory
 *  Object factories for the Bodas target
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

class ISimController;
class ISettingsFactory;

class BodasFactory
{
public:
    BodasFactory(std::string library_path, std::string modelicasystem_path);
    shared_ptr<ISimController> LoadSimController();
    shared_ptr<ISettingsFactory> LoadSettingsFactory();
    shared_ptr<IAlgLoopSolverFactory> LoadAlgLoopSolverFactory(IGlobalSettings*);
    shared_ptr<ISolver> LoadSolver(IMixedSystem* system, string solver_name, shared_ptr<ISolverSettings> solver_settings);
    shared_ptr<IMixedSystem> LoadSystem(IGlobalSettings*,  shared_ptr<ISimObjects> simObjects);
    shared_ptr<ISimData> LoadSimData();
    shared_ptr<ISolverSettings> LoadSolverSettings(string solver_name, shared_ptr<IGlobalSettings>);
    shared_ptr<IAlgLoopSolver> LoadAlgLoopSolver(INonLinearAlgLoop* algLoop, string solver_name, shared_ptr<INonLinSolverSettings> solver_settings);
    shared_ptr<INonLinSolverSettings> LoadAlgLoopSolverSettings(string solver_name);

private:
    string _library_path;
    string _modelicasystem_path;
};
/** @} */ // end of simcorefactoryBodas