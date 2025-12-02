#include "ElementVisitor.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

void ElementVisitor::visit(Class &cls)
{
  visit(static_cast<Element&>(cls));
}

void ElementVisitor::visit(Component &comp)
{
  visit(static_cast<Element&>(comp));
}

void ElementVisitor::visit(DefineUnit &unit)
{
  visit(static_cast<Element&>(unit));
}

void ElementVisitor::visit(Extends &ext)
{
  visit(static_cast<Element&>(ext));
}

void ElementVisitor::visit(Import &imp)
{
  visit(static_cast<Element&>(imp));
}
