#include "function_argument.hpp"

function_argument::function_argument()
{

}

function_argument::~function_argument()
{

}

int function_argument::size() const
{
  return m_actual_parameters.size();
}

void function_argument::push_back(value val, const std::string name = "")
{
  m_actual_parameters.push_back(std::make_pair(val,name));
}

function_argument::parameter_iterator function_argument::begin()
{
  return m_actual_parameters.begin();
}

function_argument::parameter_iterator function_argument::end()
{
  return m_actual_parameters.end();
}


