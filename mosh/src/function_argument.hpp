#ifndef FUNCTION_ARGUMENT_HPP_
#define FUNCTION_ARGUMENT_HPP_

#include "value.hpp"

class function_argument
{
public:
  typedef std::vector<std::pair<value, std::string> >::iterator parameter_iterator;

public:
  function_argument();
  ~function_argument();

  int size() const;
  void push_back(value val,const std::string name = "");

  // Iterator interface
  parameter_iterator begin();
  parameter_iterator end();

  
protected:
  std::vector<std::pair<value,std::string> > m_actual_parameters;

};
#endif
