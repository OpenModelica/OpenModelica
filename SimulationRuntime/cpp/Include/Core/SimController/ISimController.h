#pragma once

#ifdef ANALYZATION_MODE
#include <Core/SimController/ISimData.h>
#include <Core/System/IMixedSystem.h>
#include <Core/System/IAlgLoopSolverFactory.h>
#include <Core/SimulationSettings//IGlobalSettings.h>
#include <boost/weak_ptr.hpp>
#include <boost/shared_ptr.hpp>

#include <string.h>
using std::string;
#endif

struct SimSettings
{
    string solver_name;
    string linear_solver_name;
    string nonlinear_solver_name;
    double start_time;
    double end_time;
    double step_size;
    double lower_limit;
    double upper_limit;
    double tolerance;
    string outputfile_name;
    OutputFormat outputFormat;
    unsigned int timeOut;
    OutputPointType outputPointType;

};

/*SimController to start and stop the simulation*/
class ISimController
{

public:
    /// Enumeration to control the time integration
    virtual ~ISimController(){ };

  virtual std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> > LoadSystem(boost::shared_ptr<ISimData> (*createSimDataCallback)(), boost::shared_ptr<IMixedSystem> (*createSystemCallback)(IGlobalSettings*, boost::shared_ptr<IAlgLoopSolverFactory>, boost::shared_ptr<ISimData>), string modelKey)=0;
  virtual std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> > LoadSystem(string modelLib,string modelKey)=0;
    virtual std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> > LoadModelicaSystem(PATH modelica_path,string modelKey) =0;

  /*
    Starts the simulation
    modelKey: Modelica model name
    modelica_path: path to Modelica system dll
    */
    virtual void Start(boost::shared_ptr<IMixedSystem> mixedsystem,SimSettings simsettings,string modelKey)=0;

    /// Stops the simulation
    virtual void Stop()= 0;
};
