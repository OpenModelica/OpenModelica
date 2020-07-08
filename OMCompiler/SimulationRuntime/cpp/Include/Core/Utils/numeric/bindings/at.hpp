//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_AT_HPP
#define BOOST_NUMERIC_BINDINGS_AT_HPP

#include <Core/Utils/numeric/bindings/detail/offset.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename Enable = void >
struct at_impl {

    typedef typename bindings::value_type<T>::type& result_type;

    // TODO implement other array structures such as triangular, band, etc.
    static result_type invoke( T& t, const std::ptrdiff_t i1, std::ptrdiff_t i2 ) {
        return t( i1, i2 );
    }

};

template< typename T >
struct at_impl< T, typename boost::enable_if< bindings::has_linear_array<T> >::type > {

    typedef typename bindings::value_type<T>::type& result_type;

    static result_type invoke( T& t, const std::ptrdiff_t i1 ) {
        return *( bindings::begin_value(t) + offset(t,i1) );
    }

    static result_type invoke( T& t, const std::ptrdiff_t i1, std::ptrdiff_t i2 ) {
        return *( bindings::begin_value(t) + offset(t,i1,i2) );
    }

};

}

namespace result_of {

template< typename T >
struct at {
    typedef typename detail::at_impl<T>::result_type type;
};

}

template< typename T >
typename result_of::at<T>::type at( T& t, const std::ptrdiff_t i1 ) {
    return detail::at_impl<T>::invoke( t, i1 );
}

template< typename T >
typename result_of::at<T>::type at( T& t, const std::ptrdiff_t i1, const std::ptrdiff_t i2 ) {
    return detail::at_impl<T>::invoke( t, i1, i2 );
}

} // bindings
} // numeric
} // boost

#endif
