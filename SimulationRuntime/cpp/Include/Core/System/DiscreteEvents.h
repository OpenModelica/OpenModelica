#pragma once


#ifdef RUNTIME_STATIC_LINKING
class DiscreteEvents
#else
class BOOST_EXTENSION_EVENTHANDLING_DECL DiscreteEvents
#endif
{
public:
  DiscreteEvents(boost::shared_ptr<ISimVars> sim_vars);
  virtual ~DiscreteEvents( );
  //Inits the event variables
  void initialize();


  //saves a variable in _pre_vars vector
  void save(double& var);
  void save(int& var);
  void save(bool& var);
  //void savePreVars(double vars [], unsigned int n);


  //Implementation of the Modelica pre  operator
  double pre(double& var);
  double pre(int& var);
  double pre(bool& var);
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
  getCondition_type getCondition;

private:
   boost::shared_ptr<ISimVars> _sim_vars;
};
