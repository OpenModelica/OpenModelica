#pragma once
/** @addtogroup coreSimcontroller
 *
 *  @{
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
  unsigned int timeOut;
  OutputPointType outputPointType;
  LogSettings logSettings;
  bool nonLinearSolverContinueOnError;
  int solverThreads;
  OutputFormat outputFormat;
  EmitResults emitResults;
  string inputPath;
  string outputPath;
};

/**
 *  SimController to start and stop the simulation
 */
class ISimController
{

public:

  virtual ~ISimController() {};
  virtual weak_ptr<IMixedSystem> LoadSystem(string modelLib,string modelKey) = 0;
  virtual weak_ptr<IMixedSystem> LoadModelicaSystem(PATH modelica_path,string modelKey) = 0;
  virtual void Start(SimSettings simsettings, string modelKey)=0;
  virtual shared_ptr<IMixedSystem> getSystem(string modelname) = 0;
  virtual  shared_ptr<ISimObjects> getSimObjects() = 0;
  virtual void initialize(SimSettings simsettings, string modelKey, double timeout)=0;
  virtual void StartReduceDAE(SimSettings simsettings,string modelPath, string modelKey, bool loadMSL, bool loadPackage)=0;
  virtual void runReducedSimulation()=0;
  /**
   *    Stops the simulation
   */
  virtual void Stop() = 0;
};
/** @} */ // end of coreSimcontroller
