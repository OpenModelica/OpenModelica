#ifndef ABSYN_TYPESPEC_H
#define ABSYN_TYPESPEC_H

#include <iosfwd>

#include "MetaModelica.h"
#include "Path.h"
#include "Subscript.h"

namespace OpenModelica::Absyn
{
  class TypeSpec
  {
    public:
      TypeSpec(MetaModelica::Record value);

      const Path& path() const noexcept;
      const std::vector<Subscript>& dimensions() const noexcept;

    private:
      Path _path;
      std::vector<Subscript> _arrayDims;
  };

  std::ostream& operator<< (std::ostream &os, const TypeSpec &typeSpec) noexcept;
}

#endif /* ABSYN_TYPESPEC_H */
