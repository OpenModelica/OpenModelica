//
// Copyright PELAB, Linkoping University
//

#ifndef SYMBOLTABLE_HPP_
#define SYMBOLTABLE_HPP_

#include "value.hpp"

#include <map>
#include <string>

class symboltable
{
public:
  symboltable();
  virtual ~symboltable();

  void insert(std::string name, value val);
  value* lookup(std::string name);

  value* lookup_function(std::string name);
protected:
  std::map<std::string,value> m_symboltable;
  value* do_lookup(std::string name);
  value* do_file_lookup(std::string name);
 //  std::map<std::string,value> m_builtin_functions;
};
#endif
