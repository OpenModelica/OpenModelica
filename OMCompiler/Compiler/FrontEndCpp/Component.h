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

#ifndef COMPONENT_H
#define COMPONENT_H

#include <memory>

#include "Absyn/AbsynFwd.h"
#include "Attributes.h"
#include "Binding.h"
#include "Modifier.h"
#include "Prefixes.h"
#include "Type.h"

namespace OpenModelica
{
  class InstNode;

  class Component
  {
    public:
      Component(Absyn::Component *definition);
      virtual ~Component();

      virtual std::unique_ptr<Component> clone() const = 0;

      static std::unique_ptr<Component> fromMM(MetaModelica::Record value);
      virtual MetaModelica::Value toNF() const noexcept = 0;

      virtual const InstNode* classInstance() const noexcept { return nullptr; }
      virtual InstNode* classInstance() noexcept {return nullptr; }

      virtual const Type& type() const noexcept { return Type::UnknownType; }

      virtual ConnectorType connectorType() const noexcept { return ConnectorType::None; }
      bool isExpandableConnector() const noexcept;

    protected:
      Component(const Component&) = default;
      Component(Component&&) noexcept = default;
      Component& operator=(const Component&) = default;
      Component& operator=(Component&&) noexcept = default;

    protected:
      Absyn::Component *_definition;
  };

  class ComponentDef : public Component
  {
    public:
      ComponentDef(MetaModelica::Record value);
      ComponentDef(Absyn::Component *component);

      std::unique_ptr<Component> clone() const override;

      MetaModelica::Value toNF() const noexcept override;

    private:
      Modifier _modifier;
  };

  class NormalComponent : public Component
  {
    public:
      enum class State
      {
        PartiallyInstantiated, // Component instance has been created.
        FullyInstantiated,     // All component expressions have been instantiated.
        Typed,                 // The component's type has been determined.
        TypeChecked            // The component's binding has been typed and type checked.
      };

    public:
      NormalComponent(MetaModelica::Record value);
      NormalComponent(Absyn::Component *definition, std::unique_ptr<InstNode> classInst, Type ty,
                      Binding binding, Binding condition, Attributes attributes, Absyn::Comment *comment,
                      State state, SourceInfo info);

      std::unique_ptr<Component> clone() const override;

      MetaModelica::Value toNF() const noexcept override;

      const InstNode* classInstance() const noexcept override;
      InstNode* classInstance() noexcept override;

      const Type& type() const noexcept override;

      ConnectorType connectorType() const noexcept override;

    private:
      std::unique_ptr<InstNode> _classInst;
      Type _ty;
      Binding _binding;
      Binding _condition;
      Attributes _attributes;
      Absyn::Comment *_comment;
      State _state = State::PartiallyInstantiated;
      SourceInfo _info;
  };

  class MMComponent : public Component
  {
    public:
      MMComponent(MetaModelica::Record value);

      std::unique_ptr<Component> clone() const override;
      MetaModelica::Value toNF() const noexcept override;

    private:
      MetaModelica::Record _value;
  };
}

#endif /* COMPONENT_H */
