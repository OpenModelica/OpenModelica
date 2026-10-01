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

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/SimController/threading/ToZeroMQEvent.h>
#include "zhelpers.hpp"

// The string value of key in a flat JSON object.
static std::string jsonString(const std::string& json, const std::string& key)
{
    size_t pos = json.find("\"" + key + "\"");
    if (pos != std::string::npos)
        pos = json.find(':', pos + key.size() + 2);
    if (pos != std::string::npos)
        pos = json.find('"', pos + 1);
    if (pos == std::string::npos)
        throw ModelicaSimulationError(SIMMANAGER, "No " + key + " in " + json);
    std::string value;
    for (size_t i = pos + 1; i < json.size() && json[i] != '"'; i++)
        value += json[i] == '\\' && i + 1 < json.size() ? json[++i] : json[i];
    return value;
}

ToZeroMQEvent::ToZeroMQEvent(int pubPort, int subPort, string zeroMQJobiID, string zeroMQServerID, string zeroMQClientID)
    :ctx_(1),
    publisher_(ctx_, ZMQ_PUB),
    subscriber_(ctx_, ZMQ_SUB),
    _zeromq_job_id(zeroMQJobiID),
    _zeromq_server_id(zeroMQServerID),
    _zeromq_client_id(zeroMQClientID)

{
    publisher_.connect("tcp://127.0.0.1:" + to_string(pubPort));
    subscriber_.connect("tcp://127.0.0.1:" + to_string(subPort));
    string zeromq_simultaion_thread_id = _zeromq_server_id + string("Thread");
    subscriber_.setsockopt(ZMQ_SUBSCRIBE, zeromq_simultaion_thread_id.c_str(), 18);
    //Needed to establish connection
    std::this_thread::sleep_for(std::chrono::milliseconds(500));


}
ToZeroMQEvent::~ToZeroMQEvent()
{
  

}

void ToZeroMQEvent::NotifyResults(double progress)
{
    int p = (int)progress;
    if ((_progress != p)&& (!_zeromq_job_id.empty()))
    {

        _progress = p;
       
        s_sendmore(publisher_, _zeromq_client_id,false);
        s_sendmore(publisher_, "SimulationProgressChanged",false);
        s_send(publisher_, "{\"jobId\":\"" + _zeromq_job_id + "\",\"progress\":"+ std::to_string(p) +"}",false);
      
      

    }

    
  
}
void ToZeroMQEvent::NotifyWaitForStarting()
{

    s_sendmore(publisher_, _zeromq_server_id);
    s_sendmore(publisher_, "SimulationThreadWatingForID");
    s_send(publisher_, "{\"jobId\":\"" + _zeromq_job_id + "\"}");

  
     //  Read envelope with address
    std::string topic = s_recv(subscriber_);
    //  Read message contents
    std::string type = s_recv(subscriber_);
    //  Read message contents
    std::string message = s_recv(subscriber_);
    _zeromq_job_id = jsonString(message, "jobId");
    
  
}
bool ToZeroMQEvent::AskForStop()
{
    
    
    std::string message = s_recv(subscriber_, false);
    if (!message.empty())
    {

        //  Read message contents
        std::string type = s_recv(subscriber_,false);

        if (type == "StopSimulationThread")
        {
            
            return true;
        }
   
    }
    return false;
}


void ToZeroMQEvent::NotifyFinish(bool success, string erro_message)
{
    if (!_zeromq_job_id.empty())
    {
        s_sendmore(publisher_, _zeromq_client_id);
        s_sendmore(publisher_, "SimulationFinished");
        string sim_success;
        if(success)
            sim_success = "true";
        else
            sim_success = "false";
        string finished = string("{\"Succeeded\":") + sim_success + string(",\"JobId\":\"") + _zeromq_job_id + string("\",\"ResultFile\":\"\",\"Error\":\"") + erro_message +string("\"}");
            s_send(publisher_,finished.c_str());
    }
    else
        throw ModelicaSimulationError(SIMMANAGER, "No simulation id received");
}

void ToZeroMQEvent::NotifyException(std::string message)
{
if (!_zeromq_job_id.empty())
    {
        s_sendmore(publisher_, _zeromq_client_id);
        s_sendmore(publisher_, "SimulationFinished");
        string finished = string("{\"Succeeded\":false,\"JobId\":\"") + _zeromq_job_id + string("\",\"ResultFile\":\"\",\"Error\":\"") + message + string("\"}");

        s_send(publisher_,finished.c_str());
    }
    else
        throw ModelicaSimulationError(SIMMANAGER, "No simulation id received");

}

void ToZeroMQEvent::NotifyStarted()
{
    if (!_zeromq_job_id.empty())
    {
        s_sendmore(publisher_, _zeromq_client_id);
        s_sendmore(publisher_, "SimulationStarted");
        s_send(publisher_, "{\"JobId\":\"" + _zeromq_job_id + "\"}");
    }
     else
        throw ModelicaSimulationError(SIMMANAGER, "No simulation id received");
}

