/** @addtogroup coreSimcontroller
 *
 *  @{
 */


#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#ifdef USE_REDUCE_DAE
#include <Core/ReduceDAE/IReduceDAE.h>
#include <core/ReduceDAE/ReduceDAESettings.h>
#include <core/ReduceDAE/Ranking.h>
#include <core/ReduceDAE/Reduction.h>
#include <core/ReduceDAE/com/ModelicaCompiler.h>
#endif



#include <Core/SimController/ISimController.h>
#include <Core/SimController/SimController.h>
#include <Core/SimController/Configuration.h>



#if defined(OMC_BUILD) || defined(SIMSTER_BUILD)
#include "LibrariesConfig.h"
#endif


SimController::SimController(PATH library_path, PATH modelicasystem_path)
    : SimControllerPolicy(library_path, modelicasystem_path, library_path)
    , _initialized(false)
{
    _config = shared_ptr<Configuration>(new Configuration(_library_path, _config_path, modelicasystem_path));


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
        shared_ptr<ISimObjects> simObjects = iter->second->getSimObjects();
        simObjects->eraseSimData(modelKey);
        simObjects->eraseSimVars(modelKey);
        //destroy system
        _systems.erase(iter);
    }
     //create system
     shared_ptr<IMixedSystem> system = createSystem(modelLib, modelKey, _config->getGlobalSettings());
    _systems[modelKey] = system;
    return system;
}
weak_ptr<IMixedSystem>  SimController::LoadOSUSystem(string osu_name,string osu_key)
{

     //if the model is already loaded
    std::map<string,shared_ptr<IMixedSystem> >::iterator iter = _systems.find(osu_key);
    if(iter != _systems.end())
    {
        shared_ptr<ISimObjects> simObjects = iter->second->getSimObjects();
        simObjects->eraseSimData(osu_key);
        simObjects->eraseSimVars(osu_key);
        //destroy system
        _systems.erase(iter);
    }
     //create system
     shared_ptr<IMixedSystem> system = createOSUSystem(osu_name, _config->getGlobalSettings());
    _systems[osu_key] = system;
    return system;


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

 void SimController::runReducedSimulation()
 {
     _simMgr->runSimulation();
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
        global_settings->setInputPath(simsettings.inputPath);
        global_settings->setOutputPath(simsettings.outputPath);
        global_settings->setInitfilePath(simsettings.initFile);
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

			 shared_ptr<ISimObjects> simObjects =mixedsystem->getSimObjects();
            shared_ptr<ISimData> simData = simObjects->getSimData(modelKey);
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
        throw ModelicaSimulationError(SIMMANAGER, error, "", ex.isSuppressed());
    }
}

void SimController::StartReduceDAE(SimSettings simsettings,string modelPath, string modelKey,bool loadMSL, bool loadPackage)
{
    #ifdef USE_REDUCE_DAE
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
        // global_settings->setAlarmTime(2);
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
         //read reduced settings
        ReduceDAESettings reduce_settings(global_settings.get());
		reduce_settings.load("ReduceDAESettings.xml");
        Ranking ranking(mixedsystem,&reduce_settings);
        Reduction reduction(mixedsystem,&reduce_settings);
        #ifdef USE_CHRONO
        auto startSim1 = high_resolution_clock::now();
        #endif
        _simMgr->initialize();
        _simMgr->SetCheckTimeout(true);
        #ifdef RUNTIME_PROFILING
        if(MeasureTime::getInstance() != NULL)
        {
            MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[1], simControllerSolveInitialSystemHandler);
            MeasureTime::addResultContentBlock(mixedsystem->getModelName(),"simController",measureTimeFunctionsArray);
        }
        #endif


		_simMgr->runSimulation();
        #ifdef USE_CHRONO
         auto endSim1 = high_resolution_clock::now();
         double timeout= duration_cast<std::chrono::duration<double>>(endSim1-startSim1).count();
         std::cout <<" time of first simulation: "<< timeout << " seconds" << std::endl;
        #endif
        IReduceDAE* reduce_dae = dynamic_cast<IReduceDAE*>(mixedsystem.get());
        if(reduce_dae==NULL)
		{
			throw std::runtime_error("Modelica System is not of type IReduceDAE!!!");
		}



		//get history object to query simulation results
		IHistory* history = reduce_dae->getHistory();
        vector<double> time_values = history->getTimeEntries();
         cout << "time_values: " << time_values.size() << std::endl;

		//simulation results (algebraic and state variables)
		ublas::matrix<double> R;
		//simulation results (derivative variables)
		ublas::matrix<double> dR;
		//simulation results (residues)
		ublas::matrix<double> Re;
		//simulation results (output variables)
		ublas::matrix<double> Ro;
		//query simulation results
		history->getSimResults(R,dR,Re);

         cout << "number of derivatives: " << dR.size1() << std::endl;
        cout << "number of variables: " << R.size1() << std::endl;
        cout << "number of residual: " << Re.size1() << std::endl;
		history->getOutputResults(Ro);
       cout << "number of output " << Ro.size1() << std::endl;
        vector<string> output_names;
		 history->getOutputNames(output_names);


        label_list_type labels;


        //----------------------------------------------------------------------------------------------------------------
         //start  ranking


        if(reduce_settings.getRankingMethod()==IReduceDAESettings::RESIDUEN)
        {
         #ifdef USE_CHRONO
         auto start = high_resolution_clock::now();
         #endif
         //start  residue ranking
         labels =ranking.residuenRanking(R,dR,Re,time_values);
         #ifdef USE_CHRONO
         auto end = high_resolution_clock::now();
         std::cout <<" time of residual ranking: "<< std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count() << " milliseconds" << std::endl;
         #endif
        }


        else if(reduce_settings.getRankingMethod()==IReduceDAESettings::PERFECT)
        {
         #ifdef USE_CHRONO
          //start  perfect ranking
           auto start = high_resolution_clock::now();
         #endif
         labels = ranking.perfectRanking(Ro,mixedsystem,&reduce_settings,simsettings,modelKey,output_names,timeout,this);
         #ifdef USE_CHRONO
         auto end =  high_resolution_clock::now();
         std::cout <<" time of perfect ranking: "<< std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count() << " milliseconds" << std::endl;
         #endif
        }


        else if(reduce_settings.getRankingMethod()==IReduceDAESettings::NORANKING)
        {
            //without ranking, get all labels without any sorting and pass it to the redction
            labels=reduce_dae->getLabels();
        }


        std::cout<<"sorted labels: "<<"\n";
        FOREACH(label_type  label, labels)
		{
            std::cout<<"label "<< get<0>(label)<<"\n";

        }



         //----------------------------------------------------------------------------------------------------------------
         //start reduction
		std::vector<unsigned int> terms = reduction.cancelTerms(labels,Ro,mixedsystem,&reduce_settings,simsettings,modelKey,output_names,timeout,this);

        if(terms.size()>0)
        {

         //------------------------------------------------------------------------------------
          string packageName;
          size_t found;
           std::cout << "modelPath "<< modelPath << std::endl;
          found=modelPath.find(modelKey);
          //std::cout << "found "<< found << std::endl;

        if (found != std::string::npos && found!=0)
            packageName=modelPath.substr(0, found-1);
		else
            packageName="";
        std::cout << "package name "<< packageName<< std::endl;
         string fileName = modelKey;
         ModelicaCompiler* compiler;
         // when a model from MSL is used, then LoadFile doesn't need to be called
         // still there is problem with calling reducedTerms with model from MSL, because
         // for example for Modelica.Electrical.Analog.Examples.CauerLowPassSC, the modelPath only gives Modelica.CauerLowPassSC
        compiler =new ModelicaCompiler(modelKey,fileName,packageName,!loadMSL,loadPackage);
        compiler->reduceTerms(terms,simsettings.start_time,simsettings.end_time);
        //-----------------------------------------------------------------------------------------


        /*_simMgr->runSimulation();
        }*/

        }

         else
         std::cout << "list of labels for reduction is empty, so model remained as original." << std::endl;


    }
    catch(ModelicaSimulationError & ex)
    {
        string error = add_error_info(string("Simulation failed for ") + simsettings.outputfile_name,ex.what(),ex.getErrorID());
        throw ModelicaSimulationError(SIMMANAGER, error, "", ex.isSuppressed());
    }
    #else
        throw ModelicaSimulationError(SIMMANAGER,"The reduction algorithm is no supported for used compiler");
    #endif
}



void SimController::initialize(SimSettings simsettings, string modelKey, double timeout)
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
       // global_settings->setAlarmTime(simsettings.timeOut);

        global_settings->setAlarmTime(timeout);
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



    }
    catch(ModelicaSimulationError & ex)
    {
        string error = add_error_info(string("Simulation failed for ") + simsettings.outputfile_name,ex.what(),ex.getErrorID());
        throw ModelicaSimulationError(SIMMANAGER, error, "", ex.isSuppressed());
    }
}

void SimController::Stop()
{
    if(_simMgr)
    _simMgr->stopSimulation();
}
/** @} */ // end of coreSimcontroller
