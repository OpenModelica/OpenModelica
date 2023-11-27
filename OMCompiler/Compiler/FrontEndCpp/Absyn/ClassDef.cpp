#include <ostream>

#include "Util.h"
#include "Class.h"
#include "ExternalDecl.h"
#include "Equation.h"
#include "Algorithm.h"
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

std::unique_ptr<ClassDef::Base> cdef_from_mm(MetaModelica::Record value)
{
  switch (value.index()) {
    case PARTS:         return std::make_unique<Parts>(value);
    case CLASS_EXTENDS: return std::make_unique<ClassExtends>(value);
    case DERIVED:       return std::make_unique<Derived>(value);
    case ENUMERATION:   return std::make_unique<Enumeration>(value);
    case OVERLOAD:      return std::make_unique<Overload>(value);
    case PDER:          return std::make_unique<PartialDerivative>(value);
  }

  throw std::runtime_error("ClassDef::fromMM: invalid record index");
}

ClassDef::ClassDef(MetaModelica::Record value)
  : _impl{cdef_from_mm(value)}
{

}

ClassDef::ClassDef(const ClassDef &other) noexcept
  : _impl{other._impl->clone()}
{

}

ClassDef& ClassDef::operator= (const ClassDef &other) noexcept
{
  _impl = other._impl->clone();
  return *this;
}

MetaModelica::Value ClassDef::toSCode() const noexcept
{
  return _impl->toSCode();
}

void ClassDef::print(std::ostream &os, const Class &parent) const noexcept
{
  _impl->print(os, parent);
}

void ClassDef::printBody(std::ostream &os) const noexcept
{
  _impl->printBody(os);
}

Parts::Parts(MetaModelica::Record value)
  : _elements{value[0].mapVector<Element>()},
    _equations{value[1].mapVector<Equation>()},
    _initialEquations{value[2].mapVector<Equation>()},
    _algorithms{value[3].mapVector<Algorithm>()},
    _initialAlgorithms{value[4].mapVector<Algorithm>()},
    _externalDecl{value[7].mapPointer<ExternalDecl>()}
{

}

Parts::Parts(const Parts &other) noexcept
  : _elements{other._elements},
    _equations{other._equations},
    _initialEquations{other._initialEquations},
    _algorithms{other._algorithms},
    _initialAlgorithms{other._initialAlgorithms},
    _externalDecl{other._externalDecl ? std::make_unique<ExternalDecl>(*other._externalDecl) : nullptr}
{

}

Parts& Parts::operator= (Parts other) noexcept
{
  other.swap(*this);
  return *this;
}

void Parts::swap(Parts &other) noexcept
{
  std::swap(_elements, other._elements);
  std::swap(_externalDecl, other._externalDecl);
  std::swap(_equations, other._equations);
  std::swap(_initialEquations, other._initialEquations);
  std::swap(_algorithms, other._algorithms);
  std::swap(_initialAlgorithms, other._initialAlgorithms);
}

Parts::~Parts() = default;

std::unique_ptr<ClassDef::Base> Parts::clone() const noexcept
{
  return std::make_unique<Parts>(*this);
}

MetaModelica::Value Parts::toSCode() const noexcept
{
  return MetaModelica::Record(PARTS, SCode_ClassDef_PARTS__desc, {
    Element::toSCodeList(_elements),
    Equation::toSCodeList(_equations),
    Equation::toSCodeList(_initialEquations),
    MetaModelica::List(_algorithms, [](const auto &alg) { return alg.toSCode(); }),
    MetaModelica::List(_initialAlgorithms, [](const auto &alg) { return alg.toSCode(); }),
    MetaModelica::List(),
    MetaModelica::List(),
    MetaModelica::Option(_externalDecl.get(), [](const auto &decl) { return decl.toSCode(); })
  });
}

void Parts::print(std::ostream &os, const Class &parent) const noexcept
{
  os << parent.name();
  parent.comment().printDescription(os, " ");
  os << '\n';
  printBody(os);
  parent.comment().printAnnotation(os, " ");
  os << "end " << parent.name();
}

void Parts::printBody(std::ostream &os) const noexcept
{
  for (auto &e: _elements) os << e << ";\n";

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

ClassExtends::ClassExtends(MetaModelica::Record value)
  : _modifier{value[0]},
    _composition{value[1]}
{

}

std::unique_ptr<ClassDef::Base> ClassExtends::clone() const noexcept
{
  return std::make_unique<ClassExtends>(*this);
}

MetaModelica::Value ClassExtends::toSCode() const noexcept
{
  return MetaModelica::Record(CLASS_EXTENDS, SCode_ClassDef_CLASS__EXTENDS__desc, {
    _modifier.toSCode(),
    _composition.toSCode()
  });
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
  _composition.printBody(os);
}

Derived::Derived(MetaModelica::Record value)
  : _typeSpec{value[0]},
    _modifier{value[1]},
    _attributes{value[2]}
{

}

std::unique_ptr<ClassDef::Base> Derived::clone() const noexcept
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

std::unique_ptr<ClassDef::Base> Enumeration::clone() const noexcept
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

std::unique_ptr<ClassDef::Base> Overload::clone() const noexcept
{
  return std::make_unique<Overload>(*this);
}

MetaModelica::Value Overload::toSCode() const noexcept
{
  return MetaModelica::Record(OVERLOAD, SCode_ClassDef_OVERLOAD__desc, {
    MetaModelica::List(_paths, [](const Path &path) { return path.toAbsyn(); })
  });
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

std::unique_ptr<ClassDef::Base> PartialDerivative::clone() const noexcept
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

void PartialDerivative::print(std::ostream &os, const Class &parent) const noexcept
{
  os << parent.name();
  printBody(os);
}

void PartialDerivative::printBody(std::ostream &os) const noexcept
{
  os << " = der(" << _functionPath << ", " << Util::printList(_derivedVariables) << ')';
}
