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

#ifndef ABSYN_ELEMENTPREFIXES_H
#define ABSYN_ELEMENTPREFIXES_H

#include <iosfwd>

#include "Prefixes.h"
#include "ConstrainingClass.h"
#include "MetaModelica.h"

namespace OpenModelica::Absyn
{
  class ElementPrefixes
  {
    public:
      ElementPrefixes() = default;
      ElementPrefixes(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;

      Visibility visibility() const noexcept { return _visibility; }
      Redeclare redeclare() const noexcept { return _redeclare; }
      Final final() const noexcept { return _final; }
      InnerOuter innerOuter() const noexcept { return _innerOuter; }
      const Replaceable<ConstrainingClass>& replaceable() const noexcept { return _replaceable; }

      void print(std::ostream &os, Each each = Each()) const noexcept;

    private:
      Visibility _visibility;
      Redeclare _redeclare;
      Final _final;
      InnerOuter _innerOuter;
      Replaceable<ConstrainingClass> _replaceable;
  };

  std::ostream& operator<< (std::ostream& os, const ElementPrefixes &prefixes);
}

#endif /* ELEMENTPREFIXES_H */
