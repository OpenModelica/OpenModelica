//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DETAIL_OFFSET_HPP
#define BOOST_NUMERIC_BINDINGS_DETAIL_OFFSET_HPP

#include <boost/utility/enable_if.hpp>
#include <boost/mpl/and.hpp>
#include <Core/Utils/numeric/bindings/is_column_major.hpp>
#include <Core/Utils/numeric/bindings/has_linear_array.hpp>
#include <Core/Utils/numeric/bindings/has_band_array.hpp>
#include <Core/Utils/numeric/bindings/stride.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename Enable = void >
struct offset_impl {};

template< typename T >
struct offset_impl< T, typename boost::enable_if< has_linear_array< T > >::type > {

    static std::ptrdiff_t invoke( const T& t, std::ptrdiff_t i1 ) {
        return i1 * bindings::stride1( t );
    }

    static std::ptrdiff_t invoke( const T& t, std::ptrdiff_t i1, std::ptrdiff_t i2 ) {
        return i1 * bindings::stride1( t ) +
               i2 * bindings::stride2( t );
    }

};

template< typename T >
struct offset_impl< T,
        typename boost::enable_if<
            mpl::and_<
                has_band_array< T >,
                is_column_major< T >
            >
        >::type > {

    static std::ptrdiff_t invoke( const T& t, std::ptrdiff_t i1, std::ptrdiff_t i2 ) {
        return i1 * bindings::stride1( t ) +
               i2 * (bindings::stride2( t )-1);
    }

};

template< typename T >
std::ptrdiff_t offset( const T& t, std::ptrdiff_t i1 ) {
    return offset_impl< T >::invoke( t, i1 );
}

template< typename T >
std::ptrdiff_t offset( const T& t, std::ptrdiff_t i1, std::ptrdiff_t i2 ) {
    return offset_impl< T >::invoke( t, i1, i2 );
}

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
