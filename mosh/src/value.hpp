#ifndef VALUE_HPP_
#define VALUE_HPP_

#include <vector>
#include <string>
#include <iostream>

#include "runtime/modelica_array.hpp"
#include "runtime/numerical_array.hpp"
#include "modelica_type.hpp"

// Forward declaration
class modelica_function;
class function_argument;



class value
{
public:
  typedef std::vector<value>::iterator function_argument_iterator;
  typedef std::vector<value> tuple_type;

public:
  value();
  value(double val);
  value(bool val);
  value(int val);
  value(const std::string& val);
  value(const real_array& arr);
  value(const integer_array& arr);
  value(const string_array& arr);
  value(const boolean_array& arr);
  value(const tuple_type& tuple); // tuple

  value(modelica_function* function);

  virtual ~value();

  value(const value& val);
  
  void set_value(double val);
  void set_value(bool val);
  void set_value(std::string val);
  void set_value(int val);



  void set_value(const real_array& arr);
  void set_value(const integer_array& arr);
  void set_value(const string_array& arr);
  void set_value(const boolean_array& arr);
  void set_value(const tuple_type& tuple); // tuple

  void set_value(modelica_function* fcn);
  void set_value(function_argument* func_arg);

  // make_array may throw if types don't match
  void make_array(std::vector<value> const& exp_list);

  double get_real() const;
  std::string get_string() const;
  int get_integer() const;
  bool get_boolean() const;

  real_array const& get_real_array() const;
  integer_array const& get_integer_array() const;
  string_array const& get_string_array() const;
  boolean_array const& get_boolean_array() const;
  tuple_type const& get_tuple() const;

  real_array& get_real_array();
  integer_array& get_integer_array();
  string_array& get_string_array();
  boolean_array& get_boolean_array();
  tuple_type& get_tuple();

  modelica_function* get_function();
  function_argument* get_function_argument();

  modelica_type type() const;
  void set_type(const modelica_type& tp);
  //  type_en type() const;
  // void set_type(type_en type);

  bool is_numeric() const;
  bool is_real() const;
  bool is_integer() const;
  bool is_boolean() const;
  bool is_string() const;
 
  bool is_array() const;
  bool is_real_array() const;
  bool is_integer_array() const;
  bool is_string_array() const;
  bool is_boolean_array() const;
  bool is_tuple() const;

  bool is_function() const;
  bool is_function_argument() const;

public:
  const value& operator+= (const value& val);
  value operator+(const value& v) const;

  const value& operator-= (const value& val);
  value operator-(const value& val) const;

  const value& operator*= (const value& val);
    value operator*(const value& val) const;
    
  const value& operator/= (const value& val);
  value operator/(const value& val) const;
  
  value operator- () const;

public:
  friend ostream& operator<< (ostream& o, const value& v);
  
  friend const value power(const value& x, const value& y);
  friend const value not_bool(const value& x);
  friend const value and_bool(const value& x, const value& y);
  friend const value or_bool(const value& x, const value& y);
  friend const value modelica_if(const value& x, const value& y, const value& z);
  //    friend const value less(const value& x, const value& y);
  friend const value lesseq(const value& x, const value& y);
  //  friend const value greater(const value& x, const value& y);
  friend const value greatereq(const value& x, const value& y);
  friend const value eqeq(const value& x, const value& y);
  friend const value lessgt(const value& x, const value& y);

  friend const value create_array(const value& x);
  friend const value create_range_array(const value& x, const value& y, const value& z);


protected:

  //  friend bool check_type(value v1, value v2);
  std::string m_string;
  int m_integer;
  double m_real;
  bool m_boolean;
  modelica_function* m_function;
  function_argument* m_function_argument;

  real_array m_real_array;
  integer_array m_integer_array;
  string_array m_string_array;
  boolean_array m_boolean_array;
  tuple_type m_tuple;
  double to_double() const;

  modelica_type m_basic_type; 
};


bool check_type(value v1,value v2);

#endif
