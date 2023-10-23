#include <stdexcept>
#include <ostream>

#include "Util.h"
#include "Element.h"
#include "Modifier.h"

using namespace OpenModelica::Absyn;

constexpr int MOD = 0;
constexpr int REDECL = 1;

std::unique_ptr<Modifier::Base> fromMM(OpenModelica::MetaModelica::Record value)
{
  switch (value.index()) {
    case MOD: return std::make_unique<BindingModifier>(value);
    case REDECL: return std::make_unique<RedeclareModifier>(value);
  }

  return nullptr;
}

Modifier::Modifier(MetaModelica::Record value)
  : _value{fromMM(value)}
{

}

Modifier::Modifier(Final finalPrefix, Each eachPrefix, std::vector<SubMod> subMods,
  std::optional<Expression> binding, const SourceInfo &info) noexcept
  : _value(std::make_unique<BindingModifier>(finalPrefix, eachPrefix, std::move(subMods), std::move(binding), info))
{

}

Modifier::Modifier(Final finalPrefix, Each eachPrefix, Element element) noexcept
  : _value(std::make_unique<RedeclareModifier>(finalPrefix, eachPrefix, std::move(element)))
{

}

Modifier::Modifier(const Modifier &other) noexcept
  : _value{other._value ? other._value->clone() : nullptr}
{

}

Modifier& Modifier::operator= (const Modifier &other) noexcept
{
  _value = other._value ? other._value->clone() : nullptr;
  return *this;
}

bool Modifier::isEmpty() const noexcept
{
  return _value == nullptr;
}

bool Modifier::isFinal() const noexcept
{
  return _value ? _value->isFinal() : false;
}

bool Modifier::isEach() const noexcept
{
  return _value ? _value->isEach() : false;
}

const Expression* Modifier::binding() const noexcept
{
  return _value ? _value->binding() : nullptr;
}

//bool Modifier::hasBooleanNamed(std::string_view name) const
//{
//  if (!_value) return false;
//
//  auto m = _value->lookupSubMod(name);
//  auto binding = m ? m->second.binding() : nullptr;
//
//  return binding && binding->isTrue();
//}

void Modifier::print(std::ostream &os, std::string_view name) const noexcept
{
  if (_value) {
    _value->print(os, name);
  }
}

BindingModifier::BindingModifier(MetaModelica::Record value)
  : _final{value[0]},
    _each{value[1]},
    _binding{value[3].mapOptional<Expression>()},
    _info{value[4]}
{
  for (auto e: value[2].toList()) {
    auto v = e.toRecord();
    _subMods.emplace_back(v[0].toString(), v[1]);
  }
}

BindingModifier::BindingModifier(Final finalPrefix, Each eachPrefix, std::vector<Modifier::SubMod> subMods,
  std::optional<Expression> binding, const SourceInfo &info) noexcept
  : _final(finalPrefix), _each(eachPrefix), _subMods(std::move(subMods)),
    _binding(std::move(binding)), _info(info)
{
}

const Modifier::SubMod* BindingModifier::lookupSubMod(std::string_view name) const noexcept
{
  for (auto &m: _subMods) {
    if (m.first == name) {
      return &m;
    }
  }

  return nullptr;
}

std::unique_ptr<Modifier::Base> BindingModifier::clone() const noexcept
{
  return std::make_unique<BindingModifier>(*this);
}

namespace OpenModelica::Absyn
{
  std::ostream& operator<< (std::ostream &os, const Modifier::SubMod &submod)
  {
    submod.second.print(os, submod.first);
    return os;
  }
}

void BindingModifier::print(std::ostream &os, std::string_view name) const noexcept
{
  os << _final.unparse() << _each.unparse() << name;

  if (!_subMods.empty()) {
    os << '(' << Util::printList(_subMods) << ')';
  }

  if (_binding) {
    os << " = ";
    os << *_binding;
  }
}

RedeclareModifier::RedeclareModifier(MetaModelica::Record value)
  : _final{value[0]},
    _each{value[1]},
    _element{value[2]}
{

}

RedeclareModifier::RedeclareModifier(Final isFinal, Each isEach, Element element) noexcept
  : _final(isFinal), _each(isEach), _element(std::move(element))
{

}

std::unique_ptr<Modifier::Base> RedeclareModifier::clone() const noexcept
{
  return std::make_unique<RedeclareModifier>(*this);
}

void RedeclareModifier::print(std::ostream &os, std::string_view) const noexcept
{
  _element.print(os, _each);
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const Modifier &modifier) noexcept
{
  modifier.print(os);
  return os;
}
