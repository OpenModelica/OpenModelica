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

#ifndef MMVECTOR_H
#define MMVECTOR_H

#include "MetaModelica.h"

extern record_description Vector_VECTOR__desc;

namespace OpenModelica
{
  namespace MetaModelica
  {
    template<typename T>
    class Vector
    {
      public:
        // Vector.new
        Vector(std::size_t capacity = 0)
          : _value{0, Vector_VECTOR__desc, {Mutable{Array(capacity)},
                                            Mutable{Value(static_cast<int64_t>(0))}}}
        {
        }

        // Vector.newFill
        Vector(std::size_t size, T value)
          : _value{0, Vector_VECTOR__desc, {Mutable{Array{size, Value{value}}},
                                            Mutable{Value{static_cast<int64_t>(size)}}}}
        {
        }

        // Vector.fromArray
        Vector(Array arr)
          : _value{0, Vector_VECTOR__desc, {Mutable{arr.copy()},
                                            Mutable{Value{static_cast<int64_t>(arr.size())}}}}
        {
        }

        // Vector.fromList
        Vector(List lst)
          : _value{0, Vector_VECTOR__desc, {Mutable{Array(lst.begin(), lst.end())},
                                            Mutable{Value{static_cast<int64_t>(lst.size())}}}}
        {

        }

        Array toArray()
        {
          auto arr = data();

          if (size() == arr.size()) {
            // If the Vector is filled to capacity, just make a copy of the internal array.
            return arr.copy();
          } else {
            return Array{arr.begin(), arr.end()};
          }
        }

        List toList()
        {
          auto arr = data();

          if (size() == arr.size()) {
            // If the Vector is filled to capacity, use the faster arrayList.
            return List{arr};
          } else {
            return List{arr.begin(), arr.end()};
          }
        }

        operator Value() const noexcept { return _value; }

        size_t size() const
        {
          return _value[1].toMutable()->toInt();
        }

      private:
        Array data() const
        {
          return _value[0].toMutable()->toArray();
        }

      private:
        Record _value;
    };
  }
}

#endif /* MMVECTOR_H */
