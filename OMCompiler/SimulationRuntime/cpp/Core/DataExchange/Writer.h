#pragma once
/** @addtogroup dataexchange

*
*  @{
*/

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
