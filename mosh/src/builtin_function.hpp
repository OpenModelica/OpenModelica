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

#ifndef BUILTIN_FUNCTION_HPP_
#define BUILTIN_FUNCTION_HPP_

#include "modelica_function.hpp"
#include "modelica_type.hpp"
#include "runtime/modelica_runtime_error.hpp"
#include "value.hpp"
#include <string>
#include <set>

class builtin_function : public modelica_function
{
public:
  virtual ~builtin_function();

protected:
  //  typedef std::set<value::type_en> type_s;
  typedef std::set<modelica_type> type_s;
  typedef std::vector<type_s>::iterator formal_parameter_iterator;

protected:
  builtin_function();
  virtual value do_apply(value args) = 0;

  virtual bool match_formal_parameters(value args);

  std::vector<type_s> m_formal_parameters;


};

class abs_t : public builtin_function
{
public:
  abs_t();
  virtual ~abs_t();
protected:
  value do_apply(value args);
};

class bt_div_t : public builtin_function
{
public:
  bt_div_t();
  virtual ~bt_div_t();
protected:
  value do_apply(value args);
};

class mod_t : public builtin_function
{
public:
  mod_t();
  virtual ~mod_t();
protected:
  value do_apply(value args);
};

class rem_t : public builtin_function
{
public:
  rem_t();
  virtual ~rem_t();
protected:
  value do_apply(value args);
};

class sqrt_t : public builtin_function
{
public:
  sqrt_t();
  virtual ~sqrt_t();
protected:
  value do_apply(value args);
};

class sign_t : public builtin_function
{
public:
  sign_t();
  virtual ~sign_t();
protected:
  value do_apply(value args);
};

class ceil_t : public builtin_function
{
public:
  ceil_t();
  virtual ~ceil_t();
protected:
  value do_apply(value args);
};

class floor_t : public builtin_function
{
public:
  floor_t();
  virtual ~floor_t();
protected:
  value do_apply(value args);
};

class integer_t : public builtin_function
{
public:
  integer_t();
  virtual ~integer_t();
protected:
  value do_apply(value args);
};

class cd_t : public builtin_function
{
public:
  cd_t();
  virtual ~cd_t();
protected:
  value do_apply(value args);
};

class system_t : public builtin_function
{
public:
  system_t();
  virtual ~system_t();
protected:
  value do_apply(value args);
};

class read_t : public builtin_function
{
public:
  read_t();
  virtual ~read_t();
protected:
  value do_apply(value args);
};

class write_t : public builtin_function
{
public:
  write_t();
  virtual ~write_t();
protected:
  value do_apply(value args);
};

class gethrtime_t : public builtin_function
{
public:
  gethrtime_t();
  virtual ~gethrtime_t();
protected:
  value do_apply(value args);
};

template <class Fn>
class unary_fcn : public builtin_function
{
public:
  unary_fcn(Fn fn) : m_fn(fn) {}
  virtual ~unary_fcn() {}

  value do_apply(value args)
  {
    if (args.is_function_argument())
      {
	if (args.array_size() != 1)
	  {
	    throw modelica_runtime_error("wrong number of arguments");
	  }
      }

    //return value();
  }

protected:
  Fn m_fn;
};

template <class Fn>
unary_fcn<Fn>* generate_unary_fcn(Fn fn)
{
  return new unary_fcn<Fn>(fn);

}

template <class Fn>
class binary_fcn : public builtin_function
{
public:
  binary_fcn(Fn fn) : m_fcn(fn) {}
  virtual ~binary_fcn() {}

  value do_apply(value args)
  {
    return value(true);
  }

protected:
  Fn m_fcn;
};

template <class Fn>
binary_fcn<Fn> generate_binary_fcn(Fn fn)
{
  binary_fcn<Fn> tmp(fn);
  return fn;
}

#endif
