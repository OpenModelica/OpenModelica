#include "value.hpp"

#include "modelica_function.hpp"
#include "function_argument.hpp"
#include "runtime/modelica_runtime_error.hpp"
#include "runtime/modelica_array.hpp"
#include "runtime/numerical_array.hpp"

#include <cmath>

value::value() : m_function(0)//,m_function_argument(0)
{
}

value::value(double val)
{
  m_real = val;
  m_basic_type = create_real();
}

value::value(bool val)
{
  m_boolean = val;
  m_basic_type = create_boolean();
}

value::value(int val)
{
  m_integer = val;
  m_basic_type = create_integer();
}

value::value(std::string val)
{
  m_string = val;
  m_basic_type = create_string();
}

value::value(const real_array& arr)
{
  m_real_array = arr;
  m_basic_type = create_real_array(arr.size());
}

value::value(const integer_array& arr)
{
  m_integer_array = arr;
  m_basic_type = create_integer_array(arr.size());
}

value::value(const string_array& arr)
{
  m_string_array = arr;
  m_basic_type = create_string_array(arr.size());
}

value::value(const boolean_array& arr)
{
  m_boolean_array = arr;
  m_basic_type = create_boolean_array(arr.size());
}

value::value(modelica_function* fcn)
{
  m_function = fcn;
  m_basic_type = create_function_type();
}

// value::value(function_argument* func_arg)
// {
//   m_function_args = func_arg;
//   m_type = fcn_arg;
// }

value::~value()
{
}

value::value(const value& val)
{
  m_basic_type = val.m_basic_type;
  
  if (m_basic_type.is_real())
    {
      m_real = val.m_real;
      m_basic_type = create_real();
      return;
    }
  else if (m_basic_type.is_integer())
    {
      m_integer = val.m_integer;
      m_basic_type = create_integer();
      return;
    }
  else if (m_basic_type.is_string())
    {
      m_string = val.m_string;
      m_basic_type = create_string();
      return;
    }
  else if (m_basic_type.is_boolean())
    {
      m_boolean = val.m_boolean;
      m_basic_type = create_boolean();
      return;
    }
  else if (m_basic_type.is_real_array())
    {
      m_real_array = val.m_real_array;
      m_basic_type = create_real_array(val.m_real_array.size());
      return;
    }
  else if (m_basic_type.is_integer_array())
    {
      m_integer_array = val.m_integer_array;
      m_basic_type = create_integer_array(val.m_integer_array.size());
      return;
    }
  else if (m_basic_type.is_string_array())
    {
      m_string_array = val.m_string_array;
      m_basic_type = create_string_array(val.m_string_array.size());
      return;
    }
  else if (m_basic_type.is_boolean_array())
    {
      m_boolean_array = val.m_boolean_array;
      m_basic_type = create_boolean_array(val.m_boolean_array.size());
      return;
    }
  else if (m_basic_type.is_function())
    {
      m_function = val.m_function;
      m_basic_type = create_function_type();
      return;
    }
  else if (m_basic_type.is_function_argument())
    {
      m_function_argument = val.m_function_argument;
      m_basic_type = create_function_argument_type();
      return;
    }
}

void value::set_value(std::string val)
{
  m_string = val;
   m_basic_type = create_string();
}

void value::set_value(int val)
{
  m_integer = val;
   m_basic_type = create_integer();
}

void value::set_value(double val)
{
  m_real = val;
  m_basic_type = create_real();
}

void value::set_value(bool val)
{
  m_boolean = val;
  m_basic_type = create_boolean();
}

void value::set_value(modelica_function* fcn)
{
  m_function = fcn;
  m_basic_type = create_function_type();
}

void value::set_value(const real_array& arr)
{
  m_real_array = arr;
  m_basic_type = create_real_array(arr.size());
}

void value::set_value(const string_array& arr)
{
  m_string_array = arr;
  m_basic_type = create_string_array(arr.size());
}

void value::set_value(const boolean_array& arr)
{
  m_boolean_array = arr;
  m_basic_type = create_boolean_array(arr.size());
}

void value::set_value(const integer_array& arr)
{
  m_integer_array = arr;
  m_basic_type = create_integer_array(arr.size());
}

void value::set_value(function_argument* func_arg)
{
  m_function_argument = func_arg;
  m_basic_type = create_function_argument_type();
}

std::string value::get_string() const
{
  return m_string;
}


double value::get_real() const
{
  return m_real;
}


int value::get_integer() const
{
  return m_integer;
}


bool value::get_boolean() const
{
  return m_boolean;
}

modelica_function* value::get_function()
{
  return m_function;
}

real_array value::get_real_array() const
{
  return m_real_array;
}

integer_array value::get_integer_array() const
{
  return m_integer_array;
}

string_array value::get_string_array() const
{
  return m_string_array;
}

boolean_array value::get_boolean_array() const
{
  return m_boolean_array;
}

function_argument* value::get_function_argument()
{
  return m_function_argument;
}

modelica_type value::type() const
{
  return m_basic_type;
}

void value::set_type(const modelica_type& t)
{
  m_basic_type = t;
}

// value::type_en value::type() const
// {
//   return m_type;
// }

// void value::set_type(value::type_en type)
// {
//   m_type = type;
// }

bool value::is_numeric() const
{
  return m_basic_type.is_numeric();
}

bool value::is_real() const
{
  return m_basic_type.is_real();
}

bool value::is_integer() const
{
  return m_basic_type.is_integer();
}

bool value::is_boolean() const
{
  return m_basic_type.is_boolean();
}

bool value::is_string() const
{
  return m_basic_type.is_string();
}

bool value::is_function() const
{
  return m_basic_type.is_function();
}

bool value::is_array() const
{
  return m_basic_type.is_array();
  //return m_type == array;
  // return (m_type == str_array) || (m_type == integer_array_t) 
//     || (m_type == real_array_t) || (m_type == boolean_array);
}

bool value::is_real_array() const
{
  return m_basic_type.is_real_array();
}

bool value::is_integer_array() const
{
  return m_basic_type.is_integer_array();
}

bool value::is_string_array() const
{
  return m_basic_type.is_string_array();
}

bool value::is_boolean_array() const
{
  return m_basic_type.is_boolean_array();
}

bool value::is_function_argument() const
{
  //  return m_is_function_argument;
  return m_basic_type.is_function_argument();
}

// void value::append_to_array(const value& val)
// {
//   m_array.push_back(val);
// }

// void value::append_to_function_arguments(const value& val)
// {
//   //   m_function_arguments.push_back(val);
// }

// value::array_iterator value::array_begin()
// {
//   return m_array.begin();
// }

// value::array_iterator value::array_end()
// {
//   return m_array.end();
// }

// int value::array_size()
// {
//   return m_array.size();
// }

// int value::function_arguments_size()
// {
  
// }

ostream& operator<< (ostream& o, const value& v)
{
  
  if (v.is_integer()) 
    {
      o << v.m_integer;
    }

  if (v.is_boolean())
    {
      o << v.m_boolean;
    }
  
  if (v.is_real())
    {
      o << v.m_real;
    }

  if (v.is_string())
    {
      o << v.m_string;
    }

  if (v.is_function())
    {
      //      o << v.m_function->name();
    }

  if (v.is_real_array())
    {
      o << v.get_real_array();
    }

  if (v.is_integer_array())
    {
      o << v.get_integer_array();
    }
  
  if (v.is_string_array())
    {
      o << v.get_string_array();
    }

  if (v.is_boolean_array())
    {
      o << v.get_boolean_array();
    }

  return o;
}

const value& value::operator+= (const value& val)
{
  if (!is_numeric() || !val.is_numeric())
    {
      throw modelica_runtime_error("Adding non-numerical value\n");
    }
  if (check_type(*this,val))
    {
      if (is_real_array())
	{
	  m_real_array += val.m_real_array;
	}
      else if (is_integer_array())
	{
	  m_integer_array += val.m_integer_array;
	}
      else if (is_real())
	{
	  m_real += val.m_real;
	}
      else if (is_integer())
	{
	  m_integer += val.m_integer;
	}
      else
	{
	  throw modelica_runtime_error("Internal error in value +=");
	}
    }
  else
    {
      throw modelica_runtime_error("Types does not match\n");
    }
    
  return *this;
}

value value::operator+(const value& v) const
{
  value tmp(*this);

  tmp += v;
  return tmp;
}

const value& value::operator-= (const value& val)
{

    if (!is_numeric() || !val.is_numeric())
    {
      throw modelica_runtime_error("Adding non-numerical value\n");
    }

  if (check_type(*this,val))
    {
      if (is_real_array())
	{
	  m_real_array -= val.m_real_array;
	}
      else if (is_integer_array())
	{
	  m_integer_array -= val.m_integer_array;
	}
      else if (is_real())
	{
	  m_real -= val.m_real;
	}
      else if (is_integer())
	{
	  m_integer -= val.m_integer;
	}
      else
	{
	  throw modelica_runtime_error("Internal error in value +=");
	}
    }
  else
    {
      throw modelica_runtime_error("Adding non-numerical value\n");
    }

//   if (val.is_array() || is_array())
//     {
//       m_real_array -= val.m_real_array;
//       m_type = real_array_t;
//     }
//   else if (!is_numeric() || !val.is_numeric())
//     {
//       throw modelica_runtime_error("Subtracting non-numerical value\n");
//     }
  
//   if (val.is_real() || is_real())
//     {
//       m_real = to_double()-val.to_double();
//       m_type = real;
//     }
//   else 
//     {
//       m_integer -= val.m_integer;
//       m_type = integer;
//     }
  
  return *this;
}

value value::operator-(const value& v) const
{
  value tmp(*this);
  tmp -= v;
  return tmp;
}

const value& value::operator*= (const value& val)
{
 //    if (!is_numeric() || !val.is_numeric())
//     {
//       throw modelica_runtime_error("Multiplying non-numerical value\n");
//     }

//   if (val.is_real() || is_real())
//   {
//     m_real = to_double()*val.to_double();
//     m_type = real;
//   }
//   else 
//     {
//       m_integer *= val.m_integer;
//       m_type = integer;
//     }

  return *this;
}

value value::operator*(const value& v) const
{
  value tmp(*this);
  tmp *= v;
  return tmp;
}

const value& value::operator/= (const value& val)
{
//     if (!is_numeric() || !val.is_numeric())
//     {
//       throw modelica_runtime_error("Multiplying non-numerical value\n");
//     }

//   if (val.is_real() || is_real())
//   {
//     m_real = to_double()/val.to_double();
//     m_type = real;
//   }
//   else 
//     {
//       m_real = m_integer / static_cast<double>(val.m_integer);
//       m_type = real;
//     }

  return *this;
}

value value::operator/(const value& v) const
{
  value tmp(*this);
  tmp /= v;
  return tmp;
}

double value::to_double() const
{
  if (!is_numeric())
    {
      throw modelica_runtime_error("to_double on non-numerical value\n");
    }

  if (is_integer()) 
    {
      return static_cast<double>(m_integer);
    }
  else
    {
      return m_real;
    }
}

value value::operator-() const
{
    if (!is_numeric())
	{
	    throw modelica_runtime_error("unary minus on non-numerical value\n");
	}

    value tmp(*this);

    if (is_integer()) 
	{
	    tmp.m_integer = - m_integer;
	}
    else
	{
	    tmp.m_real = - m_real;
	}

    return tmp;
}

const value power(const value& x,const value& y)
{
  if (!x.is_numeric() || !y.is_numeric())
    {
      throw modelica_runtime_error("Power non-numerical value\n");
    }
  
  return value(pow(x.to_double(),y.to_double()));
}

const value not_bool(const value& x)
{
  if (!x.is_boolean())
    {
      throw modelica_runtime_error("Not of a non-boolean value\n");
    }
  
  return value(!(x.m_boolean));
}

const value and_bool(const value& x,const value& y)
{
  
  if (!x.is_boolean())
    {
      throw modelica_runtime_error("And of a non-boolean value\n");
    }
  
  return value(x.m_boolean && y.m_boolean);
}

const value or_bool(const value& x,const value& y)
{
  if (!x.is_boolean())
    {
      throw modelica_runtime_error("Or of a non-boolean value\n");
    }
  
  return value(x.m_boolean || y.m_boolean);
}

const value modelica_if(const value& x, const value& y, const value& z)
{
  if (!x.is_boolean())
    {
      throw modelica_runtime_error("If of a non-boolean value\n");
    }
  
  if (x.get_boolean())
    return y;
  else
    return z;
}

/*const value less(const value& x, const value& y)
{
    if (!x.is_numeric() || !y.is_numeric())
	{
	    throw modelica_runtime_error("less of a non-numerical value\n");
	}
    
    return value(x.to_double() < y.to_double());
}*/

const value lesseq(const value& x, const value& y)
{
    if (!x.is_numeric() || !y.is_numeric())
	{
	    throw modelica_runtime_error("less of a non-numerical value\n");
	}
    bool result = x.to_double() <= y.to_double();
    return value(result);
//    return value(static_cast<bool>(x.to_double() <= y.to_double()));
}

/*const value greater(const value& x, const value& y)
{
    if (!x.is_numeric() || !y.is_numeric())
	{
	    throw modelica_runtime_error("less of a non-numerical value\n");
	}
    
    return value(x.to_double() > y.to_double());
}*/

const value greatereq(const value& x, const value& y)
{
    if (!x.is_numeric() || !y.is_numeric())
	{
	    throw modelica_runtime_error("less of a non-numerical value\n");
	}
    
    return value(x.to_double() >= y.to_double());
}

const value eqeq(const value& x, const value& y)
{
    if (!x.is_numeric() || !y.is_numeric())
	{
	    throw modelica_runtime_error("less of a non-numerical value\n");
	}
    
    return value(x.to_double() == y.to_double());
}

const value lessgt(const value& x, const value& y)
{
    if (!x.is_numeric() || !y.is_numeric())
	{
	    throw modelica_runtime_error("less of a non-numerical value\n");
	}
    
    return value(x.to_double() != y.to_double());
}

const value create_array(const value& x)
{
  value tmp;
  // tmp.set_type(value::real_array_t);
  
  //  tmp.append_to_array(x);
  
  return tmp;
}

const value create_array(const value& x, const value& y, const value& z)
{
  if (!x.is_numeric() || !y.is_numeric() || !z.is_numeric())
	{
	    throw modelica_runtime_error("Non-numeric value in range expression\n");
	}
  
  value tmp;
  //tmp.set_type(value::real_array_t);
  

  if (x.is_integer() && y.is_integer() && z.is_integer())
    {
      //  cout << x;
      //cout << y;
      //cout << z;
      double upper = floor( (z.get_integer()-x.get_integer()) / y.get_integer());
      for (int i = 0; i <= upper; i++)
	{
	  //	  tmp.append_to_array(value(x.get_integer()+int(i)*y.get_integer()));
	}
    }
  else
    {
      double lower = x.is_real() ? x.get_real() : x.get_integer();
      double increment = y.is_real() ? y.get_real() : y.get_integer();
      double upper = z.is_real() ? z.get_real() : z.get_integer();
 
      for (int i = 0; i <= floor((upper-lower)/increment); ++i)
	{
	  // tmp.append_to_array(value(lower+i*increment));
	}
    }
  return tmp;
    
}

// const value create_array(const value& x, const value& y)
// {
//   return create_array(x, value(1), y);
// }

bool check_type(value v1,value v2)
{
  if (v1.type().type_equal(v2.type()))
    {
      return true;
    }
  else
    {
      return false;
    }
}
