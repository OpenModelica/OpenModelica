#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>

#include <Core/System/FactoryExport.h>
#include <Core/System/SimVars.h>
#include <boost/lambda/bind.hpp>
#include <boost/lambda/lambda.hpp>


/**
* Constructor for SimVars, stores all model variable in continuous block of memory
* @param dim_real  number of all real variables (real algebraic vars,discrete algebraic vars, state vars, der state vars)
* @param dim_int   number of all integer variables integer algebraic vars
* @param dim_bool  number of all bool variables (boolean algebraic vars)
* @param dim_pre_vars number of all pre variables (real algebraic vars,discrete algebraic vars, boolean algebraic vars, integer algebraic vars, state vars, der state vars)
* @param dim_state_vars number of all state variables
* @param state_index start index of state vector in real_vars list
*/
SimVars::SimVars(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_pre_vars, size_t dim_state_vars, size_t state_index):
    _dim_real(dim_real), _dim_int(dim_int), _dim_bool(dim_bool), _dim_pre_vars(dim_pre_vars), _dim_z(dim_state_vars), _z_i(state_index)
    ,_pre_vars(NULL)
{
  if (_dim_real + _dim_int + _dim_bool > _dim_pre_vars)
    throw std::runtime_error("Wrong pre variable size");
  //allocate memory for all model variables
  if(dim_bool>0)
    _bool_vars = (bool*)alignedMalloc(sizeof(bool) * dim_bool, 64);
  if(dim_int>0)
    _int_vars = (int*)alignedMalloc(sizeof(int) * dim_int, 64);
  if(dim_real>0)
    _real_vars = (double*)alignedMalloc(sizeof(double) * dim_real, 64);
  if (dim_pre_vars > 0)
    _pre_vars =  new double[dim_pre_vars];
  //initialize all model variables
  if (dim_bool > 0)
    std::fill(_bool_vars, _bool_vars + dim_bool, false);
  if (dim_int > 0)
    std::fill(_int_vars, _int_vars + dim_int, 0);
  if (dim_real > 0)
    std::fill(_real_vars, _real_vars + dim_real, 0.0);
}

SimVars::~SimVars()
{
  if(_pre_vars)
    delete [] _pre_vars;
  if(_real_vars)
    alignedFree(_real_vars);
  if(_int_vars)
    alignedFree(_int_vars);
  if(_bool_vars)
    alignedFree(_bool_vars);
}
/**
*  \brief Initialize scalar real model variables in simvars memory
*  \param [in] i index in simvars memory
*  \return simvar variable
*/
double& SimVars::initRealVar(size_t i)
{
  if (i < _dim_real)
    return _real_vars[i];
  else
    throw std::runtime_error("Wrong variable index");
}
/**
*  \brief Initialize scalar integer model variables in simvars memory
*  \param [in] i index in simvars memory
*  \return simvar variable
*/
int& SimVars::initIntVar(size_t i)
{
  if (i < _dim_int)
    return _int_vars[i];
  else
    throw std::runtime_error("Wrong variable index");
}
/**
*  \brief Initialize scalar boolean model variables in simvars memory
*  \param [in] i index in simvars memory
*  \return simvar variable
*/
bool& SimVars::initBoolVar(size_t i)
{
  if (i < _dim_bool)
    return _bool_vars[i];
  else
    throw std::runtime_error("Wrong variable index");
}
/**
*  \brief  returns state vector of size dim_z
*  \return Return_Description
*  \details pointer to the  state variable vector
*/
double* SimVars::getStateVector()
{
  if (_z_i + _dim_z <= _dim_real)
    return _dim_real > 0 ? &_real_vars[_z_i] : NULL;
  else
    throw std::runtime_error("Wrong state vars start index");
}
/**
*  \brief  returns der state vector of size dim_z
*  \return pointer to the  der state variable vector
*  \details Details
*/
double* SimVars::getDerStateVector()
{
  if (_z_i + 2*_dim_z <= _dim_real)
    return _dim_real > 0 ? &_real_vars[_z_i + _dim_z] : NULL;
  else
    throw std::runtime_error("Wrong der state vars start index");
}
/**
*  \brief  returns real vars vector of size dim_real
*  \return pointer to the real variable vector
*  \details Details
*/
double* SimVars::getRealVarsVector() const
{
  if(!_real_vars)
    return NULL;
  return _real_vars;
}
/**
*  \brief returns int vars vector of size dim_int
*  \return pointer to the integer variable vector
*  \details Details
*/
int* SimVars::getIntVarsVector() const
{
  if(!_int_vars)
    return NULL;
  return _int_vars;
}
/**
*  \brief  returns bool vars vector of size dim_bool
*  \return pointer to the bool variable vector
*  \details Details
*/
bool* SimVars::getBoolVarsVector() const
{
  if(!_bool_vars)
    return NULL;
  return _bool_vars;
}
/**
*  \brief set real vars vector of size dim_real
*  \param [in] vars new real vars
*  \details Details
*/
void SimVars::setRealVarsVector(const double* vars)
{
  std::copy(vars, vars + _dim_real, _real_vars);
}
/**
*  \brief  set int vars vector of size dim_int
*  \param [in] vars new int vars
*  \details Details
*/
void SimVars::setIntVarsVector(const int* vars)
{
  std::copy(vars, vars + _dim_int, _int_vars);
}
/**
*  \brief  set bool vars vector of size dim_bool
*  \param [in] vars new boolean vars
*  \details Details
*/
void SimVars::setBoolVarsVector(const bool* vars)
{
  std::copy(vars, vars + _dim_real, _bool_vars);
}
/**\brief initialize real model array variable in simvars memory
*  \param [in] size size of real array
*  \param [in] start_index index in simvars array
*  \return pointer to real array in simvars array
*  \details Details
*/
double* SimVars::initRealArrayVar(size_t size, size_t start_index)
{
  size_t length = start_index + (size - 1);
  if (length <= _dim_real)
  {
    double* data = &_real_vars[start_index];
    return data;
  }
  else
    throw std::runtime_error("Wrong array size");
}
/**\brief initialize int model array variable in simvars memory
*  \param [in] size size of real array
*  \param [in] start_index index in simvars array
*  \return pointer to real array in simvars array
*  \details Details
*/
int* SimVars::initIntArrayVar(size_t size, size_t start_index)
{
  size_t length = start_index + (size - 1);
  if (length <= _dim_int)
  {
    int* data = &_int_vars[start_index];
    return data;
  }
  else
    throw std::runtime_error("Wrong array size");
}

/**\brief initialize bool model array variable in simvars memory
*  \param [in] size size of real array
*  \param [in] start_index index in simvars array
*  \return pointer to real array in simvars array
*  \details Details
*/
bool* SimVars::initBoolArrayVar(size_t size, size_t start_index)
{
  size_t length = start_index + (size - 1);
  if (length <= _dim_bool)
  {
    bool* data = &_bool_vars[start_index];
    return data;
  }
  else
    throw std::runtime_error("Wrong array size");
}
/**\brief initializes real model alias array variable in simvars memory
 *  \param [in] indices indices of orginal variables in simvars memory
 *  \param [in] n size of alias array
 *  \param [out] ref_data pointer array to original array elements in simvars memory
  *  \details Details
 */
void SimVars::initRealAliasArray(int indices[], size_t n, double* ref_data[])
{
  for(int i = 0; i < n; i++)
  {
    int index = indices[i];
    double* refToVar =  SimVars::getRealVar(index);
    ref_data[i] = refToVar;
  }
}

void SimVars::initRealAliasArray(std::vector<int> indices, double* ref_data[])
{
  initRealAliasArray(&indices[0], indices.size(), ref_data);
}

/**\brief initializes int model alias array variable in simvars memory
 *  \param [in] indices indices of original variables in simvars memory
 *  \param [in] n size of alias array
 *  \param [out] ref_data pointer array to original array elements in simvars memory
  *  \details Details
 */
void SimVars::initIntAliasArray(int indices[], size_t n, int* ref_data[])
{
  std::transform(indices,indices+n,ref_data,boost::lambda::bind(&SimVars::getIntVar,this,boost::lambda::_1));
}

void SimVars::initIntAliasArray(std::vector<int> indices, int* ref_data[])
{
  initIntAliasArray(&indices[0], indices.size(), ref_data);
}

/**\brief initializes bool model alias array variable in simvars memory
 *  \param [in] indices indices of original variables in simvars memory
 *  \param [in] n size of alias array
 *  \param [out] ref_data pointer array to original array elements in simvars memory
  *  \details Details
 */
void SimVars::initBoolAliasArray(int indices[], size_t n, bool* ref_data[])
{
  std::transform(indices,indices+n,ref_data,boost::lambda::bind(&SimVars::getBoolVar,this,boost::lambda::_1));
}

void SimVars::initBoolAliasArray(std::vector<int> indices, bool* ref_data[])
{
  initBoolAliasArray(&indices[0], indices.size(), ref_data);
}

/**
*  \brief Copies all real,int,bool variables to the pre-variables list
*  \details Details
*/
void SimVars::savePreVariables()
{
  if(_dim_real>0)
    std::copy(_real_vars, _real_vars + _dim_real, _pre_vars);
  if(_dim_int>0)
    std::copy(_int_vars, _int_vars + _dim_int, _pre_vars + _dim_real);
  if (_dim_bool > 0)
    std::copy(_bool_vars, _bool_vars + _dim_bool, _pre_vars + _dim_real + _dim_int);
}
/**
*  \brief Maps a model variable address to an index in the simvars memory
*  \details Details
*/
void SimVars::initPreVariables()
{
  size_t index = 0;
  for (size_t i = 0; i < _dim_real; i++)
  {
    const double& var(_real_vars[i]);
    _pre_real_vars_idx[&var] = index;
    index++;
  }
  for (size_t i = 0; i < _dim_int; i++)
  {
    const int& var(_int_vars[i]);
    _pre_int_vars_idx[&var] = index;
    index++;
  }
  for (size_t i = 0; i < _dim_bool; i++)
  {
    const bool& var(_bool_vars[i]);
    _pre_bool_vars_idx[&var] = index;
    index++;
  }

}

double& SimVars::getPreVar(const double& var)
{
  unsigned int i = _pre_real_vars_idx[&var];
  return _pre_vars[i];
}

double& SimVars::getPreVar(const int& var)
{
  unsigned int i = _pre_int_vars_idx[&var];
  return _pre_vars[i];
}

double& SimVars::getPreVar(const bool& var)
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

/**\brief returns a pointer to a real simvar variable in simvar array
 *  \param [in] i index  of simvar in simvar array
 *  \return pointer to simvar
 *  \details Details
 */
double* SimVars::getRealVar(size_t i)
{
   if(i<_dim_real)
    return &_real_vars[i];
  else
    throw std::runtime_error("Wrong variable index");
}
/**\brief returns a pointer to a int simvar variable in simvar array
 *  \param [in] i index  of simvar in simvar array
 *  \return pointer to simvar
 *  \details Details
 */
int* SimVars::getIntVar(size_t i)
{
  if(i<_dim_int)
    return &_int_vars[i];
  else
    throw std::runtime_error("Wrong variable index");
}
/**\brief returns a pointer to a bool simvar variable in simvar array
 *  \param [in] i index  of simvar in simvar array
 *  \return pointer to simvar
 *  \details Details
 */
bool* SimVars::getBoolVar(size_t i)
{
  if(i<_dim_bool)
    return &_bool_vars[i];
  else
    throw std::runtime_error("Wrong variable index");
}
