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

extern record_description Absyn_Operator_ADD__desc;
extern record_description Absyn_Operator_SUB__desc;
extern record_description Absyn_Operator_MUL__desc;
extern record_description Absyn_Operator_DIV__desc;
extern record_description Absyn_Operator_POW__desc;
extern record_description Absyn_Operator_UPLUS__desc;
extern record_description Absyn_Operator_UMINUS__desc;
extern record_description Absyn_Operator_ADD__EW__desc;
extern record_description Absyn_Operator_SUB__EW__desc;
extern record_description Absyn_Operator_MUL__EW__desc;
extern record_description Absyn_Operator_DIV__EW__desc;
extern record_description Absyn_Operator_POW__EW__desc;
extern record_description Absyn_Operator_UPLUS__EW__desc;
extern record_description Absyn_Operator_UMINUS__EW__desc;
extern record_description Absyn_Operator_AND__desc;
extern record_description Absyn_Operator_OR__desc;
extern record_description Absyn_Operator_NOT__desc;
extern record_description Absyn_Operator_LESS__desc;
extern record_description Absyn_Operator_LESSEQ__desc;
extern record_description Absyn_Operator_GREATER__desc;
extern record_description Absyn_Operator_GREATEREQ__desc;
extern record_description Absyn_Operator_EQUAL__desc;
extern record_description Absyn_Operator_NEQUAL__desc;

constexpr auto descs = std::array{
  &Absyn_Operator_ADD__desc,
  &Absyn_Operator_SUB__desc,
  &Absyn_Operator_MUL__desc,
  &Absyn_Operator_DIV__desc,
  &Absyn_Operator_POW__desc,
  &Absyn_Operator_UPLUS__desc,
  &Absyn_Operator_UMINUS__desc,
  &Absyn_Operator_ADD__EW__desc,
  &Absyn_Operator_SUB__EW__desc,
  &Absyn_Operator_MUL__EW__desc,
  &Absyn_Operator_DIV__EW__desc,
  &Absyn_Operator_POW__EW__desc,
  &Absyn_Operator_UPLUS__EW__desc,
  &Absyn_Operator_UMINUS__EW__desc,
  &Absyn_Operator_AND__desc,
  &Absyn_Operator_OR__desc,
  &Absyn_Operator_NOT__desc,
  &Absyn_Operator_LESS__desc,
  &Absyn_Operator_LESSEQ__desc,
  &Absyn_Operator_GREATER__desc,
  &Absyn_Operator_GREATEREQ__desc,
  &Absyn_Operator_EQUAL__desc,
  &Absyn_Operator_NEQUAL__desc
};

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

MetaModelica::Value Operator::toAbsyn() const noexcept
{
  return MetaModelica::Record(static_cast<int>(_value), *descs[static_cast<int>(_value)]);
}

bool Operator::isArithmetic() const noexcept
{
  return _value <= Value::UnaryMinusEw;
}

bool Operator::isLogical() const noexcept
{
  return _value >= Value::And && _value <= Value::Not;
}

bool Operator::isRelational() const noexcept
{
  return _value >= Value::Less;
}

std::string_view Operator::symbol() const noexcept
{
  return symbols[static_cast<int>(_value)];
}

std::string_view Operator::spacedSymbol() const noexcept
{
  return spacedSymbols[static_cast<int>(_value)];
}
