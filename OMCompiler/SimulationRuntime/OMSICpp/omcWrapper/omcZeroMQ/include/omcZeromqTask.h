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