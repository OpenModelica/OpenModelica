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

#include "modelica_function.hpp"

#include "value.hpp"

modelica_function::modelica_function()
{

}

modelica_function::~modelica_function()
{

}

value modelica_function::apply(value args)
{
  // Code for element-wise function application should go here
  
  // Match formal parameters
  if (match_formal_parameters(args))
    {
      return do_apply(args);
    }

  // do type conversion

  // is the type an array of the formal type
  if (args.is_array())
    {
      
      //     cout << "an array " << args.type() <<  endl;
    }
  else
    {
      //cout << "not an array " << args.type() <<  endl;
    }
}

std::string modelica_function::name() const
{
  return m_name;
}

void modelica_function::set_name(std::string name)
{
  m_name = name;
}
