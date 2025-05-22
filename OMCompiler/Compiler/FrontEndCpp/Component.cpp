#include "Absyn/Component.h"
#include "Component.h"

using namespace OpenModelica;

extern record_description NFComponent_COMPONENT__DEF__desc;
extern record_description NFComponent_COMPONENT__desc;
extern record_description NFComponent_ITERATOR__desc;
extern record_description NFComponent_ENUM__LITERAL__desc;
extern record_description NFComponent_TYPE__ATTRIBUTE__desc;
extern record_description NFComponent_INVALID_COMPONENT__desc;
extern record_description NFComponent_WILD__desc;

constexpr int COMPONENT_DEF = 0;
constexpr int COMPONENT = 1;
constexpr int ITERATOR = 2;
constexpr int ENUM_LITERAL = 3;
constexpr int TYPE_ATTRIBUTE = 4;
constexpr int INVALID_COMPONENT = 5;
constexpr int WILD = 6;

extern record_description NFModifier_Modifier_NOMOD__desc;
const MetaModelica::Record emptyMod(2, NFModifier_Modifier_NOMOD__desc, {});

Component::Component(Absyn::Component *definition)
  : _definition{definition}
{

}

ComponentDef::ComponentDef(Absyn::Component *definition)
  : Component(definition)
{

}

MetaModelica::Value ComponentDef::toNF() const noexcept
{
  return MetaModelica::Record{COMPONENT_DEF, NFComponent_COMPONENT__DEF__desc, {
    _definition->toSCode(),
    emptyMod
  }};
}
