/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/


#include "builtin_function.hpp"

#include "runtime/modelica_runtime_error.hpp"
#include <sys/time.h>

#include <cmath>
#include <assert.h>
#include <cstdlib>
#include <fstream>

#include <unistd.h>

#include "function_argument.hpp"

builtin_function::builtin_function()
{

}

builtin_function::~builtin_function()
{

}

bool builtin_function::match_formal_parameters(value args)
{
//   function_argument* params = args.get_function_arguments();
  
//   if ( !(params->size() == m_formal_parameters.size()) )
//      {
       
//        // This functionality should probably be moved to modelica_function
//        cout << "Wrong number of arguments" << endl;
//        return false;
//      }
  
//   builtin_function::formal_parameter_iterator formal_it = m_formal_parameters.begin();
//   function_argument::parameter_iterator actual_it = params->begin();
  
//   for (; formal_it != m_formal_parameters.end(); ++formal_it,++actual_it)
//     {
//       if (formal_it->find(actual_it->first.type()) == formal_it->end())
//       {
// 	cout << "Types doesn't match. Argument is of type " << actual_it->first.type() << endl;
// 	return false;
//       }

//     }
  return true;
}

abs_t::abs_t()
{
 //  type_s t;
//   t.insert(create_real());
//   t.insert(create_integer());
//   m_formal_parameters.push_back(t);
}


abs_t::~abs_t()
{

}

value abs_t::do_apply(value args)
{
  //assert(args.is_function_argument());

  //   function_argument::parameter_iterator it = args.get_function_arguments()->begin();
//    value new_val;

//    if (it->first.is_real())
//      {
//        new_val.set_value(abs(it->first.get_real()));
//      }
//   else if (it->first.is_integer())
//     {
//       new_val.set_value(abs(it->first.get_integer()));
//     }
//   return new_val;
  return value(true);
}

cd_t::cd_t()
{
}
cd_t::~cd_t()
{
}
value cd_t::do_apply(value args)
{
  value ret;
  if (args.is_function_argument())
    {
      function_argument* fnarg = args.get_function_argument();
      if (fnarg)
	{
	  if (fnarg->size() == 1)
	    {
	      value val = fnarg->begin()->first;
	      if (val.is_string())
		{
		  std::string path = val.get_string();
		  if(chdir(path.c_str()))
		    {
		      std::cout << "Unable to change directory to \"" 
				<< path.c_str() << "\"\n";
		    }
		  char buf[1024];
		  char *b2;
		  b2 = getcwd(buf,1024);
		  if (b2)
		    {
		      ret = std::string(buf);
		    }
		  else
		    {
		      std::cout << "Unable to get current directory\n";
		    }
		}
	      else
		{
		  std::cout << "Type mismatch. Expected string\n";
		}
	    }
	  else
	    {
	      std::cout << "Incorrect number of arguments. Expected one string\n";
	    }
	}
      else
	{
	  std::cout << "Internal error: NULL function_argument\n";
	}
    }
  else
    {
      std::cout << "Internal error: not function_argument\n";
    }
  return ret;
}

system_t::system_t()
{
}
system_t::~system_t()
{
}
value system_t::do_apply(value args)
{
  value ret;
  if (args.is_function_argument())
    {
      function_argument* fnarg = args.get_function_argument();
      if (fnarg)
	{
	  if (fnarg->size() == 1)
	    {
	      value val = fnarg->begin()->first;
	      if (val.is_string())
		{
		  std::string cmd = val.get_string();
		  ret = (long)system(cmd.c_str());
		}
	      else
		{
		  std::cout << "Type mismatch. Expected string\n";
		}
	    }
	  else
	    {
	      std::cout << "Incorrect number of arguments. Expected one string\n";
	    }
	}
      else
	{
	  std::cout << "Internal error: NULL function_argument\n";
	}
    }
  else
    {
      std::cout << "Internal error: not function_argument\n";
    }
  return ret;
}


read_t::read_t()
{
}
read_t::~read_t()
{
}
value read_t::do_apply(value args)
{
  value ret;
  if (args.is_function_argument())
    {
      function_argument* fnarg = args.get_function_argument();
      if (fnarg)
	{
	  if (fnarg->size() == 1)
	    {
	      value val = fnarg->begin()->first;
	      if (val.is_string())
		{
		  std::string path = val.get_string();
		  
		  ret = read_result_file(path.c_str());

		}
	      else
		{
		  std::cout << "Type mismatch. Expected string\n";
		}
	    }
	  else
	    {
	      std::cout << "Incorrect number of arguments. Expected one string\n";
	    }
	}
      else
	{
	  std::cout << "Internal error: NULL function_argument\n";
	}
    }
  else
    {
      std::cout << "Internal error: not function_argument\n";
    }
  return ret;
}

write_t::write_t()
{
}
write_t::~write_t()
{
}
value write_t::do_apply(value args)
{
  value ret;
  if (args.is_function_argument())
    {
      function_argument* fnarg = args.get_function_argument();
      if (fnarg)
	{
	  if (fnarg->size() == 2)
	    {
	      function_argument::parameter_iterator it = fnarg->begin();
	      value val = it->first;
	      ++it;
	      value file = it->first;
	      if (file.is_string())
		{
		  std::string path = file.get_string();
		  
		  ret = (long) write_input_file(val,path.c_str());

		}
	      else
		{
		  std::cout << "Type mismatch. Expected string for second argument\n";
		}
	    }
	  else
	    {
	      std::cout << "Incorrect number of arguments. Expected one value and one string\n";
	    }
	}
      else
	{
	  std::cout << "Internal error: NULL function_argument\n";
	}
    }
  else
    {
      std::cout << "Internal error: not function_argument\n";
    }
  return ret;
}

gethrtime_t::gethrtime_t()
{
}

gethrtime_t::~gethrtime_t()
{
}

value gethrtime_t::do_apply(value args)
{
  value ret;
  function_argument* fnarg = args.get_function_argument();
  if (fnarg->size() !=0) {
    std::cout << "Internal error: Wrong number of arguments. Usage gethrtime()\n";
  } else {
    std::cout << "calling gethrtime\n";
    ret.set_value((long)gethrtime());
  }
  
  return ret;
}


bt_div_t::bt_div_t()
{

}

bt_div_t::~bt_div_t()
{

}

value bt_div_t::do_apply(value args)
{
  return value((long)2);
}

mod_t::mod_t()
{

}

mod_t::~mod_t()
{

}

value mod_t::do_apply(value args)
{
  return value((long)2);
}

rem_t::rem_t()
{

}

rem_t::~rem_t()
{

}

value rem_t::do_apply(value args)
{
  return value((long)2);
}

sqrt_t::sqrt_t()
{
  
}

sqrt_t::~sqrt_t()
{

}

value sqrt_t::do_apply(value args)
{
  return value((long)2);
}

sign_t::sign_t()
{

}

sign_t::~sign_t()
{

}

value sign_t::do_apply(value args)
{
  return value((long)2);
}

ceil_t::ceil_t()
{
//   type_s t;
//   t.insert(create_real());
//   //  t.insert(value::integer);
//   m_formal_parameters.push_back(t);
}

ceil_t::~ceil_t()
{
  
}

value ceil_t::do_apply(value args)
{
  value new_val;
 //  function_argument::parameter_iterator it = args.get_function_arguments()->begin();

//   new_val.set_value(ceil(it->first.get_real()));
//   return new_val;
  return value(true);
}

floor_t::floor_t()
{
//   type_s t;
//   t.insert(create_real());
//   //  t.insert(value::integer);
//   m_formal_parameters.push_back(t);
}

floor_t::~floor_t()
{

}

value floor_t::do_apply(value args)
{
  value new_val;
//   function_argument::parameter_iterator it = args.get_function_arguments()->begin();

//   new_val.set_value(int(floor(it->first.get_real())));
//   return new_val;
  return value(true);
}

integer_t::integer_t()
{

}

integer_t::~integer_t()
{

}

value integer_t::do_apply(value args)
{
  // if (args.is_function_argument())
//     {
//       cout << "function argument" << endl;
//     }
  return value((long)2);
}

//   value new_val;
//   if (val.is_real())
//     {
//       new_val.set_value(fabs(val.get_real()));
//     }

//   if (val.is_integer())
//     {
//       new_val.set_value(abs(val.get_integer()));
//     }

//   return new_val;
// }

// sign_t::sign_t()
// {
//   builtin_function::m_name = "sign_t";
// }

// sign_t::~sign_t()
// {

// }

// value sign_t::evaluate(value val)
// {
//   return value(1);
// }
