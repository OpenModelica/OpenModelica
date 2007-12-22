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
