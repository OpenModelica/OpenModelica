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

#include "compiled_function.hpp"
#include <stdio.h>
#include <fstream>
#include <stdlib.h>

#include "function_argument.hpp"
#include "value.hpp"
#include <unistd.h>

//extern "C" {
// #include "../c_runtime/read_write.h"
//}


compiled_function::compiled_function()
{

}

compiled_function::compiled_function(std::string filename)
{
  m_filename = filename;
}

compiled_function::~compiled_function()
{

}

bool file_exist(const char* filename)
{
  ifstream file(filename);
  if (file) return true;
  return false;
}

value compiled_function::do_apply(value args)
{
  value ret_val;

  std::string build_command = std::string("sh -c \"")
    + "rm -f success; "
    + "if make -f $MOSHHOME/build/Makefile.single TARGET="+m_filename
    +    " all 1> cmdoutput.tmp 2>&1;"
    + "then echo h > success;"
    + "fi"
    + "\"";

  std::string clean_command = std::string("sh -c \"")
    +   "make -f $MOSHHOME/build/Makefile.single TARGET=" + m_filename
    +     " clean 1> cmdoutput.tmp 2>&1"
    + "\"";


  if (system(build_command.c_str()) == -1)
    {
      system("cat cmdoutput.tmp");
      system(clean_command.c_str());
      system("rm -f cmdoutput.tmp");
      cout << "Failed to build file" << endl;
      return ret_val;
    }

  if (!file_exist("success"))
    {
      system("cat cmdoutput.tmp");
      system(clean_command.c_str());
      system("rm -f cmdoutput.tmp");
      cout << "Failed to build file" << endl;
      return ret_val;
    }
  else
    {
      system("rm -f success");
      system("rm -f cmdoutput.tmp");
    }

  write_input_file(args,"mosh_in.dat");
  std::string execute_command = "rm -f result.dat;./"
    + m_filename+" mosh_in.dat"+" result.dat";

  if (system(execute_command.c_str())==-1)
    {
      cout << "Failed to execute file" << endl;
       system("rm -f result.dat mosh_in.dat");
      return ret_val;
    }

  // Read output file
  ret_val = read_result_file("result.dat");

   system("rm -f result.dat mosh_in.dat");

  // Return value
  return ret_val;
}

bool compiled_function::match_formal_parameters(value val)
{
  return true;
}

