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
