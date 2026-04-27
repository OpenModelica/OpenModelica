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

#include <cassert>
#include <ostream>

#include "Util.h"
#include "Subscript.h"

using namespace OpenModelica;

constexpr int RAW_SUBSCRIPT_INDEX = 0;
constexpr int UNTYPED_INDEX = 1;
constexpr int INDEX_INDEX = 2;
constexpr int SLICE_INDEX = 3;
constexpr int EXPANDED_SLICE_INDEX = 4;
constexpr int WHOLE_INDEX = 5;
constexpr int SPLIT_PROXY_INDEX = 6;
constexpr int SPLIT_INDEX_INDEX = 7;

extern record_description NFSubscript_RAW__SUBSCRIPT__desc;
extern record_description NFSubscript_UNTYPED__desc;
extern record_description NFSubscript_INDEX__desc;
extern record_description NFSubscript_SLICE__desc;
extern record_description NFSubscript_EXPANDED__SLICE__desc;
extern record_description NFSubscript_WHOLE__desc;
extern record_description NFSubscript_SPLIT__PROXY__desc;
extern record_description NFSubscript_SPLIT__INDEX__desc;

extern record_description NFExpression_INTEGER__desc;

Subscript::Subscript(MetaModelica::Record value)
{
  assert(value.index() == INDEX_INDEX);

  if (value.index() == INDEX_INDEX) {
    auto index_exp = value[0].toRecord();
    _index = index_exp[0].toInt();
  }
}

Subscript::~Subscript() = default;

Subscript::operator MetaModelica::Value() const
{
  return MetaModelica::Record{INDEX_INDEX, NFSubscript_INDEX__desc, {
    MetaModelica::Record{0 /*INTEGER*/, NFExpression_INTEGER__desc, {MetaModelica::Value{_index}}}
  }};
}

std::string Subscript::str() const
{
  return std::to_string(_index);
}

std::size_t Subscript::hash() const noexcept
{
  return _index;
}

bool OpenModelica::operator== (const Subscript &subscript1, const Subscript &subscript2)
{
  return subscript1.index() == subscript2.index();
}

std::ostream& OpenModelica::operator<< (std::ostream &os, const Subscript &subscript)
{
  os << subscript.index();
  return os;
}

std::ostream& OpenModelica::operator<< (std::ostream &os, const std::vector<Subscript> &subscripts)
{
  if (!subscripts.empty()) {
    os << '[' << Util::printList(subscripts) << ']';
  }

  return os;
}
