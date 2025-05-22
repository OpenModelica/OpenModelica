#ifndef MMUNORDEREDMAP_H
#define MMUNORDEREDMAP_H

#include "MMVector.h"

extern record_description UnorderedMap_UNORDERED__MAP__desc;

namespace OpenModelica
{
  namespace MetaModelica
  {
    template<typename K, typename V>
    class UnorderedMap
    {
      public:
        UnorderedMap(void *hash, void *keyEq, size_t bucketCount = 1)
          : _value{0, UnorderedMap_UNORDERED__MAP__desc,
              {Vector{bucketCount, List{}}, Vector<K>{}, Vector<V>{}, Value{hash}, Value{keyEq}}}
        {
        }

        operator Value() const noexcept { return _value; }

      private:
        Record _value;
    };
  }
}

#endif /* MMUNORDEREDMAP_H */
