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

#include "symboltable.hpp"

#include "builtin_function.hpp"
#include "compiled_function.hpp"


#include <iostream>
#include <fstream>

symboltable::symboltable()
{
  // Initialize builtin functions
  //  cout << "Building symboltable" << endl;
  //  m_builtin_functions.insert(std::make_pair(std::string("abs"),value(new abs_t)));
  //m_builtin_functions.insert(std::make_pair(std::string("sign"),value(new sign_t)));
  // cout << "Finished building symboltable" << endl;

  // m_symboltable[(std::make_pair(std::string("abs"),value(generate_unary_fcn(ptr_fun(abs)))));
  //  m_symboltable["abs"] = value(generate_unary_fcn(ptr_fun(abs)));

  // Insert intrinsic mathematical functions
  m_symboltable["abs"] = value(new abs_t);
  m_symboltable["div"] = value(new bt_div_t);
  m_symboltable["mod"] = value(new mod_t);
  m_symboltable["rem"] = value(new rem_t);
  m_symboltable["sqrt"] = value(new sqrt_t);
  m_symboltable["sign"] = value(new sign_t);
  m_symboltable["ceil"] = value(new ceil_t);
  m_symboltable["floor"] = value(new floor_t);
  m_symboltable["integer"] = value(new integer_t);
  m_symboltable["cd"] = value(new cd_t);
  m_symboltable["system"] = value(new system_t);
  m_symboltable["read"] = value(new read_t);
  m_symboltable["write"] = value(new write_t);
  m_symboltable["gethrtime"] = value(new gethrtime_t);

}

symboltable::~symboltable()
{

}

void symboltable::insert(std::string name, value val)
{
  m_symboltable.insert(std::make_pair(name,val));
}

value* symboltable::lookup(std::string name)
{
  value* res = do_lookup(name);
  return res;
//   if (!res)
//     {
//       return res;
//     }
//   else
//     {
//       return res;
//     }
}

value* symboltable::lookup_function(std::string name)
{
  // Search among builtin functions
  value* res = do_lookup(name);

  if (!res)
    {
      // Search on the file system
      res = do_file_lookup(name);
     //  if (!res)
// 	{
// 	  throw run_time_error("Failed to resolve "+name+".");
// 	}
    }
  return res;
}

value* symboltable::do_lookup(std::string name)
{
  std::map<std::string,value>::iterator pos;
  pos = m_symboltable.find(name);
  if (pos != m_symboltable.end())
    {
      return &(pos->second);
    }
  else
    {
      return 0;
    }
}

value* symboltable::do_file_lookup(std::string name)
{
  std::ifstream file;
  std::string filename = name;
  std::string mo_filename = name + ".mo";

  file.open(mo_filename.c_str());
  if (!file)
    {
      std::cerr << "Could not open file: " << mo_filename << endl;
      return 0;
    }

  file.close();

  // Found file
  value new_val = value(new compiled_function(filename));
  insert(name,new_val);

  return do_lookup(name);
}
