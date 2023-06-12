#include <ostream>

#include "Import.h"
#include "Extends.h"
#include "Class.h"
#include "Component.h"
#include "DefineUnit.h"
#include "Element.h"

constexpr int IMPORT = 0;
constexpr int EXTENDS = 1;
constexpr int CLASS = 2;
constexpr int COMPONENT = 3;
constexpr int DEFINEUNIT = 4;

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

Element::Base::Base(SourceInfo info)
  : _info{std::move(info)}
{

}

std::unique_ptr<Element::Base> element_from_mm(MetaModelica::Record value)
{
  switch (value.index()) {
    case IMPORT:     return std::make_unique<Absyn::Import>(value);
    case EXTENDS:    return std::make_unique<Absyn::Extends>(value);
    case CLASS:      return std::make_unique<Absyn::Class>(value);
    case COMPONENT:  return std::make_unique<Absyn::Component>(value);
    case DEFINEUNIT: return std::make_unique<Absyn::DefineUnit>(value);
  }

  throw std::runtime_error("Element::Element: invalid record index");
}

Element::Element(MetaModelica::Record value)
  : _impl{element_from_mm(value)}
{

}

Element::Element(const Element &other) noexcept
  : _impl{other._impl->clone()}
{

}

Element& Element::operator= (const Element &other) noexcept
{
  _impl = other._impl->clone();
  return *this;
}

void Element::print(std::ostream &os, Each each) const noexcept
{
  _impl->print(os, each);
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const Element &element) noexcept
{
  element.print(os);
  return os;
}
