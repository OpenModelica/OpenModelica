#pragma once
/** @addtogroup coreSystem
 *  
 *  @{
 */
class  PreVariables
{
public:
  PreVariables(int numOfPreVars) : _pre_real_vars_idx(), _pre_int_vars_idx(), _pre_bool_vars_idx(), __z(NULL), __zDot(NULL)
  {
      _pre_vars = new double[numOfPreVars];
  }
  PreVariables() : _pre_real_vars_idx(), _pre_int_vars_idx(), _pre_bool_vars_idx(), __z(NULL), __zDot(NULL)
  {
      _pre_vars = new double[0];
  }
  virtual ~PreVariables(void) {};
  virtual void savePreVariables() = 0;
  virtual void initPreVariables()= 0;
  //Stores all variables indices
  unordered_map<double* const, unsigned int> _pre_real_vars_idx;
  unordered_map<int* const, unsigned int> _pre_int_vars_idx;
  unordered_map<bool* const, unsigned int> _pre_bool_vars_idx;
  //Stores all variables occurred before an event
  double* _pre_vars;
protected:
 double
        *__z,                 ///< "Extended state vector", containing all states and algebraic variables of all types
        *__zDot;              ///< "Extended vector of derivatives", containing all right hand sides of differential and algebraic equations
};
/** @} */ // end of coreSystem