#pragma once
//#include <stdio.h>
#include <Core/SimController/ISimController.h>
#include <Core/Modelica.h>

class ISimController;

class VxWorksFactory
{
    public:
        VxWorksFactory(string library_path, string modelicasystem_path);
        ~VxWorksFactory();
        boost::shared_ptr<ISimController> LoadSimController();
        boost::shared_ptr<ISettingsFactory> LoadSettingsFactory();
        boost::shared_ptr<IAlgLoopSolverFactory> LoadAlgLoopSolverFactory(IGlobalSettings*);
        boost::shared_ptr<ISolver> LoadSolver(IMixedSystem* system, string solver_name,boost::shared_ptr<ISolverSettings> solver_settings);
        boost::shared_ptr<IMixedSystem> LoadSystem(IGlobalSettings*, boost::shared_ptr<IAlgLoopSolverFactory>, boost::shared_ptr<ISimData> simData);
        boost::shared_ptr<ISimData> LoadSimData();
        boost::shared_ptr<ISolverSettings> LoadSolverSettings(string solver_name,boost::shared_ptr<IGlobalSettings>);
        boost::shared_ptr<IAlgLoopSolver> LoadAlgLoopSolver(IAlgLoop* algLoop, string solver_name, boost::shared_ptr<INonLinSolverSettings> solver_settings);
        boost::shared_ptr<INonLinSolverSettings> LoadAlgLoopSolverSettings(string solver_name);
    private:
        string _library_path;
        string _modelicasystem_path;
};


