#include <Core/Modelica.h>
#include "FactoryExport.h"
#include <Core/System/PreVariables.h>
#include <Core/System/DiscreteEvents.h>
#include <Core/Math/Functions.h>


DiscreteEvents::DiscreteEvents(PreVariables* preVars)
: _preVars(preVars)
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

  _preVars->initPreVariables();
  _preVars->_pre_vars.resize((boost::extents[_preVars->_pre_real_vars_idx.size()+_preVars->_pre_int_vars_idx.size()+_preVars->_pre_bool_vars_idx.size()]));
}

/*
void DiscreteEvents::savePreVars(double vars[], unsigned int n)
{
  _preVars->_pre_vars.assign(vars,vars+n);
}
*/

/**
Saves a variable in _preVars->_pre_vars vector
*/

void DiscreteEvents::save(double& var)
{
  unsigned int i = _preVars->_pre_real_vars_idx[&var];
  _preVars->_pre_vars[i]=var;
}

/**
Saves a variable in _preVars->_pre_vars vector
*/

void DiscreteEvents::save(int& var)
{
  unsigned int i = _preVars->_pre_int_vars_idx[&var];
  _preVars->_pre_vars[i]=var;
}

/**
Saves a variable in _preVars->_pre_vars vector
*/

void DiscreteEvents::save(bool& var)
{
  unsigned int i = _preVars->_pre_bool_vars_idx[&var];
  _preVars->_pre_vars[i]=var;
}

/**
Implementation of the Modelica pre  operator
*/
double DiscreteEvents::pre(double& var)
{
  unsigned int i = _preVars->_pre_real_vars_idx[&var];
  return _preVars->_pre_vars[i];

}

/**
Implementation of the Modelica pre  operator
*/
double DiscreteEvents::pre(int& var)
{
  unsigned int i = _preVars->_pre_int_vars_idx[&var];
  return _preVars->_pre_vars[i];

}

/**
Implementation of the Modelica pre  operator
*/
double DiscreteEvents::pre(bool& var)
{
  unsigned int i = _preVars->_pre_bool_vars_idx[&var];
  return _preVars->_pre_vars[i];

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
  unsigned int i = _preVars->_pre_real_vars_idx[&var];
  return var != _preVars->_pre_vars[i];

}
bool DiscreteEvents::changeDiscreteVar(int& var)
{
  unsigned int i = _preVars->_pre_int_vars_idx[&var];
  return var != _preVars->_pre_vars[i];

}

bool DiscreteEvents::changeDiscreteVar(bool& var)
{
  unsigned int i = _preVars->_pre_bool_vars_idx[&var];
  return var != _preVars->_pre_vars[i];

}



