#pragma once

class  PreVariables
{
public:
  PreVariables() : __z(NULL), __zDot(NULL) {};
  virtual ~PreVariables(void) {};
  virtual void savePreVariables() = 0;
  virtual void initPreVariables()= 0;
  //Stores all variables indices
  unordered_map<double* const, unsigned int> _pre_real_vars_idx;
  unordered_map<int* const, unsigned int> _pre_int_vars_idx;
  unordered_map<bool* const, unsigned int> _pre_bool_vars_idx;
  //Stores all variables occurred before an event
  boost::multi_array<double,1> _pre_vars;
protected: 
 double
        *__z,                 ///< "Extended state vector", containing all states and algebraic variables of all types
        *__zDot;              ///< "Extended vector of derivatives", containing all right hand sides of differential and algebraic equations
};
