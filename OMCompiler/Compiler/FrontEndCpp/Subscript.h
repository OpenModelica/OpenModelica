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

#ifndef SUBSCRIPT_H
#define SUBSCRIPT_H

#include <iosfwd>
#include <vector>

#include "MetaModelica.h"

namespace OpenModelica
{
  class Subscript
  {
    public:
      explicit Subscript(MetaModelica::Record value);
      ~Subscript();

      operator MetaModelica::Value() const;

      int64_t index() const { return _index; }

      std::string str() const;
      std::size_t hash() const noexcept;

    private:
      int64_t _index = 0;
  };

  bool operator== (const Subscript &subscript1, const Subscript &subscript2);

  std::ostream& operator<< (std::ostream &os, const Subscript &subscript);
  std::ostream& operator<< (std::ostream &os, const std::vector<Subscript> &subscripts);
}

template<>
struct std::hash<OpenModelica::Subscript>
{
  std::size_t operator() (const OpenModelica::Subscript &sub) const noexcept
  {
    return sub.hash();
  }
};

#endif /* SUBSCRIPT_H */
