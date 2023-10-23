#include <utility>
#include <stdexcept>
#include <ostream>

#include "Util.h"
#include "ImportPath.h"

constexpr int NAMED_IMPORT = 0;
constexpr int QUAL_IMPORT = 1;
constexpr int UNQUAL_IMPORT = 2;
constexpr int GROUP_IMPORT = 3;

constexpr int GROUP_IMPORT_NAME = 0;

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

std::pair<std::optional<Path>, std::vector<std::string>> splitPath(MetaModelica::Value value)
{
  Path p{value};
  std::vector<std::string> def_names{p.back()};

  std::optional<Path> op;
  if (p.isQualified()) {
    p.pop_back();
    op = std::make_optional<Path>(std::move(p));
  }

  return std::pair(std::move(op), std::move(def_names));
}

ImportPath::ImportPath(MetaModelica::Record value)
{
  switch (value.index()) {
    // import shortName = pkgName.defName;
    case NAMED_IMPORT:
      _shortName = value[0].toString();
      std::tie(_pkgName, _defNames) = splitPath(value[1]);
      break;

    // import pkgName.defName;
    case QUAL_IMPORT:
      std::tie(_pkgName, _defNames) = splitPath(value[0]);
      break;

    // import pkgName.*;
    case UNQUAL_IMPORT:
      _pkgName = std::make_optional<Path>(value[0]);
      break;

    // import pkgName.{defName1, defName2, ...};
    case GROUP_IMPORT:
      _pkgName = std::make_optional<Path>(value[0]);

      for (auto e: value[1].toList()) {
        auto rec = e.toRecord();
        if (rec.index() == GROUP_IMPORT_NAME) {
          _defNames.push_back(rec[0].toString());
        } else {
          // MetaModelica extension.
          throw std::runtime_error("Absyn.GroupImport.GROUP_IMPORT_RENAME not supported");
        }
      }
      break;
  }
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const ImportPath &path)
{
  if (!path.shortName().empty()) {
    os << path.shortName() << " = ";
  }

  if (path.packageName()) {
    os << *path.packageName() << '.';
  }

  switch (path.definitionNames().size()) {
    case 0:  os << '*'; break;
    case 1:  os << path.definitionNames().front(); break;
    default: os << '{' << Util::printList(path.definitionNames(), ",") << '}'; break;
  }

  return os;
}
