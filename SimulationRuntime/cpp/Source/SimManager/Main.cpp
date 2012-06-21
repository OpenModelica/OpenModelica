
#include "stdafx.h"
#include "Configuration.h"
#include "System/Interfaces/ISystemProperties.h"
#include "LibrariesConfig.h"
namespace fs = boost::filesystem;

#if defined(_MSC_VER) || defined(__MINGW32__)
#include <tchar.h>
int _tmain(int argc, _TCHAR* argv[])
#else
int main(int argc, const char* argv[])
#endif
{  
   if(argc < 3)
     throw std::invalid_argument("No runtime library path and Modelica system library path defined");

   fs::path libraries_path = fs::path( argv[1] ) ;
  fs::path modelica_path = fs::path( argv[2] ) ;

   //std::cout << libraries_path << "  end" << std::endl;
  try
  {
    
    Configuration config(libraries_path);
    
    IGlobalSettings* global_settings = config.getGlobalSettings();
    //Load Modelica sytem library
    type_map types;
    
     fs::path modelica_system_name(MODELICASYSTEM_LIB);
    fs::path modelica_system_path = modelica_path;
    modelica_system_path/=modelica_system_name;
    
  fs::path default_system_name(SYSTEM_LIB);
  fs::path default_system_path = libraries_path;
  default_system_path/=default_system_name;
  
 if(!load_single_library(types,  default_system_path.string()))
      throw std::invalid_argument("System default library could not be loaded");

    
    if(!load_single_library(types,  modelica_system_path.string()))
      throw std::invalid_argument("ModelicaSystem library could not be loaded");
    std::map<std::string, factory<IDAESystem,IGlobalSettings&> >::iterator iter;
    std::map<std::string, factory<IDAESystem,IGlobalSettings&> >& factories(types.get());
    iter = factories.find("ModelicaSystem");
    if (iter ==factories.end()) 
    {
      throw std::invalid_argument("No Modelica system found");
    }
    
    
    //create Modelica system
    boost::shared_ptr<IDAESystem> system(iter->second.create(*global_settings));
    
    //create selected solver
    IDAESolver* solver = config.createSolver(system.get());
    
    boost::shared_ptr<ISystemProperties> properties = boost::dynamic_pointer_cast<ISystemProperties>(system);
    if((properties->isODE()) && !(properties->isAlgebraic()) && (properties->isExplicit()))
    {
      
      // Command for integration: Since integration is done "at once" the solver is only called once. Hence it is both, first and last 
      // call to the solver at the same time. Furthermore it is supposed to be a regular call (not a recall)
      IDAESolver::SOLVERCALL command = IDAESolver::SOLVERCALL(IDAESolver::FIRST_CALL|IDAESolver::LAST_CALL|IDAESolver::REGULAR_CALL|IDAESolver::RECORDCALL);
      // The simulation entity is supposed to set start and end time
      solver->setStartTime(global_settings->getStartTime());
      solver->setEndTime(global_settings->getEndTime());
      solver->setInitStepSize(config.getSolverSettings()->gethInit());
      // Call the solver
      solver->solve(command);
      
    }
    // Get the status of the solver (is the interation done sucessfully?) 
    IDAESolver::SOLVERSTATUS status = solver->getSolverStatus();
    //Todo: use flags for simulation outputs
    //solver->writeSimulationInfo(std::cout);
    //solver->reportErrorMessage(std::cout);
    return 0;
  }
  catch(std::exception& ex)
  {
    std::string error = ex.what();
    std::cout << "Simulation stopped: "<< std::endl << error << std::endl;
    return 1;
  }
}


