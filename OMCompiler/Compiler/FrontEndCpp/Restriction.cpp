#include <type_traits>
#include <ostream>

#include "Restriction.h"

using namespace OpenModelica;

constexpr int R_CLASS = 0;
constexpr int R_OPTIMIZATION = 1;
constexpr int R_MODEL = 2;
constexpr int R_RECORD = 3;
constexpr int R_BLOCK = 4;
constexpr int R_CONNECTOR = 5;
constexpr int R_OPERATOR = 6;
constexpr int R_TYPE = 7;
constexpr int R_PACKAGE = 8;
constexpr int R_FUNCTION = 9;
constexpr int R_ENUMERATION = 10;

constexpr int FR_NORMAL_FUNCTION = 0;
constexpr int FR_EXTERNAL_FUNCTION = 1;
constexpr int FR_OPERATOR_FUNCTION = 2;
constexpr int FR_RECORD_CONSTRUCTOR = 3;
constexpr int FR_PARALLEL_FUNCTION = 4;
constexpr int FR_KERNEL_FUNCTION = 5;

int to_value(Restriction::Prefix prefix, Restriction::Kind kind) noexcept
{
  return static_cast<int>(prefix) | static_cast<int>(kind);
}

int to_value(Restriction::Kind kind) noexcept
{
  return static_cast<int>(kind);
}

int to_value(Restriction::Prefix prefix) noexcept
{
  return static_cast<int>(prefix);
}

Restriction::Prefix purity_to_prefix(Purity purity)
{
  switch (purity.value()) {
    case Purity::Pure:   return Restriction::Prefix::Pure;
    case Purity::Impure: return Restriction::Prefix::Impure;
    default:             return Restriction::Prefix::None;
  }
}

Restriction from_mm_function(MetaModelica::Record value) noexcept
{
  switch (value.index()) {
    case FR_NORMAL_FUNCTION:    return Restriction::Function(Purity{value[0]});
    case FR_EXTERNAL_FUNCTION:  return Restriction::ExternalFunction(Purity{value[0]});
    case FR_OPERATOR_FUNCTION:  return Restriction::OperatorFunction();
    case FR_RECORD_CONSTRUCTOR: return Restriction::RecordConstructor();
    case FR_PARALLEL_FUNCTION:  return Restriction::ParallelFunction();
    case FR_KERNEL_FUNCTION:    return Restriction::KernelFunction();
    default:                    return Restriction::Function(Purity::None);
  }
}

Restriction res_from_mm(MetaModelica::Record value) noexcept
{
  switch (value.index()) {
    case R_CLASS:        return Restriction::Class();
    case R_OPTIMIZATION: return Restriction::Optimization();
    case R_MODEL:        return Restriction::Model();
    case R_RECORD:       return value[0] ? Restriction::OperatorRecord() : Restriction::Record();
    case R_BLOCK:        return Restriction::Block();
    case R_CONNECTOR:    return Restriction::Connector(value[0].toBool());
    case R_OPERATOR:     return Restriction::Operator();
    case R_TYPE:         return Restriction::Type();
    case R_PACKAGE:      return Restriction::Package();
    case R_FUNCTION:     return from_mm_function(value[0]);
    case R_ENUMERATION:  return Restriction::Enumeration();
    default:             return Restriction::Class();
  }
}

Restriction::Restriction(MetaModelica::Record value) noexcept
{
  *this = res_from_mm(value);
}

Restriction Restriction::Connector(bool expandable) noexcept
{
  return {expandable ? Prefix::Expandable : Prefix::None, Kind::Connector};
}

Restriction Restriction::Function(Purity purity) noexcept
{
  return {purity_to_prefix(purity), Kind::Function};
}

Restriction Restriction::ExternalFunction(Purity purity) noexcept
{
  Restriction res{Prefix::External, Kind::Function};
  res._value |= static_cast<int>(purity_to_prefix(purity));
  return res;
}

bool Restriction::is(Restriction::Prefix prefix, Restriction::Kind kind) const noexcept
{
  return _value & (static_cast<int>(prefix) | static_cast<int>(kind));
}

bool Restriction::is(Restriction::Kind kind) const noexcept
{
  return _value & static_cast<int>(kind);
}

bool Restriction::is(Restriction::Prefix prefix) const noexcept
{
  return _value & static_cast<int>(prefix);
}

Restriction::Restriction(Prefix prefix, Kind kind) noexcept
  : _value{static_cast<int>(kind) | static_cast<int>(prefix)}
{
}

Restriction::Restriction(Kind kind) noexcept
  : _value{static_cast<int>(kind)}
{
}

Restriction::Restriction(Prefix prefix) noexcept
  : _value{static_cast<int>(prefix)}
{
}

std::string Restriction::str() const noexcept
{
  std::string str;

  auto prefix = _value & 0xFFFF0000;
  auto kind = static_cast<Kind>(_value & 0x0000FFFF);

  if (prefix) {
    if (is(Prefix::Expandable)) str += "expandable ";
    if (is(Prefix::Impure))     str += "impure ";
    if (is(Prefix::Operator))   str += "operator ";
    if (is(Prefix::Parallel))   str += "parallel ";
    if (is(Prefix::Kernel))     str += "kernel ";
  }

  switch (kind) {
    case Kind::Class:          str += "class";          break;
    case Kind::Model:          str += "model";          break;
    case Kind::Package:        str += "package";        break;
    case Kind::Block:          str += "block";          break;
    case Kind::Optimization:   str += "optimization";   break;
    case Kind::Connector:      str += "connector";      break;
    case Kind::Type:           str += "type";           break;
    case Kind::Enumeration:    str += "enumeration";    break;
    case Kind::Clock:          str += "Clock";          break;
    case Kind::Record:         str += "record";         break;
    case Kind::Operator:       str += "operator";       break;
    case Kind::Function:       str += "function";       break;
    case Kind::ExternalObject: str += "ExternalObject"; break;
  }

  return str;
}
