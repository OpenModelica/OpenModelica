/** @addtogroup coreSimcontroller
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/SimController/ISimController.h>
#include <Core/SimController/SimController.h>
#include <Core/SimController/Configuration.h>
#include <Core/SimController/SimObjects.h>
#if defined(OMC_BUILD) || defined(SIMSTER_BUILD)
#include "LibrariesConfig.h"
#endif


SimController::SimController(PATH library_path, PATH modelicasystem_path)
    : SimControllerPolicy(library_path, modelicasystem_path, library_path)
    , _initialized(false)
{
    _config = shared_ptr<Configuration>(new Configuration(_library_path, _config_path, modelicasystem_path));
    _sim_objects = shared_ptr<ISimObjects>(new SimObjects(_library_path,modelicasystem_path,_config->getGlobalSettings().get()));

    #ifdef RUNTIME_PROFILING
    measuredFunctionStartValues = NULL;
    measuredFunctionEndValues = NULL;

    if(MeasureTime::getInstance() != NULL)
    {
        measureTimeFunctionsArray = new std::vector<MeasureTimeData*>(2, NULL); //0 initialize //1 solveInitialSystem
        (*measureTimeFunctionsArray)[0] = new MeasureTimeData("initialize");
        (*measureTimeFunctionsArray)[1] = new MeasureTimeData("solveInitialSystem");

        measuredFunctionStartValues = MeasureTime::getZeroValues();
        measuredFunctionEndValues = MeasureTime::getZeroValues();
    }
    else
    {
      measureTimeFunctionsArray = new std::vector<MeasureTimeData*>();
    }
    #endif
}

SimController::~SimController()
{
    #ifdef RUNTIME_PROFILING
    if(measuredFunctionStartValues)
      delete measuredFunctionStartValues;
    if(measuredFunctionEndValues)
      delete measuredFunctionEndValues;
    #endif
}

weak_ptr<IMixedSystem> SimController::LoadSystem(string modelLib,string modelKey)
{

    //if the model is already loaded
    std::map<string,shared_ptr<IMixedSystem> >::iterator iter = _systems.find(modelKey);
    if(iter != _systems.end())
    {
        _sim_objects->eraseSimData(modelKey);
        _sim_objects->eraseSimVars(modelKey);
        //destroy system
        _systems.erase(iter);
    }
     //create system
    shared_ptr<IMixedSystem> system = createSystem(modelLib, modelKey, _config->getGlobalSettings().get(), _sim_objects);
    _systems[modelKey] = system;
    return system;
}

weak_ptr<IMixedSystem> SimController::LoadModelicaSystem(PATH modelica_path,string modelKey)
{
    if(_use_modelica_compiler)
    {
        // if the modell is already loaded
        std::map<string,shared_ptr<IMixedSystem> >::iterator iter = _systems.find(modelKey);
        if(iter != _systems.end())
        {
            _sim_objects->eraseSimData(modelKey);
            _sim_objects->eraseSimVars(modelKey);
            // destroy system
            _systems.erase(iter);
        }

        shared_ptr<IMixedSystem> system = createModelicaSystem(modelica_path, modelKey, _config->getGlobalSettings().get(),_sim_objects);
        _systems[modelKey] = system;
        return system;
    }
    else
        throw ModelicaSimulationError(SIMMANAGER,"No Modelica Compiler configured");
}


 shared_ptr<ISimObjects> SimController::getSimObjects()
 {

    return _sim_objects;

 }

shared_ptr<IMixedSystem> SimController::getSystem(string modelname)
{
    std::map<string,shared_ptr<IMixedSystem> >::iterator iter = _systems.find(modelname);
    if(iter!=_systems.end())
    {
        return iter->second;
    }
    else
    {
        string error = string("Simulation data was not found for model: ") + modelname;
        throw ModelicaSimulationError(SIMMANAGER,error);
    }
}



// Added for real-time simulation using VxWorks and Bodas
void SimController::StartVxWorks(SimSettings simsettings,string modelKey)
{
    try
    {
        shared_ptr<IMixedSystem> mixedsystem = getSystem(modelKey);
         shared_ptr<IGlobalSettings> global_settings = _config->getGlobalSettings();

        global_settings->useEndlessSim(true);
        global_settings->setStartTime(simsettings.start_time);
        global_settings->setEndTime(simsettings.end_time);
        global_settings->sethOutput(simsettings.step_size);
        global_settings->setResultsFileName(simsettings.outputfile_name);
        global_settings->setSelectedLinSolver(simsettings.linear_solver_name);
        global_settings->setSelectedNonLinSolver(simsettings.nonlinear_solver_name);
        global_settings->setSelectedSolver(simsettings.solver_name);
        global_settings->setAlarmTime(simsettings.timeOut);
        global_settings->setLogSettings(simsettings.logSettings);
        global_settings->setOutputPointType(simsettings.outputPointType);
        global_settings->setOutputFormat(simsettings.outputFormat);
        global_settings->setEmitResults(simsettings.emitResults);
        /*shared_ptr<SimManager>*/ _simMgr = shared_ptr<SimManager>(new SimManager(mixedsystem, _config.get()));

        ISolverSettings* solver_settings = _config->getSolverSettings();
        solver_settings->setLowerLimit(simsettings.lower_limit);
        solver_settings->sethInit(simsettings.lower_limit);
        solver_settings->setUpperLimit(simsettings.upper_limit);
        solver_settings->setRTol(simsettings.tolerance);
        solver_settings->setATol(simsettings.tolerance);

        _simMgr->initialize();
    }
    catch( ModelicaSimulationError& ex)
    {
        string error = add_error_info(string("Simulation failed for ") + simsettings.outputfile_name,ex.what(),ex.getErrorID());
        printf("Fehler %s\n", error.c_str());
        throw ModelicaSimulationError(SIMMANAGER,error);
    }
}

// Added for real-time simulation using VxWorks and Bodas
void SimController::calcOneStep()
{
    _simMgr->runSingleStep();
}

void SimController::Start(SimSettings simsettings, string modelKey)
{
    try
    {
        #ifdef RUNTIME_PROFILING
        MEASURETIME_REGION_DEFINE(simControllerInitializeHandler, "SimControllerInitialize");
        MEASURETIME_REGION_DEFINE(simControllerSolveInitialSystemHandler, "SimControllerSolveInitialSystem");
        if(MeasureTime::getInstance() != NULL)
        {
            MEASURETIME_START(measuredFunctionStartValues, simControllerInitializeHandler, "CVodeWriteOutput");
        }
        #endif
        shared_ptr<IMixedSystem> mixedsystem = getSystem(modelKey);

        shared_ptr<IGlobalSettings> global_settings = _config->getGlobalSettings();

        global_settings->setStartTime(simsettings.start_time);
        global_settings->setEndTime(simsettings.end_time);
        global_settings->sethOutput(simsettings.step_size);
        global_settings->setResultsFileName(simsettings.outputfile_name);
        global_settings->setSelectedLinSolver(simsettings.linear_solver_name);
        global_settings->setSelectedNonLinSolver(simsettings.nonlinear_solver_name);
        global_settings->setSelectedSolver(simsettings.solver_name);
        global_settings->setLogSettings(simsettings.logSettings);
        global_settings->setAlarmTime(simsettings.timeOut);
        global_settings->setOutputPointType(simsettings.outputPointType);
        global_settings->setOutputFormat(simsettings.outputFormat);
        global_settings->setEmitResults(simsettings.emitResults);
        global_settings->setNonLinearSolverContinueOnError(simsettings.nonLinearSolverContinueOnError);
        global_settings->setSolverThreads(simsettings.solverThreads);
        /*shared_ptr<SimManager>*/ _simMgr = shared_ptr<SimManager>(new SimManager(mixedsystem, _config.get()));

        ISolverSettings* solver_settings = _config->getSolverSettings();
        solver_settings->setLowerLimit(simsettings.lower_limit);
        solver_settings->sethInit(simsettings.lower_limit);
        solver_settings->setUpperLimit(simsettings.upper_limit);
        solver_settings->setRTol(simsettings.tolerance);
        solver_settings->setATol(simsettings.tolerance);
        #ifdef RUNTIME_PROFILING
        if(MeasureTime::getInstance() != NULL)
        {
            MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[0], simControllerInitializeHandler);
            measuredFunctionStartValues->reset();
            measuredFunctionEndValues->reset();
            MEASURETIME_START(measuredFunctionStartValues, simControllerSolveInitialSystemHandler, "SolveInitialSystem");
        }
        #endif

        _simMgr->initialize();

        #ifdef RUNTIME_PROFILING
        if(MeasureTime::getInstance() != NULL)
        {
            MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[1], simControllerSolveInitialSystemHandler);
            MeasureTime::addResultContentBlock(mixedsystem->getModelName(),"simController",measureTimeFunctionsArray);
        }
        #endif

        _simMgr->runSimulation();

		if(global_settings->getOutputFormat() == BUFFER)
		{
			shared_ptr<IWriteOutput> writeoutput_system = dynamic_pointer_cast<IWriteOutput>(mixedsystem);

			shared_ptr<ISimData> simData = _sim_objects->getSimData(modelKey);
			simData->clearResults();
			//get history object to query simulation results
			IHistory* history = writeoutput_system->getHistory();
			//simulation results (output variables)
			ublas::matrix<double> Ro;
			//query simulation result outputs
			history->getOutputResults(Ro);
			vector<string> output_names;
			history->getOutputNames(output_names);
			int j=0;

			FOREACH(string& name, output_names)
			{
				ublas::vector<double> o_j;
				o_j = ublas::row(Ro,j);
				simData->addOutputResults(name,o_j);
				j++;
			}

			vector<double> time_values = history->getTimeEntries();
			simData->addTimeEntries(time_values);
		}
    }
    catch(ModelicaSimulationError & ex)
    {
        string error = add_error_info(string("Simulation failed for ") + simsettings.outputfile_name,ex.what(),ex.getErrorID());
        throw ModelicaSimulationError(SIMMANAGER,error);
    }
}

void SimController::Stop()
{
    if(_simMgr)
    _simMgr->stopSimulation();
}
/** @} */ // end of coreSimcontroller
