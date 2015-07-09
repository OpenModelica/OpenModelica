/** @addtogroup simcorefactoryOMCFactory
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/SimController/ISimController.h>
#include <boost/algorithm/string.hpp>
#include <boost/container/vector.hpp>


OMCFactory::OMCFactory(PATH library_path, PATH modelicasystem_path)
    : _library_path(library_path)
    , _modelicasystem_path(modelicasystem_path)
    , _defaultLinSolver("kinsol")
    , _defaultNonLinSolver("kinsol")
{
}

OMCFactory::OMCFactory()
    : _library_path("")
    , _modelicasystem_path("")
    , _defaultLinSolver("kinsol")
    , _defaultNonLinSolver("kinsol")
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

// parse a long option that starts with one dash, like -port=12345
static pair<string, string> checkOMEditOption(const string &s)
{
    int sep = s.find("=");
    if (sep > 2 && s[0] == '-' && s[1] != '-')
        return make_pair(string("OMEdit"), s);
    else
        return make_pair(string(), string());
}

SimSettings OMCFactory::readSimulationParameter(int argc,  const char* argv[])
{
     int opt;
     int portnum;
     std::map<std::string,LogCategory> logCatMap = map_list_of("init", LC_INIT)("nls", LC_NLS)("ls",LC_LS)("solv", LC_SOLV)("output", LC_OUT)("event",LC_EVT)("model",LC_MOD)("other",LC_OTHER);
     std::map<std::string,LogLevel> logLvlMap = map_list_of("error", LL_ERROR)("warning", LL_WARNING)("info", LL_INFO)("debug", LL_DEBUG);
     std::map<std::string,OutputPointType> outputPointTypeMap = map_list_of("all", OPT_ALL)("step", OPT_STEP)("none", OPT_NONE);
     po::options_description desc("Allowed options");
     desc.add_options()
          ("help", "produce help message")
          ("emit_protected", "emits protected variables to the result file")
          ("runtime-library,r", po::value<string>(),"path to cpp runtime libraries")
          ("Modelica-system-library,m",  po::value<string>(), "path to Modelica library")
          ("results-file,R", po::value<string>(),"name of results file")
          //("config-path,c", po::value< string >(),  "path to xml files")
          ("start-time,s", po::value< double >()->default_value(0.0),  "simulation start time")
          ("stop-time,e", po::value< double >()->default_value(1.0),  "simulation stop time")
          ("step-size,f", po::value< double >()->default_value(0.0),  "simulation step size")
          ("solver,i", po::value< string >()->default_value("euler"),  "solver method")
          ("lin-solver,L", po::value< string >()->default_value(_defaultLinSolver),  "linear solver method")
          ("non-lin-solver,N", po::value< string >()->default_value(_defaultNonLinSolver),  "non linear solver method")
          ("number-of-intervals,v", po::value< int >()->default_value(500),  "number of intervals")
          ("tolerance,y", po::value< double >()->default_value(1e-6),  "solver tolerance")
          ("log-settings,l", po::value< std::vector<std::string> >(),  "log information: init, nls, ls, solv, output, event, model, other")
          ("alarm,a", po::value<unsigned int >()->default_value(360),  "sets timeout in seconds for simulation")
          ("output-type,O", po::value< string >()->default_value("all"),  "the points in time written to result file: all (output steps + events), step (just output points), none")
          ("OMEdit", po::value<vector<string> >(), "OMEdit options")
          ;
     po::variables_map vm;
     po::parsed_options parsed = po::command_line_parser(argc, argv)
         .options(desc)
         .style((po::command_line_style::default_style | po::command_line_style::allow_long_disguise) & ~po::command_line_style::allow_guessing)
         .extra_parser(checkOMEditOption)
         .allow_unregistered()
         .run();
     po::store(parsed, vm);
     po::notify(vm);

     // warn about unrecognized command line options, including OMEdit for now
     vector<string> unrecognized = po::collect_unrecognized(parsed.options, po::include_positional);
     if (vm.count("OMEdit")) {
         vector<string> opts = vm["OMEdit"].as<vector<string> >();
         unrecognized.insert(unrecognized.begin(), opts.begin(), opts.end());
     }
     if (unrecognized.size() > 0) {
         std::cerr << "Warning: unrecognized command line options ";
         std::copy(unrecognized.begin(), unrecognized.end(), std::ostream_iterator<string>(std::cerr, " "));
         std::cerr << std::endl;
     }

     string runtime_lib_path;
     string modelica_lib_path;
     double starttime =  vm["start-time"].as<double>();
     double stoptime = vm["stop-time"].as<double>();
     double stepsize =vm["step-size"].as<double>();

     if (!(stepsize > 0.0))
       stepsize =  stoptime/vm["number-of-intervals"].as<int>();

     double tolerance =vm["tolerance"].as<double>();
     string solver =  vm["solver"].as<string>();
     string nonLinSolver =  vm["non-lin-solver"].as<string>();
     string linSolver =  vm["lin-solver"].as<string>();
     unsigned int time_out =  vm["alarm"].as<unsigned int>();;
     if (vm.count("runtime-library"))
     {
          //cout << "runtime library path set to " << vm["runtime-library"].as<string>() << std::endl;
          runtime_lib_path = vm["runtime-library"].as<string>();

     }
     else
     {
          throw ModelicaSimulationError(MODEL_FACTORY,"runtime libraries path is not set");

     }

     if (vm.count("Modelica-system-library"))
     {
          //cout << "Modelica library path set to " << vm["Modelica-system-library"].as<string>()  << std::endl;
          modelica_lib_path =vm["Modelica-system-library"].as<string>();
     }
     else
     {
          throw ModelicaSimulationError(MODEL_FACTORY,"Modelica library path is not set");

     }

     string resultsfilename;
     if (vm.count("results-file"))
     {
          //cout << "results file: " << vm["results-file"].as<string>() << std::endl;
          resultsfilename = vm["results-file"].as<string>();

     }
     else
     {
          throw ModelicaSimulationError(MODEL_FACTORY,"results-filename is not set");

     }

     string outputPointType_str;
     OutputPointType outputPointType;
     if (vm.count("output-type"))
     {
          //cout << "results file: " << vm["results-file"].as<string>() << std::endl;
          outputPointType_str = vm["output-type"].as<string>();
          outputPointType = outputPointTypeMap[outputPointType_str];
     }
     else
     {
          throw ModelicaSimulationError(MODEL_FACTORY,"results-filename  is not set");
     }

     LogSettings logSet;
     if (vm.count("log-settings"))
     {
    	 std::vector<std::string> log_vec = vm["log-settings"].as<std::vector<string> >(),tmpvec;
    	 for(unsigned i=0;i<log_vec.size();++i)
    	 {
    		 cout << i << ". " << log_vec[i] << std::endl;
    		 tmpvec.clear();
    		 boost::split(tmpvec,log_vec[i],boost::is_any_of("="));

    		 if(tmpvec.size()>1 && logLvlMap.find(tmpvec[1]) != logLvlMap.end() && ( tmpvec[0] == "all" || logCatMap.find(tmpvec[0]) != logCatMap.end()))
    		 {
    			 if(tmpvec[0] == "all")
    			 {
    				 logSet.setAll(logLvlMap[tmpvec[1]]);
    				 break;
    			 }
    			 else
    				 logSet.modes[logCatMap[tmpvec[0]]] = logLvlMap[tmpvec[1]];
    	     }
    		 else
    			 throw ModelicaSimulationError(MODEL_FACTORY,"log-settings flags not supported: " + boost::lexical_cast<std::string>(log_vec[i]) + "\n");
    	 }

     }

     fs::path libraries_path = fs::path( runtime_lib_path) ;

     fs::path modelica_path = fs::path( modelica_lib_path) ;

     libraries_path.make_preferred();
     modelica_path.make_preferred();



     SimSettings settings = {solver,linSolver,nonLinSolver,starttime,stoptime,stepsize,1e-24,0.01,tolerance,resultsfilename,time_out,outputPointType,logSet};


     _library_path = libraries_path;
    _modelicasystem_path = modelica_path;



     return settings;

}

std::vector<const char *> OMCFactory::modifyArguments(int argc, const char* argv[], std::map<std::string, std::string> &opts)
{
  std::map<std::string, std::string>::const_iterator oit;
  std::vector<const char *> optv;
  optv.push_back(argv[0]);
  std::string override;                // OMEdit override option
  for (int i = 1; i < argc; i++) {
      if ((oit = opts.find(argv[i])) != opts.end() && i < argc - 1)
          opts[oit->first] = argv[++i]; // regular override
      else if (strncmp(argv[i], "-override=", 10) == 0) {
          std::map<std::string, std::string> supported = map_list_of
              ("startTime", "-s")("stopTime", "-e")("stepSize", "-f")
              ("tolerance", "-y")("solver", "-i");
          std::vector<std::string> strs;
          boost::split(strs, argv[i], boost::is_any_of(",="));
          for (int j = 1; j < strs.size(); j++) {
              if ((oit = supported.find(strs[j])) != supported.end()
                  && j < strs.size() - 1) {
                  opts[oit->second] = strs[++j];
              }
              else {
                  // leave untreated overrides
                  if (override.size() > 0)
                      override += ",";
                  else
                      override = "-override=";
                  override += strs[j];
                  if (j < strs.size() - 1)
                      override += "=" + strs[++j];
              }
          }
          if (override.size() > 10)
              optv.push_back(override.c_str());
      }
      else
          optv.push_back(argv[i]);     // pass through
  }
  for (oit = opts.begin(); oit != opts.end(); oit++) {
      optv.push_back(oit->first.c_str());
      optv.push_back(oit->second.c_str());
  }

  return optv;
}

std::pair<boost::shared_ptr<ISimController>,SimSettings>
OMCFactory::createSimulation(int argc, const char* argv[],
                             std::map<std::string, std::string> &opts)
{
     std::vector<const char *> optv = modifyArguments(argc, argv, opts);

     SimSettings settings = readSimulationParameter(optv.size(), &optv[0]);
     type_map simcontroller_type_map;
     PATH simcontroller_path = _library_path;
     PATH simcontroller_name(SIMCONTROLLER_LIB);
     simcontroller_path/=simcontroller_name;

     LOADERRESULT result =  LoadLibrary(simcontroller_path.string(),simcontroller_type_map);

     if (result != LOADER_SUCCESS)
     {

        throw ModelicaSimulationError(MODEL_FACTORY,string("Failed loading SimConroller library!") + simcontroller_path.string());
     }
     std::map<std::string, factory<ISimController,PATH,PATH> >::iterator iter;
     std::map<std::string, factory<ISimController,PATH,PATH> >& factories(simcontroller_type_map.get());
     iter = factories.find("SimController");
     if (iter ==factories.end())
     {
          throw ModelicaSimulationError(MODEL_FACTORY,"No such SimController library");
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
/** @} */ // end of simcorefactoryOMCFactory
