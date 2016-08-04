#pragma once
/** @defgroup coreSystem Core.System
 *  Core module for all algebraic and ode systems
 *  @{
 */
/*****************************************************************************/
/**

Services, which can be used by systems.
Implementation of standart functions (e.g. giveRHS(...), etc.).
Provision of member variables used by all systems.

Note:
The order of variables in the extended state vector perserved (see: "Sorting
variables by using the index" in "Design proposal for a general solver interface
for Open Modelica", September, 10 th, 2008


\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/

#define MODELICA_TERMINATE(msg) Terminate(msg)

//typedef unordered_map<std::string, boost::any> SValuesMap;

template <class T>
class InitVars
{
public:
  void setStartValue(T& variable,T val,bool overwriteOldValue);
  T& getGetStartValue(T& variable);

private:
  unordered_map<T*, T> _start_values;
};

class BOOST_EXTENSION_SYSTEM_DECL SystemDefaultImplementation
{
public:
  SystemDefaultImplementation(IGlobalSettings* globalSettings, shared_ptr<ISimObjects> sim_objects, string modelName);
  SystemDefaultImplementation(SystemDefaultImplementation &instance);
  virtual ~SystemDefaultImplementation();

  /// Provide number (dimension) of boolean variables
  virtual int getDimBoolean() const;

  /// Provide number (dimension) of states
  virtual int getDimContinuousStates() const;
  virtual int getDimAE() const;
  /// Provide number (dimension) of integer variables
  virtual int getDimInteger() const;

  /// Provide number (dimension) of real variables
  virtual int getDimReal() const;

  /// Provide number (dimension) of string variables
  virtual int getDimString() const;

  /// Provide number (dimension) of clocks
  virtual int getDimClock() const;

  /// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
  virtual int getDimRHS() const;

  /// Provide boolean variables
  virtual void getBoolean(bool* z);

  /// Provide boolean variables
  virtual void getContinuousStates(double* z);

  /// Provide integer variables
  virtual void getInteger(int* z);

  /// Provide real variables
  virtual void getReal(double* z);

  /// Provide string variables
  virtual void getString(std::string* z);

  /// Provide clocks
  virtual void getClock(bool* z);

  /// Provide clock intervals
  virtual double *clockInterval();

  /// Provide clock shifts
  virtual double *clockShift();

  /// Provide the right hand side
  virtual void getRHS(double* f);
  virtual void getResidual(double* f);
  virtual void  setConditions(bool* c);
  virtual void getConditions(bool* c);
  virtual void getClockConditions(bool* c);
  /// Provide boolean variables
  virtual void setBoolean(const bool* z);

  /// Provide boolean variables
  virtual void setContinuousStates(const double* z);

  /// Provide integer variables
  virtual void setInteger(const int* z);

  /// Provide real variables
  virtual void setReal(const double* z);

  /// Provide string variables
  virtual void setString(const std::string* z);

  /// Provide clocks
  virtual void setClock(const bool* z);

  /// Provide the right hand side
  virtual void setStateDerivatives(const double* f);

  /// (Re-) initialize the system of equations
  void initialize();
  /// Set current integration time
  void setTime(const double& t);

  IGlobalSettings* getGlobalSettings();

  shared_ptr<ISimObjects> getSimObjects() const;
  string getModelName() const;

  shared_ptr<ISimData> getSimData();
  shared_ptr<ISimVars> getSimVars();

  virtual double& getRealStartValue(double& var);
  virtual bool& getBoolStartValue(bool& var);
  virtual int& getIntStartValue(int& var);
  virtual string& getStringStartValue(string& var);
  virtual void setRealStartValue(double& var,double val);
  virtual void setRealStartValue(double& var,double val,bool overwriteOldValue);
  virtual void setBoolStartValue(bool& var,bool val);
  virtual void setBoolStartValue(bool& var,bool val,bool overwriteOldValue);
  virtual void setIntStartValue(int& var,int val);
  virtual void setIntStartValue(int& var,int val,bool overwriteOldValue);
  virtual void setStringStartValue(string& var,string val);
  virtual void setStringStartValue(string& var,string val,bool overwriteOldValue);

protected:
    void Assert(bool cond, const string& msg);
    void Terminate(string msg);
    void intDelay(vector<unsigned int> expr,vector<double> delay_max);
    void storeDelay(unsigned int expr_id,double expr_value,double time);
    void storeTime(double time);
    double delay(unsigned int expr_id,double expr_value, double delayTime, double delayMax);
    bool isConsistent();

    shared_ptr<ISimObjects> _simObjects;

    double
        _simTime;             ///< current simulation time (given by the solver)


    bool
        * _conditions,   ///< External conditions changed by the solver
        * _conditions0,
        * _time_conditions;

    int
        _dimContinuousStates,
        _dimRHS,              ///< Dimension der rechten Seite
        _dimReal,             ///< Anzahl der reelwertigen Variablen
        _dimInteger,          ///< Anzahl der integerwertigen Variablen
        _dimBoolean,          ///< Anzahl der boolwertigen Variablen
        _dimString,           ///< Anzahl der stringwertigen Variablen
        _dimZeroFunc,         ///< Dimension (=Anzahl) Nullstellenfunktion
        _dimTimeEvent,        ///< Dimension (=Anzahl) Time event (start zeit und frequenz)
        _dimClock,            ///< Dimension (=Anzahl) Clocks (active)
        _dimAE;               ///< Number (dimension) of algebraic equations (e.g. constraints from an algebraic loop)

    int
    * _time_event_counter;
    double *_clockInterval;   ///< time interval between clock ticks
    double *_clockShift;      ///< time before first activation
    double *_clockTime;       ///< time of clock ticks
    bool *_clockCondition;    ///< clock tick active
    bool *_clockStart;        ///< only active at clock start
    std::ostream *_outputStream;        ///< Output stream for results

    IContinuous::UPDATETYPE _callType;

    bool _initial;
    bool _terminal;
    bool _terminate;

    //SValuesMap _start_values;
    InitVars<double> _real_start_values;
    InitVars<int> _int_start_values;
    InitVars<bool> _bool_start_values;
    InitVars<string> _string_start_values;
   double
        *__z,                 ///< "Extended state vector", containing all states and algebraic variables of all types
        *__zDot,              ///< "Extended vector of derivatives", containing all right hand sides of differential and algebraic equations
	    *__daeResidual;
    typedef std::deque<double> buffer_type;
    typedef std::iterator_traits<buffer_type::iterator>::difference_type difference_type;
    map<unsigned int, buffer_type> _delay_buffer;
    buffer_type _time_buffer;
    double _delay_max;
    double _start_time;
    IGlobalSettings* _global_settings; //this should be a reference, but this is not working if the libraries are linked statically
    IEvent* _event_system; //this pointer to event system
    string _modelName;
};
/** @} */ // end of coreSystem
