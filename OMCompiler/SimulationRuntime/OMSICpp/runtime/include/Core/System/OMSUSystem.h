#include <Core/System/ExtendedSystem.h>

// adrpo: link with static libfmilib.a on MinGW
// if this is not desired we need to signal this
// from the CMakeFiles.txt with a define when we
// compile shared DLLs and link with dynamic
// fmilib_shared.dll instead of static libfmilib.a
#if defined(__MINGW32__)
#define FMILIB_STATIC_LIB_ONLY
#endif
#include <fmilib.h>

//Forward declaration to speed-up the compilation process
class Functions;
class EventHandling;
class DiscreteEvents;


/*****************************************************************************
*
*
*
*****************************************************************************/



typedef vector<tuple<fmi2_import_variable_t*, unsigned int>> out_vars_t;




class omsi_me;

class OMSUSystem : public IContinuous, public IEvent, public IStepEvent, public IStateSelection, public ITime,
                  public ISystemProperties, public ISystemInitialization, public IMixedSystem, public IWriteOutput,
                  public ExtendedSystem
{
public:

    OMSUSystem(shared_ptr<IGlobalSettings> globalSettings, string _osu_name);
    OMSUSystem(OMSUSystem& instance);

    virtual ~OMSUSystem();
    virtual void initialize();
    virtual void initEquations();
    virtual void setInitial(bool);
    virtual bool initial();
    virtual void initializeMemory();
    virtual void initializeFreeVariables();
    virtual void initializeBoundVariables();


    /// Releases the Modelica System
    virtual void destroy();
    /// Provide number (dimension) of variables according to the index
    virtual int getDimContinuousStates() const;
    virtual int getDimAE() const;
    /// Provide number (dimension) of boolean variables
    virtual int getDimBoolean() const;
    /// Provide number (dimension) of integer variables
    virtual int getDimInteger() const;
    /// Provide number (dimension) of real variables
    virtual int getDimReal() const;
    /// Provide number (dimension) of string variables
    virtual int getDimString() const;
    /// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
    virtual int getDimRHS() const;
    virtual double& getRealStartValue(double& var);
    virtual bool& getBoolStartValue(bool& var);
    virtual int& getIntStartValue(int& var);
    virtual string& getStringStartValue(string& var);
    virtual void setRealStartValue(double& var, double val);
    virtual void setBoolStartValue(bool& var, bool val);
    virtual void setIntStartValue(int& var, int val);
    virtual void setStringStartValue(string& var, string val);

    virtual void setNumPartitions(int numPartitions);
    virtual int getNumPartitions();
    virtual void setPartitionActivation(bool* partitions);
    virtual void getPartitionActivation(bool* partitions);
    virtual int getActivator(int state);

    //Resets all time events

    // Provide variables with given index to the system
    virtual void getContinuousStates(double* z);
    virtual void getNominalStates(double* z);
    // Set variables with given index to the system
    virtual void setContinuousStates(const double* z);

    virtual const matrix_t& getJacobian();
    virtual const matrix_t& getJacobian(unsigned int index);
    virtual sparsematrix_t& getSparseJacobian();
    virtual sparsematrix_t& getSparseJacobian(unsigned int index);


    virtual const matrix_t& getStateSetJacobian(unsigned int index);
    virtual sparsematrix_t& getStateSetSparseJacobian(unsigned int index);
    /// Called to handle all events occured at same time
    virtual bool handleSystemEvents(bool* events);
    //Saves all variables before an event is handled, is needed for the pre, edge and change operator
    virtual void saveAll();
    virtual void getAlgebraicDAEVars(double* y);
    virtual void setAlgebraicDAEVars(const double* y);
    virtual void getResidual(double* f);

    // Copy the given IMixedSystem instance
    virtual IMixedSystem* clone();

    /*colored jacobians*/
    virtual void getAColorOfColumn(int* aSparsePatternColorCols, int size);
    virtual int getAMaxColors();

    virtual string getModelName();
    virtual bool isJacobianSparse();
    //true if getSparseJacobian is implemented and getJacobian is not, false if getJacobian is implemented and getSparseJacobian is not.
    virtual bool isAnalyticJacobianGenerated(); //true if the flag --generateDynamicJacobian=symbolic, false if not.
    virtual shared_ptr<ISimObjects> getSimObjects();


    // Update transfer behavior of the system of equations according to command given by solver
    virtual bool evaluateAll(const UPDATETYPE command = IContinuous::UNDEF_UPDATE);
    virtual void evaluateODE(const UPDATETYPE command = IContinuous::UNDEF_UPDATE);
    virtual void evaluateZeroFuncs(const UPDATETYPE command = IContinuous::UNDEF_UPDATE);
    virtual bool evaluateConditions(const UPDATETYPE command);
    virtual void evaluateDAE(const UPDATETYPE command = UNDEF_UPDATE);


    // Provide the right hand side (according to the index)
    virtual void getRHS(double* f);
    virtual void setStateDerivatives(const double* f);

    //Provide number (dimension) of zero functions
    virtual int getDimZeroFunc();
    //Provide number (dimension) of zero functions
    virtual int getDimClock();
    virtual double* clockInterval();
    virtual void setIntervalInTimEventData(int clockIdx, double interval);
    virtual void setClock(const bool* tick, const bool* subactive);
    //Provides current values of root/zero functions
    virtual void getZeroFunc(double* f);
    virtual void setConditions(bool* c);
    virtual void getConditions(bool* c);
    virtual void getClockConditions(bool* c);

    //Called to handle an event
    virtual void handleEvent(const bool* events);
    //Checks if a discrete variable has changed and triggers an event
    virtual bool checkForDiscreteEvents();
    virtual bool stepCompleted(double time);

    //sets the terminal status
    virtual void setTerminal(bool);
    //returns the terminal status
    virtual bool terminal();


    // M is regular
    virtual bool isODE();
    // M is singular
    virtual bool isAlgebraic();

    virtual int getDimTimeEvent() const;
    virtual std::pair<double, double>* getTimeEventData() const;
    virtual double computeNextTimeEvents(double currTime);
    virtual void computeTimeEventConditions(double currTime);
    virtual void resetTimeConditions();
    //initializes the definition of time event samplers (i.e. starttime and frequency)
    virtual void initTimeEventData();

    /// Set current integration time
    virtual void setTime(const double& time);
    virtual double getTime();

    // System is able to provide the Jacobian symbolically
    virtual bool provideSymbolicJacobian();

    virtual void restoreOldValues();
    virtual void restoreNewValues();


    /// Provide boolean variables
    virtual void getBoolean(bool* z);
    /// Provide integer variables
    virtual void getInteger(int* z);
    /// Provide real variables
    virtual void getReal(double* z);
    /// Provide real variables
    virtual void getString(std::string* z);
    /// Provide boolean variables
    virtual void setBoolean(const bool* z);
    /// Provide integer variables
    virtual void setInteger(const int* z);
    /// Provide real variables
    virtual void setReal(const double* z);
    /// Provide real variables
    virtual void setString(const std::string* z);
    virtual bool getCondition(unsigned int index);

    //state selection methods
    int getDimStateSets() const;
    int getDimStates(unsigned int index) const;
    int getDimCanditates(unsigned int index) const;
    int getDimDummyStates(unsigned int index) const;
    void getStates(unsigned int index, double* z);
    void setStates(unsigned int index, const double* z);
    void getStateCanditates(unsigned int index, double* z);
    bool getAMatrix(unsigned int index, DynArrayDim2<int>& A);
    void setAMatrix(unsigned int index, DynArrayDim2<int>& A);
    bool getAMatrix(unsigned int index, DynArrayDim1<int>& A);
    void setAMatrix(unsigned int index, DynArrayDim1<int>& A);
    //write simulation results methods
    virtual void writeOutput(const IWriteOutput::OUTPUT command = IWriteOutput::UNDEF_OUTPUT);
    virtual shared_ptr<IHistory> getHistory();

private:

    bool addVariable(fmi2_import_variable_t* v, out_vars_t& output_value_references,
                           out_vars_t& param_value_references,
                           unsigned int var_idx);
    void addValueReferences();
    void initializeResultOutputVars();

    bool _instantiated;
    string _osu_working_dir;
    string _osu_name;
    omsi_me* _osu_me;
    double* _zeroVal;
    shared_ptr<IHistory> _writeOutput;
    shared_ptr<ISimVars> _simVars;
    //for output routine
    output_int_vars_t _int_vars;
    output_bool_vars_t _bool_vars;
    output_real_vars_t _real_vars;
    output_der_vars_t _der_vars;
    output_res_vars_t _res_vars;
    //model variables and index in memory
    out_vars_t _real_out_vars;
    out_vars_t _real_param_vars;
    out_vars_t _int_out_vars;
    out_vars_t _int_param_vars;
    out_vars_t _bool_out_vars;
    out_vars_t _bool_param_vars;
    out_vars_t _string_out_vars;
    out_vars_t _string_param_vars;
    //fmu value references for model variables
    fmi2_value_reference_t*  _real_vr;
    fmi2_value_reference_t*  _int_vr;
    fmi2_value_reference_t*  _bool_vr;
};
