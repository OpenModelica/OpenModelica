#pragma once
/** @addtogroup coreSimcontroller
 *  
 *  @{
 */
/*includes removed for static linking not needed any more
#ifdef RUNTIME_STATIC_LINKING
#include <Core/SimController/ISimData.h>
#include <Core/System/IMixedSystem.h>
#include <Core/System/IAlgLoopSolverFactory.h>
#include <Core/SimulationSettings/IGlobalSettings.h>
#include <boost/weak_ptr.hpp>
#include <boost/shared_ptr.hpp>

#include <string.h>
using std::string;
#endif
*/
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
  LogType logType;
};

/**
 *  SimController to start and stop the simulation
 */
class ISimController
{

public:
 
  virtual ~ISimController() {};
  virtual boost::weak_ptr<IMixedSystem> LoadSystem(string modelLib,string modelKey) = 0;
  virtual boost::weak_ptr<IMixedSystem> LoadModelicaSystem(PATH modelica_path,string modelKey) = 0;
  virtual boost::weak_ptr<ISimData> LoadSimData(string modelKey) = 0;
  /**
  Creates  SimVars object, stores all model variable in continuous block of memory
     @param  model name
     @param dim_real  number of all real variables (real algebraic vars,discrete algebraic vars, state vars, der state vars)
     @param dim_int   number of all integer variables integer algebraic vars
     @param dim_bool  number of all bool variables (boolean algebraic vars)
     @param dim_pre_vars number of all pre variables (real algebraic vars,discrete algebraic vars, boolean algebraic vars, integer algebraic vars, state vars, der state vars)
     @param dim_z number of all state variables
     @param z_i start index of state vector in real_vars list
     */
  virtual boost::weak_ptr<ISimVars> LoadSimVars(string modelKey,size_t dim_real,size_t dim_int,size_t dim_bool,size_t dim_pre_vars,size_t dim_z,size_t z_i) = 0;
  /**
  Starts the simulation
  @param modelKey Modelica model name
  @param modelica_path: path to Modelica system dll
  */
  virtual void Start(SimSettings simsettings, string modelKey)=0;

  virtual void StartVxWorks(SimSettings simsettings,string modelKey) = 0;
  virtual boost::weak_ptr<ISimData> getSimData(string modelname) = 0;
  virtual boost::weak_ptr<ISimVars> getSimVars(string modelname) = 0;
  virtual boost::weak_ptr<IMixedSystem> getSystem(string modelname) = 0;
  virtual void calcOneStep() = 0;

  /**
   *    Stops the simulation
   */
  virtual void Stop() = 0;
};
/** @} */ // end of coreSimcontroller
