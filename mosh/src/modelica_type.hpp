/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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

#ifndef MODELICA_TYPE_HPP_
#define MODELICA_TYPE_HPP_

#include <iostream>
#include <vector>

class modelica_type
{
public:
  modelica_type();
  virtual ~modelica_type();

public:
  bool is_scalar() const;
  bool is_array() const;

  bool is_numeric() const;
  bool is_non_numeric() const;

  bool is_real() const;
  bool is_integer() const;
  bool is_string() const;
  bool is_boolean() const;

  bool is_real_array() const;
  bool is_integer_array() const;
  bool is_string_array() const;
  bool is_boolean_array() const;

  bool is_tuple() const;

  bool is_function() const;
  bool is_function_argument() const;

  void set_real();
  void set_integer();
  void set_string();
  void set_boolean();

  void set_real_array();
  void set_integer_array();
  void set_string_array();
  void set_boolean_array();

  void set_tuple();

  void set_function();
  void set_function_argument();

  bool type_equal(modelica_type t);

  std::vector<int> dimensions() const;

  friend modelica_type create_real();
  friend modelica_type create_integer();
  friend modelica_type create_string();
  friend modelica_type create_boolean();

  friend modelica_type create_real_array(std::vector<int> s);
  friend modelica_type create_integer_array(std::vector<int> s);
  friend modelica_type create_string_array(std::vector<int> s);
  friend modelica_type create_boolean_array(std::vector<int> s);

  // Should probably take a vector of types
  friend modelica_type create_tuple();

  friend modelica_type create_function_type();
  friend modelica_type create_function_argument_type();

  friend ostream& operator<< (ostream& o, const modelica_type& v);
  ostream& print_dims(ostream&);
protected:
  std::vector<int> m_dimensions;

   enum type_en {
     real_t,
     integer_t,
     string_t,
     boolean_t,
     real_array_t,
     integer_array_t,
     string_array_t,
     boolean_array_t,
     tuple_t,
     function_t,
     function_argument_t,
     undefined
  };

  type_en m_type;

};

#endif
