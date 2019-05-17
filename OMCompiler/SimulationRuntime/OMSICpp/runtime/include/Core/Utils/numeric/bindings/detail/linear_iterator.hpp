//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DETAIL_LINEAR_ITERATOR_HPP
#define BOOST_NUMERIC_BINDINGS_DETAIL_LINEAR_ITERATOR_HPP

#include <boost/iterator/iterator_adaptor.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename StrideType >
class linear_iterator: public boost::iterator_adaptor<
        linear_iterator<T, StrideType >,
        T*, use_default, random_access_traversal_tag > {
public:

    typedef mpl::int_<StrideType::value> stride_type;

    linear_iterator():
        linear_iterator::iterator_adaptor_(0) {}

    explicit linear_iterator( T* p, StrideType ignore ):
        linear_iterator::iterator_adaptor_(p) {}

private:
    friend class boost::iterator_core_access;

    void advance( int n ) {
        (this->base_reference()) += n * stride_type::value;
    }

    void decrement() {
        (this->base_reference()) -= stride_type::value;
    }

    void increment() {
        (this->base_reference()) += stride_type::value;
    }

};

template< typename T >
class linear_iterator< T, std::ptrdiff_t >: public boost::iterator_adaptor<
        linear_iterator< T, std::ptrdiff_t >,
        T*, use_default, random_access_traversal_tag > {
public:

    typedef std::ptrdiff_t stride_type;

    linear_iterator():
        linear_iterator::iterator_adaptor_(0),
        m_stride(0) {}

    explicit linear_iterator( T* p, std::ptrdiff_t stride ):
        linear_iterator::iterator_adaptor_(p),
        m_stride( stride ) {}

private:
    friend class boost::iterator_core_access;

    void advance( int n ) {
        (this->base_reference()) += n * m_stride;
    }

    void decrement() {
        (this->base_reference()) -= m_stride;
    }

    void increment() {
        (this->base_reference()) += m_stride;
    }

    std::ptrdiff_t m_stride;
};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
