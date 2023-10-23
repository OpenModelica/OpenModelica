#include <ostream>

#include "Prefixes.h"

using namespace OpenModelica;

constexpr int VAR = 0;
constexpr int DISCRETE = 1;
constexpr int PARAM = 2;
constexpr int CONST = 3;

constexpr int INNER = 0;
constexpr int OUTER = 1;
constexpr int INNER_OUTER = 2;

constexpr int PURE = 0;
constexpr int IMPURE = 1;

constexpr int FLOW = 1;
constexpr int STREAM = 2;

constexpr int PARGLOBAL = 0;
constexpr int PARLOCAL = 1;

constexpr int INPUT = 0;
constexpr int OUTPUT = 1;

constexpr int FIELD = 1;

Visibility::Visibility(MetaModelica::Record value) noexcept
  : _value{value.index() == 0 ? Value::Public : Value::Protected}
{
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

std::string_view Encapsulated::str() const noexcept
{
  return _value ? "encapsulated" : "";
}

std::string_view Encapsulated::unparse() const noexcept
{
  return _value ? "encapsulated " : "";
}

Partial::Partial(MetaModelica::Record value)
  : _value{value.index() == 0}
{

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

std::string_view Field::str() const noexcept
{
  return _value ? "field" : "";
}

std::string_view Field::unparse() const noexcept
{
  return _value ? "field " : "";
}
