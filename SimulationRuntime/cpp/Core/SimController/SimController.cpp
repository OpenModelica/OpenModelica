#include <Core/Modelica.h>
#include <SimCoreFactory/Policies/FactoryConfig.h>
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
  _config = boost::shared_ptr<Configuration>(new Configuration(_library_path, _config_path, modelicasystem_path));
  _algloopsolverfactory = createAlgLoopSolverFactory(_config->getGlobalSettings());
}

SimController::~SimController()
{
  _systems.clear();
}

#if defined(__TRICORE__) || defined(__vxworks)
#else
std::pair<boost::shared_ptr<IMixedSystem>, boost::shared_ptr<ISimData> > SimController::LoadSystem(boost::shared_ptr<ISimData> (*createSimDataCallback)(), boost::shared_ptr<IMixedSystem> (*createSystemCallback)(IGlobalSettings*, boost::shared_ptr<IAlgLoopSolverFactory>, boost::shared_ptr<ISimData>), string modelKey)
{
  //if the model is already loaded
  std::map<string, std::pair<boost::shared_ptr<IMixedSystem>, boost::shared_ptr<ISimData> >  > ::iterator iter = _systems.find(modelKey);
  if(iter!=_systems.end())
  {
    //destroy system
    _systems.erase(iter);
  }
  //create system
  std::pair<boost::shared_ptr<IMixedSystem>, boost::shared_ptr<ISimData> > system = createSystem(createSimDataCallback, createSystemCallback, _config->getGlobalSettings(), _algloopsolverfactory);
  _systems[modelKey] = system;
  return system;
}
#endif

std::pair<boost::shared_ptr<IMixedSystem>, boost::shared_ptr<ISimData> > SimController::LoadSystem(string modelLib, string modelKey)
{
  //if the model is already loaded
  std::map<string, std::pair<boost::shared_ptr<IMixedSystem>, boost::shared_ptr<ISimData> > > ::iterator iter = _systems.find(modelKey);
  if(iter!=_systems.end())
  {
    //destroy system
    _systems.erase(iter);
  }
  //create system
  std::pair<boost::shared_ptr<IMixedSystem>, boost::shared_ptr<ISimData> > system = createSystem(modelLib, modelKey, _config->getGlobalSettings(), _algloopsolverfactory);
  _systems[modelKey] = system;
  return system;
}

std::pair<boost::shared_ptr<IMixedSystem>, boost::shared_ptr<ISimData> > SimController::LoadModelicaSystem(PATH modelica_path, string modelKey)
{
  if(_use_modelica_compiler)
  {
    //if the modell is already loaded
    std::map<string,std::pair<boost::shared_ptr<IMixedSystem>, boost::shared_ptr<ISimData> > >::iterator iter = _systems.find(modelKey);
    if(iter!=_systems.end())
    {
      //destroy system
      _systems.erase(iter);
    }
    std::pair<boost::shared_ptr<IMixedSystem>, boost::shared_ptr<ISimData> > system = createModelicaSystem(modelica_path, modelKey, _config->getGlobalSettings(), _algloopsolverfactory);
    _systems[modelKey] = system;
    return system;
  }
  else
    throw std::invalid_argument("No Modelica Compiler configured");
}

boost::shared_ptr<ISimData> SimController::getSimData(string modelname)
{
  return ((_systems[modelname]).second);
}

// Added for real-time simulation using VxWorks and Bodas
void SimController::StartVxWorks(boost::shared_ptr<IMixedSystem> mixedsystem, SimSettings simsettings)
{
  try
  {
    IGlobalSettings* global_settings = _config->getGlobalSettings();

    global_settings->useEndlessSim(true);
    global_settings->setStartTime(simsettings.start_time);
    global_settings->setEndTime(simsettings.end_time);
    global_settings->sethOutput(simsettings.step_size);
    global_settings->setResultsFileName(simsettings.outputfile_name);
    global_settings->setSelectedLinSolver(simsettings.linear_solver_name);
    global_settings->setSelectedNonLinSolver(simsettings.nonlinear_solver_name);
    global_settings->setSelectedSolver(simsettings.solver_name);
    global_settings->setOutputFormat(simsettings.outputFormat);
    global_settings->setAlarmTime(simsettings.timeOut);
    global_settings->setLogType(simsettings.logType);
    global_settings->setOutputPointType(simsettings.outputPointType);

    _simMgr = boost::shared_ptr<SimManager>(new SimManager(mixedsystem, _config.get()));

    ISolverSettings* solver_settings = _config->getSolverSettings();
    solver_settings->setLowerLimit(simsettings.lower_limit);
    solver_settings->sethInit(simsettings.lower_limit);
    solver_settings->setUpperLimit(simsettings.upper_limit);
    solver_settings->setRTol(simsettings.tolerance);
    solver_settings->setATol(simsettings.tolerance);

    _simMgr->initialize();
  }
  catch(std::exception& ex)
  {
    std::string error =string("Simulation failed for ") + simsettings.outputfile_name + string(" with error ")+ ex.what();

    printf("Fehler %s\n", ex.what());

    throw std::runtime_error(error);
  }
}

// Added for real-time simulation using VxWorks and Bodas
void SimController::calcOneStep(double cycletime)
{
  _simMgr->runSingleStep(cycletime);
}


void SimController::Start(boost::shared_ptr<IMixedSystem> mixedsystem, SimSettings simsettings, string modelKey)
{
  try
  {
    boost::shared_ptr<SimManager> simMgr;

    IGlobalSettings* global_settings = _config->getGlobalSettings();

    global_settings->setStartTime(simsettings.start_time);
    global_settings->setEndTime(simsettings.end_time);
    global_settings->sethOutput(simsettings.step_size);
    global_settings->setResultsFileName(simsettings.outputfile_name);
    global_settings->setSelectedLinSolver(simsettings.linear_solver_name);
    global_settings->setSelectedNonLinSolver(simsettings.nonlinear_solver_name);
    global_settings->setSelectedSolver(simsettings.solver_name);
    global_settings->setOutputFormat(simsettings.outputFormat);
    global_settings->setLogType(simsettings.logType);
    global_settings->setAlarmTime(simsettings.timeOut);
    global_settings->setOutputPointType(simsettings.outputPointType);

    simMgr = boost::shared_ptr<SimManager>(new SimManager(mixedsystem, _config.get()));

    ISolverSettings* solver_settings = _config->getSolverSettings();
    solver_settings->setLowerLimit(simsettings.lower_limit);
    solver_settings->sethInit(simsettings.lower_limit);
    solver_settings->setUpperLimit(simsettings.upper_limit);
    solver_settings->setRTol(simsettings.tolerance);
    solver_settings->setATol(simsettings.tolerance);
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
    std::string error = string("Simulation failed for ") + simsettings.outputfile_name + string(" with error ")+ ex.what();
    throw std::runtime_error(error);
  }
}

void SimController::Stop()
{
}
