#include "omcZeromqTask.h"
#include "IOMCZeromq.h"

//boost property tree to read and write json streams

#include <boost/program_options.hpp>
#include <boost/foreach.hpp>












omcZeromqTask::omcZeromqTask(int pub_port, int sub_port, OMCData* omc2, string workingDirectory, string openmodelica_home, string simulation_id, string client_id, string zeromq_options,bool debug)
    : ctx_(1),
    _omc(omc2),
    _pub_port(pub_port),
    _sub_port(sub_port),
    publisher_(ctx_, ZMQ_PUB),
    //  publisher2_(ctx_, ZMQ_PUB),
    subscriber_(ctx_, ZMQ_SUB),
    _working_directory(workingDirectory),
    _openmodelica_home(openmodelica_home),
    _zeromq_options(zeromq_options),
    _simulation_id(simulation_id),
    _client_id(client_id),
    _debug(debug)
 {
   
}

void omcZeromqTask::run()
{
 
    try
    {
        GC_stack_base sb;
        GC_get_stack_base(&sb);
        GC_register_my_thread(&sb);

        try
        {
            //set up connection for send data
            publisher_.connect("tcp://127.0.0.1:" + std::to_string(_pub_port));

            //set up connection for receive data
            subscriber_.connect("tcp://127.0.0.1:" + std::to_string(_sub_port));
            //register for OMCSimulator notifications
            subscriber_.setsockopt(ZMQ_SUBSCRIBE, _simulation_id.c_str(), 12);
        }
        catch(std::exception& ex)
        {
             std::cout << "zeroMQ connection failed" << ex.what() <<  std::endl;
             throw;
        }
        string zeromq_simultaion_thread_id = _simulation_id + string("Thread");
        
        // Create a root
        pt::ptree root;
        
        
        
      
        int status = 0;
        char* errorMsg = 0;
        char* result = 0;
        string error_msg;
        string result_msg;


         
        
        
        
        //Load MSL
        if(_debug)
            std::cout << "load MSL" << std::endl;
        status = loadMSL(_omc);
        result_msg = "";
        if (!checkStatus(_omc,status,error_msg,result_msg))
        {
            
            string  exception_msg  = "Coudl not load MSL " + error_msg;
            throw std::invalid_argument(exception_msg);
        }


        while (1) {
            
            
           
            if(_debug)
               std::cout << "Waiting for user commands" << std::endl;
            string jobId;
           
            //  Read envelope with address
            std::string topic = s_recv(subscriber_);
            //  Read message contents
            std::string type = s_recv(subscriber_);
            //  Read message contents
            std::string message = s_recv(subscriber_);
            std::stringstream ss(message);
            
            if(_debug)
            { 
                std::cout << "Received user command with: " << std::endl;
                std::cout << "\t Topic: " << topic <<  std::endl;
                std::cout << "\t Type: " << type  <<  std::endl; 
                std::cout << "\t Message: " << message << std::endl;
            }
            
            pt::read_json(ss, root);
           
            //read simulation id
            jobId = root.get < std::string >("jobId");
           
            
            


            

            if (type == "StartSimulation")
            {
             
               
                string error;
                setZeroMQID(_omc, jobId, error);
             
                std::thread simulation = std::thread(&omcZeromqTask::startSimulation, this, std::ref(root));
                simulation.detach();

                s_sendmore(publisher_, _client_id);
                s_sendmore(publisher_, "SimulationStarted");
                s_send(publisher_, "{\"JobId\":\"" + jobId + "\"}");
            }
            else if (type == "SimulationThreadWatingForID")
            {
                if(_debug)
                { 
                    std::cout << "simulation Thread started: " << std::endl;
                }
                s_sendmore(publisher_, zeromq_simultaion_thread_id);
                s_sendmore(publisher_, "StartSimulationThread");
                s_send(publisher_, "{\"jobId\":\"" + jobId + "\"}");

                //testSimulation(omc, "tmp");
                /*s_sendmore(publisher_, "Client");
                s_sendmore(publisher_, "SimulationFinished");
                s_send(publisher_, "{\"Succeeded\":true,\"JobId\":\""+jobId+"\",\"ResultFile\":\"\",\"Error\":\"\"}");*/
            }

            else if (type == "StopSimulation")
            {

                if(_debug)
                { 
                    std::cout << "simulation Thread stoped: " << std::endl;
                }
                s_sendmore(publisher_, zeromq_simultaion_thread_id);
                s_send(publisher_, "StopSimulationThread");
                s_send(publisher_, "{\"jobId\":\"" + jobId + "\"}");

            }
        }
        GC_unregister_my_thread();
    
    }
    catch (...)
    {
      
        globalZeroMQTaskExceptionPtr = std::current_exception();
    }
}
void omcZeromqTask::startSimulation(pt::ptree& node)
{
    try
    {
        GC_stack_base sb;
        GC_get_stack_base(&sb);
        GC_register_my_thread(&sb);
      
        std::string classPath;
        int status = 0;
        bool command_status = false;
        string error_msg;
        string result_msg;
        
        //read model name
        classPath = node.get < std::string >("classPath");
        if(_debug)
        { 
            std::cout << "startSimulation for: " << classPath << std::endl;
        }
       
        //read modelica file names which has to be loaded
        BOOST_FOREACH(const pt::ptree::value_type & child,
            node.get_child("moFiles"))
        {
            string filename = child.second.get_value<string>();
            status = LoadFile(_omc, filename.c_str());
            result_msg = "";
            if (!checkStatus(_omc,status,error_msg,result_msg))
            {
                string exception_msg = "Coudl not load file: " + error_msg;
                throw std::invalid_argument(exception_msg);
            }
        }


        string error;
        string results;
        command_status = setModelParameter(_omc, classPath, node, error);
        if (!command_status)
        {

            string exception_msg = "Could set model parameter" + string(classPath) + string(" with error: ") + error;
            throw std::invalid_argument(exception_msg);
        }
        command_status = simulateModel(_omc, classPath, node, _working_directory, results, error);
        if(_debug)
        { 
            std::cout << "received simulatoin results: " << std::endl;
            std::cout << "\t" << results;
        }
        if (!command_status)
        {

            string exception_msg = "Could not simulate model " + string(classPath) + string(" with error: ") + string(error);
            throw std::invalid_argument(exception_msg);
        }
        GC_unregister_my_thread();
    }
    catch (...)
    {
      
        globalSimulationExceptionPtr = std::current_exception();
    }
}
bool  omcZeromqTask::setModelParameter(OMCData* omc, string model_name, pt::ptree& node,string& error)
{
    int status = 0;
    //omc api call for setting parameter vlaues;
    char* errorMsg = 0;
    char* result = 0;
    string error_msg;
    string result_msg;
    
    //Read model paramater
    BOOST_FOREACH(const pt::ptree::value_type & parameter,
        node.get_child("parameters"))
    {
       
        string type = parameter.second.get < string >("type");
        string name = parameter.second.get < string >("name");
        string set_parameter = string("setParameterValue(") + model_name + string(",")+ string(name) + string(",");
       //set real parameter
        if (string("real").compare(type) == 0)
        {
            double value = parameter.second.get < double >("value");
            //append the paramter value
            string set_value = std::to_string(value) + string("\)");
            set_parameter.append(set_value);
        }
        //set int parameter
        else if (string("int").compare(type) == 0)
        {
            int value = parameter.second.get < int >("value");
            //append the paramter value
            string set_value = string(",") + std::to_string(value) + string("\)");
            set_parameter.append(set_value);
        }
        //set bool parameter
        else if (string("bool").compare(type) == 0)
        {
            bool value = parameter.second.get < bool >("value");
            //append the paramter value
            string set_value = string(",") + std::to_string(value) + string("\)");
            set_parameter.append(set_value);
        }
        //set real,int vector parameter
        else if ((string("vector<real>").compare(type) == 0) || string("vector<int>").compare(type) == 0)
        {
            string set_value = string("\{");
            int row = 0;
            BOOST_FOREACH(const pt::ptree::value_type & elem, parameter.second.get_child("value"))
            {
                    set_value.append(elem.second.get_value<std::string>());
                    set_value.append(",");
            }
            set_value.pop_back();
            set_value.append("\}\)");
            set_parameter.append(set_value);

        }
        //set real,int matrix parameter
        else if ((string("matrix<real>").compare(type) == 0)|| string("matrix<int>").compare(type) == 0)
        {
            string set_value = string("\{");
            int row = 0;
            BOOST_FOREACH(const pt::ptree::value_type & row, parameter.second.get_child("value"))
            {
                set_value.append("\{");
                // rowPair.first == ""
                BOOST_FOREACH(const pt::ptree::value_type & elem, row.second)
                {
                   
                    set_value.append(elem.second.get_value<std::string>());                
                    set_value.append(",");
                }
                set_value.pop_back();
                set_value.append("\}");
                set_value.append(",");
            }
            set_value.pop_back();
            set_value.append("\}\)");
            set_parameter.append(set_value);
            
        }
        else
        {
            error = string("parameter type ") + type + string("is not yet supported");
            return false;
        }
        if(_debug)
        {
            std::cout << "set model paramter : " << set_parameter << std::endl;
        }
        status = SendCommand(omc, set_parameter.c_str(), &result);
        result_msg = "";
        if (!checkStatus(_omc,status,error_msg,result_msg))
        {
            
            error = error_msg;
            return false;
        }
    }



    return true;

}
int omcZeromqTask::loadMSL(OMCData* omc)
{
    char* errorMsg = 0;
    int status = 0;
    char* change_dir_results = 0, * mkDirResults = 0, * version = 0, * errorMsg2 = 0, * simulateResult = 0, * clear = 0;
    status = LoadModel(omc, "Modelica");

    return status;
    if (status > 0)
     if(_debug)
     {    
            std::cout << "loaded MSL " << std::endl;
     }
    else
    {
        std::cout << "load MSL: failed" << std::endl;
        return -1;
    }
    

    status = GetError(omc, &errorMsg);


}


int omcZeromqTask::setZeroMQID(OMCData* omc, std::string jobId,string& error_msg)
{
    char* errorMsg = 0;
    int status = 0;
    
    string setJobID = "--zeroMQJOBID=" + jobId ;
    status = SetCommandLineOptions(omc, setJobID.c_str());
    if (!status)
    {
        GetError(omc, &errorMsg);
        error_msg = string(errorMsg);
        return -1;
    }
    return status;

}


bool omcZeromqTask::simulateModel(OMCData* omc, string model_name, pt::ptree& node,string tmp_dir, string& results, string& error)
{

    int status = 0;
    char* change_dir_results = 0, * mkDirResults = 0, * version = 0, * errorMsg = 0, * simulateResult = 0, * clear = 0;
    string error_msg;
    string result_msg;
    
    pt::ptree& solver_settings = node.get_child("solverSettings");
    
    //Read simulation settings
    double start_time = solver_settings.get < double >("startTime");
    double stop_time = solver_settings.get < double >("stopTime");
    double number_of_intervalls = solver_settings.get < double >("numberOfIntervals");
    double tolerance = solver_settings.get < double >("tolerance");
    string method = solver_settings.get < string >("method");
    string set_method;
    if (!method.empty())
        set_method = method + string("\"");
    if(_debug)
    {    
      std::cout << "read simulation settings : " << std::endl; 
      std::cout << "\t " << set_method << std::endl;
    }
    status = SetWorkingDirectory(omc, tmp_dir.c_str(), &change_dir_results);
   result_msg = string(change_dir_results);
    if (!checkStatus(_omc,status,error_msg,result_msg))
    {

        error = string("Cannot set working directory") + error_msg;
        return false;
    }
    if(_debug)
    { 
     std::cout << "changed working directory : "<< std::endl;
     std::cout << "\t" << tmp_dir << std::endl;
    }
        
    string simulate_model = string("simulate(") + model_name + string(",startTime=") + std::to_string(start_time) + string(",stopTime=") + std::to_string(stop_time) +  set_method + string(",tolerance =") + std::to_string(tolerance) + string(",numberOfIntervals =") + std::to_string(number_of_intervalls)  + string( ")");
    if(_debug)
    {
        std::cout << "start simulation : " << std::endl; 
        std::cout << "\t" << simulate_model << std::endl;
    }
    status = SendCommand(omc, simulate_model.c_str(), &simulateResult);
    result_msg = string(simulateResult);
    if(_debug)
    {
       std::cout << "simulation finished: " << status << std::endl; 
       std::cout << "\t" << result_msg;
    }
    if (!checkStatus(_omc,status,error_msg,result_msg))
    {
    
        error = error_msg;
        return false;
    }
    results = result_msg;
    
    return true;


}

bool omcZeromqTask::checkStatus(OMCData* omc,int status,string& error_msg,string& command_result_msg)
{
    char* errorMsg = 0;
    GetError(omc, &errorMsg);
    error_msg = string(errorMsg);
    if (status<0)
    {
        
        if(_debug)
        {
          std::cout << "received  errors: " << std::endl; 
          std::cout <<  "\t" << errorMsg << std::endl; 
        }
        return false;
    }
    std::vector<std::string> error_keywords{"failed", "error", "aborted"};
    
    for(const auto& keyword : error_keywords)
    {
        auto pos = error_msg.find(keyword);
        if(pos!= string::npos)
        {
          if(_debug)
          {
            std::cout << "received  errors: " << std::endl; 
            std::cout <<  "\t" << errorMsg << std::endl; 
          
          
            return false;
          }
        }
    }
    for(const auto& keyword : error_keywords)
    {
        auto pos = command_result_msg.find(keyword);
        if(pos!= string::npos)
        {
          if(_debug)
          {
            std::cout << "received  errors: " << std::endl; 
            std::cout <<  "\t" << errorMsg << std::endl; 
          
          
            return false;
          }
        }
    }
    return true;
    
}


