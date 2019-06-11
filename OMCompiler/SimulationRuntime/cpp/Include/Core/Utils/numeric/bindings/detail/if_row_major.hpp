//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DETAIL_IF_ROW_MAJOR_HPP
#define BOOST_NUMERIC_BINDINGS_DETAIL_IF_ROW_MAJOR_HPP

#include <Core/Utils/numeric/bindings/tag.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename Order, typename True, typename False >
struct if_row_major {
    typedef False type;
};

template< typename True, typename False >
struct if_row_major< tag::row_major, True, False > {
    typedef True type;
};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
