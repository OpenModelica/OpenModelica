/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "modelica_type.hpp"

#include <vector>

modelica_type::modelica_type() :
  m_type(undefined)
{

}

modelica_type::~modelica_type()
{

}

bool modelica_type::is_scalar() const
{
  if (is_real() ||
      is_integer() ||
      is_string() ||
      is_boolean())
    {
      return true;
    }
  else
    {
      return false;
    }
}

bool modelica_type::is_array() const
{
  if (is_real_array() ||
      is_integer_array()||
      is_string_array() ||
      is_boolean_array())
    {
      return true;
    }
  else
    {
      return false;
    }
}

bool modelica_type::is_numeric() const
{
  if (is_real() ||
      is_integer() ||
      is_real_array() ||
      is_integer_array())
    {
      return true;
    }
  else
    {
      return false;
    }
}

bool modelica_type::is_non_numeric() const
{
  if(is_boolean() ||
     is_string() ||
     is_boolean_array() ||
     is_string_array()
     )
    {
      return true;
    }
  else
    {
      return false;
    }
}

bool modelica_type::is_real() const
{
  return (m_type == real_t);
}

bool modelica_type::is_integer() const
{
  return (m_type == integer_t);
}

bool modelica_type::is_string() const
{
  return (m_type == string_t);
}

bool modelica_type::is_boolean() const
{
  return (m_type == boolean_t);
}

bool modelica_type::is_real_array() const
{
  return (m_type == real_array_t);
}

bool modelica_type::is_integer_array() const
{
  return (m_type == integer_array_t);
}

bool modelica_type::is_string_array() const
{
  return (m_type == string_array_t);
}

bool modelica_type::is_boolean_array() const
{
  return (m_type == boolean_array_t);
}

bool modelica_type::is_tuple() const
{
  return (m_type == tuple_t);
}

bool modelica_type::is_function() const
{
  return (m_type == function_t);
}

bool modelica_type::is_function_argument() const
{
  return (m_type == function_argument_t);
}

void modelica_type::set_real()
{
  m_type = real_t;
}

void modelica_type::set_integer()
{
  m_type = integer_t;
}

void modelica_type::set_string()
{
  m_type = string_t;
}

void modelica_type::set_boolean()
{
  m_type = boolean_t;
}

void modelica_type::set_real_array()
{
  m_type = real_array_t;
}

void modelica_type::set_integer_array()
{
  m_type = integer_array_t;
}

void modelica_type::set_boolean_array()
{
  m_type = boolean_array_t;
}

void modelica_type::set_string_array()
{
  m_type = string_array_t;;
}

void modelica_type::set_tuple()
{
  m_type = tuple_t;
}

void modelica_type::set_function()
{
  m_type = function_t;
}

void modelica_type::set_function_argument()
{
  m_type = function_argument_t;
}

std::vector<int> modelica_type::dimensions() const
{
  return m_dimensions;
}

bool modelica_type::type_equal(modelica_type t)
{
  if (m_type == t.m_type)
    {
      if (is_array())
	{
// 	  for (size_t i = 0; i < m_dimensions.size(); ++i)
// 	    {
// 	      cout << m_dimensions[i] << endl;
// 	    }
// 	  cout << "dimensions t " << t.m_dimensions.size() << endl;
	  return (m_dimensions == t.m_dimensions);
	}
      else
	{
	  return true;
	}
    }
  else
    {
      return false;
    }
}

modelica_type create_real()
{
  modelica_type result;
  result.set_real();

  return result;
}

modelica_type create_integer()
{
  modelica_type result;
  result.set_integer();

  return result;
}

modelica_type create_string()
{
  modelica_type result;
  result.set_string();

  return result;
}

modelica_type create_boolean()
{
  modelica_type result;
  result.set_boolean();

  return result;
}

modelica_type create_real_array(std::vector<int> s)
{
  modelica_type result;
  result.set_real_array();
  result.m_dimensions = s;

  return result;
}

modelica_type create_integer_array(std::vector<int> s)
{
  modelica_type result;
  result.set_integer_array();
  result.m_dimensions = s;

  return result;
}

modelica_type create_string_array(std::vector<int> s)
{
  modelica_type result;
  result.set_string_array();
  result.m_dimensions = s;

  return result;
}

modelica_type create_boolean_array(std::vector<int> s)
{
  modelica_type result;
  result.set_boolean_array();
  result.m_dimensions = s;

  return result;
}

modelica_type create_tuple()
{
  modelica_type result;
  result.set_tuple();

  return result;
}

modelica_type create_function_type()
{
  modelica_type result;
  result.set_function();

  return result;
}

modelica_type create_function_argument_type()
{
  modelica_type result;
  result.set_function_argument();

  return result;
}

ostream& operator<< (ostream& o, const modelica_type& v)
{
  if (v.is_real())
    {
      o << "real type";
    }
  else if (v.is_integer())
    {
      o << "integer";
    }
  else if (v.is_string())
    {
      o << "string";
    }
  else if (v.is_boolean())
    {
      o << "booelan";
    }
  else if (v.is_real_array())
    {
      o << "real_array with dimensions ";;
      for (size_t i = 0; i < v.m_dimensions.size();++i)
	{
	  o << "dimensions[" << i << "] : " << v.m_dimensions[i];
	}
    }
  else if (v.is_integer_array())
    {
      o << "integer_array with dimensions ";
      for (size_t i = 0; i < v.m_dimensions.size();++i)
	{
	  o << "dimensions[" << i << "] : " << v.m_dimensions[i];
	}
    }
  else if (v.is_boolean_array())
    {
      o << "boolean_array with dimensions ";
      for (size_t i = 0; i < v.m_dimensions.size();++i)
	{
	  o << "dimensions[" << i << "] : " << v.m_dimensions[i];
	}
    }
  else if (v.is_string_array())
    {
      o << "string_array with dimensions ";
      for (size_t i = 0; i < v.m_dimensions.size();++i)
	{
	  o << "dimensions[" << i << "] : " << v.m_dimensions[i];
	}
    }
  else
    {
      o << "unknown type";
    }
  return o;
}

ostream& modelica_type::print_dims(ostream& o)
{
  for (size_t i = 0; i < m_dimensions.size();++i)
    {
      o << "dimensions[" << i << "] : " << m_dimensions[i];
    }
  return o;
}

