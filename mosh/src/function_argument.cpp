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


#include "function_argument.hpp"

function_argument::function_argument()
{

}

function_argument::~function_argument()
{

}

int function_argument::size() const
{
  return m_actual_parameters.size();
}

void function_argument::push_back(value val, const std::string name = "")
{
  m_actual_parameters.push_back(std::make_pair(val,name));
}

function_argument::parameter_iterator function_argument::begin()
{
  return m_actual_parameters.begin();
}

function_argument::parameter_iterator function_argument::end()
{
  return m_actual_parameters.end();
}


