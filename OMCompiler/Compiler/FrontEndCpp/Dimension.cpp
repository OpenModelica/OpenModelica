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
#include <stdexcept>

#include "Prefixes.h"

#include "Dimension.h"

using namespace OpenModelica;

constexpr int RAW_DIM = 0;
constexpr int UNTYPED = 1;
constexpr int INTEGER = 2;
constexpr int BOOLEAN = 3;
constexpr int ENUM = 4;
constexpr int EXP = 5;
constexpr int RESIZABLE = 6;
constexpr int UNKNOWN = 7;

extern record_description NFDimension_RAW__DIM__desc;
extern record_description NFDimension_UNTYPED__desc;
extern record_description NFDimension_INTEGER__desc;
extern record_description NFDimension_BOOLEAN__desc;
extern record_description NFDimension_ENUM__desc;
extern record_description NFDimension_EXP__desc;
extern record_description NFDimension_RESIZABLE__desc;
extern record_description NFDimension_UNKNOWN__desc;

std::unique_ptr<int> dimension_from_mm(MetaModelica::Record value)
{
  switch (value.index()) {
    case INTEGER: return std::make_unique<int>(value[0].toInt());
    case BOOLEAN: return std::make_unique<int>(2);
  }

  throw std::runtime_error("Unhandled record index in Dimension::Dimension");
}

Dimension::Dimension() = default;

Dimension::Dimension(MetaModelica::Record value)
  : _dim{dimension_from_mm(value)}
{

}

Dimension::Dimension(int size)
  : _dim{std::make_unique<int>(size)}
{

}

Dimension::Dimension(const Dimension &other)
  : _dim{other._dim ? std::make_unique<int>(*other._dim) : nullptr}
{

}

Dimension::Dimension(Dimension &&other) = default;

Dimension::~Dimension() = default;

Dimension& Dimension::operator= (Dimension other)
{
  swap(*this, other);
  return *this;
}

MetaModelica::Value Dimension::toNF() const
{
  return MetaModelica::Record{INTEGER, NFDimension_INTEGER__desc, {
    MetaModelica::Value{static_cast<int64_t>(*_dim)},
    Variability{Variability::Constant}.toNF()
  }};
}

std::optional<int> Dimension::size() const noexcept
{
  return _dim ? std::make_optional(*_dim) : std::nullopt;
}

void OpenModelica::swap(Dimension &first, Dimension &second) noexcept
{
  using std::swap;
  swap(first._dim, second._dim);
}

std::ostream& OpenModelica::operator<< (std::ostream &os, const Dimension &dim)
{
  auto size = dim.size();
  os << (size ? *size : ':');
  return os;
}
