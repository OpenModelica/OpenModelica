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

#include "Absyn/AbsynFwd.h"
#include "Absyn/ConstrainingClass.h"
#include "Prefixes.h"
#include "ClassTree.h"

namespace OpenModelica
{
  class InstNode;

  class Class
  {
    public:
      struct Prefixes
      {
        Encapsulated encapsulated;
        Partial partial;
        Final final;
        InnerOuter innerOuter;
        Replaceable<Absyn::ConstrainingClass> replaceable;
      };

    public:
      static std::unique_ptr<Class> fromAbsyn(const Absyn::Class &cls, InstNode *scope);
      virtual ~Class();

      virtual const ClassTree* classTree() const noexcept { return nullptr; }

      virtual MetaModelica::Value toMetaModelica() const = 0;
  };

  class PartialClass : public Class
  {
    public:
      PartialClass(const Absyn::ClassParts &definition, bool isClassExtends, InstNode *scope);

      const ClassTree* classTree() const noexcept override { return &_elements; }

      MetaModelica::Value toMetaModelica() const override;

    private:
      ClassTree _elements;
      // Modifier _modifier;
      // Modifier _ccMod;
      Prefixes _prefixes;
  };
};

#endif /* CLASS_H */
