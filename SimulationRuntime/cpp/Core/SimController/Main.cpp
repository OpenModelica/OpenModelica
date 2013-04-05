
#include "stdafx.h"
#include "Configuration.h"
#include "System/ISystemProperties.h"
#include "LibrariesConfig.h"
#include <boost/program_options.hpp>
#include "System/IAlgLoopSolverFactory.h"

namespace po = boost::program_options;
namespace fs = boost::filesystem;
using namespace std;



#if defined(_MSC_VER) || defined(__MINGW32__)
#include <tchar.h>
int _tmain(int argc, _TCHAR* argv[])
#else
int main(int argc, const char* argv[])
#endif
{

    try
    {
        int opt;
        int portnum;

        po::options_description desc("Allowed options");
        desc.add_options()
            ("help", "produce help message")
            ("runtime-libray,r", po::value<string>(),"path to cpp runtime libraries")
            ("Modelica-system-library,m",  po::value<string>(), "path to Modelica library")
            ("results-file,R", po::value<string>(),"name of results file")
            ("config-path,c", po::value< string >(),  "path to xml files")
            ;
        po::variables_map vm;
        po::store(po::parse_command_line(argc, argv, desc), vm);
        po::notify(vm);
        if (vm.count("help")) {
            cout << desc << "\n";
            return 1;
        }
        string runtime_lib_path;

        if (vm.count("runtime-libray"))
        {
            //cout << "runtime library path set to " << vm["runtime-libray"].as<string>() << std::endl;
            runtime_lib_path = vm["runtime-libray"].as<string>();
        
        }
        else
        {
            cerr << "runtime  libraries path is not set";
            return 0;
        }
        fs::path libraries_path = fs::path( runtime_lib_path) ;

        fs::path modelica_path;
        if (vm.count("Modelica-system-library"))
        {
            //cout << "Modelica library path set to " << vm["Modelica-system-library"].as<string>()  << std::endl;
            modelica_path = fs::path(vm["Modelica-system-library"].as<string>());
        }
        else
        {
            cerr << "Modelica library path is not set";
            return 0;
        }
        fs::path config_path;
        if (vm.count("config-path"))
        {
            //cout << "config path set to " << vm["config-path"].as<string>() << std::endl;
            config_path = fs::path(vm["config-path"].as<string>());

        }
        else
        {
            cerr << "config  path is not set";
            return 0;
        }
        string resultsfilename;
        if (vm.count("results-file"))
        {
            //cout << "results file: " << vm["results-file"].as<string>() << std::endl;
            resultsfilename = vm["results-file"].as<string>();

        }
        else
        {
            cerr << "resultsfilename  is not set";
            return 0;
        }

        libraries_path.make_preferred();
        modelica_path.make_preferred();
        config_path.make_preferred();



        fs::path results_file_path = fs::path( resultsfilename) ;
        if(!(results_file_path.extension().string() == ".csv"))
        {
            std::string eception_msg = "The output format is not supported yet. Please use outputFormat=\"csv\" in simulate command ";
            cerr << eception_msg.c_str();
            return 0;
        }

        //std::cout << libraries_path << "  end" << std::endl;


        Configuration config(libraries_path,config_path);
        IGlobalSettings* global_settings = config.getGlobalSettings();
        global_settings->setRuntimeLibrarypath(runtime_lib_path);
        global_settings->setResultsFileName(resultsfilename);
        //Load Modelica sytem library


        fs::path modelica_system_name(MODELICASYSTEM_LIB);
        fs::path modelica_system_path = modelica_path;
        modelica_system_path/=modelica_system_name;

        fs::path math_name(MATH_LIB);
        fs::path math_path = libraries_path;
        math_path/=math_name;

        fs::path default_system_name(SYSTEM_LIB);
        fs::path default_system_path = libraries_path;
        default_system_path/=default_system_name;



        default_system_path.make_preferred();
        modelica_system_path.make_preferred();
        math_path.make_preferred();

        type_map types;
        if(!load_single_library(types,  default_system_path.string()))
            throw std::invalid_argument("System default library could not be loaded");

        shared_library math_lib(math_path.string());
        if(!math_lib.open())
            throw std::invalid_argument("Math library could not be loaded");

        if(!load_single_library(types,  modelica_system_path.string()))
            throw std::invalid_argument("ModelicaSystem library could not be loaded");


         //Load Algloopsolver library
      

       
        fs::path algsolver_name(SYSTEM_LIB);
        fs::path algsolver_path = libraries_path;
        algsolver_path/=algsolver_name;

        if(!load_single_library(types, algsolver_path.string()))
            throw std::invalid_argument("Algsolver library could not be loaded");
        std::map<std::string, factory<IAlgLoopSolverFactory,IGlobalSettings&> >::iterator iter;
        std::map<std::string, factory<IAlgLoopSolverFactory,IGlobalSettings&> >& algloopsolver_factory(types.get());
        iter = algloopsolver_factory.find("AlgLoopSolverFactory");
        if (iter ==algloopsolver_factory.end()) 
         {
            throw std::invalid_argument("No AlgLoopSolverFactory  found");
        }
        boost::shared_ptr<IAlgLoopSolverFactory> algLoopSolverFactory = boost::shared_ptr<IAlgLoopSolverFactory>(iter->second.create(*global_settings));
        std::map<std::string, factory<IMixedSystem,IGlobalSettings*,boost::shared_ptr<IAlgLoopSolverFactory> > >::iterator system_iter;
        std::map<std::string, factory<IMixedSystem,IGlobalSettings*,boost::shared_ptr<IAlgLoopSolverFactory> > >& factories(types.get());
        system_iter = factories.find("ModelicaSystem");
        if (system_iter ==factories.end()) 
        {
            throw std::invalid_argument("No Modelica system found");
        }


        //create Modelica system
        boost::shared_ptr<IMixedSystem> system(system_iter->second.create(global_settings,algLoopSolverFactory));

        //create selected solver
        boost::shared_ptr<IDAESolver> solver = config.createSolver(system.get());

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

            // Get the status of the solver (is the interation done sucessfully?)
            IDAESolver::SOLVERSTATUS status = solver->getSolverStatus();
            //Todo: use flags for simulation outputs
            //solver->writeSimulationInfo(std::cout);
            //solver->reportErrorMessage(std::cout);
        }

    }
    catch(std::exception& ex)
    {
        std::string error = ex.what();
        cerr << "Simulation stopped: "<<  error ;
        return 1;
    }

}
