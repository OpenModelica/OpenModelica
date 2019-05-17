//
// Copyright (c) 2009 Rutger ter Borg
// Copyright (c) 2010 Thomas Klimpel
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_VECTOR_VIEW_HPP
#define BOOST_NUMERIC_BINDINGS_VECTOR_VIEW_HPP

#include <Core/Utils/numeric/bindings/detail/adaptable_type.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T >
struct vector_view_wrapper:
        adaptable_type< vector_view_wrapper<T> > {
    typedef T value_type;

    vector_view_wrapper( T* t, std::size_t size ):
        m_t( t ),
        m_size( size ) {}
    T* m_t;
    std::size_t m_size;
};

template< typename T, typename Id, typename Enable >
struct adaptor< vector_view_wrapper<T>, Id, Enable > {

    typedef typename Id::value_type value_type;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::vector >,
        mpl::pair< tag::size_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::data_structure, tag::linear_array >,
        mpl::pair< tag::stride_type<1>, tag::contiguous >
    > property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.m_size;
    }

    static value_type* begin_value( Id& id ) {
        return id.m_t;
    }

    static value_type* end_value( Id& id ) {
        return id.m_t + id.m_size;
    }

};

} // namespace detail

namespace result_of {

template< typename T >
struct vector_view {
    typedef detail::vector_view_wrapper<T> type;
};

} // namespace result_of

template< typename T >
detail::vector_view_wrapper<T> const vector_view( T* t, std::size_t size ) {
    return detail::vector_view_wrapper<T>( t, size );
}

template< typename T >
detail::vector_view_wrapper<const T> const vector_view( const T* t, std::size_t size ) {
    return detail::vector_view_wrapper<const T>( t, size );
}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
