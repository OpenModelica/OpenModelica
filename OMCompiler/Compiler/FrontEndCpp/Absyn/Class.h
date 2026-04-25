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

#ifndef ABSYN_CLASS_H
#define ABSYN_CLASS_H

#include <string>

#include "MetaModelica.h"
#include "Element.h"
#include "ElementPrefixes.h"
#include "Restriction.h"
#include "ClassDef.h"
#include "Comment.h"

namespace OpenModelica::Absyn
{
  class Class : public Element
  {
    public:
      Class(MetaModelica::Record value);
      Class(std::string name, ElementPrefixes prefixes, Encapsulated enc, Partial partial, Restriction res, std::unique_ptr<ClassDef> cdef, Comment cmt = {}, SourceInfo info = SourceInfo::dummyInfo());
      Class(const Class &other);
      Class(Class &&other) = default;

      Class& operator= (Class other) noexcept;
      Class& operator= (Class &&other) = default;
      friend void swap(Class &first, Class &second) noexcept;

      void apply(ElementVisitor &visitor) override;

      MetaModelica::Value toSCode() const noexcept override;

      const std::string& name() const noexcept;
      const ElementPrefixes& prefixes() const noexcept;
      const Comment& comment() const noexcept;
      const ClassDef& definition() const noexcept;

      std::unique_ptr<Element> clone() const noexcept override;
      void print(std::ostream &os, Each each) const noexcept override;

    private:
      std::string _name;
      ElementPrefixes _prefixes;
      Encapsulated _encapsulated;
      Partial _partial;
      Restriction _restriction;
      std::unique_ptr<ClassDef> _classDef;
      Comment _comment;
  };
}

#endif /* ABSYN_CLASS_H */
