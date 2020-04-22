#pragma once
/** @addtogroup coreSimcontroller
 *
 *  @{
 */


 
 //OpenModelcia Simulation Interface Header
 #include <omsi.h>
 
 /**
 *
 */
class IExtendedSimObjects
{
public:

    virtual ~IExtendedSimObjects()
    {
    };
    virtual weak_ptr<IHistory> LoadWriter(size_t) = 0;
    virtual shared_ptr<ISimData> getSimData(string modelname) = 0;
    virtual weak_ptr<ISimData> LoadSimData(string modelKey) = 0;
    virtual void eraseSimData(string modelname) = 0;
    virtual weak_ptr<ISimVars> LoadSimVars(string modelKey, omsi_t* omsu) = 0;


};

/** @} */ // end of coreSimcontroller
