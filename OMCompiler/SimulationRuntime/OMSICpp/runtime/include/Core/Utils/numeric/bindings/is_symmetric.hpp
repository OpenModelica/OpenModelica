//
// Copyright (c) 2009 by Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_IS_SYMMETRIC_HPP
#define BOOST_NUMERIC_BINDINGS_IS_SYMMETRIC_HPP

#include <Core/Utils/numeric/bindings/detail/property_map.hpp>
#include <Core/Utils/numeric/bindings/tag.hpp>

namespace boost {
namespace numeric {
namespace bindings {

template< typename T >
struct is_symmetric:
        detail::is_same_at< T, tag::matrix_type, tag::symmetric > {};

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
