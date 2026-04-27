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

#include "TypeSpec.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

constexpr int TPATH = 0;
constexpr int TCOMPLEX = 1;

extern record_description Absyn_TypeSpec_TPATH__desc;
extern record_description Absyn_TypeSpec_TCOMPLEX__desc;

TypeSpec::TypeSpec(MetaModelica::Record value)
  : _path{value[0]}
{
  if (value.index() == TPATH) {
    if (value[1].toOption()) {
      _arrayDims = value[1].toOption()->mapVector<Subscript>();
    }
  } else {
    // MetaModelica extension, but polymorphic is used in ModelicaBuiltin.
    _typeSpecs = value[1].mapVector<TypeSpec>();

    if (value[2].toOption()) {
      _arrayDims = value[2].toOption()->mapVector<Subscript>();
    }
  }
}

MetaModelica::Value TypeSpec::toAbsyn() const noexcept
{
  if (_typeSpecs.empty()) {
    return MetaModelica::Record{TPATH, Absyn_TypeSpec_TPATH__desc, {
      _path.toAbsyn(),
      _arrayDims.empty() ?  MetaModelica::Option{} : MetaModelica::Option{Subscript::toAbsynList(_arrayDims)}
    }};
  } else {
    return MetaModelica::Record{TCOMPLEX, Absyn_TypeSpec_TCOMPLEX__desc, {
      _path.toAbsyn(),
      MetaModelica::List{_typeSpecs, [](const auto &ty) { return ty.toAbsyn(); }},
      _arrayDims.empty() ?  MetaModelica::Option{} : MetaModelica::Option{Subscript::toAbsynList(_arrayDims)}
    }};
  }
}

const Path& TypeSpec::path() const noexcept
{
  return _path;
}

const std::vector<Subscript>& TypeSpec::dimensions() const noexcept
{
  return _arrayDims;
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const TypeSpec &typeSpec) noexcept
{
  os << typeSpec.path() << typeSpec.dimensions();
  return os;
}
