#include <array>
#include <string>
#include <stdexcept>
#include <ostream>

#include "Operator.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

constexpr auto symbols = std::array{
  "+", "-", "*", "/", "^", "+", "-", ".+", ".-", ".*", "./", ".^",
  "+", "-", "and", "or", "not", "<", "<=", ">", ">=", "==", "<>"};

constexpr auto spacedSymbols = std::array{
  " + ", " - ", " * ", " / ", " ^ ", "+", "-", " .+ ", " .- ", " .* ", " ./ ", " .^ ",
  "+", "-", " and ", " or ", "not ", " < ", " <= ", " > ", " >= ", " == ", " <> "};

Operator::Value value_from_mm(MetaModelica::Record value)
{
  if (value.index() < 0 || value.index() > Operator::Value::NotEqual) {
    throw std::runtime_error("Invalid Absyn::Operator index " + std::to_string(value.index()));
  }

  return static_cast<Operator::Value>(value.index());
}

Operator::Operator(MetaModelica::Record value)
  : _value{value_from_mm(value)}
{
}

std::string_view Operator::symbol() const noexcept
{
  return symbols[static_cast<int>(_value)];
}

std::string_view Operator::spacedSymbol() const noexcept
{
  return spacedSymbols[static_cast<int>(_value)];
}
