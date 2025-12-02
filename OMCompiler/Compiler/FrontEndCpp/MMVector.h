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
