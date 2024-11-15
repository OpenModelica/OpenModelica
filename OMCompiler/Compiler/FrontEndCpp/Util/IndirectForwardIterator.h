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
