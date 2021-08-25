//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DETAIL_IF_LEFT_HPP
#define BOOST_NUMERIC_BINDINGS_DETAIL_IF_LEFT_HPP

#include <Core/Utils/numeric/bindings/tag.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename Side, typename Left, typename Right >
struct if_left_impl {

    typedef Right result_type;

    static result_type invoke( Left, Right right ) {
        return right;
    }

};

template< typename Left, typename Right >
struct if_left_impl< tag::left, Left, Right > {

    typedef Left result_type;

    static result_type invoke( Left left, Right ) {
        return left;
    }

};

// by-value
template< typename Side, typename Left, typename Right >
typename if_left_impl< Side, const Left, const Right >::result_type
if_left( const Side, const Left left, const Right right ) {
    return if_left_impl< Side, const Left, const Right >::invoke( left, right );
}

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
