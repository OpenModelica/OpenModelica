/** @addtogroup simcorefactoryOMCFactory
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Core/SimController/ISimController.h>
#include <Core/System/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>

#include <boost/algorithm/string.hpp>
#include <boost/bind.hpp>
#include <boost/container/vector.hpp>
#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>
#include <boost/program_options.hpp>

namespace fs = boost::filesystem;
namespace po = boost::program_options;

/**
 * Logger for XML messages through TCP port
 */
#include <boost/asio.hpp>

class LoggerXMLTCP : public LoggerXML
{
public:
    virtual ~LoggerXMLTCP()
    {
        _socket.close();
    }

    static void initialize(std::string host, int port, LogSettings& logSettings)
    {
        _instance = new LoggerXMLTCP(host, port, logSettings);
    }

protected:
    LoggerXMLTCP(std::string host, int port, LogSettings& logSettings)
        : LoggerXML(logSettings, true, _sstream)
// from_string no longer available in boost 1.87
#if ((BOOST_VERSION / 100000) >= 1 && (BOOST_VERSION / 100 % 1000) >= 87)
          , _endpoint(boost::asio::ip::make_address(host), port)
#else
          , _endpoint(boost::asio::ip::address::from_string(host), port)
#endif
          , _socket(_ios)
    {
        if (logSettings.format != LF_XML && logSettings.format != LF_XMLTCP)
        {
            throw ModelicaSimulationError(MODEL_FACTORY,
                                          "xmltcp logger requires log-format xml");
        }
        _socket.connect(_endpoint);
    }

    virtual void writeInternal(string msg, LogCategory cat, LogLevel lvl,
                               LogStructure ls)
    {
        _sstream.str("");
        LoggerXML::writeInternal(msg, cat, lvl, ls);
        if (_logSettings.format == LF_XMLTCP)
            _socket.send(boost::asio::buffer(_sstream.str()));
        else
            std::cout << _sstream.str();
    }

    virtual void statusInternal(const char* phase, double currentTime, double currentStepSize)
    {
        int completion = _endTime <= _startTime
                             ? 0
                             : (int)((currentTime - _startTime) / (_endTime - _startTime) * 10000);
        if (_logSettings.format == LF_XMLTCP)
        {
            _sstream.str("");
            _sstream << "<status phase=\"" << phase
                << "\" time=\"" << currentTime
                << "\" currentStepSize=\"" << currentStepSize
                << "\" progress=\"" << completion
                << "\" />" << std::endl;
            _socket.send(boost::asio::buffer(_sstream.str()));
        }
        else
        {
            // send status in old format for backwards compatibility
            _sstream.str("");
            _sstream << completion << " " << phase << std::endl;
            _socket.send(boost::asio::buffer(_sstream.str()));
        }
    }

// io_service no longer available in boost 1.87
#if ((BOOST_VERSION / 100000) >= 1 && (BOOST_VERSION / 100 % 1000) >= 87)
    boost::asio::io_context _ios;
#else
    boost::asio::io_service _ios;
#endif
    boost::asio::ip::tcp::endpoint _endpoint;
    boost::asio::ip::tcp::socket _socket;
    std::stringstream _sstream;
};

inline void normalizePath(std::string& path)
{
    if (path.length() > 0 && path[path.length() - 1] != '/')
        path += "/";
}

/**
 * Implementation of OMCFactory
 */
OMCFactory::OMCFactory(PATH library_path, PATH modelicasystem_path)
    : _library_path(library_path)

    , _modelicasystem_path(modelicasystem_path)
    #if defined(RUNTIME_STATIC_LINKING)
	, _defaultLinSolver("dgesvSolver")
	#else
	, _defaultLinSolver("linearSolver")
    #endif
	, _defaultNonLinSolver("kinsol")
    , _use_zeroMQ(false)

{
    fillArgumentsToIgnore();
    fillArgumentsToReplace();
}

OMCFactory::OMCFactory()
    : _library_path("")

    , _modelicasystem_path("")
    #if defined(RUNTIME_STATIC_LINKING)
	, _defaultLinSolver("dgesvSolver")
	#else
	, _defaultLinSolver("linearSolver")
    #endif
    , _defaultNonLinSolver("kinsol")
    , _use_zeroMQ(false)

{
    fillArgumentsToIgnore();
    fillArgumentsToReplace();
}

OMCFactory::~OMCFactory()
{
}

void OMCFactory::UnloadAllLibs(void)
{
    map<string, shared_library>::iterator iter;
    for (iter = _modules.begin(); iter != _modules.end(); ++iter)
    {
        UnloadLibrary(iter->second);
    }
}

pair<string, string> OMCFactory::parseIngoredAndWrongFormatOption(const string& s)
{
    int sep = s.find("=");
    string key = s;
    if (sep > 0)
        key = s.substr(0, sep);

    if (_argumentsToIgnore.find(key) != _argumentsToIgnore.end())
        return make_pair(string("ignored"), s);

    if (sep > 2 && s[0] == '-' && s[1] != '-')
        return make_pair(string("unrecognized"), s);
    else
        return make_pair(string(), string());
}

static LogSettings initializeLogger(const po::variables_map& vm)
{
    map<string, LogCategory> logCatMap = MAP_LIST_OF
    "init", LC_INIT
    MAP_LIST_SEP
    "nls", LC_NLS
    MAP_LIST_SEP
    "ls", LC_LS
    MAP_LIST_SEP
    "solver", LC_SOLVER
    MAP_LIST_SEP
    "output", LC_OUTPUT
    MAP_LIST_SEP
    "events", LC_EVENTS
    MAP_LIST_SEP
    "model", LC_MODEL
    MAP_LIST_SEP
    "other", LC_OTHER
    MAP_LIST_END;
    map<string, LogLevel> logLvlMap = MAP_LIST_OF
    "error", LL_ERROR
    MAP_LIST_SEP
    "warning", LL_WARNING
    MAP_LIST_SEP
    "info", LL_INFO
    MAP_LIST_SEP
    "debug", LL_DEBUG
    MAP_LIST_END;
    map<string, LogFormat> logFormatMap = MAP_LIST_OF
    "txt", LF_TXT
    MAP_LIST_SEP
    "xml", LF_XML
    MAP_LIST_SEP
    "xmltcp", LF_XMLTCP
    MAP_LIST_END;
    map<string, LogOMEdit> logOMEditMap = MAP_LIST_OF
    "LOG_EVENTS", LOG_EVENTS
    MAP_LIST_SEP
    "LOG_INIT", LOG_INIT
    MAP_LIST_SEP
    "LOG_LS", LOG_LS
    MAP_LIST_SEP
    "LOG_NLS", LOG_NLS
    MAP_LIST_SEP
    "LOG_SOLVER", LOG_SOLVER
    MAP_LIST_SEP
    "LOG_STATS", LOG_STATS
    MAP_LIST_END;

    LogSettings logSettings;
    std::string logOMEditWarning;
    if (vm.count("log-settings"))
    {
        vector<string> log_vec = vm["log-settings"].as<vector<string>>();
        vector<string> tmpvec;
        for (int i = 0; i < log_vec.size(); i++)
        {
            // translate XML stream options to native options
            if (log_vec[i].compare(0, 4, "LOG_") == 0)
            {
                LogOMEdit logOMEdit;
                boost::split(tmpvec, log_vec[i], boost::is_any_of(","));
                for (int j = 0; j < tmpvec.size(); j++)
                {
                    if (logOMEditMap.find(tmpvec[j]) != logOMEditMap.end())
                        logOMEdit = logOMEditMap[tmpvec[j]];
                    else
                    {
                        if (logOMEditWarning.size() > 0)
                            logOMEditWarning += ",";
                        logOMEditWarning += tmpvec[j];
                        continue;
                    }
                    switch (logOMEdit)
                    {
                    case LOG_EVENTS:
                        logSettings.modes[LC_EVENTS] = LL_DEBUG;
                        break;
                    case LOG_INIT:
                        logSettings.modes[LC_INIT] = LL_DEBUG;
                        break;
                    case LOG_LS:
                        logSettings.modes[LC_LS] = LL_DEBUG;
                        break;
                    case LOG_NLS:
                        logSettings.modes[LC_NLS] = LL_DEBUG;
                        break;
                    case LOG_SOLVER:
                        logSettings.modes[LC_SOLVER] = LL_DEBUG;
                        //case LOG_STATS:
                    default:
                        if (logSettings.modes[LC_SOLVER] < LL_INFO)
                            logSettings.modes[LC_SOLVER] = LL_INFO;
                    }
                }
            }
                // treat native option
            else
            {
                boost::split(tmpvec, log_vec[i], boost::is_any_of("="));

                if (tmpvec.size() > 1 && logLvlMap.find(tmpvec[1]) != logLvlMap.end()
                    && (tmpvec[0] == "all" || logCatMap.find(tmpvec[0]) != logCatMap.end()))
                {
                    if (tmpvec[0] == "all")
                    {
                        logSettings.setAll(logLvlMap[tmpvec[1]]);
                        break;
                    }
                    else
                        logSettings.modes[logCatMap[tmpvec[0]]] = logLvlMap[tmpvec[1]];
                }
                else
                    throw ModelicaSimulationError(MODEL_FACTORY,
                                                  "log-settings flags not supported: " + log_vec[i] + "\n");
            }
        }
    }

    if (vm.count("warn-all") && vm["warn-all"].as<bool>())
    {
        for (int i = 0; i < logSettings.modes.size(); i++)
            if (logSettings.modes[i] < LL_WARNING)
                logSettings.modes[i] = LL_WARNING;
    }

    if (vm.count("log-format"))
    {
        string logFormat_str = vm["log-format"].as<string>();
        if (logFormatMap.find(logFormat_str) != logFormatMap.end())
            logSettings.format = logFormatMap[logFormat_str];
        else
            throw ModelicaSimulationError(MODEL_FACTORY,
                                          "Unknown log-format " + logFormat_str);
    }

    // make sure other infos get issued and initialize logger
    if (logSettings.modes[LC_OTHER] < LL_INFO)
        logSettings.modes[LC_OTHER] = LL_INFO;

    // initialize logger if it has been enabled
    if (Logger::isEnabled())
    {
        int port = vm["log-port"].as<int>();
        if (port > 0)
        {
            try
            {
                LoggerXMLTCP::initialize("127.0.0.1", port, logSettings);
            }
            catch (std::exception& ex)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,
                                              "Failed to start logger with port " + to_string(port) + ": "
                                              + ex.what() + '\n');
            }
        }
        else
            Logger::initialize(logSettings);
    }

    if (logOMEditWarning.size() > 0)
    {
        LOGGER_WRITE("Warning: unrecognized logging " + logOMEditWarning,
                     LC_OTHER, LL_WARNING);
        ostringstream os;
        os << "Supported are: ";
        map<std::string, LogOMEdit>::const_iterator it;
        for (it = logOMEditMap.begin(); it != logOMEditMap.end(); ++it)
        {
            if (it != logOMEditMap.begin())
                os << ",";
            os << it->first;
        }
        LOGGER_WRITE(os.str(), LC_OTHER, LL_INFO);
    }

    return logSettings;
}



SimSettings OMCFactory::readSimulationParameter(int argc, const char* argv[])
{
     int opt;
     int portnum;
     map<string, OutputPointType> outputPointTypeMap = MAP_LIST_OF
       "all", OPT_ALL MAP_LIST_SEP "step", OPT_STEP MAP_LIST_SEP
       "none", OPT_NONE MAP_LIST_END;
     map<string, OutputFormat> outputFormatMap = MAP_LIST_OF
       "csv", CSV MAP_LIST_SEP "mat", MAT MAP_LIST_SEP
       "buffer", BUFFER MAP_LIST_SEP "empty", EMPTY MAP_LIST_END;
     map<string, EmitResults> emitResultsMap = MAP_LIST_OF
       "all", EMIT_ALL MAP_LIST_SEP "public", EMIT_PUBLIC MAP_LIST_SEP
       "none", EMIT_NONE MAP_LIST_END;
     po::options_description desc("Allowed options");

     //program options that can be overwritten by OMEdit must be declared as vector
     //so that the same value can be set multiple times
     //(e.g. 'executable -F arg1 -r=arg2' -> 'executable -F arg1 -F=arg2')
     //the variables of OMEdit are always the first elements of the result vectors, if they are set
     desc.add_options()
          ("help", "produce help message")
          ("nls-continue", po::bool_switch()->default_value(false), "non linear solver will continue if it can not reach the given precision")
          ("runtime-library,R", po::value<string>(), "path to cpp runtime libraries")
          ("modelica-system-library,M",  po::value<string>(), "path to Modelica library")
          ("input-path", po::value< string >(), "directory with input files, like init xml (defaults to modelica-system-library)")
          ("output-path", po::value< string >(), "directory for output files, like results (defaults to modelica-system-library)")
          ("results-file,F", po::value<vector<string> >(),"name of results file")
          ("start-time,S", po::value< double >()->default_value(0.0), "simulation start time")
          ("stop-time,E", po::value< double >()->default_value(1.0), "simulation stop time")
          ("step-size,H", po::value< double >()->default_value(0.0), "simulation step size")
          ("solver,I", po::value< string >()->default_value("euler"), "solver method")
          ("lin-solver,L", po::value< string >()->default_value(_defaultLinSolver), "linear solver method")
          ("non-lin-solver,N", po::value< string >()->default_value(_defaultNonLinSolver),  "non linear solver method")
          ("number-of-intervals,G", po::value< int >()->default_value(500), "number of intervals in equidistant grid")
          ("tolerance,T", po::value< double >()->default_value(1e-6), "solver tolerance")
          ("warn-all,W", po::bool_switch()->default_value(false), "issue all warning messages")
          ("log-settings,V", po::value< vector<string> >(), "log information: init, nls, ls, solver, output, events, model, other")
          ("log-format,X", po::value< string >()->default_value("txt"), "log format: txt, xml, xmltcp")
          ("log-port", po::value< int >()->default_value(0), "tcp port for log messages (default 0 meaning stdout/stderr)")
          ("alarm,A", po::value<unsigned int >()->default_value(360), "sets timeout in seconds for simulation")
          ("output-type,O", po::value< string >()->default_value("all"), "the points in time written to result file: all (output steps + events), step (just output points), none")
          ("output-format,P", po::value< string >()->default_value("mat"), "simulation results output format: csv, mat, buffer, empty")
          ("emit-results,U", po::value< string >()->default_value("public"), "emit results: all, public, none")
          ("use-zeromq,u", po::value<bool>()->default_value(false), "use zeromq for communication during simulation with other applications")
          ("port-publish,p", po::value<int>()->default_value(3203), "zeromq publishing port")
          ("port-subscribe,s", po::value<int>()->default_value(3204), "zeromq subscribing port")
          ("zeromq-job-id,g", po::value<string>()->default_value("empty"), "ID that identifies the translation and simulation for one model")
          ("zeromq-server-id,v", po::value<string>()->default_value("empty"), "ID that identifies the omc zeromq application that receives omc api commands via zeromq")
          ("zeromq-client-id,c", po::value<string>()->default_value("empty"), "ID that identifies the client application that uses the omc zeromq application")
          ("omsu-name,o", po::value< string >()->default_value(""), "name of omsu or fmu 2.0 ME")
          ("omsu-path,a", po::value< string >()->default_value(""), "path for omsu or fmu 2.0 ME")
          ("init-file,i", po::value< string >()->default_value(""), "path for omsu or fmu 2.0 ME initialisation xml-file")
          ;


     // a group for all options that should not be visible if '--help' is set
     po::options_description descHidden("Hidden options");
     descHidden.add_options()
          ("ignored", po::value<vector<string> >(), "ignored options")
          ("unrecognized", po::value<vector<string> >(), "unsupported options")
          ("solver-threads", po::value<int>()->default_value(1), "number of threads that can be used by the solver")
          ;

     po::options_description descAll("All options");
     descAll.add(desc);
     descAll.add(descHidden);

     po::variables_map vm;
     boost::function<pair<string, string> (const string&)> parserFunction(boost::bind(&OMCFactory::parseIngoredAndWrongFormatOption, this, _1));
     po::parsed_options parsed = po::command_line_parser(argc, argv)
         .options(descAll)
         .style((po::command_line_style::default_style | po::command_line_style::allow_long_disguise) & ~po::command_line_style::allow_guessing)
         .extra_parser(parserFunction)
         .allow_unregistered()
         .run();
     po::store(parsed, vm);
     po::notify(vm);

     if (vm.count("help")) {
         cout << desc << endl;
         throw ModelicaSimulationError(MODEL_FACTORY, "Cannot parse command line arguments correctly, because the help message was requested.", "",true);
     }

     LogSettings logSettings = initializeLogger(vm);

     // warn about unrecognized command line options
     vector<string> unrecognized = po::collect_unrecognized(parsed.options, po::include_positional);
     if (vm.count("unrecognized")) {
         vector<string> opts = vm["unrecognized"].as<vector<string> >();
         unrecognized.insert(unrecognized.begin(), opts.begin(), opts.end());
     }
     if (unrecognized.size() > 0) {
         ostringstream os;
         os << "Warning: unrecognized command line options ";
         copy(unrecognized.begin(), unrecognized.end(), ostream_iterator<string>(os, " "));
         LOGGER_WRITE(os.str(), LC_OTHER, LL_WARNING);
     }

     string runtime_lib_path;
     string modelica_lib_path;
     string init_file_path;
     string omsu_path;
     string omsu_name;
     double starttime =  vm["start-time"].as<double>();
     double stoptime = vm["stop-time"].as<double>();
     double stepsize =vm["step-size"].as<double>();
     bool nlsContinueOnError = vm["nls-continue"].as<bool>();
     int solverThreads = vm["solver-threads"].as<int>();

     if (!(stepsize > 0.0))
         stepsize = (stoptime - starttime) / vm["number-of-intervals"].as<int>();

     double tolerance = vm["tolerance"].as<double>();
     string solver = vm["solver"].as<string>();
     string nonLinSolver = vm["non-lin-solver"].as<string>();
     string linSolver = vm["lin-solver"].as<string>();
     unsigned int timeOut = vm["alarm"].as<unsigned int>();
     if (vm.count("runtime-library"))
     {
         //cout << "runtime library path set to " << vm["runtime-library"].as<string>() << endl;
         runtime_lib_path = vm["runtime-library"].as<string>();
         normalizePath(runtime_lib_path);
     }
     else
         throw ModelicaSimulationError(MODEL_FACTORY,"runtime libraries path is not set");
     if (vm.count("omsu-name"))
     {
         //cout << "runtime library path set to " << vm["runtime-library"].as<string>() << endl;
         omsu_name = vm["omsu-name"].as<string>();
     }
     if (vm.count("omsu-path"))
     {
         //cout << "runtime library path set to " << vm["runtime-library"].as<string>() << endl;
         omsu_path = vm["omsu-path"].as<string>();
     }
     if (vm.count("init-file"))
     {
         init_file_path = vm["init-file"].as<string>();
     }

     if (vm.count("modelica-system-library"))
     {
         //cout << "Modelica library path set to " << vm["Modelica-system-library"].as<string>()  << endl;
         modelica_lib_path = vm["modelica-system-library"].as<string>();
         normalizePath(modelica_lib_path);
     }
     else
         throw ModelicaSimulationError(MODEL_FACTORY,"Modelica library path is not set");

     string inputPath, outputPath;
     if (vm.count("input-path")) {
         inputPath = vm["input-path"].as<string>();
         normalizePath(inputPath);
     }
     else
         inputPath = modelica_lib_path;
     if (vm.count("output-path")) {
         outputPath = vm["output-path"].as<string>();
         normalizePath(outputPath);
     }
     else
         outputPath = modelica_lib_path;

     string resultsfilename;
     if (vm.count("results-file"))
     {
         //cout << "results file: " << vm["results-file"].as<string>() << endl;
         resultsfilename = vm["results-file"].as<vector<string> >().front();
     }
     else
         throw ModelicaSimulationError(MODEL_FACTORY,"results-filename is not set");

     OutputPointType outputPointType;
     if (vm.count("output-type"))
     {
       string outputType_str = vm["output-type"].as<string>();
       if (outputPointTypeMap.find(outputType_str) != outputPointTypeMap.end())
         outputPointType = outputPointTypeMap[outputType_str];
       else
         throw ModelicaSimulationError(MODEL_FACTORY,
           "Unknown output-type " + outputType_str);
     }
     else
       throw ModelicaSimulationError(MODEL_FACTORY, "output-type is not set");

     OutputFormat outputFormat;
     if (vm.count("output-format"))
     {
       string outputFormat_str = vm["output-format"].as<string>();
       if (outputFormatMap.find(outputFormat_str) != outputFormatMap.end())
         outputFormat = outputFormatMap[outputFormat_str];
       else
         throw ModelicaSimulationError(MODEL_FACTORY,
           "Unknown output-format " + outputFormat_str);
     }
     else
       throw ModelicaSimulationError(MODEL_FACTORY, "output-format is not set");

     EmitResults emitResults = EMIT_PUBLIC; // emit public per default for OMC use
     if (vm.count("emit-results"))
     {
       string emitResults_str = vm["emit-results"].as<string>();
       if (emitResultsMap.find(emitResults_str) != emitResultsMap.end())
         emitResults = emitResultsMap[emitResults_str];
       else
         throw ModelicaSimulationError(MODEL_FACTORY,
           "Unknown emit-results " + emitResults_str);
     }

     int port_pub =3203;
     int port_sub = 3204;
     string zeromq_job_id = "empty";
     string zeromq_server_id = "empty";
     string zeromq_client_id = "empty";
     
     if (vm.count("port-publish"))
     {
         port_pub = vm["port-publish"].as<int>();
     }
    
     if (vm.count("port-subscribe"))
     {
         port_sub = vm["port-subscribe"].as<int>();
     }
     
    if (vm.count("zeromq-job-id"))
     {
         zeromq_job_id = vm["zeromq-job-id"].as<string>();
     }
    if (vm.count("zeromq-server-id"))
    {
        zeromq_server_id = vm["zeromq-server-id"].as<string>();
    }
    if (vm.count("zeromq-client-id"))
    {
        zeromq_client_id = vm["zeromq-client-id"].as<string>();
    }
     if (vm.count("use-zeromq"))
     {
         _use_zeroMQ = vm["use-zeromq"].as<bool>();
     }
     fs::path libraries_path = fs::path( runtime_lib_path) ;
     fs::path modelica_path = fs::path( modelica_lib_path) ;

     libraries_path.make_preferred();
     modelica_path.make_preferred();

     SimSettings settings = {solver, linSolver, nonLinSolver, starttime, stoptime, stepsize, 1e-24, 0.01, tolerance, resultsfilename, timeOut, outputPointType, logSettings, nlsContinueOnError, solverThreads, outputFormat, emitResults,omsu_name, omsu_path, init_file_path, inputPath, outputPath,_use_zeroMQ ,port_pub ,port_sub,zeromq_job_id,zeromq_server_id,zeromq_client_id };

     _library_path = libraries_path.string();
     _modelicasystem_path = modelica_path.string();

     return settings;

}

vector<const char *> OMCFactory::handleArgumentsToReplace(int argc, const char* argv[], map<string, string>& opts)
{
    vector<const char *> optv;
    optv.push_back(strdup(argv[0]));
    for (int i = 1; i < argc; i++)
    {
        string arg = argv[i];

        int sep = arg.find("=");
        string key = arg;
        string value = "";
        if (sep > 0)
        {
            key = arg.substr(0, sep);
            value = arg.substr(sep + 1);
        }

        map<string, string>::iterator oldValue = opts.find(key);

        map<string, string>::iterator iter = _argumentsToReplace.find(key);
        if (iter != _argumentsToReplace.end())
        {
            //if(opts.find(iter->second) != opts.end()) //if the new key is already part of the argument list, prevent double insertion
            //  continue;

            if (oldValue != opts.end())
            {
                opts.insert(pair<string, string>(iter->second, oldValue->second));
                opts.erase(arg);
            }
            key = iter->second;


            optv.push_back(strdup(key.c_str()));
            if(sep > 0)
                optv.push_back(strdup(value.c_str()));
        }
        else
        {
          if(sep > 0)
              arg = key + "=" + value;
          else
              arg = key;
          optv.push_back(strdup(arg.c_str()));
        }

    }

    return optv;
}

vector<const char *> OMCFactory::handleComplexCRuntimeArguments(int argc, const char* argv[], map<string, string>& opts)
{
    map<string, string>::const_iterator oit;
    vector<const char *> optv;

    optv.push_back(strdup(argv[0]));
    _overrideOMEdit = "-override="; // unrecognized OMEdit overrides
    for (int i = 1; i < argc; i++)
    {
        string arg = argv[i];
        int j;
        if (arg[0] == '-' && arg[1] != '-' && (j = arg.find('=')) > 0
            && (oit = opts.find(arg.substr(0, j))) != opts.end())
            opts[oit->first] = arg.substr(j + 1); // split at = and override
        else if ((oit = opts.find(arg)) != opts.end() && i < argc - 1)
            opts[oit->first] = argv[++i]; // regular override
        else if (strncmp(argv[i], "-override=", 10) == 0)
        {
            map<string, string> supported = MAP_LIST_OF
            "startTime", "-S"
            MAP_LIST_SEP
            "stopTime", "-E"
            MAP_LIST_SEP
            "stepSize", "-H"
            MAP_LIST_SEP
            "numberOfIntervals", "-G"
            MAP_LIST_SEP
            "solver", "-I"
            MAP_LIST_SEP
            "tolerance", "-T"
            MAP_LIST_SEP
            "outputFormat", "-P"
            MAP_LIST_END;
            vector<string> strs;
            boost::split(strs, argv[i], boost::is_any_of(",="));
            for (int j = 1; j < strs.size(); j++)
            {
                if ((oit = supported.find(strs[j])) != supported.end()
                    && j < strs.size() - 1)
                {
                    opts[oit->second] = strs[++j];
                }
                else
                {
                    // ignore filter for all variables
                    if (strs[j] == "variableFilter"
                        && j < strs.size() - 1 && strs[j + 1] == ".*")
                    {
                        ++j;
                        continue;
                    }
                    // leave unrecognized overrides
                    if (_overrideOMEdit.size() > 10)
                        _overrideOMEdit += ",";
                    _overrideOMEdit += strs[j];
                    if (j < strs.size() - 1)
                        _overrideOMEdit += "=" + strs[++j];
                }
            }
            if (_overrideOMEdit.size() > 10)
                optv.push_back(strdup(_overrideOMEdit.c_str()));
        }
        else
            optv.push_back(strdup(argv[i])); // pass through
    }
    for (oit = opts.begin(); oit != opts.end(); oit++)
    {
        optv.push_back(strdup(oit->first.c_str()));
        optv.push_back(strdup(oit->second.c_str()));
    }

    return optv;
}

void OMCFactory::fillArgumentsToIgnore()
{
    _argumentsToIgnore = unordered_set<string>();
    _argumentsToIgnore.insert("-abortSlowSimulation"); // used by nightly tests
}

void OMCFactory::fillArgumentsToReplace()
{
    _argumentsToReplace = map<string, string>();
    _argumentsToReplace.insert(pair<string, string>("-r", "-F"));
    _argumentsToReplace.insert(pair<string, string>("-ls", "-L"));
    _argumentsToReplace.insert(pair<string, string>("-nls", "-N"));
    _argumentsToReplace.insert(pair<string, string>("-lv", "--log-settings"));
    _argumentsToReplace.insert(pair<string, string>("-w", "--warn-all"));
    _argumentsToReplace.insert(pair<string, string>("-logFormat", "--log-format"));
    _argumentsToReplace.insert(pair<string, string>("-port", "--log-port"));
    _argumentsToReplace.insert(pair<string, string>("-alarm", "--alarm"));
    _argumentsToReplace.insert(pair<string, string>("-emit_protected", "--emit-results all"));
    _argumentsToReplace.insert(pair<string, string>("-inputPath", "--input-path"));
    _argumentsToReplace.insert(pair<string, string>("-outputPath", "--output-path"));
}

pair<shared_ptr<ISimController>, SimSettings>
OMCFactory::createSimulation(int argc, const char* argv[],
                             map<string, string>& opts)
{
    vector<const char *> optv = handleComplexCRuntimeArguments(argc, argv, opts);
    vector<const char *> optv2 = handleArgumentsToReplace(optv.size(), &optv[0], opts);

    SimSettings settings = readSimulationParameter(optv2.size(), &optv2[0]);

    shared_ptr<ISimController> simcontroller = createSimController();

    for (int i = 0; i < optv.size(); i++)
        free((char*)optv[i]);

    optv.clear();

    for (int i = 0; i < optv2.size(); i++)
        free((char*)optv2[i]);

    optv2.clear();

    return make_pair(simcontroller, settings);
}

shared_ptr<ISimController> OMCFactory::createSimController()
{
    type_map simcontroller_type_map;
    fs::path simcontroller_path = _library_path;
    fs::path simcontroller_name(SIMCONTROLLER_LIB);
    simcontroller_path /= simcontroller_name;

    shared_ptr<ISimController> simcontroller =
        loadSimControllerLib(simcontroller_path.string(), simcontroller_type_map);
    return simcontroller;
}

LOADERRESULT OMCFactory::LoadLibrary(string libName, type_map& current_map)
{
    shared_library lib;
    if (!load_single_library(current_map, libName, lib))
        return LOADER_ERROR;
    _modules.insert(make_pair(libName, lib));
    return LOADER_SUCCESS;
}

LOADERRESULT OMCFactory::UnloadLibrary(shared_library lib)
{
    if (lib.is_open())
    {
        if (!lib.close())
            return LOADER_ERROR;
        else
            return LOADER_SUCCESS;
    }
    return LOADER_SUCCESS;
}

shared_ptr<ISimController> OMCFactory::loadSimControllerLib(PATH simcontroller_path, type_map simcontroller_type_map)
{
    LOADERRESULT result = LoadLibrary(simcontroller_path, simcontroller_type_map);


  if (result != LOADER_SUCCESS)
    throw ModelicaSimulationError(MODEL_FACTORY,string("Failed loading SimController library from path ") + simcontroller_path);

  map<string, factory<ISimController,PATH,PATH,bool> >::iterator iter;
  map<string, factory<ISimController,PATH,PATH,bool> >& factories(simcontroller_type_map.get());
  iter = factories.find("SimController");


  if (iter == factories.end())
      throw ModelicaSimulationError(MODEL_FACTORY, "No such SimController library");


  return shared_ptr<ISimController>(iter->second.create(_library_path, _modelicasystem_path, _use_zeroMQ));

}

/** @} */ // end of simcorefactoryOMCFactory
