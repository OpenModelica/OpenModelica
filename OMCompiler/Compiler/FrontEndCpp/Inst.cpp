#include <iostream>

#include "MetaModelica.h"
#include "Absyn/Element.h"
#include "Inst.h"

#include "Absyn/Expression.h"

using namespace OpenModelica;

void Inst_test(void *scode)
{
  MetaModelica::Value value(scode);

  for (auto e: value.toList()) {
    std::cout << Absyn::Element{e} << ';' << std::endl;
  }
}
