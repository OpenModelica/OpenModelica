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
