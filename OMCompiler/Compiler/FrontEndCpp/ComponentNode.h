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

#ifndef COMPONENTNODE_H
#define COMPONENTNODE_H

#include <memory>
#include <optional>

#include "Absyn/AbsynFwd.h"
#include "InstNode.h"
#include "Prefixes.h"

namespace OpenModelica
{
  class Component;

  class ComponentNode : public InstNode
  {
    public:
      ComponentNode(MetaModelica::Record value);
      ComponentNode(Absyn::Component *definition, InstNode *parent);
      ComponentNode(Absyn::Component *definition, InstNode *parent, std::unique_ptr<InstNodeType> nodeType);
      ComponentNode(std::string name, Absyn::Component *definition, Visibility visibility,
                    std::unique_ptr<Component> _component, InstNode *parent, std::unique_ptr<InstNodeType> nodeType);
      ~ComponentNode();

      std::unique_ptr<InstNode> clone() const override;

      bool isComponent() const noexcept override { return true; }

      const std::string& name() const noexcept override { return _name; }
      Path scopePath() const override;
      const Absyn::Element* definition() const noexcept override;

      const InstNodeType* nodeType() const noexcept override;
      void setNodeType(std::unique_ptr<InstNodeType> nodeType) noexcept override;

      void setParent(InstNode *parent) noexcept override;

      const Class* getClass() const noexcept override;
      Class* getClass() noexcept override;

      const Type& type() const noexcept override;

      bool isExpandableConnector() const noexcept override;

      MetaModelica::Value toNF() const override;

    private:
      void initialize() override;

    private:
      std::string _name;
      Absyn::Component *_definition;
      Visibility _visibility;
      std::shared_ptr<Component> _component;
      InstNode *_parent;
      std::unique_ptr<InstNodeType> _nodeType;

      mutable std::optional<MetaModelica::Record> _mmCache;

      friend class MMSharedCache<Component>;
      static MMSharedCache<Component> _cache;
  };
}

#endif /* COMPONENTNODE_H */
