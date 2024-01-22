#include "Absyn/Class.h"
#include "Absyn/ClassDef.h"
#include "Class.h"

using namespace OpenModelica;

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
