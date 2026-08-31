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

#ifndef ABSYN_ELEMENT_H
#define ABSYN_ELEMENT_H

#include <memory>
#include <iosfwd>

#include "MetaModelica.h"
#include "SourceInfo.h"
#include "Prefixes.h"

namespace OpenModelica::Absyn
{
  struct ElementVisitor;

  class Element
  {
    public:
      static constexpr int IMPORT = 0;
      static constexpr int EXTENDS = 1;
      static constexpr int CLASS = 2;
      static constexpr int COMPONENT = 3;
      static constexpr int DEFINEUNIT = 4;

    public:
      static std::unique_ptr<Element> fromSCode(MetaModelica::Record value);
      virtual ~Element();

      virtual std::unique_ptr<Element> clone() const noexcept = 0;
      friend void swap(Element &first, Element &second) noexcept;
      virtual MetaModelica::Value toSCode() const noexcept = 0;

      virtual void apply(ElementVisitor &visitor) = 0;

      const SourceInfo& info() const noexcept { return _info; }

      virtual void print(std::ostream &os, Each each = Each()) const noexcept = 0;

    protected:
      Element(SourceInfo info);

    private:
      SourceInfo _info;
  };

  void swap(Element &first, Element &second) noexcept;

  std::ostream& operator<< (std::ostream &os, const Element &element) noexcept;
}

#endif /* ABSYN_ELEMENT_H */
