#pragma once
/** @addtogroup dataexchange

*
*  @{
*/

#include <boost/container/vector.hpp>

/** typedef for variable, parameter names*/
typedef boost::container::vector<string> var_names_t;
 /** typedef for the output values kind list, this is a boolean container which indicates if the output variable is a negate alias variable*/
typedef boost::container::vector<bool> negate_values_t;
/**
 *  Class the holds all information to print output variables in a output file (matlab,textfile,buffer, ...)
 *  Holds a container of pointers for all output variable and parameter stored in the simvars array
 */
template<typename T>
struct SimulationOutput
{
	/** typedef for the output values list, this is a container which holds pointer for all output variables stored in the simvar array*/
  typedef boost::container::vector<const T*> values_t;

  /** Container for all output parameter names*/
	var_names_t  parameterNames;
	/** Container for all output parameter description*/
  var_names_t  parameterDescription;
	/** Container for all output variable names*/
  var_names_t  ourputVarNames;
	/** Container for all output variable descriptions*/
  var_names_t  ourputVarDescription;
	/** Container for all output variables*/
  values_t outputVars;
	/** Container for all output parameter*/
  values_t outputParams;
  /** Container for all output variable kinds*/
  negate_values_t negateOutputVars;

  /**
	 *  \brief adds a parameter to output list
	 *
	 *  \param [in] name name of parameter
	 *  \param [in] description description of parameter
	 *  \param [in] var pointer to parameter in simvars array
	 */
	void addParameter(string& name,string& description,const T* var)
	{
		parameterNames.push_back(name);
		parameterDescription.push_back(description);
		outputParams.push_back(var);
	}
	/**
	 *  \brief adds a variable to output list
	 *  \param [in] name name of variable
	 *  \param [in] description description of variable
	 *  \param [in] var pointer to variable in simvars array
	 */
	void addOutputVar(string& name,string& description,const T* var,bool negate)
	{
		ourputVarNames.push_back(name);
		ourputVarDescription.push_back(description);
		outputVars.push_back(var);
        negateOutputVars.push_back(negate);
	}
};
/** typedef for all integer outputs */
typedef SimulationOutput<int> output_int_vars_t;
/** typedef for all boolean outputs */
typedef SimulationOutput<bool> output_bool_vars_t;
/** typedef for all real outputs */
typedef SimulationOutput<double> output_real_vars_t;


/** typedef for the integer output values list*/
typedef  output_int_vars_t::values_t   int_vars_t;
/** typedef for the boolean output values list*/
typedef  output_bool_vars_t::values_t  bool_vars_t;
/** typedef for the real output values list*/
typedef  output_real_vars_t::values_t  real_vars_t;
/**typedef for all output variables   at one time step, all real vars, integer vars, boolean vars, simulation time*/
typedef  tuple<real_vars_t,int_vars_t,bool_vars_t,double> all_vars_time_t;
/**typedef for all output variables  at one time step except simulation time*/
typedef  tuple<real_vars_t,int_vars_t,bool_vars_t> all_vars_t;
/**typedef for all output variables kinds at one time step*/
typedef  tuple<negate_values_t,negate_values_t,negate_values_t> neg_all_vars_t;
/**typedef for all output data at one time step*/
typedef  tuple<all_vars_time_t,neg_all_vars_t> write_data_t;
/**typedef for all variable names*/
typedef  tuple<var_names_t,var_names_t,var_names_t> all_names_t;
/**typedef for all variable description*/
typedef  tuple<var_names_t,var_names_t,var_names_t> all_description_t;

/**
* Operator class to return value of output variable
*/
template<typename T>
struct WriteOutputVar
{
 /**
  return value of output variable
  @param val pointer to output variable
  @param negate if output variable is a negate alias variable
  */
  const double operator()(const T* val, bool negate)
  {
    //if output variable is a negate alias variable, then negate output value
    if(negate)
      return -*val;
    else
      return *val;
  }
};

/**
* specialized bool Operator class to return value of a boolean variable
*/
template < >
struct WriteOutputVar<bool>
{
 /**
  return value of output variable
  @param val pointer to output variable
  @param negate if output variable is a negate alias variable
  */
  const double operator()(const bool* val, bool negate)
  {
    //if output variable is a negate alias variable, then negate output value
    if (negate)
      return !*val;
    else
      return *val;
  }
};

class Writer
{
public:
	Writer() {}

	virtual ~Writer() {}

	virtual void write(const all_vars_time_t& v_list,const neg_all_vars_t& neg_v_list ) = 0;
};
/** @} */ // end of dataexchange
