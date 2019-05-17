/** @addtogroup coreSimcontroller
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/SimObjects.h>


SimObjects::SimObjects(PATH library_path, PATH modelicasystem_path,shared_ptr<IGlobalSettings> globalSettings)
    : SimObjectPolicy(library_path, modelicasystem_path, library_path)
      ,_globalSettings(globalSettings)
{
    _algloopsolverfactory = createAlgLoopSolverFactory(globalSettings);
}

SimObjects::SimObjects(SimObjects& instance) : SimObjectPolicy(instance)
{
    //clone sim_data
    for(std::map<string, shared_ptr<ISimData> >::iterator it = instance._sim_data.begin(); it != instance._sim_data.end(); it++)
        _sim_data.insert(pair<string, shared_ptr<ISimData> >(it->first, shared_ptr<ISimData>(it->second->clone())));

    //clone sim_vars
    for(std::map<string, shared_ptr<ISimVars> >::iterator it = instance._sim_vars.begin(); it != instance._sim_vars.end(); it++)
        _sim_vars.insert(pair<string, shared_ptr<ISimVars> >(it->first, shared_ptr<ISimVars>(it->second->clone())));

    _algloopsolverfactory = instance.getAlgLoopSolverFactory();
    _globalSettings = instance.getGlobalSettings();
    _write_output = instance.getWriter();
}

SimObjects::~SimObjects()
{

}

weak_ptr<ISimData> SimObjects::LoadSimData(string modelKey)
{
    //if the simdata is already loaded
    std::map<string,shared_ptr<ISimData> > ::iterator iter = _sim_data.find(modelKey);
    if(iter != _sim_data.end())
    {
        //destroy system
        _sim_data.erase(iter);
    }
    //create system
    shared_ptr<ISimData> sim_data = createSimData();
    _sim_data[modelKey] = sim_data;
    return sim_data;
}

weak_ptr<ISimVars> SimObjects::LoadSimVars(string modelKey, size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars, size_t dim_z, size_t z_i)
{
    //if the simdata is already loaded
    std::map<string,shared_ptr<ISimVars> > ::iterator iter = _sim_vars.find(modelKey);
    if(iter != _sim_vars.end())
    {
        //destroy system
        _sim_vars.erase(iter);
    }
    //create system
    shared_ptr<ISimVars> sim_vars = createSimVars(dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_z,z_i);
    _sim_vars[modelKey] = sim_vars;
    return sim_vars;
}
weak_ptr<ISimVars> SimObjects::LoadSimVars(string modelKey, omsi_t* omsu)
{
	//if the simdata is already loaded
	std::map<string, shared_ptr<ISimVars> > ::iterator iter = _sim_vars.find(modelKey);
	if (iter != _sim_vars.end())
	{
		//destroy system
		_sim_vars.erase(iter);
	}
	//create system
	shared_ptr<ISimVars> sim_vars = createSimVars(omsu);
	_sim_vars[modelKey] = sim_vars;
	return sim_vars;

}

shared_ptr<ISimData> SimObjects::getSimData(string modelname)
{
    std::map<string,shared_ptr<ISimData> >::iterator iter = _sim_data.find(modelname);
    if(iter != _sim_data.end())
    {
        return iter->second;
    }
    else
    {
        string error = string("Simulation data was not found for model: ") + modelname;
        throw ModelicaSimulationError(SIMMANAGER,error);
    }
}

shared_ptr<ISimVars> SimObjects::getSimVars(string modelname)
{
    std::map<string,shared_ptr<ISimVars> >::iterator iter = _sim_vars.find(modelname);
    if(iter != _sim_vars.end())
    {
        return iter->second;
    }
    else
    {
        string error = string("Simulation data was not found for model: ") + modelname;
        throw ModelicaSimulationError(SIMMANAGER,error);
    }
}

void SimObjects::eraseSimData(string modelname)
{
     // destroy simdata
    std::map<string,shared_ptr<ISimData> >::iterator iter = _sim_data.find(modelname);
    if(iter != _sim_data.end())
    {
        _sim_data.erase(iter);
    }
}

void SimObjects::eraseSimVars(string modelname)
{

      // destroy simdata
    std::map<string,shared_ptr<ISimVars> >::iterator iter = _sim_vars.find(modelname);
    if(iter != _sim_vars.end())
    {
        _sim_vars.erase(iter);
    }

}

shared_ptr<IAlgLoopSolverFactory> SimObjects::getAlgLoopSolverFactory()
{
   return _algloopsolverfactory;
}

 weak_ptr<IHistory> SimObjects::LoadWriter(size_t dim)
{

    if( _globalSettings->getOutputFormat() == MAT)
    {
        _write_output = createMatFileWriter(_globalSettings,dim);
    }
    else if( _globalSettings->getOutputFormat()  == CSV)
    {
        _write_output = createTextFileWriter(_globalSettings,dim);
    }
    else if( _globalSettings->getOutputFormat()  == BUFFER)
    {
        _write_output = createBufferReaderWriter(_globalSettings,dim);
    }
    else if( _globalSettings->getOutputFormat()  == EMPTY)
    {
        _write_output = createDefaultWriter(_globalSettings,dim);
    }
    else
    {
        throw ModelicaSimulationError(MODEL_FACTORY,"output format is not supported");
    }
    return _write_output;
}

ISimObjects* SimObjects::clone()
{
    return new SimObjects(*this);
}

shared_ptr<IGlobalSettings> SimObjects::getGlobalSettings()
{
    return _globalSettings;
}

shared_ptr<IHistory> SimObjects::getWriter()
{
    return _write_output;
}
/** @} */ // end of coreSimcontroller
