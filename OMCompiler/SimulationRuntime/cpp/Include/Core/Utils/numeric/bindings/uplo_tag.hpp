//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_UPLO_TAG_HPP
#define BOOST_NUMERIC_BINDINGS_UPLO_TAG_HPP

#include <Core/Utils/numeric/bindings/tag.hpp>
#include <Core/Utils/numeric/bindings/detail/property_map.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename DataSide, typename TransTag >
struct uplo_tag_impl {
    // If your program complains about this part, this probably
    // means that you are trying to use row_major matrices where you
    // should use column_major matrices.
};

template<>
struct uplo_tag_impl< tag::upper, tag::no_transpose > {
    typedef tag::upper type;
};

template< typename TransTag >
struct uplo_tag_impl< tag::upper, TransTag > {
    typedef tag::lower type;
};

template<>
struct uplo_tag_impl< tag::lower, tag::no_transpose > {
    typedef tag::lower type;
};

template< typename TransTag >
struct uplo_tag_impl< tag::lower, TransTag > {
    typedef tag::upper type;
};

} // namespace detail

namespace result_of {

template< typename T, typename Trans = tag::no_transpose >
struct uplo_tag {
    typedef typename detail::uplo_tag_impl<
        typename detail::property_at< T, tag::data_side >::type,
        Trans
    >::type type;
};

} // namespace result_of

//
// uplo_tag will output tags that are compatible with BLAS and LAPACK, either one
// of tag::transpose, tag::no_transpose, or tag::conjugate.
// It needs an library-orientation (Trans) before it can make a decision about whether
// a tranpose is in order. Consult the various cases above to see what kind of
// tag is being generated in what kind of situation.
//
template< typename T, typename Trans >
typename result_of::uplo_tag< T, Trans >::type uplo_tag( const T& t, Trans ) {
    return result_of::uplo_tag< T, Trans >::type();
}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
