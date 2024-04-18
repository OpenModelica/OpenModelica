#ifndef ABSYN_IMPORT_H
#define ABSYN_IMPORT_H

#include <iosfwd>

#include "MetaModelica.h"
#include "Element.h"
#include "ImportPath.h"
#include "../Prefixes.h"

namespace OpenModelica::Absyn
{
  class Import : public Element::Base
  {
    public:
      Import(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept override;

      std::unique_ptr<Element::Base> clone() const noexcept override;
      void print(std::ostream &os, Each each) const noexcept override;

    private:
      ImportPath _path;
      Visibility _visibility;
  };
}

#endif /* ABSYN_IMPORT_H */
