/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <sstream>
#include <algorithm>
#include <utility>
#include <stdexcept>
#include <cassert>

#include "Util.h"
#include "InstNode.h"
#include "ComplexType.h"
#include "Type.h"

using namespace OpenModelica;

constexpr int INTEGER = 0;
constexpr int REAL = 1;
constexpr int STRING = 2;
constexpr int BOOLEAN = 3;
constexpr int CLOCK = 4;
constexpr int ENUMERATION = 5;
constexpr int ARRAY = 7;
constexpr int TUPLE = 8;
constexpr int NORETCALL = 9;
constexpr int UNKNOWN = 10;
constexpr int COMPLEX = 11;
constexpr int FUNCTION = 12;
constexpr int METABOXED = 13;
constexpr int POLYMORPHIC = 14;
constexpr int ANY = 15;
constexpr int CONDITIONAL_ARRAY = 16;
constexpr int UNTYPED = 17;

extern record_description NFType_INTEGER__desc;
extern record_description NFType_REAL__desc;
extern record_description NFType_STRING__desc;
extern record_description NFType_BOOLEAN__desc;
extern record_description NFType_CLOCK__desc;
extern record_description NFType_ENUMERATION__desc;
extern record_description NFType_ARRAY__desc;
extern record_description NFType_TUPLE__desc;
extern record_description NFType_NORETCALL__desc;
extern record_description NFType_UNKNOWN__desc;
extern record_description NFType_COMPLEX__desc;
extern record_description NFType_FUNCTION__desc;
extern record_description NFType_METABOXED__desc;
extern record_description NFType_POLYMORPHIC__desc;
extern record_description NFType_ANY__desc;
extern record_description NFType_CONDITIONAL__ARRAY__desc;
extern record_description NFType_UNTYPED__desc;

const Type Type::UnknownType = Type::Unknown;

Type::Kind kind_from_mm(MetaModelica::Record value)
{
  switch (value.index()) {
    case INTEGER:           return Type::Kind::Integer;
    case REAL:              return Type::Kind::Real;
    case STRING:            return Type::Kind::String;
    case BOOLEAN:           return Type::Kind::Boolean;
    case CLOCK:             return Type::Kind::Clock;
    case ENUMERATION:       return Type::Kind::Enumeration;
    case ARRAY:             return kind_from_mm(value[0]);
    case TUPLE:             return Type::Kind::Tuple;
    case NORETCALL:         return Type::Kind::NoRetCall;
    case UNKNOWN:           return Type::Kind::Unknown;
    case COMPLEX:           return Type::Kind::Complex;
    case FUNCTION:          return Type::Kind::Function;
    case METABOXED:         return Type::Kind::MetaBoxed;
    case POLYMORPHIC:       return Type::Kind::Polymorphic;
    case ANY:               return Type::Kind::Any;
    case CONDITIONAL_ARRAY: return Type::Kind::ConditionalArray;
    case UNTYPED:           return Type::Kind::Untyped;
  }

  throw std::runtime_error("Unknown record index in kind_from_mm");
}

int kind_to_mm(Type::Kind kind)
{
  switch (kind) {
    case Type::Integer:          return INTEGER;
    case Type::Real:             return REAL;
    case Type::String:           return STRING;
    case Type::Boolean:          return BOOLEAN;
    case Type::Clock:            return CLOCK;
    case Type::NoRetCall:        return NORETCALL;
    case Type::Unknown:          return UNKNOWN;
    case Type::Any:              return ANY;
    case Type::Enumeration:      return ENUMERATION;
    case Type::Tuple:            return TUPLE;
    case Type::Complex:          return COMPLEX;
    case Type::Function:         return FUNCTION;
    case Type::MetaBoxed:        return METABOXED;
    case Type::Polymorphic:      return POLYMORPHIC;
    case Type::ConditionalArray: return CONDITIONAL_ARRAY;
    case Type::Untyped:          return UNTYPED;
  }

  throw std::runtime_error("Unknown kind of type in kind_to_mm");
}

std::vector<Dimension> dims_from_mm(MetaModelica::Record value)
{
  return value.index() == ARRAY ? value[1].mapVector<Dimension>() : std::vector<Dimension>{};
}

std::unique_ptr<TypeData> type_data_from_mm(MetaModelica::Record value)
{
  switch (value.index()) {
    case ENUMERATION:       return std::make_unique<EnumerationTypeData>(value);
    case ARRAY:             return type_data_from_mm(value[0]);
    case TUPLE:             return std::make_unique<TupleTypeData>(value);
    case COMPLEX:           return std::make_unique<ComplexTypeData>(value);
    case POLYMORPHIC:       return std::make_unique<PolymorphicTypeData>(value);
    case CONDITIONAL_ARRAY: return std::make_unique<ConditionalArrayData>(value);
    default: return nullptr;
  }
}

Type::Type(Kind kind)
  : _kind{kind}
{

}

Type::Type(MetaModelica::Record value)
  : _kind{kind_from_mm(value)}, _dims{dims_from_mm(value)}, _data{type_data_from_mm(value)}
{

}

Type::Type(const Type &other)
  : _kind{other._kind}, _dims{other._dims},
    _data{other._data ? other._data->clone() : nullptr}
{

}

Type::Type(Type &&other) noexcept = default;

Type& Type::operator= (Type other)
{
  swap(*this, other);
  return *this;
}

void OpenModelica::swap(Type &first, Type &second) noexcept
{
  using std::swap;
  swap(first._kind, second._kind);
  swap(first._dims, second._dims);
  swap(first._data, second._data);
}

Type::operator MetaModelica::Value() const
{
  MetaModelica::Value v;

  switch (_kind) {
    case Integer:
      v = MetaModelica::Record{INTEGER, NFType_INTEGER__desc};
      break;

    case Real:
      v = MetaModelica::Record{REAL, NFType_REAL__desc};
      break;

    case String:
      v = MetaModelica::Record{STRING, NFType_STRING__desc};
      break;

    case Boolean:
      v = MetaModelica::Record{BOOLEAN, NFType_BOOLEAN__desc};
      break;

    case Clock:
      v = MetaModelica::Record{CLOCK, NFType_CLOCK__desc};
      break;

    case NoRetCall:
      v = MetaModelica::Record{NORETCALL, NFType_NORETCALL__desc};
      break;

    case Unknown:
      v = MetaModelica::Record{UNKNOWN, NFType_UNKNOWN__desc};
      break;

    case Any:
      v = MetaModelica::Record{ANY, NFType_ANY__desc};
      break;

    default:
      assert(_data);
      v = _data->toNF(kind_to_mm(_kind));
      break;
  }

  return v;
}

bool Type::isInteger() const
{
  return _kind == Integer;
}

bool Type::isReal() const
{
  return _kind == Real;
}

bool Type::isBoolean() const
{
  return _kind == Boolean;
}

bool Type::isString() const
{
  return _kind == String;
}

bool Type::isClock() const
{
  return _kind == Clock;
}

bool Type::isEnumeration() const
{
  return _kind == Enumeration;
}

bool Type::isScalar() const
{
  return _dims.empty() || (_data && _data->isScalar());
}

bool Type::isBasic() const
{
  return _kind <= Clock || (_data && _data->isBasic());
}

bool Type::isBasicNumeric() const
{
  return _kind <= Real;
}

bool Type::isNumeric() const
{
  return isBasicNumeric() || (_data && _data->isNumeric());
}

bool Type::isScalarBuiltin() const
{
  return (isBasic() && isScalar()) || (_data && _data->isScalarBuiltin());
}

bool Type::isDiscrete() const
{
  return _kind <= Enumeration || (_data && _data->isScalarBuiltin());
}

bool Type::isArray() const
{
  return !_dims.empty() || (_data && !_data->isScalar());
}

bool Type::isConditionalArray() const
{
  return dynamic_cast<ConditionalArrayData*>(_data.get());
}

bool Type::isVector() const
{
  return _dims.size() == 1;
}

bool Type::isMatrix() const
{
  return _dims.size() == 2;
}

//bool Type::isSquareMatrix() const
//{
//  return _dims.size() == 2 && _dims[0] == _dims[1];
//}

//bool Type::isEmptyArray() const
//{
//  return std::any_of(std::begin(_dims), std::end(_dims),
//    [] (const Dimension &dim) { return dim.isZero(); });
//}

//bool Type::isSingleElementArray() const
//{
//  return _dims.size() == 1 && _dims[0].isKnown() && _dims[0].size() == 1;
//}

bool Type::isComplex() const
{
  return _kind == Complex;
}

bool Type::isConnector() const
{
  return _data && _data->isConnector();
}

bool Type::isExpandableConnector() const
{
  return _data && _data->isExpandableConnector();
}

bool Type::isExternalObject() const
{
  return _data && _data->isExternalObject();
}

bool Type::isRecord() const
{
  return _data && _data->isRecord();
}

bool Type::isTuple() const
{
  return _kind == Tuple;
}

bool Type::isUnknown() const
{
  return _kind == Unknown;
}

bool Type::isKnown() const
{
  return !isUnknown();
}

bool Type::isPolymorphic() const
{
  return _data && _data->isPolymorphic();
}

bool Type::isPolymorphicNamed(std::string_view name) const
{
  return _data && _data->isPolymorphicNamed(name);
}

Type Type::elementType()
{
  if (!_data) return _kind;

  throw std::runtime_error("TODO: implement Type::elementType");
}

std::string Type::str() const
{
  std::ostringstream ss;
  ss << *this;
  return ss.str();
}

std::ostream& OpenModelica::operator<< (std::ostream &os, const Type &ty)
{
  switch (ty._kind) {
    case Type::Integer: os << "Integer"; break;
    case Type::Real: os << "Real"; break;
    case Type::String: os << "String"; break;
    case Type::Boolean: os << "Boolean"; break;
    case Type::Clock: os << "Clock"; break;
    case Type::NoRetCall: os << "()"; break;
    case Type::Unknown: os << "unknown()"; break;
    case Type::Any: os << "$ANY$"; break;
    default: if (ty._data) os << ty._data->str();
  }

  if (!ty._dims.empty()) {
    os << '[' << Util::printList(ty._dims) << ']';
  }

  return os;
}

EnumerationTypeData::EnumerationTypeData(Path typePath, std::vector<std::string> literals)
  : _typePath{std::move(typePath)}, _literals{std::move(literals)}
{

}

EnumerationTypeData::EnumerationTypeData(MetaModelica::Record value)
  : _typePath{value[0]}, _literals{value[1].toVector<std::string>()}
{

}

std::unique_ptr<TypeData> EnumerationTypeData::clone() const
{
  return std::make_unique<EnumerationTypeData>(_typePath, _literals);
}

MetaModelica::Value EnumerationTypeData::toNF(int index) const
{
  assert(index == ENUMERATION);
  return MetaModelica::Record{ENUMERATION, NFType_ENUMERATION__desc, {
    _typePath.toAbsyn(),
    MetaModelica::List{_literals}
  }};
}

std::string EnumerationTypeData::str() const
{
  std::ostringstream ss;
  ss << "enumeration";

  if (_literals.empty()) {
    ss << "(:)";
  } else {
    ss << ' ' << _typePath << '(' << Util::printList(_literals) << ')';
  }

  return ss.str();
}

TupleTypeData::TupleTypeData(std::vector<Type> types, std::vector<std::string> names)
  : _types{std::move(types)}, _names{std::move(names)}
{

}

TupleTypeData::TupleTypeData(MetaModelica::Record value)
  : _types{value[0].mapVector<Type>()}, _names{value[1].toVector<std::string>()}
{

}

std::unique_ptr<TypeData> TupleTypeData::clone() const
{
  return std::make_unique<TupleTypeData>(_types, _names);
}

MetaModelica::Value TupleTypeData::toNF(int index) const
{
  assert(index == TUPLE);
  return MetaModelica::Record{TUPLE, NFType_TUPLE__desc, {

  }};
}

std::string TupleTypeData::str() const
{
  std::ostringstream ss;
  ss << '(' << Util::printList(_types) << ')';
  return ss.str();
}

ComplexTypeData::ComplexTypeData(InstNode *cls, std::unique_ptr<ComplexType> complexTy)
  : _cls{cls}, _complexTy{std::move(complexTy)}
{
  assert(cls);
}

ComplexTypeData::ComplexTypeData(MetaModelica::Record value)
  : _cls{InstNode::getReference(value[0])}, _complexTy{ComplexType::fromNF(value[1])}
{

}

std::unique_ptr<TypeData> ComplexTypeData::clone() const
{
  return std::make_unique<ComplexTypeData>(_cls, _complexTy ? _complexTy->clone() : nullptr);
}

MetaModelica::Value ComplexTypeData::toNF(int index) const
{
  assert(index == COMPLEX);
  return MetaModelica::Record{TUPLE, NFType_COMPLEX__desc, {
    _cls->toNF(),
    _complexTy->toNF()
  }};
}

bool ComplexTypeData::isConnector() const
{
  return dynamic_cast<const ConnectorComplexType*>(_complexTy.get());
}

bool ComplexTypeData::isExpandableConnector() const
{
  return dynamic_cast<const ExpandableConnectorComplexType*>(_complexTy.get());
}

bool ComplexTypeData::isExternalObject() const
{
  return dynamic_cast<const ExternalObjectComplexType*>(_complexTy.get());
}

bool ComplexTypeData::isRecord() const
{
  return dynamic_cast<const RecordComplexType*>(_complexTy.get());
}

std::string ComplexTypeData::str() const
{
  return _cls->name();
}

bool FunctionTypeData::isBasic() const
{
  // TODO: isBasic(Function.returnType(ty.fn))
  return false;
}

bool FunctionTypeData::isScalarBuiltin() const
{
  // TODO: isScalarBuiltin(Function.returnType(ty.fn))
  return false;
}

PolymorphicTypeData::PolymorphicTypeData(std::string name)
  : _name{std::move(name)}
{

}

PolymorphicTypeData::PolymorphicTypeData(MetaModelica::Record value)
  : _name{value[0].toString()}
{

}

std::unique_ptr<TypeData> PolymorphicTypeData::clone() const
{
  return std::make_unique<PolymorphicTypeData>(_name);
}

MetaModelica::Value PolymorphicTypeData::toNF(int index) const
{
  assert(index == POLYMORPHIC);
  return MetaModelica::Record{POLYMORPHIC, NFType_POLYMORPHIC__desc, {
    MetaModelica::Value{_name}
  }};
}

std::string PolymorphicTypeData::str() const
{
  if (_name.size() > 2 && _name[0] == '_' && _name[1] == '_') {
    return _name.substr(2);
  } else {
    return '<' + _name + '>';
  }
}

ConditionalArrayData::ConditionalArrayData(Type trueType, Type falseType, std::optional<bool> matchedBranch)
  : _trueType{std::move(trueType)}, _falseType{std::move(falseType)}, _matchedBranch{std::move(matchedBranch)}
{

}

ConditionalArrayData::ConditionalArrayData(MetaModelica::Record value)
  : _trueType{value[0]}, _falseType{value[1]}
{
  auto branch = value[2].toInt();
  if (branch > 1) {
    _matchedBranch = branch == 1;
  }
}

std::unique_ptr<TypeData> ConditionalArrayData::clone() const
{
  return std::make_unique<ConditionalArrayData>(_trueType, _falseType, _matchedBranch);
}

MetaModelica::Value ConditionalArrayData::toNF(int index) const
{
  assert(index == CONDITIONAL_ARRAY);
  return MetaModelica::Record{CONDITIONAL_ARRAY, NFType_CONDITIONAL__ARRAY__desc, {
    _trueType,
    _falseType,
    MetaModelica::Option{_matchedBranch}
  }};
}

std::string ConditionalArrayData::str() const
{
  std::ostringstream ss;
  ss << _trueType << '|' << _falseType;
  return ss.str();
}
