//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_VALUE_TYPE_HPP
#define BOOST_NUMERIC_BINDINGS_VALUE_TYPE_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>

namespace boost {
namespace numeric {
namespace bindings {

template< typename T >
struct value_type {
    typedef typename detail::property_at< T, tag::value_type >::type type;
};

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
