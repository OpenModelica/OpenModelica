#ifndef ABSYN_CONSTRAININGCLASS_H
#define ABSYN_CONSTRAININGCLASS_H

#include <iosfwd>

#include "MetaModelica.h"
#include "Path.h"
#include "Modifier.h"
#include "Comment.h"

namespace OpenModelica::Absyn
{
  class ConstrainingClass
  {
    public:
      ConstrainingClass(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;

      const Path& path() const noexcept { return _path; }

    private:
      Path _path;
      Modifier _modifier;
      Comment _comment;
  };

  std::ostream& operator<< (std::ostream &os, const ConstrainingClass &cc) noexcept;
}

#endif /* ABSYN_CONSTRAININGCLASS_H */
