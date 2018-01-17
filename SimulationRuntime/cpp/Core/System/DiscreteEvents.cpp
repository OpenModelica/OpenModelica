/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/FactoryExport.h>
#include <Core/System/DiscreteEvents.h>
#include <Core/Math/Functions.h>


DiscreteEvents::DiscreteEvents(shared_ptr<ISimVars> sim_vars)
: _sim_vars(sim_vars)
{
}

DiscreteEvents::~DiscreteEvents(void)
{


}

/**
Inits the event variables
*/
void DiscreteEvents::initialize()
{

  _sim_vars->initPreVariables();
  //_preVars->_pre_vars.resize((boost::extents[_preVars->_pre_real_vars_idx.size()+_preVars->_pre_int_vars_idx.size()+_preVars->_pre_bool_vars_idx.size()]));
}

/*
void DiscreteEvents::savePreVars(double vars[], unsigned int n)
{
  _preVars->_pre_vars.assign(vars,vars+n);
}
*/

/**
Saves a variable in _sim_vars->_pre_real_vars vector
*/
void DiscreteEvents::save(double& var,double value)
{
  _sim_vars->getPreVar(var) = value;
}

/**
Saves a variable in _sim_vars->_pre_int_vars vector
*/
void DiscreteEvents::save(int& var,double value)
{
  _sim_vars->getPreVar(var) = value;
}

/**
Saves a variable in _sim_vars->_pre_bool_vars vector
*/
void DiscreteEvents::save(bool& var,double value)
{
  _sim_vars->getPreVar(var) = value;
}

/**
Implementation of the Modelica pre  operator
*/
double& DiscreteEvents::pre(const double& var)
{
  return _sim_vars->getPreVar(var);
}

/**
Implementation of the Modelica pre  operator
*/
int& DiscreteEvents::pre(const int& var)
{
  return _sim_vars->getPreVar(var);
}

/**
Implementation of the Modelica pre  operator
*/
bool& DiscreteEvents::pre(const bool& var)
{
  return _sim_vars->getPreVar(var);
}

/**
Implementation of the Modelica edge  operator
Returns true for a variable when it  changes from false to true
*/
bool DiscreteEvents::edge(double& var)
{
  return var && !pre(var);
}

/**
Implementation of the Modelica edge  operator
Returns true for a variable when it  changes from false to true
*/
bool DiscreteEvents::edge(int& var)
{
  return var && !pre(var);
}

/**
Implementation of the Modelica edge  operator
Returns true for a variable when it  changes from false to true
*/
bool DiscreteEvents::edge(bool& var)
{
  return var && !pre(var);
}

/**
Implementation of the Modelica change  operator
Returns true for a variable when it change value
*/
bool DiscreteEvents::change(double& var)
{
  return var != pre(var);
}

/**
Implementation of the Modelica change  operator
Returns true for a variable when it change value
*/
bool DiscreteEvents::change(int& var)
{
  return var != pre(var);
}

/**
Implementation of the Modelica change  operator
Returns true for a variable when it change value
*/
bool DiscreteEvents::change(bool& var)
{
  return var != pre(var);
}

bool DiscreteEvents::changeDiscreteVar(double& var)
{
  double& pre_var = _sim_vars->getPreVar(var);
  return var != pre_var;
}

bool DiscreteEvents::changeDiscreteVar(int& var)
{
  int& pre_var = _sim_vars->getPreVar(var);
  return var != pre_var;
}

bool DiscreteEvents::changeDiscreteVar(bool& var)
{
  bool& pre_var = _sim_vars->getPreVar(var);
  return var != pre_var;
}

/** @} */ // end of coreSystem

