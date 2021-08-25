//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_HERM_HPP
#define BOOST_NUMERIC_BINDINGS_HERM_HPP

#include <Core/Utils/numeric/bindings/detail/basic_wrapper.hpp>
#include <Core/Utils/numeric/bindings/tag.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace result_of {

template< typename T >
struct herm {
    typedef detail::basic_wrapper<
        T,
        mpl::pair< tag::matrix_type, tag::hermitian >
    > type;
};

} // namespace result_of

template< typename T >
typename result_of::herm< T >::type const herm( T& underlying ) {
    return typename result_of::herm< T >::type( underlying );
}

template< typename T >
typename result_of::herm< const T >::type const herm( const T& underlying ) {
    return typename result_of::herm< const T >::type( underlying );
}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
