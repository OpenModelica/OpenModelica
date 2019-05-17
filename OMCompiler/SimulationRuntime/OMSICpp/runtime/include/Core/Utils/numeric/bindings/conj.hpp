//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_CONJ_HPP
#define BOOST_NUMERIC_BINDINGS_CONJ_HPP

#include <Core/Utils/numeric/bindings/trans.hpp>

namespace boost {
namespace numeric {
namespace bindings {

namespace result_of {

template< typename T >
struct conj {
    typedef detail::trans_wrapper<
        T,
        typename mpl::if_<
            detail::is_same_at< T, tag::value_transform, tag::conjugate >,
            mpl::pair< tag::value_transform, mpl::void_ >,
            mpl::pair< tag::value_transform, tag::conjugate >
        >::type
    > type;
};

}

template< typename T >
typename result_of::conj< T >::type const conj( T& t ) {
    return typename result_of::conj< T >::type( t );
}

template< typename T >
typename result_of::conj< const T >::type const conj( const T& t ) {
    return typename result_of::conj< const T >::type( t );
}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
