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

#include "modelica_function.hpp"

#include "value.hpp"

modelica_function::modelica_function()
{

}

modelica_function::~modelica_function()
{

}

value modelica_function::apply(value args)
{
  // Code for element-wise function application should go here

  // Match formal parameters
  if (match_formal_parameters(args))
    {
      return do_apply(args);
    }

  // do type conversion

  // is the type an array of the formal type
  if (args.is_array())
    {

      //     cout << "an array " << args.type() <<  endl;
    }
  else
    {
      //cout << "not an array " << args.type() <<  endl;
    }
}

std::string modelica_function::name() const
{
  return m_name;
}

void modelica_function::set_name(std::string name)
{
  m_name = name;
}
