#include <cassert>

#include "Absyn/Import.h"
#include "InstNode.h"
#include "Import.h"

using namespace OpenModelica;

extern record_description NFImport_UNRESOLVED__IMPORT__desc;
extern record_description NFImport_RESOLVED__IMPORT__desc;
extern record_description NFImport_CONFLICTING__IMPORT__desc;

constexpr int UNRESOLVED_IMPORT = 0;
constexpr int RESOLVED_IMPORT = 1;
constexpr int CONFLICTING_IMPORT = 2;

Import::Import(Absyn::Import *absyn, InstNode *scope)
  : _absyn{absyn}, _scope{scope}
{

}

MetaModelica::Record Import::toNF() const
{
  if (!_node) {
    assert(_scope);
    return MetaModelica::Record{UNRESOLVED_IMPORT, NFImport_UNRESOLVED__IMPORT__desc, {
      _absyn->toSCode(),
      _scope->toMetaModelica(),
      _absyn->info()
    }};
  } else {
    assert(_node);
    return MetaModelica::Record{RESOLVED_IMPORT, NFImport_RESOLVED__IMPORT__desc, {
      _node->toMetaModelica(),
      MetaModelica::Value{_absyn->importPath().shortName()},
      _absyn->info()
    }};
  }
}
