//
// Copyright PELAB, Linkoping University
//

#ifndef MODELICA_FUNCTION_HPP_
#define MODELICA_FUNCTION_HPP_

#include "value.hpp"
#include <string>

class modelica_function
{
public:
  virtual ~modelica_function();
  value apply(value args);
  std::string name() const;
  void set_name(std::string name);

protected:
  modelica_function();
  virtual value do_apply(value args) = 0;
  virtual bool match_formal_parameters(value args) = 0;

  std::string m_name;
};

#endif
