#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */
/*
#ifdef RUNTIME_STATIC_LINKING
class DiscreteEvents
#else*/
class BOOST_EXTENSION_EVENTHANDLING_DECL DiscreteEvents
/*#endif*/
{
public:
  DiscreteEvents(shared_ptr<ISimVars> sim_vars);
  virtual ~DiscreteEvents( );
  //Inits the event variables
  void initialize();


  //saves a variable in _pre_vars vector
  void save(double& var,double value);
  void save(int& var,double value);
  void save(bool& var,double value);
  //void savePreVars(double vars [], unsigned int n);


  //Implementation of the Modelica pre  operator
  double& pre(const double& var);
  int& pre(const int& var);
  bool& pre(const bool& var);
  //Implementation of the Modelica edge  operator
  bool edge(double& var);
  bool edge(int& var);
  bool edge(bool& var);
  //Implementation of the Modelica change  operator
  bool change(int& var);
  bool change(bool& var);
  bool change(double& var);


  bool changeDiscreteVar(double& var);
  bool changeDiscreteVar(int& var);
  bool changeDiscreteVar(bool& var);
  //getCondition_type getCondition;

private:
   shared_ptr<ISimVars> _sim_vars;
};

/**
 * Operator class to get pre values of an array
 */
template<typename T>
class PreArray2CArray
{
  DiscreteEvents *_discrete_events;

 public:
  PreArray2CArray(shared_ptr<DiscreteEvents>& discrete_events) {
    _discrete_events = discrete_events.get();
  }

  const T operator()(const T& val) const {
    return _discrete_events->pre(val);
  }
};
/** @} */ // end of coreSystem
