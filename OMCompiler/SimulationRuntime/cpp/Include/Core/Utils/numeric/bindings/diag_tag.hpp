//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DIAG_TAG_HPP
#define BOOST_NUMERIC_BINDINGS_DIAG_TAG_HPP

#include <Core/Utils/numeric/bindings/tag.hpp>
#include <Core/Utils/numeric/bindings/detail/property_map.hpp>

namespace boost {
namespace numeric {
namespace bindings {

namespace detail {

template< typename T >
struct diag_tag_impl {
    typedef tag::non_unit type;
};

template<>
struct diag_tag_impl< tag::unit_triangular > {
    typedef tag::unit type;
};

} // namespace detail

namespace result_of {

template< typename T >
struct diag_tag {
    typedef typename detail::diag_tag_impl<
        typename detail::property_at< T, tag::matrix_type >::type
    >::type type;
};

} // namespace result_of

//
// diag_tag will output tags that are compatible with BLAS and LAPACK
//
template< typename T, typename Order >
typename result_of::diag_tag< T >::type diag_tag( const T& t ) {
    return result_of::diag_tag< T >::type();
}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
