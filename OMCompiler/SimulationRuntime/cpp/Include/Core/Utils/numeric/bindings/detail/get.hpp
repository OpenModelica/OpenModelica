//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DETAIL_GET_HPP
#define BOOST_NUMERIC_BINDINGS_DETAIL_GET_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <boost/preprocessor/repetition.hpp>
#include <boost/preprocessor/cat.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename Key >
struct get_dispatch {};

#define GENERATE_GET( z, which, unused ) \
template<> \
struct get_dispatch< tag::size_type<which> > { \
    template< typename T > \
    static std::ptrdiff_t invoke( const T& t ) { \
        return detail::adaptor_access<T>:: \
        BOOST_PP_CAT( size, which )( t ); \
    } \
};\
\
template<> \
struct get_dispatch< tag::stride_type<which> > { \
    template< typename T > \
    static std::ptrdiff_t invoke( const T& t ) { \
        return detail::adaptor_access<T>:: \
        BOOST_PP_CAT( stride, which )( t ); \
    } \
};\
\
template<> \
struct get_dispatch< tag::bandwidth_type<which> > { \
    template< typename T > \
    static std::ptrdiff_t invoke( const T& t ) { \
        return detail::adaptor_access<T>:: \
        BOOST_PP_CAT( bandwidth, which )( t ); \
    } \
};

BOOST_PP_REPEAT_FROM_TO(1,3,GENERATE_GET,~)

template< typename T, typename Key, typename Enable = void >
struct get_impl {};

template< typename T, typename Key >
struct get_impl< T, Key, typename boost::enable_if<
        is_same_at< T, Key, std::ptrdiff_t > >::type > {

    typedef std::ptrdiff_t result_type;

    static std::ptrdiff_t invoke( const T& t ) {
        return get_dispatch<Key>::invoke( t );
    }

};

template< typename T, typename Key >
struct get_impl< T, Key, typename boost::enable_if<
            mpl::not_< is_same_at< T, Key, std::ptrdiff_t > > >::type > {

    typedef typename property_at< T, Key >::type result_type;

    static result_type invoke( const T& ) {
        return result_type();
    }

};

template< typename T, typename Key >
struct result_of_get {
    typedef typename get_impl< T, Key >::result_type type;
};

template< typename Key, typename T >
typename result_of_get< T, Key >::type get( const T& t ) {
    return get_impl< T, Key >::invoke( t );
}

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
