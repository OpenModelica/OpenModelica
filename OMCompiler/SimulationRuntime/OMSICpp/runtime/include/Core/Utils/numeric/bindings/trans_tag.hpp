//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_TRANS_TAG_HPP
#define BOOST_NUMERIC_BINDINGS_TRANS_TAG_HPP

#include <Core/Utils/numeric/bindings/data_order.hpp>
#include <Core/Utils/numeric/bindings/tag.hpp>
#include <Core/Utils/numeric/bindings/detail/property_map.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename LibraryOrder, typename DataOrder, typename ValueTransform >
struct trans_tag_impl {
    // If your program complains about this part, this probably
    // means that you are trying to use row_major matrices where you
    // should use column_major matrices. E.g., for ublas, use
    // matrix< double, column_major > instead of matrix< double >
    // to fix this.
};

template<>
struct trans_tag_impl< tag::column_major, tag::column_major, mpl::void_ > {
    typedef tag::no_transpose type;
};

template<>
struct trans_tag_impl< tag::column_major, tag::row_major, mpl::void_ > {
    typedef tag::transpose type;
};

template<>
struct trans_tag_impl< tag::column_major, tag::row_major, tag::conjugate > {
    typedef tag::conjugate type;
};

template<>
struct trans_tag_impl< tag::row_major, tag::row_major, mpl::void_  > {
    typedef tag::no_transpose type;
};

template<>
struct trans_tag_impl< tag::row_major, tag::column_major, mpl::void_ > {
    typedef tag::transpose type;
};

template<>
struct trans_tag_impl< tag::row_major, tag::column_major, tag::conjugate > {
    typedef tag::conjugate type;
};

} // namespace detail

namespace result_of {

template< typename T, typename Order >
struct trans_tag {
    typedef typename detail::trans_tag_impl< Order,
        typename result_of::data_order<T>::type,
        typename detail::property_at< T, tag::value_transform >::type >::type type;
};

} // namespace result_of

//
// trans_tag will output tags that are compatible with BLAS and LAPACK, either one
// of tag::transpose, tag::no_transpose, or tag::conjugate.
// It needs an library-orientation (Order) before it can make a decision about whether
// a tranpose is in order. Consult the various cases above to see what kind of
// tag is being generated in what kind of situation.
//
template< typename T, typename Order >
typename result_of::trans_tag< T, Order >::type trans_tag( const T& t, Order ) {
    return result_of::trans_tag< T, Order >::type();
}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
