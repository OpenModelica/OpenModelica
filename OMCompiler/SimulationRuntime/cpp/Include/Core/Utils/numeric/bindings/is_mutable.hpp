//
// Copyright (c) 2009 by Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_IS_MUTABLE_HPP
#define BOOST_NUMERIC_BINDINGS_IS_MUTABLE_HPP

#include <boost/type_traits/is_same.hpp>
#include <Core/Utils/numeric/bindings/value_type.hpp>

namespace boost {
namespace numeric {
namespace bindings {

template< typename T, typename Enable = void >
struct is_mutable: mpl::false_ {};

template< typename T >
struct is_mutable< T, typename boost::enable_if< detail::is_adaptable<T> >::type >:
        is_same<
            typename bindings::value_type< T>::type,
            typename remove_const< typename bindings::value_type< T>::type >::type
        > {};

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
