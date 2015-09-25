#pragma once
/** @addtogroup coreSimcontroller
 *
 *  @{
 */
#include <Core/SimController/SimManager.h>
#include <Core/SimController/ISimController.h>

class SimController : public ISimController,
                      public SimControllerPolicy
{
public:
    SimController(PATH library_path, PATH modelicasystem_path);
    virtual ~SimController();
    /*
    #if defined(__vxworks) || defined(__TRICORE__)
    #else
    virtual std::pair<shared_ptr<IMixedSystem>,shared_ptr<ISimData> > LoadSystem(shared_ptr<ISimData> (*createSimDataCallback)(), shared_ptr<IMixedSystem> (*createSystemCallback)(IGlobalSettings*, shared_ptr<IAlgLoopSolverFactory>, shared_ptr<ISimData>), string modelKey);
    #endif
    */
    virtual weak_ptr<IMixedSystem> LoadSystem(string modelLib,string modelKey);
    virtual weak_ptr<IMixedSystem> LoadModelicaSystem(PATH modelica_path,string modelKey);
    virtual weak_ptr<ISimData> LoadSimData(string modelKey);
    virtual weak_ptr<ISimVars> LoadSimVars(string modelKey, size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars, size_t dim_z, size_t z_i);
    /// Stops the simulation
    virtual void Stop();
    virtual void Start(SimSettings simsettings, string modelKey);
    virtual void StartVxWorks(SimSettings simsettings, string modelKey);
    virtual weak_ptr<ISimData> getSimData(string modelname);
    virtual weak_ptr<ISimVars> getSimVars(string modelname);
    virtual weak_ptr<IMixedSystem> getSystem(string modelname);
    virtual void calcOneStep();

private:
    void initialize(PATH library_path, PATH modelicasystem_path);
    bool _initialized;
    shared_ptr<Configuration> _config;
    std::map<string, shared_ptr<IMixedSystem> > _systems;
    std::map<string, shared_ptr<ISimData> > _sim_data;
    std::map<string, shared_ptr<ISimVars> > _sim_vars;
    shared_ptr<IAlgLoopSolverFactory> _algloopsolverfactory;

    // for real-time usage (VxWorks and BODAS)
    //removed, has to be released after simulation run, see SimController.Start
    shared_ptr<SimManager> _simMgr;

    #ifdef RUNTIME_PROFILING
    std::vector<MeasureTimeData*> *measureTimeFunctionsArray;
    MeasureTimeValues *measuredFunctionStartValues, *measuredFunctionEndValues;
    #endif
};
/** @} */ // end of coreSimcontroller
