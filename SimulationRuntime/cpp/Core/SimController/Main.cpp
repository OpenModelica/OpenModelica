#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
#include "Configuration.h"
#include <boost/program_options.hpp>
#include "SimController.h"

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
            ("emit_protected", "emits protected variables to the result file")
            ("runtime-library,r", po::value<string>(),"path to cpp runtime libraries")
            ("Modelica-system-library,m",  po::value<string>(), "path to Modelica library")
            ("results-file,R", po::value<string>(),"name of results file")
            ("config-path,c", po::value< string >(),  "path to xml files")
            ("start-time,s", po::value< double >()->default_value(0.0),  "simulation start time")
            ("stop-time,e", po::value< double >()->default_value(1.0),  "simulation stop time")
            ("step-size,f", po::value< double >()->default_value(1e-2),  "simulation step size")
            ("solver,i", po::value< string >()->default_value("euler"),  "solver method")
            ("number-of-intervals,v", po::value< int >()->default_value(500),  "number of intervals")
            ("tolerance,y", po::value< double >()->default_value(1e-6),  "solver tolerance")
            ("solverLog,l", "print additional solver information after simulation")
           ;
        po::variables_map vm;
        po::store(po::parse_command_line(argc, argv, desc,
          (po::command_line_style::default_style | po::command_line_style::allow_long_disguise) & ~po::command_line_style::allow_guessing
          ), vm);
        po::notify(vm);
        if (vm.count("help")) {
            cout << desc << "\n";
            return 1;
        }
        string runtime_lib_path;
        double starttime =  vm["start-time"].as<double>();
        double stoptime = vm["stop-time"].as<double>();
        double stepsize =  stoptime/vm["number-of-intervals"].as<int>();
        double tollerance =vm["tolerance"].as<double>();
        string solver =  vm["solver"].as<string>();
        if (vm.count("runtime-library"))
        {
            //cout << "runtime library path set to " << vm["runtime-library"].as<string>() << std::endl;
            runtime_lib_path = vm["runtime-library"].as<string>();

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
            return 1;
        }

        //SimController to start simulation
         SimSettings settings = {solver,"newton",starttime,stoptime,stepsize,1e-20,0.01,tollerance,results_file_path.string()};
        boost::shared_ptr<ISimController> sim_controller =  boost::shared_ptr<ISimController>(new SimController(runtime_lib_path,modelica_path));
         //create Modelica system
        std::pair<boost::weak_ptr<IMixedSystem>,boost::weak_ptr<ISimData> > system = sim_controller->LoadSystem("ModelicaSystem");

        sim_controller->Start(system.first,settings);
    }
    catch(std::exception& ex)
    {
        std::string error = ex.what();
        cerr << "Simulation stopped: "<<  error ;
        return 1;
    }
}
