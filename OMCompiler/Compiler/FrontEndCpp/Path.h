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

#ifndef PATH_H
#define PATH_H

#include <cstddef>
#include <string>
#include <vector>
#include <utility>
#include <string_view>
#include <iosfwd>

#include "MetaModelica.h"

namespace OpenModelica
{
  class Path
  {
    public:
      Path(std::vector<std::string> path, bool fullyQualified = false);
      Path(std::string name, bool fullyQualified = false);
      Path(MetaModelica::Record value);

      static Path parseString(std::string_view path);

      MetaModelica::Value toAbsyn() const noexcept;

      void pushBack(std::string name);
      void popBack();

      std::size_t size() const noexcept;
      bool isIdent() const noexcept;
      bool isQualified() const noexcept;
      bool isFullyQualified() const noexcept;

      const std::string& front() const noexcept;
      const std::string& back() const noexcept;
      Path rest() const noexcept;
      std::pair<std::string, Path> splitFront() const noexcept;
      std::pair<Path, std::string> splitBack() const noexcept;
      Path fullyQualify() const noexcept;
      Path unqualify() const noexcept;

      std::string str() const;

      friend std::ostream& operator<< (std::ostream &os, const Path &path);

    private:
      std::vector<std::string> _names;
      bool _fullyQualified = false;
  };

  std::ostream& operator<< (std::ostream &os, const Path &path);
}

#endif /* PATH_H */
