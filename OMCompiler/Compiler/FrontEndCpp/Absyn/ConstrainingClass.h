#ifndef ABSYN_CONSTRAININGCLASS_H
#define ABSYN_CONSTRAININGCLASS_H

#include <iosfwd>

#include "MetaModelica.h"
#include "Path.h"

namespace OpenModelica::Absyn
{
  class ConstrainingClass
  {
    public:
      ConstrainingClass(MetaModelica::Record value);

      const Path& path() const noexcept { return _path; }

    private:
      Path _path;
  };

  std::ostream& operator<< (std::ostream &os, const ConstrainingClass &cc) noexcept;
}

#endif /* ABSYN_CONSTRAININGCLASS_H */
