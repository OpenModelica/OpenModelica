#pragma once
/** @addtogroup coreSimcontroller
 *
 *  @{
 */
//omsi header

#include <Core/System/ISimObjects.h>
#include <SimCoreFactory/Policies/FactoryPolicy.h>

class  BOOST_EXTENSION_SIMOBJECTS_DECL SimObjects : public ISimObjects, public SimObjectPolicy
{
public:
    SimObjects(PATH library_path, PATH modelicasystem_path, shared_ptr<IGlobalSettings> globalSettings);
    SimObjects(SimObjects& instance);
    virtual ~SimObjects();
    
    virtual weak_ptr<ISimVars> LoadSimVars(string modelKey, size_t dim_real, size_t dim_int, size_t dim_bool,
                                           size_t dim_string, size_t dim_pre_vars, size_t dim_z, size_t z_i);
  
    virtual shared_ptr<ISimVars> getSimVars(string modelname);
   
    virtual void eraseSimVars(string modelname);
    virtual shared_ptr<IAlgLoopSolverFactory> getAlgLoopSolverFactory();
    virtual shared_ptr<IGlobalSettings> getGlobalSettings();
    
    
    virtual ISimObjects* clone();
protected:
    
    std::map<string, shared_ptr<ISimVars>> _sim_vars;
    shared_ptr<IAlgLoopSolverFactory> _algloopsolverfactory;
    shared_ptr<IGlobalSettings> _globalSettings;

};

/** @} */ // end of coreSimcontroller
