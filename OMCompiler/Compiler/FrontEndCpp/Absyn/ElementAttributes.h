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

#ifndef ABSYN_ELEMENTATTRIBUTES_H
#define ABSYN_ELEMENTATTRIBUTES_H

#include <vector>
#include <iosfwd>

#include "MetaModelica.h"
#include "Prefixes.h"
#include "Subscript.h"

namespace OpenModelica::Absyn
{
  class ElementAttributes
  {
    public:
      explicit ElementAttributes(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;

      const std::vector<Subscript>& arrayDims() const noexcept { return _arrayDims; }
      ConnectorType connectorType() const noexcept { return _connectorType; }
      Parallelism parallelism() const noexcept { return _parallelism; }
      Variability variability() const noexcept { return _variability; }
      Direction direction() const noexcept { return _direction; }
      Field field() const noexcept { return _field; }

    private:
      std::vector<Subscript> _arrayDims;
      ConnectorType _connectorType;
      Parallelism _parallelism;
      Variability _variability;
      Direction _direction;
      Field _field;
  };

  std::ostream& operator<< (std::ostream &os, const ElementAttributes &attrs) noexcept;
}

#endif /* ABSYN_ELEMENTATTRIBUTES_H */
