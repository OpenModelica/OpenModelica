//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DETAIL_ADAPTABLE_TYPE_HPP
#define BOOST_NUMERIC_BINDINGS_DETAIL_ADAPTABLE_TYPE_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename Derived >
struct adaptable_type {

    inline
    Derived& derived() {
        return *static_cast<Derived*>(this);
    }

    inline
    Derived const& derived() const {
        return *static_cast<Derived const*>(this);
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

template< typename T >
std::ostream& operator<<( std::ostream& os,
    boost::numeric::bindings::detail::adaptable_type<T> const& object );

#endif
