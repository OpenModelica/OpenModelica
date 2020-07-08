//
// Copyright (c) 2009 by Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_IS_NUMERIC_HPP
#define BOOST_NUMERIC_BINDINGS_IS_NUMERIC_HPP

#include <boost/mpl/or.hpp>
#include <Core/Utils/numeric/bindings/is_real.hpp>
#include <Core/Utils/numeric/bindings/is_complex.hpp>
#include <boost/type_traits/is_integral.hpp>

namespace boost {
namespace numeric {
namespace bindings {

template< typename T >
struct is_numeric: mpl::or_< is_real<T>, is_complex<T>, is_integral<T> > {};

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
