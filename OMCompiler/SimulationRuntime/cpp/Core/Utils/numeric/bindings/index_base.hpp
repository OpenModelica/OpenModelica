//
// Copyright (c) 2010 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_INDEX_BASE_HPP
#define BOOST_NUMERIC_BINDINGS_INDEX_BASE_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace result_of {

template< typename T >
struct index_base {
    typedef typename detail::property_at< T, tag::index_base >::type type;
};

} // namespace result_of

template< typename T >
typename result_of::index_base<T>::type index_base( const T& ) {
    return typename result_of::index_base<T>::type();
}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
