/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#include <zmq.hpp>

#define BOOST_SPIRIT_THREADSAFE
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>

using std::string;
// Create a root
namespace pt = boost::property_tree;
typedef struct OMCData;

class omcZeromqTask {
public:
    omcZeromqTask(int pub_port, int sub_port, OMCData* omc2, string workingDirectory, string openmodelica_home, string simulation_id, string client_id, string zeromq_options,bool debug);
   
    void run();
    
protected:
    void startSimulation(pt::ptree& node);
    bool simulateModel(OMCData* omc, string model_name, pt::ptree& node, string tmp_dir, string& results_msg, string& error_msg);
    int setZeroMQID(OMCData* omc, std::string jobId, string& error_msg);
    bool setModelParameter(OMCData* omc, string model_name, pt::ptree& node, string& error_msg);
    bool checkStatus(OMCData* omc,int status,string& error_msg,string& command_result_msg);

    int loadMSL(OMCData* omc);

private:
    zmq::context_t ctx_;
    zmq::socket_t publisher_;
    //  zmq::socket_t publisher2_;
    zmq::socket_t subscriber_;
    int _pub_port;
    int _sub_port;
    OMCData* _omc;
    string _working_directory;
    string _openmodelica_home;
    string _zeromq_options;
    string _simulation_id;
    string _client_id;
    bool _debug;

};