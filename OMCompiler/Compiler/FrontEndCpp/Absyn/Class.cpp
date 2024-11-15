#include <ostream>

#include "ElementVisitor.h"
#include "Class.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_Element_CLASS__desc;

Class::Class(MetaModelica::Record value)
  : Element(SourceInfo{value[7]}),
    _name{value[0].toString()},
    _prefixes{value[1]},
    _encapsulated{value[2]},
    _partial{value[3]},
    _restriction{value[4]},
    _classDef{ClassDef::fromSCode(value[5])},
    _comment{value[6]}
{

}

Class::Class(std::string name, ElementPrefixes prefixes, Encapsulated enc, Partial partial, Restriction res, std::unique_ptr<ClassDef> cdef, Comment cmt, SourceInfo info)
  : Element(std::move(info)),
    _name{std::move(name)},
    _prefixes{std::move(prefixes)},
    _encapsulated{enc},
    _partial{partial},
    _restriction{res},
    _classDef{std::move(cdef)},
    _comment{std::move(cmt)}
{

}

Class::Class(const Class &other)
  : Element(other.info()),
    _name{other._name},
    _prefixes{other._prefixes},
    _encapsulated{other._encapsulated},
    _partial{other._partial},
    _restriction{other._restriction},
    _classDef{other._classDef ? other._classDef->clone() : nullptr},
    _comment{other._comment}
{

}

Class& Class::operator= (Class other) noexcept
{
  Element::operator=(*this);
  swap(*this, other);
  return *this;
}

namespace OpenModelica::Absyn
{
  void swap(Class &first, Class &second) noexcept
  {
    using std::swap;
    swap(static_cast<Element&>(first), static_cast<Element&>(second));
    swap(first._name, second._name);
    swap(first._prefixes, second._prefixes);
    swap(first._encapsulated, second._encapsulated);
    swap(first._partial, second._partial);
    swap(first._restriction, second._restriction);
    swap(first._classDef, second._classDef);
    swap(first._comment, second._comment);
  }
}

void Class::apply(ElementVisitor &visitor)
{
  visitor.visit(*this);
}

MetaModelica::Value Class::toSCode() const noexcept
{
  return MetaModelica::Record{Element::CLASS, SCode_Element_CLASS__desc, {
    MetaModelica::Value{_name},
    _prefixes.toSCode(),
    _encapsulated.toSCode(),
    _partial.toSCode(),
    _restriction.toSCode(),
    _classDef->toSCode(),
    _comment.toSCode(),
    info()
  }};
}

const std::string& Class::name() const noexcept
{
  return _name;
}

const ElementPrefixes& Class::prefixes() const noexcept
{
  return _prefixes;
}

const Comment& Class::comment() const noexcept
{
  return _comment;
}

const ClassDef& Class::definition() const noexcept
{
  return *_classDef;
}

std::unique_ptr<Element> Class::clone() const noexcept
{
  return std::make_unique<Class>(*this);
}

void Class::print(std::ostream &os, Each each) const noexcept
{
  _prefixes.print(os, each);
  os << _encapsulated.unparse() << _partial.unparse() << _restriction << ' ';
  _classDef->print(os, *this);
}
