#ifndef ELEMENTVISITOR_H
#define ELEMENTVISITOR_H

#include "Class.h"
#include "Component.h"
#include "DefineUnit.h"
#include "Extends.h"
#include "Import.h"

namespace OpenModelica::Absyn
{
  struct ElementVisitor
  {
    virtual void visit(Element &) {};
    virtual void visit(Class &cls);
    virtual void visit(Component &comp);
    virtual void visit(DefineUnit &unit);
    virtual void visit(Extends &ext);
    virtual void visit(Import &imp);
  };
}

#endif /* ELEMENTVISITOR_H */
