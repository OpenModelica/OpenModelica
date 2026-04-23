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

#ifndef INSTNODE_H
#define INSTNODE_H

#include "Absyn/AbsynFwd.h"
#include "MetaModelica.h"
#include "InstNodeType.h"

#include <memory>

namespace OpenModelica
{
  class Class;

  class InstNode
  {
    public:
      static constexpr int CLASS_NODE = 0;
      static constexpr int COMPONENT_NODE = 1;
      static constexpr int INNER_OUTER_NODE = 2;
      static constexpr int REF_NODE = 3;
      static constexpr int NAME_NODE = 4;
      static constexpr int IMPLICIT_SCOPE = 5;
      static constexpr int ITERATOR_NODE = 6;
      static constexpr int VAR_NODE = 7;
      static constexpr int EMPTY_NODE = 8;

      static MetaModelica::Value emptyMMNode();

    public:
      virtual ~InstNode() = default;

      bool isComponent() const noexcept { return false; }
      bool isClass() const noexcept { return false; }
      bool isRef() const noexcept { return false; }
      bool isRedeclare() const noexcept { return false; }

      virtual const std::string& name() const noexcept = 0;
      virtual Absyn::Element* definition() const noexcept = 0;
      int refIndex() const noexcept { return 0; }

      virtual const InstNodeType* nodeType() const noexcept { return nullptr; }
      virtual void setNodeType(std::unique_ptr<InstNodeType>) noexcept {};

      virtual const Class* getClass() const noexcept { return nullptr; }

      virtual void partialInst() {};
      virtual void expand() {};
      virtual void instantiate() {};

      virtual MetaModelica::Value toMetaModelica() const = 0;
  };


}

#endif /* INSTNODE_H */
