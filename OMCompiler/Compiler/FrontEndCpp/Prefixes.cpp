#include <ostream>

#include "Prefixes.h"

using namespace OpenModelica;

extern record_description SCode_Visibility_PUBLIC__desc;
extern record_description SCode_Visibility_PROTECTED__desc;

constexpr int VAR = 0;
constexpr int DISCRETE = 1;
constexpr int PARAM = 2;
constexpr int CONST = 3;

extern record_description SCode_Variability_VAR__desc;
extern record_description SCode_Variability_DISCRETE__desc;
extern record_description SCode_Variability_PARAM__desc;
extern record_description SCode_Variability_CONST__desc;

constexpr int FINAL = 0;
constexpr int NOT_FINAL = 1;

extern record_description SCode_Final_FINAL__desc;
extern record_description SCode_Final_NOT__FINAL__desc;

constexpr int EACH = 0;
constexpr int NOT_EACH = 1;

extern record_description SCode_Each_EACH__desc;
extern record_description SCode_Each_NOT__EACH__desc;

constexpr int INNER = 0;
constexpr int OUTER = 1;
constexpr int INNER_OUTER = 2;
constexpr int NOT_INNER_OUTER = 3;

extern record_description Absyn_InnerOuter_INNER__desc;
extern record_description Absyn_InnerOuter_OUTER__desc;
extern record_description Absyn_InnerOuter_INNER__OUTER__desc;
extern record_description Absyn_InnerOuter_NOT__INNER__OUTER__desc;

constexpr int REDECLARE = 0;
constexpr int NOT_REDECLARE = 1;

extern record_description SCode_Redeclare_REDECLARE__desc;
extern record_description SCode_Redeclare_NOT__REDECLARE__desc;

constexpr int ENCAPSULATED = 0;
constexpr int NOT_ENCAPSULATED = 1;

extern record_description SCode_Encapsulated_ENCAPSULATED__desc;
extern record_description SCode_Encapsulated_NOT__ENCAPSULATED__desc;

constexpr int PARTIAL = 0;
constexpr int NOT_PARTIAL = 1;

extern record_description SCode_Partial_PARTIAL__desc;
extern record_description SCode_Partial_NOT__PARTIAL__desc;

constexpr int PURE = 0;
constexpr int IMPURE = 1;
constexpr int NO_PURITY = 2;

extern record_description Absyn_FunctionPurity_PURE__desc;
extern record_description Absyn_FunctionPurity_IMPURE__desc;
extern record_description Absyn_FunctionPurity_NO__PURITY__desc;

constexpr int POTENTIAL = 0;
constexpr int FLOW = 1;
constexpr int STREAM = 2;

extern record_description SCode_ConnectorType_POTENTIAL__desc;
extern record_description SCode_ConnectorType_FLOW__desc;
extern record_description SCode_ConnectorType_STREAM__desc;

constexpr int PARGLOBAL = 0;
constexpr int PARLOCAL = 1;
constexpr int NON_PARALLEL = 2;

extern record_description SCode_Parallelism_PARGLOBAL__desc;
extern record_description SCode_Parallelism_PARLOCAL__desc;
extern record_description SCode_Parallelism_NON__PARALLEL__desc;

constexpr int INPUT = 0;
constexpr int OUTPUT = 1;
constexpr int BIDIR = 2;

extern record_description Absyn_Direction_INPUT__desc;
extern record_description Absyn_Direction_OUTPUT__desc;
extern record_description Absyn_Direction_BIDIR__desc;

constexpr int NONFIELD = 0;
constexpr int FIELD = 1;

extern record_description Absyn_IsField_NONFIELD__desc;
extern record_description Absyn_IsField_FIELD__desc;

Visibility::Visibility(MetaModelica::Record value) noexcept
  : _value{value.index() == 0 ? Value::Public : Value::Protected}
{
}

MetaModelica::Value Visibility::toSCode() const noexcept
{
  return MetaModelica::Record{static_cast<int>(_value),
    _value == Value::Public ? SCode_Visibility_PUBLIC__desc :
                              SCode_Visibility_PROTECTED__desc
  };
}

std::string_view Visibility::str() const noexcept
{
  return _value == Value::Public ? "public" : "protected";
}

std::string_view Visibility::unparse() const noexcept
{
  return _value == Value::Public ? "" : "protected ";
}

bool OpenModelica::operator== (Visibility vis1, Visibility vis2)
{
  return vis1.value() == vis2.value();
}

bool OpenModelica::operator!= (Visibility vis1, Visibility vis2)
{
  return vis1.value() != vis2.value();
}

std::ostream& OpenModelica::operator<< (std::ostream &os, Visibility visibility) noexcept
{
  os << visibility.str();
  return os;
}

Variability::Variability(MetaModelica::Record value) noexcept
{
  switch (value.index()) {
    case VAR:      _value = Value::Continuous; break;
    case DISCRETE: _value = Value::Discrete;   break;
    case PARAM:    _value = Value::Parameter;  break;
    case CONST:    _value = Value::Constant;   break;
    default:       _value = Value::Continuous; break;
  }
}

MetaModelica::Value Variability::toSCode() const noexcept
{
  switch (effective().value()) {
    case Value::Constant:  return MetaModelica::Record(CONST, SCode_Variability_CONST__desc);
    case Value::Parameter: return MetaModelica::Record(PARAM, SCode_Variability_PARAM__desc);
    case Value::Discrete:  return MetaModelica::Record(DISCRETE, SCode_Variability_DISCRETE__desc);
    default:               return MetaModelica::Record(VAR, SCode_Variability_VAR__desc);
  }
}

Variability Variability::effective() const noexcept
{
  switch (_value) {
    case Value::StructuralParameter:    return Value::Parameter;
    case Value::NonStructuralParameter: return Value::Parameter;
    case Value::ImplicitlyDiscrete:     return Value::Discrete;
    default:                            return _value;
  }
}

bool OpenModelica::operator== (Variability var1, Variability var2)
{
  return var1.value() == var2.value();
}

bool OpenModelica::operator!= (Variability var1, Variability var2)
{
  return var1.value() != var2.value();
}

bool OpenModelica::operator<  (Variability var1, Variability var2)
{
  return var1.value() < var2.value();
}

bool OpenModelica::operator<= (Variability var1, Variability var2)
{
  return var1.value() <= var2.value();
}

bool OpenModelica::operator>  (Variability var1, Variability var2)
{
  return var1.value() > var2.value();
}

bool OpenModelica::operator>= (Variability var1, Variability var2)
{
  return var1.value() >= var2.value();
}

std::string_view Variability::str() const noexcept
{
  switch (_value) {
    case Value::Constant:               return "constant";
    case Value::StructuralParameter:
    case Value::Parameter:
    case Value::NonStructuralParameter: return "parameter";
    case Value::Discrete:
    case Value::ImplicitlyDiscrete:     return "discrete";
    default:                            return "continuous";
  }
}

std::string_view Variability::unparse() const noexcept
{
  switch (_value) {
    case Value::Constant:               return "constant ";
    case Value::StructuralParameter:
    case Value::Parameter:
    case Value::NonStructuralParameter: return "parameter ";
    case Value::Discrete:               return "discrete ";
    default:                            return "";
  }
}

Final::Final(MetaModelica::Record value)
  : _value{value.index() == 0}
{

}

MetaModelica::Value Final::toSCode() const noexcept
{
  return isFinal() ?
    MetaModelica::Record(FINAL, SCode_Final_FINAL__desc) :
    MetaModelica::Record(NOT_FINAL, SCode_Final_NOT__FINAL__desc);
}

std::string_view Final::str() const noexcept
{
  return _value ? "final" : "";
}

std::string_view Final::unparse() const noexcept
{
  return _value ? "final " : "";
}

Each::Each(MetaModelica::Record value)
  : _value{value.index() == 0}
{

}

MetaModelica::Value Each::toSCode() const noexcept
{
  return isEach() ?
    MetaModelica::Record(EACH, SCode_Each_EACH__desc) :
    MetaModelica::Record(NOT_EACH, SCode_Each_NOT__EACH__desc);
}

std::string_view Each::str() const noexcept
{
  return _value ? "each" : "";
}

std::string_view Each::unparse() const noexcept
{
  return _value ? "each " : "";
}

InnerOuter::InnerOuter(MetaModelica::Record value)
{
  switch (value.index()) {
    case INNER:       _value = Value::Inner; break;
    case OUTER:       _value = Value::Outer; break;
    case INNER_OUTER: _value = Value::Both;  break;
    default:          _value = Value::None;  break;
  }
}

MetaModelica::Value InnerOuter::toAbsyn() const noexcept
{
  switch (_value) {
    case Inner: return MetaModelica::Record(INNER, Absyn_InnerOuter_INNER__desc);
    case Outer: return MetaModelica::Record(OUTER, Absyn_InnerOuter_OUTER__desc);
    case Both:  return MetaModelica::Record(INNER_OUTER, Absyn_InnerOuter_INNER__OUTER__desc);
    default:    return MetaModelica::Record(NOT_INNER_OUTER, Absyn_InnerOuter_NOT__INNER__OUTER__desc);
  }
}

bool OpenModelica::operator== (InnerOuter io1, InnerOuter io2) noexcept
{
  return io1._value == io2._value;
}

bool OpenModelica::operator!= (InnerOuter io1, InnerOuter io2) noexcept
{
  return io1._value != io2._value;
}

std::string_view InnerOuter::str() const noexcept
{
  switch (_value) {
    case Value::Inner: return "inner";
    case Value::Outer: return "outer";
    case Value::Both:  return "inner outer";
    default:           return "";
  }
}

std::string_view InnerOuter::unparse() const noexcept
{
  switch (_value) {
    case Value::Inner: return "inner ";
    case Value::Outer: return "outer ";
    case Value::Both:  return "inner outer ";
    default:           return "";
  }
}

Redeclare::Redeclare(MetaModelica::Record value)
  : _value{value.index() == 0}
{

}

MetaModelica::Value Redeclare::toSCode() const noexcept
{
  return isRedeclare() ?
    MetaModelica::Record(REDECLARE, SCode_Redeclare_REDECLARE__desc) :
    MetaModelica::Record(NOT_REDECLARE, SCode_Redeclare_NOT__REDECLARE__desc);
}

std::string_view Redeclare::str() const noexcept
{
  return _value ? "redeclare" : "";
}

std::string_view Redeclare::unparse() const noexcept
{
  return _value ? "redeclare " : "";
}

Encapsulated::Encapsulated(MetaModelica::Record value)
  : _value{value.index() == 0}
{

}

MetaModelica::Value Encapsulated::toSCode() const noexcept
{
  return isEncapsulated() ?
    MetaModelica::Record(ENCAPSULATED, SCode_Encapsulated_ENCAPSULATED__desc) :
    MetaModelica::Record(NOT_ENCAPSULATED, SCode_Encapsulated_NOT__ENCAPSULATED__desc);
}

std::string_view Encapsulated::str() const noexcept
{
  return _value ? "encapsulated" : "";
}

std::string_view Encapsulated::unparse() const noexcept
{
  return _value ? "encapsulated " : "";
}

Partial::Partial(MetaModelica::Record value)
  : _value{value.index() == PARTIAL}
{

}

MetaModelica::Value Partial::toSCode() const noexcept
{
  return isPartial() ?
    MetaModelica::Record(PARTIAL, SCode_Partial_PARTIAL__desc) :
    MetaModelica::Record(NOT_PARTIAL, SCode_Partial_NOT__PARTIAL__desc);
}

std::string_view Partial::str() const noexcept
{
  return _value ? "partial" : "";
}

std::string_view Partial::unparse() const noexcept
{
  return _value ? "partial " : "";
}

Purity::Value purity_from_mm(MetaModelica::Record value)
{
  switch (value.index()) {
    case PURE:   return Purity::Pure;
    case IMPURE: return Purity::Impure;
  }

  return Purity::None;
}

Purity::Purity(MetaModelica::Record value)
  : _value{purity_from_mm(value)}
{

}

MetaModelica::Value Purity::toAbsyn() const noexcept
{
  switch (_value) {
    case Value::Pure:   return MetaModelica::Record(PURE, Absyn_FunctionPurity_PURE__desc);
    case Value::Impure: return MetaModelica::Record(IMPURE, Absyn_FunctionPurity_IMPURE__desc);
    default:            return MetaModelica::Record(NO_PURITY, Absyn_FunctionPurity_NO__PURITY__desc);
  }
}

std::string_view Purity::str() const noexcept
{
  switch (_value) {
    case Value::Pure:   return "pure";
    case Value::Impure: return "impure";
    default:            return "";
  }
}

std::string_view Purity::unparse() const noexcept
{
  switch (_value) {
    case Value::Pure:   return "pure ";
    case Value::Impure: return "impure ";
    default:            return "";
  }
}

bool OpenModelica::operator== (Purity pur1, Purity pur2) noexcept
{
  return pur1.value() == pur2.value();
}

bool OpenModelica::operator!= (Purity pur1, Purity pur2) noexcept
{
  return pur1.value() != pur2.value();
}

bool OpenModelica::operator< (Purity pur1, Purity pur2) noexcept
{
  return pur1 == Purity::Impure && pur2 != Purity::Impure;
}

ConnectorType::Value connector_from_mm(MetaModelica::Record value)
{
  switch (value.index()) {
    case FLOW:      return ConnectorType::Flow;
    case STREAM:    return ConnectorType::Stream;
    default:        return ConnectorType::None;
  }
}

ConnectorType::ConnectorType(MetaModelica::Record value)
  : _value{connector_from_mm(value)}
{

}

MetaModelica::Value ConnectorType::toSCode() const noexcept
{
  if (isFlow()) {
    return MetaModelica::Record(FLOW, SCode_ConnectorType_FLOW__desc);
  } else if (isStream()) {
    return MetaModelica::Record(STREAM, SCode_ConnectorType_STREAM__desc);
  }

  return MetaModelica::Record(POTENTIAL, SCode_ConnectorType_POTENTIAL__desc);
}

bool ConnectorType::isPotential() const noexcept
{
  return _value & Value::Potential;
}

bool ConnectorType::isFlow() const noexcept
{
  return _value & Value::Flow;
}

bool ConnectorType::isStream() const noexcept
{
  return _value & Value::Stream;
}

bool ConnectorType::isFlowOrStream() const noexcept
{
  return _value & (Value::Flow | Value::Stream);
}

// Returns true if the connector type has the connector bit set, otherwise false.
bool ConnectorType::isConnector() const noexcept
{
  return _value & Value::Connector;
}

// Returns true if the connector type has the connector, expandable, or
// potentially present bits set, otherwise false.
bool ConnectorType::isConnectorType() const noexcept
{
  return _value & (Value::Connector | Value::Expandable | Value::PotentiallyPresent);
}

bool ConnectorType::isExpandable() const noexcept
{
  return _value & Value::Expandable;
}

// Returns true if the connector type has the potentially present or virtual
// bits set, otherwise false.
bool ConnectorType::isUndeclared() const noexcept
{
  return _value & (Value::Virtual | Value::PotentiallyPresent);
}

bool ConnectorType::isVirtual() const noexcept
{
  return _value & Value::Virtual;
}

bool ConnectorType::isPotentiallyPresent() const noexcept
{
  return _value & Value::PotentiallyPresent;
}

std::optional<ConnectorType> ConnectorType::merge(ConnectorType outer, ConnectorType inner) noexcept
{
  // Merging flow/stream with flow/stream is not allowed.
  if (outer.isFlowOrStream() && inner.isFlowOrStream()) return std::nullopt;

  return static_cast<Value>(outer._value | inner._value);
}

std::string_view ConnectorType::str() const noexcept
{
  if (_value & Value::Flow) {
    return "flow";
  } else if (_value & Value::Stream) {
    return "stream";
  } else if (_value & Value::Expandable) {
    return "expandable";
  } else {
    return "";
  }
}

constexpr auto connectorTypeNames = std::array{
  "potential",
  "flow",
  "stream",
  "potentially present",
  "virtual",
  "connector",
  "expandable"
};

std::string ConnectorType::debugStr() const noexcept
{
  std::string str;

  for (auto i = 0u; i < connectorTypeNames.size(); ++i) {
    if (_value & (1 << i)) {
      if (!str.empty()) {
        str += " ";
      }
      str += connectorTypeNames[i];
    }
  }

  return str;
}

std::string_view ConnectorType::unparse() const noexcept
{
  if (_value & Value::Flow) {
    return "flow ";
  } else if (_value & Value::Stream) {
    return "stream ";
  } else if (_value & Value::Expandable) {
    return "expandable ";
  } else {
    return "";
  }
}

Parallelism::Value parallelism_from_mm(MetaModelica::Record value)
{
  switch (value.index()) {
    case PARGLOBAL: return Parallelism::Global;
    case PARLOCAL:  return Parallelism::Local;
    default:        return Parallelism::None;
  }
}

Parallelism::Parallelism(MetaModelica::Record value)
  : _value{parallelism_from_mm(value)}
{

}

MetaModelica::Value Parallelism::toSCode() const noexcept
{
  switch (_value) {
    case Value::Global:
      return MetaModelica::Record(PARGLOBAL, SCode_Parallelism_PARGLOBAL__desc);
    case Value::Local:
      return MetaModelica::Record(PARLOCAL, SCode_Parallelism_PARLOCAL__desc);
    default:
      return MetaModelica::Record(NON_PARALLEL, SCode_Parallelism_NON__PARALLEL__desc);
  }
}

std::string_view Parallelism::str() const noexcept
{
  switch (_value) {
    case Value::Global: return "parglobal";
    case Value::Local:  return "parlocal";
    default:            return "";
  }
}

std::string_view Parallelism::unparse() const noexcept
{
  switch (_value) {
    case Value::Global: return "parglobal ";
    case Value::Local:  return "parlocal ";
    default:            return "";
  }
}

bool OpenModelica::operator== (Parallelism par1, Parallelism par2) noexcept
{
  return par1.value() == par2.value();
}

bool OpenModelica::operator!= (Parallelism par1, Parallelism par2) noexcept
{
  return par1.value() != par2.value();
}

Direction::Value direction_from_mm(MetaModelica::Record value)
{
  switch (value.index()) {
    case INPUT:  return Direction::Input;
    case OUTPUT: return Direction::Output;
    default:     return Direction::None;
  }
}

Direction::Direction(MetaModelica::Record value)
  : _value{direction_from_mm(value)}
{

}

MetaModelica::Value Direction::toAbsyn() const noexcept
{
  switch (_value) {
    case Value::Input:  return MetaModelica::Record(INPUT, Absyn_Direction_INPUT__desc);
    case Value::Output: return MetaModelica::Record(OUTPUT, Absyn_Direction_OUTPUT__desc);
    default:            return MetaModelica::Record(BIDIR, Absyn_Direction_BIDIR__desc);
  }
}

std::string_view Direction::str() const noexcept
{
  switch (_value) {
    case Value::Input:  return "input";
    case Value::Output: return "output";
    default:            return "";
  }
}

std::string_view Direction::unparse() const noexcept
{
  switch (_value) {
    case Value::Input:  return "input ";
    case Value::Output: return "output ";
    default:            return "";
  }
}

std::optional<Direction> Direction::merge(Direction outer, Direction inner, bool allowSame)
{
  if (outer == Direction::None) {
    return inner;
  } else if (inner == Direction::None) {
    return outer;
  } else if (allowSame && outer == inner) {
    return inner;
  }

  return std::nullopt;
}

bool OpenModelica::operator== (Direction dir1, Direction dir2) noexcept
{
  return dir1.value() == dir2.value();
}

bool OpenModelica::operator!= (Direction dir1, Direction dir2) noexcept
{
  return dir1.value() != dir2.value();
}

Field::Field(MetaModelica::Record value)
  : _value{value.index() == FIELD}
{

}

MetaModelica::Value Field::toAbsyn() const noexcept
{
  return _value ?
    MetaModelica::Record(FIELD, Absyn_IsField_FIELD__desc) :
    MetaModelica::Record(NONFIELD, Absyn_IsField_NONFIELD__desc);
}

std::string_view Field::str() const noexcept
{
  return _value ? "field" : "";
}

std::string_view Field::unparse() const noexcept
{
  return _value ? "field " : "";
}
