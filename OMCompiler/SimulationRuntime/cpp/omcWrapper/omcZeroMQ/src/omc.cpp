


#include <zmq.hpp>
#include "zhelpers.hpp"
#include <string>
#include <vector>
#include <thread>
#include <memory>
#include <functional>
#include <iostream>
#ifndef _WIN32
#include <unistd.h>
#else
#include <windows.h>
#endif
#include "OMC.h"
//boost property tree to read and write json streams
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>
#include <boost/program_options.hpp>
#include <exception>
#include "omcZeromqTask.h"
//#define GC_THREADS
//#include "gc.h"

using std::string;
OMCData* omc;

int initOMCWithZeroMQ(OMCData** omc, string compiler,string codetarget, string openmodelicaHome, string zeroMQOptions);
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
            ;
        po::variables_map vm;
        po::store(po::parse_command_line(argc, argv, desc), vm);
        po::notify(vm);


        int port_pub;
        int port_sub;
        string simulation_id;
        string client_id;
        string openmodelica_home_path;
        string working_directory;
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


        /*GC_INIT();
        GC_allow_register_threads();*/

        //enable use of zeomq in simulation and configure port numbers and simulation idendifier
        string zeromqOptions = "--useZeroMQInSim=true --zeroMQPubPort=" + std::to_string(port_pub) + " --zeroMQSubPort=" + std::to_string(port_sub) + " --zeroMQServerID=" + simulation_id + " --zeroMQClientID=" + client_id;



        int status = 0;
        char* errorMsg = 0;
        char* result = 0;



        //intitalize omc with above options
        status = initOMCWithZeroMQ(&omc, "msvc15","cpp", openmodelica_home_path, zeromqOptions);
        if (!status)
            throw std::invalid_argument("Could not iniitialize omc");

        string version = getVersion(omc);
        std::cout << "used omc version: " << version << std::endl;

  
    
    omcZeromqTask st(port_pub, port_sub,omc, working_directory,openmodelica_home_path, simulation_id,client_id,zeromqOptions);


    std::thread t(std::bind(&omcZeromqTask::run, &st));

    t.detach();

    getchar();

      }
    catch (std::exception & ex)
    {

        std::cout << "Stop omc zeromq application with error: " << ex.what();
      
        return -1;
    }

    return 1;
 
}


int initOMCWithZeroMQ(OMCData** omc, string compiler,string codetarget, string openmodelicaHome, string zeroMQOptions)
{

    int status = 0;
    std::string set_omhome_var = string("OPENMODELICAHOME=") + openmodelicaHome;

#ifdef _WIN32
    status = SetEnvironmentVariable("OPENMODELICAHOME", TEXT(openmodelicaHome.c_str()));
#endif
   
    InitMetaOMC();


    char* change_dir_results = 0, * mkDirResults = 0, * version = 0, * errorMsg2 = 0, * simulateResult = 0, * clear = 0;

    // if you send in 1 here it will crash on Windows, i need do debug more why this happens
    status = InitOMCWithZeroMQ(omc, compiler.c_str(), codetarget.c_str(),openmodelicaHome.c_str(), zeroMQOptions.c_str());


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







