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

#include <ostream>

#include "ElementPrefixes.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_Prefixes_PREFIXES__desc;

ElementPrefixes::ElementPrefixes(MetaModelica::Record value)
  : _visibility{value[0]},
    _redeclare{value[1]},
    _final{value[2]},
    _innerOuter{value[3]},
    _replaceable{value[4]}
{

}

MetaModelica::Value ElementPrefixes::toSCode() const noexcept
{
  return MetaModelica::Record{0, SCode_Prefixes_PREFIXES__desc, {
    _visibility.toSCode(),
    _redeclare.toSCode(),
    _final.toSCode(),
    _innerOuter.toAbsyn(),
    _replaceable.toSCode()
  }};
}

void ElementPrefixes::print(std::ostream &os, Each each) const noexcept
{
  os << _redeclare.unparse() << each.unparse() << _final.unparse() <<
        _innerOuter.unparse() << _replaceable.unparse();
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const ElementPrefixes &prefixes)
{
  prefixes.print(os);
  return os;
}
