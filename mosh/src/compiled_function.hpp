//
// Copyright PELAB, Linkoping University
//

#ifndef COMPILED_FUNCTION_HPP_
#define COMPILED_FUNCTION_HPP_

#include "modelica_function.hpp"
#include "value.hpp"

#include <string>

class compiled_function : public modelica_function
{
public:
  compiled_function();
  compiled_function(std::string filename);
  virtual ~compiled_function();

  virtual value do_apply(value args);
  bool match_formal_parameters(value val);

protected:
  std::string m_filename;

};
#endif
