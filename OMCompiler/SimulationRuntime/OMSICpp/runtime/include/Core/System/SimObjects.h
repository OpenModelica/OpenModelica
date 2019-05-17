#pragma once
/** @addtogroup coreSimcontroller
 *
 *  @{
 */
 //omsi header

#include <Core/System/ISimObjects.h>
#include <SimCoreFactory/Policies/FactoryPolicy.h>
class SimObjects : public ISimObjects, public SimObjectPolicy
{
public:
    SimObjects(PATH library_path, PATH modelicasystem_path,shared_ptr<IGlobalSettings> globalSettings);
    SimObjects(SimObjects &instance);
    virtual ~SimObjects();
    virtual weak_ptr<ISimData> LoadSimData(string modelKey);
    virtual weak_ptr<ISimVars> LoadSimVars(string modelKey, size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars, size_t dim_z, size_t z_i);
	virtual weak_ptr<ISimVars> LoadSimVars(string modelKey, omsi_t* omsu);
	virtual shared_ptr<ISimData> getSimData(string modelname);
    virtual shared_ptr<ISimVars> getSimVars(string modelname);
    virtual void eraseSimData(string modelname);
    virtual void eraseSimVars(string modelname);
    virtual shared_ptr<IAlgLoopSolverFactory> getAlgLoopSolverFactory();
    virtual shared_ptr<IGlobalSettings> getGlobalSettings();
    virtual shared_ptr<IHistory> getWriter();
    virtual weak_ptr<IHistory> LoadWriter(size_t dim);
    virtual ISimObjects* clone();
private:
    std::map<string, shared_ptr<ISimData> > _sim_data;
    std::map<string, shared_ptr<ISimVars> > _sim_vars;
	shared_ptr<IAlgLoopSolverFactory> _algloopsolverfactory;
    shared_ptr<IGlobalSettings> _globalSettings;
	shared_ptr<IHistory> _write_output;
};
/** @} */ // end of coreSimcontroller
