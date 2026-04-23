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

#ifndef INDIRECTFORWARDITERATOR_H
#define INDIRECTFORWARDITERATOR_H

#include <iterator>

namespace OpenModelica
{
  namespace Util
  {
    template<typename Iterator>
    class IndirectForwardIterator
    {
      public:
        using iterator_category = std::forward_iterator_tag;
        using different_type    = std::ptrdiff_t;
        using iter_value_type   = typename std::iterator_traits<Iterator>::value_type;
        using value_type        = typename std::pointer_traits<iter_value_type>::element_type;
        using pointer           = value_type*;
        using reference         = value_type&;

        explicit IndirectForwardIterator(Iterator it)
          : _it{it}
        {
        }

        reference operator*() const noexcept
        {
          return **_it;
        }

        pointer operator->() const noexcept
        {
          return std::pointer_traits<pointer>::pointer_to(**_it);
        }

        IndirectForwardIterator& operator++()
        {
          ++_it;
          return *this;
        }

        IndirectForwardIterator operator++(int)
        {
          IndirectForwardIterator tmp = *this;
          ++(*this);
          return tmp;
        }

        friend bool operator== (const IndirectForwardIterator &i1, const IndirectForwardIterator &i2)
        {
          return i1._it == i2._it;
        }

        friend bool operator!= (const IndirectForwardIterator &i1, const IndirectForwardIterator &i2)
        {
          return i1._it != i2._it;
        }

      private:
        Iterator _it;
    };
  }
}

#endif /* INDIRECTFORWARDITERATOR_H */
