#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/SimController/threading/ToZeroMQEvent.h>
#include "zhelpers.hpp"
 
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>
// Short alias for this namespace
namespace pt = boost::property_tree;

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

    //std::cout << "pub port: " << to_string(pubPort)<< " sub port: " << to_string(subPort) <<  " job id " << zeroMQJobiID << " server thread id " << zeromq_simultaion_thread_id << std::endl;
}
ToZeroMQEvent::~ToZeroMQEvent()
{
  

}

void ToZeroMQEvent::NotifyResults(double progress)
{
    boost::property_tree::ptree progress_tree;
    std::stringstream progress_stream;
    int p = (int)progress;
    if ((_progress != p)&& (!_zeromq_job_id.empty()))
    {

        _progress = p;
        progress_tree.put("JobId", _zeromq_job_id);
        progress_tree.put("Progress", (int)progress);
        pt::write_json(progress_stream, progress_tree);
       
        s_sendmore(publisher_, _zeromq_client_id,false);
        s_sendmore(publisher_, "SimulationProgressChanged",false);
        s_send(publisher_, "{\"jobId\":\"" + _zeromq_job_id + "\",\"progress\":"+ std::to_string(p) +"}",false);
      
      

    }

    
  
}
void ToZeroMQEvent::NotifyWaitForStarting()
{
    //std::cout << "Wating for ID" << std::endl;
    s_sendmore(publisher_, _zeromq_server_id);
    s_sendmore(publisher_, "SimulationThreadWatingForID");
    s_send(publisher_, "{\"jobId\":\"" + _zeromq_job_id + "\"}");

  
     //  Read envelope with address
    std::string topic = s_recv(subscriber_);
    //  Read message contents
    std::string type = s_recv(subscriber_);
    //  Read message contents
    std::string message = s_recv(subscriber_);
    std::stringstream ss(message);
    // Create a root
    pt::ptree root;
    pt::read_json(ss, root);
    _zeromq_job_id = root.get < std::string >("jobId");
    
  
}
bool ToZeroMQEvent::AskForStop()
{
    
    
    std::string message = s_recv(subscriber_, false);
    if (!message.empty())
    {
       // std::cout << "received topic" << message << std::endl;
        //  Read message contents
        std::string type = s_recv(subscriber_,false);
        std::cout << "received type " << type << std::endl;
        if (type == "StopSimulationThread")
        {
            
            return true;
        }
   
    }
    return false;
}


void ToZeroMQEvent::NotifyFinish()
{
    if (!_zeromq_job_id.empty())
    {
        s_sendmore(publisher_, _zeromq_client_id);
        s_sendmore(publisher_, "SimulationFinished");
        s_send(publisher_, "{\"Succeeded\":true,\"JobId\":\"" + _zeromq_job_id + "\",\"ResultFile\":\"\",\"Error\":\"\"}");
    }
    else
        throw ModelicaSimulationError(SIMMANAGER, "No simulation id received");
}

void ToZeroMQEvent::NotifyException(std::string message)
{


}

void ToZeroMQEvent::NotifyStarted()
{
    if (!_zeromq_job_id.empty())
    {
        s_sendmore(publisher_, _zeromq_client_id);
        s_sendmore(publisher_, "SimulationStarted");
        s_send(publisher_, "{\"JobId\":\"" + _zeromq_job_id + "\"}");
    }
}

