


#include <zmq.hpp>


#ifndef _WIN32
#include <unistd.h>
#else
#include <windows.h>
#endif

#include <ModelicaDefine.h>
#include <Modelica.h>

//boost property tree to read and write json streams
#define BOOST_SPIRIT_THREADSAFE
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>
#include <boost/program_options.hpp>

#include "IOMCZeromq.h"
#include "omcZeromqTask.h"



using std::string;
OMCData* omc;

int initOMCWithZeroMQ(OMCData** omc, string compiler,string codetarget, string openmodelicaHome, string zeroMQOptions,bool debug);
string getVersion(OMCData* omc);

// Short alias for this namespace
namespace po = boost::program_options;



#if defined(_MSC_VER) || defined(__MINGW32__)
#include <tchar.h>


int _tmain(int argc, const _TCHAR* argv[])
#else
int main(int argc, const char* argv[])
#endif
{
    
   
    
    int port_pub;
        int port_sub;
        string simulation_id;
        string client_id;
        string openmodelica_home_path;
        string working_directory;
        string compiler;
        bool debug;
	
	try
    {

        po::options_description desc("Allowed options");
        desc.add_options()
            ("help,h", "produce help message")
            ("port-publish,p", po::value<int>(), "zeromq publishing port")
            ("port-subscribe,s", po::value<int>(), "zeromq subscribing port")
            ("simulation-id,i", po::value<string>(), "ID that identifies the translation and simulation for one model")
            ("client-id,c", po::value<string>(), "ID that identifies the client application")
            ("OpenModelicaHome-path,o", po::value<string>(), "Path of OpenModelica home folder")
            ("workingDirectory,w", po::value<string>(), "Path of working directory where model is generated and simulated")
            ("cppCompiler,g", po::value<string>()->default_value("msvc15"), "C++ Compiler, gcc or msvc. For a special VS version, e.g. VS 2015 use msvc15")
            ("debug,d", po::value<bool>()->default_value("false"), "print debug logging information to the console")
            ;
        po::variables_map vm;
        po::store(po::parse_command_line(argc, argv, desc), vm);
        po::notify(vm);


        if (vm.count("help"))
        {
            std::cout << "Usage: options_description [options]\n";
            std::cout << desc;
            return 0;
        }
        if (vm.count("port-publish"))
        {
            port_pub = vm["port-publish"].as<int>();
        }
        else
            throw std::invalid_argument("zeromq port for publish was not passed");
        if (vm.count("port-subscribe"))
        {
            port_sub = vm["port-subscribe"].as<int>();
        }
        else
            throw std::invalid_argument("zeromq port for subscribe was not passed");
        if (vm.count("simulation-id"))
        {
            simulation_id = vm["simulation-id"].as<string>();
        }
        else
            throw std::invalid_argument("Simulation server idendifier was not passed");
        if (vm.count("client-id"))
        {
            client_id = vm["client-id"].as<string>();
        }
        else
            throw std::invalid_argument("Simulation server idendifier was not passed");
        if (vm.count("OpenModelicaHome-path"))
        {

            openmodelica_home_path = vm["OpenModelicaHome-path"].as<string>();

        }
        else
            throw std::invalid_argument("Path for OpenModelica home was not passed");


        if (vm.count("workingDirectory"))
        {

            working_directory = vm["workingDirectory"].as<string>();

        }
        else
            // throw std::invalid_argument("Wokring directory folder was not passed");
            working_directory = "C:\\temp";
        if (vm.count("cppCompiler"))
        {

            compiler = vm["cppCompiler"].as<string>();

        }
        if (vm.count("debug"))
        {

            debug = vm["debug"].as<bool>();

        }
	}
	catch(po::error e)
    {
        std::cout << "Reading arguments error: " << e.what();
        return 1;
    }
    try
	{
       GC_INIT();
        GC_allow_register_threads();

        //enable use of zeomq in simulation and configure port numbers and simulation idendifier
        string zeromqOptions = "--useZeroMQInSim=true --zeroMQPubPort=" + std::to_string(port_pub) + " --zeroMQSubPort=" + std::to_string(port_sub) + " --zeroMQServerID=\"" + simulation_id + "\" --zeroMQClientID=\"" + client_id +"\"";



        int status = 0;
        char* errorMsg = 0;
        char* result = 0;
//#ifdef WIN32
//
//        SetEnvironmentVariable();
//#endif

        

        //intitalize omc with above options
        status = initOMCWithZeroMQ(&omc, compiler.c_str(),"omsicpp", openmodelica_home_path, zeromqOptions,debug);
        if (!status)
            throw std::invalid_argument("Could not iniitialize omc");

        string version = getVersion(omc);
        if(debug)
          std::cout << "used omc version: " << version << std::endl;

  
    
    omcZeromqTask st(port_pub, port_sub,omc, working_directory,openmodelica_home_path, simulation_id,client_id,zeromqOptions,debug);


    std::thread t(std::bind(&omcZeromqTask::run, &st));

    t.join();
    
     if (globalSimulationExceptionPtr)
     {
        std::rethrow_exception(globalSimulationExceptionPtr);
     }
         
     if (globalZeroMQTaskExceptionPtr)
     {
        std::rethrow_exception(globalZeroMQTaskExceptionPtr);
     }

    getchar();

    }
    catch (std::exception & ex)
    {

        std::cout << "Stop omc zeromq application with error: " << ex.what();
    
        return 1;
    }

    return 0;
 
}


int initOMCWithZeroMQ(OMCData** omc, string compiler,string codetarget, string openmodelicaHome, string zeroMQOptions,bool debug)
{

    int status = 0;
    std::string set_omhome_var = string("OPENMODELICAHOME=") + openmodelicaHome;

#ifdef _WIN32
    status = SetEnvironmentVariable("OPENMODELICAHOME", TEXT(openmodelicaHome.c_str()));
#endif
   
    InitMetaOMC();


    char* change_dir_results = 0, * mkDirResults = 0, * version = 0, * errorMsg2 = 0, * simulateResult = 0, * clear = 0;
    int debug_logging = 0;
    if(debug)
        debug_logging = 1;
    // if you send in 1 here it will crash on Windows, i need do debug more why this happens
    status = InitOMCWithZeroMQ(omc, compiler.c_str(), codetarget.c_str(),openmodelicaHome.c_str(), zeroMQOptions.c_str(),debug_logging);


    return status;




}

string getVersion(OMCData* omc)
{
    int status = 0;

    char* version;
    status = GetOMCVersion(omc, &version);
    /*
    if (status > 0)
        std::cout << "get version: ok " << version << std::endl;
    else
        std::cout << "get version: failed " << std::endl;
    */
    return string(version);
}







