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

#ifndef DIMENSION_H
#define DIMENSION_H

#include <memory>
#include <optional>
#include <iosfwd>

#include "MetaModelica.h"

namespace OpenModelica
{
  class Dimension
  {
    public:
      Dimension();
      explicit Dimension(MetaModelica::Record value);
      explicit Dimension(int size);
      Dimension(const Dimension &other);
      Dimension(Dimension &&other);
      ~Dimension();

      Dimension& operator= (Dimension other);
      friend void swap(Dimension &first, Dimension &second) noexcept;

      MetaModelica::Value toNF() const;

      std::optional<int> size() const noexcept;

    private:
      std::unique_ptr<int> _dim;
  };

  void swap(Dimension &first, Dimension &second) noexcept;

  std::ostream& operator<< (std::ostream &os, const Dimension &dim);
}

#endif /* DIMENSION_H */
