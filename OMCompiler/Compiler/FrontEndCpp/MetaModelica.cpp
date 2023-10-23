#include <cassert>
#include <stdexcept>
#include <ostream>

#include "meta/meta_modelica.h"
#include "MetaModelica.h"

using namespace OpenModelica::MetaModelica;

template<typename Container>
void print_list(Container container, std::ostream &os)
{
  bool first = true;

  for (auto e: container) {
    if (first) {
      first = false;
    } else {
      os << ", ";
    }

    os << e;
  }
}

void* get_index(void *data, size_t index)
{
  return MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(data), index + 1));
}

size_t get_slots(void *data)
{
  auto hdr = MMC_HDR_UNMARK(MMC_GETHDR(data));
  return MMC_HDRSLOTS(hdr);
}

int get_ctor(void *data)
{
  return MMC_HDRCTOR(MMC_HDR_UNMARK(MMC_GETHDR(data)));
}

Value::Value(void *value) noexcept
  : _value{value}
{
}

Value::Type Value::getType() const noexcept
{
  if (MMC_IS_INTEGER(_value)) {
    return Type::integer;
  }

  auto hdr = MMC_HDR_UNMARK(MMC_GETHDR(_value));

  if (hdr == MMC_NILHDR) {
    return Type::list; // Empty list
  }

  if (hdr == MMC_REALHDR) {
    return Type::real;
  }

  if (MMC_HDRISSTRING(hdr)) {
    return Type::string;
  }

  auto slots = MMC_HDRSLOTS(hdr);
  auto ctor = MMC_HDRCTOR(hdr);

  if (ctor == MMC_ARRAY_TAG) {
    return Type::array;
  }

  if (slots > 0 && ctor > 1) {
    return Type::record;
  }

  if (slots > 0 && ctor == 0) {
    return Type::tuple;
  }

  if (slots == 0 && ctor == 1) {
    return Type::option; // NONE()
  }

  if (slots == 1 && ctor == 1) {
    return Type::option; // SOME()
  }

  if (slots == 2 && ctor == 1) {
    return Type::list;
  }

  return Type::unknown;
}

bool Value::isInteger() const noexcept
{
  return MMC_IS_INTEGER(_value);
}

bool Value::isReal() const noexcept
{
  return getType() == Type::real;
}

bool Value::isBoolean() const noexcept
{
  // MetaModelica doesn't have a specific internal representation for Boolean,
  // instead we consider an integer of value 0 or 1 to be a Boolean.
  if (isInteger()) {
    auto v = toInt();
    return v == 0 || v == 1;
  }

  return false;
}

bool Value::isString() const noexcept
{
  return getType() == Type::string;
}

bool Value::isOption() const noexcept
{
  return getType() == Type::option;
}

bool Value::isList() const noexcept
{
  return getType() == Type::list;
}

bool Value::isArray() const noexcept
{
  return getType() == Type::array;
}

bool Value::isTuple() const noexcept
{
  return getType() == Type::tuple;
}

bool Value::isRecord() const noexcept
{
  return getType() == Type::record;
}

int64_t Value::toInt() const
{
  if (!isInteger()) {
    throw std::runtime_error("Value::toInt(): expected Integer, got " + name());
  }
  return static_cast<int64_t>(MMC_UNTAGFIXNUM(_value));
}

double Value::toDouble() const
{
  if (!isReal()) {
    throw std::runtime_error("Value::toDouble(): expected Real, got " + name());
  }

  return mmc_prim_get_real(_value);
}

bool Value::toBool() const
{
  if (!isBoolean()) {
    throw std::runtime_error("Value::toBool(): expected Boolean, got " + name());
  }

  return toInt() == 0 ? false : true;
}

std::string Value::toString() const
{
  if (!isString()) {
    throw std::runtime_error("Value::toString(): expected String, got " + name());
  }

  return MMC_STRINGDATA(_value);
}

Option Value::toOption() const
{
  if (!isOption()) {
    throw std::runtime_error("Value::toOption(): expected Option, got " + name());
  }

  return _value;
}

List Value::toList() const
{
  if (!isList()) {
    throw std::runtime_error("Value::toList(): expected list, got " + name());
  }

  return _value;
}

Array Value::toArray() const
{
  if (!isArray()) {
    throw std::runtime_error("Value::toArray(): expected array, got " + name());
  }

  return _value;
}

Tuple Value::toTuple() const
{
  if (!isTuple()) {
    throw std::runtime_error("Value::toTuple(): expected tuple, got " + name());
  }

  return _value;
}

Record Value::toRecord() const
{
  if (!isRecord()) {
    throw std::runtime_error("Value::toRecord(): expected record, got " + name());
  }

  return _value;
}

Value::operator bool() const
{
  return toBool();
}

std::string Value::name() const noexcept
{
  switch (getType()) {
    case Value::Type::integer: return "Integer";
    case Value::Type::real:    return "Real";
    case Value::Type::string:  return "String";
    case Value::Type::option:  return "Option";
    case Value::Type::list:    return "List";
    case Value::Type::array:   return "array";
    case Value::Type::tuple:   return "tuple";
    case Value::Type::record:  return "uniontype " + toRecord().uniontypeName();
    default:                   return "unknown";
  }
}

void* Value::data() const noexcept
{
  return _value;
}

std::ostream& OpenModelica::MetaModelica::operator<< (std::ostream &os, Value value) noexcept
{
  switch (value.getType()) {
    case Value::Type::integer: os << value.toInt();                  break;
    case Value::Type::real:    os << value.toDouble();               break;
    case Value::Type::string:  os << '"' << value.toString() << '"'; break;
    case Value::Type::option:  os << value.toOption();               break;
    case Value::Type::list:    os << value.toList();                 break;
    case Value::Type::array:   os << value.toArray();                break;
    case Value::Type::tuple:   os << value.toTuple();                break;
    case Value::Type::record:  os << value.toRecord();               break;
    default:                   os << "UNKNOWN";                      break;
  }

  return os;
}

Option::Option(void *value) noexcept
  : _value{value}
{

}

Value Option::operator*() const noexcept
{
  return value();
}

Value::ArrowProxy Option::operator->() const noexcept
{
  assert(hasValue());
  return get_index(_value, 0);
}

Option::operator bool() const noexcept
{
  return hasValue();
}

bool Option::hasValue() const noexcept
{
  return get_slots(_value) > 0;
}

Value Option::value() const
{
  assert(hasValue());
  return get_index(_value, 0);
}

std::ostream& OpenModelica::MetaModelica::operator<< (std::ostream &os, Option option) noexcept
{
  if (option) {
    os << "SOME(" << *option << ')';
  } else {
    os << "NONE()";
  }

  return os;
}

List::ConstIterator::ConstIterator(void *value) noexcept
  : _value{!value || MMC_NILTEST(value) ? nullptr : value}
{

}

List::ConstIterator::value_type List::ConstIterator::operator*() const noexcept
{
  return MMC_CAR(_value);
}

Value::ArrowProxy List::ConstIterator::operator->() const noexcept
{
  return MMC_CAR(_value);
}

List::ConstIterator& List::ConstIterator::operator++() noexcept
{
  _value = MMC_CDR(_value);
  if (MMC_NILTEST(_value)) _value = nullptr;
  return *this;
}

List::ConstIterator List::ConstIterator::operator++(int) noexcept
{
  List::ConstIterator it = *this;
  ++(*this);
  return it;
}

bool OpenModelica::MetaModelica::operator== (const List::ConstIterator &i1, const List::ConstIterator &i2) noexcept
{
  return i1._value == i2._value;
}

bool OpenModelica::MetaModelica::operator != (const List::ConstIterator &i1, const List::ConstIterator &i2) noexcept
{
  return i1._value != i2._value;
}

List::List(void *value) noexcept
  : _value{value}
{
}

Value List::front() const noexcept
{
  return MMC_CAR(_value);
}

List List::rest() const noexcept
{
  return MMC_CDR(_value);
}

List::ConstIterator List::begin() const noexcept
{
  return _value;
}

List::ConstIterator List::cbegin() const noexcept
{
  return _value;
}

List::ConstIterator List::end() const noexcept
{
  return nullptr;
}

List::ConstIterator List::cend() const noexcept
{
  return nullptr;
}

bool List::empty() const noexcept
{
  return MMC_NILTEST(_value);
}

size_t List::size() const noexcept
{
  return listLength(_value);
}

std::ostream& OpenModelica::MetaModelica::operator<< (std::ostream &os, List list) noexcept
{
  os << '{';
  print_list(list, os);
  os << '}';
  return os;
}

IndexedConstIterator::IndexedConstIterator(void *value, size_t index) noexcept
  : _value{value}, _index{index}
{

}

IndexedConstIterator::value_type IndexedConstIterator::operator*() const noexcept
{
  return get_index(_value, _index);
}

Value::ArrowProxy IndexedConstIterator::operator->() const noexcept
{
  return get_index(_value, _index);
}

IndexedConstIterator& IndexedConstIterator::operator++() noexcept
{
  ++_index;
  return *this;
}

IndexedConstIterator IndexedConstIterator::operator++(int) noexcept
{
  IndexedConstIterator it = *this;
  ++(*this);
  return it;
}

bool OpenModelica::MetaModelica::operator== (const IndexedConstIterator &i1, const IndexedConstIterator &i2) noexcept
{
  return i1._value == i2._value && i1._index == i2._index;
}

bool OpenModelica::MetaModelica::operator!= (const IndexedConstIterator &i1, const IndexedConstIterator &i2) noexcept
{
  return i1._value != i2._value || i1._index != i2._index;
}

Array::Array(void *value) noexcept
  : _value{value}
{
}

Value Array::front() const noexcept
{
  return (*this)[0];
}

Value Array::back() const noexcept
{
  return (*this)[size() - 1];
}

IndexedConstIterator Array::begin() const noexcept
{
  return {_value, 0};
}

IndexedConstIterator Array::cbegin() const noexcept
{
  return begin();
}

IndexedConstIterator Array::end() const noexcept
{
  return {_value, size()};
}

IndexedConstIterator Array::cend() const noexcept
{
  return end();
}

bool Array::empty() const noexcept
{
  return size() == 0;
}

size_t Array::size() const noexcept
{
  return get_slots(_value);
}

Value Array::operator[](size_t index) const noexcept
{
  return get_index(_value, index);
}

Value Array::at(size_t index) const
{
  if (index >= size()) {
    throw std::out_of_range("Array::at: " + std::to_string(index) + " >= " + std::to_string(size()));
  }

  return (*this)[index];
}

std::ostream& OpenModelica::MetaModelica::operator<< (std::ostream &os, Array array) noexcept
{
  os << '[';
  print_list(array, os);
  os << ']';
  return os;
}

Tuple::Tuple(void *value) noexcept
  : _value{value}
{
}

IndexedConstIterator Tuple::begin() const noexcept
{
  return {_value, 0};
}

IndexedConstIterator Tuple::cbegin() const noexcept
{
  return begin();
}

IndexedConstIterator Tuple::end() const noexcept
{
  return {_value, size()};
}

IndexedConstIterator Tuple::cend() const noexcept
{
  return end();
}

size_t Tuple::size() const noexcept
{
  return get_slots(_value);
}

Value Tuple::operator[](size_t index) const noexcept
{
  return get_index(_value, index);
}

Value Tuple::at(size_t index) const
{
  if (index >= size()) {
    throw std::out_of_range("Tuple::at: " + std::to_string(index) + " >= " + std::to_string(size()));
  }

  return (*this)[index];
}

std::ostream& OpenModelica::MetaModelica::operator<< (std::ostream &os, Tuple tuple) noexcept
{
  os << '(';
  print_list(tuple, os);
  os << ')';
  return os;
}

Record::Record(void *value) noexcept
  : _value{value}
{
}

Record::Record(Value value)
  : _value{value.toRecord()._value}
{

}

std::string Record::fullName() const noexcept
{
  auto desc = static_cast<record_description*>(get_index(_value, 0));
  return desc->name;
}

std::string Record::uniontypeName() const noexcept
{
  auto name = fullName();
  auto pos = name.find_last_of('.');
  return name.substr(0, pos);
}

std::string Record::recordName() const noexcept
{
  auto name = fullName();
  auto pos = name.find_last_of('.');
  return name.substr(pos + 1, std::string::npos);
}

int Record::index() const noexcept
{
  return get_ctor(_value) - 3;
}

IndexedConstIterator Record::begin() const noexcept
{
  return {_value, 1};
}

IndexedConstIterator Record::cbegin() const noexcept
{
  return begin();
}

IndexedConstIterator Record::end() const noexcept
{
  return {_value, size() + 1};
}

IndexedConstIterator Record::cend() const noexcept
{
  return end();
}

size_t Record::size() const noexcept
{
  return get_slots(_value) - 1;
}

Value Record::operator[](std::string_view name) const noexcept
{
  return *find(name);
}

Value Record::operator[](size_t index) const noexcept
{
  return get_index(_value, index + 1);
}

Value Record::at(size_t index) const
{
  if (index >= size()) {
    throw std::out_of_range("Record::at: " + std::to_string(index) + " >= " + std::to_string(size()));
  }

  return (*this)[index];
}

IndexedConstIterator Record::find(std::string_view name) const noexcept
{
  auto desc = static_cast<record_description*>(get_index(_value, 0));

  for (size_t i = 0u; i < size(); ++i) {
    if (desc->fieldNames[i] == name) {
      return {_value, i + 1};
    }
  }

  return end();
}

bool Record::contains(std::string_view name) const noexcept
{
  return find(name) != end();
}

std::ostream& OpenModelica::MetaModelica::operator<< (std::ostream &os, Record record) noexcept
{
  os << record.fullName() << '(';
  print_list(record, os);
  os << ')';
  return os;
}

template<> int64_t     Value::to() const { return toInt(); }
template<> double      Value::to() const { return toDouble(); }
template<> bool        Value::to() const { return toBool(); }
template<> std::string Value::to() const { return toString(); }
template<> Option      Value::to() const { return toOption(); }
template<> List        Value::to() const { return toList(); }
template<> Array       Value::to() const { return toArray(); }
template<> Tuple       Value::to() const { return toTuple(); }
template<> Record      Value::to() const { return toRecord(); }

