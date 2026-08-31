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

#ifndef CLASS_H
#define CLASS_H

#include <optional>

#include "Absyn/AbsynFwd.h"
#include "Absyn/ConstrainingClass.h"
#include "Modifier.h"
#include "Attributes.h"
#include "Prefixes.h"
#include "Restriction.h"
#include "Type.h"
#include "ClassTree.h"

namespace OpenModelica
{
  class InstNode;

  class Class
  {
    public:
      struct Prefixes
      {
        Prefixes() = default;
        Prefixes(MetaModelica::Record value);

        MetaModelica::Value toNF() const noexcept;

        Encapsulated encapsulated;
        Partial partial;
        Final final;
        InnerOuter innerOuter;
        Replaceable<Absyn::ConstrainingClass> replaceable;
      };

    public:
      Class() = default;
      Class(MetaModelica::Record value);
      static std::unique_ptr<Class> fromMM(MetaModelica::Record value);
      static std::unique_ptr<Class> fromAbsyn(const Absyn::Class &cls, InstNode *scope);
      virtual ~Class();

      virtual std::unique_ptr<Class> clone() const = 0;

      bool add(std::unique_ptr<InstNode> node);

      virtual const ClassTree* classTree() const noexcept { return nullptr; }
      virtual ClassTree* classTree() noexcept { return nullptr; }

      virtual MetaModelica::Value toNF() const = 0;

    protected:
      Class(const Class&) = default;
      Class(Class&&) = default;
      Class& operator=(const Class&) = default;
      Class& operator=(Class&&) = default;

    protected:
      std::optional<MetaModelica::Record> _mm_value;
  };

  class PartialClass : public Class
  {
    public:
      explicit PartialClass(MetaModelica::Record value);
      PartialClass(const Absyn::ClassParts &definition, bool isClassExtends, InstNode *scope);

      std::unique_ptr<Class> clone() const override;

      const ClassTree* classTree() const noexcept override { return &_elements; }
      ClassTree* classTree() noexcept override { return &_elements; }

      MetaModelica::Value toNF() const override;

    private:
      ClassTree _elements;
      Modifier _modifier;
      Modifier _ccMod;
      Prefixes _prefixes;
  };

  class PartialBuiltin : public Class
  {
    public:
      explicit PartialBuiltin(MetaModelica::Record value);

      std::unique_ptr<Class> clone() const override;

      //const ClassTree* classTree() const noexcept override { return &_elements; }
      //ClassTree* classTree() noexcept override { return &_elements; }

      MetaModelica::Value toNF() const override;

    private:
      Type _ty;
      ClassTree _elements;
      Modifier _modifier;
      Prefixes _prefixes;
      Restriction _restriction;
  };

  class ExpandedClass : public Class
  {
    public:
      explicit ExpandedClass(MetaModelica::Record value);

      std::unique_ptr<Class> clone() const override;

      const ClassTree* classTree() const noexcept override { return &_elements; }
      ClassTree* classTree() noexcept override { return &_elements; }

      MetaModelica::Value toNF() const override;

    private:
      ClassTree _elements;
      Modifier _modifier;
      Modifier _ccMod;
      Prefixes _prefixes;
      Restriction _restriction;
  };

  class ExpandedDerived : public Class
  {
    public:
      ExpandedDerived(std::unique_ptr<InstNode> baseClass, Modifier modifier, Modifier ccMod,
        std::vector<Dimension> dims, Prefixes prefixes, Attributes attributes, Restriction restriction);
      explicit ExpandedDerived(MetaModelica::Record value);

      std::unique_ptr<Class> clone() const override;

      const ClassTree* classTree() const noexcept override;
      ClassTree* classTree() noexcept override;

      MetaModelica::Value toNF() const override;

    private:
      std::unique_ptr<InstNode> _baseClass;
      Modifier _modifier;
      Modifier _ccMod;
      std::vector<Dimension> _dims;
      Prefixes _prefixes;
      Attributes _attributes;
      Restriction _restriction;
  };

  class InstancedClass : public Class
  {
    public:
      explicit InstancedClass(MetaModelica::Record value);

      std::unique_ptr<Class> clone() const override;

      const ClassTree* classTree() const noexcept override { return &_elements; }
      ClassTree* classTree() noexcept override { return &_elements; }

      MetaModelica::Value toNF() const override;

    private:
      Type _ty;
      ClassTree _elements;
      MetaModelica::Value _sections;
      Prefixes _prefixes;
      Restriction _restriction;
  };

  class InstancedBuiltin : public Class
  {
    public:
      explicit InstancedBuiltin(MetaModelica::Record value);

      std::unique_ptr<Class> clone() const override;

      //const ClassTree* classTree() const noexcept override { return &_elements; }
      //ClassTree* classTree() noexcept override { return &_elements; }

      MetaModelica::Value toNF() const override;

    private:
      Type _ty;
      ClassTree _elements;
      Restriction _restriction;
  };

  class TypedDerived : public Class
  {
    public:
      TypedDerived(Type ty, std::unique_ptr<InstNode> baseClass, Restriction restriction);
      explicit TypedDerived(MetaModelica::Record value);

      std::unique_ptr<Class> clone() const override;

      const ClassTree* classTree() const noexcept override;
      ClassTree* classTree() noexcept override;

      MetaModelica::Value toNF() const override;

    private:
      Type _ty;
      std::unique_ptr<InstNode> _baseClass;
      Restriction _restriction;
  };

  class DAEType : public Class
  {
    public:
      explicit DAEType(MetaModelica::Record value);

      std::unique_ptr<Class> clone() const override;

      MetaModelica::Value toNF() const override;

    private:
      Type _ty;
  };
}

#endif /* CLASS_H */
