//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_BANDWIDTH_HPP
#define BOOST_NUMERIC_BINDINGS_BANDWIDTH_HPP

#include <Core/Utils/numeric/bindings/detail/generate_functions.hpp>
#include <Core/Utils/numeric/bindings/detail/get.hpp>
#include <Core/Utils/numeric/bindings/rank.hpp>
#include <Core/Utils/numeric/bindings/addressing_index.hpp>
#include <boost/mpl/and.hpp>
#include <boost/mpl/min.hpp>
#include <boost/mpl/greater.hpp>
#include <boost/mpl/less_equal.hpp>
#include <boost/static_assert.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename AddressingIndex, typename Enable = void >
struct bandwidth_impl {

    typedef typename tag::bandwidth_type< AddressingIndex::value > key_type;
    typedef typename result_of_get< T, key_type >::type result_type;

    static result_type invoke( const T& t ) {
        return get< key_type >( t );
    }

};

template< typename T >
struct bandwidth_impl< T, tag::lower >:
    bandwidth_impl< T, tag::addressing_index<1> > {};


template< typename T >
struct bandwidth_impl< T, tag::upper >:
    bandwidth_impl< T, tag::addressing_index<2> > {};


template< typename T, int N >
struct bandwidth_impl< T, tag::addressing_index<N>,
        typename boost::enable_if< typename mpl::and_<
            mpl::greater< tag::addressing_index<N>, rank<T> >,
            is_same_at< T, tag::bandwidth_type<1>, std::ptrdiff_t >
        >::type >::type > {

    typedef std::ptrdiff_t result_type;

    static result_type invoke( const T& t ) {
        return std::min< std::ptrdiff_t >( bandwidth_impl<T, tag::addressing_index<1> >::invoke(t), 1 );
    }

};

template< typename T, int N >
struct bandwidth_impl< T, tag::addressing_index<N>,
        typename boost::enable_if< typename mpl::and_<
            mpl::greater< tag::addressing_index<N>, rank<T> >,
            mpl::not_< is_same_at< T, tag::bandwidth_type<1>, std::ptrdiff_t > >
        >::type >::type > {

    typedef typename mpl::min<
        typename detail::property_at< T, tag::bandwidth_type<1> >::type,
        mpl::int_<1>
    >::type result_type;

    static result_type invoke( const T& t ) {
        return result_type();
    }

};

} // namespace detail


namespace result_of {

template< typename T, typename Tag = tag::addressing_index<1> >
struct bandwidth {
    BOOST_STATIC_ASSERT( (is_tag<Tag>::value) );
    typedef typename detail::bandwidth_impl< T, Tag >::result_type type;
};

} // namespace result_of

//
// Overloads for free template functions bandwidth( x, tag ),
//
template< typename T, typename Tag >
inline typename result_of::bandwidth< const T, Tag >::type
bandwidth( const T& t, Tag ) {
    return detail::bandwidth_impl< const T, Tag >::invoke( t );
}

// Overloads for free template function bandwidth( x )
// Valid for types with rank <= 1 (scalars, vectors)
// In theory, we could provide overloads for matrices here, too,
// if their minimal_rank is at most 1.

// template< typename T >
// typename boost::enable_if< mpl::less< rank<T>, mpl::int_<2> >,
//     typename result_of::bandwidth< const T >::type >::type
// bandwidth( const T& t ) {
//     return detail::bandwidth_impl< const T, tag::addressing_index<1> >::invoke( t );
// }

#define GENERATE_BANDWIDTH_INDEX( z, which, unused ) \
GENERATE_FUNCTIONS( bandwidth, which, tag::addressing_index<which> )

BOOST_PP_REPEAT_FROM_TO(1,3,GENERATE_BANDWIDTH_INDEX,~)

GENERATE_FUNCTIONS( bandwidth, _left, tag::addressing_index<1> )
GENERATE_FUNCTIONS( bandwidth, _right, tag::addressing_index<2> )
GENERATE_FUNCTIONS( bandwidth, _lower, tag::addressing_index<1> )
GENERATE_FUNCTIONS( bandwidth, _upper, tag::addressing_index<2> )
GENERATE_FUNCTIONS( bandwidth, _major, typename addressing_index_major<T>::type )
GENERATE_FUNCTIONS( bandwidth, _minor, typename addressing_index_minor<T>::type )

//
// Overloads for free template functions bandwidth_row( x, tag ),
// Here, tag is assumed to be either one of
// tag::transpose, tag::no_transpose, or tag::conjugate
//
namespace result_of {

template< typename T, typename TransTag >
struct bandwidth_lower_op {
    typedef typename bandwidth<
        T,
        typename addressing_index_trans< tag::addressing_index<1>, TransTag >::type
    >::type type;
};

template< typename T, typename TransTag >
struct bandwidth_upper_op {
    typedef typename bandwidth< T,
        typename addressing_index_trans< tag::addressing_index<2>, TransTag >::type >::type type;
};

} // namespace result_of

template< typename T, typename Tag >
inline typename result_of::bandwidth_lower_op< const T, Tag >::type
bandwidth_lower_op( const T& t, Tag ) {
    return bindings::bandwidth( t, typename addressing_index_trans< tag::addressing_index<1>, Tag >::type() );
}

template< typename T, typename Tag >
inline typename result_of::bandwidth_upper_op< const T, Tag >::type
bandwidth_upper_op( const T& t, Tag ) {
    return bindings::bandwidth( t, typename addressing_index_trans< tag::addressing_index<2>, Tag >::type() );
}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
