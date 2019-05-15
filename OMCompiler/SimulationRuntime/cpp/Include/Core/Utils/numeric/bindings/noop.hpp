//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_NOOP_HPP
#define BOOST_NUMERIC_BINDINGS_NOOP_HPP

#include <Core/Utils/numeric/bindings/detail/adaptable_type.hpp>
#include <Core/Utils/numeric/bindings/detail/basic_unwrapper.hpp>
#include <boost/ref.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T >
struct noop_wrapper:
        adaptable_type< noop_wrapper<T> >,
        reference_wrapper<T> {
    noop_wrapper( T& t ): reference_wrapper<T>( t ) {}
};

template< typename T, typename Id, typename Enable >
struct adaptor< noop_wrapper<T>, Id, Enable >:
        basic_unwrapper< T, Id > {

    typedef typename property_map_of< T >::type property_map;

};

} // namespace detail

namespace result_of {

template< typename T >
struct noop {
    typedef detail::noop_wrapper<T> type;
};

} // namespace result_of

template< typename T >
detail::noop_wrapper<T> const noop( T& underlying ) {
    return detail::noop_wrapper<T>( underlying );
}

template< typename T >
detail::noop_wrapper<const T> const noop( const T& underlying ) {
    return detail::noop_wrapper<const T>( underlying );
}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
