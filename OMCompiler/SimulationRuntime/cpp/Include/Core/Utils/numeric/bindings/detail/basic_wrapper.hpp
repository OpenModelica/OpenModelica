//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DETAIL_BASIC_WRAPPER_HPP
#define BOOST_NUMERIC_BINDINGS_DETAIL_BASIC_WRAPPER_HPP

#include <boost/ref.hpp>
#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/detail/basic_unwrapper.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename P1 = mpl::void_, typename P2 = mpl::void_,
        typename P3 = mpl::void_, typename P4 = mpl::void_ >
struct basic_wrapper: reference_wrapper<T> {
    basic_wrapper( T& t ): reference_wrapper<T>( t ) {}
};

template< typename T, typename P1, typename P2, typename P3, typename P4,
        typename Id, typename Enable >
struct adaptor< basic_wrapper<T, P1, P2, P3, P4>, Id, Enable >:
        basic_unwrapper< T, Id > {

    typedef typename property_insert< T, P1, P2, P3, P4 >::type property_map;

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
