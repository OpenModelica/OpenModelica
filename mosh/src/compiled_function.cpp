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

value compiled_function::do_apply(value args)
{
  // Generate input file
  write_input_file(args);

  // Check if a valid executable exist
  // Execute
  
  // Build executable
  std::string build_command = "make -f Makefile.single TARGET="+m_filename+ " clean all";
  if (system(build_command.c_str()) == -1)
    {
      cout << "Failed to build file" << endl;
    }

  std::string execute_command = m_filename+" mosh_in.dat"+" result.dat";
  
  if (system(execute_command.c_str())==-1)
    {
      cout << "Failed to execute file" << endl;
    }
  
  // Read output file
  value ret_val;
  read_result_file(&ret_val);
  // Return value
  return ret_val;
}

bool compiled_function::match_formal_parameters(value val)
{
  return true;
}

void compiled_function::write_input_file(value args)
{
  FILE* fp = fopen("mosh_in.dat","w");
  
  if(fp == NULL)
    {
      cout << "Failed to open mosh_in.dat" << endl;
    }

//   function_argument* params = args.get_function_arguments();
//   function_argument::parameter_iterator it = params->begin();  
//   for (; it != params->end();++it)
//     {
//       if (it->first.is_real())
// 	{
// 	  fprintf(fp,"%e\n",it->first.get_real());
// 	  //	  cout << "printing real value " << it->f <<endl;
// 	}
//       else if (it->first.is_integer())
// 	{
// 	  fprintf(fp,"%d\n",it->first.get_integer());
// 	}
//       else
// 	{
// 	  cout << "tried to print an unknown type" << endl;
// 	}
//     }
  
  fclose(fp);
}

void compiled_function::read_result_file(value* v)
{
  FILE* fp = fopen("result.dat","r");

  if (fp == NULL)
    {
      cout << "Failed to open data.out" << endl;
    }
  float f;
  fscanf(fp,"%e",&f);
  //  cout << f << endl;
  v->set_value(f);
  
  fclose(fp);
}

