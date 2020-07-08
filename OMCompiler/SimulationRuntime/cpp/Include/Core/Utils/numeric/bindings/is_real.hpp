//
// Copyright (c) 2009 by Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_IS_REAL_HPP
#define BOOST_NUMERIC_BINDINGS_IS_REAL_HPP

#include <boost/type_traits/is_floating_point.hpp>

namespace boost {
namespace numeric {
namespace bindings {

template< typename T >
struct is_real: boost::is_floating_point<T> {};

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
