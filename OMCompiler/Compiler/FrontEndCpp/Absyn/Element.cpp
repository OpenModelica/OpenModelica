#include <ostream>

#include "Import.h"
#include "Extends.h"
#include "Class.h"
#include "Component.h"
#include "DefineUnit.h"
#include "Element.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

Element::Element(SourceInfo info)
  : _info{std::move(info)}
{

}

std::unique_ptr<Element> Element::fromSCode(MetaModelica::Record value)
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

Element::~Element() = default;

namespace OpenModelica::Absyn
{
  void swap(Element &first, Element &second) noexcept
  {
    using std::swap;
    swap(first._info, second._info);
  }

  std::ostream& operator<< (std::ostream &os, const Element &element) noexcept
  {
    element.print(os);
    return os;
  }
}

