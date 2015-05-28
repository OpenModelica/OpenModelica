// declaration for Cpp FMU target

class BouncingBallFMU: public BouncingBallExtension {
 public:
  // create simulation variables
  static ISimVars *createSimVars();

  // constructor
  BouncingBallFMU(IGlobalSettings* globalSettings,
      boost::shared_ptr<IAlgLoopSolverFactory> nonLinSolverFactory,
      boost::shared_ptr<ISimData> simData,
      boost::shared_ptr<ISimVars> simVars);
  
  // initialization
  virtual void initialize();
  
  // getters for given value references
  virtual void getReal(const unsigned int vr[], int nvr, double value[]);
  virtual void getInteger(const unsigned int vr[], int nvr, int value[]);
  virtual void getBoolean(const unsigned int vr[], int nvr, int value[]);
  virtual void getString(const unsigned int vr[], int nvr, string value[]);
  
  // setters for given value references
  virtual void setReal(const unsigned int vr[], int nvr, const double value[]);
  virtual void setInteger(const unsigned int vr[], int nvr, const int value[]);
  virtual void setBoolean(const unsigned int vr[], int nvr, const int value[]);
  virtual void setString(const unsigned int vr[], int nvr, const string value[]);
};