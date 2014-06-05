#include "Modelica.h"
#include <Policies/FactoryConfig.h>
#include <OMCFactory/OMCFactory.h>
#include <SimController/ISimController.h>


OMCFactory::OMCFactory(PATH library_path, PATH modelicasystem_path)
    : _library_path(library_path)
    , _modelicasystem_path(modelicasystem_path)
{
}

OMCFactory::OMCFactory()
    : _library_path("")
    , _modelicasystem_path("")
{
}

OMCFactory::~OMCFactory()
{
}

void OMCFactory::UnloadAllLibs(void)
{
    map<string,shared_library>::iterator iter;
    for(iter = _modules.begin();iter!=_modules.end();++iter)
    {
        UnloadLibrary(iter->second);
    }
}
SimSettings OMCFactory::ReadSimulationParameter(int argc,  const char* argv[])
{
     int opt;
     int portnum;
      std::map<std::string,OutputFormat> outputFormatMap = map_list_of("csv", CSV)("mat", MAT)("empty",EMPTY);
       std::map<std::string,LogType> logTypeMap = map_list_of("stats", STATS)("nls", NLS)("ode",ODE)("off",OFF);
     po::options_description desc("Allowed options");
     desc.add_options()
          ("help", "produce help message")
          ("runtime-library,r", po::value<string>(),"path to cpp runtime libraries")
          ("Modelica-system-library,m",  po::value<string>(), "path to Modelica library")
          ("results-file,R", po::value<string>(),"name of results file")
          ("config-path,c", po::value< string >(),  "path to xml files")
          ("start-time,s", po::value< double >()->default_value(0.0),  "simulation start time")
          ("stop-time,e", po::value< double >()->default_value(1.0),  "simulation stop time")
          ("step-size,f", po::value< double >()->default_value(1e-2),  "simulation step size")
          ("solver,i", po::value< string >()->default_value("euler"),  "solver method")
          ("OutputFormat,o", po::value< string >()->default_value("csv"),  "output Format [csv,empty]")
          ("number-of-intervalls,v", po::value< int >()->default_value(500),  "number of intervalls")
          ("tollerance,y", po::value< double >()->default_value(1e-6),  "solver tollerance")
          ("log-type,l", po::value< string >()->default_value("off"),  "log information: stats ,nls,ode,off")
          ;
     po::variables_map vm;
     po::store(po::parse_command_line(argc, argv, desc), vm);
     po::notify(vm);

     string runtime_lib_path;
     string modelica_lib_path;
     double starttime =  vm["start-time"].as<double>();
     double stoptime = vm["stop-time"].as<double>();
     double stepsize =  stoptime/vm["number-of-intervalls"].as<int>();
     double tollerance =vm["tollerance"].as<double>();
     string solver =  vm["solver"].as<string>();
     if (vm.count("runtime-library"))
     {
          //cout << "runtime library path set to " << vm["runtime-library"].as<string>() << std::endl;
          runtime_lib_path = vm["runtime-library"].as<string>();

     }
     else
     {
          throw  std::invalid_argument("runtime  libraries path is not set");

     }

     if (vm.count("Modelica-system-library"))
     {
          //cout << "Modelica library path set to " << vm["Modelica-system-library"].as<string>()  << std::endl;
          modelica_lib_path =vm["Modelica-system-library"].as<string>();
     }
     else
     {
          throw  std::invalid_argument("Modelica library path is not set");

     }

     string resultsfilename;
     if (vm.count("results-file"))
     {
          //cout << "results file: " << vm["results-file"].as<string>() << std::endl;
          resultsfilename = vm["results-file"].as<string>();

     }
     else
     {
          throw std::invalid_argument("resultsfilename  is not set");

     }
     string outputFormat_str;
     OutputFormat outputFomat;
     if (vm.count("OutputFormat"))
     {
          //cout << "results file: " << vm["results-file"].as<string>() << std::endl;
          outputFormat_str = vm["OutputFormat"].as<string>();
          outputFomat = outputFormatMap[outputFormat_str];
          if((outputFomat!=CSV) && (outputFomat!=EMPTY))
          {
            std::string eception_msg = "The output format is not supported yet. Please use outputFormat=\"csv\" or  outputFormat=\"empty\" in simulate command ";
            throw  std::invalid_argument(eception_msg.c_str());
          }
     }
     else
     {
          throw std::invalid_argument("resultsfilename  is not set");

     }

     /*fs::path results_file_path = fs::path( resultsfilename) ;
    if(!(results_file_path.extension().string() == ".csv"))
    {
            std::string eception_msg = "The output format is not supported yet. Please use outputFormat=\"csv\" in simulate command ";
          throw  std::invalid_argument(eception_msg.c_str());

    }*/
      fs::path libraries_path = fs::path( runtime_lib_path) ;

        fs::path modelica_path = fs::path( modelica_lib_path) ;

           libraries_path.make_preferred();
        modelica_path.make_preferred();


     SimSettings settings = {solver,"kinsol",starttime,stoptime,stepsize,1e-20,0.01,tollerance,resultsfilename,outputFomat};

     _library_path = libraries_path;
    _modelicasystem_path = modelica_path;



     return settings;

}
std::pair<boost::shared_ptr<ISimController>,SimSettings> OMCFactory::createSimulation(int argc, const char* argv[])
{
     SimSettings settings = ReadSimulationParameter(argc,argv);
     type_map simcontroller_type_map;
     PATH simcontroller_path = _library_path;
     PATH simcontroller_name(SIMCONRTOLLER_LIB);
     simcontroller_path/=simcontroller_name;

     LOADERRESULT result =  LoadLibrary(simcontroller_path.string(),simcontroller_type_map);

     if (result != LOADER_SUCCESS)
     {

          throw std::runtime_error("Failed loading SimConroller library!");
     }
     std::map<std::string, factory<ISimController,PATH,PATH> >::iterator iter;
     std::map<std::string, factory<ISimController,PATH,PATH> >& factories(simcontroller_type_map.get());
     iter = factories.find("SimController");
     if (iter ==factories.end())
     {
          throw std::invalid_argument("No such SimController library");
     }
     boost::shared_ptr<ISimController>  simcontroller = boost::shared_ptr<ISimController>(iter->second.create(_library_path,_modelicasystem_path));
     return std::make_pair(simcontroller,settings);
}

LOADERRESULT OMCFactory::LoadLibrary(string libName,type_map& current_map)
{

    shared_library lib;
        if(!load_single_library(current_map,libName,lib))
           return LOADER_ERROR;
     _modules.insert(std::make_pair(libName,lib));
return LOADER_SUCCESS;
}

LOADERRESULT OMCFactory::UnloadLibrary(shared_library lib)
{
    if(lib.is_open())
    {
       if(!lib.close())
            return LOADER_ERROR;
       else
           return LOADER_SUCCESS;
    }
    return LOADER_SUCCESS;
}
