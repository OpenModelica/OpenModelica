//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_END_HPP
#define BOOST_NUMERIC_BINDINGS_END_HPP

#include <Core/Utils/numeric/bindings/begin.hpp>

namespace boost {
namespace numeric {
namespace bindings {

namespace detail {

template< typename T, typename Tag >
struct end_impl {};

template< typename T >
struct end_impl< T, tag::value > {
    typedef typename bindings::value_type< T>::type* result_type;

    static result_type invoke( T& t ) {
        return adaptor_access<T>::end_value( t );
    }
};

template< typename T, int N >
struct end_impl< T, tag::addressing_index<N> > {

    typedef tag::addressing_index<N> tag_type;

    typedef linear_iterator<
        typename bindings::value_type< T>::type,
        typename result_of::stride< T, tag_type >::type
    > result_type;

    static result_type invoke( T& t ) {
        return result_type( adaptor_access<T>::end_value( t ), stride(t, tag_type() ) );
    }
};

template< typename T >
struct end_impl< T, tag::index_major > {
    typedef typename detail::property_at< T, tag::index_type >::type* result_type;

    static result_type invoke( T& t ) {
        return adaptor_access<T>::end_index_major( t );
    }
};

template< typename T >
struct end_impl< T, tag::compressed_index_major > {
    typedef typename detail::property_at< T, tag::index_type >::type* result_type;

    static result_type invoke( T& t ) {
        return adaptor_access<T>::end_compressed_index_major( t );
    }
};

template< typename T >
struct end_impl< T, tag::index_minor > {
    typedef typename detail::property_at< T, tag::index_type >::type* result_type;

    static result_type invoke( T& t ) {
        return adaptor_access<T>::end_index_minor( t );
    }
};

} // namespace detail

namespace result_of {

template< typename T, typename Tag = tag::addressing_index<1> >
struct end {
    BOOST_STATIC_ASSERT( (is_tag<Tag>::value) );
    typedef typename detail::end_impl<T,Tag>::result_type type;
};

} // namespace result_of

//
// Free Functions
//

//
// Overloads like end( t, tag );
//
template< typename T, typename Tag >
inline typename result_of::end<T,Tag>::type
end( T& t, Tag ) {
    return detail::end_impl<T,Tag>::invoke( t );
}

template< typename T, typename Tag >
inline typename result_of::end<const T,Tag>::type
end( const T& t, Tag ) {
    return detail::end_impl<const T,Tag>::invoke( t );
}

// Overloads for types with rank <= 1 (scalars, vectors)
// In theory, we could provide overloads for matrices here, too,
// if their minimal_rank is at most 1.

template< typename T >
typename boost::enable_if< mpl::less< rank<T>, mpl::int_<2> >,
    typename result_of::end< T, tag::addressing_index<1> >::type >::type
end( T& t ) {
    return detail::end_impl<T,tag::addressing_index<1> >::invoke( t );
}

template< typename T >
typename boost::enable_if< mpl::less< rank<T>, mpl::int_<2> >,
    typename result_of::end< const T >::type >::type
end( const T& t ) {
    return detail::end_impl<const T, tag::addressing_index<1> >::invoke( t );
}

#define GENERATE_END_INDEX( z, which, unused ) \
GENERATE_FUNCTIONS( end, which, mpl::int_<which> )

BOOST_PP_REPEAT_FROM_TO(1,3,GENERATE_END_INDEX,~)
GENERATE_FUNCTIONS( end, _value, tag::value )
GENERATE_FUNCTIONS( end, _row, tag::addressing_index<1> )
GENERATE_FUNCTIONS( end, _column, tag::addressing_index<2> )

GENERATE_FUNCTIONS( end, _index_major, tag::index_major )
GENERATE_FUNCTIONS( end, _compressed_index_major, tag::compressed_index_major )
GENERATE_FUNCTIONS( end, _index_minor, tag::index_minor )

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
