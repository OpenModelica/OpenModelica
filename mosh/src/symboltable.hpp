/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/


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
