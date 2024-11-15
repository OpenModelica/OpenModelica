#include <ostream>

#include "Util.h"
#include "Class.h"
#include "ExternalDecl.h"
#include "Equation.h"
#include "Algorithm.h"
#include "Element.h"
#include "ClassDef.h"

constexpr int PARTS = 0;
constexpr int CLASS_EXTENDS = 1;
constexpr int DERIVED = 2;
constexpr int ENUMERATION = 3;
constexpr int OVERLOAD = 4;
constexpr int PDER = 5;

extern record_description SCode_ClassDef_PARTS__desc;
extern record_description SCode_ClassDef_CLASS__EXTENDS__desc;
extern record_description SCode_ClassDef_DERIVED__desc;
extern record_description SCode_ClassDef_ENUMERATION__desc;
extern record_description SCode_ClassDef_OVERLOAD__desc;
extern record_description SCode_ClassDef_PDER__desc;

extern record_description SCode_Enum_ENUM__desc;

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

std::unique_ptr<ClassDef> ClassDef::fromSCode(MetaModelica::Record value)
{
  switch (value.index()) {
    case PARTS:         return std::make_unique<ClassParts>(value);
    case CLASS_EXTENDS: return std::make_unique<ClassExtends>(value);
    case DERIVED:       return std::make_unique<Derived>(value);
    case ENUMERATION:   return std::make_unique<Enumeration>(value);
    case OVERLOAD:      return std::make_unique<Overload>(value);
    case PDER:          return std::make_unique<PartialDerivative>(value);
  }

  throw std::runtime_error("ClassDef::fromMM: invalid record index");
}

ClassDef::~ClassDef() = default;

ClassParts::ClassParts() = default;

ClassParts::ClassParts(std::vector<std::unique_ptr<Element>> elements)
  : _elements(std::move(elements))
{

}

ClassParts::ClassParts(MetaModelica::Record value)
  : _elements{value[0].mapVector([](auto v) { return Element::fromSCode(v); })},
    _equations{value[1].mapVector<Equation>()},
    _initialEquations{value[2].mapVector<Equation>()},
    _algorithms{value[3].mapVector<Algorithm>()},
    _initialAlgorithms{value[4].mapVector<Algorithm>()},
    _externalDecl{value[7].mapPointer<ExternalDecl>()}
{

}

ClassParts::ClassParts(const ClassParts &other) noexcept
  : _elements{Util::cloneVector(other._elements)},
    _equations{other._equations},
    _initialEquations{other._initialEquations},
    _algorithms{other._algorithms},
    _initialAlgorithms{other._initialAlgorithms},
    _externalDecl{other._externalDecl ? std::make_unique<ExternalDecl>(*other._externalDecl) : nullptr}
{

}

ClassParts& ClassParts::operator= (ClassParts other) noexcept
{
  ClassDef::operator=(other);
  swap(*this, other);
  return *this;
}

namespace OpenModelica::Absyn
{
  void swap(ClassParts &first, ClassParts &second) noexcept
  {
    using std::swap;
    swap(first._elements, second._elements);
    swap(first._externalDecl, second._externalDecl);
    swap(first._equations, second._equations);
    swap(first._initialEquations, second._initialEquations);
    swap(first._algorithms, second._algorithms);
    swap(first._initialAlgorithms, second._initialAlgorithms);
  }
}

ClassParts::~ClassParts() = default;

std::unique_ptr<ClassDef> ClassParts::clone() const noexcept
{
  return std::make_unique<ClassParts>(*this);
}

MetaModelica::Value ClassParts::toSCode() const noexcept
{
  return MetaModelica::Record(PARTS, SCode_ClassDef_PARTS__desc, {
    MetaModelica::List(_elements, [](const auto &e) { return e->toSCode(); }),
    Equation::toSCodeList(_equations),
    Equation::toSCodeList(_initialEquations),
    MetaModelica::List(_algorithms, [](const auto &alg) { return alg.toSCode(); }),
    MetaModelica::List(_initialAlgorithms, [](const auto &alg) { return alg.toSCode(); }),
    MetaModelica::List(),
    MetaModelica::List(),
    MetaModelica::Option(_externalDecl.get(), [](const auto &decl) { return decl.toSCode(); })
  });
}

void ClassParts::apply(ClassDefVisitor &visitor) const
{
  visitor.visit(*this);
}

void ClassParts::print(std::ostream &os, const Class &parent) const noexcept
{
  os << parent.name();
  parent.comment().printDescription(os, " ");
  os << '\n';
  printBody(os);
  parent.comment().printAnnotation(os, " ");
  os << "end " << parent.name();
}

void ClassParts::printBody(std::ostream &os) const noexcept
{
  for (auto &e: _elements) os << *e << ";\n";

  if (!_equations.empty()) {
    os << "equation\n";
    for (auto &eq: _equations) os << eq << ";\n";
  }

  if (!_initialEquations.empty()) {
    os << "initial equation\n";
    for (auto &eq: _initialEquations) os << eq << ";\n";
  }

  os << Util::printList(_algorithms, "");
  os << Util::printList(_initialAlgorithms, "");

  if (_externalDecl) os << *_externalDecl << ";\n";
}

ClassParts::ElementIterator ClassParts::elementsBegin()
{
  return ClassParts::ElementIterator{_elements.begin()};
}

ClassParts::ElementConstIterator ClassParts::elementsBegin() const
{
  return ClassParts::ElementConstIterator{_elements.begin()};
}

ClassParts::ElementIterator ClassParts::elementsEnd()
{
  return ClassParts::ElementIterator{_elements.end()};
}

ClassParts::ElementConstIterator ClassParts::elementsEnd() const
{
  return ClassParts::ElementConstIterator{_elements.end()};
}

ClassExtends::ClassExtends(MetaModelica::Record value)
  : _modifier{value[0]},
    _composition{ClassDef::fromSCode(value[1])}
{

}

ClassExtends::ClassExtends(const ClassExtends &other) noexcept
  : _modifier(other._modifier),
    _composition(other._composition ? other._composition->clone() : nullptr)
{

}

ClassExtends::~ClassExtends() = default;

ClassExtends& ClassExtends::operator= (ClassExtends other) noexcept
{
  ClassDef::operator=(other);
  swap(*this, other);
  return *this;
}

namespace OpenModelica::Absyn
{
  void swap(ClassExtends &first, ClassExtends &second) noexcept
  {
    using std::swap;
    swap(first._modifier, second._modifier);
    swap(first._composition, second._composition);
  }
}

std::unique_ptr<ClassDef> ClassExtends::clone() const noexcept
{
  return std::make_unique<ClassExtends>(*this);
}

MetaModelica::Value ClassExtends::toSCode() const noexcept
{
  return MetaModelica::Record(CLASS_EXTENDS, SCode_ClassDef_CLASS__EXTENDS__desc, {
    _modifier.toSCode(),
    _composition->toSCode()
  });
}

void ClassExtends::apply(ClassDefVisitor &visitor) const
{
  visitor.visit(*this);
}

void ClassExtends::print(std::ostream &os, const Class &parent) const noexcept
{
  os << "extends " << parent.name() << _modifier;
  parent.comment().printDescription(os, " ");
  os << '\n';
  printBody(os);
  parent.comment().printAnnotation(os, " ");
  os << "end " << parent.name();
}

void ClassExtends::printBody(std::ostream &os) const noexcept
{
  _composition->printBody(os);
}

Derived::Derived(MetaModelica::Record value)
  : _typeSpec{value[0]},
    _modifier{value[1]},
    _attributes{value[2]}
{

}

std::unique_ptr<ClassDef> Derived::clone() const noexcept
{
  return std::make_unique<Derived>(*this);
}

MetaModelica::Value Derived::toSCode() const noexcept
{
  return MetaModelica::Record(DERIVED, SCode_ClassDef_DERIVED__desc, {
    _typeSpec.toAbsyn(),
    _modifier.toSCode(),
    _attributes.toSCode()
  });
}

void Derived::apply(ClassDefVisitor &visitor) const
{
  visitor.visit(*this);
}

void Derived::print(std::ostream &os, const Class &parent) const noexcept
{
  os << parent.name();
  printBody(os);
  os << parent.comment();
}

void Derived::printBody(std::ostream &os) const noexcept
{
  os << " = " << _attributes << _typeSpec << _modifier;
}

Enumeration::Enumeration(MetaModelica::Record value)
{
  for (const auto &e: value[0].toList()) {
    auto lit = e.toRecord();
    _literals.emplace_back(lit[0].toString(), lit[1]);
  }
}

std::unique_ptr<ClassDef> Enumeration::clone() const noexcept
{
  return std::make_unique<Enumeration>(*this);
}

MetaModelica::Value Enumeration::toSCode() const noexcept
{
  return MetaModelica::Record(ENUMERATION, SCode_ClassDef_ENUMERATION__desc, {
    MetaModelica::List(_literals, [](const auto &lit) {
      return MetaModelica::Record(0, SCode_Enum_ENUM__desc, {
        MetaModelica::Value(lit.first),
        lit.second.toSCode()
      });
    })
  });
}

void Enumeration::apply(ClassDefVisitor &visitor) const
{
  visitor.visit(*this);
}

namespace OpenModelica::Absyn
{
  std::ostream& operator<< (std::ostream &os, const Enumeration::EnumLiteral &literal)
  {
    os << literal.first << literal.second;
    return os;
  }
}

void Enumeration::print(std::ostream &os, const Class &parent) const noexcept
{
  os << parent.name();
  printBody(os);
}

void Enumeration::printBody(std::ostream &os) const noexcept
{
  os << " = enumeration(";

  if (_literals.empty()) {
    os << ':';
  } else {
    os << Util::printList(_literals);
  }

  os << ')';
}

Overload::Overload(MetaModelica::Record value)
  : _paths(value[0].mapVector<Path>())
{

}

std::unique_ptr<ClassDef> Overload::clone() const noexcept
{
  return std::make_unique<Overload>(*this);
}

MetaModelica::Value Overload::toSCode() const noexcept
{
  return MetaModelica::Record(OVERLOAD, SCode_ClassDef_OVERLOAD__desc, {
    MetaModelica::List(_paths, [](const Path &path) { return path.toAbsyn(); })
  });
}

void Overload::apply(ClassDefVisitor &visitor) const
{
  visitor.visit(*this);
}

void Overload::print(std::ostream &os, const Class &parent) const noexcept
{
  os << parent.name();
  printBody(os);
}

void Overload::printBody(std::ostream &os) const noexcept
{
  os << " = overload(" << Util::printList(_paths) << ')';
}

PartialDerivative::PartialDerivative(MetaModelica::Record value)
  : _functionPath(value[0]),
    _derivedVariables(value[1].toVector<std::string>())
{

}

std::unique_ptr<ClassDef> PartialDerivative::clone() const noexcept
{
  return std::make_unique<PartialDerivative>(*this);
}

MetaModelica::Value PartialDerivative::toSCode() const noexcept
{
  return MetaModelica::Record(PDER, SCode_ClassDef_PDER__desc, {
    _functionPath.toAbsyn(),
    MetaModelica::List(_derivedVariables)
  });
}

void PartialDerivative::apply(ClassDefVisitor &visitor) const
{
  visitor.visit(*this);
}

void PartialDerivative::print(std::ostream &os, const Class &parent) const noexcept
{
  os << parent.name();
  printBody(os);
}

void PartialDerivative::printBody(std::ostream &os) const noexcept
{
  os << " = der(" << _functionPath << ", " << Util::printList(_derivedVariables) << ')';
}
