#include "Absyn/Class.h"
#include "Absyn/ClassDef.h"
#include "Class.h"

using namespace OpenModelica;

extern record_description NFClass_PARTIAL__CLASS__desc;

constexpr int NOT_INSTANTIATED = 0;
constexpr int PARTIAL_CLASS = 1;
constexpr int PARTIAL_BUILTIN = 2;
constexpr int EXPANDED_CLASS = 3;
constexpr int EXPANDED_DERIVED = 4;
constexpr int INSTANCED_CLASS = 5;
constexpr int INSTANCED_BUILTIN = 6;
constexpr int TYPED_DERIVED = 7;
constexpr int DAE_TYPE = 8;

extern record_description NFModifier_Modifier_NOMOD__desc;
extern record_description NFClass_Prefixes_PREFIXES__desc;

std::unique_ptr<Class> Class::fromAbsyn(const Absyn::Class &cls, InstNode *scope)
{
  struct Visitor : public Absyn::ClassDefVisitor
  {
    Visitor(InstNode *scope) : scope{scope} {}

    void visit(const Absyn::ClassParts &def)
    {
      cls = std::make_unique<PartialClass>(def, false, scope);
    }

    //void visit(Absyn::ClassExtends &def) {
    //  classDef = std::make_unique<ClassTree>(def.composition(), true, scope);
    //}

    //void visit(Absyn::Enumeration &def) {
    //  classDef = std::make_unique<ClassTree>(def);
    //}

    InstNode *scope;
    std::unique_ptr<Class> cls;
  };

  Visitor visitor{scope};
  cls.definition().apply(visitor);
  return std::move(visitor.cls);
}

Class::~Class() = default;

PartialClass::PartialClass(const Absyn::ClassParts &definition, bool isClassExtends, InstNode *scope)
  : _elements{definition, isClassExtends, scope}
{

}

MetaModelica::Value PartialClass::toMetaModelica() const
{
  static const MetaModelica::Record emptyMod(2, NFModifier_Modifier_NOMOD__desc, {});

  return MetaModelica::Record(PARTIAL_CLASS, NFClass_PARTIAL__CLASS__desc, {
    _elements.toNF(),
    emptyMod,
    emptyMod,
    MetaModelica::Record(0, NFClass_Prefixes_PREFIXES__desc, {
      _prefixes.encapsulated.toSCode(),
      _prefixes.partial.toSCode(),
      _prefixes.final.toSCode(),
      _prefixes.innerOuter.toAbsyn(),
      _prefixes.replaceable.toSCode()
    })
  });
}
