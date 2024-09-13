#include <stdexcept>
#include <ostream>

#include "Util.h"
#include "Element.h"
#include "Modifier.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

constexpr int MOD = 0;
constexpr int REDECL = 1;
constexpr int NOMOD = 2;

extern record_description SCode_Mod_MOD__desc;
extern record_description SCode_Mod_REDECL__desc;
extern record_description SCode_Mod_NOMOD__desc;

extern record_description SCode_SubMod_NAMEMOD__desc;

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

MetaModelica::Value Modifier::toSCode() const noexcept
{
  if (_value) return _value->toSCode();
  return MetaModelica::Record(NOMOD, SCode_Mod_NOMOD__desc);
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
    _subMods{value[2].mapVector([](MetaModelica::Record v) {
      return Modifier::SubMod{v[0].toString(), v[1]};
    })},
    _binding{value[3].mapOptional<Expression>()},
    _info{value[4]}
{

}

BindingModifier::BindingModifier(Final finalPrefix, Each eachPrefix, std::vector<Modifier::SubMod> subMods,
  std::optional<Expression> binding, const SourceInfo &info) noexcept
  : _final(finalPrefix), _each(eachPrefix), _subMods(std::move(subMods)),
    _binding(std::move(binding)), _info(info)
{
}

MetaModelica::Value BindingModifier::toSCode() const noexcept
{
  return MetaModelica::Record(MOD, SCode_Mod_MOD__desc, {
    _final.toSCode(),
    _each.toSCode(),
    MetaModelica::List(_subMods, [](const auto &m) {
      return MetaModelica::Record(0, SCode_SubMod_NAMEMOD__desc, {
        MetaModelica::Value(m.first),
        m.second.toSCode()
      });
    }),
    MetaModelica::Option(_binding, [](const auto &b) { return b.toAbsyn(); }),
    _info
  });
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

MetaModelica::Value RedeclareModifier::toSCode() const noexcept
{
  return MetaModelica::Record(REDECL, SCode_Mod_REDECL__desc, {
    _final.toSCode(),
    _each.toSCode(),
    _element.toSCode()
  });
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
