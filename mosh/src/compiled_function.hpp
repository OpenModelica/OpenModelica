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
