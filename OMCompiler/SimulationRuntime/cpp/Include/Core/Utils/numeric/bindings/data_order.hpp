//
// Copyright (c) 2009 by Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DATA_ORDER_HPP
#define BOOST_NUMERIC_BINDINGS_DATA_ORDER_HPP

#include <Core/Utils/numeric/bindings/is_column_major.hpp>
#include <Core/Utils/numeric/bindings/is_row_major.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace result_of {

template< typename T, typename Enable = void >
struct data_order {};

template< typename T >
struct data_order< T, typename boost::enable_if< is_column_major<T> >::type > {
    typedef tag::column_major type;
};

template< typename T >
struct data_order< T, typename boost::enable_if< is_row_major<T> >::type > {
    typedef tag::row_major type;
};

} // namespace result_of

template< typename T >
typename result_of::data_order<T>::type data_order( const T& ) {
    return typename result_of::data_order<T>::type();
}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
