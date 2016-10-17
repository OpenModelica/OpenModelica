/** @addtogroup coreSystem
*
*  @{
*/
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
* @param dim_string  number of all string variables (string algebraic vars)
* @param dim_pre_vars number of all pre variables (real algebraic vars,discrete algebraic vars, boolean algebraic vars, integer algebraic vars, state vars, der state vars)
* @param dim_state_vars number of all state variables
* @param state_index start index of state vector in real_vars list
*/
SimVars::SimVars(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars, size_t dim_state_vars, size_t state_index)
{
	create(dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_state_vars, state_index);
}

SimVars::SimVars(SimVars& instance)
{
	create(instance.getDimReal(), instance.getDimInt(), instance.getDimBool(), instance.getDimString(), instance.getDimPreVars(), instance.getDimStateVars(), instance.getStateVectorIndex());
	setRealVarsVector(instance.getRealVarsVector());
	setIntVarsVector(instance.getIntVarsVector());
	setBoolVarsVector(instance.getBoolVarsVector());
	setStringVarsVector(instance.getStringVarsVector());
}

void SimVars::create(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars, size_t dim_state_vars, size_t state_index)
{
	_dim_real = dim_real;
	_dim_int = dim_int;
	_dim_bool = dim_bool;
	_dim_string = dim_string;
	_dim_pre_vars = dim_pre_vars;
	_dim_z = dim_state_vars;
	_z_i = state_index;

	if (_dim_real + _dim_int + _dim_bool > _dim_pre_vars)
		throw std::runtime_error("Wrong pre variable size");
	//allocate memory for all model variables
	if (dim_string > 0) {
		_string_vars = new string[dim_string];
	}
	else {
		_string_vars = NULL;
	}
	if (dim_bool > 0) {
		_bool_vars = (bool*)alignedMalloc(sizeof(bool) * dim_bool, 64);
		_pre_bool_vars = (bool*)alignedMalloc(sizeof(bool) * dim_bool, 64);
	}
	else {
		_bool_vars = NULL;
		_pre_bool_vars = NULL;
	}
	if (dim_int > 0) {
		_int_vars = (int*)alignedMalloc(sizeof(int) * dim_int, 64);
		_pre_int_vars = (int*)alignedMalloc(sizeof(int) * dim_int, 64);
	}
	else {
		_int_vars = NULL;
		_pre_int_vars = NULL;
	}
	if (dim_real > 0) {
		_real_vars = (double*)alignedMalloc(sizeof(double) * dim_real, 64);
		_pre_real_vars = (double*)alignedMalloc(sizeof(double) * dim_real, 64);
	}
	else {
		_real_vars = NULL;
		_pre_real_vars = NULL;
	}

	//initialize all model variables
	if(dim_string > 0)
		std::fill(_string_vars, _string_vars + dim_string, string());
	if (dim_bool > 0)
		std::fill(_bool_vars, _bool_vars + dim_bool, false);
	if (dim_int > 0)
		std::fill(_int_vars, _int_vars + dim_int, 0);
	if (dim_real > 0)
		std::fill(_real_vars, _real_vars + dim_real, 0.0);
}

SimVars::~SimVars()
{
	if(_pre_real_vars)
		alignedFree(_pre_real_vars);
	if(_real_vars)
		alignedFree(_real_vars);
	if(_pre_int_vars)
		alignedFree(_pre_int_vars);
	if(_int_vars)
		alignedFree(_int_vars);
	if(_pre_bool_vars)
		alignedFree(_pre_bool_vars);
	if(_bool_vars)
		alignedFree(_bool_vars);
	if(_string_vars)
		delete [] _string_vars;
}

ISimVars* SimVars::clone()
{
	return new SimVars(*this);
}

//see: http://stackoverflow.com/questions/12504776/aligned-malloc-in-c
void* SimVars::alignedMalloc(size_t required_bytes, size_t alignment)
{
	void *p1;
	void **p2;

	int offset = alignment - 1 + sizeof(void*);
	p1 = malloc(required_bytes + offset);
	p2=(void**)(((size_t)(p1)+offset)&~(alignment-1));
	p2[-1]=p1;
	return p2;
}

void SimVars::alignedFree(void* p)
{
	void* p1 = ((void**)p)[-1];         // get the pointer to the buffer we allocated
	free( p1 );
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
*  \brief read scalar real model variables from simvars memory
*  \param [in] i index in simvars memory
*  \return simvar variable
*/
const double& SimVars::getRealVar(size_t i)
{
	if (i < _dim_real)
		return _real_vars[i];
	else
		throw std::runtime_error("Wrong variable index");
}
/**
*  \brief read scalar integer model variables from simvars memory
*  \param [in] i index in simvars memory
*  \return simvar variable
*/
const int& SimVars::getIntVar(size_t i)
{
	if (i < _dim_int)
		return _int_vars[i];
	else
		throw std::runtime_error("Wrong variable index");
}
/**
*  \brief Read scalar boolean model variables from simvars memory
*  \param [in] i index in simvars memory
*  \return simvar variable
*/
const bool& SimVars::getBoolVar(size_t i)
{
	if (i < _dim_bool)
		return _bool_vars[i];
	else
		throw std::runtime_error("Wrong variable index");
}

string& SimVars::initStringVar(size_t i)
{
	if (i < _dim_string)
		return _string_vars[i];
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

string* SimVars::getStringVarsVector() const
{
	if(!_string_vars)
		return NULL;
	return _string_vars;
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
	std::copy(vars, vars + _dim_bool, _bool_vars);
}

void SimVars::setStringVarsVector(const string* vars)
{
	std::copy(vars, vars + _dim_string, _string_vars);
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

string* SimVars::initStringArrayVar(size_t size, size_t start_index)
{
	size_t length = start_index + (size - 1);
	if (length <= _dim_string)
	{
		string* data = &_string_vars[start_index];
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
	std::transform(indices,indices+n,ref_data,boost::lambda::bind(&SimVars::getRealVarPtr,this,boost::lambda::_1));
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
	std::transform(indices,indices+n,ref_data,boost::lambda::bind(&SimVars::getIntVarPtr,this,boost::lambda::_1));
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
	std::transform(indices,indices+n,ref_data,boost::lambda::bind(&SimVars::getBoolVarPtr,this,boost::lambda::_1));
}

void SimVars::initBoolAliasArray(std::vector<int> indices, bool* ref_data[])
{
	initBoolAliasArray(&indices[0], indices.size(), ref_data);
}

void SimVars::initStringAliasArray(int indices[], size_t n, string* ref_data[])
{
	std::transform(indices,indices+n,ref_data,boost::lambda::bind(&SimVars::getStringVarPtr,this,boost::lambda::_1));
}

void SimVars::initStringAliasArray(std::vector<int> indices, string* ref_data[])
{
	initStringAliasArray(&indices[0], indices.size(), ref_data);
}

/**
*  \brief Copies all real,int,bool variables to the pre-variables list
*  \details Details
*/
void SimVars::savePreVariables()
{
	if(_dim_real>0)
		std::copy(_real_vars, _real_vars + _dim_real, _pre_real_vars);
	if(_dim_int>0)
		std::copy(_int_vars, _int_vars + _dim_int, _pre_int_vars);
	if (_dim_bool > 0)
		std::copy(_bool_vars, _bool_vars + _dim_bool, _pre_bool_vars);
}
/**
*  \brief Initializes access to pre variables
*  \details Details
*/
void SimVars::initPreVariables()
{
	// nothing needs to be done, exploiting contiguous vars storage
}

double& SimVars::getPreVar(const double& var)
{
	size_t i = &var - _real_vars;
	return _pre_real_vars[i];
}

int& SimVars::getPreVar(const int& var)
{
	size_t i = &var - _int_vars;
	return _pre_int_vars[i];
}

bool& SimVars::getPreVar(const bool& var)
{
	size_t i = &var - _bool_vars;
	return _pre_bool_vars[i];
}

/**\brief returns a pointer to a real simvar variable in simvar array
*  \param [in] i index  of simvar in simvar array
*  \return pointer to simvar
*  \details Details
*/
double* SimVars::getRealVarPtr(size_t i)
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
int* SimVars::getIntVarPtr(size_t i)
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
bool* SimVars::getBoolVarPtr(size_t i)
{
	if(i<_dim_bool)
		return &_bool_vars[i];
	else
		throw std::runtime_error("Wrong variable index");
}

string* SimVars::getStringVarPtr(size_t i)
{
	if(i<_dim_string)
		return &_string_vars[i];
	else
		throw std::runtime_error("Wrong variable index");
}

size_t SimVars::getDimString() const
{
	return _dim_string;
}

size_t SimVars::getDimBool() const
{
	return _dim_bool;
}

size_t SimVars::getDimInt() const
{
	return _dim_int;
}

size_t SimVars::getDimPreVars() const
{
	return _dim_pre_vars;
}

size_t SimVars::getDimReal() const
{
	return _dim_real;
}

size_t SimVars::getDimStateVars() const
{
	return _dim_z;
}

size_t SimVars::getStateVectorIndex() const
{
	return _z_i;
}
/** @} */ // end of coreSystem
