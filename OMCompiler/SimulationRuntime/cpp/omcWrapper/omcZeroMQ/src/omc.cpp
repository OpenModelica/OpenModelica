


#include <zmq.hpp>
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
#include "zhelpers.hpp"


OMCData* omc;

// Short alias for this namespace
namespace pt = boost::property_tree;
namespace po = boost::program_options;

// Create a root
pt::ptree root;
using std::string;



void initOMC(OMCData** omc, string compiler)
{
    //std::cout << "Initialize OMC" << std::endl;
    InitMetaOMC();

    int status = 0;
    char* change_dir_results = 0, *mkDirResults = 0, *version = 0, *errorMsg2 = 0, *simulateResult = 0, *clear = 0;

    // if you send in 1 here it will crash on Windows, i need do debug more why this happens
    status = InitOMC(omc, compiler.c_str(), "");
    /*
    if (status > 0)
        std::cout << "init omc using compiler " << compiler << ": ok" << std::endl;
    else
        std::cout << "init omc: failed" << std::endl;
     */
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








#if defined(_MSC_VER) || defined(__MINGW32__)
#include <tchar.h>

int _tmain(int argc, const _TCHAR* argv[])
#else
int main(int argc, const char* argv[])
#endif
{
    po::options_description desc("Allowed options");
    desc.add_options()
        ("help,h", "produce help message")
        ("port-publish,p", po::value<int>(), "zeromq publishing port")
        ("port-subscribe,s", po::value<int>(), "zeromq subscribing port")
        ("simlation-ID,i", po::value<int>(), "ID that identifies the translation and simulation for one model")
        ("OpenModelicaHome-path,o", po::value<string>(), "Path of OpenModelica home folder")
        ;
    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    
    int port_pub;
    int port_sub;
    int simulation_id;
    string openmodelica_home_path;
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
    if (vm.count("simlation-ID"))
    {
        simulation_id = vm["simlation-ID"].as<int>();
    }
    else
        throw std::invalid_argument("Simulation idendifier was not passed");
    if (vm.count("OpenModelicaHome-path"))
    {
       
        openmodelica_home_path = vm["OpenModelicaHome-path"].as<string>();
     
    }
    else
        throw std::invalid_argument("Path for OpenModelica home was not passed");


    initOMC(&omc, "msvc15");
    string version = getVersion(omc);
    std::cout << "used omc version: " << version << std::endl;
}


