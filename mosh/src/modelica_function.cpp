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
      
      cout << "an array " << args.type() <<  endl;
    }
  else
    {
      cout << "not an array " << args.type() <<  endl;
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
