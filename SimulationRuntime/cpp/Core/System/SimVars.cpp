#include <Core/Modelica.h>
#include <SimCoreFactory/Policies/FactoryConfig.h>
#include "FactoryExport.h"
#include <Core/System/SimVars.h>

SimVars::SimVars(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_pre_vars, size_t dim_state_vars, size_t state_index) :
    _dim_real(dim_real), _dim_int(dim_int), _dim_bool(dim_bool), _dim_pre_vars(dim_pre_vars), _dim_z(dim_state_vars), _z_i(state_index)
/*,_bool_vars(NULL)
 ,_int_vars(NULL)
 ,_real_vars(NULL)
 ,_pre_vars(NULL)*/
{
  if (_dim_real + _dim_int + _dim_bool > _dim_pre_vars)
    throw std::runtime_error("Wrong pre variable size");
  //allocate memory for all model variables
  _bool_vars = boost::shared_ptr<AlignedArray<bool> >(new AlignedArray<bool>(dim_bool));
  _int_vars = boost::shared_ptr<AlignedArray<int> >(new AlignedArray<int>(dim_int));
  _real_vars = boost::shared_ptr<AlignedArray<double> >(new AlignedArray<double>(dim_real));
  if (dim_pre_vars > 0)
    _pre_vars = boost::shared_array<double>(new double[dim_pre_vars]);
  //initialize all model variables
  if (dim_bool > 0)
    std::fill(_bool_vars.get()->get(), _bool_vars.get()->get() + dim_bool, false);
  if (dim_int > 0)
    std::fill(_int_vars.get()->get(), _int_vars.get()->get() + dim_int, 0);
  if (dim_real > 0)
    std::fill(_real_vars.get()->get(), _real_vars.get()->get() + dim_real, 0.0);
}

SimVars::~SimVars()
{
  /*if(_bool_vars.get())
   delete [] _bool_vars.get();
   if(_int_vars.get())
   delete[]  _int_vars.get();
   if(_real_vars.get()->get())
   delete [] _real_vars.get()->get();
   if(_pre_vars)
   delete []_pre_vars;*/
}

double& SimVars::initRealVar(size_t i)
{
  if (i < _dim_real)
    return _real_vars.get()->get()[i];
  else
    throw std::runtime_error("Wrong variable index");
}

int& SimVars::initIntVar(size_t i)
{
  if (i < _dim_int)
    return _int_vars.get()->get()[i];
  else
    throw std::runtime_error("Wrong variable index");
}

bool& SimVars::initBoolVar(unsigned int i)
{
  if (i < _dim_bool)
    return _bool_vars.get()->get()[i];
  else
    throw std::runtime_error("Wrong variable index");
}

double* SimVars::getStateVector()
{
  if (_z_i + _dim_z - 1 < _dim_real)
    return &_real_vars.get()->get()[_z_i];
  else
    throw std::runtime_error("Wrong state vars start index");
}

double* SimVars::getDerStateVector()
{
  if (_z_i + _dim_z - 1 < _dim_real)
    return &_real_vars.get()->get()[_z_i + _dim_z];
  else
    throw std::runtime_error("Wrong state vars start index");
}

const double* SimVars::getRealVarsVector() const
{
  return _real_vars.get()->get();
}

const int* SimVars::getIntVarsVector() const
{
  return _int_vars.get()->get();
}

const bool* SimVars::getBoolVarsVector() const
{
  return _bool_vars.get()->get();
}

void SimVars::setRealVarsVector(const double* vars)
{
  std::copy(vars, vars + _dim_real, _real_vars.get()->get());
}

void SimVars::setIntVarsVector(const int* vars)
{
  std::copy(vars, vars + _dim_int, _int_vars.get()->get());
}

void SimVars::setBoolVarsVector(const bool* vars)
{
  std::copy(vars, vars + _dim_real, _bool_vars.get()->get());
}

double* SimVars::initRealArrayVar(size_t size, size_t start_index)
{
  size_t length = start_index + (size - 1);
  if (length <= _dim_real)
  {
    double* data = &_real_vars.get()->get()[start_index];
    return data;
  }
  else
    throw std::runtime_error("Wrong array size");
}

int* SimVars::initIntArrayVar(size_t size, size_t start_index)
{
  size_t length = start_index + (size - 1);
  if (length <= _dim_int)
  {
    int* data = &_int_vars.get()->get()[start_index];
    return data;
  }
  else
    throw std::runtime_error("Wrong array size");
}

bool* SimVars::initBoolArrayVar(size_t size, size_t start_index)
{
  size_t length = start_index + (size - 1);
  if (length <= _dim_bool)
  {
    bool* data = &_bool_vars.get()->get()[start_index];
    return data;
  }
  else
    throw std::runtime_error("Wrong array size");
}

/*
 Copies all real,int,bool variables to the pre-variables list
 */
void SimVars::savePreVariables()
{
  std::copy(_real_vars.get()->get(), _real_vars.get()->get() + _dim_real, _pre_vars.get());
  std::copy(_int_vars.get()->get(), _int_vars.get()->get() + _dim_int, _pre_vars.get() + _dim_real);
  std::copy(_bool_vars.get()->get(), _bool_vars.get()->get() + _dim_bool, _pre_vars.get() + _dim_real + _dim_int);
}
/*
 Maps a model variable adress to an index in the simvars memory
 */
void SimVars::initPreVariables()
{
  size_t index = 0;
  for (size_t i = 0; i < _dim_real; i++)
  {
    const double& var(_real_vars.get()->get()[i]);
    _pre_real_vars_idx[&var] = index;
    index++;
  }
  for (size_t i = 0; i < _dim_int; i++)
  {
    const int& var(_int_vars.get()->get()[i]);
    _pre_int_vars_idx[&var] = index;
    index++;
  }
  for (size_t i = 0; i < _dim_bool; i++)
  {
    const bool& var(_bool_vars.get()->get()[i]);
    _pre_bool_vars_idx[&var] = index;
    index++;
  }

}

double& SimVars::getPreVar(double& var)
{
  unsigned int i = _pre_real_vars_idx[&var];
  return _pre_vars[i];
}

double& SimVars::getPreVar(int& var)
{
  unsigned int i = _pre_int_vars_idx[&var];
  return _pre_vars[i];
}

double& SimVars::getPreVar(bool& var)
{
  unsigned int i = _pre_bool_vars_idx[&var];
  return _pre_vars[i];
}

void SimVars::setPreVar(double& var)
{
  unsigned int i = _pre_real_vars_idx[&var];
  _pre_vars[i] = var;
}

void SimVars::setPreVar(int& var)
{
  unsigned int i = _pre_int_vars_idx[&var];
  _pre_vars[i] = var;
}

void SimVars::setPreVar(bool& var)
{
  unsigned int i = _pre_bool_vars_idx[&var];
  _pre_vars[i] = var;
}
