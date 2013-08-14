#include "StdAfx.h"
#include "SimController.h"
#include "LibrariesConfig.h"
#include "Configuration.h"

SimController::SimController(PATH library_path, PATH modelicasystem_path)
    :SimControllerPolicy(library_path,modelicasystem_path,library_path)
{
  
    _config = new  Configuration(_library_path,_config_path,modelicasystem_path);
    
    _algloopsolverfactory = createAlgLoopSolverFactory(_config->getGlobalSettings());
    
}

SimController::~SimController()
{
    //Gibt alle Singletons frei die in der generic facotry verwaltet werden.
   delete _config;
    //vxworks: clean_up_generic_factory();
}

std::pair<boost::weak_ptr<IMixedSystem>,boost::weak_ptr<ISimData> > SimController::LoadSystem(string modelKey)
{
    //if the modell is already loaded
    std::map<string, std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> >  > ::iterator iter = _systems.find(modelKey);
    if(iter!=_systems.end())
    {
        //destroy system
        _systems.erase(iter);
    }
    //create system
     std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> >  system  = createSystem(modelKey,_config->getGlobalSettings(),_algloopsolverfactory);
    _systems[modelKey]=system;
    return system;
}

std::pair<boost::weak_ptr<IMixedSystem>,boost::weak_ptr<ISimData> > SimController::LoadModelicaSystem(PATH modelica_path,string modelKey)
{
    if(_use_modelica_compiler)
    {
        //if the modell is already loaded
        std::map<string,std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> > >::iterator iter = _systems.find(modelKey);
        if(iter!=_systems.end())
        {
            //destroy system
            _systems.erase(iter);
        }
        std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> >  system = createModelicaSystem(modelica_path, modelKey,_config->getGlobalSettings(),_algloopsolverfactory);
        _systems[modelKey]=system;
        return system;
    }
    else
        throw std::invalid_argument("No Modelica Compiler configured");

}

void SimController::Start(boost::weak_ptr<IMixedSystem> mixedsystem,SimSettings simsettings/*,ISimData* simData*/)
{
    /*vxworks: double startTime,endTime,llimit,ulimit,stepSize;
    string solver,nonlinsolver,outputfile;
    boost::tie(solver,nonlinsolver,startTime,endTime,stepSize,llimit,ulimit,outputfile)=simsettings;
    */
    try
    {
        
        boost::shared_ptr<SimManager> simMgr;
     
        IGlobalSettings* global_settings = _config->getGlobalSettings();
      
        global_settings->setStartTime(simsettings.start_time);
        global_settings->setEndTime(simsettings.end_time);
        global_settings->sethOutput(simsettings.step_size);
        global_settings->setResultsFileName(simsettings.outputfile_name);
        global_settings->setSelectedNonLinSSolver(simsettings.nonlinear_solver_name);
        global_settings->setSelectedSolver(simsettings.solver_name);
     
        simMgr = boost::shared_ptr<SimManager>(new SimManager(mixedsystem.lock(),_config));
        ISolverSettings* solver_settings = _config->getSolverSettings();
        solver_settings->setLowerLimit(simsettings.lower_limit);
        solver_settings->sethInit(simsettings.lower_limit);
        solver_settings->setUpperLimit(simsettings.upper_limit);
    
        simMgr->initialize();
      
        simMgr->runSimulation();

       /* if(boost::shared_ptr<IMixedSystem> history_system = mixedsystem.lock())
        {
            //get history object to query simulation results
            IHistory* history = history_system->getHistory();
            //simulation results (output variables)
            ublas::matrix<double> Ro;
            //query simulation result otuputs
            history->getOutputResults(Ro);
            vector<string> output_names;
            history->getOutputNames(output_names);
            string name;
            int j=0;
            BOOST_FOREACH(name,output_names)
            {
                ublas::vector<double> o_j;
                o_j =ublas::row(Ro,j);
                simData->addOutputResults(name,o_j);
                j++;
            }
            vector<double> time_values = history->getTimeEntries();
            simData->addTimeEntries(time_values);
        }*/

    }
    catch(std::exception& ex)
    {
        std::string error =string("Simulation failed for ") + simsettings.outputfile_name + string(" with error ")+ ex.what() ;

        throw std::runtime_error(error);
    }
}


void SimController::Stop()
{
}

