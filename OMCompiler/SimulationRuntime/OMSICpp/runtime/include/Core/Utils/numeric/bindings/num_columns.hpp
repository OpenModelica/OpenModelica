//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_NUM_COLUMNS_HPP
#define BOOST_NUMERIC_BINDINGS_NUM_COLUMNS_HPP

#include <Core/Utils/numeric/bindings/size.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace result_of {

template< typename T >
struct num_columns {
    typedef typename result_of::size2<T>::type type;
};

} // namespace result_of

template< typename T >
inline typename result_of::num_columns<T>::type num_columns( const T& t ) {
    return size2( t );
}

} // bindings
} // numeric
} // boost

#endif
