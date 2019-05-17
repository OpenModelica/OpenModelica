//
// Copyright (c) 2009 by Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_IS_COMPLEX_HPP
#define BOOST_NUMERIC_BINDINGS_IS_COMPLEX_HPP

#include <boost/type_traits/is_complex.hpp>

namespace boost {
namespace numeric {
namespace bindings {

template< typename T >
struct is_complex: boost::is_complex<T> {};

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
