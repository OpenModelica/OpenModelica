#pragma once
/** @addtogroup coreSimcontroller
 *
 *  @{
 */
//omsi header

#include <Core/System/SimObjects.h>
#include <Core/System/IExtendedSimObjects.h>
#include <SimCoreFactory/Policies/FactoryPolicy.h>

class ExtendedSimObjects : public IExtendedSimObjects,  public SimObjects, public ExtendedSimObjectPolicy
{
public:
    ExtendedSimObjects(PATH library_path, PATH modelicasystem_path, shared_ptr<IGlobalSettings> globalSettings);
    ExtendedSimObjects(ExtendedSimObjects& instance);
    virtual ~ExtendedSimObjects();
    virtual weak_ptr<ISimData> LoadSimData(string modelKey);
    virtual weak_ptr<IHistory> LoadWriter(size_t dim);
    virtual shared_ptr<IHistory> getWriter();
    virtual shared_ptr<ISimData> getSimData(string modelname);
    virtual void eraseSimData(string modelname);
    virtual weak_ptr<ISimVars> LoadSimVars(string modelKey, omsi_t* omsu);
    
  
private:
    std::map<string, shared_ptr<ISimData>> _sim_data;
    shared_ptr<IHistory> _write_output;
};

/** @} */ // end of coreSimcontroller
