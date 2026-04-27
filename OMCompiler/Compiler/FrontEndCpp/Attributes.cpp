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

#include "Absyn/ElementAttributes.h"
#include "Absyn/ElementPrefixes.h"
#include "Attributes.h"

using namespace OpenModelica;

constexpr int ATTRIBUTES_CONNECTOR_TYPE = 0;
constexpr int ATTRIBUTES_PARALLELISM = 1;
constexpr int ATTRIBUTES_VARIABILITY = 2;
constexpr int ATTRIBUTES_DIRECTION = 3;
constexpr int ATTRIBUTES_INNER_OUTER = 4;
constexpr int ATTRIBUTES_IS_FINAL = 5;
constexpr int ATTRIBUTES_IS_REDECLARE = 6;
constexpr int ATTRIBUTES_REPLACEABLE = 7;
constexpr int ATTRIBUTES_IS_RESIZABLE = 8;

extern record_description NFAttributes_ATTRIBUTES__desc;

Attributes::Attributes(MetaModelica::Record value)
  : connectorType{value[ATTRIBUTES_CONNECTOR_TYPE]},
    parallelism{value[ATTRIBUTES_PARALLELISM]},
    variability{value[ATTRIBUTES_VARIABILITY]},
    direction{value[ATTRIBUTES_DIRECTION]},
    innerOuter{value[ATTRIBUTES_INNER_OUTER]},
    isFinal{value[ATTRIBUTES_IS_FINAL].toBool()},
    isRedeclare{value[ATTRIBUTES_IS_REDECLARE].toBool()},
    isResizable{value[ATTRIBUTES_IS_RESIZABLE].toBool()}
{

}

Attributes::Attributes(const Absyn::ElementAttributes &attrs, const Absyn::ElementPrefixes &prefs)
  : connectorType{attrs.connectorType()},
    parallelism{attrs.parallelism()},
    variability{attrs.variability()},
    direction{attrs.direction()},
    innerOuter{prefs.innerOuter()},
    isFinal{prefs.final()},
    isRedeclare{prefs.redeclare()},
    isResizable{false}
{

}

MetaModelica::Value Attributes::toNF() const
{
  return MetaModelica::Record{0, NFAttributes_ATTRIBUTES__desc, {
    connectorType.toNF(),
    parallelism.toNF(),
    variability.toNF(),
    direction.toNF(),
    innerOuter.toNF(),
    MetaModelica::Value{isFinal},
    MetaModelica::Value{isRedeclare},
    replaceable.toNF(),
    MetaModelica::Value{isResizable}
  }};
}
