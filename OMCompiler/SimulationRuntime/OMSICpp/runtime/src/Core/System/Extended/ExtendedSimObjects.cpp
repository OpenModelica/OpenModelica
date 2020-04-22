/** @addtogroup coreSimcontroller
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/FactoryExport.h>

#include <Core/System/ExtendedSimObjects.h>


ExtendedSimObjects::ExtendedSimObjects(PATH library_path, PATH modelicasystem_path, shared_ptr<IGlobalSettings> globalSettings)
    : ExtendedSimObjectPolicy(library_path, modelicasystem_path, library_path)
    ,SimObjects(library_path, modelicasystem_path, globalSettings)
     
{
 
}

ExtendedSimObjects::ExtendedSimObjects(ExtendedSimObjects& instance) 
    : ExtendedSimObjectPolicy(instance)
    , SimObjects(instance)
{
   
    //clone sim_data
    for (std::map<string, shared_ptr<ISimData>>::iterator it = instance._sim_data.begin(); it != instance
        ._sim_data.end(); it++)
        _sim_data.insert(pair<string, shared_ptr<ISimData>>(it->first, shared_ptr<ISimData>(it->second->clone())));
   
    _write_output = instance.getWriter();
}





ExtendedSimObjects::~ExtendedSimObjects()
{
}


weak_ptr<ISimVars> ExtendedSimObjects::LoadSimVars(string modelKey, omsi_t* omsu)
{
    //if the simdata is already loaded
    std::map<string, shared_ptr<ISimVars>>::iterator iter = _sim_vars.find(modelKey);
    if (iter != _sim_vars.end())
    {
        //destroy system
        _sim_vars.erase(iter);
    }
    //create system
    shared_ptr<ISimVars> sim_vars = createExtendedSimVars(omsu);
    _sim_vars[modelKey] = sim_vars;
    return sim_vars;
}


weak_ptr<ISimData> ExtendedSimObjects::LoadSimData(string modelKey)
{
    //if the simdata is already loaded
    std::map<string, shared_ptr<ISimData>>::iterator iter = _sim_data.find(modelKey);
    if (iter != _sim_data.end())
    {
        //destroy system
        _sim_data.erase(iter);
    }
    //create system
    shared_ptr<ISimData> sim_data = createSimData();
    _sim_data[modelKey] = sim_data;
    return sim_data;
}



shared_ptr<ISimData> ExtendedSimObjects::getSimData(string modelname)
{
    std::map<string, shared_ptr<ISimData>>::iterator iter = _sim_data.find(modelname);
    if (iter != _sim_data.end())
    {
        return iter->second;
    }
    else
    {
        string error = string("Simulation data was not found for model: ") + modelname;
        throw ModelicaSimulationError(SIMMANAGER, error);
    }
}

void ExtendedSimObjects::eraseSimData(string modelname)
{
    // destroy simdata
    std::map<string, shared_ptr<ISimData>>::iterator iter = _sim_data.find(modelname);
    if (iter != _sim_data.end())
    {
        _sim_data.erase(iter);
    }
}

weak_ptr<IHistory> ExtendedSimObjects::LoadWriter(size_t dim)
{
    if (_globalSettings->getOutputFormat() == MAT)
    {
        _write_output = createMatFileWriter(_globalSettings, dim);
    }
    else if (_globalSettings->getOutputFormat() == CSV)
    {
        _write_output = createTextFileWriter(_globalSettings, dim);
    }
    else if (_globalSettings->getOutputFormat() == BUFFER)
    {
        _write_output = createBufferReaderWriter(_globalSettings, dim);
    }
    else if (_globalSettings->getOutputFormat() == EMPTY)
    {
        _write_output = createDefaultWriter(_globalSettings, dim);
    }
    else
    {
        throw ModelicaSimulationError(MODEL_FACTORY, "output format is not supported");
    }
    return _write_output;
}

shared_ptr<IHistory> ExtendedSimObjects::getWriter()
{
    return _write_output;
}


/** @} */ // end of coreSimcontroller
