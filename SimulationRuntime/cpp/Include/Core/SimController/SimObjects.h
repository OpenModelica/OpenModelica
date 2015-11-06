#pragma once
/** @addtogroup coreSimcontroller
 *
 *  @{
 */

#include <Core/SimController/ISimObjects.h>
#include <SimCoreFactory/Policies/FactoryPolicy.h>
class SimObjects : public ISimObjects, public SimObjectPolicy
{
public:
    SimObjects(PATH library_path, PATH modelicasystem_path,IGlobalSettings* globalSettings);
    virtual ~SimObjects();
    virtual weak_ptr<ISimData> LoadSimData(string modelKey);
    virtual weak_ptr<ISimVars> LoadSimVars(string modelKey, size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars, size_t dim_z, size_t z_i);
    virtual shared_ptr<ISimData> getSimData(string modelname);
    virtual shared_ptr<ISimVars> getSimVars(string modelname);
    virtual void eraseSimData(string modelname);
    virtual void eraseSimVars(string modelname);
    virtual shared_ptr<IAlgLoopSolverFactory> getAlgLoopSolverFactory();
    virtual weak_ptr<IHistory> LoadWriter(size_t dim);
private:
    std::map<string, shared_ptr<ISimData> > _sim_data;
    std::map<string, shared_ptr<ISimVars> > _sim_vars;
	shared_ptr<IAlgLoopSolverFactory> _algloopsolverfactory;
    IGlobalSettings* _globalSettings;
	shared_ptr<IHistory> _write_output;
};
/** @} */ // end of coreSimcontroller
