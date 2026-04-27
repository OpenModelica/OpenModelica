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

#include "Binding.h"

using namespace OpenModelica;

extern record_description NFBinding_UNBOUND__desc;
extern record_description NFBinding_RAW_BINDING__desc;
extern record_description NFBinding_UNTYPED_BINDING__desc;
extern record_description NFBinding_TYPED_BINDING__desc;
extern record_description NFBinding_FLAT_BINDING__desc;
extern record_description NFBinding_CEVAL_BINDING__desc;
extern record_description NFBinding_INVALID_BINDING__desc;
extern record_description NFBinding_WILD__desc;

constexpr int UNBOUND = 0;
constexpr int RAW_BINDING = 1;
constexpr int UNTYPED_BINDING = 2;
constexpr int TYPED_BINDING = 3;
constexpr int FLAT_BINDING = 4;
constexpr int CEVAL_BINDING = 5;
constexpr int INVALID_BINDING = 6;
constexpr int WILD = 7;

Binding::Binding()
  : _value{nullptr}
{

}

MetaModelica::Value Binding::toNF() const
{
  return _value.data() ? _value : MetaModelica::Record{UNBOUND, NFBinding_UNBOUND__desc, {}};
}
