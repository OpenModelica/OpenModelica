#include <ostream>

#include "Import.h"
#include "Extends.h"
#include "Class.h"
#include "Component.h"
#include "DefineUnit.h"
#include "Element.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

Element::Base::Base(SourceInfo info)
  : _info{std::move(info)}
{

}

std::unique_ptr<Element::Base> element_from_mm(MetaModelica::Record value)
{
  switch (value.index()) {
    case Element::IMPORT:     return std::make_unique<Absyn::Import>(value);
    case Element::EXTENDS:    return std::make_unique<Absyn::Extends>(value);
    case Element::CLASS:      return std::make_unique<Absyn::Class>(value);
    case Element::COMPONENT:  return std::make_unique<Absyn::Component>(value);
    case Element::DEFINEUNIT: return std::make_unique<Absyn::DefineUnit>(value);
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

MetaModelica::Value Element::toSCode() const noexcept
{
  return _impl->toSCode();
}

MetaModelica::Value Element::toSCodeList(const std::vector<Element> &elements) noexcept
{
  return MetaModelica::List(elements, [](const auto &e) { return e.toSCode(); });
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
