//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_ROW_HPP
#define BOOST_NUMERIC_BINDINGS_ROW_HPP

#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/end.hpp>
#include <Core/Utils/numeric/bindings/detail/adaptable_type.hpp>
#include <Core/Utils/numeric/bindings/detail/offset.hpp>
#include <Core/Utils/numeric/bindings/size.hpp>
#include <Core/Utils/numeric/bindings/stride.hpp>
#include <Core/Utils/numeric/bindings/value_type.hpp>
#include <boost/ref.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T >
struct row_wrapper:
        adaptable_type< row_wrapper<T> >,
        reference_wrapper<T> {

    row_wrapper( T& t, std::size_t index ):
        reference_wrapper<T>(t),
        m_index( index ) {}

    std::size_t m_index;
};

template< typename T, typename Id, typename Enable >
struct adaptor< row_wrapper<T>, Id, Enable > {

    typedef typename bindings::value_type< T>::type value_type;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::vector >,
        mpl::pair< tag::size_type<1>, typename result_of::size2<T>::type >,
        mpl::pair< tag::data_structure, tag::linear_array >,
        mpl::pair< tag::stride_type<1>, typename result_of::stride2<T>::type >
    > property_map;

    static typename result_of::size2<T>::type size1( const Id& id ) {
        return bindings::size2( id.get() );
    }

    static typename result_of::begin_value< T >::type begin_value( Id& id ) {
        return bindings::begin_value( id.get() ) +
               offset( id.get(), id.m_index, 0 );
    }

    static typename result_of::end_value< T >::type end_value( Id& id ) {
        return bindings::begin_value( id.get() ) +
               offset( id.get(), id.m_index, size1(id) );
    }

    static typename result_of::stride2<T>::type stride1( const Id& id ) {
        return bindings::stride2( id.get() );
    }

};

} // namespace detail

namespace result_of {

template< typename T >
struct row {
    typedef detail::row_wrapper<T> type;
};

} // namespace result_of

template< typename T >
detail::row_wrapper<T> const row( T& underlying, std::size_t index ) {
    return detail::row_wrapper<T>( underlying, index );
}

template< typename T >
detail::row_wrapper<const T> const row( const T& underlying, std::size_t index ) {
    return detail::row_wrapper<const T>( underlying, index );
}

template< int N, typename T >
void row( const T& underlying ) {

}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
