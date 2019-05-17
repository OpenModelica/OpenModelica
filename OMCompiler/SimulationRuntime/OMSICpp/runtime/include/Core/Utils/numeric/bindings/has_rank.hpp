//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_HAS_RANK_HPP
#define BOOST_NUMERIC_BINDINGS_HAS_RANK_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <boost/mpl/equal_to.hpp>

namespace boost {
namespace numeric {
namespace bindings {

template< typename T, int N, typename Enable = void >
struct has_rank {};

template< typename T, int N >
struct has_rank<
        T, N,
        typename boost::enable_if< detail::is_adaptable<T> >::type
    >:
    mpl::equal_to<
        typename detail::property_at< T, tag::entity >::type,
        mpl::int_< N >
    > {};

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
