#include "value.hpp"

#include "modelica_function.hpp"
#include "function_argument.hpp"
#include "runtime/modelica_runtime_error.hpp"

#include <cmath>

value::value() : m_function(0)//,m_function_args(0)
{

  m_type = undefined;
}

value::value(double val)
{
  m_real = val;
  m_type = real;
}

value::value(bool val)
{
  m_boolean = val;
  m_type = boolean;
}

value::value(int val)
{
  m_integer = val;
  m_type = integer;
}

value::value(std::string val)
{
  m_string = val;
  m_type = str;
}

value::value(modelica_function* fcn)
{
  m_function = fcn;
  m_type = function;
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
  m_type = val.m_type;
  switch (m_type)
    {
    case str:
      m_string = val.m_string;
      break;
    case integer:
      m_integer = val.m_integer;
      break;
    case real:
      m_real = val.m_real;
      break;
    case boolean:
      m_boolean = val.m_boolean;
      break;
    case real_array:
      // Copy real array
      // m_array = val.m_array;
      break;
    case function:
      m_function = val.m_function;
      break;
//     case fcn_arg:
//       //      m_function_arguments = val.m_function_arguments;
//       m_function_args = val.m_function_args;
//       //            m_is_function_argument = val.m_is_function_argument;
//       break;
    case undefined:
      // do something here
      break;
      
    }
 
  
}

void value::set_value(std::string val)
{
  m_string = val;
  m_type = str;
}

void value::set_value(int val)
{
  m_integer = val;
  m_type = integer;
}

void value::set_value(double val)
{
  m_real = val;
  m_type = real;
}

void value::set_value(bool val)
{
  m_boolean = val;
  m_type = boolean;
}

void value::set_value(modelica_function* fcn)
{
  m_function = fcn;
  m_type = function;
}

// void value::set_value(function_argument* func_arg)
// {
//   m_function_args = func_arg;
//   m_type = fcn_arg;
// }

// void value::set_value(modelica_real_array* arr)
// {
//   m_array = arr;
//   m_type = real_array;
// }

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

// function_argument* value::get_function_arguments()
// {
//   return m_function_args;
// }

value::type_en value::type() const
{
  return m_type;
}

void value::set_type(value::type_en type)
{
  m_type = type;
}

bool value::is_numeric() const
{
  return (m_type == integer) || (m_type == real);
}

bool value::is_real() const
{
  return m_type == real;
}

bool value::is_integer() const
{
  return m_type == integer;
}

bool value::is_boolean() const
{
  return m_type == boolean;
}

bool value::is_string() const
{
  return m_type == str;
}

bool value::is_function() const
{
  return m_type == function;
}

bool value::is_array() const
{
  //return m_type == array;
  return (m_type == str_array) || (m_type == integer_array) 
    || (m_type == real_array) || (m_type == boolean_array);
}

// bool value::is_function_argument() const
// {
//   //  return m_is_function_argument;
//   return m_type == fcn_arg;
// }

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

  if (v.is_array())
    {
      o << "{";

//       for (int i = 0; i < ndims; ++i)
// 	{
	  
// 	}
      
    //   vector<const value>::iterator pos = v.m_array.begin();
      
//       o << "{" << *pos;
//       pos++;
//       for (; pos < v.m_array.end(); ++pos)
// 	{
// 	  o << "," << *pos;
// 	}
//       o << "}";
    }

  return o;
}

const value& value::operator+= (const value& val)
{
  //  cout << "type: m_type " << m_type << endl;
  // cout << "val type: " << val.type() << endl;
  if (!is_numeric() || !val.is_numeric())
    {
      throw modelica_runtime_error("Adding non-numerical value\n");
    }


  if (val.is_real() || is_real())
  {
    m_real = to_double()+val.to_double();
    m_type = real;
  }
  else 
    {
      m_integer += val.m_integer;
      m_type = integer;
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
      throw modelica_runtime_error("Subtracting non-numerical value\n");
    }

  if (val.is_real() || is_real())
  {
    m_real = to_double()-val.to_double();
    m_type = real;
  }
  else 
    {
      m_integer -= val.m_integer;
      m_type = integer;
    }

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
    if (!is_numeric() || !val.is_numeric())
    {
      throw modelica_runtime_error("Multiplying non-numerical value\n");
    }

  if (val.is_real() || is_real())
  {
    m_real = to_double()*val.to_double();
    m_type = real;
  }
  else 
    {
      m_integer *= val.m_integer;
      m_type = integer;
    }

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
    if (!is_numeric() || !val.is_numeric())
    {
      throw modelica_runtime_error("Multiplying non-numerical value\n");
    }

  if (val.is_real() || is_real())
  {
    m_real = to_double()/val.to_double();
    m_type = real;
  }
  else 
    {
      m_real = m_integer / static_cast<double>(val.m_integer);
      m_type = real;
    }

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
  tmp.set_type(value::real_array);
  
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
  tmp.set_type(value::real_array);
  

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
