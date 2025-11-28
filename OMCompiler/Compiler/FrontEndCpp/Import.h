#ifndef IMPORT_H
#define IMPORT_H

#include "Absyn/AbsynFwd.h"
#include "MetaModelica.h"

namespace OpenModelica
{
  class InstNode;

  class Import
  {
    public:
      Import(Absyn::Import *absyn, InstNode *scope);

      MetaModelica::Record toNF() const;

    private:
      Absyn::Import *_absyn = nullptr;
      InstNode *_scope = nullptr;
      InstNode *_node = nullptr;
  };
}

#endif /* IMPORT_H */
