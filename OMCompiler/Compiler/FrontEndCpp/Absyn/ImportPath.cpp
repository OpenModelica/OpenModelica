#include <utility>
#include <stdexcept>
#include <ostream>

#include "Util.h"
#include "ImportPath.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

constexpr int NAMED_IMPORT = 0;
constexpr int QUAL_IMPORT = 1;
constexpr int UNQUAL_IMPORT = 2;
constexpr int GROUP_IMPORT = 3;

constexpr int GROUP_IMPORT_NAME = 0;

extern record_description Absyn_Import_NAMED__IMPORT__desc;
extern record_description Absyn_Import_QUAL__IMPORT__desc;
extern record_description Absyn_Import_UNQUAL__IMPORT__desc;
extern record_description Absyn_Import_GROUP__IMPORT__desc;

extern record_description Absyn_GroupImport_GROUP__IMPORT__NAME__desc;

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

MetaModelica::Value ImportPath::toAbsyn() const noexcept
{
  if (!_shortName.empty()) {
    return MetaModelica::Record(NAMED_IMPORT, Absyn_Import_NAMED__IMPORT__desc, {
      MetaModelica::Value(_shortName),
      fullPath().toAbsyn()
    });
  }

  switch (_defNames.size()) {
    case 0:
      return MetaModelica::Record(UNQUAL_IMPORT, Absyn_Import_UNQUAL__IMPORT__desc, {
        _pkgName->toAbsyn()
      });

    case 1:
      return MetaModelica::Record(QUAL_IMPORT, Absyn_Import_QUAL__IMPORT__desc, {
        fullPath().toAbsyn()
      });

    default:
      return MetaModelica::Record(GROUP_IMPORT, Absyn_Import_GROUP__IMPORT__desc, {
        _pkgName->toAbsyn(),
        MetaModelica::List(_defNames, [](const auto &n) {
          return MetaModelica::Record(GROUP_IMPORT_NAME, Absyn_GroupImport_GROUP__IMPORT__NAME__desc, {
            MetaModelica::Value(n)
          });
        })
      });
  }
}

Path ImportPath::fullPath() const noexcept
{
  auto p = _pkgName ? *_pkgName : Path(_defNames.front());

  if (_defNames.size() == 1 && _pkgName) {
    p.push_back(_defNames.front());
  }

  return p;
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
