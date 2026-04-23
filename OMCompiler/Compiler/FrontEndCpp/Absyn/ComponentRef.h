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

#ifndef ABSYN_COMPONENTREF_H
#define ABSYN_COMPONENTREF_H

#include <string>
#include <utility>
#include <vector>
#include <iosfwd>

#include "MetaModelica.h"

namespace OpenModelica::Absyn
{
  class Subscript;

  class ComponentRef
  {
    public:
      using Part = std::pair<std::string, std::vector<Subscript>>;

    public:
      ComponentRef(std::vector<Part> parts, bool fullyQualified = false);
      explicit ComponentRef(MetaModelica::Record value);
      ~ComponentRef();

      MetaModelica::Value toAbsyn() const noexcept;

      void push_back(Part part) noexcept;

      bool isIdent() const noexcept;
      bool isQualified() const noexcept;
      bool isFullyQualified() const noexcept;
      bool isWild() const noexcept;

      const Part& first() const;
      ComponentRef rest() const;
      ComponentRef fullyQualify() const noexcept;
      ComponentRef unqualify() const noexcept;

      std::string str() const noexcept;

      friend std::ostream& operator<< (std::ostream &os, const ComponentRef &cref);

    private:
      std::vector<Part> _parts;
      bool _fullyQualified;
  };

  std::ostream& operator<< (std::ostream &os, const ComponentRef &cref);
}

#endif /* ABSYN_COMPONENTREF_H */
