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

extern record_description SCode_Restriction_R__CLASS__desc;
extern record_description SCode_Restriction_R__OPTIMIZATION__desc;
extern record_description SCode_Restriction_R__MODEL__desc;
extern record_description SCode_Restriction_R__RECORD__desc;
extern record_description SCode_Restriction_R__BLOCK__desc;
extern record_description SCode_Restriction_R__CONNECTOR__desc;
extern record_description SCode_Restriction_R__OPERATOR__desc;
extern record_description SCode_Restriction_R__TYPE__desc;
extern record_description SCode_Restriction_R__PACKAGE__desc;
extern record_description SCode_Restriction_R__FUNCTION__desc;
extern record_description SCode_Restriction_R__ENUMERATION__desc;

constexpr int FR_NORMAL_FUNCTION = 0;
constexpr int FR_EXTERNAL_FUNCTION = 1;
constexpr int FR_OPERATOR_FUNCTION = 2;
constexpr int FR_RECORD_CONSTRUCTOR = 3;
constexpr int FR_PARALLEL_FUNCTION = 4;
constexpr int FR_KERNEL_FUNCTION = 5;

extern record_description SCode_FunctionRestriction_FR__NORMAL__FUNCTION__desc;
extern record_description SCode_FunctionRestriction_FR__EXTERNAL__FUNCTION__desc;
extern record_description SCode_FunctionRestriction_FR__OPERATOR__FUNCTION__desc;
extern record_description SCode_FunctionRestriction_FR__RECORD__CONSTRUCTOR__desc;
extern record_description SCode_FunctionRestriction_FR__PARALLEL__FUNCTION__desc;
extern record_description SCode_FunctionRestriction_FR__KERNEL__FUNCTION__desc;

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

MetaModelica::Value to_mm_function(Restriction res) noexcept
{
  if (res.is(Restriction::Prefix::External)) {
    return MetaModelica::Record{FR_EXTERNAL_FUNCTION,
      SCode_FunctionRestriction_FR__EXTERNAL__FUNCTION__desc, {res.purity().toAbsyn()}};
  } else if (res.is(Restriction::Prefix::Operator)) {
    return MetaModelica::Record{FR_OPERATOR_FUNCTION,
      SCode_FunctionRestriction_FR__OPERATOR__FUNCTION__desc};
  } else if (res.is(Restriction::Prefix::Constructor)) {
    return MetaModelica::Record{FR_RECORD_CONSTRUCTOR,
      SCode_FunctionRestriction_FR__RECORD__CONSTRUCTOR__desc};
  } else if (res.is(Restriction::Prefix::Parallel)) {
    return MetaModelica::Record{FR_PARALLEL_FUNCTION,
      SCode_FunctionRestriction_FR__PARALLEL__FUNCTION__desc};
  } else if (res.is(Restriction::Prefix::Kernel)) {
    return MetaModelica::Record{FR_KERNEL_FUNCTION,
      SCode_FunctionRestriction_FR__KERNEL__FUNCTION__desc};
  }

  return MetaModelica::Record{FR_NORMAL_FUNCTION,
    SCode_FunctionRestriction_FR__NORMAL__FUNCTION__desc, {res.purity().toAbsyn()}};
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

MetaModelica::Value Restriction::toSCode() const noexcept
{
  switch (kind()) {
    case Kind::Class:
      return MetaModelica::Record(R_CLASS, SCode_Restriction_R__CLASS__desc);
    case Kind::Model:
      return MetaModelica::Record(R_MODEL, SCode_Restriction_R__MODEL__desc);
    case Kind::Package:
      return MetaModelica::Record(R_PACKAGE, SCode_Restriction_R__PACKAGE__desc);
    case Kind::Block:
      return MetaModelica::Record(R_BLOCK, SCode_Restriction_R__BLOCK__desc);
    case Kind::Optimization:
      return MetaModelica::Record(R_OPTIMIZATION, SCode_Restriction_R__OPTIMIZATION__desc);
    case Kind::Connector:
      return MetaModelica::Record(R_CONNECTOR, SCode_Restriction_R__CONNECTOR__desc, {
        MetaModelica::Value{is(Prefix::Expandable)}
      });
    case Kind::Type:
      return MetaModelica::Record(R_TYPE, SCode_Restriction_R__TYPE__desc);
    case Kind::Enumeration:
      return MetaModelica::Record(R_ENUMERATION, SCode_Restriction_R__ENUMERATION__desc);
    case Kind::Record:
      if (is(Prefix::Constructor)) {
        return MetaModelica::Record(R_FUNCTION, SCode_Restriction_R__FUNCTION__desc, {
          to_mm_function(Prefix::Constructor)
        });
      } else {
        return MetaModelica::Record(R_RECORD, SCode_Restriction_R__RECORD__desc, {
          MetaModelica::Value{is(Prefix::Operator)}
        });
      }
    case Kind::Operator:
      return MetaModelica::Record(R_OPERATOR, SCode_Restriction_R__OPERATOR__desc);
    case Kind::Function:
      return MetaModelica::Record(R_FUNCTION, SCode_Restriction_R__FUNCTION__desc, {
        to_mm_function(*this)
      });
    default:
      return MetaModelica::Record(R_CLASS, SCode_Restriction_R__CLASS__desc);
  }
}

Restriction::Kind Restriction::kind() const noexcept
{
  return static_cast<Kind>(_value & 0x0000FFFF);
}

Purity Restriction::purity() const noexcept
{
  if (is(Prefix::Pure)) {
    return Purity::Pure;
  } else if (is(Prefix::Impure)) {
    return Purity::Impure;
  }

  return Purity::None;
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
