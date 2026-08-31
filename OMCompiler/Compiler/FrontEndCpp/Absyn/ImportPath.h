/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

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
