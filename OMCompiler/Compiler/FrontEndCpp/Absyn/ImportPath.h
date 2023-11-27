#ifndef ABSYN_IMPORTPATH_H
#define ABSYN_IMPORTPATH_H

#include <optional>
#include <vector>
#include <string>
#include <iosfwd>

#include "MetaModelica.h"
#include "Path.h"

namespace OpenModelica::Absyn
{
  class ImportPath
  {
    public:
      ImportPath(MetaModelica::Record value);

      MetaModelica::Value toAbsyn() const noexcept;

      const std::optional<Path>& packageName() const noexcept { return _pkgName; }
      const std::vector<std::string>& definitionNames() const noexcept { return _defNames; }
      const std::string& shortName() const noexcept { return _shortName; }
      Path fullPath() const noexcept;

    private:
      std::optional<Path> _pkgName;
      std::vector<std::string> _defNames;
      std::string _shortName;
  };

  std::ostream& operator<< (std::ostream &os, const ImportPath &path);
}

#endif /* ABSYN_IMPORTPATH_H */
