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

#ifndef CLASSNODE_H
#define CLASSNODE_H

#include "InstNode.h"

#include <optional>

namespace OpenModelica
{
  class ClassNode : public InstNode
  {
    public:
      ClassNode(MetaModelica::Record value);
      ClassNode(Absyn::Class *cls, InstNode *parent);
      ClassNode(Absyn::Class *cls, InstNode *parent, std::unique_ptr<InstNodeType> nodeType);
      ClassNode(std::string name, Absyn::Class *definition, Visibility visibility,
                std::unique_ptr<Class> cls, InstNode *parentScope, std::unique_ptr<InstNodeType> nodeType);
      ~ClassNode();

      std::unique_ptr<InstNode> clone() const override;

      //const Class* getClass() const noexcept override;

      const std::string& name() const noexcept override { return _name; }
      const Absyn::Element* definition() const noexcept override;

      const InstNodeType* nodeType() const noexcept override;
      void setNodeType(std::unique_ptr<InstNodeType> nodeType) noexcept override;

      void setParent(InstNode *parent) noexcept override;

      const Class* getClass() const noexcept override;
      Class* getClass() noexcept override;

      void partialInst() override;
      void expand() override;
      void instantiate() override;

      MetaModelica::Value toNF() const override;

    protected:
      void initialize() override;

    private:
      std::string _name;
      Absyn::Class *_definition;
      Visibility _visibility;
      // TODO: Change to unique_ptr once conversion from MetaModelica is no longer needed.
      std::shared_ptr<Class> _cls;
      // array<CachedData> caches;
      InstNode *_parentScope [[maybe_unused]];
      std::unique_ptr<InstNodeType> _nodeType;

      mutable std::optional<MetaModelica::Record> _mmCache;

      friend class MMSharedCache<Class>;
      static MMSharedCache<Class> _cache;
  };
}

#endif /* CLASSNODE_H */
