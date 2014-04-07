#pragma once
#include <SimController/ISimData.h>
#include <System/IMixedSystem.h>
#include <System/IAlgLoopSolverFactory.h>
#include <SimulationSettings/IGlobalSettings.h>
#include <boost/weak_ptr.hpp>
#include <boost/shared_ptr.hpp>

#include <string.h>
using std::string;

struct SimSettings
{
    string solver_name;
    string nonlinear_solver_name;
    double start_time;
    double end_time;
    double step_size;
    double lower_limit;
    double upper_limit;
    double tolerance;
    string outputfile_name;
    OutputFormat outputFormat;

};

/*SimController to start and stop the simulation*/
class ISimController
{

public:
    /// Enumeration to control the time integration
    virtual ~ISimController(){ };

  virtual std::pair<boost::weak_ptr<IMixedSystem>,boost::weak_ptr<ISimData> > LoadSystem(boost::shared_ptr<ISimData> (*createSimDataCallback)(), boost::shared_ptr<IMixedSystem> (*createSystemCallback)(IGlobalSettings*, boost::shared_ptr<IAlgLoopSolverFactory>, boost::shared_ptr<ISimData>), string modelKey)=0;
  virtual std::pair<boost::weak_ptr<IMixedSystem>,boost::weak_ptr<ISimData> > LoadSystem(string modelLib,string modelKey)=0;
    virtual std::pair<boost::weak_ptr<IMixedSystem>,boost::weak_ptr<ISimData> > LoadModelicaSystem(PATH modelica_path,string modelKey) =0;
   
  /*
    Starts the simulation
    modelKey: Modelica model name
    modelica_path: path to Modelica system dll
    */
    virtual void Start(boost::weak_ptr<IMixedSystem> mixedsystem,SimSettings simsettings/*,ISimData* simData*/)=0;

    /// Stops the simulation
    virtual void Stop()= 0;
};
