//
// Copyright (c) 2009 by Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DATA_SIDE_HPP
#define BOOST_NUMERIC_BINDINGS_DATA_SIDE_HPP

#include <Core/Utils/numeric/bindings/detail/property_map.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace result_of {

template< typename T >
struct data_side {
    typedef typename detail::property_at< T, tag::data_side >::type type;
};

} // namespace result_of

template< typename T >
typename result_of::data_side<T>::type data_side( const T& ) {
    return result_of::data_side<T>::type();
}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
