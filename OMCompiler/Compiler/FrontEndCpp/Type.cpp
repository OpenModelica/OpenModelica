#include <algorithm>
#include <utility>

#include "Type.h"

using namespace OpenModelica;

Type::Type(Kind kind)
  : _kind(kind)
{

}

Type::Type(const Type &other)
  : _kind{other._kind}, _dims{other._dims},
    _data{other._data ? other._data->clone() : nullptr}
{

}

Type::Type(Type &&other) = default;

Type& Type::operator= (Type other)
{
  swap(*this, other);
  return *this;
}

Type& Type::operator= (Type &&other) = default;

namespace OpenModelica
{
  void swap(Type &first, Type &second) noexcept
  {
    using std::swap;
    swap(first._kind, second._kind);
    swap(first._dims, second._dims);
    swap(first._data, second._data);
  }
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
  return !_dims.empty() || (_data && _data->isArray());
}

bool Type::isConditionalArray() const
{
  return _data && _data->isArray();
}

bool Type::isVector() const
{
  return _dims.size() == 1;
}

bool Type::isMatrix() const
{
  return _dims.size() == 2;
}

bool Type::isSquareMatrix() const
{
  return _dims.size() == 2 && _dims[0] == _dims[1];
}

bool Type::isEmptyArray() const
{
  return std::any_of(std::begin(_dims), std::end(_dims),
    [] (const Dimension &dim) { return dim.isZero(); });
}

bool Type::isSingleElementArray() const
{
  return _dims.size() == 1 && _dims[0].isKnown() && _dims[0].size() == 1;
}

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

//ArrayType::ArrayType(const Type &type, Dimension dimension)
//  : _elementType(std::make_unique<Type>(type.elementType()))
//{
//  auto ty_dims = type.arrayDims();
//  _dimensions.reserve(ty_dims.size() + 1);
//  _dimensions.emplace_back(dimension);
//  _dimensions.insert(_dimensions.end(), ty_dims.begin(), ty_dims.end());
//}
//
//ArrayType::ArrayType(const Type &type, tcb::span<const Dimension> dimensions)
//  : _elementType(std::make_unique<Type>(type.elementType()))
//{
//  auto ty_dims = type.arrayDims();
//  _dimensions.reserve(ty_dims.size() + dimensions.size());
//  _dimensions.insert(_dimensions.end(), dimensions.begin(), dimensions.end());
//  _dimensions.insert(_dimensions.end(), ty_dims.begin(), ty_dims.end());
//}
//
//ArrayType::ArrayType(std::unique_ptr<Type> type, std::vector<Dimension> dimensions)
//  : _elementType(std::move(type)), _dimensions(std::move(dimensions))
//{
//
//}
//
//bool ArrayType::isSquareMatrix() const
//{
//  return _dimensions.size() == 2 && Dimension::isEqualKnown(_dimensions[0], _dimensions[1]);
//}
//
//bool ArrayType::isEmptyArray() const
//{
//  return std::any_of(_dimensions.begin(), _dimensions.end(),
//    [] (const auto& dim) { return dim.isZero(); });
//}
//
//bool ArrayType::isSingleElementArray() const
//{
//  return _dimensions.size() == 1 && _dimensions[0].isKnown() && _dimensions[0].size() == 1;
//}
//
//std::unique_ptr<Type> ArrayType::unliftArray(size_t n) const
//{
//  if (n == 0) {
//    return std::make_unique<Type>(*this);
//  } else if (_dimensions.size() < n || n < 0) {
//    return nullptr;
//  } else if (_dimensions.size() == n) {
//    return std::make_unique<Type>(*_elementType);
//  }
//
//  return std::make_unique<ArrayType>(*_elementType, tcb::span(_dimensions).last(_dimensions.size() - n));
//}
