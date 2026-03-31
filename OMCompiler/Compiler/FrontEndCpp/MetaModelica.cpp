#include <cassert>
#include <stdexcept>
#include <ostream>

extern "C" {
#include "meta/meta_modelica.h"
}

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

/* These functions will crash on MetaModelica types that don't have headers, i.e. Integers. */

mmc_uint_t get_header(void *data)
{
  return MMC_HDR_UNMARK(MMC_GETHDR(data));
}

void* get_index(void *data, std::size_t index)
{
  return MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(data), index + 1));
}

std::size_t get_slots(void *data)
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

Value::Value(int64_t value) noexcept
  : _value{mmc_mk_icon(value)}
{

}

Value::Value(double value) noexcept
  : _value{mmc_mk_rcon(value)}
{

}

Value::Value(bool value) noexcept
  : _value{mmc_mk_bcon(value)}
{

}

Value::Value(std::string_view value) noexcept
  : _value{mmc_mk_scon(value.data())}
{

}

Value::Value(const char *value) noexcept
  : Value(std::string_view{value})
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
  if (isInteger()) return false;
  return get_header(_value) == MMC_REALHDR;
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
  if (isInteger()) return false;
  return MMC_HDRISSTRING(get_header(_value));
}

bool Value::isOption() const noexcept
{
  if (isInteger()) return false;
  const auto hdr = get_header(_value);
  return MMC_HDRCTOR(hdr) == 1 && MMC_HDRSLOTS(hdr) < 2;
}

bool Value::isList() const noexcept
{
  if (isInteger()) return false;
  const auto hdr = get_header(_value);
  return hdr == MMC_NILHDR || (MMC_HDRCTOR(hdr) == 1 && MMC_HDRSLOTS(hdr) >= 2);
}

bool Value::isArray() const noexcept
{
  if (isInteger()) return false;
  return MMC_HDRCTOR(get_header(_value)) == MMC_ARRAY_TAG;
}

bool Value::isTuple() const noexcept
{
  if (isInteger()) return false;
  const auto hdr = get_header(_value);
  return MMC_HDRCTOR(hdr) == 0 && MMC_HDRSLOTS(hdr) > 0;
}

bool Value::isRecord() const noexcept
{
  if (isInteger()) return false;
  const auto hdr = get_header(_value);
  return MMC_HDRCTOR(hdr) > 1 && MMC_HDRSLOTS(hdr) > 0;
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

std::string_view Value::toStringView() const
{
  if (!isString()) {
    throw std::runtime_error("Value::toStringView(): expected String, got " + name());
  }

  return MMC_STRINGDATA(_value);
}

Option Value::toOption() const
{
  if (!isOption()) {
    throw std::runtime_error("Value::toOption(): expected Option, got " + name());
  }

  return Option{_value};
}

List Value::toList() const
{
  if (!isList()) {
    throw std::runtime_error("Value::toList(): expected list, got " + name());
  }

  return List{_value};
}

Array Value::toArray() const
{
  if (!isArray()) {
    throw std::runtime_error("Value::toArray(): expected array, got " + name());
  }

  return Array{_value};
}

Tuple Value::toTuple() const
{
  if (!isTuple()) {
    throw std::runtime_error("Value::toTuple(): expected tuple, got " + name());
  }

  return Tuple{_value};
}

Record Value::toRecord() const
{
  if (!isRecord()) {
    throw std::runtime_error("Value::toRecord(): expected record, got " + name());
  }

  return Record{_value};
}

Pointer Value::toPointer() const
{
  if (!(isTuple() || isOption())) { // Pointers are tuples (mutable) or Options (immutable).
    throw std::runtime_error("Value::toPointer(): expected Pointer, got " + name());
  }

  return Pointer{_value};
}

Mutable Value::toMutable() const
{
  if (!isTuple()) { // Mutables are tuples.
    throw std::runtime_error("Value::toMutable(): expected Mutable, got " + name());
  }

  return Mutable{_value};
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

Option::Option() noexcept
  : _value{mmc_mk_none()}
{

}

Option::Option(Value value) noexcept
  : _value{value.data() ? mmc_mk_some(value.data()) : mmc_mk_none()}
{

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
  return Value::ArrowProxy{get_index(_value, 0)};
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
  return Value{get_index(_value, 0)};
}

void* Option::data() const noexcept
{
  return _value;
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
  return Value{MMC_CAR(_value)};
}

Value::ArrowProxy List::ConstIterator::operator->() const noexcept
{
  return Value::ArrowProxy{MMC_CAR(_value)};
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

List::List() noexcept
  : _value{mmc_mk_nil()}
{

}

List::List(void *value) noexcept
  : _value{value}
{
}

List::List(Array arr) noexcept
  : _value{arrayList(arr.data())}
{

}

Value List::front() const noexcept
{
  return Value{MMC_CAR(_value)};
}

List List::rest() const noexcept
{
  return List{MMC_CDR(_value)};
}

List::ConstIterator List::begin() const noexcept
{
  return List::ConstIterator{_value};
}

List::ConstIterator List::cbegin() const noexcept
{
  return List::ConstIterator{_value};
}

List::ConstIterator List::end() const noexcept
{
  return List::ConstIterator{nullptr};
}

List::ConstIterator List::cend() const noexcept
{
  return List::ConstIterator{nullptr};
}

bool List::empty() const noexcept
{
  return MMC_NILTEST(_value);
}

std::size_t List::size() const noexcept
{
  return listLength(_value);
}

void List::cons(Value v) noexcept
{
  _value = mmc_mk_cons(v.data(), _value);
}

void* List::data() const noexcept
{
  return _value;
}

std::ostream& OpenModelica::MetaModelica::operator<< (std::ostream &os, List list) noexcept
{
  os << '{';
  print_list(list, os);
  os << '}';
  return os;
}

IndexedConstIterator::IndexedConstIterator(void *value, std::size_t index) noexcept
  : _value{value}, _index{index}
{

}

IndexedConstIterator::value_type IndexedConstIterator::operator*() const noexcept
{
  return Value{get_index(_value, _index)};
}

Value::ArrowProxy IndexedConstIterator::operator->() const noexcept
{
  return Value::ArrowProxy{get_index(_value, _index)};
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

Array::Array() noexcept
  : _value{mmc_mk_box_no_assign(0, MMC_ARRAY_TAG, 0)}
{

}

Array::Array(void *value) noexcept
  : _value{value}
{
}

Array::Array(std::size_t size) noexcept
  : _value{mmc_mk_box_no_assign(size, MMC_ARRAY_TAG, 0)}
{

}

Array::Array(std::size_t size, Value v) noexcept
  : _value{mmc_mk_box_no_assign(size, MMC_ARRAY_TAG, MMC_IS_IMMEDIATE(v.data()))}
{
  void **arr = MMC_STRUCTDATA(_value);
  for(std::size_t i = 0; i < size; ++i) {
    arr[i] = v.data();
  }
}

Array::Array(List lst) noexcept
  : _value{listArray(lst.data())}
{

}

Array Array::copy() const noexcept
{
  return Array{arrayCopy(_value)};
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

std::size_t Array::size() const noexcept
{
  return get_slots(_value);
}

Value Array::operator[](std::size_t index) const noexcept
{
  return Value{get_index(_value, index)};
}

Value Array::at(std::size_t index) const
{
  if (index >= size()) {
    throw std::out_of_range("Array::at: " + std::to_string(index) + " >= " + std::to_string(size()));
  }

  return (*this)[index];
}

void Array::set(std::size_t index, Value value) noexcept
{
  MMC_STRUCTDATA(_value)[index] = value.data();
}

void* Array::data() const noexcept
{
  return _value;
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

Tuple::Tuple(std::initializer_list<Value> values) noexcept
{
  mmc_struct *p = static_cast<mmc_struct*>(mmc_alloc_words(values.size() + 1));
  p->header = MMC_STRUCTHDR(values.size(), 0);

  void **data = p->data;
  for (auto v: values) {
    *data++ = v.data();
  }

  _value = MMC_TAGPTR(p);
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

std::size_t Tuple::size() const noexcept
{
  return get_slots(_value);
}

Value Tuple::operator[](std::size_t index) const noexcept
{
  return Value{get_index(_value, index)};
}

Value Tuple::at(std::size_t index) const
{
  if (index >= size()) {
    throw std::out_of_range("Tuple::at: " + std::to_string(index) + " >= " + std::to_string(size()));
  }

  return (*this)[index];
}

void* Tuple::data() const noexcept
{
  return _value;
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

Record::Record(int index, record_description &desc, std::initializer_list<Value> values)
{
  mmc_struct *p = static_cast<mmc_struct*>(mmc_alloc_words(values.size() + 2));
  p->header = MMC_STRUCTHDR(values.size() + 1, index + 3);

  void **data = p->data;
  *data++ = &desc;

  for (auto v: values) {
    *data++ = v.data();
  }

  _value = MMC_TAGPTR(p);
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

std::size_t Record::size() const noexcept
{
  return get_slots(_value) - 1;
}

Value Record::operator[](std::string_view name) const noexcept
{
  return *find(name);
}

Value Record::operator[](std::size_t index) const noexcept
{
  return Value{get_index(_value, index + 1)};
}

Value Record::at(std::size_t index) const
{
  if (index >= size()) {
    throw std::out_of_range("Record::at: " + std::to_string(index) + " >= " + std::to_string(size()));
  }

  return (*this)[index];
}

void Record::set(std::size_t index, Value value)
{
  if (index >= size()) {
    throw std::out_of_range("Record::set: " + std::to_string(index) + " >= " + std::to_string(size()));
  }

  static_cast<modelica_metatype*>(MMC_UNTAGPTR(_value))[index + 2] = value.data();
}

IndexedConstIterator Record::find(std::string_view name) const noexcept
{
  auto desc = static_cast<record_description*>(get_index(_value, 0));

  for (std::size_t i = 0u; i < size(); ++i) {
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

void* Record::data() const noexcept
{
  return _value;
}

std::size_t Record::hash() const noexcept
{
  return reinterpret_cast<std::size_t>(MMC_UNTAGPTR(_value));
}

bool OpenModelica::MetaModelica::operator== (Record record1, Record record2) noexcept
{
  return MMC_UNTAGPTR(record1.data()) == MMC_UNTAGPTR(record2.data());
}

std::ostream& OpenModelica::MetaModelica::operator<< (std::ostream &os, Record record) noexcept
{
  os << record.fullName() << '(';
  print_list(record, os);
  os << ')';
  return os;
}

Pointer::Pointer() noexcept
  : _ptr{mmc_mk_box1(0, nullptr)}
{

}

Pointer::Pointer(void *value) noexcept
  : _ptr{value}
{
}

Pointer::Pointer(Value value, bool immutable) noexcept
  : _ptr(immutable ? mmc_mk_some(value.data()) : mmc_mk_box1(0, value.data()))
{
}

Value Pointer::access() const noexcept
{
  return Value(MMC_STRUCTDATA(_ptr)[0]);
}

Value::ArrowProxy Pointer::operator->() const noexcept
{
  return Value::ArrowProxy{MMC_STRUCTDATA(_ptr)[0]};
}

void Pointer::update(Value value)
{
  assert(valueConstructor(_ptr) == 0); // Must be mutable
  MMC_STRUCTDATA(_ptr)[0] = value.data();
}

void* Pointer::data() const noexcept
{
  return _ptr;
}

bool Pointer::isImmutable() const noexcept
{
  return Value{_ptr}.isOption();
}

Mutable::Mutable(void *value) noexcept
  : _ptr{value}
{

}

Mutable::Mutable(Value value) noexcept
  : _ptr{mmc_mk_box1(0, value.data())}
{
}

Value Mutable::access() const noexcept
{
  return Value(MMC_STRUCTDATA(_ptr)[0]);
}

Value::ArrowProxy Mutable::operator->() const noexcept
{
  return Value::ArrowProxy{MMC_STRUCTDATA(_ptr)[0]};
}

void Mutable::update(Value value)
{
  assert(valueConstructor(_ptr) == 0); // Must be mutable
  MMC_STRUCTDATA(_ptr)[0] = value.data();
}

void* Mutable::data() const noexcept
{
  return _ptr;
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
template<> Pointer     Value::to() const { return toPointer(); }
template<> Mutable     Value::to() const { return toMutable(); }

