#include "builtin_function.hpp"

#include "runtime/modelica_runtime_error.hpp"
#include <cmath>
#include <assert.h>
#include <cstdlib>
#include <fstream>

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
  type_s t;
  t.insert(value::real);
  t.insert(value::integer);
  m_formal_parameters.push_back(t);
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

bt_div_t::bt_div_t()
{

}

bt_div_t::~bt_div_t()
{

}

value bt_div_t::do_apply(value args)
{
  return value(2);
}

mod_t::mod_t()
{

}

mod_t::~mod_t()
{

}

value mod_t::do_apply(value args)
{
  return value(2);
}

rem_t::rem_t()
{

}

rem_t::~rem_t()
{

}

value rem_t::do_apply(value args)
{
  return value(2);
}

sqrt_t::sqrt_t()
{
  
}

sqrt_t::~sqrt_t()
{

}

value sqrt_t::do_apply(value args)
{
  return value(2);
}

sign_t::sign_t()
{

}

sign_t::~sign_t()
{

}

value sign_t::do_apply(value args)
{
  return value(2);
}

ceil_t::ceil_t()
{
  type_s t;
  t.insert(value::real);
  //  t.insert(value::integer);
  m_formal_parameters.push_back(t);
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
  type_s t;
  t.insert(value::real);
  //  t.insert(value::integer);
  m_formal_parameters.push_back(t);
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
  return value(2);
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
