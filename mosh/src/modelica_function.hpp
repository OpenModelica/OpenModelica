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
